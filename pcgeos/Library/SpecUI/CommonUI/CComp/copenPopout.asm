COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CComp (common code for several specific ui's)
FILE:		copenPopout.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLPopoutClass		OLCtrlClass subclass object - can 'popout'
					to become OLDialogWinClass object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/92		Initial version

DESCRIPTION:
	$Id: copenPopout.asm,v 1.1 97/04/07 10:53:48 newdeal Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLPopoutClass	mask CLASSF_DISCARD_ON_SAVE or \
			mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


;---------------------------------------------------


Build	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPopoutInitialize

DESCRIPTION:	We intercept this to indicate that we want to provide a
		custom vis parent.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLPopout)

		ax	= MSG_META_INITIALIZE

		cx, dx, bp - ?

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp
		bx, di, si, es, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/9/92		initial version

------------------------------------------------------------------------------@

OLPopoutInitialize	method dynamic	OLPopoutClass, \
					MSG_META_INITIALIZE
	;
	; call superclass directly to do stuff first
	;
	call	OLCtrlInitialize
	;
	; then force default SpecBuild handler to MSG_SPEC_GET_VIS_PARENT
	; to this object when looking for a visible parent to attach it to
	;
	call	Build_DerefVisSpecDI
	ornf	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT
	;
	; set up initial state
	;
	clr	ax
	mov	ds:[di].OLPOI_posX, ax
	mov	ds:[di].OLPOI_posY, ax
	mov	ds:[di].OLPOI_width, ax
	mov	ds:[di].OLPOI_height, ax
	mov	ds:[di].OLPOI_flags, 0		; default to not allowed
	call	UserGetInterfaceOptions		; ax = UIInterfaceOptions
	test	ax, mask UIIO_DISABLE_POPOUTS	; allowed?
	jnz	notAllowed			; not allowed
						; else, set
						; (subclass can override this)
	mov	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
notAllowed:
						; initially not popped out
						; default - not a menu bar
	mov	ax, segment GenInteractionClass
	mov	es, ax
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	jc	isGenInt
EC <	mov	ax, segment OLMenuBarClass				>
EC <	mov	es, ax							>
EC <	mov	di, offset OLMenuBarClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
	call	Build_DerefVisSpecDI		; indicate is a menu bar
	ornf	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	;
	; cannot determine if menu bar should be popped out yet, because we
	; don't know who the parent GenDisplay is.  We'll know when we get
	; MSG_OL_CTRL_SET_VIS_PARENT as that is sent for just that purpose,
	; so we'll delay setting OLPOF_POPPED_OUT until then.
	;
	jmp	short done

isGenInt:
	mov	ax, ATTR_GEN_INTERACTION_POPPED_OUT
	call	ObjVarFindData
	jnc	checkHidden	; (I guess we don't require ATTR_GEN_INTER-
				;  ACTION_POPPED_OUT for HINT_INTERACTION_-
				;  POPOUT_HIDDEN_ON_STARTUP - brianc 2/10/93)
	call	Build_DerefVisSpecDI
	ornf	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
checkHidden:
						; check for hidden on shutdown
	mov	ax, TEMP_GEN_INTERACTION_POPOUT_HIDDEN
	call	PopoutCheckIfRestoringFromState	; carry set if so
	jc	checkIt				; yes
						; else, check startup hint
	mov	ax, HINT_INTERACTION_POPOUT_HIDDEN_ON_STARTUP
;
; add TEMP_GEN_INTERACTION_POPOUT_HIDDEN if
; HINT_INTERACTION_POPOUT_HIDDEN_ON_STARTUP - brianc 5/24/93
;
	call	ObjVarFindData
	jnc	done
	mov	ax, TEMP_GEN_INTERACTION_POPOUT_HIDDEN or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
;	call	Build_DerefVisSpecDI
;	ornf	ds:[di].OLPOI_flags, mask OLPOF_HIDE_ON_STARTUP or \
;				mask OLPOF_HIDDEN_STATE_SET
;	jmp	short done
; OLPOF_HIDDEN_STATE_SET no longer used - brianc 5/26/93
	jmp	short hidden

checkIt:
	call	ObjVarFindData
; Delay deleting this until EnsurePopoutDialog to fix problem where
; an app with a GenDocumentControl in a file menu will cause the menu
; bar to build both during MSG_META_APP_STARTUP (as the model exclusive
; is grabbed) and again after GenAppAttach's GenSpecShrinkBranch when
; the MODEL exclusive is restored.  OLPopoutInitalize and
; OLPopoutOLCtrlSetVisParent happen twice in this case -- the first occurance
; incorrectly deletes the HIDDEN vardata and hidden popouts are restored
; non-hidden by the second occurance.  We use the OLPOF_MENU_BAR flag to
; determine which vardata to delete from which object in EnsurePopoutDialog
; - brianc 4/9/93
;	pushf					; save hidden on shutdown flag
;	call	ObjVarDeleteData		; delete unconditionally
;	popf					; hidden on shutdown?
; combined with above check to fix bug restoring unhidden popouts from state
; - brianc 5/13/93
;	jc	hidden				; if so, hide
;	mov	ax, HINT_INTERACTION_POPOUT_HIDDEN_ON_STARTUP
;	call	ObjVarFindData
	jnc	done
hidden:
	call	Build_DerefVisSpecDI
	ornf	ds:[di].OLPOI_flags, mask OLPOF_HIDE_ON_STARTUP
done:
	ret
OLPopoutInitialize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutOLCtrlSetVisParent

DESCRIPTION:	Set visual parent for this object.  If menu bar, check
		'popped out' state.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

	ax - MSG_OL_CTRL_SET_VIS_PARENT

	^lcx:dx - vis parent
	bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/22/92		Initial version

------------------------------------------------------------------------------@
OLPopoutOLCtrlSetVisParent	method	dynamic OLPopoutClass, \
						 MSG_OL_CTRL_SET_VIS_PARENT
	;
	; let superclass store visual parent
	;
	push	cx, dx				; save vis parent
	mov	di, offset OLPopoutClass
	call	ObjCallSuperNoLock
	;
	; check if we are a menu bar, if so, we need to evaluate 'popped out'
	; state (via vis parent)
	;
	pop	bx, dx				; restore vis parent
	call	Build_DerefVisSpecDI
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	LONG jz	done
	push	si
	call	ObjSwapLock			; *ds:si = vis parent
	push	bx
	mov	si, dx				; *ds:si = parent (GenDisplay)
