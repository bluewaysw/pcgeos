COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (gadgets code common to all specific UIs)
FILE:		copenButtonClass.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_SPEC_UPDATE_VIS_MONIKER 
				Handles updating of a vis moniker.

    MTD MSG_SPEC_VIS_OPEN_NOTIFY 
				Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    MTD MSG_SPEC_VIS_CLOSE_NOTIFY 
				Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    INT VisOpenNotifyCommon     Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    INT VisCloseNotifyCommon    Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    INT VisOpenCloseNotifyCommon 
				Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    INT MaybeInvalidateReplyMonikerSize 
				Forces a moniker's cached size to
				disappear, if there is some reason to
				believe it is not correct.

    INT OLButtonApplySizeHints  Returns the size of the button.

    INT RudyConvertHintSlot     Converts a HINT_SEEK_SLOT to the appropiate
				ATTR_GEN_POSITION_Y position.

    INT SetInReplyBarFlagBasedOnParent 
				Sets the reply bar flag if parent has any
				oversized children. Doesn't affect whether
				the button actually can receive the default
				or not.

    INT SetupMonikerArgs        Sets up arguments to pass to moniker
				routines.

    MTD MSG_META_KBD_CHAR       This method is sent either: 1) directly
				from the Flow object, because this button
				has the keyboard grab (was cursored
				earlier) 2) from this button's ancestors up
				the "focus" tree. This is only true if the
				key could be a system-level shortcut.

    INT OLButtonMovePenCalcSize Move the graphics pen and calculate the
				size of this button.

    INT OLButtonChooseBWRegionSet 
				This procedure determines which region
				definitions should be used to calculate
				geometry and draw a B&W button.

    INT OLButtonChooseBWRegionSet 
				This procedure determines which region
				definitions should be used to calculate
				geometry and draw a B&W button.

    INT CheckForOtherButtonLooks 
				Check this button's hints for the other
				buttons hints and set bp to the appropriate
				region if one is set.

    INT OLButtonSetMonoBitmapColor 
				set the area color to use in case the
				moniker for this object is a monochrome
				bitmap

    INT OLButtonGetGenAndSpecState 
				This is a utility routine used by the draw
				routines.

    INT OLButtonSetupMonikerAttrs 
				This procedure is used to setup some
				argument flags before calling
				OpenDrawMoniker.

    INT OLButtonSetupMonikerAttrsBX 
				This procedure is used to setup some
				argument flags before calling
				OpenDrawMoniker.

    INT OLButtonTestForCursored This procedure is used to setup some
				argument flags before calling
				OpenDrawMoniker.

    MTD MSG_GEN_FIND_KBD_ACCELERATOR 
				Find keyboard accelerator (and beep is
				necessary)

    INT OpenButtonCheckIfFullyEnabled 
				Checks to see if fully enabled.

    INT OpenButtonCheckIfAlwaysEnabled 
				Checks to see if this button opens a menu.

    GLB CheckIfPushpin          Checks if the passed object is a pushpin
				trigger or not

    INT OLButtonCallGenPart     This routine will forward a method call
				onto the object which is designated as the
				"generic object" for this OLButtonClass
				object. In some cases, this is the same
				object.

    MTD MSG_META_GAINED_FOCUS_EXCL 
				Handle gaining the focus for a visual
				button

    INT InsetBoundsIfReplyPopup Do horrible things to the button's bounds
				if we're a popup list in a reply bar, so
				that everything draws right from here on
				out.  Since this only affects menu buttons,
				we'll be undoing the damage in its
				MSG_VIS_DRAW handler.

    INT AdjustCurPosIfReplyPopup 
				Hacks in space around reply popups so
				they'll line up with other reply buttons.

    MTD MSG_VIS_NOTIFY_GEOMETRY_VALID 
				Notification of complete geometry.

    MTD MSG_META_GET_ACTIVATOR_BOUNDS 
				Gets bounds of activator.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenButton.asm

DESCRIPTION:

	$Id: copenButtonClass.asm,v 1.47 97/01/06 16:59:37 brianc Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLButtonClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
				
	method	VupCreateGState, OLButtonClass, MSG_VIS_VUP_CREATE_GSTATE

;	method VisCallParent, OLButtonClass, MSG_VIS_VUP_RELEASE_ALL_MENUS

CommonUIClassStructures ends


;---------------------------------------------------


MenuSepQuery	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSpecChangeUsable -- MSG_SPEC_SET_USABLE,
			MSG_SPEC_SET_NOT_USABLE handler.

DESCRIPTION:	We intercept this method here, for the case where this button
		is inside a menu. We want to update the separators which are
		drawn within the menu.

PASS:		*ds:si	= instance data for object
		dl = VisUpdateMode

RETURN:		nothing

DESTROYED:	anything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLButtonSpecChangeUsable method	private static OLButtonClass, \
						MSG_SPEC_SET_USABLE,
						MSG_SPEC_SET_NOT_USABLE
	
	;
	; If setting not usable, we'll look up the guy's parent now so
	; we'll have it after the thing has been disconnected. -cbh 3/ 9/93
	;
	cmp	ax, MSG_SPEC_SET_NOT_USABLE
	jne	10$
	push	si
	call	VisFindParent
	mov	cx, si			;parent in ^lbx:cx
	pop	si
10$:
	
	;cannot use CallSuper macro, because we do not know the method #
	;at assembly time.

	push	ax, cx
	mov	di, offset OLButtonClass
	call	ObjCallSuperNoLock
	pop	ax, cx

	;If this OLButtonClass object is in a menu, update the separators
	;in the menu, since they might be immediately above or below this
	;button.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	done

	;
	; Setting not usable, use the parent passed in ^lbx:dx.
	;
	cmp	ax, MSG_SPEC_SET_NOT_USABLE
	jne	20$
	mov	si, cx				;old VisParent in ^lbx:si
	mov	ax, MSG_SPEC_UPDATE_MENU_SEPARATORS
	mov	di, mask MF_CALL
	GOTO	ObjMessage
20$:
	mov	ax, MSG_SPEC_UPDATE_MENU_SEPARATORS
	call	VisCallParent			;was CallOLWin from 1-93 to 3-93
done:
	ret
OLButtonSpecChangeUsable	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSpecMenuSepQuery -- MSG_SPEC_MENU_SEP_QUERY handler

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

OLButtonSpecMenuSepQuery method	OLButtonClass, MSG_SPEC_MENU_SEP_QUERY
	;find generic info for this OLButtonClass object (may be submenu
	;or window) and see if is USABLE

	call	OLButtonGetGenAndSpecState
	test	bx, mask OLBSS_SYS_ICON	;skip if icon in header area...
	jnz	notUsable

	test	dl, mask GS_USABLE
	jz	notUsable		;skip if not...

	;let's make sure is really usable: some buttons (CUA Pins) are USABLE
	;and ENABLED, but not DRAWABLE.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	notUsable

isUsable: ;indicate that a separator should be drawn next, and that there
	  ;is at least one usable object within this composite level.

	ORNF	ch, mask MSF_SEP or mask MSF_USABLE
	call	ForwardMenuSepQueryToNextSiblingOrParent

	;now we are travelling back up the menu: indicate that a separator
	;should be drawn above this object.

	ORNF	ch, mask MSF_SEP
	stc
	ret

notUsable:
	;this object is not usable: pass the SEP and USABLE flags as is,
	;and return them as is.

	call	ForwardMenuSepQueryToNextSiblingOrParent
	ret
OLButtonSpecMenuSepQuery endm




MenuSepQuery ends

;-----------------------------------------

Geometry segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonUpdateVisMoniker -- 
		MSG_SPEC_UPDATE_VIS_MONIKER for OLButtonClass

DESCRIPTION:	Handles updating of a vis moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UPDATE_VIS_MONIKER
		dl	- update mode

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
	brianc	12/22/94	Add title bar group update

------------------------------------------------------------------------------@

