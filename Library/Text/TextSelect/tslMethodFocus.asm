COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		tslMethodFocus.asm

AUTHOR:		John Wedgwood, Oct 25, 1989

METHODS:
	Name			Description
	----			-----------
	MSG_META_GAINED_FOCUS_EXCL
	MSG_META_LOST_FOCUS_EXCL
	MSG_META_GAINED_TARGET_EXCL
	MSG_META_LOST_TARGET_EXCL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/25/89		Initial revision

DESCRIPTION:


	$Id: tslMethodFocus.asm,v 1.1 97/04/07 11:20:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextSelect2 segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendTextFocusNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS notification.

CALLED BY:	GLOBAL
PASS:		bp - data to send out
		*ds:si - ink obj
RETURN:
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendTextFocusNotification	proc	far	uses	si
	class	VisTextClass
	.enter

;	No focus if we aren't editable

	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	exit

;	Check to see if the object is run by the UI thread - if so, set the
;	appropriate bit.

	clr	bx
	call	GeodeGetAppObject
	call	ObjTestIfObjBlockRunByCurThread
	jnz	notRunByUIThread
	ornf	bp, mask TFF_OBJECT_RUN_BY_UI_THREAD
notRunByUIThread:

;	Record event to send to ink controller

	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, mask GCNLSF_SET_STATUS
	test	bp, mask  TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	jnz	10$
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:

;	Send it to the appropriate gcn list

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_NOTIFY_FOCUS_TEXT_OBJECT
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax



;	If a UserDoDialog is running, the process thread could be blocked, so
;	send this directly to the app object.

	mov	ax, MSG_GEN_APPLICATION_CHECK_IF_RUNNING_USER_DO_DIALOG

	push	cx, dx, bp
	call	UserCallApplication
	pop	cx, dx, bp

	tst	ax			;If a UserDoDialog is active, send
	jnz	sendDirectly		; this directly on.
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
common:
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx
exit:
	.leave
	ret
sendDirectly:
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_META_GCN_LIST_SEND
	jmp	common
SendTextFocusNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal user that this object has gained the focus exclusive.

CALLED BY:	External. (Via MSG_META_GAINED_FOCUS_EXCL).
PASS:		ds:*si = pointer to VisTextInstance.
		es     = segment containing VisTextClass
		ax     = MSG_META_GAINED_FOCUS_EXCL.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGainedFocusExcl	proc	far	; MSG_META_GAINED_SYS_FOCUS_EXCL
	class	VisTextClass

ifdef	USE_FEP
	;
	; See if we should talk to the FEP
	;
	call	VTCheckFEP
	jc	noFEP
	;
	; Call the FEP
	;
	push	cx, dx, di
	mov 	ax, segment FepCallBack
	mov	bx, offset FepCallBack
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	di, DR_FEP_GAIN_FOCUS
	call	FepCallRoutine
	pop	cx, dx, di
noFEP:
endif	; USE_FEP

	call	TextGStateCreate

EC <	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS	>
EC <	ERROR_NZ VIS_TEXT_GAINED_FOCUS_ALREADY_FOCUS		>


	; Special case of going from just TARGET to TARGET & FOCUS.
	; In this case the appearance of the selection doesn't change so there
	; is no need to flash. This is only the case when there is a selection.
	; If there is just a cursor then we can't do this optimization.

	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	call	ObjVarFindData
	jnc	notTarget
	call	TSL_SelectIsCursor			; Is selection a cursor
	jc	notTarget				; Jump if is cursor
	or	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jmp	done
notTarget:
	call	EditUnHilite				; Remove old hilite.
	or	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS; This is the focus.
	call	EditHilite				; Draw new hilite.
done:


	call	TSL_StartCursorCommon

	; Send message to output in case user wants to handle this.

	mov	ax, MSG_META_TEXT_GAINED_FOCUS
	call	FarSendToTextOutput

	mov	bp, mask TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	call	SendTextFocusNotification

	call	T_CheckIfContextUpdateDesired
	jz	exit			;Exit if no context notification needed
	call	SendSelectionContext
