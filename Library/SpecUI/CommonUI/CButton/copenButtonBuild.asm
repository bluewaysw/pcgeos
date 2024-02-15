COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (gadgets code common to all specific UIs)
FILE:		copenButtonBuild.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLButtonClass		Open look button

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenButton.asm

DESCRIPTION:

	$Id: copenButtonBuild.asm,v 1.3 98/03/13 16:11:32 joon Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonInitialize -- MSG_META_INITIALIZE for OLButtonClass

DESCRIPTION:	Initialize a specific-ui button object.

PASS:		*ds:si - instance data
		es - segment of OlButtonClass
		ax - MSG_META_INITIALIZE

RETURN:		nothing

DESTROYED:	bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Assume the ButtonClass instance data has been initialized to zero,
	so all of our state flags are FALSE. Set the field in the instance
	data which indicates where the generic object is.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	9/89		commenting, removed call to UpdateButtonState
				since do not always have a generic object
				at this point in time.

------------------------------------------------------------------------------@

OLButtonInitialize	method private static	OLButtonClass,
							MSG_META_INITIALIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	CallMod	VisInitialize

	;
	; Set first field in generic part of OLButtonInstance structure
	;
	mov	di, ds:[si]			;get pointer to instance data
	add	di, ds:[di].Vis_offset		;push ahead to specific offset
	mov	ds:[di].OLBI_genChunk, si	;Init gen data as coming from
						;this object

					; This object, if requested to
					; Vis build, must be a GenTrigger,
					; which can use the default
					; MSG_SPEC_BUILD.  Set flag so that
					; we can specify visual parent.
	ORNF	ds:[di].VI_specAttrs, mask SA_SIMPLE_GEN_OBJ or \
					mask SA_CUSTOM_VIS_PARENT

	;Set these flags.  If the button wants to clear them in SCAN_GEOMETRY_-
	;HINTS, it will.

	ORNF	ds:[di].VI_geoAttrs, mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID or\
				     mask VGA_USE_VIS_CENTER or \
				     mask VGA_USE_VIS_SET_POSITION


	;set button type and visual-appearance flags to default: assume
	;this object is not subclassed, so set flags = normal button object.

	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED

if DRAW_STYLES
	;
	; default to 3D raised
	;
	mov	ds:[di].OLBI_drawStyle, DS_RAISED
endif

	call	OLButtonScanGeometryHints

	;
	; If this button is seeking the title bar, give it an
	; attribute to help it size correctly.  Note that we
	; can't do this from within a VarDataHandler routine,
	; so we have to do it here.
	;
	mov	ax, HINT_SEEK_TITLE_BAR_LEFT
	call	ObjVarFindData
	jc	inTitleBar

	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	call	ObjVarFindData
	jnc	notInTitleBar

inTitleBar:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON

	;
	;  This attribute will cause the button to return the
	;  height of the title bar as its height -- a Good Thing.
	;
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR		; set flag
	clr	cx
	call	ObjVarAddData

notInTitleBar:

	.leave
	ret
OLButtonInitialize	endp

if _GCM	;----------------------------------------------------------------------
OLButtonHintHandlers	VarDataHandler \
	<HINT_TRIGGER_BRINGS_UP_WINDOW, offset Build:OLButtonSetWinFlagHint>,
	<ATTR_GEN_TRIGGER_IMMEDIATE_ACTION, offset Build:OLButtonSetImmediateAction>,
	<HINT_DEFAULT_DEFAULT_ACTION, offset Build:OLButtonSetIsDefault>,
	<HINT_MDI_LIST_ENTRY, offset Build:OLButtonIsMDIListEntry>,
	<HINT_SYS_ICON, offset Build:OLButtonHintSysIcon>,
	<HINT_EXPRESS_MENU, offset Build:OLButtonHintExpressMenu>,
	<HINT_GCM_SYS_ICON, offset Build:OLButtonHintGCMSysIcon>,
	<HINT_DEFAULT_FOCUS, offset Build:OLButtonHintMakeDefaultFocus>,
	<HINT_SHOW_SHORTCUT, \
			offset Build:OLButtonShowShortcut>,
	<HINT_DRAW_SHORTCUT_BELOW, \
			offset Build:OLButtonDrawShortcutBelow>,
	<HINT_DONT_SHOW_SHORTCUT, \
			offset Build:OLButtonDontShowShortcut>
else	; not _GCM ------------------------------------------------------------

OLButtonHintHandlers	VarDataHandler \
	<HINT_TRIGGER_BRINGS_UP_WINDOW, offset Build:OLButtonSetWinFlagHint>,
	<ATTR_GEN_TRIGGER_IMMEDIATE_ACTION, offset Build:OLButtonSetImmediateAction>,
	<HINT_DEFAULT_DEFAULT_ACTION, offset Build:OLButtonSetIsDefault>,
	<HINT_MDI_LIST_ENTRY, offset Build:OLButtonIsMDIListEntry>,
	<HINT_SYS_ICON, offset Build:OLButtonHintSysIcon>,
	<HINT_EXPRESS_MENU, offset Build:OLButtonHintExpressMenu>,
if EVENT_MENU
	<HINT_EVENT_MENU, offset Build:OLButtonHintExpressMenu>,
endif
	<HINT_DEFAULT_FOCUS, offset Build:OLButtonHintMakeDefaultFocus>,
if DRAW_STYLES
	<HINT_DRAW_STYLE_FLAT, offset Build:OLButtonDrawStyleFlat>,
endif
	<HINT_SHOW_SHORTCUT, \
			offset Build:OLButtonShowShortcut>,
	<HINT_DRAW_SHORTCUT_BELOW, \
			offset Build:OLButtonDrawShortcutBelow>,
	<HINT_DONT_SHOW_SHORTCUT, \
			offset Build:OLButtonDontShowShortcut>
endif	; _GCM	----------------------------------------------------------------

if DRAW_STYLES
OLButtonDrawStyleFlat	proc	far
	class	OLButtonClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLBI_drawStyle, DS_FLAT
	ret
OLButtonDrawStyleFlat	endp
endif

OLButtonDrawShortcutBelow	proc	far
	class	OLButtonClass
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_moreAttrs, mask OLBMA_DRAW_SHORTCUT_BELOW
	ret
OLButtonDrawShortcutBelow	endp

