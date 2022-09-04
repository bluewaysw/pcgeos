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

    INT RudyCheckHotKeys        Checks for special Rudy "hot keys".

    INT OLAppTestJediKeys       Do special things for special people.

    INT CloseOpenMenus          close open menus via GAGCNLT_WINDOWS list

    INT COM_callback            close open menus via GAGCNLT_WINDOWS list

    INT FindGenEditControl      find GenEditControl

    INT FindGenEditControlCB    Return if this is a popup window.

    INT LaunchJotterApp         User pressed "Jotter" key.

    INT CheckHotkeyApps         Toggle hotkey applications (Typewriter and
				BigCalc)

    INT HandlePrinterKeys       Check for Printer keys

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

    INT RudySendMonikerToIndicator 
				Copies the size and the given moniker to a
				data block, and actually sends the block to
				a GCN list.

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

	$Id: copenAppMisc.asm,v 1.74 97/03/04 21:38:29 cassie Exp $

------------------------------------------------------------------------------@

NKE <	include	Internal/printDr.def	>

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
if _NIKE
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	noUpdate

	; Update the keyboard status buttons
	;
	cmp	cx, VC_ISCTRL shl 8 or VC_CAPSLOCK
	je	updateStatus
	cmp	cx, VC_ISCTRL shl 8 or VC_NUMLOCK
	je	updateStatus
	cmp	cx, VC_ISCTRL shl 8 or VC_INS
	jne	noUpdate
	test	dh, mask SS_LALT or mask SS_RALT or mask SS_LCTRL or \
		    mask SS_RCTRL or mask SS_LSHIFT or mask SS_RSHIFT
	jnz	noUpdate

	push	ax
	call	UserGetOverstrikeMode
	mov	al, 0xff
	jz	setMode
	clr	al
setMode:
	call	UserSetOverstrikeMode
	pop	ax

updateStatus:
	push	ax
	mov	ax, MSG_OL_FIELD_UPDATE_KBD_STATUS_BUTTONS
	call	GenCallParent			; call field
	pop	ax
noUpdate:
endif

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
if _JEDIMOTIF
	LONG	jnz	jediCallField
else
	LONG jnz callField			; if active, just send on to
						; field & do nothing else.
endif	; _JEDIMOTIF
	
processKbdChar:
	test	dl,mask CF_RELEASE or mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	LONG jnz	doLocalShortcuts		;ignore if not press.

NKE <	call	CheckHotkeyApps						>
NKE <	jc	done				;done if hotkey		>

NKE <	push	di							>
NKE <	call	HandlePrinterKeys					>
NKE <	pop	di							>
NKE <	jc	done				;done if printer key	>

if _JEDIMOTIF
	call	DoJediKbdProcessing
	jc	done				; carry set if handled
endif	; _JEDIMOTIF

if _RUDY
	call	RudyCheckHotKeys
	LONG jc	done				; done if hotkey
endif

	;
	; If .ini flag says not to process kbd accelerators, don't
	;
	call	UserGetKbdAcceleratorMode	; Z set if off
	LONG jz	afterLocalShortcuts		; skip all shortcuts

if (not _JEDIMOTIF)		; no help key for Jedi
	;
	; Special case <F1> for help -- we want this to bring up
	; help even for modal dialogs  (Ctrl-H in Redwood. 9/13/93 cbh)
	;
if	_REDMOTIF
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	notHelp
	cmp	cx, 'H'
	je	doLocalShortcuts
	cmp	cx, 'h'				;it seems 'h' is generated
elif _RUDY
SBCS <	cmp	cx, VC_INS or (CS_CONTROL shl 8)			>
DBCS <	cmp	cx, C_SYS_INS						>
else
SBCS <	cmp	cx, VC_F1 or (CS_CONTROL shl 8)				>
DBCS <	cmp	cx, C_SYS_F1						>
endif
	je	doLocalShortcuts		;branch if help

notHelp:
endif		; (not _JEDIMOTIF)

if _JEDIMOTIF
	;
	; eat accelerator handled by OLItem
	;
	cmp	cx, (CS_CONTROL shl 8) or VC_NULL
	je	bringUpMenus
endif

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

if _JEDIMOTIF
	;
	; beep if not used
	;
	jc	bringUpMenus			;accelerator match in dialog
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
endif ; _JEDIMOTIF

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
   
if not (_JEDIMOTIF or _RUDY)
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
endif	; not _JEDIMOTIF
	
afterLocalShortcuts:
endif	;----------------------------------------------------------------------

callField:
if _JEDIMOTIF
	;
	;  Test for various special jedi keys.
	;
	call	OLAppTestJediKeys
	jc	done
jediCallField:
endif	; _JEDIMOTIF
	mov	ax, MSG_META_FUP_KBD_CHAR
	call	GenCallParent			;send to field
done:
	pop	di
	call	ThreadReturnStackSpace
	ret
	
OLApplicationFupKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoJediKbdProcessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maybe send MSG_META_QUIT or MSG_META_TRANSPARENT_DETACH.

CALLED BY:	OLApplicationFupKbdChar

PASS:		*ds:si = app obj

RETURN:		ds:di = OLApp instance ptr
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	if CTRL_F5_QUITS_APP is set, allow FN-F5 to send MSG_META_QUIT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/ 6/96		broken out of OLApplicationFupKbdChar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _JEDIMOTIF
DoJediKbdProcessing	proc	near