OLButtonUpdateVisMoniker	method dynamic	OLButtonClass, \
				MSG_SPEC_UPDATE_VIS_MONIKER, 
				MSG_SPEC_UPDATE_KBD_ACCELERATOR
	;
	; Make sure everything in the menu gets their geometry redone.
	;
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jnz	inMenu
	;
	; check if in title bar group (can't both be in menu and title bar)
	;
	push	ax
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR
	call	ObjVarFindData			; carry set if found
	pop	ax
	jnc	callSuper			; nope
	push	ax, dx
	mov	ax, MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
	call	CallOLWin
	pop	ax, dx
	jmp	callSuper

inMenu:
	push	dx, ax, es
	mov	dl, VUM_MANUAL
	mov	cl, mask VOF_GEOMETRY_INVALID 
	mov	ax, MSG_VIS_MARK_INVALID
	call	CallOLWin
	pop	dx, ax, es

callSuper:
	mov	di, offset OLButtonClass
	call	ObjCallSuperNoLock
	ret
OLButtonUpdateVisMoniker	endm



COMMENT @----------------------------------------------------------------------

MESSAGE:	OLButtonSpecVisOpenNotify -- MSG_SPEC_VIS_OPEN_NOTIFY
							for OLButtonClass

DESCRIPTION:	Handle notification that an object with GA_NOTIFY_VISIBILITY
		has been opened

PASS:
	*ds:si - instance data
	es - segment of OLButtonClass

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
OLButtonSpecVisOpenNotify	method dynamic	OLButtonClass,
						MSG_SPEC_VIS_OPEN_NOTIFY
	call	VisOpenNotifyCommon
	ret

OLButtonSpecVisOpenNotify	endm

;---

OLButtonSpecVisCloseNotify	method dynamic	OLButtonClass,
						MSG_SPEC_VIS_CLOSE_NOTIFY
	call	VisCloseNotifyCommon
	ret

OLButtonSpecVisCloseNotify	endm

;---

VisOpenNotifyCommon	proc	near
	mov	bp, 1			;non-zero for open
	GOTO	VisOpenCloseNotifyCommon
VisOpenNotifyCommon	endp

;---

VisCloseNotifyCommon	proc	near
	clr	bp			;non-zero for open
	FALL_THRU	VisOpenCloseNotifyCommon
VisCloseNotifyCommon	endp

;---

VisOpenCloseNotifyCommon	proc	near
	class	OLButtonClass

	; get data

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;default data is our OD
	mov	ax, ATTR_GEN_VISIBILITY_DATA
	call	ObjVarFindData
	jnc	gotData
	movdw	cxdx, ds:[bx]
gotData:

	; get message

	mov	di, MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION
	mov	ax, ATTR_GEN_VISIBILITY_MESSAGE
	call	ObjVarFindData
	jnc	gotMessage
	mov	di, ds:[bx]
gotMessage:

	; get destination

	mov	ax, ATTR_GEN_VISIBILITY_DESTINATION
	call	ObjVarFindData
	jnc	useGenApp
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	jmp	gotDest
useGenApp:
	clr	bx
	call	GeodeGetAppObject
gotDest:

	mov_tr	ax, di
	clr	di
	call	ObjMessage
	ret

VisOpenCloseNotifyCommon	endp

if _RUDY ; --------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaybeInvalidateReplyMonikerSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forces a moniker's cached size to disappear, if there
		is some reason to believe it is not correct.

CALLED BY:	OLButtonRerecalcSize
PASS:		*ds:si	- OLButton Instance
		*es:bx	- Gen instance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MaybeInvalidateReplyMonikerSize	proc	near
	uses	di
	.enter

	mov	di, ds:[bx]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GI_visMoniker
	tst	di
	jz	noInvalidate
	mov	di, ds:[di]			; ds:di = moniker
	;
	; A textual moniker in a reply bar may have been placed there
	; by the EnsureStandardTriggers code, which uses the wrong
	; font settings to calculate size.  We'll need to force
	; the size to be recalc'ed here
	;

	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	noInvalidate

	;
	; Set width to 0, forcing a recalculation.
	;
	clr	ds:[di].VM_width

noInvalidate:
	.leave
	ret
MaybeInvalidateReplyMonikerSize		endp


endif ; _RUDY --------------------------------------------------

COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonRerecalcSize -- MSG_VIS_RECALC_SIZE for OLButtonClass

DESCRIPTION:	Returns the size of the button.

PASS:
	*ds:si - instance data
	es - segment of OLButtonClass
	di - MSG_VIS_GET_SIZE
	cx - RerecalcSizeArgs: width info for choosing size
	dx - RerecalcSizeArgs: height info

RETURN:
	cx - width to use
	dx - height to use

DESTROYED:
	si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@

OLButtonRerecalcSize	method private static	OLButtonClass, \
							MSG_VIS_RECALC_SIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	call	SetInReplyBarFlagBasedOnParent

	call	OLButtonApplySizeHints	;account for initial hint here

	sub	sp, size OpenMonikerArgs ;make room for args
	mov	bp, sp			;pass pointer in bp

	push	cx, dx			;save width and height requested
   	call	SetupMonikerArgs	;pass things to moniker routine

if _RUDY
	;
	; In Rudy deal with 20 point fonts in certain buttons.
	;
	clr	di
	call	GrCreateState		;make a gstate
	mov	ss:[bp].OMA_gState, di
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR
	jnz	inABar
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
inABar:
	pop	di
	jz	dontSetBold

	call	MaybeInvalidateReplyMonikerSize

	push	ax, cx, dx
	mov	dx, FOAM_LARGE_FONT_SIZE
	clr	ax
	clr	cx
	call	GrSetFont
	mov	ax, mask TS_BOLD		;for all reply bar buttons...
	call	GrSetTextStyle
	pop	ax, cx, dx
dontSetBold:
endif

CUAS <	push	ax			;save returned min height  >
MAC <	push	ax			;save returned min height  >
	call	OpenGetMonikerSize	;get size of moniker (cx, dx)
if _PCV
	; all this code just tweaks the width for various looks so
	; the size matches the size on liberty exactly - jimmy
	pushf
	push	ax, di
	call	CheckForCompressedMoniker
	jc	afterAdjust

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLBI_legosLook, 1	; COMMAND
	je	doLower
	cmp	ds:[di].OLBI_legosLook, 3	; TOOL_LOOK
	je	doTool
	cmp	ds:[di].OLBI_legosLook, 6	; UPPER RIGHT
	je	doUpper
	cmp	ds:[di].OLBI_legosLook, 5	; LOWER RIGHT
	je	doLower
normalAdjust::
	dec	cx
doLower:
	dec	cx
	jmp	afterAdjust
doTool:
	inc	dx
	add	cx, 2
doUpper:
	inc	cx
afterAdjust:
	pop	ax, di
	popf
endif
haveMonikerSize::

if _RUDY
	mov	di, ss:[bp].OMA_gState
	;
	; buttons that open popups often have no monikers, only to
	; have them replaced later.  So that initial size is calc'ed
	; correctly, assume that this will happen, and give it
	; some size.
	;
	push	si
	tst	dx				; assume 0 size = no moniker
	jnz	haveMoniker
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	cmp	si, ds:[bx].OLBI_genChunk
	jne	reasonableMinimum
	;
	; if this is a settings trigger, pretend we have a moniker.
	; If we were to let the size be 0,0 then scroll-to-focus
	; might not scroll far enough.
	;
	mov	ax, ATTR_OL_BUTTON_SETTINGS_TRIGGER
	call	ObjVarFindData
;	jnc	haveMoniker
;even if there isn't this hint, if the parent interaction has
;OLCRF_DRAW_RIGHT_ARROW, we'll do this -- brianc 2/2/96
	jc	reasonableMinimum		; have SETTINGS hint
	push	si
	call	VisSwapLockParent		; *ds:si = parent, bx = han
	jnc	popHaveResult			; no parent, not settings
	push	es, di
	mov	di, segment OLCtrlClass
	mov	es, di
	mov	di, offset OLCtrlClass
	call	ObjIsObjectInClass
	jnc	unlockPopHaveResult		; parent not ctrl, not settings
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_rudyFlags, mask OLCRF_DRAW_RIGHT_ARROW
	jz	unlockPopHaveResult		; not settings, carry clear
	stc					; indicate is settings trigger
unlockPopHaveResult:
	pop	es, di
	call	ObjSwapUnlock			; (preserves flags)
popHaveResult:
	pop	si
	jnc	haveMoniker			; carry clear if not settings
reasonableMinimum:
	mov	bx, dx				; bx <- initial min height
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			; dx <- height (ax garbage)
	mov	ax, cx				; ax <- initial min width
	cmp	bx, dx
	jge	haveMinimum			; if initial is larger,use it.

haveMoniker:
endif ; _RUDY

	mov	ax, cx			;use as minimum width
	mov	bx, dx			;use as minimum height

if _RUDY
haveMinimum:
	pop	si
	call	GrDestroyState
endif ; _RUDY

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

if CURSOR_OUTSIDE_BOUNDS
	;
	; outside focus indicator requires extra space
	;
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	noFocus
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
			mask OLBSS_IN_MENU_BAR or mask OLBSS_SYS_ICON
	jnz	noFocus
	add	ax, OUTSIDE_CURSOR_MARGIN*2
	add	bx, OUTSIDE_CURSOR_MARGIN*2
noFocus:
endif

if _MOTIF and not _RUDY ;----------------------------------------------------

	; (It's not clear this code does the right thing.   It tacks on
	;  extra reply button insets, but these are equated to the regular
	;  button inset, which is kind of strange.   -cbh 11/ 8/95 )

	;if this button can get the temporary default emphasis, make it
	;larger. The button draw code will chose the correct region to use.

	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	5$			;skip if not...

if DRAW_STYLES
	add	ax, DRAW_STYLE_DEFAULT_WIDTH*2
	add	bx, DRAW_STYLE_DEFAULT_WIDTH*2
else
	add	ax, MO_REPLY_BUTTON_INSET_X * 2
	add	bx, MO_REPLY_BUTTON_INSET_Y * 2

	call	OpenCheckIfCGA
	jnc	5$
						; If so, compensate vertically
	sub	bx, 2 * (MO_REPLY_BUTTON_INSET_Y - MO_CGA_REPLY_BUTTON_INSET_Y)
endif ; DRAW_STYLES
5$:
endif		;--------------------------------------------------------------

if _PM		;--------------------------------------------------------------
	;if this button can get the temporary default emphasis, make it
	;larger. The button draw code will chose the correct region to use.

	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	5$			;skip if not...

	add	ax, MO_REPLY_BUTTON_INSET_X * 2
	add	bx, MO_REPLY_BUTTON_INSET_Y * 2

	call	OpenCheckIfCGA		;running CGA?
	jnc	8$			;skip if not
					;if so, compensate vertically
	sub	bx, 2 * (MO_REPLY_BUTTON_INSET_Y - MO_CGA_REPLY_BUTTON_INSET_Y)
	jmp	8$

	;
	;Now take care of toolbox buttons
5$:	;
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	8$			;skip is not a toolbox button

	call	OpenCheckIfCGA		;running CGA?
	jc	8$			;skip if so

	;allow for thicker borders around toolbox buttons
	inc	ax
	inc	ax
	inc	bx
	inc	bx
8$:
endif		;--------------------------------------------------------------

CUAS <	pop	bp			;restore returned min height  >
MAC <	pop	bp			;restore returned min height  >
	pop	cx, dx			;get passed width and height
CUAS <	push	bp			;save returned min height  >
MAC <	push	bp			;save returned min height  >

	xchgdw	cxdx, axbx		;cx, dx <- moniker imposed size
					;ax, bx <- passed size
	;
	; New code to pass whether we're a system icon or not.  7/20/94 cbh
	;
	push	cx
	clr	cx
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON
	jz	9$
	dec	ch					;ch non-zero
9$:
	mov	cl, ds:[di].OLBI_moreAttrs		;pass flags in cl
	mov	bp, cx					;now in bp
	pop	cx
	call	OpenChooseNewGadgetSize			;choose a size

	call	OLButtonApplySizeHints	;account for initial hint here

if _ODIE
	;
	; ensure ODIE IC_OK buttons are eye-pleasingly wide
	;
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	call	ObjVarFindData
	jnc	notOK
	cmp	{InteractionCommand}ds:[bx], IC_OK
	jne	notOK
	cmp	cx, IC_OK_BUTTON_MIN_WIDTH
	jae	notOK
	mov	cx, IC_OK_BUTTON_MIN_WIDTH
notOK:
endif

	;Make sure button is big enough to keep drawn regions working.

CUAS  <	pop	ax			;restore returned min height	>
MAC   <	pop	ax			;restore returned min height	>

OLS   <	cmp	cx, BUTTON_MIN_WIDTH	;compare against smallest legal button>
NOT_MO<	cmp	cx, CUA_BUTTON_MIN_WIDTH				>
;MAC  <	cmp	cx, CUA_BUTTON_MIN_WIDTH				>
MO    <	cmp	cx, MO_BUTTON_MIN_WIDTH					>
PMAN  <	cmp	cx, MO_BUTTON_MIN_WIDTH					>
	jae	10$			;skip if is large enough...

OLS <	mov	cx, BUTTON_MIN_WIDTH	;too small: use minimum width	>
NOT_MO<	mov	cx, CUA_BUTTON_MIN_WIDTH				>
;MAC <	mov	cx, CUA_BUTTON_MIN_WIDTH				>
MO <	mov	cx, MO_BUTTON_MIN_WIDTH					>
PMAN <	mov	cx, MO_BUTTON_MIN_WIDTH					>

10$:
OLS <	cmp	dx, BUTTON_MIN_HEIGHT	;compare against shortest button >
CUAS <	cmp	dx, ax			;compare against shortest button >
;MAC <	cmp	dx, ax			;compare against shortest button >

	jae	20$			;skip if is tall enough...

OLS <	mov	dx, BUTTON_MIN_HEIGHT	;use minimum height		>
CUAS <	mov	dx, ax			;use minimum height		>
;MAC <	mov	dx, ax			;use minimum height		>

20$:
	add	sp, size OpenMonikerArgs	;dump args

	;
	; not a hack!  Return title bar height if this button is in title bar
	;
	mov	ax, ATTR_OL_BUTTON_IN_TITLE_BAR
	call	ObjVarFindData
	jnc	notInTitleBar
if _JEDIMOTIF
	;
	; title bar buttons are 16 pixels high in JEDI
	;
	mov	dx, 16
else
	push	cx			; save width
	mov	ax, MSG_OL_WIN_GET_TITLE_BAR_HEIGHT
	call	CallOLWin		; dx = height
	pop	cx			; restore width
endif
notInTitleBar:

if _RUDY
	;
	; Rudy, fix the height of menu bars.   At least for now, later we'll
	; shrink them when there are more than four buttons.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	jnz	forceHeight
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR
	jz	exit
forceHeight:
	mov	dx, RUDY_RIGHT_BUTTON_HEIGHT
	tst	ds:[di].OLBI_genChunk
	jz	exit
	push	si
	mov	si, ds:[di].OLBI_genChunk	; ds:si = gen part
	mov	ax, HINT_SEEK_SLOT
	call	ObjVarFindData
	pop	si
	jnc	exit
	mov	ax, ds:[bx]
	call	RudyConvertHintSlot	; dx <- button height
exit:
endif

if _JEDIMOTIF
	;
	;  Jedi -> fixed-width and fixed-height menu-bar buttons.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU_BAR
	jz	exitJedi

	mov	cx, JEDI_APP_MENU_WIDTH
	mov	dx, JEDI_MENU_BAR_BUTTON_HEIGHT
	mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
	call	ObjVarFindData
	jc	exitJedi

	mov	cx, JEDI_MENU_BAR_BUTTON_WIDTH
exitJedi:
endif

ifdef POPUP_DYNAMIC_SCROLLING_LISTS_EARLY_BUILD_OUT
	;
	; If this opens a popup list, build the list out now.
	; 
	mov	ax, ATTR_OL_BUTTON_OPENS_POPUP_LIST
	call	ObjVarFindData
	jnc	afterUpdatePopup

	push	si, cx, dx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLBI_genChunk	;get popup window
	call	UpdatePopupAndGetSize	
	pop	si, cx, dx

afterUpdatePopup:
endif
	.leave
	ret
OLButtonRerecalcSize	endp

OLButtonApplySizeHints	proc	near
	push	si
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLBI_genChunk
	CallMod	VisApplySizeHints	;account for initial hint here
	pop	si
	ret
OLButtonApplySizeHints endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RudyConvertHintSlot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a HINT_SEEK_SLOT to the appropiate
		ATTR_GEN_POSITION_Y position.

CALLED BY:	OLButtonRerecalcSize
PASS:		ax 	= slot position (0-3)
		dx	= height of button 
RETURN:		dx unchanged
DESTROYED:	ax, bx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	reza	12/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _RUDY
RudyConvertHintSlot		proc 	near
	class	OLButtonClass
	position	local	sword
	uses	cx
	.enter

	push	ax			; save slot position
	mov	ax, ATTR_SPEC_POSITION_Y
	call	ObjVarFindData
	pop	ax			; restore slot position
	jc	exit			; branch if ATTR... exists previously

	push	dx			; save height
	mul	dx			; ax = new Y position of object
	add	ax, RUDY_SLOT_TOP_MARGIN
	;
	; If in a bubble dialog, use less top margin
	;
	push	si
	call	SwapLockOLWin		; *ds:si = parent win, bx = child han
	jnc	noBubble
	mov	di, segment OLDialogWinClass
	mov	es, di
	mov	di, offset OLDialogWinClass
	call	ObjIsObjectInClass
	jnc	noBubbleUnlock
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPWI_flags, mask OLPWF_IS_POPUP
	jz	noBubbleUnlock
.assert (RUDY_SLOT_TOP_MARGIN gt RUDY_SLOT_BUBBLE_TOP_MARGIN)
	sub	ax, RUDY_SLOT_TOP_MARGIN-RUDY_SLOT_BUBBLE_TOP_MARGIN
noBubbleUnlock:
	call	ObjSwapUnlock
noBubble:
	pop	si

	mov	position, ax

	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	di, sp

	mov	ss:[di].AVDP_data.segment, ss
	lea	dx, position
	mov	ss:[di].AVDP_data.offset, dx

	mov	ss:[di].AVDP_dataSize, size sword
	mov	ss:[di].AVDP_dataType, ATTR_SPEC_POSITION_Y
	xchg	bp, di
	mov	ax, MSG_META_ADD_VAR_DATA
	call	ObjCallInstanceNoLock
	add	sp, size AddVarDataParams
	mov	bp, di
	pop	dx
exit:
	.leave
	ret
RudyConvertHintSlot		endp
endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetInReplyBarFlagBasedOnParent

SYNOPSIS:	Sets the reply bar flag if parent has any oversized children.
		Doesn't affect whether the button actually can receive the
		default or not.

CALLED BY:	OLButtonRerecalcSize

PASS:		*ds:si -- button

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 8/92       	Initial version

------------------------------------------------------------------------------@

SetInReplyBarFlagBasedOnParent	proc	near		uses	cx
	.enter
	call	OpenCheckDefaultRings
	jnc	exit
	call	OpenGetParentMoreFlagsIfCtrl	
	test	cl, mask OLCOF_OVERSIZED_CHILDREN
	jz	exit
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR 
exit:
	.leave
	ret
SetInReplyBarFlagBasedOnParent	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLButtonClass

DESCRIPTION:	Returns non-moniker size of button.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx, dx  - size without moniker

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 7/89	Initial version

------------------------------------------------------------------------------@

OLButtonGetExtraSize	method	OLButtonClass, MSG_SPEC_GET_EXTRA_SIZE
	sub	sp, size OpenMonikerArgs	;make room for args
	mov	bp, sp				;pass pointer in bp
	call	SetupMonikerArgs		;pass our insets, flags
	call	OpenGetMonikerExtraSize		;returns extra size
EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>
	add	sp, size OpenMonikerArgs	;unload args

if _MOTIF or _PM;--------------------------------------------------------------
	;if this button can get the temporary default emphasis, make it
	;larger. The button draw code will chose the correct region to use.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	10$			;skip if not...

	add	cx, MO_REPLY_BUTTON_INSET_X*2
	add	dx, MO_REPLY_BUTTON_INSET_Y*2	

	call	OpenCheckIfCGA
	jnc	10$
	sub	bx, 2 * (MO_REPLY_BUTTON_INSET_Y - MO_CGA_REPLY_BUTTON_INSET_Y)
10$:
endif		;--------------------------------------------------------------
if _JEDIMOTIF
	;
	; if we have HINT_FIXED_SIZE, then return no extra size to allow
	; the hint full control of the size
	;
	mov	ax, HINT_FIXED_SIZE
	call	ObjVarFindData
	jnc	done
	cmp	{SpecWidth}ds:[bx], 0
	je	leaveWidth
	clr	cx
leaveWidth:
	cmp	{SpecHeight}ds:[bx][(size SpecWidth)], 0
	je	leaveHeight
	clr	dx
leaveHeight:
done:
endif
	ret
OLButtonGetExtraSize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonMkrPos - 
		MSG_GET_FIRST_MKR_POS for OLButtonClass

DESCRIPTION:	Returns the position of the button's moniker.

PASS:
	*ds:si - instance data
	es - segment of OLButtonClass
	di - MSG_GET_FIRST_MKR_POS
		
RETURN:
	carry set (method handled) if there is a moniker at all
	ax, cx -- starting position of moniker

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/89	Initial version

------------------------------------------------------------------------------@

OLButtonMkrPos	method	OLButtonClass, MSG_GET_FIRST_MKR_POS
	sub	sp, size OpenMonikerArgs	;make room for args
	mov	bp, sp				;pass pointer in bp
   	call	SetupMonikerArgs		;pass things to moniker routine
	call	OpenGetMonikerPos		;get pos of moniker (ax, bx)

EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>
	mov	cx, bx				;return y pos in cx
	add	sp, size OpenMonikerArgs	;dump args
	tst	ax				;any moniker?
	jz	exit				;no, moniker exit (clc)
	stc					;say handled
exit:
	ret
OLButtonMkrPos	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonGetCenter -- MSG_VIS_GET_CENTER for OLButtonClass

DESCRIPTION:	Returns the center of the button.

PASS:		*ds:si - instance data
		es - segment of OLButtonClass
		di - MSG_VIS_GET_CENTER

RETURN:		cx 	- minimum amount needed left of center
		dx	- minimum amount needed right of center
		ax 	- minimum amount needed above center
		bp      - minimum amount needed below center

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@

OLButtonGetCenter	method	OLButtonClass, MSG_VIS_GET_CENTER
	sub	sp, size OpenMonikerArgs	;make room for args
	mov	bp, sp				;pass pointer in bp
	call	SetupMonikerArgs		;pass things to moniker routine
	call	OpenGetMonikerCenter		;get center of moniker (cx, dx)
	add	sp, size OpenMonikerArgs	;unload args
	ret
OLButtonGetCenter	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonGetMenuCenter -- MSG_SPEC_GET_MENU_CENTER 
		for OLButtonClass

DESCRIPTION:	Returns the center of the button.

PASS:		*ds:si - instance data
		es - segment of OLButtonClass
		di - MSG_SPEC_GET_MENU_CENTER
		cx	- monikers space found, so far
		dx	- accel space found, so far
		bp	- non-zero if any items found so far are marked as 
				having valid geometry

RETURN:		cx, dx, bp - possibly updated

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@

OLButtonGetMenuCenter	method	OLButtonClass, MSG_SPEC_GET_MENU_CENTER
	push	bp
	sub	sp, size OpenMonikerArgs	;make room for args
	mov	bp, sp				;pass pointer in bp
	push	cx, dx
	call	SetupMonikerArgs		;pass things to moniker routine
	pop	cx, dx
	call	OpenGetMonikerMenuCenter	;get center of moniker (cx, dx)
	add	sp, size OpenMonikerArgs	;unload args
	pop	bp

	mov	di, ds:[si]			;geometry already invalid, exit
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jnz	checkWrapping
	or	bp, mask SGMCF_NEED_TO_RESET_GEO ;else need to reset geometry
						 ; (previously a dec bp 1/18/93)

checkWrapping:
	;
	; Now see if whether ourselves or one of our children is allowing 
	; wrapping.  If so, clear the only-recalc-size flag.  -cbh 1/18/93
	;
	test	bp, mask SGMCF_ALLOWING_WRAPPING
	jz	exit
	and	ds:[di].VI_geoAttrs, not mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
	or	ds:[di].OLBI_moreAttrs, mask OLBMA_EXPAND_WIDTH_TO_FIT_PARENT
exit: 
	ret
OLButtonGetMenuCenter	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupMonikerArgs

SYNOPSIS:	Sets up arguments to pass to moniker routines.

CALLED BY:	OLButtonRerecalcSize, OLButtonGetCenter

PASS:		*ds:si -- handle of button
		ss:bp -- space allocated for OpenMonikerArgs

RETURN:	
	*es:bx - gen object to use

    I AM NOT SURE IF CL NEED BE RETURNED.
	cl - how to draw moniker: OpenMonikerFlags

	ss:bp  - OpenMonikerArgs:  
	    ss:[bp].OMA_drawMonikerFlags	word	;justification & clipping flags
	    ss:[bp].OMA_monikerAttrs	word	;OLMonikerAttrs: cursored etc.
	    ss:[bp].OMA_drawMonikerFlags	word	;low byte = DrawMonikerFlags <>
	    ss:[bp].OMA_bottomInset	 	word	;bottom inset
	    ss:[bp].OMA_rightInset	 	word	;right inset
	    ss:[bp].OMA_topInset	 	word	;top inset
	    ss:[bp].OMA_leftInset		word	;left inset 
	    openMkrMaxLen		word    ;max len to draw (internal)
	    openMkrState		lptr GState ;handle of graphics state
	ax - MINIMUM HEIGHT
	si - handle of generic data for button (No, SI isn't changed, dickless)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/12/89		Initial version
	Eric	4/90		OpenMonikerArgs expanded.

------------------------------------------------------------------------------@

;NOTE: this routine is using button size info from the B&W tables!
;Should check color and use color tables if necessary?

SetupMonikerArgs	proc	near
	class	OLButtonClass
	
	;get region definition for this button, and grab some positioning
	;info from it (see copenButtonData.asm).

	push	bp, ds
if _PCV
	call	CheckForCompressedMoniker		; carry if compressed
	pushf
endif
	; pass: *ds:si = object pointer
	call	OLButtonChooseBWRegionSet
	; return: ds:bp = Region table 

	mov	dl, ds:[bp].BWBRSS_monikerXInset
if _PCV
	;
	; If they are drawing a bitmap, use different fields
	;
	mov	dh, ds:[bp].BWBRSS_monikerRightInset
	popf					; COMPRESSED_INSETS?
	pushf					; save flags for y inset
	jnc	textMoniker
	mov	dl, ds:[bp].BWBRSS_graphicXInset
	mov	dh, ds:[bp].BWBRSS_graphicRightInset
textMoniker:
else
	clr	dh
endif
if (not _OPEN_LOOK)
	call	OpenCheckIfNarrow		 ;check if narrow
	jnc	8$				 ;it's not, branch
	mov	dl, ds:[bp].BWBRSS_monikerXInsetNarrow
8$:
endif
	mov	bl, ds:[bp].BWBRSS_monikerYInset
if _PCV
	mov	bh, ds:[bp].BWBRSS_monikerBottomInset
	popf					; carry set if using graphic
	jnc	textMonikerAgain
	mov	bl, ds:[bp].BWBRSS_graphicYInset
	mov	bh, ds:[bp].BWBRSS_graphicBottomInset
textMonikerAgain:
else
	clr	bh
endif
	call	OpenCheckIfCGA		 	 ;check if CGA
	jnc	10$				 ;it's not, branch
	mov	bl, ds:[bp].BWBRSS_monikerYInsetCGA
10$:
	mov	al, ds:[bp].BWBRSS_monikerFlags	;get justifications
	clr	ah			;set ax = DrawMonikerFlags (justifi-
					;cation and clipping flags)

CUAS <	mov	cl, ds:[bp].BWBRSS_minHeight				>
CUAS <	clr	ch							>
;MAC <	mov	cl, ds:[bp].BWBRSS_minHeight				>
;MAC <	clr	ch							>
	pop	bp, ds
if _PCV
	; store the right and bottom insets until later
	;
	push	ax				; DrawMonikerFlags
	clr	ax
	mov	al, dh
	;
	; This has the potential to read words past the end of 
	; the structure if it isn't a pcv button region.
	; nothing bad should be happening as we won't be reading
	; past the end of the resource block
	mov	ss:[bp].OMA_rightInset, ax
	mov	al, bh
	mov	ss:[bp].OMA_bottomInset, ax
	clr	bh, dh
	pop	ax				; DrawMonikerFlags
endif	; PCV
	segmov	es, ds

	;now save this info into the passes structure on the stack

EC <	call	ECInitOpenMonikerArgs	;save IDs on stack for testing	>

   	; if running under a toolbox, shrink the button a little, to match
	; list entries.  (Only in color, though. In B/W, we can do part of the
	; shrink but not all, due to the items needing a double border.)

ODIE <	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON		>
ODIE <	jnz	15$				; but not for sys icons	>

	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jz	15$
if DRAW_STYLES
	mov	dx, BUTTON_MONIKER_X_TOOLBOX_MARGIN
	mov	bx, BUTTON_MONIKER_Y_TOOLBOX_MARGIN
else
	mov	dx, BUTTON_TOOLBOX_X_INSET
endif
	mov	bx, dx
		CheckHack <(BUTTON_TOOLBOX_X_INSET eq BUTTON_TOOLBOX_Y_INSET)>

if	(BUTTON_BW_TOOLBOX_X_INSET ne BUTTON_TOOLBOX_X_INSET)
	call	OpenCheckIfBW			;color, done
	jnc	15$				
	add	cx, BUTTON_BW_TOOLBOX_X_INSET - BUTTON_TOOLBOX_X_INSET
	add	dx, BUTTON_BW_TOOLBOX_Y_INSET - BUTTON_TOOLBOX_Y_INSET
endif
15$:

if DRAW_STYLES ;---------------------------------------------------------------
	;
	; flat borderless buttons (normal and toolbox) have no default
	; inset -- brianc 9/16/96
	;
	test	ds:[di].OLBI_specState, mask OLBSS_BORDERED
	jnz	haveBorder
	cmp	ds:[di].OLBI_drawStyle, DS_FLAT
	jne	haveBorder
	clr	bx, dx
haveBorder:
	;
	; add room for frame and insets
	;
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON or \
			mask OLBSS_IN_MENU or mask OLBSS_IN_MENU_BAR
	jnz	doneInsets		; not for sys and menu buttons
	test	ds:[di].OLBI_specState, mask OLBSS_BORDERED
	jz	noFrame
	add	bx, DRAW_STYLE_FRAME_WIDTH
	add	dx, DRAW_STYLE_FRAME_WIDTH
noFrame:
	cmp	ds:[di].OLBI_drawStyle, DS_FLAT
	je	doneInsets
	add	bx, DRAW_STYLE_INSET_WIDTH
	add	dx, DRAW_STYLE_INSET_WIDTH
doneInsets:
endif ;------------------------------------------------------------------------

if _JEDIMOTIF	;-------------------------------------------------------------
	;
	; if we have HINT_FIXED_SIZE, then return no extra size to allow
	; the hint full control of the size
	;
	push	ax
	push	bx			; top inset
	mov	ax, HINT_FIXED_SIZE
	call	ObjVarFindData
	jnc	notFixed
	cmp	{SpecWidth}ds:[bx], 0
	je	leaveWidth
	clr	dx			; clear left inset
leaveWidth:
	cmp	{SpecHeight}ds:[bx][(size SpecWidth)], 0
	je	leaveHeight
	mov	bx, sp			; ss:bx = top inset
	mov	{word}ss:[bx], 0	; clear top inset
leaveHeight:
notFixed:
	pop	bx			; bx = updated top inset
	pop	ax
endif	;---------------------------------------------------------------------
	
CUAS <	push	cx				;save minimum height	>
;MAC <	push	cx				;save minimum height	>
	clr	ss:[bp].OMA_gState			;set have no GState...
	mov	ss:[bp].OMA_leftInset, dx		;pass as left inset
	mov	ss:[bp].OMA_topInset, bx		;pass as top inset

if	(DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY) and (not _RUDY)
	test	ds:[di].OLBI_specState, mask OLBSS_SYS_ICON or \
					mask OLBSS_IN_MENU_BAR
	jnz	17$
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	17$
	call	OpenCheckIfBW
	jnc	17$
if _PCV
	; if we are using graphics, things are ok, if its text we
	; need to move things up a little
	push	ax
	call	CheckForCompressedMoniker
	pop	ax
	jc	afterAdjust
	sub	ss:[bp].OMA_leftInset, 2
	dec	ss:[bp].OMA_topInset
afterAdjust:
	inc	ss:[bp].OMA_rightInset
	inc	ss:[bp].OMA_bottomInset
else
	inc	dx
	inc	bx
endif
17$:
endif
if _PCV
	;
	; if a component, use the region information (which we already stored)
	; othwise, the region info isn't thre
	tst	ds:[di].OLBI_legosLook
	jne	haveInsets
	;
endif
	mov	ss:[bp].OMA_rightInset, dx		;and as right inset
	mov	ss:[bp].OMA_bottomInset, bx		;and as bottom inset
haveInsets::
	mov	ss:[bp].OMA_drawMonikerFlags, ax	;save DrawMonikerFlags (low byt)

	;determine which accessories to draw with the moniker

	clr	al
	call	OLButtonSetupMonikerAttrs	;gets attributes in cx

	mov	ss:[bp].OMA_monikerAttrs, cx	;set have no flags...

	;point to generic instance data and grab vis moniker

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLBI_genChunk	;get chunk holding gen data
	mov	cl, al				;return DrawMonikerFlags
CUAS <	pop	ax				;get min height		>
;MAC <	pop	ax				;get min height		>

if _ODIE
	;
	; use no margins for gstring monikers in menu buttons
	; (plus hack to leave margins for 28x28 icons)
	;
	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU
	jz	noGString
	mov	di, ds:[bx]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GI_visMoniker
	mov	di, ds:[di]			; ds:di = VisMoniker
	test	ds:[di].VM_type, mask VMT_GSTRING
	jz	noGString
	cmp	ds:[di].VM_width, 28
	jne	noMargin
	cmp	({VisMonikerGString}ds:[di].VM_data).VMGS_height, 28
	je	noGString			; 28x28 gstring, leave margin
noMargin:
	clr	ax
	mov	ss:[bp].OMA_rightInset, ax
	mov	ss:[bp].OMA_leftInset, ax
	mov	ss:[bp].OMA_topInset, ax
	mov	ss:[bp].OMA_bottomInset, ax
noGString:
endif

EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>

	ret
SetupMonikerArgs	endp

Geometry ends


;--------------------------


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonGenActivate - MSG_GEN_ACTIVATE

DESCRIPTION:	This procedure is called in the following situations:
			1) the mouse button is released on object
			2) the space bar (SELECT key) is released while this
			   object is cursored.
			3) somebody sends MSG_GEN_ACTIVATE to this object.
			4) the keyboard shortcut for this object is received,
			   and this object sends MSG_GEN_ACTIVATE to itself.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonGenActivate	method	OLButtonClass, MSG_GEN_ACTIVATE
	call	OpenButtonCheckIfFullyEnabled	
	jnc	exit			;not fully enabled, exit

	;if the button is not yet CURSORED or HAS_MOUSE_GRAB-ed, then save
	;the current bordered and depressed state, and set DEPRESSED and/or
	;BORDERED as required by specific UI.

	call	OLButtonSaveStateSetBorderedAndOrDepressed
	call	OLButtonDrawNOWIfNewState ;redraw immediately if necessary

	;trigger the button (via queue or directly)

	clr	cx			  ;act as single press
	call	OLButtonActivate

	; sleep for a bit (possibly), to allow the button's inverted
	; state (or whatever) to be seen by the user
	push	es
	segmov	es, dgroup, ax		;es = dgroup
	mov	ax, es:[olButtonActivateDelay]
	pop	es
	tst	ax
	jz	doneSleep
	call	TimerSleep
