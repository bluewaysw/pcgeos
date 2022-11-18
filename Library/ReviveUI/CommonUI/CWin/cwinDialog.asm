COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/CWin
FILE:		cwinDialog.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB NukeKbdObj              Nukes the kbd object, if one was created.

    MTD MSG_META_INITIALIZE     Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT OLDialogAlignInitNotPinned 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT OLDialogAlignMakeResizable 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT OLDialogAlignMaximizable 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogWinSingleUsage 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogWinFrequentUsage 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogWinComplexProperties 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogWinSimpleProperties 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogWinDelayedMode 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogWinImmediateMode 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT DialogWinAndInOptFlags  Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT DialogWinOrInOptFlags   Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogWinNoDisturb  Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    INT HintDialogDefaultActionIsNavigateToNextField 
				Add on to initialize routine for
				OLPopupWinClass & saves the properties
				window hints (if any) for later evaluating
				in determining which of the standard
				triggers to create at the bottom of the
				window, after the interaction & all its
				children have been built.

    MTD MSG_SPEC_SCAN_GEOMETRY_HINTS 
				Scans for geometry hints.

    MTD MSG_SPEC_BUILD_BRANCH   Add on to super classes method & construct
				standard triggers at the bottom of the
				window, after the interaction & all its
				children have been built.

    MTD MSG_SPEC_BUILD          Add on to super classes method & build
				OLGadgetArea.

    MTD MSG_VIS_RECALC_SIZE     Recalc's size.

    MTD MSG_OL_WIN_MAXIMIZE

    MTD MSG_OL_RESTORE_WIN

    INT HandleDialogResponses   Creates a GenInteraction w/triggers inside
				of it, with the correct buttons inside for
				the user to respond to this inteaction
				with.

    INT RemoveReplyBarIfPossible 
				If running on a small screen, remove reply
				bar if all we have is a IC_DISMISS trigger
				and the dialog is OWA_CLOSABLE, meaning
				we'll be providing an alternate close
				button

    INT EnsureStandardTriggerMonikers 
				Go through all the standard triggers
				(either created here or supplied by the
				application) and create monikers for them
				if they don't have one yet.  This requires
				the standard trigger list to be up to date.
				We also sneak in some work to esnure that
				APPLY and RESET triggers are disabled, as
				they aren't enabled until some property is
				changed by the user.

    INT EnsureStandardTriggerMonikerCallback 
				Callback routine for
				EnsureStandardTriggerMonikers.

    INT AddPositionHint         Add position hint.

    INT CheckIfNotification     Check if button is in a GIT_NOTIFICATION
				interaction

    INT CheckDismissCloseCancel This routine checks if we should use
				"Close" moniker or "Cancel" moniker for an
				IC_DISMISS trigger.  "Cancel" will be used
				if the dialog is modal.  "Close" if
				non-modal.

    INT EnsureReplyBar          Make sure reply bar exists for
				GenInteraction.

    INT AddStandardTriggerIfNeeded 
				Creates and add standard GenInteraction
				trigger to reply bar, if standard trigger
				doesn't already exist (i.e. provided by the
				application).

    MTD MSG_VIS_ADD_CHILD       We intercept this to ensure that our reply
				bar is always at the end.

    MTD MSG_OL_WIN_NOTIFY_OF_INTERACTION_COMMAND 
				notification of IC trigger

    MTD MSG_OL_DIALOG_WIN_REBUILD_STANDARD_TRIGGERS 
				rebuild standard triggers because reply is
				being rebuilt

    MTD MSG_OL_DIALOG_WIN_RAISE_TAB 
				Raise tab

    MTD MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD 
				We intercept this here to deal with
				OLGadgetArea.

    MTD MSG_GEN_INTERACTION_TEST_INPUT_RESTRICTABILITY

    MTD MSG_SPEC_GET_VIS_PARENT We intercept this here to see if we should
				deal with
				ATTR_GEN_INTERACTION_ON_TOP_OF_APPLICATION,
				ATTR_GEN_INTERACTION_ON_TOP_OF_FIELD, or
				ATTR_GEN_INTERACTION_ON_TOP_OF_SCREEN.

    INT SaveStandardTriggerInfo Save information about this standard
				trigger in our standard trigger list.

    INT RemoveStandardTriggerInfo 
				Remove information about this standard
				trigger in our standard trigger list.

    INT FindStandardTriggerInfo Find information about this standard
				trigger in our standard trigger list.

    INT FindStandardTriggerInfo Find information about this standard
				trigger in our standard trigger list.

    INT FindStandardTriggerEntry 
				Find information about this standard
				trigger in our standard trigger list.

    INT FindStandardTriggerCallback 
				Find information about this standard
				trigger in our standard trigger list.

    MTD MSG_OL_DIALOG_WIN_FIND_STANDARD_TRIGGER 
				Find standard trigger

    GLB CreateKeyboardObject    Creates a keyboard object for the dialog

    GLB EnsureBottomArea        Creates a "bottom area" for the dialog (an
				area below the reply bar that holds goodies
				like pen-input controllers).

    MTD MSG_SPEC_GUP_QUERY      We intercept generic-upward queries here to
				see if we can answer them.

    MTD MSG_OL_WIN_NOTIFY_OF_REPLY_BAR

    MTD MSG_SPEC_UNBUILD        Remove the reply bar, if we created it;
				remove any standard triggers we created;
				free standard trigger list

    INT UnbuildTriggers         remove any standard triggers we created

    INT FreeStandardTriggerMonikerCallback 
				remove any standard triggers we created

    MTD MSG_SPEC_NOTIFY_ENABLED Handle enabling and disabling

    MTD MSG_SPEC_NOTIFY_NOT_ENABLED 
				Handle enabling and disabling

    INT OLDWNotifyCommon        Handle enabling and disabling

    MTD MSG_GEN_APPLY           Handle applying properties.

    INT HandleBubbleApply       Special apply handling for bubbles
				(GIV_POPUPs)

    INT ActivateBubbleFocus     Activates the window focus.

    MTD MSG_GEN_RESET           Handle resetting properties.

    MTD MSG_GEN_GUP_INTERACTION_COMMAND 
				Handle the various InteractionCommands.

    MTD MSG_GEN_INTERACTION_ACTIVATE_COMMAND 
				Activate InteractionCommand standard
				trigger, if any.

    MTD MSG_OL_WIN_CLOSE        convert MSG_OL_WIN_CLOSE to activate an
				IC_DISMISS reply bar trigger

    MTD MSG_GEN_INTERACTION_INITIATE_NO_DISTURB 
				Initiate the dialog on-screen, behind other
				windows and without taking focus or target.

    MTD MSG_META_FUP_KBD_CHAR   This method is sent by child which 1) is
				the focused object and 2) has received a
				MSG_META_FUP_KBD_CHAR which is does not
				care about. Since we also don't care about
				the character, we forward this method up to
				the parent in the focus hierarchy.

				At this class level, the parent in the
				focus hierarchy is is the generic parent.

    MTD MSG_META_FUP_KBD_CHAR   This method is sent by child which 1) is
				the focused object and 2) has received a
				MSG_META_FUP_KBD_CHAR which is does not
				care about. Since we also don't care about
				the character, we forward this method up to
				the parent in the focus hierarchy.

				At this class level, the parent in the
				focus hierarchy is is the generic parent.

    MTD MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC 
				For dialogs with folder tabs: Check tabs to
				see if mnemonics match

    MTD MSG_META_MUP_ALTER_FTVMC_EXCL 
				Intercept change of focus within dialog to
				give UIApp and window the focus, as long as
				a child has the focus within the dialog.

    INT WinDialog_DerefVisSpec_DI 
				Returns whether the object allows express
				menu shortcuts.

    INT WinDialog_DerefGen_DI   Returns whether the object allows express
				menu shortcuts.

    INT WinDialog_ObjCallSuperNoLock_OLDialogWinClass 
				Returns whether the object allows express
				menu shortcuts.

    INT WinDialog_ObjCallInstanceNoLock 
				Returns whether the object allows express
				menu shortcuts.

    INT WinDialog_ObjMessageCallFixupDS 
				Returns whether the object allows express
				menu shortcuts.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

DESCRIPTION:

	$Id: cwinDialog.asm,v 1.151 97/03/06 02:40:42 brianc Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLDialogWinClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;---------------------------



AUTOMATICALLY_IMBED_KEYBOARD	equ	0
WinClasses segment resource

if	AUTOMATICALLY_IMBED_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinUpdateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If detaching, nukes the data

CALLED BY:	GLOBAL
PASS:		cx - UpdateWindowFlags
RETURN:		nada
DESTROYED:	ax, cx, dx, bp - by superclass
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDialogWinUpdateWindow		method OLDialogWinClass, 
					MSG_META_UPDATE_WINDOW

	test	cx, mask UWF_DETACHING
	jz	toSuper
	call	NukeKbdObj
toSuper:
	mov	di, offset OLDialogWinClass
	GOTO	ObjCallSuperNoLock
OLDialogWinUpdateWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeKbdObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes the kbd object, if one was created.

CALLED BY:	GLOBAL
PASS:		*ds:si - OLWinDialog object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeKbdObj	proc	near	uses	ax, bx, cx, dx, bp, di
	.enter
	mov	ax, ATTR_GEN_INTERACTION_PEN_MODE_KEYBOARD_OBJECT
	call	ObjVarFindData
	jnc	afterKbdObj
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLDWI_optFlags, mask OLDOF_KBD_CREATED
	jz	noCreatedKbd
	andnf	ds:[di].OLDWI_optFlags, not (mask OLDOF_KBD_CREATED or mask OLDOF_KBD_ADDED)

	push	si
	mov	si, ds:[bx].chunk
EC <	mov	ax, ds:[bx].handle					>
EC <	cmp	ax, ds:[LMBH_handle]					>
EC <	ERROR_NZ	-1						>
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	clr	bp
	call	WinClasses_ObjCallInstanceNoLock
	
	pop	si
	mov	ax, ATTR_GEN_INTERACTION_PEN_MODE_KEYBOARD_OBJECT
	call	ObjVarDeleteData
	jmp	afterKbdObj
noCreatedKbd:

;	Remove the user-provided keyboard object from the gen linkage, but
;	don't destroy it.

	test	ds:[di].OLDWI_optFlags, mask OLDOF_KBD_ADDED
	jz	afterKbdObj
	andnf	ds:[di].OLDWI_optFlags, not mask OLDOF_KBD_ADDED
	push	si
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, MSG_GEN_REMOVE
	mov	dl, VUM_NOW
	clr	bp
	call	WinClasses_ObjMessageCallFixupDS
	pop	si
afterKbdObj:
	.leave
	ret
NukeKbdObj	endp
endif	;AUTOMATICALLY_IMBED_KEYBOARD 

COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinInitialize
			-- MSG_META_INITIALIZE for OLDialogWinClass

DESCRIPTION:	Add on to initialize routine for OLPopupWinClass & saves the
		properties window hints (if any) for later evaluating in 
		determining which of the standard triggers to create
		at the bottom of the window, after the interaction & all its 
		children have been built.

PASS:
	*ds:si - instance data
	es - segment of OLDialogWinClass
	ax - MSG_META_INITIALIZE
	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@

OLDialogWinInitialize	method dynamic	OLDialogWinClass, MSG_META_INITIALIZE

	;Do super class (ctrl & win) INIT

	; This routine is used for OLDialogWinClass

	mov	di, offset OLDialogWinClass
	CallSuper	MSG_META_INITIALIZE

	call	WinClasses_DerefVisSpec_DI

if ALL_DIALOGS_ARE_MODAL
	;for keyboard only setups, force all dialogs to be modal
	call	OpenCheckIfKeyboardOnly	; carry set if so
	jnc	notKeyboardOnly
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
					mask OLPWF_SYS_MODAL
	jnz	notKeyboardOnly		; already modal
					; else, set modal and indicate that
					;	we did this
	ornf	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
					mask OLPWF_FORCED_MODAL
notKeyboardOnly:
endif

	;set fixed attribute: all popup windows DO NOT preserve the focus.
	; (In Rudy, all popup windows (bubbles) DO preserve focus.)
	;  
if _RUDY
	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_PRESERVE_FOCUS
else
	ANDNF	ds:[di].OLWI_fixedAttr, not (mask OWFA_PRESERVE_FOCUS)
endif

if _RUDY
	;
	; Keep separate flags around for visibility=popup and type=properties,
	; for the benefit of choosing standard trigger monikers later.
	; 
	call	WinClasses_DerefGen_DI
	cmp	ds:[di].GII_visibility, GIV_POPUP
	jne	notPopup

	call	WinClasses_DerefVisSpec_DI
	ORNF	ds:[di].OLPWI_flags, mask OLPWF_IS_POPUP
notPopup:
	call	WinClasses_DerefGen_DI
	cmp	ds:[di].GII_type, GIT_PROPERTIES
	jne	notProp

	call	WinClasses_DerefVisSpec_DI
	ORNF	ds:[di].OLPWI_flags, mask OLPWF_IS_PROPERTIES
notProp:
	call	WinClasses_DerefVisSpec_DI

endif

	;THEN, test to see if this is a modal window or not.

	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
						mask OLPWF_SYS_MODAL
	jnz	modalInit		;skip if modal...

	;init for non-modal window
					; & give basic base window attributes
CUAS <	ORNF	ds:[di].OLWI_attrs, MO_ATTRS_COMMAND_WINDOW		>
CUAS <	mov	ds:[di].OLWI_type, MOWT_COMMAND_WINDOW			>
ODIE <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_MOVABLE or mask OWA_THICK_LINE_BORDER) >

OLS <	ORNF	ds:[di].OLWI_attrs, mask OWA_HEADER or mask OWA_TITLED \
			or mask OWA_FOCUSABLE or mask OWA_MOVABLE \
			or mask OWA_PINNABLE or mask OWA_HAS_POPUP_MENU	>
OLS <	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_LONG_TERM		>
					; initialize as pinned

					; Store is command window
OLS <	mov	ds:[di].OLWI_type, OLWT_COMMAND_WINDOW			>


	call	OLDialogWinScanGeometryHints

	;Process alignment hints

	segmov	es, cs
	mov	di, offset cs:OLDialogAlignHintHandlers
	mov	ax, length (cs:OLDialogAlignHintHandlers)
	call	ObjVarScanData
	jmp	short afterInit

modalInit:

;
; Bleah, the previous set (in superclass) OWA_FOCUSABLE and OWA_TARGETABLE
; OLWI_attrs are trashed below.  Preserve them - brianc 6/18/93
;

					;give basic base window attributes
	and	ds:[di].OLWI_attrs, mask OWA_FOCUSABLE or mask OWA_TARGETABLE
	or	ds:[di].OLWI_attrs, mask OWA_THICK_LINE_BORDER \
				 or mask OWA_FOCUSABLE

if _MOTIF ;--------------------------------------------------------------------

	;Motif modal dialogs have titlebars, sysmenus, and are movable.
	;(But no system menu! -cbh 12/15/92)

	and	ds:[di].OLWI_attrs, mask OWA_FOCUSABLE or mask OWA_TARGETABLE

if _ODIE
	or	ds:[di].OLWI_attrs, MO_ATTRS_COMMAND_WINDOW and \
				    (not mask OWA_THICK_LINE_BORDER) and \
				    (not mask OWA_MOVABLE)
elif _DUI
	or	ds:[di].OLWI_attrs, MO_ATTRS_COMMAND_WINDOW and \
				    (not mask OWA_HAS_SYS_MENU) and \
				    (not mask OWA_CLOSABLE) and \
				    (not mask OWA_MOVABLE)
else
	or	ds:[di].OLWI_attrs, MO_ATTRS_COMMAND_WINDOW and \
				    (not mask OWA_HAS_SYS_MENU) and \
				    (not mask OWA_CLOSABLE)
endif

if _JEDIMOTIF
	;
	; Oh heck -- check if help control and mark closable and adorned with
	; system menu to allowing optimizing away the IC_DISMISS "Exit Help"
	; reply bar trigger
	;
	push	es, di
	mov	di, segment HelpControlClass
	mov	es, di
	mov	di, offset HelpControlClass
	call	ObjIsObjectInClass
	pop	es, di
	jnc	notHelp
	call	WinClasses_DerefVisSpec_DI	; just in case
	ornf	ds:[di].OLWI_attrs, mask OWA_CLOSABLE or mask OWA_HAS_SYS_MENU
notHelp:
endif	; _JEDIMOTIF

else
if _PM	;----------------------------------------------------------------------

	;PM modal dialogs have titlebars, sysmenus, and are movable.

	and	ds:[di].OLWI_attrs, mask OWA_FOCUSABLE or mask OWA_TARGETABLE
	or	ds:[di].OLWI_attrs, MO_ATTRS_COMMAND_WINDOW and \
				    (not mask OWA_CLOSABLE)

	test	ds:[di].OLPWI_flags, mask OLPWF_SYS_MODAL
	jz	notSysModal
sysModal:
	;
	; But sys modal dialogs do not have sys menus
	;
	and	ds:[di].OLWI_attrs, not mask OWA_HAS_SYS_MENU
notSysModal:

else	;----------------------------------------------------------------------

CUAS <	and	ds:[di].OLWI_attrs, mask OWA_FOCUSABLE or mask OWA_TARGETABLE >
CUAS <	or	ds:[di].OLWI_attrs, MO_ATTRS_NOTICE_WINDOW		      >

endif	;----------------------------------------------------------------------
endif

					;Store is notice
CUAS <	mov	ds:[di].OLWI_type, MOWT_NOTICE_WINDOW			>
OLS <	mov	ds:[di].OLWI_type, OLWT_NOTICE_WINDOW			>

	; Set visible instance data bit to override branch minimize
	; behavior for this window -- i.e. if the primary it is within is
	; iconified, THIS window should stay up on screen.
	call	WinClasses_DerefVisSpec_DI
	or	ds:[di].VI_attrs, mask VA_BRANCH_NOT_MINIMIZABLE

	;process positioning and sizing hints

	call	OLDialogWinScanGeometryHints

afterInit:

	;set the HGF_MENU_WINDOW_GRABS_ARE_TEMPORARY flag, so that dialog
	;windows will restore the focus after a menu closes.
	;DO NOT do this at OLWinClass! We don't want this behaviour in menus!

	call	WinClasses_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_menuState, \
				mask OLWMS_MENU_WINDOW_GRABS_ARE_TEMPORARY

	;this window is by default OWA_CLOSABLE (see cwinClass.asm).
	;if GIT_PROGRESS, GIT_MULTIPLE_RESPONSE, GIT_NOTIFICATION, or
	;GIT_AFFIRMATION then reset the OWA_CLOSABLE flag.

	call	WinClasses_DerefGen_DI
	cmp	ds:[di].GII_type, GIT_PROGRESS
	je	9$
	cmp	ds:[di].GII_type, GIT_AFFIRMATION
	je	9$
	cmp	ds:[di].GII_type, GIT_NOTIFICATION
	je	9$
	cmp	ds:[di].GII_type, GIT_MULTIPLE_RESPONSE
	jne	10$
9$:
	call	WinClasses_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_CLOSABLE)
10$:
	;
	; set up defaults for properties, etc.
	;
	call	WinClasses_DerefGen_DI		; ds:di = gen instance
	mov	al, ds:[di].GII_type		; ax = GenInteractionType
if _RUDY
	mov	ah, ds:[di].GII_visibility
