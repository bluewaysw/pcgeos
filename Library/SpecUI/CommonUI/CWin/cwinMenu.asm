COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinMenu.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLMenuWinClass		Open Look/CUA/Motif window class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	6/89		Moved to winMenu.asm from openMenuWin.asm
	Eric	7/89		Motif extensions, more documentation
	Joon	9/92		PM extensions

DESCRIPTION:

	$Id: cwinMenu.asm,v 1.2 98/05/04 07:35:25 joon Exp $

------------------------------------------------------------------------------@

	;
	;	For documentation of the OLMenuWinClass see:
	;	/staff/pcgeos/Spec/olMenuWinClass.doc
	;

CommonUIClassStructures segment resource

	OLMenuWinClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

	MenuWinScrollerClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


;---------------------------------------------------

MenuBuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinInitialize -- MSG_META_INITIALIZE for OLMenuWinClass

DESCRIPTION:	Initialize an OLMenuWin object for the GenInteraction.

PASS:		*ds:si - instance data
		es - segment of OlMenuClass
		ax - MSG_META_INITIALIZE
		cx, dx, bp	- ?

RETURN:		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


OLMenuWinInitialize	method dynamic	OLMenuWinClass, MSG_META_INITIALIZE

	;Do superclass initialization

	mov	di, offset OLMenuWinClass
	CallSuper	MSG_META_INITIALIZE

	;Setup our geometry preferences before calling superclass which will
	;process hints

	;set menu attributes (SAVE BYTES here)

	call	MenuBuild_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU

OLS <	mov	ds:[di].OLWI_attrs, mask OWA_SHADOW or mask OWA_FOCUSABLE >
CUAS <	ORNF	ds:[di].OLWI_attrs, mask OWA_THICK_LINE_BORDER \
			or mask OWA_KIDS_INSIDE_BORDER or mask OWA_FOCUSABLE \
			or mask OWA_CLOSABLE >

if _MENUS_PINNABLE	;------------------------------------------------------

	;CUA/MOTIF: only allow pinnable menus if not in strict-compatibility mde
CUAS <	call	FlowGetUIButtonFlags	;get args from geosec.ini file	>
CUAS <	test	al, mask UIBF_SPECIFIC_UI_COMPATIBLE			>
CUAS <	jnz	noLawsuit						>

OLS <	ORNF	ds:[di].OLWI_attrs, mask OWA_PINNABLE or mask OWA_HEADER >
CUAS <	ORNF	ds:[di].OLWI_attrs, mask OWA_PINNABLE >

noLawsuit:

	;
	; If keyboard-only, or UI concept of Pinnable menus isn't allowed,
	; turn off pinnable menus altogether.
	;
	call	OpenCheckIfKeyboardOnly		; carry set if so
	jc	notPinnable

	push	es, cx
	segmov	es, dgroup, cx
	test	es:[olWindowOptions], mask UIWO_PINNABLE_MENUS
	pop	es, cx
	jnz	afterNotPinnable

notPinnable:
	andnf	ds:[di].OLWI_attrs, not mask OWA_PINNABLE	; clear flag

afterNotPinnable:

endif			;------------------------------------------------------

	;now set menu type

OLS <	mov	ds:[di].OLWI_type, OLWT_MENU				>
CUAS <	mov	ds:[di].OLWI_type, MOWT_MENU	;set window type = MENU	>

if _SUB_MENUS	;--------------------------------------------------------------
	mov	cx, ds:[di].OLCI_buildFlags
	and	cx, mask OLBF_REPLY
	cmp	cx, OLBR_SUB_MENU shl offset OLBF_REPLY
	jnz	winPosSize

OLS <	mov	ds:[di].OLWI_type, OLWT_SUBMENU				>
CUAS <	mov	ds:[di].OLWI_type, MOWT_SUBMENU				>
endif		;--------------------------------------------------------------

winPosSize:
	;do geometry handling
	call	OLMenuWinScanGeometryHints

	;Process hints from GenInteraction object. We want to know if the
	;CUA/Motif - specific hint HINT_SYSTEM_MENU was specified.

						;setup es:di to be ptr to
						;Hint handler table
	segmov	es, cs, di
	mov	di, offset cs:OLMenuWinHintHandlers
	mov	ax, length (cs:OLMenuWinHintHandlers)
	call	ObjVarScanData
	ret
OLMenuWinInitialize	endp

;Hint handler table

OLMenuWinHintHandlers	VarDataHandler \
	<HINT_INFREQUENTLY_USED, offset HintNotPinnable>,
	<HINT_SYS_MENU, offset OLMenuWinHintIsSystemMenu>,
	<HINT_IS_EXPRESS_MENU,offset OLMenuWinHintIsExpressMenu>,
	<HINT_CUSTOM_SYS_MENU, offset OLMenuWinHintCustomSysMenu>,
	<HINT_INTERACTION_INFREQUENT_USAGE,offset OLMenuWinHintInfrequentUsage>

HintNotPinnable	proc	far
	class	OLMenuWinClass
	call	MenuBuild_DerefVisSpec_DI
OLS <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_PINNABLE or mask OWA_HEADER)>
CUAS <	ANDNF	ds:[di].OLWI_attrs, not mask OWA_PINNABLE >
	ret
HintNotPinnable	endp

OLMenuWinHintCustomSysMenu	proc	far
	class	OLMenuWinClass
	call	MenuBuild_DerefVisSpec_DI
	ORNF	ds:[di].OLMWI_specState, mask OMWSS_CUSTOM_SYS_MENU
	ret
OLMenuWinHintCustomSysMenu	endp

OLMenuWinHintInfrequentUsage	proc	far
	class	OLMenuWinClass
	call	MenuBuild_DerefVisSpec_DI
	ORNF	ds:[di].OLMWI_specState, mask OMWSS_INFREQUENT_USAGE
	ret
OLMenuWinHintInfrequentUsage	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinScanGeometryHints --
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLMenuWinClass

DESCRIPTION:	Scans geometry hints.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 5/92		Initial Version

------------------------------------------------------------------------------@

OLMenuWinScanGeometryHints	method static OLMenuWinClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLMenuWinClass
	mov	es, di

	;handle superclass geometry stuff first

	mov	di, offset OLMenuWinClass
	CallSuper	MSG_SPEC_SCAN_GEOMETRY_HINTS

	;Setup our geometry preferences before calling superclass which will
	;process hints

	;Make all buttons the width of the smallest

	call	MenuBuild_DerefVisSpec_DI

	;override OLWinClass positioning/sizing behavior
	;(We set the PERSIST flags so that if this menu is pinned, and then
	;closed, PrepForReOpen does not set anything invalid.)

	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_AS_REQUIRED shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)

	;process positioning and sizing hints - might not allow this

	clr	cx			;pass flag: no icon for this window
	call	OpenWinProcessHints
	.leave
	ret
OLMenuWinScanGeometryHints	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinHintIsSystemMenu

DESCRIPTION:	Hint handler for HINT_SYS_MENU.  Internal hint to indicate
		that this generic interaction group was actually created by
		the specific UI, & should be turned into the CUA system
		menu.

CALLED BY:	INTERNAL

PASS:
	*ds:si	- window object
	ds:bx	- ptr to hint structure
	ax	- hint = (ds:bx).HE_type

RETURN:
	ds	- new segment of object block

OK TO DESTROY in hint handler:
		ax, bx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric			Initial version
	Doug	10/89		Added header
	Eric	6/90		Added OLMenuWinHintIsExpressMenu.

------------------------------------------------------------------------------@

OLMenuWinHintIsExpressMenu	proc	far
	FALL_THRU OLMenuWinHintIsSystemMenu	;for now, no diff.
OLMenuWinHintIsExpressMenu	endp

OLMenuWinHintIsSystemMenu	proc	far
	class	OLMenuWinClass
	;set the OMWA_IS_SYSTEM_MENU attribute bit for this menu window

	call	MenuBuild_DerefVisSpec_DI

;SAVE BYTES: may not be necessary
	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
OLS <	mov	ds:[di].OLWI_type, OLWT_SYSTEM_MENU			>
CUAS <	mov	ds:[di].OLWI_type, MOWT_SYSTEM_MENU			>
						;set window type = SYSTEM_MENU
	ret
OLMenuWinHintIsSystemMenu	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinUpdateSpecBuild -- MSG_SPEC_BUILD_BRANCH

DESCRIPTION:	We intercept UPDATE_SPEC_BUILD here so that menus which are
		pinnable can add a PIN button. (CUA style only).

PASS:
	*ds:si - instance data
	es - segment of OLMenuWinClass

	ax - MSG_SPEC_BUILD_BRANCH

	cx - ?
	dx - ?
	bp - SpecBuildFlags (SBF_WIN_GROUP, etc)

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
	Eric	12/89		Initial version

------------------------------------------------------------------------------@


OLMenuWinUpdateSpecBuild	method dynamic	OLMenuWinClass,
					MSG_SPEC_BUILD_BRANCH

if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	;
	; Make sure this is set.  System menus are always enabled regardless
	; of their parent's status.   (Changed to always enable menus of
	; any kind.  -cbh 12/10/92)
	;
;OLS <	cmp	ds:[di].OLWI_type, OLWT_SYSTEM_MENU			>
;CUAS <	cmp	ds:[di].OLWI_type, MOWT_SYSTEM_MENU			>
;	jne	10$
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
;10$:
endif

if _MENUS_PINNABLE	;------------------------------------------------------
if _CUA_STYLE		;------------------------------------------------------

	mov	di, ds:[di].OLCI_buildFlags
	and	di, mask OLBF_TARGET
	cmp	di, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
	je	callSuper		;popup list, cannot pin (for now)

	;first test if this MSG_SPEC_BUILD_BRANCH has been recursively
	;descending the visible tree. If not, it means we are opening this menu

	test	bp, mask SBF_WIN_GROUP	;at top of tree?
	jz	callSuper		;skip if not...

	push	bp
	call	OLMenuWinEnsurePinTrigger
	pop	bp
endif		;--------------------------------------------------------------
endif		;--------------------------------------------------------------

callSuper:


	mov	ax, MSG_SPEC_BUILD_BRANCH
	push	bp
	mov	di, offset OLMenuWinClass
	call	ObjCallSuperNoLock
	pop	bp

alreadyBuilt:
	;get our orientation correct.  We'll be horizontal if our button
	;desires it.

	call	MenuBuild_DerefVisSpec_DI
	or	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	mov	ax, ds:[di].OLCI_buildFlags
	and	ax, mask OLBF_TARGET
	cmp	ax, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
	jne	20$			;not popup list, leave vertical

	push	si
	mov	si, ds:[di].OLPWI_button
	tst	si
	clc				;assume no button, choose vertical
	jz	15$			;no button, skip this, after popping si
	mov	ax, MSG_OL_MENU_BUTTON_INIT_POPUP_ORIENTATION
	call	ObjCallInstanceNoLock	;returns carry set if horizontal
15$:
	pop	si
	jnc	20$			;button wants us vertical, branch
	call	MenuBuild_DerefVisSpec_DI
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ORIENT_CHILDREN_VERTICALLY
20$:
	;if File menu, ensure File:Exit exists and has moniker

	test	bp, mask SBF_WIN_GROUP
	jz	noFileExitYet
	call	EnsureFileExit
noFileExitYet:

	;update separators in this menu

	mov	ax, MSG_SPEC_UPDATE_MENU_SEPARATORS
	GOTO	ObjCallInstanceNoLock

OLMenuWinUpdateSpecBuild	endp


MenuBuild_DerefVisSpec_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
MenuBuild_DerefVisSpec_DI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForCustomSystemMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the application has provided a custom
		system menu.  If yes, we use it as the system menu.
		The standard system menu becomes a submenu of the app
		provided sys menu.

CALLED BY:	OLMenuWinUpdateSpecBuild
PASS:		*ds:si -	Instance data
		bp     -	SpecBuildFlags

RETURN:		carry set if we called our superclass to do SPEC_BUILD_BRANCH

DESTROYED:	ax, bx, cx, dx, di

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



MenuBuild_DerefGen_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
MenuBuild_DerefGen_DI	endp

if not	(_DISABLE_APP_EXIT_UI)

MenuBuild_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
MenuBuild_ObjMessageCallFixupDS	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinVisAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept MSG_VIS_ADD_CHILD to place the standard system
		menu at the correct position in the app provided sys menu

CALLED BY:	MSG_VIS_ADD_CHILD
PASS:		*ds:si	= OLMenuWinClass object
		ds:di	= OLMenuWinClass instance data
		ds:bx	= OLMenuWinClass object (same as *ds:si)
		es 	= segment of OLMenuWinClass
		ax	= message #

RETURN:		cx, dx	= unchanged

DESTROYED:	ax, bp

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	8/30/92   	Initial version
	brianc	10/8/92		force Exit to end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLMenuWinVisAddChild	method dynamic OLMenuWinClass, MSG_VIS_ADD_CHILD
	uses	bp
	.enter


	mov	di, offset OLMenuWinClass
	call	ObjCallSuperNoLock

	;
	; after adding whatever it was we added, make sure the Exit trigger
	; is last
	;	*ds:si = OLMenuWin
	;	^lcx:dx = child added
	;
	call	MenuBuild_DerefVisSpec_DI
	test	ds:[di].OLMWI_specState, mask OMWSS_EXIT_CREATED
	jz	noExit
	mov	ax, ATTR_OL_MENU_WIN_EXIT_TRIGGER
	call	ObjVarFindData			; carry set if found
	jnc	noExit
	push	cx, dx				; save child for exit
	mov	cx, ({optr} ds:[bx]).handle	; ^lcx:dx = exit trigger if any
	mov	dx, ({optr} ds:[bx]).chunk
	mov	ax, MSG_VIS_MOVE_CHILD
	mov	bp, CCO_LAST			; move to end, not dirty
	call	ObjCallInstanceNoLock
	pop	cx, dx				; restore child for return
noExit:

	.leave
	ret
OLMenuWinVisAddChild	endm


if _MENUS_PINNABLE	;------------------------------------------------------
if _CUA_STYLE		;------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinEnsurePinTrigger

DESCRIPTION:	Create a pushpin trigger, if one is needed & doesn't yet
		exist.

CALLED BY:	INTERNAL
		OLMenuWinUpdateSpecBuild

PASS:		*ds:si	- 	OLMenuWin objec

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Added header
------------------------------------------------------------------------------@


OLMenuWinEnsurePinTrigger	proc	far
	class	OLMenuWinClass
	.enter

	;see if we already have a PinTrigger object for this menu

	call	MenuBuild_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jz	done				;skip if not pinnable...
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	done				;skip if already pinned...

	tst	ds:[di].OLPWI_pinTrigger	;See if already created
	jnz	done				;skip to end if so...

	;create a group to hold pin trigger

	push	es, si
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; add to ourselves
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	mov	ax, -1				; init USABLE, one-way up link
	mov	bx, 0				; no hints
	mov	bp, 0				; ignore dirty
	call	OpenCreateChildObject		; ^lcx:dx = new object
	pop	es, si
	call	MenuBuild_DerefVisSpec_DI
	mov	ds:[di].OLPWI_pinTrigger, dx	; save chunk handle, so we
						; can find it later.
	push	dx				; save again for short term use

	push	si				; save OLMenuWin chunk

EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	ERROR_NE	OL_ERROR					>
	mov	si, dx				; *ds:si = pin group
	mov	bp, mask SBF_IN_UPDATE_WIN_GROUP or mask SBF_TREE_BUILD or \
			mask SBF_VIS_PARENT_FULLY_ENABLED or VUM_NOW
	mov	ax, MSG_SPEC_BUILD_BRANCH
	call	ObjCallInstanceNoLock

	;create a GenTrigger object, and place at the top of this menu
	;	*ds:si = pin group (parent for pin trigger)

	mov	cx, ds:[LMBH_handle]
	pop	dx				; ^lcx:dx = *ds:dx = OLMenuWin
						;	(destination of message)
	push	dx				; save OLMenuWin chunk again
	mov	ax, MSG_OL_POPUP_TOGGLE_PUSHPIN	; action message
	mov	di, handle PinMoniker		; VisualMoniker to use
	mov	bp, offset PinMoniker
	mov	bx, ATTR_GEN_TRIGGER_IMMEDIATE_ACTION	; hint to add
	clc					; full gen linkage
						; (we use this when we destroy
						;	the pin group/trigger)
	call	OpenCreateChildTrigger		; ^lcx:dx = new trigger

	;now since we had virtually no control over where this object
	;was placed in the visible tree, move it to be the first child now.

	pop	si				; *ds:si = OLMenuWin
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = pin group
	pop	dx
	mov	bp, CCO_FIRST		;make it the first child
	mov	ax, MSG_VIS_MOVE_CHILD
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
OLMenuWinEnsurePinTrigger	endp

endif		;--------------------------------------------------------------
endif		;--------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureFileExit

DESCRIPTION:	If this is GenInteraction is marked with
		ATTR_GEN_INTERACTION_GROUP_TYPE {GIGT_FILE_MENU},
		make sure we have an Exit item.

CALLED BY:	INTERNAL
			OLMenuWinUpdateSpecBuild

PASS:
	*ds:si	- OLDialogWin object

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/13/92		Initial version
	VL	7/11/95		Comment out this proc if
				_DISABLE_APP_EXIT_UI if true.

------------------------------------------------------------------------------@
EnsureFileExit	proc	near
	; Don't want a File Exit if _DISABLE_APP_EXIT_UI is true.
