COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Tiramisu
MODULE:		Preferences
FILE:		preffax2PrefFaxDialog.asm

AUTHOR:		Peter Trinh, Feb  8, 1995

ROUTINES:
	Name			Description
	----			-----------

PrefFaxDialogInitiate		Allows new changes to be accepted.
PrefFaxDialogSendMsgToSelectedList	Relays msgs to selected list.
PrefFaxDialogSelectList		"Selects" a dialing code list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/ 8/95   	Initial revision


DESCRIPTION:
	Contains method handler and routines too implement the
	PrefFaxDialogClass. 
		

	$Id: preffax2PrefFaxDialog.asm,v 1.1 97/04/05 01:43:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrefFaxCode	segment resource;



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes self apply-able so that new changes will be accepted.

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= PrefFaxDialogClass object
		ds:di	= PrefFaxDialogClass instance data
		ds:bx	= PrefFaxDialogClass object (same as *ds:si)
		es 	= segment of PrefFaxDialogClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	2/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxDialogInitiate	method dynamic PrefFaxDialogClass, 
					MSG_GEN_INTERACTION_INITIATE
	.enter

	; be sure to call the super class first, cuz it disables the
	; IC_APPLY trigger.

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, offset PrefFaxDialogClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	ObjCallInstanceNoLock

	.leave
	ret

PrefFaxDialogInitiate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxDialogSendMsgToSelectedList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will send the message and parameters (given on the
		stack) to the list selected by the list selector.  Eg.
		if the Access list is chosen, then the message and
		parameters on the passed structure will be sent to the
		Access list.

		For now, the list selector is hard-coded to be
		DialingCodeSelector, but can be expanded later on to
		support any various selectors.  Assumes
		DialingCodeSelector is in the same segment as the
		PrefFaxDialog object. 

CALLED BY:	MSG_PREF_FAX_DIALOG_SEND_MSG_TO_SELECTED_LIST
PASS:		*ds:si	= PrefFaxDialogClass object
		ds:di	= PrefFaxDialogClass instance data
		ds:bx	= PrefFaxDialogClass object (same as *ds:si)
		es 	= segment of PrefFaxDialogClass
		ax	= message #

		PrefFaxMesgStruct	- on the stack, ss:bp

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxDialogSendMsgToSelectedList	method dynamic PrefFaxDialogClass, 
				MSG_PREF_FAX_DIALOG_SEND_MSG_TO_SELECTED_LIST 
	uses	ax, cx, dx, si
	.enter

	mov	si, offset DialingCodeSelector
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	push	bp					; stack frame
	call	ObjCallInstanceNoLock
	pop	bp					; stack frame
	jc	noSelection

	mov	si, offset DialingCodeLongDistList
	cmp	ax, FAX_LONG_DISTANCE_ITEM
	je	gotListLptr
	mov	si, offset DialingCodeAccessList

gotListLptr:
	mov	ax, ss:[bp].PFMS_msgNumber
	mov	cx, ss:[bp].PFMS_cx_data
	mov	dx, ss:[bp].PFMS_dx_data
	push	bp					; stack frame
	mov	bp, ss:[bp].PFMS_bp_data
	call	ObjCallInstanceNoLock
	pop	bp					; stack frame

noSelection:
	.leave
	ret
PrefFaxDialogSendMsgToSelectedList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxDialogSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when the user clicks on one of the items of the
		DialingCodeSelector.  Will determine which list is
		selected, and "ACTIVATE" that list while
		"DEACTIVATING" the other list(s) NOT_USABLE.

CALLED BY:	MSG_PREF_FAX_DIALOG_SELECT_DIALING_CODE_LIST
PASS:		*ds:si	= PrefFaxDialogClass object
		ds:di	= PrefFaxDialogClass instance data
		ds:bx	= PrefFaxDialogClass object (same as *ds:si)
		es 	= segment of PrefFaxDialogClass
		ax	= message #

		cx	= current selection
		bp	= number of selections
		dl	= GenItemGroupStateFlags

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

	Sets the selected DialingCodeList usable, and makes the other
	list not_usable.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxDialogSelectList	method dynamic PrefFaxDialogClass, 
				MSG_PREF_FAX_DIALOG_SELECT_DIALING_CODE_LIST
	uses	ax, cx, dx, bp
	.enter

	tst	bp
	jz	done				; nothing was selected

	cmp	cx, FAX_ACCESS_ITEM
	je	activateAccessList

	;
	; Activating long distance list
	;
	mov	ax, MSG_PREF_DIALING_CODE_LIST_DEACTIVATE
	mov	si, offset DialingCodeAccessList
	call	ObjCallInstanceNoLock

	mov	ax, MSG_PREF_DIALING_CODE_LIST_ACTIVATE
	mov	si, offset DialingCodeLongDistList
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

activateAccessList:

	mov	ax, MSG_PREF_DIALING_CODE_LIST_DEACTIVATE
	mov	si, offset DialingCodeLongDistList
	call	ObjCallInstanceNoLock

	mov	ax, MSG_PREF_DIALING_CODE_LIST_ACTIVATE
	mov	si, offset DialingCodeAccessList
	call	ObjCallInstanceNoLock
	jmp	done

PrefFaxDialogSelectList	endm


PrefFaxCode	ends

