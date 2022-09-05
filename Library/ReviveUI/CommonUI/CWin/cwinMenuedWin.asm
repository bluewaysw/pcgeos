COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinMenuedWin.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLMenuedWinClass	Open look window class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version
	Eric	9/89		Renamed from cwinMenuBar -> cwinMenuedWin
				and OLMenuedWinClass -> OLMenuedWinClass

DESCRIPTION:

	$Id: cwinMenuedWin.asm,v 2.171 96/12/27 21:12:10 brianc Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLMenuedWinClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


;---------------------------------------------------

WinClasses segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinInitialize -- MSG_META_INITIALIZE handler for
			OLMenuedWinClass

DESCRIPTION:	We intercept this method here to set a flag in the window's
		FOCUS exclusive HierarchicalGrab structure. This flag
		causes the exclusion mechanism to consider menus
		temporary.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuedWinInitialize	method private static OLMenuedWinClass, 
							MSG_META_INITIALIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

EC <	push	es, di							>
EC <	mov	di, segment GenDisplayClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenDisplayClass				>
EC <	call	ObjIsObjectInClass					>
EC <	pop	es, di							>
EC <	ERROR_NC	OL_ERROR					>

					;call super (OLWinClass) for init
	mov	di, segment OLMenuedWinClass
	mov	es, di
	mov	di, offset OLMenuedWinClass
	CallSuper	MSG_META_INITIALIZE

	;set the HGF_MENU_WINDOW_GRABS_ARE_TEMPORARY flag, so that GenPrimary
	;and GenDisplay windows will restore the focus after a menu closes.
	;DO NOT do this at OLWinClass! We don't want this behaviour in menus!

	call	WinClasses_DerefVisSpec_DI
if MENU_BAR_IS_A_MENU
	mov	ds:[di].OLMDWI_menuCenter, 0
endif
	ORNF	ds:[di].OLWI_menuState, \
				mask OLWMS_MENU_WINDOW_GRABS_ARE_TEMPORARY

	;
	; Before replacing moniker list with most appropriate moniker (in
	; OLMenuedWinSpecBuild), find and store the monikers we'll need to use
	; for the icon if this window is iconified.  Doing this here also
	; allows minimizied GenPrimary to be restored from state correctly as
	; the OLMenuedWin never gets built, yet the icon monikers are needed.
	;
	; (Correctly handles case where this window has no moniker, will use
	; GenApplication moniker list).
	;

ifndef NO_WIN_ICONS	;------------------------------------------------------

	call	FindIconMonikers

endif			; ifndef NO_WIN_ICONS ---------------------------------

	;
	; handling of minimized state is done in OLMenuedWinAttach and
	; OLMenuedWinSpecSetUsable
	;

	.leave
	ret
OLMenuedWinInitialize	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinVisAddChild

DESCRIPTION:	We intercept this to ensure that our menu bar is always at
		the end.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLMenuedWin)

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

if MENU_BAR_AT_BOTTOM

OLMenuedWinVisAddChild	method dynamic	OLMenuedWinClass, MSG_VIS_ADD_CHILD
	push	cx, dx			; save child
	;
	; first add child normally
	;
	mov	di, offset OLMenuedWinClass
	CallSuper	MSG_VIS_ADD_CHILD

	;
	; then force our menu bar to the end
	;	(menu bar optr is guaranteed to be stored before it is added)
	;
	call	WinClasses_DerefVisSpec_DI
	mov	dx, ds:[di].OLMDWI_menuBar	; ^lcx:dx = menu bar
	mov	cx, ds:[LMBH_handle]
	call	MoveToEnd
	pop	cx, dx				; restore child
	ret

MoveToEnd:
	mov	ax, MSG_VIS_FIND_CHILD
	call	WinClasses_ObjCallInstanceNoLock	; ^lcx:dx preserved
	jc	noMove				; not added yet, nothing to fix
	mov	ax, MSG_VIS_MOVE_CHILD
	mov	bp, CCO_LAST			; make it the last one
	call	WinClasses_ObjCallInstanceNoLock
noMove:
	retn
OLMenuedWinVisAddChild	endm

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindIconMonikers

DESCRIPTION:	Search this window's (GenPrimary) moniker list, if any,
		for icon and icon caption monikers.  If not appropriate, search
		GenApplication's moniker list.

CALLED BY:	INTERNAL
			OLMenuedWinInitialize

PASS:		*ds:si	- OLMenuedWin instance data

RETURN:		*ds:[si].OLMDWI_iconCaptionMoniker updated
		*ds:[si].OLMDWI_iconMoniker updated
		updates ds

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
		If we find the gstring or textual moniker in the OLMenuedWin,
		it may be because it has a single gstring or textual moniker or
		because it has a moniker list with a gstring or textual
		moniker.  In either case, that gstring or textual moniker will
		always be around for us to reference it via our optr, even if
		the moniker list is resolved into a single moniker.  If we
		have to go the GenApplication object for the gstring or textual
		moniker, that moniker will always be around because a GenApp's
		moniker is never resolved.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/30/92		initial version

------------------------------------------------------------------------------@

ifndef NO_WIN_ICONS	;------------------------------------------------------

FindIconMonikers	proc	near
	call	WinClasses_DerefVisSpec_DI
OLS <	cmp	ds:[di].OLWI_type, OLWT_DISPLAY_WINDOW			>
CUAS <	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>
	je	done			;GenDisplay, not GenPrimary, don't
					;	bother with icon monikers
	;
	; if hint specifies, go directly to GenApp for moniker
	;
	mov	ax, HINT_DISPLAY_USE_APPLICATION_MONIKER_WHEN_MINIMIZED
	call	ObjVarFindData		; carry set if found
	jc	useGenAppForIcon	; (carry set)
	;
	; check this window for graphics string moniker for icon
	;
	mov	bp, mask VMSF_GSTRING \
		    or (VMS_ICON shl offset VMSF_STYLE)
	clc
	call	GenFindMoniker		; ^lcx:dx = moniker
	;
	; make sure we found a gstring moniker
	;
	tst	cx			; any moniker found?
	jz	useGenAppForIcon	; nope, use GenApplication
					; (carry clear)
	push	es
	mov	bx, cx			; bx = moniker resource
	call	ObjLockObjBlock
	mov	es, ax
	mov	di, dx			; *es:di = moniker
	mov	di, es:[di]		; es:di = moniker
	test	es:[di].VM_type, mask VMT_GSTRING
	call	MemUnlock		; preserves flags
	pop	es
	jnz	haveIconMoniker		; yes (carry cleared by 'test')
	;
	; gstring moniker not found in this window, use GenApplication's
	; moniker list
	;
useGenAppForIcon:
	pushf				; save use GenApp flag
	mov	bp, mask VMSF_GSTRING \
		    or (VMS_ICON shl offset VMSF_STYLE)
	stc				;use moniker list from GenApp object
	call	GenFindMoniker		;^lcx:dx = moniker
					;don't care if it's not a gstring,
					;or even if it doesn't exist
	popf				; restore use GenApp flag