if CTRL_F5_QUITS_APP

	; 
	;  These keystrokes (FN-F3 and FN-F5) get along poorly.  We
	;  don't allow them if the app is going down in any sort of way.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, (mask AS_DETACHING or \
				     mask AS_QUITTING or \
				     mask AS_TRANSPARENT_DETACHING or \
				     mask AS_QUIT_DETACHING)
	lahf
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	sahf
	jnz	noDetachJedi			; don't do if detaching
	
	;
	;  Code stolen from Rudy to transparently detach the app if
	;  the user hits Ctrl-F3.  Because Rudy's trunk-only, and
	;  Jedi is on Release20X, I'm just stealing the code here
	;  to help deal with merge problems.
	;
	mov	ax, MSG_META_TRANSPARENT_DETACH
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F3				>
DBCS <	cmp	cx, C_SYS_F3						>
	je	checkCtrlKey
checkF5::
	mov	ax, MSG_META_QUIT
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F5				>
DBCS <	cmp	cx, C_SYS_F5						>
	jne	noDetachJedi

checkCtrlKey:
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	noDetachJedi
	
if not ERROR_CHECK
	;
	;  Make it "non-sticky" for the actual hardware.  I.e. don't do
	;  it unless they really mean it.
	;
	test	dl, mask TS_FNCTSTICK
	jnz	noDetachJedi
endif	
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage
if 0
	;
	;  Debugging beeps.
	;
	mov	bx, SST_ERROR
	cmp	ax, MSG_META_QUIT
	je	doSound
	mov	bx, SST_WARNING
doSound:
	mov	ax, bx
	call	UserStandardSound
endif
	stc	
	jmp	done
else	; not CTRL_F5_QUITS_APP
	;
	;  Code stolen from Rudy to transparently detach the app if
	;  the user hits Ctrl-F3.  Because Rudy's trunk-only, and
	;  Jedi is on Release20X, I'm just stealing the code here
	;  to help deal with merge problems.
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F3				>
DBCS <	cmp	cx, C_SYS_F3						>
	jne	noDetachJedi
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	noDetachJedi
if not ERROR_CHECK
	;
	; Make it "non-sticky" for the actual hardware.
	;
	test	dl, mask TS_FNCTSTICK
	jnz	noDetachJedi
endif	; not ERROR_CHECK
		
	mov	ax, MSG_META_TRANSPARENT_DETACH
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	stc	
	jmp	done
noDetachJedi:
endif		; CTRL_F5_QUITS_APP
noDetachJedi:
	clc
done:
	ret
DoJediKbdProcessing	endp
endif	; _JEDIMOTIF

if _RUDY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RudyCheckHotKeys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for special Rudy "hot keys".

CALLED BY:	OLApplicationFupKbdChar
PASS:		*ds:si 	- instance data
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code
RETURN:		carry set if hotkey was processed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		EC-only: Ctrl-F3 is transparent detach
			 Ctrl-F4 is quit

		Insert key is help key

		F5 thru F12, and Ctrl-F12 are hot keys

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	reza	4/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RudyCheckHotKeys	proc	near
	.enter
if	ERROR_CHECK

;	EC code to transparently detach the app if the user hits Ctrl-F3
;		OR quit the app if the user hits Ctrl-F4

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F3	;F3 key?		>
DBCS <	cmp	cx, C_SYS_F3						>
	jne	noDetach

 	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	noDetach			;Ctrl not pressed, skip

; Ctrl-F3 = transparent detach
;
; First make sure that the GenApplication does not have the
; AS_AVOID_TRANSPARENT_DETACH bit set.  We do this so we can emulate the
; transparent detach code which ignores apps with this bit set.  

	push	bx, si, di	
	clr	bx
	call	GeodeGetAppObject		; ^lbx:si <- Application obj
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax <- ApplicationStates
	pop	bx, si, di
		
	test	ax, mask AS_AVOID_TRANSPARENT_DETACH
	jnz	noDetach

	mov	ax, MSG_META_TRANSPARENT_DETACH
	jmp	detachOrQuit
noDetach:
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F4	;F4 key?		>
DBCS <	cmp	cx, C_SYS_F4						>
	jne	noQuit

 	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	noQuit				;Ctrl not pressed, skip

; Ctrl-F4 = quit

	mov	ax, MSG_META_QUIT
detachOrQuit:
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage
	stc	
	jmp	done
noQuit:
endif	; ERROR_CHECK

	;
	; Check if help pressed. The help key varies depending on the
	; hardware type:
	;
	;	PC emulator	= shift-HELP key (emulate Lizzy)
	;	Responder	= HELP key
	;	Lizzy		= shift-HELP key
	;
	cmp	cx, RUDY_HELP_CHAR
	jne	notHelp

	push	ax
	call	RespGetPDAHardwareInfo		; al -> flags
	andnf	al, mask PDAHI_PDA_TYPE
	cmp	al, PDAT_N9000
	pop	ax
	je	checkNoShift

	;
	; Check for shift
	;
	test	dh, not (mask SS_LSHIFT or mask SS_RSHIFT)
	jnz	notHelp
	test	dh, mask SS_LSHIFT or mask SS_RSHIFT
	jz	notHelp
	jmp	isHelp