doneSleep:

	;now reset the BORDERED and or DEPRESSED status to normal and REDRAW

	call	OLButtonRestoreBorderedAndDepressedStatusAndDrawNOW

exit:
	ret
OLButtonGenActivate	endm

ActionObscure	ends

;----------------

KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonKbdChar -- MSG_META_KBD_CHAR handler

DESCRIPTION:	This method is sent either:
			1) directly from the Flow object, because this button
			   has the keyboard grab (was cursored earlier)
			2) from this button's ancestors up the "focus" tree.
			   This is only true if the key could be a system-level
			   shortcut.

PASS:		*ds:si	= instance data for object
		ax = MSG_META_KBD_CHAR.
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version (from John's VisKbdText)

------------------------------------------------------------------------------@

OLButtonKbdChar	method	dynamic OLButtonClass,
				MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR
if _KBD_NAVIGATION	;------------------------------------------------------
	;we should not get events when the button is disabled...

	call	VisCheckIfFullyEnabled
	jnc	ignoreKey

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT or \
		    mask CF_REPEAT_PRESS or mask CF_RELEASE
	jnz	ignoreKey		;quit if not character.
	
	test	dh, mask SS_LALT or mask SS_RALT or mask SS_LCTRL or \
							mask SS_RCTRL
	jnz	ignoreKey		;one of these pressed, branch

	test	ds:[di].OLBI_specState, mask OLBSS_IN_MENU or \
					mask OLBSS_IN_MENU_BAR
if _RUDY
	jz	ignoreKey		;in RUDY, we want to ignore the
					;space bar as a SELECT key
else
	jz	checkSelect		;skip if not in menu or menu bar...
endif
					;is menu button, Ctrl-M activates
SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_CTRL_M			>
DBCS <	cmp	cx, C_SYS_ENTER						>
if _RUDY
	jne	ignoreKey		;ignore any SELECT key
else
	je	activate

checkSelect:
SBCS <	cmp	cx, (CS_BSW shl 8) or VC_BLANK				>
DBCS <	cmp	cx, C_SPACE						>
					;is SELECT key (space bar) pressed?
	jne	ignoreKey		;skip if not...
endif	; _RUDY

activate: ;SELECT key has been pressed
	call	OpenSaveNavigationChar	;save KBD char in idata so that when
					;a button gets MSG_GEN_ACTIVATE,
					;it knows whether it is a result of
					;KBD navigation or not.
	mov	ax, MSG_OL_BUTTON_KBD_ACTIVATE
	call	ObjCallInstanceNoLock

	clr	cx
	call	OpenSaveNavigationChar	;reset our saved KBD char to "none".

returnProcessed:
	ret
endif	;----------------------------------------------------------------------

ignoreKey:
	;this button does not care about this keyboard event. As a leaf object
	;in the FOCUS exclusive hierarchy, we must now initiate a FOCUS-UPWARD
	;query to see a parent object (directly) or a parent's descendants
	;(indirectly) cares about this event.
	;	cx, dx, bp = data from MSG_META_KBD_CHAR

	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent
OLButtonKbdChar	endm

KbdNavigation	ends



;----------------------

Resident segment resource




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonMovePenCalcSize

DESCRIPTION:	Move the graphics pen and calculate the size of this button.

CALLED BY:	DrawColorButton, DrawBWButton

PASS:		*ds:si	= instance data for object
		di	= GState

RETURN:		cx, dx	= size of button

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OLButtonMovePenCalcSize	proc	far
	class	OLButtonClass

	push	ax, bx, si

	mov	si, ds:[si]			;ds:si = instance data
	add	si, ds:[si].Vis_offset		;ds:si = VisInstance

	mov	ax, ds:[si].VI_bounds.R_left	;move to left,top
	mov	bx, ds:[si].VI_bounds.R_top
						;pass di = handle of grstate
	call	GrMoveTo			;place pen there

	mov	cx, ds:[si].VI_bounds.R_right	;calculate width, height
	sub	cx, ax				;cx = width
	mov	dx, ds:[si].VI_bounds.R_bottom
	sub	dx, bx				;dx = height
	pop	ax, bx, si			;restore handle of Button object
	ret
OLButtonMovePenCalcSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonChooseBWRegionSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure determines which region definitions should
		be used to calculate geometry and draw a B&W button.

CALLED BY:	DrawBWButton, and lots of button geometry routines

PASS:		*ds:si = object pointer

RETURN:		ds:bp = region table (is in idata, which is fixed. Regions
			definitions themselves are in B&W resource.)

DESTROYED:	Nothing
		
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Note that DS is NOT preserved.
	
	Also, the region returned from this routine may be overridden
	by various functions in the Stylus UI in the case of a button
	on the left or right edge of the title bar.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	7/89		split off from DrawBWButton, added motif stuff.
	JimG	4/94		Added code for Stylus UI.
	dlitwin	9/7/95		Added edge buttons checks and cleaned up number
				  labels (30$, 45$ and 50$. ick)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _OL_STYLE	;--------------------------------------------------------------

OLButtonChooseBWRegionSet	proc	far
	class	OLButtonClass
	
	push	bx
	
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bx, ds:[bx].OLBI_specState
	
	mov	bp, segment idata
	mov	ds, bp			;ds points at regions

	;see if this is a "Default" or a "Normal" button

	mov	bp, offset OLBWButtonRegionSet_default
					;assume default border and
					;interior button region

	test	bx, mask OLBSS_DEFAULT
	jnz	default			;skip if is default...

	mov	bp, offset OLBWButtonRegionSet_normal
					;point to normal button border
					;and interior region definition
default:
	pop	bx
	ret
OLButtonChooseBWRegionSet	endp

endif		;--------------------------------------------------------------

if _CUA_STYLE or _MAC	;------------------------------------------------------

OLButtonChooseBWRegionSet	proc	far
	class	OLButtonClass
	uses	bx, di
	.enter

	; Dereference instance data pointer.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLBI_specState
	
	mov	bp, offset MOBWButtonRegionSet_systemMenuButton
	test	bx, mask OLBSS_SYS_ICON		;system menu icon?
	jnz	done				;skip if so...

	mov	bp, offset MOBWButtonRegionSet_menuItem
	test	bx, mask OLBSS_IN_MENU
	jnz	done				;skip if so...

	mov	bp, offset MOBWButtonRegionSet_menuButton
	test	bx, mask OLBSS_IN_MENU_BAR	;button in menu bar?
	jnz	done				;skip if so...

if _THICK_DROP_MENU_BW_BUTTONS
   	mov	bp, offset STBWButtonRegionSet_thickDropMenuButton
	test	bx, mask OLBSS_MENU_DOWN_MARK	;does button have a down mark
	jnz	done				;skip if so..
endif ;_THICK_DROP_MENU_BW_BUTTONS

if _ROUND_NORMAL_BW_BUTTONS
	; Is this button in the toolbox?  If so, use a 1-point rectangular
	; border instead of a 2-point round border.
	mov	bp, offset MOBWButtonRegionSet_systemMenuButton
   	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	jnz	done
endif ;_ROUND_NORMAL_BW_BUTTONS

if _MOTIF	;--------------------------------------------------------------
	;if this button can get the temporary default emphasis, use a different
	;region definition, because we made this button pregnant during
	;geometry.

	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	notReplyBar		;skip if not...

	call	OpenCheckIfCGA
	jc	CGAreply

	mov	bp, offset MOBWButtonRegionSet_replyButton
	test	bx, mask OLBSS_DEFAULT		;default?
	jz	done				;skip if not...

	mov	bp, offset MOBWButtonRegionSet_defReplyButton
	jmp	short done

CGAreply:
	mov	bp, offset MOCGAButtonRegionSet_replyButton
	test	bx, mask OLBSS_DEFAULT		;default?
	jz	done				;skip if not...

	mov	bp, offset MOCGAButtonRegionSet_defReplyButton
	jmp	short done

notReplyBar:
endif		;--------------------------------------------------------------

if _PM		;--------------------------------------------------------------
	;if this button can get the temporary default emphasis, use a different
	;region definition, because we made this button pregnant during
	;geometry.

	test	ds:[di].OLBI_fixedAttrs, mask OLBFA_IN_REPLY_BAR or \
					 mask OLBFA_CAN_BE_TEMP_DEFAULT_TRIGGER
	jz	notReplyBar		;skip if not...

	mov	bp, offset MOBWButtonRegionSet_replyButton
	test	bx, mask OLBSS_DEFAULT		;default?
	jz	done				;skip if not...

	mov	bp, offset MOBWButtonRegionSet_defReplyButton
	jmp	short done
notReplyBar:
	mov	bp, offset MOBWButtonRegionSet_listBoxButton
	test	bx, mask OLBSS_MENU_DOWN_MARK
	jnz	done
endif		;--------------------------------------------------------------

	;assume is regular button, check DEFAULT status

	mov	bp, offset MOBWButtonRegionSet_normButton

	test	bx, mask OLBSS_DEFAULT		;default?
	jz	notDefault			;skip if not...

	mov	bp, offset MOBWButtonRegionSet_defButton

;MAC <	test	bx, mask OLBSS_DEFAULT		;default?		>
;MAC <	jz	done				;skip if not...		>

;MAC <	mov	bp, offset MOBWButtonRegionSet_defButton		>
	jmp	done

notDefault:

if	DRAW_SHADOWS_ON_BW_GADGETS or DRAW_SHADOWS_ON_BW_TRIGGERS_ONLY
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLBI_moreAttrs, mask OLBMA_IN_TOOLBOX
	pop	di
	jz	done
	mov	bp, offset MOBWButtonRegionSet_systemMenuButton
endif

done:
	push	ax
if (_EDGE_STYLE_BUTTONS or _BLANK_STYLE_BUTTONS or _TOOL_STYLE_BUTTONS or _COMMAND_STYLE_BUTTONS)
	call	CheckForOtherButtonLooks
endif
	mov	ax, segment idata
	mov	ds, ax				;ds points at regions
	pop	ax
	
	.leave
	ret

OLButtonChooseBWRegionSet	endp


if (_EDGE_STYLE_BUTTONS or	\
	_BLANK_STYLE_BUTTONS or	\
	_TOOL_STYLE_BUTTONS or	\
	_COMMAND_STYLE_BUTTONS or \
	_WINDOW_CONTROL_BUTTONS)
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForOtherButtonLooks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check this button's hints for the other buttons hints
		and set bp to the appropriate region if one is set.

CALLED BY:	OLButtonChooseBWRegionSet
PASS:		*ds:si	= button object
RETURN:		bp	= new region, or (if no edge hints found) unchanged
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForOtherButtonLooks	proc	near
	.enter

	push	bp			; save bp in case we don't find a look

if _EDGE_STYLE_BUTTONS
	mov	bp, offset MOBWButtonRegionSet_upperRightButton
	mov	ax, HINT_TRIGGER_EDGE_STYLE_UPPER_RIGHT
	call	ObjVarFindData
	jc	gotIt

	mov	bp, offset MOBWButtonRegionSet_lowerRightButton
	mov	ax, HINT_TRIGGER_EDGE_STYLE_LOWER_RIGHT
	call	ObjVarFindData
	jc	gotIt
endif	; if _EDGE_STYLE_BUTTONS

if _BLANK_STYLE_BUTTONS
	mov	bp, offset MOBWButtonRegionSet_blankButton
	mov	ax, HINT_TRIGGER_BLANK_STYLE_BUTTON
	call	ObjVarFindData
	jc	gotIt
endif	; if _BLANK_STYLE_BUTTONS

if _TOOL_STYLE_BUTTONS
	mov	bp, offset MOBWButtonRegionSet_toolButton
	mov	ax, HINT_TRIGGER_TOOL_STYLE_BUTTON
	call	ObjVarFindData
	jc	gotIt
endif	; if _TOOL_STYLE_BUTTONS

if _COMMAND_STYLE_BUTTONS
	mov	bp, offset MOBWButtonRegionSet_commandButton
	mov	ax, HINT_TRIGGER_COMMAND_STYLE_BUTTON
	call	ObjVarFindData
	jc	gotIt
endif	; if _TOOL_COMMAND_BUTTONS

if _WINDOW_CONTROL_BUTTONS
	mov	bp, offset MOBWButtonRegionSet_windowControlButton
	mov	ax, HINT_TRIGGER_WINDOW_CONTROL_BUTTON
	call	ObjVarFindData
	jc	gotIt
endif	; if _WINDOW_CONTROL_BUTTONS

	pop	bp			; nothing found, pop original bp
	jmp	done
gotIt:
	pop	ax			; got new bp, discard old into ax
done:
	.leave
	ret
CheckForOtherButtonLooks	endp
endif	; if (_EDGE_STYLE_BUTTONS or _BLANK_STYLE_BUTTONS or TOOL_STYLE_BUTTONS)


endif		;CUA_STYLE ----------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSetMonoBitmapColor

DESCRIPTION:	set the area color to use in case the moniker for this
		object is a monochrome bitmap

CALLED BY:	DrawColorButton, DrawBWButton

PASS:		al	= color to use if button is disabled
		bx	= OLBI_specState
		si	= VI_attrs
		di	= gState
		*es:dx	= object (Only for BW button when _BLACK_NORMAL_BUTTON
	 		  is true).
RETURN:		bx, si = same

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version
	VL	7/7/95		Invert color of Bitmap if _BLACK_NORMAL_BUTTON.

------------------------------------------------------------------------------@
if (not _PM)	;--------------------------------------------------------------

OLButtonSetMonoBitmapColor	proc	far
	class	OLButtonClass

if	_BLACK_NORMAL_BUTTON
   if	not _ASSUME_BW_ONLY
	ErrMessage <_BLACK_NORMAL_BUTTON assumes B&W only operation>
   endif

EC <	Assert	objectPtr, esdx, OLButtonClass				>
endif	; _BLACK_NORMAL_BUTTON

	test	si, mask VA_FULLY_ENABLED	;is button enabled?
	jz	notEnabled			;skip if not...

	test	bx, mask OLBSS_DEPRESSED 	;if button depressed,
	mov	ax, C_WHITE		 	;draw as white
	jnz	30$

	mov	ax, C_BLACK			;else draw as black
30$:
if	_BLACK_NORMAL_BUTTON
	;
	;	Need to set bitmap in the reverse color if it is a 
	;	normally black button.
	;
	xchg	dx, si				; *es:si = object
	call	BWButtonInvertColorIfNeeded
	xchg	dx, si			
endif	; _BLACK_NORMAL_BUTTON

notEnabled:
	call	GrSetAreaColor		;set color for b/w bitmap monikers
	ret
OLButtonSetMonoBitmapColor	endp

endif		; if (not _PM) ------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonGetGenAndSpecState

DESCRIPTION:	This is a utility routine used by the draw routines.

CALLED BY:	DrawBWButton, DrawColorButton, OLButtonMouse

PASS:		*ds:si	= instance data for object

RETURN:		bx	= OLBI_specState
		cl	= OLBI_optFlags
		dl	= GI_states for object 
		dh	= VI_attrs for object

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonGetGenAndSpecState	proc	far
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	dh, ds:[di].VI_attrs		;dh = VI_attrs
	mov	bx, ds:[di].OLBI_specState	;bx = OLBI_specState
	mov	cl, ds:[di].OLBI_optFlags	;cl = OLBI_optFlags
	mov	di, ds:[di].OLBI_genChunk	;get chunk holding gen data

EC <	xchg	di, si							   >
EC <	call	GenCheckGenAssumption		;Make sure gen data exists >
EC <	xchg	di, si							   >

	mov	di, ds:[di]			;get ptr to instance
	add	di, ds:[di].Gen_offset		;ds:di = GenInstance
	mov	dl, ds:[di].GI_states		;Get GI_states in DL
	pop	di
	ret
OLButtonGetGenAndSpecState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonSetupMonikerAttrs
FUNCTION:	OLButtonSetupMonikerAttrsBX

DESCRIPTION:	This procedure is used to setup some argument flags before
		calling OpenDrawMoniker.

CALLED BY:	DrawBWButton, DrawColorButton

OLButtonSetupMonikerAttrsBX

PASS:		bx	= OLBI_specState
		al	= 0 (for normal operation)
			= OLBI_optFlags (we check for OLBOF_CURSORED to
				see if must erase selection cursor)
		ah	= OLButtonFixedAttrs
		cl	= OLButtonMoreAttrs

OLButtonSetupMonikerAttrs

PASS:		*ds:si	= object (will grab bx = OLBI_specState)
		al	= 0 (for normal operation)
			= OLBI_optFlags (we check for OLBOF_CURSORED to
				see if must erase selection cursor)

RETURN:		cx	= OLMonikerAttrs

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLButtonSetupMonikerAttrs	proc	far
	push	ax, di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLBI_specState
	mov	ch, ds:[di].OLBI_fixedAttrs
	mov	cl, ds:[di].OLBI_moreAttrs
	call	OLButtonSetupMonikerAttrsBX
	pop	ax, di
	ret
OLButtonSetupMonikerAttrs	endp

OLButtonSetupMonikerAttrsBX	proc	far	;no longer called!
	push	cx				; save OLBI_moreAttrs,
						;      OLBI_fixedAttrs
	mov	ah, ch				; keep fixedAttrs in ah

	test	cl, mask OLBMA_IN_TOOLBOX	; forcing no shortcut?
	mov	cx, 0				 ;assume nothing (always good)
	jnz	15$				 ;in toolbox, no window mark.

	test	bx, mask OLBSS_WINDOW_MARK	 ;see if window mark
	jz	15$

	ORNF	cx, mask OLMA_DISP_WIN_MARK	 ;else pass flag

15$:
	;We'll allow menu down marks in CUA again.  We'll just won't set the
	;flag if we don't want them.  -cbh 5/18/92   Also, we'll draw the
	;outline around the edge of a popup list button, so we don't have 
	;different outlines depending on what is selected.  -cbh 11/23/92

if	not SELECTION_BOX
	test	bx, mask OLBSS_MENU_DOWN_MARK
	jz	17$
	ORNF	cx, mask OLMA_DISP_DOWN_ARROW or \
		    mask OLMA_DRAW_CURSOR_INSIDE_BOUNDS
17$:
endif
	test	bx, mask OLBSS_MENU_RIGHT_MARK
	jz	20$
	ORNF	cx, mask OLMA_DISP_RT_ARROW	
20$:
	;if moniker is in a menu, set flag.
	;(display-keyboard-moniker is set later).
	
	test	bx, mask OLBSS_IN_MENU
	jz	25$				;not in menu, branch
	ORNF	cx, mask OLMA_IS_MENU_ITEM
25$:
	test	bx, mask OLBSS_IN_MENU_BAR or mask OLBSS_SYS_ICON
	jz	26$
	ORNF	cx, mask OLMA_DRAW_SHORTCUT_TO_RIGHT
26$:

	;if moniker is not in a menu or menu bar, and is cursored,
	;draw with cursored emphasis.

if _KBD_NAVIGATION	;------------------------------------------------------

if _GCM
	test	ah, mask OLBFA_GCM_SYS_ICON
	jnz	27$			;skip if is GCM icon...
endif	; _GCM

	test	bx, mask OLBSS_IN_MENU or mask OLBSS_IN_MENU_BAR \
			or mask OLBSS_SYS_ICON
	jnz	30$			;skip if in menu or menu bar...

27$::
					;pass al = OLBI_optFlags
	call	OLButtonTestForCursored
endif 			;------------------------------------------------------

30$:

	;
	; If accelerators turned off (either because no keyboard or by user)
	; force shortcuts to be *NOT* drawn.
	; If in keyboard-only mode, force shortcuts to be drawn
	; If hints desires shortcut, force shortcuts to be drawn
	; Else, set according to in-menu status
	;
	pop	ax			; retrieve al = OLBI_moreAttrs
					;          ah = OLBI_fixedAttrs

	call	OpenCheckIfKeyboardNavigation
	jnc	afterShortcut		; skip if not providing

	test	ah, mask OLBFA_FORCE_NO_SHORTCUT	; forcing no shortcut?
	jnz	afterShortcut		; yes, no shortcuts
					; assume shortcuts drawn

if _USE_KBD_ACCELERATORS
	ORNF	cx, mask OLMA_DISP_KBD_MONIKER
endif
	call	OpenCheckIfKeyboardOnly	; carry set if so
	jc	afterShortcut		; yes, force shortcuts
	test	ah, mask OLBFA_FORCE_SHORTCUT
	jnz	afterShortcut		; yes, force shortcuts
if (not _JEDIMOTIF)	; JEDI menu items don't show shortcut by default
	test	bx, mask OLBSS_IN_MENU	; in menu?
	jnz	afterShortcut		; yes, use shortcuts
endif
	andnf	cx, not mask OLMA_DISP_KBD_MONIKER	; else, turn if off
afterShortcut:
	;
	; Deal with HINT_DRAW_SHORTCUT_BELOW.  This is overridden by menu items
	;
	test	al, mask OLBMA_DRAW_SHORTCUT_BELOW
	jz	notBelow
	test	bx, mask OLBSS_IN_MENU	; menu item?
	jnz	notBelow		; yes, don't allow below
	ornf	cx, mask OLMA_DRAW_SHORTCUT_BELOW	; force this
notBelow:

	ret
OLButtonSetupMonikerAttrsBX	endp

if _KBD_NAVIGATION	;------------------------------------------------------

;This has been split off from OLButtonSetupMonikerAttrsBX so that
;it can be called by objects which show the standard selection cursor
;in menus (such as exclusive settings which are checkboxes in a menu)

OLButtonTestForCursored	proc	far
	;New code to ensure that the outline gets drawn in the correct color
	;when selected.  -cbh 11/18/92

	test	bx, mask OLBSS_DEPRESSED
	jz	10$
	call	OpenCheckIfBW
	jnc	10$
	ORNF	cx, mask OLMA_BLACK_MONOCHROME_BACKGROUND
10$:
if FOCUSED_GADGETS_ARE_INVERTED
	test	bx, mask OLBSS_DEPRESSED
else
	test	bx, mask OLBSS_CURSORED
endif
	jz	25$			;skip if not cursored...

if DRAW_SELECTION_CURSOR_FOR_FOCUSED_GADGETS
	ORNF	cx, mask OLMA_DISP_SELECTION_CURSOR or \
		    mask OLMA_SELECTION_CURSOR_ON
endif
	jmp	short 30$

25$:	;item is not cursored. If was cursored, pass flags so that cursor
	;outline is erased.

	;In Redwood, we'll have button redraw completely because of cursor/
	;mnemonic overlaps.  (Changed to be used in all systems, and to check
	;keyboard-only.  6/20/94 cbh)

	call	OpenCheckIfKeyboardOnly
	jc	27$				;keyboard only, skip this

	test	al, mask OLBOF_DRAWN_CURSORED	;was it cursored?
	jz	30$			;skip if not...

if DRAW_SELECTION_CURSOR_FOR_FOCUSED_GADGETS
	ORNF	cx, mask OLMA_DISP_SELECTION_CURSOR
endif

27$:

	;NOTE: if this object is an entry in a scrolling list, then our
	;caller (DrawColorScrollItem) will also set the
	;OLMA_USE_LIST_SELECTION_CURSOR flag.

	;NOTE: caller may also decide that erasing is not necessary
	;because the item which is losing the cursor is redrawing anyway.

30$:
	ret
OLButtonTestForCursored	endp

endif 			;------------------------------------------------------

Resident ends

;---------------------------------------

KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonActivateObjectWithMnemonic -- 
		MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC for OLButtonClass

DESCRIPTION:	Looks at its vis moniker to see if its mnemonic matches that
		key currently pressed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if found, clear otherwise

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/90		Initial version

------------------------------------------------------------------------------@

OLButtonActivateObjectWithMnemonic method OLButtonClass, \
				   MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	push	si				;save visual handle
	mov	si, ds:[di].OLBI_genChunk	;get gen handle
	call	VisCheckMnemonic		;see if mnemonic matches
	pop	si				;restore visual handle
	jnc	exit				;no, exit
	
	call	OpenButtonCheckIfFullyEnabled
	jc	activate			;fully enabled, activate

	mov	ax, SST_NO_INPUT
	call	UserStandardSound		;beep to indicate no input
	jmp	found

activate:
	mov	ax, MSG_OL_BUTTON_KBD_ACTIVATE
	call	ObjCallInstanceNoLock		;found match,activate specially
found:
	stc					;say match found
exit:
	ret
OLButtonActivateObjectWithMnemonic	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonFindKbdAccelerator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find keyboard accelerator (and beep is necessary)

CALLED BY:	MSG_GEN_FIND_KBD_ACCELERATOR
PASS:		*ds:si	= OLButtonClass object
		ds:di	= OLButtonClass instance data
		ds:bx	= OLButtonClass object (same as *ds:si)
		es 	= segment of OLButtonClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState (ModBits)
		bp low	= ToggleState
		bp high	= scan code
RETURN:		carry set if accelerator found
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLButtonFindKbdAccelerator	method dynamic OLButtonClass, 
					MSG_GEN_FIND_KBD_ACCELERATOR
	call	GenCheckKbdAccelerator		;see if we have a match
	jnc	exit				;nope, exit with carry clear

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jnz	exit				;exit with carry clear
						; GenClass will activate
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	stc					;accl found and dealt with
exit:
	ret
OLButtonFindKbdAccelerator	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonKbdActivate -- 
		MSG_OL_BUTTON_KBD_ACTIVATE for OLButtonClass

DESCRIPTION:	Activates the button, and gives it the gadget exclusive.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_BUTTON_KBD_ACTIVATE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/90		Initial version

------------------------------------------------------------------------------@

OLButtonKbdActivate	method OLButtonClass, MSG_OL_BUTTON_KBD_ACTIVATE
	mov	ax, MSG_GEN_ACTIVATE		;activate the entry
	call	ObjCallInstanceNoLock

	;call a utility routine to send a method to the Flow object that
	;will force the dismissal of all menus in stay-up-mode.

	GOTO	OLReleaseAllStayUpModeMenus
OLButtonKbdActivate	endm

KbdNavigation	ends



;---------

ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLButtonMakeDefaultAction -- 
		MSG_GEN_TRIGGER_MAKE_DEFAULT_ACTION for OLButtonClass

DESCRIPTION:	Set this trigger as temporary default.

PASS:		*ds:si 	- instance data
		es     	- segment of OLButtonClass
		ax 	- MSG_GEN_TRIGGER_MAKE_DEFAULT_ACTION

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/12/92		Initial version

------------------------------------------------------------------------------@

OLButtonMakeDefaultAction method OLButtonClass,
					MSG_GEN_TRIGGER_MAKE_DEFAULT_ACTION
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_TAKE_DEFAULT_EXCLUSIVE
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	CallOLWin		; call OLWinClass object above us
	;
	; since SVQT_TAKE_DEFAULT_EXCLUSIVE assumes the sender is going to
	; redraw and thus avoids redrawing, we must redraw
	;
	call	OLButtonDrawLATERIfNewStateFar
	ret
OLButtonMakeDefaultAction endm





ActionObscure	ends

;-------------------------------

Resident	segment	resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenButtonCheckIfFullyEnabled

SYNOPSIS:	Checks to see if fully enabled.

CALLED BY:	utility

PASS:		*ds:si -- button handle

RETURN:		carry set if fully enabled

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/16/90		Initial version

------------------------------------------------------------------------------@

OpenButtonCheckIfFullyEnabled	proc	far

if	ALLOW_ACTIVATION_OF_DISABLED_MENUS
	call	OpenButtonCheckIfAlwaysEnabled
	jc	exit				;button opens menu, always enbld
endif

	call	VisCheckIfFullyEnabled		;else check carefully
exit:
	ret
OpenButtonCheckIfFullyEnabled	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenButtonCheckIfAlwaysEnabled

SYNOPSIS:	Checks to see if this button opens a menu.

CALLED BY:	utility

PASS:		*ds:si -- button

RETURN:		carry set if always enabled

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 9/92       	Initial version

------------------------------------------------------------------------------@

if	ALLOW_ACTIVATION_OF_DISABLED_MENUS

OpenButtonCheckIfAlwaysEnabled	proc	far	uses	di, ax
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
EC <	tst	ds:[di].OLBI_genChunk		;is there a generic object? >
EC <	ERROR_Z	OL_ERROR			;error if not		    >

	push	si				;save button handle
	mov	si, ds:[di].OLBI_genChunk	;get gen chunk
	call	OLQueryIsMenu			;is this a menu?
	pop	si

if	_MENUS_PINNABLE
	jc	exit				;yes, return carry set

	;if this GenTrigger is a push-pin in a menu or window, DO NOT
	;disable it! (It is ok to test for MSG_OL_POPUP_TOGGLE_PUSHPIN
	;directly because it is exported from MetaUIMessages.)
	;

	call	CheckIfPushpin


exit:
endif
	.leave
	ret
OpenButtonCheckIfAlwaysEnabled	endp

if	_MENUS_PINNABLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfPushpin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed object is a pushpin trigger or not

CALLED BY:	GLOBAL
PASS:		*ds:si - OLButton object
RETURN:		carry set if pushpin
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfPushpin	proc	far
	class	GenTriggerClass
	.enter

;	This is a pushpin if:
;
;	1) It is a subclass of GenTrigger
;	2) Its action msg is MSG_OL_POPUP_TOGGLE_PUSHPIN
;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	exit		;If not a subclass of gen, exit with carry clr

	push	es
	mov	di, segment GenTriggerClass
	mov	es, di							
	mov	di, offset GenTriggerClass
	call	ObjIsObjectInClass					
	pop	es
	jnc	exit		;Exit w/carry clear if not a subclass of
				; GenTrigger
	

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GTI_actionMsg, MSG_OL_POPUP_TOGGLE_PUSHPIN
	stc
	je	exit			;skip if is pushpin...
	clc
