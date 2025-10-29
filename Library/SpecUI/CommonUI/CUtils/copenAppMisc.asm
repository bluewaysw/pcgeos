COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		OpenLook/Open
FILE:		copenAppMisc.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE
				Set the application's measurement type

    MTD MSG_META_QUERY_IF_PRESS_IS_INK
				If the application is *not* the focus
				application, then presses on it are not
				turned into ink.

    MTD MSG_META_GET_FOCUS_EXCL Returns the current focus/target/model
				below this point in hierarchy

    MTD MSG_META_GET_MODEL_EXCL Returns the current focus/target/model
				below this point in hierarchy

    MTD MSG_META_GET_TARGET_EXCL
				Returns the current focus/target/model
				below this point in hierarchy

    INT OLApplicationGetCommon  Returns the current focus/target/model
				below this point in hierarchy

    MTD MSG_META_GET_TARGET_AT_TARGET_LEVEL
				Returns current target object within this
				branch of the hierarchical target
				exclusive, at level requested

    MTD MSG_SPEC_RESOLVE_MONIKER_LIST
				Intercept MSG_SPEC_RESOLVE_MONIKER_LIST to
				NOT resolve moniker list into a single
				moniker.  GenApplication is allowed keep a
				moniker list.

    MTD MSG_SPEC_UPDATE_VIS_MONIKER
				Handle change in GenApplication moniker by
				telling iconified apps' icon, if any, to
				update.

    MTD MSG_META_KBD_CHAR       Intercept keyboard events to ignore input
				when necessary

    MTD MSG_OL_APP_NAVIGATE_TO_NEXT_WINDOW
				navigate to next window, ignored if modal
				window is up

    INT OLANTNW_Callback        callback routine to find next window

    MTD MSG_OL_APP_NAVIGATE_TO_NEXT_APP
				navigate to next app in field

    MTD MSG_OL_APP_NAVIGATE_TO_NEXT_APP
				navigate to next app in field

    MTD MSG_OL_APP_TRY_NAVIGATE_TO_APP
				try navigating to this app, navigate to
				next if not possible

    MTD MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG
				Build a standard dialog box, attach it to
				this application object, & set it USABLE.

    INT CreateHelpHintIfNeeded  Create a ATTR_GEN_HELP_CONTEXT if one was
				specified in the parameters

    INT CreateMultipleResponseTriggers
				Create response triggers for a
				GIT_MULTIPLE_RESPONSE dialog.

    INT CopyTriggerTemplate     Duplicate trigger template

    INT SubstituteStringArg     Substitute a string for a character in a
				chunk

    MTD MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
				Execute a standard dialog box.

    MTD MSG_OL_APP_DO_DIALOG_RESPONSE
				Finish a standard dialog box.

    MTD MSG_META_START_SELECT   Mouse button stuff.

    INT NukeExpressMenu         Gets rid of any express menus in stay up
				mode.

    MTD MSG_META_NOTIFY         Notification that a
				GWNT_HARD_ICON_BAR_FUNCTION or
				GWNT_STARTUP_INDEXED_APP has occurred - do
				a NukeExpressMenu.

    MTD MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC
				Tests for cancel mnemonic for the specific
				UI.

    MTD MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR
				toggle current GenPrimary's menu bar, if
				togglable

    MTD MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU
				toggle parent field's express menu.

    MTD MSG_META_QUERY_SAVE_DOCUMENTS
				Save documents on an app switch.

    MTD MSG_META_GAINED_FULL_SCREEN_EXCL
				Hack to force the model to match the target
				when the application comes to the front.
				Currently the document control stuff is
				forced to muck with the model exclusive
				when saving documents prior to switching
				apps, so that the model document is not on
				top.

    MTD MSG_META_GAINED_FULL_SCREEN_EXCL
				Sends data blocks containing, the text
				moniker, and icon moniker to the Indicator
				App.

    MTD MSG_META_APP_SHUTDOWN   We're shutting down the app.  Subclassed
				here so the app can re-enable the express
				menu, if it's disabled, to cover up
				problems with switching apps quickly in
				Redwood.

				Menu disabling happens in the express menu
				code -- see cwinField.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenApplication.asm

DESCRIPTION:

	$Id: copenAppMisc.asm,v 1.4 98/07/13 10:19:48 joon Exp $

------------------------------------------------------------------------------@

InstanceObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationSetMeasurementType --
		MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE for OLApplicationClass

DESCRIPTION:	Set the application's measurement type

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - The method
	cl - AppMeasurementType

RETURN:
	cx, dx, bp - same

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/90		Initial version

------------------------------------------------------------------------------@

OLApplicationSetMeasurementType	method dynamic	OLApplicationClass,
					MSG_GEN_APPLICATION_SET_MEASUREMENT_TYPE

	mov	ds:[di].OLAI_units, cl
	ret

OLApplicationSetMeasurementType	endm

InstanceObscure	ends
CommonFunctional	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the application is *not* the focus application, then
		presses on it are not turned into ink.

CALLED BY:	GLOBAL
PASS:		ds:di - OLApplication instance data
		cx, dx - position of mouse
RETURN:		ax - InkReturnValue
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationQueryIfPressIsInk	method	dynamic OLApplicationClass,
				MSG_META_QUERY_IF_PRESS_IS_INK
if GRAFFITI_ANYWHERE and 0
	;
	;  Pass the query onto the first focused child.
	;
	push	ax, cx, dx

	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	ObjCallInstanceNoLock		; ^lcx:dx = obj
	movdw	bxsi, cxdx

	pop	ax, cx, dx			; passed args

	mov	di, mask MF_CALL
	call	ObjMessage			; ax, bp = returned

	push	ax				; InkReturnValue
	mov_tr	cx, ax				; just in case start-select
	mov	ax, MSG_GEN_APPLICATION_INK_QUERY_REPLY
	call	ObjCallInstanceNoLock		;   is being held up
	pop	ax
else

	;
	; If any menus were up, release them now.  -cbh 12/15/92
	;
	push	cx, dx
	call	OLCountStayUpModeMenus		;release any menus, no counting
	pop	cx, dx
	tst	bp
	jnz	noInk				;No ink if menus in stayup mode

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLAI_flowFlags, mask AFF_FOCUS_APP
	jnz	callSuper			;If this is the focused app,
						; pass query off to children

noInk:
	mov	ax, MSG_GEN_APPLICATION_INK_QUERY_REPLY
	mov	cx, IRV_NO_INK
	GOTO	ObjCallInstanceNoLock

callSuper:
	mov	ax, MSG_META_QUERY_IF_PRESS_IS_INK
	mov	di, offset OLApplicationClass
	CallSuper	MSG_META_QUERY_IF_PRESS_IS_INK
exit:
endif		; not _JEDIMOTIF
	ret
OLApplicationQueryIfPressIsInk	endp

CommonFunctional ends
ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationGetFocus
METHOD:		OLApplicationGetTarget
METHOD:		OLApplicationGetModel

DESCRIPTION:	Returns the current focus/target/model
		below this point in hierarchy

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_META_GET_[FOCUS/TARGET/MODEL]

RETURN:		^lcx:dx - handle of object
		ax, bp	- destroyed
		carry	- set

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/25/91		Initial version

------------------------------------------------------------------------------@

OLApplicationGetFocusExcl 	method dynamic OLApplicationClass, \
					MSG_META_GET_FOCUS_EXCL
	mov	bx, offset VCNI_focusExcl
	GOTO	OLApplicationGetCommon
OLApplicationGetFocusExcl	endm

OLApplicationGetModelExcl 	method dynamic OLApplicationClass, \
					MSG_META_GET_MODEL_EXCL
	mov	bx, offset OLAI_modelExcl
	GOTO	OLApplicationGetCommon
OLApplicationGetModelExcl	endm

OLApplicationGetTargetExcl 	method dynamic OLApplicationClass, \
					MSG_META_GET_TARGET_EXCL
	mov	bx, offset VCNI_targetExcl
	FALL_THRU	OLApplicationGetCommon
OLApplicationGetTargetExcl	endm

OLApplicationGetCommon	proc	far
	mov	cx, ds:[di][bx].FTVMC_OD.handle
	mov	dx, ds:[di][bx].FTVMC_OD.chunk
	Destroy	ax, bp
	stc
	ret
OLApplicationGetCommon	endp

ActionObscure	ends
ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationGetTargetAtTargetLevel

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - MSG_META_GET_TARGET_AT_TARGET_LEVEL

	cx	- TargetLevel

RETURN:
	cx:dx	- OD of target at level requested (0 if none)
	bp	- TargetType

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


OLApplicationGetTargetAtTargetLevel	method dynamic	OLApplicationClass, \
					MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	ax, TL_GEN_APPLICATION
	mov	bx, Vis_offset
	mov	di, offset VCNI_targetExcl
	call	FlowGetTargetAtTargetLevel
	ret
OLApplicationGetTargetAtTargetLevel	endm

ActionObscure	ends
ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLApplicationSpecResolveMonikerList -
		MSG_SPEC_RESOLVE_MONIKER_LIST handler.

DESCRIPTION:	Intercept MSG_SPEC_RESOLVE_MONIKER_LIST to NOT resolve moniker
		list into a single moniker.  GenApplication is allowed keep
		a moniker list.

PASS:		*ds:si	- instance data
		*ds:cx	- moniker list to resolve

RETURNS:	nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/2/92		initial version

------------------------------------------------------------------------------@

OLApplicationSpecResolveMonikerList	method dynamic	OLApplicationClass, \
				MSG_SPEC_RESOLVE_MONIKER_LIST
	ret