checkNoShift:	
	tst	dh				; any ShiftState ?
	jnz	notHelp
isHelp:
	mov	ax, MSG_GEN_APPLICATION_BRING_UP_HELP
	call	ObjCallInstanceNoLock
	stc
	jmp	done
notHelp:

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F5		;F5 key?	>
DBCS <	cmp	cx, C_SYS_F5				;F5 key?	>
	jb	afterAppCheck
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F12	;F12 key?	>
DBCS <	cmp	cx, C_SYS_F12				;F12 key?	>
	ja	afterAppCheck

	pushf
SBCS <	sub	cx, (CS_CONTROL shl 8) or VC_F5				>
DBCS <	sub	cx, C_SYS_F5						>
	popf						;preserve whether F12

	;
	; If ctrl is pressed and it's F12, pretend F13.
	;
	jne	noCtrl					;wasn't F12, branch
	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	noCtrl
	inc	cx
noCtrl:
	mov	bp, cx
	mov	cx, MANUFACTURER_ID_GEOWORKS	
	mov	dx, GWNT_STARTUP_INDEXED_APP
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_META_NOTIFY
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	stc
	jmp	done

afterAppCheck:
	clc
done:
	.leave
	ret
RudyCheckHotKeys	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppTestJediKeys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do special things for special people.

CALLED BY:	OLApplicationFupKbdChar

PASS:		*ds:si = app object
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if key handled
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This probably ought to be table-driven.  I had no
 	idea when I first wrote the routine that there would
	be so many special keys to check.  -stevey

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

OLAppTestJediKeys	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Only interested in first press, thank you.
	;
		test	dl, mask CF_FIRST_PRESS
		LONG	jz	passUp
		test	dl, mask CF_RELEASE
		LONG	jnz	passUp
testUChars::
	;
	;  Send clipboard keys to Edit control.
	;
		mov	ax, MSG_META_CLIPBOARD_CUT
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_CUT
		je	sendEventToEditControl

		mov	ax, MSG_META_CLIPBOARD_COPY
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_COPY
		je	sendEventToEditControl

		mov	ax, MSG_META_CLIPBOARD_PASTE
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_PASTE
		je	sendEventToEditControl

		mov	ax, MSG_META_DELETE
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_DELETE
		je	sendEventToEditControl
	;
	;  Exit key -- "quit" the app.
	;
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_EXIT
		jne	notExit

		mov	ax, MSG_GEN_LOWER_TO_BOTTOM
		call	ObjCallInstanceNoLock
		jmp	handled
notExit:
	;
	;  Jotter key - launch Jotter app.
	;
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_JOTTER
		jne	notJotter

		call	LaunchJotterApp
		jmp	handled
notJotter:
	;
	;  Lock sequence - lock the screen.
	;
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_LOCK
		jne	notLock

		mov	bx, handle ui
		mov	ax, MSG_USER_PROMPT_FOR_PASSWORD
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	handled
notLock:
	;
	;  Help key sequence - bring up help.
	;
		cmp	cx, (CS_CONTROL shl 8) or VC_F1
		jne	notHelp

		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	notHelp

		mov	ax, MSG_GEN_APPLICATION_BRING_UP_HELP
		call	ObjCallInstanceNoLock
		jmp	handled
notHelp:
	;
	;  Are we rotating the screen?
	;
		cmp	cx, (CS_UI_FUNCS shl 8) or UC_ROTATE
		jne	passUp

		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	passUp

		mov	ax, MSG_GEN_ROTATE_DISPLAY
		call	GenCallParent		; send to field
		jmp	handled

sendEventToEditControl:
	;
	;  Close any menus, first, so focus will not be in menu
	;	*ds:si = app object
	;	ax = edit message
	;
		call	CloseOpenMenus
	;
	;  Find App menu
	;	*ds:si = app object
	;
		push	ax				; save Edit message
		call	FindAppMenu			; ^lcx:dx = App menu
		pop	ax				; ax = Edit message
		jcxz	sendToFocus			; no App menu
	;
	;  Find GenEditControl
	;	^lcx:dx = App menu
	;	ax = edit message
	;	*ds:si = app object
	;
		call	FindGenEditControl		; ^lcx:dx = GEditCtrl
		jnc	sendToFocus			; not found
	;
	;  Send edit message to GenEditControl
	;	^lcx:dx = GenEditControl
	;	ax = edit message
	;
		movdw	bxsi, cxdx			; ^lbx:si = GEditCtrl
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		jmp	handled
passUp:
	;
	;  It's not one of ours -- pass it on to superclass.
	;
		clc
		jmp	done
handled:
		stc
done:
		.leave
		ret

sendToFocus:
	;
	; no Edit control found, send to focus
	;	*ds:si = app object
	;	ax = edit message
	;
		push	si
		clr	bx, si
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = event
		pop	si
		mov	cx, di
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_APP_FOCUS
		call	ObjCallInstanceNoLock
		jmp	short handled

OLAppTestJediKeys	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseOpenMenus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close open menus via GAGCNLT_WINDOWS list