EC <	mov	di, segment GenDisplayClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenDisplayClass				>
EC <	call	ObjIsObjectInClass		; carry set if so	>
EC <	ERROR_NC	OL_ERROR					>
	clr	cl				; OLPOF flags to set
	mov	ax, HINT_DISPLAY_USE_APPLICATION_MONIKER_WHEN_MENU_BAR_POPPED_OUT
	call	ObjVarFindData			; carry set if found
	jnc	notGenAppMoniker
	ornf	cl, mask OLPOF_USE_GEN_APP_MONIKER
notGenAppMoniker:
	mov	ax, ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT
	call	ObjVarFindData			; carry set if found
	jnc	notPoppedOut	; (I guess we don't require ATTR_GEN_DISPLAY_-
				;  MENU_BAR_POPPED_OUT for HINT_DISPLAY_MENU_-
				;  BAR_HIDDEN_ON_STARTUP - brianc 2/10/93)
	ornf	cl, mask OLPOF_POPPED_OUT
notPoppedOut:
						; check for hidden on shutdown
	mov	ax, TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN
	call	PopoutCheckIfRestoringFromState	; carry set if so
	jc	checkIt				; yes
	call	UserGetInterfaceOptions		; ax = UIInterfaceOptions
	test	ax, mask UIIO_ALLOW_INITIALLY_HIDDEN_MENU_BARS
	jnz	checkStartupHint		; allowed to check startup hint
	andnf	cl, not mask OLPOF_POPPED_OUT	; must also clear this...
	mov	ax, ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT
	call	ObjVarDeleteData		; ...and delete this
						; (don't care about APP_STARTUP
						;	double delete)
	jmp	short notHidden

checkStartupHint:
						; check startup hint
	mov	ax, HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP
;
; add TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN if
; HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP - brianc 5/24/93
;
	call	ObjVarFindData
	jnc	notHidden
	push	cx
	mov	ax, TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
	pop	cx
; OLPOF_HIDDEN_STATE_SET no longer used - brianc 5/26/93
;	ornf	cl, mask OLPOF_HIDDEN_STATE_SET
	jmp	short hidden

checkIt:
	call	ObjVarFindData
; Delay deleting this until EnsurePopoutDialog to fix problem where
; an app with a GenDocumentControl in a file menu will cause the menu
; bar to build both during MSG_META_APP_STARTUP (as the model exclusive
; is grabbed) and again after GenAppAttach's GenSpecShrinkBranch when
; the MODEL exclusive is restored.  OLPopoutInitalize and
; OLPopoutOLCtrlSetVisParent happen twice in this case -- the first occurance
; incorrectly deletes the HIDDEN vardata and hidden popouts are restored
; non-hidden by the second occurance.  We use the OLPOF_MENU_BAR flag to
; determine which vardata to delete from which object in EnsurePopoutDialog
; - brianc 4/9/93
;	pushf					; save hidden on shutdown flag
;	call	ObjVarDeleteData		; delete unconditionally
;	popf					; hidden on shutdown?
; combined with above check to fix bug restoring unhidden popouts from state
; - brianc 5/13/93
;	jc	hidden				; if so, hide
;	mov	ax, HINT_DISPLAY_MENU_BAR_HIDDEN_ON_STARTUP
;	call	ObjVarFindData
	jnc	notHidden
hidden:
	ornf	cl, mask OLPOF_HIDE_ON_STARTUP
notHidden:
	pop	bx
	call	ObjSwapUnlock
	pop	si				; *ds:si = OLPopout
	call	Build_DerefVisSpecDI
	ornf	ds:[di].OLPOI_flags, cl		; set desired flags
done:
	ret
OLPopoutOLCtrlSetVisParent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PopoutCheckIfRestoringFromState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if restoring from state

CALLED BY:	INTERNAL
			OLPopoutInitialize
			OLPopoutOLCtrlSetVisParent

PASS:		*ds:si = OLPopout

RETURN:		carry set if restoring from state

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PopoutCheckIfRestoringFromState	proc	near
	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_GEN_APPLICATION_GET_ATTACH_FLAGS
	call	UserCallApplication	; cx = AppAttachFalgs
	test	cx, mask AAF_RESTORING_FROM_STATE
	jz	done			; not restoring from state, carry clear
	stc				; else, indicate restoring from state
done:
	.leave
	ret
PopoutCheckIfRestoringFromState	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutGetVisParent

DESCRIPTION:	Returns visual parent for this object

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

	ax - MSG_SPEC_GET_VIS_PARENT

	cx - ?
	dx - ?
	bp - SpecBuildFlags
		mask SBF_WIN_GROUP	- set if building win group

RETURN:
	carry - set if vis parent available, clear to use gen parent
	ax - ?
	cx:dx	- Visual parent to use
	bp - SpecBuildFlags

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/9/92		Initial version

------------------------------------------------------------------------------@
OLPopoutGetVisParent	method	dynamic OLPopoutClass, \
						 MSG_SPEC_GET_VIS_PARENT
	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
	jz	done				; exit w/carry clear
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jz	done				; exit w/carry clear
	
	;
	; Try to nuke any margins the gadget area might be trying to put
	; around us.  -cbh 3/12/93  (added here 5/10/94, JimG)
	;
	; Originally only called from OLPopoutGenInteractionPopOut, but that
	; method may not be called if the popout is opening from state.  So,
	; force queue this message (since the vis parent link has not been
	; set up) now because EnsurePopoutDialog may force queue a
	; MSG_GEN_INTERACTION_INITIATE.  --JimG 5/10/94
	;
	tst	ds:[di].OLPOI_dialog		; already "nuked"?
	jnz	alreadyNuked			; dialog exists..
						;   should be nuked already
	
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = OLPopout
	mov	ax, MSG_SPEC_VUP_NUKE_GADGET_AREA_MARGINS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	
alreadyNuked:
	call	EnsurePopoutDialog
	call	Build_DerefVisSpecDI
	mov	cx, ds:[di].OLPOI_dialog	; ^lcx:dx = dialog group
	mov	dx, offset PopoutDialogGroup
EC <	tst	cx							>
EC <	ERROR_Z	OL_ERROR						>
	stc					; use dialog group as parent
done:
	ret
OLPopoutGetVisParent	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	EnsurePopoutDialog

CALLED BY:	INTERNAL
			OLPopoutGetVisParent
			PopInOutCommon

DESCRIPTION:	Creates duplicated dialog UI block.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Could either 1) destroy and create dialog as needed or 2) create a
	dialog when needed and leave around for next time.  We implement
	1) here.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@
EnsurePopoutDialog	proc	far
	uses	si
	.enter
	call	Build_DerefVisSpecDI