OLApplicationSpecResolveMonikerList	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLApplicationSpecUpdateVisMoniker -
		MSG_SPEC_UPDATE_VIS_MONIKER handler.

DESCRIPTION:	Handle change in GenApplication moniker by telling iconified
		apps' icon, if any, to update.

PASS:		*ds:si	- instance data

		dl	- VisUpdateMode
		cx	- width of old moniker
		bp	- height of old moniker

RETURNS:	nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/3/92		initial version

------------------------------------------------------------------------------@

OLApplicationSpecUpdateVisMoniker	method dynamic	OLApplicationClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER
	;
	; First, call superclass for default handling
	;
	mov	di, offset OLApplicationClass
	CallSuper	MSG_SPEC_UPDATE_VIS_MONIKER
	;
	; Send MSG_OL_MENUED_WIN_UPDATE_ICON_MONIKER to all GenPrimarys.  It
	; will update its icon, if any.
	;
	push	si
	mov	bx, segment GenPrimaryClass
	mov	si, offset GenPrimaryClass
	mov	ax, MSG_OL_MENUED_WIN_UPDATE_ICON_MONIKER
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	pop	si
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	ObjCallInstanceNoLock
	;
	; XXX: update GEOS tasks list entries?
	;
	ret
OLApplicationSpecUpdateVisMoniker	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationUnwantedKbdEvent

DESCRIPTION:	Handler for Kbd event with no destination, i.e. no kbd grab
		has been set up.  Default behavior here is to beep,
		on presses only.

PASS:		*ds:si 	- instance data
		es     	- segment of OLApplicationClass
		ax 	- MSG_VIS_CONTENT_UNWANTED_KBD_EVENT
		cx, dx, bp	- same as MSG_META_KBD_CHAR

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@

OLApplicationUnwantedKbdEvent	method	OLApplicationClass,
				MSG_VIS_CONTENT_UNWANTED_KBD_EVENT

				; No destination!
				; See if first press or not
	test	dl, mask CF_FIRST_PRESS
	jz	afterBeep	; if not, no beep
				; Let user know that he is annoying us ;)
	push	ax
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	pop	ax
afterBeep:

	Destroy	ax, cx, dx, bp
	ret

OLApplicationUnwantedKbdEvent	endm


ActionObscure	ends
KbdNavigation	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept keyboard events to ignore input when necessary

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		ds:bx	= OLApplicationClass object (same as *ds:si)
		es 	= segment of OLApplicationClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _KBD_NAVIGATION	;------------------------------------------------------

OLApplicationKbdChar	method dynamic OLApplicationClass,
					MSG_META_KBD_CHAR
	;
	; If overriding input restrictions, process kbd input.
	; Otherwise, check ignore input flag
	;
	test	ds:[di].OLAI_flowFlags, mask AFF_OVERRIDE_INPUT_RESTRICTIONS
	jnz	processKbdChar
						; If no modal window, however
	tst	ds:[di].OLAI_ignoreInputCount	; check for ignore input mode.
	jz	processKbdChar			; if active, just send on to
						; field & do nothing else.
	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	GenCallParent			; Send to field

processKbdChar:
	;
	; If we're low on handles, ignore input and then send accept input via
	; the process thread. This will ignore input until we've caught up.
	;
	push	ax, dx
	mov	ax, SGIT_NUMBER_OF_FREE_HANDLES
	call	SysGetInfo
	cmp	ax, LOW_ON_FREE_HANDLES_THRESHOLD
	ja	manyHandles

	tst	ds:[di].OLAI_ignoreInputCount
	jnz	manyHandles			; skip ignore if already ignore

	push	cx, bp
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	UserSendToApplicationViaProcess
	pop	cx, bp
manyHandles:
	pop	ax, dx

	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock


OLApplicationKbdChar  endm


endif			;------------------------------------------------------



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationFupKbdChar --
		MSG_META_FUP_KBD_CHAR for OLApplicationClass

DESCRIPTION:	Handles keyboard characters, in order to do application
		shortcuts.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_FUP_KBD_CHAR
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if key handled

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/90		Initial version

------------------------------------------------------------------------------@

OLApplicationFupKbdChar	method OLApplicationClass, MSG_META_FUP_KBD_CHAR
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

SBCS <	cmp	ch, CS_UI_FUNCS			; If a UI function notification>
SBCS <	LONG je	callField			; don't need to do anything >

						; If a modal window is up,
						; go ahead & process kbd input
						; for it (ignore input
						; overridden)

if _KBD_NAVIGATION	;------------------------------------------------------

	; If overriding input restrictions, process kbd input.
	; Otherwise, check ignore input flag
	;
	test    ds:[di].OLAI_flowFlags, \
				mask AFF_OVERRIDE_INPUT_RESTRICTIONS
	jnz	processKbdChar
						; If no modal window, however
	tst	ds:[di].OLAI_ignoreInputCount	; check for ignore input mode.
	LONG jnz callField			; if active, just send on to
						; field & do nothing else.
processKbdChar:
	test	dl,mask CF_RELEASE or mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	LONG jnz	doLocalShortcuts		;ignore if not press.

	;
	; If .ini flag says not to process kbd accelerators, don't
	;
	call	UserGetKbdAcceleratorMode	; Z set if off
	LONG jz	afterLocalShortcuts		; skip all shortcuts

	;
	; Special case <F1> for help -- we want this to bring up
	; help even for modal dialogs  (Ctrl-H in Redwood. 9/13/93 cbh)
	;
SBCS <	cmp	cx, VC_F1 or (CS_CONTROL shl 8)				>
DBCS <	cmp	cx, C_SYS_F1						>
	je	doLocalShortcuts		;branch if help

notHelp:
	;
	; See if there is currently a modal window up.  If there is, we
	; want to just do accelerators for that window and exit without
	; trying application shortcuts.  Otherwise, we'll do accelerators for
	; the entire application and if we get no match, try application
	; shortcuts.
	;
 	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	mov	bx, ds:[di].OLAI_modalWin.handle
	tst	bx				;is there a modal window?
	jz	findAccel			;nope, branch to do entire appl

if	ALL_DIALOGS_ARE_MODAL
	;
	; Redwood, make sure we can access the express menu.  We'll allow
	; characters to be fupped.   8/30/93 cbh    (Changed to not send
	; to express menu if window is sys-modal.  9/ 2/93 cbh)  (Changed
	; yet again to only allow windows with a special hint on them,
	; i.e., the New/Open Dialog box, to pass it through. 2/ 9/94 cbh)
	;
	push	cx, dx, bp
	push	si
	mov	si, ds:[di].OLAI_modalWin.chunk
	call	ObjMessageCallFixupDS
	pop	si				;restore application handle
	pushf
	call	OLReleaseAllStayUpModeMenus
	popf
	pop	cx, dx, bp
	jc	done

	push	cx, dx, si, bp
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	bxsi, ds:[di].OLAI_modalWin
if ERROR_CHECK
	mov	cx, segment OLWinClass
	mov	dx, offset OLWinClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjMessageCallFixupDS
	ERROR_NC	OL_ERROR		;whoops.
endif
	mov	ax, MSG_OL_WIN_ALLOWS_EXPRESS_MENU_SHORTCUTS_THROUGH
	call	ObjMessageCallFixupDS		;c=1 if allows shortcuts
	pop	cx, dx, si, bp
	jc	callField
	jmp	short done

else	; not ALL_DIALOGS_ARE_MODAL

	push	si				;save application handle
	mov	si, ds:[di].OLAI_modalWin.chunk
						;need to check carry afterwards
	call	ObjMessageCallFixupDS		;send method to modal win
	pop	si				;restore application handle
	jmp	short bringUpMenus		;branch to bring up menus

endif	; ALL_DIALOGS_ARE_MODAL

findAccel:
	push	cx, dx, bp
	call	ObjCallInstanceNoLock		;send to ourselves
	pop	cx, dx, bp
	jnc	doLocalShortcuts		;nothing found, move on

bringUpMenus:
	;
	; Call a utility routine to send a method to the Flow object that
	; will force the dismissal of all menus in stay-up-mode.
	;
	call	OLReleaseAllStayUpModeMenus
	stc					;handled...
	jmp	short done

doLocalShortcuts:

	;Don't handle state keys (shift, ctrl, etc).
	;
	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	afterLocalShortcuts
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	afterLocalShortcuts		;skip if not press event...


	push	es
						;set es:di = table of shortcuts
						;and matching methods
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLAppKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jnc	afterLocalShortcuts		;no match, branch

	;found a shortcut: send method to self.
	;
	clr	bp		;in case it is MSG_OL_APP_NAVIGATE_TO_NEXT_APP
	call	ObjCallInstanceNoLock
	stc					;say handled
	jmp	short done

afterLocalShortcuts:
endif	;----------------------------------------------------------------------

callField:
	mov	ax, MSG_META_FUP_KBD_CHAR
	call	GenCallParent			;send to field
done:
	pop	di
	call	ThreadReturnStackSpace
	ret



OLApplicationFupKbdChar	endm


if _KBD_NAVIGATION	;------------------------------------------------------

;Keyboard shortcut bindings for OLApplicationClass

OLAppKbdBindings	label	word
	word	length OLAShortcutList

if _ISUI ;------------------------------------------------------------

if DBCS_PCGEOS