CALLED BY:	OLAppTestJediKeys
PASS:		*ds:si = OLApp
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseOpenMenus	proc	near
	uses	ax,si,bp,es
	.enter
	;
	; Go through app's GAGCNLT_WINDOWS list to find menus.
	;	*ds:si = OLApp
	;
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData		; ds:bx = data
	jnc	done			; if no lists, done
	mov	di, ds:[bx].TMGCND_listOfLists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_WINDOWS
	clc				; don't create list
	call	GCNListFindListInBlock	; *ds:si = list, if found
	jnc	done			; if no GAGCNLT_WINDOWS list, done
	mov	bx, SEGMENT_CS
	mov	di, offset COM_callback
	call	ChunkArrayEnum		; close all menus
done:
	.leave
	ret
CloseOpenMenus	endp

;
; pass:
;	ds:di = optr
; returned:
;	nothing
; destroyed:
;	es, di, ax, bx, cx, dx, bp
;
COM_callback	proc	far
	uses	si
	.enter
	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	call	ObjTestIfObjBlockRunByCurThread
	jnz	done			; different thread, not menu
	push	ds:[LMBH_handle]	; save OLApp block handle
	call	ObjLockObjBlock
	mov	ds, ax			; ds = GCN item block
	mov	di, segment OLMenuWinClass
	mov	es, di
	mov	di, offset OLMenuWinClass
	call	ObjIsObjectInClass
	jnc	doneUnlock		; not menu
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
.warn -private
	mov	si, ds:[di].OLPWI_button	; *ds:si = menu button
.warn @private
	tst	si
	jz	doneUnlock
	mov	ax, MSG_OL_MENU_BUTTON_CLOSE_MENU
	call	ObjCallInstanceNoLock	; close this menu
doneUnlock:
	call	MemUnlock
	pop	bx
	call	MemDerefDS		; ds = OLApp block
done:
	clc				; continue enumeration
	.leave
	ret
COM_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindGenEditControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find GenEditControl

CALLED BY:	OLAppTestJediKeys
PASS:		^lcx:dx = App menu
		*ds:si = app object
RETURN:		carry set if found
			^lcx:dx = GenEditControl
		carry clear, otherwise
DESTROYED:	bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindGenEditControl	proc	far
		uses	ax, si
		.enter
		mov	bx, cx
		mov	si, dx
		call	ObjSwapLock		; *ds:si = App menu
		push	bx

		clr	di			; start at child 0
		push	di
		push	di			; push starting child #

		mov	di, offset GI_link
		push	di			; push offset to LinkPart

		mov	di, SEGMENT_CS
		push	di
		mov	di, offset FindGenEditControlCB
		push	di

		mov	bx, offset Gen_offset	; Use the generic linkage
		mov	di, offset GI_comp
		call	ObjCompProcessChildren
		pop	bx
		call	ObjSwapUnlock		; (preserves flags)
		.leave
		ret
FindGenEditControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindGenEditControlCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return if this is a popup window.

CALLED BY:	FindGenEditControl via ObjCompProcessChildren

PASS:		*ds:si = child
		*es:di = composite (App menu)

RETURN:		carry set if found (end processing)
			^lcx:dx = GenEditControl
		carry clear, otherwise (continue searching)

DESTROYED:	di, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	brianc	2/22/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindGenEditControlCB	proc	far

	;
	;  See if we're a GenEditControlClass
	;
		mov	cx, ds:[LMBH_handle]		; in case found
		mov	dx, si
		mov	di, segment GenEditControlClass
		mov	es, di
		mov	di, offset GenEditControlClass
		call	ObjIsObjectInClass		; carry set if so
		.leave
		ret
FindGenEditControlCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LaunchJotterApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User pressed "Jotter" key.

CALLED BY:	OLAppTestJediKeys

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- just launch it.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LaunchJotterApp	proc	near
		uses	ax,bx,cx,dx,si,bp,di
		.enter

		mov	bx, handle ui
		call	GeodeGetAppObject	; ^lbx:si = UIApp
		mov	ax, MSG_META_NOTIFY
		mov	di, mask MF_FORCE_QUEUE
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_STARTUP_INDEXED_APP
	;
	;  Changed from 6 (finance) to 5 (jotter) - stevey 6/24/95
	;
		mov	bp, 5
		call	ObjMessage

		.leave
		ret
LaunchJotterApp	endp

endif	; _JEDIMOTIF ----------------------------------------------------------

if _KBD_NAVIGATION	;------------------------------------------------------

;Keyboard shortcut bindings for OLApplicationClass

if not _JEDIMOTIF
OLAppKbdBindings	label	word
	word	length OLAShortcutList

if _PM ;------------------------------------------------------------

if DBCS_PCGEOS

	 ;P     C  S  C
	 ;h  A  t  h  h
	 ;y  l  r  f  a
	 ;s  t  l  t  r

OLAShortcutList	KeyboardShortcut \
	<0, 1, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>,	;NEXT application
	<0, 1, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;NEXT application
	<0, 1, 0, 0, C_SYS_F6 and mask KS_CHAR>,	;NEXT window
	<0, 0, 0, 0, C_SYS_F3 and mask KS_CHAR>,	;Quit application
	<0, 0, 0, 0, C_SYS_F1 and mask KS_CHAR>		;Help
else ; PM but not DBCS 

	 ;P     C  S     C
	 ;h  A  t  h  S  h
	 ;y  l  r  f  e  a
	 ;s  t  l  t  t  r

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

elif _REDMOTIF ;------------------------------------------------------------