EC <	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED			>
EC <	ERROR_Z	OL_ERROR						>
	tst	ds:[di].OLPOI_dialog
	LONG jnz	done
	;
	; create a GIV_DIALOG GenInteraction for the 'popped out' OLPopout
	;	*ds:si = OLPopout
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	ax, bx				; same owner as current object
	clr	cx				; run by same thread
	mov	bx, handle PopoutDialogTemplate
	call	ObjDuplicateResource		; bx = new block
	call	Build_DerefVisSpecDI
	mov	ds:[di].OLPOI_dialog, bx	; store block handle
	call	ObjSwapLock			; ds = segment of new block
						; ^lbx:si = OLPopout
	call	ObjBlockSetOutput		; set output for pop-in trigger
	call	ObjSwapUnlock			; *ds:si = OLPopout
						; bx = new dialog block
	;
	; attach to nearest Gen object
	;	*ds:si = OLPopout
	;	bx = new dialog block handle
	;
	push	si
	call	Build_DerefVisSpecDI
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	jnz	attachForMenuBar
	;
	; normal GIV_POPOUT GenInteraction, must be under some generic object,
	; find it.
	;
	push	bx, si
	call	GenFindParent			; ^lbx:si = Gen object
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	movdw	cxdx, bxsi
	pop	bx, si
	mov	al, 0				; not menu bar
	jmp	short attachCommon

attachForMenuBar:
	;
	; OLCI_visParent of menu bar is GenPrimary or GenDisplay, hook
	; popout dialog there
	;	*ds:si = OLPopout
	;	bx = new dialog block handle
	;
	call	Build_DerefVisSpecDI
	mov	cx, ds:[di].OLCI_visParent.handle
	mov	dx, ds:[di].OLCI_visParent.chunk
	mov	al, ds:[di].OLPOI_flags		; al = menu bar flags

attachCommon:
	;
	; ^lcx:dx = parent to attach to
	; bx = new dialog block handle
	; al = menu bar flags (OLPOF_MENU_BAR, OLPOF_USE_GEN_APP_MONIKER)
	;
	push	ax
	xchg	bx, cx				; ^lbx:si = Gen object
	mov	si, dx
	mov	dx, offset PopoutDialogTemplate	; ^lcx:dx = new dialog
	mov	ax, MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax
	test	al, mask OLPOF_MENU_BAR		; menu bar?
	jz	afterMoniker
	;
	; while we've got ^lbx:si = parent GenDisplay/GenPrimary, set the
	; moniker for the popout dialog to be the moniker of the GenDisplay/
	; GenPrimary
	;	^lbx:si = GenDisplay/GenPrimary
	;	^lcx:dx = new popout dialog
	;	(cx = destination block for MSG_GEN_FIND_MONIKER)
	;	al = menu bar flags (OLPOF_MENU_BAR, OLPOF_USE_GEN_APP_MONIKER)
	;
	test	al, mask OLPOF_USE_GEN_APP_MONIKER	; straight to GenApp?
	jnz	useGenApp			; yes
	push	cx				; save dest block
	mov	ax, MSG_GEN_FIND_MONIKER
						; find text moniker
	mov	bp, VMS_TEXT shl offset VMSF_STYLE or mask VMSF_COPY_CHUNK
	clr	dx				; use GenDisp/GenPrim
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ^lcx:dx = moniker
	tst	cx
	pop	cx				; cx = dest block
	jnz	haveMoniker			; found moniker in Disp/Prim
useGenApp:
	;
	; else, go to app to get moniker
	;	cx = dest block
	;
	mov	ax, MSG_GEN_FIND_MONIKER
						; find text moniker
	mov	bp, VMS_TEXT shl offset VMSF_STYLE or mask VMSF_COPY_CHUNK
	mov	dx, -1				; use GenApp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ^lcx:dx = moniker
	jcxz	afterMoniker			; still no moniker, give up
haveMoniker:
	;
	; set this as the moniker for the popout dialog
	;	^lcx:dx = moniker
	;	^lcx:(offset PopoutDialogTemplate) = popout dialog
	;
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	bx, cx
	mov	si, offset PopoutDialogTemplate	; ^lbx:si = popout dialog
	mov	cx, dx				; cx = moniker
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ^lcx:dx = moniker
afterMoniker:
	pop	si
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	Build_PopoutCallDialog
;use this if we want the dialog to always popout where the original OLPopout
;sits
done:
	;
	; setup the new dialog
	;	*ds:si = OLPopout
	;
EC <	call	VisCheckVisAssumption					>
	;
	; see if there is state data from which to restore the popout dialog's
	; size and position info
	;	*ds:si = OLPopout
	;
	call	Build_DerefVisSpecDI
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	LONG jnz	checkMenuBar
	;
	; OLPopout is GIV_POPOUT GenInteraction, search it for state data
	;
	mov	ax, TEMP_GEN_INTERACTION_SAVE_POPOUT_INFO
	call	ObjVarFindData
	LONG jc	genSavedInfoFound

noSavedInfoFound:
	;
	; not restoring from state, use OLPopout bounds for dialog
	;	*ds:si = OLPopout
	;
	push	si				; save OLPopout chunk handle
	call	Build_DerefVisSpecDI
	mov	cx, ds:[di].OLPOI_posX		; get screen-based coords
	mov	dx, ds:[di].OLPOI_posY
	mov	ax, ds:[di].OLPOI_width		; get width and height
	mov	bp, ds:[di].OLPOI_height
	mov	bx, ds:[di].OLPOI_dialog	; ^hbx = new dialog block
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	call	ObjSwapLock			; ds = new dialog block
						; ^hbx = OLPopout block
						; (preserves flags)
	;
	; set size and position of popout dialog
	;	ds = new dialog block
	;	^hbx = OLPopout block
	;	cx, dx = position
	;	ax, bp = size
	;	Z clr if menu bar
	;
	push	bx				; save OLPopout block
	pushf					; save menu-bar flag
	mov	si, offset PopoutDialogGroup	; *ds:si = dialog group
	;
	; use HINT_INITIAL_SIZE on the dialog group to get the dialog to
	; be the right size
	;	ax = width
	; 	bp = height
	;
	mov	bx, ax				; bx = width
	or	bx, bp
	tst	bx
	jz	noSize
	push	ax, cx				; save width, X pos
	mov	ax, HINT_INITIAL_SIZE
	mov	cx, size GadgetSizeHintArgs
	call	ObjVarAddData
	pop	ds:[bx].GSHA_width, cx		; restore width, X pos
	mov	ds:[bx].GSHA_height, bp
	;
	; queue up a MSG_GEN_RESET_TO_INITIAL_SIZE so the
	; HINT_INITIAL_SIZE will be used correctly
	;	cx, dx = position
	;
	push	cx, dx				; save position
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	cx, dx				; restore position
noSize:
	;
	; position the popout dialog
	;	ds = dialog block
	;	cx, dx = position
	;
