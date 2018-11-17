COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiUtils.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	TextSuspendOnApplyInteractionClass	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement
	TextSuspendOnApplyInteractionClass

	$Id: uiUtils.asm,v 1.1 97/04/07 11:17:22 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	TextSuspendOnApplyInteractionClass	;declare the class record

TextClassStructures	ends

;---------------------------------------------------

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextSuspendOnApplyInteractionPreApply --
		MSG_GEN_PRE_APPLY for TextSuspendOnApplyInteractionClass

DESCRIPTION:	Handle PRE_APPLY be suspending the output

PASS:
	*ds:si - instance data
	es - segment of TextSuspendOnApplyInteractionClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/10/92		Initial version

------------------------------------------------------------------------------@
TextSuspendOnApplyInteractionPreApply	method dynamic	\
					TextSuspendOnApplyInteractionClass,
					MSG_GEN_PRE_APPLY

	mov	ax, MSG_META_SUSPEND
	FALL_THRU	TSUP_Common

TextSuspendOnApplyInteractionPreApply	endm

;---

TSUP_Common	proc	far
	push	ax
	movdw	bxsi, ds:[OLMBH_output]		;bxsi = controller
	call	ObjLockObjBlock
	mov	ds, ax
	pop	ax
	push	bx
	clrdw	bxdi				;no class
	call	GenControlSendToOutputRegs
	pop	bx
	call	MemUnlock
	ret
TSUP_Common	endp

;---

TextSuspendOnApplyInteractionPostApply	method dynamic	\
					TextSuspendOnApplyInteractionClass,
					MSG_GEN_POST_APPLY

	mov	ax, MSG_META_UNSUSPEND
	GOTO	TSUP_Common

TextSuspendOnApplyInteractionPostApply	endm

TextControlCode ends
