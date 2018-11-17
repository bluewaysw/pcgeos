COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genAppCommonIACP.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenApplicationClass	Class that implements an application

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of genApplication.asm

DESCRIPTION:
	This file contains routines to implement the GenApplication class.

	$Id: genAppCommonIACP.asm,v 1.1 97/04/07 11:44:51 newdeal Exp $

------------------------------------------------------------------------------@
Common segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppGetAppModeMethod

DESCRIPTION:	Retrieves the process method stored in GAI_appMode
		MUST BE IN COMMON RESOURCE, SINCE IS CALLED BY ATTACH *AND*
		DETACH CODE. Also, it is only a few bytes, so it doesn't cost
		much to keep it in (far less than, say, loading the entire
		AppAttach/AppDetach resource when it isn't necessary.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE

RETURN: cx	- method # stored in GAI_appMode

ALLOWED TO DESTROY:
	ax, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

GenAppGetAppModeMethod	method	dynamic GenApplicationClass, MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE
	mov	cx, ds:[di].GAI_appMode
	ret

GenAppGetAppModeMethod	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppQueryUI -- MSG_GEN_APPLICATION_QUERY_UI for GenApplicationClass

DESCRIPTION:	Return the segment of the UI to use

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_GEN_APPLICATION_QUERY_UI

RETURN: carry - set if query acknowledged, clear if not
	ax - handle of UI to use

ALLOWED TO DESTROY:
	cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	UI_FOR_APPLICATION		-> default
	UI_FOR_BASE_GROUP		-> default
	UI_FOR_POPUP			-> default
	UI_FOR_URGENT			-> default
	UI				-> APP UI


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

GenAppQueryUI	method	dynamic GenApplicationClass, MSG_GEN_APPLICATION_QUERY_UI
	mov	ax, ds:[di].GAI_specificUI
	stc
	ret

GenAppQueryUI	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenAppGetState -- MSG_GEN_APPLICATION_GET_STATE for
			GenApplicationClass

DESCRIPTION:	Return application state info (GAI_states)

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_GEN_APPLICATION_GET_STATE

RETURN: ax	- ApplicationStates

ALLOWED TO DESTROY:
	ah, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

GenAppGetState	method	dynamic GenApplicationClass, MSG_GEN_APPLICATION_GET_STATE

	mov	ax, ds:[di].GAI_states
	stc				; Method received just fine, thank you
	ret

GenAppGetState	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppSendClassedEvent

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

	ax - MSG_META_SEND_CLASSED_EVENT

	^hcx	- ClassedEvent
	dx	- TravelOption

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/92		Initial version

------------------------------------------------------------------------------@

GenAppSendClassedEvent	method	GenApplicationClass, \
				MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_PRINT_CONTROL
	je	sendToPrintControl


	mov	di, offset GenApplicationClass
	GOTO	ObjCallSuperNoLock

sendToPrintControl:
	mov	dx, TO_SELF
	call	GenAppFindPrintControl	; Get PrintControl in ^lbx:si, or
					; NULL if not found
	clr	di
	GOTO	FlowMessageClassedEvent

GenAppSendClassedEvent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GenAppFindPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds OD of PrintControl, if existing.

CALLED BY:	GenAppSendClassedEvent
PASS:		*ds:si	- app object
RETURN:		^lbx:si	- PrintControl, else NULL if not found.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenAppFindPrintControl	proc	near	uses	ax, cx, dx, di, bp
	.enter
	mov	ax, ATTR_GEN_APPLICATION_PRINT_CONTROL
	call	ObjVarFindData
	jnc	notFound

	mov	si, ds:[bx].chunk	; Fetch PrintControl
	mov	bx, ds:[bx].handle
	jmp	short exit

notFound:
	clr	bx, si
exit:
	.leave
	ret

GenAppFindPrintControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListFindObjectOfClassInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find and object of the specified class in the
		general change notification list.  Only looks at objects
		run by same block as current.

CALLED BY:	INTERNAL

PASS:		cx:dx - class to look for
		*ds:si - gcn list to search

RETURN:		carry set if optr found
			ds:di - item
		carry clear if not found (di perserved)
		ds - updated to keep pointing to gcn list block, if moved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	(0)
GCNListFindObjectOfClassInList	proc	far	uses	ax, bx
	.enter
EC <	call	ECCheckChunkArray					>
	push	di
	mov	bx, cs
	mov	di, offset GCNFindObjectOfClassCallback
	call	ChunkArrayEnum
	pop	di
	jnc	exit			; if not found, restore di
	mov	di, ax			; return item offset, in case found
exit:
	.leave
	ret
GCNListFindObjectOfClassInList	endp

;
; pass:
;	*ds:si = array
;	ds:di = element
;	cx:dx = class to look for
; return:
;	carry - set to end enumeration (optr found)
;		ds:ax - offset to element found
; destroyed:
;	none
;
GCNFindObjectOfClassCallback	proc	far	uses bx, si, es, di
	.enter
	mov	ax, di			; save offset, in case found

	mov	bx, ds:[di].GCNLE_item.handle
	call	ObjTestIfObjBlockRunByCurThread
	jne	noMatch
	mov	si, ds:[di].GCNLE_item.chunk
	mov	es, cx
	mov	di, dx
	call	ObjSwapLock
	call	ObjIsObjectInClass
	call	ObjSwapUnlock
	jnc	noMatch

match:
	stc				; end enumeration
	jmp	done
noMatch:
	clc				; continue enumeration
done:
	.leave
	ret
GCNFindObjectOfClassCallback	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfFloatingKbdAllowed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if floating keyboards are allowed...

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if floating keyboards are allowed
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfFloatingKbdAllowed	proc	far	uses	ax
	.enter

;	If no keyboard is attached to the system, then the floating keyboard
;	is definitely allowed...

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_NO_KEYBOARD
	jnz	kbdAllowed

;	If a keyboard is (or may be) attached to the system, then we may still
;	want a floating keyboard. Check the flag...

	push	ds
	mov	ax, segment udata
	mov	ds, ax
	tst_clc	ds:[floatingKbdEnabled]
	pop	ds
	jz	exit
kbdAllowed:
	stc
exit:
	.leave
	ret
CheckIfFloatingKbdAllowed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserGetFloatingKbdEnabledStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the floatingKbdEnabled variable

CALLED BY:	GLOBAL

PASS:		nothing
RETURN:		ax	= floatingKbdEnabled
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserGetFloatingKbdEnabledStatus	proc	far
	uses	es
	.enter

	segmov	es, udata, ax
	clr	ax
	mov	al, es:[floatingKbdEnabled]

	.leave
	ret
UserGetFloatingKbdEnabledStatus	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenAppGetAttachFlags -- MSG_GEN_APPLICATION_GET_ATTACH_FLAGS for
			GenApplicationClass

DESCRIPTION:	Return AppAttachFlags (GAI_attachFlags)

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS

RETURN: cx	- AppAttachFlags

ALLOWED TO DESTROY:
	ah, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/22/92		Initial version

------------------------------------------------------------------------------@


GenAppGetAttachFlags	method	dynamic GenApplicationClass, \
				MSG_GEN_APPLICATION_GET_ATTACH_FLAGS

	mov	cx, ds:[di].GAI_attachFlags
	ret

GenAppGetAttachFlags	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenApplicationGetAppFeatures -- MSG_GEN_APPLICATION_GET_APP_FEATURES
						for GenApplicationClass

DESCRIPTION:	Get the app features

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

	ax - The message

RETURN:
	ax - features
	dx - UIInterfaceLevel for app

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/16/92		Initial version

------------------------------------------------------------------------------@
GenApplicationGetAppFeatures	method dynamic	GenApplicationClass,
						MSG_GEN_APPLICATION_GET_APP_FEATURES
	mov	ax, ds:[di].GAI_appFeatures
	mov	dx, ds:[di].GAI_appLevel
	ret

GenApplicationGetAppFeatures	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenApplicationSetAppFeatures --
		MSG_GEN_APPLICATION_SET_APP_FEATURES for GenApplicationClass

DESCRIPTION:	Set the app features

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

	ax - The message

	cx - features

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/16/92		Initial version

------------------------------------------------------------------------------@
GenApplicationSetAppFeatures	method dynamic	GenApplicationClass,
					MSG_GEN_APPLICATION_SET_APP_FEATURES

	sub	sp, (size GenAppUpdateFeaturesParams)
	mov	bp, sp					;ss:bp <- params

	mov	ax, cx					;ax <- new features
	xchg	ax, ds:[di].GAI_appFeatures		;ax <- old features
	xor	ax, cx					;bp <- features changed
	mov	ss:[bp].GAUFP_featuresOn, cx
	mov	ss:[bp].GAUFP_featuresChanged, ax

	mov	ax, ds:[di].GAI_appLevel
	mov	ss:[bp].GAUFP_level, ax
	mov	ss:[bp].GAUFP_oldLevel, ax

UpdateAppCommon	label	far
	jz	done					;branch if no change

	mov	ax, ds:[di].GAI_states
	andnf	ax, mask AS_ATTACHING			;ax <- opening flag
	mov	ss:[bp].GAUFP_appOpening, ax

	mov	ax, MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
	call	ObjCallInstanceNoLock
done:
	add	sp, (size GenAppUpdateFeaturesParams)
	ret

GenApplicationSetAppFeatures	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationSetAppLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user level for the application

CALLED BY:	MSG_GEN_APPLICATION_SET_APP_LEVEL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenApplicationClass
		ax - the message

		cx - UIInterfaceLevel

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationSetAppLevel		method dynamic GenApplicationClass,
					MSG_GEN_APPLICATION_SET_APP_LEVEL
	sub	sp, (size GenAppUpdateFeaturesParams)
	mov	bp, sp					;ss:bp <- params

	mov	ax, ds:[di].GAI_appFeatures
	mov	ss:[bp].GAUFP_featuresOn, ax
	clr	ss:[bp].GAUFP_featuresChanged

	mov	ax, cx
	xchg	ax, ds:[di].GAI_appLevel		;set new level
	mov	ss:[bp].GAUFP_oldLevel, ax
	mov	ss:[bp].GAUFP_level, cx
	cmp	ax, cx
	jmp	UpdateAppCommon
GenApplicationSetAppLevel		endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenApplicationUpdateFeaturesViaTable --
		MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
						for GenApplicationClass

DESCRIPTION:	Update the features of an application via a table

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

	ax - The message

	ss:bp - GenAppUpdateFeaturesParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/22/92		Initial version

------------------------------------------------------------------------------@
GenApplicationUpdateFeaturesViaTable	method dynamic	GenApplicationClass,
				MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE

	mov	cx, ss:[bp].GAUFP_featuresOn
	mov	dx, ss:[bp].GAUFP_featuresChanged
	mov	di, ss:[bp].GAUFP_appOpening
	movdw	bxsi, ss:[bp].GAUFP_table
	call	MemLockFixedOrMovable
	mov	ds, ax					;dssi = table
	mov	ax, ss:[bp].GAUFP_tableLength
	;
	; Process tables corresponding to app feature bits
	;
	push	bp, di
featureLoop:
	shl	dx
	jnc	nextFeature			;branch if feature not changed
	push	ax, dx, si
	movdw	axsi, ds:[si]			;ds:si <- UsabilityTuple array
	tstdw	axsi
	jz	nextFeaturePop
	call	doOneTable
nextFeaturePop:
	pop	ax, dx, si
nextFeature:
	add	si, size fptr
	shl	cx				;cx <- shift next feature in
	dec	ax				;ax <- one less entry
	jnz	featureLoop			;loop while more entries
	pop	bp, di
	;
	; Process table for levels
	;
	tst	ss:[bp].GAUFP_levelTable.segment
	jz	done				;branch if no table
	movdw	bxsi, ss:[bp].GAUFP_levelTable
	call	MemLockFixedOrMovable
	mov	ds, ax				;dssi = level table
	mov	ax, ss:[bp].GAUFP_level
	cmp	ax, ss:[bp].GAUFP_oldLevel
	je	doneUnlockLevelTable
	mov	cx, 0x8000			;mark as "on"
	push	bp
	call	doOneTable
	pop	bp
doneUnlockLevelTable:
	mov	bx, ss:[bp].GAUFP_levelTable.segment
	call	MemUnlockFixedOrMovable
done:
	mov	bx, ss:[bp].GAUFP_table.segment
	call	MemUnlockFixedOrMovable

	ret

	;
	; PASS:
	;	ds:si - GenAppUsabilityTuple array
	;	cx - high bit set if feature on
	;	di - non-zero if app opening
	; DESTROYED:
	;	ax, bx, dx, bp, si, di
	;
doOneTable:

innerLoop:
	mov	al, ds:[si].GAUT_flags
	push	ax, cx, si, di, bp
	test	al, mask GAUTF_OFF_IF_BIT_ON
	jz	10$
	xornf	cx, 0x8000			;high bit set if "on"
10$:
	mov	bx, ds:[si].GAUT_objResId
	call	GeodeGetResourceHandle
	mov	si, ds:[si].GAUT_objChunk	;bx:si = object

	and	al, mask GAUTF_COMMAND
	cmp	al, GAUC_RECALC_CONTROLLER
	jz	recalcController

	cmp	al, GAUC_REPARENT
	LONG jz	reparent

	cmp	al, GAUC_POPUP
	LONG jz	popup

	cmp	al, GAUC_RESTART
	jz	restart

	cmp	al, GAUC_TOOLBAR
	jnz	usability

	; toolbar -- turn off is going not usable

	test	cx, 0x8000
	jnz	usability

	push	bx, cx, si
	mov	ax, MSG_GEN_BOOLEAN_GET_IDENTIFIER
	call	objMessageCall				;ax = identifier
	push	ax
	mov	ax, MSG_GEN_FIND_PARENT
	call	objMessageCall				;cxdx = parent
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	objMessageCall				;ax = bits set
	pop	cx
	not	cx
	and	cx, ax					;cx = new bits
	xor	ax, cx					;ax = bits changed
	jz	15$
	push	ax
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	call	objMessageSend
	pop	cx
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	objMessageSend
	mov	ax, MSG_GEN_APPLY
	call	objMessageSend
15$:
	pop	bx, cx, si

usability:

	; set usable/not-usable

	test	cx, 0x8000
	mov	ax, MSG_GEN_SET_USABLE
	jnz	20$
	mov	ax, MSG_GEN_SET_NOT_USABLE
20$:

	call	objMessageSendWithMode
	jmp	common

recalcController:
	tst	di				;if opening app then
	jnz	toCommon			;do nothing
	mov	ax, MSG_GEN_CONTROL_REBUILD_NORMAL_UI
	call	objMessageSend
	mov	ax, MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI
	call	objMessageSend
	jmp	common

restart:

	; Set not-usable then usable, but only do this if the object is
	; currently usable

	mov	ax, MSG_GEN_GET_USABLE
	call	objMessageCall			;carry set if usable
	jnc	toCommon
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	objMessageSendWithMode
	mov	ax, MSG_GEN_SET_USABLE
	call	objMessageSendWithMode
toCommon:
	jmp	common

popup:

	; Make this a popup

	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	objMessageSendWithMode

	test	cx, 0x8000
	mov	cl, GIV_SUB_GROUP
	jz	gotVisibility
	mov	cl, GIV_POPUP
gotVisibility:
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	call	objMessageSend
	mov	ax, MSG_GEN_SET_USABLE
	call	objMessageSendWithMode
	jmp	common

reparent:

	; if bit is set then move object up a level, else make it a child
	; of the CharacterMenu

	pushdw	bxsi				;save object to reparent
	push	cx, bp				;save "on" flag, frame
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	objMessageSendWithMode
	mov	ax, MSG_GEN_FIND_PARENT
	call	objMessageCall			;cxdx = parent

	xchgdw	bxsi, cxdx			;bxsi = parent
						;cxdx = child
	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	bp, mask CCF_MARK_DIRTY
	call	objMessageSend

	pop	cx, bp				;recover "on" flag, frame
	test	cx, 0x8000
	jz	moveDown

	tst	ss:[bp].GAUFP_unReparentObject.handle
	jnz	unreparent

	mov	ax, MSG_GEN_FIND_PARENT
	call	objMessageCall			;cxdx = grandparent
	xchgdw	bxsi, cxdx			;bxsi = grandparent
						;cxdx = parent
	mov	ax, MSG_GEN_FIND_CHILD
	call	objMessageCall			;bp = position
	inc	bp
	jmp	moveCommon

moveDown:
	movdw	bxsi, ss:[bp].GAUFP_reparentObject
clrBpMoveCommon:
	clr	bp

moveCommon:

	popdw	cxdx				;cxdx = object to reparent
	ornf	bp, mask CCF_MARK_DIRTY
	mov	ax, MSG_GEN_ADD_CHILD
	call	objMessageSend

	movdw	bxsi, cxdx			;bxsi = child
	mov	ax, MSG_GEN_SET_USABLE
	call	objMessageSendWithMode

common:
	pop	ax, cx, si, di, bp
	add	si, size GenAppUsabilityTuple
	test	al, mask GAUTF_END_OF_LIST
	LONG jz	innerLoop

	retn

unreparent:
	movdw	bxsi, ss:[bp].GAUFP_unReparentObject
	jmp	clrBpMoveCommon	

;---

objMessageCall:
	mov	di, mask MF_CALL
	call	ObjMessage
	retn

;---

objMessageSendWithMode:
	mov	dl, VUM_NOW
	tst	di
	jnz	gotMode
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
gotMode:

objMessageSend:
	clr	di
	call	ObjMessage
	retn

GenApplicationUpdateFeaturesViaTable	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationSetNotUserInteractable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets AS_NOT_USER_INTERACTABLE bit

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationSetNotUserInteractable	method	dynamic GenApplicationClass, 
				MSG_GEN_APPLICATION_SET_NOT_USER_INTERACTABLE
	ornf	ds:[di].GAI_states, mask AS_NOT_USER_INTERACTABLE
	ret
GenApplicationSetNotUserInteractable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationSetUserInteractable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears AS_NOT_USER_INTERACTABLE bit

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationSetUserInteractable	method	dynamic GenApplicationClass, 
				MSG_GEN_APPLICATION_SET_USER_INTERACTABLE
	andnf	ds:[di].GAI_states, not mask AS_NOT_USER_INTERACTABLE
	ret
GenApplicationSetUserInteractable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFirstPrimaryCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sets the carry if the passed object is a primary.

CALLED BY:	GLOBAL

PASS:		*ds:si - ptr to object
RETURN:		carry set if this is a primary
		^lCX:DX - set to this object if it is a primary
DESTROYED:	es,di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	(0)		; not used
GetFirstPrimaryCallback	proc	far
	mov	di, segment GenPrimaryClass
	mov	es, di
	mov	di, offset GenPrimaryClass
	call	ObjIsObjectInClass
	jnc	exit
	mov	cx, ds:[LMBH_handle]	;^lCX:DX <- this object
	mov	dx, si
exit:
	ret
GetFirstPrimaryCallback	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationInkQueryReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler is invoked when an object replies to
		a MSG_META_QUERY_IF_PRESS_IS_INK.

CALLED BY:	GLOBAL
PASS:		cx - InkReturnValue
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationInkQueryReply	method	dynamic GenApplicationClass,
				MSG_GEN_APPLICATION_INK_QUERY_REPLY
EC <	jcxz	error							>
EC <	cmp	cx, IRV_WAIT						>
EC <	jae	error							>
EC <	cmp	cx, IRV_NO_INK						>
EC <	je	10$							>
EC <	tst	bp							>
EC <	jz	10$							>
EC <	mov	bx, bp							>
EC <	call	ECCheckMemHandle					>
EC <10$:								>
	mov	ax, MSG_FLOW_INK_REPLY
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	UserCallFlow	
	Destroy	ax, cx, dx, bp
	ret
EC <error:>
EC <	ERROR	UI_BAD_INK_RETURN_VALUE_PASSED_TO_GEN_APP_INK_QUERY_REPLY >
GenApplicationInkQueryReply	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenApplicationBringWindowToTop -- 
		MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP for GenApplicationClass

DESCRIPTION:	Updates order or GAGCNLT_WINDOWS GCN list.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax 	- MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP

	^lcx:dx	- window to bring to top

RETURN:	nothing

ALLOWED TO DESTROY:
	ah, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/92		Initial version

------------------------------------------------------------------------------@
GenApplicationBringWindowToTop 	method dynamic GenApplicationClass, \
				MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP

	call	FindWindowListItem			; ds:di = item
	jnc	done					; not found

	mov	bx, di					; ds:bx = item to move

	clr	ax					; get first item
	call	ChunkArrayElementToPtr			; ds:di = first item

	cmp	bx, di					; already first item?
	je	done					; yes, done

	push	ds:[bx].GCNLE_item.handle		; save item to move
	push	ds:[bx].GCNLE_item.chunk

	xchg	di, bx					; ds:di = item to move
							; ds:bx = first item
	call	ChunkArrayDelete			; delete item to move
	mov	di, bx					; ds:di = first item
	call	ChunkArrayInsertAt			; insert before 1st item
							; (ds:di = new item)
	pop	ds:[di].GCNLE_item.chunk		; restore item to move
	pop	ds:[di].GCNLE_item.handle
done:
	ret
GenApplicationBringWindowToTop	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenApplicationLowerWindowToBottom -- 
		MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM for GenApplicationClass

DESCRIPTION:	Updates order or GAGCNLT_WINDOWS GCN list.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax 	- MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM

	^lcx:dx	- window to lower to bottom

RETURN:	nothing

ALLOWED TO DESTROY:
	ah, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/92		Initial version

------------------------------------------------------------------------------@
GenApplicationLowerWindowToBottom 	method dynamic GenApplicationClass, \
				MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM

	call	FindWindowListItem			; ds:di = item
	jnc	done					; not found

	push	ds:[di].GCNLE_item.handle		; save item to move
	push	ds:[di].GCNLE_item.chunk

	call	ChunkArrayDelete			; delete item to move
	call	ChunkArrayAppend			; insert item at end
							; (ds:di = new item)
	pop	ds:[di].GCNLE_item.chunk		; restore item to move
	pop	ds:[di].GCNLE_item.handle
done:
	ret
GenApplicationLowerWindowToBottom	endm

;
; pass:		*ds:si = GenApplication
;		^lcx:dx = window
; return:	carry set if found
;			ds:di = GAGCNLT_WINDOWS list item
;		carry clear if not found
;
FindWindowListItem	proc	near
	call	GenApplicationGCNListGetListOfLists	; *ds:ax = list of lists
	tst	ax					; (clears carry)
	jz	done
	mov	di, ax					; *ds:di = list of lists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_WINDOWS
	clc						; don't create list
	call	GCNListFindListInBlock			; *ds:si = list
	jnc	done					; list not found
	call	GCNListFindItemInList			; ds:di = item
							; carry set if found
done:
	ret
FindWindowListItem	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	SendToGenAppGCNList

DESCRIPTION:	Send to GenApp's GCN list

PASS:	*ds:si	- instance data
	es - segment of GenApplicationClass

	ax - message to send
	cx, dx, bp - data to send
	di - GenApp GCN list to send to

RETURN: nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/16/92		Initial version

------------------------------------------------------------------------------@
SendToGenAppGCNList	proc	far
	push	di			; save gcn list
	push	si
	clr	bx			; message for all entries
	clr	si
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	pop	si
	pop	ax
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, ax
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	call	ObjCallInstanceNoLock
	add	sp, size GCNListMessageParams
	ret
SendToGenAppGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UIAppPreventCrashOnShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_META_PTR, etc.  on to spui if spec-built

CALLED BY:	MSG_META_PTR, etc.

PASS:		*ds:si	= UIApplicationClass object
		ds:di	= UIApplicationClass instance data
		es 	= segment of UIApplicationClass
		ax	= MSG_META_PTR, etc.

RETURN:		depends on msg

ALLOWED TO DESTROY:
		cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/10/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if STATIC_PEN_INPUT_CONTROL
;handle MSG_META_QUERY_IF_PRESS_IS_INK elsewhere
UIAppPreventCrashOnShutdown	method	dynamic	UIApplicationClass,
						MSG_META_PTR,
						MSG_META_START_SELECT,
						MSG_META_END_SELECT,
						MSG_META_START_MOVE_COPY,
						MSG_META_END_MOVE_COPY,
						MSG_META_START_FEATURES,
						MSG_META_END_FEATURES,
						MSG_META_START_OTHER,
						MSG_META_END_OTHER,
						MSG_META_DRAG_SELECT,
						MSG_META_DRAG_MOVE_COPY,
						MSG_META_DRAG_FEATURES,
						MSG_META_DRAG_OTHER,
						MSG_META_IMPLIED_WIN_CHANGE,
						MSG_META_RELEASE_FOCUS_EXCL
else
UIAppPreventCrashOnShutdown	method	dynamic	UIApplicationClass,
						MSG_META_PTR,
						MSG_META_START_SELECT,
						MSG_META_END_SELECT,
						MSG_META_START_MOVE_COPY,
						MSG_META_END_MOVE_COPY,
						MSG_META_START_FEATURES,
						MSG_META_END_FEATURES,
						MSG_META_START_OTHER,
						MSG_META_END_OTHER,
						MSG_META_DRAG_SELECT,
						MSG_META_DRAG_MOVE_COPY,
						MSG_META_DRAG_FEATURES,
						MSG_META_DRAG_OTHER,
						MSG_META_IMPLIED_WIN_CHANGE,
						MSG_META_QUERY_IF_PRESS_IS_INK,
						MSG_META_RELEASE_FOCUS_EXCL
endif


	call	GenCheckIfSpecGrown
	jnc	notGrown
	mov	di, offset UIApplicationClass
	GOTO	ObjCallSuperNoLock

notGrown:

;	Eat the event (if it is an ink event, we need to tell people about
;	it).

	cmp	ax, MSG_META_QUERY_IF_PRESS_IS_INK
	mov	ax, mask MRF_PROCESSED
	jne	exit

	mov	cx, IRV_NO_INK
	mov	ax, MSG_GEN_APPLICATION_INK_QUERY_REPLY
	call	ObjCallInstanceNoLock
exit:
	ret
UIAppPreventCrashOnShutdown	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UIAppFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Eat all FUP'ed kbd events

CALLED BY:	MSG_META_FUP_KBD_CHAR

PASS:		*ds:si	= class object
		ds:di	= class instance data
		es 	= segment of class
		ax	= message #

		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code

RETURN:		carry set if character was handled by someone

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UIAppFupKbdChar	method	dynamic	UIApplicationClass, MSG_META_FUP_KBD_CHAR

	;
	; Let help work for UI dialogs
	;
				; generic UI shouldn't know F1 = help, but what
				;	the heck


SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F1				>
DBCS <	cmp	cx, C_SYS_F1						>
	je	callSuper
	stc			; eat it
	ret

callSuper:
	mov	di, offset UIApplicationClass
	GOTO	ObjCallSuperNoLock

UIAppFupKbdChar	endm


COMMENT @----------------------------------------------------------------------

METHOD:		UIAppAlterFTVMCExcl

DESCRIPTION:	Intercept change of focus within UIApp

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_MUP_ALTER_FTVMC_EXCL

	^lcx:dx - object requesting grab/release
	bp	- MetaAlterFTVMCExclFlags

RETURN:	nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/92		Initial version

------------------------------------------------------------------------------@
UIAppAlterFTVMCExcl method dynamic UIApplicationClass,
					MSG_META_MUP_ALTER_FTVMC_EXCL

	;
	; first, call super for normal handling
	;
	push	bp
	mov	di, offset UIApplicationClass
	call	ObjCallSuperNoLock
	pop	bp
	;
	; if doing stuff for something under us, do some more
	;
	test	bp, mask MAEF_NOT_HERE
	jz	moreToDo
done:
	ret			; <-- EXIT HERE ALSO

moreToDo:
	;
	; if focus under UIApp, give it focus
	;
	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	ObjCallInstanceNoLock		; ^lcx:dx = focus
	jcxz	done
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	GOTO	ObjCallInstanceNoLock

UIAppAlterFTVMCExcl endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UIAppNotifyNoFocusWithinNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle no focus

CALLED BY:	MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE

PASS:		*ds:si	= UIApplicationClass object
		ds:di	= UIApplicationClass instance data
		es 	= segment of UIApplicationClass
		ax	= MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/23/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UIAppNotifyNoFocusWithinNode	method	dynamic	UIApplicationClass,
					MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE

	test	ds:[di].GAI_states, mask AS_ATTACHING or \
					mask AS_DETACHING or \
					mask AS_QUIT_DETACHING or \
					mask AS_TRANSPARENT_DETACHING
	jnz	done				; ignore when attaching

	; If not usable, must already be on our way out, so bail.
	;
	test	ds:[di].GI_states, mask GS_USABLE
	jz	done

	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	ObjCallInstanceNoLock		; ^lcx:dx = focus
	tst	cx
	jnz	done
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	UserCallSystem
done:
	ret

UIAppNotifyNoFocusWithinNode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppLostFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lost the focus exclusive, so force down the floating keyboard

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppLostFocusExcl	method	GenApplicationClass, MSG_META_LOST_FOCUS_EXCL
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock

	call	CheckIfFloatingKbdAllowed
	jnc	noFloatingKeyboard

if not STATIC_PEN_INPUT_CONTROL
	call	BringDownKeyboard
endif

noFloatingKeyboard:
	ret
GenAppLostFocusExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gained the focus exclusive, so bring up the floating keyboard
		if it was around before.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppGainedFocusExcl	method	GenApplicationClass, MSG_META_GAINED_FOCUS_EXCL
	uses	es
	.enter

	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock

	;
	; Notify mailbox library if it's loaded
	;
	push	si
	mov	bx, ds:[LMBH_handle]	; bx is a handle belonging to the
					;  current application
	call	IACPPrepareMailboxNotify	; bxcxdx = GeodeToken,
						;  si = SST_MAILBOX
	mov	di, MSN_NEW_FOCUS_APP
	call	SysSendNotification
	pop	si			; *ds:si = self

	mov	ax, TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
	call	ObjVarFindData
	jnc	exit

	segmov	es, dgroup, ax
	tst	es:[displayKeyboard]
	jz	exit

if not STATIC_PEN_INPUT_CONTROL
	clr	ax			;We don't need to bring the window
					; offscreen first, because it is
					; already offscreen
	call	BringUpKeyboard
endif

exit:
	.leave
	ret
GenAppGainedFocusExcl	endp

Common ends
IACPCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPCode_DerefGenDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point ds:di to the generic instance data

CALLED BY:	(INTERNAL) things in IACPCode resource
PASS:		*ds:si	= generic object
RETURN:		ds:di	= Gen master level data
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPCommon_DerefGenDI proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
IACPCommon_DerefGenDI endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppCompleteConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete any and all pending IACP connections, now we're
		fully in application mode.

CALLED BY:	MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS
PASS:		*ds:si	= GenApplication object
		ds:di	= GenApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppCompleteConnections method dynamic GenApplicationClass, MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS
		.enter
		mov	dx, si
		mov	si, ds:[di].GAI_iacpConnects
		tst	si
		jz	done
		mov	bx, cs
		mov	di, offset GACC_callback
		call	ChunkArrayEnum
done:
		.leave
		ret
GenAppCompleteConnections endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GACC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to complete pending IACP connections.

CALLED BY:	(INTERNAL) GenAppCompleteConnections via ChunkArrayEnum
PASS:		ds:di	= GenAppIACPConnection
		*ds:dx	= GenApplication object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	pending messages for the connection will be queued for us.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GACC_callback	proc	far
		uses	cx, dx, bp
		.enter
		mov	cx, ds:[LMBH_handle]
		mov	bp, ds:[di].GAIACPC_connection
		call	IACPFinishConnect
		clc		; keep enumerating
		.leave
		ret
GACC_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppRegisterAsIACPServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a GenApplication object as an IACP server for the
		process's token.

CALLED BY:	(INTERNAL) GenApplication::META_ATTACH
       		    GenApplication::GEN_APPLICATION_IACP_NO_MORE_CONNECTIONS
PASS:		*ds:si	= GenApplication object
		cl	= IACPServerMode
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppRegisterAsIACPServer method dynamic GenApplicationClass,
					MSG_GEN_APPLICATION_IACP_REGISTER
		uses	bp
		.enter
		clr	bp
		call	GenAppRegisterUnregisterCommon

		.leave
		ret
GenAppRegisterAsIACPServer endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppRegisterUnregisterCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call IACP to register or unregister the current application
		as a server for the various tokens it serves. The list of
		tokens is made from the geode's own token, plus any tokens
		found in the ATTR_GEN_APPLICATION_ADDITIONAL_TOKENS vardata
		attached to the GenApplication object
		

CALLED BY:	(INTERNAL) GenAppRegisterAsIACPServer,
			   GenAppIACPUnregister
PASS:		*ds:si	= GenApplication object
		ds:di	= GenApplicationInstance
		bp	= 0 if registering, -1 if unregistering
		cl	= server mode if registering
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppRegisterUnregisterCommon proc	near
		uses	es, di, bx, cx, dx, ax
		class	GenApplicationClass
		.enter
		tst	bp
		jnz	getToken		; if unregistering, don't
						;  bother figuring server flags
		clr	ch
		test	ds:[di].GAI_states, mask AS_SINGLE_INSTANCE
		jnz	checkNoQuery
		ornf	ch, mask IACPSF_MULTIPLE_INSTANCES
checkNoQuery:
	;
	; Look for hint that says whether to set IACPSF_MAILBOX_DONT_ASK_USER
	; 
		mov	ax, HINT_APPLICATION_NO_INBOX_QUERY_WHEN_FOREGROUND_APP
		call	ObjVarFindData
		jnc	getToken
		ornf	ch, mask IACPSF_MAILBOX_DONT_ASK_USER
getToken:
	;
	; Fetch app's token.
	; 
		sub	sp, size GeodeToken
		mov	di, sp
		segmov	es, ss
		mov	ax, GGIT_TOKEN_ID
		clr	bx
		call	GeodeGetInfo
	;
	; Register/unregister app object as server for that token.
	; 
		mov_tr	ax, cx			; ax <- server flags, if
						;  register
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	regOrUnreg
		add	sp, size GeodeToken
	;
	; Now register/unregister for additional tokens, if any. First we
	; need to find the attribute.
	; 
		push	ax
		mov	ax, ATTR_GEN_APPLICATION_ADDITIONAL_TOKENS
		call	ObjVarFindData
		pop	ax
		jnc	done
	;
	; Got it. Figure the end of the entry and point es:di to the first
	; token in it.
	; 
		segmov	es, ds
		VarDataSizePtr	ds, bx, di
		add	di, bx		; di <- end of the entry
		xchg	bx, di		; bx <- end of the entry,
					; es:di <- first token
additionalLoop:
		cmp	di, bx
		je	done
EC <		ERROR_A	INVALID_ADDITIONAL_TOKENS_ATTRIBUTE		>

		call	regOrUnreg

		add	di, size GeodeToken
		jmp	additionalLoop
done:
		.leave
		ret
	;--------------------
	; register or unregister as a server:
	; es:di	= token
	; ^lcx:dx = app object
	; ax	= IACPServerFlags, if registering
	; bp	= non-zero to unregister, zero to register
regOrUnreg:
		tst	bp
		jnz	unregister
		call	IACPRegisterServer
		retn
unregister:
		call	IACPUnregisterServer
		retn
GenAppRegisterUnregisterCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationIACPLostConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with losing an IACP connection when acting as a 
		server. If someone cares about a server going away,
		they'll have to subclass this.

CALLED BY:	MSG_META_IACP_LOST_CONNECTION
PASS:		*ds:si	= GenApplication object
		cx	= IACPSide that shut the connection down
		bp	= IACPConnection that's closed
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationIACPLostConnection method dynamic GenApplicationClass, MSG_META_IACP_LOST_CONNECTION
		.enter
		LOG	ALA_LOST_CONNECTION

		tst	cx		; server shutdown?
		jnz	done			; yes -- we do nothing here.

	;
	; Notify any and all document objects of our loss. This is done by
	; having MSG_GEN_SEND_TO_CHILDREN send MSG_META_IACP_LOST_CONNECTION
	; to all the children of the GenDocumentGroup, which we reach via a
	; MSG_META_SEND_CLASSED_EVENT to that class travelling down the Model
	; hierarchy.
	; 
		push	cx, bp

		push	si
		mov	bx, segment MetaClass	; GEN_SEND_TO_CHILDREN insists
		mov	si, offset MetaClass	;  on a class...
		mov	di, mask MF_RECORD
		call	ObjMessage	; record LOST_CONNECTION

		mov	cx, di
		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		mov	bx, segment GenDocumentGroupClass
		mov	si, offset GenDocumentGroupClass
		mov	di, mask MF_RECORD
		call	ObjMessage	; record GEN_SEND_TO_CHILDREN to send
					;  recorded LOST_CONNECTION to all kids
					;  of the GenDocumentGroup
		pop	si
		mov	cx, di		; cx <- classed event to send
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_MODEL
		call	ObjCallInstanceNoLock	; ship the send-to-kids
		pop	cx, bp
	;
	; Perform standard processing to shut down the connection.
	; 
		call	IACPLostConnection
done:
		.leave
		ret
GenApplicationIACPLostConnection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationIACPShutdownConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish shutting down a connection to us as a server.

CALLED BY:	MSG_META_IACP_SHUTDOWN_CONNECTION
PASS:		*ds:si	= GenApplication object
		bp	= IACPConnection whose client shut down
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	If the application object is in engine mode and this is the
     		last IACP connection, the application will shutdown once
		the object is unregistered as a server.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationIACPShutdownConnection method dynamic GenApplicationClass, MSG_META_IACP_SHUTDOWN_CONNECTION
		.enter
		LOG	ALA_SHUTDOWN_CONNECTION
	;
	; Shutdown the connection itself.
	; 
		call	IACPShutdownConnection
	;
	; Delete it from the array of open connections.
	; 
		call	IACPCommon_DerefGenDI
		push	si
		mov	si, ds:[di].GAI_iacpConnects
		tst	si
		jz	popSIDone
		mov	bx, cs
		mov	di, offset GAISC_callback
		call	ChunkArrayEnum
		pop	si
	;
	; Use common message to deal with having no more connections.
	;
	; We instruct APP_MODE_COMPLETE to send REAL_DETACH to the process,
	; rather than META_QUIT_ACK, as we get called in one of two
	; states: (1) while the app is usable, where it won't do anything
	; anyway, or (2) after the user as quit the app (or we never went
	; to app mode...), in which case there's no need to do the QUIT_ACK,
	; as it's already been done. The process is just waiting for a
	; REAL_DETACH to continue its march into history.
	; 
		clr	dx, bp			; assume no ack OD

		mov	ax, TEMP_GEN_APPLICATION_APP_MODE_COMPLETE_ACK_OD
		call	ObjVarFindData
		jnc	appModeComplete
		movdw	dxbp, ds:[bx]		; use stored ack OD

appModeComplete:
		mov	ax, MSG_GEN_APPLICATION_APP_MODE_COMPLETE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
popSIDone:
	;
	; If no GAI_iacpConnects array, then we've already been through
	; IACP_NO_MORE_CONNECTIONS and are in our death throes, so don't do
	; the APP_MODE_COMPLETE stuff a second time.
	; 
		pop	si
		jmp	done
GenApplicationIACPShutdownConnection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GAISC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to nuke an entry from the iacpConnects
		array.

CALLED BY:	GenApplicationIACPShutdownConnection via ChunkArrayEnum
PASS:		*ds:si	= array
		ds:di	= array element to examine
		bp	= IACPConnection that's being shut down
RETURN:		carry set to stop enumerating (if found and nuked entry)
		carry clear to keep going
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GAISC_callback	proc	far
		.enter
		cmp	ds:[di].GAIACPC_connection, bp
		clc
		jne	done

		call	ChunkArrayDelete
		stc
done:
		.leave
		ret
GAISC_callback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationIACPNoMoreConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we still have no more connections and quit if not.

CALLED BY:	MSG_GEN_APPLICATION_IACP_NO_MORE_CONNECTIONS
PASS:		*ds:si	= GenApplication object
		^ldx:bp	= ack OD to pass.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	GAI_iacpConnects array is freed if MSG_META_QUIT is sent.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationIACPNoMoreConnections method dynamic GenApplicationClass,
				   MSG_GEN_APPLICATION_IACP_NO_MORE_CONNECTIONS
		LOG	ALA_NO_MORE_CONNECTIONS
	;
	; Cope with having been set usable again.
	; 
		test	ds:[di].GI_states, mask GS_USABLE
		jnz	wereBack
		
		LOG	ALA_NMC_NOT_USABLE
	;
	; check if we started switching back to app mode
	;
		test	ds:[di].GAI_states, mask AS_ATTACHING
		jnz	stickingAround
	;
	; Still not usable -- see if any new connections came in.
	; 
		push	si, cx
		mov	ax, MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS
		call	ObjCallInstanceNoLock
		call	IACPCommon_DerefGenDI
		tst	cx
		pop	si, cx
		jz	hasta
		
		LOG	ALA_NMC_HAVE_CONNECTIONS
	;
	; If we got here and AS_QUITTING isn't set, we don't give a damn how
	; many connections there are, someone wants us to go away, so go away
	; we shall.
	; 
		test	ds:[di].GAI_states, mask AS_QUITTING
		jz	hasta
		
stickingAround:
		LOG	ALA_NMC_STICKING_AROUND
	;
	; Since we've another connection or are usable, we should register as a
	; server again; we'll be around a while longer.
	; 
		mov	cl, IACPSM_NOT_USER_INTERACTIBLE
		jmp	reregister
wereBack:
		mov	cl, IACPSM_USER_INTERACTIBLE
reregister:
		mov	ax, MSG_GEN_APPLICATION_IACP_REGISTER
		GOTO	ObjCallInstanceNoLock

hasta:
	;
	; No connections came in while we were unregistering ourselves, so
	; we're gone. Free the array and zero the instance variable (being
	; careful....), then start a MSG_META_QUIT.
	; 
		clr	ax
		xchg	ax, ds:[di].GAI_iacpConnects
		tst	ax
		jz	connectArrayFree
		call	LMemFree
