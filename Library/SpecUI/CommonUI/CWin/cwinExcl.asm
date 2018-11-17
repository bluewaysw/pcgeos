COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinExcl.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB SendKbdStatusNotification
				Sends out the notification that causes the
				kbd to get brought up (or not).

    GLB SendFocusWindowKbdStatusNotification
				Sends the GWNT_FOCUS_WINDOW_KBD_STATUS
				notification

    GLB SendToAppGCNList	Sends the passed event/block to the passed
				gcn list

    MTD MSG_META_GAINED_FOCUS_EXCL
				We've just gained the focus exclusive. Give
				the object focus to the last/default object
				within us that had the focus.

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL
				We've just gained/lost the focus exclusive.
				Mark as being focus, & redraw the title
				bar.  Other than this, provide standard
				focus node behavior

    MTD MSG_META_LOST_FOCUS_EXCL
				We've just lost the focus exclusive.  Take
				away focus exclusive from any object which
				has it.  (But remember which one it was, so
				that we can give it back the focus should
				the window be given the focus again)

    INT OpenWinUpdateFocusExcl	Provide standard focus node behavior

 ?? INT OLWinSendSetEmphasis	Sends the SET_EMPHASIS message to the
				Ctrl's emphasized child, if any.

    MTD MSG_META_GAINED_SYS_TARGET_EXCL
				Update title header if needed, otherwise
				provide standard target node behavior.

 ?? INT OpenWinMarkFocusAreaInvalidIfNoOtherExcl
				Mark the window header area as invalid (and
				initiate an update) if necessary.

    MTD MSG_META_GRAB_FOCUS_EXCL
				Attempt to make this window become the
				focus window.  Will only try if window is
				marked as being capable of having
				focus. Also, whether or not the window is
				actually given the focus depends on the
				whims of the application, which will
				undoubtedly refuse should the application
				not be the active one in the system.

    MTD MSG_META_GRAB_TARGET_EXCL
				Attempt to make this window become the
				target window.  The target window is the
				one which holds the current target
				selection; the data on which any
				application functions would operate on.

 ?? none OpenWinCallParentOfWindow
				Grab/Release Focus/Target exclusive

 ?? INT OpenWinSetFocusExcl	Called by any object in the window which
				wishes to become the current focus.  If the
				focus is given, it will be sent a
				MSG_META_GAINED_FOCUS_EXCL

 ?? INT OpenWinUnsetFocusExcl	Called by any object of the window which
				wishes to release the focus grab, should it
				have it.

 ?? INT OpenWinAlterFocusCommon	A common utility routine for altering the
				focus exclusive

 ?? INT OpenWinDelayedRestorePreviousFocusExcl
				This routine determines if we have a
				previous focus owner to restore the focus
				to. If so, we send a method to ourselves
				via the UI queue,

    MTD MSG_OL_WIN_RESTORE_PREVIOUS_FOCUS_EXCL
				This method is sent when an gadget or menu
				releases the focus exclusive below this
				window. We send this method to ourselves,
				to allow time for other menus to open. When
				this method does arrive, if no new menu has
				opened, we restore the focus to the
				previous owner.

    MTD MSG_META_GET_FOCUS_EXCL	Returns the current focus exclusive at the
				focus node.

    MTD MSG_META_GET_TARGET_EXCL
				Returns the current target exclusive at the
				focus node.

    MTD MSG_META_KBD_CHAR	Pass on kbd input event to current focus,
				else superclass for default handling

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Split from cwinClassCommon.asm, fixed for
				GenDisplayGroups.

DESCRIPTION:
	This file contains procedures for OLWinClass related to the FOCUS,
	TARGET, and MODAL exclusives.

	$Id: cwinExcl.asm,v 1.1 97/04/07 10:53:24 newdeal Exp $

-------------------------------------------------------------------------------@

WinOther segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendKbdStatusNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out the notification that causes the kbd to get brought
		up (or not).

CALLED BY:	GLOBAL
PASS:		*ds:si - OLWin object
		ax - KeyboardOverride
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendKbdStatusNotification	proc	far
	.enter
if _DUI
	;
	; just use FloatingKbdSetState
	;
	cmp	ax, KO_NO_KEYBOARD
	je	kbdOff
	;
	; keyboard is on, set type before turning on
	;
	push	ax				; save KeyboardOverride
	mov	ax, HINT_KEYBOARD_TYPE
	call	ObjVarFindData
	mov	cx, mask FKT_DEFAULT		; display type
	mov	dx, 0				; disallow type (preserves C)
	mov	bp, mask FKEM_DEFAULT		; entry mode
	jnc	haveType
	mov	cx, ds:[bx].KTP_displayType
	mov	dx, ds:[bx].KTP_disallowType
	mov	bp, ds:[bx].KTP_entryMode
haveType:
	call	FloatingKbdSetType
	pop	bx				; bx = KeyboardOverride
	mov	ax, mask FKF_ON or mask FKF_NEEDS_SPACE
	cmp	bx, KO_KEYBOARD_EMBEDDED
	je	haveFlags
	mov	ax, mask FKF_ON
	jmp	short haveFlags

kbdOff:
	;
	; keyboard is off, remove space if we had embedded keyboard
	;
	mov	ax, HINT_PREVIOUS_KBD_OVERRIDE
	call	ObjVarFindData
	mov	ax, 0			; no info, assume not embedded
	jnc	haveFlags
	cmp	{word}ds:[bx], KO_KEYBOARD_EMBEDDED
	jne	haveFlags		; not embedded
	mov	ax, mask FKF_NEEDS_SPACE	; else, remove space
haveFlags:
	call	GeodeGetProcessHandle	; bx = layer ID for this app
	mov	cx, bx			; cx = layer ID for this app
	call	VisQueryWindow		; di = window
	tst	di
	jz	noWindow
	push	ax, si
	mov	si, WIT_PRIORITY
	call	WinGetInfo		; al = WinPriorityData
	mov	dx, ax
	andnf	dx, mask WPD_WIN	; dx = window priority
	pop	ax, si
	call	OpenWinFloatingKbdSetState