haveIconMoniker:
	;
	; carry set if we should go straight to GenApp for moniker
	;
	pushdw	cxdx			;save icon moniker
	jc	useGenAppForCaption

	;For caption: look for abbreviated text, or text, or textual GString,
	;or GString. Copy moniker to this object block.

	mov	bp, (VMS_ABBREV_TEXT shl offset VMSF_STYLE)
	clc
	call	GenFindMoniker		; ^lcx:dx = moniker
	;
	; make sure we found something
	;
	tst	cx			; anything?
	jnz	haveIconCaptionMoniker
	;
	; gstring moniker not found in this window, use GenApplication's
	; moniker list (don't care if there is any)
	;
useGenAppForCaption:
	mov	bp, (VMS_ABBREV_TEXT shl offset VMSF_STYLE)
	stc				;use moniker list from GenApp object
	call	GenFindMoniker
haveIconCaptionMoniker:
					;^lcx:dx = icon caption moniker

	call	WinClasses_DerefVisSpec_DI
	movdw	ds:[di].OLMDWI_iconCaptionMoniker, cxdx	; save icon caption mkr
	popdw	ds:[di].OLMDWI_iconMoniker		; save icon moniker
done:
	ret
FindIconMonikers	endp

endif		; ifndef NO_WIN_ICONS -----------------------------------------



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinUpdateWindow -- MSG_META_UPDATE_WINDOW for
		OLMenuedWinClass

DESCRIPTION:	Handle *_ON_STARTUP stuff.

PASS:
	*ds:si - instance data
	es - segment of OLMenuedWinClass

	ax - MSG_META_UPDATE_WINDOW

	cx - UpdateWindowFlags
	dl - VisUpdateMode

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
	brianc	6/9/92		Initial version

------------------------------------------------------------------------------@

OLMenuedWinUpdateWindow	method dynamic	OLMenuedWinClass, 
					MSG_META_UPDATE_WINDOW

	test	cx, mask UWF_ATTACHING
	jz	notAttaching

	; Attaching:
	;
	; If GenDisplay/GenPrimary specified in .ui file and placed on active
	; list, handle HINT_DISPLAY_MINIMIZED_ON_STARTUP.
	; (HINT_DISPLAY_NOT_MINIMIZED_ON_STARTUP is the default)
	; If restoring from state file, handle ATTR_GEN_DISPLAY_MINIMIZED_STATE.
	; (HINT_DISPLAY_MAXIMIZED_ON_STARTUP,
	; HINT_DISPLAY_NOT_MAXIMIZED_ON_STARTUP, and
	; ATTR_GEN_DISPLAY_MAXIMIZED_STATE are ignored for GenDisplay
	; and are handled in OLBaseWinClass' MSG_META_ATTACH for GenPrimary.
	; Maximized states for GenDisplay are dictated by parent
	; GenDisplayGroup.)
	;
	; The actual minimization is handled in OpenWinAttach via
	; MSG_GEN_DISPLAY_SET_MINIMIZED.  OLMenuedWinCheckForGensMinimized
	; will clear ATTR_GEN_DISPLAY_MINIMIZED_STATE so that the generic
	; handler for MSG_GEN_DISPLAY_SET_MINIMIZED will work.
	;
	push	ax, cx, dx
						; assume restoring from state
	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
	test	cx, mask UWF_RESTORING_FROM_STATE	; state?
	jnz	haveVarData			; yes
						; else, use startup hint
	mov	ax, HINT_DISPLAY_MINIMIZED_ON_STARTUP
haveVarData:
	call	OLMenuedWinCheckForGensMinimized

	pop	ax, cx, dx
	jmp	short callSuper

notAttaching:
	test	cx, mask UWF_DETACHING
	jnz	callSuper			; let super handle detach

	; Runtime update:
	;
	; Must deal with minimized state

	push	ax, cx, dx
	;
	; OLMenuedWinCheckForGensMinimized will clear
	; ATTR_GEN_DISPLAY_MINIMIZED_STATE so that the generic handler for
	; MSG_GEN_DISPLAY_SET_MINIMIZED (sent below) will work.
	;
	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
	call	OLMenuedWinCheckForGensMinimized
	jnc	notMinimized
	;
	; if minimized on startup or minimized when set not-usable (or set
	; minimized while not-usable), do the normal
	; MSG_GEN_DISPLAY_SET_MINIMIZED handling
	;
	mov	ax, MSG_GEN_DISPLAY_SET_MINIMIZED
	mov	dl, VUM_NOW
	call	WinClasses_ObjCallInstanceNoLock
notMinimized:
	pop	ax, cx, dx

callSuper:
	call	WinClasses_ObjCallSuperNoLock_OLMenuedWinClass

	ret
OLMenuedWinUpdateWindow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuedWinSetCustomSystemMenuMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search this window's moniker list, if any, for a VMS_TINY
		gstring moniker.  If not found, search the GenApplication's
		moniker list.  If a suitable moniker is found, use it to
		replace the default system menu moniker.

CALLED BY:	OpenWinEnsureSysMenu

PASS:		*ds:si	= OLMenuedWinClass object
		ds:di	= OLMenuedWinClass instance data
		ds:bx	= OLMenuedWinClass object (same as *ds:si)
		es 	= segment of OLMenuedWinClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	7/30/92   	Initial version taken from FindIconMonikers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PM	;----------------------------------------------------------------------

OLMenuedWinSetCustomSystemMenuMoniker	method dynamic OLMenuedWinClass, 
				MSG_OL_WIN_SET_CUSTOM_SYSTEM_MENU_MONIKER
	uses	ax, cx, dx, bp
	.enter
	;
	; check this window for a VMS_TINY, gstring moniker
	;
	clc				;use window's moniker list
	call	SearchForVMSTinyGstringMoniker	;returns carry set if found
						; ^lcx:dx = moniker
	jc	haveMoniker

	;
	; gstring moniker not found in this window, use GenApplication's
	; moniker list
	;
	stc				;use moniker list from GenApp object
	call	SearchForVMSTinyGstringMoniker	;returns carry set if found
						; ^lcx:dx = moniker
	jnc	done			; didn't find what we're looking for

haveMoniker:
	;
	; Now replace the system menu moniker - new moniker is cx:dx
	;
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_menuState, mask OWA_SYS_MENU_IS_CLOSE_BUTTON
	jnz	done			; not needed if just a close button

	call	GetSystemMenuBlockHandle
	mov	si, offset StandardWindowMenu
	jz	haveSysMenu
	mov	si, ds:[di].OLBWI_titleBarMenu.chunk
haveSysMenu:
	mov	bp, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	ObjMessage
done:
	.leave
	ret
OLMenuedWinSetCustomSystemMenuMoniker	endm


SearchForVMSTinyGstringMoniker	proc	near
	mov	bp, mask VMSF_GSTRING \
		    or (VMS_TOOL shl offset VMSF_STYLE)
	call	GenFindMoniker		; ^lcx:dx = moniker

	tst	cx			; any moniker found?
	jz	done			; if zero then not carry
	push	es
	mov	bx, cx			; bx = moniker resource
	call	ObjLockObjBlock
	mov	es, ax
	mov	di, dx			; *es:di = moniker
	mov	di, es:[di]		; es:di = moniker
	cmp	es:[di].VM_width, CUAS_WIN_ICON_WIDTH
	jg	notFound		; if greater then not carry
	test	es:[di].VM_type, mask VMT_GSTRING
	jz	notFound		; if zero then not carry
found:
	stc				; set carry to indicate that we
notFound:				;  have found a suitable moniker
	call	MemUnlock		; preserves flags
	pop	es
done:
	ret
SearchForVMSTinyGstringMoniker	endp


OLMenuedWinFindTitleMonikerFar	proc	far
	call	OLMenuedWinFindTitleMoniker
	ret
OLMenuedWinFindTitleMonikerFar	endp

endif	; if _PM --------------------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinCheckForGensMinimized

DESCRIPTION:	see below

CALLED BY:	OLMenuedWinAttach, OLMenuedWinSpecSetUsable

PASS:		ds:*si	- instance data
		ax - hint or attr vardata type to check for (and set
			minimized on existance of)

RETURN:		carry set if minimized flags set
		carry clear if not

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version
	brianc	3/12/92		modified for 2.0

------------------------------------------------------------------------------@

OLMenuedWinCheckForGensMinimized	proc	near
	class	OLMenuedWinClass

	;if this window is marked as minimized and the specific UI
	;allows this, set as not SA_REALIZABLE and SA_BRANCH_MINIMIZED
	;so visible build will not occur. (This could be handled
	;in OLMenuedWinClass, but there is no INITIALIZE handler there.)

EC <	call	GenCheckGenAssumption	; Make sure gen data exists >
EC <	call	VisCheckVisAssumption	; Make sure vis data exists >

	call	ObjVarFindData		; carry set if found
	jnc	done			; if not minimized, done
					; (carry is clear)

	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_MINIMIZABLE
	jz	done			; skip if not minimizable...
					; (carry is clear)

	;
	; If called from OLMenuedWinAttach, generic state flag is set when we
	; evaluate SA_BRANCH_MINIMIZED in OpenWinAttach.  If called from
	; OLMenuedWinSpecSetUsable, generic state flag is set there.
	;

;moved to end
;	;
;	; In either case, since the actual minimization is done with the
;	; generic MSG_GEN_DISPLAY_SET_MINIMIZED, we need to clear the
;	; minimized state flag, ATTR_GEN_DISPLAY_MINIMIZED_STATE.
;	;
;	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
;	call	ObjVarDeleteData

	;Set this OLMenuedWin NOT REALIZABLE (do not touch generic state -
	;application has control of that info).

	call	WinClasses_DerefVisSpec_DI
	ANDNF	ds:[di].VI_specAttrs, not mask SA_REALIZABLE
	ORNF	ds:[di].VI_specAttrs, mask SA_BRANCH_MINIMIZED

	stc				; indicate minimized flags set

done:

;moved here from above to handle case where HINT_DISPLAY_MINIMIZED_ON_STARTUP
;is passed and not found, we still want to clear
;ATTR_GEN_DISPLAY_MINIMIZED_STATE (failcase: GenAppLazarus on minimized app)
;- brianc 3/8/93
	;
	; In either case, since the actual minimization is done with the
	; generic MSG_GEN_DISPLAY_SET_MINIMIZED, we need to clear the
	; minimized state flag, ATTR_GEN_DISPLAY_MINIMIZED_STATE.
	;
	pushf				; save results
	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
	call	ObjVarDeleteData
	popf				; restore results

	ret
OLMenuedWinCheckForGensMinimized	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinUpdateSpecBuild

DESCRIPTION:	Intercept branch build to make certain that at the end of
		this whole build that our menu & trigger bars, if any, have
		been vis built.

PASS:		*ds:si - instance data
		es - segment of OLMenuedWinClass

		ax - MSG_SPEC_BUILD_BRANCH
		cx - ?
		dx - ?
		bp - SpecBuildFlags

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version.

------------------------------------------------------------------------------@

OLMenuedWinUpdateSpecBuild	method	dynamic OLMenuedWinClass,
					MSG_SPEC_BUILD_BRANCH
EC <	call	VisCheckVisAssumption	;Make sure vis data exists >

	; If this is a "custom" window, don't need a gadget area.
	;
	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	haveGadgetArea
	;
	;if there ain't a gadget area then create one.  Reasoning:
	;Menued wins build a gadget area object to put non-view,
	;non-display-control children in.  The GadgetAreaCtrl basically
	;exists for the purpose of providing margins for these objects so
	;they're not up against the edges of the menued win (which has
	;no margins other than the resize area).  cbh 5/18/91

	tst	ds:[di].OLMDWI_gadgetArea
	jnz	haveGadgetArea

	push	ax
	mov	di, offset OLGadgetAreaClass
	call	OpenWinCreateBarObject		;creates object, sets visible

	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLMDWI_gadgetArea, ax	;save handle of gadget area 
						;   object

if INDENT_BOXED_CHILDREN
	;
	; if desired, tell gadget area not to indent HINT_DRAW_IN_BOX
	; children
	;
	push	si				; save window
	push	ax				; save gadget area
	mov	cx, mask OLGAF_NEEDS_TOP_MARGIN
	mov	ax, HINT_DONT_INDENT_BOX
	call	ObjVarFindData
	pop	si				; *ds:si = gadget area
	jnc	leaveIndent
	ornf	cx, mask OLGAF_PREVENT_LEFT_MARGIN
leaveIndent:
	;
	; tell gadget area to use top margin
	;
	mov	ax, MSG_SPEC_GADGET_AREA_SET_FLAGS
	call	ObjCallInstanceNoLock
	pop	si				; *ds:si = window