connectArrayFree:
	;
	; Forcibly shutdown any remaining IACP connections of which we are
	; a part. Do this on a flush-queue to cope with a SHUTDOWN_CONNECTION
	; being in the queue at this point.
	; 
		push	cx, dx, bp
		mov	ax, MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di
		mov	dx, bx
		clr	bp
		mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp

	; Flush full input queue before we do "REAL" detach
	;
		LOG	ALA_NMC_DETACHING_PROCESS

EC <	; Make sure we only go through here once...			>
EC <	;								>
EC <		call	IACPCommon_DerefGenDI				>
EC <		test	ds:[di].GAI_states, mask AS_REAL_DETACHING	>
EC <		ERROR_NZ	UI_ERROR_SECOND_REAL_DETACH		>
EC <		ornf	ds:[di].GAI_states, mask AS_REAL_DETACHING	>

	.warn	-private
		mov	ax, MSG_GEN_PROCESS_REAL_DETACH
	.warn 	@private
		call	GeodeGetProcessHandle
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di		; Pass Event in cx
		mov	dx, bx		; handle of block in dx
		clr	bp		; Init next stop
		mov     ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
		GOTO    ObjCallInstanceNoLock	; Call self to start flush

GenApplicationIACPNoMoreConnections endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppCheckMultiDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the application's document control (if it has one)
		supports multiple documents. This relies on some undocumented
		behaviour of MSG_META_SEND_CLASSED_EVENT when performed on
		things in the same thread, namely that it can return
		values.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= GenApplication object