;
; This allows normal keyboard and mouse systems to force showing shortcuts.
; This is overridden by the keyboard-only (where shortcuts are always drawn)
; and the no-keyboard (where shortcuts are never drawn) modes
;
OLButtonShowShortcut	proc	far
	class	OLButtonClass
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_FORCE_SHORTCUT
done:
	ret
OLButtonShowShortcut	endp

;
; This allows objects to force not showing shortcuts.
; This is overrides keyboard-only mode.
;
OLButtonDontShowShortcut	proc	far
	class	OLButtonClass
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_FORCE_NO_SHORTCUT
done:
	ret
OLButtonDontShowShortcut	endp

OLButtonSetIsDefault	proc	far
	class	OLButtonClass
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_MASTER_DEFAULT_TRIGGER
	ret
OLButtonSetIsDefault	endp

OLButtonSetImmediateAction	proc	far
	class	OLButtonClass
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_IMMEDIATE_ACTION
						;Update flags based on new
						;generic object.
	ret
OLButtonSetImmediateAction	endp

OLButtonHintMakeDefaultFocus	proc	far
	class	OLButtonClass
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_DEFAULT_FOCUS
	ret
OLButtonHintMakeDefaultFocus	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonIsMDIListEntry
DESCRIPTION:	Handles case of GenItem being used by Display/App to
		generate an entry in a menu where the moniker of the
		list entry should be the Display/App.
CALLED BY:	INTERNAL
PASS:
	Std data to Hint Handler
RETURN:
DESTROYED:
	Std data to Hint Handler
------------------------------------------------------------------------------@
OLButtonIsMDIListEntry	proc	far
	class	OLButtonClass

	; This object is GenItem created by a GenDisplay or an application.
	; turn off OLBSS_BORDERED (CUAS/MAC: indicate is in menu so draws
	; correctly)

	push	cx
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
CUAS <	ORNF	ds:[di].OLBI_specState, mask OLBSS_IN_MENU		>
	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED

	; NEXT, fetch the generic object in this same block whose enabled
	; flag & moniker we'll use.  Note that this couldn't have come from
	; a resource.  Rather, OLDislayClass copies the list entry from
	; a resource & stuffs the chunk into the hint directly, before
	; setting this object USABLE.  This object is always destroyed/
	; discarded on DETACH.
						; ds:bx = ptr to hint args
	mov	cx, {word} ds:[bx]		; Fetch genChunk of Display/App
						; to use for moniker, enabled
						; flags
	tst	cx				; if NULL, don't change gen
						; chunk (just use this object
						; itself, as inited)
	jz	afterChunkChange
	mov	ds:[di].OLBI_genChunk, cx	; store into specific instance
afterChunkChange:
	call	UpdateButtonState		;trashes only ax & di
	pop	cx
	ret
OLButtonIsMDIListEntry	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonScanGeometryHints --
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLButtonClass

DESCRIPTION:	Scans geometry hints.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

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
	chris	2/ 4/92		Initial Version

------------------------------------------------------------------------------@

OLButtonScanGeometryHints	method static OLButtonClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	; If this OLButton has generic hints, then scan them.  (Use the
	; gen part of the button, though.  -cbh 6/29/92)

	push	si
	mov	di, ds:[si]		; get pointer to instance data
	add	di, ds:[di].Vis_offset
	mov	cx, si			; keep chunk in cx as well
	mov	si, ds:[di].OLBI_genChunk
	tst	si
	jz	5$
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	5$			; skip if not...
					;Otherwise, handle hints:
	segmov	es, cs			; setup es:di to be ptr to
					; Hint handler table

	mov	di, offset cs:OLButtonHintHandlers
	mov	ax, length (cs:OLButtonHintHandlers)
	call	ObjVarScanData
5$:
	pop	si

	;parent doesn't care about size: set flag for Geometry Manager:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].VI_geoAttrs, mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID or \
				     mask VGA_USE_VIS_CENTER or \
				     mask VGA_USE_VIS_SET_POSITION
	;
	; Assume these hints aren't around.
	;
	ANDNF	ds:[di].OLBI_moreAttrs, not \
			(mask OLBMA_EXPAND_WIDTH_TO_FIT_PARENT or \
			 mask OLBMA_EXPAND_HEIGHT_TO_FIT_PARENT or \
			 mask OLBMA_CAN_CLIP_MONIKER_WIDTH or \
			 mask OLBMA_CAN_CLIP_MONIKER_HEIGHT or \
			 mask OLBMA_CENTER_MONIKER)

	clr	cx			      ;assume no flags
	push	si
	mov	si, ds:[di].OLBI_genChunk     ;look for hints in generic part
	tst	si
	jz	10$

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	pop	di
	jz	10$				; skip if gen chunk is not gen

	call	OpenSetupGadgetGeometryFlags  ;set up geometry hints
10$:
	pop	si
	ORNF	ds:[di].OLBI_moreAttrs, cl
90$:
	; If we can take the default, let's tell our parent about it.
	;
	.leave
	ret
OLButtonScanGeometryHints	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonSetWinFlag --
			MSG_OL_BUTTON_SET_WIN_FLAG for OLButtonClass

DESCRIPTION:	Set the OLBSS_WINDOW_MARK flag

PASS:
	*ds:si - instance data
	es - segment of OLButtonClass

	ax - The method

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
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@

OLButtonSetWinFlagHint	proc	far
	mov	si, cx
	FALL_THRU	OLButtonSetWinFlag
OLButtonSetWinFlagHint	endp

OLButtonSetWinFlag	method	OLButtonClass, MSG_OL_BUTTON_SET_WIN_FLAG
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_specState, mask OLBSS_WINDOW_MARK
	ret
OLButtonSetWinFlag	endm


OLButtonClearWinFlag	method	OLButtonClass, MSG_OL_BUTTON_CLEAR_WIN_FLAG
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_WINDOW_MARK
	ret
OLButtonClearWinFlag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonHintSysIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notes that this object is a system icon.  It also makes it
		unmanaged since the window will place it itself.
		This is also called form OLMenuButtonSetup when it is
		initializing a system menu button.

CALLED BY:	OLButtonHintHandlers - HINT_MO_SYS_ICON