noWindow:
else
	clr	bx			;If no keyboard, send out a 
	cmp	ax, KO_NO_KEYBOARD	; notification to bring it down.
	je	sendNotification
	
	;
	; Embedded keyboards aren't supported anymore, so we will ignore
	; the KO_KEYBOARD_EMBEDDED and treat it as if it were a regular
	; KO_KEYBOARD_REQUIRED.  Should (in the future) these somehow
	; be reimplemented (I don't know how when the PenInputControl
	; is in the SPUI), this can be put back, but for now just assume
	; that if the override isn't KO_NO_KEYBOARD that it is required.
	; We also will want to set the existing provided embedded keyboard
	; not usable, so we don't wind up with a situation where we have
	; both of them up.
	;  dlitwin 7/8/94
	;
	mov	dx, -1				; Set DX non-zero if we need a
						; floating keyboard
	mov	ax, size NotifyFocusWindowKbdStatus
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	push	bx
	mov	es, ax
	mov	ax,  1
	call   	MemInitRefCount
	mov	es:[NFWKS_needsFloatingKbd], dx
	mov	ax, ds:[LMBH_handle]
	movdw	es:[NFWKS_focusWindow], axsi
	clr	es:[NFWKS_sysModal]
	mov	di, ds:[si]
	add	di, ds:[di].OLWin_offset
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	notSysModal
	test	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
	jz	notSysModal
	mov	es:[NFWKS_sysModal], TRUE
notSysModal:

;	Get the position that we want to move the box to - if no desired
;	position set, just pass -1,-1 to put it at the system default
;	(at the center of the bottom of the screen)

	mov	cx, -1			;CX,DX = -1, -1
	mov	dx, cx
	mov	ax, ATTR_GEN_WINDOW_KBD_POSITION
	call	ObjVarFindData
	jnc	setPosition
	mov	cx, ds:[bx].P_x
	mov	dx, ds:[bx].P_y
setPosition:
	mov	es:[NFWKS_kbdPosition].P_x, cx
	mov	es:[NFWKS_kbdPosition].P_y, dx
	pop	bx
	call	MemUnlock

;	Send the notification block off to the FOCUS_WINDOW_KBD_STATUS GCN list

sendNotification:
	call	SendFocusWindowKbdStatusNotification
endif
	.leave
	ret

SendKbdStatusNotification	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFocusWindowKbdStatusNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the GWNT_FOCUS_WINDOW_KBD_STATUS notification

CALLED BY:	GLOBAL
PASS:		*ds:si - OLWin object
		bx - notification handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _DUI

SendFocusWindowKbdStatusNotification	proc	near
	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di

	mov	bp, bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_FOCUS_WINDOW_KBD_STATUS
	mov	di, mask MF_RECORD
	call	ObjMessage			;DI <- event handle

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GAGCNLT_FOCUS_WINDOW_KBD_STATUS
	mov	ax, mask GCNLSF_SET_STATUS
	tst	bx
	jnz	10$
	ORNF	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:

	call	SendToAppGCNList
	pop	di
	call	ThreadReturnStackSpace
	ret

SendFocusWindowKbdStatusNotification	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToAppGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed event/block to the passed gcn list

CALLED BY:	GLOBAL
PASS:		bx - handle to send (0 if none)
		di - event
		ax - GCNListSendFlags		
		ds - segment of InkObject
		cx, dx - event type
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToAppGCNList	proc	near
	.enter
	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, cx
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, dx
	mov	dx, size GCNListMessageParams
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax

;	Since all UI Windows are guaranteed to be run under the same thread
;	as the application object, we just send the notification directly to
;	the app object, and not queue it via the process.

	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, dx
	.leave
	ret
SendToAppGCNList	endp

endif	; (not _DUI)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've just gained the focus exclusive. Give the object focus
		to the last/default object within us that had the focus.

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data

