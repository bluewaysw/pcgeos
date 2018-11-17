COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taNotify.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------
	SendCharAttrParaAttrChange

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Low level utility routines for implementing the methods defined on
	VisTextClass.

	$Id: taNotify.asm,v 1.1 97/04/07 11:18:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; We put a stub routine in TextFixed to prevent unnecessary loading of
	; the TextAttributes resource

TextFixed segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextGenerateCursorPositionNotification --
		MSG_VIS_TEXT_GENERATE_CURSOR_POSITION_NOTIFICATION
		for VisTextClass

DESCRIPTION:	Generate cursor position notification

PASS:
	*ds:si - instance data
	ds:di - instance data
	es - segment of VisTextClass

	ax - The message

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/24/93		Initial version

------------------------------------------------------------------------------@
VisTextGenerateCursorPositionNotification	proc	far
			; MSG_VIS_TEXT_GENERATE_CURSOR_POSITION_NOTIFICATION
	class	VisTextClass

	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_TIME
	call	ObjVarDeleteData
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO
	call	ObjVarDeleteData
	mov	ax, mask VTNF_CURSOR_POSITION
	FALL_THRU	TA_SendNotification

VisTextGenerateCursorPositionNotification	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_SendNotification

DESCRIPTION:	Send a MSG_NOTIFY_WITH_DATA if needed.  Sends requested
		updates to the output, & to the TARGET GCN Lists if
		currently the target.  Optionally, if ax passed 0, will
		send zero notification status to all TARGET GCN Lists.
		This latter capability is utilized upon receiving
		LOST_TARGET, to clear any status events reflecting the state
		of this object.

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - VisTextNotificationFlags for things to send, or 0 to clear out
	     status events on all TARGET GCN Lists only.

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
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
TA_SendNotification	proc	far	uses ax, bx, cx, dx, di, bp
	class	VisTextClass
	.enter

EC <	call	T_AssertIsVisText					>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	;
	; See if we have any types -- if not, we shouldn't send
	; out any type or name notifications
	;
	test	ds:[di].VTI_storageFlags, mask VTSF_TYPES
	jnz	haveTypes
	andnf	ax, not (mask VTNF_NAME or mask VTNF_TYPE)
haveTypes:

	; if not editable then don't update most things
	; unless it is also targetable

	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jnz	editable
	test	ds:[di].VTI_state, mask VTS_TARGETABLE
	jnz	editable
	andnf	ax, mask VTNF_SELECT_STATE
editable:

	sub	sp, size VisTextGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].VTGNP_notificationTypes, ax

	; Test to see if normal update happening, or if we have just
	; lost the target, & therefore our eligibility to be updating
	; various APP_TARGET GCN lists.

	; To clear out references to our status as the current target, set
	; flag to create NULL status events, and send only to GCN lists,
	; not our output, which should get only real status info.

	mov	dx, mask VTNSF_NULL_STATUS or \
				mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS
	tst	ax
	jz	update

	; make sure that we need to send the method -- set flags for
	; destination

	clr	dx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jz	notSuspended

	; object is suspended -- add flags

	push	ax
	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData
	pop	ax
	or	ds:[bx].VTSD_notifications, ax
	jmp	done

notSuspended:
	;
	; If object is marked as "send when not targetable", then
	; make sure all GCN lists get updated, and ignore the
	; IS_TARGET flag
	;

	push	bx, ax
	mov	ax, ATTR_VIS_TEXT_NOTIFY_EVEN_IF_NOT_TARGETED
	call	ObjVarFindData
	pop	bx, ax
	jc	sendAnyway

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	noTarget
sendAnyway:
	ornf	dx, mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS
noTarget:

update:
	ornf	dx, mask VTNSF_SEND_AFTER_GENERATION
	mov	ss:[bp].VTGNP_sendFlags, dx

	mov	ax, MSG_VIS_TEXT_GENERATE_NOTIFY
	call	ObjCallInstanceNoLock

done:
	add	sp, size VisTextGenerateNotifyParams

	.leave
	ret

TA_SendNotification	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleCursorPositionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	turn off and/or delay cursor position notification

CALLED BY:	VisTextGenerateNotify

PASS:		*ds:si - VisTextClass object
		ss:bp - VisTextGenerateNotifyParams

RETURN:		ss:[bp].VTGNP_notificationTypes - new VisTextNotificationFlags
			(VTNF_CURSOR_POSITION may be cleared)
		carry set to send notifications
		carry clear if no notifications should be sent

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleCursorPositionNotification	proc	near
	uses	bx, cx, dx, di

	.enter

	test	ss:[bp].VTGNP_notificationTypes, mask VTNF_CURSOR_POSITION
	LONG jz	sendNotif			; no cur pos notification,
						;	send other notifs
	mov	ax, ATTR_VIS_TEXT_NOTIFY_CURSOR_POSITION
	call	ObjVarFindData			; ds:bx = threshold
	jnc	noCurPos
	mov	cx, ds:[bx]			; cx = threshold
	jcxz	updateCurPosTimeAndSend		; threshold = 0, always send
	call	TimerGetCount			; bx:ax = count
	movdw	dxdi, bxax			; dx:di = current time
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_TIME
	call	ObjVarFindData			; {dword}ds:bx = previous time
	jnc	updateCurPosTimeAndSend		; send now
	pushdw	dxdi				; save current time
	subdw	dxdi, ds:[bx]			; dxdi = time difference
	;wrap-around will generate notification
	clr	bx				; bxcx = threshold
	cmpdw	dxdi, bxcx
	popdw	dxdi				; restore current time
	jb	sendDelayed			; less than threshold, delay
