COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		hello3.asm

AUTHOR:		Allen Yuen, Jan 19, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/19/95   	Initial revision


DESCRIPTION:
	This contais the code for the Hello3 App.
		

	$Id: hello3.asm,v 1.1 97/04/04 16:35:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	stdapp.def

include	hello3.def

include	hello3.rdef



idata	segment

	HelloProcessClass	mask CLASSF_NEVER_SAVED
					; process class needs this flag
	HelloReplaceTriggerClass

idata	ends

HelloCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HRTGenTriggerSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the text on the text object when button is pressed

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION
PASS:		*ds:si	= HelloReplaceTriggerClass object
		ds:di	= HelloReplaceTriggerClass instance data
		ds:bx	= HelloReplaceTriggerClass object (same as *ds:si)
		es 	= segment of HelloReplaceTriggerClass
		ax	= message #
		cl	= zero if we should send regular action, non-zero if
			  trigger should act as if double-pressed on.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HRTGenTriggerSendAction	method dynamic HelloReplaceTriggerClass, 
					MSG_GEN_TRIGGER_SEND_ACTION
;
; Change the "uses" line if necessary.
;
	uses	ax, cx, dx, bp
	.enter

	.leave
	ret
HRTGenTriggerSendAction	endm

HelloCode	ends