PASS:		*ds:si - instance data
		ax - MSG_META_GAINED_FOCUS_EXCL

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	eric	1/90		more doc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenWinGainedFocusExcl	method dynamic	OLWinClass,
				MSG_META_GAINED_FOCUS_EXCL

	;Now set the focus exclusive to the correct object below this node:
	; (Rudy -- even in "menus", we'll give the focus to the first child.)

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	notMenuWindow

	;menu window: assign focus to 1st object in navigation path,
	;or to NOTHING, depending upon specific UI.

	call	WinOther_ClrAXandOLWIFocusExcl
	jmp	short giveFocusToChild	;skip ahead...


notMenuWindow:
	tst	ds:[di].OLWI_focusExcl.FTVMC_OD.handle	
					;does an object have the focus?
	jz	assignToFirst		;skip if not...

	test	ds:[di].OLWI_fixedAttr, mask OWFA_PRESERVE_FOCUS
	jnz	giveFocusToChild	;skip to preserve focus on this obj...

assignToFirst:
	;assign the focus to the object in this window which has
	;HINT_MAKE_FOCUS_OBJ.

	ANDNF	ds:[di].OLWI_focusExcl.FTVMC_flags, not \
		(mask MAEF_OD_IS_WINDOW or mask MAEF_OD_IS_MENU_RELATED)
	call	WinOther_ClrAXandOLWIFocusExcl

	mov	ax, MSG_GEN_START_BROADCAST_FOR_DEFAULT_FOCUS
	call	WinOther_ObjCallInstanceNoLock

	call	WinOther_DerefVisSpec_DI
					;will reset cx, dx, bp before searching
	tst	cx			;did we find a hint?
	jnz	9$			;yes, give it the focus

	;no HINT_DEFAULT_FOCUS found, give focus to HINT_DEFAULT_DEFAULT_ACTION
	;object, if any

	mov	cx, ds:[di].OLWI_masterDefault.handle
	mov	dx, ds:[di].OLWI_masterDefault.chunk
	jcxz	10$			;skip if none


9$:	;there is an object which has the HINT_DEFAULT_FOCUS. Store its
	;OD and info about it (i.e. windowed or not)

	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.handle, cx
	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.chunk, dx

	ORNF	ds:[di].OLWI_focusExcl.FTVMC_flags, bp
	jmp	giveFocusToChild

10$:	;there is no such object: must assign focus to first child in
	;navigation circuit (even if this specific UI does not support
	;"TABBING" navigation, it may support auto-navigation between text
	;objects, so find first text object)

	mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	call	WinOther_ObjCallInstanceNoLock

giveFocusToChild:


	mov	ax, MSG_META_GAINED_FOCUS_EXCL
	call	OpenWinUpdateFocusExcl
	;
	; after setting focus, make sure we've got a default exclusive
	; (release for NULL so we'll keep current default or use master
	;  default)
	;
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_RELEASE_DEFAULT_EXCLUSIVE
	clr	bp, dx				; NULL
	call	ObjCallInstanceNoLock

if _DUI
	call	SendKbdStatusIfNeeded
else
	call	CheckIfKeyboardRequired
	jnc	noBringupKbd
	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	noBringupKbd			;Branch if vardata not present
						; (no keyboard for this window)
	mov	ax, ds:[bx]
	cmp	ax, KO_NO_KEYBOARD		;If no keyboard is required for
	je	noBringupKbd			; this window, do not send any
						; notification.
	call	SendKbdStatusNotification

noBringupKbd:
endif
	ret
OpenWinGainedFocusExcl	endp

if _DUI
SendKbdStatusIfNeeded	proc	near
	call	CheckIfKeyboardRequired
	jnc	noBringupKbd
	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	noBringupKbd			;Branch if vardata not present
						; (no keyboard for this window)
	mov	ax, ds:[bx]
	cmp	ax, KO_NO_KEYBOARD		;If no keyboard is required for
	je	noBringupKbd			; this window, do not send any
						; notification.
	call	SendKbdStatusNotification

noBringupKbd:
	ret
SendKbdStatusIfNeeded	endp
endif



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinUpdateSystemFocusExcl

DESCRIPTION:	We've just gained/lost the focus exclusive.  Mark as being
		focus, & redraw the title bar.  Other than this, provide
		standard focus node behavior

PASS:		*ds:si - instance data
		ax - MSG_META_GAINED_SYS_FOCUS_EXCL,
		     MSG_META_LOST_SYS_FOCUS_EXCL

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
		Rudy only: indicator check is now done in OpenWinOpenWin,
		VisClose, and OLApplicationBringToTop. -- kho, 1/25/96

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	eric	1/90		more doc.
	kho	6/95		As window gains focus, make sure
				Indicator appears / disappears as
				required. (RUDY only)
	kho	1/25/96		Check taken away.

------------------------------------------------------------------------------@

OpenWinUpdateSystemFocusExcl	method dynamic	OLWinClass,
				MSG_META_GAINED_SYS_FOCUS_EXCL,
				MSG_META_LOST_SYS_FOCUS_EXCL
	push	ax

	;If this window does not have the other (focus/target) exclusive,
	;set a state flag so that the header area which indicates focus/target
	;is redrawn soon.

	mov	bp, offset OLWI_targetExcl	;point to HierarchicalGrab
	call	OpenWinMarkFocusAreaInvalidIfNoOtherExcl

	pop	ax
	call	OpenWinUpdateFocusExcl		;preserves ax

	;
	; if MSG_META_LOST_SYS_FOCUS_EXCL, stop move/resize if active
	; via queue (after normal lost focus processing)
	;
	cmp	ax, MSG_META_LOST_SYS_FOCUS_EXCL
	jne	notLost
	mov	ax, MSG_OL_WIN_ABORT_MOVE_RESIZE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

if _DUI
	ret					; end of LOST_FOCUS handling

notLost:
	;
	; gained focus, update keyboard
	;
	call	SendKbdStatusIfNeeded
else
notLost:
endif
	ret
OpenWinUpdateSystemFocusExcl	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinLostFocusExcl

DESCRIPTION:	We've just lost the focus exclusive. 
		Take away focus exclusive from
		any object which has it.  (But remember which one it was,
		so that we can give it back the focus should the window
		be given the focus again)

PASS:		*ds:si - instance data
		ax - MSG_META_LOST_FOCUS_EXCL

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Eric	1/90		more doc

------------------------------------------------------------------------------@

OpenWinLostFocusExcl	method dynamic	OLWinClass,
				MSG_META_LOST_FOCUS_EXCL

					; See if ptr is in universe
	test	ds:[di].OLWI_specState, mask OLWSS_PTR_IN_RAW_UNIV
	jz	afterPrePassive		; if not, skip
					; Otherwise, the ptr is within this
					; window's universe, & yet the window
					; doesn't have the focus.  We need to
					; restart the pre-passive grab so that
					; we can detect if user clicks in the
					; window again.  (This happens when
					; a summons or command window comes
					; up)
	tst	ds:[di].VCI_window	; However... the window could actually
	jz	afterPrePassive		; have just shut down, & the ptr just
					; hasn't "left" it yet.  If window
					; gone, let's stay wide away from
					; adding another pre-passive, after
					; so many other places worked so
					; hard to get this object OFF of
					; those lists.. :)
	call	VisAddButtonPrePassive		; startup CTTFM mechanisms.

afterPrePassive:

	mov	ax, MSG_META_LOST_FOCUS_EXCL
	call	OpenWinUpdateFocusExcl


;SAVE BYTES: see how OpenWinReleaseFocusExcl handles this...

	;we make the assumption that the HGF_APP_EXCL flag is now clear

	call	WinOther_DerefVisSpec_DI