updateCurPosTimeAndSend:
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_TIME
	mov	cx, size dword
	call	ObjVarAddData
	movdw	ds:[bx], dxdi			; store time
	jmp	short sendNotif

sendDelayed:
	;
	; send off a MSG_VIS_TEXT_GENERATE_CURSOR_POSITION_NOTIFICATION after
	; the threshold time
	;	cx = threshold
	;
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO
	call	ObjVarFindData
	jc	noCurPos			; timer already going
	mov	bx, ds:[LMBH_handle]		; else, start timer
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	dx, MSG_VIS_TEXT_GENERATE_CURSOR_POSITION_NOTIFICATION
	call	TimerStart
	push	bx				; save timer handle
	push	ax				; save timer ID
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO
	mov	cx, size TVTNCPIData
	call	ObjVarAddData
	pop	ds:[bx].TVTNCPID_id		; store timer ID
	pop	ds:[bx].TVTNCPID_handle		; store timer handle
noCurPos:
	;
	; if we are notifying of cursor position only and we aren't going
	; to for some reason, don't bother doing any notification work
	;
	cmp	ss:[bp].VTGNP_notificationTypes, mask VTNF_CURSOR_POSITION
	je	done				; (carry clear), don't send
						;	notifications
						; else, just clear cur pos
	andnf	ss:[bp].VTGNP_notificationTypes, not mask VTNF_CURSOR_POSITION
sendNotif:
	stc					; send notifications
done:
	.leave
	ret
HandleCursorPositionNotification	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextGenerateNotify -- MSG_VIS_TEXT_GENERATE_NOTIFY
							for VisTextClass

DESCRIPTION:	Generate notifications

PASS:
	*ds:si - instance data
	ds:di - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - VisTextGenerateNotifyParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/29/92		Initial version

------------------------------------------------------------------------------@
VisTextGenerateNotify	proc	far	; MSG_VIS_TEXT_GENERATE_NOTIFY
		class	VisTextClass
		
	test	ss:[bp].VTGNP_sendFlags,
			mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS
	jz	done
	;
	; See if we have any types -- if not, we shouldn't send
	; out any type or name notifications
	;
	test	ds:[di].VTI_storageFlags, mask VTSF_TYPES
	jnz	haveTypes
	andnf	ss:[bp].VTGNP_notificationTypes, \
				not (mask VTNF_NAME or mask VTNF_TYPE)
haveTypes:
	mov	ax, TEMP_VIS_TEXT_FREEING_OBJECT
	call	ObjVarFindData
	jc	done

	;
	; don't bother sending cursor position if not desired, or if
	; time threshold hasn't been reached
	;
	call	HandleCursorPositionNotification
	jnc	done			; don't send any notifications
	
	push	bp
	call	SendNotificationLow
	pop	bp
done:

		
	ret

VisTextGenerateNotify	endp

TextFixed ends

;-----

TextAttributes segment resource

NotifStruct	struct
    NS_routine	nptr.near
    NS_size	word
    NS_gcnType	GeoWorksNotificationType
    NS_appType	GeoWorksGenAppGCNListType
NotifStruct	ends

notificationTable	NotifStruct	\
	<GenSelectStateNotify, size NotifySelectStateChange,
			GWNT_SELECT_STATE_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>,
	<GenCharAttrNotify, size VisTextNotifyCharAttrChange,
			GWNT_TEXT_CHAR_ATTR_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<GenParaAttrNotify, size VisTextNotifyParaAttrChange,
			GWNT_TEXT_PARA_ATTR_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>,
	<GenTypeNotify, size VisTextNotifyTypeChange,
			GWNT_TEXT_TYPE_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_TYPE_CHANGE>,
	<GenSelectionNotify, VisTextNotifySelectionChange,
			GWNT_TEXT_SELECTION_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_SELECTION_CHANGE>,
	<GenCountNotify, size VisTextNotifyCountChange,
			GWNT_TEXT_COUNT_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_COUNT_CHANGE>,

	; The StyleSheet notification *must* come before the style notification

	<GenStyleSheetNotify, size NotifyStyleSheetChange,
			GWNT_STYLE_SHEET_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_TEXT_CHANGE>,
	<GenStyleNotify, size NotifyStyleChange,
			GWNT_STYLE_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_STYLE_TEXT_CHANGE>,

	<GenSearchReplaceEnableNotify, size NotifySearchReplaceEnableChange,
			GWNT_SEARCH_REPLACE_ENABLE_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_SEARCH_REPLACE_CHANGE>,
	<GenSpellEnableNotify, size NotifySpellEnableChange,
			GWNT_SPELL_ENABLE_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE>,
	<GenNameNotify, size VisTextNotifyNameChange,
			GWNT_TEXT_NAME_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_NAME_CHANGE>,
	<GenCursorPositionNotify, size VisTextCursorPositionChange,
			GWNT_CURSOR_POSITION_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_CURSOR_POSITION_CHANGE>,
	<GenHyperlinkabilityNotify, VisTextNotifyHyperlinkabilityChange,
			GWNT_TEXT_HYPERLINKABILITY_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_HYPERLINKABILITY_CHANGE>

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendNotificationLow

DESCRIPTION:	Implement MSG_VIS_TEXT_GENERATE_NOTIFY

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - VisTextGenerateNotifyParams

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/29/92		Initial version

------------------------------------------------------------------------------@
SendNotificationLow	proc	far

	mov	ax, size VisTextGenerateNotifyParams
	push	ax
	mov	bx, bp
	mov	cx, sp
	call	SwitchStackWithData
	mov	di, sp
	sub	cx, ss:[di+2+(size VisTextGenerateNotifyParams)].SL_savedStackPointer
	push	bx				;save original BP
	push	cx				;save offset

	mov	ax, ss:[bp].VTGNP_notificationTypes
	mov	bx, ss:[bp].VTGNP_sendFlags
	ornf	ss:[bp].VTGNP_sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	mov	cx, bp

notifFlags		local	VisTextNotificationFlags	\
				push	ax
sendFlags		local	VisTextNotifySendFlags		\
				push	bx
notifyParams		local	nptr			\
				push	cx
counter			local	word
notifPtr		local	nptr
gcnParams		local	GCNListMessageParams
getParams		local	VisTextGetAttrParams
charAttrToken		local	word
paraAttrToken		local	word
styleToken		local	word
styleDiffs		local	byte
charAttrChecksum	local	dword
paraAttrChecksum	local	dword
point			local	PointDWord
trans			local	TransMatrix
styleCD			local	StyleChunkDesc
	ForceRef gcnParams
	ForceRef getParams
	ForceRef charAttrToken
	ForceRef paraAttrToken
	ForceRef styleToken
	ForceRef styleDiffs
	ForceRef charAttrChecksum
	ForceRef paraAttrChecksum
	ForceRef point
	ForceRef trans
	ForceRef styleCD
	class	VisTextClass
	.enter

	; loop through the various notification types, generating a
	; structure for each and sending it

	clr	counter
	mov	notifPtr, offset notificationTable

generateLoop:
	test	sendFlags, mask VTNSF_NULL_STATUS
	jnz	doThisOne
	rol	notifFlags
	jnc	next
doThisOne:

	;
	; If NS_appType = 0, then this is a dummy entry. - Joon (8/7/94)
	;
	mov	di, notifPtr
	tst	cs:[di].NS_appType
	jz	next

	mov	di, notifyParams
	add	di, counter
	mov	bx, ss:[di].VTGNP_notificationBlocks
	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	alreadyInitialized
	clr	bx
alreadyInitialized:

	; if we're supposed to generate then do it

	test	sendFlags, mask VTNSF_SEND_ONLY
	jnz	afterGenerate
	call	CallGenNotify		;bx = data block (ref count = 1)
afterGenerate:

	mov	ss:[di].VTGNP_notificationBlocks, bx

	; if we're supposed to send then do it

	test	sendFlags, mask VTNSF_SEND_AFTER_GENERATION or \
							mask VTNSF_SEND_ONLY
	jz	next

	mov	di, notifPtr
	mov	dx, cs:[di].NS_gcnType

	; Don't send off search/spell enables if attrs say so.

	cmp	dx, GWNT_SEARCH_REPLACE_ENABLE_CHANGE
	jnz	afterSearchSpellCheck
	push	bx
	mov	ax, ATTR_VIS_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL
	call	ObjVarFindData
	pop	bx
	jc	noAppGCNListSend
afterSearchSpellCheck:

	test	sendFlags, mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS
	jz	noAppGCNListSend

	; Update the specified GenApplication GCNList status event with a
	; MSG_META_NOTIFY_WITH_DATA_BLOCK of the specified notification type,
	; with the specified status block.
	;
	call	UpdateAppGCNList

noAppGCNListSend:
	call	MemDecRefCount			;One less reference -- we
						;don't need block for ourself
						;anymore (balances init of
						;ref count to 1 at time of
						;creation)
next:
	add	counter, size word
	add	notifPtr, size NotifStruct
	cmp	notifPtr, (offset notificationTable) + (size notificationTable)
	LONG jnz generateLoop

	.leave

	; if we borrowed stack space we must copy the parameters back

	pop	cx				;stack offset
	pop	si				;old BP
	pop	di
	tst	di
	jz	noBorrow