exit:

	; Optimize MSG_META_KBD_CHAR travel time by grabbing the keyboard
	; exclusive whenever we have the system-wide focus.  -- Doug 9/17/92

	call	VisForceGrabKbd

	ret
VisTextGainedFocusExcl	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TSL_StartCursorCommon

DESCRIPTION:	Start the cursor going

CALLED BY:	StartCursorCommon

PASS:
	*ds:si - text object
	ds:di - text instance

RETURN:
	none

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@
TSL_StartCursorCommon	proc	far
	class	VisTextClass

	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	noTimer

	tst	ds:[di].VTI_timerHandle
	jnz	noTimer

	; start a timer to flash the cursor if the object is editable

	call	CheckNotEditable
	jc	noTimer

	; make sure "flashing" cursor is on

	call	FlowGetUIButtonFlags		;al = UIButtonFlags
	test	al, mask UIBF_BLINKING_CURSOR
	jz	noTimer

	mov	ax, MSG_VIS_TEXT_FLASH_CURSOR_ON
	call	ObjCallInstanceNoLock
noTimer:
	ret

TSL_StartCursorCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTCheckFEP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this text object 

CALLED BY:	VisTextGainedFocusExcl(), VisTextLostFocusExcl()
PASS:		*ds:si	= pointer to VisTextInstance
RETURN:		carry	= set if no FEP
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/17/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef	USE_FEP

VTCheckFEP		proc	near
	class	VisTextClass
	;
	; If not editable, forget the FEP
	;
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	noFEP
	;
	; See if we should interact with the FEP or not
	;
	mov	ax, ATTR_VIS_TEXT_NO_FEP
	call	ObjVarFindData
	jc	noFEP
	;
	; See if there is a filter that isn't FEP suitable.
	;
	mov	al, ds:[di].VTI_filters
	andnf	al, mask VTF_FILTER_CLASS
	cmp	al, VTFC_NUMERIC shl offset VTF_FILTER_CLASS
	jb	fepOK
	cmp	al, VTFC_FLOAT_DECIMAL shl offset VTF_FILTER_CLASS
	ja	fepOK
noFEP:
	stc					;carry <- no FEP
	ret

fepOK:
	clc					;carry <- FEP OK
	ret
VTCheckFEP		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLostFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal user that this object has lost the focus exclusive.

CALLED BY:	External. (Via MSG_META_LOST_FOCUS_EXCL).
PASS:		ds:*si = pointer to VisTextInstance.
		es     = segment containing VisTextClass
		ax     = MSG_META_LOST_FOCUS_EXCL
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLostFocusExcl	proc	far	; MSG_META_LOST_SYS_FOCUS_EXCL
	class	VisTextClass

EC <	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS	>
EC <	ERROR_Z	VIS_TEXT_LOST_FOCUS_NOT_FOCUS			>

	;
	; Try to kill the timer used to flash the cursor.  We may not
	; be successful, since the event may already be queued up.
	;
	mov	bx, ds:[di].VTI_timerHandle
	tst	bx
	jz	10$
	mov	ax, ds:[di].VTI_timerID
	call	TimerStop			; carry set if couldn't stop
	jc	10$
	;
	; Clear the timer handle only if we successfully stopped the
	; timer.  Otherwise, the gained_focus handler can, in some
	; situations, start an extra one (like in the UI's password
	; dialog).
	;
	clr	ds:[di].VTI_timerHandle
10$:

ifdef	USE_FEP
	;
	; See if we talked to the FEP before
	;
	call	VTCheckFEP
	jc	noFEP
	;
	; Call the FEP
	;
	push	cx, dx, di, bp
	sub	sp, size FepCallBackInfo
	mov	bp, sp
	mov 	cx, segment FepCallBack
	mov	dx, offset FepCallBack
	movdw	ss:[bp].FCBI_function, cxdx
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].FCBI_data, cxsi
	movdw	cxdx, ssbp
	mov	di, DR_FEP_LOST_FOCUS
	call	FepCallRoutine
	add	sp, size FepCallBackInfo
	pop	cx, dx, di, bp
noFEP:

endif	; USE_FEP

	; make sure "flashing" cursor is on

	call	CursorForceOn

	;
	; Abort an HWR macro in progress.  If we do not abort it, the
	; macro started in this object will finish in another object.
	;
	call	AbortHWRMacro

	; Special case of going from TARGET & FOCUS to just TARGET.
	; In this case the appearance of the selection doesn't change so there
	; is no need to flash.

	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	call	ObjVarFindData
	jnc	notTarget
	call	TSL_SelectIsCursor			; Is selection a cursor
	jc	notTarget				; Jump if is cursor.
	and	ds:[di].VTI_intSelFlags, not mask VTISF_IS_FOCUS
	jmp	done
notTarget:
	call	EditUnHilite
	and	ds:[di].VTI_intSelFlags, not mask VTISF_IS_FOCUS
	call	EditHilite
done:
	call	TextGStateDestroy

	; Send message to output in case user wants to handle this.

	mov	ax, MSG_META_TEXT_LOST_FOCUS
	call	FarSendToTextOutput

	clr	bp
	call	SendTextFocusNotification

	; Optimize MSG_META_KBD_CHAR travel time by grabbing the keyboard
	; exclusive whenever we have the system-wide focus.  -- Doug 9/17/92

	call	VisReleaseKbd

		
	ret
VisTextLostFocusExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal user that this object has gained the target exclusive.

CALLED BY:	External. (Via MSG_META_GAINED_TARGET_EXCL).
PASS:		ds:*si = pointer to VisTextInstance.
		es     = segment containing VisTextClass
		ax     = MSG_META_GAINED_TARGET_EXCL
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGainedTargetExcl	proc	far	; MSG_META_GAINED_TARGET_EXCL
	class	VisLargeTextClass

EC <	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET	>
EC <	ERROR_NZ VIS_TEXT_GAINED_TARGET_ALREADY_TARGET		>

	clr	ax
	mov	al, mask VTISF_IS_TARGET
	mov	bx, MSG_META_TEXT_GAINED_TARGET
	call	ChangeSelectionFlags

	;	
	; Just avoid notification if we're not realized.   Notification leads
	; to death in objects with invalid geometry anyway, but let's just
	; worry about objects that aren't onscreen yet.  -cbh 3/ 3/93
	;	
	call	Text_DerefVis_DI
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	avoidNotification

	mov	ax, VIS_TEXT_GAINED_TARGET_NOTIFICATION_FLAGS
	call	TA_SendNotification

avoidNotification:
	call	Text_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	notLarge
	mov	cx, ds:[di].VTI_cursorRegion
	mov	ax, MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED
	call	ObjCallInstanceNoLock
notLarge:

	; Scroll to show the selected area

	;
	; if ATTR_VIS_TEXT_DONT_SHOW_POSTION_ON_GAINED_TARGET_EXCL is
	; set then do not do show position no matter what type of text
	; object we are.
	;
	mov	ax, ATTR_VIS_TEXT_DONT_SHOW_POSITION_ON_GAINED_TARGET_EXCL
	call	ObjVarFindData
	jnc	stillTesting
exit:
	ret

stillTesting:
	;
	; if the ATTR_VIS_TEXT_SHOW_POSITION_ON_GAINED_TARGET_EXCL is
	; set then show the position no matter what type of text
	; object we are
	;
	mov	ax, ATTR_VIS_TEXT_SHOW_POSITION_ON_GAINED_TARGET_EXCL
	call	ObjVarFindData
	jc	showPosition
	;
	; if neither
	; ATTR_VIS_TEXT_DONT_SHOW_POSTION_ON_GAINED_TARGET_EXCL or 
	; ATTR_VIS_TEXT_SHOW_POSITION_ON_GAINED_TARGET_EXCL are set
	; then do show position if we are a small text object, but not
	; if we are a large text object.
	;
	call	Text_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	showPosition
	jmp	exit