PASS:		ds:cx -- OLButtonInstance

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLButtonHintSysIcon	proc	far
	class	OLButtonClass

	;Note that this is a system icon

	call	OLButtonSetAsSysIcon

	;Its geometry is managed by the window, not by the geometry window.

	ANDNF	ds:[di].VI_attrs, not mask VA_MANAGED
	ret
OLButtonHintSysIcon	endp

OLButtonHintExpressMenu	proc	far
	class	OLButtonClass

if TOOL_AREA_IS_TASK_BAR

	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TBF_ENABLED is set
	pop	ds					; restore ds
	jz	done					; skip if no taskbar

	ret
done:
endif
	FALL_THRU 	OLButtonSetAsSysIcon
OLButtonHintExpressMenu	endp

OLButtonSetAsSysIcon	proc	far
	;Note that this is a system icon.

	push	si
	mov	si, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	pop	si
	ret
OLButtonSetAsSysIcon	endp

if _GCM
OLButtonHintGCMSysIcon	proc	far
	class	OLButtonClass

	call	OLButtonHintSysIcon	;perform HINT_SYS_ICON work

	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_GCM_SYS_ICON
	ret
OLButtonHintGCMSysIcon	endp
endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonGetVisParent -- MSG_SPEC_GET_VIS_PARENT

DESCRIPTION:	This objects SHOULD respond to this method by returning
		the OD of visible parent to use for this object. To save time
		and space later, we also set some button attributes.

		Since we have to do a BUILD_INFO query to find the correct
		visible parent, and this query returns the BuildFlags which
		indicate where this button is placed, we use these flags
		to set the correct OLBI_specState attribute flags for
		the button. Normally, we would do this during initialization
		or during SPEC_BUILD.

PASS:		ax 	- MSG_SPEC_GET_VIS_PARENT
		ds:*si 	- instance data
		bp	- SpecBuildFlags
		es     	- segment of OLButtonClass

RETURN:		carry set if have custom vis parent to use
			cx:dx = visparent
		carry clear to force use of GenParent

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/20/89		Initial version
	Eric	7/89		additional commenting
	Doug	9/89		Changed from SpecBuild to GetVisParent routine
	Eric	1/90		added doc on query.

------------------------------------------------------------------------------@

OLButtonGetVisParent	method	OLButtonClass, MSG_SPEC_GET_VIS_PARENT
EC <	call	VisCheckVisAssumption					>

	push	bp			; Save SpecBuildFlags
	CallMod	UpdateButtonState	; copy generic state data from
					; GenTrigger object, set
					; DRAW_STATE_KNOWN

	; returns ds:di = VisInstance

	; If in B&W, force the first draw of the button to erase the
	; background in case the button is drawn on a non-white background.
	; -- JimG (4/11/94)
	call	OpenCheckIfBW
	jnc	usingColor
	andnf	ds:[di].OLBI_optFlags, not mask OLBOF_DRAW_STATE_KNOWN

usingColor:
	;
	;  OK, a bit of a hack.  The primary help button has been
	;  moved into the title-bar-right group, so it needs to go
	;  through the process of asking the primary for its custom
	;  parent.  However, for sizing & other reasons, it also has
	;  OLBSS_SYS_ICON set on it.  So before checking that bit,
	;  we check the button for HINT_SEEK_TITLE_BAR_LEFT/RIGHT and
	;  automatically check if it's got that hint.  Eventually all
	;  system icons should be moved into the title-bar groups,
	;  in which case this code and the two lines following the
	;  next block comment below can all be nuked.  -stevey 10/5/94
	;
	push	bx
	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	call	ObjVarFindData
	pop	bx
	jc	isStandAloneButton

	push	bx
	mov	ax, HINT_SEEK_TITLE_BAR_LEFT
	call	ObjVarFindData
	pop	bx
	jc	isStandAloneButton
	;
	; First check if this is a system menu icon.  If so, skip the
	; query -- just use generic parent (GenDisplay/Primary) as vis parent.
	;
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jz	afterSysIcon		;skip if not...

	push	bx, si			;if so, always place visibly on
	call	GenFindParent		;generic parent, the Display/Primary
	mov	cx, bx
	mov	dx, si
	pop	bx, si
	pop	bp
	jmp	short exitCarrySet

afterSysIcon:
	;if this is a button which opens a popup window (menu, command window),
	;then MSG_OL_BUTTON_SETUP will have already set one of the
	;"window mark" flags in this button. If none are set, it means that
	;this is a normal GenTrigger.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, OLBSS_OPENS_POPUP_WINDOW_MASK
	jz	isStandAloneButton	;skip if does not open a window...

	;this button opens a popup window (menu or command window)
	;get the query results from the window's instance data

	mov	di, ds:[di].OLBI_genChunk ;get chunk of window object
	cmp	si, di			;quick check: GenTriggers with
					;HINT_TRIGGER_BRINGS_UP_WINDOW will have window
					;mark flag set, but treat as a
					;standard button.
	je	isStandAloneButton	;skip if so...

EC <	xchg	si, di							>
EC <	call	GenCheckGenAssumption	;Make sure gen data exists	>
EC <   	xchg	si, di							>
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLCI_visParent.handle
	mov	dx, ds:[di].OLCI_visParent.chunk
	stc
	jmp	short haveParent	;skip ahead...

isStandAloneButton:
	;Since the generic->specific build for this object did not perform
	;the BUILD_INFO query which is necessary to determine where this button
	;lives, we must do it now. First scan hints for things like
	;HINT_SEEK_MENU_BAR and HINT_AVOID_MENU_BAR

	mov	dx, mask OLBF_TRIGGER	;init OLBuildFlags: is trigger
	call	ScanMapGroupHintHandlers;returns dx = OLBuildFlags
					;see table in cspecInteraction
	;
	; send a query up the generic tree to see if this GenTrigger should
	; be visually placed beneath an object besides the generic parent.
	;
	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, SGQT_BUILD_INFO
	mov	bp, dx				;pass OLBuildFlags in bp
	call	GenCallParent		;returns carry flag, OLBuildFlags
					;in bp, and cx:dx = custom vis parent

	;Update draw flags if button according to where this button (or menu
	;button has been placed), so OLButtonClass draw handler will draw ok.

	lahf				;save carry flag

	call	UseQueryResultsToSetButtonAttributes

	; if no parent returned by gup-query, ask generic parent

	tst	cx			;clears carry
	jz	haveParent

	sahf				;restore carry flag