OLAShortcutList	KeyboardShortcut \
	<0, 1, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>,	;NEXT application
	<0, 1, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;NEXT application
	<0, 1, 0, 0, C_SYS_F6 and mask KS_CHAR>,	;NEXT window
	<0, 0, 0, 0, C_SYS_F3 and mask KS_CHAR>,	;Quit application
	<0, 0, 0, 0, C_SYS_F1 and mask KS_CHAR>		;Help

else ; ISUI but not DBCS

OLAShortcutList	KeyboardShortcut \
	<0, 1, 0, 0, 0xf, VC_ESCAPE>,	;NEXT application
	<0, 1, 0, 0, 0xf, VC_TAB>,	;NEXT application
	<0, 1, 0, 0, 0xf, VC_F6>,	;NEXT window
	<0, 0, 0, 0, 0xf, VC_F3>,	;Quit application
	<0, 0, 0, 0, 0xf, VC_F1>	;Help

endif

OLAMethodList	label word
	word	MSG_OL_APP_NAVIGATE_TO_NEXT_APP
	word	MSG_OL_APP_NAVIGATE_TO_NEXT_APP
	word	MSG_OL_APP_NAVIGATE_TO_NEXT_WINDOW
	word	MSG_OL_APPLICATION_QUIT
	word	MSG_GEN_APPLICATION_BRING_UP_HELP

else ;not _ISUI ;------------------------------------

if DBCS_PCGEOS

OLAShortcutList	KeyboardShortcut \
	<0, 1, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>,	;NEXT application
	<0, 1, 0, 0, C_SYS_F6 and mask KS_CHAR>,	;NEXT window
	<0, 0, 0, 0, C_SYS_F3 and mask KS_CHAR>,	;Quit application
	<0, 0, 0, 0, C_SYS_F1 and mask KS_CHAR>		;Help

else ; not DBCS_PCGEOS
OLAShortcutList	KeyboardShortcut \
	<0, 1, 0, 0, 0xf, VC_ESCAPE>,	;NEXT application
	<0, 1, 0, 0, 0xf, VC_F6>,	;NEXT window
	<0, 0, 0, 0, 0xf, VC_F3>,	;Quit application
	<0, 0, 0, 0, 0xf, VC_F1>	;Help

endif ; DBCS
OLAMethodList	label word
	word	MSG_OL_APP_NAVIGATE_TO_NEXT_APP
	word	MSG_OL_APP_NAVIGATE_TO_NEXT_WINDOW
	word	MSG_OL_APPLICATION_QUIT
	word	MSG_GEN_APPLICATION_BRING_UP_HELP
endif

ForceRef OLAMethodList
CheckHack <($-OLAMethodList) eq (size OLAShortcutList)>

endif	; KBD_NAVIGATION -----------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationNavigateToNextWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	navigate to next window, ignored if modal window is up

CALLED BY:	MSG_OL_APP_NAVIGATE_TO_NEXT_WINDOW

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= MSG_OL_APP_NAVIGATE_TO_NEXT_WINDOW

		bp = event to dispatch when app to navigate to is found

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/11/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationNavigateToNextWindow	method	dynamic	OLApplicationClass,
					MSG_OL_APP_NAVIGATE_TO_NEXT_WINDOW

	;
	; if we have a modal win up, ignore
	;
	tst	ds:[di].OLAI_modalWin.handle
	LONG jnz	done
	;
	; get current focus window
	;
	push	si			; save OLApp chunk handle
	mov	bx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle
	mov	si, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
	mov	cx, segment OLDialogWinClass
	mov	dx, offset OLDialogWinClass
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry set if found (^lcx:dx)
	jc	haveFocusWin
if (not _NO_WIN_ICONS)
	mov	cx, segment OLWinIconClass
	mov	dx, offset OLWinIconClass
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry set if found (^lcx:dx)
	jc	haveFocusWin
endif
	mov	cx, segment OLBaseWinClass
	mov	dx, offset OLBaseWinClass
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry set if found (^lcx:dx)
					; else, ^lcx:dx = null
haveFocusWin:
	pop	si			; *ds:si = OLApp
	;
	; Go through app's GAGCNLT_WINDOWS list to find next window.
	; there shouldn't be any modal windows on the list as they're
	; removed from the list when they close.  We have to manually
	; ignore OLDisplayWins and pinned menus.  We're just looking for
	; OLBaseWin and OLDialogWin.
	;	^lcx:dx = current focus window
	;	*ds:si = OLApp
	;
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData
	jnc	done			; if no lists, done

	mov	bp, si			; *ds:bp = OLApp
	mov	di, ds:[bx].TMGCND_listOfLists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_WINDOWS
	clc				; don't create list
	call	GCNListFindListInBlock	; *ds:si = list, if found
	jnc	done			; if no GAGCNLT_WINDOWS list, done

	pushdw	cxdx			; save current focus window
	push	bp			; save OLApp chunk
	clr	ax			; haven't found first eligible window
	mov	bx, SEGMENT_CS
	mov	di, offset OLANTNW_Callback
	call	ChunkArrayEnum		; stops after finding suitable window
	pop	di			; di = OLApp chunk
	popdw	bxsi			; ^lbx:si = current focus window
	jc	foundAWindow		; use found window
	movdw	cxdx, axbp		; ^lcx:dx = otherwise eligible window
	jcxz	done			; no otherwise eligible window found
foundAWindow:
	;
	; found "next window"
	;	^lcx:dx = "next window"
	;	^lbx:si = current focus window, if any
	;	*ds:di = OLApplication
	;
	push	di			; save OLApp
	pushdw	bxsi			; save curent focus window
	movdw	bxsi, cxdx		; ^lbx:si = "next window"
;this is too much as it should already be above everything else we're
;interested in
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
;	mov	ax, MSG_META_GRAB_FOCUS_EXCL
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	call	ObjMessage
;	mov	ax, MSG_META_GRAB_TARGET_EXCL
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	call	ObjMessage
	;
	; lower old focus window
	;
	popdw	bxsi			; ^lbx:si = old focus window
	mov	cx, bx			; in case no old focus window
	tst	bx
	jz	donePop			; no old focus window
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ^hcx = window
donePop:
	pop	bp			; *ds:bp = OLApplication
	jcxz	done			; no window, screw it
	mov	di, cx			; ^hdi = window
	mov	ax, mask WPF_PLACE_BEHIND
	clr	dx			; leave layerID
	call	WinChangePriority
	mov	ax, MSG_GEN_APPLICATION_LOWER_WINDOW_TO_BOTTOM
	movdw	cxdx, bxsi
	mov	si, bp			; *ds:si = OLApplication
	call	ObjCallInstanceNoLock
done:
	ret
OLApplicationNavigateToNextWindow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLANTNW_Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to find next window

CALLED BY:	INTERNAL
			OLApplicationNavigateToNextWindow

PASS:		*ds:si - GAGCNLT_WINDOWS list
		ds:di - GCNListElement
		^lcx:dx = current focus window to search for
			null to return next available window
		^lax:bp = first eligible window (0 if not found yet)

RETURN:		carry clear to continue enumeration
			^lax:bp = eligible window, if nothing else found
		carry set to stop enumeration, when next window is found
			^lcx:dx = next window

DESTROYED:

PSEUDO CODE/STRATEGY:
		Windows are moved to the front of the list when they are
		raised to the top.

		Look for first OLDialogWin or OLBaseWin after the focus
		window.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLANTNW_Callback	proc	far

	;
	; check if this is eligible "next window"
	;
	pushdw	axbp
	pushdw	cxdx
	mov	bx, ds:[di].GCNLE_item.handle
	mov	si, ds:[di].GCNLE_item.chunk
	mov	cx, segment OLDialogWinClass
	mov	dx, offset OLDialogWinClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry set if in-class
	jc	checkWin
if (not _NO_WIN_ICONS)
	mov	cx, segment OLWinIconClass
	mov	dx, offset OLWinIconClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry set if in-class
	jc	checkWin
endif
	mov	cx, segment OLBaseWinClass
	mov	dx, offset OLBaseWinClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnc	haveWindowStatus
checkWin:
	mov	ax, MSG_OL_WIN_CHECK_IF_POTENTIAL_NEXT_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry set if so
haveWindowStatus:
	;
	; carry set if window is eligible "next window"
	;	^lbx:si = window
	;
	mov	di, 0			; assume ineligible window
	jnc	10$
	dec	di			; indicate eligible window
10$:
	popdw	cxdx
	popdw	axbp

	tst	cx			; have we found current focus window?
	jnz	findFocus		; nope, check if this is it
	;
	; no current focus window or found focus window, return this if it
	; is a potential "next window"
	;
	tst	di
	jz	continueForNext		; not eligible, continue
	;
	; return this as "next window"
	;
	movdw	cxdx, bxsi
	stc
	jmp	short exit

findFocus:
	cmp	cx, bx
	jne	thisIsNotFocus		; this is not current focus window
	cmp	dx, si
	je	continueForNext		; found current focus window, now
					;	find next eligible window
thisIsNotFocus:
	;
	; haven't found current focus yet, if we have an eligible
	; "next window", save it in case we wrap around the list
	;
	tst	di
	jz	continueForFocus
	movdw	axbp, bxsi		; save eligible window
	jmp	short continueForFocus

continueForNext:
	clr	cx			; indicate we want the next eligible
					;	item
continueForFocus:
	clc
exit:
	ret
OLANTNW_Callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationNavigateToNextApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	navigate to next app in field