RETURN:		carry set if supports multiple documents
DESTROYED:	bx, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0		; USE THIS WHEN ENGINE-MODE DOCS BECOME ALL THE RAGE
GenAppCheckMultiDocument proc	near
		uses	ax, cx, dx, bp
		.enter
	;
	; Record message to go do the GenDocumentControl
	; 
		push	si
		mov	bx, segment GenDocumentControlClass
		mov	si, offset GenDocumentControlClass
		mov	ax, MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di
		pop	si
	;
	; Call the GDC asking it for its attributes. If there is no object
	; of that class, META_SEND_CLASSED_EVENT should return us ax=0, so
	; we will assume the worst-case, namely a single-document document
	; control.
	; 
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_MODEL
		call	ObjCallInstanceNoLock
		test	ax, mask GDCA_MULTIPLE_OPEN_FILES
		jz	done
		stc
done:
		.leave
		ret
GenAppCheckMultiDocument endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationIACPNewConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with getting a connection from a client.

CALLED BY:	MSG_META_IACP_NEW_CONNECTION
PASS:		*ds:si	= GenApplication object
		cx	= handle of AppLaunchBlock, if any
		dx	= non-zero if launched by IACP, so AppLaunchBlock
			  should already have been handled.
		bp	= IACPConnection just created
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	If there's a document mentioned in the ALB, a message is
     		    sent to the document control to open it.