haveParent:
	;Return parent not known if vis parent we came up with matches our
	;regular gen parent.  Vis class will call the gen parent with MSG_SPEC_
	;DETERMINE_VIS_PARENT_FOR_CHILD in case the parent has a generally
	;different idea about where its children go.

	pop	bp				;get SpecBuildFlags
	jnc	exit				;definitely not handled, exit

	push	si
	call	GenFindParent
	cmp	si, dx				;if something other than gen
	pop	si				;  parent, we'll exit with it
	jne	exitCarrySet
	cmp	bx, cx
	je	exit				;(carry is clear)

exitCarrySet:
	stc
exit:
	;carry flag is TRUE if we have a custom visparent (cx:dx) to use
	ret
OLButtonGetVisParent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseQueryResultsToSetButtonAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update draw flags if button according to where
		this button (or menu button has been placed),
		so OLButtonClass draw handler will draw ok.

CALLED BY:	OLButtonGetVisParent, OLButtonSetup
PASS:		*ds:si	= OLButtonObject
		bp	= OLBuildFlags
RETURN:		*ds:di	= VisSpec Instance data of object
DESTROYED:	ax, bx, cx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	11/16/95    	Added this documentation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UseQueryResultsToSetButtonAttributes	proc	near
	mov	bx, bp			;bx = OLBuildFlags
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = SpecInstance

	and	bx, mask OLBF_TARGET
	cmp	bx, (OLBT_IS_POPUP_LIST) shl offset OLBF_TARGET
	jne	checkForAvoidMenuBar

	;button brings up popup list


EC <	push	di							>
EC <	mov	di, segment OLMenuButtonClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLMenuButtonClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
EC <	pop	di							>

	;A terrible, terrible thing I'm doing here, to set menu button instance
	;data here, but who cares.    Also, we must set WAS_BORDERED as later
	;the popup window thinks it's been opened (because we spec build it
	;during button size calcs) and will restore the button's old status,
	;which generally is only saved when you actually click on the button
	;to open the popup list, so we'll force it here.  -5/27/92 cbh
	;(Changed to not automatically clip the moniker.  Apps will set that
	;on the GenItemGroup as they see fit.  -cbh 12/11/92)

	ORNF	ds:[di].OLMBI_specState, mask OLMBSS_OPENS_POPUP_LIST



if _ISUI ; don't center
;	ORNF	ds:[di].OLBI_moreAttrs, mask OLBMA_CAN_CLIP_MONIKER_WIDTH
else
	ORNF	ds:[di].OLBI_moreAttrs, mask OLBMA_CENTER_MONIKER ;or \
;					mask OLBMA_CAN_CLIP_MONIKER_WIDTH
endif	;----------------------------------------------------------------------

	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED or \
					mask OLBSS_WAS_BORDERED

	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_IN_MENU_BAR
	ret

checkForAvoidMenuBar:
	;
	; If avoiding the menu bar, we'll bestow a border on it and exit.
	; (We'll also try putting a down arrow on it, unless its the express
	; menu, and see what happens.  -cbh 12/10/92)
	;
	test	bp, mask OLBF_AVOID_MENU_BAR
	jz	checkForInMenuBar

if	(_MOTIF or _ISUI) and not _DETACHED_MENUS_DRAW_AS_NORMAL_BUTTONS

	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED or \
					mask OLBSS_MENU_DOWN_MARK

	push	si
	mov	si, ds:[di].OLBI_genChunk
	tst	si
	jz	10$
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VI_typeFlags, mask VTF_IS_GEN
	jz	10$
if EVENT_MENU
	mov	ax, HINT_EVENT_MENU
	call	ObjVarFindData
	jc	9$
endif
	mov	ax, HINT_EXPRESS_MENU
	call	ObjVarFindData
	jnc	10$
9$::
	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_MENU_DOWN_MARK
10$:
	pop	si
else
	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED
endif
	ret

checkForInMenuBar:

	mov	bx, bp
	and	bx, mask OLBF_REPLY
	cmp	bx, OLBR_TOP_MENU shl offset OLBF_REPLY	;in menu bar?
	jne	checkForInMenu		;skip if not in menu bar...

inMenu::
	;button is in the MenuBar object

OLS <	ORNF	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR \
					or mask OLBSS_BORDERED		>

CUAS <	ORNF	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR		>

	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED
	ret

checkForInMenu:
	cmp	bx, OLBR_SUB_MENU shl offset OLBF_REPLY
	jne	done			;skip if not...

	ORNF	ds:[di].OLBI_specState, mask OLBSS_IN_MENU

MO   <	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED		>
ISU  <	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED		>
OLS  <	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED		>

done:
	ret
UseQueryResultsToSetButtonAttributes	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonSpecBuild

DESCRIPTION:	Visibly build a button

PASS:		*ds:si - instance data
		es - segment of OLButtonClass
		ax - MSG_SPEC_BUILD
		bp - SpecBuildFlags

RETURN:		nothing

DESTROYED:	ax, cx, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version
	Joon	9/92		Check for items in scrollable lists

------------------------------------------------------------------------------@


OLButtonSpecBuild	method private static	OLButtonClass, MSG_SPEC_BUILD
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class


if	ALLOW_ACTIVATION_OF_DISABLED_MENUS

if	_MENUS_PINNABLE
	call	CheckIfPushpin
	jnc	AA10
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
	jmp	short AA20		; can't have ATTR_SYSTEM_MENU_CLOSE

AA10:
endif

	;
	; if "Close" item in window's system menu, always enabled to allow
	; closing a pinned menu (even one that is disabled)
	;
	; XXX: This can possibly be optimized by find an instance data bit,
	; and scanning when other vardata is scanned
	;
	mov	ax, ATTR_SYSTEM_MENU_CLOSE
	call	ObjVarFindData
	jnc	AA20
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
AA20:
endif