CALLED BY:	MSG_OL_APP_NAVIGATE_TO_NEXT_APP
			OLApplicationFupKbdChar (bp = 0)
			OLApplicationTryNavigateToApp (bp <> 0)

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= MSG_OL_APP_NAVIGATE_TO_NEXT_APP

		^hbp = event to dispatch when app to navigate to is found,
			if none, we'll create one

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/5/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not _ISUI)		;------------------------------------------------------

OLApplicationNavigateToNextApp	method	dynamic	OLApplicationClass,
					MSG_OL_APP_NAVIGATE_TO_NEXT_APP
	;
	; create event to lower current app to bottom, if none yet
	;
	tst	bp
	jnz	haveEvent
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = send event to
						;	this object
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	mov	di, mask MF_RECORD
	call	ObjMessage			; ^hdi = event
	mov	bp, di				; ^hbp = event
haveEvent:
	;
	; ask field to handle this
	;
	push	si
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = this app
	mov	dx, si				; (bp = passed event)
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	ax, MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	ret
OLApplicationNavigateToNextApp	endm

else	; ISUI ---------------------------------------------------------------
;
; ISUI just asks the field to bring to front the next window listed in the
; window list
;
OLApplicationNavigateToNextApp	method	dynamic OLApplicationClass,
					MSG_OL_APP_NAVIGATE_TO_NEXT_APP
	; ask field to handle this
	push	si
	mov	bx, segment OLFieldClass
	mov	si, offset OLFieldClass
	mov	ax, MSG_OL_FIELD_NAVIGATE_TO_NEXT_APP
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si
	mov	cx, di
	mov	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	GOTO	ObjCallInstanceNoLock

OLApplicationNavigateToNextApp	endm

endif	;----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationTryNavigateToApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try navigating to this app, navigate to next if not possible

CALLED BY:	MSG_OL_APP_TRY_NAVIGATE_TO_APP

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= MSG_OL_APP_TRY_NAVIGATE_TO_APP

		bp = event to dispatch when app to navigate to is found

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/5/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not _ISUI)	;--------------------------------------------------------------

OLApplicationTryNavigateToApp	method	dynamic	OLApplicationClass,
					MSG_OL_APP_TRY_NAVIGATE_TO_APP
	;
	; if not focusable or interactable, navigate to next app
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_FOCUSABLE
	jz	goToNext			; not focusable
	test	ds:[di].GAI_states, mask AS_NOT_USER_INTERACTABLE
	jnz	goToNext			; not interactable

	;
	; can navigate to this app, grab focus/target, etc.
	;
	push	bp				; save passed event
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
	pop	bx				; restore passed event

	;
	; now, dispatch passed event (will be MSG_GEN_LOWER_TO_BOTTOM)
	;
	tst	bx				; nothing to send out
	jz	exit
	mov	di, si				; *ds:di = OLApp
	call	ObjGetMessageInfo		; ax = msg, cx:si = dest
EC <	cmp	ax, MSG_GEN_LOWER_TO_BOTTOM				>
EC <	ERROR_NZ	OL_ERROR					>
	cmp	cx, ds:[LMBH_handle]		; is it for us?
	jne	sendItOn			; nope, send it out
	cmp	si, di
	jne	sendItOn			; nope, send it out

	call	ObjFreeMessage			; yes, it is for us, don't
	jmp	exit				;	bother, as we just
						;	brought ourselves
						;	to top
sendItOn:
	clr	di
	call	MessageDispatch
exit:
	ret

goToNext:
						; pass bp = passed event
	mov	ax, MSG_OL_APP_NAVIGATE_TO_NEXT_APP
	GOTO	ObjCallInstanceNoLock
OLApplicationTryNavigateToApp	endm

endif	;----------------------------------------------------------------------

KbdNavigation ends
StandardDialog	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationBuildStandardDialog --
		    MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG for OLApplicationClass

DESCRIPTION:	Build a standard dialog box, attach it to this application
		object, & set it USABLE.

PASS:
	*ds:si - instance data
	ds:bx - instance data of object called (= *ds:si)
	if class of method handler is in a master part
	    ds:di - data for master part of method handler
	else
	    ds:di - instance data of object called (= *ds:si)
	es - segment of OLApplicationClass

	ax - The method

	dx - size StandardDialogParams
	ss:bp - StandardDialogParams

RETURN:
	^lcx:dx - summons (in a new block)
	bp - CustomDialogType
DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
OLApplicationBuildStandardDialog	method dynamic	OLApplicationClass,
				MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG

	push	di			; If detaching, too late -- can't
	mov	di, ds:[si]		; put up a dialog box.  Return NULL
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_DETACHING
	pop	di
	jz	continue
	clr	cx			; Return NULL dialog box
	clr	dx
	jmp	done

continue:

	; make a copy of our standard summons

	mov	bx, handle StandardDialogUI
	clr	ax				; have current geode own
	clr	cx				; have current thread run block
	call	ObjDuplicateResource		; bx = new block


	; set the correct moniker for the glyph

	push	ds:[LMBH_handle], si
	call	ObjLockObjBlock
	mov	ds, ax

	; If _MINIMAL_STANDARD_DIALOGS is true, then we do not have a glyph
	; or any artwork, so skip all of this.
if	 not _MINIMAL_STANDARD_DIALOGS

	mov	ax, ss:[bp].SDP_customFlags
	and	ax, mask CDBF_DIALOG_TYPE
	mov	cx, offset StdDialogQuestionMoniker
	cmp	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	cx, offset StdDialogWarningMoniker
	cmp	ax, CDT_WARNING shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	cx, offset StdDialogNotificationMoniker
	cmp	ax, CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	cx, offset StdDialogErrorMoniker
10$:

if MONIKER_LIST_NEEDED_FOR_STD_DIALOG_MONIKERS

;	RELOCATE THE MONIKER FOR THE GLYPH (BY HAND)

;
;	We have to do this, because the block we are relocating no longer
;	belongs to motif, but to an application. If we try to relocate it, it
;	will use the APPLICATIONs reloc table, which will result in badness.
;	10/93 - don't assume that we know how big the moniker list is,
;	or what position each entry is, as this prevents us from
;	crunching Motif.

	push	bx, cx
	mov	di, cx
	mov	di, ds:[di]		;DS:DI <- ptr to moniker list
	ChunkSizePtr	ds, di, cx

relocateLoop:
	mov	ax, ds:[di].VMLE_moniker.handle
	andnf	ax, not mask RID_SOURCE
	mov	bx, handle 0
	call	GeodeGetGeodeResourceHandle
	mov	ds:[di].VMLE_moniker.handle, bx
	add	di, size VisMonikerListEntry
	sub	cx, size VisMonikerListEntry
	jnz	relocateLoop

	pop	bx, cx

endif	;if MONIKER_LIST_NEEDED_FOR_STD_DIALOG_MONIKERS

	mov	si, offset StdDialogCuteGlyph
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	ds:[si].GI_visMoniker, cx

endif	;not _MINIMAL_STANDARD_DIALOGS

	; set correct response type

	mov	si, offset StandardDialogSummons
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset

	mov	ax, ss:[bp].SDP_customFlags
	test	ax, mask CDBF_SYSTEM_MODAL
	jz	notSysModal
	ornf	ds:[si].GII_attrs, mask GIA_SYS_MODAL
	andnf	ds:[si].GII_attrs, not mask GIA_MODAL
notSysModal:

	;
	; set correct GenInteractionType
	;	GIT_NOTIFICATION
	;	GIT_AFFIRMATION
	;	GIT_MULTIPLE_RESPONSE
	;
	;	ax = CustomDialogBoxFlags
	;
	andnf	ax, mask CDBF_INTERACTION_TYPE
	mov	cl, offset CDBF_INTERACTION_TYPE
	shr	ax, cl
	mov	ds:[si].GII_type, al
	cmp	al, GIT_MULTIPLE_RESPONSE
	jne	notMultipleResponse

	; handle GIT_MULTIPLE_RESPONSE:  create response triggers in the
	; summons

	call	CreateMultipleResponseTriggers

notMultipleResponse:


	; copy over correct string

	les	di, ss:[bp].SDP_customString
	mov	dx, di
if DBCS_PCGEOS
	LocalStrSize includeNULL
else
	clr	ax				;find string length
	mov	cx, -1
;	mov	cx, 1000
	repne	scasb
;	sub	cx, 1000
;	neg	cx				;cx = length
	not	cx
endif
	or	cx, CCM_FPTR shl offset CCF_MODE

	push	bp
	sub	sp, size CopyChunkOutFrame
	mov	bp, sp
	mov	ss:[bp].CCOF_source.segment, es
	mov	ss:[bp].CCOF_source.offset, dx
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].CCOF_dest.handle, ax
	mov	ss:[bp].CCOF_dest.chunk, offset StdDialogText
	mov	ss:[bp].CCOF_copyFlags, cx
	mov	dx, size CopyChunkOutFrame
	push	es
	segmov	es, ds				;so FIXUP_ES will not fail
	call	UserHaveProcessCopyChunkOver
	pop	es
	add	sp, size CopyChunkOutFrame
	pop	bp

	; deal with parameters

	mov	al, C_CTRL_A
	mov	cx, ss:[bp].SDP_stringArg1.segment
	mov	dx, ss:[bp].SDP_stringArg1.offset
	mov	si, offset StdDialogText
	call	SubstituteStringArg

	mov	al, C_CTRL_B
	mov	cx, ss:[bp].SDP_stringArg2.segment
	mov	dx, ss:[bp].SDP_stringArg2.offset
	call	SubstituteStringArg

	; create a help hint if needed

	mov	si, offset StandardDialogSummons
	call	CreateHelpHintIfNeeded

	call	MemUnlock
	pop	ax, si				;ax = handle
	xchg	ax, bx
	call	MemDerefDS
	mov_tr	bx, ax

	; add the summons as our child

	mov	cx, bx
	mov	dx, offset StandardDialogSummons

	; add the summons as the last child of the application.  We cannot add
	; it as the first child because the primary must be the first child.

	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di

	push	bp
	pushdw	cxdx
	mov	bp, CCO_LAST
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	popdw	bxsi					;bxsi = summons

	; mark the summons as usable

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	call	ObjMessageCallFixupDS

	pop	bp


	pop	di
	call	ThreadReturnStackSpace

	mov	bp, ss:[bp].SDP_customFlags
	mov	cx, bx		;Return new summons in cx:dx
	mov	dx, si