endif
	pop	ax				;parent = this OLWinClass obj,
						;and sends SPEC_BUILD to object
						;if this OLWinClass has already
						;been visbuilt. (which it
						;likely hasn't)
haveGadgetArea:						
	; Send to superclass to cause visual buildout of everything
	; under the Primary, so that app menus, created menus such as
	; "file" & "windows" etc. have been created.
	;
	push	bp
	call	WinClasses_ObjCallSuperNoLock_OLMenuedWinClass
	pop	bp

exit:
	ret

OLMenuedWinUpdateSpecBuild	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinSpecBuild -- MSG_SPEC_BUILD for OLMenuedWinClass

DESCRIPTION:	Do the standard OLWin SPEC_BUILD and if a menu bar is already
		existing (from OLMapGroup earlier) then spec build it

PASS:		*ds:si - instance data
		es - segment of OLMenuedWinClass

		ax - MSG_SPEC_BUILD
		cx - ?
		dx - ?
		bp - SpecBuildFlags

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation
	Eric	11/89		Now overrides OLWinClass handler.

------------------------------------------------------------------------------@

OLMenuedWinSpecBuild	method	dynamic OLMenuedWinClass, MSG_SPEC_BUILD
EC <	call	VisCheckVisAssumption	       ;Make sure vis data exists >

	call	VisSpecBuildSetEnabledState    ;set fully-enabled flag

;==============================================================================
;COPIED FROM OLWINCLASS SPEC_BUILD HANDLER:
	push	bp
	call	OpenWinSetVisParent	;query for visual parent and visually
					;attach self to that object.

	;PM will find the title moniker after it has built the system menu.
	;That way we can make a copy a system menu moniker from the window's
	;moniker list before OLMenuedWinFindTitleMoniker destroys the window's
	;moniker list.  JS (8/92)

if (not _PM)
	;search the VisMonikerList to find the moniker best suited for
	;the title of this window.

	call	OLMenuedWinFindTitleMoniker
endif

	;first: if the visible bounds for this object are actually
	;ratios of the Parent/Field window, convert to pixel coordinates now.

	call	ConvertSpecWinSizePairsToPixels

	;now update the window according to hints passed from the application
	;or specific-ui determined behavior (this does not actually run
	;geometry - it just sets the VIS bounds and flags so that when geometry
	;runs, it does the right thing.)

	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until MSG_VIS_MOVE_RESIZE_WIN to
					;do this.
	pop	bp
	push	bp

skipExpand:
	;FINALLY, PROCESS HINTS.  The hints requesting that the window be
	;made the default focus or target are processed here.

	call	ScanFocusTargetHintHandlers

	;now check the generic state data for this object to see if it
	;should be maximized (this is required when the window is first
	;appearing, or when it is restarting after a shutdown.)

if not _RUDY
					; this msg allows GenDisplay to
					; check with parent GenDisplayGroup
					; and GenPrimary to check its own attrs
	mov	ax, MSG_GEN_DISPLAY_GET_MAXIMIZED
	call	WinClasses_ObjCallInstanceNoLock	; carry set if maximized
	jnc	notMaximized
	mov	al, VUM_MANUAL		; don't update
	call	SetMaximized
notMaximized:
endif



;END OF COPY
;==============================================================================

	pop	bp			;restore BuildFlags

	; Vis-build out the menu, trigger bar, & gadget area, so that they
	; are specifically built out before things below attempt to vis-build on
	; to them.  This is the law!  Unfortunately, a bug appears to result
	; in which menus adopted by the Primary from Displays with adoptable
	; menus end up appearing to the LEFT of main menus, instead of to 
	; their RIGHT.  A fix was made awhile back in which the following
	; code was added at the end of this objects' SPEC_BUILD_BRANCH handler,
	; thereby vis-building the menu bar AFTER the children had been
	; vis-built!  This amazingly didn't blow up, as most things adding
	; themselves to the menu or windows hanging off of them (OLPopup) 
	; were'nt checking for parents that weren't vis-built.   I'm changing
	; the code back, expecting the strangely placed adopted menus to
	; come back, but I think this bug should be dealt with in a better
	; manner.  The bug, by the way, evidences itself when an app such
	; as America Online w/adopted menus is brought back from state
	; iconified, & then uniconified.  -- Doug 12/10/91

	;if there are titlebar objects then spec build them

	mov	ax, OLWI_titleBarLeftGroup.offset
	call	OLWinSendVBToBar

	mov	ax, OLWI_titleBarRightGroup.offset
	call	OLWinSendVBToBar

if (not _JEDIMOTIF)
	;if there is a menu bar then spec build it

	mov	ax, OLMDWI_menuBar
	call	OLWinSendVBToBar
endif

	; What's a triggerBar?  Is it used anywhere? JS.

	;if there is a trigger bar then spec build it

	mov	ax, OLMDWI_triggerBar
	call	OLWinSendVBToBar

	; build gadget area

	mov	ax, OLMDWI_gadgetArea
	call	OLWinSendVBToBar

if _JEDIMOTIF	
	;if there is a menu bar then spec build it

	mov	ax, OLMDWI_menuBar
	call	OLWinSendVBToBar
endif

	ret

OLMenuedWinSpecBuild	endp



;Pass ax = offset to field in OLWinClass specific data

OLWinSendVBToBar	proc	near
	push	si
	call	WinClasses_DerefVisSpec_DI
	add	di, ax				;point to _menuBar or
						;_triggerBar field
	mov	si, ds:[di]			;get handle of bar object
	tst	si
	jz	OLMWVBTB_noBarObject

	;SPEC_BUILD the menu bar object (it does this itsself since it is
	;not a generic object)

	push	bp
	mov	ax, MSG_SPEC_BUILD
	call	WinClasses_ObjCallInstanceNoLock
	pop	bp

OLMWVBTB_noBarObject:
	pop	si				;get handle
	ret
OLWinSendVBToBar	endp

WinClasses	ends


Unbuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinVisUnbuild -- MSG_SPEC_UNBUILD
		for OLMenuedWinClass

DESCRIPTION:	Visibly unbuilds & destroys a menued window

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_SPEC_UNBUILD

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

OLMenuedWinVisUnbuild	method dynamic OLMenuedWinClass, 
						MSG_SPEC_UNBUILD
					; Then, unbuild visible objects
					; we created. (menu bars)

					; Null out references to menu bars
					; MSG_SPEC_UNBUILD_BRANCH will
					; send MSG_SPEC_UNBUILD's
					; to them, where they will destroy
					; themselves.
	clr	bx
	mov	ds:[di].OLMDWI_menuBar, bx
	mov	ds:[di].OLMDWI_triggerBar, bx
	mov	ds:[di].OLMDWI_gadgetArea, bx

	mov	di, offset OLMenuedWinClass
	GOTO	ObjCallSuperNoLock

OLMenuedWinVisUnbuild	endm

Unbuild	ends


WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinFindTitleMoniker

DESCRIPTION:	This procedure finds the correct moniker to use for the
		title bar in this GenPrimary or GenDisplay. This moniker
		will come from the moniker list of this window, or
		of the GenApplication object.

CALLED BY:	OLMenuedWinSpecBuild
		UpdateAllMonikers

PASS:		*ds:si	- instance data

RETURN:		*ds:si	- same

DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
	call GenFindMoniker to find moniker for title, using this window
	if none found & this is GenPrimary, try again with GenApplication's
		moniker list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version
	Eric	10/90		removed icon-related code, as OLWinIconClass'
				SPEC_BUILD handler now searches for those
				monikers. See cwinWinIcon.asm.
	brianc	4/3/92		Fix to allow moniker lists

------------------------------------------------------------------------------@

OLMenuedWinFindTitleMoniker	proc	near
	class	OLMenuedWinClass	;can touch instance data
	;
	; Replace the moniker list, with the most appropriate text moniker
	;
	mov	bp, mask VMSF_REPLACE_LIST \
		    or (VMS_TEXT shl offset VMSF_STYLE)
					;return non-abbreviated text string,
					;otherwise abbreviated text string,
					;otherwise textual GString, otherwise
					;non-textual GString.
	clc
	call	GenFindMoniker		;*ds:dx = moniker
	;
	; If this is a GenPrimary and we don't have a moniker, use one
	; from the GenApplication object
	;
	tst	dx			;have moniker?
	jnz	done			;yes
	call	WinClasses_DerefVisSpec_DI
OLS <	cmp	ds:[di].OLWI_type, OLWT_DISPLAY_WINDOW			>
CUAS <	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>
	je	done			;GenDisplay, not GenPrimary, leave no
					;	moniker

	mov	bp, mask VMSF_COPY_CHUNK \
		    or (VMS_TEXT shl offset VMSF_STYLE)
					;return non-abbreviated text string,
					;otherwise abbreviated text string,
					;otherwise textual GString, otherwise
					;non-textual GString.
	mov	cx, ds:[LMBH_handle]	;pass handle of destination chunk
	stc				;get from GenApplication
	call	GenFindMoniker		;*ds:dx = moniker
	;
	; store VisMoniker found in GenApplication object
	;	*ds:si = OLMenuedWin
	;	dx = VisMoniker chunk
	;
EC <	call	GenCheckGenAssumption					>
	call	WinClasses_DerefGen_DI
	mov	ds:[di].GI_visMoniker, dx
done:
	ret
OLMenuedWinFindTitleMoniker	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinGenSetMinimized -- MSG_GEN_DISPLAY_SET_MINIMIZED

DESCRIPTION:	This method is passed on to us after the Generic UI has handled
		it. This whole process starts when the user selects "minimize"
		from the window's system menu, or when he clicks on the
		Minimize icon. Each of these triggers sends
		MSG_GEN_DISPLAY_SET_MINIMIZED to the GenPrimary object.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - METHOD
		dl - VisUpdateMode

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
	Set the GenPrimary object as SA_BRANCH_MINIMIZED so it and its
	children will close down temporarily (they will remain on the
	window list, so that if the application is restored, they will
	be like they were).

	Create an OLWinIcon object if necessary, and make it usable.

	Note: this even works if the GenPrimary was MAXIMIZED.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version

------------------------------------------------------------------------------@

OLMenuedWinGenSetMinimized	method	OLMenuedWinClass, 
						MSG_GEN_DISPLAY_SET_MINIMIZED

	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
	jnz	bail			;already minimized, do nothing
	test	ds:[di].OLWI_attrs, mask OWA_MINIMIZABLE
	jnz	10$			;minimizable, continue

bail:	;forget it!
	stc
	ret

10$:	;minimize window: enable icon, make this object unusable

	ORNF	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
					;set flag: this window is minimized
					;(not really important, since window
					;will be set UNUSABLE also, until the
					;OLWinIcon object sets us USABLE
					;again.)

; Doesn't do any good, since events can't be processed until we return
; anyway...
;	;mark the UI as busy, so we don't get any more button presses
;
;	mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT
;	call	GenCallApplication

	;Set this GenPrimary NOT REALIZABLE (do not touch generic state -
	;application has control of that info).

	mov	cx, (mask SA_REALIZABLE shl 8) or (mask SA_BRANCH_MINIMIZED)
					;turn off SA_REALIZABLE flag
					;and turn on BRANCH_MINIMIZED flag

	call	WinClasses_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW

ifndef NO_WIN_ICONS	;------------------------------------------------------

	;See if there is an OLWinIcon object associated with this window

	call	WinClasses_DerefVisSpec_DI
	tst	ds:[di].OLMDWI_icon.handle	;See if already built
	jnz	OMWGSM_50		;skip if so...

	;create object, by duplicating from .UI file resource to object block

	push	si
	mov	dx, si			;set *ds:dx = OLMenuedWinClass object
	clr	bx
	call	GeodeGetAppObject	;get ^lbx:si = GenApplication.

	push	bx, si			;save for later
	push	dx			;save chunk handle of this object

	mov	cx, bx			;set cx = block to place icon in
					;(resource which contains GenApp)

					;object to a generic parent
	clr	bp
if	(0)
	clr	dx			;do not attempt to add new
					;set ^lbx:si = template in UI resource
	mov	bx, handle WindowIcon
	mov	si, offset WindowIcon
	mov	ax, MSG_GEN_COPY_TREE
	call	WinClasses_ObjMessageCallFixupDS
					;returns ^lcx:dx = handle of icon object
else
	call	ObjSwapLock		; Need *ds:dx = app object
	push	bx

	; CREATE new icon object, placing it in the same block as the
	; GenApplication object.  Note that an icon is actually a 
	; GenPrimary w/HINT_WIN_ICON.
	;
	mov	dx, si			; add below GenApplication object
	mov	di, segment GenPrimaryClass
	mov	es, di
	mov	di, offset GenPrimaryClass
	mov	al, -1			; init USABLE
	mov	ah, -1			; add to parent using one-way linkage
	mov	bx, HINT_WIN_ICON	; Set hint to become OLWinIconClass
	call	OpenCreateChildObject

	pop	bx
	call	ObjSwapUnlock
endif
	pop	si

	;save OD of this new icon object (^lcx:dx)

	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLMDWI_icon.handle, cx
	mov	ds:[di].OLMDWI_icon.chunk, dx

	mov	bx, cx			;get ^lbx:ax = OLWinIconClass object
	mov	ax, dx
	pop	cx, dx			;^lcx:dx = OD of GenApplication
	pop	si			;*ds:si = OLMenuedWinClass object

	;send MSG_OL_WIN_ICON_SET_STATE to icon, to give it info
	;on its window, and to allow it to perform special initialization.
	;	*ds:si = window
	;	^lbx:ax = OLWinIconClass object

	push	si			;save window chunk on stack again
					;PASS PARAMETERS ON STACK:
	call	WinClasses_DerefVisSpec_DI
	push	ds:[di].OLMDWI_iconWinPosSizeFlags
	push	ds:[di].OLMDWI_iconWinPosSizeState
	push	ds:[di].OLMDWI_iconPosLeft
	push	ds:[di].OLMDWI_iconPosTop
	push	ds:[LMBH_handle]	;pass OD of this GenPrimary
	push	si

	mov	bp, sp			;ds:bp points to bottom of args
					;(80XXX stack builds downwards)
	mov	dx, size IconPassData	;pass size of passed data

	mov	si, ax			;set ^lbx:si = OLWinIconClass object
	mov	ax, MSG_OL_WIN_ICON_SET_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage

	add	sp, size IconPassData	;fixup stack
	pop	si			;get handle of window object again

	; Tell the icon which monikers to use for icon and icon caption

	call	OLMenuedWinSendIconMonikers

	;When this object is generic->specific built, the BUILD_INFO query
	;will be sent up the generic tree to find a generic parent for the icon.

OMWGSM_50: ;make the Icon SA_REALIZABLE so will appear on-screen.
	  ;(We can touch specific-visible state data since we have created
	  ;this generic object.)

	mov	ax, MSG_OL_WIN_ICON_SET_USABLE
	call	OLMenuedWinCallIconObject

	;lower ourselves to the bottom of the application stack within the
	;field, so the next application can have the focus

	push	si
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	mov	di, mask MF_FORCE_QUEUE		; (but do this after the window
	call	ObjMessage			; is actually up on screen)
	pop	si

	;make sure that icon is the focus within the application, so that
	;it can be interacted with if the application gets the focus

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	OLMenuedWinCallIconObject

endif	; ifndef NO_WIN_ICONS -------------------------------------------------

;	;release input
;
;	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT
;	call	GenCallApplication

	stc
	ret
OLMenuedWinGenSetMinimized	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinSetNotMinimized --
		MSG_GEN_DISPLAY_SET_NOT_MINIMIZED

DESCRIPTION:	This method is passed on to us after the Generic UI has
		handled it.
		
		This whole process starts when the user selects "restore"
		from the window's system menu, or when he clicks on the
		Minimize icon. Each of these triggers sends
		MSG_OL_RESTORE_WIN to the GenPrimary object.
		OpenWinRestoreWin handles this, and decides whether restore
		means "un-maximize" or "un-iconify". In this case, it
		decides for the latter and sends MSG_GEN_SET_NOT_MINIMIZED
		to the GenPrimary. The Generic UI handles this, and sends
		the method on to this handler.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - METHOD
		cx:dx	- ?
		bp	- ?

RETURN:		carry set if un-minimized window
		ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
	Set the GenPrimary object as NOT SA_BRANCH_MINIMIZED so it and its
	children will re-open.

	Make the OLWinIcon object NOT USABLE.

	Note: this even works if the GenPrimary was MAXIMIZED.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version

------------------------------------------------------------------------------@

OLMenuedWinSetNotMinimized	method	dynamic OLMenuedWinClass, \
					MSG_GEN_DISPLAY_SET_NOT_MINIMIZED

	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
	jz	done			;already not-minimized, do nothing
					;	(carry cleared)

	;restore window: make this object usable

	ANDNF	ds:[di].OLWI_specState, not (mask OLWSS_MINIMIZED)
					;set flag: this window is minimized
					;(not really important, since window
					;will be set UNUSABLE also, until the
					;OLWinIcon object sets us USABLE
					;again.)

ifndef NO_WIN_ICONS	;------------------------------------------------------

	;make OLWinIcon object NOT_USABLE (can set generic state of
	;this object since was created by specific UI and not application)
	;	ds:di = instance data

	mov	ax, MSG_SPEC_SET_ATTRS
	mov	dl, VUM_NOW
	mov	cx, mask SA_REALIZABLE shl 8
					;turn off SA_REALIZABLE flag
	call	OLMenuedWinCallIconObject

endif			; ifndef NO_WIN_ICONS ---------------------------------

	;mark window as invalid

	mov     cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID \
			or mask VOF_IMAGE_INVALID
	mov     dl, VUM_MANUAL
	mov     ax, MSG_VIS_MARK_INVALID
	call    WinClasses_ObjCallInstanceNoLock

	;set this window REALIZABLE (do not touch generic state data)

;SAVE BYTES: Can we turn on and turn off stuff at the same time?	
	mov	cx, mask SA_REALIZABLE
					;turn on SA_REALIZABLE flag
	call	WinClasses_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW

	mov	cx, (mask SA_BRANCH_MINIMIZED shl 8)
					;turn off BRANCH_MINIMIZED flag
	call	WinClasses_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW

	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	GenCallApplication

	stc
done:
	ret
OLMenuedWinSetNotMinimized	endp


ifndef NO_WIN_ICONS	;------------------------------------------------------

;pass:	*ds:si = OLMenuedWinClass object instance data
;	ax = message
;	cx, dx, bp = message data
OLMenuedWinCallIconObject	proc	far
	push	si
	call	WinClasses_DerefVisSpec_DI	;set ds:di = instance data
	mov	bx, ds:[di].OLMDWI_icon.handle	;set ^lbx:si = OLWinIcon object
	mov	si, ds:[di].OLMDWI_icon.chunk
	tst	si
	jz	done
	call	WinClasses_ObjMessageCallFixupDS
done:
	pop	si
	ret
OLMenuedWinCallIconObject	endp

endif			; ifndef NO_WIN_ICONS ---------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinSetMaximized -- MSG_GEN_DISPLAY_SET_MAXIMIZED

DESCRIPTION:	Handle what the specific-UI thinks MAXIMIZED means.

CALLED BY:	MSG_GEN_DISPLAY_SET_MAXIMIZED

PASS:		*ds:si	- instance data

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version
	Chris	4/91		Updated for new graphics, bounds conventions
	brianc	3/5/92		Changed to MSG_GEN_DISPLAY_SET_MAXIMIZED handler

------------------------------------------------------------------------------@

if not _RUDY		;no need to do this stuff in Rudy -- already maxed

OLMenuedWinSetMaximized	method dynamic	OLMenuedWinClass, \
					MSG_GEN_DISPLAY_SET_MAXIMIZED
	mov	al, VUM_NOW
	GOTO	SetMaximized
OLMenuedWinSetMaximized	endp

OLMenuedWinInternalSetMaximized	method dynamic	OLMenuedWinClass, \
					MSG_GEN_DISPLAY_INTERNAL_SET_FULL_SIZED
	mov	al, dl			; al = VisUpdateMode
	FALL_THRU	SetMaximized
OLMenuedWinInternalSetMaximized	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetMaximized

DESCRIPTION:	Common routine to maximized OLMenuedWin

CALLED BY:	OLMenuedWinSetMaximized
		OLMenuedWinSpecBuild

PASS:		*ds:si	- instance data
		al	- VisUpdateMode

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/7/92		Initial revision
	joon	7/92		PM extensions

------------------------------------------------------------------------------@

if not _RUDY

SetMaximized	proc	far
	;if this object is not yet VIS_BUILT, abort now. When VIS_BUILT,
	;will do specific-UI work for maximizing.

	call	VisCheckIfSpecBuilt
	jnc	abort			;skip if not yet VIS_BUILT...

					; GenDisplay's don't clear this even if
					; they are marked with M_G_D_NOT_MAX,
					; so this check is okay
	call	WinClasses_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE
	jz	abort			;skip if not...

	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz 	maximize		;skip if not already maximized...

abort:
	jmp	done

maximize:
	push	ax			; save VisUpdateMode

	;maximize window: save present position and size, expand to full screen

	ORNF	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
					;set flag: prevents resize borders
					;from appearing

	call	OpenWinSwapState	;save current position, size, and
					;state information in instance data

	;now set state so that SPEC_BUILD will maximize this window,
	;and so user can't screw things up.
	;SAVE BYTES HERE: stuff into "previous" area before swap

	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   (WCT_NONE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_AT_RATIO shl offset WPSF_POSITION_TYPE) \
		or (WST_EXTEND_TO_BOTTOM_RIGHT shl offset WPSF_SIZE_TYPE)

	mov	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID \
			or mask WPSS_SIZE_INVALID
					;clear all other flags

	;preserve OLWinAttrs value, except for movable and resizable flags

	mov	ax, ds:[di].OLWI_prevAttrs
	and	ax, not (mask OWA_MOVABLE or mask OWA_RESIZABLE)
	mov	ds:[di].OLWI_attrs, ax

	;set visible bounds invalid here, in case UpdateWinPosSize is not
	;yet able to determine position and size given our new flags
	;
	;(changed to position the window at -1 on B/W systems in order to
	; inset the window.  We can't do this in  UpdateWinPosition, since the 
	; position is never actually calculated via a specSizePair (WPSS_VIS_-
	; POS_IS_SPEC_PAIR is never set here).  -cbh 2/14/92)

	clr	ax
if	(not _MOTIF)
	call	OpenCheckIfBW
	jnc	dontInset
	dec	ax
dontInset:			
else
	dec	ax			;Motif always does this now, to get nice
					;etched MDI borders in color. 12/12/92
endif
	
	call	WinClasses_DerefVisSpec_DI
if THREE_DIMENSIONAL_BORDERS
	;
	; Maximized windows need to hide their 3-d borders.  Make sure
	; that the position is off-screen enough so that top & left
	; sides don't show shadows.
	;
	mov	ds:[di].VI_bounds.R_right, ax
	mov	ds:[di].VI_bounds.R_bottom, ax
	sub	ax, THREE_D_BORDER_THICKNESS-1
	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_top, ax
else
	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_top, ax
	mov	ds:[di].VI_bounds.R_right, ax
	mov	ds:[di].VI_bounds.R_bottom, ax
endif
	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until MSG_VIS_MOVE_RESIZE_WIN to
					;do this.


if _NIKE
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	jne	noTitle
	mov	cx, ds:[di].OLDW_titleObject
	jcxz	noTitle

	push	si
	mov	si, cx
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	si
noTitle:
endif

if (not _PM)	; PM GenDisplays keep their title bars and icons --------------

	;See if this GenDisplay is inside a GenDisplayGroup.

	push	si, es
	call	GenSwapLockParent	; *ds:si = parent, bx = our block
EC <	ERROR_NC	OL_ERROR					>
	mov	di, segment GenDisplayGroupClass
	mov	es, di
	mov	di, offset GenDisplayGroupClass
	call	ObjIsObjectInClass	; carry set if GenDisplayGroup
	call	ObjSwapUnlock		; (preserves carry)
	pop	si, es
	jnc	updateWindow		;skip if not in DC...

	;This is a GenDisplay within a GenDisplayGroup: turn off our title
	;bar and nuke the icons up there.

	call	WinClasses_DerefVisSpec_DI

CUAS <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_HEADER or mask OWA_TITLED or mask OWA_HAS_SYS_MENU) >