if	NORMAL_HEADERS_ON_DISABLED_WINDOWS
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jz	NH10
					; always enabled if sys icon
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
NH10:
endif

					; Call superclass to do Vis Build
	mov	di, segment OLButtonClass
	mov	es, di
	mov	di, offset OLButtonClass
	CallSuper	MSG_SPEC_BUILD


	;Check to see if we're in a menu, and set an optimization flag if so.
	;This is also done in UseQueryResultsToSetButtonAttributes, but it
	;doesn't always work there (our visible parent may not have had a
	;MENU hint in it.)  Some of that code probably could go away.
	;-cbh 12/13/91

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON

	jnz	notInMenu		;sys icons are not in menu

	push	si
	call	SwapLockOLWin
	jc 	visPart

	;If the button is an item inside a scrollable list, SwapLockOLWin
	;returns garbage because it couldn't find an OLWin parent in the Vis
	;tree.  This seems to be caused by the fact that the scrollable list
	;is a child of a GenContent which does not have it's VI_link set until
	;after we've done SPEC_BUILD.  JS. 9/3/92.  So we need to
	;check for ...

	pop	si
	push	si
        push    di, es
	mov     di, segment OLScrollableItemClass
	mov     es, di
	mov     di, offset OLScrollableItemClass
	call    ObjIsObjectInClass
	pop     di, es
	jnc	visPart
	call	GenFindParent		;This item is inside a scrollable list.
	call	ObjSwapLock		;Set OLBSS_IN_MENU flag based on
	mov	di, ds:[si]		;whether the gen parent is a popup list
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLIGI_moreState, mask OLIGMS_POPUP_LIST
	call	ObjSwapUnlock
	pop	si
	jnz	inMenu
	jmp	short notInMenu

	;Otherwise we can check the usual case where the button is not under
	;a GenContent.

visPart:
	mov	di, si
	pop	si
	jnc	notInMenu		;code added 11/23/94 cbh to check for
					;  no window

	push	si
	mov	di, ds:[di]

	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	call	ObjSwapUnlock
	pop	si
	jz	notInMenu		;skip if not in menu...
inMenu:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_specState, mask OLBSS_IN_MENU

MO   <	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED		>
ISU  <	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED		>
OLS  <	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED		>

notInMenu:

	push	bp

	;if this is a GenTrigger within a pinned menu, then set BORDERED

OLS <	mov	di, ds:[si]						>
OLS <	add	di, ds:[di].Vis_offset					>
OLS <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
OLS <	jz	10$							>
OLS <	call	OLButtonTestIfInPinnedMenu				>
OLS <10$:								>

	;initialize a few FixedAttr flags: see if this button is inside
	;a reply bar, and set the default value for the TEMP_DEFAULT flag.
	;first: if this is a GenTrigger inside a reply bar, set flag.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_SETTING or mask OLBSS_IN_MENU
	jnz	20$			;skip if not a button

	call	OpenCheckDefaultRings
	jnc	20$
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_QUERY_FOR_REPLY_BAR
	call	VisCallParent
	jnc	20$			;skip if not in reply bar...

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR

20$:	;finish up:

	call	OLButtonInitFixedAttrs

	;
	; If this GenTrigger is marked with
	; ATTR_GEN_TRIGGER_INTERACTION_COMMAND, notify
	; the GenInteraction above us of the trigger's optr
	;
	; IMPORTANT:  This must occur after the superclass handling of
	; MSG_SPEC_BUILD as we need the visual links to be in place for
	; the MSG_VIS_VUP_QUERY to get up to the OLDialogWin
	;
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	call	ObjVarFindData		; any interaction command?
	jnc	noInteractionCommand	; nope
EC <	VarDataFlagsPtr	ds, bx, ax					>
EC <	test	ax, mask VDF_EXTRA_DATA					>
EC <	ERROR_Z	OL_ERROR_ATTR_GEN_TRIGGER_INTERACTION_COMMAND_WITHOUT_DATA >
	;
	; notify GenInteraction with MSG_VIS_VUP_QUERY
	;
	sub	sp, size NotifyOfInteractionCommandStruct
	mov	bp, sp			; dx:bp=NotifyOfInteractionCommandStruct
	mov	dx, ss
	mov	ax, ds:[LMBH_handle]	; pass GenTrigger optr
	mov	ss:[bp].NOICS_optr.handle, ax
	mov	ss:[bp].NOICS_optr.chunk, si
	mov	ax, ds:[bx]		; pass ATTR_GEN_TRIGGER_I_C data
	mov	ss:[bp].NOICS_ic, ax
	mov	ss:[bp].NOICS_flags, 0
	mov	ax, MSG_OL_WIN_NOTIFY_OF_INTERACTION_COMMAND
	call	CallOLWin		; only go up to first OLWin
	add	sp, size NotifyOfInteractionCommandStruct
noInteractionCommand:

	call	HandleGenericButtonHints

	;if this GenTrigger is marked as the DEFAULT trigger (via a hint)
	;then notify the parent window.

	call	OpenButtonCheckIfFullyEnabled
	jnc	done			;skip if not enabled...

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_MASTER_DEFAULT_TRIGGER
	jz	done			;skip if not...

	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_SET_MASTER_DEFAULT
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	CallOLWin		; call OLWinClass object above us

done:
if _HAS_LEGOS_LOOKS
	call	LegosSetButtonLookFromHints
endif
	pop	bp
	.leave
	ret
OLButtonSpecBuild	endp


if _HAS_LEGOS_LOOKS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegosSetButtonLookFromHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The legos look is stored in instance data, so when
		we unbuild and rebuild we need to set it from the hints.

		*** Note ***
		This code is pretty much identical to code in Window, Item
		and CComp (Ctrl).  There should only be one routine that is
		called with the table to check against and the offset to
		the legos look instance data passed in.  I just don't have
		time to do it right now.

CALLED BY:	OLButtonSpecBuild
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegosSetButtonLookFromHints	proc	near
	uses	ax, bx, bp, di
	.enter

	clr	bp			; our table index

	;
	; Start our indexing at 1, as 0 has no hint
	;
loopTop:
	inc	bp
	inc	bp			; next entry
	mov	ax, cs:[buildLegosButtonLookHintTable][bp]
	call	ObjVarFindData
	jc	gotLook

	cmp	bp, LAST_BUILD_LEGOS_BUTTON_LOOK * 2
	jl	loopTop

	clr	bp			; no hints found, so must be look 0

gotLook:
	mov	ax, bp			; use ax as bp can't be byte addressable
	sar	ax, 1			; words to bytes
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLBI_legosLook, al
done:
	.leave
	ret