showPosition:
	mov	dx, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SHOW_POSITION
	GOTO	ObjCallInstanceNoLock

VisTextGainedTargetExcl	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal user that this object has lost the target exclusive.

CALLED BY:	External. (Via MSG_META_LOST_TARGET_EXCL).
PASS:		ds:*si = pointer to VisTextInstance.
		es     = segment containing VisTextClass
		ax     = MSG_META_LOST_TARGET_EXCL
RETURN:		nothing
DESTROYED:	nothing
SYNOPSIS:

CALLED BY:
PASS:
RETURN:
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLostTargetExcl	proc	far	; MSG_META_LOST_TARGET_EXCL
	class	VisTextClass

EC <	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET	>
EC <	ERROR_Z	VIS_TEXT_LOST_TARGET_NOT_TARGET			>

	mov	ax, mask VTISF_IS_TARGET shl 8
	mov	bx, MSG_META_TEXT_LOST_TARGET
	call	ChangeSelectionFlags

	; Send notification to GenApplication object that there is no
	; longer an APP_TARGET text object.
	;

	clr	ax				; send NO_TARGET to all
	call	TA_SendNotification

	call	TU_NukeCachedUndo
	call	SendAbortSearchSpellNotification
	;
	; Abort an HWR macro in progress.  If we do not abort it, the
	; macro started in this object will finish in another object.
	;
	call	AbortHWRMacro

	ret

VisTextLostTargetExcl	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextGainedSysTargetExcl --
		MSG_META_GAINED_SYS_TARGET_EXCL for VisTextClass

DESCRIPTION:	Handle gaining the system target

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

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
	Tony	3/ 4/93		Initial version

------------------------------------------------------------------------------@
VisTextGainedSysTargetExcl	proc	far  ; MSG_META_GAINED_SYS_TARGET_EXCL
	class	VisTextClass

	; if we already have the focus then we can cheat

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jnz	isFocus

	call	TextGStateCreate
	call	EditUnHilite

	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	clr	cx
	call	ObjVarAddData

	call	EditHilite
	call	TextGStateDestroy

	ret

isFocus:
	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	clr	cx
	call	ObjVarAddData

	ret

VisTextGainedSysTargetExcl	endp

;---

VisTextLostSysTargetExcl	proc	far  ; MSG_META_LOST_SYS_TARGET_EXCL
	class	VisTextClass

	; if we have the focus then we can cheat

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jnz	isFocus

	call	TextGStateCreate
	call	EditUnHilite

	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	call	ObjVarDeleteData

	call	EditHilite
	call	TextGStateDestroy

	ret

isFocus:
	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	call	ObjVarDeleteData

	ret

VisTextLostSysTargetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeSelectionFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the selection flags, keeping the hilite up to date.

CALLED BY:	VisTextGainedTargetExcl, VisTextLostTargetExcl
PASS:		ds:*si	= instance ptr.
		ds:di	= instance ptr.
		al	= bits to set in VTI_intSelFlags
		ah	= bits to clear in VTI_intSelFlags
		bx	= method to send to text output.
RETURN:		nothing
DESTROYED:	ah

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeSelectionFlags	proc	near
	class	VisTextClass

	call	TextGStateCreate
	call	EditUnHilite
	or	ds:[di].VTI_intSelFlags, al
	not	ah
	and	ds:[di].VTI_intSelFlags, ah
	call	EditHilite
	call	TextGStateDestroy

	mov	ax, bx
	call	FarSendToTextOutput
	ret
ChangeSelectionFlags	endp


TextSelect2 ends