exit:
	.leave
	ret
CheckIfPushpin	endp

endif
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLButtonCallGenPart

DESCRIPTION:	This routine will forward a method call onto the object
		which is designated as the "generic object" for this
		OLButtonClass object. In some cases, this is the same object.

CALLED BY:	misc.

PASS:		*ds:si	= instance data for object
		ax, cx, dx, bp = method data to pass

RETURN:		ds, si = same
		ax, cx, dx, bp = method data returned

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OLButtonCallGenPart	proc	far
	;all OLButtonClass objects must have a OLBI_genChunk value, even
	;if it is the chunk of this object.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
EC <	tst	ds:[di].OLBI_genChunk		;is there a generic object? >
EC <	ERROR_Z	OL_ERROR			;error if not		    >

	push	si				;save button handle
	mov	si, ds:[di].OLBI_genChunk	;get gen chunk
	call	ObjCallInstanceNoLock
	pop	si
	ret
OLButtonCallGenPart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle gaining the focus for a visual button

CALLED BY:	MSG_META_GAINED_APP_FOCUS_EXCL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of OLButtonClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0

This has been commented out until such time as as focus / Doug help
comes back into vogue.  It will use ATTR_GEN_FOCUS_HELP, but a different
mechanism for sending the notification, as it will be a system-wide
feature instead of an application GCN list.

