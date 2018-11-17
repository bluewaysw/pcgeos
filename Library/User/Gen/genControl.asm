COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenControlClass		Control object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/91		Initial version

DESCRIPTION:
	This file contains routines to implement the Interaction class

Interaction with various GCN lists:

ATTACH
    - <assert GCBF_IS_ON_ACTIVE_LIST is set>
    - if GCBF_ALWAYS_INTERACTABLE then set interactability
    - if GCBF_ALWAYS_ON_GCN_LIST then add to GCN lists
DETACH
 - DestroyGeneratedUI
   - Destroy normal/toolbox UI, remove from active list if on temporarily

SPEC_BUILD / GENERATE_{TOOLBOX}_UI
 - Temporarily add to active list if not there already

SPEC_UNBUILD
 - DestroyGeneratedUI
   - Destroy normal/toolbox UI, remove from active list if on temporarily

SPEC_SET_USABLE
 - add object to appropriate lists (active, self-load options, startup
   load options)

SPEC_SET_NOT_USABLE
 - DestroyGeneratedUI
   - Destroy normal/toolbox UI, remove from active list if on temporarily
 - remove object from appropriate lists (active, self-load options, startup
   load options)

	$Id: genControl.asm,v 1.1 97/04/07 11:44:46 newdeal Exp $

-------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenControlClass

UserClassStructures	ends

;---------------------------------------------------

GCCommon segment resource

DerefVardata	proc	far	uses ax
	.enter
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
EC <	test	{word} ds:[bx].VEDP_dataType, mask VDF_SAVE_TO_STATE	>
EC <	ERROR_NZ	TEMP_INSTANCE_IS_MARKED_SAVE_TO_STATE		>
	.leave
	ret

DerefVardata	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetDupInfo

DESCRIPTION:	Call self to get info

PASS:
	*ds:si - gen control object
	ss:bp - inherited variables

RETURN:
	none

------------------------------------------------------------------------------@
GetDupInfo	proc	far	uses ax, cx, dx, bp
dupinfo		local	GenControlBuildInfo
	.enter inherit far
EC <	mov	cx, sp							>
EC <	cmp	bp, cx							>
EC <	ERROR_BE	GEN_CONTROL_INTERNAL_ERROR			>

	; call ourself to get the group to duplicate

	mov	cx, ss
	lea	dx, dupinfo			;cx:dx = structure to fill in

EC <	push	ds, si							>
EC <	movdw	dssi, cxdx						>
EC <	call	ECCheckBounds						>
EC <	add	si, size GenControlBuildInfo-1				>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>

	mov	ax, MSG_GEN_CONTROL_GET_INFO
	call	ObjCallInstanceNoLock

	.leave
	ret

GetDupInfo	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockTableESDI

DESCRIPTION:	Lock the table block

PASS:
	ss:bp - inherited variables
	di - offset of fptr inside dupinfo

RETURN:
	es - table block
	di - child list

------------------------------------------------------------------------------@
LockTableESDI	proc	far	uses ax, bx
dupinfo		local	GenControlBuildInfo
	.enter inherit far

	mov	bx, ({dword} dupinfo[di]).segment
	call	MemLockFixedOrMovable
	mov	es, ax
	mov	di, ({dword} dupinfo[di]).offset

	.leave
	ret

LockTableESDI	endp

;---

UnlockTableDI	proc	far	uses bx
dupinfo		local	GenControlBuildInfo
	.enter inherit far

	mov	bx, ({dword} dupinfo[di]).segment
	call	MemUnlockFixedOrMovable

	.leave
	ret

UnlockTableDI	endp


;---

GC_SendToSuper	proc	far
	mov	di, segment GenControlClass
	mov	es, di
	mov	di, offset GenControlClass
	GOTO	ObjCallSuperNoLock
GC_SendToSuper	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlNotifyWithDataBlock -- MSG_META_NOTIFY_WITH_DATA_BLOCK
							for GenControlClass

DESCRIPTION:	Handle notification by doing some preprocessing for
		the controller object

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx.dx - change type ID
	bp - handle of block with NotifyTextChange structure

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 2/91		Initial version

------------------------------------------------------------------------------@
GenControlNotifyWithDataBlock	method dynamic	GenControlClass,
						MSG_META_NOTIFY_WITH_DATA_BLOCK,
						MSG_META_NOTIFY

	dupinfo		local	GenControlBuildInfo

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	.enter		

	; look for a recognized change type

	push	cx
	push	ax

	mov_tr	ax, cx				;ax = manufacturer ID
	call	GetDupInfo
	mov	cx, dupinfo.GCBI_notificationCount
	jcxz	sendToSuper
	mov	di, offset GCBI_notificationList
	call	LockTableESDI

searchLoop:
	cmp	ax, es:[di].NT_manuf
	jnz	next
	cmp	dx, es:[di].NT_type
	jz	found
next:
	add	di, size NotificationType
	loop	searchLoop

unlockSendToSuper:
	mov	di, offset GCBI_notificationList
	call	UnlockTableDI

sendToSuper:
	pop	ax
	pop	cx

	.leave

	pop	di
	call	ThreadReturnStackSpace

	GOTO	GC_SendToSuper

found:
	mov_tr	cx, ax				;cx:dx = change type ID

	; if this is a null notification from a list other than the list
	; which gave us a null notification then ignore it

	call	DerefVardata
	test	dupinfo.GCBI_flags, mask GCBF_ALWAYS_UPDATE
	jnz	notNull
	tst	<{word} ss:[bp]>
	jnz	notNull
	cmpdw	dxcx, ds:[bx].TGCI_activeNotificationList
	jnz	unlockSendToSuper		;different list, bail out
notNull:
	movdw	ds:[bx].TGCI_activeNotificationList, dxcx

	; OK, we're really updating.  We need to update both enable/disable
	; status, & the actual data.  In the past, we always did this enable/
	; disable first, then status.  While this worked just fine, it resulted
	; in unecessary work caused by enabling the gadgets & then mucking
	; with them.  By mucking first while disabled, we should be able to
	; reduce the overall amount of work, as foucus, mouse grabs, etc
	; don't have to be tampered with in this state . -- Doug 1/93

	tst	<{word} ss:[bp]>
	jnz	blockPresent

;blockNotPresent:

	call	EnableDisableCommon	; Disable first,
	call	UpdateCommon		; then update
	jmp	unlockSendToSuper

blockPresent:
; Incorrect assumption??? rmsg isn't happy...
;	call	UpdateCommon		; Update first,
;	call	EnableDisableCommon	; then enable

	call	EnableDisableCommon
	call	UpdateCommon

	jmp	unlockSendToSuper

GenControlNotifyWithDataBlock	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EnableDisableCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform enable/disable update portion of
		GenControlNotifyWithDataBlock

CALLED BY:	INTERNAL
		GenControlNotifyWithDataBlock
PASS:		*ds:si	- GenControl object
		ss:bp	- GenControlBuildInfo
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Pulled out into seperate routine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableDisableCommon	proc	near
	class	GenControlClass
	.enter inherit GenControlNotifyWithDataBlock

	push	cx, dx

	; set enabled or not depending of whether a block was passed

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	al, ds:[di].GI_states		;not current enabled state
	mov	cx, MSG_GEN_SET_ENABLED
	tst	<{word} ss:[bp]>
	jnz	common
	xor	al, mask GS_ENABLED
	mov	cx, MSG_GEN_SET_NOT_ENABLED
common:
	test	dupinfo.GCBI_flags, mask GCBF_CUSTOM_ENABLE_DISABLE
	jnz	forceIt
	test	al, mask GS_ENABLED		;if no state change then
	jnz	afterEnable			;bail
forceIt:
	mov	dl, VUM_NOW
	push	bp
	mov	ax, MSG_GEN_CONTROL_ENABLE_DISABLE
	call	ObjCallInstanceNoLock
	pop	bp
afterEnable:

	pop	cx, dx

	.leave
	ret
EnableDisableCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			UpdateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
		GenControlNotifyWithDataBlock
PASS:		*ds:si	- GenControl object
		ss:bp	- GenControlBuildInfo
		cx	- manufacturer
		dx	- change type
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Pulled out into seperate routine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateCommon	proc	near
	class	GenControlClass
	.enter inherit GenControlNotifyWithDataBlock

	test	dupinfo.GCBI_flags, mask GCBF_ALWAYS_UPDATE
	jnz	sendUpdate
	tst	<{word} ss:[bp]>
	jz	noUpdate
sendUpdate:

	push	cx, dx, bp

	; push parameters for MSG_GEN_CONTROL_UPDATE_UI

	call	DerefVardata

	; Save off state of interactableFlags at this update, so that
	; we can avoid redundant updates should the gadgets become not
	; interactable, then interactable again, before another update.
	;
	mov	ax, ds:[bx].TGCI_interactableFlags
	mov	ds:[bx].TGCI_upToDate, ax

	; Get GenControlInteractableFlags, so that we can figure out whether
	; to pass actual features available, or NULL, indicating none of
	; them need updating.
	;
	test	dupinfo.GCBI_flags, mask GCBF_ALWAYS_UPDATE
	jnz	10$
	mov	ax, ds:[bx].TGCI_childBlock
	ornf	ax, ds:[bx].TGCI_toolBlock
	jz	abortUpdate
10$:

	mov	di, ds:[bx].TGCI_interactableFlags

	mov	ax, ds:[bx].TGCI_toolboxFeatures ;toolbox features
	test	di, mask GCIF_TOOLBOX_UI
	jnz	haveToolBoxFeaturesToUpdate
	clr	ax
haveToolBoxFeaturesToUpdate:

	test	di, mask GCIF_NORMAL_UI
	mov	di, ds:[bx].TGCI_features	;toolbox features
	jnz	haveNormalFeaturesToUpdate
	clr	di
haveNormalFeaturesToUpdate:
	test	dupinfo.GCBI_flags, mask GCBF_ALWAYS_UPDATE
	jnz	doUpdate
	tst	ax				;if toolbox features visible
	jnz	doUpdate			;then update
	tst	di
	jz	abortUpdate
doUpdate:

	push	ds:[bx].TGCI_toolBlock
	push	ds:[bx].TGCI_childBlock		;child block
	push	ax				;toolbox features to update
	push	di				;normal features to update

	push	ss:[bp]				;data block
	push	dx				;change type
	push	cx				;manufacturer
	mov	bp, sp
	mov	ax, MSG_GEN_CONTROL_UPDATE_UI
	call	ObjCallInstanceNoLock
	add	sp, size GenControlUpdateUIParams
abortUpdate:

	pop	cx, dx, bp

noUpdate:

	.leave
	ret
UpdateCommon	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlEnableDisable -- MSG_GEN_CONTROL_ENABLE_DISABLE
							for GenControlClass

DESCRIPTION:	Enable or disable the controller pieces that are interactable

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx - message: MSG_GEN_SET_ENABLED or MSG_GEN_SET_NOT_ENABLED
	dl - VisualUpdateMode

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
	Tony	11/20/91		Initial version

------------------------------------------------------------------------------@
GenControlEnableDisable	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_ENABLE_DISABLE

	; if this controller is marked as having custom enable/disable
	; behavior then bail

	push	ax, cx, dx
	call	GetControllerFlags
	test	ax, mask GCBF_CUSTOM_ENABLE_DISABLE
	jnz	afterController

	; get GenControlInteractableFlags, in di

	call	DerefVardata
	mov	di, ds:[bx].TGCI_interactableFlags

	mov_tr	ax, cx			; get enable/disable message in ax

	; Update enable/disable status for controller object itself.  Since
	; enable/disable is hierarchical, and the normal UI is generically
	; below the controller, we'll need to do this if either the 
	; controller itself or the normal UI is interactable.	-- Doug
	;
	test	di, mask GCIF_CONTROLLER or mask GCIF_NORMAL_UI \
			or mask GCIF_TOOLBOX_UI
	jz	afterController
	call	ObjCallInstanceNoLock	; enable/disable ourself
afterController:
	pop	ax, cx, dx

	call	SendToSuperIfFlagSet

	ret

GenControlEnableDisable	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenControlSendToOutputStack

DESCRIPTION:	Utility routine to send a message to the output of a
		controller.

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - message
	ss:bp - data
	dx - data size
	bx:di - class

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/11/91		Initial version

------------------------------------------------------------------------------@
GenControlSendToOutputStack	proc	far
	clc
	jmp	OutputStackCommon

GenControlSendToOutputStack	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenControlSendToOutputStack

DESCRIPTION:	Utility routine to send a message to the output of a
		controller.

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - message
	cx, dx, bp - data
	bx:di - class

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/11/91		Initial version

------------------------------------------------------------------------------@
GenControlSendToOutputRegs	proc	far
	clc
	jmp	OutputRegsCommon

GenControlSendToOutputRegs	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenControlOutputActionStack

DESCRIPTION:	Utility routine to call MSG_GEN_OUTPUT_ACTION.  This is used
		when a controller needs to send out an action.  This handles
		GenAttrs such as GA_SIGNAL_INTERACTION_COMPLETE,
		GA_INITIATES_BUSY_STATE and GA_INITIATES_INPUT_HOLD_UP.

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - message
	ss:bp - data
	dx - data size
	bx:di - class

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/11/91		Initial version

------------------------------------------------------------------------------@

GenControlOutputActionStack	proc	far
	stc

OutputStackCommon	label	far
	push	di, bp
	push	si
	mov	si, di
	mov	di, mask MF_RECORD or mask MF_STACK
	jmp	OutputActionCommon

GenControlOutputActionStack	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenControlOutputActionRegs

DESCRIPTION:	Utility routine to call MSG_GEN_OUTPUT_ACTION.  This is used
		when a controller needs to send out an action.  This handles
		GenAttrs such as GA_SIGNAL_INTERACTION_COMPLETE,
		GA_INITIATES_BUSY_STATE and GA_INITIATES_INPUT_HOLD_UP.

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - message
	cx, dx, bp - data
	bx:di - class

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/11/91		Initial version

------------------------------------------------------------------------------@
GenControlOutputActionRegs	proc	far
	stc

OutputRegsCommon	label	far

	push	di, bp
	push	si
	mov	si, di
	mov	di, mask MF_RECORD

	; carry - set if action

OutputActionCommon	label	far
	class	GenControlClass

	pushf
	call	ObjMessage		;di = event handle
	popf
	mov	bp, di
	pop	si

EC <	pushf								>
EC <	push	es							>
EC <	mov	di, segment GenControlClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenControlClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	ROUTINE_REQUIRES_GEN_CONTROL_OBJECT_AS_INPUT	>
EC <	pop	es							>
EC <	popf								>
	push	ax, cx, dx
	pushf
	jnc	10$
	call	GenProcessGenAttrsBeforeAction
10$:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	cxdx, ds:[di].GCI_output
	mov	ax, MSG_GEN_OUTPUT_ACTION
	call	ObjCallInstanceNoLock
	popf
	jnc	20$
	call	GenProcessGenAttrsAfterAction
20$:
	pop	ax, cx, dx

	pop	di, bp
	ret