if _CUA_STYLE	;--------------------------------------------------------------
	;This could be improved. We are trying to defeat
	;OpenWinCalcWinHdrGeometry

	push	si, dx
	call	WinClasses_DerefVisSpec_DI
	mov	bx, ds:[di].OLWI_sysMenu
	tst	bx
	jz	afterDisable
	mov	si, ds:[di].OLWI_sysMenuButton
	call	ObjSwapLock

if not _REDMOTIF ;----------------------- Not needed for Redwood project
	call	DisableSysMenuIcon
	mov	si, offset SMI_MinimizeIcon
	call	DisableSysMenuIcon
	mov	si, offset SMI_MaximizeIcon
	call	DisableSysMenuIcon
	mov	si, offset SMI_RestoreIcon
	call	DisableSysMenuIcon
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

	call	ObjSwapUnlock
afterDisable:
	pop	si, dx
endif		;--------------------------------------------------------------

endif		; if (not _PM) ------------------------------------------------

updateWindow:
	pop	dx				; restore update mode
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	call	WinClasses_ObjCallInstanceNoLock

done:
	ret
SetMaximized	endp

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if _CUA_STYLE	;--------------------------------------------------------------
DisableSysMenuIcon	proc	near
	tst	si
	jz	done
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE) shl 8
	mov	ax, MSG_VIS_SET_ATTRS
	mov	dl, VUM_MANUAL			;object will be updated later
	call	WinClasses_ObjCallInstanceNoLock
done:
	ret
DisableSysMenuIcon	endp
endif		;--------------------------------------------------------------
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

endif 	;not _RUDY


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinSetNotMaximized -- MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED

DESCRIPTION:	Handle what the specific-UI thinks un-MAXIMIZED means.

CALLED BY:	

PASS:		ds:*si	- instance data

RETURN:		ds, si = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	brianc	3/5/92		Changed to MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED
					handler

------------------------------------------------------------------------------@

if not _RUDY		;not needed in Rudy

OLMenuedWinSetNotMaximized	method dynamic	OLMenuedWinClass,
					MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED
	mov	al, VUM_NOW
	GOTO	SetNotMaximized
OLMenuedWinSetNotMaximized	endm

OLMenuedWinInternalSetNotMaximized	method dynamic	OLMenuedWinClass,
					MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING
	mov	al, dl			; al = VisUpdateMode
	FALL_THRU	SetNotMaximized
OLMenuedWinInternalSetNotMaximized	endm

SetNotMaximized	proc	far

	;if this object is not yet VIS_BUILT, abort now. When VIS_BUILT,
	;will do specific-UI work for un-maximizing.

	call	VisCheckIfSpecBuilt
	jnc	done			;skip if not yet VIS_BUILT...

	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz	done			;skip if already not maximized...

	push	ax			; save VisUpdateMode

;unMaximize:
	;unmaximize window: restore previous position and size

	ANDNF	ds:[di].OLWI_specState, not mask OLWSS_MAXIMIZED

	call	OpenWinSwapState	;restore previous position, size, and
					;state information in instance data

	;in case this window was MAXIMIZED when first VIS_BUILT,
	;must create the system menu icons now. (Do this before the
	;MSG_VIS_VUP_UPDATE_WIN_GROUP)
	
CUAS <	mov	bp, mask SBF_IN_UPDATE_WIN_GROUP or mask SBF_WIN_GROUP \
							or VUM_NOW	>
CUAS <	call	OpenWinEnsureSysMenu					>
CUAS <	call	OpenWinEnsureSysMenuIcons				>

	;first: if the visible bounds for this object are actually
	;ratios of the Parent/Field window, convert to pixel coordinates now.
	;(This is VITAL if the window was originally opened maximized, and
	;so its _prevBounds has held ratios and not pixel values.)

	call	ConvertSpecWinSizePairsToPixels

	;set the position and size of this window INVALID so that
	;UpdateWinPosSize will re-stuff the visible bounds according to
	;the WST_AS_DESIRED or WPT_STAGGER, etc, flags.

	call	WinClasses_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_POSITION_INVALID \
					   or mask WPSS_SIZE_INVALID

	;now update the window according to hints passed from the application
	;or specific-ui determined behavior. IMPORTANT: if this sets
	;visible size = 4000h (DESIRED), it will set geometry invalid
	;so that this is converted into a pixel value before we try to display
	;or convert into a Ratio as window closes...

	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until OpenWinOpenWin to;do this.

if _NIKE
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	jne	noTitle
	mov	cx, ds:[di].OLDW_titleObject
	jcxz	noTitle

	push	si
	mov	si, cx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	si
noTitle:
endif

	;Mark everything as invalid: will cause SPEC_BUILD of window,
	;which will use new positioning and size flags, and will
	;enable the MAXIMIZE menu item.

	call	VisMarkFullyInvalid

	pop	dx			; dl = VisUpdateMode
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	call	WinClasses_ObjCallInstanceNoLock

done:
	ret
SetNotMaximized	endp

endif




COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinRestoreWin -- MSG_OL_RESTORE_WIN

DESCRIPTION:	This method is sent when the user selects "restore"
		from the window's system menu, or when he clicks on the
		Minimize icon.

		We have to decide if this means "un-maximize" or "un-iconify",
		and send the correct generic method back to this object,
		so that the Generic UI and this specific UI can work
		together to do the right thing.

PASS:		*ds:si - instance data
		es - segment of OLMenuedWinClass

		ax	- MSG_OL_RESTORE_WIN
		cx, dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version
	brianc	3/5/92		moved from OLWin to OLMenuedWin

------------------------------------------------------------------------------@

OLMenuedWinRestoreWin	method dynamic	OLMenuedWinClass, MSG_OL_RESTORE_WIN

	test	ds:[di].OLWI_fixedAttr, mask OWFA_RESTORABLE
	jz	done			; not restorable, do nothing

	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
					;assume window is minimized

	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
	jnz	OWRW_50			;skip if is minimized...

	;This window must be MAXIMIZED, since the RESTORE function was enabled.

	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED

OWRW_50:
	call	WinClasses_ObjCallInstanceNoLock
done:
	ret
OLMenuedWinRestoreWin	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinGupQuery -- MSG_SPEC_GUP_QUERY for OLMenuedWinClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLMenuedWinClass

	ax - MSG_SPEC_GUP_QUERY
	cx - Query type (GenQueryTypes or SpecGenQueryTypes)
	dx -?
	bp - OLBuildFlags
RETURN:
	carry - set if query acknowledged, clear if not
	bp - OLBuildFlags
	cx:dx - vis parent

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	WARNING: see OLMapGroup for up-to-date details

	if (query = SGQT_BUILD_INFO) {
		;Is below a window with a menu bar or trigger bar. Note that
		;if this window has GenFile or GenEdit type objects, then
		;the menu bar will already have been created.
		;(The important thing is we don't want GenTriggers with
		;HINT_FILE, etc, forcing the creation of a menu bar just to
		;find that there is no GenFile-type object to grab the Trigger.
		;OpenLook: all GenTriggers go into menu bar.

	    if (MENUABLE or HINT_SEEK_MENU_BAR
				or (OL and not HINT_AVOID_MENU_BAR) )
		and (menu not created yet) {
			create menu
	    }

	    if (menu bar has been created) and (not HINT_AVOID_MENU_BAR) {
	        MSG_SPEC_GUP_QUERY(menu bar, SGQT_BUILD_INFO);
		if (menu bar returned TOP_MENU or SUB_MENU true) {
	    	    return(stuff from parent)
		}

	    ;Return NULL so that GenParent will be used as visParent.
	    TOP_MENU = 0;
	    SUB_MENU = 0;
	    visParent = NULL;

	} else {
		send query to superclass (will send to generic parent)
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@

OLMenuedWinGupQuery	method	dynamic OLMenuedWinClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO		;can we answer this query?
	je	buildInfo			;skip if so...

	cmp	cx, SGQT_FIND_MENU_BAR
	je	findMenuBar

	;we can't answer this query: call super class to handle

	call	WinClasses_ObjCallSuperNoLock_OLMenuedWinClass
	ret

findMenuBar:
	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].OLMDWI_menuBar	;may be null
	stc
	ret

buildInfo:
	;Don't build menu bar if this is a custom window

	test	ds:[di].OLWI_moreFixedAttr, mask OWMFA_CUSTOM_WINDOW
	jnz	afterMenuBar

	;see if we want to create a menu bar
	;OpenLook defaults to placing trigger in the menu bar, unless there
	;is a HINT to prevent it. CUA/Motif default to placing the trigger
	;in the TriggerBar, unless hints say otherwise, or is case where
	;trigger is looking for a specific menu, such as the file menu.
	;(Rudy, menus are dialog boxes, leave it up to programmer.)
	;
	test	bp, mask OLBF_MENUABLE	;can object be placed in a menu?
	jnz	createMenuBar		;skip if so...

	;Is not MENUABLE, or seeking specific menu. OpenLook defaults to place
	;item in menu bar. CUA and MOTIF prefer it to be in the trigger bar.

OLS <	test	bp, mask OLBF_AVOID_MENU_BAR ;is hint present?		>
OLS <	jnz	afterMenuBar		;skip if so...			>

CUAS <	test	bp, mask OLBF_SEEK_MENU_BAR ;is hint present?		>
CUAS <	jz	afterMenuBar		;skip if not so...		>

createMenuBar: ;create a menu bar object
	;Does menu exist yet?

	tst	ds:[di].OLMDWI_menuBar
	jnz	menuBarExists

	push	bp

if MENU_BAR_IS_A_MENU

	call	OLMenuedWinCreateMenuBar
	call	WinClasses_DerefVisSpec_DI
else
	mov	di, offset OLMenuBarClass
	call	OpenWinCreateBarObject		;creates object, sets visible
						;parent = this OLWinClass obj,
						;and sends SPEC_BUILD to object
						;if this OLWinClass has already
						;been visbuilt.
	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLMDWI_menuBar, ax	;save handle of menu bar object

endif	;MENU_BAR_IS_A_MENU

if	(0)	; Having a little fun w/colors
	push	ax, bx, si
	mov	si, ax
	mov	ax, HINT_GADGET_BACKGROUND_COLORS 
	call	ObjVarAddData
	mov	ds:[bx].BC_unselectedColor1, C_LIGHT_GRAY
	mov	ds:[bx].BC_unselectedColor2, C_WHITE
	mov	ds:[bx].BC_selectedColor1, C_DARK_GRAY
	mov	ds:[bx].BC_selectedColor2, C_DARK_GRAY
	pop	ax, bx, si
endif

	;set OLWinClass = vertical composite

if _RUDY
	ANDNF	ds:[di].VCI_geoAttrs, not mask VCGA_ORIENT_CHILDREN_VERTICALLY
else
	ORNF	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
endif
	pop	bp

menuBarExists:
	;send query to the menu bar

if MENU_BAR_IS_A_MENU

	; There is no menu bar in Odie so we'll have to handle the query here.

	test	bp, mask OLBF_MENUABLE or mask OLBF_SEEK_MENU_BAR or \
		    mask OLBF_MENU_IN_DISPLAY
	jz	afterMenuBar		; are we menuable or seeking menu bar

	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].OLMDWI_menuBar
	or	bp, OLBR_TOP_MENU shl offset OLBF_REPLY
	jmp	done
else
	push	si
	mov	si, ds:[di].OLMDWI_menuBar
	mov	ax, MSG_BAR_BUILD_INFO
	call	WinClasses_ObjCallInstanceNoLock	;returns updated bp
	pop	si

	mov	bx, bp
	ANDNF	bx, mask OLBF_REPLY
	cmp	bx, OLBR_TOP_MENU shl offset OLBF_REPLY
	LONG jz	done
	cmp	bx, OLBR_SUB_MENU shl offset OLBF_REPLY
	LONG jz	done			;skip if parent grabbed...

endif	;MENU_BAR_IS_A_MENU

afterMenuBar:
	clr	cx				;return NULL
						;so that GenParent will
						;be used as visParent

done:
	stc				;query answered
	ret
OLMenuedWinGupQuery	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuedWinCreateMenuBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create menu bar object - the menu bar is itself a menu

CALLED BY:	OLMenuedWinGupQuery
PASS:		*ds:si	= OLMenuedWinClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if MENU_BAR_IS_A_MENU

OLMenuedWinCreateMenuBar	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter

	mov	dx, si				;*ds:dx = OLMenuedWin
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass	;instantiate a GenInteraction
	mov	ax, 0ffffh			;one-way upward & usable
	mov	bx, HINT_AVOID_MENU_BAR		;avoid menu bar
	mov	cx, ds:[LMBH_handle]		;instantiate in this block
	clr	bp				;no CompChildFlags
	call	OpenCreateChildObject		;^lcx:dx = GenInteraction

	call	WinClasses_DerefVisSpec_DI
	mov	ds:[di].OLMDWI_menuBar, dx	;save handle of menu bar object

	mov	cx, (C_DARK_GRAY shl 8) or C_LIGHT_GRAY
	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData
	jnc	getBuildFlags
;	mov	cl, ds:[bx].BC_unselectedColor1
;	mov	ch, ds:[bx].BC_selectedColor1
	;
	; if we have a custom background color for the title bar (which is
	; what HINT_GADGET_BACKGROUND_COLORS on a menued window does), we'll
	; use the selected (i.e. focused color) for the unselected menu color
	; to give the menu button the right background color.  We'll invert
	; that for the selected menu color.
	;
	mov	cl, ds:[bx].BC_selectedColor1	; menu's unselected color
	mov	ch, cl
	not	ch				; menu's selected color
	and	ch, 0x0f			; low nibble only

getBuildFlags:
	clr	bp
	call	VisCheckIfFullyEnabled
	jnc	build
	ornf	bp, mask SBF_VIS_PARENT_FULLY_ENABLED

build:
	mov	si, dx				;*ds:si = GenInteraction
	call	WinClasses_DerefGen_DI
	mov	ds:[di].GII_visibility, GIV_POPUP ; visibility = popup

	mov	dx, cx				;dx = Background color
	clr	cx
	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	call	ObjVarAddData
	mov	ax, HINT_CAN_CLIP_MONIKER_HEIGHT
	call	ObjVarAddData
	mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
	call	ObjVarAddData
	mov	ax, HINT_ORIENT_CHILDREN_HORIZONTALLY
	call	ObjVarAddData
	mov	ax, HINT_MENU_BAR
	call	ObjVarAddData

	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	mov	cx, size BackgroundColors
	call	ObjVarAddData
	mov	ds:[bx].BC_unselectedColor1, dl
	mov	ds:[bx].BC_unselectedColor2, dl
	mov	ds:[bx].BC_selectedColor1, dh
	mov	ds:[bx].BC_selectedColor2, dh

	push	bp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	cx, handle MenuBarMoniker
	mov	dx, offset MenuBarMoniker
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock
	pop	bp

	push	bp
	mov	ax, MSG_SPEC_BUILD
	call	ObjCallInstanceNoLock
	pop	bp
	;
	; let's build the win group too, so menu items can be set
	; usable (and correctly attached to menu bar via spec-build)
	; before the menu bar is opened
	;
	ornf	bp, mask SBF_WIN_GROUP
	mov	ax, MSG_SPEC_BUILD
	call	ObjCallInstanceNoLock

	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarDeleteData		; delete activated_by vardata

	call	WinClasses_DerefVisSpec_DI
	mov	si, ds:[di].OLPWI_button
	call	WinClasses_DerefVisSpec_DI
	ornf	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX 
	ornf	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	andnf	ds:[di].OLBI_specState, not mask OLBSS_MENU_DOWN_MARK
if _ODIE and DRAW_STYLES
	;
	; set flat draw style and no border for menu bar menu button
	;
	mov	ds:[di].OLBI_drawStyle, DS_FLAT
	andnf	ds:[di].OLBI_specState, not mask OLBSS_BORDERED
endif

	.leave
	ret
OLMenuedWinCreateMenuBar	endp

endif	; MENU_BAR_IS_A_MENU


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinCreateBarObject

DESCRIPTION:	This procedure creates a trigger or menu bar object,
		sets its visible parent, and sends a SPEC_BUILD on to
		it if necessary.

CALLED BY:	OLMenuedWinGupQuery, OLMenuBarBuildInfo

PASS:		ds - handle of block to create object in
		es:di	= class of object to create (OLTriggerBarClass
				or OLMenuBarObject)

RETURN:		ds, si = same
		ax	= handle of bar object

DESTROYED:	bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

------------------------------------------------------------------------------@

OpenWinCreateBarObject	proc	far
	push	si				;save handle of OLWinClass
	mov	bx, ds:[LMBH_handle]		;pass block to place obj in
	call	GenInstantiateIgnoreDirty	;create object
						;(returns si = bar object)

	mov	cx, ds:[LMBH_handle]		;pass cx:dx = parent obj
	pop	dx				;(parent of new object)
	push	dx				;save handle of parent
	mov	ax, MSG_OL_CTRL_SET_VIS_PARENT
	call	WinClasses_ObjCallInstanceNoLock	;set vis parent of object

	mov	ax, si				;save handle of menu bar
	pop	si				;get handle of parent

	;if window has been specifically built, spec build the menu bar

	call	VisCheckIfSpecBuilt
	jnc	OWCBO_endCreate			;skip if not vis built...

	;we need to "Vis build" this visible object

	clr	bp
	call	VisCheckIfFullyEnabled
	jnc	10$				;not fully enabled, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	push	si
	mov	si, ax				;si = handle of bar object
	mov	ax, MSG_SPEC_BUILD		;and spec build it
	call	WinClasses_ObjCallInstanceNoLock
	mov	ax, si				;ax = bar object
	pop	si

OWCBO_endCreate:
	ret
OpenWinCreateBarObject	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinSpecNavigateToNext - MSG_SPEC_NAVIGATE_TO_NEXT
		OLMenuedWinSpecNavigateToPrevious -
			MSG_SPEC_NAVIGATE_TO_PREVIOUS

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same

DESTROYED:	ax, bx, cx, dx, bp, es, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuedWinSpecNavigateToNextField	method dynamic OLMenuedWinClass, \
					MSG_SPEC_NAVIGATE_TO_NEXT_FIELD

	;default flags to pass: we are trying to navigate backards.

	clr	bp			;pass flags: navigate forwards
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	callCommon			;skip if not doing menus

	;the user has been navigating the menu bar: pass flag so that
	;query is kept within these items.

	mov	bp, mask NF_NAV_MENU_BAR ;pass flags: navigate forwards
					 ;through the menu bar.

callCommon:
					;pass ds:di = VisSpec instance data
	call	OpenWinNavigateCommon
	ret
OLMenuedWinSpecNavigateToNextField	endm

WinClasses	ends


KbdNavigation	segment resource

OLMenuedWinSpecNavigateToPreviousField	method dynamic OLMenuedWinClass, \
					MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD

	;default flags to pass: we are trying to navigate backards.

	mov	bp, mask NF_TRAVEL_CIRCUIT or \
		    mask NF_BACKTRACK_AFTER_TRAVELING
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	callCommon			;skip if not doing menus

	;the user has been navigating the menu bar: pass flag so that
	;query is kept within these items.

	mov	bp, mask NF_TRAVEL_CIRCUIT or \
		    mask NF_BACKTRACK_AFTER_TRAVELING or \
		    mask NF_NAV_MENU_BAR

callCommon:
					;pass ds:di = VisSpec instance data
	call	OpenWinNavigateCommon
	ret
OLMenuedWinSpecNavigateToPreviousField	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinFindKbdAccelerator -- 
		MSG_GEN_FIND_KBD_ACCELERATOR for OLMenuedWinClass

DESCRIPTION:	Finds any keyboard accelerators.  Subclassed here to find
		anything in the MDI windows menu, a child of the menu bar.

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
	Chris	5/ 2/90		Initial version

------------------------------------------------------------------------------@

if (0)	; OLMenuBarClass doesn't intercept MSG_GEN_FIND_KBD_ACCELERATOR

OLMenuedWinFindKbdAccelerator	method dynamic OLMenuedWinClass, \
				MSG_GEN_FIND_KBD_ACCELERATOR
	mov	si, ds:[di].OLMDWI_menuBar	;else find menu bar	
	tst	si				;is there one?
	jz	exit				;no, exit (carry should be 
						;  clear from tst)
	call	ObjCallInstanceNoLock		;else send to menu bar.
exit:
	ret
OLMenuedWinFindKbdAccelerator	endm

endif	; if (0)



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinQueryMenuBar -- 
		MSG_OL_WIN_QUERY_MENU_BAR for OLMenuedWinClass

DESCRIPTION:	Returns menu bar handle in cx.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_WIN_QUERY_MENU_BAR

RETURN:		cx 	- menu bar handle, of zero if none

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/90		Initial version

------------------------------------------------------------------------------@

OLMenuedWinQueryMenuBar	method dynamic OLMenuedWinClass, \
						MSG_OL_WIN_QUERY_MENU_BAR
	mov	cx, ds:[di].OLMDWI_menuBar	;get the menu bar handle	
	ret
OLMenuedWinQueryMenuBar	endm

KbdNavigation ends

Geometry	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinSetIconPos -- 
		MSG_OL_MW_SET_ICON_POS for OLMenuedWinClass

DESCRIPTION:	Sets a new slot and position (if there is a slot) for the icon.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_MW_SET_ICON_POS
		cx, dx  - new icon position
		bp low  - new slot

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/29/90		Initial version

------------------------------------------------------------------------------@

ifndef NO_WIN_ICONS	;------------------------------------------------------

OLMenuedWinSetIconPos	method OLMenuedWinClass, MSG_OL_MW_SET_ICON_POS

	;Store new icon position.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	bp, mask WPSS_STAGGERED_SLOT shr 8
	jz	10$				;no slot, don't set icon pos
	
	mov	ds:[di].OLMDWI_iconPosLeft, cx	;store new position
	mov	ds:[di].OLMDWI_iconPosTop, dx

10$:	;Store new slot number.

	mov	dl, {byte} ds:[di].OLMDWI_iconWinPosSizeState+1
	and	dl, not (mask WPSS_STAGGERED_SLOT shr 8)
	mov	cx, bp				;put slot in cl
	or	cl, dl				;or in new slot
	mov	{byte} ds:[di].OLMDWI_iconWinPosSizeState+1, cl
	ret
OLMenuedWinSetIconPos	endm

endif			; ifndef NO_WIN_ICONS ---------------------------------

Geometry	ends


Unbuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinQuit -- 
		MSG_META_QUIT for OLMenuedWinClass

DESCRIPTION:	Handles a quit.  Frees its corresponding icon.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_QUIT

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/28/90		Initial version

------------------------------------------------------------------------------@

OLMenuedWinQuit	method OLMenuedWinClass, MSG_META_QUIT
	mov	di, offset OLMenuedWinClass
	call	ObjCallSuperNoLock
	
	;Release its staggered slot # if it has one.
	;This will affect both the instance data for the object
	;and the data that might be saved.

	call	OpenWinFreeStaggeredSlot
	
ifndef NO_WIN_ICONS	;------------------------------------------------------

	;Release the icon slot as well.
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	dl, {byte} ds:[di].OLMDWI_iconWinPosSizeState+1
	ANDNF	dl, mask WPSS_STAGGERED_SLOT shr 8
					;only keep slot # (including ICON flag)
	test	dl, mask SSPR_SLOT	;test for slot # (ignore ICON flag)
	jz	done			;skip if not STAGGERED...
	mov	cx, SVQT_FREE_STAGGER_SLOT
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
done:
endif			; ifndef NO_WIN_ICONS ---------------------------------

	ret
OLMenuedWinQuit	endm

Unbuild	ends


WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinStartSelect -- 
		MSG_META_START_SELECT for OLMenuedWinClass

DESCRIPTION:	Handles a mouse press.   Handles if doubleclick; otherwise
		sends to superclass.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_START_SELECT

		ax	- method
		cx, dx	- ptr position
		bp	- [ UIFunctionsActive | buttonInfo ]


RETURN:		ax 	- MRF_PROCESSED, etc.

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/16/90		Initial version

------------------------------------------------------------------------------@

if	_CUA_STYLE
	
OLMenuedWinStartSelect	method OLMenuedWinClass, MSG_META_START_SELECT

if not KEYBOARD_ONLY_UI
	test	bp, (mask UIFA_SELECT) shl 8
	jz	callSuper			;nope, skip
	test	bp, mask BI_DOUBLE_PRESS	;see if doublepress
	jz	callSuper			;nope, skip

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	call	MouseInTitleBounds?		;see if in title area
	jnc	callSuper			;no, skip
if _GCM
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jnz	callSuper			;no doubleclicks in GCM mode
endif
	;
	; Toggle the maximized state.
	;
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jz	10$				;not currently max'ed, branch
	;
	; Currently maximized.  We want to restore it.
	;
	test	ds:[di].OLWI_fixedAttr, mask OWFA_RESTORABLE
	jz	callSuper			;not restorable, skip
	mov	ax, MSG_OL_RESTORE_WIN	;else we want to restore
	jmp	short 20$
10$:
	;
	; Currently unmaximized.
	;
	test	ds:[di].OLWI_attrs, mask OWA_MAXIMIZABLE	
	jz	callSuper			;not maximizable, skip
EC <	;before we load up MSG_GEN_DISPLAY_SET_MAXIMIZED, make sure it	>
EC <	;is a GenDisplay...						>
EC <	push	es, di							>
EC <	mov	di, segment GenDisplayClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenDisplayClass				>
EC <	call	ObjIsObjectInClass					>
EC <	pop	es, di							>
EC <	ERROR_NC	OL_ERROR					>
	mov	ax, MSG_GEN_DISPLAY_SET_MAXIMIZED	;we want to maximize
20$:
	call	ObjCallInstanceNoLock
	mov	ax, mask MRF_PROCESSED
	ret
	
callSuper:
endif

	mov	ax, MSG_META_START_SELECT		;reset method	
	mov	di, offset OLMenuedWinClass
	CallSuper	MSG_META_START_SELECT	;send to superclass
	ret
OLMenuedWinStartSelect	endm

endif

WinCommon	ends


KbdNavigation	segment resource
	

COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinKbdChar -- 
		MSG_META_FUP_KBD_CHAR for OLMenuedWinClass

DESCRIPTION:	Handles keyboard characters, in order to do MenuedWin 
		shortcuts.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_FUP_KBD_CHAR
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if handled

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/90		Initial version

------------------------------------------------------------------------------@

OLMenuedWinKbdChar	method OLMenuedWinClass, MSG_META_FUP_KBD_CHAR
						; If a modal window is up,
						; go ahead & process kbd input
						; for it (ignore input
						; overridden)
if _KBD_NAVIGATION and _USE_KBD_ACCELERATORS
 
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
if _GCM
	test	ds:[di].OLWI_fixedAttr, mask OWFA_GCM_TITLED
	jz	afterLocalShortcuts		; not GCM, local shortcuts
						;   handled by system menu
endif

if not _JEDIMOTIF ;------------------------------------------------------------
	;
	; See if there is currently a modal window up.  If there is, we
	; want to just do accelerators for that window.
	;
	;Don't handle state keys (shift, ctrl, etc).
	;
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	afterLocalShortcuts		;skip if not press event...

	push	es
						;set es:di = table of shortcuts
						;and matching methods
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLMenuedWinKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jnc	afterLocalShortcuts		;no match, branch

	;found a shortcut: send method to self.
	;
	call	ObjCallInstanceNoLock
	stc					;say handled
	jmp	short done

endif	; !_JEDIMOTIF ----------------------------------------------------------

afterLocalShortcuts:

endif	; _KBD_NAVIGATION and _USE_KBD_ACCELERATORS ----------------------------

if FUNCTION_KEYS_MAPPED_TO_MENU_BAR_BUTTONS
	;
	; If between F1-F4, pass number from 0 to 3 to menu bar...
	;
	test	dl, mask CF_FIRST_PRESS
	jz	callField		;skip if not press event...

	test	dh, mask SS_LCTRL or mask SS_RCTRL or mask SS_LALT or mask SS_RALT
	jnz	callField
if _JEDIMOTIF	;--------------------------------------------------------------
	;
	;  If it's the UC_MENU key, activate the app menu.
	;
DBCS <PrintMessage<checking for UC_MENU doesn't work in DBCS>>
	cmp	cx, (CS_UI_FUNCS shl 8) or UC_MENU
	jne	doneMenu
SBCS <	mov	cx, 5 + ((CS_CONTROL shl 8) or VC_F1)	; no time for beauty>
DBCS <	mov	cx, 5 + C_SYS_F1)			; no time for beauty>
	jmp	callMenu
