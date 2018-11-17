COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentDisplay.asm

AUTHOR:		Andrew Wilson, Oct 29, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/29/92		Initial revision

DESCRIPTION:
	This contains code for the NTaker display object.	

	$Id: documentDisplay.asm,v 1.1 97/04/04 16:17:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplaySpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We determine which of our children should be usable here.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplaySpecBuild	method	NTakerDisplayClass, MSG_SPEC_BUILD
	.enter
	push	ax, cx, dx, bp
	mov	ax, MSG_NTAKER_DISPLAY_REDO_UI
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	mov	di, offset NTakerDisplayClass
	call	ObjCallSuperNoLock
	.leave
	ret
NTakerDisplaySpecBuild	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUsableIfFeatureOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the passed object usable or not depending upon whether
		or not the passed feature bit is set.

CALLED BY:	GLOBAL
PASS:		*ds:di - object
		ax - feature bit
		es - dgroup
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUsableIfFeatureOn	proc	near	uses	ax, cx, dx, bp
	.enter
	test	ax, es:[features]
	mov	ax, MSG_GEN_SET_USABLE
	jnz	10$
	mov	ax, MSG_GEN_SET_NOT_USABLE	
10$:
	xchg	di, si
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	xchg	di, si
	.leave
	ret
SetUsableIfFeatureOn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplayRedoUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-inits the UI, depending upon the UI level.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplayRedoUI	method	dynamic NTakerDisplayClass, 
			MSG_NTAKER_DISPLAY_REDO_UI

;	Set the topic navigation gadgetry usable if the associated feature
;	exists, *or* if the document being opened has topics.

	mov	ax, MSG_GEN_SET_USABLE
	test	es:[features], mask NF_CREATE_TOPICS
	jnz	setTopicObj
	tst	ds:[di].NDISPI_hasTopics
	jnz	setTopicObj
	mov	ax, MSG_GEN_SET_NOT_USABLE
setTopicObj:
	push	si
	mov	si, offset TopicGroup
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	si

	mov	ax, mask NF_CREATE_TOPICS
	mov	di, offset CreateTopicTrigger
	call	SetUsableIfFeatureOn

	mov	di, offset MoveBoxTrigger
	call	SetUsableIfFeatureOn

	mov	ax, mask NF_KEYWORDS
	mov	di, offset CardKeywords
	call	SetUsableIfFeatureOn

	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GetResourceHandleNS	ViewTypeList, bx
	mov	si, offset ViewTypeList
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;
	mov_tr	cx, ax				;CX <- current selection
	pop	si


	mov	ax, MSG_NTAKER_DISPLAY_SET_VIEW_TYPE
	GOTO	ObjCallInstanceNoLock
NTakerDisplayRedoUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplaySetViewType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets various objs usable/not usable depending upon the passed
		view type.

CALLED BY:	GLOBAL
PASS:		cx - view type
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplaySetViewType	method	NTakerDisplayClass, 
				MSG_NTAKER_DISPLAY_SET_VIEW_TYPE
	.enter

	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	GetResourceHandleNS	NTakerPrimary, bx
	mov	si, offset NTakerPrimary
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

EC <	cmp	cx, ViewType						>
EC <	ERROR_AE	BAD_VIEW_TYPE					>

	test	es:[features], mask NF_CARD_LIST
	jnz	10$
	mov	cx, VT_CARD
10$:

;	Set the UI gadgetry on the "list" side usable or not depending on
;	the passed ViewType

	mov	ax, MSG_GEN_SET_USABLE
	cmp	cx, VT_CARD
	jne	setListObj
	mov	ax, MSG_GEN_SET_NOT_USABLE
setListObj:
	push	cx
	mov	si, offset NTakerListInfo
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	cx

;	Set the UI gadgetry on the "card" side usable or not depending on
;	the passed ViewType

	mov	ax, MSG_GEN_SET_USABLE
	cmp	cx, VT_LIST
	jne	setCardObj
	mov	ax, MSG_GEN_SET_NOT_USABLE
setCardObj:
	mov	si, offset NTakerCardInfo
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

;
;	If dates are turned on, update the date display, as we may have to
;	set one of the items usable/not usable
;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	GetResourceHandleNS	OptionsList, bx
	mov	si, offset OptionsList
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	test	ax, mask NTO_DISPLAY_DATES
	jz	exit
	mov_tr	cx, ax
	call	NTakerDisplayChangeOptions
exit:
	.leave
	ret
NTakerDisplaySetViewType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplayChangeOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent out when the user changes the options.

CALLED BY:	GLOBAL
PASS:		cx - new options
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplayChangeOptions	method	NTakerDisplayClass, 
				MSG_NTAKER_DISPLAY_CHANGE_OPTIONS
	.enter
	test	cx, mask NTO_DISPLAY_DATES
	jz	turnOffDates
	test	es:[features], mask NF_MISC
	jnz	turnOnDates
turnOffDates:

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset ListDateDisplay
	call	ObjCallInstanceNoLock 
	
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset CardDateDisplay
	call	ObjCallInstanceNoLock

	jmp	exit