EC <	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask HGF_APP_EXCL	>
EC <	ERROR_NZ OL_ERROR						>

	test	ds:[di].OLWI_menuState, mask OLWMS_OD_IS_OWNER_BEFORE_MENU
	jz	done			;skip if not...

	;copy the previous HG to the current HG & clear previous focus

	clr	ax
	xchg	ax, ds:[di].OLWI_prevFocusExcl.FTVMC_OD.handle
	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.handle, ax
	clr	ax
	xchg	ax, ds:[di].OLWI_prevFocusExcl.FTVMC_OD.chunk
	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.chunk, ax
	clr	ax
	xchg	ax, ds:[di].OLWI_prevFocusExcl.FTVMC_flags
	andnf	ax, mask HGF_OTHER_INFO
	andnf	ds:[di].OLWI_focusExcl.FTVMC_flags, not (mask HGF_OTHER_INFO)
	ornf	ds:[di].OLWI_focusExcl.FTVMC_flags, ax

	ANDNF	ds:[di].OLWI_menuState, not (mask OLWMS_OD_IS_OWNER_BEFORE_MENU)

done:
	call	CheckIfKeyboardRequired
	jnc	skipKbdStuff

;	If this window required a keyboard, then bring it down now.

	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	skipKbdStuff
	cmp	{word} ds:[bx], KO_NO_KEYBOARD
	jz	skipKbdStuff
if _DUI
	mov	ax, mask FKF_NEEDS_SPACE	; turn off embedded keyboard
	cmp	{word}ds:[bx], KO_KEYBOARD_EMBEDDED
	je	haveFlags
	clr	ax, cx, dx		; else, turn off regular keyboard
haveFlags:
	call	OpenWinFloatingKbdSetState
else
	clr	bx
	call	SendFocusWindowKbdStatusNotification
endif
skipKbdStuff:
	ret

OpenWinLostFocusExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			OpenWinUpdateFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide standard focus node behavior

CALLED BY:	INTERNAL
PASS:		ax	- gained/lost [system] message to implement
RETURN:
DESTROYED:	bx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenWinUpdateFocusExcl	proc far
	mov	bp, MSG_META_GAINED_FOCUS_EXCL	; pass base message
	mov	bx, offset Vis_offset
	mov	di, offset OLWI_focusExcl
	GOTO	FlowUpdateHierarchicalGrab

OpenWinUpdateFocusExcl	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinUpdateSysTargetExcl

DESCRIPTION:	Update title header if needed, otherwise provide standard
		target node behavior.

PASS:		*ds:si - instance data
		ax - MSG_META_GAINED_SYS_TARGET_EXCL,
		     MSG_META_LOST_SYS_TARGET_EXCL

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Eric	1/90		more doc.

------------------------------------------------------------------------------@

OpenWinUpdateSysTargetExcl	method dynamic	OLWinClass,
				MSG_META_GAINED_SYS_TARGET_EXCL,
				MSG_META_LOST_SYS_TARGET_EXCL


	;If this window does not have the other (focus/target) exclusive,
	;set a state flag so that the header area which indicates focus/target
	;is redrawn soon.

	push	ax
	mov	bp, offset OLWI_focusExcl	;point to HierarchicalGrab
	call	OpenWinMarkFocusAreaInvalidIfNoOtherExcl
	pop	ax

	FALL_THRU	OpenWinUpdateTargetExcl

OpenWinUpdateSysTargetExcl	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinUpdateTargetExcl

DESCRIPTION:	Provide standard target node behavior.

PASS:		*ds:si - instance data
		ax - MSG_META_GAINED_TARGET_EXCL,
		     MSG_META_LOST_TARGET_EXCL

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Eric	1/90		more doc.

------------------------------------------------------------------------------@
OpenWinUpdateTargetExcl	method OLWinClass,
				MSG_META_GAINED_TARGET_EXCL,
				MSG_META_LOST_TARGET_EXCL

	mov	bp, MSG_META_GAINED_TARGET_EXCL	; pass base message
	mov	bx, offset Vis_offset
	mov	di, offset OLWI_targetExcl
	GOTO	FlowUpdateHierarchicalGrab

OpenWinUpdateTargetExcl	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinMarkFocusAreaInvalidIfNoOtherExcl

DESCRIPTION:	Mark the window header area as invalid (and initiate an
		update) if necessary.

CALLED BY:	OpenWinGainedFWExcl
		OpenWinLostFWExcl
		OpenWinGainedTWExcl
		OpenWinLostTWExcl

PASS:		*ds:si	= instance data for object
		bp	= offset to "other" HeirarchicalGrab structure

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OpenWinMarkFocusAreaInvalidIfNoOtherExcl	proc	near
	class	OLWinClass

	;if MENU window, never need to update the header.

	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	done			;skip if is menu...

	;if GenPrimary, GenDisplay, or CommandWindow: gaining or losing one
	;exclusive only affects the header if you don't have the other.

	add	di, bp
	test	ds:[di].FTVMC_flags, mask HGF_SYS_EXCL
	jnz	done			;skip if has other exclusive...

	mov	cl, mask OLWHS_FOCUS_AREA_INVALID
	call	OpenWinHeaderMarkInvalid

done:
	ret
OpenWinMarkFocusAreaInvalidIfNoOtherExcl	endp

WinOther	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGrabFocusExcl

DESCRIPTION:	Attempt to make this window become the focus window.  Will
		only try if window is marked as being capable of having focus.
		Also, whether or not the window is actually given the focus
		depends on the whims of the application, which will undoubtedly
		refuse should the application not be the active one in the
		system.

PASS:		*ds:si	- object
		ax	- MSG_META_GRAB_FOCUS_EXCL

RETURN:		Nothing

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

OpenWinGrabFocusExcl	method dynamic OLWinClass, MSG_META_GRAB_FOCUS_EXCL
					; If marked not focusable, exit
	test	ds:[di].OLWI_attrs, mask OWA_FOCUSABLE
	jz	done

					; Toolboxes may not have the focus .
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	done

	;
	; Default: is window requesting grab
	;
	mov	bp, mask MAEF_OD_IS_WINDOW or mask MAEF_GRAB or \
		    mask MAEF_FOCUS or mask MAEF_NOT_HERE

	; Check to see if menu flag should be set
	;
	; (Rudy -- popups appear as dialog boxes, and don't have OLFA_IS_MENU
	;  set.)
	;
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	10$
	ornf	bp, mask MAEF_OD_IS_MENU_RELATED