if not	(_DISABLE_APP_EXIT_UI) ;-----------------------------------------------
	uses	si
	.enter

	call	MenuBuild_DerefVisSpec_DI
	test	ds:[di].OLMWI_specState, mask OMWSS_FILE_MENU
	LONG jz	done
	;
	; do not create Exit trigger if we are running in UILM_TRANSPARENT
	; mode and we are not a Desk Accessory
	; Changed to allow .ini-file override via UILO_CLOSABLE_APPS flag
	;  (9/9/93 -atw)

	call	UserGetLaunchModel		; ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	jne	addExit				; not UILM_TRANSPARENT, add
	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS	;In transparent mode, but
	jnz	addExit				; override flag present, so add
						; exit trigger.
	mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
	call	GenCallApplication		; al = AppLaunchFlags
	test	al, mask ALF_DESK_ACCESSORY
	LONG jz	done				; not DA, no Exit item
addExit:
	;
	; this is file menu and we want to add Exit trigger
	;
	mov	ax, ATTR_OL_MENU_WIN_EXIT_TRIGGER
	call	ObjVarFindData			; carry set if found
	mov	cx, ({optr} ds:[bx]).handle	; ^lcx:dx = exit trigger if any
	mov	dx, ({optr} ds:[bx]).chunk
	jc	haveTrigger
	push	es
	mov	cx, ds:[LMBH_handle]		; add to this object
	mov	dx, si
	mov	di, segment GenTriggerClass
	mov	es, di
	mov	di, offset GenTriggerClass
	mov	al, -1				; init USABLE
	mov	ah, -1				; one-way upward generic link
	clr	bx
	mov	bp, CCO_LAST			; (not dirty)
	call	OpenCreateChildObject		; ^lcx:dx = new trigger
	pop	es
	push	si, cx, dx			; save OLMenuWin
	mov	si, dx				; *ds:si = new trigger
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND or \
						mask VDF_SAVE_TO_STATE
	mov	cx, size InteractionCommand
	call	ObjVarAddData			; ds:dx = pointer to extra data
	mov	{InteractionCommand} ds:[bx], IC_EXIT
	mov	ax, si				; *ds:ax = exit trigger
	mov	bx, mask OCF_DIRTY shl 8
	call	ObjSetFlags			; undo dirtying by ObjVarAddData
	clr	bp				; basic build
	call	VisSendSpecBuild		; build it
	pop	si, cx, dx			; *ds:si = OLMenuWin
	call	SaveExitTriggerInfo		; preserves cx, dx
	call	MenuBuild_DerefVisSpec_DI
	ornf	ds:[di].OLMWI_specState, mask OMWSS_EXIT_CREATED
haveTrigger:
	;
	; ^lcx:dx = exit trigger
	;
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	MenuBuild_ObjMessageCallFixupDS	; ax = moniker (if any)
	tst	ax
	LONG jnz	done				; have moniker already
if _MOTIF or _ISUI
	mov	dx, -1			; get appname from app
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE) or mask VMSF_COPY_CHUNK
	mov	cx, ds:[LMBH_handle]	; copy into menu block
	mov	ax, MSG_GEN_FIND_MONIKER
	call	MenuBuild_ObjMessageCallFixupDS	; ^lcx:dx = moniker (call trig.)
	LONG jcxz	exitDone		; not found leave plain "Exit" moniker
	mov	di, dx
	mov	di, ds:[di]		; ds:di = app name moniker
	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	monikerDone		; carry clear

	push	si, es, bx
	mov	bx, handle StandardMonikers
	call	ObjLockObjBlock
	mov	es, ax
	mov	di, offset FileExitMoniker
	mov	di, es:[di]
	mov	bl, es:[di].VM_data.VMT_mnemonicOffset
	add	di, offset VM_data.VMT_text
	push	bx
	push	di
	LocalStrLength includeNull	; cx = length w/null (for separator)
	pop	di
	mov	ax, dx
	mov	bx, offset VM_data.VMT_text
DBCS <	shl	cx, 1						>
	call	LMemInsertAt		; insert space in app name chunk for Exit
DBCS <	shr	cx, 1						>
	pop	bx			; bl = mnemonic offset
	mov	si, di
	mov	di, dx
	mov	di, ds:[di]
	mov	ds:[di].VM_width, 0	; recompute size
	mov	ds:[di].VM_data.VMT_mnemonicOffset, bl
	add	di, offset VM_data.VMT_text
	segxchg	ds, es			; ds:si = "Exit"  es:di = app name
	LocalCopyString			; insert "Exit" before app name
	segmov	ds, es			; ds:di = app name
	mov	{TCHAR}ds:[di-(size TCHAR)], C_SPACE	; separator
	mov	bx, handle StandardMonikers
	call	MemUnlock		; unlock moniker resource
	pop	si, es, bx
	mov	cx, ds:[LMBH_handle]
	mov	bp, VUM_MANUAL
	push	dx
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	MenuBuild_ObjMessageCallFixupDS
	pop	dx
	stc				; moniker already set
monikerDone:
	pushf
	mov	ax, dx
	call	LMemFree
	popf
	jc	short afterExit
exitDone:
endif
	mov	cx, handle StandardMonikers
	mov	dx, offset FileExitMoniker
setMoniker::
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	MenuBuild_ObjMessageCallFixupDS
afterExit::
	;
	; do keyboard shortcut
	;
	mov	ax, MSG_GEN_GET_KBD_ACCELERATOR
	call	MenuBuild_ObjMessageCallFixupDS
	tst	cx
	jnz	done				; something set already
if DBCS_PCGEOS
	mov	cx, KeyboardShortcut <0, 0, 0, 0, C_SYS_F3 and mask KS_CHAR>
else
	mov	cx, KeyboardShortcut <0, 0, 0, 0, 0xf, VC_F3>
endif
	mov	dl, VUM_MANUAL
	mov	ax, MSG_GEN_SET_KBD_ACCELERATOR
	call	MenuBuild_ObjMessageCallFixupDS
done:
	.leave
endif	;not (_DISABLE_APP_EXIT_UI) -------------------------------------------
	ret
EnsureFileExit	endp

;
; pass:
;	*ds:si = OLMenuWin
;	^lcx:dx = exit trigger
; return:
;	nothing
; destroy:
;	ax, bx
;
SaveExitTriggerInfo	proc	near
	mov	ax, ATTR_OL_MENU_WIN_EXIT_TRIGGER	; don't save to state
	push	cx
	mov	cx, size optr
	call	ObjVarAddData			; ds:bx = extra data
	pop	cx				; restore handle (returned)
	mov	({optr} ds:[bx]).handle, cx
	mov	({optr} ds:[bx]).chunk, dx
done:
	ret
SaveExitTriggerInfo	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinSpecBuild -- MSG_SPEC_BUILD

DESCRIPTION:	Ensure moniker if ATTR_GEN_INTERACTION_GROUP_TYPE set.

PASS:
	*ds:si - instance data
	es - segment of OLMenuWinClass

	ax - MSG_SPEC_BUILD

	cx - ?
	dx - ?
	bp - SpecBuildFlags (SBF_WIN_GROUP, etc)

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Moniker must be set before calling superclass as the moniker is needed
	at that time.  Don't care whether SBF_WIN_GROUP or not, we need to do
	this the first time through.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/12/92		Initial version

------------------------------------------------------------------------------@
OLMenuWinSpecBuild	method	OLMenuWinClass, MSG_SPEC_BUILD

if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	;
	; Enable menus of any kind.  -cbh 12/10/92   (Actually, only those in
	; a menu bar. -cbh 12/17/92)
	;
	mov	di, ds:[di].OLCI_buildFlags
	test	di, mask OLBF_AVOID_MENU_BAR
	jz	notInMenuBar
	and	di, mask OLBF_TARGET
	cmp	di, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
	jne	notInMenuBar
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
notInMenuBar:

endif

	;
	; ensure moniker if ATTR_GEN_INTERACTION_GROUP_TYPE set
	;
	push	ax, bp
	mov	ax, ATTR_GEN_INTERACTION_GROUP_TYPE
	call	ObjVarFindData			; ds:bx = data, if found
	LONG	jnc	done				; not found, done
EC <	VarDataSizePtr	ds, bx, ax					>
EC <	cmp	ax, size GenInteractionGroupType			>
EC <	ERROR_NE	OL_ERROR_BAD_GEN_INTERACTION_GROUP_TYPE		>
	mov	bl, ds:[bx]			; bl = GenInteractionGroupType
EC <	cmp	bl, GenInteractionGroupType				>
EC <	ERROR_AE	OL_ERROR_BAD_GEN_INTERACTION_GROUP_TYPE		>
	;
	; if GIGT_FILE_MENU, set flag so we know this fact later
	;
	cmp	bl, GIGT_FILE_MENU
	jne	notFileMenu
	call	MenuBuild_DerefVisSpec_DI
	ornf	ds:[di].OLMWI_specState, mask OMWSS_FILE_MENU
						; set this so OLPopupWinClass
						;	can know this
	ornf	ds:[di].OLPWI_flags, mask OLPWF_FILE_MENU
	;
	; let GenPrimary know about us
	;
	push	es, bx, si			; save "File" menu chunk
	call	GenSwapLockParent		; *ds:si = parent
						; bx = "File" menu block
	mov	di, segment GenPrimaryClass
	mov	es, di
	mov	di, offset GenPrimaryClass
	call	ObjIsObjectInClass		; carry set if so
	call	ObjSwapUnlock			; *ds - this block
						; (preserves flags)
	pop	es, bx, si			; restore "File" menu chunk
	jnc	notFileMenu			; not under GenPrimary, ignore
						;	as "File" menu
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = "File" menu
	mov	dx, si
	mov	ax, MSG_OL_BASE_WIN_NOTIFY_OF_FILE_MENU
	call	GenCallParent			; let GenPrimary know of us
notFileMenu:
	;
	; check if moniker exists
	;	*ds:si = OLMenuWin
	;
	call	MenuBuild_DerefGen_DI		; ds:di = gen instance
	tst	ds:[di].GI_visMoniker		; have vis moniker?
	jnz	done				; yes, leave alone
	;
	; add moniker based on GenInteractionGroupType
	;	bl = GenInteractionGroupType
	;
	clr	bh
	shl	bx, 1				; convert to word table offset
	mov	dx, cs:[groupTypeMonikerTable][bx]	; dx = moniker
	mov	cx, handle StandardMonikers	; ^lcx:dx = moniker
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	ObjCallInstanceNoLock
	;
	; let superclass finish up
	;
done:
	pop	ax, bp
	mov	di, offset OLMenuWinClass
	GOTO	ObjCallSuperNoLock
OLMenuWinSpecBuild	endm

groupTypeMonikerTable	label	word
	word	offset GroupTypeFileMoniker	; GIGT_FILE_MENU
	word	offset GroupTypeEditMoniker	; GIGT_EDIT_MENU
	word	offset GroupTypeViewMoniker	; GIGT_VIEW_MENU
	word	offset GroupTypeOptionsMoniker	; GIGT_OPTIONS_MENU
	word	offset GroupTypeWindowMoniker	; GIGT_WINDOW_MENU
	word	offset GroupTypeHelpMoniker	; GIGT_HELP_MENU
	word	offset GroupTypePrintMoniker	; GIGT_PRINT_GROUP
GROUP_TYPE_MONIKER_TABLE_SIZE equ $-groupTypeMonikerTable
.assert (((GIGT_PRINT_GROUP+1)*2) eq GROUP_TYPE_MONIKER_TABLE_SIZE)



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinNotifyOfInteractionCommand --
		MSG_OL_WIN_NOTIFY_OF_INTERACTION_COMMAND for OLMenuWinClass

DESCRIPTION:	Respond to MSG_OL_WIN_NOTIFY_OF_INTERACTION_COMMAND.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLMenuWin)

		dx:bp = NotifyOfInteractionCommandStruct

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@

OLMenuWinNotifyOfInteractionCommand	method dynamic	OLMenuWinClass,
					MSG_OL_WIN_NOTIFY_OF_INTERACTION_COMMAND

	;
	; notification of MSG_GEN_TRIGGER_INTERACTION_COMMAND
	;
	mov	es, dx				; es:bp = NOICS_
	cmp	es:[bp].NOICS_ic, IC_EXIT
	jne	done				; if non-EXIT IC trigger in
						;	menu, ignore it
						; did we create one?
	test	ds:[di].OLMWI_specState, mask OMWSS_EXIT_CREATED
	jnz	done				; yes, don't save again
	mov	cx, es:[bp].NOICS_optr.handle
	mov	dx, es:[bp].NOICS_optr.chunk
	call	SaveExitTriggerInfo
done:
	ret

OLMenuWinNotifyOfInteractionCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinECCheckCascadeData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC only code which checks consistency of the IS_CASCADING
		bit and ATTR_OL_MENU_WIN_CASCADED_MENU vardata.

CALLED BY:	Cascade menu code
PASS:		*ds:si = object ptr
RETURN:		nothing
DESTROYED:	nothing, even flags are maintained.
SIDE EFFECTS:	Dies if inconsistent.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS and ERROR_CHECK
OLMenuWinECCheckCascadeData	proc	far
	uses	ax,bx,cx,dx,di,ds,es
	.enter

	pushf

	mov	ax, ATTR_OL_MENU_WIN_CASCADED_MENU
	call	ObjVarFindData			; if data, ds:bx = ptr
	mov	dl, TRUE			; found var data?
	jc	lookAtBit
	mov	dl, FALSE			; no.. didn't find it

lookAtBit:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMWI_moreSpecState, mask OMWMSS_IS_CASCADING
	mov	dh, TRUE			; bit set?
	jnz	doTests
	mov	dh, FALSE			; no, bit clear

doTests:
	; dl = is there var data? TRUE/FALSE
	; dh = is the CASCADING bit set? TRUE/FALSE
	cmp	dl, dh
	ERROR_NE	OL_ERROR		; INCONSISTENT dl & dh
	tst	dl
	jz	done

	; check var data's contents -- should be valid optr
	push	si
	mov	si, ds:[bx].offset
	mov	bx, ds:[bx].handle
	call	ECCheckLMemOD
	pop	si
done:
	popf

	.leave
	ret
OLMenuWinECCheckCascadeData	endp
endif	;_CASCADING_MENUS and ERROR_CHECK

MenuBuild	ends

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinGupQuery -- MSG_SPEC_GUP_QUERY for OLMenuWinClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree -
		see OLMapGroup (in CSpec/cspecInteraction.asm) for info.

PASS:		*ds:si - instance data
		es - segment of OLMenuWinClass
		ax - MSG_SPEC_GUP_QUERY
		cx - Query type (GenQueryType or SpecGenQueryType)
		dx -?
		bp - OLBuildFlags

RETURN:		carry - set if query acknowledged, clear if not
		bp - OLBuildFlags
		cx:dx - vis parent

DESTROYED:	?