if 0
	mov	bp, VUM_MANUAL or (WPT_AT_RATIO shl 8)
	mov	bx, cx
	or	bx, dx
	tst	bx
	jnz	havePositionInfo		; non-zero, use WPT_AS_REQUIRED
						; else, stagger window
	mov	bp, VUM_MANUAL or (WPT_STAGGER shl 8)
havePositionInfo:
	;
	; convert X and Y screen position into SpecWinSizeSpec by just
	; clearing the SWSS_RATIO bit (works for -16384 < values < 16384)
	;
	andnf	cx, not mask SWSS_RATIO
	andnf	dx, not mask SWSS_RATIO
	push	cx, dx, bp
	mov	si, offset PopoutDialogTemplate	; *ds:si = dialog
	call	Build_DerefVisSpecDI		; ds:di = dialog
	andnf	ds:[di].OLWI_winPosSizeFlags, not mask WPSF_PERSIST
	mov	cx, 0
	mov	bp, 0
	mov	dx, VUM_MANUAL or (WST_AS_DESIRED shl 8)
	mov	ax, MSG_GEN_SET_WIN_SIZE
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
	xchg	dx, bp				; dl = VUM, dh = WPT, bp = Ypos
	mov	ax, MSG_GEN_SET_WIN_POSITION
	call	ObjCallInstanceNoLock
	call	Build_DerefVisSpecDI		; ds:di = dialog
	ornf	ds:[di].OLWI_winPosSizeFlags, mask WPSF_PERSIST
else
	mov	si, offset PopoutDialogTemplate	; *ds:si = dialog
	call	Build_DerefVisSpecDI		; ds:di = dialog
	push	ax, bx, cx, dx, bp		; save coords
	mov	bp, di				; ds:bp = instance
	call	OpenWinGetHeaderBoundsFar	; (ax, bx, cx, dx) = bounds
	mov	di, dx				; di = bottom
	pop	ax, bx, cx, dx, bp		; restore coords
	push	dx				; save original bottom
	sub	dx, di				; bump up by title bar bottom
	jns	10$				; if still on-screen, leave it
	clr	dx				; else, force on-screen