recoverStack::
	mov	bx, di
	call	MemLock
	mov	es, ax
	sub	si, cx
	sub	si, 2					;es:si = dest

copyCommon:
	push	di
	segmov	ds, ss
	mov	di, bp					;ds:di = source
	xchg	si, di
	mov	cx, size VisTextGenerateNotifyParams
	rep movsb
	pop	di

	add	sp, size VisTextGenerateNotifyParams
	call	ThreadReturnStackSpace
	ret

	; we did not borrow any stack space, but we have to copy the
	; data back anyway

noBorrow:
	segmov	es, ss					;es:si = dest
	jmp	copyCommon

SendNotificationLow	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextForceControllerUpdate --
				MSG_META_UI_FORCE_CONTROLLER_UPDATE for VisTextClass

DESCRIPTION:	Send out update stuff

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx.dx - manufacturer ID, NotificationType to update
		or 0xffff.0xffff to update all

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/10/91		Initial version

------------------------------------------------------------------------------@
VisTextForceControllerUpdate	proc	far
					; MSG_META_UI_FORCE_CONTROLLER_UPDATE

	; assume all

	cmp	cx, 0xffff
	jz	sendAll

	; lookup in table

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jnz	done

	mov	di, offset notificationTable
	mov	cx, length notificationTable
	mov	ax, 0x8000
searchLoop:
	cmp	dx, cs:[di].NS_gcnType
	jz	common
	shr	ax
	add	di, size NotifStruct
	loop	searchLoop
done:
	ret

sendAll:
	mov	ax, mask VisTextNotificationFlags
	cmp	dx, 0xffff
	jz	common
	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
common:
	call	TA_SendNotification
	ret

VisTextForceControllerUpdate	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateAppGCNList

DESCRIPTION:	Updates GenApplication GCN list with status passed.

		Calls MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST on process, passing
		event consisting of update information for passed list.

CALLED BY:	INTERNAL
		TA_SendNotification

PASS:
	*ds:si - text object
	ss:bp - inherited variables
	bx - handle of status block, or zero if none, to be passed in
	     MSG_META_NOTIFY_WITH_DATA_BLOCK

RETURN:	
	none

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

		Assumes GeoWorks manufacturer types for GCNListType &
		NotificationType, and use of MSG_META_NOTIFY_WITH_DATA_BLOCK.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version, pulled out of
				TA_SendNotification because of its size (would
				not assemble).  Updated to provide info
				needed for optimizations.
------------------------------------------------------------------------------@
UpdateAppGCNList	proc	near
	class	VisTextClass
	.enter inherit SendNotificationLow

EC <	call	T_AssertIsVisText					>

	push	bx, dx, bp
	mov	di, notifPtr
	mov	di, cs:[di].NS_appType
	call	loadParams
	mov	ax, ATTR_VIS_TEXT_UPDATE_VIA_PROCESS
	call	ObjVarFindData
	jc	sendViaProcess
	push	si
	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_STACK or mask MF_FIXUP_DS   ;added fixup 7/15/93 cbh
							;ds needed at sendCommon
	call	ObjMessage
	pop	si
	jmp	sendCommon

sendViaProcess:
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST ; Update GCN list
	call	GenSendToProcessStack
sendCommon:
	pop	bx, dx, bp

	; if this is an GWNT_TEXT_PARA_ATTR_CHANGE then send the block to
	; the content also (if ATTR_VIS_TEXT_NOTIFY_CONTENT is set)

	cmp	dx, GWNT_TEXT_PARA_ATTR_CHANGE
	jnz	done

	push	bx
	mov	ax, ATTR_VIS_TEXT_DO_NOT_NOTIFY_CONTENT
	call	ObjVarFindData
	pop	bx
	jc	done

	; record a message to send to the content to update its GCN list

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].VI_link.LP_next.handle
	jz	done
	push	bx, bp
	push	si
	mov	di, VCGCNLT_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE
	call	loadParams
	mov	ax, MSG_META_GCN_LIST_SEND
	mov	bx, segment VisContentClass
	mov	si, offset VisContentClass
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage		;di = message
	mov	cx, di
	pop	si

	;
	; Send this directly -- if we send it via the queue, we'll eat
	; up gobs of handles and crash the system.  If this causes
	; stack space problems, then we'll have to borrow more
	;
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock 
	pop	bx, bp
done:
	.leave
	ret

	; load gcnParams -- di = list type

loadParams:
	push	di				;save list type
	call	MemIncRefCount			;one more reference, for send
	mov	di, notifPtr
	mov	dx, cs:[di].NS_gcnType
	push	bx, si, bp
	mov	bp, bx				;bp - block
	clrdw	bxsi
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, si, bp

	mov	gcnParams.GCNLMP_event, di

	mov	gcnParams.GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	pop	gcnParams.GCNLMP_ID.GCNLT_type
	mov	gcnParams.GCNLMP_block, bx

	; if clearing status, meaning we're no longer the target, set bit to
	; indicate this clearing should be avoided if the status will get
	; updated by a new target.

	mov	ax, mask GCNLSF_SET_STATUS
	tst	bx
	jnz	afterTransitionCheck
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:
	mov	gcnParams.GCNLMP_flags, ax

	mov	dx, size GCNListMessageParams	; create stack frame
	lea	bp, gcnParams
	retn