PSEUDO CODE/STRATEGY:

	see OLMapGroup for details

	if (query = SGQT_BUILD_INFO) {
		respond:
			TOP_MENU = 0
			SUB_MENU = 1
			visParent = this object
	} else {
		send query to superclass (will send to generic parent)
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Adapted from Tony's new handler.

------------------------------------------------------------------------------@


OLMenuWinGupQuery	method dynamic	OLMenuWinClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO		;can we answer this query?
	jne	noAnswer			;skip if so...

EC <	test	bp, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	or	bp, OLBR_SUB_MENU shl offset OLBF_REPLY

	;
	; We'll return ourselves, but if an OLCtrl was the generic parent
	; of the querying object, it will set itself as the visual parent
	; rather than this object.  -cbh 5/11/92
	;
	call	WinClasses_Mov_CXDX_Self
	stc					;return query acknowledged
	ret

noAnswer:
	FALL_THRU	WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far

OLMenuWinGupQuery	endp

WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far	proc	far
	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass
	ret
WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far	endp


WinClasses	ends

;-------------------------------

MenuSepQuery	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinUpdateMenuSeparators --
			MSG_SPEC_UPDATE_MENU_SEPARATORS handler

DESCRIPTION:	This method is sent when an object in the menu decides that
		a separator in the menu might need to change. We start a
		wandering query, which updates the appropriate items
		in the menu.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLMenuWinUpdateMenuSeparators	method dynamic	OLMenuWinClass, \
					MSG_SPEC_UPDATE_MENU_SEPARATORS

	clr	ch			;pass flags: initiate query
	mov	ax, MSG_SPEC_MENU_SEP_QUERY
	GOTO	ObjCallInstanceNoLock
OLMenuWinUpdateMenuSeparators	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinSpecMenuSepQuery -- MSG_SPEC_MENU_SEP_QUERY handler

DESCRIPTION:	This method travels the visible tree within a menu,
		to determine which OLMenuItemGroups need top and bottom
		separators to be drawn.

PASS:		*ds:si	= instance data for object
		ch	= MenuSepFlags

RETURN:		ch	= MenuSepFlags (updated)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLMenuWinSpecMenuSepQuery	method dynamic	OLMenuWinClass, \
						MSG_SPEC_MENU_SEP_QUERY

	;see if we are initiating this query, or if it has travelled the
	;entire visible tree in the menu already.

	test	ch, mask MSF_FROM_CHILD
	jnz	fromChild		;skip if reached end of visible tree...

	GOTO	VisCallFirstChild

fromChild:
	;this method has travelled the entire visible tree in the menu,
	;and was sent by the last child to this root node. Begin the
	;process of un-recursing.

	ANDNF	ch, not (mask MSF_SEP or mask MSF_USABLE or mask MSF_FROM_CHILD)
					;indicate no need for separator yet
	stc
	ret
OLMenuWinSpecMenuSepQuery endm

MenuSepQuery	ends

;-------------------------------

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinActivate -- MSG_OL_POPUP_ACTIVATE for OLMenuWinClass

DESCRIPTION:	Open this menu, allowing it to be active

PASS:		*ds:si - instance data
		es - segment of OlMenuClass
		ax - MSG_ACTIVATE_MENU
		cx, dx	- location to make active (field coordinates)
		bp	- ?

RETURN:		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


OLMenuWinActivate	method dynamic	OLMenuWinClass, MSG_OL_POPUP_ACTIVATE

	mov	bp, VUM_MANUAL		;assume menu is not visible

if _MENUS_PINNABLE	;------------------------------------------------------
	;if menu is pinned, un-pin it

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	afterPinned		;skip if not pinned (not visible)...

	;first save menu's current position so that it can be restored when
	;the menu button is released. Start by stuffing the desired location
	;of the menu into our "OLWI_prevWinBounds" variable, so the Swap
	;routine stuffs them into the visible bounds.

	push	cx, dx
	call	WinClasses_DerefVisSpec_DI
	clr	ds:[di].OLWI_prevWinBounds.R_left
	clr	ds:[di].OLWI_prevWinBounds.R_top
	mov	ds:[di].OLWI_prevWinBounds.R_right, -1
	mov	ds:[di].OLWI_prevWinBounds.R_bottom, -1

	ORNF	ds:[di].OLMWI_specState, mask OMWSS_WAS_PINNED
					;indicate was pinned, so want to
					;restore to old location when closes
	push	ds:[di].OLWI_attrs
	call	OpenWinSwapState	;swap attributes, position and size
					;flags, and visible bounds
					;restore attributes trashed during swap
	call	WinClasses_DerefVisSpec_DI
	pop	ds:[di].OLWI_attrs

OLS <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_PINNABLE or mask OWA_HEADER) >
CUAS <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_PINNABLE) >
					;set temporarily not pinnable

	;make menu unpinned, but DO NOT CLOSE IT!

	clr	bp			;pass FALSE flag
	mov	ax, MSG_OL_POPUP_TOGGLE_PUSHPIN
	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass

	;borders and header attributes have been updated, and children
	;marked as invalid if necessary. Now resize window to desired size
	;again, and update it.

	mov	cx, mask RSA_CHOOSE_OWN_SIZE	;set win group to desired size
	mov	dx, mask RSA_CHOOSE_OWN_SIZE	;(just changes bounds)
	call	VisSetSize

	mov	cl, mask VOF_GEOMETRY_INVALID	;set geometry invalid here
	call	WinClasses_VisMarkInvalid_MANUAL
	pop	cx, dx

	mov	bp, VUM_NOW		;force an update below
endif			;------------------------------------------------------

afterPinned:
	;enforce positioning behavior: keep menu visible, and place below
	;our menu button. (bp = VisUpdateMode)

	;Preserve WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT flag when setting
	;this stuff up.  -cbh 1/18/93

	call	WinClasses_DerefVisSpec_DI
	and	ds:[di].OLWI_winPosSizeFlags, \
			mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT

	or	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_AS_REQUIRED shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)

	;make popup lists redo their geometry, if necessary, to stay onscreen
	;(No, let's do this for all menus.  We can't have menus trailing off
	; the screen!)

;	push	cx
;	mov	cx, ds:[di].OLCI_buildFlags
;	and	cx, mask OLBF_TARGET
;	cmp	cx, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
;	jne	10$			;not popup list, branch
	or	ds:[di].OLWI_winPosSizeFlags, \
			mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT
;10$:
;	pop	cx

	;not yet in stay-up mode

	ANDNF	ds:[di].OLMWI_specState, not (mask OMWSS_IN_STAY_UP_MODE)

	;Position menu based on cx, dx passed



	push	bp
	call	VisSetPosition
	pop	dx			;set dl = VisUpdateMode
					; Mark window as invalid, from move
	mov	cl, mask VOF_WINDOW_INVALID	;set this flag
	call	WinClasses_VisMarkInvalid

	;Send method to do vis update, bring to top.

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass

	;start SelectMyControlsOnly mechanism for menu window.
	;(See documentation for OLWinClass)

	mov	ax, MSG_OL_WIN_STARTUP_GRAB
	call	WinClasses_ObjCallInstanceNoLock

	;if this is a popup-menu (no menu button), then grab the Gadget
	;exclusive from the parent window, so that we know to close
	;if the parent closes unexpectedly.

	call	WinClasses_DerefVisSpec_DI
	tst	ds:[di].OLPWI_button	;do we have a menu button?
	jnz	done			;skip if so...

	call	OLMenuWinGrabRemoteGadgetExcl

done:
	ret
OLMenuWinActivate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Startup a menu window in stay-up-mode.

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= OLMenuWinClass object
		ds:di	= OLMenuWinClass instance data
		ds:bx	= OLMenuWinClass object (same as *ds:si)
		es 	= segment of OLMenuWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	9/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLMenuWinInitiate	method dynamic OLMenuWinClass,
					MSG_GEN_INTERACTION_INITIATE
	;not yet in stay-up mode

	ANDNF	ds:[di].OLMWI_specState, not (mask OMWSS_IN_STAY_UP_MODE)

	;Send method to do vis update, bring to top.

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass

	;start SelectMyControlsOnly mechanism for menu window.
	;(See documentation for OLWinClass)

	mov	ax, MSG_OL_WIN_STARTUP_GRAB
	call	WinClasses_ObjCallInstanceNoLock

	;enter stay-up mode

	mov	ax, MSG_MO_MW_ENTER_STAY_UP_MODE
	mov	cx, TRUE				; grab gadget exclusive
	GOTO	ObjCallInstanceNoLock

OLMenuWinInitiate	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinInteractionCommand

DESCRIPTION:	If IC_DISMISS, dismiss the menu.  If IC_EXIT, exit the app.


PASS:
	*ds:si - instance data
	es - segment of OLMenuWinClass

	ax 	- MSG_GEN_GUP_INTERACTION_COMMAND

	cx	- InteractionCommand

RETURN:
	carry - set (query answered)
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version

------------------------------------------------------------------------------@

OLMenuWinInteractionCommand	method dynamic	OLMenuWinClass,
					MSG_GEN_GUP_INTERACTION_COMMAND

	;
	; handle only IC_DISMISS and IC_EXIT
	;
	cmp	cx, IC_DISMISS
	je	dismiss

	cmp	cx, IC_EXIT
	je	exit

					; else, let superclass handle
	mov	di, offset OLMenuWinClass
	GOTO	ObjCallSuperNoLock	; need tail recurse here

dismiss:
	;first: see if this menu is transitioning from pinned & opened from
	;menu button to just pinned. If so, abort - there is already
	;a MSG_OL_POPUP_TOGGLE_PUSHPIN in progress; we arrived here
	;because the toggle operation restores the focus to an object which
	;grabs the gadget exclusive from the menu button, and so the menu button
	;is asking the menu to close. Just ignore it.

	test	ds:[di].OLMWI_specState, mask OMWSS_RE_PINNING
	jnz	done			;skip to abort...

notRePinning:
	ForceRef notRePinning

	;If this menu is pinned, toggle its pushpin status.

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	notPinned		;skip if not pinned...

isPinnedSoToggle:
	ForceRef isPinnedSoToggle

	;menu is pinned: toggle the pinned status: this will
	;send a MSG_GEN_GUP_INTERACTION_COMMAND {IC_DISMISS} to the menu.

	mov	bp, TRUE		;pass flag: dismiss menu
	mov	ax, MSG_OL_POPUP_TOGGLE_PUSHPIN
	call	WinClasses_ObjCallInstanceNoLock
	jmp	short done

notPinned: ;if this menu was pinned before it was opened under the menu button,
	   ;then restore it to that state now. (Keeps the focus)

	test	ds:[di].OLMWI_specState, mask OMWSS_WAS_PINNED
	jz	notPinnedWasNotPinned	;skip if was not pinned...

;notPinnedButWasPinned:
	;HACK: the toggle pushpin code is going to release the FOCUS exclusive
	;from this window, and so the base window may restore the FOCUS
	;to an object on the base window which will take the gadget exclusive,
	;such as a GenTrigger. The menu button which opens this menu will
	;lose the gadget exclusive, and tell this menu to close. To prevent the
	;menu from closing, set OMWSS_RE_PINNING)

	ANDNF	ds:[di].OLMWI_specState, not (mask OMWSS_WAS_PINNED)
	ORNF	ds:[di].OLMWI_specState, mask OMWSS_RE_PINNING
	call	OpenWinSwapState	;restore old attrs, position flags,
					;and position

	mov	ax, MSG_OL_POPUP_TOGGLE_PUSHPIN
	call	WinClasses_ObjCallInstanceNoLock

	call	WinClasses_DerefVisSpec_DI
	ANDNF	ds:[di].OLMWI_specState, not (mask OMWSS_RE_PINNING)

	;
	;DO NOT call superclass- OLPopupWinClass will close this window!
	;
	jmp	short done

exit:
	;
	; exit associated application
	;
	mov	ax, MSG_META_QUIT
	call	GenCallApplication
	jmp	short done

notPinnedWasNotPinned:
	;menu is NOT pinned, and WAS NOT pinned.

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	;Call superclass so that window is CLOSED (set not REALIZABLE)

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass

	;tell our menu button to make sure that it is reset visually

	mov	ax, MSG_OL_MENU_BUTTON_NOTIFY_MENU_DISMISSED
	call	OLPopupWinSendToButton

	pop	di
	call	ThreadReturnStackSpace

done:
	stc				; gup query handled
	ret

OLMenuWinInteractionCommand	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinPrePassiveButton -- MSG_META_PRE_PASSIVE_BUTTON

DESCRIPTION:	Handler for mouse button being pressed while we have a
		passive mouse grab. This grab is set up when the menu
		window is told by the menu button that it is in stay-up mode.

		First we tell the base window that we are leaving
		stay-up mode, and reset our own state bits, so that the
		SelectMyControlsOnly mechanism in the base window and here
		will take the menu down.

PASS:		*ds:si - instance data
		es - segment of OLMenuWinClass
		ax 	- method
		cx, dx	- ptr position
		bp	- [ UIFunctionsActive | buttonInfo ]
			(for menu window - indicates if pointer is inside menu)

RETURN:		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version
	Joon	9/92		Added check for scrollable popup list

------------------------------------------------------------------------------@

OLMenuWinPrePassiveButton	method dynamic	OLMenuWinClass, \
						MSG_META_PRE_PASSIVE_BUTTON

	;if we were in stay-up mode, send MSG_MO_MW_LEAVE_STAY_UP_MODE
	;to self, so will send to menu button and base window.

	test	ds:[di].OLMWI_specState, mask OMWSS_IN_STAY_UP_MODE
	jz	done			;skip if not...


ifdef	ALLOW_SCROLLABLE_POPUP_LISTS

	;if this is a popup list and the ptr is in bounds, then just return
	;processed.  Mouse interactions needs to be handled by the items in
	;the popup list.

	mov	di, ds:[di].OLCI_buildFlags
	and	di, mask OLBF_TARGET
	cmp	di, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
	jne	notPopupList
	call	VisTestPointInBounds
	jc	returnProcessed
notPopupList:

endif

	; don't leave stay up mode if press is not UIFA_IN and
	; VisTestPointInBounds is true

	test	bp, (mask UIFA_IN) shl 8
	jnz	continue

	call	VisTestPointInBounds
	jc	returnProcessed
continue:

	;we are in stay-up mode. Send method to self so will be sent
	;to BaseWindow and MenuButton. MenuButton will return cx = TRUE/FALSE
	;telling us if we should keep menu up.
	;Pass: cx, dx = mouse position (in window coords)
	;	bp = [ UIFunctionsActive | buttonInfo ]

	test	bp, mask BI_PRESS	;any button pressed?
	jz	done			;skip if not...

if BUBBLE_HELP
	test	bp, (mask UIFA_IN) shl 8
	jz	leaveStayUpMode

	; button press inside menu

	mov	ax, bp
	andnf	ax, mask BI_BUTTON	;is it BUTTON_2?
	cmp	ax, BUTTON_2 shl offset BI_BUTTON
	je	done			;skip if so...

leaveStayUpMode:
endif	; BUBBLE_HELP

	mov	ax, cx
	mov	bx, dx
	call	VisQueryWindow		; get window we're on

EC <	push	bx							>
EC <	mov	bx, di							>
EC <	call	ECCheckWindowHandle	; ensure good window		>
EC <	pop	bx							>

	call	WinTransform	; get screen coords
	mov	cx, ax			; cx, dx = ptr position in screen coords
	mov	dx, bx

	push	bp				;save UIFA_IN flags from Flow
						;pass bp...
	mov	ax, MSG_MO_MW_LEAVE_STAY_UP_MODE
	call	WinClasses_ObjCallInstanceNoLock	;send to self
						;returns cx = TRUE if mouse
						;over menu button AND is correct
						;mouse button for this specific
						;UI. (Will restart base window
						;grab if over mouse button)
	pop	bp

	;If mouse is pressed outside of menu window AND menu button
	;bounds, kill menu immediately.

	test	bp, (mask UIFA_IN) shl 8	;is mouse ptr in menu window?
	jnz	returnProcessed			;skip if so...

;notInBounds: ;Mouse pointer is not over menu window.
	tst	cx				;over menu button?
	jnz	returnProcessed			;skip if so...

	;kill menu immediately (if not pinned)! Send method to self.

	;Cascading menus cannot have the pre-passive grab forcing the
	;closure of the menus.  The bad case is where two or more menus are
	;open, and the user clicks on a menu that is not the "top" menu (the
	;one that has the pre-passive grab).  This will get called first,
	;bringing down the "top" menu, which will cause the other menus to
	;go down since the "top" menu will send a SUBMENU_REQUESTS_CLOSE
	;message up the gen tree.  But this is not desired since the user
	;may have clicked on another menu button.  The other mechanisms,
	;post-passive grab and gadget exclusive, will do the work.
	;  --JimG 4/29/94

if	 not _CASCADING_MENUS
	push	bp				;save UIFunctionsActive etc
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	WinClasses_ObjCallInstanceNoLock	;send to self
	pop	bp
endif	;not _CASCADING_MENUS

	; Replay button, just in case the pre-passive list has changed as a
	; result of the above

	mov	ax, mask MRF_REPLAY
	ret

returnProcessed: ;return with ax = MRF_*** flag
	mov	ax, mask MRF_PROCESSED
	ret

done:	;send event to superclass (OLWinClass) so that its
	;mechanisms operate properly.
	GOTO	WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far
OLMenuWinPrePassiveButton	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinPostPassiveButton -- MSG_META_POST_PASSIVE_BUTTON

DESCRIPTION:	See OLWinClass for complete description of how this
		fits into the SelectMyConrolsOnly mechanism. We have
		subclassed this method here so that a menu can decide
		whether to kill itself when leaving stay-up mode.
		IMPORTANT: we are concerned with the button PRESS here,
		not the release. We want the press because we may want the
		menu to close the instant we leave stay-up mode.

PASS:		*ds:si - instance data
		es - segment of OLMenuWinClass
		ax 	- method
		cx, dx	- ptr position
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@

OLMenuWinPostPassiveButton	method dynamic	OLMenuWinClass, \
						MSG_META_POST_PASSIVE_BUTTON
	push	ax, bp				;save method and flags
						;for superclass call

	;are any buttons pressed?

	test	bp, mask BI_PRESS	;any button pressed?
	jnz	callSuper		;skip if so...

	;are any buttons pressed?

	test	bp, mask BI_B3_DOWN or mask BI_B2_DOWN or \
		    mask BI_B1_DOWN or mask BI_B0_DOWN
	jnz	callSuper		;skip if so...

	;all buttons released: if not in stay-up-mode or pinned, close menu now.

	test	ds:[di].OLMWI_specState, mask OMWSS_IN_STAY_UP_MODE
	jnz	callSuper		;skip if so...

	;If using cascading menus, call OLMenuWinCloseOrCascade which will
	;take care of checking if this menu is currently cascading.
if	 _CASCADING_MENUS
	call	OLMenuWinCloseOrCascade		;destroys:ax,bx,cx,dx,bp,di
else	;_CASCADING_MENUS is FALSE
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	WinClasses_ObjCallInstanceNoLock	;send to self
endif	;_CASCADING_MENUS

callSuper:
	pop	ax, bp			;get method and flags

	;call superclass to handle remainder of work (EndGrab, etc)

	GOTO	WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far
OLMenuWinPostPassiveButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinEnterStayUpMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		MSG_MO_MW_ENTER_STAY_UP_MODE

DESCRIPTION:	This is sent by the MOMenuButton object when it realizes
		that we are entering stay-up mode. This procedure sets some
		state flags in this object.

PASS:		*ds:si - instance data
		es - segment of OLMenuWinClass
		ax 	- method
		cx	= TRUE to force release of current GADGET EXCL owner,
			  so that higher-level menus close.

RETURN:		ds:*si, es = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLMenuWinEnterStayUpMode	method dynamic	OLMenuWinClass,
					MSG_MO_MW_ENTER_STAY_UP_MODE