done:
	ret

OLApplicationBuildStandardDialog	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateHelpHintIfNeeded

DESCRIPTION:	Create a ATTR_GEN_HELP_CONTEXT if one was specified in the
		parameters

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenInteraction to add the hint to
	ss:bp - StandardDialogParams

RETURN:
	none

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 8/92		Initial version

------------------------------------------------------------------------------@
CreateHelpHintIfNeeded	proc	near	uses bx
	.enter

	movdw	bxdi, ss:[bp].SDP_helpContext
	tst	bx
	jz	done

	push	bx					;save virtual segment
	call	MemLockFixedOrMovable
if DBCS_PCGEOS
	mov	es, ax					;es:di <- context
	call	LocalStringSize
	LocalNextChar escx				;cx <- +2 bytes for NULL
else
	push	di
	mov	es, ax					;es:di = context
	mov	cx, 0xffff
	clr	ax
	repne	scasb
	pop	di
	not	cx					;cx = length
EC <	cmp	cx, 30							>
EC <	ERROR_A	USER_STANDARD_DIALOG_HELP_CONTEXT_TOO_LONG		>
endif
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

	;
	; If dialog is system modal, make sure the help controller knows this.
	;
	test	ss:[bp].SDP_customFlags, mask CDBF_SYSTEM_MODAL
	jz	done

	mov	cx, 1				; need 1 byte of data
	mov	ax, ATTR_GEN_HELP_TYPE
	call	ObjVarAddData
	mov	{byte}ds:[bx], HT_SYSTEM_MODAL_HELP

done:
	.leave
	ret

CreateHelpHintIfNeeded	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateMultipleResponseTriggers

DESCRIPTION:	Create response triggers for a GIT_MULTIPLE_RESPONSE
		dialog.

CALLED BY:	OLApplicationBuildStandardDialog

PASS:		ss:bp - StandardDialogParams
		bx - handle of new standard dialog block
		ds - segment of new standard dialog block

RETURN:		none

DESTROYED:	ax, cx, dx, di, si, es

PSEUDO CODE/STRATEGY:
	If the first trigger is an IC_YES trigger, and
	CDBF_DESTRUCTIVE_ACTION is set, then add a HINT_DEFAULT_FOCUS
	to the second trigger.  What a nightmare!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@

CreateMultipleResponseTriggers	proc	near

	push	bx				; dialog handle

	les	di, ss:[bp].SDP_customTriggers
	mov	cx, es:[di].SDRTT_numTriggers	; cx = trigger count
	jcxz	afterResponseTriggers

	add	di, offset SDRTT_triggers	; es:di = first trigger
	clr	dx				; trigger number, 0-based

createResponseTrigger:
	push	cx				; save trigger counter
	;
	; copy trigger template into standard dialog
	;	es:di = response trigger entry
	;
	call	CopyTriggerTemplate		; ^lbx:si = new trigger
						; (or ComplexExpandingMoniker
						;  if no chunk specified)
	;
	; copy moniker from table into trigger
	;	^lbx:si = new trigger
	;	es:di = response trigger entry
	;
	push	di, dx
	mov	ax, es:[di].SDRTE_moniker.chunk	; ^ldi:ax = moniker
	mov	di, es:[di].SDRTE_moniker.handle
	tst	di				; if no moniker, leave blank
						; (will use response value to
						;  determine moniker)
	jz	afterMoniker
	mov	cx, di				; ^lcx:dx = moniker
	mov	dx, ax

	push	bp
	mov	bp, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	ObjMessage
	pop	bp

afterMoniker:
	;
	; set trigger's response value from table
	;	^lbx:si = new trigger
	;	since we copied trigger into our block, we know that
	;	^lbx:si = *ds:si, so *ds:si = new trigger
	;

EC <	cmp	bx, ds:[LMBH_handle]					>
EC <	ERROR_NE	OL_ERROR					>
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	mov	cx, size word			; size of extra data
	call	ObjVarAddData			; ds:bx = extra data space
	pop	di, dx				; es:di = trigger entry
	mov	ax, es:[di].SDRTE_responseValue
	mov	ds:[bx], ax			; store response value

	;
	; If the dialog is a "destructive" one, then we want to keep
	; the focus from initially going to the first trigger, if that
	; trigger was an IC_YES trigger.  If the first trigger isn't
	; IC_YES, then no need to do anything.
	;

	test	ss:[bp].SDP_customFlags, mask CDBF_DESTRUCTIVE_ACTION
	jz	afterDestructive

	cmp	dx, 1		; are we on the second trigger?
	jne	afterDestructive

	; We're at the 2nd trigger.  Was the previous trigger an
	; IC_YES trigger?

	cmp	es:[di-size StandardDialogResponseTriggerEntry].SDRTE_responseValue, IC_YES
	jne	afterDestructive

	mov	ax, HINT_DEFAULT_FOCUS
	clr	cx
	call	ObjVarAddData
afterDestructive:

	;
	; add signalInteractionComplete as this is a UserDoDialog trigger and
	; must complete the interaction
	;	*ds:si = new trigger
	;

	mov	bx, ds:[si]			; deref.
	add	bx, ds:[bx].Gen_offset		; access generic stuff
	ornf	ds:[bx].GI_attrs, mask GA_SIGNAL_INTERACTION_COMPLETE
	;
	; loop back for next trigger, if any
	;
	add	di, size StandardDialogResponseTriggerEntry	; next one, pls
	pop	cx				; restore trigger counter
	inc	dx
	loop	createResponseTrigger
afterResponseTriggers:

	pop	bx				; dialog handle
	ret
CreateMultipleResponseTriggers	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyTriggerTemplate

DESCRIPTION:	Duplicate trigger template

CALLED BY:	CreateMultipleResponseTriggers

PASS:		ds - segment of new standard dialog block

RETURN:		^lbx:si - new trigger

DESTROYED:	ax, cx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/91		Initial version

------------------------------------------------------------------------------@

CopyTriggerTemplate	proc	near

	uses	di, es, bp, dx

	.enter

	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = dialog is parent
	mov	dx, offset StandardDialogSummons
	mov	bp, CCO_LAST			; add in order list in table
	mov	di, segment GenTriggerClass
	mov	es, di
	mov	di, offset GenTriggerClass
	mov	al, -1				; pass flag -- init USABLE
	clr	ah				; pass flag -- full linkage
	mov	bx, HINT_SEEK_REPLY_BAR		; put this puppy in reply bar
	call	OpenCreateChildObject
	mov	bx, cx				; ^lbx:si = new trigger
	mov	si, dx

	.leave
	ret
CopyTriggerTemplate	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SubstituteStringArg

DESCRIPTION:	Substitute a string for a character in a chunk

CALLED BY:	INTERNAL

PASS:
	*ds:si - chunk to substitute in
	al - arg # to substitute for
	cx:dx - string to substitute

RETURN:
	none

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@

SubstituteStringArg	proc	near	uses bx, si, es
if DBCS_PCGEOS

substString	local	fptr	push cx, dx
target		local	lptr	push si

else

substString	local	fptr
target		local	lptr
targetOffset	local	word

endif
	.enter

if DBCS_PCGEOS
	jcxz	done				;branch if no substition string

	clr	ah				;ax <- character
	clr	bx
else
	tst	cx
	jz	done
	mov	substString.handle, cx
	mov	substString.chunk, dx
	mov	target, si
	clr	targetOffset
endif

outerLoop:
SBCS <	mov	bx, targetOffset					>
	mov	si, target
	mov	di, ds:[si]
innerLoop:
SBCS <	mov	ah, ds:[di][bx]						>
DBCS <	mov	dx, ds:[di][bx]						>
SBCS <	tst	ah							>
DBCS <	tst	dx							>
	jz	done
SBCS <	cmp	al, ah							>
DBCS <	cmp	ax, dx							>
	jz	match
	inc	bx
DBCS <	inc	bx							>
	jmp	innerLoop

match:
SBCS <	mov	targetOffset, bx					>

	; find the string length

	push	ax				;save the compare value in AL
	les	di, substString
	mov	si, di
if DBCS_PCGEOS
	call	LocalStringLength		;cx <- length of subst string
	mov	dx, cx				;dx <- length of subst string
	dec	cx				;cx <- -1 for replaced char
	sal	cx, 1				;cx <- # bytes change
	mov	ax, ss:target			;ax <- chunk of target
	js	delete				;branch if removing bytes
else
	mov	cx, 1000
	clr	al
	repne	scasb
	sub	cx, 999-1			;since we will replace a char
	neg	cx				;cx = # bytes
	mov	ax, target
	cmp	cx, 0				;possible to substitute nothing
	jl	delete				;jump to remove bytes
endif
	call	LMemInsertAt
	mov	di, ax				;*ds:di = target
	mov	di, ds:[di]