GenControlOutputActionRegs	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetControllerFlags

DESCRIPTION:	Get the controller flags for this controller

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenControl object

RETURN:
	ax - GenControlBuildFlags

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/27/92		Initial version

------------------------------------------------------------------------------@
GetControllerFlags	proc	far
	dupinfo		local	GenControlBuildInfo
	.enter

	call	GetDupInfo
	mov	ax, dupinfo.GCBI_flags

	.leave
	ret

GetControllerFlags	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToSuperIfFlagSet

DESCRIPTION:	Send the message to the superclass if needed

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenControl object
	ax - message
	cx, dx, bp - data

RETURN:
	from message

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/27/92		Initial version

------------------------------------------------------------------------------@
SendToSuperIfFlagSet	proc	far

	push	ax
	call	GetControllerFlags
	test	ax, mask GCBF_SPECIFIC_UI
	pop	ax
	jz	exit
	call	GC_SendToSuper
exit:
	ret

SendToSuperIfFlagSet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlPreApply -- MSG_GEN_PRE_APPLY for GenControlClass

DESCRIPTION:	Handle pre-apply by sending a suspend if the controller
		has the GCBF_SUSPEND_ON_APPLY flag set

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

RETURN:
	carry - set to abort apply

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
GenControlPreApply	method dynamic	GenControlClass, MSG_GEN_PRE_APPLY

	mov	di, MSG_META_SUSPEND
	FALL_THRU SuspendUnsuspendCommon

GenControlPreApply	endm

;---

SuspendUnsuspendCommon	proc	far
dupinfo		local	GenControlBuildInfo
	.enter

	push	ax
	call	GetDupInfo
	test	dupinfo.GCBI_flags, mask GCBF_SUSPEND_ON_APPLY
	jz	noSuspend
	mov_tr	ax, di
	clrdw	bxdi				;no class (Meta message)
	call	GenControlSendToOutputRegs
noSuspend:
	pop	ax

	.leave
	GOTO	GC_SendToSuper

SuspendUnsuspendCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlPostApply -- MSG_GEN_POST_APPLY for GenControlClass

DESCRIPTION:	Handle post-apply by sending an unsuspend if the controller
		has the GCBF_SUSPEND_ON_APPLY flag set

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

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
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
GenControlPostApply	method dynamic	GenControlClass, MSG_GEN_POST_APPLY

	mov	di, MSG_META_UNSUSPEND
	GOTO	SuspendUnsuspendCommon

GenControlPostApply	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlSetEnabled
			-- MSG_GEN_SET_ENABLED for GenControlClass
			-- MSG_GEN_SET_NOT_ENABLED for GenControlClass

DESCRIPTION:	Handle the controller being set enabled/not enabled.  
		Performs default behavior, then deals with tool group 
		specially, by setting it enabled/not enabled based on
		controller status.  This is necessary because the tool group
		is unrelated generically to the controller -- it is not a
		direct child, & is not even a child having a one-way pointer
		up to the controller -- it is just somewhere else in the
		generic tree, so we control its enabled status directly.
		-- Doug

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	dl - VisUpdateMode
	dh - NotifyEnabledFlags

RETURN:	carry set if visual change occurred

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version
	Doug	12/29/92	Changed to base off fully enabled status

------------------------------------------------------------------------------@
GenControlSetEnabled	method dynamic	GenControlClass,
						MSG_GEN_SET_ENABLED,
						MSG_GEN_SET_NOT_ENABLED,
						MSG_GEN_NOTIFY_NOT_ENABLED,
						MSG_GEN_NOTIFY_ENABLED

	; This is still not right - if becoming fully enabled becuase of
	; something further up tree, won't get called.
	;
	push	dx
	mov	di, offset GenControlClass
	call	ObjCallSuperNoLock
	pop	dx

	pushf
	call	GenControlUpdateToolEnableStatus
	popf
	ret

GenControlSetEnabled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GenControlUpdateToolEnableStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
PASS:		*ds:si	- GenControl object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenControlUpdateToolEnableStatus	proc	near
	uses	ax, bx, cx, dx, bp, si, di
	.enter

	; If we have any tools, set them enabled/disabled now based on our own
	; status.
	;
	;
	call	DerefVardata
	mov	di, ds:[bx].TGCI_toolParent.chunk
	mov	bx, ds:[bx].TGCI_toolParent.handle
	tst	bx
	jz	afterTools

	mov	cx, -1			; no shortcuts
	call	GenCheckIfFullyEnabled	; are we fully enabled?
	mov	ax, MSG_GEN_SET_ENABLED
	jc	fullyEnabled
.assert (MSG_GEN_SET_NOT_ENABLED - MSG_GEN_SET_ENABLED) eq 1
	inc	ax			; if not fully enabled, use NOT msg
fullyEnabled:

	mov_tr	si, di			; get tool parent in ^lbx:si
	clr	di
	call	ObjMessage

afterTools:
	.leave
	ret
GenControlUpdateToolEnableStatus	endp

GCCommon ends

;---

GCBuild segment resource

AddOrRemoveActiveListEntry	proc	far
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, MGCNLT_ACTIVE_LIST or mask GCNLTF_SAVE_TO_STATE
	FALL_THRU	AddOrRemoveListEntry
AddOrRemoveActiveListEntry	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddOrRemoveListEntry

DESCRIPTION:	Add or remove an object to a GCN list

CALLED BY:	INTERNAL

PASS:
	ax - messsage (MSG_META_GCN_LIST_ADD or MSG_META_GCN_LIST_REMOVE)
	bxsi - object
	cxdx - GCN list

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/19/92		Initial version

------------------------------------------------------------------------------@
AddOrRemoveListEntry	proc	far	uses ax, cx, dx, bp
	.enter

	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, cx
	mov	ss:[bp].GCNLP_ID.GCNLT_type, dx
	movdw	ss:[bp].GCNLP_optr, bxsi
	mov	dx, size GCNListParams
	call	GenCallApplication
	add	sp, size GCNListParams

	.leave
	ret

AddOrRemoveListEntry	endp

GC_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	GC_ObjMessage
	pop	di
	ret
GC_ObjMessageFixupDS	endp

;---

GC_ObjMessage	proc	near
	call	ObjMessage
	ret
GC_ObjMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlAddToGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Add ourselves to any GCN lists we should be on

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_ADD_TO_GCN_LISTS

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlAddToGCNLists	method dynamic GenControlClass,
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS

	push	ax, es
	mov	ax, MSG_META_GCN_LIST_ADD
	call	AddToGCNLists
	pop	ax, es

	call	SendToSuperIfFlagSet

	ret
GenControlAddToGCNLists	endm

;---

	; ax = message

AddToGCNLists	proc	far
dupinfo		local	GenControlBuildInfo
	.enter

	call	GetDupInfo
	mov	cx, dupinfo.GCBI_gcnCount
	jcxz	done

	mov	di, offset GCBI_gcnList
	call	LockTableESDI		;es = table

	; es:di = list, cx = count, ax = message

	push	bp
	sub	sp, size GCNListParams	; create stack frame
	mov	bp, sp
gcnLoop:
	push	cx
	mov	cx, es:[di].GCNLT_manuf
	mov	dx, es:[di].GCNLT_type
	mov	bx, ds:[LMBH_handle]
	call	AddOrRemoveListEntry
	pop	cx
	add	di, size GCNListType
	loop	gcnLoop

	add	sp, size GCNListParams	; fix stack
	pop	bp

	mov	di, offset GCBI_gcnList
	call	UnlockTableDI
done:
	.leave
	ret

AddToGCNLists	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlAttach -- MSG_META_ATTACH for GenControlClass

DESCRIPTION:	Load options saved in the .ini file

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

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
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GenControlAttach	method dynamic	GenControlClass, MSG_META_ATTACH,
							MSG_SPEC_SET_USABLE
dupinfo		local	GenControlBuildInfo
	ForceRef dupinfo

EC <	call	EnsureOnAppropriateLists				>

	call	EnsureOptionsLoaded

	call	GC_SendToSuper

	.enter
	call	GetDupInfo
	mov	di, dupinfo.GCBI_flags

	; if this controller always needs to get updates then add it to the
	; GCN list

	test	di, mask GCBF_ALWAYS_INTERACTABLE
	jz	noGCN
	push	bp
	mov	ax, MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	cx, mask GCIF_CONTROLLER
	call	ObjCallInstanceNoLock
	pop	bp
noGCN:

	; if this controller always needs to be on the GCN lists then do so

	test	di, mask GCBF_ALWAYS_ON_GCN_LIST
	jz	notAlwaysGCN
	push	bp
	mov	ax, MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	call	ObjCallInstanceNoLock
	pop	bp
notAlwaysGCN:

	.leave
	ret

GenControlAttach	endm

COMMENT @----------------------------------------------------------------------

ROUTINE:	EnsureOptionsLoaded

DESCRIPTION:	Load options saved in the .ini file

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

RETURN:

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/10/92		Initial version
	doug	7/31/92		Pulled guts out to be handler for
						MSG_META_LOAD_OPTIONS

------------------------------------------------------------------------------@
EnsureOptionsLoaded	proc	far	uses ax, bx, cx, dx, bp
	.enter

	mov	ax, TEMP_GEN_CONTROL_OPTIONS_LOADED or mask VDF_SAVE_TO_STATE
	call	ObjVarFindData
	jc	done

	clr	cx
	call	ObjVarAddData

	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

EnsureOptionsLoaded	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlInteractable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	One or more areas of the Controller have become
		interactable.  Add ourself to notification list(s)

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_NOTIFY_INTERACTABLE

		cx - GenControlInteractableFlags indicating which area
		     has become interactable

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlInteractable	method dynamic GenControlClass,
					MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
dupinfo	local	GenControlBuildInfo
	.enter
	call	DerefVardata
					; get "up to date" flags
	mov	ax, ds:[bx].TGCI_upToDate
	not	ax			; get areas NOT up to date
	and	ax, cx			; get bits representing new areas
					; that need to be updated



	tst	ds:[bx].TGCI_interactableFlags
	jnz	alreadyOnActiveList

;	The controller is becoming interactable, so add it to the active
;	list.

	call	GetDupInfo
	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_ACTIVE_LIST
	jnz	alreadyOnActiveList		; always on active list, no
						;	need to add it again
	push	ax, cx
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	bx, ds:[LMBH_handle]
	call	AddOrRemoveActiveListEntry
	pop	ax, cx

	call	DerefVardata

alreadyOnActiveList:

	tst	ax			; see if any new areas to update
	jz	done

	; Save new combined interactable flags for a moment while we fake the
	; flags in order to update only those things that have just become
	; interactable:
	;
	push	ds:[bx].TGCI_interactableFlags
	mov	ds:[bx].TGCI_interactableFlags, ax


	; Always add ourselves to the notification lists -- if we weren't on
	; them before, we need to be now.  If we were already on them, we
	; still need to force a notification update, so that we can fix up
	; the new UI areas to reflect current state.  Re-adding an optr
	; to a notification list results in the status for that list being
	; sent out again to the optr.

	push	cx, bp
	mov	ax, MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	call	ObjCallInstanceNoLock
	pop	cx, bp

	; Restore interactable flags to new, combined value, so that gadetry
	; will correctly be updated next time the status changes for real.
	;
	call	DerefVardata
	pop	ds:[bx].TGCI_interactableFlags
done:
	or	ds:[bx].TGCI_interactableFlags, cx
	.leave
	ret

GenControlInteractable	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DestroyBXSI

DESCRIPTION:	Destroy an object

CALLED BY:	INTERNAL

PASS:
	^lbx:si - object to destroy
	ss:bp - inherited variables

RETURN:
	none

DESTROYED:
	si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/24/92		Initial version

------------------------------------------------------------------------------@
DestroyBXSI	proc	near	uses ax, cx, dx, di, ds
dupinfo		local	GenControlBuildInfo
	class	GenControlClass
	.enter inherit far

	tst	si			;check for null object 10/29/93 cbh
	jz	exit

EC <	call	ECCheckLMemOD						>

	push	bx
	call	ObjLockObjBlock
	mov	ds, ax

	; first see if this object is linked to any others that are part of
	; the same feature.  We will follow the linked list, nuking features
	; until

nukeLinkedFeatureLoop:
	mov	ax, ATTR_GEN_FEATURE_LINK
	call	ObjVarFindData
	jnc	noLinkedObjects
	push	ds:[bx]				;save link
	call	DestroyDSSIHereAndNow
	pop	si
	jmp	nukeLinkedFeatureLoop

noLinkedObjects:
	call	DestroyDSSIHereAndNow

	pop	bx
	call	MemUnlock
exit:
	.leave
	ret

DestroyBXSI	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DestroyDSSIHereAndNow

DESCRIPTION:	Destroy a object *FAST*

CALLED BY:	INTERNAL

PASS:
	*ds:si - object to destroy
	ss:bp - inherited variables

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/24/92		Initial version

------------------------------------------------------------------------------@
DestroyDSSIHereAndNow	proc	near
dupinfo		local	GenControlBuildInfo
	class	GenControlClass
	.enter inherit far

	push	bp

	; see if we're allowed to use our boffo optimized way of doing
	; things

	test	dupinfo.GCBI_flags, mask GCBF_USE_GEN_DESTROY
	jnz	useGenDestroy

	; can optimize, go for it -- Note that it is legal to push/pop ds
	; here for two reasons:
	;	1) All we do is LMemFree which does not move anything
	;	2) DS points at a different block (the controller block)

	; remove us from our parent -- we do it directly knowing that it
	; is in the same block

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;cx:dx = ourself
	mov	bx, Gen_offset
	mov	di, offset GI_link
	call	ObjLinkFindParent		;bx:si = parent
	tst	si
	jz	noParent
EC <	cmp	bx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	GEN_CONTROL_INTERNAL_ERROR			>

	mov	ax, offset GI_link
	mov	bx, Gen_offset
	mov	di, offset GI_comp
	clr	bp
	call	ObjCompRemoveChild
noParent:
	mov	si, dx				;*ds:si = object to nuke

	call	DestroyHereLow

done:
	pop	bp
	.leave
	ret

useGenDestroy:

	; can't optimize, do it the slow, generic way

	mov	bx, ds:[LMBH_handle]

	mov	dl, VUM_NOW
	clr	bp				;don't bother marking dirty
	mov	ax, MSG_GEN_DESTROY
	mov	di, mask MF_FORCE_QUEUE		;destroy a litle later..
	call	GC_ObjMessage

	mov	dl, VUM_NOW
	clr	bp
	mov	ax, MSG_GEN_REMOVE		;not usable, remove now.
	clr	di
	call	GC_ObjMessage
	jmp	done

DestroyDSSIHereAndNow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DestroyHereLow

DESCRIPTION:	Destroy this object and its children

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

RETURN:
	none

DESTROYED:
	ax, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/24/92		Initial version

------------------------------------------------------------------------------@
DestroyHereLow	proc	near
	class	GenControlClass

	; find destroy our moniker

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GI_visMoniker
	tst	ax
	jz	afterMoniker
	call	LMemFree