EC <	cmp	cx, TRUE						>
EC <	je	1$							>
EC <	cmp	cx, FALSE						>
EC <	ERROR_NE OL_ERROR						>
EC <1$:									>

	;is ENTER_STAY_UP_MODE: set our state info, and start a pre-passive
	;mouse grab so that we can exit stay-up mode when the button is
	;next pressed.

	ORNF	ds:[di].OLMWI_specState, mask OMWSS_IN_STAY_UP_MODE

	;inform our parent window that it has a menu in stay-up mode.
	;(If this is a menu or sub-menu, inform GenPrimary/GenDisplay/
	;GenSummons, etc. If is a sys-menu for a pinned menu, inform
	;the menu.) This will cause OpenWinEndGrab to NOT force the release
	;of the gadget exclusive as the mouse button is released.

	push	cx
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_HAS_MENU_IN_STAY_UP_MODE
	call	OLMenuWinCallButtonOrGenParent
	pop	cx

	;if we want to force the release of high-level menus, send a VUP
	;query through our menu button, so that 1) this menu gets the GADGET
	;exclusive directly from the parent window (GenPrimary), and
	;2) so that as the high-level menus close, our menu button does not
	;force this menu to close.

	tst	cx
	jz	10$

	call	OLMenuWinGrabRemoteGadgetExcl

10$:	;tell the Flow Object that we want to be notified of ANY button press,
	;even if not on menu.

	call	VisAddButtonPrePassive

if _KBD_NAVIGATION and _MENU_NAVIGATION	;------------------------------

	;CUA/Motif: set focus to first object in menu (is currently 0:0).

	mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	call	WinClasses_ObjCallInstanceNoLock
endif		;--------------------------------------------------------------

		ret
OLMenuWinEnterStayUpMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinLeaveStayUpMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		MSG_MO_MW_LEAVE_STAY_UP_MODE

DESCRIPTION:	This method is sent by this object to itself when
		a pre-passive button event is received, indicating that
		we should exit stay-up mode.

PASS:		*ds:si - instance data
		es - segment of OLMenuWinClass
		ax - method
		cx, dx	- mouse position in screen coordinates
		bp	- [ UIFunctionsActive | buttonInfo ]
			(for menu window - indicates if pointer is inside menu)

RETURN:		ds:*si, es = same
		cx = TRUE if mouse over menu button

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLMenuWinLeaveStayUpMode	method dynamic	OLMenuWinClass,
					MSG_MO_MW_LEAVE_STAY_UP_MODE

EC <	call	VisCheckVisAssumption	;make sure ds:*si ok		>

	;FIRST: make sure that we are in stay-up-mode, so that we don't
	;mess up the state of the parent window (GenPrimary) by telling it
	;that we are leaving stay-up-mode when we aren't.

;Do we ever have a case where the OMWSS_IN_STAY_UP_MODE has been reset already,
;so that we don't release our VisRemoveButtonPrePassive before the window
;goes away??? Seems to happen 1/100 times that menu navigation is used.
;
;Should not be a problem, as VisRemoveButtonPrePasive is called from VisClose,
;just to make sure that it is gene -- Doug
;
	test	ds:[di].OLMWI_specState, mask OMWSS_IN_STAY_UP_MODE
	jz	done			;skip if not in stay-up mode...

	;reset state bit, remove passive grab, ;and send
	;MSG_MO_MB_LEAVE_STAY_UP_MODE to OLMenuButton, so it knows to set
	;closing = TRUE

	ANDNF	ds:[di].OLMWI_specState, not (mask OMWSS_IN_STAY_UP_MODE)

	call	VisRemoveButtonPrePassive

	;inform our parent window that it has no menu in stay-up mode.
	;(If this is a menu or sub-menu, inform GenPrimary/GenDisplay/
	;GenSummons, etc. If is a sys-menu for a pinned menu, inform
	;the menu.)

	push	cx, dx, bp
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_NO_MENU_IN_STAY_UP_MODE
	call	OLMenuWinCallButtonOrGenParent
	pop	cx, dx, bp

	;First: send method to menu button which opens this menu,
	;so it will reset its state bit
	;Pass: bp - [ UIFunctionsActive | buttonInfo ]
	;	(for menu window - indicates if pointer is inside menu)

	tst	ds:[di].OLPWI_button	;make sure we have a button
	jnz	sendToButton		;if yes, send to button

	clr	cx			;else return cx = FALSE
	ret

sendToButton:
	mov	ax, MSG_MO_MB_LEAVE_STAY_UP_MODE
	call	OLPopupWinSendToButton
done:
	ret
OLMenuWinLeaveStayUpMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinCascadeMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/disables cascade mode.
		Will cause submenu's to be killed if disabling cascade mode
		or cascading with a different submenu optr.
		Will automatically start the grab for this window if the
		result of this call closes a menu.

CALLED BY:	MSG_MO_MW_CASCADE_MODE
PASS:		*ds:si	= OLMenuWinClass object
		ds:di	= OLMenuWinClass instance data
		ds:bx	= OLMenuWinClass object (same as *ds:si)
		es 	= segment of OLMenuWinClass
		ax	= message #
		cl	= OLMenuWinCascadeModeOptions
			    OMWCMO_CASCADE
				True=Enable/False=Disable cascade mode.
			    OMWCMO_START_GRAB
			    	If TRUE, will take the grabs and take the gadget
				exclusive after setting the cascade mode.

		if OMWCMO_CASCADE = TRUE
		    ^ldx:bp = optr to submenu
		else
		    dx, bp are ignored

RETURN:		Nothing
DESTROYED:	ax, cx
SIDE EFFECTS:
	If cascade mode is enabled, the menu will NOT be closed when a
	lost gadget exclusive is received, nor when the passive grab wants
	to close it.  It will, however, still be closed by a
	MSG_MO_MW_GUP_SUBMENU_REQUESTS_CLOSE message if the ignore bit
	is not set.

PSEUDO CODE/STRATEGY:
	None

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuWinCascadeMode	method dynamic OLMenuWinClass,
					MSG_MO_MW_CASCADE_MODE
	.enter

	push	cx				; save for last	(cl)

	; set cascading information based upon argument

	; ensure original cascade data is correct before changing (EC)
EC <	call	OLMenuWinECCheckCascadeData				>

	mov	ch, ds:[di].OLMWI_moreSpecState	; save original state
	clr	ax				; use ah to keep cascade bit

	; Here we put the new cascade bit into ah, later into ch.
	; This value is or'ed back into instance data after the "done"
	; label.  This is done this way because some routines called below
	; depend upon the moreSpecState's CASCADE bit to be consistent with
	; the vardata which hasn't been changed yet.

	test	cl, mask OMWCMO_CASCADE
	jz	handleVarData
	ornf	ah, mask OMWMSS_IS_CASCADING

handleVarData:
	; check to see if the cascading bit changed

	xor	ch, ah
	test	ch, mask OMWMSS_IS_CASCADING	; test if bit changed
	push	cx				; case "changed" info (ch)
	mov	ch, ah				; new state is now in ch
	mov	ax, ATTR_OL_MENU_WIN_CASCADED_MENU
	jnz	updateVarData			; bit changed - fix var data

	; cascade bit hasn't change.  Check to see if the bit is true.
	test	cl, mask OMWCMO_CASCADE
	jz	done				; not cascading, we're done

	; We are cascading.  Make sure that the handle passed is the same as
	; the handle stored.

	call	ObjVarFindData			; ds:bx = ptr to data
EC <	ERROR_NC	OL_ERROR		; SHOULD HAVE VAR DATA	>

	; compare handle already in var data with ^ldx:bp (handle passed in)

	cmp	ds:[bx].handle, dx		; ^ldx:bp = handle passed in
	jne	changeVarData			; nope, need to change vardata
	cmp	ds:[bx].offset, bp
	je	done				; handle is the same, we're done

changeVarData:
	; handle not the same.  we need to force the close of the submenu
	; tree starting with the old handle, and then update the stored handle.

	; Close "old" submenus below this menu
	push	ax, cx, dx, bp, bx
	mov	cx, TRUE
	call	OLMenuWinSendCloseRequestToLastMenu	; destroy:ax,bx,cx,dx,bp
	pop	ax, cx, dx, bp, bx

	; change var data to reflect the new submenu.  Then we're done.
	call	ObjVarFindData				; may have moved
	movdw	ds:[bx], dxbp
	jmp	short done

updateVarData:
	; the bit has changed.. adjust the var data accordingly

	test	cl, mask OMWCMO_CASCADE
	jz	deleteVarData

	; add var data
	push	cx
	mov	cx, size optr			; size of data
	call	ObjVarAddData			; ds:bx = ptr to data
	movdw	ds:[bx], dxbp			; ^ldx:bp = handle passed in
	pop	cx
	jmp	short done

deleteVarData:
	; Close all submenus below current menu
	push	ax, cx
	mov	cx, TRUE
	call	OLMenuWinSendCloseRequestToLastMenu
	pop	ax, cx

	; Delete the var data
	call	ObjVarDeleteData
EC <	ERROR_C	OL_ERROR	; nothing deleted? should have var data!>

done:

	; ONLY the cascade bit should be set in ch.
EC <	test	ch, not (mask OMWMSS_IS_CASCADING)			>
EC <	ERROR_NZ	OL_ERROR			;ch got trashed >

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	; store new cascade bit
	andnf	ds:[di].OLMWI_moreSpecState, not mask OMWMSS_IS_CASCADING
	ornf	ds:[di].OLMWI_moreSpecState, ch

	; check to make sure that we didn't screw up the data consistency
EC <	call	OLMenuWinECCheckCascadeData				>

	; Decide to start up grabs and/or enter stay up mode.

	pop	cx					; "change" info (ch)
	pop	ax					; get passed flags (al)

	; If we are cascading, then don't do any of this.. we don't want to
	; take the gadget exclusive away from someone else...

	test	al, mask OMWCMO_CASCADE			; cascading?
	jnz	dontGrab				; yes.. done

	; ch = the OLMWI_moreSpecState cascading information that has changed.
	; We know that we aren't currently cascading.  So, IF we were
	; cascading (i.e. we closed submenus) OR we were told to start the
	; grab, then ask the window to startup grab.
	mov	cl, al
	test	cx, (mask OMWMSS_IS_CASCADING shl 8) or mask OMWCMO_START_GRAB
	jz	dontGrab				; nope.. done

	push	ax					; preserve passed flags
	mov	ax, MSG_OL_WIN_STARTUP_GRAB
	call	ObjCallInstanceNoLock
	pop	ax

	; Were we told to start grab? If so, then we also enter stay up
	; mode.  Otherwise, we just bail.
	test	al, mask OMWCMO_START_GRAB
	jz	dontGrab				; skip stay up mode...

	mov	cx, TRUE				; grab gadget exclusive
	mov	ax, MSG_MO_MW_ENTER_STAY_UP_MODE
	call	ObjCallInstanceNoLock

dontGrab:
	.leave
	ret
OLMenuWinCascadeMode	endm
endif	;_CASCADING_MENUS


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinMoveResizeWin -- MSG_VIS_MOVE_RESIZE_WIN for OLWinClass

DESCRIPTION:	Intercepts the method which does final positioning & resizing
		of a window, in order to allow pinned menu to be moved
		off-screen.

PASS:		*ds:si 	- instance data
		es     	- segment of OLMenuWinClass

		ax 	- MSG_VIS_MOVE_RESIZE_WIN

RETURN:		nothing

DESTROYED:	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@


OLMenuWinMoveResizeWin	method dynamic	OLMenuWinClass, MSG_VIS_MOVE_RESIZE_WIN
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	callSuper		;skip if not...

	;relax positioning behavior somewhat - allow menu to be
	;partially obscured.

	ANDNF	ds:[di].OLWI_winPosSizeFlags, not (mask WPSF_CONSTRAIN_TYPE)
	ORNF	ds:[di].OLWI_winPosSizeFlags, \
		   WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE

callSuper:
	;finally, call superclass to do move/resize

	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far

	;and update scrollers if needed

	call	ImGetButtonState		; non-zero if pressed
	call	OLMenuWinUpdateUpDownScrollers

	ret
OLMenuWinMoveResizeWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinVisClose -- MSG_VIS_CLOSE for OLMenuWinClass

DESCRIPTION:	We intercept this method here so that we can release
		any remote gadget exclusives that we might have.

PASS:		*ds:si - instance data

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuWinVisClose	method dynamic	OLMenuWinClass, MSG_VIS_CLOSE

	;send query to generic parent (do not send to self, in the hope
	;of deciding whether to send to button or genparent, because self
	;will handle as if a child had called!)

	push	ax, cx, dx, bp
	call	OLMenuWinReleaseRemoteGadgetExcl
	pop	ax, cx, dx, bp

	;call superclass (OLPopupWinClass) for default handling

	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far

	; Update up/down scrollers as needed

	mov	al, 0
	call	OLMenuWinUpdateUpDownScrollers

	ret
OLMenuWinVisClose	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinEnsureNoMenusInStayUpMode

DESCRIPTION:	This method is sent from the Flow object to all objects
		which have active or passive mouse grabs.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		cx:dx - EnsureNoMenusInStayUpModeParams, of null if no buffer
			passed

RETURN:		ax = 0 (due to byte-saving measure in FlowObject)

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		Initial version

------------------------------------------------------------------------------@

OLMenuWinEnsureNoMenusInStayUpMode method dynamic OLMenuWinClass, \
				MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE

	;if PINNED = TRUE, it means that we are entering pinned mode.
	;Do not close menu if so.

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	done

	;Otherwise, if the menu is in stay-up-mode, force it to close now.

	test	ds:[di].OLMWI_specState, mask OMWSS_IN_STAY_UP_MODE
	jz	done			;exit if not stay up mode

	tst	cx
	jnz	incDismissCount
	push	cx, dx, bp
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
        call    WinClasses_ObjCallInstanceNoLock
	pop	cx, dx, bp
	jmp	short sendToKids

incDismissCount:
	tst	cx				;no buffer, branch
	jz	sendToKids
EC <	push	ds, si							>
EC <	movdw	dssi, cxdx						>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
	mov	es, cx
	mov	bx, dx
	inc	es:[bx].ENMISUMP_menuCount	;increment menu count

sendToKids:
	;
	; Now, to close any of our submenus, send to our children
	;
	mov	ax, MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE
	call	GenSendToChildren

done:
	clr	ax			;Return "MouseFlags" null
	ret
OLMenuWinEnsureNoMenusInStayUpMode endm

WinClasses	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinFupKbdChar - MSG_META_FUP_KBD_CHAR handler
			for OLMenuWinClass

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

PASS:		*ds:si	= instance data for object
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

if _KBD_NAVIGATION	;------------------------------------------------------
OLMenuWinFupKbdChar	method dynamic	OLMenuWinClass, MSG_META_FUP_KBD_CHAR

	push	ax			;save method
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	LONG jz	callSuper		;skip if not press event...

;ADDED 10/23/90 by Eric to prevent pinned menus from interpreting keyboard
;navigation keys which would try to close the menu.

	;if this menu is pinned (the user must have pinned it using
	;keyboard navigation, for the focus to be inside the menu),
	;then ignore key at this class level.

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	checkControlMenuNavigationThenInternalKeys ;skip if is pinned...

	;if this menu has a menu button (i.e. is not a popup menu), then
	;first check for the keys which cause us to send methods to the button.

	tst	ds:[di].OLPWI_button	;is there a menu button?
	jz	checkInternalKeys	;skip if not...

	;we will check these keys using two tables: one for menus, one
	;for sub-menus.

	mov	bx, ds:[di].OLCI_buildFlags
	ANDNF	bx, mask OLBF_REPLY
	cmp	bx, OLBR_SUB_MENU shl offset OLBF_REPLY

	push	es			;set es:di = table of shortcuts
	segmov	es, cs
	mov	di, offset cs:OLMenuWinKbdBindings
	jne	10$			;skip if is menu...

	;is a sub-menu

	mov	di, offset cs:OLMenuWinKbdBindings2

10$:
	call	ConvertKeyToMethod
	pop	es
	jnc	checkInternalKeys	;skip if none found...


	cmp	ax, MSG_META_DUMMY	 ;left-arrow in sub-menu?
	je	closeSubMenuToParentMenu ;skip if so...

sendToButton:
	ForceRef sendToButton

	;
	; Code put in here to do nothing with left and right arrows for express
	; menus, so we won't have complicated deaths in express submenus.
	; There's probably a cleaner solution than this.  -cbh 11/ 4/92
	;
if EVENT_MENU
	push	ax
	mov	ax, HINT_EVENT_MENU
	call	ObjVarFindData
	pop	ax
	jc	19$
endif
	push	ax
	mov	ax, HINT_EXPRESS_MENU
	call	ObjVarFindData
	pop	ax
	jnc	20$
19$::
SBCS <	mov	cx, (CS_CONTROL shl 8) or VC_ESCAPE	;make an escape key >
DBCS <	mov	cx, C_SYS_ESCAPE			;make an escape key >
	mov	ax, MSG_META_FUP_KBD_CHAR
20$:

	call	OLMenuWinFocusAndCallButton ;trashes si

popExit:
	pop	ax
	stc				;say handled
	ret

closeSubMenuToParentMenu:
	call	OLMenuWinKbdCloseSubMenuToParentMenu ;trashes si
	pop	ax
	stc				;say handled
	ret

;ADDED 10/23/90 by Eric to allow usage of the System Menu Button in a
;pinned menu.

checkControlMenuNavigationThenInternalKeys:
					;pass ds:di = instance data
	call	HandleMenuNavigation	;do menu navigation, if needed
	jnc	checkInternalKeys	;skip if not handled...
	pop	ax
	ret