OLAShortcutList	KeyboardShortcut \
	<0, 1, 0, 0, 0xf, VC_F6>,	;NEXT window
	<0, 0, 1, 0, 0, 'h'>,		;Help
	<0, 0, 1, 0, 0, 'H'>		;Help

OLAMethodList	label word
	word	MSG_OL_APP_NAVIGATE_TO_NEXT_WINDOW
	word	MSG_GEN_APPLICATION_BRING_UP_HELP
	word	MSG_GEN_APPLICATION_BRING_UP_HELP

elif _RUDY ;------------------------------------------------------------

if DBCS_PCGEOS

OLAShortcutList	KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_INS and mask KS_CHAR>	;Help

else

OLAShortcutList	KeyboardShortcut \
	<0, 0, 0, 1, 0xf, VC_INS>	;Help

endif

OLAMethodList	label word
	word	MSG_GEN_APPLICATION_BRING_UP_HELP


else ;not _RUDY or _REDMOTIF or _PM ;------------------------------------

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

endif	;not _RUDY or _REDMOTIF or _PM --------------------------------------

endif	; not _JEDIMOTIF

if not _JEDIMOTIF
ForceRef OLAMethodList
CheckHack <($-OLAMethodList) eq (size OLAShortcutList)>
endif

endif	; KBD_NAVIGATION -----------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHotkeyApps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle hotkey applications (Typewriter and BigCalc)

CALLED BY:	OLApplicationFupKbdChar
PASS:		*ds:si 	- instance data
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code
RETURN:		carry set if hotkey was processed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

typewriterApp	char	"twapp   ",0
bigcalcApp	char	"bigcalc ",0

CheckHotkeyApps	proc	near

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT or \
		    mask CF_REPEAT_PRESS or mask CF_RELEASE
	LONG jnz done				; don't bother if ...

	tst	dh				; don't bother if ShiftState
	jnz	done				

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F9		;F9 key?	>
DBCS <	cmp	cx, C_SYS_F9				;F9 key?	>
	cmc					; clr carry for exit
	jnc	done				; don't bother if below F9

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F10	;F10 key?	>
DBCS <	cmp	cx, C_SYS_F10				;F10 key?	>
	ja	done				; don't bothing if above F10

	push	ax,bx,cx,dx,bp,di,es
ifdef NIKE_EUROPE
	mov	bp, 6				; typewriter = app #6
else
	mov	bp, 9				; typewriter = app #9
endif
	mov	di, offset typewriterApp
	jne	gotApp
ifdef NIKE_EUROPE
	mov	bp, 8				; bigcalc = app #8
else
	mov	bp, 10				; bigcalc = app #10
endif
	mov	di, offset bigcalcApp			
gotApp:
	segmov	es, cs
	call	findGeode
	jnc	tryRunApp
						; bx = handle of geode
	call	GeodeGetAppObject		; ^lbx:si = app object
	mov	ax, MSG_META_QUIT
	mov	di, mask MF_FORCE_QUEUE
	jmp	sendMessage

tryRunApp:
	; but don't run it if we already have the other one running

	mov	di, offset bigcalcApp
ifdef NIKE_EUROPE
	cmp	bp, 6				; typewriter = app #6
else
	cmp	bp, 9				; typewriter = app #9
endif
	je	gotOtherApp
	mov	di, offset typewriterApp
gotOtherApp:
	call	findGeode
	jnc	runApp

	; put up stupid box saying you can't run another one

	clr	ax
	pushdw	axax		; don't care about SDOP_helpContext
	pushdw	axax		; don't care about SDOP_customTriggers
	pushdw	axax		; don't care about SDOP_stringArg2
	pushdw	axax		; don't care about SDOP_stringArg1
	mov	cx, handle OneDeskAccessoryString
	mov	dx, offset OneDeskAccessoryString
	pushdw	cxdx
	mov	ax, CustomDialogBoxFlags <TRUE,	CDT_ERROR, GIT_NOTIFICATION,0>
	push	ax
	call	UserStandardDialogOptr
	jmp	popStuff

runApp:
	mov	dx, GWNT_STARTUP_INDEXED_APP
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	ax, MSG_META_NOTIFY
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
sendMessage:
	call	ObjMessage
popStuff:
	pop	ax,bx,cx,dx,bp,di,es
	stc					; hotkey processed
done:
	ret


findGeode:
FXIP <	clr	cx							>
FXIP <	call	SysCopyToStackESDI					>
	mov	ax, 8
	mov	cx, mask GA_APPLICATION
	clr	dx
	call	GeodeFind
FXIP <	call	SysRemoveFromStack					>
	retn

CheckHotkeyApps	endp

endif	; if _NIKE ------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandlePrinterKeys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for Printer keys

CALLED BY:	OLApplicationFupKbdChar
PASS:		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
RETURN:		carry set if hotkey was processed
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

printerCategory	char	"printer",0
printerKey	char	"printers",0

HandlePrinterKeys	proc	near
printer	local	(GEODE_MAX_DEVICE_NAME_SIZE+1) dup (char)
prEsc	local	word
pstate	local	hptr
	uses	ax,bx,cx,dx,si,ds,es

	test	dh, mask SS_LSHIFT or mask SS_RSHIFT or \
		    mask SS_LALT or mask SS_RALT
	jnz	exit

	test	dh, mask SS_LCTRL or mask SS_RCTRL
	jz	notCtrl

	; Ctrl-F11 -> Clean print head

	mov	di, DR_PRINT_ESC_CLEAN_HEAD
	cmp	cx, VC_F11 or (VC_ISCTRL shl 8)
	je	checkSysModal
	jmp	exit