endif ; _RUDY
	call	WinClasses_DerefVisSpec_DI	; ds:di = spec instance
					; default is delayed (checked only for
					; building of GIT_PROPERTIES standard
					; response triggers)
	cmp	al, GIT_PROPERTIES
	jne	notProperties		; don't mark as delayed if not
					;	properties
if _RUDY
	cmp	ah, GIV_DIALOG		; ... or if Dialog (to make
	je	notProperties		; properties dialogs immediate)
endif ; _RUDY
	mov	ds:[di].OLDWI_optFlags, mask OLDOF_DELAYED_MODE

notProperties:
;
; Don't do this yet as it conflicts with Wizard documentation - brianc 2/24/93
;
;	;
;	; If in keyboard only-mode, always default to single-usage.
;	;
;	call	OpenCheckIfKeyboardOnly		; carry set if so
;	jc	singleUsage
	;
	; Else, if not GIT_PROPERTIES or GIT_COMMAND, default is single usage,
	; (checked when handling IC_INTERACTION_COMPLETE)
	;
	cmp	al, GIT_PROPERTIES
	je	notSingleUsage
	cmp	al, GIT_COMMAND
	je	notSingleUsage
singleUsage:
	ornf	ds:[di].OLDWI_optFlags, mask OLDOF_SINGLE_USAGE
notSingleUsage:
	;
	; scan hints for various information
	;	(this is NOT just for _CUA_STYLE)
	;
	segmov	es, cs
	mov	di, offset cs:OLDialogWinHintHandlers
	mov	ax, length (cs:OLDialogWinHintHandlers)
	call	ObjVarScanData

	;
	; If in delayed mode, set the corresponding OLCtrl flag.
	;
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLDWI_optFlags, mask OLDOF_DELAYED_MODE
	jz	noDelayedMode
	or	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
noDelayedMode:

if	 _RUDY
	;
	; For Rudy, we want all dialogs that aren't POPUP (that is,
	; GIV_POPUP), to NOT have a border.  Also, if we were instructed
	; to have a fancy border, don't disable the thick line border
	; attribute or else it won't be drawn.
	;
	test	ds:[di].OLPWI_flags, mask OLPWF_IS_POPUP or \
				     mask OLPWF_FANCY_BORDER
	jnz	doneNukingBorder
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_THICK_LINE_BORDER
doneNukingBorder:
	;
	; If the dialog has no border, then this dialog should
	; look just like a primary.  Turn off the flag that causes
	; the margins to be larger than normal
	;
	test	ds:[di].OLWI_attrs, mask OWA_THICK_LINE_BORDER
	jnz	doneWithBorder
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_KIDS_INSIDE_BORDER
doneWithBorder:
endif	;_RUDY

	ret
OLDialogWinInitialize	endm

;
; OLDialogAlignHintHandlers is for non-modal dialogs only
;
if 	_CUA_STYLE	;START of MOTIF specific code -------------------------
OLDialogAlignHintHandlers	VarDataHandler \
	<HINT_INTERACTION_MAKE_RESIZABLE, offset OLDialogAlignMakeResizable>,
	<HINT_INTERACTION_MAXIMIZABLE, offset OLDialogAlignMaximizable>
endif		;END of MOTIF specific code -----------------------------------

if	_OL_STYLE	;START of OPEN LOOK specific code ---------------------
OLDialogAlignHintHandlers	VarDataHandler \
	<HINT_INTERACTION_SINGLE_USAGE, offset OLDialogAlignInitNotPinned>,
	<HINT_INTERACTION_MAKE_RESIZABLE, offset OLDialogAlignMakeResizable>
endif		;END of OPEN LOOK specific code -------------------------------

OLDialogAlignMakeResizable	proc	far
	class	OLWinClass

	call	WinClasses_DerefVisSpec_DI
if _ODIE
	ORNF	ds:[di].OLWI_attrs, mask OWA_RESIZABLE or mask OWA_THICK_LINE_BORDER
else
	ORNF	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
endif
	ret
OLDialogAlignMakeResizable	endp

OLDialogAlignMaximizable	proc	far
	class	OLWinClass

	call	WinClasses_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	ret
OLDialogAlignMaximizable	endp

;
; OLDialogWinHintHandlers is for all dialogs
;
OLDialogWinHintHandlers	VarDataHandler	\
	< HINT_INTERACTION_SINGLE_USAGE,
			offset HintDialogWinSingleUsage >,
	< HINT_INTERACTION_FREQUENT_USAGE,
			offset HintDialogWinFrequentUsage >,
	< HINT_INTERACTION_COMPLEX_PROPERTIES,
			offset HintDialogWinComplexProperties >,
	< HINT_INTERACTION_SIMPLE_PROPERTIES,
			offset HintDialogWinSimpleProperties >,
	< HINT_INTERACTION_RELATED_PROPERTIES,
			offset HintDialogWinDelayedMode >,
	< HINT_INTERACTION_UNRELATED_PROPERTIES,
			offset HintDialogWinImmediateMode >,
	< HINT_INTERACTION_SLOW_RESPONSE_PROPERTIES,
			offset HintDialogWinDelayedMode >,
	< HINT_INTERACTION_FAST_RESPONSE_PROPERTIES,
			offset HintDialogWinImmediateMode >,
	< HINT_INTERACTION_REQUIRES_VALIDATION,
			offset HintDialogWinDelayedMode >,
	< HINT_INTERACTION_NO_DISTURB,
			offset HintDialogWinNoDisturb >,
	< HINT_INTERACTION_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD,
			offset HintDialogDefaultActionIsNavigateToNextField >

; ATTR_GEN_INTERACTION_CUSTOM_WINDOW has been removed and replaced with
;  ATTR_GEN_WINDOW_CUSTOM_WINDOW. (7/92 JS.)
;	< ATTR_GEN_INTERACTION_CUSTOM_WINDOW,
;			offset HintDialogWinCustomWindow>,

HintDialogWinSingleUsage	proc	far
	mov	al, mask OLDOF_SINGLE_USAGE
	GOTO	DialogWinOrInOptFlags
HintDialogWinSingleUsage	endp

HintDialogWinFrequentUsage	proc	far
	mov	al, not mask OLDOF_SINGLE_USAGE
	GOTO	DialogWinAndInOptFlags
HintDialogWinFrequentUsage	endp

HintDialogWinComplexProperties	proc	far
	mov	al, mask OLDOF_COMPLEX_PROPERTIES
	GOTO	DialogWinOrInOptFlags
HintDialogWinComplexProperties	endp

HintDialogWinSimpleProperties	proc	far
	mov	al, not mask OLDOF_COMPLEX_PROPERTIES
	GOTO	DialogWinAndInOptFlags
HintDialogWinSimpleProperties	endp

HintDialogWinDelayedMode	proc	far
	mov	al, mask OLDOF_DELAYED_MODE
	GOTO	DialogWinOrInOptFlags
HintDialogWinDelayedMode	endp

HintDialogWinImmediateMode	proc	far
	mov	al, not mask OLDOF_DELAYED_MODE
	FALL_THRU	DialogWinAndInOptFlags
HintDialogWinImmediateMode	endp

DialogWinAndInOptFlags	proc	far
	class	OLDialogWinClass

	call	WinClasses_DerefVisSpec_DI
	and	ds:[di].OLDWI_optFlags, al
	ret
DialogWinAndInOptFlags	endp

DialogWinOrInOptFlags	proc	far
	class	OLDialogWinClass

	call	WinClasses_DerefVisSpec_DI
	or	ds:[di].OLDWI_optFlags, al
	ret
DialogWinOrInOptFlags	endp

HintDialogWinNoDisturb	proc	far
	class	OLWinClass

	call	WinClasses_DerefVisSpec_DI
	ornf	ds:[di].OLWI_moreFixedAttr, mask OWMFA_NO_DISTURB
	ret
HintDialogWinNoDisturb	endp

HintDialogDefaultActionIsNavigateToNextField	proc	far
	class	OLWinClass
	call	WinClasses_DerefVisSpec_DI
	ornf	ds:[di].OLWI_moreFixedAttr, \
			mask OWMFA_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD
	ret
HintDialogDefaultActionIsNavigateToNextField	endp

if	_OL_STYLE	;START of OPEN LOOK specific code ---------------------

OLDialogAlignInitNotPinned	proc	far
	call	OLWinClass

	call	WinClasses_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_fixedAttr, not (mask OWFA_LONG_TERM)
	ret
OLDialogAlignInitNotPinned	endp
endif		;END of OPEN LOOK specific code -------------------------------




COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLDialogWinClass

DESCRIPTION:	Scans for geometry hints.

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
PCT_EIGHTH	equ	128				; 640*128/1024 = 80
PCT_HALF equ	5				; 200*5/1024 = 1

OLDialogWinScanGeometryHints	method static OLDialogWinClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLDialogWinClass
	mov	es, di

	;do superclass geometry first.

	mov	di, offset OLDialogWinClass
	CallSuper	MSG_SPEC_SCAN_GEOMETRY_HINTS

	;THEN, test to see if this is a modal window or not.

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
						mask OLPWF_SYS_MODAL
	jnz	modalInit		;skip if modal...

	;this object is below the GenPrimary. If modal, center it on the
	;field. If non-modal, center it in the 

	;override OLWinClass positioning and sizing flags

if not _RUDY
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_CENTER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE) \
		or mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT
endif

	;process positioning and sizing hints

	mov	cx, FALSE		;pass flag: window cannot have icon
	jmp	short processHints

modalInit:
	;override OLWinClass positioning and sizing flags

if _PM		
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_CENTER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
elif not _RUDY
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_CENTER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
endif

processHints:

if _RUDY
	;
	; Assume first that the dialog will be full screen.
	;
	andnf	ds:[di].OLWI_winPosSizeFlags, \
			(not mask WPSF_POSITION_TYPE)
	andnf	ds:[di].OLWI_winPosSizeFlags, \
			(not mask WPSF_SIZE_TYPE)
	ornf	ds:[di].OLWI_winPosSizeFlags, \
			WPT_AT_RATIO shl offset WPSF_POSITION_TYPE or \
			WST_EXTEND_TO_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	add	di, offset VI_bounds		; ds:di = VI_bounds
	mov	bp, di				; ds:bp+2 = OLWI_winPosSizeState
	add	bp, offset OLWI_winPosSizeFlags
	call	EnsureRightBottomBoundsAreIndependent
	mov	ds:[di].R_left, mask SWSS_RATIO or PCT_EIGHTH
	mov	ds:[di].R_top, mask SWSS_RATIO or PCT_0
				; indicate that VI_bounds.R_left and R_top
				;	contain a SpecWinSizePair 
	ornf	{word} ds:[bp]+2, mask WPSS_VIS_POS_IS_SPEC_PAIR


	;
	; If we're a popup, our window goes on the right side
	; of the screen.  
	;
	call	WinClasses_DerefGen_DI
	cmp	ds:[di].GII_visibility, GIV_POPUP
	jne	checkNoTitleBar

	;
	; Changed to SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT and set initial
	; left bounds to 95% of parent's width so that it will only be as
	; wide as needed by the children. --JimG 7/27/95
	;
	call	WinClasses_DerefVisSpec_DI
	andnf	ds:[di].OLWI_winPosSizeFlags, \
			(not mask WPSF_POSITION_TYPE)
	andnf	ds:[di].OLWI_winPosSizeFlags, \
			(not mask WPSF_SIZE_TYPE)
	ornf	ds:[di].OLWI_winPosSizeFlags, \
			WPT_AT_RATIO shl offset WPSF_POSITION_TYPE or \
			WST_EXTEND_NEAR_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE
	ornf	ds:[di].OLWI_winPosSizeFlags, \
			mask WPSF_SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT
	add	di, offset VI_bounds		; ds:di = VI_bounds
	mov	bp, di				; ds:bp+2 = OLWI_winPosSizeState
	add	bp, offset OLWI_winPosSizeFlags
	call	EnsureRightBottomBoundsAreIndependent
	mov	ds:[di].R_left, mask SWSS_RATIO or PCT_95
	mov	ds:[di].R_top, mask SWSS_RATIO or PCT_HALF
				; indicate that VI_bounds.R_left and R_top
				;	contain a SpecWinSizePair 
	ornf	{word} ds:[bp]+2, mask WPSS_VIS_POS_IS_SPEC_PAIR

checkNoTitleBar:

	;
	; No title bar EXPLICITLY defined, assume this is a funny window that
	; appears in the middle of the screen, and avoid taking it down.
	;
	mov	ax, HINT_WINDOW_NO_TITLE_BAR
	call	ObjVarFindData
	jnc	afterTitleBar
	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_CENTER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
	jmp	setFancyBorder

afterTitleBar:
	mov	ax, HINT_CENTER_WINDOW
	call	ObjVarFindData
	jnc	afterFancyBorder
	
	;
	; If either HINT_WINDOW_NO_TITLE_BAR or HINT_CENTER_WINDOW is
	; present, then set the bit that indicates that the SPUI should draw
	; a fancy border on the dialog.  Also, ensure that the thick line
	; border bit is enabled.
	;
setFancyBorder:
	call	WinClasses_DerefVisSpec_DI
	ornf	ds:[di].OLWI_attrs, mask OWA_THICK_LINE_BORDER
	ornf	ds:[di].OLPWI_flags, mask OLPWF_FANCY_BORDER

afterFancyBorder:

endif ;_RUDY
	call	OpenWinProcessHints
	.leave
	ret
OLDialogWinScanGeometryHints	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinUpdateSpecBuild
			-- MSG_SPEC_BUILD_BRANCH for OLDialogWinClass

DESCRIPTION:	Add on to super classes method & construct standard
		triggers at the bottom of the window, after the
		interaction & all its children have been built.

PASS:
	*ds:si - instance data
	es - segment of OLDialogWinClass

	ax - MSG_SPEC_BUILD_BRANCH

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
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


OLDialogWinUpdateSpecBuild	method dynamic	OLDialogWinClass,
						MSG_SPEC_BUILD_BRANCH

	test	bp, mask SBF_WIN_GROUP
	LONG jz	callSuper	; if not top, then no gadget area work, etc.

	; If this is a "custom" window, don't need a gadget area.
	;
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	haveGadgetArea
	;
	; Create gadget area, if necessary to allow
	; HINT_ORIENT_CHILDREN_HORIZONTALLY on the GenInteraction.
	; Parent will be this object (and spec build, etc. is handled
	; as usual by superclass)
	;
	tst	ds:[di].OLDWI_gadgetArea
	jnz	haveGadgetArea
	push	ax, bp			; save build flags, msg
	mov	di, offset OLGadgetAreaClass	; es:di = class of object
	call	OpenWinCreateBarObject	; ax = chunk of new OLGadgetArea
	call	WinClasses_DerefVisSpec_DI	; ds:di = OLDialogWin
	mov	ds:[di].OLDWI_gadgetArea, ax	; save chunk
if INDENT_BOXED_CHILDREN
	;
	; if desired, tell gadget area not to indent HINT_DRAW_IN_BOX
	; children
	;
	push	si				; save window
	push	ax				; save gadget area
	mov	ax, HINT_DONT_INDENT_BOX
	call	ObjVarFindData
	pop	si				; *ds:si = gadget area
	jnc	leaveIndent
	mov	cx, mask OLGAF_PREVENT_LEFT_MARGIN
	mov	ax, MSG_SPEC_GADGET_AREA_SET_FLAGS
	call	ObjCallInstanceNoLock
leaveIndent:
	pop	si				; *ds:si = window
endif
	pop	ax, bp			; restore build flags, msg
haveGadgetArea:

	;
	; If we've created a reply bar, we must build it now before any
	; children are built (in superclass handler).  Developer-supplied
	; reply bar will be built in superclass as it is in generic tree.
	; (Reply bar we created is not in generic tree.)
	;	*ds:si = OLDialogWin
	;	ds:di = OLDialogWin spec part
	;
	test	ds:[di].OLDWI_optFlags, mask OLDOF_REPLY_BAR_CREATED
	jz	noReplyBar		; let superclass build it
	push	ax, si, bp		; save OLDialogWin
EC <	mov	si, ds:[di].OLDWI_replyBar.handle			>
EC <	cmp	si, ds:[LMBH_handle]					>
EC <	ERROR_NE	OL_ERROR					>
	mov	si, ds:[di].OLDWI_replyBar.chunk	; *ds:si = reply bar
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
	clr	bp			; basic spec build
	call	VisSendSpecBuildBranch
	pop	ax, si, bp		; restore OLDialogWin
noReplyBar:

;	Bottom-area object we created is like a reply bar - it isn't in the
;	generic tree. We have to force it to get built.

	
	call	WinClasses_DerefVisSpec_DI
	tst	ds:[di].OLDWI_bottomArea
	jz	callSuper
	push	ax, si, bp
	mov	si, ds:[di].OLDWI_bottomArea
	clr	bp
	call	VisSendSpecBuildBranch
	pop	ax, si, bp

callSuper:
				; First, do regular build for interaction and
				; children
	push	bp
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
	pop	bp

				; See if top
	test	bp, mask SBF_WIN_GROUP
	jz	done		; if not top, then just did button.  Done.

				; If not constructed yet, build interaction
				; response
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLDWI_optFlags, mask OLDOF_BUILT
	jnz	done
	ornf	ds:[di].OLDWI_optFlags, mask OLDOF_BUILT
				; Then deal with standard interaction triggers
				; (either creating them, or fixing up app-
				;  supplied ones)
	call	HandleDialogResponses		; in WinDialog resource
						; (not always used)
done:

	ret
OLDialogWinUpdateSpecBuild	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinSpecBuild
			-- MSG_SPEC_BUILD for OLDialogWinClass

DESCRIPTION:	Add on to super classes method & build OLGadgetArea.

PASS:
	*ds:si - instance data
	es - segment of OLDialogWinClass

	ax - MSG_SPEC_BUILD_BRANCH

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
	brianc	1/29/92		Initial version

------------------------------------------------------------------------------@


OLDialogWinSpecBuild	method dynamic	OLDialogWinClass, MSG_SPEC_BUILD

	test	bp, mask SBF_WIN_GROUP
	jz	done		; if not top, then no gagdet area work

	; First, build OLTitleBarGroups so that when things below them get
	; built, they'll have something to attach themselves to.
	;
	mov	ax, OLWI_titleBarLeftGroup.offset
	call	OLWinSendVBToBar

	mov	ax, OLWI_titleBarRightGroup.offset
	call	OLWinSendVBToBar

	; Then build OLGadgetArea so that when when things below us get
	; built, they'll have something to attach themselves to.
	;
	mov	ax, OLDWI_gadgetArea
	call	OLWinSendVBToBar

	;
	; UserDoDialogs must be made not movable because when you move them,
	; the background is not redrawn.  (Changed to include Motif 12/15/92)
	;
	mov	bx, ds:[si]	
	add	bx, ds:[bx].Gen_offset					
	test	ds:[bx].GII_attrs, mask GIA_INITIATED_VIA_USER_DO_DIALOG
	jz	done
		
	call	WinClasses_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_MOVABLE		

	;
	; Then, do regular build for interaction
	;
done:
	mov	ax, MSG_SPEC_BUILD
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
	ret
OLDialogWinSpecBuild	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLDialogWinClass

DESCRIPTION:	Recalc's size.

PASS:		*ds:si 	- instance data
		es     	- segment of OLDialogWinClass
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
	brianc	8/ 5/92		Initial Version