10$:
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_IS_POPUP
	jz	20$
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
					mask OLPWF_SYS_MODAL
	jz	20$
	ornf	bp, mask MAEF_MODAL
20$:

	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	GOTO	ObjCallInstanceNoLock
done:
	ret

OpenWinGrabFocusExcl	endm

WinMethods	ends

;-------------------------------

WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinGrabTargetExcl

DESCRIPTION:	Attempt to make this window become the target window.  The
		target window is the one which holds the current target
		selection; the data on which any application functions would
		operate on.

PASS:		*ds:si - instance data
		ax	- MSG_META_GRAB_TARGET_EXCL

RETURN:

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

OpenWinGrabTargetExcl	method	dynamic OLWinClass, MSG_META_GRAB_TARGET_EXCL
					; First, see if can have target

	test	ds:[di].OLWI_attrs, mask OWA_TARGETABLE
	jz	done			; if window can't, skip

	GOTO	WinCommon_ObjCallSuperNoLock_OLWinClass_Far

done:
	ret
OpenWinGrabTargetExcl	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinAlterFTVMCExcl

DESCRIPTION:	Grab/Release Focus/Target exclusive

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_META_MUP_ALTER_FTVMC_EXCL

	^cx:dx	- OD to grab/release exclusive for
	bp	- MetaAlterFTVMCExclFlags

RETURN:
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@

OpenWinAlterFTVMCExcl	method	OLWinClass, \
					MSG_META_MUP_ALTER_FTVMC_EXCL
	test	bp, mask MAEF_NOT_HERE
	jnz	notHere

next:
	; If no requests for operations left, exit
	;
	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done

	; Check for requests we can handle
	;

	test	bp, mask MAEF_FOCUS
	jnz	doFocus			; Special case focus

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask MAEF_TARGET
	mov	di, offset OLWI_targetExcl
	test	bp, bx
	jnz	doHierarchy

	; Pass message on to superclass for handling of other hierarhies
	;
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	GOTO	WinCommon_ObjCallSuperNoLock_OLWinClass_Far

doHierarchy:
	push	bx, bp
	and	bp, mask MAEF_GRAB
	or	bp, bx			; or back in hierarchy flag
	mov	bx, offset Vis_offset
	call	FlowAlterHierarchicalGrab
	pop	bx, bp
	not	bx			; get not mask for hierarchy
	and	bp, bx			; clear request on this hierarchy
	jmp	short next

doFocus:
	push	cx, dx, bp
	test	bp, mask MAEF_GRAB
	jz	unsetFocus
;setFocus:
	call	OpenWinSetFocusExcl
	jmp	short continue
unsetFocus:
	call	OpenWinUnsetFocusExcl
continue:
	pop	cx, dx, bp
	and	bp, not mask MAEF_FOCUS
	jmp	short next

done:
	Destroy	ax, cx, dx, bp
	ret


notHere:
	and	bp, not mask MAEF_NOT_HERE	; clear "not here" bit, since
	FALL_THRU	OpenWinCallParentOfWindow	; sending on...

OpenWinAlterFTVMCExcl	endm



;pass *ds:si = instance data of object

OpenWinCallParentOfWindow	proc	far
	class	OLPopupWinClass

	call	WinCommon_DerefVisSpec_DI

if 0	;was _RUDY, I don't think it's appropriate to check for POPUP here,
	;since we're actually dealing with a dialog box, not a real menu. -cbh

	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_POPUP
	pop	di
	jne	callVisParent
else
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	callVisParent
endif

	;this window is a menu. If pinned, treat it like a dialog box -
	;have it grab the focus window exclusive from the application.
	;Otherwise, must send according to whether menu has a menu button
	;which opens it. If so, we send query upwards from that button,
	;so that adopted menu buttons send the query up to the GenPrimary
	;and not the GenDisplay. If no menu button, just send to generic parent,
	;will arrive at GenPrimary safely.

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	callVisParent		;skip if is pinned...

	tst	ds:[di].OLPWI_button	;do we have a menu button?
	jz	callVisParent		;skip if not...

	;this menu has a menu button. Forward query from there.

	call	OLPopupWinSendToButton
	ret

callVisParent:
	GOTO	VisCallParent

OpenWinCallParentOfWindow	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinSetFocusExcl

DESCRIPTION:	Called by any object in the window which wishes
		to become the current focus.  If the focus is given,
		it will be sent a MSG_META_GAINED_FOCUS_EXCL

CALLED BY:	OpenWinAlterFTVMCExcl