OLButtonGainedFocusExcl		method dynamic OLButtonClass,
						MSG_META_GAINED_FOCUS_EXCL
	push	ds:[di].OLBI_genChunk		;save chunk of GenClass object
	;
	; Let our superclass do its thing
	;
	mov	di, offset OLButtonClass
	call	ObjCallSuperNoLock
	;
	; See if there is any "focus" help -- this will be in the
	; GenClass object associated with this button
	;
	pop	si				;*ds:si <- GenClass object
	mov	ax, ATTR_GEN_FOCUS_HELP
	call	ObjVarFindData
	jnc	noFocusHelp1			;branch if no focus help
	;
	; There is focus help -- get the OD of the text
	;
	mov	si, ds:[bx].chunk		;si <- chunk of text
	mov	cx, ds:[bx].handle		;cx <- handle to relocate
	;
	; We need to relocate the handle manually
	;
	mov	bx, ds:[LMBH_handle]		;bx <- handle of block
	mov	al, RELOC_HANDLE
	call	ObjDoRelocation
	mov	bx, cx				;^lbx:si <- relocated OD of text
	jmp	sendFocusHelpNotify

	;
	; Check for the the other flavor of focus help
	;
noFocusHelp1:
	mov	ax, ATTR_GEN_FOCUS_HELP_LIB
	call	ObjVarFindData
	jnc	noFocusHelp2			;branch if no focus help
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle		;^lbx:si <- OD of text
	;
	; Send the help notification
	;