UpdateAppGCNList	endp

;---

GenSendToProcessStack	proc	near uses	bx, si, di
	.enter
	call	GeodeGetProcessHandle		; new thread model allows this
						;	- Doug 6/9/92
	clr	si
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	.leave
	ret

GenSendToProcessStack	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CallGenNotify

DESCRIPTION:	Generate notification block

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - block

RETURN:
	bx - block

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91		Initial version

------------------------------------------------------------------------------@
CallGenNotify	proc	near	uses di
	.enter inherit SendNotificationLow

	test	sendFlags, mask VTNSF_NULL_STATUS
	jnz	afterGenerate

	mov	di, notifPtr

	; allocate the block

	tst	bx
	jnz	afterAllocate

	mov	ax, cs:[di].NS_size
	mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	ax, 1
	call	MemInitRefCount
afterAllocate:

	call	MemLock
	mov	es, ax

	push	bx, si, ds
	clr	ax
	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jz	10$
	mov	ax, mask VTGAF_MERGE_WITH_PASSED
10$:
	mov	getParams.VTGAP_flags, ax
	mov	getParams.VTGAP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	getParams.VTGAP_attr.segment, es
	mov	getParams.VTGAP_return.segment, es
	call	cs:[di].NS_routine
	pop	bx, si, ds

	call	MemUnlock

afterGenerate:

	.leave
	ret

CallGenNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCharAttrNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - inherited variables
	es - notification block (locked)

RETURN:

DESTROYED:
	cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenCharAttrNotify	proc	near
	.enter inherit SendNotificationLow

	; Get the charAttr

	mov	getParams.VTGAP_attr.offset, offset VTNCAC_charAttr
	mov	getParams.VTGAP_return.offset, offset VTNCAC_charAttrDiffs

	push	bp
	lea	bp, getParams
	call	VisTextGetCharAttr
	pop	bp

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jz	storeToken
	cmp	ax, es:[VTNCAC_charAttrToken]
	jz	afterToken
	mov	ax, CA_NULL_ELEMENT
storeToken:
	mov	es:[VTNCAC_charAttrToken], ax
	mov	charAttrToken, ax
afterToken:

	; calculate the checksum for the structure

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	afterChecksum
	push	si, ds
	segmov	ds, es
	mov	si, offset VTNCAC_charAttr
	mov	cx, size VisTextCharAttr
	call	StyleSheetGenerateChecksum	;dxax = checksum
	pop	si, ds
	movdw	charAttrChecksum, dxax
afterChecksum:

	mov	ax, es:[VTNCAC_charAttr].VTCA_meta.SSEH_style
	mov	styleToken, ax

	clr	bx
	test	es:[VTNCAC_charAttrDiffs].VTCAD_diffs,
						mask VTCAF_MULTIPLE_STYLES
	jz	99$
	dec	bx
99$:
	mov	styleDiffs, bl

	.leave
	ret

GenCharAttrNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenParaAttrNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - inherited variables
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenParaAttrNotify	proc	near
	.enter inherit SendNotificationLow
	class	VisTextClass

	; Get the paraAttr

	mov	getParams.VTGAP_attr.offset, offset VTNPAC_paraAttr
	mov	getParams.VTGAP_return.offset, offset VTNPAC_paraAttrDiffs

	push	bp
	lea	bp, getParams
	call	VisTextGetParaAttr
	pop	bp

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jz	storeToken
	cmp	ax, es:[VTNPAC_paraAttrToken]
	jz	afterToken
	mov	ax, CA_NULL_ELEMENT
storeToken:
	mov	es:[VTNPAC_paraAttrToken], ax
	mov	paraAttrToken, ax
afterToken:

	; get the selected tab

	mov	cx, -1
	mov	ax, ATTR_VIS_TEXT_SELECTED_TAB
	call	ObjVarFindData
	jnc	noSelectedTab
	mov	cx, ds:[bx]
noSelectedTab:
	mov	es:VTNPAC_selectedTab, cx

	; get the region offset

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	ax, ds:[di].VTI_leftOffset
	cwd
	movdw	es:VTNPAC_regionOffset, dxax
	clr	cx				; first region

	;
	; If this text object is not the target, or if it's generic,
	; then just use the default region offset.
	;

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	afterRegionOffset

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jnz	afterRegionOffset

	push	bp
	lea	bp, point
	mov	cx, ds:[di].VTI_cursorRegion
	call	TR_RegionGetTopLeft
	pop	bp

	; if this is a small object add it the amount that the gstate
	; is translated

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	afterSmallTransform
	call	TextGStateCreate
	clr	cx
	clr	dx
	call	TR_RegionTransformGState
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate
	push	si, ds
	segmov	ds, ss
	lea	si, trans
	call	GrGetTransform
	pop	si, ds
	adddw	point.PD_x, trans.TM_e31.DWF_int, ax
	call	TextGStateDestroy