checkInternalKeys:
	;now check for keys which we can handle by navigating within
	;this menu.

	push	es			;set es:di = table of shortcuts
	segmov	es, cs
	mov	di, offset cs:OLMenuWinKbdBindings3
	call	ConvertKeyToMethod
	pop	es
	jnc	callSuper		;skip if none found...


sendToSelf::

	push	ds			;save KBD char in idata so that when
	mov	bp, segment idata
	segmov	ds, bp			;new child item (possibly a genlist)
	mov	ds:[lastKbdCharCX], cx	;gains focus, it knows whether to start
	pop	ds			;at top or bottom item in list.

	mov	cx, IC_INTERACTION_COMPLETE	;in case we send
						;MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjCallInstanceNoLock

	push	ds			;reset our saved KBD char to "none"
	mov	bp, segment idata	;so that if a genlist gains the focus
	segmov	ds, bp
	clr	ds:[lastKbdCharCX]	;because the menu regains focus,
	pop	ds			;it starts at the top item in the list
handled::
	pop	ax
	stc				;say handled
	ret


callSuper:
	;we don't care about this keyboard event. Call our superclass
	;so it will be forwarded up the focus hierarchy.

	pop	ax			;get method
	mov	di, offset OLMenuWinClass
	GOTO	ObjCallSuperNoLock

OLMenuWinFupKbdChar	endm


;Keyboard shortcut bindings for OLMenuWinClass (do not separate tables)

;*** KEYS FOR MENU, WHICH WILL SEND METHODS TO THE MENU BUTTON ***


OLMenuWinKbdBindings	label	word
	word	length OLMWShortcutList
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r

if DBCS_PCGEOS
OLMWShortcutList KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;previous menu
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;next menu
	<0, 0, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>	;close menu, go up
else
OLMWShortcutList KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_LEFT>,	;NAVIGATE TO PREVIOUS (MENU)
	<0, 0, 0, 0, 0xf, VC_RIGHT>,	;NAVIGATE TO NEXT (MENU)
	<0, 0, 0, 0, 0xf, VC_ESCAPE>	;CLOSE MENU (will continue up tree)
endif

	;insert additional shortcuts here.

;OLMWMethodList	label word
	word	MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
					;use SPEC instead of GEN method since
					;we are sending to non-generic objects.
	word	MSG_META_FUP_KBD_CHAR	;will send cx, dx, bp up to menu button
					;disguised as MSG_META_FUP_KBD_CHAR.
					;Button will close this menu and those
					;above it.


;*** KEYS FOR SUB-MENU, WHICH WILL SEND METHODS TO THE MENU BUTTON ***

OLMenuWinKbdBindings2	label	word
	word	length OLMWShortcutList2
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r

if DBCS_PCGEOS
OLMWShortcutList2 KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;close sub-menu
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;close, go to next
	<0, 0, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>	;close menu, go up
else
OLMWShortcutList2 KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_LEFT>,	;CLOSE THIS SUB-MENU (ONLY)
	<0, 0, 0, 0, 0xf, VC_RIGHT>,	;CLOSE THIS SUB-MENU AND THE PARENT
					;MENU, OPEN THE NEXT TOP-LEVEL MENU.
	<0, 0, 0, 0, 0xf, VC_ESCAPE>	;CLOSE MENU (will continue up tree)
endif

	;insert additional shortcuts here.

;OLMWMethodList2	label word
	word	MSG_META_DUMMY		;we will handle this specially: see
					;OLMenuWinKbdCloseSubMenuToParentMenu
	word	MSG_OL_MENU_BUTTON_SEND_RIGHT_ARROW_TO_PARENT_MENU
					;send method to menu button, so it will
					;send a MSG_META_FUP_KBD_CHAR to the
					;menu it is in, simulating the RIGHT
					;arrow being pressed. Will close parent
					;menu, and open next top-level menu.
	word	MSG_META_FUP_KBD_CHAR	;will send cx, dx, bp up to menu button
					;disguised as MSG_META_FUP_KBD_CHAR.
					;Button will close this menu and those
					;above it.



;*** KEYS FOR MENU, WHICH ARE SENT TO THIS MENU ***

OLMenuWinKbdBindings3	label	word
	word	length OLMWShortcutList3
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
 if DBCS_PCGEOS
OLMWShortcutList3 KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;previous menu item
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;next menu item
	<0, 0, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>	;close popup
 else
OLMWShortcutList3 KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_UP>,	;NAVIGATE TO PREVIOUS menu item
	<0, 0, 0, 0, 0xf, VC_DOWN>,	;NAVIGATE TO NEXT menu item
	<0, 0, 0, 0, 0xf, VC_ESCAPE>	;CLOSE THIS POPUP MENU (has no button)
 endif


	;insert additional shortcuts here.

;OLMWMethodList3	label word
	word	MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	word	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	word	MSG_GEN_GUP_INTERACTION_COMMAND
;ODIE: adding items here requires change in code above


endif	;----------------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLMenuWinFocusAndCallButton

SYNOPSIS:	Places the FOCUS exclusive on the menu button, and then
		forwards the passed method on to it.

		IMPORTANT: this is not called for popup menus, since they
		DO NOT have a menu button!

CALLED BY:	OLMenuWinFupKbdChar

PASS:		*ds:si -- handle
		ax     -- navigation method to call button's parent with

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/90		Initial version
	Eric	6/90		update, more doc.

------------------------------------------------------------------------------@

OLMenuWinFocusAndCallButton	proc	near
	class	OLMenuWinClass
	;set *ds:si = OLMenuButtonClass object, and send some methods to it.

	call	KN_DerefVisSpec_DI
	mov	si, ds:[di].OLPWI_button	;set *ds:si = menu button

EC <	tst	si							>
EC <	ERROR_Z OL_ERROR			;we MUST have a button	>
EC <	call	VisCheckVisAssumption		;make sure everything's OK >

	;
	; skip giving focus to menu button if kbd-char (ESCAPE)
	;
	cmp	ax, MSG_META_FUP_KBD_CHAR
	je	afterFocus

	;first move the focus inside the Primary to the menu button.
	;(must indicate that is MENU_RELATED!)

	push	ax, cx, dx, bp
	mov	bp, mask MAEF_OD_IS_MENU_RELATED or \
		    mask MAEF_GRAB or mask MAEF_FOCUS or mask MAEF_NOT_HERE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp			;restore method args
afterFocus:

	;Do whatever navigation is called for at the menu bar level.
	;(send to menu button, not its parent, since we might be sending
	;MSG_META_FUP_KBD_CHAR.)

	push	ax
	call	ObjCallInstanceNoLock		;navigate / handle ESCAPE
	pop	ax

	cmp	ax, MSG_OL_MENU_BUTTON_SEND_RIGHT_ARROW_TO_PARENT_MENU
	je	exit				;skip if not navigating...

	cmp	ax, MSG_META_FUP_KBD_CHAR		;if not navigating,
	je	exit				;skip to end...

	;else, was navigating: Find out which object in the window
	;was navigated to, and send a method which will only activate
	;menu buttons. Standard OLButtonClass objects will ignore.

	mov	ax, MSG_VIS_VUP_QUERY_FOCUS_EXCL
	call	VisCallParent		  	;returns focus in cx:dx

	mov	bx, cx				  ;set up focus in ^lbx:si
	mov	si, dx
	mov	ax, MSG_OL_MENU_BUTTON_KBD_ACTIVATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

exit:
	ret
OLMenuWinFocusAndCallButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinSendCloseRequestToParentMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up the generic tree to find an object of class
		OLMenuWinClass.  The search is continued until an
		object that is not a subclass of GenInteractionClass is
		found.  If it finds the menu window, the message
		MSG_MO_MW_CASCADE_MODE(OMWCMO_START_GRAB) is called.
		The menu window object's vis part MUST already be built.

CALLED BY:	OLMenuWinKbdCloseSubMenuToParentMenu
PASS:		*ds:si	= menu object
RETURN:		*ds:si = current menu object.  (ds is fixed up).
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/6/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuWinSendCloseRequestToParentMenu	proc	near
	uses	si, es
	.enter

	mov	bx, ds:[LMBH_handle]
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLPWI_button	; ^lbx:si = menu button
	tst	si
	jz	done

searchLoop:
	mov	ax, MSG_VIS_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jcxz	done

	movdw	bxsi, cxdx			; ^lbx:si = parent
	call	ObjSwapLock

	segmov	es, <segment GenInteractionClass>, di
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	jnc	unlock				; break out of loop

	segmov	es, <segment OLMenuWinClass>, di
	mov	di, offset OLMenuWinClass
	call	ObjIsObjectInClass
	cmc
	jc	unlock				; continue up tree

	mov	cl, mask OMWCMO_START_GRAB
	mov	ax, MSG_MO_MW_CASCADE_MODE
	call	ObjCallInstanceNoLock
	clc
unlock:
	call	ObjSwapUnlock
	jc	searchLoop			; continue if carry set
done:
	.leave
	ret
OLMenuWinSendCloseRequestToParentMenu	endp
endif	;_CASCADING_MENUS


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinKbdCloseSubMenuToParentMenu

DESCRIPTION:	This procedure is used when the left-arrow key is pressed
		inside the menu. If this menu is not pinned, we close this
		menu, and place the focus on our menu button,
		inside the parent menu.

CALLED BY:	OLMenuWinFupKbdChar

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuWinKbdCloseSubMenuToParentMenu	proc	far
	class	OLMenuWinClass

	call	KN_DerefVisSpec_DI
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	LONG jnz	done

if ERROR_CHECK

;Do NOT test for WAS_PINNED case.
;	fail case: pin a sub-menu, then try to navigate to it by going through
;	the parent menu. Once the sub-menu is visible, press left-arrow to
;	get back to parent.
;
;	test	ds:[di].OLMWI_specState, mask OMWSS_WAS_PINNED
;	ERROR_NZ OL_ERROR

	;make sure this menu is a sub-menu

	mov	bx, ds:[di].OLCI_buildFlags	;will be used below
	ANDNF	bx, mask OLBF_REPLY		;see if we are sub-menu or menu
	cmp	bx, OLBR_SUB_MENU shl offset OLBF_REPLY
	ERROR_NE OL_ERROR
endif



	;set *ds:si = OLMenuButtonClass object, and send some methods to it.

	push	si			;save *ds:si = submenu
	mov	si, ds:[di].OLPWI_button ;set *ds:si = menu button
	push	si			;save menu button
	call	KN_DerefVisSpec_DI 	;set ds:di = menu button

	;make sure that we have a valid menu button, and that it thinks
	;this menu is opened

EC <	tst	si							>
EC <	ERROR_Z OL_ERROR			;we MUST have a button	>
EC <	call	VisCheckVisAssumption		;make sure everything's OK >

EC <	test	ds:[di].OLMBI_specState, mask OLMBSS_POPUP_OPEN	>
EC <	ERROR_Z OL_ERROR					>

	;reset OLButton and OLMenuButton state flags for this menu button

	.warn	-private

	ANDNF	ds:[di].OLMBI_specState, not (mask OLMBSS_POPUP_OPEN)

	.warn	@private

	;hack: force the button to reset itself visually (without redrawing),
	;so that when it gains the focus, it can save this state again.

					;pass ds:di = instance data
	call	OLButtonRestoreBorderedAndDepressedStatus

	;now make sure that the parent menu that this menu button is inside
	;gets the focus window exclusive from the GenPrimary.

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	CallOLWin
	pop	si			;restore *ds:si = menu button

	;dismiss this menu. It has already lost the focus. This will
	;cause the menu button to redraw properly.

	pop	di			;set *ds:si = submenu
	xchg	si, di			;set *ds:di = menu button, *ds:si=menu

	push	si
	push	di
if _CASCADING_MENUS
	;
	; close last menu only
	;
	call	OLMenuWinSendCloseRequestToParentMenu
else
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock
endif
	pop	si			;set *ds:si = menu button


	;now move the focus inside the parent menu to the menu button.
	;(DO NOT pass IS_MENU_RELATED flag!) This will cause the menu button
	;to draw properly. (*ds:si = menu button)

	call	MetaGrabFocusExclLow
afterGrab:
	pop	si			;restore *ds:si = menu

done:
	ret
OLMenuWinKbdCloseSubMenuToParentMenu	endp

KbdNavigation	ends


WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinBringToTop

DESCRIPTION:	Intercepts default handler to check to see if this is an
		app modal window.  If it is, & it is coming to the top of
		the screen, then it should be made THE modal window within
		the application.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_BRING_TO_TOP

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@


;IMPORTANT: this method handler must match OpenWinBringToTop in functionality,
;except for FOCUS handling.

OLMenuWinBringToTop	method dynamic	OLMenuWinClass, MSG_GEN_BRING_TO_TOP

	;if this window is not opened then abort: the user or application
	;caused the window to close before this method arrived via the queue.

	call	VisQueryWindow
	tst	di
	jz	setGenState		; Skip if window not opened...

	;Raise window to top of window group

	clr	ax
	clr	dx			; Leave LayerID unchanged
	call	WinChangePriority

	call	MenuWinScrollerEnsureOnTop

	;if this menu is pinned, DO NOT grab the FOCUS exclusive.
	;During MSG_META_START_BUTTON, we will determine if a menu item is
	;being pressed on, and will decide whether to grab the focus.
	;Note: no need to grab the target exclusive.

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	setGenState		;skip if is pinned...

	call	OpenCheckIfMenusTakeFocus
	jnc	setGenState

	;
	; Let's try grabbing the mouse.  The problem is that when this menu
	; comes up, the menu button that created it gets a MSG_META_PTR out
	; of its bounds, which causes it to release the mouse, and realizing
	; that it did have the mouse beforehand, causes it to give the focus
	; back to its parent window.  So submenus never get the focus.
	; -cbh 6/22/92  (Removed -- causes problems when clicking and
	; releasing on the left-edge of submenu menu buttons -- the submenu
	; goes away without doing anyway when you click on it. -cbh 10/13/92)
	;
;	call	VisGrabMouse

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	WinClasses_ObjCallInstanceNoLock
					;Make it the focus window, if posible

setGenState:
					; Raise the active list entry to
					; the top, to reflect new/desired
					; position in window hierarchy.
					; (If no active list entry, window
					; isn't up & nothing will be done)
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_APPLICATION_BRING_WINDOW_TO_TOP
	call	GenCallApplication
	ret
OLMenuWinBringToTop	endm

MenuWinScrollerEnsureOnTop	proc	near
		uses	bx, si, di
		.enter
		mov	ax, TEMP_OL_MENU_WIN_SCROLLERS
		call	ObjVarFindData
		jnc	done
		push	ds:[bx].MWSS_downScroller
		mov	si, ds:[bx].MWSS_upScroller
		call	ensureScrollerOnTop
		pop	si
		call	ensureScrollerOnTop
done:
		.leave
		ret

ensureScrollerOnTop	label	near
		tst	si
		jz	ensureDone
		mov	di, ds:[si]
		mov	di, ds:[di].MWSI_window
		tst	di
		jz	ensureDone
		clr	ax, dx			; just bring to top of layer
		call	WinChangePriority
ensureDone:
		retn
MenuWinScrollerEnsureOnTop	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinGrabGadgetExcl

DESCRIPTION:	This routine ensures that the gadget exclusive mechanism
		is set up to that it will close this menu if the parent
		window (GenPrimary) suddenly goes away. Note that this routine
		works according to whether the mouse or keyboard was used
		to place the menu in stay-up-mode:

		MOUSE: we send a VUP query through our menu button, so that
		it will eventually reach the GenPrimary. We grab the gadget
		exclusive directly from the primary, forcing any higher-level
		or same-level menus to close.

		KBD: we do absolutely nothing. Since this menu was placed
		in stay-up mode via the keyboard, the user must have of
		activated our menu button. Therefore that button has the
		gadget exclusive, and will close this menu if the button
		loses the gadget.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLMenuWinGrabRemoteGadgetExcl	proc	far		; uses GOTO
	;send query to button or generic parent (do not send to self, in the
	;hope of deciding whether to send to button or genparent, because self
	;will handle as if a child had called!) If this query passes through
	;our menu button, it will reset a state flag and then be sent up the
	;tree as a standard SVQT_REMOTE_GRAB_GADGET_EXCL query.

	mov	cx, SVQT_NOTIFY_MENU_BUTTON_AND_REMOTE_GRAB_GADGET_EXCL
	mov	ax, MSG_VIS_VUP_QUERY
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	GOTO	OLMenuWinCallButtonOrGenParent
OLMenuWinGrabRemoteGadgetExcl	endp

OLMenuWinReleaseRemoteGadgetExcl	proc	far	; uses GOTO

	mov	cx, SVQT_REMOTE_RELEASE_GADGET_EXCL
	mov	ax, MSG_VIS_VUP_QUERY
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	GOTO	OLMenuWinCallButtonOrGenParent

OLMenuWinReleaseRemoteGadgetExcl	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinVupQuery -- MSG_VIS_VUP_QUERY for OLMenuWinClass

DESCRIPTION:	Respond to MSG_VIS_VUP_QUERY.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLMenuWin)
		cx	= SpecVisQueryType (see cConstant.def)

RETURN:		carry set if answered query

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@