------------------------------------------------------------------------------@

OLDialogWinRecalcSize	method dynamic OLDialogWinClass, MSG_VIS_RECALC_SIZE
	push	cx				; save desired width
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
	pop	ax				; ax = desired width
	tst	ax
	jns	done				; wasn't as-desired
	push	cx, dx				; save w, h
if _JEDIMOTIF
	mov	cx, 240
	mov	dx, 240
else
	call	OpenGetScreenDimensions		; cx = w, dx = h
endif
	mov	ax, cx				; ax = w
	dec	ax				; give it a bit on each side
	dec	ax
	pop	cx, dx				; restore w, h
	cmp	cx, ax
	jbe	done
	mov	cx, ax
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	mov	ax, MSG_VIS_RECALC_SIZE_AND_INVAL_IF_NEEDED
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
done:
	ret

OLDialogWinRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinMaximize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maximize dialog

CALLED BY:	MSG_OL_WIN_MAXIMIZE
PASS:		*ds:si	= OLDialogWinClass object
		ds:di	= OLDialogWinClass instance data
		ds:bx	= OLDialogWinClass object (same as *ds:si)
		es 	= segment of OLDialogWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

OLDialogWinMaximize	method dynamic OLDialogWinClass, 
					MSG_OL_WIN_MAXIMIZE
	mov	al, VUM_NOW
	GOTO	SetMaximized

OLDialogWinMaximize	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinRestore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore (unmaximize) dialog

CALLED BY:	MSG_OL_RESTORE_WIN
PASS:		*ds:si	= OLDialogWinClass object
		ds:di	= OLDialogWinClass instance data
		ds:bx	= OLDialogWinClass object (same as *ds:si)
		es 	= segment of OLDialogWinClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

OLDialogWinRestore	method dynamic OLDialogWinClass, 
					MSG_OL_RESTORE_WIN
	mov	al, VUM_NOW
	GOTO	SetNotMaximized

OLDialogWinRestore	endm

endif	;----------------------------------------------------------------------

WinClasses	ends

;-----------------------------------------------------------------------------

WinDialog	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleDialogResponses

DESCRIPTION:	Creates a GenInteraction w/triggers inside of it,
		with the correct buttons inside for the user to respond
		to this inteaction with.

CALLED BY:	INTERNAL

PASS:
	*ds:si	- OLDialogWin object

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version

------------------------------------------------------------------------------@
HandleDialogResponses	proc	far
	;
	; We know that we are a dialog, so we can just proceed with dealing
	; with standard triggers (either ones we need to create or ones
	; supplied by the application).  Ones supplied by the application are
	; done so with HINT_SEEK_REPLY_BAR.  This is handled with a GUP_QUERY
	; elsewhere.
	;
	; First, find the cases where we don't need to add any standard
	; triggers.  For these cases, we also don't allow the application to
	; supply any standard triggers, so we just exit
	;
	; The only current such case is GIT_MULTIPLE_RESPONSE, where the
	; application must supply all triggers, none of which can be standard
	; triggers.
	;
	call	WinDialog_DerefGen_DI
	mov	al, ds:[di].GII_type

if _RUDY
	;
	; Rudy - organizational popups (i.e. menus) get an OK and close.
	;
	cmp	ds:[di].GII_visibility, GIV_POPUP
	jne	notPopup

	cmp	al, GIT_PROPERTIES
	je	popup
	cmp	al, GIT_ORGANIZATIONAL
	jne	notPopup
popup:
	mov	cx, IC_APPLY
	call	AddStandardTriggerIfNeeded

	push	ax
	mov	ax, HINT_IS_POPUP_LIST
	call	ObjVarFindData
	pop	ax
	mov	cx, IC_DISMISS
	jnc	notPopupList
	mov	cx, IC_CANCEL_POPUP_LIST		;popups use reset
notPopupList:
	call	AddStandardTriggerIfNeeded
	jmp	short doMonikers
notPopup:
endif

	cmp	al, GIT_MULTIPLE_RESPONSE
;	LONG je	done
; To support moniker-less triggers to GIT_MULTIPLE_RESPONSE
; UserStandardDialogs, we'll check monikers - brianc 2/27/92
	je	doMonikers
	;
	; Now trudge through each of the types...
	;
	cmp	al, GIT_NOTIFICATION
	jne	notNotification
	mov	cx, IC_OK
	call	AddStandardTriggerIfNeeded
	jmp	short doMonikers

notNotification:
	cmp	al, GIT_AFFIRMATION
	jne	notAffirmation
	mov	cx, IC_YES
	call	AddStandardTriggerIfNeeded
	mov	cx, IC_NO
	call	AddStandardTriggerIfNeeded
	jmp	short doMonikers

notAffirmation:
	cmp	al, GIT_PROGRESS
	jne	notProgress
	mov	cx, IC_STOP
	call	AddStandardTriggerIfNeeded
	jmp	short doMonikers

notProgress:
	cmp	al, GIT_ORGANIZATIONAL
	jne	notOrganizational
;don't add "Done" button for GIT_ORGANIZATIONAL as we need to be able to
;make dialogs without reply bars, toolboxes for example
;	mov	cx, IC_DISMISS
;	call	AddStandardTriggerIfNeeded
	jmp	short doMonikers

notOrganizational:
	cmp	al, GIT_COMMAND
	jne	notCommand
	mov	cx, IC_DISMISS
	call	AddStandardTriggerIfNeeded
	jmp	short doMonikers

notCommand:
EC <	cmp	al, GIT_PROPERTIES					>
EC <	ERROR_NE	OL_ERROR_BAD_GEN_INTERACTION_TYPE		>
	call	WinDialog_DerefVisSpec_DI

if _RUDY
	mov	cx, IC_CHANGE
	call	AddStandardTriggerIfNeeded

	call	WinDialog_DerefVisSpec_DI
	test	ds:[di].OLDWI_optFlags, mask OLDOF_DELAYED_MODE
	jz	addDismiss
else
	test	ds:[di].OLDWI_optFlags, mask OLDOF_DELAYED_MODE
	jz	doMonikers
endif
						; delayed required for complex
	test	ds:[di].OLDWI_optFlags, mask OLDOF_COMPLEX_PROPERTIES
	jz	addPropertiesApply		; not COMPLEX, just apply
	mov	cx, IC_RESET			; add reset for COMPLEX
	call	AddStandardTriggerIfNeeded

addPropertiesApply:
if not _RUDY ; Rudy doesn't want an extra "Apply" trigger
	mov	cx, IC_APPLY
	call	AddStandardTriggerIfNeeded
endif ; not _RUDY

RUDY<addDismiss:							>
	mov	cx, IC_DISMISS
	call	AddStandardTriggerIfNeeded

doMonikers:

if not _RUDY
	;
	; If our gen counterpart has help, add a help trigger
	; ...unless we've been told not to
	;
	call	OpenGetHelpOptions
	test	ax, mask UIHO_HIDE_HELP_BUTTONS
	jnz	noHelp				;branch if help hidden
	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarFindData
	jnc	noHelp				;branch if no help
	mov	cx, IC_HELP
	call	AddStandardTriggerIfNeeded
noHelp:
endif


if (0)	; We EnsureStandardTriggerMonikers when we SaveStandardTriggerInfo
	;
	; Go through all the standard triggers (either created here or supplied
	; by the application) and create monikers for them if they don't have
	; one yet.  This requires the standard trigger list to be up to date.
	; We also sneak in some work to esnure that APPLY and RESET triggers
	; are disabled, as they aren't enabled until some property is changed 
	; by the user.
	;	*ds:si = OLDialogWin
	;
	call	EnsureStandardTriggerMonikers
endif
	;
	; If running on a small screen, remove reply bar if all we have is a
	; IC_DISMISS trigger and the dialog is OWA_CLOSABLE, meaning we'll be
	; providing an alternate close button - brianc 2/9/93
	;
	call	RemoveReplyBarIfPossible
	;
	; spec build new reply bar (with new triggers)
	; (must build unconditionally as the reply is not a generic child of
	;  of the GenIntearction, so will not get built in the normal fashion)
	; (Also, everything else about the OLDialog has been built as we are
	;  called in the tail end of the SPEC_BUILD_BRANCH handler)
	;	*ds:si = OLDialogWin
	;
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDialogWin
	mov	bx, ds:[di].OLDWI_replyBar.handle	; ^lbx:si = reply bar
	mov	si, ds:[di].OLDWI_replyBar.chunk
	tst	bx
	jz	done				; no reply bar to update
	call	ObjSwapLock			; ds = reply bar segment
						; bx = OLDialogWin block
	clr	bp				; basic spec build
	call	VisSendSpecBuildBranch
	call	ObjSwapUnlock			; ds = segment of OLDialogWin
done:
	ret
HandleDialogResponses	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveReplyBarIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If running on a small screen, remove reply bar if all we
		have is a IC_DISMISS trigger and the dialog is OWA_CLOSABLE,
		meaning we'll be providing an alternate close button

CALLED BY:	HandleDialogResponses

PASS:		*ds:si = OLDialogWin

RETURN:		nothing

DESTROYED:	ax, bx, cx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveReplyBarIfPossible	proc	near
	uses	si
	.enter
	call	OpenCheckIfTiny			; on tiny screen?
	LONG jnc	done				; nope
	call	WinDialog_DerefGen_DI		; ds:di = GenInteraction
	cmp	ds:[di].GII_type, GIT_ORGANIZATIONAL
	LONG jne	done
	mov	bp, si				; *ds:bp = OLDialogWin
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDialogWin
if not _OL_STYLE
	test	ds:[di].OLWI_attrs, mask OWA_HAS_SYS_MENU	; any sys menu?
	jz	done				; no, can't remove close
endif
	;
	; can't remove if reply bar has other triggers
	;
	mov	bx, ds:[di].OLDWI_replyBar.handle
	mov	si, ds:[di].OLDWI_replyBar.chunk
	mov	ax, MSG_VIS_COUNT_CHILDREN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	bp
	call	ObjMessage			; dx = #
	pop	bp
	cmp	dx, 1				; only one?
	jne	done				; nope, can't remove

	mov	si, bp				; *ds:si = OLDialogWin
	call	WinDialog_DerefVisSpec_DI
	mov	si, ds:[di].OLDWI_triggerList
	tst	si
	jz	done				; no triggers, done
	call	ChunkArrayGetCount		; cx = # triggers
	cmp	cx, 1				; exactly one?
	jne	done				; nope, don't bother
	mov	ax, 0				; get first element
	call	ChunkArrayElementToPtr		; ds:di = element
	jc	done				; out of bounds!?!
	cmp	ds:[di].NOICS_ic, IC_DISMISS	; IC_DISMISS?
	jne	done				; nope
	push	ds:[di].NOICS_optr.handle
	push	ds:[di].NOICS_optr.chunk
	mov	si, bp				; *ds:si = OLDialogWin
	call	WinDialog_DerefVisSpec_DI
	mov	bx, ds:[di].OLDWI_replyBar.handle	; ^lbx:si = reply bar
	tst	bx
	jz	donePop				; no reply bar to turn off
	mov	si, ds:[di].OLDWI_replyBar.chunk
						; turn off
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE or \
					mask VA_MANAGED) shl 8
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_MANUAL			; will be updating later
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
donePop:
	pop	si
	pop	bx
						; turn off
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE or \
					mask VA_MANAGED) shl 8
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_MANUAL			; will be updating later
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave
	ret
RemoveReplyBarIfPossible	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureStandardTriggerMonikers

DESCRIPTION:	Go through all the standard triggers (either created here or
		supplied by the application) and create monikers for them if
		they don't have one yet.  This requires the standard trigger
		list to be up to date.  We also sneak in some work to esnure
		that APPLY and RESET triggers are disabled, as they aren't
		enabled until some property is changed by the user.

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLDialogWin object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@

if (0)	; We EnsureStandardTriggerMonikers when we SaveStandardTriggerInfo ----

EnsureStandardTriggerMonikers	proc	near
	uses	si
	.enter
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDialogWin
	mov	si, ds:[di].OLDWI_triggerList	; *ds:si = trigger list
	tst	si
	jz	done
	mov	cl, ds:[di].OLPWI_flags		; cl = OLPopupWinFlags
	mov	dl, ds:[di].OLDWI_optFlags	; dl = OLDialogOptFlags
	mov	bx, cs
	mov	di, offset EnsureStandardTriggerMonikerCallback
	call	ChunkArrayEnum
done:
	.leave
	ret
EnsureStandardTriggerMonikers	endp

endif	;----------------------------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureStandardTriggerMonikerCallback

DESCRIPTION:	Callback routine for EnsureStandardTriggerMonikers.

CALLED BY:	INTERNAL

PASS:		ds:di	- element (NotifyOfInteractionCommandStruct)
		cl	- OLPopupWinFlags
		dl	- OLDialogOptFlags

RETURN:		carry clear to continue enumeration

DESTROYED:	ax, bx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/92		Initial version

------------------------------------------------------------------------------@

EnsureStandardTriggerMonikerCallback	proc	far
	uses	cx, dx
	.enter

	push	cx, dx				; save OLPWF_*, OLDOF_*
	push	ds:[di].NOICS_ic		; save InteractionCommand
	mov	bx, ds:[di].NOICS_optr.handle
	mov	si, ds:[di].NOICS_optr.chunk
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	WinDialog_ObjMessageCallFixupDS	; ax = moniker (if any)
	pop	bp				; restore InteractionCommand
	pop	cx, dx				; restore OLPWF_*, OLDOF_*
	tst	ax				; any moniker?
	LONG	jnz	haveMoniker		; have moniker already, done

; To support moniker-less triggers to GIT_MULTIPLE_RESPONSE
; UserStandardDialogs, we'll check InteractionCommand range - brianc 2/27/92
	cmp	bp, InteractionCommand		; skip moniker work if not
	LONG jae	done			;	standard IC

if _RUDY
	;
	; Rudy, for change hints, put at top, hope other buttons have
	; been given slots.
	;
	cmp	bp, IC_CHANGE
	jne	checkNo
	clr	ax
	call	AddPositionHint			; position at bottom

checkNo:
	; 
	; Rudy, special code to stick "No" triggers at the bottom.   Also
	; IC_CANCEL_POPUP_LIST triggers.
	;
	cmp	bp, IC_CANCEL_POPUP_LIST
	je	putAtBottom
	cmp	bp, IC_NO
	jne	notNo

putAtBottom:
	mov	ax, 3
	call	AddPositionHint
notNo:

endif
	;
	; add moniker to this standard trigger, depending on the
	; InteractionCommand, OLDialogOptFlags, and GenInteractionAttrs
	;	bp = InteractionCommand
	;	cl = OLPopupWinFlags
	;	dl = OLDialogOptFlags
	;	^lbx:si = trigger
	;
	cmp	bp, IC_DISMISS			; dismiss?
	jne	notDismiss
	;
	; IC_DISMISS is "Close" for non-modal, "Cancel" for modal
	;
if _RUDY
	mov	ax, 3
	call	AddPositionHint			; position at bottom
endif

;
; Don't use "Esc - Close/Cancel" as this yet as it conflicts with Wizard
; documentation - brianc 2/24/93
;
if KEYBOARD_ONLY_UI
	call	OpenCheckIfKeyboardOnly		; carry set if so
endif
	mov	ax, offset StandardCancelMoniker ; assume not-keyboard-only &
	
if KEYBOARD_ONLY_UI				;	modal, use "Cancel"
	jnc	notKeyboardOnlyModal
	mov	ax, offset StandardKeyboardCancelMoniker ; else, kbd-only
							;	modal
notKeyboardOnlyModal:
endif
	call	CheckDismissCloseCancel		; Z clear if "Cancel"
	jnz	setThisMoniker			; modal, use "Cancel"

	mov	ax, offset StandardCloseMoniker	; else, assume not-kbd-only,
	
if KEYBOARD_ONLY_UI			;	use "Close"
	call	OpenCheckIfKeyboardOnly		; carry set if so
	jnc	setThisMoniker			; no, use "Close"
	mov	ax, offset StandardKeyboardCloseMoniker	; else, use
							;	"[ESC] - Close"
endif
	jmp	short setThisMoniker

	;
	; Rudy has a single "apply" moniker, so this is not needed.
	;
notDismiss:
	cmp	bp, IC_APPLY			; apply?
	jne	notApply
	;
	; IC_APPLY is "Apply" except for OLDOF_SINGLE_USAGE or modal where
	; it is "OK"
	;	bp = InteractionCommand
	;	cl = OLPopupWinFlags
	;	dl = OLDialogOptFlags
	;

if _RUDY
	mov	ax, offset StandardOKMoniker	; assume modal -- "OK"

	test	cl, mask OLPWF_IS_POPUP		; popup window,
	jnz	setThisMoniker			; use "ok"
						; else use "accept"	
else ; _not RUDY

	mov	ax, offset StandardOKMoniker	; assume modal -- "OK"

if ALL_DIALOGS_ARE_MODAL
	;
	; Forced "modal" by keyboard-only mode, preserve the non-modal
	; dialog box functionality and allow users to make multiple applies
	; before closing the dialog.  2/17/94 cbh
	;
	test	cl, mask OLPWF_FORCED_MODAL
	jnz	dontTreatAsModal
endif ; ALL_DIALOGS_ARE_MODAL

	test	cl, mask OLPWF_APP_MODAL or mask OLPWF_SYS_MODAL	; modal?
	jnz	setThisMoniker			; modal, use "OK"

if ALL_DIALOGS_ARE_MODAL
dontTreatAsModal:
endif
	test	dl, mask OLDOF_SINGLE_USAGE	; single usage?
	jnz	setThisMoniker			; yes, use "OK"
endif ; not _RUDY