notCtrl:
	; F11 -> Change ink cartridge

	mov	di, DR_PRINT_ESC_CHANGE_INK_CARTRIDGE
	cmp	cx, VC_F11 or (VC_ISCTRL shl 8)
	je	checkSysModal

	; F12 -> Insert paper

	mov	di, DR_PRINT_ESC_INSERT_PAPER
	cmp	cx, VC_F12 or (VC_ISCTRL shl 8)
	jne	exit

checkSysModal:
	push	cx, dx, bp
	call	AppFindTopSysModalWin
	tst	cx			; is there a sysmodal window?
	pop	cx, dx, bp
	jz	callPrinter

	; Beep to notify user that key will be ignored.

	mov	ax, SST_NO_INPUT
	call	UserStandardSound
exit:
	clc				; key not processed
	ret


callPrinter:
	.enter

	mov	ss:[prEsc], di

	push	bp
	mov	cx, cs
	mov	dx, offset printerKey
	mov	ds, cx
	mov	si, offset printerCategory
	segmov	es, ss
	lea	di, ss:[printer]
	clr	ax				; first printer
	mov	bp, (GEODE_MAX_DEVICE_NAME_SIZE) or INITFILE_INTACT_CHARS
	call	InitFileReadStringSection	; copy the string
	pop	bp
	jc	done

	; Allocate a PState
	;
	mov	ax, (size PState)
	mov	cx, ALLOC_DYNAMIC_NO_ERR
	call	MemAlloc			; handle => BX (PState)
	mov	ss:[pstate], bx

	; Access this driver, please
	;
	segmov	ds, es
	mov	si, di
	mov	ax, SP_PRINTER_DRIVERS
	mov	cx, PRINT_PROTO_MAJOR
	mov	dx, PRINT_PROTO_MINOR
	call	UserLoadExtendedDriver		; driver handle => BX
	jc	memFree				; if error, abort

	; Get driver strategy routine
	
	call	GeodeInfoDriver			; to get strategy routine

	; Call print driver

	push	bx				; save driver handle
	mov	di, ss:[prEsc]
	mov	bx, ss:[pstate]
	call	ds:[si].DIS_strategy
	pop	bx				; restore driver handle

	; Free print driver

	call	GeodeFreeDriver
memFree:
	mov	bx, ss:[pstate]
	call	MemFree				; free PState
	stc					; key was processed
done:
	.leave
	ret
HandlePrinterKeys	endp

endif		;--------------------------------------------------------------



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

if not _JEDIMOTIF

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
if (not _PM)
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
if (not _PM)
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

endif	; not _JEDIMOTIF ------------------------------------------------------


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

if not _JEDIMOTIF

if (not _PM)		;------------------------------------------------------

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

else	; PM ------------------------------------------------------------------
;
; PM just asks the field to bring to front the next window listed in the
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

endif	; not _JEDIMOTIF


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

if not _JEDIMOTIF

if (not _PM)	;--------------------------------------------------------------

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

if _NIKE
	;
	; Don't navigate to this app, if it is not a desk accessory and
	; doesn't have the full screen exclusive.
	;
	test	ds:[di].GAI_launchFlags, mask ALF_DESK_ACCESSORY
	jnz	mayNavigate

	test	ds:[di].GAI_states, mask AS_HAS_FULL_SCREEN_EXCL
	jz	goToNext
mayNavigate:
endif

	;
	; can navigate to this app, grab focus/target, etc.
	;
	push	bp				; save passed event
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
	pop	bx				; restore passed event

if (not _NIKE)
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
endif

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

endif	; not _JEDIMOTIF

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
RUDY <	mov	dx, offset StdDialogQuestionBitmap			>
	cmp	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	cx, offset StdDialogWarningMoniker
if _RUDY
	mov	dx, offset StdDialogWarningBitmap
else
	cmp	ax, CDT_WARNING shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	cx, offset StdDialogNotificationMoniker
	cmp	ax, CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	cx, offset StdDialogErrorMoniker
endif
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

if _RUDY
	mov	si, offset StdDialogCuteGlyph
	mov	si, ds:[si]
	add	si, ds:[si].ComplexMoniker_offset
	mov	ds:[si].CMI_topText, cx
	mov	ds:[si].CMI_iconBitmap, dx
else
	mov	si, offset StdDialogCuteGlyph
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	ds:[si].GI_visMoniker, cx
endif

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

if _ODIE
	; copy help text to Summons moniker
		
	mov	si, offset StandardDialogSummons
	call	CopyHelpTextToMoniker
else
	; create a help hint if needed
		
	mov	si, offset StandardDialogSummons
	call	CreateHelpHintIfNeeded
endif
		
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

if _ODIE

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyHelpTextToMoniker

DESCRIPTION:	Copy help text to Summons moniker.

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenInteraction to add the moniker to
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
CopyHelpTextToMoniker	proc	near	uses bx, bp
	.enter

	movdw	bxdx, ss:[bp].SDP_helpContext
	tst	bx
	jz	done

	push	bx					;save virtual segment
	call	MemLockFixedOrMovable			;ax = real segment

	mov	cx, ax					;cx:dx <- string fptr
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock

	pop	bx
	call	MemUnlockFixedOrMovable