afterMoniker:

	; get the chunk of our first child and then nuke ourself

EC <	push	bx							>
EC <	mov	bx, ds:[di].GI_comp.CP_firstChild.handle		>
EC <	tst	bx							>
EC <	jz	10$							>
EC <	cmp	bx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	GEN_CONTROL_INTERNAL_ERROR			>
EC <10$:								>
EC <	pop	bx							>

	mov_tr	ax, si
	mov	si, ds:[di].GI_comp.CP_firstChild.chunk	;*ds:si = first child
	call	LMemFree

	; now destroy our children

childLoop:
	tst	si
	jz	afterChildren
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

EC <	push	bx							>
EC <	mov	bx, ds:[di].GI_link.LP_next.handle			>
EC <	tst	bx							>
EC <	jz	20$							>
EC <	cmp	bx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	GEN_CONTROL_INTERNAL_ERROR			>
EC <20$:								>
EC <	pop	bx							>

	push	ds:[di].GI_link.LP_next.chunk
	call	DestroyHereLow
	pop	si
	test	si, LP_IS_PARENT		;is this our parent?
	jz	childLoop			;done if we've reached parent
afterChildren:

	ret

DestroyHereLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize var data elements which we want to be
		accessable via ObjVarDerefData

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_INITIALIZE_VAR_DATA
		cx	- data type

RETURN:		ds:ax	- ptr to data entry
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlInitializeVarData	method GenControlClass,
					MSG_META_INITIALIZE_VAR_DATA

	mov	bx, size TempGenControlInstance
	cmp	cx, TEMP_GEN_CONTROL_INSTANCE
	jz	allocate

	mov	bx, size GenControlUserData
	cmp	cx, HINT_GEN_CONTROL_USER_MODIFIED_UI
	jz	allocateAsSaveToState

	call	GC_SendToSuper
	ret

allocateAsSaveToState:
	or	cx, mask VDF_SAVE_TO_STATE
allocate:
	mov_tr	ax, cx		;AX <- entry type
	mov	cx, bx
	call	ObjVarAddData	; ds:bx = data

	push	bx
	cmp	ax, HINT_GEN_CONTROL_USER_MODIFIED_UI or mask VDF_SAVE_TO_STATE
	jne	exit
	mov	di, bx
	mov	ax, HINT_GEN_CONTROL_MODIFY_INITIAL_UI
	call	ObjVarFindData
	jnc	exit

;	Copy over HINT_GEN_CONTROL_MODIFY_INITIAL_UI

	segmov	es, ds			;ES:DI <- ptr to dest for copy
	mov	si, bx			;DS:SI <- ptr to source for copy
	mov	cx, (size GenControlUserData / 2)
.assert (size GenControlUserData and 1) eq 0
	rep	movsw
exit:
	pop	ax
	ret

GenControlInitializeVarData	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetUIFeatures

DESCRIPTION:	Get the effective UI level for this controller

CALLED BY:	INTERNAL

PASS:
	*ds:si - UI controller
	ss:bp - inherited vars
	ax - GenControlUIType

RETURN:
	ax - UI features

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GetUIFeatures	proc	near	uses bx, cx, dx
dupinfo		local	GenControlBuildInfo
scaninfo	local	GenControlScanInfo
	.enter inherit far
	call	GenControlGetFeatures
	.leave
	ret

GetUIFeatures	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenControlGetFeatures

DESCRIPTION:	Get the effective UI level for this controller

CALLED BY:	INTERNAL
		GetUIFeatures

PASS:
	*ds:si - UI controller
	ss:bp - inherited vars
	ax - GenControlUIType

RETURN:
	ax - current feature set
	bx - features supported by controller
	cx - application-required features
	dx - application-prohibited features

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/3/91		Pulled out from GetUIFeatures

------------------------------------------------------------------------------@
GenControlGetFeatures	proc	near	uses	di
dupinfo		local	GenControlBuildInfo
scaninfo	local	GenControlScanInfo
	.enter inherit far

	; First, scan hints & get the full scoop
	;
	push	bp, ax

	mov	cx, ax
	lea	bp, scaninfo
	mov	dx, ss				;dx:bp is GenControlScanInfo struct
	mov	ax, MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
	call	ObjCallInstanceNoLock

	pop	bp, di
	tst	di
	jz	haveCorrectionOffset
	mov	di, offset GCBI_toolList - offset GCBI_childList
haveCorrectionOffset:

	; Get controller default features

					; Get controller default features
	mov	ax, dupinfo[di].GCBI_features

	; Figure out mask of what features this controller supports, put in bx
	;
	clr	bx
	mov	cx, dupinfo[di].GCBI_featuresCount	; Get # of features
	jcxz	haveSupportedMask
supportedLoop:
	stc
	rcl	bx, 1
	loop	supportedLoop
haveSupportedMask:

	or	ax, scaninfo.GCSI_userAdded
	mov	dx, scaninfo.GCSI_userRemoved
	not	dx
	and	ax, dx

	mov	cx, scaninfo.GCSI_appRequired	; Override w/app's requests
	or	ax, cx
	mov	dx, scaninfo.GCSI_appProhibited
	push	dx
	not	dx
	and	ax, dx
	pop	dx

	and	ax, bx			; Take out any features not supported
					; by controller

	.leave
	ret
GenControlGetFeatures	endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlScanFeatureHints -- MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
							for GenControlClass

DESCRIPTION:	Scan the hints for feature info

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx - GenControlUIType
	dx:bp	- ptr to GenControlScanInfo structure to fill in

RETURN:
	dx:bp	- structure filled out

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/21/91	Initial version
	Doug	1/14/92		Modifications for toolbox

------------------------------------------------------------------------------@
GenControlScanFeatureHints	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_SCAN_FEATURE_HINTS

	push	ax, cx, dx, bp
	movdw	esdi, dxbp
	call	EnsureOptionsLoaded

	clr	ax
	stosw				; init userAdded to 0
	stosw				; init userRemoved to 0

	clr	ax
	stosw				; init appRequired to 0
	stosw				; init appProhibited to 0

	mov	bx, cx			; bx = GenControlUIType

	clr	ax
	mov	al, cs:[GEUIHintStart][bx]
	add	ax, offset GEUIHintTable
	mov_tr	di, ax				;cs:di = table
	clr	ax
	mov	al, cs:[GEUIHintCount][bx]	;ax = count
	segmov	es, cs
	call	ObjVarScanData
	pop	ax, cx, dx, bp

	push	cx, dx, bp
	call	SendToSuperIfFlagSet
	pop	cx, dx, bp

	;
	; mask out global controller features (stored in geos.ini) under
	; associated field's category
	;
	call	SetGlobalControllerFeatures
		
	ret

GenControlScanFeatureHints	endm

GEUIHintStart	byte	\
	0 * (size VarDataHandler),	;GCUIT_NORMAL
	3 * (size VarDataHandler)	;GCUIT_TOOLBOX

GEUIHintCount	byte	\
	(length GEUIHintTable) - 2,	;GCUIT_NORMAL
	(length GEUIHintTable) - 3	;GCUIT_TOOLBOX

GEUIHintTable	VarDataHandler	\
		; Hints for Normal UI only... \
	<ATTR_GEN_CONTROL_REQUIRE_UI, offset GEUIRequireUI>,
	<ATTR_GEN_CONTROL_PROHIBIT_UI, offset GEUIProhibitUI>,
	<HINT_GEN_CONTROL_TOOLBOX_ONLY, offset GEUIToolboxOnly>,
		; Hints for both Normal and Toolbox UI...
	<HINT_GEN_CONTROL_MODIFY_INITIAL_UI, offset GEUIModifyInitialUI>,
	<HINT_GEN_CONTROL_USER_MODIFIED_UI, offset GEUIUserModifiedUI>,
	<HINT_GEN_CONTROL_SCALABLE_UI_DATA, offset GEUIScalableUI>,
		; Hints for Toolbox UI only...
	<ATTR_GEN_CONTROL_REQUIRE_TOOLBOX_UI, offset GEUIRequireUI>,
	<ATTR_GEN_CONTROL_PROHIBIT_TOOLBOX_UI, offset GEUIProhibitUI>

	; for callbacks:
	; pass:
	;	*ds:si - object
	;	ds:bx - extra data with hints
	;	dx:bp - GenControlScanInfo
	;	cx - GenControlUIType (GCUIT_NORMAL or GCUIT_TOOLBOX)

GEUIRequireUI	proc	far
	mov	di, offset GCSI_appRequired
	GOTO	StoreWord
GEUIRequireUI	endp

GEUIProhibitUI	proc	far
	mov	di, offset GCSI_appProhibited
	FALL_THRU	StoreWord
GEUIProhibitUI	endp

StoreWord	proc	far
	mov	ax, ds:[bx]
	push	es
	mov	es, dx
	or	es:[di+bp], ax
	pop	es
	ret
StoreWord	endp

;---

GEUIToolboxOnly	proc	far
	mov	es, dx
	or	es:[bp].GCSI_appProhibited, -1
	ret
GEUIToolboxOnly	endp

;---

GEUIModifyInitialUI	proc	far

	; if our version exists then skip this hint

	push	bx
	mov	ax, HINT_GEN_CONTROL_USER_MODIFIED_UI
	call	ObjVarFindData
	pop	bx
	jc	done
	call	GEUIUserModifiedUI
done:
	ret

GEUIModifyInitialUI	endp

;---

GEUIUserModifiedUI	proc	far
	mov	ax, ds:[bx].GCUD_flags
	cmp	cx, GCUIT_TOOLBOX
	jz	toolbox

	test	ax, mask GCUF_USER_UI
	jz	done
	mov	ax, ds:[bx].GCUD_userAddedUI
	mov	bx, ds:[bx].GCUD_userRemovedUI
	jmp	common

toolbox:
	test	ax, mask GCUF_USER_TOOLBOX_UI
	jz	done
	mov	ax, ds:[bx].GCUD_userAddedToolboxUI
	mov	bx, ds:[bx].GCUD_userRemovedToolboxUI

common:
	mov	es, dx
	mov	es:[bp].GCSI_userAdded, ax
	mov	es:[bp].GCSI_userRemoved, bx

done:
	ret
GEUIUserModifiedUI	endp

;---

GEUIScalableUI	proc	far
	push	dx
	mov	es, dx				;es:bp <- GenControlScanInfo
	push	cx, bp
	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	call	GenCallApplication		;ax = features, dx = UI level
	pop	cx, bp
	VarDataSizePtr	ds, bx, di		;di = size

	;
	; ax - features in the application
	; dx - UIInteraceLevel
	; ds:bx - ptr to current GenControlScalableUIEntry
	; di - size of all GenControlScalableUIEntry for this hint
	;
	; es:bp - ptr to GenControlScanInfo
	; cx - GenControlUIType (GCUIT_NORMAL or GCUIT_TOOLBOX)
	;
	clr	es:[bp].GCSI_userAdded
	clr	es:[bp].GCSI_userRemoved
	push	si
scanloop:
	push	ax
	;
	; Is this the correct UI type? (normal vs. toolbox)
	;
	test	ds:[bx].GCSUIE_command, 1
	jnz	toolbox
	cmp	cx, GCUIT_NORMAL
	jmp	20$
toolbox:
	cmp	cx, GCUIT_TOOLBOX
20$:
	jne	next				;branch if not right type
	;
	; Figure out the command type and do the right thing
	; NOTE: the "andnf si, 0x00fe" has two purposes:
	; (1) throw away the garbage high byte, since the command is a byte
	; (2) ignore the low bit, which is toolbox vs. menu
	;
	mov	si, {word}ds:[bx].GCSUIE_command
	andnf	si, 0x00fe			;si <- ScalableUICommand
	test	ax, ds:[bx].GCSUIE_appFeature	;clear Z flag if feature ON
	jmp	cs:scaleUITable[si]

scaleUITable nptr \
	setIfAppFeatureOn,
	setIfAppFeatureOff,
	setIfAppLevel,
	addIfAppFeatureOn

	;
	; Add the controller features if the app feature is ON
	;
addIfAppFeatureOn:
	jz	next				;branch if feature is OFF
	;
	; For adding, mark the features as added, and make sure they
	; aren't removed.
	;
	mov	ax, ds:[bx].GCSUIE_newFeatures
	or	es:[bp].GCSI_userAdded, ax
	not	ax
	and	es:[bp].GCSI_userRemoved, ax
	jmp	next

	;
	; Set the controller features if the app feature is ON
	;
setIfAppFeatureOn:
	jnz	setFeatures
	jmp	next

	;
	; Set the controller features if the app feature is OFF
	;
setIfAppFeatureOff:
	jz	setFeatures
	jmp	next

setIfAppLevel:
	cmp	dx, ds:[bx].GCSUIE_appFeature	;level high enough?
	jb	next				;branch if too low
setFeatures:
	mov	ax, ds:[bx].GCSUIE_newFeatures
	mov	es:[bp].GCSI_userAdded, ax
	not	ax
	mov	es:[bp].GCSI_userRemoved, ax
next:
	pop	ax
	add	bx, (size GenControlScalableUIEntry)
	sub	di, (size GenControlScalableUIEntry)
	jnz	scanloop
	pop	si
	pop	dx
	ret
GEUIScalableUI	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetGlobalControllerFeatures

DESCRIPTION:	Update global features for this controller

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	cx - GenControlUIType
	dx:bp	- ptr to GenControlScanInfo structure to fill in

RETURN:
	dx:bp	- structure filled out

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/6/98		Initial version

------------------------------------------------------------------------------@
SetGlobalControllerFeatures	proc	far
	uses	ax, bx, cx, dx, si, di, ds, es
dupInfo		local	GenControlBuildInfo
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
userData	local	GenControlUserData
features	local	fptr.GenControlScanInfo
uiType		local	GenControlUIType
	ForceRef	dupInfo
	.enter
	mov	features.segment, dx
	mov	dx, ss:[bp]		; dx = saved bp = features offset
	mov	features.offset, dx
	mov	uiType, cx
	;
	; get .ini category for associated field
	;
	push	bp
	push	si
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	cx, ss
	lea	dx, categoryBuffer
	mov	di, dx
SBCS <	mov	{char}ss:[di], 0 				>
DBCS <	mov	{wchar}ss:[di], 0				>
	mov	ax, MSG_META_GET_INI_CATEGORY
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	UserCallApplication
	pop	bp
	lea	di, categoryBuffer
SBCS <	cmp	{char}ss:[di], 0				>
DBCS <	cmp	{wchar}ss:[di], 0				>
	je	done
	;
	; get key for this controller
	;
	call	GetDupInfo
	call	LoadCatAndKey
	jcxz	noKey
	;
	; read global feature set
	;
	push	bp
	mov	bp, size GenControlUserData
	call	InitFileReadData
	pop	bp
	jc	noKey
	;
	; update features
	;
	mov	ax, mask GCUF_USER_UI
	mov	bx, offset GCUD_userAddedUI
	cmp	uiType, GCUIT_NORMAL
	je	haveType
	mov	ax, mask GCUF_USER_TOOLBOX_UI
	mov	bx, offset GCUD_userAddedToolboxUI