turnOnDates:
;
;	The user wants the date display - depending upon what mode we are
;	in, we will set the card/list displays usable.
;

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset ListDateDisplay
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GetResourceHandleNS	ViewTypeList, bx
	mov	si, offset ViewTypeList
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;
	cmp	ax, VT_CARD
	mov	ax, MSG_GEN_SET_NOT_USABLE
	jnz	setCardList
	mov	ax, MSG_GEN_SET_USABLE
setCardList:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset CardDateDisplay
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
NTakerDisplayChangeOptions	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplaySetHasTopics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets "hasTopics" boolean

CALLED BY:	GLOBAL
PASS:		cx - non-zero if file has topics
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplaySetHasTopics	method	NTakerDisplayClass, 
				MSG_NTAKER_DISPLAY_SET_HAS_TOPICS

	mov	ds:[di].NDISPI_hasTopics, cx
	mov	ax, MSG_NTAKER_DISPLAY_REDO_UI
	GOTO	ObjCallInstanceNoLock
NTakerDisplaySetHasTopics	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplayChangeNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables/enables UI depending upon whether currently selected
		item is a card or a folder

CALLED BY:	GLOBAL
PASS:		cx - selection #
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplayChangeNote	method	NTakerDisplayClass, 
			MSG_NTAKER_DISPLAY_CHANGE_NOTE
	push	cx

;	Enable/Disable the gadgetry depending upon whether a note or a
;	folder is selected

	cmp	cx, GIGS_NONE
	je	setDisabled

	cmp	cx, ds:[di].NDISPI_numTopics
	mov	ax,  MSG_GEN_SET_NOT_ENABLED
	mov	cx,  MSG_GEN_SET_ENABLED
	mov	dx,  cx
	jae	setEnabledStatus		;Branch if selection is a
						; note
	mov_tr	dx, ax		;DX <- MSG_GEN_SET_NOT_ENABLED
	mov	ax, cx		;AX,CX <- MSG_GEN_SET_ENABLED
setEnabledStatus:

;	DX <- message for card only objects (Move,EditCard trigger)
;	CX <- message for folder/card objects (Move,Delete triggers)
;	AX <- message for folder only objects (DownTopic trigger)

	push	dx
	push	cx
	mov	dl, VUM_NOW
	mov	si, offset DownTopic
	call	ObjCallInstanceNoLock

	pop	ax
	mov	dl, VUM_NOW
	mov	si, offset DeleteTrigger
	call	ObjCallInstanceNoLock

	pop	ax
	push	ax
	mov	dl, VUM_NOW
	mov	si, offset MoveBoxTrigger
	call	ObjCallInstanceNoLock
	pop	ax

	mov	dl, VUM_NOW
	mov	si, offset EditCardTrigger
	call	ObjCallInstanceNoLock

;	Send the notification off to the document

	pop	cx
	mov	ax, MSG_NTAKER_DOC_CHANGE_NOTE
	call	SendToDocument
	ret
setDisabled:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	cx, ax
	mov	dx, ax
	jmp	setEnabledStatus
NTakerDisplayChangeNote	endp

SendToDocument	proc	near		uses	bx, si, di
	.enter
	movdw	bxsi, ds:[OLMBH_output]
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SendToDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplaySetNumSubTopics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the # sub topics for the currently displayed topic

CALLED BY:	GLOBAL
PASS:		cx - num sub topics
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplaySetNumSubTopics	method	NTakerDisplayClass,
				MSG_NTAKER_DISPLAY_SET_NUM_SUB_TOPICS
	.enter
	mov	ds:[di].NDISPI_numTopics, cx
	.leave
	ret
NTakerDisplaySetNumSubTopics	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplayCardListDoubleClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines whether the double click is on a folder or not,
		and behaves accordingly.

CALLED BY:	GLOBAL
PASS:		cx - item number
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplayCardListDoubleClick	method	dynamic NTakerDisplayClass,
				MSG_NTAKER_DISPLAY_CARD_LIST_DOUBLE_CLICK
	push	cx
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	GenCallApplication
	pop	cx
	mov	ax, MSG_NTAKER_DOC_DOWN_TOPIC	
	cmp	cx, ds:[di].NDISPI_numTopics
	jb	sendMessage			;Branch if double click on 
						; sub topic
	mov	ax, MSG_NTAKER_DOC_EDIT_SELECTED_CARD
sendMessage:
	call	SendToDocument

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenSendToApplicationViaProcess

	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	GenSendToApplicationViaProcess	
	ret
NTakerDisplayCardListDoubleClick	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDisplayQueryForNoteListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passes this to the document.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDisplayQueryForNoteListMoniker	method	NTakerDisplayClass,
				MSG_NTAKER_DISPLAY_QUERY_FOR_NOTE_LIST_MONIKER
	.enter
	mov	ax, MSG_NTAKER_DOC_QUERY_FOR_NOTE_LIST_MONIKER
	call	SendToDocument
	.leave
	ret
NTakerDisplayQueryForNoteListMoniker	endp

DocumentCode	ends