LegosSetButtonLookFromHints	endp

	;
	; Make sure this table matches that in copenButtonCommon.asm.  The
	; only reason the table is in two places it is that I don't want
	; to be bringing in the WinMethods resource at build time, and it
	; is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
buildLegosButtonLookHintTable	label word
	word	0
LAST_BUILD_LEGOS_BUTTON_LOOK	equ ((($ - buildLegosButtonLookHintTable) / \
					(size word)) - 1)
CheckHack<LAST_BUILD_LEGOS_BUTTON_LOOK eq LAST_LEGOS_BUTTON_LOOK>

endif	; endif of if _HAS_LEGOS_LOOKS




COMMENT @----------------------------------------------------------------------

ROUTINE:	HandleGenericButtonHints

SYNOPSIS:	Handles a couple of hints that apply to any button.

CALLED BY:	OLButtonSpecBuild, OLButtonSetup

PASS:		*ds:si -- button

RETURN:		nothing

DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/12/92	Initial version

------------------------------------------------------------------------------@

HandleGenericButtonHints	proc	near
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, di
	mov	si, ds:[di].OLBI_genChunk	;use generic part of object

	push	es
	segmov	es, cs			;es:di = hint handlers
	mov	di, offset cs:OLButtonHintHandlers2
	mov	ax, length (cs:OLButtonHintHandlers2)
	call	ObjVarScanData
	pop	es
	pop	si
	ret
HandleGenericButtonHints	endp



OLButtonHintHandlers2	VarDataHandler \
	<HINT_TRIGGER_DESTRUCTIVE_ACTION, \
		offset Build:OLButtonSetIsDestructiveAction>,
		;GenInteractions use HINT_INTERACTION_CANNOT_BE_DEFAULT,
		;which has the same value
	<HINT_ENSURE_TEMPORARY_DEFAULT, \
		offset Build:OLButtonEnsureTemporaryDefault>,
	<ATTR_GEN_DEFAULT_MONIKER,
		offset OLButtonDefaultMoniker>,
	<HINT_NO_BORDERS_ON_MONIKERS,
		offset OLButtonNoBordersOnMonikers>



OLButtonSetIsDestructiveAction	proc	far
	class	OLButtonClass

	mov	di, cx
	ANDNF	ds:[di].OLBI_fixedAttrs, \
				not (mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER)
	ret
OLButtonSetIsDestructiveAction	endp

OLButtonNoBordersOnMonikers	proc	far
	class	OLButtonClass

	mov	di, cx
	ANDNF	ds:[di].OLBI_specState, not mask OLBSS_BORDERED
	ret
OLButtonNoBordersOnMonikers	endp

OLButtonEnsureTemporaryDefault	proc	far
	class	OLButtonClass

	call	OpenCheckDefaultRings
	jnc	done
	mov	di, cx
	ORNF	ds:[di].OLBI_fixedAttrs, \
				mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER

	;
	; Let parent OLCtrl know that there are children who will be getting
	; large.  -12/ 8/92 cbh
	;
	mov	cx, mask OLCOF_OVERSIZED_CHILDREN
	mov	ax, MSG_SPEC_CTRL_SET_MORE_FLAGS
	call	VisCallParent
done:
	ret
OLButtonEnsureTemporaryDefault	endp

OLButtonDefaultMoniker		proc	far
	mov	bx, ds:[bx]			;bx = monier type
	shl	bx
	mov	dx, cs:[defaultMonikerTable][bx]
	mov	cx, handle StandardMonikers
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	ObjCallInstanceNoLock		;ax = chunk
	ret
OLButtonDefaultMoniker	endp

defaultMonikerTable	word	\
	offset	DefaultLevel0Moniker,
	offset	DefaultLevel1Moniker,
	offset	DefaultLevel2Moniker,
	offset	DefaultLevel3Moniker,
	offset	StandardHelpMoniker,
	offset	StandardPrimaryHelpMoniker
CheckHack <(length defaultMonikerTable) eq GenDefaultMonikerType>

if _OL_STYLE	;--------------------------------------------------------------

;See code in OLPopupWinSpecBuild also.

OLButtonTestIfInPinnedMenu	proc	far
	;if this GenTrigger is within a pinned menu, then set BORDERED

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	done			;skip if not in menu...

	test	ds:[di].OLBI_specState, mask OLBSS_SETTING
	jnz	done			;skip if setting...

	push	bx, si
	call	SwapLockOLWin
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_fixedAttr,  (mask OLWSS_PINNED shl 8)
	call	ObjSwapUnlock
	pop	bx, si
; Hmmm... SwapLockOLWin doesn't allow for this case... let's see if
; we blow up!
;	jnc	done			;skip if query not answered...
	jz	done			;skip if menu not pinned...

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_specState, mask OLBSS_BORDERED

done:
	ret
OLButtonTestIfInPinnedMenu	endp

endif		;--------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonInitFixedAttrs

DESCRIPTION:	initialize a few FixedAttr flags: see if this button is inside
		a reply bar, and set the default value for the
		TEMP_DEFAULT flag.

		NOTE: I have moved the "check for reply bar" code out of this
		routine, because we may not yet hve a visible parent.
		See callers for info.

CALLED BY:	OLButtonSpecBuild, OLButtonSetup

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version

------------------------------------------------------------------------------@