afterSmallTransform:

	; We need to find the region width, and for this we need to supply
	; a line height.  Since we don't have any line height handy, we
	; will use a reasonable default.  Since this is only used for drawing
	; the ruler this will work well enough.

	movdw	es:VTNPAC_regionOffset, point.PD_x, ax
afterRegionOffset:
	clr	dx
	mov	bx, VIS_TEXT_DEFAULT_POINT_SIZE
	call	TR_RegionWidth
	;
	; Check for a really large value.
	;
EC <	cmp	ax, 0xf000				>
EC <	ERROR_A	REGION_WIDTH_IS_NOT_REASONABLE		>

	mov	es:VTNPAC_regionWidth, ax

	; calculate the checksum for the structure

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	afterChecksum
	push	si, ds
	segmov	ds, es
	mov	si, offset VTNPAC_paraAttr
	mov	cx, size VisTextMaxParaAttr
	call	StyleSheetGenerateChecksum	;dxax = checksum
	pop	si, ds
	movdw	paraAttrChecksum, dxax
afterChecksum:

	.leave
	ret

GenParaAttrNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenTypeNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - inherited variables
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenTypeNotify	proc	near
	.enter inherit SendNotificationLow

	; Get the type

	mov	getParams.VTGAP_attr.offset, offset VTNTC_type
	mov	getParams.VTGAP_return.offset, offset VTNTC_typeDiffs

	push	bp
	lea	bp, getParams
	call	VisTextGetType
	pop	bp
	;
	; Convert the hyperlink and context references from tokens
	; to list indices because the controllers need them...
	;
	push	ax
	mov	ax, es:VTNTC_type.VTT_hyperlinkFile
	cmp	ax, CA_NULL_ELEMENT
	jne	doTokensToNames			 ;branch if a link
	inc	ax
	mov	es:VTNTC_index.VTT_hyperlinkFile, ax

	mov	ax, es:VTNTC_type.VTT_hyperlinkName
	cmp	ax, CA_NULL_ELEMENT
	jne	doTokensToNames
	mov	es:VTNTC_index.VTT_hyperlinkName, ax

	mov	ax, es:VTNTC_type.VTT_context
	cmp	ax, CA_NULL_ELEMENT
	jne	doTokensToNames
	mov	es:VTNTC_index.VTT_context, ax

	jmp	afterNames

doTokensToNames:
	push	bp
	clr	bp			;es:bp <- VisTextNotifyTypeChange
	call	TokensToNames
	pop	bp
afterNames:
	pop	ax

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jz	storeToken
	cmp	ax, es:[VTNTC_typeToken]
	jz	afterToken
	mov	ax, CA_NULL_ELEMENT
storeToken:
	mov	es:[VTNTC_typeToken], ax
afterToken:
	ornf	es:[VTNTC_typeDiffs], dx	;add any new differences

	.leave
	ret
GenTypeNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenNameNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a notifcation that names have changed

CALLED BY:	TA_SendNotification

PASS: 		*ds:si - instance data
		es - VisTextNotifyNameChange block (locked)
RETURN:		none

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenNameNotify		proc	near
	uses	ds
	.enter

	mov	ax, segment idata
	mov	ds, ax
	inc	ds:nameCount
	mov	ax, ds:nameCount
	mov	es:VTNNC_count, ax

	.leave
	ret
GenNameNotify		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenCursorPositionNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a notifcation that cursor position has changed

CALLED BY:	TA_SendNotification

PASS: 		*ds:si - instance data
		es - VisTextCursorPositionChange block (locked)
RETURN:		none

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenCursorPositionNotify		proc	near
	uses	bp
	.enter inherit SendNotificationLow

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	done

	call	TSL_SelectGetSelection		;dx.ax, cx.bx

	pushdw	dxax				;save cursor
	pushdw	dxax				;save cursor again

	clc
	call	TL_LineFromOffset		;bxdi = line within document

	call	TL_LineToOffsetStart		;dxax = line start
	popdw	cxbp				;cxbp = cursor
	subdw	cxbp, dxax			;cxbp = row number
	movdw	es:VTCPC_rowNumber, cxbp

	popdw	dxax				;dxax = cursor
	pushdw	bxdi				;save line
	call	TR_RegionFromLine		;cx = region
	call	TR_RegionGetTopLine		;bxdi = first line in page
	popdw	dxax				;dxax = line within document
	subdw	dxax, bxdi			;dxax = line within page
	movdw	es:VTCPC_lineNumber, dxax

done:
	.leave
	ret