OLMenuWinVupQuery	method dynamic	OLMenuWinClass, MSG_VIS_VUP_QUERY

	cmp	cx, SVQT_HAS_MENU_IN_STAY_UP_MODE
	je	callSuperIfPinned
	cmp	cx, SVQT_NO_MENU_IN_STAY_UP_MODE
	je	callSuperIfPinned	;Both changed from callSuperIfPinned
					;  so this function actually does
					;  what it's supposed to in non-pinned
					;  menus.  -cbh 12/30/93
					;Changed back to callSuperIfPinned
					;  to fix problem with submenus not
					;  staying up if parent menu is not in
					;  stay up mode. - Joon (7/28/94)

	cmp	cx, SVQT_REMOTE_GRAB_GADGET_EXCL
	je	callSuperIfPinned		;skip if cannot handle query...

	cmp	cx, SVQT_REMOTE_RELEASE_GADGET_EXCL
	je	callSuperIfPinned

callSuper:
	GOTO	WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far

callSuperIfPinned:
	;if this is a pinned menu (or will revert back to being a pinned
	;menu shortly), behave as a base window: call superclass,
	;so that OLWinClass handles this query as if this window was
	;a GenPrimary. Otherwise (is normal menu), send query up tree.

	FALL_THRU OLMenuWinCallSuperIfPinned
OLMenuWinVupQuery	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinCallSuperIfPinned

DESCRIPTION:	If this menu is pinned (or will shortly revert back to being
		pinned), then behave as a base window: call superclass,
		so that OLWinClass handles this query as if this window was
		a GenPrimary.

CALLED BY:	OLMenuWinVupQuery, OLMenuWinVupGrabFocusWinExcl

PASS:		*ds:si	= instance data for object
		es	= segment of OLMenuWinClass
		ax	= method to send
		cx, dx, bp = data to send with method

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLMenuWinCallSuperIfPinned	proc	far
	class	OLMenuWinClass
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	callSuper		;skip if pinned (cy=0)...

	test	ds:[di].OLMWI_specState, mask OMWSS_WAS_PINNED
	jnz	callSuper		;skip if pinned (cy=0)...

	;this menu is not pinned: is an intermediate menu inbetween the
	;requesting submenu, and the base window. Forward up the tree:
	;if has a menu button, send VUP_QUERY from that button. Otherwise,
	;send to generic parent and pray!

	GOTO	OLMenuWinCallButtonOrGenParent

callSuper:
	GOTO	WinClasses_ObjCallSuperNoLock_OLMenuWinClass_Far
OLMenuWinCallSuperIfPinned	endp

OLMenuWinCallButtonOrGenParent	proc	far	;called via GOTO
	class	OLMenuWinClass
	;this menu is not pinned: is an intermediate menu inbetween the
	;requesting submenu, and the base window. Forward up the tree:
	;if has a menu button, send VUP_QUERY from that button. Otherwise,
	;send to generic parent and pray!

	call	WinClasses_DerefVisSpec_DI

	.warn	-private

	tst	ds:[di].OLPWI_button	;do we have a menu button?

	.warn	@private

	jz	callGenParent		;skip if not...

	call	OLPopupWinSendToButton	; (is movable, so no GOTO)
	ret

callGenParent:
	GOTO	GenCallParent
OLMenuWinCallButtonOrGenParent	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinAlterFTVMCExcl

DESCRIPTION:	We intercept this method here so that if a sub-menu requests
		the focus window exclusive from an un-pinned menu,
		we forward the request on up to the parent window (GenPrimary
		or GenDisplay).

PASS:		*ds:si - instance data
		ax - MSG_VIS_VUP_ALTER_FTVMC_Excl
		^lcx:dx	- OD of object
		bp	- MetaAlterFTVMCExclFlags for object

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Doug	10/91		merged VUP_GRAB & VUP_RELEASE handlers here

------------------------------------------------------------------------------@

OLMenuWinAlterFTVMCExcl	method dynamic	OLMenuWinClass,	\
					MSG_META_MUP_ALTER_FTVMC_EXCL

	test	bp, mask MAEF_NOT_HERE	; if asking for exclusive ourself,
	jnz	callSuper		; let superclass do right thing

	; If a child object, however, decide what to do with request
	;
	test	bp, mask MAEF_FOCUS	; If not focus,
	jz	callSuper		; send request to superclass

	; Otherwise, figure out if we should redirect request
	;
	test	bp, mask MAEF_GRAB
	jz	release

;grab:
	; First, see if sub-menu requesting grab.  If not, just pass on
	; request to superclass for normal handling
	;
	test	bp, mask MAEF_OD_IS_WINDOW
	jz	callSuper
	test	bp, mask MAEF_OD_IS_MENU_RELATED
	jz	callSuper

	;if this is a pinned menu (or will revert back to being a pinned
	;menu shortly), behave as a base window: call superclass,
	;so that OLWinClass handles this query as if this window was
	;a GenPrimary. Otherwise (is normal menu), send query up tree.

	GOTO	OLMenuWinCallSuperIfPinned