OLButtonInitFixedAttrs	proc	near
	call	SetToolboxBasedOnParent		;set toolbox setting

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;set expand-to-fit on all menu buttons.  (Not needed anymore -- buttons
	;get correct width from OLMenuWin's now.)

;	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
;	jz	20$			;move along if not a menu button
;	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_EXPAND_WIDTH_TO_FIT_PARENT
;
;20$:
	;set the default "temporary default" behavior flag, then scan hints
	;to see if app designer wants to override.

	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_MASTER_DEFAULT_TRIGGER
	jz	25$			;skip if not master default trigger...

	;this is the MASTER default trigger: it can be the temporary default,
	;except if it is in a menu.
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
					mask OLBSS_IN_MENU_BAR
	jnz	30$			;skip if menu related...
	jz	27$			;skip if normal master trigger
					;(give it temp default)...

25$:
if _MOTIF or _ISUI ;----------------------------------------------------------
	;Motif: only if inside reply bar do we allow temporary default
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR
	jz	30$			;skip if not in reply bar...
endif 		;--------------------------------------------------------------

27$:
	call	OpenCheckDefaultRings
	jnc	30$
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER

30$:
	ret
OLButtonInitFixedAttrs	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	SetToolboxBasedOnParent

SYNOPSIS:	Sets toolbox flag.  Also forces the thing to expand its height
		to fit the parent when necessary, to make toolboxes look nice
		onscreen.

CALLED BY:	OLButtonInitFixedAttrs, OLMenuButtonSetup

PASS:		*ds:si -- button

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/92		Initial version

------------------------------------------------------------------------------@

SetToolboxBasedOnParent	proc	near
	; set toolbox attribute based on parent
	; (changed 2/28/92 cbh to get the flags from generic parent, so that
	;  OLPopupWin's work)
	;
	; DON'T do this for HINT_MDI_LIST_ENTRY GenItems because their
	; genChunk is a GenDisplay whose parent is a GenDisplayControl, which
	; doesn't become a specific UI subclass of OLCtrlClass, where
	; MSG_GET_BUILD_FLAGS is implemented.  The Window menu can't be a
	; toolbox anyway (ack!, not yet anyway) - brianc 3/26/92
	;
	mov	ax, HINT_MDI_LIST_ENTRY
	call	ObjVarFindData
	LONG jc	10$			; found, don't do this!


	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLBI_genChunk
	call	GenSwapLockParent
	jnc	popSiExit			; no generic parent, exit
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLCI_buildFlags	; Get the build flags
	mov	dl, ds:[di].VCI_geoAttrs	; and geometry orientation
	call	ObjSwapUnlock
	pop	si
	;
	; if we're in title bar group, set flag
	;
	mov	di, cx
	andnf	di, mask OLBF_TARGET
	cmp	di,  OLBT_FOR_TITLE_BAR_LEFT shl offset OLBF_TARGET
	je	setTitleBar
	cmp	di, OLBT_FOR_TITLE_BAR_RIGHT shl offset OLBF_TARGET
	jne	notInTitleBar
setTitleBar:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	push	cx
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR		; don't save to state
	clr	cx
	call	ObjVarAddData
	pop	cx
notInTitleBar:

	;
	; If we're a toolbox button, expand our height to fill a horizontal
	; toolbox, and expand our width to fill a vertical one.  Also, for now,
	; let's forget about menu arrows on popups in vertical lists.
	; (Forget about expand width to fit -- it's so ugly when the font
	;  menu is there...)  (Also, no expand if we're in a menu. -cbh 1/29/93)
	; (Changed to re-allow menu marks in vertical toolboxes.  -cbh 3/18/93)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	cx, mask OLBF_TOOLBOX
	jz	10$
if _STYLUS
	;
	; don't mark close button as being in-toolbox
	;
	mov	ax, HINT_CLOSE_BUTTON
	call	ObjVarFindData
	jc	noToolboxForClose
endif
	or	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
noToolboxForClose::
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	7$			;don't expand height if in menu

	mov	cl, mask OLBMA_EXPAND_HEIGHT_TO_FIT_PARENT
	test	dl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	7$			;parent toolbar horizontal, branch
if	_MOTIF
	call	OpenCheckIfNarrow	;not narrow, keep menu down mark
	jnc	8$			;3/21/93 cbh
endif
	and	ds:[di].OLBI_specState, not mask OLBSS_MENU_DOWN_MARK
	jmp	short	8$
7$:
	or	ds:[di].OLBI_moreAttrs, cl
8$:
	and	ds:[di].VI_geoAttrs, not mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
10$:
	ret

popSiExit:
	pop	si
	ret

SetToolboxBasedOnParent	endp

Build	ends
GadgetBuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonVisUnbuildBranch

DESCRIPTION:	We intercept this to release some exclusives we might have.
		Removes this object from navigation mechanism, then calls
		default handler.  Note that we intercept the BRANCH
		message & not the node message.   This is because OLButton
		is often only a visible object, which are destroyed by
		the default VisClass handler for MSG_SPEC_UNBUILD_BRANCH --
		we'd never see the low level message.


PASS:		*ds:si - instance data
		es - segment of OLButtonClass

		ax - MSG_SPEC_UNBUILD_BRANCH
		bp	- SpecBuildFlags

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
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


OLButtonVisUnbuildBranch	method	OLButtonClass, MSG_SPEC_UNBUILD_BRANCH

	push	ax, cx, dx, bp

if 0
	;
	; if we are unbuilding a title bar button, notify the
	; window
	;
	mov	ax, HINT_SEEK_TITLE_BAR_LEFT
	call	ObjVarFindData
	jnc	noTitleBarLeft
	mov	ax, MSG_OL_WIN_NOTIFY_OF_TITLE_BAR_LEFT_GROUP
	jmp	short notifyParent
noTitleBarLeft:
	mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
	call	ObjVarFindData
	jnc	noTitleBarCleanup
	mov	ax, MSG_OL_WIN_NOTIFY_OF_TITLE_BAR_RIGHT_GROUP
notifyParent:
	clr	cx			; no more title bar group
	mov	dx, cx
EC <	call	OpenEnsureGenParentIsOLWin				>
	call	GenCallParent
noTitleBarCleanup:
endif
	;
	; If this GenTrigger is marked with
	; ATTR_GEN_TRIGGER_INTERACTION_COMMAND, notify
	; the GenInteraction above us of this trigger's demise
	;	*ds:si = OLButton
	;
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	call	ObjVarFindData		; any interaction command?
	jnc	noInteractionCommand	; nope
EC <	VarDataFlagsPtr	ds, bx, ax					>
EC <	test	ax, mask VDF_EXTRA_DATA					>
EC <	ERROR_Z	OL_ERROR_ATTR_GEN_TRIGGER_INTERACTION_COMMAND_WITHOUT_DATA >
	;
	; notify GenInteraction with MSG_VIS_VUP_QUERY
	;
	sub	sp, size NotifyOfInteractionCommandStruct
	mov	bp, sp			; dx:bp=NotifyOfInteractionCommandStruct
	mov	dx, ss
	mov	ax, ds:[LMBH_handle]	; pass GenTrigger optr
	mov	ss:[bp].NOICS_optr.handle, ax
	mov	ss:[bp].NOICS_optr.chunk, si
	mov	ax, ds:[bx]		; pass ATTR_GEN_TRIGGER_I_C data
	mov	ss:[bp].NOICS_ic, ax
	mov	ss:[bp].NOICS_flags, mask NOICF_TRIGGER_DEMISE
	mov	ax, MSG_OL_WIN_NOTIFY_OF_INTERACTION_COMMAND
	call	CallOLWin		; only go up to first OLWin
	add	sp, size NotifyOfInteractionCommandStruct
noInteractionCommand:

	; This stuff moved here from OLMenuButton class 4/16/91 cbh
	;
	; Handle case of notification that the visible
	; parent of this object is being visibly unbuilt.
	; This object obviously must belong to a menu that's not
	; generically under this object's vis parent, so we have
	; to take it upon ourselves to get off of the visible
	; parent before it goes away.  The default handler actually
	; does that for us, but we want to additionally make sure that
	; our associated popup menu knows that we're gone, so that it
	; doesn't try to reference us later.
	;
	test	bp, mask SBF_VIS_PARENT_UNBUILDING
	jz	doNormalButtonStuff

					; Go into the popup window, & clear
					; out reference to the button
	mov	di, ds:[di].OLBI_genChunk
	tst	di
	jz	doNormalButtonStuff
	cmp	si, di			; gen part not different, branch
	je	doNormalButtonStuff

	push	si
	mov	si, di			; else delve into gen part

if	ERROR_CHECK
	push	es
					; Make DAMN SURE that what we're
					; messing with here is a popup window...
	mov	di, segment OLPopupWinClass
	mov	es, di
	mov	di, offset OLPopupWinClass
	call	ObjIsObjectInClass
	ERROR_NC	OL_ERROR	; If not, hooey bricks :)
	pop	es
endif
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLPWI_button, 0	; NULL out reference to button -
					; will no longer exist.
	pop	si

doNormalButtonStuff:

	;in case the user is (or was) interacting with this menu button,
	;release the GADGET exclusive now. This will force us to release
	;the mouse, focus, and target exclusives if necessary.

; Performed in VisRemove later
;	mov	cx, ds:[LMBH_handle]
;	mov	dx, si
;	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
;	call	VisCallParent

	;in case this button has HINT_DEFAULT_DEFAULT_ACTION, release the master default
	;exclusive for this window. (If this button is not the master default,
	;this does nothing)

	call	OLButtonResetMasterDefault

	;
	; release default exclusive, as well, if we've got it
	;
	call	OLButtonReleaseDefaultExclusive

; Performed in VisRemove later
;	call	MetaReleaseFocusExclLow	; Release focus excl if we have it

	pop	ax, cx, dx, bp

	; Call superclass
	;
	mov	di, offset OLButtonClass
	CallSuper	MSG_SPEC_UNBUILD_BRANCH
	ret

OLButtonVisUnbuildBranch	endm

GadgetBuild	ends
Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonSetup -- MSG_OL_BUTTON_SETUP for OLButtonClass

DESCRIPTION:	Set some vars in an OLButton object -- one which we are
		stuffing into a menu.

		This method is also used for initializing menu buttons for
		menus - see OLMenuButtonSetup handler.

		NOTE that this method may NOT be used to set up generic objects,
		as the specific instance data will dissappear when the
		object is set USABLE.

PASS:		*ds:si - instance data
		es - segment of OLButtonClass
		ax - MSG_OL_BUTTON_SETUP
		cx - generic object in same block which this button is
			associated with.
		dl - window type (not used here)
		dh - OLWinFixedAttr from window
		bp - OLBuildFlags which BUILD_INFO query determined for the
			popup window this button opens

RETURN:		ds, si, ax, cx, dx, bp = same

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		Full rewrite

------------------------------------------------------------------------------@

OLButtonSetup	method	OLButtonClass, MSG_OL_BUTTON_SETUP

	;now to override default instance values set in OLButtonInitialize

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = specificInstance
	mov	ds:[di].OLBI_genChunk, cx	;save handle of gen parent

	;make sure we are not creating a button for a menu
	;(OLMenuButtonSetup handles this case)

EC <	; This method may no longer be called to set up genItems	>
EC <	; (This used to be called w/dh = TRUE to do this).  Now, the	>
EC <	; HINT_MDI_LIST_ENTRY must be used instead			>
EC <	cmp	dh, TRUE						>
EC <	ERROR_E	OL_ERROR						>

EC <	test	dh, mask OWFA_IS_MENU					>
EC <	ERROR_NZ OL_ERROR						>

	;this button will open a popup window, such as a command window
	;or summons box. set OLBSS_WINDOW_MARK unless the moniker for the
	;thing is a gstring, on which the window mark would look rather
	;silly.

	mov	bx, cx
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Gen_offset
	mov	bx, ds:[bx].GI_visMoniker

	tst	bx			;Oops, need this.  12/ 1/94 cbh
	jz	queryMenuBar

	mov	bx, ds:[bx]
	test	ds:[bx].VM_type, mask VMT_GSTRING
	jnz	queryMenuBar
	ORNF	ds:[di].OLBI_specState, mask OLBSS_WINDOW_MARK

queryMenuBar:
	call	UseQueryResultsToSetButtonAttributes
					;update IN_MENU / IN_MENU_BAR status,
					;and bordered status
					;returns ds:di = VisSpec instance data

	;initialize a few FixedAttr flags: see if this button is inside
	;a reply bar, and set the default value for the TEMP_DEFAULT flag.
	;trick: since we know this button opens a window, see which visparent
	;the window found from its BUILD_INFO query

	push	si
	mov	di, ds:[di].OLBI_genChunk ;set *ds:di = generic window object

	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLCI_visParent.handle
	mov	si, ds:[di].OLCI_visParent.chunk

	call	OpenCheckDefaultRings
	jnc	20$
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_QUERY_FOR_REPLY_BAR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;send to future visible parent
	jnc	20$			;skip if not in reply bar...

	pop	si
	push	si

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR

20$:	;call routine to handle the rest...
	pop	si
	call	OLButtonInitFixedAttrs
	call	UpdateButtonState


	;handle generic hints
	call	HandleGenericButtonHints
	ret
OLButtonSetup	endp

Build	ends