PASS:		*ds:si - instance data
		cx:dx	- OD of object (may be 0:0) if we are forcing release
				of current owner
		bp	- mask MAEF_OD_IS_WINDOW	- set for window objects
			  mask MAEF_OD_IS_MENU_RELATED	- set if menu window

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

	if MENU_WINDOW_GRABS_ARE_TEMPORARY {

	    /* FOCUS exclusive grabs from menu-related objects are temporary,
	     * so see if we need to save the OD of the current FOCUS owner,
	     * or update our "previous" owner OD info... */

	    if (requestor = HGF_OD_IS_MENU_RELATED) {

		/* a menu or menu button is requesting the exclusive */

		if (current != HGF_OD_IS_MENU_RELATED) {

		    /* current exclusive owner is a Gadget in the window.
		     * We must save its OD and info */

		    previous = current
		    previous.FTVMC_flags = or OD_IS_OWNER_BEFORE_MENU
		}
		CALL SUPERCLASS, so FlowGrabWithinLevel is called to change
			exclusive to new menu-related owner.

	    } else {

		/* a gadget within this window is requesting the exclusive,
		 * or this window has lost the FOCUS exclusive, and is
		 * faking a FOCUS grab with an OD of 0:0 */

		if (current = HGF_OD_IS_MENU_RELATED) {

		    /* current exclusive owner is menu-related object. */

		    if (requestor = 0:0) {
			/* requestor is 0:0, meaning that this window has lost
			 * the FOCUS, and is faking a request by 0:0 to force
			 * release of current owner. We call superclass so that
			 * the menu loses the focus, and then rely upon the fact
			 * that the OpenWinLostFWExcl handler (higher in
			 * stack) will set current = previous. */

			CALL SUPERCLASS, so FlowGrabWithinLevel is called to
				release current menu-related owner.
		    } else {
			/* requestor is gadget, but there is a menu up.
			 * simply save the OD of this gadget in the "previous"
			 * variable, so that when the menu closes, we restore
			 * the focus to the correct gadget. */

			previous = requestor
		        previous.FTVMC_flags = or OD_IS_OWNER_BEFORE_MENU
		    }

		} else {
		    /* current exclusive owner is a Gadget in the window.
		     * We ust call superclass to handle this normally. */

		    CALL SUPERCLASS, so FlowGrabWithinLevel is called to
			release current menu-related owner.
		}
	    }

	} else {

	    /* menu window grabs are not temporary: just do default behavior */

	    CALL SUPERCLASS, so FlowGrabWithinLevel is called to change
		exclusive to new owner.
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version
	Eric	5/90		Last minute full rewrite.
	Eric	5/90		moved from OLMenuedWinClass
	Doug	9/91		Pulled OpenWinGrabFocusCommon back into
				MSG_VIS_VUP_GRAB_FOCUS_EXCL handler

------------------------------------------------------------------------------@


;IMPORTANT: see OLMenuWinClass for how this method is forwarded up to the
;parent window... (in cwinMenu.asm)

OpenWinSetFocusExcl	proc	near
	test	ds:[di].OLWI_menuState, \
				mask OLWMS_MENU_WINDOW_GRABS_ARE_TEMPORARY
	jz	callSuper		;skip if not...

menuWindowGrabsAreTemporary:
	ForceRef menuWindowGrabsAreTemporary

	test	bp, mask MAEF_OD_IS_MENU_RELATED
	jz	gadgetRequesting

;This was an idea when we were trying to set HGF_OD_IS_MENU_RELATED in menu
;init code. Experiment failed, because of complications. -Eric 10/24/90
;
;;MUST ignore HGF_OD_IS_MENU_RELATED requests, because will screw up navigation
;;into sub-menus, as they request the FOCUS_EXCL from their parent menu.
;;Unfortunately, this also means that navigation within a pinned menu is
;;broken, since the System Menu will try to request the FOCUS_EXCL,
;;passing the HGF_OD_IS_MENU_RELATED. What we really need is a special
;;HGF_OD_IS_SYS_MENU_RELATED flag to differentiate.
;
;hackBailIfMenu:
;	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
;	jnz	gadgetRequesting	;if menu, skip this bullshit...

menuRequesting:
	ForceRef menuRequesting

	;a menu or menu button is requesting the exclusive

	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jnz	callSuper		;skip if current owner is menu related..
					;(i.e. preserve the PrevFocus vars)

	;current exclusive owner is a Gadget in the window.
	;Save the OD, flags, and methods to use to restore the focus to the
	;current owner, when the menu releases it.


	mov	ax, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.handle, ax
	mov	ax, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.chunk, ax
	mov	ax, ds:[di].OLWI_focusExcl.FTVMC_flags
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_flags, ax

	ORNF	ds:[di].OLWI_menuState, mask OLWMS_OD_IS_OWNER_BEFORE_MENU

	jmp	callSuper

gadgetRequesting:
	;a gadget within this window is requesting the exclusive, or this
	;window has lost the FOCUS exclusive, and is faking a FOCUS grab with
	;an OD of 0:0

	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	callSuper		;skip if current owner is gadget...

	;current exclusive owner is menu-related object.

	tst	cx			;is requestor 0:0?
	jz	callSuper		;skip if so (see doc above)...

	;requestor is gadget, but there is a menu up. simply save the OD of
	;this gadget in the "previous" variable, so that when the menu closes,
	;we restore the focus to the correct gadget.

	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.handle, cx
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.chunk, dx
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_flags, bp

	ORNF	ds:[di].OLWI_menuState, mask OLWMS_OD_IS_OWNER_BEFORE_MENU
	ret

callSuper:
	;call utility routine to switch exclusive over

	and	bp, not MAEF_MASK_OF_ALL_HIERARCHIES
	or	bp, mask MAEF_FOCUS		; acting on focus hierarchy
	call	OpenWinAlterFocusCommon
	ret

OpenWinSetFocusExcl	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinUnsetFocusExcl

DESCRIPTION:	Called by any object of the window which wishes
		to release the focus grab, should it have it.

CALLED BY:	OpenWinAlterFTVMCExcl

PASS:		*ds:si - instance data
		cx:dx	- OD of object releasing grab
		bp	- ?

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version
	Eric	5/90		Oh my god! It's May already!

------------------------------------------------------------------------------@

OpenWinUnsetFocusExcl	proc	near

	test	ds:[di].OLWI_menuState, \
				mask OLWMS_MENU_WINDOW_GRABS_ARE_TEMPORARY
	jnz	menuWindowGrabsAreTemporary ;skip if so...

	;call common routine for default exclusive handling

	mov	bp, mask MAEF_FOCUS	;Release focus grab
	call	OpenWinAlterFocusCommon
	ret

menuWindowGrabsAreTemporary:
	;if releasor is same as previous OD, then previous = nil.

	cmp	cx, ds:[di].OLWI_prevFocusExcl.FTVMC_OD.handle
	jne	checkCurrent		;skip if not same as previous...
	cmp	dx, ds:[di].OLWI_prevFocusExcl.FTVMC_OD.chunk
	jne	checkCurrent		;skip if not same as previous...

	;clear out reference. (Has already been sent LOST_FOCUS_EXCL so we
	;don't have to worry about that)

	clr	ax
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.handle, ax
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.chunk, ax
	mov	ds:[di].OLWI_prevFocusExcl.FTVMC_flags, ax
	ANDNF	ds:[di].OLWI_menuState, not (mask OLWMS_OD_IS_OWNER_BEFORE_MENU)

checkCurrent:
	;IF OD passed doesn't match focus OD, then is nothing more that
	;we should do.  Let's NOT make the mistake of going ahead &
	;restoring the previous focus.

	cmp	cx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	jne	done			;skip if not same...
	cmp	dx, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	jne	done			;skip if not same...

	;save info on current owner, so after is released, we can see if it
	;was a menu.

	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	pushf

	;call superclass for default exclusive handling

	mov	bp, mask MAEF_FOCUS	;Release focus grab
	call	OpenWinAlterFocusCommon

	;if was menued window, restore previous grab owner (we saved
	;its OD, flags, and required methods)

	popf				;was it a menu or menu button?
	jz	done			;skip if not...

	;if the Previous FOCUS owner has been saved, send method to self
	;via the UI queue, so that if no other menu opens, we will restore
	;the focus to the previous owner.

	call	OpenWinDelayedRestorePreviousFocusExcl

done:
	ret
OpenWinUnsetFocusExcl	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinAlterFocusCommon

DESCRIPTION:	A common utility routine for altering the focus exclusive

CALLED BY:	OpenWinUnsetFocusExcl
		OpenWinSetFocusExcl
		OpenWinRestorePreviousFocusExcl

PASS:		*ds:si	= instance data for object
		bp      - HierarchicalGrabFlags:
			  HGF_GRAB 		- set to grab, clear to release
			  HGF_OTHER_INFO	- data to store, if grabbing
						  (MAEF_FOCUS MUST be set,
						   other hierarchy flags 
						   cleared)


RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Doug	9/92		put into wider use

------------------------------------------------------------------------------@

OpenWinAlterFocusCommon	proc	near
	class	OLWinClass
	.enter
	mov	ax, MSG_META_GAINED_FOCUS_EXCL	; Pass base message
	mov	bx, offset Vis_offset		; pass master part
	mov	di, offset OLWI_focusExcl	; & offset to BasicGrab
	call	FlowAlterHierarchicalGrab
	.leave
	ret

OpenWinAlterFocusCommon	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinDelayedRestorePreviousFocusExcl

DESCRIPTION:	This routine determines if we have a previous focus owner
		to restore the focus to. If so, we send a method to ourselves
		via the UI queue, 

CALLED BY:	OpenWinReleaseFocusExcl

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OpenWinDelayedRestorePreviousFocusExcl	proc	near
	class	OLWinClass

	;did we save data?

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_menuState, mask OLWMS_OD_IS_OWNER_BEFORE_MENU
	jz	done			;skip if not...

	;let's make it real obvious that we are waiting to restore.
	;(do NOT clear out flags! It is essential that the HGF_IS_MENU_RELATED
	;flag remain TRUE!)

	call	WinCommon_ClrAXandOLWIFocusExcl
	ORNF	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED

	;send method to self so we restore focus to previous owner

	mov	ax, MSG_OL_WIN_RESTORE_PREVIOUS_FOCUS_EXCL
	mov	bx, ds:[LMBH_handle]
	call	WinCommon_ObjMessageForceQueue

done:
	ret
OpenWinDelayedRestorePreviousFocusExcl	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinRestorePreviousFocusExcl --
			MSG_OL_WIN_RESTORE_PREVIOUS_FOCUS_EXCL handler.

DESCRIPTION:	This method is sent when an gadget or menu releases the
		focus exclusive below this window. We send this method to
		ourselves, to allow time for other menus to open.
		When this method does arrive, if no new menu has opened,
		we restore the focus to the previous owner.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OpenWinRestorePreviousFocusExcl	method dynamic	OLWinClass,
				MSG_OL_WIN_RESTORE_PREVIOUS_FOCUS_EXCL

	;first see if there is a "previous" owner of the focus exclusive.

	test	ds:[di].OLWI_menuState, mask OLWMS_OD_IS_OWNER_BEFORE_MENU
	jz	done			;skip if not...

	;Code added 11/25/92 cbh to not worry about any of this restoring
	;stuff if there is no prevFocusExcl.  What's the point?  Anyway, I'm
	;hoping it will fix a problem with traveling in express menus where
	;the fatal error below happens.

	tst	ds:[di].OLWI_prevFocusExcl.FTVMC_OD.handle
;	jz	done
;if this is the case, and OLWI_focusExcl is empty, we need to clear the
;MAEF_OD_IS_MENU_RELATED we set when we queued
;MSG_OL_WIN_RESTORE_PREVIOUS_FOCUS_EXCL - brianc 5/10/95
	jz	clearTest
	
	;Error check: make sure that while we were waiting for this method
	;to arrive, the OLWI_focusExcl variable was kept as is: it is ok
	;for another menu to have grabbed the focus, but if another object
	;grabbed the focus, it should have just updated the OLWI_prevFocusExcl
	;variable, so the OLWI_focusExcl variable should be as is.

EC <	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED >
;EC <	ERROR_Z OL_ERROR_NON_MENU_OBJECT_TOOK_FOCUS_BEFORE_DELAYED_RESTORE >
;this can happen when interacting with a menu button that is partially
;obscured by a pinned menu that has submenus (swat is confused because
;we warn with an error code, but that's okay)
EC <	WARNING_Z OL_ERROR_NON_MENU_OBJECT_TOOK_FOCUS_BEFORE_DELAYED_RESTORE >

	;a "menu-related" object still has the focus. If the OD is 0:0,
	;it means we should now restore to the previous focus owner.

	tst	ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	jnz	done			;skip if another menu grabbed the focus,
					;so we don't change anything...

	;get OD and methods required for previous owner of grab
	;(even if is 0:0, we want to copy it) and clear "previous" info.

	clr	cx, dx, bp
	xchg	cx, ds:[di].OLWI_prevFocusExcl.FTVMC_OD.handle
	xchg	dx, ds:[di].OLWI_prevFocusExcl.FTVMC_OD.chunk
	xchg	bp, ds:[di].OLWI_prevFocusExcl.FTVMC_flags
					;get previous IS_WINDOW status
					;and other flags

	ANDNF	ds:[di].OLWI_menuState, not (mask OLWMS_OD_IS_OWNER_BEFORE_MENU)

	ANDNF	bp, mask MAEF_OD_IS_WINDOW or mask MAEF_OD_IS_MENU_RELATED
	or	bp, mask MAEF_GRAB or mask MAEF_FOCUS

	;grab the FOCUS exclusive for the requesting object
	;(ax = first method of gained/lost pair)

	call	OpenWinAlterFocusCommon

	;make sure that we are no longer menu-related

EC <	call	WinCommon_DerefVisSpec_DI				>
EC <	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED >
EC <	ERROR_NZ OL_ERROR 						>

done:
	ret

clearTest:
	tst	ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	jnz	done			;someone grabbed and set flags
					;else, clear menu-related flag
	andnf	ds:[di].OLWI_focusExcl.FTVMC_flags, not (mask MAEF_OD_IS_MENU_RELATED)
	jmp	short done

OpenWinRestorePreviousFocusExcl	endm

WinCommon	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinGetFocusExcl

DESCRIPTION:	Returns the current focus exclusive at the focus node.

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of MetaClass
		ax 	- MSG_META_GET_FOCUS_EXCL
			  MSG_VIS_FUP_QUERY_FOCUS_EXCL
			  MSG_VIS_VUP_QUERY_FOCUS_EXCL
		
RETURN:		^lcx:dx - handle of object with focus
		bp 	- HierarchicalGrabFlags (For MSG_VIS_VUP & FUP messages)
		carry	- set

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/18/90		Initial version

------------------------------------------------------------------------------@

OpenWinGetFocusExcl	method	dynamic OLWinClass,
					MSG_META_GET_FOCUS_EXCL,
					MSG_VIS_FUP_QUERY_FOCUS_EXCL,
					MSG_VIS_VUP_QUERY_FOCUS_EXCL
	mov	cx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	mov	dx, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	mov	bp, ds:[di].OLWI_focusExcl.FTVMC_flags
	stc
	ret
OpenWinGetFocusExcl	endm

WinMethods	ends

;-------------------------------

ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinGetTargetExcl

DESCRIPTION:	Returns the current target exclusive at the focus node.

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of MetaClass
		ax 	- MSG_META_GET_TARGET_EXCL
		
RETURN:		^lcx:dx - handle of object with focus
		carry	- set

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/18/90		Initial version

------------------------------------------------------------------------------@

OpenWinGetTargetExcl	method	dynamic OLWinClass,
					MSG_META_GET_TARGET_EXCL
	mov	cx, ds:[di].OLWI_targetExcl.FTVMC_OD.handle
	mov	dx, ds:[di].OLWI_targetExcl.FTVMC_OD.chunk
	stc
	ret
OpenWinGetTargetExcl	endm

ActionObscure	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinSendClassedEvent

DESCRIPTION:	Sends message to focus/target object.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TargetObject

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@
OLWinSendClassedEvent	method	OLWinClass, \
				MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_FOCUS
	je	toFocus
	cmp	dx, TO_TARGET
	je	toTarget

	GOTO	WinMethods_ObjCallSuperNoLock_OLWinClass_Far

toFocus:
	push	ax
	call	CheckIfKeyboardRequired
	jnc	passMessageToFocus
					;If not a no-keyboard system, branch
					; to just pass event to child

	mov	ax, ATTR_GEN_WINDOW_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	passMessageToFocus	;If no floating kbd associated with
					; this window, pass the message on

if _DUI
	;
	; for _DUI, we don't use MSG_GEN_SET_KBD_POSITION, but we do have
	; MSG_GEN_TOGGLE_FLOATING_KBD, so send that to anyone with
	; a keyboard (ATTR_GEN_WINDOW_KBD_OVERRIDE(!KO_NO_KEYBOARD)) or who
	; previously had a keyboard (HINT_PREVIOUS_KBD_OVERRIDE)
	;
	push	cx, si
	push	bx, si			; save kbd override
	mov	bx, cx			; bx = event handle
	call	ObjGetMessageInfo
	pop	bx, si			; ds:bx = kbd override
	cmp	ax, MSG_GEN_TOGGLE_FLOATING_KBD
	jne	notSetKbdPosition
	cmp	{word}ds:[bx], KO_NO_KEYBOARD
	jne	sendToHere
	mov	ax, HINT_PREVIOUS_KBD_OVERRIDE
	call	ObjVarFindData
	jnc	notSetKbdPosition
sendToHere:
else
	cmp	{word} ds:[bx], KO_KEYBOARD_REQUIRED
	jne	passMessageToFocus

	push	cx, si
	mov	bx, cx			;BX <- event handle
	call	ObjGetMessageInfo
	cmp	ax, MSG_GEN_SET_KBD_POSITION
	jne	notSetKbdPosition
endif

;	This message is MSG_GEN_SET_KBD_POSITION, so sent it to this window

	clrdw	bxbp			;
	pop	cx, si
	pop	ax
	jmp	toHere

notSetKbdPosition:
	pop	cx, si
passMessageToFocus:
	pop	ax
	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	mov	bp, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	jmp	short toHere

toTarget:
	mov	bx, ds:[di].OLWI_targetExcl.FTVMC_OD.handle
	mov	bp, ds:[di].OLWI_targetExcl.FTVMC_OD.chunk
toHere:
	clr	di
	GOTO	FlowDispatchSendOnOrDestroyClassedEvent

OLWinSendClassedEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Pass on kbd input event to current focus, else superclass for
		default handling

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_KBD_CHAR

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0	; this has been incorporated into cwinPtr.asm to allow keyboard
	; move/resize functionality

OLWinKbdChar	method	dynamic OLWinClass, MSG_META_KBD_CHAR
	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	tst	bx
	jz	callSuper
	mov	si, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	clr	di
	GOTO	ObjMessage

callSuper:
	FALL_THRU	WinMethods_ObjCallSuperNoLock_OLWinClass_Far

OLWinKbdChar	endm

endif

WinMethods	ends