10$:
	call	Build_DerefVisSpecDI		; ds:di = dialog
	mov	ds:[di].VI_bounds.R_left, cx	; store position for dialog
	mov	ds:[di].VI_bounds.R_top, dx	; allow it to choose own size
	mov	ds:[di].VI_bounds.R_right, cx
	mov	ds:[di].VI_bounds.R_bottom, dx
	pop	dx				; restore original bottom
	;
	; ADD in RSA_CHOOSE_OWN_SIZE (don't OR) so RSA_CHOOSE_OWN_SIZE will
	; be computed as the size
	;
	add	ds:[di].VI_bounds.R_right, mask RSA_CHOOSE_OWN_SIZE
	add	ds:[di].VI_bounds.R_bottom, mask RSA_CHOOSE_OWN_SIZE

;
; If menu bar, make full width of screen, regardless of positioning
; - brianc 6/11/93
;
	popf					; Z clr if menu bar
	pushf
	jnz	hackMenuBar

	or	ax, bp				; all zeros?
	or	ax, cx
	or	ax, dx
	tst	ax
	mov	ds:[di].OLWI_winPosSizeFlags, mask WPSF_PERSIST or \
			(WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) or \
			(WPT_AS_REQUIRED shl offset WPSF_POSITION_TYPE) or \
			(WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
	mov	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED
	jnz	useSizePos
hackMenuBar:
						; else, stagger window position
	mov	ds:[di].OLWI_winPosSizeFlags, mask WPSF_PERSIST or \
			(WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) or \
			(WPT_STAGGER shl offset WPSF_POSITION_TYPE) or \
			(WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
						; only set position invalid,
						;	not size
;	mov	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID
;preserve WPSS_HAS_MOVED_OR_RESIZED - brianc 5/24/93
	mov	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID or \
						mask WPSS_HAS_MOVED_OR_RESIZED
;
; If size was zero (initial condition), make popout menu bar the width of the
; screen - brianc 6/3/93
;	(on stack) - menu-bar flag
;
	popf					; Z clr if menu bar
	pushf
	jz	useSizePos			; not menu bar
	call	OpenGetScreenDimensions		; cx = width, dx = height
	mov	ds:[di].VI_bounds.R_right, cx	; make menu bar width of scrn
useSizePos:
endif
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid			; invalidate dialog
	popf					; throw away menu bar flag
	pop	bx				; bx = OLPopout block
	pop	si				; si = OLPopout chunk
	call	ObjSwapUnlock			; *ds:si = OLPopout
	jmp	stateRestored

checkMenuBar:
	;
	; is OLMenuBarClass, search vis-parent (will be either GenPrimary or
	; GenDisplay) for state data
	;	*ds:si = OLPopout
	;
	mov	bp, si				; bp = OLPopout chunk
	call	Build_DerefVisSpecDI
	mov	bx, ds:[di].OLCI_visParent.handle
	tst	bx
	LONG jz	noSavedInfoFound
	mov	si, ds:[di].OLCI_visParent.chunk
	call	ObjSwapLock			; *ds:si = vis-parent
						; (bx = OLPopout block handle)
	mov	dx, bx				; dx = OLPopout block handle
	mov	ax, TEMP_GEN_DISPLAY_SAVE_POPOUT_MENU_BAR_INFO
	call	ObjVarFindData
	jnc	noSavedVisParentInfoFound	; not restoring from state
	push	ds:[bx].GSWI_winPosSizeState
	push	ds:[bx].GSWI_winPosition.SWSP_x
	push	ds:[bx].GSWI_winPosition.SWSP_y
	push	ds:[bx].GSWI_winSize.SWSP_x
	push	ds:[bx].GSWI_winSize.SWSP_y
	call	ObjVarDeleteData		; delete TEMP_GEN_DISPLAY...
	stc					; indicate saved info found
noSavedVisParentInfoFound:
	mov	bx, dx				; bx = OLPopout block handle
	mov	si, bp				; si = OLPopout chunk
	call	ObjSwapUnlock			; *ds:si = OLPopout
						; (preserves flags)
	jc	short haveCommonSavedInfo	; use saved info
	jmp	noSavedInfoFound		; else, not restoring from state

genSavedInfoFound:
	;
	; restoring from state for GIV_POPOUT GenInteraction, saved Popout
	; info found
	;	ds:bx = GenSaveWindowInfo
	;	*ds:si = OLPopout
	;	ax = TEMP_GEN_INTERACTION_SAVE_POPOUT_INFO
	;
	push	ds:[bx].GSWI_winPosSizeState
	push	ds:[bx].GSWI_winPosition.SWSP_x
	push	ds:[bx].GSWI_winPosition.SWSP_y
	push	ds:[bx].GSWI_winSize.SWSP_x
	push	ds:[bx].GSWI_winSize.SWSP_y
	call	ObjVarDeleteData		; delete TEMP_GEN_INTERACTION...
haveCommonSavedInfo:
	;
	; use saved info to restore state
	;	*ds:si = OLPopout
	;	saved info on stack
	;
	push	si				; save OLPopout chunk
	call	Build_DerefVisSpecDI		; ds:di = OLPopout instance
	mov	bx, ds:[di].OLPOI_dialog	; ^lbx:si = new dialog
	mov	si, offset PopoutDialogTemplate
	call	ObjSwapLock			; *ds:si = new dialog
						; (bx = OLPopout block handle)
	call	Build_DerefVisSpecDI		; ds:di = dialog instance
	pop	si				; ^lbx:si = OLPopout
	pop	{word} ds:[di].VI_bounds+6
	pop	{word} ds:[di].VI_bounds+4
	pop	{word} ds:[di].VI_bounds+2
	pop	{word} ds:[di].VI_bounds+0
	pop	ds:[di].OLWI_winPosSizeState
	ornf	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED
	call	ObjSwapUnlock			; *ds:si = OLPopout

stateRestored:
	;
	; Set TEMP_OL_WIN_SAVE_INFO_OBJECT so that dialog will save its
	; size and position information to the generic portion of the OLPopout
	; object during shutdown (either a GIV_POPOUT GenInteraction or a
	; GenDisplay for a OLMenuBar).
	;	*ds:si = OLPopout
	;
						; assume GIV_POPOUT
	mov	dx, ds:[LMBH_handle]		; ^ldx:bp = OLPopout
	mov	bp, si
	mov	ax, TEMP_GEN_INTERACTION_SAVE_POPOUT_INFO or mask VDF_SAVE_TO_STATE
	mov	cx, TEMP_GEN_INTERACTION_POPOUT_HIDDEN or mask VDF_SAVE_TO_STATE
	call	Build_DerefVisSpecDI		; ds:di = OLPopout instance
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	jz	haveSaveInfoObject
						; else, use menu bar vis parent
	mov	dx, ds:[di].OLCI_visParent.handle	; ^ldx:bp = vis parent
	mov	bp, ds:[di].OLCI_visParent.chunk
	mov	ax, TEMP_GEN_DISPLAY_SAVE_POPOUT_MENU_BAR_INFO or mask VDF_SAVE_TO_STATE
	mov	cx, TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN or mask VDF_SAVE_TO_STATE
haveSaveInfoObject:
	push	si
	;
	; check if the popout dialog should be not-closable
	;	dx:bp = object to save to
	;	ax = tag
	;	cx = hidden tag
	;
	call	Build_DerefVisSpecDI		; ds:di = OLPopout instance
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR	; (carry clear)
	jnz	isMenuBar			; is menu bar, not not-closable
	push	ax				; save tag
	mov	ax, ATTR_GEN_INTERACTION_POPOUT_NOT_CLOSABLE
	call	ObjVarFindData			; carry set if found
	pop	ax				; restore tag
isMenuBar:
	pushf					; save not-closable flag
	call	Build_DerefVisSpecDI		; ds:di = OLPopout instance
	mov	bx, ds:[di].OLPOI_dialog	; ^lbx:si = new dialog
	mov	si, offset PopoutDialogTemplate
	call	ObjSwapLock			; *ds:si = new dialog
	push	bx				; (bx = OLPopout block handle)
	push	ax				; save vardata tag
	push	cx				; save hidden tag
	mov	ax, TEMP_OL_WIN_SAVE_INFO_OBJECT	; don't save to state
	mov	cx, size SaveInfoObjectStruct
	call	ObjVarAddData
	mov	ds:[bx].SIOS_object.handle, dx
	mov	ds:[bx].SIOS_object.chunk, bp
	pop	ds:[bx].SIOS_hiddenTag
	pop	ds:[bx].SIOS_tag
	pop	bx				; bx = OLPopout block handle
	;
	; clear OWA_CLOSABLE if popout dialog should be not-closable
	;	*ds:si = new dialog
	;
	call	Build_DerefVisSpecDI		; ds:di = new dialog
	popf					; restore not-closable flag
	jnc	notNotClosable
	andnf	ds:[di].OLWI_attrs, not mask OWA_CLOSABLE
notNotClosable:
;move this above - brianc 11/12/92
;	;
;	; set WPSS_HAS_MOVED_OR_RESIZED so popout dialog state is saved even
;	; if the dialog is not moved or resized (avoids popout coming up at
;	; startup at 0,0 and with minimal size)
;	;	*ds:si = new dialog
;	;	ds:di = new dialog instance
;	;
;	ornf	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED
	;
	; spec-build dialog
	;	*ds:si = new dialog
	;	bx = OLPopout block handle
	;
	mov	ax, MSG_SPEC_BUILD_BRANCH
	mov	bp, mask SBF_WIN_GROUP or \
			mask SBF_VIS_PARENT_FULLY_ENABLED or \
			VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	call	ObjSwapUnlock			; ^lbx:si = new dialog
	pop	si				; *ds:si = OLPopout
;use this if we want the dialog to appear where it appeared last time it was
;popped out
;done:
	;
	; Queue an initiate so it comes up later.  We send this to ourselves,
	; so we can ignore it if in the interim, we get popped-in.
	;	*ds:si = OLPopout
	;
	; Wait, if hidden-on-startup, don't initiate
	;
	call	Build_DerefVisSpecDI
	test	ds:[di].OLPOI_flags, mask OLPOF_HIDE_ON_STARTUP
	jz	initiate
						; on-startup has occurred,
						;	clear flag
	andnf	ds:[di].OLPOI_flags, not mask OLPOF_HIDE_ON_STARTUP

; WILL THIS EVER END?:
;
; don't delete TEMP_GEN_INTERACTION_POPOUT_HIDDEN and
; TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN until we show the popout
; (in POP_IN, POP_OUT, and TOGGLE), fixes bug where restoring from
; state the second time will restore popout non-hidden as the
; TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN we added on the first invocation is
; deleted on the second invocation - brianc 5/26/93
;
if 0	;--------------------------------------------------------------------

;
; if OLPOF_HIDDEN_STATE_SET, don't delete - brianc 5/24/93
;
	test	ds:[di].OLPOI_flags, mask OLPOF_HIDDEN_STATE_SET
	jz	deleteAway
	andnf	ds:[di].OLPOI_flags, not mask OLPOF_HIDDEN_STATE_SET
	jmp	short exit

deleteAway:

; Delay deleting this until EnsurePopoutDialog to fix problem where
; an app with a GenDocumentControl in a file menu will cause the menu
; bar to build both during MSG_META_APP_STARTUP (as the model exclusive
; is grabbed) and again after GenAppAttach's GenSpecShrinkBranch when
; the MODEL exclusive is restored.  OLPopoutInitalize and
; OLPopoutOLCtrlSetVisParent happen twice in this case -- the first occurance
; incorrectly deletes the HIDDEN vardata and hidden popouts are restored
; non-hidden by the second occurance.  We use the OLPOF_MENU_BAR flag to
; determine which vardata to delete from which object in EnsurePopoutDialog
; - brianc 4/9/93
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	jnz	deleteFromMenuBar
deleteFromPopout::
	mov	ax, TEMP_GEN_INTERACTION_POPOUT_HIDDEN
	call	ObjVarDeleteData
	jmp	short exit

deleteFromMenuBar:
	push	si
	movdw	bxsi, ds:[di].OLCI_visParent	; ^lbx:si = GenDisplay
	call	ObjSwapLock			; *ds:si = GenDisplay
EC <	push	es							>
EC <	mov	di, segment GenDisplayClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenDisplayClass				>
EC <	call	ObjIsObjectInClass		; carry set if so	>
EC <	pop	es							>
EC <	ERROR_NC	OL_ERROR					>
	mov	ax, TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN
	call	ObjVarDeleteData
	call	ObjSwapUnlock			; *ds:si = OLPopout
	pop	si
	jmp	short exit

else	;--------------------------------------------------------------------

	jmp	short exit

endif	;--------------------------------------------------------------------

initiate:
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = OLPopout
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
exit:
	.leave
	ret
EnsurePopoutDialog	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	Build_PopoutCallDialog

CALLED BY:	INTERNAL

DESCRIPTION:	call dialog object

PASS:
	*ds:si = OLPopout
	ax - message to send to dialog
	cx, dx, bp - message data

RETURN:
	ax, cx, dx, bp - message return values

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/22/92		Initial version

------------------------------------------------------------------------------@
Build_PopoutCallDialog	proc	near
	uses	si
	.enter
	call	Build_DerefVisSpecDI
	mov	bx, ds:[di].OLPOI_dialog
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	si, offset PopoutDialogTemplate
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
Build_PopoutCallDialog	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutSpecUnbuildBranch -- MSG_SPEC_UNBUILD_BRANCH
			for OLPopoutClass

DESCRIPTION:	Unbuild this OLPopout visually, destroying the
		duplicated UI block (popout dialog).

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass (OL dgroup)

	ax - MSG_SPEC_UNBUILD_BRANCH

	cx - ?
	dx - ?
	bp - SpecBuildFlags

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@

OLPopoutSpecUnbuildBranch	method	dynamic OLPopoutClass,
						MSG_SPEC_UNBUILD_BRANCH
	;
	; call superclass to unbuild ourselves
	;
	mov	di, offset OLPopoutClass
	call	ObjCallSuperNoLock
	;
	; then destroy popout dialog UI, if any
	; the dialog will be rebuilt if needed on SPEC_BUILD
	;
	call	PopoutDestroyDialogUI
	ret
OLPopoutSpecUnbuildBranch	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	PopoutDestroyDialogUI

CALLED BY:	INTERNAL
			OLPopoutSpecUnbuildBranch
			PopInOutCommon

DESCRIPTION:	Destroys duplicated dialog UI block.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Could either 1) destroy and create dialog as needed or 2) create a
	dialog when needed and leave around for next time.  We implement
	1) here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@