PSEUDO CODE/STRATEGY:
		If ALB given:
		    - lock it down
		    - if document given:
		        - manufacture a MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
			  message for the document.
			- send the message down the model hierarchy to the
			  GenDocumentGroup object.
		    - unlock the ALB
		    - no need to free the ALB as that's handled by IACP
		      itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenApplicationIACPNewConnection method dynamic GenApplicationClass,
				MSG_META_IACP_NEW_CONNECTION
		.enter

		LOG	ALA_NEW_CONNECTION
	;
	; If no ALB, assume engine mode.
	; 
		mov	bx, cx
		push	bx
		jcxz	engMode
		call	MemLock

		mov	es, ax
		cmp	es:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
		je	appMode
		tst	es:[ALB_appMode]
		jnz	engMode			; not open-app or default, so
						;  treat as engine
appMode:
	;
	; Remember the connection so we don't try and shut down while a
	; SHUTDOWN_CONNECTION is still wandering through the queues...
	; 
		mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	GenAppRecordConnection
	;
	; ALB indicates app mode. If just launched, anything in the ALB should
	; have been taken care of, so we do nothing.
	;
		tst	dx
		jnz 	done

		call	GAINCAppModeConnection
		jmp	done

	;--------------------
engMode:
	;
	; Remember the connection so we don't try and shut down while a
	; SHUTDOWN_CONNECTION is still wandering through the queues...
	; 
		mov	ax, MSG_GEN_PROCESS_OPEN_ENGINE
		call	GenAppRecordConnection

		call	GAINCEngModeConnection