sendFocusHelpNotify:
	mov	al, HT_FOCUS_HELP		;al <- HelpType
	call	HelpSendFocusNotification
noFocusHelp2:
	ret
OLButtonGainedFocusExcl		endm

endif





COMMENT @----------------------------------------------------------------------

ROUTINE:	InsetBoundsIfReplyPopup

SYNOPSIS:	Do horrible things to the button's bounds if we're a popup 
		list in a reply bar, so that everything draws right from here
		on out.   Since this only affects menu buttons, we'll be
		undoing the damage in its MSG_VIS_DRAW handler.

CALLED BY:	FAR

PASS:		*ds:si -- poor victim
		bx -- OLButtonSpecState
		di -- gstate

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 8/92       	Initial version

------------------------------------------------------------------------------@

InsetBoundsIfReplyPopup	proc	far		uses	bp
	.enter
	;
	; If we're a popup list in a reply bar kind of situation, temporarily 
	; muck with bounds so things like the cursor and the down arrow draw in
	; the right place.   Also, move the pen position left a bit.
	;
	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLBI_specState, mask OLBSS_DEFAULT_TRIGGER
	jz	10$
	push	ax, bx, cx, dx

	call	VisGetBounds
	add	ax, MO_REPLY_BUTTON_INSET_X
	sub	cx, MO_REPLY_BUTTON_INSET_X
	add	bx, MO_REPLY_BUTTON_INSET_Y
	sub	dx, MO_REPLY_BUTTON_INSET_Y
	call	OpenCheckIfCGA		;running CGA?
	jnc	5$			;skip if not
	sub	bx, MO_REPLY_BUTTON_INSET_Y - MO_CGA_REPLY_BUTTON_INSET_Y
	add	dx, MO_REPLY_BUTTON_INSET_Y - MO_CGA_REPLY_BUTTON_INSET_Y