if _RUDY
	;
	; We get apply triggers for non-popup delayed Properties dialogs
	; (which should almost never happen on Responder anyway).
	; But we also get Change triggers, both of which usually
	; occupy slot 0.  Move the apply trigger to slot 1
	; (and hope there's nothing there)
	;
	mov	ax, 1
	call	AddPositionHint

endif ; _RUDY

	mov	ax, offset StandardApplyMoniker	; else, use "Apply"
	jmp	short setThisMoniker

notApply:

if _RUDY
	;
	; Rudy, IC_OK for notification boxes should be in slot 3.
	;
	cmp	bp, IC_OK
	jne	notOK

	call	CheckIfNotification
	jnc	notOK

	mov	ax, 3
	call	AddPositionHint
notOK:
endif

	;
	; this InteractionCommand type has a fixed moniker, just use the
	; moniker specified in the table
	;	bp = InteractionCommand
	;
	mov	di, bp				; di = InteractionCommand
	shl	di, 1				; convert to word table offset
	mov	ax, cs:[standardTriggerMonikerTable][di]	; ax = moniker
setThisMoniker:

	push	dx, bp
	mov	bp, VUM_MANUAL
	mov	cx, handle StandardMonikers	; ^lcx:dx = moniker
	mov	dx, ax
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	WinDialog_ObjMessageCallFixupDS
	pop	dx, bp

haveMoniker:

if	_REDMOTIF
	cmp	bp, IC_HELP
	jne	notHelp
	push	dx, bp
	mov	cx, mask KS_PHYSICAL or mask KS_CTRL or C_SMALL_H

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_KBD_ACCELERATOR
	call	WinDialog_ObjMessageCallFixupDS
	pop	dx, bp
notHelp:
endif
	;
	; if it is IC_APPLY or IC_RESET, disable it
	;	^lbx:si = trigger
	;	bp = InteractionCommand
	;	cl = OLPopupWinFlags
	;	dl = OLDialogOptFlags
	;
	cmp	bp, IC_APPLY
	je	isApplyReset
	cmp	bp, IC_RESET
	jne	done
isApplyReset:

if not _RUDY					; apply acts differently

	test	dl, mask OLDOF_DELAYED_MODE	; only do this for properties
	jz	done
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_MANUAL
	call	WinDialog_ObjMessageCallFixupDS
endif
done:
	clc					; continue enumeration
	.leave
	ret
EnsureStandardTriggerMonikerCallback	endp

;
; this tables must be in same order as InteractionCommand in
; Include/Objects/gInterC.def
;

if _RUDY
standardTriggerMonikerTable	nptr \
	0,				; IC_NULL
	0,				; IC_DISMISS - "Close"/"Cancel"
	0,				; IC_INTERACTION_COMPLETE - invalid
	offset StandardApplyMoniker,	; IC_APPLY - always "Accept"
	offset StandardResetMoniker,	; IC_RESET - always "Reset"
	offset StandardOKMoniker,	; IC_OK - always "OK"
	offset StandardYesMoniker,	; IC_YES - always "Yes"
	offset StandardNoMoniker,	; IC_NO - always "No"
	offset StandardStopMoniker,	; IC_STOP - always "Stop"
	0,				; IC_EXIT
	offset StandardHelpMoniker,	; IC_HELP - "Help"
	offset StandardChangeMoniker,	; IC_CHANGE - "Change"
	offset StandardCancelMoniker,	; IC_CANCEL_POPUP_LIST - "Cancel"
	offset StandardNextMoniker,	; IC_NEXT - "Next"
	offset StandardPrevMoniker	; IC_PREVIOUS - "Previous"

else

standardTriggerMonikerTable	nptr \
	0,				; IC_NULL
	0,				; IC_DISMISS - "Close"/"Cancel"
	0,				; IC_INTERACTION_COMPLETE - invalid
	0,				; IC_APPLY - "Apply"/"OK"
	offset StandardResetMoniker,	; IC_RESET - always "Reset"
	offset StandardOKMoniker,	; IC_OK - always "OK"
	offset StandardYesMoniker,	; IC_YES - always "Yes"
	offset StandardNoMoniker,	; IC_NO - always "No"
	offset StandardStopMoniker,	; IC_STOP - always "Stop"
	0,				; IC_EXIT
	offset StandardHelpMoniker,	; IC_HELP - "Help"
	0,				; IC_INTERNAL_1
	0,				; IC_INTERNAL_2
	offset StandardNextMoniker,	; IC_NEXT - "Next"
	offset StandardPrevMoniker	; IC_PREVIOUS - "Previous"
endif

CheckHack< (length standardTriggerMonikerTable) eq (InteractionCommand) >



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPositionHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add position hint.

CALLED BY:	EnsureStandardTriggerMonikerCallback

PASS:		^lbx:si -- trigger	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/13/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

AddPositionHint	proc	near		uses	ax, bx, cx, dx, bp
	slot	local	word

	.enter
	Assert	objectOD bxsi VisClass
	Assert	objectOD bxsi GenClass

	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	di, sp

	mov	slot, ax

	mov	ss:[di].AVDP_data.segment, ss
	lea	dx, slot
	mov	ss:[di].AVDP_data.offset, dx

	mov	ss:[di].AVDP_dataSize, size word
	mov	ss:[di].AVDP_dataType, HINT_SEEK_SLOT
	xchg	bp, di
	mov	ax, MSG_META_ADD_VAR_DATA
	call	objMessageCallSaveDI
	add	sp, size AddVarDataParams

	mov	cx, mask VGA_NOTIFY_GEOMETRY_VALID	;necessary hack
	mov	ax, MSG_VIS_SET_GEO_ATTRS
	mov	dl, VUM_MANUAL
	call	objMessageCallSaveDI
	mov	bp, di
	.leave
	ret

objMessageCallSaveDI	label	near
	push	di
	call	WinDialog_ObjMessageCallFixupDS	
	pop	di
	retn

AddPositionHint	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if button is in a GIT_NOTIFICATION interaction

CALLED BY:	EnsureStandardTriggerMonikerCallback
PASS:		^lbx:si	= button
RETURN:		carry set if button is in a GIT_NOTIFICATION interaction
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

CheckIfNotification	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; search up the generic tree for a OLDialogWinClass object
	; (can't go up vis tree because the button hasn't been spec built yet.)

	mov	ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
	mov	cx, segment OLDialogWinClass
	mov	dx, offset OLDialogWinClass
	call	WinDialog_ObjMessageCallFixupDS
	jnc	exit				;exit, c=0

	movdw	bxsi, cxdx			;^lbx:si = GenInteraction
	mov	ax, MSG_GEN_INTERACTION_GET_TYPE
	call	WinDialog_ObjMessageCallFixupDS

	cmp	cl, GIT_NOTIFICATION
	clc
	jne	exit				;exit, c=0

	stc					;GIT_NOTIFICATION
exit:
	.leave
	ret
CheckIfNotification	endp

endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckDismissCloseCancel

DESCRIPTION:	This routine checks if we should use "Close" moniker or
		"Cancel" moniker for an IC_DISMISS trigger.  "Cancel" will
		be used if the dialog is modal.  "Close" if non-modal.

CALLED BY:	INTERNAL
			EnsureStandardTriggerMonikerCallback

PASS:		cl	- OLPopupWinFlags
		dl	- OLDialogOptFlags

RETURN:		Z clear (JNZ) to use "Cancel"
		Z set (JZ) to use "Close"

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		If we decide that single-usage should also produce a "Cancel"
		trigger instead of a "Close" trigger, check here.  This will
		allow a single-usage properties to be reset when IC_DISMISSed.
		(Motif says that "Cancel" = IC_DISMISS + IC_RESET, so we cannot
		leave a single-usage properties' IC_DISMISS as "Close" and also
		have it IC_RESET).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@
CheckDismissCloseCancel	proc	near

if _RUDY
	;
	; Rudy, we always show a "close" on non-delayed properties boxes.
	;
	test	cl, mask OLPWF_IS_PROPERTIES
	jz	notProperties
	test	dl, mask OLDOF_DELAYED_MODE
	jz	exit				;immediate properties, exit, z=0
notProperties:

endif

if ALL_DIALOGS_ARE_MODAL
	;
	; Forced "modal" by keyboard-only mode, preserve the non-modal
	; dialog box functionality and allow users to make multiple applies
	; before closing the dialog.  2/17/94 cbh
	;
	test	cl, mask OLPWF_FORCED_MODAL
	jz	10$				;normal modal, branch
	push	cx
	clr	cx				;else set zero flag and exit
	pop	cx
	jmp	short exit
10$:
	test	cl, mask OLPWF_APP_MODAL or mask OLPWF_SYS_MODAL ; modal?
exit:

else
	test	cl, mask OLPWF_APP_MODAL or mask OLPWF_SYS_MODAL ; modal?
endif
	ret
CheckDismissCloseCancel	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureReplyBar

DESCRIPTION:	Make sure reply bar exists for GenInteraction.

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLDialogWin object

RETURN:		^lcx:dx - reply bar

DESTROYED:	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@
EnsureReplyBar	proc	near
	uses	ax, bp, si
	.enter
	call	WinDialog_DerefVisSpec_DI
	mov	cx, ds:[di].OLDWI_replyBar.handle	; ^lcx:dx = reply bar
	mov	dx, ds:[di].OLDWI_replyBar.chunk
	tst	cx				; any reply bar?
	jnz	haveReplyBar			; yes
	;
	; no reply bar defined, create emtpy reply bar
	;
	push	si				; save OLDialogWin chunk
	mov	cx, ds:[LMBH_handle]		; destination block
	clr	bp				; NOT dirty
	mov	dx, si				; add to reply bar
        mov     di, segment GenInteractionClass
        mov     es, di
        mov     di, offset GenInteractionClass
	mov	al, -1				; init USABLE
	mov	ah, -1				; add using one-way link only
						; add this hint to object
	mov	bx, HINT_MAKE_REPLY_BAR or mask VDF_SAVE_TO_STATE
	call	OpenCreateChildObject
	mov	si, dx				; *ds:si is new object
	pop	dx				; ^lcx:dx = OLDialogWin
	xchg	dx, si				; ^lcx:dx = reply bar
						; *ds:si = OLDialogWin
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDialogWin instance
	mov	ds:[di].OLDWI_replyBar.handle, cx	; save new reply bar OD
	mov	ds:[di].OLDWI_replyBar.chunk, dx
	ornf	ds:[di].OLDWI_optFlags, mask OLDOF_REPLY_BAR_CREATED
	;
	; spec build new reply bar (with no triggers yet)
	; (must build unconditionally, if the OLDialogWin is spec-built, as the
	;  reply is not a generic child of of the GenIntearction, so will not
	;  get built in the normal fashion.  If OLDialogWin is not spec-built,
	;  we will be spec-built in OLDialogWin SPEC_BUILD_BRANCH handler.)
	;	*ds:si = OLDialogWin
	;	^lcx:dx = reply bar
	;
	call	VisCheckIfSpecBuilt		; carry set if OLDialogWin built
	jnc	haveReplyBar			; don't build yet
	push	cx, dx				; save reply bar optr
	mov	si, dx				; *ds:si = reply bar
						; 	(same block as win)
	clr	bp				; basic spec build
	call	VisSendSpecBuildBranch
	pop	cx, dx				; retrieve reply bar optr
haveReplyBar:
	.leave
	ret
EnsureReplyBar	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	AddStandardTriggerIfNeeded

DESCRIPTION:	Creates and add standard GenInteraction trigger to reply bar,
		if standard trigger doesn't already exist (i.e. provided by
		the application).

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLDialogWin object
		cx - InteractionCommand for standard trigger

RETURN:		nothing

DESTROYED:	bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		need to add?
		if (need to add) {
			which position?
			add ATTR_GEN_TRIGGER_INTERACTION_COMMAND
			HINT_DEFAULT_DEFAULT_ACTION?
			signalInteractionComplete?
			disable?
		}
		(moniker dealt with later)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@
AddStandardTriggerIfNeeded	proc	near
	uses	ax, si
	.enter
EC <	cmp	cx, InteractionCommand					>
EC <	ERROR_AE	OL_ERROR_ILLEGAL_INTERACTION_COMMAND		>
	call	FindStandardTriggerInfo		; carry set if found
	LONG jc	done				; already there, done
	;
	; Create and the desired standard trigger to the reply bar
	; (can be added to reply bar with full linkage as reply bar will
	;  be throw out at detach time)
	;	cx = InteractionCommand
	;
	push	si				; save  OLDialogWin chunk
	push	cx				; save InteractionCommand
	mov	bx, cx				; bx = InteractionCommand
	shl	bx, 1				; convert to word table offset
	mov	bx, cs:[addFlagsTable][bx]
	push	bx				; save add flags
	call	EnsureReplyBar			; cx:dx = trigger bar (created
						;	if needed)
	;
	; determine position for trigger
	;
	mov	bp, CCO_LAST			; assume last (not dirty)
	test	bx, mask ASTF_LAST		; add last?
	jnz	addLast				; yes
	mov	bp, CCO_FIRST			; else first (not dirty)
addLast:
        mov     di, segment GenTriggerClass
        mov     es, di
        mov     di, offset GenTriggerClass
	mov	bx, cx				; bx = reply bar block
	call	ObjSwapLock			; *ds:dx = reply bar
	push	bx				; bx = OLDialogWin block (save)
	mov	al, -1				; init USABLE
	clr	ah				; Full linkage OK, as reply
						; bar is contructed w/one-way
						; upward link only, & itself
						; will be tossed.
						; put in reply bar block (cx)
						; add this hint to object (bx)
	mov	bx, HINT_SEEK_REPLY_BAR or mask VDF_SAVE_TO_STATE
	call	OpenCreateChildObject		; ^lcx:dx = new trigger
	pop	bx				; bx = OLDialogWin block
	call	ObjSwapUnlock			; ds = OLDialogWin segment
						; bx = reply bar block
	mov	bx, cx				; ^lbx:si = new trigger
	mov	si, dx
	call	ObjSwapLock			; *ds:si = new trigger
						; bx = OLDialogWin block handle
	pop	di				; restore add flags
	pop	dx				; dx = InteractionCommand
	push	bx				; save OLDialogWin block handle
	;
	; add ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	;	*ds:si = new trigger
	;	dx = InteractionCommand
	;	di = add flags
	;
						; no save to state
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND or \
						mask VDF_SAVE_TO_STATE
	mov	cx, size word
	call	ObjVarAddData			; ds:bx = pointer to extra data
	mov	ds:[bx], dx			; save InteractionCommand
	push	dx
	;
	; check if trigger requires 'HINT_DEFAULT_DEFAULT_ACTION'
	;
	test	di, mask ASTF_HINT_DEFAULT	; need HINT_DEFAULT_DEFAULT_ACTION?
	jz	noHintDefault			; not needed
						; no save to state
	mov	ax, HINT_DEFAULT_DEFAULT_ACTION or mask VDF_SAVE_TO_STATE
	clr	cx				; no extra data
	call	ObjVarAddData			; else add HINT_DEFAULT_DEFAULT_ACTION
noHintDefault:
	;
	; check if trigger requires 'signalInteractionComplete'
	;	*ds:si = trigger
	;
	mov_tr	bx, di				; bx = add flags
	call	WinDialog_DerefGen_DI		; ds:di = GenTrigger
	test	bx, mask ASTF_SIGNAL_INTERACTION_COMPLETE
	jz	noSignalInteractionComplete	; not needed
						; set signalCompletesInteraction
	ornf	ds:[di].GI_attrs, mask GA_SIGNAL_INTERACTION_COMPLETE
noSignalInteractionComplete:
	;
	; check if trigger needs to be disabled
	;
	test	bx, mask ASTF_DISABLE
	jz	noDisable
	andnf	ds:[di].GI_states, not mask GS_ENABLED	; disable
noDisable:
	;
	; See if it needs to be expand to fit
	;
	test	bx, mask ASTF_EXPAND_TO_FIT	;expand to fit?
	jz	noExpand			;branch if not needed
	mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT or mask VDF_SAVE_TO_STATE
	clr	cx				;cx <- no extra data
	call	ObjVarAddData
noExpand:
	;
	; finish off by clearing dirty flag, so new trigger doesn't get saved
	; to state file
	;
	mov	ax, si				; *ds:ax = new trigger
	mov	bx, mask OCF_DIRTY shl 8	; clear dirty flag after setting
	call	ObjSetFlags			;	up instance data
	pop	dx				; restore InteractionCommand
	pop	bx				; restore OLDialogWin block
	call	ObjSwapUnlock			; unlock trigger block
	pop	si				; *ds:si = OLDialogWin
	;
	; add new standard trigger to our trigger list
	;	*ds:si = OLDialogWin
	;	^lbx:ax = new trigger
	;	dx = InteractionCommand
	;
	sub	sp, size NotifyOfInteractionCommandStruct
	mov	bp, sp
	mov	ss:[bp].NOICS_optr.handle, bx
	mov	ss:[bp].NOICS_optr.chunk, ax
	mov	ss:[bp].NOICS_ic, dx
	mov	ss:[bp].NOICS_flags, mask NOICF_TRIGGER_CREATED
	mov	dx, ss				; dx:bp = NOICS_*
	call	SaveStandardTriggerInfo
	add	sp, size NotifyOfInteractionCommandStruct
done:
	.leave
	ret
AddStandardTriggerIfNeeded	endp

;
; these tables must be in same order as InteractionCommand in
; Include/Objects/gInterC.def
;
AddStandardTriggerFlags	record
	ASTF_LAST:1,
	ASTF_HINT_DEFAULT:1,
	ASTF_SIGNAL_INTERACTION_COMPLETE:1,
	ASTF_DISABLE:1,
	ASTF_EXPAND_TO_FIT:1
	:11
AddStandardTriggerFlags	end

if _RUDY		;Don't disable apply here
addFlagsTable	AddStandardTriggerFlags \
	<0,0,0,0,0>,	; IC_NULL
	<1,0,0,0,0>,	; IC_DISMISS
	<0,0,0,0,0>,	; IC_INTERACTION_COMPLETE
	<0,1,0,0,0>,	; IC_APPLY
	<1,0,0,1,0>,	; IC_RESET
	<0,1,1,0,0>,	; IC_OK
	<0,0,1,0,0>,	; IC_YES
	<1,0,1,0,0>,	; IC_NO
	<0,0,1,0,0>,	; IC_STOP
	<0,0,0,0,0>,	; IC_EXIT
	<1,0,0,0,0>,	; IC_HELP
	<0,1,0,0,0>,	; IC_CHANGE
	<1,0,0,0,0>,	; IC_CANCEL_POPUP_LIST
	<0,0,1,0,0>,	; IC_NEXT
	<0,0,1,0,0>	; IC_PREVIOUS
CheckHack< (length addFlagsTable) eq (InteractionCommand) >
else
addFlagsTable	AddStandardTriggerFlags \
	<0,0,0,0,0>,	; IC_NULL
	<1,0,0,0,0>,	; IC_DISMISS
	<0,0,0,0,0>,	; IC_INTERACTION_COMPLETE
	<0,1,1,1,0>,	; IC_APPLY
	<1,0,0,1,0>,	; IC_RESET
	<0,1,1,0,0>,	; IC_OK
	<0,1,1,0,0>,	; IC_YES
	<1,0,1,0,0>,	; IC_NO
	<0,0,1,0,0>,	; IC_STOP
	<0,0,0,0,0>,	; IC_EXIT
	<1,0,0,0,1>,	; IC_HELP
	<0,0,0,0,0>,	; IC_INTERNAL_1
	<0,0,0,0,0>,	; IC_INTERNAL_2
	<0,0,1,0,0>,	; IC_NEXT
	<0,0,1,0,0>	; IC_PREVIOUS
CheckHack< (length addFlagsTable) eq (InteractionCommand) >
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinVisAddChild

DESCRIPTION:	We intercept this to ensure that our reply bar is always at
		the end.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLDialogWin)

		ax	= MSG_VIS_ADD_CHILD

		^lcx:dx	= child to add
		bp	= CompChildFlags

RETURN:		nothing
		cx, dx unchanged

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

OLDialogWinVisAddChild	method dynamic	OLDialogWinClass, MSG_VIS_ADD_CHILD
	push	cx, dx			; save child
	;
	; first add child normally
	;
	call	WinDialog_ObjCallSuperNoLock_OLDialogWinClass
					; preserves ^lcx:dx = child
	;
	; then force our reply bar to the end
	;	(reply optr is guaranteed to be stored before it is added)
	;
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDialogWin
	mov	cx, ds:[di].OLDWI_replyBar.handle	; ^lcx:dx = reply bar
	jcxz	noReplyBar				; no reply bar to fix
	mov	dx, ds:[di].OLDWI_replyBar.chunk
	call	MoveToEnd
noReplyBar:
	mov	dx, ds:[di].OLDWI_bottomArea
	tst	dx
	jz	done
	mov	cx, ds:[LMBH_handle]
	call	MoveToEnd
done:
	pop	cx, dx				; restore child
	ret