done:
	.leave
	ret
CopyHelpTextToMoniker	endp

else
		

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
endif


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
if _RUDY
	call	PositionCustomTriggers
endif

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

if _RUDY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionCustomTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place certain triggers in certain spots in command
		button area

CALLED BY:	CreateMultipleResponseTriggers
PASS:		*ds:si = trigger
		es:di = StandardDialogResponseTriggerEntry
		dx = trigger number, 0-based
		ss:bp = StandardDialogParams
RETURN:		nothing
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	HINT_SEEK_SLOT() may be added

PSEUDO CODE/STRATEGY:
		API says that triggers appear in reply bar in the
		order they appear in the table, so we only need to
		deal with these cases:
			1) one trigger -> slot 3
			2) two triggers -> slot 0 and 3
			3) three triggers -> slot 0, 1, 3
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionCustomTriggers	proc	near
	uses	dx, di, bp, es
	.enter
	les	di, ss:[bp].SDP_customTriggers
	mov	cx, es:[di].SDRTT_numTriggers	; cx = trigger count
	jcxz	done				; no triggers, done
	cmp	cx, 4
	jae	done				; 4 or more triggers, done
	mov	bp, 3				; last trigger, use slot 3
	dec	cx				; dx = cx if last trigger
	cmp	cx, dx
	je	storeSlot			; last trigger
	;
	; 2 or 3 triggers, 1st or 2nd
	;	dx = 0 if 2 triggers, 1st --> slot 0
	;	dx = 0 if 3 triggers, 1st --> slot 0
	;	dx = 1 if 3 triggers, 2nd --> slot 1
	;
	mov	bp, dx				; bp = desired slot
storeSlot:
	mov	ax, HINT_SEEK_SLOT
	mov	cx, size word
	call	ObjVarAddData			; ds:bx = var data
	mov	ds:[bx], bp			; store position
	;
	; necessary to process HINT_SEEK_SLOT
	;
	mov	ax, MSG_VIS_SET_GEO_ATTRS
	mov	cx, mask VGA_NOTIFY_GEOMETRY_VALID
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
PositionCustomTriggers	endp
endif



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
		MSG_GEN_APPLICATION_DO_STANDARD_DIALOG for OLApplicationClass

DESCRIPTION:	Execute a standard dialog box.

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - The method

	dx - size StandardDialogParams
	ss:bp - StandardDialogParams

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
					MSG_GEN_APPLICATION_DO_STANDARD_DIALOG

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

	; build the dialog box

	mov	ax, MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG
	call	ObjCallInstanceNoLock			;cx:dx = dialog

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
	; Record the summons & link new chunk at the head of the list.
	; 
	mov	di, ds:[bx]
	movdw	ds:[di].OLASD_summons, cxdx

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
if _RUDY
	cmp	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	ax, SST_WARNING
else
	mov	bx, SST_ERROR
	cmp	ax, CDT_ERROR shl offset CDBF_DIALOG_TYPE
	je	haveSound
	mov	bx, SST_WARNING
	cmp	ax, CDT_WARNING shl offset CDBF_DIALOG_TYPE
	jne	10$
haveSound:
	mov_tr	ax, bx
endif
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

if not _JEDIMOTIF

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

endif	; not _JEDIMOTIF



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
if not _JEDIMOTIF

OLApplicationNotify	method	dynamic	OLApplicationClass, MSG_META_NOTIFY,
						MSG_META_NOTIFY_WITH_DATA_BLOCK
	;
	; make sure we've got what we're looking for
	;
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_STARTUP_INDEXED_APP
	je	nukeExpress
if	_RUDY
	cmp	dx, GWNT_RESPONDER_NOTIFICATION
	je	handleResponderNotification
endif
	cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
	jne	callSuper
	cmp	bp, HIBF_TOGGLE_EXPRESS_MENU
	je	callSuper	; don't close E-menu if we're going to open it
nukeExpress:
	call	NukeExpressMenu
callSuper:
	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock
if	_RUDY
handleResponderNotification:
	cmp	bp, RNT_SAVE_DATA
	jne	callSuper

	push	dx
	mov	dx, GWNT_FOAM_AUTO_SAVE
	call	SendFoamNotification
	pop	dx
	jmp	callSuper
endif

OLApplicationNotify	endm

endif	; not _JEDIMOTIF

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

else

if _RUDY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationGainedFullScreenExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends data blocks containing, the text moniker, and
		icon moniker to the Indicator App.

CALLED BY:	MSG_META_GAINED_FULL_SCREEN_EXCL
PASS:		*ds:si	= OLApplicationClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	reza	1/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationGainedFullScreenExcl	method dynamic	OLApplicationClass, \
				MSG_META_GAINED_FULL_SCREEN_EXCL

	push	ax, cx, dx, bp
	;
	; See if the geode can get the full screen exclusive.
	;
        mov     bx, ds:[LMBH_handle]
        call    MemOwner                	; BX -> owning geode
        call    WinGeodeGetFlags
        test    ax, mask GWF_FULL_SCREEN
        LONG jz	callSuper			; NO, don't change monikers

	;
	; See if we are focusable	
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_FOCUSABLE
	LONG jz	callSuper			; NO, don't change monikers

	;
	; Bring ourselves to the top - no need, indicator is no longer
	; targetable / focusable. kho, 8/10/95
	;
	; mov	ax, MSG_GEN_BRING_TO_TOP
	; call	ObjCallInstanceNoLock