5$:
	sub	cx, ax
	sub	dx, bx
	call	VisSetSize
	mov	cx, ax
	mov	dx, bx
	call	VisSetPosition
	pop	ax, bx, cx, dx
10$:
	.leave
	ret
InsetBoundsIfReplyPopup	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	AdjustCurPosIfReplyPopup

SYNOPSIS:	Hacks in space around reply popups so they'll line up with
		other reply buttons.

CALLED BY:	ReDrawBWButton, maybe something else

PASS:		di -- gstate
		bx -- OLButtonSpecState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 8/93       	Initial version

------------------------------------------------------------------------------@

AdjustCurPosIfReplyPopup	proc	far
	test	bx, mask OLBSS_DEFAULT_TRIGGER
	jz	exit
	push	ax, bx, cx, dx, bp
	mov	bp, MO_REPLY_BUTTON_INSET_X
	mov	dx, bp
	clr	cx
	negdw	dxcx
	clrdw	bxax
	call	GrRelMoveTo
	pop	ax, bx, cx, dx, bp
exit:
	ret
AdjustCurPosIfReplyPopup	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonNotifyGeometryValid -- 
		MSG_VIS_NOTIFY_GEOMETRY_VALID for OLButtonClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Notification of complete geometry.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_NOTIFY_GEOMETRY_VALID

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
	chris	7/20/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_DIALOGS and (not (_ODIE or _DUI))

