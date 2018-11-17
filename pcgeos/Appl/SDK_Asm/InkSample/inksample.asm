COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	InkSample
MODULE:		
FILE:		inksample.asm

AUTHOR:		Allen Yuen, Jan 25, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/25/94   	Initial revision


DESCRIPTION:
	This contains the body code for the InkSample App.
		

	$Id: inksample.asm,v 1.1 97/04/04 16:35:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include geos.def
include geode.def
include resource.def
include ec.def
include object.def

UseLib	ui.def

include Objects/vTextC.def

include	inksample.def

include	inksample.rdef


idata	segment
	InkSampleProcessClass	mask CLASSF_NEVER_SAVED
					; process class needs this flag
	InkSampleTriggerClass
	InkSampleCopyTriggerClass
idata	ends

InkSampleCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSampleTriggerSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the text on the text object when button is pressed

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION
PASS:		*ds:si	= InkSampleTriggerClass object
		ds:di	= InkSampleTriggerClass instance data
		ds:bx	= InkSampleTriggerClass object (same as *ds:si)
		es 	= segment of InkSampleTriggerClass
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
	AY	1/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSampleTriggerSendAction	method dynamic InkSampleTriggerClass, 
					MSG_GEN_TRIGGER_SEND_ACTION

	GetResourceHandleNS	InkSampleText, bx
	mov	si, offset InkSampleText	; ^lbx:si = InkSampleText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	movdw	dxbp, ds:[di].ISTI_textToDisplay ; ^ldx:bp = text to switch to
EC <	xchg	bx, dx							>
EC <	call	ECCheckMemHandle					>
EC <	xchg	dx, bx							>
	clr	cx, di				; null-terminated,
						; no MessageFlags
	GOTO	ObjMessage

InkSampleTriggerSendAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSampleCopyTriggerSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION
PASS:		*ds:si	= InkSampleCopyTriggerClass object
		ds:di	= InkSampleCopyTriggerClass instance data
		ds:bx	= InkSampleCopyTriggerClass object (same as *ds:si)
		es 	= segment of InkSampleCopyTriggerClass
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
	AY	1/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSampleCopyTriggerSendAction	method dynamic InkSampleCopyTriggerClass, 
					MSG_GEN_TRIGGER_SEND_ACTION
	.enter

	sub	sp, 100
	GetResourceHandleNS	InkSampleInterface, bx
	mov	si, offset InkSampleText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	dx, ss
	mov	bp, sp
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	si, offset NewText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	add	sp, 100

	.leave
	ret
InkSampleCopyTriggerSendAction	endm

InkSampleCode	ends