doneMenu:
endif	;-----------------------------------------------------------------------
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F1		;F1  key?	>
DBCS <	cmp	cx, C_SYS_F1				;F1 key?	>
	jb	callField

if _JEDIMOTIF ;--------------------

	;
	; F1-F5 plus F6 for App Menu
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F6		;go up to F6	>
DBCS <	cmp	cx, C_SYS_F6				;F6 key?	>
	ja	callField
else

SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F4		;F4  key?	>
DBCS <	cmp	cx, C_SYS_F4				;F4 key?	>
	ja	callField

endif	; _JEDIMOTIF ---------------

callMenu::
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLMDWI_menuBar
	jz	sendItUp

SBCS <	sub	cx, (CS_CONTROL shl 8) or VC_F1				>
DBCS <	sub	cx, C_SYS_F1						>

	mov	si, ds:[di].OLMDWI_menuBar
	mov	ax, MSG_OL_MENU_BAR_ACTIVATE_TRIGGER
	call	ObjCallInstanceNoLock
	stc
	jmp	short done
endif

callField:

sendItUp::
	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, offset OLMenuedWinClass
	call	ObjCallSuperNoLock
done:
	ret
	
OLMenuedWinKbdChar	endm


if _KBD_NAVIGATION and _USE_KBD_ACCELERATORS ; --------------------------------

;Keyboard shortcut bindings for OLMenuedWinClass

if not _JEDIMOTIF

OLMenuedWinKbdBindings	label	word
	word	length OLMWinShortcutList
if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLMWinShortcutList KeyboardShortcut \
	<0, 1, 0, 0, C_SYS_F4 and mask KS_CHAR>		;F4 = close window
else
	 ;P     C  S     C
	 ;h  A  t  h  S  h
	 ;y  l  r  f  e  a
	 ;s  t  l  t  t  r
OLMWinShortcutList	KeyboardShortcut \
	<0, 1, 0, 0, 0xf, VC_F4>	;close window
endif
;OLMWinMethodList	label word
	word	MSG_OL_WIN_CLOSE

endif	; not _JEDIMOTIF