haveType:
	test	ax, userData.GCUD_flags
	jz	noKey
	lea	ax, userData
	add	bx, ax
	mov	ax, ss:[bx]			; ax = added UI
	mov	bx, ss:[bx+(size word)]		; bx = removed UI
	movdw	dssi, features
	ornf	ds:[si].GCSI_appRequired, ax
	ornf	ds:[si].GCSI_appProhibited, bx
noKey:
	call	UnlockIniKey
done:
	.leave
	ret
SetGlobalControllerFeatures	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlLoadOptions -- MSG_META_LOAD_OPTIONS
							for GenControlClass

DESCRIPTION:	Load state of the features from the .ini file

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

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
	Doug	7/31/91		Extracted from EnsureOptionsLoaded

------------------------------------------------------------------------------@
GenControlLoadOptions	method dynamic	GenControlClass, MSG_META_LOAD_OPTIONS
dupinfo		local	GenControlBuildInfo
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
userData	local	GenControlUserData
	ForceRef dupinfo

; See note at end -- Doug 1/93
;	push	ds:[LMBH_handle], si
	;
	; Make sure controller is aware that options have been loaded, and
	; don't have to be again.  (Moved from EnsureOptionsLoaded 11/12/92
	; cbh.   Basically this would get called on startup, but the first 
	; time EnsureOptionsLoaded got called again, everything would be
	; reloaded due to the lack of this hint being stored, causing everything
	; to be reset usable.
	;
	mov	ax, TEMP_GEN_CONTROL_OPTIONS_LOADED or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData

	mov	di, 900
	call	ThreadBorrowStackSpace
	push	di

	.enter

	call	GetDupInfo

	; get the category string

	mov	cx, ss
	lea	dx, categoryBuffer
	call	UserGetInitFileCategory		;get .ini category

	; read in the data

	push	si, bp, ds
	call	LoadCatAndKey			;ds:si = cat, cx:dx = key
	stc					;assume no key
	jcxz	noKey
	mov	bp, size GenControlUserData
	call	InitFileReadData
noKey:
	pop	si, bp, ds
	jc	done

	; store the data

	push	si
	mov	ax, HINT_GEN_CONTROL_USER_MODIFIED_UI or mask VDF_SAVE_TO_STATE
	mov	cx, size GenControlUserData
	call	ObjVarAddData
	push	ds				;save updated ds
	segmov	es, ds
	mov	di, bx				;es:di = dest
	segmov	ds, ss
	lea	si, userData
	mov	cx, size GenControlUserData
	rep	movsb
	pop	ds
	pop	si

done:
	call	UnlockIniKey

	.leave

	pop	di
	call	ThreadReturnStackSpace

; Optimization -- Do NOT call superclass.  This prevents any superclass
; of GenControlClass from ever getting MSG_META_RESET_OPTIONS, but the need
; is not there, so we'll take it away in the name of speed. -- Doug 1/93
;
;	pop	bx, si
;	call	MemDerefDS
;	mov	ax, MSG_META_LOAD_OPTIONS
;	call	GC_SendToSuper
	ret

GenControlLoadOptions	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadCatAndKey

DESCRIPTION:	Load the category and key pointers

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ss:bp - inherited vars

RETURN:
	ds:si - category
	es:di - data buffer
	cx:dx - key

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/21/92		Initial version

------------------------------------------------------------------------------@
LoadCatAndKey	proc	far
	.enter inherit GenControlLoadOptions

	mov	di, offset GCBI_initFileKey
	call	LockTableESDI
	movdw	cxdx, esdi				;cxdx = key
	segmov	ds, ss
	lea	si, categoryBuffer			;ds:si = category

	segmov	es, ss
	lea	di, userData

	.leave
	ret

LoadCatAndKey	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DupTheBlock

DESCRIPTION:	Duplicate the given block

PASS:
	ds - object block
	bx - block

RETURN:
	carry - clear if block exists
	bx - new block

------------------------------------------------------------------------------@
DupTheBlock	proc	near	uses ax, cx
	.enter

	push	bx
if	0	;For new *thread* model
	clr	ax			; set owner to that of current thread
else
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov_tr	ax, bx			; set owner to that owning block at DS
endif
	clr	cx			; set to be run by current thread
	pop	bx
	tst	bx
	stc
	jz	done
	call	ObjDuplicateResource		;bx = duplicated block

	; Set the block output of the new object block to point to the
	; controller object

	push	ax, bx, ds
	call	ObjLockObjBlock		;Don't call MemLock on obj blocks, 
					; hoser!
	mov	bx, ds:[LMBH_handle]
	mov	ds, ax
	call	ObjBlockSetOutput
	pop	ax, bx, ds
	call	MemUnlock

	clc
done:
	.leave
	ret

DupTheBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnlockTableDI

DESCRIPTION:	Unlock the table block

PASS:
	ss:bp - inherited variables
	di - offset of fptr inside dupinfo

RETURN:
	none

------------------------------------------------------------------------------@

UnlockIniKey	proc	far
	mov	di, offset GCBI_initFileKey
	call	UnlockTableDI
	ret

UnlockIniKey	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI for
						GenControlClass

DESCRIPTION:	Generate the UI for a controller

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	none

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
	Tony	11/20/91		Initial version

------------------------------------------------------------------------------@
GenControlGenerateUI	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_GENERATE_UI

	mov	di, 700	
	call	ThreadBorrowStackSpace
	push	di

dupinfo		local	GenControlBuildInfo
scaninfo	local	GenControlScanInfo
childCount	local	word
featuresCount	local	word
featuresListOff	local	word
childListOff	local	word
parent		local	optr
	ForceRef scaninfo
	.enter

	call	GetDupInfo
	mov	bx, ds:[LMBH_handle]
	movdw	parent, bxsi
	mov	ax, dupinfo.GCBI_childCount
	mov	childCount, ax
	mov	ax, dupinfo.GCBI_featuresCount
	mov	featuresCount, ax

	mov	ax, GCUIT_NORMAL
	call	GetUIFeatures				;ax = features

	mov	bx, dupinfo.GCBI_dupBlock
	call	DupTheBlock
	LONG jc	none

	push	ax, bx, bp
	mov	dx, ax
	mov	cx, bx
	mov	ax, MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	call	ObjCallInstanceNoLock
	pop	ax, bx, bp

	mov	featuresListOff, offset GCBI_featuresList
	mov	childListOff, offset GCBI_childList
	call	GenerateUICommon
done:

	; store the handle (bx) and flags (ax)

	push	bx
	call	DerefVardata
	pop	ds:[bx].TGCI_childBlock
	mov	ds:[bx].TGCI_features, ax

	; if this controller is implemented in the specific UI then pass
	; on the generate UI

	test	dupinfo.GCBI_flags, mask GCBF_SPECIFIC_UI
	jz	notSpecificUI
	push	ax, bp
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	GC_SendToSuper
	pop	ax, bp
notSpecificUI:

; We will add app ui if it exists even if there are no features. JS (11/21/92)
;	tst	ax
;	jz	noAddAppUI
	mov	ax, ATTR_GEN_CONTROL_APP_UI
	mov	dx, MSG_GEN_CONTROL_ADD_APP_UI
	call	AddAppUI
;noAddAppUI:

	; check to see if we need to add a hint for help

	mov	di, ds:[si]				;only add the hint
	add	di, ds:[di].Gen_offset			;if this is a dialog
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jnz	afterHelp

	movdw	bxdi, dupinfo.GCBI_helpContext
	tst	bx
	jz	afterHelp
	;
	; See if a help context is defined externally (ie. by the app)
	;
	push	bx
	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarFindData
	pop	bx
	jc	afterHelp				;branch if external help
	;
	; No external help context is defined -- add our default context
	;
	push	bx					;save virtual segment
	call	MemLockFixedOrMovable
	push	di
	mov	es, ax					;es:di = context
	mov	cx, 0xffff
	clr	ax
	repne	scasb
	pop	di
	not	cx					;cx = length
EC <	cmp	cx, 30							>
EC <	ERROR_A	GEN_CONTROL_HELP_CONTEXT_TOO_LONG			>
	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarAddData				;ds:bx = new data
	push	si, ds
	segxchg	ds, es
	mov	si, di					;ds:si = source
	mov	di, bx					;es:di = dest
	rep	movsb					;copy data
	pop	si, ds
	pop	bx
	call	MemUnlockFixedOrMovable

afterHelp:

	.leave

	pop	di
	call	ThreadReturnStackSpace
	ret

none:
	clr	ax
	clr	bx
	jmp	done

GenControlGenerateUI	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenerateUICommon

DESCRIPTION:	Common code for generating UI

CALLED BY:	INTERNAL

PASS:
	*ds:si - control object
	ss:bp - inherited variables
	ax - mask of features to generate
	bx - duplicated block

RETURN:
	ax - feature flags
	bx - handle

DESTROYED:
	cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/21/92		Initial version

------------------------------------------------------------------------------@
GenerateUICommon	proc	near
	.enter inherit GenControlGenerateUI

	; remove any children that are not usable in this UI setup

	; es:di = features list
	; bx = duplicated block
	; *ds:si = controller

	mov	cx, featuresCount
	jcxz	noFeatures

	mov	di, featuresListOff
	call	LockTableESDI				;esdi = features list

	; es:di = features list (GenControlFeaturesInfo)
	; cx = count
	; ax = flags
	; bx = duplicated block

	push	ax, si
featuresLoop:
	mov	si, es:[di].GCFI_object		;bx:si = object
	test	ax, 1
	jnz	nextFeature
	

	; this feature needs to be removed -- remove it from its parent now
	; to prevent redundant geometry work, but queue the DESTROY to
	; prevent in-use problems

	call	DestroyBXSI

nextFeature:
	shr	ax
	add	di, size GenControlFeaturesInfo
	loop	featuresLoop

	pop	ax, si

	mov	di, featuresListOff
	call	UnlockTableDI
noFeatures:

	; loop to add the children (and set them usable)
	;	*ds:si = controller
	;	bx = duplicated block
	;	cx = count
	;	es:di = list
	;	parent = parent to add to

	mov	cx, childCount
	jcxz	kidsDone

	call	ProcessChildren

kidsDone:
	; bx = duplicated block
	; *ds:si = controller

if 0
	;
	; Moved this to be done when the controller is interactable, instead,
	; as we always want to be on the active list as long as any part of
	; the controller is interactable - 5/19/93 -atw
	;

	; Add this Controller to the active list as we have created some UI
	; for it and we wish to received MSG_META_DETACH so we can destroy the
	; created UI.  We remove ourselves from the active list at that time,
	; if we don't always need to be on it.

	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_ACTIVE_LIST
	jnz	done				; always on active list, no
						;	need to add it again
	push	ax, bx				; save features flags
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	bx, ds:[LMBH_handle]
	call	AddOrRemoveActiveListEntry
	pop	ax, bx				; retreive features flags
done:
endif

	.leave
	ret

GenerateUICommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the child list, adding or destroying each of the
		children mentioned in the array.

CALLED BY:	(INTERNAL) GenerateUICommon
PASS:		ss:bp	= inherited frame
		cx	= # of children
RETURN:		nothing
DESTROYED:	es, di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessChildren proc near
	.enter	inherit	GenControlGenerateUI
	mov	di, childListOff
	call	LockTableESDI
childLoop:
	push	ax, bx, cx, si, di, bp
	mov	cx, bx
	mov	dx, es:[di].GCCI_object		;cx:dx = child to add

	test	es:[di].GCCI_flags, mask GCCF_ALWAYS_ADD
	jnz	usable
	test	ax, es:[di].GCCI_featureMask
	jnz	usable

	; if the child is not usable and does not directly represent a
	; feature then nuke the child

	test	es:[di].GCCI_flags, mask GCCF_IS_DIRECTLY_A_FEATURE
	jnz	nextChild

	movdw	bxsi, cxdx
	call	DestroyBXSI
	jmp	nextChild

usable:

	; add child

	test	es:[di].GCCI_flags, mask GCCF_NOTIFY_WHEN_ADDING

; NOTE!  If your code blows up here, check to make sure that the ordering of
; the features/tools in the controller dup info table matches the order of the
; bits as defined in the constant mask.  Specifically, if the "features" 
; list mismatches the "child" list, the child can end up being deleted above,
; & then attempted to be used below.
;
EC <	pushf								>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	call	ECCheckLMemOD						>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	popf								>

	jz	afterNotify
	push	cx, dx, bp			;notification added 1/26/93 cbh
	mov	ax, MSG_GEN_CONTROL_NOTIFY_ADDING_FEATURE
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp

afterNotify:
	push	cx, dx
	movdw	bxsi, parent
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	GC_ObjMessage
	pop	bx, si				;bx:si = child added

	mov	dl, VUM_MANUAL
	mov	ax, MSG_GEN_SET_USABLE
	call	GC_ObjMessageFixupDS

nextChild:
	pop	ax, bx, cx, si, di, bp
	add	di, size GenControlChildInfo
	loop	childLoop

	mov	di, childListOff
	call	UnlockTableDI

	.leave
	ret
ProcessChildren endp
COMMENT @----------------------------------------------------------------------

FUNCTION:	AddAppUI

DESCRIPTION:	Add the additional UI specified by the app

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenControl object
	ax - ATTR
	dx - message

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
AddAppUI	proc	near

	; Add the app-specified UI and set it usable.

	clr	di				;di is pointer into the vardata
addUILoop:
	call	ObjVarFindData
	jnc	done
	VarDataSizePtr	ds, bx, cx
	cmp	cx, di
	jz	done
	push	ax, dx, si, bp
	mov_tr	ax, dx
	movdw	cxdx, ds:[bx][di]
	pushdw	cxdx
	call	ObjCallInstanceNoLock
	popdw	cxdx

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	call	GC_ObjMessageFixupDS
	pop	ax, dx, si, bp
	add	di, size optr
	jmp	addUILoop
done:
	ret

AddAppUI	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlGenerateToolboxUI --
		MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI for GenControlClass

DESCRIPTION:	Generate the toolbox UI for a controller

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message
	^lcx:dx	- parent object for tools

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
	Tony	11/20/91		Initial version

------------------------------------------------------------------------------@
GenControlGenerateToolboxUI	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
dupinfo		local	GenControlBuildInfo
scaninfo	local	GenControlScanInfo
childCount	local	word
featuresCount	local	word
featuresListOff	local	word
childListOff	local	word
parent		local	optr
	ForceRef scaninfo
EC <	call	EnsureOnAppropriateLists				>

	push	cx
	clr	cx
	call	GenCheckIfFullyUsable
	pop	cx
	jc	usable
	ret
usable:

	.enter

EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	call	ECCheckLMemOD						>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>

	call	DerefVardata
	call	GetDupInfo
	mov	ax, dupinfo.GCBI_toolCount
	mov	childCount, ax
	mov	ax, dupinfo.GCBI_toolFeaturesCount
	mov	featuresCount, ax
	mov	featuresListOff, offset GCBI_toolFeaturesList
	mov	childListOff, offset GCBI_toolList
	movdw	parent, cxdx

	mov	ax, GCUIT_TOOLBOX
	call	GetUIFeatures				;ax = features
	tst	ax
	jnz	10$
none:
	clr	ax
	clr	bx
	jmp	done
10$:
	mov	bx, dupinfo.GCBI_toolBlock
	call	DupTheBlock			; bx = duplicated block
	jc	none

	push	ax, bx, cx, dx, bp
	mov	dx, ax
	mov	cx, bx
	mov	ax, MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI
	call	ObjCallInstanceNoLock
	pop	ax, bx, cx, dx, bp

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	push	bx				; save duplicated block
	push	ax				; save features

	push	ds:[LMBH_handle]		; save controller optr
	push	si				; 

	mov	bx, cx				; get parent into ^lbx:si
	mov	si, dx
	push	cx, dx, bp			; save interaction optr, frame

	; Save ENABLED status of controller on stack
	;
	test	ds:[di].GI_states, mask GS_ENABLED
	pushf

	; now that we have created this new object we need to lock it so
	; that we can add some hints to it and tweak its instance data

	call	ObjLockObjBlock
	mov	ds, ax				; *ds:si = object

	mov	ax, MSG_GEN_SET_ENABLED
	popf
	jnz	haveEnableMsg
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveEnableMsg:
	mov	dl, VUM_MANUAL			; So geometry is only done once
	call	ObjCallInstanceNoLock		; set enabled status correctly

	call	MemUnlock
	pop	cx, dx, bp			; recover interaction optr

	; add the interaction OD to our temp data

	pop	si				; restore controller optr
	pop	bx
	call	MemDerefDS			; ds:si = controller

	pop	ax				; recover features flags
	pop	bx				; bx = duplicated block

	push	ax, bx, si, cx, dx, bp
	push	cx, dx
	call	GenerateUICommon		; Create tools
	pop	bx, si
	mov	ax, MSG_GEN_UPDATE_VISUAL	; Do visual update
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	; delayed, so geometry is
						;	 only done once
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bx, si, cx, dx, bp

done:

	; store the handle (bx) and flags (ax)

	push	bx
	call	DerefVardata
	pop	ds:[bx].TGCI_toolBlock
	mov	ds:[bx].TGCI_toolboxFeatures, ax
	mov	ds:[bx].TGCI_toolParent.handle, cx
	mov	ds:[bx].TGCI_toolParent.chunk, dx

	; if this controller is implemented in the specific UI then pass
	; on the generate UI

	test	dupinfo.GCBI_flags, mask GCBF_SPECIFIC_UI
	jz	notSpecificUI
	push	ax
	mov	ax, MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
	call	GC_SendToSuper
	pop	ax
notSpecificUI:

	tst	ax
	jz	noAddAppUI
	push	ax
	mov	ax, ATTR_GEN_CONTROL_APP_TOOLBOX_UI
	mov	dx, MSG_GEN_CONTROL_ADD_APP_TOOLBOX_UI
	call	AddAppUI
	pop	ax
noAddAppUI:

	.leave

	tst	ax
	jz	exit
	mov	ax, MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	cx, mask GCIF_TOOLBOX_UI
	GOTO	ObjCallInstanceNoLock
exit:
	ret

GenControlGenerateToolboxUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlGetNormalFeatures -- MSG_GEN_CONTROL_GET_NORMAL_FEATURES

DESCRIPTION:	Returns masks indicating what features the controller supports,
		what features the application requires & prohibits, and what the
		current feature set is, taking into account all this info plus
		controller & user preferences.  Called by GenToolControl to get
		info needed to be able to display current setup & control what
		the user is allowed to change

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

RETURN:
	ax - current normal feature set
	cx - application-required normal features
	dx - application-prohibited normal features
	bp - normal features supported by controller

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/3/92		Initial version

------------------------------------------------------------------------------@
GenControlGetNormalFeatures	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_GET_NORMAL_FEATURES
	mov	ax, GCUIT_NORMAL
	GOTO	GetUIFeaturesForMessageCommon

GenControlGetNormalFeatures	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlGetToolboxFeatures -- MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES

DESCRIPTION:	Returns masks indicating what features the controller supports,
		what features the application requires & prohibits, and what the
		current feature set is, taking into account all this info plus
		controller & user preferences.  Called by GenToolControl to get
		info needed to be able to display current setup & control what
		the user is allowed to change

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

RETURN:
	ax - current toolbox feature set
	cx - application-required toolbox features
	dx - applicaiton-prohibited toolbox features
	bp - toolbox features supported by controller

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/3/92		Initial version

------------------------------------------------------------------------------@
GenControlGetToolboxFeatures	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES
	mov	ax, GCUIT_TOOLBOX
	FALL_THRU	GetUIFeaturesForMessageCommon

GenControlGetToolboxFeatures	endm


GetUIFeaturesForMessageCommon	proc	far
dupinfo		local	GenControlBuildInfo
scaninfo	local	GenControlScanInfo
	ForceRef dupinfo
	ForceRef scaninfo
	.enter
	call	GetDupInfo
	call	GenControlGetFeatures
	.leave
	mov	bp, bx		; return supported featured in bp
	ret
GetUIFeaturesForMessageCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlNotifyObjBlockInteractible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that the UI object block we've created
		has become interactible.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_NOTIFY_OBJ_BLOCK_INTERACTIBLE
		cx	- block handle

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlNotifyObjBlockInteractible method dynamic GenControlClass, \
				MSG_META_NOTIFY_OBJ_BLOCK_INTERACTIBLE

	; Default handler can deal only with single block that GenControl
	; has created.
	;
	call	DerefVardata
	cmp	cx, ds:[bx].TGCI_childBlock
	jne	exit

	; Children are busy, so let's bump our own interactible count to reflect
	; this.  Will ensure that if we are ourselves a child of a controller,
	; it will know that we're busy & will continue to send us updates
	; and not SPEC_UNBUILD us in the name of efficiency.  (Would result
	; in any child gadgets which become pinned menus or dialogs to 
	; come down, not a desirable thing)
	;
	call	ObjIncInteractibleCount

	; Send notification to ourselves that the normal UI has become
	; interactable.  If we're not yet on the notification lists, we'll add
	; ourselves.  If we already are, we'll update the flags indicating
	; which things are interactable, & force an update of the UI
	; gadgetry.
	;
	mov	ax, MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	cx, mask GCIF_NORMAL_UI
	GOTO	ObjCallInstanceNoLock
exit:
	ret

GenControlNotifyObjBlockInteractible endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlNotifyObjBlockNotInteractible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that the UI object block we've created
		has become not in-use.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE
		cx	- block handle

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlNotifyObjBlockNotInteractible method dynamic GenControlClass, \
				MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE

	; Default handler can deal only with single block that GenControl
	; has created.
	;
	call	DerefVardata
	cmp	cx, ds:[bx].TGCI_childBlock
	jne	exit

	; Send notification to ourselves that the normal UI has become not
	; interactable.  This will cause the flags to be updated so that
	; the normal UI will not be updated on changes, & if no areas of
	; the controller are left interactable, the controller will be
	; taken off the notification lists altogether.
	;
	push	cx
	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	mov	cx, mask GCIF_NORMAL_UI
	call	ObjCallInstanceNoLock
	pop	cx

; The following code placement, if activated, results in the created Normal UI
; block being unbuilt, if possible, anytime it becomes not visible to the
; user.  This frequency may be excessive, & a different algorithm used to
; decided when to do the unbuild.  In any case, the code is commmented out
; now, both because we don't want this behavior on normal machines, and
; because this behavior is not yet fully supported by the specific UI.
; See comments in MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE handler.
; -- Doug 12/20/91
;

	; A test!  See if it is possible to not only quit updating, but
	; to actually unbuild the normal UI component block at this time.
	; Why?  Because some machines (such as palmtops) may have very little
	; swap space.  Being able to actually nuke UI that isn't in use would
	; be greatly beneficial.
	;
	mov	ax, MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE
	mov	bx, ds:[LMBH_handle]
					; force on queue, since
					; "NOT_INTERACTIBLE"
					; notification is generally from the
					; middle of a visual update, which would
					; be a bad place to be destroying things
;	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT

;	We force queue the message (don't insert it at the front) because
;	there could be a queued message to bring up a child dialog box or
;	something, so we don't want to nuke the block just yet.

	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; Dec in-use count when child block is no longer interactible to balance
	; the Inc performed in GenControlNotifyObjBlockInteractible.
	;
	call	ObjDecInteractibleCount
exit:
	ret

GenControlNotifyObjBlockNotInteractible endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlSpecBuildBranch -- MSG_SPEC_BUILD_BRANCH
						for GenControlClass

DESCRIPTION:	Build the generic tree

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	bp - SpecBuildFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
GenControlSpecBuildBranch	method dynamic	GenControlClass,
						MSG_SPEC_BUILD_BRANCH

EC <	call	EnsureOnAppropriateLists				>

	push	bp				;save build flags

	; if this is a dual build object and this is not a win group
	; build then don't do anything

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, 1				;assume need to do no features
						; check
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jz	noDualBuild
	test	bp, mask SBF_WIN_GROUP
	LONG jz	afterGenerateUI
	dec	cx
noDualBuild:

	call	DerefVardata
	tst	ds:[bx].TGCI_childBlock
	jnz	afterGenerateUI

; Can't do this.  Command windows such as GeoFile's treasure chest have to
; be built out in SPEC_BUILD, so that the box actually contains something
; when it appears on screen.		-- Doug 1/28/93
;
;	mov	di, ds:[si]
;	add	di, ds:[di].Gen_offset
;	test	ds:[di].GII_attrs, mask GIA_NOT_USER_INITIATABLE
;	LONG jnz afterInteractable

	; send a message to ourself to get the UI added, passing ourself
	; as the object to add to

	push	cx
	mov	cx, ds:[bx].TGCI_toolParent.handle
	mov	dx, ds:[bx].TGCI_toolParent.chunk
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock
	pop	cx

afterGenerateUI:

	; if needed then check for no features and set us "not user initiatable"
	; if so

	jcxz	afterNoFeaturesCheck
	mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
	call	ObjCallInstanceNoLock		;ax = feature set
	tst	ax
	jnz	afterNoFeaturesCheck

	mov	ax, ATTR_GEN_CONTROL_APP_UI
	call	ObjVarFindData			;carry set if we have app ui
	jc	afterNoFeaturesCheck

	mov	cx, mask GIA_NOT_USER_INITIATABLE
	mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
	call	ObjCallInstanceNoLock
afterNoFeaturesCheck:

	; to finish - call our superclass

	; On any spec-build, the controller itself becomes visible & may 
	; need to be enabled/disabled, so update interactable status to
	; ensure we're on the gcn lists.	-- Doug

	; Optimization: If we are not user initiatable then we really don't
	; need to be interactable -- Tony

	; The GIA_NOT_USER_INITIATABLE bit only means something for dialogs.
	; If the controller is not a dialog, then we want to mark it 
	; interactable.

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jnz	interactable
	test	ds:[di].GII_attrs, mask GIA_NOT_USER_INITIATABLE
	jnz	afterInteractable
interactable:
	mov	ax, MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	cx, mask GCIF_CONTROLLER
	call	ObjCallInstanceNoLock
afterInteractable:

	pop	bp

;	The NOTIFY_INTERACTABLE may have set this object fully enabled, so
;	we need to update our spec build flags appropriately.

	andnf	bp, not mask SBF_VIS_PARENT_FULLY_ENABLED
	mov	cx, -1			; no optimizations -- do full check
        call    GenCheckIfFullyEnabled  ; see if we're fully enabled
        jnc     doBuild                 ; no, branch
        ornf    bp, mask SBF_VIS_PARENT_FULLY_ENABLED
doBuild:
	mov	ax, MSG_SPEC_BUILD_BRANCH
	call	GC_SendToSuper
	ret

GenControlSpecBuildBranch	endm

;---

if ERROR_CHECK

EnsureOnAppropriateLists	proc	far
	uses	ax, bx, cx, dx, bp, si, di
dupinfo		local	GenControlBuildInfo
params		local	GCNListParams
	.enter

	call	GetDupInfo

	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_ACTIVE_LIST
	jz	notOnActive
	mov	ax, MGCNLT_ACTIVE_LIST
	call	checkActiveList
	ERROR_C	GEN_CONTROL_MUST_BE_ON_ACTIVE_LIST
	jmp	afterActive
notOnActive:
	test	dupinfo.GCBI_flags, mask GCBF_ALWAYS_INTERACTABLE
	ERROR_NZ GEN_CONTROL_CANNOT_SET_ALWAYS_INTERACTABLE_IF_NOT_ON_ACTIVE_LIST
	test	dupinfo.GCBI_flags, mask GCBF_ALWAYS_ON_GCN_LIST
	ERROR_NZ GEN_CONTROL_CANNOT_SET_ALWAYS_ON_GCN_LIST_IF_NOT_ON_ACTIVE_LIST
afterActive:

	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_START_LOAD_OPTIONS_LIST
	jnz	startupList
	test	dupinfo.GCBI_flags,
			mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST
	jnz	common

	mov	ax, GAGCNLT_SELF_LOAD_OPTIONS
	call	checkActiveList
	ERROR_C	GEN_CONTROL_MUST_BE_ON_SELF_LOAD_OPTIONS_LIST
	jmp	common

startupList:
	mov	ax, GAGCNLT_STARTUP_LOAD_OPTIONS
	call	checkActiveList
	ERROR_C	GEN_CONTROL_MUST_BE_ON_STARTUP_LOAD_OPTIONS_LIST

common:
	.leave
	ret

checkActiveList:
	push	si
	mov	params.GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	params.GCNLP_ID.GCNLT_type, ax
	mov	ax, ds:[LMBH_handle]
	mov	params.GCNLP_optr.handle, ax
	mov	params.GCNLP_optr.chunk, si
	clr	bx
	call	GeodeGetAppObject
	tst_clc	bx
	jz	noApp
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, size GCNListParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	push	bp
	lea	bp, params
	call	GC_ObjMessage
	pop	bp
noApp:
	pop	si
	retn

EnsureOnAppropriateLists	endp
endif


GCBuild ends

;---

ControlObject segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlDetach -- MSG_META_DETACH for GenControlClass

DESCRIPTION:	Intercept detach and nuke our created UI

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx - caller's ID
	dx:bp - ack OD

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
	Tony	11/27/91		Initial version

------------------------------------------------------------------------------@
GenControlDetach	method dynamic	GenControlClass, MSG_META_DETACH

	mov	ax, 1				;detaching
	call	DestroyGeneratedUI

	push	ax, cx, dx, bp
	mov	cx, mask GCIF_CONTROLLER or mask GCIF_NORMAL_UI or mask GCIF_TOOLBOX_UI
	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

	; pass DETACH to our superclass

	mov	ax, MSG_META_DETACH
	call	GC_SendToSuper
	ret

GenControlDetach	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlSpecUnbuild -- MSG_SPEC_UNBUILD for GenControlClass

DESCRIPTION:	Build the generic tree

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	bp - SpecBuildFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version
	Doug	12/17		New logic to allow dynamic unbuilding

------------------------------------------------------------------------------@
GenControlSpecUnbuild	method dynamic	GenControlClass, MSG_SPEC_UNBUILD

	; See if generically or visibly unbuilding.  If generic, we're being
	; set NOT_USABLE, so we should go ahead & nuke everything.  If
	; just a visual unbuild, depends on some other logic to follow...
	;
	test	bp, mask SBF_VIS_PARENT_UNBUILDING
	jz	destroyAll

	; Split up single & dual build cases.  If single, then the visible
	; parent that the normal UI components are on is unbuilding, so they
	; must be unbuilt as well.  If dual build, more logic to follow...
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jz	destroyAll

;dualBuild:
	; If dual build, split up non-WIN_GROUP & WIN_GROUP cases.  If
	; WIN_GROUP, is like single-case in that visible parent of NORMAL UI
	; gadgets is being unbuilt.  Proceed to unbuild them.
	;
	test	bp, mask SBF_WIN_GROUP
	jz	nonWinGroup

;;destroyNormalUI:
	; Destroy JUST the Normal UI stuff
	;
	call	DestroyNormalUI
	jmp	callSuper

destroyAll:
	push	ax
	clr	ax					;not detaching
	call	DestroyGeneratedUI
	pop	ax

nonWinGroup:
	; Otherwise, if non-win group portion, then just affects button
	; that leads to NORMAL UI window.  call superclass to nuke the button
	; after marking the controller not-interactable

	push	ax, cx, dx, bp
	mov	cx, mask GCIF_CONTROLLER
	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

callSuper:
	call	GC_SendToSuper
	ret

GenControlSpecUnbuild	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DestroyGeneratedUI

DESCRIPTION:	Destroy the generated UI for the controller and remove the
		controller from thew active list if the controller was only
		on the active list to get DETACH.

CALLED BY:	INTERNAL

PASS:
	ax - non-zero if detaching (are therefore can optimize)
	*ds:si - GenControl object

RETURN:
	none

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/19/92		Initial version

------------------------------------------------------------------------------@
DestroyGeneratedUI	proc	far	uses ax, cx, dx, bp
	class	GenControlClass
	.enter

	; if we are detaching try to optimize...

	tst	ax
	LONG jz	normalDestroy

	; Since we are detaching there is really no need to do a whole lot
	; of work (like destroying all the UI), so let's just nuke our
	; children (and the tool interaction's children) and let it go at that
	; -- tony 10/12/92

	call	DerefVardata			; get variable data
	clr	cx
	xchg	cx, ds:[bx].TGCI_childBlock	; have we created UI yet ??
	jcxz	afterNormalUI			; no, so do nothing

	;
	; We need to free the block, too, dude, not just unlink it...
	; -- atw & jdashe 7/7/95
	;		
	mov	ax, MSG_GEN_CONTROL_FREE_OBJ_BLOCK
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	push	cx
	call	removeAllFromWindowList
	pop	bx

	; if the block is interactable then decrement our in-use count now
	; since when we get a MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE
	; we will no longer know that this is our block

	push	ds
	call	ObjLockObjBlock
	mov	ds, ax
	tst	ds:[OLMBH_interactibleCount]
	call	MemUnlock
	pop	ds
	jz	childBlockNotInteractable
	call	ObjDecInteractibleCount
childBlockNotInteractable:

	mov	ax, ATTR_GEN_CONTROL_APP_UI
	call	RemoveAppUI

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	ax
	clrdw	ds:[di].GI_comp.CP_firstChild, ax

	mov	di, ds:[si]
	tst	ds:[di].Vis_offset		; built?
	jz	afterNormalUI			; no

EC <	push	es, di							>
EC <	segmov	es, <segment VisCompClass>, di				>
EC <	mov	di, offset VisCompClass					>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	GEN_CONTROL_DIDNT_BUILD_TO_VIS_COMP		>
EC <	pop	es, di							>

	add	di, ds:[di].Vis_offset
	clrdw	ds:[di].VCI_comp.CP_firstChild, ax

afterNormalUI:

	call	DerefVardata			; get variable data
	clr	cx
	xchg	cx, ds:[bx].TGCI_toolBlock	; have we created toolbox yet ??
	jcxz	done				; no, so do nothing

	;
	; We need to free the block, too, dude, not just unlink it...
	; -- atw & jdashe 7/7/95
	;		
	mov	ax, MSG_GEN_CONTROL_FREE_OBJ_BLOCK
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	call	removeAllFromWindowList
	mov	ax, ATTR_GEN_CONTROL_APP_TOOLBOX_UI
	call	RemoveAppUI

	push	si
	call	DerefVardata
	mov	si, ds:[bx].TGCI_toolParent.chunk
	mov	bx, ds:[bx].TGCI_toolParent.handle
	call	ObjSwapLock
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	ax
	clrdw	ds:[di].GI_comp.CP_firstChild
	call	ObjSwapUnlock
	pop	si

	jmp	done

normalDestroy:

	; Destroy Normal & Toolbox created UI components

	call	DestroyNormalUI
	call	DestroyToolboxUI


if 0
	; Moved this to GenControlNotInteractable, as we want to remain on
	; the active list as long as any part of the controller is
	; interactable (5/18/93 - atw)

	; If Controller was added to active list to receive MSG_META_DETACH,
	; remove it now, as we have destroyed created UI components (which is
	; why we originally wanted to receieve MSG_META_DETACH).

	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_ACTIVE_LIST or \
				    mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST
	jnz	done				; if always on active list,
						;	leave it there
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	bx, ds:[LMBH_handle]
	call	AddOrRemoveActiveListEntry
endif
done:

	.leave
	ret

;---

	; cx = handle of child block or toolbox block that is about to
	;      be removed
	;
	; If any object in the block is on the GAGCNLT_WINDOWS list, remove it

removeAllFromWindowList:
	push	si, bp
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLP_optr.handle, cx
	mov	ss:[bp].GCNLP_optr.chunk, 0
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ax, MSG_META_GCN_LIST_REMOVE
	clr	bx				; use current thread
	call	GeodeGetAppObject		; ^lbx:si = app object
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size GCNListParams
	pop	si, bp
	retn

DestroyGeneratedUI	endp

;---

DestroyNormalUI	proc	near	uses ax, cx, dx, bp
	.enter

	mov	cx, mask GCIF_NORMAL_UI
	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	call	ObjCallInstanceNoLock

	call	SendDestroyUI

	.leave
	ret
DestroyNormalUI	endp

SendDestroyUI	proc	near
	.enter

	call	DerefVardata			; get variable data
	tst	ds:[bx].TGCI_childBlock		; have we created UI yet ??
	jz	done				; no, so do nothing
	mov	ax, MSG_GEN_CONTROL_DESTROY_UI
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
SendDestroyUI	endp



DestroyToolboxUI	proc	near	uses ax, cx, dx, bp
	.enter

	mov	cx, mask GCIF_TOOLBOX_UI
	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	call	ObjCallInstanceNoLock

	call	SendDestroyToolboxUI

	.leave
	ret
DestroyToolboxUI	endp

SendDestroyToolboxUI	proc	near
	.enter

	call	DerefVardata			; get variable data
	tst	ds:[bx].TGCI_toolBlock		; have we created toolbox yet ??
	jz	done				; no, so do nothing
	mov	ax, MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
SendDestroyToolboxUI	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlAddToUI -- MSG_GEN_CONTROL_ADD_TO_UI for
		GenControlClass

DESCRIPTION:	Add the controller to the GCN lists that it needs to be on
		to fuction correctly (usually SELF_LOAD_OPTIONS or
		STARTUP_LOAD_OPTIONS and occasionally ACTIVE)


PASS:
	*ds:si - instance data
	es - segment of GenControlClass

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
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
GenControlAddToUI	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_ADD_TO_UI

	; we need to add this object to all lists that it is supposed to be on

	mov	ax, MSG_META_GCN_LIST_ADD
	GOTO	AddOrRemoveSelfToAppropriateLists

GenControlAddToUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlRemoveFromUI -- MSG_GEN_CONTROL_REMOVE_FROM_UI for
		GenControlClass

DESCRIPTION:	Remove the controller from the GCN lists that it needs to
		be on to fuction correctly (usually SELF_LOAD_OPTIONS or
		STARTUP_LOAD_OPTIONS and occasionally ACTIVE)

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

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
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
GenControlFinalObjFree	method	dynamic	GenControlClass,
						MSG_META_FINAL_OBJ_FREE

	mov	ax, MSG_GEN_CONTROL_REMOVE_FROM_UI
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset GenControlClass
	GOTO	ObjCallSuperNoLock
GenControlFinalObjFree	endm

GenControlRemoveFromUI	method dynamic	GenControlClass,
						MSG_GEN_CONTROL_REMOVE_FROM_UI

	mov	ax, MSG_META_GCN_LIST_REMOVE
	FALL_THRU	AddOrRemoveSelfToAppropriateLists

GenControlRemoveFromUI	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	AddOrRemoveSelfToAppropriateLists

DESCRIPTION:	Add or remove this object to appropriate GCN lists

CALLED BY:	INTERNAL

PASS:
	*ds:si - controller
	ax - messsage (MSG_META_GCN_LIST_ADD or MSG_META_GCN_LIST_REMOVE)

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/19/92		Initial version

------------------------------------------------------------------------------@
AddOrRemoveSelfToAppropriateLists	proc	far
dupinfo		local	GenControlBuildInfo
	.enter

	call	GetDupInfo
	mov	bx, ds:[LMBH_handle]	;bxsi = object to add/remove (ourself)

	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_ACTIVE_LIST
	jz	afterActive
	call	AddOrRemoveActiveListEntry
afterActive:

	test	dupinfo.GCBI_flags,
			mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST
	jnz	done

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GAGCNLT_STARTUP_LOAD_OPTIONS or mask GCNLTF_SAVE_TO_STATE
	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_START_LOAD_OPTIONS_LIST
	jnz	gotOptionsList
	mov	dx, GAGCNLT_SELF_LOAD_OPTIONS or mask GCNLTF_SAVE_TO_STATE
gotOptionsList:
	call	AddOrRemoveListEntry
done:
	.leave
	ret

AddOrRemoveSelfToAppropriateLists	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlFindKbdAccelerator

DESCRIPTION:	Make sure the UI's built out before looking further downward
		for a keyboard accelerator.   The default GenClass handler
		for this will inc/dec the interactible count around the test
		for usable + enabled + accelerator match, to ensure that 
		we've updated all of these states correctly before the test
		is made.

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - MSG_GEN_FIND_KBD_ACCELERATOR
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN: carry - set if accelerator found

DESTROYED:
	ax, cx, dx, bp
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version

------------------------------------------------------------------------------@
GenControlFindKbdAccelerator	method dynamic	GenControlClass,
					MSG_GEN_FIND_KBD_ACCELERATOR
	; We shouldn't bother generating UI for this controller if it is not
	; usable. - Joon (6/22/93)
	;
	test	ds:[di].GI_states, mask GS_USABLE
	jz	callSuper

	push	ax, cx, dx, bp

	call	DerefVardata
	tst	ds:[bx].TGCI_childBlock
	jnz	alreadyBuilt
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock
alreadyBuilt:

	mov	di, offset GenControlClass

	call	DerefVardata
	test	ds:[bx].TGCI_interactableFlags, mask GCIF_CONTROLLER
	jnz	goAhead
	;
	; If the controller is not interactable, make it so.  This
	; needs to happen so that the controller will become enabled
	; appropriately, so that it's children can become enabled
	; as well. -- eca 7/14/92
	;
	mov	ax, MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	cx, mask GCIF_CONTROLLER
	call	ObjCallInstanceNoLock

	pop	ax, cx, dx, bp
	call	ObjCallSuperNoLock
	;
	; Once we've checked the keyboard shortcuts, we can make the
	; controller not interactable again.
	;
	pushf					;save carry from superclass
	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	mov	cx, mask GCIF_CONTROLLER
	call	ObjCallInstanceNoLock
	popf
	ret

goAhead:
	pop	ax, cx, dx, bp
callSuper:
	mov	di, offset GenControlClass
	GOTO	ObjCallSuperNoLock

GenControlFindKbdAccelerator	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to a "reset" request

CALLED BY:	GLOBAL (MSG_GEN_RESET)

PASS:		*DS:SI	= GenControlClass object
		DS:DI	= GenControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX

PSEUDO CODE/STRATEGY:
		We simply re-add ourselves to the GCN list, which will
		cause the cached data to be re-sent.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlReset	method dynamic	GenControlClass, MSG_GEN_RESET

	; Only re-add ourselves to the GCN list if either:
	;	a) We are always on a GCN list, or
	;	b) We are currently interactible
	;
	call	GetControllerFlags
	test	ax, mask GCBF_ALWAYS_INTERACTABLE
	jnz	addToList
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarFindData
	jnc	exit
	test	ds:[bx].TGCI_interactableFlags, \
			mask GCIF_CONTROLLER or \
			mask GCIF_TOOLBOX_UI or \
			mask GCIF_NORMAL_UI
	jz	exit
addToList:
	mov	ax, MSG_META_GCN_LIST_ADD
	call	AddToGCNLists
exit:
	ret
GenControlReset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlAddAppUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method adds the app UI as the last child of the
		controller.

CALLED BY:	GLOBAL
PASS:		^lCX:DX <- object to add
RETURN:		nada
DESTROYED:	bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenControlAddAppUI	method	GenControlClass, MSG_GEN_CONTROL_ADD_APP_UI
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	call	ECCheckLMemOD						>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
	mov	bp, CCO_LAST
	mov	ax, MSG_GEN_ADD_CHILD
	GOTO	ObjCallInstanceNoLock
GenControlAddAppUI	endm

GenControlAddAppToolboxUI method GenControlClass,
					MSG_GEN_CONTROL_ADD_APP_TOOLBOX_UI
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
EC <	call	ECCheckLMemOD						>
EC <	xchg	bx, cx							>
EC <	xchg	si, dx							>
	call	DerefVardata
	mov	si, ds:[bx].TGCI_toolParent.chunk
	mov	bx, ds:[bx].TGCI_toolParent.handle
	mov	bp, CCO_LAST
	mov	ax, MSG_GEN_ADD_CHILD
	mov	di, mask MF_CALL
	GOTO	ObjMessage
GenControlAddAppToolboxUI	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	RemoveAppUI

DESCRIPTION:	Remove application specified UI

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenControl object
	ax - ATTR holding App UI elements (as list of optrs)

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
RemoveAppUI	proc	near	uses	bp
	.enter

	; Set the app-specified UI not usable and remove it.

	mov	bp, bx				;keep flag in bp
	clr	di				;di is pointer into the vardata