SBCS <	add	di, targetOffset		;ds:di = dest		>
DBCS <	add	di, bx				;ds:di = dest		>
	segxchg	ds, es				;ds = source, es = dest
SBCS <	inc	cx							>
SBCS <	rep	movsb							>
DBCS <	mov	cx, dx				;cx <- # of chars	>
DBCS <	rep	movsw							>
	segmov	ds, es
	pop	ax				;restore compare value to AL
	jmp	outerLoop
delete:
	neg	cx				;make into a positive number
	call	LMemDeleteAt			;delete the byte(s)
	pop	ax				;restore compare value to AL
	jmp	outerLoop			;loop again

done:
	.leave
	ret

SubstituteStringArg	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationDoStandardDialog --
		MSG_GEN_APPLICATION_DO_STANDARD_DIALOG and
		MSG_GEN_APPLICATION_DO_STANDARD_TIMED_DIALOG for
		OLApplicationClass

DESCRIPTION:	Execute a standard dialog box.

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - The method

	For MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	dx - size StandardDialogParams
	ss:bp - StandardDialogParams
	For MSG_GEN_APPLICATION_DO_STANDARD_TIMED_DIALOG
	dx - size StandardTimedDialogParams
	ss:bp - StandardTimedDialogParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/90		Initial version

------------------------------------------------------------------------------@

OLApplicationDoStandardDialog	method dynamic	OLApplicationClass,
				MSG_GEN_APPLICATION_DO_STANDARD_DIALOG,
				MSG_GEN_APPLICATION_DO_STANDARD_TIMED_DIALOG
.assert	GADDP_dialog eq GADTDP_dialog
.assert	GADDP_finishOD eq GADTDP_finishOD
.assert	GADDP_message eq GADTDP_message

	push	ax			; save message

	; allocate a chunk to describe this dialog

	mov	al, mask OCF_IGNORE_DIRTY
	mov	cx, size OLAStdDialog
	call	LMemAlloc
	mov_tr	bx, ax				; *ds:bx <- descriptor
	mov	di, ds:[bx]

	; store OD and method

	movdw	ds:[di].OLASD_response.AD_OD, ss:[bp].GADDP_finishOD, ax
	mov	ax, ss:[bp].GADDP_message
	mov	ds:[di].OLASD_response.AD_message, ax

	mov	di, ss:[bp].GADTDP_timeout	; di = timeout, or garbage if
						;  dialog not timed

	; build the dialog box

	mov	ax, MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG
	call	ObjCallInstanceNoLock			;cx:dx = dialog

	pop	ax			; ax = GenApplicationMessages

	;
	; handle error from MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG
	; - brianc 8/6/93
	; send IC_NULL to  response - brianc 8/10/93
	;
	tst	cx
	jnz	haveDialog

	mov	di, ds:[bx]		; ds:di <- OLASD
	movdw	cxsi, ds:[di].OLASD_response.AD_OD
	mov	ax, ds:[di].OLASD_response.AD_message

	xchg	ax, bx		; ax <- data chunk, bx <- message
	call	LMemFree
	mov_tr	ax, bx		; ax <- message
	mov	bx, cx		; ^lbx:si <- response OD
	mov	cx, IC_NULL		; cx <- dialog response
	mov	di, mask MF_FORCE_QUEUE	; ensure we return before handling
	call	ObjMessage
	stc				; indicate no dialog displayed
	mov	cx, 0
	mov	dx, 0
	jmp	done			; exit with error and cx:dx = NULL

haveDialog:

	push	bp					;bp = dialog flags

	;
	; Create the timer if it's a timed dialog.
	;
	cmp	ax, MSG_GEN_APPLICATION_DO_STANDARD_TIMED_DIALOG
	mov	ax, 0			; assume no timer, ID = 0
	jne	afterTimer		; => not timed

	push	bx, cx, dx
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[OLMBH_header].LMBH_handle	; ^lbx:si = self
	mov	cx, di			; cx = timeout
	mov	dx, MSG_OL_APP_TIMED_DIALOG_TIMER_EXPIRED
	call	TimerStart		; bx = handle, ax = ID
	mov	bp, bx			; bp = handle
	pop	bx, cx, dx
afterTimer:

	;
	; Record the summons & link new chunk at the head of the list.
	;
	mov	di, ds:[bx]
	movdw	ds:[di].OLASD_summons, cxdx
	mov	ds:[di].OLASD_timerHandle, bp
	mov	ds:[di].OLASD_timerId, ax

	mov	bp, ds:[si]
	add	bp, ds:[bp].OLApplication_offset
	mov	ax, ds:[bp].OLAI_stdDialogs
	mov	ds:[di].OLASD_next, ax
	mov	ds:[bp].OLAI_stdDialogs, bx

	mov	bp, bx			; save chunk handle in BP

	; start the summons with our response action (not the callers!)

	mov	bx, cx
	xchg	dx, si					;bx:si = dialog
							;dx = OLApp chunk
	call	ObjSwapLock				;*ds:si = dialog
							;bx = OLApp block
	push	bx					;save it
	mov	ax, TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE
	mov	cx, size ActionDescriptor + size lptr	;extra data = AD + chunk
	call	ObjVarAddData				;ds:bx = extra data
	pop	ax					;ax = OLApp block
	mov	ds:[bx].AD_OD.handle, ax
	mov	ds:[bx].AD_OD.chunk, dx
	mov	ds:[bx].AD_message, MSG_OL_APP_DO_DIALOG_RESPONSE
	mov	{lptr}ds:[bx+size ActionDescriptor], bp
	mov_tr	bx, ax					;bx = OLApp block
	call	ObjSwapUnlock				;^lbx:si = dialog
							;ds = OLApp segment
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageCallFixupDS
	;
	; TEMP_GEN_INTERACTION_WITH_ACTION_RESPONSE is removed in
	; MSG_OL_APP_DO_DIALOG_RESPONSE when we destroy duplicated
	; dialog block
	;

	; MAKE APPROPRIATE SOUND.

	pop	ax					;dialog flags
	and	ax, mask CDBF_DIALOG_TYPE
	mov	bx, SST_ERROR
	cmp	ax, CDT_ERROR shl offset CDBF_DIALOG_TYPE
	je	haveSound
	mov	bx, SST_WARNING
	cmp	ax, CDT_WARNING shl offset CDBF_DIALOG_TYPE
	jne	10$
haveSound:
	mov_tr	ax, bx
	call	UserStandardSound
10$:

	clc						;return no error
done:
	ret

OLApplicationDoStandardDialog	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationDoDialogResponse --
		MSG_OL_APP_DO_DIALOG_RESPONSE for OLApplicationClass

DESCRIPTION:	Finish a standard dialog box.

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - MSG_OL_APP_DO_DIALOG_RESPONSE

	cx - response from dialog
	dx - chunk handle of data describing the dialog

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/90		Initial version

------------------------------------------------------------------------------@

OLApplicationDoDialogResponse	method dynamic	OLApplicationClass,
					MSG_OL_APP_DO_DIALOG_RESPONSE

	push	cx				;save response value

	; find data chunk in list and unlink it
	; ds:di	= pointer in prev to current
	add 	di, offset OLAI_stdDialogs - offset OLASD_next
findDataLoop:
	cmp	ds:[di].OLASD_next, dx	; next is data chunk?
	je	foundIt			; yes
	mov	bx, ds:[di].OLASD_next	; *ds:bx <- next
EC <	tst	bx							>
EC <	ERROR_Z	OL_STANDARD_DIALOG_DATA_CHUNK_NOT_FOUND			>
	mov	di, ds:[bx]
	jmp	findDataLoop

foundIt:
	mov	bp, dx			; *ds:bp <- data chunk
	mov	bp, ds:[bp]
	mov	ax, ds:[bp].OLASD_next
	mov	ds:[di].OLASD_next, ax

	; stop the time if it's a timed dialog, because we don't know at this
	; point if it has expired yet.

	mov	ax, ds:[bp].OLASD_timerId
	tst	ax
	jz	afterTimer		; => no timer
	mov	bx, ds:[bp].OLASD_timerHandle
	call	TimerStop
afterTimer:

	; remove dialog box

	push	si, dx
	movdw	cxdx, ds:[bp].OLASD_summons

	pushdw	cxdx			; save for setting not-usable

	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ss:[bp].GCNLP_optr.handle, cx
	mov	ss:[bp].GCNLP_optr.chunk, dx
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	ObjCallInstanceNoLock
	add	sp, size GCNListParams

	popdw	bxsi				; ^lbx:si <- dialog
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjMessageCallFixupDS
	movdw	cxdx, bxsi			;cx:dx = dialog

	pop	si, bx				;*ds:si = app
						;*ds:bx = OLASD

EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	cmp	ds:[di].VCNI_focusExcl.FTVMC_OD.handle, cx		>
EC <	ERROR_Z	OL_ERROR_STANDARD_DIALOG_BLOCK_BEING_FREED_STILL_HAS_GRAB   >
EC <	cmp	ds:[di].OLAI_modalWin.handle, cx		>
EC <	ERROR_Z	OL_ERROR_STANDARD_DIALOG_BLOCK_BEING_FREED_STILL_HAS_GRAB   >

	clr	bp
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock


	; free the dialog block

	mov	ax, MSG_META_BLOCK_FREE
	call	ObjMessageCallPreserveCXDXWithSelf

	; send the response back to the sender of
	;  MSG_GEN_APPLICATION_DO_STANDARD_DIALOG after freeing the data chunk

	mov	di, ds:[bx]		; ds:di <- OLASD
	movdw	cxsi, ds:[di].OLASD_response.AD_OD
	mov	ax, ds:[di].OLASD_response.AD_message

	xchg	ax, bx		; ax <- data chunk, bx <- message
	call	LMemFree
	mov_tr	ax, bx		; ax <- message
	mov	bx, cx		; ^lbx:si <- response OD
	pop	cx		; cx <- dialog response
	mov	di, mask MF_FIXUP_DS	; DO NOT CALL -- might be on different
					;  thread if started with MSG_GEN_APP_
					;  DO_STANDARD_DIALOG
	GOTO	ObjMessage