MoveToEnd:
	mov	ax, MSG_VIS_FIND_CHILD
	call	WinDialog_ObjCallInstanceNoLock	; ^lcx:dx preserved
	jc	noMove				; not added yet, nothing to fix
	mov	ax, MSG_VIS_MOVE_CHILD
	mov	bp, CCO_LAST			; make it the last one
	call	WinDialog_ObjCallInstanceNoLock
noMove:
	retn
OLDialogWinVisAddChild	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinNotifyOfInteractionCommand

DESCRIPTION:	notification of IC trigger

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLDialogWin)

		dx:bp = NotifyOfInteractionCommandStruct

RETURN:		none

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

OLDialogWinNotifyOfInteractionCommand	method dynamic	OLDialogWinClass,
				MSG_OL_WIN_NOTIFY_OF_INTERACTION_COMMAND
	push	es
	mov	es, dx
EC <	test	es:[bp].NOICS_flags, mask NOICF_TRIGGER_CREATED		>
EC <	ERROR_NZ	OL_ERROR					>
	test	es:[bp].NOICS_flags, mask NOICF_TRIGGER_DEMISE
	pop	es
	jnz	removeTriggerInfo
	call	SaveStandardTriggerInfo	; pass NotifyOfInteractionCommandStruct
done:
	ret

removeTriggerInfo:
	call	RemoveStandardTriggerInfo
	jmp	short done

OLDialogWinNotifyOfInteractionCommand	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinRebuildStandardTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rebuild standard triggers because reply is being rebuilt

CALLED BY:	MSG_OL_DIALOG_WIN_REBUILD_STANDARD_TRIGGERS

PASS:		*ds:si	= OLDialogWinClass object
		ds:di	= OLDialogWinClass instance data
		es 	= segment of OLDialogWinClass
		ax	= MSG_OL_DIALOG_WIN_REBUILD_STANDARD_TRIGGERS

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/8/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDialogWinRebuildStandardTriggers	method	dynamic	OLDialogWinClass,
				MSG_OL_DIALOG_WIN_REBUILD_STANDARD_TRIGGERS
	;
	; XXX: should not be disabled Apply Reset triggers, as
	; HandleDialogResponses does
	;
	call	HandleDialogResponses
	ret
OLDialogWinRebuildStandardTriggers	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinRaiseTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise tab

CALLED BY:	MSG_OL_DIALOG_WIN_RAISE_TAB
PASS:		*ds:si	= OLDialogWinClass object
		ds:di	= OLDialogWinClass instance data
		ds:bx	= OLDialogWinClass object (same as *ds:si)
		es 	= segment of OLDialogWinClass
		ax	= message #
		cx	= tab to raise to top (0..NUMBER_OF_TABBED_WINDOWS-1)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DIALOGS_WITH_FOLDER_TABS	;----------------------------------------------

OLDialogWinRaiseTab	method dynamic OLDialogWinClass, 
					MSG_OL_DIALOG_WIN_RAISE_TAB
	mov	ax, TEMP_OL_WIN_TAB_INFO
	call	ObjVarFindData
	jnc	done

	clr	dx			; assume top tab is child #0
	tst	ds:[bx].OLWFTS_tabPosition[0]
	jz	gotTopChild
	inc	dx			; assume top tab is child #1
	tst	ds:[bx].OLWFTS_tabPosition[2]
	jz	gotTopChild
	inc	dx			; top tab is child #2
gotTopChild:

	mov	di, cx
	shl	di, 1
	mov	ax, ds:[bx].OLWFTS_tabPosition[di]
EC <	tst	ax							>
EC <	ERROR_Z	-1							>

	cmp	ax, 1
	jne	raiseThirdTab

	xchg	di, dx
	shl	di, 1
	xchg	ds:[bx].OLWFTS_tabPosition[di], ax
	shr	di, 1
	xchg	di, dx
	mov	ds:[bx].OLWFTS_tabPosition[di], ax
	jmp	update

raiseThirdTab:
EC <	cmp	ax, 2							>
EC <	ERROR_NE -1							>

	inc	ds:[bx].OLWFTS_tabPosition[0]
	inc	ds:[bx].OLWFTS_tabPosition[2]
	inc	ds:[bx].OLWFTS_tabPosition[4]
	clr	ds:[bx].OLWFTS_tabPosition[di]

update:
	push	cx
	mov	cx, dx
	mov	di, MSG_GEN_SET_NOT_USABLE
	call	sendToChild
	pop	cx

	mov	di, MSG_GEN_SET_USABLE
	call	sendToChild

	mov	cl, mask OLWHS_TITLE_IMAGE_INVALID
	call	OpenWinHeaderMarkInvalid
done:
	ret


sendToChild:
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock
EC <	ERROR_C	-1			; say what!			>
NEC <	jc	10$							>

	push	si
	movdw	bxsi, cxdx
	mov	ax, di
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
10$:
	retn

OLDialogWinRaiseTab	endm

endif	; if DIALOGS_WITH_FOLDER_TABS -----------------------------------------

WinDialog	ends

;-------------------------------

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinDetermineVisParentForChild

DESCRIPTION:	We intercept this here to deal with OLGadgetArea.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLDialogWin)
		ax	= MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
		^lcx:dx	= child
		bp 	= SpecBuildFlags

RETURN:		carry set if something special found
		^lcx:dx = vis parent to use, or null if nothing found
		bp      = SpecBuildFlags
		ax	= destroyed

ALLOWED TO DESTROYED:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/29/92		initial version

------------------------------------------------------------------------------@

OLDialogWinDetermineVisParentForChild	method dynamic	OLDialogWinClass, 
					MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD

	;
	; Check for various window buttons, and let them be directly below
	; us.
	;
	cmp	cx, ds:[di].OLWI_titleBarLeftGroup.handle
	jne	notTitleBarLeft
	cmp	dx, ds:[di].OLWI_titleBarLeftGroup.chunk
	je	exitNoSpecialChild
notTitleBarLeft:
	cmp	cx, ds:[di].OLWI_titleBarRightGroup.handle
	jne	notTitleBarRight
	cmp	dx, ds:[di].OLWI_titleBarRightGroup.chunk
	je	exitNoSpecialChild
notTitleBarRight:

if not _OL_STYLE
	cmp	cx, ds:[di].OLWI_sysMenu
	jne	notWindowButton

if not _REDMOTIF ;----------------------- Not needed for Redwood project
	cmp	dx, offset SMI_MinimizeIcon
	je	exitNoSpecialChild
	cmp	dx, offset SMI_MaximizeIcon
	je	exitNoSpecialChild
	cmp	dx, offset SMI_RestoreIcon
	je	exitNoSpecialChild
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project
endif

notWindowButton:
	cmp	cx, ds:[LMBH_handle]
	jne	notBelowArea
	cmp	dx, ds:[di].OLDWI_bottomArea
	je	exitNoSpecialChild
notBelowArea:
	;
	; put the reply bar directly below us
	;
	cmp	cx, ds:[di].OLDWI_replyBar.handle
	jne	checkTitleGroup
	cmp	dx, ds:[di].OLDWI_replyBar.chunk
	je	exitNoSpecialChild

checkTitleGroup:
	;
	; If this object wants to be in the title bar, return
	; the appropriate title-bar group as the parent.
	;
	call	MaybeInTitleBar		; carry set if in the title bar
	jc	exit			; ^lcx:dx = parent

putUnderGadgetArea::
	mov	dx, ds:[di].OLDWI_gadgetArea
	tst	dx
	jz	exitDXAlreadyClear	; exit, carry clear
	mov	cx, ds:[LMBH_handle]	; return gadget area as vis parent
	stc				; vis parent found
	jmp	short exit

exitNoSpecialChild:
	clr	dx			; (will clear carry)
exitDXAlreadyClear:
EC <	ERROR_C	ASSERTION_FAILED					>
	mov	cx, dx			; return null parent
exit:
	ret
OLDialogWinDetermineVisParentForChild	endm

WinClasses	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinTestInputRestrictability

DESCRIPTION:	

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLDialogWin)
		ax	= MSG_GEN_INTERACTION_TEST_INPUT_RESTRICTABILITY
		^lcx:dx	= child

RETURN:		carry set to override input flow restrictions

ALLOWED TO DESTROYED:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/24/92		initial version

------------------------------------------------------------------------------@

OLDialogWinTestInputRestrictability	method dynamic	OLDialogWinClass, 
				MSG_GEN_INTERACTION_TEST_INPUT_RESTRICTABILITY
	; Test to see if this is a modal window or not.  If not, then 
	; allow flow restrictions, as the ability to override such restrictions
	; is limited to modal dialogs, which the app is aware of coming &
	; going & so can query us.  Which raises an excellent question -- how
	; the heck could this message get here if we weren't modal?  We'll
	; deal with it anyway, just in case someone does something silly
	; like raise the prio of a non-modal window to WIN_PRIO_MODAL.
	;
if ALL_DIALOGS_ARE_MODAL
	;
	; RedMotif, all dialogs are forced "modal" for keyboard-only.  If
	; this is the case, we'll treat these originally-non-modal
	; dialog boxes as accepting input restrictions, so the apps will
	; continue to function properly.   2/26/94 cbh
	;
	test	ds:[di].OLPWI_flags, mask OLPWF_FORCED_MODAL 
	jnz	allowRestrictions
endif

	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
						mask OLPWF_SYS_MODAL
	jz	allowRestrictions

	; Check to see if developer has made specific request for override
	;
	mov	ax, ATTR_GEN_INTERACTION_OVERRIDE_INPUT_RESTRICTIONS
	call	ObjVarFindData
	jc	done			; if so, go for it.

	; Check to see if developer wants the opposite
	;
	mov	ax, ATTR_GEN_INTERACTION_ABIDE_BY_INPUT_RESTRICTIONS
	call	ObjVarFindData
	jc	allowRestrictions	; oblige that request as well.

	; OK, no specific requests, use default behavior:  If initiated via
	; user do dialog, let everything flow, or we could easily end up
	; locking out the user.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GII_attrs, mask GIA_INITIATED_VIA_USER_DO_DIALOG
	jnz	overrideRestrictions

	; Barring that, go by GenInteractionType defaults
	;
	mov	bl, ds:[di].GII_type
	clr	bh
	tst	cs:[bx].dialogOverrideInputRestrictionsTable
	jz	allowRestrictions

overrideRestrictions:
	stc
	jmp	short done

allowRestrictions:
	clc
done:
	ret
OLDialogWinTestInputRestrictability	endm

;
; change -- allow any kind of modal window to override input restrictions
; - brianc 12/11/92
;
if 0
dialogOverrideInputRestrictionsTable	byte \
	0,	; GIT_ORGANIZATIONAL
	0,	; GIT_PROPERTIES
	1,	; GIT_PROGRESS
	0,	; GIT_COMMAND
	1,	; GIT_NOTIFICATION
	1,	; GIT_AFFIRMATION
	1	; GIT_MULTIPLE_RESPONSE
else
dialogOverrideInputRestrictionsTable	byte \
	1,	; GIT_ORGANIZATIONAL
	1,	; GIT_PROPERTIES
	1,	; GIT_PROGRESS
	1,	; GIT_COMMAND
	1,	; GIT_NOTIFICATION
	1,	; GIT_AFFIRMATION
	1	; GIT_MULTIPLE_RESPONSE
endif

WinMethods	ends

;-------------------------------

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinSpecGetVisParent

DESCRIPTION:	We intercept this here to see if we should deal with
		ATTR_GEN_INTERACTION_ON_TOP_OF_APPLICATION,
		ATTR_GEN_INTERACTION_ON_TOP_OF_FIELD, or
		ATTR_GEN_INTERACTION_ON_TOP_OF_SCREEN.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLDialogWin)
		bp	= SpecBuildFlags
				mask SBF_WIN_GROUP - set if building win group

RETURN:		carry set
		cx:dx = vis parent to use
		bp = SpecBuildFlags

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		initial version

------------------------------------------------------------------------------@

OLDialogWinSpecGetVisParent	method dynamic	OLDialogWinClass, 
							MSG_SPEC_GET_VIS_PARENT

	test	bp, mask SBF_WIN_GROUP		; building win group?
	jz	callSuper			; nope, let superclass handle
	;
	; building win group, check if DUAL_BUILD?
	;
	test	ds:[di].VI_specAttrs, mask SA_USES_DUAL_BUILD
	jz	callSuper			; nope, let superclass handle
	;
	; Check to see if ATTR_GEN_CUSTOM_WINDOW_PARENT(0) passed indicating
	; that this window should appear on the screen window.  If so, return
	; the screen object as the visual parent.
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
	call	ObjVarFindData
	jnc	callSuper
	tst	<{WinPriority} ds:[bx]>		; If anything else, just
						; use the default vis parent
						; (Though window will be placed
						; on this window handle later
						; when opened)
	jnz	callSuper

	mov	cx, SQT_VIS_PARENT_FOR_SYS_MODAL
	mov	ax, MSG_SPEC_GUP_QUERY_VIS_PARENT
	call	GenCallParent
EC <	ERROR_NC	OL_WINDOWED_GEN_OBJECT_NOT_IN_GEN_TREE		>
	ret

callSuper:
	mov	ax, MSG_SPEC_GET_VIS_PARENT
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
	ret
OLDialogWinSpecGetVisParent	endm

WinClasses	ends

;-----------------------------------------------------------------------------

WinDialog	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	SaveStandardTriggerInfo

DESCRIPTION:	Save information about this standard trigger in our
		standard trigger list.

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLDialogWin object
		dx:bp - NotifyOfInteractionCommandStruct with information
				about standard trigger

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@
SaveStandardTriggerInfo	proc	near
	uses	si, es
	.enter
	;
	; check if we already have this trigger saved -- this will happen for
	; triggers that we create, we save it once in AddStandardTriggerIfNeeded
	; and again when they are built (saved via MSG_VIS_VUP_QUERY)
	;
	push	bp				; save NOICS_* offset
	mov	es, dx				; es:bx = NOICS_*
	mov	bx, bp
	mov	cx, es:[bx].NOICS_ic		; cx = InteractionCommand
	call	FindStandardTriggerInfo		; ^ldx:bp = trigger, if any
EC <	mov	ax, bp				; ^ldx:ax = trigger	>
	pop	bp				; restore NOICS_* offset
NEC <	jc	done				; already saved		>
EC <	jnc	saveInfo			; not saved yet, save	>
EC <	cmp	dx, es:[bx].NOICS_optr.handle	; is it this one?	>
EC <	ERROR_NE	OL_ERROR_CANT_HAVE_DUPLICATE_STANDARD_TRIGGERS	>
EC <	cmp	ax, es:[bx].NOICS_optr.chunk				>
EC <	ERROR_NE	OL_ERROR_CANT_HAVE_DUPLICATE_STANDARD_TRIGGERS	>
EC <	jmp	short done						>
EC <saveInfo:								>
	;
	; not saved yet, proceed to save
	;

if _PM	;-----------------------------------------------------------------
	; If trigger is IC_DISMISS, then make dialog closable
	cmp	cx, IC_DISMISS
	jne	afterICDismiss
	call	WinDialog_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
afterICDismiss:
endif	;-----------------------------------------------------------------

	push	bp				; save NOICS_* offset
	mov	bp, si				; bp = OLDialogWin chunk
	call	WinDialog_DerefVisSpec_DI	; ds:di = instance
	mov	si, ds:[di].OLDWI_triggerList
	tst	si				; do we have a list yet?
	jnz	haveList
	mov	al, mask OCF_IGNORE_DIRTY	; don't save to state...
	mov	bx, size NotifyOfInteractionCommandStruct	; element size
	clr	cx				; no special header info
	mov	si, cx
	call	ChunkArrayCreate		; *ds:si = chunk array
	xchg	bp, si				; *ds:si = OLDialogWin
						; *ds:bp = chunk array
	call	WinDialog_DerefVisSpec_DI	; ds:di = instance
	mov	ds:[di].OLDWI_triggerList, bp	; save list chunk
	xchg	si, bp				; *ds:si = chunk array
						; *ds:bp = OLDialogWin
haveList:
						; not variable sized (ax = X)
	call	ChunkArrayAppend		; ds:di = new element
	pop	si				; get NOICS_* offset

	push	ds, si				; save updated ds
	segmov	es, ds				; es:di = new element
	mov	ds, dx				; ds:si = new NOICS_* info
	mov	cx, size NotifyOfInteractionCommandStruct
	rep	movsb
	pop	ds, si				; restore update ds

	xchg	si, bp				; *ds:si <- OLDialogWin
						; ds:bp <- NOICS_*
	mov_tr	ax, dx
	call	WinDialog_DerefVisSpec_DI	; ds:di = instance data
	mov	cl, ds:[di].OLPWI_flags
	mov	dl, ds:[di].OLDWI_optFlags

	;
	; Set ES to a fixed segment or else die when ec segment is turned on.
	; 
EC <	segmov	es, ss						>	
	
	push	ds:[LMBH_handle]
	mov	ds, ax
	mov	di, bp				; ds:di = NOICS_*
	call	EnsureStandardTriggerMonikerCallback
	pop	bx
	call	MemDerefDS
done:
	.leave
	ret
SaveStandardTriggerInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	RemoveStandardTriggerInfo

DESCRIPTION:	Remove information about this standard trigger in our
		standard trigger list.

CALLED BY:	INTERNAL
			OLDialogWinVupQuery (trigger being unbuild)

PASS:		*ds:si	- OLDialogWin object
		dx:bp - NotifyOfInteractionCommandStruct with information
				about standard trigger

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@
RemoveStandardTriggerInfo	proc	near
	uses	si, es
	.enter
	;
	; check if we already have this trigger saved -- this will happen for
	; triggers that we create, we save it once in AddStandardTriggerIfNeeded
	; and again when they are built (saved via MSG_VIS_VUP_QUERY)
	;
	mov	es, dx				; es:bx = NOICS_*
	mov	bx, bp
EC <	test	es:[bx].NOICS_flags, mask NOICF_TRIGGER_DEMISE		>
EC <	ERROR_Z	OL_ERROR						>
	mov	cx, es:[bx].NOICS_ic		; cx = InteractionCommand
	call	FindStandardTriggerEntry	; ds:bp = trigger entry, if any
	jnc	done				; not found, just boogie
	;
	; found trigger entry, proceed to remove it
	;	*ds:si = OLDialogWin
	;	ds:bp = trigger entry
	;	es:bx = NotifyOfInteractionCommandStruct
	;

if _PM	; If trigger is IC_DISMISS, then make dialog not closable --------
	cmp	cx, IC_DISMISS
	jne	afterICDismiss
	call	WinDialog_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_CLOSABLE
afterICDismiss:
endif	;-----------------------------------------------------------------

	mov	ax, es:[bx].NOICS_optr.handle	; let's make sure we've got
	cmp	ax, ds:[bp].NOICS_optr.handle	;	the right one
	jne	done
	mov	ax, es:[bx].NOICS_optr.chunk
	cmp	ax, ds:[bp].NOICS_optr.chunk
	jne	done
	call	WinDialog_DerefVisSpec_DI	; ds:di = instance
	mov	si, ds:[di].OLDWI_triggerList
	tst	si				; do we have a list yet?
	jz	done				; if not, just bail
	mov	di, bp				; ds:di = element to remove
	call	ChunkArrayDelete
done:
	.leave
	ret
RemoveStandardTriggerInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindStandardTriggerInfo

DESCRIPTION:	Find information about this standard trigger in our
		standard trigger list.

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLDialogWin object
		cx - InteractionCommand