removeUILoop:
	call	ObjVarFindData
	jnc	done
	VarDataSizePtr	ds, bx, cx
	cmp	cx, di
	jz	done

	; remove the application-specified ui (set it not usable, and remove
	; it from the parent.

	push	ax, si, di, bp
	mov	si, ds:[bx][di].chunk	;^lcx:dx <- app-supplied object/tree
	mov	bx, ds:[bx][di].handle
	mov	ax, MSG_GEN_REMOVE
	mov	dl, VUM_NOW
	clr	bp
	call	CO_ObjMessageFixupDS
	pop	ax, si, di, bp

	add	di, size optr
	jmp	removeUILoop
done:
	.leave
	ret

RemoveAppUI	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlDestroyUI -- MSG_GEN_CONTROL_DESTROY_UI for
							GenControlClass

DESCRIPTION:	Destroy the UI for the controller

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

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
	Tony	11/20/91		Initial version

------------------------------------------------------------------------------@
GenControlDestroyUI	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_DESTROY_UI
dupinfo		local	GenControlBuildInfo
	.enter

	mov	ax, ATTR_GEN_CONTROL_APP_UI
	call	RemoveAppUI

	; if no children then exit

	call	DerefVardata
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	tst	bx
	LONG jz	done

	; call ourself to get the information

	call	GetDupInfo

	mov	dx, dupinfo.GCBI_childCount
	tst	dx
	jz	afterChildren

	mov	di, offset GCBI_childList
	call	LockTableESDI			;es:di = child list

	; loop to remove the children (and set them not usable)
	;	*ds:si - controller
	;	ax - features flags
	;	bx - child block
	;	dx - count
	;	es:di - list

	push	si
childLoop:
	test	es:[di].GCCI_flags, mask GCCF_ALWAYS_ADD
	jnz	nukeIt
	test	ax, es:[di].GCCI_featureMask
	jz	nextChild
nukeIt:

	push	si, ax, dx, bp
	mov	si, es:[di].GCCI_object		;bx:si = child
	mov	dl, VUM_NOW
	clr	bp
	mov	ax, MSG_GEN_REMOVE
	call	CO_ObjMessageFixupDS
	pop	si, ax, dx, bp

nextChild:
	add	di, size GenControlChildInfo
	dec	dx
	jnz	childLoop
	pop	si

	mov	di, offset GCBI_childList
	call	UnlockTableDI

afterChildren:

	; free the child block

		; I THINK we can actually dispense w/all of this.  We're
		; nuking the block anyway, so the object block output will
		; certainly be nuked at that point, & I can't think of 
		; any problems that will occur if we just wait to receive
		; the MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE naturally,
		; so let's give a shot at this simpler approach.
		;			-- Doug 5/11/92
		; NO, we can't, because we clear out our child block pointer
		; below, and MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE
		; (if/when it ever comes in) will just exit, so we have to
		; do this now - Drew 1/8/93


	push	ax, bx, si, ds
	call	ObjLockObjBlock
	mov	ds, ax
	clr	bx
	clr	si
	call	ObjBlockSetOutput
	tst	ds:[OLMBH_interactibleCount]	; check interactible count
	pop	ax, bx, si, ds
	call	MemUnlock			; preserves flags

	; If in-use count is non-zero, we must fake a
	; MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE so that various good stuff
	; happens (like dec'ing *our* interactible count).  Since we clear the
	; TGCI_childBlock below, we can't rely on the normal sending of
	; MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE when the child block's
	; interactible count actually goes to zero, hence we clear the
	; output above.

	jz	inUseZero			; we got the MSG normally
	mov	cx, bx				; cx = child block
	mov	ax, MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE
	call	ObjCallInstanceNoLock		; preserves bx, si
inUseZero:

;
;	Send a message to free this block up via the queue, in case there 
;	is a message queued up for it (the problem we had was that the
;	PenInputControl has a view/content in its child block, so a
;	MSG_META_CONTENT_VIEW_WIN_OPENED is queued up for the content, so
;	if we call ObjFreeObjBlock before that message comes in, the system
;	will die trying to do a VisOpen when the block is being destroyed.
;
	mov	cx, bx			;CX <- handle of block
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_CONTROL_FREE_OBJ_BLOCK
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; update the vardata

	call	DerefVardata
	clr	ds:[bx].TGCI_childBlock
	clr	ds:[bx].TGCI_features
	and	ds:[bx].TGCI_upToDate, not mask GCIF_NORMAL_UI
	
	; This is the second half of the check in MSG_GEN_CONTROL_NOTIFY_-
	; NOT_INTERACTABLE for TGCI_childBlock being non-zero and remaining
	; on the active list if so. If no part of the controller is interactible
	; then we need to remove ourselves from the active list now the children
	; are gone. -- ardeb 5/11/95

	tst	ds:[bx].TGCI_interactableFlags
	jnz	done		; some part is interactible, still
	
	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_ACTIVE_LIST or \
				mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST
	jnz	done		; always on active list or let subclass handle
				;  removal

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	bx, ds:[LMBH_handle]
	call	AddOrRemoveActiveListEntry

done:
	.leave
	ret
GenControlDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlFreeObjBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls ObjFreeObjBlock with the passed block

CALLED BY:	GLOBAL
PASS:		cx - block to free
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenControlFreeObjBlock	method	GenControlClass, MSG_GEN_CONTROL_FREE_OBJ_BLOCK
	.enter
	mov	bx, cx
	call	ObjFreeObjBlock
	Destroy	ax, cx, dx, bp
	.leave
	ret
GenControlFreeObjBlock	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlDestroyToolboxUI -- MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI
							for GenControlClass

DESCRIPTION:	Destroy the UI for the controller's toolbox

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

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
	Tony	11/20/91		Initial version

------------------------------------------------------------------------------@
GenControlDestroyToolboxUI	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI

	mov	ax, ATTR_GEN_CONTROL_APP_TOOLBOX_UI
	call	RemoveAppUI

	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	mov	cx, mask GCIF_TOOLBOX_UI
	call	ObjCallInstanceNoLock

	; Fetch Tool Holder object & set all children not usable, remove them.
	;
	push	si
	call	DerefVardata
	mov	si, ds:[bx].TGCI_toolParent.chunk
	mov	bx, ds:[bx].TGCI_toolParent.handle
	call	ObjSwapLock
nextChild:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GI_comp.CP_firstChild.handle
	mov	dx, ds:[di].GI_comp.CP_firstChild.chunk
	tst	cx
	jz	childrenGone

	; ^lcx:dx = child object to set not usable & remove

	push	bx, si
	mov	bx, cx
	mov	si, dx
;	mov	ax, MSG_GEN_REMOVE
;	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	; in case we're "re-doing" the
;						; toolbox, avoid doing geometry
;						; twice.
;	clr	bp
;	call	CO_ObjMessageFixupDS
;The above is insufficient -- the SET_NOT_USABLE in GEN_REMOVE may not cause
;unbuilding if the child object is not *fully* usable.  It won't be fully
;usable if the toolbox UI is being destroyed because some object containing
;both the controller and the tool group (in that order) is being set not
;usable.  The problem occurs because we are removing the children from the
;gen tree before the UNBUILD (from the original set not usable) can get to
;them.  The side effect of this fix is that toolbox UI destruction may be
;slightly slower as SPEC_SET_NOT_USABLE may happen twice. - brianc 6/13/95
	call	ObjSwapLock			; *ds:si = child object
						; bx = tool group handle
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjCallInstanceNoLock
	call	GenCheckIfSpecGrown
	jnc	notGrown
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_SPEC_SET_NOT_USABLE
	call	ObjCallInstanceNoLock
notGrown:
	clr	bp
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	GenCallParent
	call	ObjSwapUnlock
;end of change

	pop	bx, si
	jmp	short nextChild

childrenGone:
	call	ObjSwapUnlock
	pop	si

	; Then, nuke the duplicated tool block, & clear out references to
	; the tools.
	;
	call	DerefVardata
	clr	cx
	and	ds:[bx].TGCI_upToDate, not mask GCIF_TOOLBOX_UI
	mov	ds:[bx].TGCI_toolParent.handle, cx
	mov	ds:[bx].TGCI_toolParent.chunk, cx
	mov	ds:[bx].TGCI_toolboxFeatures, cx
	xchg	cx, ds:[bx].TGCI_toolBlock	;CX <- child block to free
;
;	Send a message to free this block up via the queue, in case there 
;	is a message queued up for it (the problem we had was that the
;	PenInputControl has a view/content in its child block, so a
;	MSG_META_CONTENT_VIEW_WIN_OPENED is queued up for the content, so
;	if we call ObjFreeObjBlock before that message comes in, the system
;	will die trying to do a VisOpen when the block is being destroyed.
;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_CONTROL_FREE_OBJ_BLOCK
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
GenControlDestroyToolboxUI	endm



COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlAddFeature -- MSG_GEN_CONTROL_ADD_FEATURE
							for GenControlClass

DESCRIPTION:	Add a feature (allow the user to access it)

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx - flag for feature to add

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
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GenControlAddFeature	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_ADD_FEATURE

	; add the appropriate hint

	clr	dx
	call	AddUserFeatureHint

	FALL_THRU	GenControlRebuildNormalUI

GenControlAddFeature	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlRebuildNormalUI -- MSG_GEN_CONTROL_REBUILD_NORMAL_UI
							for GenControlClass

DESCRIPTION:	Rebuild the normal UI

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

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
	Don	5/15/92		Initial version

------------------------------------------------------------------------------@

GenControlRebuildNormalUI	method	GenControlClass,
				MSG_GEN_CONTROL_REBUILD_NORMAL_UI

	call	SendToSuperIfFlagSet

	; only rebuild in built currently

	call	DerefVardata
	tst	ds:[bx].TGCI_childBlock
	jz	done

	call	SendDestroyUI
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock

	; Notify Toolbox of feature change

	mov	ax, mask GCSF_NORMAL_FEATURES_CHANGED
	call	ControlSendStatusChange

	; MSG_GEN_CONTROL_GENERATE_UI uses VUM_MANUAL thinking it was
	; initiated because of a visual update, however, that is not the
	; case here, so we update ourselves

	mov	ax, MSG_GEN_UPDATE_VISUAL
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	; if we are a dialog box then we want to reset our geometry

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jnz	afterDialog
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
afterDialog:

done:

	ret

GenControlRebuildNormalUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlRemoveFeature -- MSG_GEN_CONTROL_REMOVE_FEATURE
							for GenControlClass

DESCRIPTION:	Remove a feature (don't allow the user to access it)

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx - flag for feature to remove

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
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GenControlRemoveFeature	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_REMOVE_FEATURE

	; add the appropriate hint

	mov	dx, cx
	clr	cx
	call	AddUserFeatureHint

	GOTO	GenControlRebuildNormalUI

GenControlRemoveFeature	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlAddToolboxFeature --
		MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE for GenControlClass

DESCRIPTION:	Add a feature (allow the user to access it)

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx - flag for features to add

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
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GenControlAddToolboxFeature	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_ADD_TOOLBOX_FEATURE

	; add the appropriate hint

	clr	dx
	call	AddUserToolboxFeatureHint

	FALL_THRU	GenControlRebuildToolboxUI

GenControlAddToolboxFeature	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlRebuildToolboxUI -- MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI
							for GenControlClass

DESCRIPTION:	Rebuild the toolbox UI

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

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
	Don	5/15/92		Initial version

------------------------------------------------------------------------------@

GenControlRebuildToolboxUI	method	GenControlClass,
				MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI

	call	DerefVardata
	tst	ds:[bx].TGCI_toolParent.handle
	jz	done
;
;	Nuked this check, as this can be called when adding a toolbox feature
;	when none existed before (and hence, no toolbox was around).
;
;	tst	ds:[bx].TGCI_toolBlock
;	jz	done

	pushdw	ds:[bx].TGCI_toolParent		; Save parent of tools

	; Destroy the existing UI, and regenerate it
	;
	call	SendDestroyToolboxUI

	popdw	cxdx					; Get parent for tools
	mov	ax, MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
	call	ObjCallInstanceNoLock

	; Notify Toolbox of toolbox feature change
	;
	mov	ax, mask GCSF_TOOLBOX_FEATURES_CHANGED
	call	ControlSendStatusChange
done:
	ret
GenControlRebuildToolboxUI	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlRemoveToolboxFeature --
		MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE for GenControlClass

DESCRIPTION:	Remove a feature (don't allow the user to access it)

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

	ax - The message

	cx - flag for features to remove

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
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GenControlRemoveToolboxFeature	method dynamic	GenControlClass,
					MSG_GEN_CONTROL_REMOVE_TOOLBOX_FEATURE

	; add the appropriate hint

	mov	dx, cx
	clr	cx
	call	AddUserToolboxFeatureHint

	GOTO	GenControlRebuildToolboxUI

GenControlRemoveToolboxFeature	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddUserFeatureHint

DESCRIPTION:	Add a hint for a given user feature

CALLED BY:	INTERNAL

PASS:
	*ds:si - controller
	cx - bits to add
	dx - bits to remove

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
AddUserToolboxFeatureHint	proc	near
	mov	di, mask GCUF_USER_TOOLBOX_UI
	mov	bx, offset GCUD_userAddedToolboxUI
	GOTO	FeatureHintCommon

AddUserToolboxFeatureHint	endp

AddUserFeatureHint	proc	near
	mov	di, mask GCUF_USER_UI
	mov	bx, offset GCUD_userAddedUI
	FALL_THRU	FeatureHintCommon

AddUserFeatureHint	endp

FeatureHintCommon	proc	near
	call	EnsureOptionsLoaded
	push	bx
	mov	ax, HINT_GEN_CONTROL_USER_MODIFIED_UI
	call	ObjVarDerefData
	pop	ax
	or	ds:[bx].GCUD_flags, di
	add	bx, ax
	or	ds:[bx], cx
	or	ds:[bx+2], dx
	not	cx
	not	dx
	and	ds:[bx], dx
	and	ds:[bx+2], cx
	ret

FeatureHintCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlSaveOptions -- MSG_META_SAVE_OPTIONS
							for GenControlClass

DESCRIPTION:	Save the state of the features in the .ini file

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

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
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GenControlSaveOptions	method dynamic	GenControlClass, MSG_META_SAVE_OPTIONS
dupinfo		local	GenControlBuildInfo
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
userData	local	GenControlUserData
	ForceRef dupinfo

; See note at end -- Doug 1/93
;	push	ds:[LMBH_handle], si

	.enter

	call	EnsureOptionsLoaded

	mov	ax, HINT_GEN_CONTROL_USER_MODIFIED_UI
	call	ObjVarFindData
	jnc	done

	push	si
	mov	si, bx				;ds:si = source
	segmov	es, ss
	lea	di, userData			;es:di = dest
	mov	cx, size GenControlUserData
	rep	movsb
	pop	si

	call	GetDupInfo

	; get the category string

	mov	cx, ss
	lea	dx, categoryBuffer
	call	UserGetInitFileCategory		; get .ini category

	call	LoadCatAndKey
	jcxz	noKey

	push	bp
	mov	bp, size GenControlUserData
	call	InitFileWriteData
	pop	bp

noKey:
	call	UnlockIniKey
done:
	.leave

; Optimization -- Do NOT call superclass.  This prevents any superclass
; of GenControlClass from ever getting MSG_META_RESET_OPTIONS, but the need
; is not there, so we'll take it away in the name of speed. -- Doug 1/93
;
;	pop	bx, si
;	call	MemDerefDS
;	mov	ax, MSG_META_SAVE_OPTIONS
;	call	GC_SendToSuper

	ret

GenControlSaveOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenControlResetOptions -- MSG_META_RESET_OPTIONS
							for GenControlClass

DESCRIPTION:	Reset options

PASS:
	*ds:si - instance data
	es - segment of GenControlClass

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
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
GenControlResetOptions	method dynamic	GenControlClass, MSG_META_RESET_OPTIONS

	mov	ax, HINT_GEN_CONTROL_USER_MODIFIED_UI
	call	ObjVarFindData
	jnc	done
	call	ObjVarDeleteData
	call	GenControlRebuildNormalUI
	call	GenControlRebuildToolboxUI
done:
	ret

GenControlResetOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlNotInteractable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	One or more areas of the Controller are no longer 
		interactable.  If no areas left interactable, we can
		remove ourselves from the notification list(s)

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE

		cx - bits to reset

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlNotInteractable	method dynamic GenControlClass,
					MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
dupinfo		local	GenControlBuildInfo
	.enter

	call	DerefVardata

	not	cx
	and	ds:[bx].TGCI_interactableFlags, cx
	jnz	done


	; remove ourselves from the notification lists, since no portions
	; of the controller need to know about updates.

	call	GetDupInfo
	test	dupinfo.GCBI_flags, mask GCBF_ALWAYS_ON_GCN_LIST
	jnz	alwaysOnGCNList
	push	bp
	mov	ax, MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
	call	ObjCallInstanceNoLock
	pop	bp

alwaysOnGCNList:

	; If Controller was added to active list to receive MSG_META_DETACH,
	; remove it now, as nothing is interactable anymore

	test	dupinfo.GCBI_flags, mask GCBF_IS_ON_ACTIVE_LIST or \
				    mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST
	jnz	done				; if always on active list,
						;	leave it there

	; If Controller has childBlock, then don't remove from active list.
	; We need to remain on the active list so we'll get a detach to
	; rid ourselves of the child block. - Joon (6/23/93)

	call	DerefVardata
	tst	ds:[bx].TGCI_childBlock
	jnz	done

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	bx, ds:[LMBH_handle]
	call	AddOrRemoveActiveListEntry
done:
	.leave
	ret

GenControlNotInteractable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlRemoveFromGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Remove ourselves from any GCN lists we're on.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenControlRemoveFromGCNLists	method dynamic GenControlClass,
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
	; Since we're coming off the GCN lists, & won't know if any updates
	; to it happen beyond this point, clear out the "up to date" flags
	; we have, to reflect that these objects may be out of date past
	; this point.
	;
	push	ax, es
	call	DerefVardata
	clr	ds:[bx].TGCI_upToDate

	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	AddToGCNLists
	pop	ax, es

	call	SendToSuperIfFlagSet

	ret
GenControlRemoveFromGCNLists	endm


COMMENT @----------------------------------------------------------------------
FUNCTION:	ControlSendStatusChange

DESCRIPTION:	Send out notice about a change in this controller itself, for
		any toolboxes wishing to take note.

CALLED BY:	INTERNAL

PASS:		*ds:si	- this object
		ax	- GenControlStatusChange
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@

ControlSendStatusChange	proc	far	uses	ax, bx, cx, dx, di, bp
	.enter
	push	ax

	mov	ax, size NotifyGenControlStatusChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax

        ; Initialize Data block reference count to 1, for call to
	; MSG_META_GCN_LIST_SEND, which will decrement the count once
	; done.

	mov	ax, 1
	call	MemInitRefCount
	mov	ax, ds:[LMBH_handle]
	mov	es:[NGCS_controller].handle, ax
	mov	es:[NGCS_controller].chunk, si

	pop	es:[NGCS_statusChange]

	call	MemUnlock

	; bx = handle of data block

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_GEN_CONTROL_NOTIFY_STATUS_CHANGE
	mov	bp, bx
	mov	di, mask MF_RECORD
	call	ObjMessage			; get event to send in di

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_GEN_CONTROL_NOTIFY_STATUS_CHANGE
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0		; just send, no cache
	mov	ax, MSG_META_GCN_LIST_SEND
	call	GenCallApplication
	add	sp, size GCNListMessageParams
	.leave
	ret
ControlSendStatusChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlUnbuildIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	SPEC_UNBUILD the normal UI block of componentry, if this 
		is something that can be done.   Would be useful to be
		able to do on machines with low amounts of swap space,
		such as palmtops.


CALLED BY:	INTERNAL
		GenControlNotifyObjBlockNotInteractible

PASS:		*ds:si	- GenControl object
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	A refresher course on SPEC_BUILD/SPEC_UNBUILD:

	WIN_GROUPs get spec built on demand, when usable,
	attached & realizable.  On become not realizable, they visibly close
	only & give themselves a one-way upward link, setting a flag to
	let themselves know they've got this funny setup.
	(TREE_BUILT_BUT_NOT_REALIZED)

	SPEC_UNBUILD generally only happens as a direct result of becoming
	NOT_USABLE, but also can come an object's way if the visible object
	they sit on becomes NOT_USABLE.  In this case, the SPEC_UNBUILD
	message has the flag SBF_VIS_PARENT_UNBUILDING set, & results in
	only one of the non-WIN_GROUP/WIN_GROUP sides getting un-visbuilt.
	As unbuilds are mostly looked at as being set not-usable & going away,
	I'm not sure it clears the one-way upward link, figuring the vis
	data is about to be nuked anyway -- a bug that would have to be
	fixed if we were to attempt to SPEC_UNBUILD one side of a WIN_GROUP
	only dynamically without the other.

	Thoughts on dynamically unbuilding controllers:

	In the case where a controller is dual build, it should be
	possible to set children NOT_USABLE, remove them, & then fake
	a SBF_VIS_PARENT_UNBUILDING on oneself to cleanly unbuild just
	the WIN_GROUP side.  The next time the button is clicked on, the
	controller will become realizable again, & will be built out.

	With regards to non-win group portions, or controllers that aren't
	dual build, however, unbuilding means removing children from a
	visual tree having already been sized by the geometry manager.  As
	the wingroup is not visible, however, geometry won't be done until
	the window is asked to come back up.  If the controller's vis
	composite is at least left in the tree, then it will at least
	get geometry requests & VIS_OPEN when the window is realizable
	again.    As SPEC_BUILD is an operation that is invoked on
	generic trees, however, & this is a visual opening sequence, the
	controller will not receive any kind of SPEC_BUILD request.  The
	best you could shoot for would be to respond to the UPDATE_GEOMETRY
	message by visually building with VUM_MANUAL to avoid blowing up
	with a recursive visual update.  Might work...

	I don't believe there is any hope whatsoever in attempting
	to be able to visually unbuild the controller object itself, i.e.
	its non-win group part or visual shell if not dual-build, specifically
	because there is no message that would ever get to it that could
	be used to trigger the SPEC_BUILD.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	* Is currently NOT being used.
	  All specific UI gadets have not been required to deal with 
          SBF_VIS_PARENT_UNBUILDING in the past.  If we do decide we want to
          use this message (perhaps for Palmtop machines), we'll
          have to put some work into some of the UI gadgets so that they
          support this correctly.

	* Has only been tested for the case of GenStyleControl becoming a menu.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version
------------------------------------------------------------------------------@

GenControlUnbuildIfPossible method dynamic GenControlClass, \
				MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE
dupInfo		local	GenControlBuildInfo

	segmov	es, dgroup, ax			; SH
	tst	es:[unbuildControllers]
	jz	exit

	;
	; If HINT_GEN_CONTROL_DESTROY_CHILDREN_WHEN_NOT_INTERACTABLE is 
	; present, unbuild the children even if the controller has 
	; ATTR_GEN_CONTROL_APP_UI present. This allows the app to provide
	; extra UI, and still have the controller destroy the children when
	; it is closed.
	;
	mov	ax, HINT_GEN_CONTROL_DESTROY_CHILDREN_WHEN_NOT_INTERACTABLE
	call	ObjVarFindData
	jc	destroyIt

	;
	; If the controller has appUI that has been added, we have no way
	; of knowing when this UI has been brought off-screen, so don't
	; unbuild the children.
	;
	mov	ax, ATTR_GEN_CONTROL_APP_UI
	call	ObjVarFindData
	jc	exit

destroyIt:
	; Check to see if interactable (in-use).  If so, it would be
	; a bad idea to nuke it from the user's point of view.  (Besides that,
	; it's unclear that the approach used here would work or not)
	;

	call	DerefVardata			;ds:bx = temp instance data
	test	ds:[bx].TGCI_interactableFlags, mask GCIF_NORMAL_UI
	jnz	exit

	cmp	cx, ds:[bx].TGCI_childBlock
	jne	exit

	; Next check if this object dual-builds, i.e. has both a button
	; & window part.  If so, we should theoretically be able to
	; unbuild the win-group part,  If not, there's little hope of
	; being able to unbuild.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jnz	dualBuild

;nonDualBuild:
	test	ds:[bx].TGCI_interactableFlags, mask GCIF_TOOLBOX_UI
	jnz	exit

;	It is difficult (if not impossible) to unbuild this controller if it
; 	is not a dual build controller, as its children do not lie in a
;	separate win group. It could be that this controller is the only
;	child of a dialog, or is in some other fairly safe situation. If
;	this is the case, the app can put the DESTROY_CHILDREN_WHEN_NOT_
;	INTERACTABLE attribute on the controller, and we will unbuild the
;	entire parent win group *of the controller*.
;
;	We avoid various sticky situations (dealing with multiple controllers
;	in a single win group, etc) by leaving the choice of behavior entirely
;	up to the app - by definition, if unbuilding the parent is the wrong
;	thing to do in a given situation, the app should not have put the
;	attribute on the controller.
;

	mov	ax, HINT_GEN_CONTROL_DESTROY_CHILDREN_WHEN_NOT_INTERACTABLE
	call	ObjVarFindData
	jnc	exit

	push	si
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	mov	bx, segment VisClass
	mov	si, offset VisClass
	mov	bp, mask SBF_VIS_PARENT_UNBUILDING
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di		;CX <- ClassedEvent
	pop	si
	
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	GOTO	ObjCallInstanceNoLock
	
exit:
	ret

dualBuild:

	; Make sure that the GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED bit
	; is not set before unbuilding the children

	.enter

	call	GetDupInfo
	test	dupInfo.GCBI_flags, mask GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED
	.leave
	jnz	exit

	; Instruct the specific UI to unbuild just the WIN_GROUP
	; portion of the GenInteraction that the Controller comes off of.
	;
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
				; Cheat -- use flag saying visible parent
				; that the window was on is going away.
				; Should unbuild window but leave button.
	mov	bp, mask SBF_VIS_PARENT_UNBUILDING
	GOTO	ObjCallInstanceNoLock

GenControlUnbuildIfPossible	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlOutputAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed event to the output of the controller

CALLED BY:	GLOBAL
PASS:		bp - event
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenControlOutputAction	method	GenControlClass, MSG_GEN_CONTROL_OUTPUT_ACTION
	mov	di, ds:[si]
	add	di, ds:[di].GenControl_offset
	movdw	cxdx, ds:[di].GCI_output
	mov	ax, MSG_GEN_OUTPUT_ACTION
	GOTO	ObjCallInstanceNoLock
GenControlOutputAction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlCheckIfInteractableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when a UserDoDialog is on the screen, to see
		if the passed object can get events.

CALLED BY:	GLOBAL
PASS:		cx:dx - object
RETURN:		carry set if in child block
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenControlCheckIfInteractableObject	method GenControlClass,
				MSG_META_CHECK_IF_INTERACTABLE_OBJECT
	.enter
	call	DerefVardata
	cmp	cx, ds:[bx].TGCI_childBlock
	stc
	je	exit

	mov	di, offset GenControlClass
	call	ObjCallSuperNoLock
exit:
	.leave
	ret
GenControlCheckIfInteractableObject	endp

CO_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
CO_ObjMessageFixupDS	endp

ControlObject ends

HelpControlCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenControlGetHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get help file for a controller

CALLED BY:	MSG_META_GET_HELP_FILE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenControlClass
		ax - the message

		cx:dx - buffer for help file name
RETURN:		cx:dx - filled (NULL string for none)
		carry - set if buffer filled

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	Normally objects check locally then gup to find the help file.
	For controllers, we use the library name unless
	ATTR_GEN_CONTROL_DO_NOT_USE_LIBRARY_NAME_FOR_HELP is present,
	in which case the normal behavior is used.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenControlGetHelpFile		method dynamic GenControlClass,
						MSG_META_GET_HELP_FILE
dupinfo		local	GenControlBuildInfo
	ForceRef dupinfo

	mov	ax, ATTR_GEN_CONTROL_DO_NOT_USE_LIBRARY_NAME_FOR_HELP
	call	ObjVarFindData
	jc	callSuper			;branch if present
	;
	; Get the name of the library to use for the help file name
	;
	.enter
	;
	; Call ourself to get the controller info
	;
	push	cx, dx, bp
	mov	cx, ss
	lea	dx, ss:dupinfo			;cx:dx = structure to fill in
	mov	ax, MSG_GEN_CONTROL_GET_INFO
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
	;
	; Get either the normal UI resource that is duplicated or the
	; tool UI resource that is duplicated (whichever is non-NULL).
	; From this we can get the library that defines the controller.
	;
	mov	bx, ss:dupinfo.GCBI_dupBlock
	tst	bx				;any handle?
	jnz	gotHandle
	mov	bx, ss:dupinfo.GCBI_toolBlock
EC <	tst	bx				;>
EC <	ERROR_Z	GEN_CONTROL_NO_DUP_BLOCKS	;>
gotHandle:
	;
	; Get the owner of the duplicated block (the library)
	;
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE ;ax <- MemGetInfoType
	call	MemGetInfo
	;
	; Get the permanent name of the library
	;
	mov	bx, ax				;bx <- handle of library
	mov	ax, GGIT_PERM_NAME_ONLY		;ax <- GeodeGetInfoType
	mov	es, cx
	mov	di, dx				;es:di <- ptr to buffer
	call	GeodeGetInfo
	;
	; NULL-terminate the name
	;
	mov	{char}es:[di+GEODE_NAME_SIZE], 0
	call	RemoveTrailingSpacesFromHelpFileName
	stc					;carry <- filename found

	.leave
	ret

callSuper:
	mov	ax, MSG_META_GET_HELP_FILE
	mov	di, offset GenControlClass
	GOTO	ObjCallSuperNoLock
GenControlGetHelpFile		endm

HelpControlCode	ends