OLApplicationDoDialogResponse	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationTimedDialogTimerExpired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timeout for a timed dialog has occurred.

CALLED BY:	MSG_OL_APP_TIMED_DIALOG_TIMER_EXPIRED

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		bp	= timer ID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/22/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationTimedDialogTimerExpired	method dynamic OLApplicationClass,
					MSG_OL_APP_TIMED_DIALOG_TIMER_EXPIRED

	;
	; Try to find OLAStdDialog chunk for this timer, to see if the user
	; has responded to the dialog just before the timer expired.
	;
	add 	di, offset OLAI_stdDialogs - offset OLASD_next
findDataLoop:
	mov	bx, ds:[di].OLASD_next	; *ds:bx = OLAStdDialog
	tst	bx
	jz	done			; => not found, user already responded
	mov	di, ds:[bx]		; ds:di = OLAStdDialog
	cmp	ds:[di].OLASD_timerId, bp
	jne	findDataLoop		; =>dialog not timed or timer not match

	;
	; Chunk found.  Respond to this dialog with IC_NULL.
	;
	mov	ax, MSG_OL_APP_DO_DIALOG_RESPONSE
		CheckHack <IC_NULL eq 0>
	clr	cx			; cx = IC_NULL
	mov	dx, bx			; dx = OLAStdDialog chunk handle
	call	ObjCallInstanceNoLock

done:
	ret
OLApplicationTimedDialogTimerExpired	endm


StandardDialog	ends
CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationStartTimer --
		MSG_OL_APP_START_TIMER for OLApplicationClass

DESCRIPTION:	Starts a timer up for an object that has the gadget exclusive.
		The object must also have the active grab, and must handle
		a MSG_GADGET_REPEAT_PRESS, sending it on to the application
		object (this object).

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_APP_START_TIMER

		cx:dx	- OD to send MSG_TIMER_EXPIRED
		bp	- number of ticks until expiration, or zero for
			  standard olGadgetRepeatDelay from the .ui file.

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/31/90		Initial version

------------------------------------------------------------------------------@

OLApplicationStartTimer	method OLApplicationClass, MSG_OL_APP_START_TIMER
EC <	xchg	bx, cx				;make sure OD OK	      >
EC <	xchg	si, dx							      >
EC <	call	ECCheckOD				      		      >
EC <	xchg	bx, cx				;make sure OD OK	      >
EC <	xchg	si, dx							      >
	tst	bp				;see if standard time desired
	jnz	10$				;nope, branch

	push	ds
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	mov	bp, ds:[olGadgetRepeatDelay]	;use standard value
	pop	ds
10$:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
EC <	tst	ds:[di].OLAI_timerOD.chunk	;error if one already running >
EC <	ERROR_NZ OL_TIMER_STARTED_WHILE_ONE_ALREADY_RUNNING		      >
	mov	ds:[di].OLAI_timerOD.chunk,dx	;save OD
	mov	ds:[di].OLAI_timerOD.handle,cx	;

	mov	cx, bp				;put delay in cx
	mov	bx, ds:[LMBH_handle]
	mov	dx, MSG_TIMER_EXPIRED
	mov	ax, TIMER_EVENT_ONE_SHOT
	call	TimerStart			;

;	Commented out until we decide to send repeat events through the IM
; 	queue again.
;	mov	cx, bp				;put delay in cx
;	mov	bx, handle im			;pass handle of input manager
;	push	si
;	clr	si				;send to the process...
;	mov	dx, MSG_GADGET_REPEAT_PRESS
;	mov	ax, TIMER_EVENT_ONE_SHOT
;	call	TimerStart			;
;	pop	si

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	ds:[di].OLAI_timerID, ax	;save these
	mov	ds:[di].OLAI_timerHandle, bx
	ret
OLApplicationStartTimer	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationStopTimer --
		MSG_OL_APP_STOP_TIMER for OLApplicationClass

DESCRIPTION:	Stops a previously started timer, if any.  An object that
		starts a timer and loses the gadget exclusive MUST call this
		routine.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_APP_STOP_TIMER
		^lcx:dx - OD handle

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/31/90		Initial version

------------------------------------------------------------------------------@

OLApplicationStopTimer	method OLApplicationClass, MSG_OL_APP_STOP_TIMER
EC <	xchg	bx, cx				;make sure OD OK	      >
EC <	xchg	si, dx							      >
EC <	call	ECCheckOD				      		      >
EC <	xchg	bx, cx				;make sure OD OK	      >
EC <	xchg	si, dx							      >

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	;
	; Added 10/29/90 cbh to fix a problem where the port window is blindly
	; turning off timers that it didn't start.  Really the port window
	; should be fixed, but it'll have to wait until later.
	;
	cmp	cx, ds:[di].OLAI_timerOD.handle	;not the right timer, forget it
	jnz	exit				;  (should eventually be a
	cmp	dx, ds:[di].OLAI_timerOD.chunk	;   a fatal error)
	jnz	exit

	clr	ax
	xchg	ax, ds:[di].OLAI_timerID	;turn off timer, if any
	clr	bx
	xchg	bx, ds:[di].OLAI_timerHandle
	clr	ds:[di].OLAI_timerOD.handle	;clear old OD
	clr	ds:[di].OLAI_timerOD.chunk	;clear old chunk
	tst	bx
	jz	exit
	call	TimerStop
exit:
	ret
OLApplicationStopTimer	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationTimerExpired --
		MSG_TIMER_EXPIRED for OLApplicationClass

DESCRIPTION:	Sent by gadget when done (it gets it from the timer); we will
		send it off to our timerOD and clear the timer instance data.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_TIMER_EXPIRED
		cx,dx	- tick count
		bp	- ID of timer that expired

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/31/90		Initial version

------------------------------------------------------------------------------@
;Repeat press stuff commented out until we decide to send repeat events
;through the IM queue again.
;OLApplicationRepeatPress	method OLApplicationClass, \
;				MSG_GADGET_REPEAT_PRESS

OLApplicationTimerExpired	method OLApplicationClass, MSG_TIMER_EXPIRED
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	cmp	ds:[di].OLAI_timerID, bp	;see if timer ID matches
	jne	exit				;no, it's an old timer, exit
	clr	si
	xchg	si, ds:[di].OLAI_timerOD.chunk	;get chunk (and clear it)
	clr	bx
	xchg	bx, ds:[di].OLAI_timerOD.handle	;get handle
	tst	si
	jz	exit				;no OD anymore, exit
	tst	ds:[di].OLAI_timerHandle	;timer's been canceled, exit
	jz	exit
	clr	ds:[di].OLAI_timerHandle	;clear old timer info
	clr	ds:[di].OLAI_timerID		;
	clr	di				;no flags to ObjMessage
;	mov	ax, MSG_TIMER_EXPIRED
	call	ObjMessage			;send same method on to OD.
exit:
	ret
OLApplicationTimerExpired	endm

;OLApplicationRepeatPress	endm






COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationStartSelect --
		MSG_META_START_SELECT for OLApplicationClass

DESCRIPTION:	Mouse button stuff.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_START_SELECT
		cx, dx, bp	- mouse data

RETURN:		ax	- mask MRF_PROCESSED
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/ 3/92         	Initial Version

------------------------------------------------------------------------------@

OLApplicationStartSelect	method dynamic	OLApplicationClass,
						MSG_META_START_SELECT,
						MSG_META_START_MOVE_COPY
	call	NukeExpressMenu

	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock

OLApplicationStartSelect	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	NukeExpressMenu

SYNOPSIS:	Gets rid of any express menus in stay up mode.

CALLED BY:	OLApplicationStartSelect, OLApplicationQueryIfPressIsInk

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 3/92       	Initial version

------------------------------------------------------------------------------@

NukeExpressMenu	proc	near

	; At this point the express menu may be hanging around.  Let's get
	; rid of it if it's there.  (Added cbh 11/ 3/92)  (Moved here
	; from OLWinStartSelect 12/ 3/92 cbh).
	;
	push	ax, cx, dx, bp
	push	si
	clrdw	cxdx
	mov	ax, MSG_OL_FIELD_RELEASE_EXPRESS_MENU
	mov	bx, segment OLFieldClass	; for OLFieldClass
	mov	si, offset OLFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	pop	si				; *ds:si = this object
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	ret
NukeExpressMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that a GWNT_HARD_ICON_BAR_FUNCTION or
		GWNT_STARTUP_INDEXED_APP has occurred - do a
		NukeExpressMenu.