RETURN:		carry set if found
		dx:bp - standard trigger optr

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@
if _JEDIMOTIF or _ODIE
FindStandardTriggerInfo	proc	far
else
FindStandardTriggerInfo	proc	near
endif
	call	FindStandardTriggerEntry
	jnc	done				; if not found, carry clear
						; else, ds:bp = NOICS_*
	mov	dx, ds:[bp].NOICS_optr.handle	; return dx:bp = trigger otpr
	mov	bp, ds:[bp].NOICS_optr.chunk
done:
	ret
FindStandardTriggerInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindStandardTriggerEntry

DESCRIPTION:	Find information about this standard trigger in our
		standard trigger list.

CALLED BY:	INTERNAL
			RemoveStandardTriggerInfo
			FindStandardTriggerInfo

PASS:		*ds:si	- OLDialogWin object
		cx - InteractionCommand

RETURN:		carry set if found
		ds:bp - NOICS_* entry for standard trigger

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/92		Initial version

------------------------------------------------------------------------------@
FindStandardTriggerEntry	proc	near
	uses	bx, si, di
	.enter
	call	WinDialog_DerefVisSpec_DI	; ds:di = instance
	mov	si, ds:[di].OLDWI_triggerList
	tst	si				; do we have a list yet?
	jz	done				; nope, carry clear -- not found
	mov	bx, cs
	mov	di, offset FindStandardTriggerCallback
	call	ChunkArrayEnum			; if not found, carry clear
						; else, ds:bp = NOICS_*
done:
	.leave
	ret
FindStandardTriggerEntry	endp

;
; pass:
;	ds:di = element (NotifyOfInteractionCommandStruct)
;	cx = InteractionCommand being searched for
; return:
;	ds:bp = this element
;	carry set if match (stops enumeration)
;
FindStandardTriggerCallback	proc	far
	mov	bp, di				; in case this is the element
	cmp	cx, ds:[di].NOICS_ic
	stc					; assume found -- stop enum
	je	found				; yes, found
	clc					; else, return carry clear
found:
	ret
FindStandardTriggerCallback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinFindStandardTrigger

DESCRIPTION:	Find standard trigger

PASS:		*ds:si	= instance data for object
		cx	= InteractionCommand of standard trigger to find

RETURN:		carry set if standard trigger found
			^ldx:bp = standard trigger
		carry clear otherwise

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		initial version

------------------------------------------------------------------------------@

OLDialogWinFindStandardTrigger	method dynamic	OLDialogWinClass, \
					MSG_OL_DIALOG_WIN_FIND_STANDARD_TRIGGER
	call	FindStandardTriggerInfo
	ret
OLDialogWinFindStandardTrigger	endm


if	AUTOMATICALLY_IMBED_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateKeyboardObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a keyboard object for the dialog

CALLED BY:	GLOBAL
PASS:		*ds:si - OLDialogWin
RETURN:		^lcx:dx - kbd object
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateKeyboardObject	proc	near
	.enter

	call	WinDialog_DerefVisSpec_DI
	ornf	ds:[di].OLDWI_optFlags, mask OLDOF_KBD_CREATED

;	Create a floating keyboard to display, and store the OD in vardata

	mov	dx, si
	mov	di, segment GenPenInputControlClass
	mov	es, di
	mov	di, offset GenPenInputControlClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate		;^lBX:SI <- GenPenInputControl object
					;^lBX:DX <- GenApplication object
;	We don't need/want to load any options, so add this flag so we don't
;	bother.

	mov	ax, TEMP_GEN_CONTROL_OPTIONS_LOADED
	clr	cx
	call	ObjVarAddData

	xchg	dx, si

;	Store the OD of the object in our vardata

	mov	ax, ATTR_GEN_INTERACTION_PEN_MODE_KEYBOARD_OBJECT
	mov	cx, size optr
	call	ObjVarAddData
	mov	cx, ds:[LMBH_handle]	;^lCX:DX <- GenPenInputControl object
	movdw	ds:[bx], cxdx
	.leave
	ret
CreateKeyboardObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureBottomArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a "bottom area" for the dialog (an area below the
		reply bar that holds goodies like pen-input controllers).

CALLED BY:	GLOBAL
PASS:		*ds:si - OLDialogWin object
RETURN:		*ds:si - bottom area GenInteraction
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureBottomArea	proc	near
	.enter
	call	WinDialog_DerefVisSpec_DI
	mov	di, ds:[di].OLDWI_bottomArea
	tst	di
	jz	create
	mov	si, di
	.leave
	ret
create:

;	Create a gen interaction to hold all this junk

	push	ax, bx, cx, dx, bp, es

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	mov	al, -1				;init USABLE
	mov	ah, -1				;make one-way upward link to
						; parent, so we don't have to
						; nuke it when exiting to state
	mov	bx, HINT_CENTER_CHILDREN_HORIZONTALLY or mask VDF_SAVE_TO_STATE
	mov	bp, CCO_LAST
	call	OpenCreateChildObject
	call	WinDialog_DerefVisSpec_DI
	mov	ds:[di].OLDWI_bottomArea, dx

;	When the window gets spec built



	call	VisCheckIfSpecBuilt		;If window was spec built,
	pushf					; build the bottom area too.
	mov	si, dx				
	mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData	
	popf	
	jnc	exit				;Branch if parent window not
						; spec build (the bottomArea
						; will be built manually in 
						; OLDialogWinUpdateSpecBuild).
						
	clr	bp
	call	VisSendSpecBuildBranch
exit:
	pop	ax, bx, cx, dx, bp, es
	ret
EnsureBottomArea	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinGupQuery

DESCRIPTION:	We intercept generic-upward queries here to see if we
		can answer them.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLDialogWin)
		cx	= SpecGenQueryType

		if cx = SGQT_BUILD_INFO
			bp = OLBuildFlags

RETURN:		carry set if answered query
			(SGQT_BUILD_INFO and OLBT_FOR_REPLY_BAR)
				cx:dx = reply bar
				bp - OLBuildFlags updated
		carry clear if not answered

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		if (SGQT_BUILD_INFO) {
		    if (OLBT_FOR_REPLY_BAR) {
			return(OLDWI_replyBar)
		    }
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

OLDialogWinGupQuery	method dynamic	OLDialogWinClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO
	jne	notBuildInfo

	;
	; Don't force menuable objects to be a direct child of the dialog.
	;
if	not _RUDY
	test	bp, mask OLBF_MENUABLE
	jnz	handleMenu
endif

	mov	bx, bp
	andnf	bx, mask OLBF_TARGET
	cmp	bx, OLBT_FOR_REPLY_BAR shl offset OLBF_TARGET
	jne	callSuperIfNotMenu
	;
	; return reply bar as visual parent of object with OLBT_FOR_REPLY_BAR
	;
	call	EnsureReplyBar			; ^lcx:dx = reply bar
						; (only bx, di trashed)
	jcxz	callSuperIfNotMenu		; no reply bar
	ornf	bp, OLBR_REPLY_BAR shl offset OLBF_REPLY
queryAnswered:
	stc					; else, query answered
	ret

handleMenu:
	ornf	bp, OLBR_TOP_MENU shl offset OLBF_REPLY
	clr	cx				;return NULL
						;so that GenParent will
						;be used as visParent
	jmp	queryAnswered


notBuildInfo:
if 	AUTOMATICALLY_IMBED_KEYBOARD
	cmp	cx, SGQT_BRING_UP_KEYBOARD
	jne	callSuper

	call	WinDialog_DerefVisSpec_DI
	test	ds:[di].OLDWI_optFlags, mask OLDOF_KBD_ADDED
	jnz	queryAnswered
	ornf	ds:[di].OLDWI_optFlags, mask OLDOF_KBD_ADDED

;	Set the floating keyboard object usable so it will appear.

	mov	ax, ATTR_GEN_INTERACTION_PEN_MODE_KEYBOARD_OBJECT
	call	ObjVarFindData
	jnc	create

	mov	dx, ds:[bx].chunk	;NOTE: The OD here could be 0, which
	mov	cx, ds:[bx].handle	; allows the app to specify that the
					; dialog should get no keyboard, or
					; if the object was created by the
					; UI itself, it is already usable, 
					; so no message need be sent.
	jcxz	queryAnswered		; if it is zero, we've done!

addObject:
	call	EnsureBottomArea	;Returns *ds:si - bottom area
	
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	call	WinDialog_ObjCallInstanceNoLock

	movdw	bxsi, cxdx

;	Add the object to the bottom area and set it usable.

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	queryAnswered
create:
	call	CreateKeyboardObject
	jmp	addObject
endif	;AUTOMATICALLY_IMBED_KEYBOARD

callSuperIfNotMenu:

if _RUDY
	;
	; Don't force menuable objects to be a direct child of the dialog.
	;
	test	bp, mask OLBF_MENUABLE
	jnz	handleMenu
endif

callSuper:
	mov	di, offset OLDialogWinClass
	GOTO	ObjCallSuperNoLock

OLDialogWinGupQuery	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinNotifyOfReplyBar

DESCRIPTION:	

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLDialogWin)

		cx:dx = reply bar optr

RETURN:		carry set
		cx:dx = reply bar
		bp - OLBuildFlags updated

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Pulled out from Gup Query

------------------------------------------------------------------------------@

OLDialogWinNotifyOfReplyBar	method dynamic	OLDialogWinClass,
						MSG_OL_WIN_NOTIFY_OF_REPLY_BAR
	;
	; Reply may be saved twice, once when we create it in EnsureReplyBar,
	; and again when it is initialized.
	;
EC <	tstdw	cxdx							>
EC <	jz	store							>
EC <	tst	ds:[di].OLDWI_replyBar.handle				>
EC <	jz	store							>
EC <	cmpdw	ds:[di].OLDWI_replyBar, cxdx				>
EC <	ERROR_NE	OL_ERROR_CANT_HAVE_MULTIPLE_REPLY_BARS		>
EC <store:								>
	movdw	ds:[di].OLDWI_replyBar, cxdx
	jcxz	clearing			; that's all, if just clearing
	;
	; then notify the reply bar of our status
	;	*ds:si = OLDialogWin
	;	^lcx:dx = reply bar
	;
	mov	bx, cx
	push	dx
	mov	cx, ds:[LMBH_handle]		; ^cx:dx = this OLDialogWin
	mov	dx, si
	pop	si				; ^lbx:si = reply bar
	mov	ax, MSG_OL_REPLY_BAR_SET_DIALOG
	call	WinDialog_ObjMessageCallFixupDS
done:
	stc					; else, query answered
	ret
clearing:
	andnf	ds:[di].OLDWI_optFlags, not mask OLDOF_REPLY_BAR_CREATED
	jmp	done


OLDialogWinNotifyOfReplyBar	endm

WinDialog	ends

;------------------------------------------------------------------------------

WinClasses	segment resource

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinSpecUnbuildBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unbuilds the branch.

CALLED BY:	GLOBAL
PASS:		bp - SpecBuildFlags
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDialogWinSpecUnbuildBranch	method	OLDialogWinClass, 
				MSG_SPEC_UNBUILD_BRANCH
	push	ax, bp
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
	pop	ax, bp
	test	bp, mask SBF_WIN_GROUP
	jz	exit
	
	call	WinClasses_DerefVisSpec_DI
	mov	si, ds:[di].OLDWI_bottomArea
	tst	si
	jz	exit

	call	WinClasses_ObjCallInstanceNoLock
exit:
	ret
OLDialogWinSpecUnbuildBranch	endm
endif

COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinSpecUnbuild

DESCRIPTION:	Remove the reply bar, if we created it; remove any
		standard triggers we created; free standard trigger
		list

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_SPEC_UNBUILD

	cx, dx, - ?
	bp	- SpecBuildFlags

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@

OLDialogWinSpecUnbuild	method dynamic	OLDialogWinClass, MSG_SPEC_UNBUILD
	;
	; When we get MSG_SPEC_UNBUILD, default handler for
	; MSG_SPEC_UNBUILD_BRANCH has already torn apart the visual tree that
	; contained the reply bar and response triggers.  We'll access these
	; things from our stored otprs.
	;
	test	bp, mask SBF_WIN_GROUP
	LONG jz	afterWinGroup

	;
	; We are no longer built, so clear out this flag
	;
	call	WinClasses_DerefVisSpec_DI	; ds:di = OLDWI_*
	andnf	ds:[di].OLDWI_optFlags, not mask OLDOF_BUILT

	;
	; We're unbuilding the win group, therefore we must do several things
	; in addition to the default handling:
	;
	push	bp				; save build flags
	;
	;	1) Free any created standard triggers
	;
	push	si				; save OLDialogWin chunk

	mov	si, ds:[di].OLDWI_triggerList	; *ds:si = trigger list
						; DON'T CLEAR HERE, cleared
						;	later
	tst	si
	jz	noTriggers
	call	UnbuildTriggers			; in WinDialog resource
						; (not always used)
noTriggers:
	pop	si				; restore OLDialogWin chunk
	;
	;	2) Remove reply bar, if we created it
	;
	;	It is okay to use GEN_DESTROY here because if we created the
	;	reply bar, the application can't have any generic children
	;	attached to it.  Any generic children of the reply bar are
	;	standard triggers that we've added to it.  These have been
	;	destroyed above.
	;
	;	1/5/93: always clear out OLDWI_replyBar, to deal with case
	;	where reply bar is in generic tree below the dialog and gets
	;	biffed through some other mechanism (e.g. the Search/Replace
	;	controller has a reply bar in its generated UI, and that UI
	;	goes away independent of what we do here...) -- ardeb
	;
	call	WinClasses_DerefVisSpec_DI	; ds:di = OLDWI_*
	push	si				; save OLDialogWin chunk
	clr	bx, si
	xchg	bx, ds:[di].OLDWI_replyBar.handle
	xchg	si, ds:[di].OLDWI_replyBar.chunk

	test	ds:[di].OLDWI_optFlags, mask OLDOF_REPLY_BAR_CREATED
	jz	noReplyBar
	andnf	ds:[di].OLDWI_optFlags, not mask OLDOF_REPLY_BAR_CREATED
	mov	ax, MSG_GEN_DESTROY		; else, destroy reply bar
	mov	dl, VUM_NOW
	clr	bp
	call	WinClasses_ObjMessageCallFixupDS
noReplyBar:
	pop	si				; restore OLDialogWin chunk
	;
	;	3) Destroy standard trigger list chunk
	;
	call	WinClasses_DerefVisSpec_DI	; ds:di = OLDWI_*
	clr	ax
	xchg	ax, ds:[di].OLDWI_triggerList	; clear in case we access it
	tst	ax
	jz	noTriggerList
	call	LMemFree			; free chunk
noTriggerList:
	;
	;	4) Clear reference to OLGadgetArea as superclass will
	;		have destroyed it in MSG_SPEC_UNBUILD_BRANCH.
	;
	clr	ax
	mov	ds:[di].OLDWI_gadgetArea, ax

	pop	bp				; restore build flags

	;	Unbuild the "bottomArea", if one exists, and nuke any
	;	goodies that lie in it, like the PenInputControl. We have
	;	to unbuild the bottomArea, because otherwise any keyboard
	;	objects will never get SPEC_UNBUILD messages, because they 
	;	aren't really gen children of the dialog (they have a one-way
	;	link).

	tst	ds:[di].OLDWI_bottomArea
	jz	noBottomArea

	push	bp

	push	si
	mov	si, ds:[di].OLDWI_bottomArea
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	call	WinClasses_ObjCallInstanceNoLock
	pop	si

if	AUTOMATICALLY_IMBED_KEYBOARD
	;
	;	5) Nuke pen input control, if we created it
	;

	call	NukeKbdObj
endif	;AUTOMATICALLY_IMBED_KEYBOARD

	;
	;	6) Clear out the reference/destroy the "bottom area"
	;

	push	si
	call	WinClasses_DerefVisSpec_DI
	clr	si
	xchg	si, ds:[di].OLDWI_bottomArea

;	Should have no children here...

if 	ERROR_CHECK
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	WinClasses_ObjCallInstanceNoLock
	tst	dx
	ERROR_NZ	OL_ERROR
endif
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	clr	bp
	call	WinClasses_ObjCallInstanceNoLock
	pop	si
	pop	bp

noBottomArea:
	
	;
	;	Finish up w/having superclass unbuild this object itself
	;

afterWinGroup:
	mov	ax, MSG_SPEC_UNBUILD		; pass method on to superclass
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
	ret
OLDialogWinSpecUnbuild	endm

WinClasses	ends

;------------------------------------------------------------------------------

WinDialog	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	UnbuildTriggers

DESCRIPTION:	remove any standard triggers we created

PASS:
	*ds:si - trigger list

RETURN:
	nothing

DESTROYED:
	bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@

UnbuildTriggers	proc	far
	mov	bx, cs
	mov	di, offset FreeStandardTriggerMonikerCallback
	call	ChunkArrayEnum
	ret
UnbuildTriggers	endp

;
; pass:
;	*ds:si = trigger list
;	ds:di = element (NotifyOfInteractionCommandStruct)
; return:
;	carry clear to continue enumeration
; destroyed:
;	ax, cx, dx, bx, si, di, bp
;
FreeStandardTriggerMonikerCallback	proc	far
	test	ds:[di].NOICS_flags, mask NOICF_TRIGGER_CREATED
	jz	done				; we didn't create trigger, done
	mov	bx, ds:[di].NOICS_optr.handle
	mov	si, ds:[di].NOICS_optr.chunk
	mov	ax, MSG_GEN_DESTROY		; else, destroy the trigger
	mov	dl, VUM_NOW
	clr	bp
	call	WinDialog_ObjMessageCallFixupDS
done:
	clc					; continue enumeration
	ret
FreeStandardTriggerMonikerCallback	endp

WinDialog	ends

;------------------------------------------------------------------------------

WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinNotifyEnabled, OLDialogWinNotifyNotEnabled --
		MSG_SPEC_NOTIFY_ENABLED, MSG_SPEC_NOTIFY_NOT_ENABLED handler
		for OLDialogWinClass

DESCRIPTION:	Handle enabling and disabling

PASS:		*ds:si	= instance data for object
		ds:di	= OLDialogWin instance

		ax	= MSG_SPEC_NOTIFY_ENABLED
			  MSG_SPEC_NOTIFY_NOT_ENABLED
		dl	= update flags
		dh	= NotifyEnabledFlags

RETURN:		carry set to indicate visual state changed

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		initial version

------------------------------------------------------------------------------@

OLDialogWinNotifyEnabled	method	dynamic OLDialogWinClass,
							MSG_SPEC_NOTIFY_ENABLED
	mov	cx, MSG_GEN_NOTIFY_ENABLED
	GOTO	OLDWNotifyCommon
OLDialogWinNotifyEnabled	endm

OLDialogWinNotifyNotEnabled	method	dynamic OLDialogWinClass,
						MSG_SPEC_NOTIFY_NOT_ENABLED
	mov	cx, MSG_GEN_NOTIFY_NOT_ENABLED
	FALL_THRU	OLDWNotifyCommon
OLDialogWinNotifyNotEnabled	endm

