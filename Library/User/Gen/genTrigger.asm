COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genTrigger.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenTriggerClass		Trigger object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the Trigger class

	$Id: genTrigger.asm,v 1.1 97/04/07 11:45:19 newdeal Exp $

-------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenTrigger.doc
	
UserClassStructures	segment resource

; Declare the class record

	GenTriggerClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenTriggerBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenTriggerBuild	method	GenTriggerClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_TRIGGER
	GOTO	GenQueryUICallSpecificUI

GenTriggerBuild	endm

Build ends


BuildUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenTriggerReplaceParams

DESCRIPTION:	Replaces any generic instance data paramaters that match
		BranchReplaceParamType

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_BRANCH_REPLACE_PARAMS

	dx	- size BranchReplaceParams structure
	ss:bp	- offset to BranchReplaceParams

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

GenTriggerReplaceParams	method	GenTriggerClass, \
					MSG_GEN_BRANCH_REPLACE_PARAMS
	cmp	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR	; Replacing output OD?
	jne	done			; 	branch if so
					; Replace action OD if matches
					;	search OD
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	bx, offset GTI_destination
	call	GenReplaceMatchingDWord

done:
	ret				; & all done (superclass only calls
					; children, which we don't have)

GenTriggerReplaceParams	endm

BuildUncommon ends

;--------

Common segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenTriggerTrigger -- 
		MSG_GEN_TRIGGER_SEND_ACTION for GenTriggerClass

DESCRIPTION:	Trigger a Trigger into sending the action method to
		the action output descriptor

PASS:
	*ds:si - instance data
	es - segment of GenTriggerClass
	ax - MSG_GEN_TRIGGER_SEND_ACTION
	cl - non-zero if we're handling a double-click.

RETURN: carry - set if error (object not enabled or usable)

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if trigger enabled {
		objSendOuput(actionMethod, actionOD);
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Chris 	1/22/92		Changed to allow ATTR_GEN_TRIGGER_-
				CUSTOM_DOUBLE_PRESS

------------------------------------------------------------------------------@

GenTriggerSendMessage	method	dynamic GenTriggerClass, \
				MSG_GEN_TRIGGER_SEND_ACTION
				
	; trigger must be enabled and usable, if not then return carry set

	mov	al,ds:[di].GI_states
	and	al, mask GS_ENABLED or mask GS_USABLE
	cmp	al, mask GS_ENABLED or mask GS_USABLE
	stc
	LONG	jnz	exit

	call	GetTriggerMessage
	push	bp			; save message to use
	
	; IN CASE WE SEND A MSG_GEN_NOTIFY_INTERACTION_COMPLETE,
	; pass cx:dx as our OD, bp = AD_message
	
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	
					; Process attributes stored
					; in GI_Attrs, whenever this
					; trigger is activated, including
					; 'signalInteractionComplete'
	call	GenProcessGenAttrsBeforeAction

	; SEND OUT TRIGGER ACTION
	;
	; first deal with null action optr:  in this case if there is a
	; ATTR_GEN_TRIGGER_INTERACTION_COMMAND, send its data with
	; MSG_GEN_GUP_INTERACTION_COMMAND to the trigger itself.  This will
	; travel up the to first non-GIT_ORGANIZATIONAL GenInteraction
	; where it will be handled
	;
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	mov	ax, ds:[di].GTI_destination.handle
	or	ax, ds:[di].GTI_destination.chunk
	jnz	noInteractionCommand
	;
	; check for ATTR_GEN_TRIGGER_INTERACTION_COMMAND and fetch its data,
	; if any
	;
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	call	ObjVarFindData		; ds:bx = data, if found
	jnc	noInteractionCommand
	VarDataFlagsPtr	ds, bx, ax
	test	ax, mask VDF_EXTRA_DATA	; if no data, ignore it
	jz	noInteractionCommand
	mov	cx, ds:[bx]		; else, fetch data
	pop	ax			; unload predefined message
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjCallInstanceNoLock	; send data gup
	jmp	afterStackFixed	; skip normal send code

noInteractionCommand:
	;
	; If we're about to send out a custom double-click message, don't 
	; bother with arguments.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	cmp	bp, ds:[di].GTI_actionMsg
	mov	di, mask MF_FIXUP_DS	; assume not doing action data
	jne	send			; not sending normal message, forget
					;    action data
	
	;
	; action optr is not null, handle as usual
	;
	clr	bp		; presume no ATTR_GEN_TRIGGER_ACTION_DATA
	segmov	es, cs
	mov	di, offset cs:ProcessGenTriggerVarDataHandlers
	mov	ax, length (cs:ProcessGenTriggerVarDataHandlers)
	call	ObjVarScanData

	mov	di, mask MF_FIXUP_DS

	tst	bp		; see if ACTION_DATA returned
	jz	send

	VarDataSizePtr	ds, bp, dx	; get size of hint into dx
	cmp	dx, 6		; will data fit into registers? (cx, dx, bp)
	jbe	getIntoRegs	; if not, dx = size, ds:[bp] = data.

;getOntoStack:
	pop	ax			; ax <- get msg (before stack params!)
	sub	sp, dx			; get space on stack for data
	push	si, di, es
	mov	si, bp			; ds:si <- ptr to var data entry
	mov	di, sp
	add	di, 6			; compensation for pushed registers
	segmov	es, ss
	mov	bp, di			; ss:[bp] <- ptr to dest
	mov	cx, dx			; cx <- size of var data
	rep	movsb			; copy over data
	pop	si, di, es
	ornf	di, mask MF_STACK	; set flag to show on stack
	jmp	sendWithMessage

getIntoRegs:
	mov	cx, ds:[bp+0]	; if will fit into registers, get it there
	mov	dx, ds:[bp+2]
	mov	bp, ds:[bp+4]
send:
	pop	ax			;restore message to use
sendWithMessage:
	mov	bx, ds:[si]		;get ptr to instance data
	add	bx, ds:[bx].Gen_offset	;ds:di = GenInstance
	push	dx, di
	push	ds:[bx].GTI_destination.handle
	push	ds:[bx].GTI_destination.chunk
	call	GenProcessAction
	pop	dx, di
	test	di, mask MF_STACK
	jz	afterStackFixed
	add	sp, dx			; fix stack
afterStackFixed:

	call	GenProcessGenAttrsAfterAction
	clc
exit:
	ret
GenTriggerSendMessage	endm



ProcessGenTriggerVarDataHandlers	VarDataHandler \
	< ATTR_GEN_TRIGGER_ACTION_DATA, offset AttrActionData >

AttrActionData	proc	far
	mov	bp, bx			; return offset to hint
	ret
AttrActionData	endp

		


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetTriggerMessage

SYNOPSIS:	Returns appropriate message for trigger to send.

CALLED BY:	GenTriggerTrigger

PASS:		*ds:si -- GenTrigger object
		cl -- non-zero if double-press behavior requested

RETURN:		cx -- appropriate message to use

DESTROYED:	di, es, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/22/92		Initial version

------------------------------------------------------------------------------@

GetTriggerMessage	proc	near
	class	GenTriggerClass
			
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	;ds:di = GenInstance
	mov	bp, ds:[di].GTI_actionMsg
					; Process attributes stored
					; in GI_Attrs, whenever this
					; trigger is activated
	tst	cl			; see if double-press requested
	jz	exit			; Nah, return normal message
	mov	di, cs
	mov	es, di
	mov	di, offset cs:DoublePressHint
	mov	ax, length (cs:DoublePressHint)
	call	ObjVarScanData		; bp changed if ATTR_ exists
exit:
	ret
GetTriggerMessage	endp

DoublePressHint	VarDataHandler \
	<ATTR_GEN_TRIGGER_CUSTOM_DOUBLE_PRESS, offset CustomDoublePress>

CustomDoublePress	proc	far
	mov	bp, {word} ds:[bx]		;get double-press message
	ret
CustomDoublePress	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenTriggerGetMessage -- MSG_GEN_TRIGGER_GET_ACTION_MSG for
		GenTriggerClass

DESCRIPTION:	Get the message for a trigger

PASS:
	*ds:si - instance data
	es - segment of GenTriggerClass

	ax - MSG_GEN_TRIGGER_GET_ACTION_MSG

RETURN: cx:dx - OD
	bp - action

ALLOWED TO DESTROY:
	ax
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/22/92		Initial version

------------------------------------------------------------------------------@

GenTriggerGetMessage	method	GenTriggerClass, MSG_GEN_TRIGGER_GET_ACTION_MSG
	mov	cx, ds:[di].GTI_actionMsg
	ret

GenTriggerGetMessage	endm

Common	ends
;
;----------------
;
Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenTriggerSetAction -- MSG_GEN_TRIGGER_SET_ACTION_MSG for
		GenTriggerClass

DESCRIPTION:	Set the message for a trigger

PASS:
	*ds:si - instance data
	es - segment of GenTriggerClass
	ax - MSG_GEN_TRIGGER_SET_ACTION_MSG

	cx - new message

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/22/92		Initial version
	
------------------------------------------------------------------------------@

GenTriggerSetMessage	method	GenTriggerClass, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	bx, offset GTI_actionMsg
	call	GenSetWord
					; If specifically grown, call specific
					; UI class
	GOTO	GenCallSpecIfGrown

GenTriggerSetMessage	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenTriggerSetOD   

DESCRIPTION:	Set the OD for a trigger

PASS:
	*ds:si - instance data
	es - segment of GenTriggerClass
	ax - MSG_GEN_TRIGGER_SET_DESTINATION

	cx:dx - new output

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

GenTriggerSetOD	method	GenTriggerClass, MSG_GEN_TRIGGER_SET_DESTINATION
EC<	call	ECCheckODCXDX						>
					; Store OD, mark as dirty
	mov	bx, offset GTI_destination
	GOTO	GenSetDWord
GenTriggerSetOD	endm

Build	ends
;
;----------------
;
GetUncommon segment resource

GenTriggerGetOD	method	GenTriggerClass, MSG_GEN_TRIGGER_GET_DESTINATION
	mov	cx, ds:[di].GTI_destination.handle
	mov	dx, ds:[di].GTI_destination.chunk
	ret

GenTriggerGetOD	endm

GetUncommon ends