CALLED BY:	MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK

		cx	= ManufacturerId
		dx	= NotificationType
		bp	= data

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/22/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationNotify	method	dynamic	OLApplicationClass, MSG_META_NOTIFY,
						MSG_META_NOTIFY_WITH_DATA_BLOCK
	;
	; make sure we've got what we're looking for
	;
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
if DYNAMIC_SCREENN_RESIZING
	cmp	dx, GWNT_HOST_SCREEN_FIELD_SIZE_CHANGE
	jne	handleExpress

	mov	ax, MSG_OL_WIN_PREPARE_FIELD_SIZE_CHANGE
	call	VisSendToChildren

	;
	;  Resize ourselves.
	;
	mov	ax, MSG_VIS_GET_SIZE
	call	VisCallParent
	

	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock
	
	;
	;  Tell our primary windows to resize.
	;
	mov	ax, MSG_OL_WIN_FIELD_SIZE_CHANGED
	call	VisSendToChildren

	jmp	callSuper

handleExpress:
endif
	cmp	dx, GWNT_STARTUP_INDEXED_APP
	je	nukeExpress
	cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
	jne	callSuper
	cmp	bp, HIBF_TOGGLE_EXPRESS_MENU
	je	callSuper	; don't close E-menu if we're going to open it
nukeExpress:
	call	NukeExpressMenu
callSuper:
	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock

OLApplicationNotify	endm

CommonFunctional	ends
KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationTestForCancelMnemonic --
		MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC for OLApplicationClass

DESCRIPTION:	Tests for cancel mnemonic for the specific UI.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if match found
		cx, dx, bp - preserved
		ax - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 8/91		Initial version

------------------------------------------------------------------------------@

OLApplicationTestForCancelMnemonic	method dynamic	OLApplicationClass, \
				MSG_GEN_APPLICATION_TEST_FOR_CANCEL_MNEMONIC
	;
	; ignore modified ESC as they may be needed for shortcuts
	;
	test	dh, mask SS_LSHIFT or mask SS_RSHIFT or \
			mask SS_LCTRL or mask SS_RCTRL or \
			mask SS_LALT or mask SS_RALT
	jnz	noMatch
SBCS <	cmp	cl, VC_ESCAPE			 ;If ESCAPE key pressed, >
DBCS <	cmp	cx, C_SYS_ESCAPE		 ;If ESCAPE key pressed, >
	jne	noMatch
	stc
	jmp	short exit
noMatch:
	clc
exit:
	Destroy	ax
	ret
OLApplicationTestForCancelMnemonic	endm

KbdNavigation	ends
ActionObscure	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationToggleCurrentMenuBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	toggle current GenPrimary's menu bar, if togglable

CALLED BY:	MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR

PASS:		*ds:si	= class object
		ds:di	= class instance data
		es 	= segment of class
		ax	= MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/25/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationToggleCurrentMenuBar	method	dynamic	OLApplicationClass,
				MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR

	;
	; get current GenPrimary
	;
	mov	ax, MSG_META_GET_TARGET_EXCL
	call	ObjCallInstanceNoLock		; ^lcx:dx = target
	jnc	done				; no target, give up
	;
	; check if a OLBaseWin (GenPrimary)
	;
	movdw	bxsi, cxdx			; ^lbx:si = target
	mov	cx, segment OLBaseWinClass
	mov	dx, offset OLBaseWinClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; carry set if so
	jnc	done				; not a OLBaseWin, give up
	;
	; tell OLBaseWin (GenPrimary) to toggle menu bar
	;	^lbx:si = OLBaseWin
	;
	mov	ax, MSG_OL_BASE_WIN_TOGGLE_MENU_BAR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
OLApplicationToggleCurrentMenuBar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationToggleExpressMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	toggle parent field's express menu.

CALLED BY:	MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU

PASS:		*ds:si	= class object
		ds:di	= class instance data
		es 	= segment of class
		ax	= MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/30/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _EXPRESS_MENU

OLApplicationToggleExpressMenu	method	dynamic	OLApplicationClass,
					MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU

	;
	; Make sure we actually are on a GenFieldClass object
	;
	mov	cx, segment OLFieldClass
	mov	dx, offset OLFieldClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	GenCallParent
	jnc	noParentField			;if not, use default field
	;
	; else, tell it to toggle express menu
	;
	mov	ax, MSG_OL_FIELD_TOGGLE_EXPRESS_MENU
	call	GenCallParent
	ret

noParentField:
	;
	; use default field, so UIApp can bring up Express menu
	;
	mov	ax, MSG_GEN_SYSTEM_GET_DEFAULT_FIELD
	call	UserCallSystem			; ^lcx:dx = current field
	movdw	bxsi, cxdx			; ^lbx:si = current field
	mov	ax, MSG_OL_FIELD_TOGGLE_EXPRESS_MENU
	clr	di
	GOTO	ObjMessage

OLApplicationToggleExpressMenu	endm

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationQuerySaveDocuments --
		MSG_META_QUERY_SAVE_DOCUMENTS for OLApplicationClass

DESCRIPTION:	Save documents on an app switch.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_QUERY_SAVE_DOCUMENTS
		cx	- event

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
	chris	7/26/93         	Initial Version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

OLApplicationQuerySaveDocuments	method dynamic	OLApplicationClass, \
				MSG_META_QUERY_SAVE_DOCUMENTS

	push	ax, cx
	mov	ax, MSG_META_GET_MODEL_EXCL
	call	ObjCallInstanceNoLock		;in ^lcx:dx, no doubt
	movdw	bxsi, cxdx			;send on to document control
	pop	ax, cx

	tst	si				;no model, we'll give up and
	jz	returnQuery			; allow app switching.

	clr	di				;else send on to model
	GOTO	ObjMessage

returnQuery:
	mov	bx, cx
	mov	di, mask MF_FORCE_QUEUE
	call	MessageDispatch

	ret
OLApplicationQuerySaveDocuments	endm

endif




COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationGainedFullScreenExcl --
		MSG_META_GAINED_FULL_SCREEN_EXCL for OLApplicationClass

DESCRIPTION:	Hack to force the model to match the target when the application
		comes to the front.  Currently the document control stuff
		is forced to muck with the model exclusive when saving documents
		prior to switching apps, so that the model document is not on
		top.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_GAINED_FULL_SCREEN_EXCL

RETURN:
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/30/93         	Initial Version

------------------------------------------------------------------------------@

if	VOLATILE_SYSTEM_STATE

OLApplicationGainedFullScreenExcl	method dynamic	OLApplicationClass, \
				MSG_META_GAINED_FULL_SCREEN_EXCL

	;
	; Make the target document grab the model exclusive again. 8/30/93 cbh
	;
	push	si
	mov	si, offset GenDocumentClass		;class of destination
	mov	bx, segment GenDocumentClass
	mov	ax, MSG_META_GRAB_MODEL_EXCL
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di					;event
	pop	si

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_APP_TARGET
	GOTO	ObjCallInstanceNoLock

OLApplicationGainedFullScreenExcl	endm

endif 	; VOLATILE_SYSTEM_STATE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationAppShutdown --
		MSG_META_APP_SHUTDOWN for OLApplicationClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	We're shutting down the app.  Subclassed here so the
		app can re-enable the express menu, if it's disabled,
		to cover up problems with switching apps quickly in
		Redwood.

		Menu disabling happens in the express menu code -- see
		cwinField.asm

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_APP_SHUTDOWN

RETURN:
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 8/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if LIMITED_HEAPSPACE

OLApplicationAppShutdown	method dynamic	OLApplicationClass, \
				MSG_META_APP_SHUTDOWN
	.enter
	mov	ax, MSG_GEN_FIELD_ENABLE_EXPRESS_MENU
	call	GenCallParent
	.leave
	ret
OLApplicationAppShutdown	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppRotateDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate ourselves.

CALLED BY:	MSG_GEN_ROTATE_DISPLAY

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if RECTANGULAR_ROTATION

OLAppRotateDisplay	method dynamic OLApplicationClass,
					MSG_GEN_ROTATE_DISPLAY
		uses	ax, cx, dx, bp
		.enter
	;
	;  Resize ourselves.
	;
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		xchg	cx, dx
		mov	ax, MSG_VIS_SET_SIZE
		call	ObjCallInstanceNoLock
	;
	;  Tell our primary windows to resize.
	;
		mov	ax, MSG_GEN_ROTATE_DISPLAY
		call	VisSendToChildren

		.leave
		ret
OLAppRotateDisplay	endm

endif	; RECTANGULAR_ROTATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppUpdateWindowsForTaskBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update windows to account for change in taskbar position

CALLED BY:	MSG_OL_APP_UPDATE_WINDOWS_FOR_TASK_BAR

PASS:		*ds:si	= OLApplicationClass object
		es 	= segment of OLApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	7/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TOOL_AREA_IS_TASK_BAR
OLAppUpdateWindowsForTaskBar	method dynamic OLApplicationClass,
					MSG_OL_APP_UPDATE_WINDOWS_FOR_TASK_BAR
	; close menus

	;
	; if TaskBar == on
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds
	jz	done					; skip if no taskbar

	call	OLReleaseAllStayUpModeMenus

	push	si
	mov	bx, segment OLWinClass
	mov	si, offset OLWinClass
	mov	ax, MSG_OL_WIN_UPDATE_POSITION_FOR_TASK_BAR
	mov	cx, FALSE
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	mov	cx, di
	call	ObjCallInstanceNoLock

	; now do something for windows that have been minimized

	push	si
	mov	bx, segment OLWinClass
	mov	si, offset OLWinClass
	mov	ax, MSG_OL_WIN_UPDATE_POSITION_FOR_TASK_BAR
	mov	cx, TRUE
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	mov	cx, di
	GOTO	ObjCallInstanceNoLock
done:
	ret

OLAppUpdateWindowsForTaskBar	endm
endif

ActionObscure	ends