GenCursorPositionNotify		endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSelectStateNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenSelectStateNotify	proc	near	uses bp
	.enter inherit SendNotificationLow
	class	VisTextClass

	mov	es:[NSSC_selectionType], SDT_TEXT
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	pushf					;save editable state

	; deal with cut/copy/delete

	mov	es:NSSC_selectAllAvailable, BB_TRUE

	call	TSL_SelectGetSelection		;dx.ax, cx.bx
	cmpdw	dxax, cxbx
	jz	noSelection

	pushdw	cxbx				; Push the end
	pushdw	dxax				; Push the start
	mov	bp, sp				; ss:bp <- ptr to the range

	; Added 8/26/99 by Tony for browser
	push	ax, bx
	mov	ax, ATTR_VIS_TEXT_ALLOW_CROSS_SECTION_COPY
	call	ObjVarFindData
	pop	ax, bx
	jc	copyable

	call	TR_CheckCrossSectionChange	; Carry set if cross section
	jc	notCopyable
copyable:
	mov	es:NSSC_clipboardableSelection, BB_TRUE
notCopyable:
	add	sp, size VisTextRange
	popf					;recover editable state
	jz	done				;finish if not editable
	
	;
	; Make sure that the selection doesn't cross a section break.
	;

if 1
	mov	es:NSSC_deleteableSelection, BB_TRUE
	jmp	afterSelection
else
	pushdw	cxbx				; Push the end
	pushdw	dxax				; Push the start
	mov	bp, sp				; ss:bp <- ptr to the range

	call	TR_CheckCrossSectionChange	; Carry set if cross section
	jc	notDeletable

	mov	es:NSSC_deleteableSelection, BB_TRUE

notDeletable:
	add	sp, 2 * size dword		; Restore stack
	jmp	afterSelection
endif

noSelection:
	popf					;recover editable state
	jz	done				;finish if not editable

afterSelection:
	; deal with paste

	clr	bp				;normal transfer
	call	ClipboardQueryItem		;fill our buffer with formats

	; does CIF_TEXT format exist ?

	tst	bp
	jz	cleanUp				; no transfer item
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT			;format to search for
	call	ClipboardTestItemFormat
	jnc	canPaste			;jump if valid assumption

	; how about CIF_GRAPHICS_STRING ?

	mov	dx, CIF_GRAPHICS_STRING		;format to search for
	call	ClipboardTestItemFormat
	jc	cleanUp

	; found graphics string -- can only use this if the object supports it

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_GRAPHICS
	jz	cleanUp

canPaste:
	mov	es:NSSC_pasteable, BB_TRUE
cleanUp:
	call	ClipboardDoneWithItem
done:
	.leave
	ret

GenSelectStateNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSelectionNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenSelectionNotify	proc	near
	.enter inherit SendNotificationLow

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	done

	call	TSL_SelectGetSelection		;dx.ax, cx.bx
	movdw	es:VTNSC_selectStart, dxax
	movdw	es:VTNSC_selectEnd, cxbx

	clc
	call	TL_LineFromOffset
	movdw	es:VTNSC_lineNumber, bxdi

	call	TL_LineToOffsetStart		;dxax = line start
	movdw	es:VTNSC_lineStart, dxax

	call	TR_RegionFromLine
	mov	es:VTNSC_region, cx

	call	TR_RegionFromOffsetGetStartLineAndOffset
	movdw	es:VTNSC_regionStartLine, bxdi
	movdw	es:VTNSC_regionStartOffset, dxax
done:
	.leave
	ret

GenSelectionNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenHyperlinkabilityNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/27/94		Initial version

------------------------------------------------------------------------------@
GenHyperlinkabilityNotify	proc	near
		.enter inherit SendNotificationLow

		test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
		jnz	done
	;
	; Only if the start and end of the selection differ is it
	; hyperlinkable. The value of the VTNHC_hyperlinkable field is
	; by default false since BW_FALSE = 0.
	;
		call	TSL_SelectGetSelection		;dx.ax, cx.bx
		cmpdw	dxax, cxbx
		je	done
		mov	es:VTNHC_hyperlinkable, BW_TRUE
done:
		.leave
		ret
GenHyperlinkabilityNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCountNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenCountNotify	proc	near
	.enter inherit SendNotificationLow

	call	TS_GetTextSize
	movdw	es:VTNCC_charCount, dxax

	call	TL_LineGetCount
	movdw	es:VTNCC_lineCount, dxax

	call	TS_GetWordCount
	movdw	es:VTNCC_wordCount, dxax

	call	TL_LineGetParaCount
	movdw	es:VTNCC_paraCount, dxax

	.leave
	ret

GenCountNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSearchReplaceEnableNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenSearchReplaceEnableNotify	proc	near
	.enter inherit SendNotificationLow
	class	VisTextClass

;	TELL THE SEARCH AND REPLACE BOX IF IT HAS A FRIENDLY OBJECT
;	AS THE TARGET.

	clr	cx
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	10$
	or	cl, mask SREF_SEARCH
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	10$		;Exit if not editable
	ornf	cl, mask SREF_REPLACE