done:
	;
	; Unlock the ALB if it was passed. IACP takes care of freeing it, so
	; we needn't worry about it.
	; 
		pop	bx
		tst	bx
		jz	exit
		call	MemUnlock
exit:
		; Update transparent detach list, as we're now doing something
		; for somebody via IACP.
		;
		call	GenAppUpdateTransparentDetachLists
		.leave
		ret
GenApplicationIACPNewConnection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppIACPGetNumberOfConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the number of connections this application is
		serving.

CALLED BY:	MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS
PASS:		*ds:si	= GenApplication object
RETURN:		cx	= number of open IACP connections application is
			  serving
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppIACPGetNumberOfConnections method dynamic GenApplicationClass, MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS
		.enter
		mov	si, ds:[di].GAI_iacpConnects
		clr	cx
		tst	si
		jz	done
		call	ChunkArrayGetCount
done:
		.leave
		ret
GenAppIACPGetNumberOfConnections endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppRecordConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record an IACP connection made to us as a server. We do
		this for both engine-mode and app-mode connections, so as
		to synchronize our shutdown with the shutdown of both
		types of connections.

CALLED BY:	(INTERNAL) GenApplicationIACPNewConnection
PASS:		*ds:si	= GenApplication object
		ax	= app mode method
		bp	= IACPConnection