release:
	;Typically, we could just call OLMenuWinCallSuperIfPinned, and
	;it would decide whether this menu should handle this VUP, or if it
	;should forward it up to the Primary. But we have a situation where
	;as this pinned menu is CLOSING, its system menu closes, and releases
	;the focus window exclusive from this pinned menu. The problem is that
	;since this menu is closing, the PINNED flag has been reset,
	;and so we would forward this VUP to the Primary, when in fact we
	;should handle it here, since this menu was recently pinned.

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	callSuper		;skip if pinned (cy=0)...

	test	ds:[di].OLMWI_specState, mask OMWSS_WAS_PINNED
	jnz	callSuper		;skip if pinned (cy=0)...

	;If not pinned, might have been recently pinned, or object releasing
	;is not a sub-menu which grabbed the focus from the primary, so
	;check to see if object actually does have grab here before sending
	;on to primary.

	cmp	cx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	jne	10$
	cmp	dx, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	je	callSuper		;skip to release exclusive from THIS
					;windowed object...

	;(no need to check the OLWI_prevFocusExcl, since menu ODs are not
	;stored there: just gadgets, and they don't send RELEASE_FOCUS_EXCL)

10$:	;this menu is not pinned: is an intermediate menu inbetween the
	;requesting submenu, and the base window. Forward up the tree:
	;if has a menu button, send VUP_QUERY from that button. Otherwise,
	;send to generic parent and pray!

	GOTO	OLMenuWinCallButtonOrGenParent

callSuper:
	;
	; fix problem of opening and pinning a submenu from a pinned menu
	; resulting in the focus being returned to the pinned menu instead
	; of the previous focus in the Primary -- if after release the focus
	; for the becoming-pinned sub-menu, we are focus-less, then release
	; the focus from ourselves.  We will still have a focus if you open
	; the submenu, then close it via kbd navigation.  - brianc 1/22/93
	;
	push	bp
	call	WinClasses_ObjCallSuperNoLock_OLMenuWinClass
	pop	bp
	test	bp, mask MAEF_GRAB or mask MAEF_NOT_HERE
	jnz	done			; not submenu release
	test	bp, mask MAEF_FOCUS
	jz	done			; not focus
	call	WinClasses_DerefVisSpec_DI
	tst	ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	jnz	done			; have focus

; Should we do this test also - brianc 1/22/93
; Yes.  2/24/94 cbh (

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	done			; wasn't pinned
; )

	call	MetaReleaseFocusExclLow
	;
	; Give focus to next best window (will usually turn out to be the
	; current target window)
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	GenCallApplication
done:
	ret
OLMenuWinAlterFTVMCExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinRecalcSize --
		MSG_VIS_RECALC_SIZE for OLMenuWinClass

DESCRIPTION:	Recalc's size.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE

		cx, dx  - size suggestions

RETURN:		cx, dx  - size to use
		ax, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 1/92		Initial Version

------------------------------------------------------------------------------@

OLMenuWinRecalcSize	method dynamic OLMenuWinClass, MSG_VIS_RECALC_SIZE
	call	MenuWinPassMarginInfo
	call	OpenRecalcCtrlSize
	ret
OLMenuWinRecalcSize	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinVisPositionBranch --
		MSG_VIS_POSITION_BRANCH for OLMenuWinClass

DESCRIPTION:	Positions the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_POSITION_BRANCH
		cx, dx  - position

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 1/92		Initial Version

------------------------------------------------------------------------------@

OLMenuWinVisPositionBranch	method dynamic	OLMenuWinClass, \
				MSG_VIS_POSITION_BRANCH

	call	MenuWinPassMarginInfo
	call	VisCompPosition
	ret
OLMenuWinVisPositionBranch	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	MenuWinPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLMenuWinRecalcSize, OLMenuWinPositionBranch

PASS:		*ds:si -- MenuWin bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

MenuWinPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OLMenuWinGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OpenWinGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
MenuWinPassMarginInfo	endp

WinClasses	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinGetSpacing --
		MSG_VIS_COMP_GET_CHILD_SPACING for OLMenuWinClass

DESCRIPTION:	Handles spacing for the OLMenuWinClass.  Makes very small
		spacing between the non-outlined buttons in unpinned menus.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_COMP_GET_CHILD_SPACING

RETURN:		cx	- spacing between children
		dx	- spacing between lines of wrapped children

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/18/89		Initial version

------------------------------------------------------------------------------@

OLMenuWinGetSpacing method OLMenuWinClass, MSG_VIS_COMP_GET_CHILD_SPACING
	;
	; Do normal window stuff.
	;
	mov	cx, MENU_SPACING		;no spacing between menu items
	mov	dx, cx

if _MENUS_PINNABLE	;------------------------------------------------------
if _OL_STYLE	;START of OPEN_LOOK specific code -----------------------------

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED   ;if pinned, exit
	jnz	OLMWGS_exit
	mov	cx, 1				;else very minimal spacing
endif
endif
	ret
OLMenuWinGetSpacing	endp

WinMethods	ends

;-------------------------------

KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinFindKbdAccelerator --
		MSG_GEN_FIND_KBD_ACCELERATOR for OLMenuWinClass

DESCRIPTION:	Looks for keyboard accelerator.  The only reason this is
		subclassed is to set the gadget exclusive when we activate
		the menu button.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_FIND_KBD_ACCELERATOR
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if accelerator found and dealt with

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 4/90		Initial version

------------------------------------------------------------------------------@

OLMenuWinFindKbdAccelerator method OLMenuWinClass, \
				   MSG_GEN_FIND_KBD_ACCELERATOR
	call	GenCheckKbdAccelerator		;see if we have a match
	jnc	exit				;nope, exit

	call	KN_DerefVisSpec_DI
	mov	si, ds:[di].OLPWI_button	;application releasing the
	tst	si				;no button, exit
	jz	exit

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OL_BUTTON_KBD_ACTIVATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	stc
exit:
	ret
OLMenuWinFindKbdAccelerator	endm

KbdNavigation	ends


WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuWinLostGadgetExcl

DESCRIPTION:	This method is sent when some other object in the parent window
		(GenPrimary or pinned parent menu) grabs the gadget exclusive.

		NOTE: if we get this method, it means that we HAVE the
		gadget exclusive; so therefore this menu is in stay-up-mode,
		or is a popup menu which is being held open.
		If the menu button which opens this menu is grabbing the
		gadget exclusive, we ignore this loss, because we know
		this button is going to open this menu shortly.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

OLMenuWinLostGadgetExcl	method dynamic	OLMenuWinClass, MSG_VIS_LOST_GADGET_EXCL

	mov	di, ds:[di].OLPWI_button
	tst	di			;do we have a menu button?
	jz	genDismissInteraction	;skip if not (is popup menu)...

	;this is a standard menu: if menu button is going to open menu,
	;DO NOT close menu now! (*ds:di = OLMenuButtonClass object)

	.warn	-private

	mov	di, ds:[di]		;set ds:di = Spec instance data for
	add	di, ds:[di].Vis_offset	;the OLMenuButtonClass object
	test	ds:[di].OLBI_specState, mask OLBSS_HAS_MOUSE_GRAB

	.warn	@private

	jz	genDismissInteraction	;skip if button not pressed...

	;ignore this LOST_GADGET event, since the button will shortly
	;open this menu again.

	ret

genDismissInteraction:
	;if this menu is not PINNED, will send MSG_GEN_GUP_INTERACTION_COMMAND
	;with IC_DISMISS to self.

	;If using cascading menus, call OLMenuWinCloseOrCascade which will
	;take care of checking if this menu is currently cascading.
if	 _CASCADING_MENUS
	call	OLMenuWinCloseOrCascade		;destroys:ax,bx,cx,dx,bp,di
else	;_CASCADING_MENUS is FALSE
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	ObjCallInstanceNoLock
endif	;_CASCADING_MENUS

	ret
OLMenuWinLostGadgetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuMarkForCloseOneLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	used to close last menu in cascading set

CALLED BY:	MSG_OL_MENU_MARK_FOR_CLOSE_ONE_LEVEL
PASS:		*ds:si	= OLMenuWinClass object
		ds:di	= OLMenuWinClass instance data
		ds:bx	= OLMenuWinClass object (same as *ds:si)
		es 	= segment of OLMenuWinClass
		ax	= message #
RETURN:
DESTROYED:
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinGupSubmenuRequestsClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the OMWMSS_IGNORE_SUBMENU_CLOSE_REQUEST flag.
		If the flag is true, then the flag is cleared, and the
		method returns.  If the flag is false, then this menu
		is closed, and the message is sent to the Gen parent
		if the parent's vis part is an OLMenuWinClass.

CALLED BY:	MSG_MO_MW_GUP_SUBMENU_REQUESTS_CLOSE
PASS:		*ds:si	= OLMenuWinClass object
		ds:di	= OLMenuWinClass instance data
		ds:bx	= OLMenuWinClass object (same as *ds:si)
		es 	= segment of OLMenuWinClass
		ax	= message #

RETURN:		Nothing
DESTROYED:	ax
SIDE EFFECTS:	None.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuWinGupSubmenuRequestsClose	method dynamic OLMenuWinClass,
					MSG_MO_MW_GUP_SUBMENU_REQUESTS_CLOSE

	; check this before saving the passed args since it would be a waste
	; of time if the jump was followed.

	test	ds:[di].OLMWI_moreSpecState, \
			mask OMWMSS_IGNORE_SUBMENU_CLOSE_REQUEST
	jnz	done

	push	cx, dx, bp			; save args

	; ensure cascade data is consistent
EC <	call	OLMenuWinECCheckCascadeData				>

	; since this menu is going down, disable the cascading bit.
	test	ds:[di].OLMWI_moreSpecState, mask OMWMSS_IS_CASCADING
	jz	notCascading

	andnf	ds:[di].OLMWI_moreSpecState, not (mask OMWMSS_IS_CASCADING)

	; Delete the cascaded var data
	mov	ax, ATTR_OL_MENU_WIN_CASCADED_MENU
	call	ObjVarDeleteData
EC <	ERROR_C	OL_ERROR			; no var data-inconsistent >


notCascading:
	; prevent this message from being resent by lost_gadget_excl handler.
	ornf	ds:[di].OLMWI_moreSpecState, mask OMWMSS_DONT_SEND_REQUEST

	; close this menu
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	ObjCallInstanceNoLock

	call	OLMenuWinSendCloseRequest	; Destroys ax, bx, cx, dx, bp

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

donePop::
	pop	cx, dx, bp			; restore args

	; ONLY JUMP HERE FROM BEFORE PUSHING THE ARGS
done:
	; the ignore is only valid for one request at a time.  also,
	; allow this request to be sent again.
	andnf	ds:[di].OLMWI_moreSpecState, \
			not (mask OMWMSS_IGNORE_SUBMENU_CLOSE_REQUEST or \
			     mask OMWMSS_DONT_SEND_REQUEST)
	ret
OLMenuWinGupSubmenuRequestsClose	endm
endif	;_CASCADING_MENUS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinCloseOrCascade
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the current menu and sends the submenu close request
		message to the parent if the current menu is not cascading.

CALLED BY:	OLMenuWinLostGadgetExcl, OLMenuWinPostPassiveButton
PASS:		*ds:si	= menu object

RETURN:		None.
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuWinCloseOrCascade	proc	far
	class	OLMenuWinClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	ds:[di].OLMWI_moreSpecState, mask OMWMSS_IS_CASCADING
	jnz	done				; menu is cascading..
						; don't close

	; be sure to always clear this flag if the menu is going down
	andnf	ds:[di].OLMWI_moreSpecState, \
			not mask OMWMSS_IGNORE_SUBMENU_CLOSE_REQUEST

	; prevent close request from being resent by lost_gadget_excl handler.
	mov	bl, ds:[di].OLMWI_moreSpecState	; store original state for later
	ornf	ds:[di].OLMWI_moreSpecState, mask OMWMSS_DONT_SEND_REQUEST

	; close this menu
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	ObjCallInstanceNoLock

	; okay, send the request.  restore the flag first.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLMWI_moreSpecState, not mask OMWMSS_DONT_SEND_REQUEST

	; told not to send request.. skip to end.
	test	bl, mask OMWMSS_DONT_SEND_REQUEST
	jnz	done

	; send close request to menu parents, if they exists.
	call	OLMenuWinSendCloseRequest	; destroys: ax,bx,cx,dx,bp

done:
	.leave
	ret
OLMenuWinCloseOrCascade	endp
endif	;_CASCADING_MENUS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinSendCloseRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up the generic tree to find an object of class
		OLMenuWinClass.  The search is continued until an
		object that is not a subclass of GenInteractionClass is
		found.  If it finds the menu window, the message
		MSG_MO_MW_GUP_SUBMENU_REQUESTS_CLOSE is sent.
		The menu window object's vis part MUST already be built.

CALLED BY:	OLMenuWinCloseOrCascade and OLMenuWinGupSubmenuRequestClose
PASS:		*ds:si	= menu object
RETURN:		*ds:si = current menu object.  (ds is fixed up).
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuWinSendCloseRequest	proc	near
	uses	si, es
	.enter

	mov	bx, ds:[LMBH_handle]
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLPWI_button	; ^lbx:si = menu button
	tst	si
	jz	done

searchLoop:
	mov	ax, MSG_VIS_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jcxz	done

	movdw	bxsi, cxdx			; ^lbx:si = parent
	call	ObjSwapLock

	segmov	es, <segment GenInteractionClass>, di
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	jnc	unlock				; break out of loop

	segmov	es, <segment OLMenuWinClass>, di
	mov	di, offset OLMenuWinClass
	call	ObjIsObjectInClass
	cmc
	jc	unlock				; continue up tree

	mov	ax, MSG_MO_MW_GUP_SUBMENU_REQUESTS_CLOSE
	call	ObjCallInstanceNoLock		; Destroys: ax
	clc
unlock:
	call	ObjSwapUnlock
	jc	searchLoop			; continue if carry set
done:
	.leave
	ret
OLMenuWinSendCloseRequest	endp
endif	;_CASCADING_MENUS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinSendCloseRequestToLastMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_MO_MW_GUP_SUBMENU_REQUESTS_CLOSE to the last
		menu of the currently cascaded menus.  May close all menus
		in the this chain of menus or may close only the menus BELOW
		the current menu depending upon the value of cx.

CALLED BY:
PASS:		*ds:si	= current menu object
		cx	= Preserve current menu and those above it
			  TRUE: Only close menus BELOW the current menu
			  FALSE: Close all menus in this chain

RETURN:		*ds:si = current menu object.  (ds is fixed up).
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuWinSendCloseRequestToLastMenu	proc	far
	.enter

	; Set ignore bit to preserve the current menu based upon cx.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; Assume we close all menus.
	andnf	ds:[di].OLMWI_moreSpecState, \
			not (mask OMWMSS_IGNORE_SUBMENU_CLOSE_REQUEST)
	jcxz	beginLoop

	; Nope, preserve current menu.
	ornf	ds:[di].OLMWI_moreSpecState, \
			mask OMWMSS_IGNORE_SUBMENU_CLOSE_REQUEST

beginLoop:
	; Add extra lock to original object to make loop work correctly.
	mov	bx, ds:[LMBH_handle]		; ^lbx = orig obj handle
	push	bx, si				; SAVE original object OPTR
	call	ObjLockObjBlock			; ax = segment
EC <	mov	dx, ds							>
EC <	cmp	ax, dx							>
EC <	ERROR_NE	OL_ERROR		; SHOULD BE EQUAL!	>

tryAgain:
	; *ds:si = current menu, locked

	; ensure cascade data consistency
EC <	call	OLMenuWinECCheckCascadeData				>

	; Ensure the object's vis part is built!
EC <	call	VisCheckVisAssumption					>

	; Check if the object is of class OLMenuWinClass
EC <	mov	cx, segment OLMenuWinClass				>
EC <	mov	dx, offset OLMenuWinClass				>
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				>
EC <	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp>
EC <	ERROR_NC	OL_ERROR		; NOT OLMenuWinClass !!	>

	; Is this the last child?
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMWI_moreSpecState, mask OMWMSS_IS_CASCADING
	jz	sendMessage			; Yes -- send message

	; No -- find next child in cascade.
	mov	ax, ATTR_OL_MENU_WIN_CASCADED_MENU
	call	ObjVarFindData			; if data, ds:bx = ptr
						; (ds still ptr to our block)
EC <	ERROR_NC	OL_ERROR		; no var data - that's bad >

	; Get optr from vardata of next child.
	mov	si, ds:[bx].offset
	mov	bx, ds:[bx].handle		; ^lbx:si = next child menu
	call	ObjLockObjBlock			; *ax:si = next child, locked

	mov	bx, ds:[LMBH_handle]		; ^lbx = parent menu handle
	call	MemUnlock			; unlock parent menu
	mov	ds, ax				; *ds:si = next child, locked

	; Continue looking for child
	jmp	tryAgain

sendMessage:
	; *ds:si = correct object to send message to, locked.
	mov	ax, MSG_MO_MW_GUP_SUBMENU_REQUESTS_CLOSE
	call	ObjCallInstanceNoLock

	; unlock last block
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	pop	bx, si				; ^lbx:si = original obj optr
	call	MemDerefDS			; fixup ds.. *ds:si = orig obj

	.leave
	ret
OLMenuWinSendCloseRequestToLastMenu	endp
endif	;_CASCADING_MENUS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinCloseAllMenusInCascade
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	All the menus in the cascade that the destination menu
		belongs to will be closed.  Basically just calls
		OLMenuWinSendCloseRquestToLastMenu.

CALLED BY:	MSG_MO_MW_CLOSE_ALL_MENUS_IN_CASCADE
PASS:		*ds:si	= OLMenuWinClass object
		ds:di	= OLMenuWinClass instance data
		ds:bx	= OLMenuWinClass object (same as *ds:si)
		es 	= segment of OLMenuWinClass
		ax	= message #

RETURN:		None
DESTROYED:	ax, cx, bp
SIDE EFFECTS:
	May close all menus in cascade!

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	6/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _CASCADING_MENUS
OLMenuWinCloseAllMenusInCascade	method dynamic OLMenuWinClass,
					MSG_MO_MW_CLOSE_ALL_MENUS_IN_CASCADE
	uses	dx
	.enter

	; send close request to last menu.  do not preserve the current menu.
	clr	cx
	call	OLMenuWinSendCloseRequestToLastMenu

	.leave
	ret
OLMenuWinCloseAllMenusInCascade	endm
endif	;_CASCADING_MENUS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up some flags used for cascading menus, calls superclass.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= OLMenuWinClass object
		ds:di	= OLMenuWinClass instance data
		ds:bx	= OLMenuWinClass object (same as *ds:si)
		es 	= segment of OLMenuWinClass
		ax	= message #
		bp	= 0 if top window, else window for obejct to open on

RETURN:		Nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	4/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLMenuWinVisOpen	method dynamic OLMenuWinClass,
					MSG_VIS_OPEN
	.enter

if	 _CASCADING_MENUS

	; ensure cascade data is consistent
EC <	call	OLMenuWinECCheckCascadeData				>

	; clear cascade var data, if any remaining.
	test	ds:[di].OLMWI_moreSpecState, mask OMWMSS_IS_CASCADING
	jz	notCascading

	; Delete the cascaded var data
	push	ax
	mov	ax, ATTR_OL_MENU_WIN_CASCADED_MENU
	call	ObjVarDeleteData
EC <	ERROR_C	OL_ERROR			; no var data-inconsistent >
	pop	ax

notCascading:
	; Clears all cascade state bits
	clr	ds:[di].OLMWI_moreSpecState

endif	;_CASCADING_MENUS

	; Call superclass
	mov	di, offset OLMenuWinClass
	call	ObjCallSuperNoLock

	; Update up/down scrollers as needed

	mov	al, 0
	call	OLMenuWinUpdateUpDownScrollers

	.leave
	ret
OLMenuWinVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuWinUpdateUpDownScrollers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update up/down scrollers for menu window

CALLED BY:	OLMenuWinVisOpen, OLMenuWinVisClose, OLMenuWinMoveResizeWin
PASS:		*ds:si	= OLMenuWinClass object
		al = non-zero to delay closing until END_SELECT
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/02/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MENU_WIN_SCROLL_DELTA	equ	23

OLMenuWinUpdateUpDownScrollers	proc	far
delayClose	local	word	push	ax	; only al used
scrollers	local	word	push	0	; assume no scrollers needed
upScroller	local	lptr	push	0	; assume no up scroller exists
downScroller	local	lptr	push	0	; assume no dn scroller exists
parent		local	Rectangle
parentWin	local	hptr
menu		local	Rectangle
menuWin		local	hptr
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter

	; not needed for pinned menus

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	LONG jnz	done

	; first figure out what needs to be updated

	call	VisQueryParentWin			; di = window handle
	tst	di
	jz	checkUpdate

	call	WinGetWinScreenBounds
	mov	ss:[parent].R_top, bx
	mov	ss:[parent].R_bottom, dx
	mov	ss:[parentWin], di

if TOOL_AREA_IS_TASK_BAR
	;
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	jz	doneTaskBar				; skip if no taskbar

	call	OLWinGetToolAreaSize			; dx = height
	test	ds:[taskBarPrefs], mask TBF_AUTO_HIDE
	jnz	doneTaskBar

	push 	ax
	mov	ax, ds:[taskBarPrefs]			; load taskBarPrefs in ax
	andnf	ax, mask TBF_POSITION			; mask out everything but the position bits
	cmp	ax, (TBP_TOP) shl offset TBF_POSITION	; compare position bits with TBP_TOP
	pop	ax					; restore ax
	jne	atBottom				; is not top => bottom position

	add	ss:[parent].R_top, dx
	jmp	short doneTaskBar
atBottom:
	sub	ss:[parent].R_bottom, dx
doneTaskBar:
	pop	ds
endif

	call	VisQueryWindow			; di = window handle
	tst	di
	jz	checkUpdate

	call	WinGetWinScreenBounds
	add	ax, 2
	sub	cx, 2
	mov	ss:[menu].R_left, ax
	mov	ss:[menu].R_top, bx
	mov	ss:[menu].R_right, cx
	mov	ss:[menu].R_bottom, dx
	mov	ss:[menuWin], di

	cmp	bx, ss:[parent].R_top
	jge	checkDown
	mov	ss:[scrollers].high, TRUE		; need up scroller
checkDown:
	cmp	dx, ss:[parent].R_bottom
	jle	checkUpdate
	mov	ss:[scrollers].low, TRUE		; need down scroller

	; now update the scrollers
checkUpdate:
	tst	ss:[scrollers]
	jnz	update

	mov	ax, TEMP_OL_MENU_WIN_SCROLLERS	; if no hint and no scrollers
	call	ObjVarFindData			; are needed, then we're done
	jnc	done

update:
	call	EnsureMenuWinUpDownScrollers

handleUpScroller:
	mov	si, ss:[upScroller]
	tst	ss:[scrollers].high
	call	openClose

	mov	si, ss:[downScroller]
	tst	ss:[scrollers].low
	call	openClose
done:
	.leave
	ret

openClose:
	jz	close
	call	OpenMenuWinScrollerWindow
	retn
close:
	call	CloseMenuWinScrollerWindow
	retn

OLMenuWinUpdateUpDownScrollers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureMenuWinUpDownScrollers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure up/down scroller objects exist

CALLED BY:	OLMenuWinUpdateUpDownScrollers
PASS:		*ds:si	= OLMenuWinClass object
		OLMenuWinUpdateUpDownScrollers stack frame
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,es
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/2/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureMenuWinUpDownScrollers	proc	near
	.enter	inherit OLMenuWinUpdateUpDownScrollers

	mov	ax, TEMP_OL_MENU_WIN_SCROLLERS
	call	ObjVarFindData
	jnc	createScrollers

	mov	ax, ds:[bx].MWSS_upScroller
	mov	ss:[upScroller], ax
	mov	ax, ds:[bx].MWSS_downScroller
	mov	ss:[downScroller], ax
	jmp	done

createScrollers:
	mov	ax, MENU_WIN_SCROLL_DELTA
	mov	dx, offset menuWinScrollerUpBitmap
	call	createScroller
	mov	ss:[upScroller], ax

	mov	ax, -MENU_WIN_SCROLL_DELTA
	mov	dx, offset menuWinScrollerDownBitmap
	call	createScroller
	mov	ss:[downScroller], ax

	mov	ax, TEMP_OL_MENU_WIN_SCROLLERS
	mov	cx, size MenuWinScrollerStruct
	call	ObjVarAddData

	mov	ax, ss:[upScroller]
	mov	ds:[bx].MWSS_upScroller, ax
	mov	ax, ss:[downScroller]
	mov	ds:[bx].MWSS_downScroller, ax
done:
	.leave
	ret

createScroller:
	push	si
	segmov	es, <segment MenuWinScrollerClass>
	mov	di, offset MenuWinScrollerClass
	mov	bx, ds:[LMBH_handle]
	call	GenInstantiateIgnoreDirty
	mov	di, ds:[si]
	mov	ds:[di].MWSI_delta, ax
	mov	ds:[di].MWSI_bitmap, dx
	mov	ax, si
	pop	si
	mov	ds:[di].MWSI_menu, si
	retn

EnsureMenuWinUpDownScrollers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenMenuWinScrollerWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open menu window up/down scroller

CALLED BY:	OLMenuWinUpdateUpDownScrollers
PASS:		*ds:si	= MenuWinScrollerClass object
		OLMenuWinUpdateUpDownScrollers stack frame
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/3/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenMenuWinScrollerWindow	proc	near
	.enter	inherit OLMenuWinUpdateUpDownScrollers

EC <	push	es, di							>
EC <	segmov	es, <segment MenuWinScrollerClass>			>
EC <	mov	di, offset MenuWinScrollerClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC OL_ERROR		; not a MenuWinScroller		>
EC <	pop	es, di							>

	mov	di, ds:[si]
	tst	ds:[di].MWSI_window
	jnz	done

if (0)
	push	si, bp
	mov	bx, si
	mov	di, ss:[menuWin]
	mov	si, WIT_LAYER_ID
	call	WinGetInfo
	mov	si, bx
	push	ax			; layer ID to use
	call	GeodeGetProcessHandle	; Get owner for window
	push	bx			; owner to use
	push	ss:[parentWin]		; parent window handle
	push	0			; window region segment
	push	0			; window region offset
	mov	bx, ss:[parent].R_top
	mov	dx, bx
	add	dx, MENU_WIN_SCROLL_DELTA
	mov	di, ds:[si]
	tst	ds:[di].MWSI_delta
	jg	gotBounds
	mov	dx, ss:[parent].R_bottom
	mov	bx, dx
	sub	bx, MENU_WIN_SCROLL_DELTA
gotBounds:
	push	dx			; window bottom
	push	ss:[menu].R_right	; window right
	push	bx			; window top
	push	ss:[menu].R_left	; window left
	mov	di, ss:[menuWin]	; ^hdi = menu Window
	mov	bp, si			; *ds:bp = expose OD
	mov	si, WIT_PRIORITY
	call	WinGetInfo		; al = WinPriorityData
	clr	ah			; ax = WinPassFlags
	push	ax			; save WinPassFlags
	mov	si, WIT_COLOR
	call	WinGetInfo		; ax,bx = color
	pop	si			; si = WinPassFlags
	mov	di, ds:[LMBH_handle]	; ^ldi:bp = expose OD
	movdw	cxdx, dibp		; ^lcx:dx = mouse OD
	call	WinOpen
	pop	si, bp
else
	mov	ax, ss:[parent].R_top
	mov	cx, ax
	add	cx, MENU_WIN_SCROLL_DELTA
	tst	ds:[di].MWSI_delta
	jg	createWindow
	mov	cx, ss:[parent].R_bottom
	mov	ax, cx
	sub	ax, MENU_WIN_SCROLL_DELTA

createWindow:
	push	si, bp
	call	GeodeGetProcessHandle	; Get owner for window
	push	bx			; layer ID to use
	push	bx			; owner to use
	push	ss:[parentWin]		; parent window handle
	push	0			; window region segment
	push	0			; window region offset
	push	cx			; window bottom
	mov	ss:[menu].R_bottom, cx	; store for later
	push	ss:[menu].R_right	; window right
	push	ax			; window top
	mov	ss:[menu].R_top, ax	; store for later
	push	ss:[menu].R_left	; window left
	mov	di, ss:[menuWin]	; ^hdi = menu Window
	mov	bp, si			; *ds:bp = expose OD
	mov	si, WIT_PRIORITY
	call	WinGetInfo		; al = WinPriorityData
	clr	ah			; ax = WinPassFlags
	push	ax			; save WinPassFlags
	mov	si, WIT_COLOR
	call	WinGetInfo		; ax,bx = color
	pop	si			; si = WinPassFlags
	mov	di, ds:[LMBH_handle]	; ^ldi:bp = expose OD
	movdw	cxdx, dibp		; ^lcx:dx = mouse OD
	call	WinOpen
	pop	si, bp
endif

	mov	di, ds:[si]
	mov	ds:[di].MWSI_window, bx
	mov	ax, ss:[menu].R_top
	mov	ds:[di].MWSI_top, ax
	mov	ax, ss:[menu].R_bottom
	mov	ds:[di].MWSI_bottom, ax
done:
	.leave
	ret
OpenMenuWinScrollerWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseMenuWinScrollerWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close menu window up/down scroller

CALLED BY:	INTERNAL
PASS:		*ds:si	= MenuWinScrollerClass
RETURN:		nothing
DESTROYED:	ax,di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/3/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseMenuWinScrollerWindow	proc	near
	.enter	inherit OLMenuWinUpdateUpDownScrollers

EC <	push	es, di							>
EC <	segmov	es, <segment MenuWinScrollerClass>			>
EC <	mov	di, offset MenuWinScrollerClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC OL_ERROR		; not a MenuWinScroller		>
EC <	pop	es, di							>

	tst	ss:[delayClose].low
	jnz	done

	clr	ax
	mov	di, ds:[si]
	xchg	ax, ds:[di].MWSI_window
	tst	ax
	jz	done

	mov	di, ax
	call	WinClose		; close the MenuWinScroller window
done:
	.leave
	ret
CloseMenuWinScrollerWindow	endp

WinMethods	ends

LessUsedGeometry	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinUpdateGeometry --
		MSG_VIS_UPDATE_GEOMETRY for OLMenuWinClass

DESCRIPTION:	Updates geometry.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_UPDATE_GEOMETRY

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/21/92		Initial Version

------------------------------------------------------------------------------@

OLMenuWinUpdateGeometry	method dynamic	OLMenuWinClass, MSG_VIS_UPDATE_GEOMETRY
	push	ax, es
	test	ds:[di].VI_optFlags, mask VOF_GEO_UPDATE_PATH or \
				     mask VOF_GEOMETRY_INVALID
	jz	callSuper

	call	OLMenuCalcCenters
	jnc	callSuper		  ;nothing to do, branch

	test	bp, mask SGMCF_NEED_TO_RESET_GEO  ;any item have valid geometry?
	jz	callSuper		  ;no, no need to reset stuff.
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
	call	ObjCallInstanceNoLock

callSuper:
	pop	ax, es
	mov	di, offset OLMenuWinClass
	CallSuper	MSG_VIS_UPDATE_GEOMETRY
	ret
OLMenuWinUpdateGeometry	endm






COMMENT @----------------------------------------------------------------------

ROUTINE:	OLMenuCalcCenters

SYNOPSIS:	Calculates left and right portions of a menu.

CALLED BY:	OLMenuWinUpdateGeometry, OLMenuWinResetSizeToStayOnscreen

PASS:		*ds:si -- menu

RETURN:		carry set if values changed
		bp -- SpecGetMenuCenterFlags

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 4/93		Initial version

------------------------------------------------------------------------------@

OLMenuCalcCenters	proc	near
	;
	; Before we do geometry, we'll go through all the child menu items and
	; determinate who is the biggest one.    (We'll make two passes if the
	; first pass yields an object allowing wrapping, so that all the
	; children can clear their optimization bits and set expand-width-to-fit
	; bits correctly. -cbh 1/18/93)
	;
	; If this is a pinned menu, we need the items to expand to fit whatever
	; minimum width might be needed for the menu, so we'll set the ALLOWING_
	; WRAPPING flag now, which effectively turns off geometry optizations.
	; -cbh 2/12/93
	;
	clr	bp
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jz	5$
	or	bp, mask SGMCF_ALLOWING_WRAPPING
5$:
	call	GetMenuCenter
	test	bp, mask SGMCF_ALLOWING_WRAPPING
	jz	10$
	call	GetMenuCenter
10$:
	cmp	cx, ds:[di].OLMWI_monikerSpace
	jne	sizesChanged
	cmp	dx, ds:[di].OLMWI_accelSpace
	clc					;assume sizes not changing
	je	exit				;nope, exit

sizesChanged:
	;
	; If the menu item sizes changed, we'll store the new values and
	; reset the geometry of all the objects in the window, so the menus
	; will get their sizes recalculated.  (We could also do this via
	; VGA_ALWAYS_RECALC_SIZE in the buttons, but this will be more efficient
	; for most situations.)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLMWI_monikerSpace, cx
	mov	ds:[di].OLMWI_accelSpace, dx
	stc
exit:
	ret
OLMenuCalcCenters	endp


GetMenuCenter	proc	near
	clr	cx			;moniker space
	mov	dx, cx			;accelerator space
	mov	ax, MSG_SPEC_GET_MENU_CENTER
	call	ObjCallInstanceNoLock
	ret
GetMenuCenter	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinConvertDesiredSizeHint --
		MSG_SPEC_CONVERT_DESIRED_SIZE_HINT for OLMenuWinClass

DESCRIPTION:	Converts desired size for this object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
		cx	- SpecSizeSpec: width
		dx	- SpecSizeSpec: height
		bp	- number of childre

RETURN:		cx, dx  - converted size
		ax, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/20/92		Initial Version

------------------------------------------------------------------------------@

OLMenuWinConvertDesiredSizeHint	method dynamic	OLMenuWinClass, \
				MSG_SPEC_CONVERT_DESIRED_SIZE_HINT

	;
	; Hack to get the buttons of popup lists to get correct desired size
	; calculations (it derives its hint from this object).
	; (Changed 11/11/92 cbh to do the conversion at the button.)
	;
	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_IS_POPUP_LIST shl offset OLBF_TARGET
	je	isPopupList

callSuper:
	mov	di, offset OLMenuWinClass
	GOTO	ObjCallSuperNoLock		;do normal OLCtrl stuff

isPopupList:
	mov	di, ds:[di].OLPWI_button
	tst	di
	jz	callSuper			;no button, call superclass
						; (why, I don't know.)
	mov	si, di
	call	ObjCallInstanceNoLock		;send to the button
if not SELECTION_BOX
 	tst	cx				;no width hint, exit
	jz	exit
	add	cx, OL_DOWN_MARK_WIDTH + OL_MARK_SPACING
endif
exit::						;add width of arrow plus margin
	ret

OLMenuWinConvertDesiredSizeHint	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuWinResetSizeToStayOnscreen --
		MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN for OLMenuWinClass

DESCRIPTION:	Resets size to keep itself onscreen.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN
		dl	- VisUpdateMode

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 4/93		Initial Version

------------------------------------------------------------------------------@

OLMenuWinResetSizeToStayOnscreen	method dynamic	OLMenuWinClass, \
				MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN

	;
	; Wrap the puppy if it doesn't fit, and hope for the best. -2/ 5/93
	; (Not working yet.  -cbh 2/ 6/93)
	;
;	or	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP

	mov	di, offset OLMenuWinClass
	call	ObjCallSuperNoLock

	call	OLMenuCalcCenters		; this needs to be redone now,
						; mainly so that the ONE_PASS
						; OPTIMIZATION flag is cleared.
	ret

OLMenuWinResetSizeToStayOnscreen	endm



LessUsedGeometry	ends


WinMethods	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MenuWinScrollerStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start select on scroller

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= MenuWinScrollerClass object
		ds:di	= MenuWinScrollerClass instance data
		ds:bx	= MenuWinScrollerClass object (same as *ds:si)
		es 	= segment of MenuWinScrollerClass
		ax	= message #
		cx	= X position of mouse
		dx	= X position of mouse
		bp low	= ButtonInfo		(In input.def)
		bp high	= UIFunctionsActive	(In Objects/uiInputC.def)
RETURN:		ax	= MouseReturnFlags	(In Objects/uiInputC.def)
DESTROYED:	bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/03/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MenuWinScrollerStartSelect	method dynamic MenuWinScrollerClass,
					MSG_META_START_SELECT
MenuWinScrollerScroll	label	far
	push	si
	call	MenuWinScrollerScrollOnly

	call	ImGetButtonState
	call	OLMenuWinUpdateUpDownScrollers
	pop	si

	call	MenuWinScrollerStartTimer

	mov	ax, mask MRF_PROCESSED
	ret
MenuWinScrollerStartSelect	endm

;
; returns: C set if actually scrolled
;
MenuWinScrollerScrollOnly	proc	near
	mov	di, ds:[si]
	mov	bp, ds:[di].MWSI_delta
	mov	si, ds:[di].MWSI_menu
	;
	; check if already at top or bottom
	;
	call	VisQueryParentWin			; di = window handle
	tst	di
	jz	update
	call	WinGetWinScreenBounds

if TOOL_AREA_IS_TASK_BAR
	;
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds
	jz	endIfTaskbar				; skip if no taskbar
							; bx = top, dx = bottom
	mov	ax, dx					; ax = bottom
	call	OLWinGetToolAreaSize			; cx = width, dx = height

	push	ds
	segmov	ds, dgroup
	test	ds:[taskBarPrefs], mask TBF_AUTO_HIDE
	jnz	doneTaskBar

	push 	ax
	mov	ax, ds:[taskBarPrefs]			; load taskBarPrefs in ax
	andnf	ax, mask TBF_POSITION			; mask out everything but the position bits
	cmp	ax, (TBP_TOP) shl offset TBF_POSITION	; compare position bits with TBP_TOP
	pop	ax					; restore ax
	jne	atBottom				; is not top => bottom position

	add	bx, dx
	jmp	short doneTaskBar
atBottom:
	sub	ax, dx
doneTaskBar:
	pop	ds
	push	bx, ax					; save top, bottom
endIfTaskbar:
else
	push	bx, dx					; save top, bottom
endif

	call	VisQueryWindow				; di = window handle
	tst	di
	jz	update
	call	WinGetWinScreenBounds
	pop	ax, cx					; ax = scrn top, cx = scrn bot
	tst	bp
	jns	scrollDown
	cmp	dx, cx
	jle	update
	jmp	short moveIt

scrollDown:
	cmp	bx, ax
	jge	update
moveIt:
	call	VisGetBounds

	mov	cx, ax
	mov	dx, bx
	add	dx, bp
	call	VisSetPosition

	mov	ax, MSG_VIS_MOVE_RESIZE_WIN
	mov	di, offset OLWinClass
	call	ObjCallSuperNoLock
	stc
	jmp	short exit

update:
	clc
exit:
	ret
MenuWinScrollerScrollOnly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MenuWinScrollerEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end select on scroller

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si	= MenuWinScrollerClass object
		ds:di	= MenuWinScrollerClass instance data
		ds:bx	= MenuWinScrollerClass object (same as *ds:si)
		es 	= segment of MenuWinScrollerClass
		ax	= message #
		cx	= X position of mouse
		dx	= X position of mouse
		bp low	= ButtonInfo		(In input.def)
		bp high	= UIFunctionsActive	(In Objects/uiInputC.def)
RETURN:		ax	= MouseReturnFlags	(In Objects/uiInputC.def)
DESTROYED:	bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/03/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MenuWinScrollerEndSelect	method dynamic MenuWinScrollerClass,
					MSG_META_END_SELECT, MSG_META_END_OTHER
	call	MenuWinScrollerStopTimer
	;
	; update pending close
	;
	mov	di, ds:[si]
	mov	si, ds:[di].MWSI_menu
	mov	al, 0
	call	OLMenuWinUpdateUpDownScrollers
	mov	ax, mask MRF_PROCESSED
	ret
MenuWinScrollerEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MenuWinScrollerRawUnivEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse pointer entered scroller window

CALLED BY:	MSG_META_RAW_UNIV_ENTER

PASS:		*ds:si	= MenuWinScrollerClass object
		ds:di	= MenuWinScrollerClass instance data
		ds:bx	= MenuWinScrollerClass object (same as *ds:si)
		es 	= segment of MenuWinScrollerClass
		ax	= message #
		^lcx:dx	= InputObj of window method refers to
		^hbp	= Window that method refers to
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/03/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MenuWinScrollerRawUnivEnter	method dynamic MenuWinScrollerClass,
					MSG_META_RAW_UNIV_ENTER
	mov	di, offset MenuWinScrollerClass
	call	ObjCallSuperNoLock

	call	ImGetButtonState
	test	al, mask BI_B0_DOWN
	jz	done

MenuWinScrollerStartTimer	label	far
	push	ds
	segmov	ds, <segment idata>
	mov	cx, ds:[olGadgetRepeatDelay]
	pop	ds

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[LMBH_handle]
	mov	dx, MSG_MENU_WIN_SCROLLER_TIMER_EXPIRED
	call	TimerStart

	mov	di, ds:[si]
	mov	ds:[di].MWSI_timerID, ax
	mov	ds:[di].MWSI_timerHandle, bx
done:
	ret
MenuWinScrollerRawUnivEnter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MenuWinScrollerRawUnivLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse pointer left scroller window

CALLED BY:	MSG_META_RAW_UNIV_LEAVE

PASS:		*ds:si	= MenuWinScrollerClass object
		ds:di	= MenuWinScrollerClass instance data
		ds:bx	= MenuWinScrollerClass object (same as *ds:si)
		es 	= segment of MenuWinScrollerClass
		ax	= message #
		^lcx:dx	= InputObj of window method refers to
		^hbp	= Window that method refers to
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/03/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MenuWinScrollerRawUnivLeave	method dynamic MenuWinScrollerClass,
					MSG_META_RAW_UNIV_LEAVE
	mov	di, offset MenuWinScrollerClass
	call	ObjCallSuperNoLock

MenuWinScrollerStopTimer	label	far
	clr	ax, bx
	mov	di, ds:[si]
	xchg	ax, ds:[di].MWSI_timerID
	xchg	bx, ds:[di].MWSI_timerHandle
	tst	bx
	jz	done

	call	TimerStop
done:
	;
	; update pending close
	;
	mov	di, ds:[si]
	push	si
	mov	si, ds:[di].MWSI_menu
	mov	al, 0
	call	OLMenuWinUpdateUpDownScrollers
	pop	si
	ret
MenuWinScrollerRawUnivLeave	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MenuWinScrollerTimerExpired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle timer expired

CALLED BY:	MSG_MENU_WIN_SCROLLER_TIMER_EXPIRED

PASS:		*ds:si	= MenuWinScrollerClass object
		ds:di	= MenuWinScrollerClass instance data
		ds:bx	= MenuWinScrollerClass object (same as *ds:si)
		es 	= segment of MenuWinScrollerClass
		ax	= message #
RETURN:
DESTROYED:
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/03/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MenuWinScrollerTimerExpired	method dynamic MenuWinScrollerClass,
					MSG_MENU_WIN_SCROLLER_TIMER_EXPIRED
	clr	ax, bx
	xchg	ax, ds:[di].MWSI_timerID
	xchg	bx, ds:[di].MWSI_timerHandle
	cmp	ax, bp
	jne	done
	tst	bx
	jz	done

	call	ImGetButtonState
	test	al, mask BI_B0_DOWN
	jz	done

	call	MenuWinScrollerScroll
	call	MenuWinScrollerStartTimer
done:
	ret
MenuWinScrollerTimerExpired	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MenuWinScrollerExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw

CALLED BY:	MSG_META_EXPOSED

PASS:		*ds:si	= MenuWinScrollerClass object
		ds:di	= MenuWinScrollerClass instance data
		ds:bx	= MenuWinScrollerClass object (same as *ds:si)
		es 	= segment of MenuWinScrollerClass
		ax	= message #
		^hcx	= Window
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	3/03/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MenuWinScrollerExposed	method dynamic MenuWinScrollerClass,
					MSG_META_EXPOSED
	mov	di, cx
	call	GrCreateState
	call	GrBeginUpdate

	call	GrGetWinBounds
	sub	cx, ax
	sub	cx, 7
	shr	cx, 1
	mov	ax, cx
	sub	dx, bx
	sub	dx, 4
	shr	dx, 1
	mov	bx, dx

	mov	si, ds:[si]
	mov	si, ds:[si].MWSI_bitmap
	segmov	ds, cs
	clr	dx
	call	GrFillBitmap

	call	GrEndUpdate
	call	GrDestroyState
	ret
MenuWinScrollerExposed	endm

menuWinScrollerUpBitmap Bitmap <7, 4, 0, BMF_MONO>
	db	00010000b
	db	00111000b
	db	01111100b
	db	11111110b

menuWinScrollerDownBitmap Bitmap <7, 4, 0, BMF_MONO>
	db	11111110b
	db	01111100b
	db	00111000b
	db	00010000b

;
; ensure keyboard navigation item remains on-screen
;
OLMenuWinNavigate	method	dynamic	OLMenuWinClass, MSG_SPEC_NAVIGATE_TO_NEXT_FIELD, MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD, MSG_OL_MENU_WIN_UPDATE_SCROLLABLE_MENU
		cmp	ax, MSG_OL_MENU_WIN_UPDATE_SCROLLABLE_MENU
		je	checkAgain
		mov	di, offset OLMenuWinClass
		call	ObjCallSuperNoLock
checkAgain:
		mov	ax, TEMP_OL_MENU_WIN_SCROLLERS
		call	ObjVarFindData
		jnc	done			; no scrollers
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	ax, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
		tst	ax
		jz	done			; no focus
		mov	si, ds:[di].VCI_window
		tst	si
		jz	done			; no menu window
		push	bx			; save vardata
		push	si			; save window
		mov	bx, ax
		mov	si, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
		mov	ax, MSG_VIS_GET_BOUNDS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; bp = top, dx = bottom
		pop	di			; di = window
		mov	bx, bp
		call	WinTransform
		push	ax, bx
		movdw	axbx, cxdx
		call	WinTransform
		movdw	cxdx, axbx		; dx = bottom (scr)
		pop	bx, ax			; ax = top (scr)
		pop	bx			; ds:bx = vardata
		mov	si, ds:[bx].MWSS_upScroller
		mov	di, ds:[si]
		tst	ds:[di].MWSI_window
		jz	doneUp
		cmp	ax, ds:[di].MWSI_bottom
		jge	doneUp
scrollMenu:
		push	si			; save scroller
		call	MenuWinScrollerScrollOnly	; *ds:si = menu win
		pushf				; save scroll result
		clr	al			; update immediately
		call	OLMenuWinUpdateUpDownScrollers
		popf				; C set if scrolled
		pop	si			; *ds:si = scroller
		jnc	done			; no scroll, done
		mov	di, ds:[si]
		mov	si, ds:[di].MWSI_menu
		jmp	checkAgain

doneUp:
		mov	si, ds:[bx].MWSS_downScroller
		mov	di, ds:[si]
		tst	ds:[di].MWSI_window
		jz	done
		cmp	dx, ds:[di].MWSI_top
		jg	scrollMenu
done:
		ret
OLMenuWinNavigate	endm

WinMethods	ends