PopoutDestroyDialogUI	proc	far
	uses	si
	.enter

	call	Build_DerefVisSpecDI
	clr	bx
	xchg	bx, ds:[di].OLPOI_dialog
	tst	bx
	jz	done
EC <	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED			>
EC <	ERROR_Z	OL_ERROR						>

	call	ObjSwapLock
	mov	si, offset PopoutDialogTemplate
	call	OLWinTakeOffWindowList
	call	ObjSwapUnlock
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_META_BLOCK_FREE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave
	ret
PopoutDestroyDialogUI	endp

Build	ends


Popout	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLPopoutSpecVisCloseNotify -- MSG_SPEC_VIS_CLOSE_NOTIFY
							for OLPopoutClass

DESCRIPTION:	Kill close notification if transitioning

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

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
	Tony	4/24/92		Initial version

------------------------------------------------------------------------------@
OLPopoutSpecVisCloseNotify	method dynamic	OLPopoutClass,
						MSG_SPEC_VIS_CLOSE_NOTIFY
	test	ds:[di]. OLPOI_flags, mask OLPOF_POPPING_IN_OR_OUT
	jnz	done
	mov	di, offset OLPopoutClass
	call	ObjCallSuperNoLock
done:
	ret

OLPopoutSpecVisCloseNotify	endm

Popout ends

;----------------

WinMethods segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutStartSelect -- MSG_META_START_SELECT

DESCRIPTION:	Handler for SELECT button pressed on OLPopout.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	ax	- MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/9/92		Initial version

------------------------------------------------------------------------------@
OLPopoutStartSelect	method	dynamic OLPopoutClass, MSG_META_START_SELECT

	push	bp				; save ButtonInfo
	mov	di, offset OLPopoutClass
	call	ObjCallSuperNoLock
	pop	bp				; restore ButtonInfo
	test	ax, mask MRF_PROCESSED		; any use it?
	jnz	exit				; yes, done
	test	bp, mask BI_DOUBLE_PRESS	; double-press?
	jz	exit				; no, done
	;
	; else unused double-press --> toggle pop out state
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jnz	forcePopIn		; currently popped out, force pop in
forcePopOut::
					; allow subclass to intercept
	mov	ax, MSG_GEN_INTERACTION_POP_OUT
	call	ObjCallInstanceNoLock
	jmp	short done

forcePopIn:
					; allow subclass to intercept
	mov	ax, MSG_GEN_INTERACTION_POP_IN
	call	ObjCallInstanceNoLock
done:
	mov	ax, mask MRF_PROCESSED
exit:
	ret
OLPopoutStartSelect	endm

WinMethods ends

;------------------

Popout segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPopoutQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/26/92		Initial version
	brianc	11/24/92	stolen for OLPopoutClass

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPopoutQueryIfPressIsInk	method	dynamic OLPopoutClass,
						MSG_META_QUERY_IF_PRESS_IS_INK
	.enter
	mov	ax, IRV_NO_INK		; never accept ink as double-press
					;	means pop-out
	.leave
	ret
OLPopoutQueryIfPressIsInk	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutGenInteractionPopOut

DESCRIPTION:	Pops out a GIV_POPOUT GenInteraction.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

	ax - MSG_GEN_INTERACTION_POP_OUT

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@
OLPopoutGenInteractionPopOut	method	dynamic	OLPopoutClass,
						MSG_GEN_INTERACTION_POP_OUT
	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
	jz	done				; operation not allowed
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jnz	done				; already popped out
	ornf	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT or \
					mask OLPOF_POPPING_IN_OR_OUT
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	jnz	popOutMenuBar
	mov	ax, ATTR_GEN_INTERACTION_POPPED_OUT or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
;delete TEMP_GEN_INTERACTION_POPOUT_HIDDEN - brianc 5/26/93
	mov	ax, TEMP_GEN_INTERACTION_POPOUT_HIDDEN
	call	ObjVarDeleteData
	jmp	short common

popOutMenuBar:
	push	si
	call	Popout_DerefVisSpecDI
	movdw	bxsi, ds:[di].OLCI_visParent	; ^lbx:si = vis parent
	tst	bx
	jz	noParent
	call	ObjSwapLock			; *ds:si = vis parent
	push	bx
	mov	ax, ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT or \
							mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
;delete TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN - brianc 5/26/93
	mov	ax, TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN
	call	ObjVarDeleteData
	pop	bx
	call	ObjSwapUnlock
noParent:
	pop	si

common:
	call	PopInOutCommon

	;
	; Try to nuke any margins the gadget area might be trying to put
	; around us.  -cbh 3/12/93
	;
	mov	ax, MSG_SPEC_VUP_NUKE_GADGET_AREA_MARGINS
	call	VisCallParent
done:
	ret
OLPopoutGenInteractionPopOut	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutGenInteractionPopIn

DESCRIPTION:	Pops in a GIV_POPOUT GenInteraction.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

	ax - MSG_GEN_INTERACTION_POP_IN

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@
OLPopoutGenInteractionPopIn	method	dynamic	OLPopoutClass,
						MSG_GEN_INTERACTION_POP_IN,
						MSG_OL_POPOUT_POP_IN
	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
	jz	done				; operation not allowed
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jz	done				; already popped in
	andnf	ds:[di].OLPOI_flags, not mask OLPOF_POPPED_OUT
	ornf	ds:[di].OLPOI_flags, mask OLPOF_POPPING_IN_OR_OUT
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	jnz	popInMenuBar
	mov	ax, ATTR_GEN_INTERACTION_POPPED_OUT
	call	ObjVarDeleteData
;delete TEMP_GEN_INTERACTION_POPOUT_HIDDEN - brianc 5/26/93
	mov	ax, TEMP_GEN_INTERACTION_POPOUT_HIDDEN
	call	ObjVarDeleteData
	jmp	short common

popInMenuBar:
	push	si
	call	Popout_DerefVisSpecDI
	movdw	bxsi, ds:[di].OLCI_visParent	; ^lbx:si = vis parent
	tst	bx
	jz	noParent
	call	ObjSwapLock		; *ds:si = vis parent
	mov	ax, ATTR_GEN_DISPLAY_MENU_BAR_POPPED_OUT
	call	ObjVarDeleteData
;delete TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN - brianc 5/26/93
	mov	ax, TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN
	call	ObjVarDeleteData
	call	ObjSwapUnlock
noParent:
	pop	si

common:
	call	PopInOutCommon
done:
	ret
OLPopoutGenInteractionPopIn	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	PopInOutCommon

CALLED BY:	INTERNAL
			OLPopoutGenInteractionPopOut
			OLPopoutGenInteractionPopIn

DESCRIPTION:	Pops in or out a GIV_POPOUT GenInteraction.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@
PopInOutCommon	proc	near
EC <	call	Popout_DerefVisSpecDI					>
EC <	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED			>
EC <	ERROR_Z	OL_ERROR						>
	;
	; save size and position of this object, in case we need it later
	;	*ds:si = OLPopout
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; bp = GState
	call	VisGetBounds			; ax = top, bx = left
	mov	di, bp
	call	GrTransform
	call	GrDestroyState
	call	VisGetSize			; cx = width, dx = height
	call	Popout_DerefVisSpecDI
	mov	ds:[di].OLPOI_posX, ax
	mov	ds:[di].OLPOI_posY, bx
	mov	ds:[di].OLPOI_width, cx
	mov	ds:[di].OLPOI_height, dx
	;
	; unbuild this object
	;
	mov	ax, MSG_VIS_REMOVE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	;
	; if not 'popped out', destroy dialog
	;
	call	Popout_DerefVisSpecDI
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jnz	afterDialog
;	call	PopoutDestroyDialogUI
;just dismiss it
	push	si				; save OLPopout chunk handle
	mov	bx, ds:[di].OLPOI_dialog
	mov	si, offset PopoutDialogTemplate
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	;
	; remove from window list so when we don't save to state and end up
	; setting TEMP_GEN_INTERACTION_POPOUT_HIDDEN or
	; TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN - brianc 4/9/93
	;
	call	ObjSwapLock
	call	OLWinTakeOffWindowList
	call	ObjSwapUnlock
	pop	si				; *ds:si = OLPopout

afterDialog:
	;
	; re-build, using new 'popout' state
	;
	call	Popout_DerefVisSpecDI
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jnz	poppedOut

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	notGen
	;
	; Unbuild the thing so it'll reset geometry when popped back in.
	;
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	;
	; OLPopout is 'popped in', rebuild to get it added back into it's
	; normal place in the vis tree
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	jmp	short done

notGen:
	;
	; We'll just rebuild non-gen object to get it added back into it's
	; normal place in the vis tree
	;
	mov	ax, MSG_SPEC_BUILD
	mov	bp, mask SBF_VIS_PARENT_FULLY_ENABLED or \
			VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	jmp	short updateOurselvesAndParent

poppedOut:
	;
	; OLPopout is 'popped out', place under dialog
	;
	call	EnsurePopoutDialog
	call	Popout_DerefVisSpecDI
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = OLPopout
	mov	dx, si
	mov	bx, ds:[di].OLPOI_dialog	; ^lbx:si = dialog
	mov	si, offset PopoutDialogGroup
	mov	ax, MSG_VIS_ADD_CHILD
	clr	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; (preserves ^lcx:dx)
	mov	si, dx				; *ds:si = OLPopout
updateOurselvesAndParent:
	;
	; update
	;	*ds:si = OLPopout
	;
	mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid
	mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_VIS_MARK_INVALID
	call	VisCallParent			; update parent that we added
						;	ourselves to
done:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLPOI_flags, not mask OLPOF_POPPING_IN_OR_OUT
	ret
PopInOutCommon	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutGenInteractionTogglePopout

DESCRIPTION:	Toggles the state of a GIV_POPOUT GenInteraction.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

	ax - MSG_GEN_INTERACTION_TOGGLE_POPOUT

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	For Motif,
		if popped in -> pop out
		if popped out -> hide (dimiss)
		if hidden -> pop out (initiate)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/25/92		Initial version

------------------------------------------------------------------------------@
OLPopoutGenInteractionTogglePopout	method	dynamic	OLPopoutClass,
					MSG_GEN_INTERACTION_TOGGLE_POPOUT,
					MSG_OL_POPOUT_TOGGLE_POPOUT
	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
	LONG jz	done				; operation not allowed
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	LONG jz	needToPopOut
	;
	; already popped out, check if visible (merely popped out) or not
	; (popped out and hidden)
	;
	push	si
	mov	bx, ds:[di].OLPOI_dialog
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	si, offset PopoutDialogTemplate
	call	ObjSwapLock			; *ds:si = dialog
	call	Popout_DerefVisSpecDI
						; assume hidden, will initiate
	;
	; if dialog is hidden, TEMP_GEN_INTERACTION_POPOUT_HIDDEN and
	; TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN will have to be removed
	; (done below) - brianc 5/26/93
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	haveToggle
	;
	; dismissed popout dialog will cause TEMP_GEN_INTERACTION_POPOUT_HIDDEN
	; or TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN to be added on OpenWinSaveToState
	; - brianc 5/26/93
	;
	mov	cx, IC_DISMISS			; else, dismiss
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
haveToggle:
	push	ax				; save message
	call	ObjCallInstanceNoLock
	pop	ax				; restore message
	call	ObjSwapUnlock
	pop	si				; *ds:si = OLPopout
;----------------------------------------------------------------------------
	cmp	ax, MSG_GEN_INTERACTION_INITIATE
	jne	done
	call	Popout_DerefVisSpecDI
	test	ds:[di].OLPOI_flags, mask OLPOF_MENU_BAR
	jnz	deleteFromMenuBar
deleteFromPopout::
	mov	ax, TEMP_GEN_INTERACTION_POPOUT_HIDDEN
	call	ObjVarDeleteData
	jmp	short done

deleteFromMenuBar:
	movdw	bxsi, ds:[di].OLCI_visParent	; ^lbx:si = GenDisplay
	call	ObjSwapLock			; *ds:si = GenDisplay
EC <	push	es							>
EC <	mov	di, segment GenDisplayClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenDisplayClass				>
EC <	call	ObjIsObjectInClass		; carry set if so	>
EC <	pop	es							>
EC <	ERROR_NC	OL_ERROR					>
	mov	ax, TEMP_GEN_DISPLAY_MENU_BAR_HIDDEN
	call	ObjVarDeleteData
	call	ObjSwapUnlock
;----------------------------------------------------------------------------
	jmp	short done

needToPopOut:
	mov	ax, MSG_GEN_INTERACTION_POP_OUT
	call	ObjCallInstanceNoLock
done:
	ret
OLPopoutGenInteractionTogglePopout	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPopoutGenInteractionSendToDialog

DESCRIPTION:	Send message on to popout dialog, if it is popped out.

PASS:
	*ds:si - instance data
	es - segment of OLPopoutClass

	ax - MSG_GEN_INTERACTION_INITIATE,
		MSG_GEN_INTERACTION_ACTIVATE_COMMAND,
		MSG_GEN_GUP_INTERACTION_COMMAND

	cx - InteractionCommand (for MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		and MSG_GEN_GUP_INTERACTION_COMMAND)
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/26/92		Initial version

------------------------------------------------------------------------------@
OLPopoutGenInteractionSendToDialog	method	dynamic	OLPopoutClass,
					MSG_GEN_INTERACTION_INITIATE,
					MSG_GEN_INTERACTION_ACTIVATE_COMMAND,
					MSG_GEN_GUP_INTERACTION_COMMAND
	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
	jz	done				; operation not allowed
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jz	done				; not popped out
	cmp	ax, MSG_GEN_INTERACTION_INITIATE
	je	sendOnToDialog
EC <	cmp	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND		>
EC <	je	ok							>
EC <	cmp	ax, MSG_GEN_GUP_INTERACTION_COMMAND			>
EC <	ERROR_NE	OL_ERROR					>
EC <ok:									>
	cmp	cx, IC_DISMISS
	je	sendOnToDialog
	;
	; not IC_DISMISS, let superclass handle
	;
	mov	di, offset OLPopoutClass
	call	ObjCallSuperNoLock
done:
	ret

sendOnToDialog:
	call	Popout_DerefVisSpecDI
	mov	bx, ds:[di].OLPOI_dialog
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	si, offset PopoutDialogTemplate
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
OLPopoutGenInteractionSendToDialog	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	Utility routines

CALLED BY:	INTERNAL

DESCRIPTION:	Utility routines

PASS:
	various

RETURN:
	various

DESTROYED:
	various

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/17/92		Initial version

------------------------------------------------------------------------------@
Popout_DerefVisSpecDI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
Popout_DerefVisSpecDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPopoutNotifyEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle setting enabled, not enabled

CALLED BY:	MSG_SPEC_NOTIFY_ENABLED, MSG_SPEC_NOTIFY_NOT_ENABLED

PASS:		*ds:si	= OLPopoutClass object
		ds:di	= OLPopoutClass instance data
		es 	= segment of OLPopoutClass
		ax	= MSG_SPEC_NOTIFY_ENABLED, MSG_SPEC_NOTIFY_NOT_ENABLED

		dl	= VisUpdateMode
		dh	= NotifyEnabledFlags

RETURN:		carry set if visual state changed

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/30/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPopoutNotifyEnabled	method	dynamic	OLPopoutClass,
						MSG_SPEC_NOTIFY_ENABLED,
						MSG_SPEC_NOTIFY_NOT_ENABLED
	;
	; call super
	;
	push	ax, dx				; save message, update mode
	mov	di, offset OLPopoutClass
	call	ObjCallSuperNoLock
	pop	cx, dx				; restore message, update mode
	;
	; then let popout dialog, if any, know
	;	dl = VisUpdateMode
	;
	pushf					; save carry
	call	Popout_DerefVisSpecDI
	mov	bx, ds:[di].OLPOI_dialog
	tst	bx
	jz	done
	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, MSG_SPEC_NOTIFY_ENABLED
	je	haveMessage
	mov	ax, MSG_GEN_SET_NOT_ENABLED
EC <	cmp	cx, MSG_SPEC_NOTIFY_NOT_ENABLED				>
EC <	ERROR_NE	OL_ERROR					>
haveMessage:
	mov	si, offset PopoutDialogTemplate
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	popf					; restore carry
	ret
OLPopoutNotifyEnabled	endm

Popout	ends