RETURN:		nothing
DESTROYED:	di, cx, ax
SIDE EFFECTS:	app object may move, and GAI_iacpConnects may be changed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppRecordConnection proc	near
		class	GenApplicationClass
		uses	bx, cx
		.enter
		push	ax			; save app mode on stack
		call	IACPCommon_DerefGenDI
		tst	ds:[di].GAI_iacpConnects
		jnz	haveConnectsArray
	;
	; Create array to hold engine-mode connection identifiers.
	; 
		push	si
		mov	bx, size GenAppIACPConnection
		mov	cx, size ChunkArrayHeader
		clr	si
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
		mov	ax, si
		pop	si
		call	IACPCommon_DerefGenDI
		mov	ds:[di].GAI_iacpConnects, ax

haveConnectsArray:
	;
	; Add this connection to the end of the array.
	; 
		push	si
		mov	si, ds:[di].GAI_iacpConnects
		call	ChunkArrayAppend
		mov	ds:[di].GAIACPC_connection, bp
		pop	si
		pop	ds:[di].GAIACPC_appMode	; store app mode
		.leave
		ret
GenAppRecordConnection endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppIACPUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister as a server for the application token.

CALLED BY:	MSG_GEN_APPLICATION_IACP_UNREGISTER
PASS:		*ds:si	= GenApplication object
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppIACPUnregister method dynamic GenApplicationClass, MSG_GEN_APPLICATION_IACP_UNREGISTER
		.enter
		mov	bp, -1
		call	GenAppRegisterUnregisterCommon
		.leave
		ret
GenAppIACPUnregister endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppIACPShutdownAllConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut down all IACP connections to which this application
		is a party, either server-wise or client-wise.

CALLED BY:	MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS
PASS:		*ds:si	= GenApplication object
RETURN:		cx, dx, bp - unchanged
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppIACPShutdownAllConnections method dynamic GenApplicationClass, MSG_GEN_APPLICATION_IACP_SHUTDOWN_ALL_CONNECTIONS
		uses	cx, dx
		.enter
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	IACPShutdownAll
		.leave
		ret
GenAppIACPShutdownAllConnections endm

IACPCommon ends
IACPCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GAINCAppModeConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with getting a new application-mode IACP connection

CALLED BY:	(INTERNAL) GenApplicationIACPNewConnection
PASS:		es	= locked AppLaunchBlock
		bx	= handle of AppLaunchBlock
		*ds:si	= GenApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GAINCAppModeConnection proc	far
		class	GenApplicationClass
		.enter
		call	IACPCode_DerefGenDI
		test	ds:[di].GAI_states, mask AS_DETACHING or \
						mask AS_QUIT_DETACHING
		jz	notDetaching
recordALB::
		call	GAINCRecordALBIfAppropriate
		jmp	done
notDetaching:
	;
	; Record the ALB until QUIT_AFTER_UI to avoid ugliness.
	; 

if (0)	; Let's not do this since many apps put up dialogs when quitting
	; and won't come forward if we do this. - Joon (7/6/94)
	;
		test	ds:[di].GAI_states, mask AS_QUITTING
		jz	notQuitting
		test	ds:[di].GI_states, mask GS_USABLE
		jnz	recordALB
notQuitting:
endif

	;
	; Make sure we're in app mode.
	; 
		call	GenAppSwitchToAppMode
		jnc	finishConnect
	;
	; Switching now. => don't need to worry about document in ALB, as
	; it'll be fielded when we receive MSG_META_ATTACH from the process.
	; 