OLDWNotifyCommon	proc	far
	push	ax, cx, dx		; save method data
	call	WinClasses_ObjCallSuperNoLock_OLDialogWinClass
	pop	ax, cx, dx		; retrieve method data
	;
	; State changed.  We need to disable the reply bar/bottom area.
	; This is connected to the OLDialogWin via one-way links, but we have
	; its OD in our instance data.  The response triggers in the reply
	; bar are either generic children of the dialog (if application-
	; supplied) or generic children of the reply bar (if we added them),
	; so they will get disable/enabled via the normal mechanisms.
	;
	and	dh, not mask NEF_STATE_CHANGING
	push	ax				; save SPECIFIC msg for gadget
						;	area
	mov	ax, cx			; send generic enable/not-enable method
					; (reply bar is generic object)
	push	ax, dx, si				; save flags, etc.
	call	WinClasses_DerefVisSpec_DI	; ds:di = OLDWI_*
	movdw	bxsi, ds:[di].OLDWI_replyBar
	tst	si
	jz	afterReplyBar
	call	WinClasses_ObjMessageCallFixupDS
afterReplyBar:
	pop	ax, dx, si
	call 	WinClasses_DerefVisSpec_DI
	tst	ds:[di].OLDWI_bottomArea
	jz	noBottomArea
	push	dx, si
	mov	si, ds:[di].OLDWI_bottomArea
	call	WinClasses_ObjCallInstanceNoLock
	pop	dx, si
noBottomArea:
	pop	ax				; retreive SPECIFIC msg for
						;	gadget area
	call	WinClasses_DerefVisSpec_DI	; ds:di = OLDWI_*
	mov	si, ds:[di].OLDWI_gadgetArea
	tst	si
	jz	done
	call	WinClasses_ObjCallInstanceNoLock
done:
	stc				; indicate something changed
	ret
OLDWNotifyCommon	endp

WinClasses	ends

;------------------------------------------------------------------------------

WinDialog	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinGenApply -- MSG_GEN_APPLY handler for
		OLDialogWinClass

DESCRIPTION:	Handle applying properties.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLDialogWinGenApply	method	dynamic OLDialogWinClass, MSG_GEN_APPLY

if _RUDY
	call	HandleBubbleApply		;special apply for bubbles
endif

	;
	; first call superclass to send APPLY to gadgets
	;
	call	WinDialog_ObjCallSuperNoLock_OLDialogWinClass


	; New! After user clicks on apply, transfer focus back to the primary
	; window.  This seems to be the behavior that everyone would like to
	; see.	-- Doug
	; {

	;
	; If in keyboard-only mode, we don't want to do this because the user
	; will be stuck with the properties dialog.
	;
	call	OpenCheckIfKeyboardOnly	; carry set if so
	jc	afterFocus

	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	WinDialog_ObjCallInstanceNoLock

	; Give focus to next best window (will usually turn out to be the
	; current target window)
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	GenCallApplication
afterFocus:
	; }

if _RUDY
	;
	; Dismiss the window AFTER activating the focus.
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
else
	mov	ax, MSG_OL_MAKE_NOT_APPLYABLE
endif
	call	WinDialog_ObjCallInstanceNoLock
					; Window settings no longer applyable
	ret
OLDialogWinGenApply	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleBubbleApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special apply handling for bubbles (GIV_POPUPs)

CALLED BY:	OLDialogWinGenApply

PASS:		*ds:si = object instance data

RETURN:		nothing

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 8/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

HandleBubbleApply	proc	near		uses	ax, si
	class	GenInteractionClass
	.enter
	Assert	objectPtr dssi GenInteractionClass
	;
	; If we're a popup list, send a special apply down the vis linkage
	; to find the item group.
	;
	mov	ax, HINT_IS_POPUP_LIST
	call	ObjVarFindData
	jnc	activateFocus
	mov	ax, MSG_SPEC_POPUP_LIST_APPLY
	call	VisSendToChildren	
	jmp	short exit

activateFocus:
	;
	; If we're an organizational popup (i.e. a menu), activate the
	; focus.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_type, GIT_ORGANIZATIONAL
	jne	exit
	call	ActivateBubbleFocus
exit:
	.leave
	ret
HandleBubbleApply	endp

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ActivateBubbleFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Activates the window focus.

CALLED BY:	HandleBubbleApply, OLDialogWinInteractionCommand

PASS:		*ds:si -- interaction

RETURN:		nothing

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/16/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

ActivateBubbleFocus	proc	near		uses	ax, si
	class	OLWinClass
	.enter
	Assert	objectPtr dssi VisClass
	;
	; We "activate" the object with the focus, provided it's not
	; an InteractionCommand trigger.
	;
	call	WinDialog_DerefVisSpec_DI	

	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	tst	bx
	jz	exit

	mov	si, bx
	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle

	;
	; Not a GenTrigger, go ahead and activate.
	;
	mov	cx, segment GenTriggerClass
	mov	dx, offset GenTriggerClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnc	activate

	;
	; If the focused trigger is some kind of interaction command, don't
	; activate it!
	;
	sub	sp, size GetVarDataParams
	mov	bp, sp
	clr	ax
	movdw	ss:[bp].GVDP_buffer, axax
	mov	ss:[bp].GVDP_bufferSize, ax
	mov	ss:[bp].GVDP_dataType, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	mov	ax, MSG_META_GET_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GetVarDataParams
	tst	ax
	jns	exit

activate:
	mov	ax, MSG_SPEC_CHANGE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret
ActivateBubbleFocus	endp

endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinGenReset -- MSG_GEN_RESET handler for
		OLDialogWinClass

DESCRIPTION:	Handle resetting properties.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLDialogWinGenReset	method	dynamic OLDialogWinClass, MSG_GEN_RESET

if MENUS_HAVE_APPLY_CANCEL_BUTTONS
	;
	; If HINT_IS_POPUP_LIST, force this down to the first child, which
	; should be the item group.   We could handle this like we did
	; for applies, which was to send a custom spec apply-like message,
	; but this seems easier this time.	
	;
	push	ax
	mov	ax, HINT_IS_POPUP_LIST
	call	ObjVarFindData
	pop	ax
	jnc	notPopupList

	mov	ax, MSG_SPEC_POPUP_LIST_CANCEL
	call	VisCallFirstChild		;send on down to item group
	jmp	short makeNotApplyable		

notPopupList:
endif
	;
	; first call superclass to send RESET to gadgets
	;
	call	WinDialog_ObjCallSuperNoLock_OLDialogWinClass

if MENUS_HAVE_APPLY_CANCEL_BUTTONS
makeNotApplyable:
endif

	mov	ax, MSG_OL_MAKE_NOT_APPLYABLE
	call	WinDialog_ObjCallInstanceNoLock
					; Window settings no longer applyable
	ret
OLDialogWinGenReset	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinHandleApplyable -- MSG_GEN_MAKE_APPLYABLE,
		MSG_GEN_MAKE_NOT_APPLYABLE, MSG_OL_VUP_MAKE_APPLYABLE
		handler for OLDialogWinClass

DESCRIPTION:	Enable or disable apply/reset triggers, if any.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

if not _RUDY		;no applyable anywhere, can't get it to work with
			;   bubble interface.  In the process of making the
			;   applyable stuff work, the setting up the popup
			;   list moniker breaks.  Fixing the moniker to be
			;   updated all the time makes it impossible to "reset."

OLDialogWinHandleApplyable	method	OLDialogWinClass, \
						MSG_GEN_MAKE_APPLYABLE,
						MSG_OL_MAKE_APPLYABLE,
						MSG_GEN_MAKE_NOT_APPLYABLE,
						MSG_OL_MAKE_NOT_APPLYABLE,
						MSG_OL_VUP_MAKE_APPLYABLE

	mov	bx, MSG_GEN_SET_NOT_ENABLED	; assume disabling
	cmp	ax, MSG_GEN_MAKE_NOT_APPLYABLE
	je	haveMsg
	cmp	ax, MSG_OL_MAKE_NOT_APPLYABLE
	je	haveMsg
	mov	bx, MSG_GEN_SET_ENABLED		; else enabling
haveMsg:
	mov_trash	ax, bx			; ax = msg
	push	si
	mov	cx, IC_APPLY
	call	FindStandardTriggerInfo		; ^ldx:bp = apply trigger
	jnc	noApply
	mov	bx, dx
	mov	si, bp
	mov	dl, VUM_NOW
	push	ax				; save msg
	call	WinDialog_ObjMessageCallFixupDS
	pop	ax				; retrieve msg
noApply:
	pop	si
	mov	cx, IC_RESET
	call	FindStandardTriggerInfo		; ^ldx:bp = reset trigger
	jnc	noReset
	mov	bx, dx
	mov	si, bp
	mov	dl, VUM_NOW
	call	WinDialog_ObjMessageCallFixupDS
noReset:
	ret
OLDialogWinHandleApplyable	endm

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinInteractionCommand

DESCRIPTION:	Handle the various InteractionCommands.

PASS:
	*ds:si - instance data
	es - segment of OLDialogWinClass

	ax 	- MSG_GEN_GUP_INTERACTION_COMMAND

	cx	- InteractionCommand

RETURN:
	carry - set (answered)
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@

OLDialogWinInteractionCommand	method dynamic	OLDialogWinClass,
						MSG_GEN_GUP_INTERACTION_COMMAND

if _RUDY
	cmp	cx, IC_CHANGE
	LONG	je handleChange
	cmp	cx, IC_CANCEL_POPUP_LIST
	je	handleDismiss
endif
	cmp	cx, IC_APPLY
	LONG je	handleApply
	cmp	cx, IC_RESET
	LONG je	handleReset
	cmp	cx, IC_INTERACTION_COMPLETE
	je	handleInteractionComplete
	cmp	cx, IC_HELP
	je	handleHelp
	cmp	cx, IC_DISMISS
				; unblock with response for all others
	LONG jne	unblockUserDoDialog
if _RUDY
	;
	; OLButtons try to dismiss us whenever they are dismissed.
	; To avoid spurious & unexpected GEN_RESET's, check to
	; see if we've already been dismissed, assuming that we already
	; got RESET or APPLY when the window was actually closed.
	;
	test	ds:[di].VI_attrs, mask VA_REALIZED
	LONG jz	notPropertiesDismiss
endif
handleDismiss::
	;
	; IC_DISMISS:  If this is a properties dialog, we want to reset on
	; dismiss "Cancel".  We only do this if this is a true IC_DISMISS, not
	; one from an IC_INTERACTION_COMPLETE.  Since IC_DISMISS may be a
	; "Close" or a "Cancel", we must check that also.
	;
	call	WinDialog_DerefGen_DI		; ds:di = GIGI_*
	cmp	ds:[di].GII_type, GIT_PROPERTIES
	jne	notPropertiesDismiss		; don't reset for non-properties
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDWI_*
	test	ds:[di].OLDWI_optFlags, mask OLDOF_DOING_COMPLETE
	jnz	notPropertiesDismiss		; don't reset for
						;	IC_INTERACTION_COMPLETE
	mov	cl, ds:[di].OLPWI_flags		; cl = OLPopupWinFlags
	mov	dl, ds:[di].OLDWI_optFlags	; dl = OLDialogOptFlags
	call	CheckDismissCloseCancel		; Z set if "Close"
	jz	notPropertiesDismiss		; don't reset for "Close"

	mov	ax, MSG_GEN_RESET		; do RESET work
	call	WinDialog_ObjCallInstanceNoLock
notPropertiesDismiss:
	;
	; Handle IC_DISMISS -- dismiss, unblock and return IC_DISMISS response.
	;
	call	OLPopupDismiss			; use common code in OLPopupWin
	;
	; reset default trigger from temporary default to master default
	;
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_FORCE_RELEASE_DEFAULT_EXCLUSIVE
	call	WinDialog_ObjCallInstanceNoLock
	;
	; IC_DISMISS:  If doing IC_DISMISS for IC_INTERACTION_COMPLETE, don't
	; unblock.  Let some other, later InteractionCommand unblock.
	;
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDWI_*
	test	ds:[di].OLDWI_optFlags, mask OLDOF_DOING_COMPLETE
	pushf
						; clear flag for next time
	andnf	ds:[di].OLDWI_optFlags, not mask OLDOF_DOING_COMPLETE
	popf
	LONG jnz	afterUnblock
	mov	cx, IC_DISMISS			; else, unblock with IC_DISMISS
	jmp	short unblockUserDoDialog

	;
	; Handle the help button being pressed. But don't unblock UserDoDialogs
	;
handleHelp:
	mov	ax, MSG_META_BRING_UP_HELP
	call	ObjCallInstanceNoLock
	jmp	afterUnblock