EC < 	Assert	objectPtr, dssi, OLApplicationClass			>
EC <	Assert	segment, es						>

	;
	; Search for the text moniker first
	;
	mov	ax, MSG_GEN_FIND_MONIKER
	mov	dx, 1				; just make dx non-zero
	mov	bp, VMSF_TEXT_MASK
	call	ObjCallInstanceNoLock		; ^lcx:dx = text moniker
	mov	bx, GWNT_INDICATOR_REPLACE_TEXT_GLYPH
	push	cx, dx				; save text moniker optr
	call	RudySendMonikerToIndicator

	;
	; Search for the icon moniker next
	;
	mov	ax, MSG_GEN_FIND_MONIKER
	mov	dx, 1				; just make dx non-zero
	mov	bp, (VMS_ICON shl 12) or (mask VMSF_GSTRING)
	call	ObjCallInstanceNoLock		; ^lcx:dx = text moniker
	pop	ax, bx				; recover text moniker optr
	cmpdw	cxdx, axbx			; icon moniker = text moniker?
	jne	diffMoniker
	clr	cx, dx				; YES, don't use same moniker
diffMoniker:
	mov	bx, GWNT_INDICATOR_REPLACE_ICON_GLYPH
	call	RudySendMonikerToIndicator
callSuper:

	mov	dx, GWNT_FOAM_GAINED_FULL_SCREEN_EXCL
	call	SendFoamNotification

;	Add ourselves to the GCNSLT_RESPONDER_NOTIFICATIONS list, so we can
;	receive GWNT_RESPONDER_NOTIFICATION notifications. We are interested
;	in the RNT_SAVE_DATA notification, which we turn into
;	GWNT_FOAM_AUTO_SAVE notifications.

	mov	cx, ds:[LMBH_handle]
	mov	dx, si			;CX:DX - OD of this object
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_RESPONDER_NOTIFICATIONS
	call	GCNListAdd

	pop	ax, cx, dx, bp
	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock
OLApplicationGainedFullScreenExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RudySendMonikerToIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the size and the given moniker to a data block,
		and actually sends the block to a GCN list.

CALLED BY:	OLApplicationGainedFullScreenExcl
PASS:		^lcx:dx	= moniker to send (^lcx:dx = NIL if none)
		bx	= GeoWorksNotificationType 
		          valid ones: 
				GWNT_INDICATOR_REPLACE_TEXT_GLYPH
				GWNT_INDICATOR_REPLACE_ICON_GLYPH
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Format of data block: 
		Word containing size of moniker (bytes).
		Actual moniker data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	reza	1/19/95    	Initial version
	reza	2/29/96		Changed to use SysSendNotification
	reza	3/1/96		Temporarily changed back to GCNList
	reza	3/5/96		Indicator updated, back to SysSendNotification

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RudySendMonikerToIndicator	proc	near
	uses	si, es, ds
	.enter

	mov	di, bx				; di = NotificationType
	clr	ax				; assume moniker size = 0
	push	cx				; save moniker block handle
	tst	cx				; hptr valid?
	jz	noMoniker			; No, no icon to copy

	;
	; Lock the moniker block, and figure moniker size 
	;
EC <	Assert	optr, cxdx						>
	mov	bx, cx
	call	ObjLockObjBlock
	mov	ds, ax				; es = segment
	mov	si, dx
	mov	si, ds:[si]			; ds:si = source moniker
	ChunkSizeHandle	ds, dx, ax		; ax = size of moniker

	;
	; Allocate extra data block to send moniker
	;
noMoniker:
EC <	Assert  etype,	di, GeoWorksNotificationType			>
	push	di				; save NotificationType
	push	ax				; save moniker size
	add	ax, size IndicatorDataBlock
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or (mask HF_SHARABLE)
	call	MemAlloc			; ax <- size of block
						; bx -> block handle
						; ax -> block segment
	mov_tr	es, ax

	;	
	; Move size of moniker, and actual moniker to data block
	;
	pop	cx				; recover moniker size
	mov	es:[IDB_monikerSize], cx
	mov	di, offset IDB_monikerData	; es:di = dest block
	tst	cx				; any data to copy?
	jz	moveDone			; NO, skip the copy

	shr	cx, 1
	cld
	rep	movsw
	jnc	moveDone
	movsb

	;
	; Done with data block
	;
moveDone:
	call	MemUnlock			; unlock data block

	;
	; Send the block to the Indicator subsystem
	;
	pop	di				; recover
						; GeoWorksNotificationType 
	mov	si, SST_INDICATOR
	ornf	di, mask SNT_AX_MEM
	mov_tr	ax, bx				; pass block as word1
	clr	bx, cx, dx			; don't have to pass these
	call	SysSendNotification

	pop	bx				; recover moniker
						; block handle
	tst	bx				; did we lock a block?
	jz	quit				; NO, no need to unlock
	call	MemUnlock
quit:
	.leave
	ret
RudySendMonikerToIndicator	endp

endif	; _RUDY

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

ActionObscure	ends