endif	; _KBD_NAVIGATION and _USE_KBD_ACCELERATORS ---------------------------

KbdNavigation	ends


WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinLostSysExcl -- MSG_META_LOST_SYS_FOCUS_EXCL

DESCRIPTION:	We've just lost the sys focus exclusive. This is mainly
		handled by CWin/cwinExcl.asm (OLWinClass), but at this level
		we want to reset the gadget exclusive within this window,
		to ensure that the user is not interacting with any
		gadgets or menus inside this Primary or Display.

PASS:		*ds:si - instance data
		ax - MSG_META_LOST_SYS_FOCUS_EXCL
		cx, dx, bp = ?

RETURN:

DESTROYED:	bx, di, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/90		Initial version

------------------------------------------------------------------------------@

OLMenuedWinLostSysExcl	method dynamic	OLMenuedWinClass, \
						MSG_META_LOST_SYS_FOCUS_EXCL
	push	ax

	; Make sure the user isn't interacting with any gadgets or menus.
	; As we're in the middle of updating the focus hierarchy, wait until
	; that has completed, before nuked the gadget excl, otherwise we can
	; end up in some nested update situations.	-- Doug 9/17/92
	;
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	clr	cx			;grab active exclusive semaphore:
	clr	dx			;will notify open menu and force it to
					;close up toute suite.
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

	pop	ax
	mov	di, offset OLMenuedWinClass
	GOTO	ObjCallSuperNoLock

OLMenuedWinLostSysExcl	endp

			


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinDetermineVisParentForChild -- 
		MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD for OLMenuedWinClass

DESCRIPTION:	Determines a child's visible parent.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
		^lcx:dx - child
		bp -- SpecBuildFlags

RETURN:		carry set if something special found
		^lcx:dx - vis parent to use, or null if nothing found
		bp -- SpecBuildFlags
		ax -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/91		Initial version

------------------------------------------------------------------------------@
OLMenuedWinDetermineVisParentForChild	method OLMenuedWinClass, \
				MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
	
	;
	;  Check for title-bar left/right group, which should
	;  be directly below us.
	;
	call	WinClasses_DerefVisSpec_DI 
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
	cmp	cx, ds:[di].OLWI_sysMenu	;same block as system menu?
	jne	checkTitleGroup			;no, not a window button

	;
	; Check for various window buttons, and let them be directly
	; below us.
	;
if not _REDMOTIF ;----------------------- Not needed for Redwood project
	cmp	dx, offset SMI_MinimizeIcon
	je	exitNoSpecialChild
	cmp	dx, offset SMI_MaximizeIcon
	je	exitNoSpecialChild
	cmp	dx, offset SMI_RestoreIcon
	je	exitNoSpecialChild
endif ; not _REDMOTIF ;------------------- Not needed for Redwood project
endif

checkTitleGroup:
	;
	;  If this object wants to be in the title bar, return
	;  the appropriate title-bar group as the parent.
	;
	call	MaybeInTitleBar			; carry set if in title bar
	jc	exit				; ^lcx:dx = parent

if _ALLOW_MISC_GADGETS_IN_MENU_BAR	;--------------------------------------
	;
	;  If this object wants to be in the menu bar, return
	;  the menu-bar group as the parent.
	;
	call	MaybeInMenuBar
	jc	exit		
endif	; _ALLOW_MISC_GADGETS_IN_MENU_BAR ------------------------------------

putUnderGadgetArea::
	;
	;  By default the object goes in the gadget area.
	;
	mov	si, ds:[di].OLMDWI_gadgetArea	;see if there is anything
	tst	si
	jz	exit				;exit (carry should be clear)
	
	mov	dx, si
	mov	cx, ds:[LMBH_handle]		;else return ^lbx:si
	stc					;say found
	jmp	short exit
	
exitNoSpecialChild:
	clr	cx				;(will clear carry)
	mov	dx, cx				;return null
exit:
	Destroy	ax
	ret
OLMenuedWinDetermineVisParentForChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaybeInTitleBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this object wants to be in the title bar.

CALLED BY:	OLMenuedWinDetermineVisParentForChild

PASS:		^lcx:dx = object for which to determine parent
		*ds:[si] = OLMenuedWin instance data

RETURN:		carry set if it should be in a title group
			^lcx:dx = parent (title group)
		carry clear if not in a title group
			cx, dx = same

		object block may have moved (ds updated)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/28/94			Initial version
	Joon	11/14/94		Simplified and allow
					^hcx != ds:[LMBH_handle]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MaybeInTitleBar	proc	near
		uses	ax,bx,si,di
		.enter
	;
	; Search the child object for titlebar hints
	;
		push	si
		movdw	bxsi, cxdx
		call	ObjSwapLock
		push	bx

		mov	ax, HINT_SEEK_TITLE_BAR_LEFT
		call	ObjVarFindData
		mov	ax, TGT_LEFT_GROUP
		jc	unlock

		mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
		call	ObjVarFindData
		mov	ax, TGT_RIGHT_GROUP
unlock:
		pop	bx
		call	ObjSwapUnlock
		pop	si
		jnc	done				; not in titlebar
	;
	;  Object wants to be in the title bar.
	;
		mov_tr	bx, ax				; bx <- TitleGroupType

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		movdw	cxdx, ds:[di+bx].OLWI_titleBarLeftGroup
		tst	cx				; any group yet?
		jnz	inTitleBar
	;
	;  We don't have this title group yet, so make one and return
	;  it as the vis parent.
	;
		call	CreateTitleBarGroup

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset		; ds:di = instance
		movdw	ds:[di+bx].OLWI_titleBarLeftGroup, cxdx
inTitleBar:
		stc					; found parent
done:
		.leave
		ret
MaybeInTitleBar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTitleBarGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an interaction to hold stuff in.

CALLED BY:	MaybeInTitleBar

PASS:		*ds:si	= window object
		bx	= TitleGroupType

RETURN:		^lcx:dx = title group

DESTROYED:	nothing (block may move -- ds updated)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/21/94			Initial version
	Joon	11/14/94		Delay vis add of titlebar group

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTitleBarGroup	proc	far
		uses	ax,di,si,bp,es
		.enter
	;
	;  Create the empty object.
	;
		push	bx
		mov	di, segment OLTitleGroupClass
		mov	es, di
		mov	di, offset OLTitleGroupClass	; es:di = class
		call	OpenWinCreateBarObject		; ax <- titleGroup
		pop	bx
	;
	;  Turn geometry management OFF.  We'll turn it back on
	;  (temporarily) when the title bar is managing its own
	;  geometry (OpenWinPositionTitleBarGroup).
	;
		push	ax				; save new object
		mov	si, ax				; *ds:si = object
		mov	ax, MSG_VIS_SET_ATTRS
		mov	cx, mask VA_MANAGED shl 8	; bits to clear
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		pop	dx

		mov	cx, ds:[LMBH_handle]		; ^lcx:dx = titleGroup
	;
	;  Set some flags in the new object.  It got vis-grown by
	;  the message we just sent it.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset		; ds:di = instance

		cmp	bx, TGT_RIGHT_GROUP
		je	rightGroup

		ornf	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_LEFT \
			shl offset OLBF_TARGET
		jmp	done
rightGroup:
		ornf	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_RIGHT \
			shl offset OLBF_TARGET		
done:
		.leave
		ret
CreateTitleBarGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaybeInMenuBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if object should be in menu bar.

CALLED BY:	OLMenuedWinDetermineVisParentForChild

PASS:		^lcx:dx = object for which to determine parent
		*ds:si	= OLMenuedWin object

RETURN:		carry set if it should be in a title group
			^lcx:dx = parent (title group)
		carry clear if not in a title group
			cx, dx = same

		object block may have moved (ds updated)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	10/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _ALLOW_MISC_GADGETS_IN_MENU_BAR	;---------------------------------------

MaybeInMenuBar	proc	near
		uses	ax,bx,si,di,bp
		.enter

	Assert	optr cxdx				; check child
	Assert	objectPtr  dssi, OLMenuedWinClass	; check parent

if _ODIE

	;
	; Why limit to same block?
	;
	mov	bp, si				; save OLMenuedWin
	movdw	bxsi, cxdx			; ^lbx:si = object
	call	ObjSwapLock			; *ds:si = object
	push	bx				; save OLMenuedWin block
	mov	ax, HINT_SEEK_MENU_BAR
	call	ObjVarFindData			; carry set if found
	pop	bx				; bx = our block
	call	ObjSwapUnlock			; *ds:bp = OLMenuedWin
						; (preserves flags)
	jnc	done				; not in menu bar
	mov	cx, ds:[LMBH_handle]		; menu bar in same block as
						;	OLMenuedWin

else

	;
	;  Deal with the child not being in the same block as
	;  the parent.  (If it's not, then exit -- the object
	;  will wind up in the gadget area instead of the menu
	;  bar.)
	;
		cmp	cx, ds:[LMBH_handle]
		clc					; assume not same block
		jne	done
	;
	;  See if the child wants to be in the menu bar.
	;
		mov	bp, si				; *ds:bp = parent
		mov	si, dx				; *ds:si = object
		mov	ax, HINT_SEEK_MENU_BAR
		call	ObjVarFindData			; carry set if found
		jnc	done				; nope, bail

endif

	;
	;  Return optr of menu bar.
	;
		mov	si, bp				; *ds:si = window
		call	WinClasses_DerefVisSpec_DI	; ds:di = instance
		mov	dx, ds:[di].OLMDWI_menuBar

		Assert	optr cxdx			; check menu bar
		stc					; found parent
done:
		.leave
		ret
MaybeInMenuBar	endp

endif	; _ALLOW_MISC_GADGETS_IN_MENU_BAR ------------------------------------

WinClasses	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinTranslateToGenMessage

DESCRIPTION:	Handle specific UI messages by sending
		MSG_GEN_DISPLAY_* to self.

PASS:
	*ds:si - instance data
	es - segment of OLMenuedWinClass

	ax 	- MSG_OL_WIN_CLOSE
		  MSG_OL_WIN_MAXIMIZE
		  MSG_OL_WIN_MINIMIZE

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
	brianc	3/3/92		Initial version

------------------------------------------------------------------------------@
OLMenuedWinTranslateToGenMessage	method	dynamic	OLMenuedWinClass,
							MSG_OL_WIN_CLOSE,
							MSG_OL_WIN_MINIMIZE,
							MSG_OL_WIN_MAXIMIZE

EC <	push	es, di							>
EC <	mov	di, segment GenDisplayClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenDisplayClass				>
EC <	call	ObjIsObjectInClass					>
EC <	pop	es, di							>
EC <	ERROR_NC	OL_ERROR					>

	mov	cx, MSG_GEN_DISPLAY_CLOSE
	cmp	ax, MSG_OL_WIN_CLOSE
	je	sendIt
	mov	cx, MSG_GEN_DISPLAY_SET_MINIMIZED
	cmp	ax, MSG_OL_WIN_MINIMIZE
	je	sendIt
	mov	cx, MSG_GEN_DISPLAY_SET_MAXIMIZED
EC <	cmp	ax, MSG_OL_WIN_MAXIMIZE					>
EC <	ERROR_NE	OL_ERROR					>
sendIt:
	mov	ax, cx
	call	ObjCallInstanceNoLock
	ret
OLMenuedWinTranslateToGenMessage	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinNotifyEnabled -- 
		MSG_SPEC_NOTIFY_ENABLED and MSG_SPEC_NOTIFY_NOT_ENABLED for
		OLWinClass

DESCRIPTION:	Handles notifying an object that it is enabled or not.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED or MSG_SPEC_NOTIFY_NOT_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

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
	brianc	12/5/92		Initial Version

------------------------------------------------------------------------------@

OLMenuedWinNotifyEnabled	method dynamic	OLMenuedWinClass,
			MSG_SPEC_NOTIFY_ENABLED, MSG_SPEC_NOTIFY_NOT_ENABLED

	push	ax, dx				;save method and flag
	mov	di, offset OLMenuedWinClass
	call	ObjCallSuperNoLock		;call superclass
	DoPop	dx, ax				;restore method and flag
	jnc	exit				;no state change, exit
	
	push	si
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLMDWI_gadgetArea	;get gadget area
	tst	si
	jz	doneGadgetArea			;none
	push	ax, dx
	call	ObjCallInstanceNoLock
	pop	ax, dx
doneGadgetArea:
	pop	si

	push	si
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLMDWI_menuBar	;get menu bar
	tst	si
	jz	doneMenuBar			;none
	push	ax, dx
	call	ObjCallInstanceNoLock
	pop	ax, dx