10$:
	mov	es:NSREC_flags, cl

	.leave
	ret

GenSearchReplaceEnableNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSpellEnableNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenSpellEnableNotify	proc	near
	.enter inherit SendNotificationLow
	class	VisTextClass

;	TELL THE SPELL BOX IF IT HAS A FRIENDLY OBJECT
;	AS THE TARGET.

	clr	cx
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	10$
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	10$		;Branch if not editable
	mov	cx, -1		;
10$:
	mov	es:NSEC_spellEnabled, cx

	.leave
	ret

GenSpellEnableNotify	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenStyleNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	ss:bx - params
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenStyleNotify	proc	near
	.enter inherit SendNotificationLow

	mov	ax, charAttrToken
	mov	es:NSC_attrTokens[0], ax
	mov	ax, paraAttrToken
	mov	es:NSC_attrTokens[1 * (size word)], ax

	mov	ax, styleToken
	mov	bl, styleDiffs
	
	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	notFirst
	movdw	<es:NSC_attrChecksums[0*(size dword)]>, charAttrChecksum, dx
	movdw	<es:NSC_attrChecksums[1*(size dword)]>, paraAttrChecksum, dx
	mov	es:NSC_styleToken, ax
notFirst:

	cmp	es:NSC_styleToken, ax
	jz	noStyleDiffs
	mov	bl, -1
noStyleDiffs:
	or	es:NSC_indeterminate, bl

	; ax = style token

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	done

	tst	es:NSC_indeterminate
	jz	getStyle
	mov	ax, CA_NULL_ELEMENT
getStyle:

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GetStyleArray
	jnc	noStyles
	mov	di, offset NSC_style
	call	StyleSheetGetStyle			;ax = size, bx = used
	add	sp, size StyleChunkDesc

	segmov	ds, es
	mov	ds:NSC_styleSize, ax
	mov	ds:NSC_usedIndex, bx
	mov	ds:NSC_usedToolIndex, cx

	; we can "return to base style" is the current style differs from the
	; base style or if anything is indeterminate

	; we can "redefine style" is the current style differs from the
	; base style and if nothing is indeterminate

	clr	bx
	mov	ax, ({TextStyleElementHeader} ds:NSC_style).TSEH_charAttrToken
	cmp	ax, ds:NSC_attrTokens[0]
	jz	10$
	inc	bx
10$:
	test	({TextStyleElementHeader} ds:NSC_style).TSEH_privateData.\
				TSPD_flags, mask TSF_APPLY_TO_SELECTION_ONLY
	jnz	20$
	mov	ax, ({TextStyleElementHeader} ds:NSC_style).TSEH_paraAttrToken
	cmp	ax, ds:NSC_attrTokens[1 * (size word)]
	jz	20$
	inc	bx
20$:
	mov	cx, bx				;bx = return to base
						;cx = redefine
	cmp	charAttrToken, CA_NULL_ELEMENT
	jz	25$
	test	({TextStyleElementHeader} ds:NSC_style).TSEH_privateData.\
				TSPD_flags, mask TSF_APPLY_TO_SELECTION_ONLY
	jnz	30$
	cmp	paraAttrToken, CA_NULL_ELEMENT
	jnz	30$
25$:
	inc	bx
	clr	cx
30$:
	mov	ds:NSC_canReturnToBase, bl
	mov	ds:NSC_canRedefine, cl

	call	StyleSheetGetNotifyCounter
	mov	ds:NSC_styleCounter, ax

done:
	.leave
	ret

noStyles:
	add	sp, size StyleChunkDesc
	jmp	done

GenStyleNotify	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenStyleSheetNotify

DESCRIPTION:	Generate a notificiation structure

CALLED BY:	TA_SendNotification

PASS:
	ax - style token
	bl - style diffs
	*ds:si - instance data
	ss:bp - VisTextRange
	es - notification block (locked)

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@
GenStyleSheetNotify	proc	near
	.enter inherit SendNotificationLow
	class	VisTextClass

	test	sendFlags, mask VTNSF_STRUCTURE_INITIALIZED
	jnz	done

	mov	ax, ATTR_VIS_TEXT_STYLE_ARRAY
	call	ObjVarFindData
	jnc	done

	lea	bx, styleCD
	call	GetStyleArray

	mov	ax, styleCD.SCD_chunk
	mov	es:NSSHC_styleArray.SCD_chunk, ax
	mov	ax, styleCD.SCD_vmFile
	mov	es:NSSHC_styleArray.SCD_vmFile, ax
	mov	ax, styleCD.SCD_vmBlockOrMemHandle
	mov	es:NSSHC_styleArray.SCD_vmBlockOrMemHandle, ax

	call	StyleSheetGetStyleCounts
	mov	es:NSSHC_styleCount, ax
	mov	es:NSSHC_toolStyleCount, bx

	call	StyleSheetGetNotifyCounter
	mov	es:NSSHC_counter, ax

done:
	.leave
	ret

GenStyleSheetNotify	endp

TextAttributes ends