OLButtonNotifyGeometryValid	method dynamic	OLButtonClass, \
				MSG_VIS_NOTIFY_GEOMETRY_VALID
	.enter
	mov	di, offset OLButtonClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLBI_genChunk
	cmp	si, di
	je	exit			;chunks match, exit

	push	si			;save our chunk
	mov	si, di			;interaction chunk in si

EC <	push	di							>
EC <	mov	di, segment GenInteractionClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenInteractionClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
EC <	pop	di							>

	;
	; Add bounds of our button
	;
	mov	cx, size optr
	mov	ax, HINT_INTERACTION_ACTIVATED_BY
	call	ObjVarAddData
	mov	di, bx
	pop	ds:[di].chunk			;store our optr
	mov	bx, ds:[LMBH_handle]
	mov	ds:[di].handle, bx
exit:
	.leave
	ret
OLButtonNotifyGeometryValid	endm

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLButtonGetActivatorBounds -- 
		MSG_META_GET_ACTIVATOR_BOUNDS for OLButtonClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Gets bounds of activator.

PASS:		*ds:si 	- instance data
		es     	- segment of OLButtonClass
		ax 	- MSG_META_GET_ACTIVATOR_BOUNDS

RETURN:		carry set if an activating object found
		ax, bp, cx, dx - screen bounds of object

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/24/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_DIALOGS

OLButtonGetActivatorBounds	method dynamic	OLButtonClass, \
				MSG_META_GET_ACTIVATOR_BOUNDS
	.enter
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		;BP <- GState handle

	call	VisGetBounds		;AX <- left edge of the object

if _RUDY
	sub	ax, GET_PAST_ARROW_AMOUNT
					;make sure arrow happens for buttons

;	If this is NOT a setting, have the arrow draw to the *left* edge,
;	by setting right = left.

	mov	di, ds:[si]
	add	di, ds:[di].OLButton_offset
	test	ds:[di].OLBI_specState, mask OLBSS_SETTING
	jnz	20$
	mov	cx, ax
20$:
endif

	sub	dx, bx
	shr	dx, 1
	add	bx, dx		;BX <- middle of the object (vertically)

	;
	; "Left" bounds now in ax, right bounds in cx, top/bottom in bx.
	;
	mov	di, bp		;DI <- GState handle
	
	; Check if "right" is in window bounds.  If not, return carry clear.

	xchg	ax, cx
	push	cx
	call	CheckIfPointInWinBounds
	pop	cx
	xchg	ax, cx
	jnc	done

	; Transform into window coordinates.

	call	GrTransform	;Transform AX,BX to screen coords
	mov	dx, bx
	mov	bp, bx		;BP,DX <- middle of obj vertically
	xchg	ax, cx
	call	GrTransform	;Transform CX
	xchg	ax, cx

	stc

done:
	pushf
	call	GrDestroyState
	popf

	.leave
	ret
OLButtonGetActivatorBounds	endm

endif
if _PCV

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForCompressedMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if this component/object should draw using the
		compressed moniker insets.

CALLED BY:	SetupMonikerArgs, ReDrawBWButton
PASS:		*ds:si	- object
RETURN:		Carry set if compressed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForCompressedMoniker	proc	far
	uses	si, bx
	.enter
	mov	ax, HINT_USE_COMPRESSED_INSETS_FOR_MONIKER
	call	ObjVarFindData
	.leave
	ret
CheckForCompressedMoniker	endp
endif 	; PCV

Resident	ends