doneMenuBar:
	pop	si

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLMDWI_triggerBar	;get trigger bar
	tst	si
	jz	doneTriggerBar			;none
	call	ObjCallInstanceNoLock
doneTriggerBar:

	stc					;return state changed
exit:
	ret
OLMenuedWinNotifyEnabled	endm

ActionObscure	ends


WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinSpecSetUsable

DESCRIPTION:	Handle set-usable by bring OLMenuedWin (GenDisplay and
		GenPrimary to the top).

PASS:
	*ds:si - instance data
	es - segment of OLMenuedWinClass

	ax 	- MSG_SPEC_SET_USABLE
	dl	- VisUpdateMode

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
	brianc	3/10/92		Initial version

------------------------------------------------------------------------------@
OLMenuedWinSpecSetUsable	method	dynamic	OLMenuedWinClass,
							MSG_SPEC_SET_USABLE
if 0		; "on-startup" no longer includes setting usable
		; - brianc 7/9/92
	;
	; First, check if we should be minimized on startup (additional
	; interpretation of this is to minimize on usable).  If so, set
	; appropriate spui stuff (see OLMenuedWinCheckForGensMinimized)
	;
	; OLMenuedWinCheckForGensMinimized will clear
	; ATTR_GEN_DISPLAY_MINIMIZED_STATE so that the generic handler for
	; MSG_GEN_DISPLAY_SET_MINIMIZED (sent below) will work.
	;
	push	ax, cx, dx, bp
	mov	ax, HINT_DISPLAY_MINIMIZED_ON_STARTUP
	call	OLMenuedWinCheckForGensMinimized
	jc	minimizeNow
	;
	; if not HINT_DISPLAY_MINIMIZED_ON_STARTUP, check for minimized
	; state when set not-usable (or set minimized while not-usable).  We
	; want to preserve this across the not-usable/usable boundary.
	;
	; OLMenuedWinCheckForGensMinimized will clear
	; ATTR_GEN_DISPLAY_MINIMIZED_STATE so that the generic handler for
	; MSG_GEN_DISPLAY_SET_MINIMIZED (sent below) will work.
	;
	mov	ax, ATTR_GEN_DISPLAY_MINIMIZED_STATE
	call	OLMenuedWinCheckForGensMinimized
	jnc	notMinimized
minimizeNow:
	;
	; if minimized on startup or minimized when set not-usable (or set
	; minimized while not-usable), do the normal
	; MSG_GEN_DISPLAY_SET_MINIMIZED handling
	;
	mov	ax, MSG_GEN_DISPLAY_SET_MINIMIZED
	mov	dl, VUM_NOW
	call	WinClasses_ObjCallInstanceNoLock
notMinimized:
	pop	ax, cx, dx, bp
endif
	;
	; then, let superclass handle
	;
	call	WinClasses_ObjCallSuperNoLock_OLMenuedWinClass
	;
	; then bring to top, give focus and target, etc
	;
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	WinClasses_ObjCallInstanceNoLock
	ret
OLMenuedWinSpecSetUsable	endm

WinClasses	ends


Unbuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinSpecSetNotUsable

DESCRIPTION:	Handle set-not-usable by freeing the associated icon
		GenPrimary, if any.  This is okay as it will be reconstructed
		when this OLMenued made usable again.

PASS:
	*ds:si - instance data
	es - segment of OLMenuedWinClass

	ax 	- MSG_SPEC_SET_NOT_USABLE
	dl	- VisUpdateMode

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
	brianc	3/13/92		Initial version
	joon	12/31/92	Release stagger slots

------------------------------------------------------------------------------@
OLMenuedWinSpecSetNotUsable	method	dynamic	OLMenuedWinClass,
							MSG_SPEC_SET_NOT_USABLE
	push	ax, dx

	;Release its staggered slot # if it has one.
	;This will affect both the instance data for the object
	;and the data that might be saved.

	call	OpenWinFreeStaggeredSlot
	
ifndef NO_WIN_ICONS	;------------------------------------------------------

	;Release the icon slot as well.
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	dl, {byte} ds:[di].OLMDWI_iconWinPosSizeState+1
	ANDNF	dl, mask WPSS_STAGGERED_SLOT shr 8
					;only keep slot # (including ICON flag)
	test	dl, mask SSPR_SLOT	;test for slot # (ignore ICON flag)
	jz	10$			;skip if not STAGGERED...
	mov	cx, SVQT_FREE_STAGGER_SLOT
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
10$:
	;
	;make OLWinIcon object NOT_USABLE (can set generic state of
	;this object since was created by specific UI and not application)
	;	ds:di = instance data

	mov	ax, MSG_SPEC_SET_ATTRS
	mov	dl, VUM_NOW
	mov	cx, mask SA_REALIZABLE shl 8
					;turn off SA_REALIZABLE flag
	call	OLMenuedWinCallIconObject

endif	; ifndef NO_WIN_ICONS -------------------------------------------------

	pop	ax, dx
	;
	; let superclass handle
	;
	mov	di, offset OLMenuedWinClass
	call	ObjCallSuperNoLock
	ret
OLMenuedWinSpecSetNotUsable	endm

Unbuild ends


ActionObscure segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinUpdateIconMoniker

DESCRIPTION:	If we have an icon, update its moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of OLMenuedWinClass
		ax 	- MSG_OL_MENUED_WIN_UPDATE_ICON_MONIKER

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@

ifndef NO_WIN_ICONS	;------------------------------------------------------
	
OLMenuedWinUpdateIconMoniker	method dynamic OLMenuedWinClass,
				MSG_OL_MENUED_WIN_UPDATE_ICON_MONIKER
	;
	; If GenApplication moniker changes, resolve moniker list, and redo
	; icon and icon caption monikers as if our moniker were changed.
	;
	call	UpdateAllMonikers
	ret
OLMenuedWinUpdateIconMoniker endm

endif			; ifndef NO_WIN_ICONS ---------------------------------

ActionObscure	ends


WinClasses	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinSpecUpdateVisMoniker

DESCRIPTION:	OLMenuedWin's moniker has been changed.  If the new moniker
		is a moniker list, we'll need to resolve it (we prevented it
		from being resolved earlier by intercepting
		MSG_SPEC_RESOLVE_MONIKER_LIST).  Before resolving, however,
		we re-compute the icon and icon caption monikers, and tell
		our icon, if any, about them.

PASS:		*ds:si 	- instance data
		es     	- segment of OLMenuedWinClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER

		dl	- VisUpdateMode
		cx	- old moniker width
		bp	- old moniker height

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/3/92		Initial version

------------------------------------------------------------------------------@

ifndef NO_WIN_ICONS	;------------------------------------------------------
	
OLMenuedWinSpecUpdateVisMoniker	method dynamic OLMenuedWinClass,
					MSG_SPEC_UPDATE_VIS_MONIKER
	;
	; First, resolve moniker list and redo monikers for icon and icon
	; caption
	;
	push	ax, cx, dx, bp		; save MSG_SPEC_UPDATE_VIS_MONIKER data
	call	UpdateAllMonikers
	pop	ax, cx, dx, bp		; get MSG_SPEC_UPDATE_VIS_MONIKER data
	;
	; Then, call superclass to update window header
	;
	call	WinClasses_ObjCallSuperNoLock_OLMenuedWinClass
	ret
OLMenuedWinSpecUpdateVisMoniker endm

endif			; ifndef NO_WIN_ICONS ---------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateAllMonikers

DESCRIPTION:	Resolve moniker list, if any, and find icon and icon caption
		monikers, in case this window is iconified.

CALLED BY:	INTERNAL
			OLMenuedWinUpdateIconMoniker
			OLMenuedWinSpecUpdateVisMoniker

PASS:		*ds:si	- OLMenuedWin instance data
		es	- segment of OLMenuedWinClass

RETURN:		*ds:[si].OLMDWI_iconCaptionMoniker updated
		*ds:[si].OLMDWI_iconMoniker updated
		icon and icon caption objects, if any, updated
		updates ds

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/30/92		initial version

------------------------------------------------------------------------------@

ifndef NO_WIN_ICONS	;------------------------------------------------------

UpdateAllMonikers	proc	far		;also called from diff resource
	;
	; get optrs of monikers for icon moniker and icon caption moniker
	;
	call	FindIconMonikers
	;
	; tell icon, if any, about new monikers
	;
	call	OLMenuedWinSendIconMonikers
	;
	; resolve moniker list, if any
	;
	call	OLMenuedWinFindTitleMoniker
	ret
UpdateAllMonikers	endp

OLMenuedWinSendIconMonikers	proc	near	uses	si
	.enter
	call	WinClasses_DerefVisSpec_DI
	sub	sp, size IconMonikerPassData
	mov	bp, sp
	push	es, di
.assert ((offset OLMDWI_iconMoniker-OLMDWI_iconMoniker) eq IMPD_iconMoniker)
.assert ((offset OLMDWI_iconCaptionMoniker-OLMDWI_iconMoniker) eq IMPD_iconCaptionMoniker)
	mov	si, di				; ds:si = source
	add	si, offset OLMDWI_iconMoniker
	segmov	es, ss				; es:di = dest.
	mov	di, bp
	mov	cx, (2*(size optr))/2		; using movsw
	rep movsw				; copy over two optrs
	mov	ax, MSG_OL_WIN_ICON_UPDATE_MONIKER
	pop	es, di
	mov	bx, ds:[di].OLMDWI_icon.handle	;set ^lbx:si = OLWinIcon object
	mov	si, ds:[di].OLMDWI_icon.chunk
	tst	si
	jz	done
EC <	;must have monikers, if we have icon				>
EC <	tst	ss:[bp].IMPD_iconMoniker.handle				>
EC <	ERROR_Z	OL_ERROR						>
EC <	tst	ss:[bp].IMPD_iconCaptionMoniker.handle			>
EC <	ERROR_Z	OL_ERROR						>
	mov	dx, size IconMonikerPassData
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
done:
	add	sp, size IconMonikerPassData
	.leave
	ret
OLMenuedWinSendIconMonikers	endp

endif			; ifndef NO_WIN_ICONS ---------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuedWinSetMenuCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set menu center

CALLED BY:	MSG_OL_MENUED_WIN_SET_MENU_CENTER
PASS:		*ds:si	= OLMenuedWinClass object
		ds:di	= OLMenuedWinClass instance data
		ds:bx	= OLMenuedWinClass object (same as *ds:si)
		es 	= segment of OLMenuedWinClass
		ax	= message #
		cx	= menu center, 0 for screen center
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if MENU_BAR_IS_A_MENU

OLMenuedWinSetMenuCenter	method dynamic OLMenuedWinClass, 
					MSG_OL_MENUED_WIN_SET_MENU_CENTER
	mov	ds:[di].OLMDWI_menuCenter, cx
	ret
OLMenuedWinSetMenuCenter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuedWinGetMenuCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get menu center

CALLED BY:	MSG_OL_MENUED_WIN_GET_MENU_CENTER
PASS:		*ds:si	= OLMenuedWinClass object
		ds:di	= OLMenuedWinClass instance data
		ds:bx	= OLMenuedWinClass object (same as *ds:si)
		es 	= segment of OLMenuedWinClass
		ax	= message #
RETURN:		cx	= menu center, 0 for screen center
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLMenuedWinGetMenuCenter	method dynamic OLMenuedWinClass, 
					MSG_OL_MENUED_WIN_GET_MENU_CENTER
	mov	cx, ds:[di].OLMDWI_menuCenter
	ret
OLMenuedWinGetMenuCenter	endm

endif

WinClasses	ends

;-------------------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuedWinSpecResolveMonikerList - 
		MSG_SPEC_RESOLVE_MONIKER_LIST handler.

DESCRIPTION:	Intercept MSG_SPEC_RESOLVE_MONIKER_LIST to NOT resolve moniker
		list.  We will delay this until MSG_SPEC_UPDATE_VIS_MONIKER
		comes in, at which time, we'll update our icon and icon caption
		monikers, tell the icon, if any, about them, then finally
		resolve the moniker list in-place.

PASS:		*ds:si	- instance data
		*ds:cx	- moniker list to resolve

RETURNS:	moniker list unchanged

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/3/92		initial version

------------------------------------------------------------------------------@

OLMenuedWinSpecResolveMonikerList	method dynamic	OLMenuedWinClass, \
					MSG_SPEC_RESOLVE_MONIKER_LIST
	ret
OLMenuedWinSpecResolveMonikerList	endm

WinMethods	ends