handleInteractionComplete:
	;
	; If marked as single usage (HINT_INTERACTION_SINGLE_USAGE,
	; dismiss.  This allows any dialog response trigger with
	; signalInteractionComplete to dismiss the thing, modal or
	; not.  Different GenInteractionTypes have different defaults
	; for usage:
	;	GIT_ORGANIZATIONAL - not relevant as no response triggers
	;	GIT_PROPERTIES - multiple usage
	;	GIT_PROGRESS - single usage
	;	GIT_COMMAND - multiple usage
	;	GIT_NOTIFICATION - single usage
	;	GIT_AFFIRMATION - single usage
	;	GIT_MULTIPLE_RESPONSE - single usage
	; The defaults can be overridden with hints
	; (HINT_INTERACTION_{SINGLE,MULTIPLE}_USAGE) or if replacement
	; triggers are provided (via ATTR_GEN_TRIGGER_INTERACTION_COMMAND)
	; without the GA_SIGNAL_INTERACTION_COMMAND attribute
	;
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDWI_*
	test	ds:[di].OLDWI_optFlags, mask OLDOF_SINGLE_USAGE
	jnz	dismissForIC
	;
	; If modal, dismiss.  This means any response trigger with
	; singalInteractionComplete in a modal dialog will dismiss
	; the thing (even the multiple usage ones, GIT_PROPERTIES and
	; GIT_COMMAND).
	;
if ALL_DIALOGS_ARE_MODAL
	;
	; Forced "modal" by keyboard-only mode, preserve the non-modal
	; dialog box functionality and allow users to make multiple applies
	; before closing the dialog.  2/17/94 cbh
	;
	test	ds:[di].OLPWI_flags, mask OLPWF_FORCED_MODAL
	jnz	afterDismissForIC
endif
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
						mask OLPWF_SYS_MODAL
	jz	afterDismissForIC
;default setting of OLDOF_SINGLE_USAGE takes care of this
;CHANGE ABOVE TEST IF THIS IS ADDED BACK IN
if 0
	;
	; If a GIT_PROGRESS, GIT_NOTIFICATION, GIT_AFFIRMATION, dismiss.  This
	; means any response trigger with signalInteractionComplete
	; in such a dialog will dismiss, modal or not.  The standard
	; triggers for these (IC_STOP, IC_OK, IC_YES/IC_NO) are marked with
	; signalInteractionComplete.  (These have no IC_DISMISS response
	; trigger.)  If the developer wishes to avoid this, they need to
	; provide own trigger.  This doesn't occur for GIT_PROPERTIES's
	; IC_RESET (this shouldn't close) and IC_APPLY (this should allow
	; multiple usage of dialog box).
	;
	call	WinDialog_DerefGen_DI		; ds:di = GIGI_*
	cmp	ds:[di].GII_type, GIT_PROGRESS
	je	dismissForIC
	cmp	ds:[di].GII_type, GIT_NOTIFICATION
	je	dismissForIC
	cmp	ds:[di].GII_type, GIT_AFFIRMATION
	jne	afterDismissForIC
endif
dismissForIC:
	;
	; Single usage or modal dialog, dismiss on IC_INTERACTION_COMPLETE.
	; UserDoDialogs are unblocked when an InteractionCommand other than
	; IC_INTERACTION_COMPLETE (stored in the GenTrigger's
	; ATTR_GEN_TRIGGER_INTERACTION_COMMAND) is sent via a null action
	; or when the trigger's action message handler manually sends a
	; MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE (but
	; obviously from thread other than the blocked one).
	;
	; Indicate that we are doing an IC_DISMISS for IC_INTERACTION_COMPLETE
	;
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDWI_*
	ornf	ds:[di].OLDWI_optFlags, mask OLDOF_DOING_COMPLETE
	;
	; Send IC_DISMISS to ourselves so that a subclass can intercept
	; MSG_GEN_GUP_INTERACTION_COMPLETE(IC_DISMISS) and correctly get it
	; when MSG_GEN_GUP_INTERACTION_COMPLETE(IC_INTERACTION_COMPLETE) is
	; handled.
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	WinDialog_ObjCallInstanceNoLock
afterDismissForIC:
	;
	; don't unblock for IC_INTERACTION_COMPLETE (see previous comment)
	;
	jmp	afterUnblock

if _RUDY
handleChange:
	;
	; Change "activates" the object with the focus, provided it's not
	; the change trigger itself.
	;
	call	ActivateBubbleFocus
	jmp	short unblockUserDoDialog
endif

handleApply:

	;	
	; Normal apply.  (In Rudy, we'll just activate the current object.)
	;
	mov	ax, MSG_GEN_PRE_APPLY
	call	WinDialog_ObjCallInstanceNoLock
	jc	skipApply
	mov	ax, MSG_GEN_APPLY
	call	WinDialog_ObjCallInstanceNoLock
skipApply:
	mov	ax, MSG_GEN_POST_APPLY
	call	WinDialog_ObjCallInstanceNoLock
	mov	cx, IC_APPLY
	jmp	short unblockUserDoDialog

handleReset:
	mov	ax, MSG_GEN_RESET
	call	WinDialog_ObjCallInstanceNoLock
	mov	cx, IC_RESET

unblockUserDoDialog:
	;
	; If this GenInteraction has TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE,
	; send out the action with the response.  This has nothing to do with
	; dismissing.  That is handled seperately.  So, you could have a
	; response action sent out without it being dismissed.
	;	cx = response
	;
	mov	ax, TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE
	call	ObjVarFindData			; ds:bx = extra data, if found
	jnc	notResponseAction		; not found
EC <	VarDataSizePtr	ds, bx, ax					>
EC <	cmp	ax, size ActionDescriptor + size lptr			>
EC <	ERROR_NE	OL_ERROR					>
	;
	; A TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE dialog can't be a blocking
	; one.
	;
EC <	tst	ds:[di].OLPWI_udds.segment				>
EC <	ERROR_NZ	OL_ERROR					>
	push	si
	mov	ax, ds:[bx].AD_message		; ax = action message
	mov	si, ds:[bx].AD_OD.chunk		; ^lbx:si = action output
	mov	dx, {lptr}ds:[bx+size ActionDescriptor]	; dx <- data word
	mov	bx, ds:[bx].AD_OD.handle
	mov	di, mask MF_FIXUP_DS		; no MF_CALL!
	call	ObjMessage			; pass response in CX
	;
	; remove TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE so that if we've
	; got more ACTIVATE_INTERACTION_COMMAND-type messages in the queue,
	; we'll effectively ignore them, as we are going away
	;
	pop	si
	mov	ax, TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE
	call	ObjVarDeleteData
	jmp	short afterUnblock
notResponseAction:
	;
	; If this GenInteraction was displayed with UserDoDialog,
	; unlock application thread and return response.  Note that
	; MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE doesn't
	; dismiss.  That should have been done by a previous IC_DISMISS
	; or IC_INTERACTION_COMPLETE (the latter always dismisses a modal
	; dialog, which is required for UserDoDialog).  This allows unblocking
	; but leaving the dialog up (for verifcation purposes?).
	;	cx = response
	;
	call	WinDialog_DerefVisSpec_DI	; ds:di = OLDWI_*
	mov	ax, ds:[di].OLPWI_udds.segment
	tst	ax
	jz	afterUnblock
	mov	ax, MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE
	call	WinDialog_ObjCallInstanceNoLock
afterUnblock:
	stc				; gup query answered
	ret
OLDialogWinInteractionCommand	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinActiveInteractionCommand

DESCRIPTION:	Activate InteractionCommand standard trigger, if any.

PASS:
	*ds:si - instance data
	es - segment of OLDialogWinClass

	ax 	- MSG_GEN_INTERACTION_ACTIVATE_COMMAND

	cx	- InteractionCommand

RETURN:
	carry - set (answered)
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@

OLDialogWinActivateInteractionCommand	method dynamic	OLDialogWinClass,
					MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	call	FindStandardTriggerInfo		; ^ldx:bp = trigger, if any
	jnc	noTrigger
	mov	bx, dx				; ^lbx:si = trigger
	mov	si, bp
	mov	ax, MSG_GEN_TRIGGER_SEND_ACTION	; activate it
	call	WinDialog_ObjMessageCallFixupDS
	jmp	short done

noTrigger:
	;
	; no standard trigger found, do default handling with
	; MSG_GEN_GUP_INTERACTION_COMMAND
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	WinDialog_ObjCallInstanceNoLock
done:
	ret
OLDialogWinActivateInteractionCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert MSG_OL_WIN_CLOSE to activate an IC_DISMISS reply
		bar trigger

CALLED BY:	MSG_OL_WIN_CLOSE

PASS:		*ds:si	= OLDialogWinClass object
		ds:di	= OLDialogWinClass instance data
		es 	= segment of OLDialogWinClass
		ax	= MSG_OL_WIN_CLOSE

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/8/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDialogWinClose	method	dynamic	OLDialogWinClass, MSG_OL_WIN_CLOSE
	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE	; closable?
	jz	done					; NOT!
	mov	cx, IC_DISMISS
			; reverts to MSG_GEN_GUP_INTERACTION_COMMAND if
			; no IC_DISMISS found
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	call	ObjCallInstanceNoLock
done:
	ret
OLDialogWinClose	endm

WinDialog	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinInitiateNoDisturb

DESCRIPTION:	Initiate the dialog on-screen, behind other windows and without
		taking focus or target.

PASS:
	*ds:si - instance data
	es - segment of OLDialogWinClass

	ax - MSG_GEN_INTERACTION_INITATE_NO_DISTURB

	cx, dx, bp	- ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	This only works for GIV_DIALOG GenInteractions and GIV_CONTROL_GROUP
	GenInteractions that become dialogs.  MSG_GEN_INTERACTION_INITIATE
	also works for menus, so is handled in OLPopupWinClass.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@

OLDialogWinInitiateNoDisturb	method dynamic	OLDialogWinClass, \
					MSG_GEN_INTERACTION_INITIATE_NO_DISTURB
	;
	; first check status of this window
	;
	clr	cx			;allow optimized approach
	call	GenCheckIfFullyUsable	;check to see if FULLY USABLE
	jnc	done			;skip to end if not...

	;
	; if window is OWA_DISMISS_WHEN_DISABLED, ignore initiate requests
	; if disabled
	;
	call	AO_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_DISMISS_WHEN_DISABLED
	jz	notDismissWhenDisabled
	clr	cx			;allow optimized check
	call	GenCheckIfFullyEnabled	;carry set if so
	jnc	done			;not fully enabled, ignore request

notDismissWhenDisabled:
	;
	; set REALIZABLE if not that way already.  Bring up on screen, raise
	; to top.
	;
					; Make sure window is on the active
					; list, as ALL REALIZABLE windows
					; should be.
	call	OpenWinEnsureOnWindowList

					; If already visible, done
	call	AO_DerefVisSpec_DI
	test	ds:[di].VI_attrs, mask VA_VISIBLE
	jnz	done
					; If NOT visible, try again:

					; clear on-top flags for use if it
					; becomes visibile
	andnf	ds:[di].OLWI_fixedAttr, not mask OWFA_OPEN_ON_TOP

					; Cast specific-UI vote to
					; make this OLWinClass realizable
	mov	cx, mask SA_REALIZABLE
	mov	dl, VUM_NOW
	mov	ax, MSG_SPEC_SET_ATTRS
	call	ObjCallInstanceNoLock
done:
	ret
OLDialogWinInitiateNoDisturb	endp

ActionObscure	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDialogWinFupKbdChar - MSG_META_FUP_KBD_CHAR handler

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

		At this class level, the parent in the focus hierarchy is
		is the generic parent.

PASS:		*ds:si	= instance data for object
		ds:di = specific instance data for object
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
	brianc	1/92		Initial version (adapted from similar handlers)

------------------------------------------------------------------------------@


if FUNCTION_KEYS_MAPPED_TO_REPLY_BAR_BUTTONS

OLDialogWinFupKbdChar	method dynamic	OLDialogWinClass, \
				MSG_META_FUP_KBD_CHAR

	test	dl, mask CF_FIRST_PRESS
	jz	10$				;check for hard icon & sysModal
	
if _RUDY
	;
	; Esc is used to dismiss dialogs in special situations
	;
	call	RudyDismissOnEsc
	jc	exit
endif ; _RUDY

	test	dh, mask SS_LCTRL or mask SS_RCTRL or \
			mask SS_LALT or mask SS_RALT
	jnz	10$

if _RUDY
	;
	; if HELP key, dismiss all blocking dialogs to avoid situation
	; where help is closed and blocking dialog prevents app from
	; updating area exposed by closed help window
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_INS	;help?		>
DBCS <	cmp	cx, C_SYS_INS				;help?		>
	jne	notHelp
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_REMOVE_ALL_BLOCKING_DIALOGS
	call	UserCallApplication
	pop	ax, cx, dx, bp
notHelp:
endif

	;
	; If between F1-F4, pass number from 0 to 3 to reply bar...
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F1		;F1  key?	>
DBCS <	cmp	cx, C_SYS_F1				;F1 key?	>
	jb	callSuper
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F4		;F4  key?	>
DBCS <	cmp	cx, C_SYS_F4				;F4 key?	>
	ja	10$

SBCS <	sub	cx, (CS_CONTROL shl 8) or VC_F1				>
DBCS <	sub	cx, C_SYS_F1						>

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	movdw	bxsi, ds:[di].OLDWI_replyBar
	clr	di
	mov	ax, MSG_OL_REPLY_BAR_ACTIVATE_TRIGGER
	call	ObjMessage
	stc
	jmp	short exit

	;
	; If we are sysModal, and key pressed between F5-F12 or Ctrl-F12,
	; then ignore keystroke.
	;
10$:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GII_attrs, mask GIA_SYS_MODAL
	jz	callSuper

	;
	; See if key pressed within hard icon bar range
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F5		;F5 key?	>
DBCS <	cmp	cx, C_SYS_F5				;F5 key?	>
	jb	callSuper
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F12	;F12 key?	>
DBCS <	cmp	cx, C_SYS_F12				;F12 key?	>
	ja	callSuper

	stc
	jmp	exit
callSuper:
	mov	di, offset OLDialogWinClass
	call	ObjCallSuperNoLock
exit:
	ret
OLDialogWinFupKbdChar	endm

endif


if _JEDIMOTIF or _ODIE
;
; close dialogs on ESC (i.e. activate IC_DISMISS trigger
;
OLDialogWinFupKbdChar	method dynamic	OLDialogWinClass, \
				MSG_META_FUP_KBD_CHAR

	;
	; Don't do for custom window
	;
	push	ax, bx
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW
	call	ObjVarFindData
	pop	ax, bx
	jc	callSuper

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper		;ignore character...

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		;skip if not press event...

	;
	; Check for cancel mnemonic
	;
	mov	ax, MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC
	call	GenCallApplication	;carry set if found
	jnc	callSuper		;skip if not found...

	;found an escape: send method to self, after a slight delay to let
	;cancel buttons invert, etc.

	;
	; Close the dialog, activating any application supplied trigger
	; (message is MSG_GEN_INTERACTION_ACTIVATE_COMMAND).  If an
	; application supplied IC_DISMISS trigger doesn't actually dismiss
	; the dialog, we're hosed. We could use MSG_GEN_GUP_INTERACTION_COMMAND
	; instead, but that will not handle any application-provided IC_DISMISS
	; triggers, possibly leaving the application in a bad state.
	;
	; First, if we've got a single IC_OK or IC_DISMISS trigger, just
	; activate it.
	;
	push	si
	call	KN_DerefVisSpec_DI		; ds:di = OLDWI_*
	mov	si, ds:[di].OLDWI_triggerList
	tst_clc	si
	jz	tryDismiss
	call	ChunkArrayGetCount		; cx = count
	cmp	cx, 1
	clc					; try dismiss
	jne	tryDismiss
	mov	ax, 0				; first element
	call	ChunkArrayElementToPtr		; ds:di = first element
	mov	cx, ds:[di].NOICS_ic
if (not _ODIE)	; don't activate IC_OK for _ODIE
	cmp	cx, IC_OK
	je	useIt
endif
	cmp	cx, IC_DISMISS
	clc					; assume try dismiss
	jne	tryDismiss
useIt:
	stc					; use IC in cx
tryDismiss:
	pop	si
	jc	useCommand
	;
	; Or, if it has a IC_DISMISS (and any number of reply triggers,
	; IC_DISMISS it
	;
	mov	cx, IC_DISMISS
	call	FindStandardTriggerInfo		; preserves cx
	jc	useCommand			; found, use it
	;
	; Otherwise, if OWA_CLOSABLE, IC_DISMISS
	;
	call	KN_DerefVisSpec_DI		; ds:di = OLDWI_*
	test	ds:[di].OLWI_attrs, mask OWA_CLOSABLE
	jz	done				; not closable, eat it, don't
						;	send up
	mov	cx, IC_DISMISS
useCommand:
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:	
	stc				;say handled
	ret

callSuper:
	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, offset OLDialogWinClass
	call	ObjCallSuperNoLock
	ret
OLDialogWinFupKbdChar	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RudyDismissOnEsc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dismisses a dialog on an ESC press if IC_OK is the only
		reply trigger.

CALLED BY:	OLDialogWinFupKbdChar
PASS:		*ds:si	= instance data for object
		cx = character value
		dl = CharFlags (CF_FIRST_PRESS will be set)
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if key used to dismiss dialog.

DESTROYED:	nothing
SIDE EFFECTS:	could move lmem blocks

PSEUDO CODE/STRATEGY:
	This would be a good place to put other dialog-related
	global keypress	behavior that can't be handled by
	child objects.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	12/27/95    	Initial version, swiped from Jedi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _RUDY
RudyDismissOnEsc	proc	near
	class	OLDialogWinClass
	uses	ax,bx,cx,dx,si,di
	.enter
	;
	; Check for cancel mnemonic
	;
	mov	ax, MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC
	call	GenCallApplication	;carry set if found
	jnc	notUsed

	;
	; On Rudy, ESC is supposed to close a dialog when OK is
	; the only trigger in the dialog.  We'll only check the
	; standard trigger list, so if the dialog has triggers
	; that aren't in the list, it's too bad for you, dude.
	;

	push	si
	call	KN_DerefVisSpec_DI		; ds:di = OLDWI_*
	mov	si, ds:[di].OLDWI_triggerList
	tst_clc	si
	jz	tryDismiss
	call	ChunkArrayGetCount		; cx = count
	cmp	cx, 1
	clc					; try dismiss
	jne	tryDismiss
	mov	ax, 0				; first element
	call	ChunkArrayElementToPtr		; ds:di = first element
	mov	cx, ds:[di].NOICS_ic
	cmp	cx, IC_OK
	clc
	jne	tryDismiss
useIt::
	stc
tryDismiss:
	pop	si
	jnc	notUsed

useCommand:
	;
	; Close the dialog, by simulating the button press, in case
	; the button has other important side effects.
	;
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	stc
notUsed:
	.leave
	ret
RudyDismissOnEsc	endp
endif ; _RUDY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinActivateObjectWithMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For dialogs with folder tabs:
			Check tabs to see if mnemonics match

CALLED BY:	MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
PASS:		*ds:si	= OLDialogWinClass object
		ds:di	= OLDialogWinClass instance data
		ds:bx	= OLDialogWinClass object (same as *ds:si)
		es 	= segment of OLDialogWinClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState (ModBits)
		bp low	= ToggleState
		bp high	= scan code
RETURN:		carry set if mnemonic found
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DIALOGS_WITH_FOLDER_TABS	;----------------------------------------------

OLDialogWinActivateObjectWithMnemonic	method dynamic OLDialogWinClass, 
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	ax, TEMP_OL_WIN_TAB_INFO
	call	ObjVarFindData
	jnc	callSuper

	clr	di
tabLoop:
	tst	ds:[bx].OLWFTS_tabPosition[di]
	jz	nextTab

	CheckHack <(size OLWFTS_tabPosition) eq (size OLWFTS_tabs)/2>

	push	di
	shl	di, 1
	tst	ds:[bx].OLWFTS_tabs[di].LS_start
	pop	di
	jz	nextTab

	push	bx, si
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	cx, di
	shr	cx, 1
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx
	pop	ax, cx, dx, bp
	jc	skipTab

	call	ObjSwapLock
	call	VisCheckMnemonic
	call	ObjSwapUnlock
skipTab:
	pop	bx, si
	jnc	nextTab

	mov	cx, di				; cx = (0, 2, 4, ...)
	shr	cx, 1				; cx = (0, 1, 2, ...)
	mov	ax, MSG_OL_DIALOG_WIN_RAISE_TAB
	call	ObjCallInstanceNoLock
	stc					; mnemonic found
	ret

nextTab:
	add	di, size word
	cmp	di, NUMBER_OF_TABS * (size word)
	jl	tabLoop

callSuper:
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, offset OLDialogWinClass
	GOTO	ObjCallSuperNoLock

OLDialogWinActivateObjectWithMnemonic	endm

endif	; if DIALOGS_WITH_FOLDER_TABS -----------------------------------------

KbdNavigation	ends


WinCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDialogWinAlterFTVMCExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept change of focus within dialog to give UIApp and
		window the focus, as long as a child has the focus within
		the dialog.

CALLED BY:	MSG_META_MUP_ALTER_FTVMC_EXCL

PASS:		*ds:si	= OLDialogWinClass object
		ds:di	= OLDialogWinClass instance data
		es 	= segment of OLDialogWinClass
		ax	= MSG_META_MUP_ALTER_FTVMC_EXCL

		^lcx:dx	= object requesting grab/release
		bp	= MetaAlterFTVMCExclFlags

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		UIApp sits under system object, so when UI-run dialog
		gets focus, we grab focus for UIApp.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/13/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDialogWinAlterFTVMCExcl method dynamic OLDialogWinClass,
					MSG_META_MUP_ALTER_FTVMC_EXCL

	test	bp, mask MAEF_NOT_HERE		; are we coming from below?
	jz	callSuper			; yes, let superclass handle

	;
	; attempting to grab/release for dialog?
	;
	cmp	cx, ds:[LMBH_handle]
	jne	callSuper			; nope, let superclass handle
	cmp	dx, si
	jne	callSuper			; nope, let superclass handle

	;
	; grabbing/releasing focus for dialog?
	;
	test	bp, mask MAEF_FOCUS
	jz	callSuper			; nope, let superclass handle

	;
	; are we run by global ui thread?
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			; ax = burden thread
	mov	bx, handle ui
	call	ProcInfo			; bx = ui thread
	cmp	bx, ax
	jne	callSuper			; nope, let superclass handle

	;
	; grab or release?
	;
	test	bp, mask MAEF_GRAB
	jnz	grab

	;
	; Release focus for dialog.  If focus under UIApp changed (it will
	; not change if this is a non-modal dialog and there is a modal
	; dialog up, e.g.), release focus for UIApp, then ask system object
	; to find something to give the focus to (should be field we took it
	; away from earlier)
	;	bp = MetaAlterFTVMCExclFlags
	;
	; skip if modal, normal modal dialog closing code handles this
	; sufficiently (let superclass handle)
	;
	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLPWI_flags, mask OLPWF_APP_MODAL or \
					mask OLPWF_SYS_MODAL
	jnz	callSuper

	push	bp				; save MetaAlterFTVMCExclFlags
	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	UserCallApplication		; ^lcx:dx = current focus
	pop	bp				; restore MAEF
	push	cx, dx				; save

	mov	cx, ds:[LMBH_handle]		; release focus for ourselves
	mov	dx, si
	andnf	bp, not mask MAEF_NOT_HERE
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	UserCallApplication

	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	UserCallApplication		; ^lcx:dx = current focus
	pop	ax, di				; ^lax:di = prev focus
	cmp	ax, cx
	jne	focusChangedRelease
	cmp	di, dx
	je	done				; no focus change, done

focusChangedRelease:
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL	; release focus for UIApp
	call	UserCallApplication
	mov	ax, MSG_META_ENSURE_ACTIVE_FT	; ask system to ensure focus
	call	UserCallSystem
done:
	ret				; <-- EXIT HERE

callSuper:
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, offset OLDialogWinClass
	GOTO	ObjCallSuperNoLock	; <-- EXIT HERE

grab:
	;
	; Grab focus for dialog.  Grab focus for UIApp.
	;	bp = MetaAlterFTVMCExclFlags
	;
	mov	cx, ds:[LMBH_handle]		; grab focus for ourselves
	mov	dx, si
	andnf	bp, not mask MAEF_NOT_HERE
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	UserCallApplication

	mov	ax, MSG_META_GRAB_FOCUS_EXCL	; grab focus for UIApp
	call	UserCallApplication
	jmp	short done

OLDialogWinAlterFTVMCExcl endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLDialogWinAllowsExpressMenuShortcutsThrough -- 
		MSG_OL_WIN_ALLOWS_EXPRESS_MENU_SHORTCUTS_THROUGH 
		for OLDialogWinClass

DESCRIPTION:	Returns whether the object allows express menu shortcuts.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_ALLOWS_EXPRESS_MENU_SHORTCUTS_THROUGH

RETURN:		carry set if allows express menu shortcuts to go out to field
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	9/ 2/93         	Initial Version

------------------------------------------------------------------------------@

if	ALL_DIALOGS_ARE_MODAL		;Currently only used here.

OLDialogWinAllowsExpressMenuShortcutsThrough	\
				method dynamic	OLDialogWinClass, \
				MSG_OL_WIN_ALLOWS_EXPRESS_MENU_SHORTCUTS_THROUGH

	mov	ax, ATTR_ALLOWS_EXPRESS_MENU_SHORTCUTS_THROUGH
	call	ObjVarFindData			;returns carry set if exists
	ret
OLDialogWinAllowsExpressMenuShortcutsThrough	endm

endif

WinCommon	ends


WinDialog	segment resource

;
; optimization routines
;
WinDialog_DerefVisSpec_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
WinDialog_DerefVisSpec_DI	endp

WinDialog_DerefGen_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
WinDialog_DerefGen_DI	endp

WinDialog_ObjCallSuperNoLock_OLDialogWinClass	proc	near
	mov	di, offset OLDialogWinClass
	call	ObjCallSuperNoLock
	ret
WinDialog_ObjCallSuperNoLock_OLDialogWinClass	endp

WinDialog_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
WinDialog_ObjCallInstanceNoLock	endp

WinDialog_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
WinDialog_ObjMessageCallFixupDS	endp

WinDialog ends