done:
		.leave
		ret

finishConnect:
	;
	; If a document was passed, let the document group know about it.
	; 
		push	bp
		clr	bp
		clr	cx		; do nothing if no doc
		call	GenAppNotifyModelIfDoc
		pop	bp
	;
	; Release any messages that might, for some reason, be held in the
	; connection.
	; 
		call	IACPCode_DerefGenDI
		test	ds:[di].GAI_states, mask AS_ATTACHING
		jnz	done		; will be handled when OPEN_COMPLETE
					;  arrives

		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	IACPFinishConnect
		jmp	done
GAINCAppModeConnection endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPCode_DerefGenDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point ds:di to the generic instance data

CALLED BY:	(INTERNAL) things in IACPCode resource
PASS:		*ds:si	= generic object
RETURN:		ds:di	= Gen master level data
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPCode_DerefGenDI proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
IACPCode_DerefGenDI endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GAINCRecordALBIfAppropriate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we don't have a saved ALB yet, save this one for lazarus
		when the detach is complete.

CALLED BY:	(INTERNAL) GAINCAppModeConnection
PASS:		*ds:si	= GenApplication object
		^hbx, es= locked AppLaunchBlock
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The only time we get an app-mode connection while in engine
		mode is when the IACP system has decided we need to be in
		app mode, so we always save the ALB...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GAINCRecordALBIfAppropriate proc near
		class	GenApplicationClass
		uses	bx
		.enter
	;
	; If we've already got an ALB saved, the user is likely just being
	; impatient, so toss this one.
	; 
		push	bx
		mov	ax, TEMP_GEN_APPLICATION_SAVED_ALB
		call	ObjVarFindData
		pop	bx
		jc	done
	;
	; Duplicate the ALB (it's going to be freed when we return) and store
	; its handle in vardata for APP_MODE_COMPLETE to cope with.
	; 
		call	IACPDuplicateALB
		mov	dx, bx
		mov	ax, TEMP_GEN_APPLICATION_SAVED_ALB
		mov	cx, size hptr
		call	ObjVarAddData
		mov	ds:[bx], dx

	; Finally, put up any necessary "Activating" dialog to cover the
	; period here where we're finishing detaching to engine mode &
	; then AppLarus'ing.  Update it to include the icon as well, since
	; known.
	;
		; dx = AppLaunchBlock (not a MemRef reference)
		;
		push	bp
		push	dx
		mov	ax, MSG_GEN_FIELD_ACTIVATE_INITIATE
		call	GenCallParent
		pop	dx
		mov	bx, ds:[LMBH_handle]
		call	MemOwner
		mov	cx, bx
		mov	ax, MSG_GEN_FIELD_ACTIVATE_UPDATE
		call	GenCallParent
		pop	bp
done:
		.leave
		ret
GAINCRecordALBIfAppropriate endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppSwitchToAppMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change ourselves into application mode if necessary.

CALLED BY:	(INTERNAL) GAINCAppModeConnection
PASS:		*ds:si	= GenApplication object
		bx	= handle of AppLaunchBlock
RETURN:		carry set if mode switch in-progress.
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppSwitchToAppMode proc	far
		class	GenApplicationClass
		uses	bp, si, es
		.enter
		LOG	ALA_SWITCH_TO_APP_MODE
		call	MemLock
		mov	es, ax
	;
	; If app is to be opened for user, do so.
	;
	; {
		test	es:[ALB_launchFlags], mask ALF_OPEN_FOR_IACP_ONLY
		jnz	afterOpenForUser

	; Clear bit which in GAI_launchFlags really means ALF_NOT_OPEN_FOR_USER,
	; as we are now, indeed, being requested to be open for the user's
	; general use.
	;
		LOG	ALA_STAM_FOR_USER
		call	IACPCode_DerefGenDI
		andnf	ds:[di].GAI_launchFlags, not mask ALF_OPEN_FOR_IACP_ONLY

	; Add "ABORT_QUIT" flag, so that if this is called after the last
	; requested QUIT, but before detach, the quit can be aborted.
	; (Cleared at start of any quit)
	;
		test 	ds:[di].GAI_states, mask AS_QUITTING
		jz	afterOpenForUser
		push	bx
		mov	ax, TEMP_GEN_APPLICATION_ABORT_QUIT
		clr	cx
		call	ObjVarAddData
		pop	bx

afterOpenForUser:
		call	MemUnlock
	; }
	;
	; See if we're still not in application mode.
	; 
		call	IACPCode_DerefGenDI
		test	ds:[di].GI_states, mask GS_USABLE
		jnz	bringToTop

		test	ds:[di].GAI_states, mask AS_ATTACHING
		jnz	inProgress	; => we're working on it, so don't
					;  flog a dead horse.
	;
	; 3/11/93: set AS_ATTACHING a little early, so if we shut down a
	; connection between when we decide to switch to app mode and and
	; when the process thread sends us a MSG_META_ATTACH, we don't decide
	; to exit. -- ardeb.
	; 
		LOG	ALA_STAM_SWITCHING
		ornf	ds:[di].GAI_states, mask AS_ATTACHING
	;
	; Still not in app mode, so send ALB over to our process to
	; switch ourselves into it.
	; 
		call	IACPDuplicateALB
		mov	ax, 1
		call	MemInitRefCount	; set ref count to 1 so we can follow
					;  our message with a ref-count
					;  decrement to cause the block to be
					;  freed.

		push	bx

		mov	dx, bx			; dx <- ALB handle

		clr	cx			; AppAtachFlags
		mov	bx, dx
		call	MemLock
		mov	es, ax
		tst	es:[ALB_dataFile][0]
		jz	changeToAppMode
		ornf	cx, mask AAF_DATA_FILE_PASSED
		LOG	ALA_STAM_HAVE_DOCUMENT
changeToAppMode:
		call	MemUnlock

		mov	ax, MSG_GEN_PROCESS_TRANSITION_FROM_ENGINE_TO_APPLICATION_MODE
		call	GeodeGetProcessHandle
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Follow that with a MSG_META_DEC_BLOCK_REF_COUNT on the ALB so it
	; gets freed when the OPEN_APPLICATION is complete (this is normally
	; handled by UI_Attach...)
	; 
		pop	cx
		clr	dx
		mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		call	ObjMessage
inProgress:
		stc
done:
		.leave
		ret
bringToTop:
	;
	; Bring to the top, but only if the server has requested it.
	; (6/ 2/95 cbh)
	;
		test	es:ALB_launchFlags, mask ALF_DO_NOT_OPEN_ON_TOP or \
					    mask ALF_OPEN_IN_BACK
		jnz	done				;c=0

	;
	; Bring the application to the top of the heap, as it were. Use
	; the task-selected meta-message to take care of unminimizing and
	; other gross things.
	; 
		LOG	ALA_STAM_BRING_TO_TOP

		mov	ax, MSG_META_NOTIFY_TASK_SELECTED
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_GEN_BRING_TO_TOP
		call	ObjCallInstanceNoLock
		clc
		jmp	done
GenAppSwitchToAppMode endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GAINCEngModeConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a connection that's in engine mode.

CALLED BY:	(INTERNAL) GenApplicationIACPNewConnection
PASS:		es	= locked AppLaunchBlock
		bx	= handle of AppLaunchBlock
		bp	= IACPConnection
		*ds:si	= GenApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GAINCEngModeConnection proc	far
		class	GenApplicationClass
		.enter
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	IACPFinishConnect

if 0
	;
	; If ALB is 0, there's no document to deal with.
	; XXX: Right around here is where we might notify the model that we
	; want to open the document in the ALB, but this seems very problematic
	; as we look at all the things that can go wrong. In any case, we'd
	; only want to do it if the DC can support multiple documents.
	; 
		tst	bx
		jz	done
done:
endif
		.leave
		ret
GAINCEngModeConnection endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppNotifyModelIfDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the GenDocumentGroup object via the Model hierarchy
		if there's a document in the ALB.

CALLED BY:	(INTERNAL) GenApplication::META_IACP_NEW_CONNECTION
PASS:		es	= locked AppLaunchBlock
		*ds:si	= GenApplication object
		cx	= TRUE if should open default document if no doc
			  in ALB
		bp	= IACPConnection to tell document, 0 if opened for
			  user editing.
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppNotifyModelIfDoc proc	far
		class	GenApplicationClass
		uses	bx
		.enter
		tst	es:[ALB_dataFile][0]
		jz	checkDefaultDoc
	;
	; There is. Copy the relevant pieces from the ALB to a 
	; DocumentCommonParams structure on the stack, for eventual passing
	; to the GenDocumentGroup.
	; 
		push	bp
		push	ds, si
		sub	sp, size DocumentCommonParams

		call	GenAppInitDocumentCommonParams

	;
	; Record a message to the GenDocumentGroupClass object, with stack
	; data...
	; 
		mov	bp, sp
		mov	dx, size DocumentCommonParams
		mov	bx, segment GenDocumentGroupClass
		mov	si, offset GenDocumentGroupClass
		mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
		mov	di, mask MF_RECORD or mask MF_STACK
		call	ObjMessage
	;
	; Clear the stack.
	; 
		add	sp, size DocumentCommonParams
	;
	; Send the recorded message down the Model hierarchy by sending
	; MSG_META_SEND_CLASSED_EVENT to ourselves.
	; 
		pop	ds, si
sendCommon:
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_MODEL
		mov	cx, di		; cx <- event handle
		call	ObjCallInstanceNoLock
		pop	bp
done:
		.leave
		ret

checkDefaultDoc:
		jcxz	done
		
		push	bp
		push	si
		mov	ax, MSG_GEN_DOCUMENT_CONTROL_OPEN_DEFAULT_DOC
		mov	bx, segment GenDocumentControlClass
		mov	si, offset GenDocumentControlClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	si
		jmp	sendCommon
GenAppNotifyModelIfDoc endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppInitDocumentCommonParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a DocumentCommonParams structure from an
		AppLaunchBlock

CALLED BY:	(INTERNAL) GenAppNotifyModelIfDoc,
PASS:		es	= locked AppLaunchBlock
		bp	= IACPConnection
		ss:sp -> DocumentCommonParams to initialize
RETURN:		nothing
DESTROYED:	es, di, si, dx, cx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppInitDocumentCommonParams proc	near	params:DocumentCommonParams
connection	local	IACPConnection	push bp
		uses	ds
		.enter
		; store IACPConnection here before we nuke bp

		mov	ax, ss:[connection]
		lea	di, ss:[params]
		mov	bp, di
		mov	ss:[di].DCP_connection, ax

		segmov	ds, es
		segmov	es, ss
		
	CheckHack <offset DCP_name eq 0>
		mov	si, offset ALB_dataFile
		mov	cx, size DCP_name
		rep	movsb

	CheckHack <offset DCP_diskHandle eq DCP_name+size DCP_name>
		mov	si, offset ALB_diskHandle
		movsw

	CheckHack <offset DCP_path eq DCP_diskHandle+size DCP_diskHandle>
		mov	si, offset ALB_path
		mov	cx, size ALB_path
		rep	movsb
		mov	ss:[bp].DCP_flags, 0
		mov	ss:[bp].DCP_docAttrs, 0
	;
	; If we're printing, pass that fact on to document
	;
		test	ds:[ALB_launchFlags], mask ALF_OPEN_FOR_IACP_ONLY
		jz	afterPrintFlag
		ornf	ss:[bp].DCP_flags, mask DOF_OPEN_FOR_IACP_ONLY
afterPrintFlag:
	;
	; If document is under SP_TEMPLATE, then open as template.
	;
		segmov	es, ds
		mov	dx, es:[ALB_diskHandle]
		mov	di, offset ALB_path	; path 2 => DX, ES:DI
		clr	ax
		mov	ds, ax
		mov	cx, SP_TEMPLATE		; path 1 => CX, DS:SI
		call	FileComparePaths
		cmp	al, PCT_SUBDIR		; = PCT_EQUAL or PCT_SUBDIR ?
		ja	done
		ornf	ss:[bp].DCP_flags, mask DOF_FORCE_TEMPLATE_BEHAVIOR
done:
		.leave
		ret
GenAppInitDocumentCommonParams endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GenAppIACPCloseReopenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Requests that this application close the file.

CALLED BY:	IACPSendMessage, usually

PASS:		typical method stuff PLUS:

		bp - IACPConnection requesting the file closure.

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 feb 1995	initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppIACPCloseReopenFile	method GenApplicationClass,
				MSG_META_IACP_ALLOW_FILE_ACCESS,
				MSG_META_IACP_NOTIFY_FILE_ACCESS_FINISHED
						
		uses	ax, cx, dx, bp
		.enter
	;
	; Look for the "quitter" hint.
	;
		mov_tr	cx, ax
		mov	ax, HINT_APPLICATION_QUIT_ON_IACP_ALLOW_FILE_ACCESS
		call	ObjVarFindData
		jnc	sendToDocument

	;
	; This application is a quitter (i.e., it quits when it gets
	; a MSG_META_IACP_ALLOW_FILE_ACCESS), so if that's the message
	; being sent, then quit, otherwise, do nothing.
	;
		cmp	cx, MSG_META_IACP_ALLOW_FILE_ACCESS
		jne	done

	;
	; Send the app a detach, as that's been suggested as A Good Thing.
	;
		mov	ax, MSG_META_TRANSPARENT_DETACH
		call	ObjCallInstanceNoLock
		jmp	done

sendToDocument:
	;
	;  The default behavior is to send this thing to the document, so
	;  we'll encapsulate a MSG_GEN_DOCUMENT_CLOSE_FILE and send it off.
	;

		mov	ax, MSG_GEN_DOCUMENT_REOPEN_FILE
		cmp	cx, MSG_META_IACP_ALLOW_FILE_ACCESS
		jne	recordMsg
		mov	ax, MSG_GEN_DOCUMENT_CLOSE_FILE

recordMsg:
		push	si
		mov	bx, segment GenDocumentClass
		mov	si, offset GenDocumentClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	si

	;
	;  Send the thing off to some GenDocumentClass, if any.
	;
		mov	cx, di				;cx <- encaps'd msg.
		mov	dx, TO_MODEL
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		call	ObjCallInstanceNoLock

done:
		.leave
		ret
GenAppIACPCloseReopenFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppMetaIACPProcessMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pull gross hack to get MSG_META_IACP_ALLOW_FILE_ACCESS to
		work.

CALLED BY:	MSG_META_IACP_PROCESS_MESSAGE
PASS:		*ds:si	= GenApplicationClass object
		cx - handle of recorded message the other side of the
		     connection is actually sending.
		dx - TravelOption or -1. If -1, cx should be dispatched
		     via MessageDispatch, else it should be delivered by
		     sending MSG_META_SEND_CLASSED_EVENT to yourself.
		bp - handle of recorded message to send when the message in cx
		     has been handled. If 0, then there's no completion
		     message to send.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	4/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppMetaIACPProcessMessage	method dynamic GenApplicationClass, 
					MSG_META_IACP_PROCESS_MESSAGE
		.enter
	;
	; Handle MSG_META_IACP_ALLOW_FILE_ACCESS specially.
	;
		push	cx			; #1
		push	si			; #2
		mov	bx, cx			; bx <- event
		call	ObjGetMessageInfo	; ax <- method, cx:si <- junk
		pop	si			; #2
		cmp	ax, MSG_META_IACP_ALLOW_FILE_ACCESS
		jne	processMessage

	;
	; Add some vardata with the completion message in it.
	;
		tst	bp
		jz	processMessage
		mov	cx, size hptr
		mov	ax, TEMP_GEN_APPLICATION_CLOSE_FILE_ACK_EVENT
		call	ObjVarAddData		; ds:bx <- vardata space (hptr)
		mov	{hptr} ds:[bx], bp

	;
	; Now fake out IACPProcessMessage into thinking that there's
	; no completion message to send.  We'll send it along later,
	; once we're notified by the document obj that the file's been
	; closed.
	;
		clr	bp

processMessage:
		pop	cx			; #1
		call	IACPProcessMessage

		.leave
		ret
GenAppMetaIACPProcessMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppCloseFileAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the TEMP_BLAH_BLAH vardata is present; if so
		do the 2nd half of IACPProcessMessage so that the
		completion message gets sent.

CALLED BY:	MSG_GEN_APPLICATION_CLOSE_FILE_ACK
PASS:		*ds:si	= GenApplicationClass object
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	4/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppCloseFileAck	method dynamic GenApplicationClass, 
					MSG_GEN_APPLICATION_CLOSE_FILE_ACK
		.enter
	;
	; If the vardata doesn't exist, then there's nothing for us to
	; do.
	;
		mov	ax, TEMP_GEN_APPLICATION_CLOSE_FILE_ACK_EVENT
		call	ObjVarFindData		; ds:bx <- event
		jnc	exit

	;
	; Remove the vardata so event doesn't get sent again.
	;
		mov	bx, {hptr} ds:[bx]	; bx <- event to send
		call	ObjVarDeleteData

	;
	; Send off the IACP completion message.
	;
EC <		call	ECCheckEventHandle				>
		mov	di, mask MF_FORCE_QUEUE
		call	MessageDispatch

exit:
		.leave
		ret
GenAppCloseFileAck		endm

IACPCode	ends

