COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988-1994 -- All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		openMenuBar.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLMenuBarClass		menu bar class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation

DESCRIPTION:

	$Id: copenMenuBar.asm,v 1.3 98/05/04 06:46:17 joon Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLMenuBarClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


MenuBarBuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarInitialize -- MSG_META_INITIALIZE for OLMenuBarClass

DESCRIPTION:	Initialize an open look base window

PASS:
	*ds:si - instance data
	es - segment of OLMenuBarClass
	ax - MSG_META_INITIALIZE

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation

------------------------------------------------------------------------------@
OLMenuBarInitialize	method dynamic	OLMenuBarClass,	\
					MSG_META_INITIALIZE
	;
	;  Do superclass
	;
	mov	di, offset OLMenuBarClass
	call	ObjCallSuperNoLock

	;
	; indicate whether pop-out menu bars are allowed
	;	(OLPopout superclass allows them by default)
	;
	call	MBBuild_DerefVisSpecDI	;set ds:di = VisSpec instance data
					;ignore super and allow based totally
					;	on OpenCheckPopOutMenuBar
	ornf	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
	call	OpenCheckPopOutMenuBar
	jc	allow
	andnf	ds:[di].OLPOI_flags, not mask OLPOF_ALLOWED
allow:
	;
	; Initialize Visible characteristics
	;
	call	MBBuild_DerefVisSpecDI	;set ds:di = VisSpec instance data

    	call	CtrlExpandWidthToFitParent
	call	CtrlAllowChildrenToWrap
	call	CtrlOrientHorizontally

	;
	; Don't include menu bar in centering operations if the primary is
	; being centered.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].VI_geoAttrs, mask VGA_DONT_CENTER

	ret
OLMenuBarInitialize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarSpecBuild -- MSG_SPEC_BUILD for OLMenuBarClass

DESCRIPTION:	Build out this menu bar window visually, attaching it onto
		some background window in the system.

PASS:
	*ds:si - instance data
	es - segment of OLMenuBarClass

	ax - MSG_SPEC_BUILD

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

	Use data set during BUILD to determine vis parent

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation
	Doug	6/91		Added sending of MSG_SPEC_BUILD on to
				the transient group, which was somehow left
				out of the original code.  Caused bug in 
				new America Online being release w/V1.2, in
				which adopted display menus were missing after
				restoring an iconfied instance of the app.
				Also changed to manual update, since caller
				is responsible for visual update.

------------------------------------------------------------------------------@

OLMenuBarSpecBuild	method dynamic	OLMenuBarClass, MSG_SPEC_BUILD
EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>

	call	VisCheckIfSpecBuilt
	jc	alreadyBuilt

	call	VisSpecBuildSetEnabledState	;set enabled state correctly
	
	;add ourself to the visual world

	push	bp
	push	si

	;
	; deal with popped out menu bar, use popout dialog instead of normal
	; vis parent
	;
	mov	ax, MSG_SPEC_GET_VIS_PARENT
	call	ObjCallInstanceNoLock		; carry set to use custom
						;	vis parent
	jc	haveVisParent
	call	MBBuild_DerefVisSpecDI	;ds:di = VisSpec instance data
	mov	cx, ds:[di].OLCI_visParent.handle	;^lcx:dx = vis parent
	mov	dx, ds:[di].OLCI_visParent.chunk
haveVisParent:
	mov	bx, cx
	mov	cx, ds:[LMBH_handle]		;^lcx:dx = ourself
	xchg	dx, si				;^lbx:si = vis parent

if MENU_BAR_AT_BOTTOM
	mov	bp, CCO_LAST
else
	mov	bp, CCO_FIRST
endif
	mov	ax, MSG_VIS_ADD_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	si				; *ds:si = self

	;
	; Since we're just now building this object, visually invalidate it.

	mov	cx, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid

	pop	bp

	; Make sure all the sub-items sitting underneath us are built out
	; as well.

alreadyBuilt:

	ret
OLMenuBarSpecBuild	endp


MBBuild_DerefVisSpecDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
MBBuild_DerefVisSpecDI	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarBuildInfo -- MSG_BAR_BUILD_INFO for OLMenuBarClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLMenuBarClass

	ax - MSG_MB_BUILD_INFO
	cx - Query type (GenQueryType or SpecGenQueryType)
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

		;is below a window which has a menu bar: if is seeking
		;specific menu, send on to that menu. Otherwise, if is
		;menu window or OpenLook trigger, place in this menu bar.
		;Otherwise return NO.
	    if (HINT_FIND or HINT_EDIT or HINT_WINDOW_MENU) {
	        MSG_SPEC_GUP_QUERY(specific menu, SGQT_BUILD_INFO);
		return(stuff from specific menu)
	    }
	    if (MENUABLE or OpenLook or HINT_SEEK_MENU) {
		TOP_MENU = 1;
		SUB_MENU = 0;
		visParent = this object;
	    } else {
		just return - caller (OLMenuedWinClass) will return NULL
		so that genparent is used as visparent.
	    }

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version
	Eric	10/89		Added checks for HINT_AVOID_MENU_BAR, etc
	Eric	12/89		Added MDI menu, etc.

------------------------------------------------------------------------------@
OLMenuBarBuildInfo	method dynamic	OLMenuBarClass, MSG_BAR_BUILD_INFO

	;first see if this menu has been sent upwards from inside a GenDisplay
	;which is in a GenDisplayGroup. If so, create an OLCtrlClass object
	;to hold what will be a transient menu button.

	call	MBBuild_DerefVisSpecDI	;ds:di = VisSpec instance data

	call	OLMenuBarTestForDisplayMenu
	jc	returnChunkHandle	;skip with dx = handle of Ctrl group
					;to use as parent...

	;If this item is not a Menu and is not a GenTrigger seeking the
	;menu bar, tell the GenPrimary to handle it.

CUAS <	test	bp, mask OLBF_MENUABLE or mask OLBF_SEEK_MENU_BAR	>
CUAS <	jz	done			;skip with CY=0			>

	;OpenLook (or Motif with SEEK_MENU_BAR): place in this menu bar.

	mov	dx, si
EC <	test	bp, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	or	bp, OLBR_TOP_MENU shl offset OLBF_REPLY

returnChunkHandle:
	mov	cx, ds:[LMBH_handle]
CUAS < done:								>
	ret
OLMenuBarBuildInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuBarTestForDisplayMenu

DESCRIPTION:	This procedure is called by OLMenuBarBuildInfo to see
		if the query has been sent by a GenInteraction which
		is inside a GenDisplay. We want that menu to open from
		the GenPrimary's menu bar.

CALLED BY:	OLMenuBarBuildInfo	

PASS:
	ds:*si	- instance data
	ds:di - spec data
	bp - OLBuildInfo

RETURN:
	carry - set if destination found
	dx - chunk handle of destination
	di - same if destination not found
	bp - updated

DESTROYED:
	ax, bx, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		initial version

------------------------------------------------------------------------------@

OLMenuBarTestForDisplayMenu	proc	near
	class	OLMenuBarClass
	
	test	bp, mask OLBF_MENU_IN_DISPLAY
					;(clears carry flag)
	jz	done			;skip if not in display (cy=0)...

	mov	dx, si			; return MenuBar

EC <	test	bp, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	or	bp, OLBR_TOP_MENU shl offset OLBF_REPLY ;indicate is in menu bar
	stc				;return flag

done:	;return with carry set if we placed button in OLCtrl group.
	ret
OLMenuBarTestForDisplayMenu	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarGetVisParent

DESCRIPTION:	Returns visual parent for this object

PASS:
	*ds:si - instance data
	es - segment of OLMenuBarClass

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
	chris	4/27/93		Initial version

------------------------------------------------------------------------------@
if	0

OLMenuBarGetVisParent	method	dynamic OLMenuBarClass, \

	mov	di, offset OLMenuBarClass
	call	ObjCallSuperNoLock

	;
	; After calling the superclass, we'll add some hints that we need,
	; so that menu bar popout windows avoid expanding unnecessarily.
	;
	pushf					;save carry returned
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPOI_flags, mask OLPOF_ALLOWED
	jz	done				; exit w/carry clear
	test	ds:[di].OLPOI_flags, mask OLPOF_POPPED_OUT
	jz	done				; exit w/carry clear

	mov	bx, ds:[di].OLPOI_dialog	; ^lbx:si = new dialog
	mov	si, offset PopoutDialogTemplate
	call	ObjSwapLock			; *ds:si = new dialog

	mov	ax, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
	clr	cx
	call	ObjVarAddData

	mov	ax, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
	clr	cx
	call	ObjVarAddData

	call	ObjSwapUnlock			; *ds:si = OLPopout
done:
	popf
	ret
OLMenuBarGetVisParent	endp

endif


MenuBarBuild ends

;----------------------------------

MenuBarCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarGetSpacing -- 
		MSG_VIS_COMP_GET_CHILD_SPACING for OLMenuBarClass

DESCRIPTION:	Returns spacing for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_GET_SPACING

RETURN:		cx 	- spacing between children
		dx	- spacing between lines of wrapped children
		
DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@

OLMenuBarGetSpacing	method OLMenuBarClass, \
			MSG_VIS_COMP_GET_CHILD_SPACING

	mov	dx, MENU_BAR_BETWEEN_LINES
	mov	cx, MENU_BAR_BETWEEN_KIDS
	ret

OLMenuBarGetSpacing	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarGetMargins -- 
		MSG_VIS_COMP_GET_MARGINS for OLMenuBarClass

DESCRIPTION:	Returns margins and margins for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_VIS_COMP_GET_MARGINS

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@

OLMenuBarGetMargins method OLMenuBarClass, MSG_VIS_COMP_GET_MARGINS

if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
	call	OpenCheckIfKeyboardOnly	; carry set if so
	jnc	noMenuActivator		; nope
	call	GetMenuActivatorWidth	; dx = width
noMenuActivator:
endif	;----------------------------------------------------------------------

	;assume is color display: get margin values

	mov	ax, MENU_BAR_LEFT_MARGIN
if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
	call	OpenCheckIfKeyboardOnly	; carry set if so
	jnc	noMenuActivator2	; nope
	add	ax, dx			; add in width of "Alt"
	add	ax, 2
noMenuActivator2:
endif	;----------------------------------------------------------------------
MO <	segmov	es, dgroup, cx					>
	mov	bp, MENU_BAR_TOP_MARGIN
	mov	cx, MENU_BAR_RIGHT_MARGIN
	mov	dx, MENU_BAR_BOTTOM_MARGIN

MO <	test	es:[moCS_flags], mask CSF_BW			>
MO <	jz	10$			;skip if is color display...	>
MO <	;in CGA, we overlap the header, so we need top margin -cbh 2/15/92 >
MO <	call	OpenCheckIfCGA		;CHECK CGA FOR CUA LOOK		>
MO <	jc	10$							>
MO <	;black & white display: if Motif, set for 0 pixel margin at top,>
MO <	;since we don't have etched lines.				>
MO <	dec	bp			;else we don't need a top margin>
MO <	;same with left margin - brianc 2/14/92  (we need margin back 2/15/92)
MO <	dec	ax			;else we don't need a left margin>
MO <10$:								>

	ret

OLMenuBarGetMargins	endp

if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
GetMenuActivatorWidth	proc	far
	uses	ax, bx, cx, di, bp
	.enter
	mov	ax, TEMP_MENU_ACTIVATOR_WIDTH
	call	ObjVarFindData		; carry set if found
	mov	dx, ds:[bx]		; assume found
	jc	done			; found, done -- dx = width
;	mov	ax, MSG_VIS_VUP_QUERY
;	mov	cx, VUQ_DISPLAY_SCHEME
;	call	ObjCallInstanceNoLock	; cx = font ID, dx = point size
	call	SpecGetDisplayScheme
	clr	di			; no window
	call	GrCreateState
	clr	ah			; dx.ah = point size
	call	GrSetFont
	push	ds
	mov	bx, handle ActivateMenuKey
	call	MemLock
	mov	ds, ax
	push	si
	mov	si, offset ActivateMenuKey
	mov	si, ds:[si]
	mov	cx, -1			; check 'em all
	call	GrTextWidth		; dx = width of "Alt"
	pop	si
	call	MemUnlock
	pop	ds
	call	GrDestroyState
	mov	ax, TEMP_MENU_ACTIVATOR_WIDTH
	mov	cx, size word
	call	ObjVarAddData		; ds:bx = extra data
	mov	ds:[bx], dx		; save width
done:
	.leave
	ret
GetMenuActivatorWidth	endp
endif	;----------------------------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuBarNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for OLMenuBarClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		cx:dx	= OD of replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLMenuBarClass handler:
	    identical to standard VisCompClass handler, except we set
	    the NCF_BAR_MENU_RELATED flag, so that non-menu bar navigation
	    queries can skip this group completely.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLMenuBarNavigate	method dynamic	OLMenuBarClass,
					MSG_SPEC_NAVIGATION_QUERY
	;other ERROR CHECKING is in VisNavigateCommon

	;call utility routine, passing flags to indicate that this is
	;a composite node in visible tree, and that this object cannot
	;get the focus (although it may have siblings that do).
	;This routine will check the passed NavigationFlags and decide
	;what to respond.

	mov	bl, mask NCF_IS_MENU_RELATED or mask NCF_IS_COMPOSITE
					;pass flags: is composite, is not
				  	;root node, not focusable.
	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon
	ret
OLMenuBarNavigate	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarDraw -- MSG_VIS_DRAW for OLMenuBarClass

DESCRIPTION:	Draw the menu bar

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_VIS_DRAW

	cl - DrawFlags:  DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState to use

RETURN:		nothing

DESTROYED:	everything
	

PSEUDO CODE/STRATEGY:
	A presentation manager menu bar is framed by the window frame on
	the left and right, and by the bottom of the header on the top.
	Therefore, we only need to draw the bottom line of the menu bar.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@

if not NO_MENU_BAR_DRAWING

if _CUA_STYLE	;---------------------------------------------------------------

OLMenuBarDraw	method dynamic	OLMenuBarClass, MSG_VIS_DRAW
	push	ax, bp, si, es, cx

	segmov	es, ds
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
					; (There is no generic part)
	;
	; get display scheme data
	;
	mov	di, bp			; put GState in di
	push	cx			; DrawFlags
	mov	ax, GIT_PRIVATE_DATA	; pass di, ax
	call	GrGetInfo		; returns ax, bx, cx, dx
	pop	cx

	;
	; al = color scheme, ah = display type, cl = update flag
	;
	ANDNF	ah, mask DF_DISPLAY_TYPE
MO <	mov	dl, ah				; Pass Display type in dl >
ISU <	mov	dl, ah				; Pass Display type in dl >
	mov	ch, cl				; Pass DrawFlags in ch
	mov	cl, al				; Pass color scheme in cl
						; (ax & bx get trashed)
	;
	; call procedure in DrawBW or DrawColor resource
	;
	call	DrawColorOrBWMenuBar
	pop	ax, bp, si, es, cx

if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
	push	bp				; save gstate
endif	;----------------------------------------------------------------------

	;
	;  Let the superclass do its little thing.
	;
	mov	di, offset OLMenuBarClass
	CallSuper	MSG_VIS_DRAW	;send MSG_VIS_DRAW to OLCtrlClass
					;so will send to kids
if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
	pop	di				; restore gstate
endif	;----------------------------------------------------------------------

if HIGHLIGHT_MNEMONICS	;------------------------------------------------------
	call	OpenCheckIfKeyboardOnly	;carry set if so
	jnc	noMenuActivator
	push	ds
	mov	bx, handle ActivateMenuKey
	push	bx
	call	ObjLockObjBlock
	push	ax			;save segment
	call	VisGetBounds
	add	ax, MENU_BAR_LEFT_MARGIN + 2	;draw at offset 2,2
	add	bx, MENU_BAR_TOP_MARGIN + 2
MO <	push	es						>
MO <	segmov	es, dgroup, cx					>
MO <	test	es:[moCS_flags], mask CSF_BW			>
MO <	pop	es						>
MO <	jz	10$			;skip if is color display...	>
MO <	;black & white display: if Motif, set for 0 pixel margin at top,>
MO <	;since we don't have etched lines.				>
MO <	sub	bx, (MENU_BAR_TOP_MARGIN+ 1)				>
MO <10$:								>
ISU <	push	es						>
ISU <	segmov	es, dgroup, cx					>
ISU <	test	es:[moCS_flags], mask CSF_BW			>
ISU <	pop	es						>
ISU <	jz	10$			;skip if is color display...	>
ISU <	;black & white display: if Motif, set for 0 pixel margin at top,>
ISU <	;since we don't have etched lines.				>
ISU <	sub	bx, (MENU_BAR_TOP_MARGIN+ 1)				>
ISU <10$:								>
	pop	ds			;restore segment
	push	si
	mov	si, offset ActivateMenuKey
	mov	si, ds:[si]
	clr	cx			;null term'ed
	call	GrDrawText
	pop	si
	mov	cx, bx			;cx = Y pos
	pop	bx
	call	MemUnlock
	pop	ds
	mov	dx, ax			;dx = X pos
	mov	bx, cx			;bx = Y pos

	;
	; invert the thing
	;
	call	GrGetMixMode
	push	ax
	mov	al, MM_INVERT
	call	GrSetMixMode
	mov	ax, dx			;ax = left
	call	GetMenuActivatorWidth	;dx = width
	mov	cx, dx
	add	cx, ax			;cx = right
					;bx = top
	mov	si, GFMI_ROUNDED or GFMI_UNDER_POS	;offset to underline
	call	GrFontMetrics		;dx = height
	add	dx, bx			;dx = bottom
	call	GrFillRect
	pop	ax
	call	GrSetMixMode
noMenuActivator:

endif	; _HIGHLIGHT_MNEMONICS ------------------------------------------------

	ret
OLMenuBarDraw	endp

endif		;CUA_STYLE -----------------------------------------------------

endif


if 	not NO_MENU_BAR_DRAWING		
if	_MOTIF or _ISUI
	
DrawColorOrBWMenuBar	proc	far
	cmp	dl, DC_GRAY_1			;B&W display?	          
	pushf

if	(0)		; just having fun with colors :)
	jz	afterBackground
	mov	al, SDM_50
	call	GrSetAreaMask
	mov	ax, C_WHITE
	call	GrSetAreaColor
	call	VisGetBounds
	call	GrFillRect
	mov	al, SDM_100
	call	GrSetAreaMask
afterBackground:
endif

	call	OpenSetInsetRectColors		;get inset rect colors
	xchg	ax, bp
	xchg	al, ah				;make outset rect
	xchg	ax, bp
	call	VisGetBounds			;get normal bounds
	popf								  
	jne	10$				;skip if color...         

	;In B/W, do some despicable things above, left, and right of the menu
	;  bar to make things overlap properly.
	;  CHECK BW FOR CUA LOOK

	call	OpenCheckIfCGA			;in CGA, don't do despicable
	jc	10$				;  things.
	dec	bx				;up one
if (not _ISUI)
   	dec	ax				;left
	inc	cx				;right
endif ; (not _ISUI)

10$:								  
	call	OpenDrawRect
done::
	ret			
DrawColorOrBWMenuBar	endp

endif
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuBarBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}. We handle here so that
		the broadcast does not get lost in the menu bar.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= OD of object with hint
		carry set if broadcast handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLMenuBarBroadcastForDefaultFocus	method dynamic	OLMenuBarClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	;do not handle broadcast; do not allow to look at kids

	ret			;do not call kids
OLMenuBarBroadcastForDefaultFocus	endm

MenuBarCommon	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarActivateObjectWithMnemonic -- 
		MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC for OLMenuBarClass

DESCRIPTION:	Finds any mnemonics in this branch.  If the menu bar doesn't
		have the focus, and alt isn't pressed, we won't check out
		menu button mnemonics.

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

RETURN:		carry set if match found

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/31/90		Initial version

------------------------------------------------------------------------------@

OLMenuBarActivateObjectWithMnemonic	method dynamic OLMenuBarClass, 
			MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	test	dh, mask SS_LALT or mask SS_RALT ;alt pressed, call superclass
	jnz	callSuper

	push	cx, dx, bp
	mov	ax, MSG_OL_WIN_QUERY_MENU_BAR_HAS_FOCUS
	call	VisCallParent			;see if menu bar has focus
	pop	cx, dx, bp
	jnc	exit				;it don't, exit
	
callSuper:
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, offset OLMenuBarClass
	CallSuper	MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
exit:
	ret
OLMenuBarActivateObjectWithMnemonic	endm

KbdNavigation	ends


MenuBarCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLMenuBarClass

DESCRIPTION:	Recalcs size for the menu bar.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - suggested size

RETURN:		cx, dx - size to use
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 6/92		Initial Version

------------------------------------------------------------------------------@

OLMenuBarRecalcSize	method dynamic	OLMenuBarClass, \
				MSG_VIS_RECALC_SIZE
	;
	; Code added 2/ 6/92 to put in header when in maximized mode.  We
	; will force the menu bar to be the width of the header title area.
	;
	call	OpenCheckMenusInHeaderOnMax
	jnc	20$

	tst	cx
	js	20$				;desired width, branch
	push	ax
	mov	ax, MSG_OL_WIN_IS_MAXIMIZED
	call	VisCallParent
	pop	ax
	jnc	20$
	push	ax
	mov	ax, MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS
	call	VisCallParent
	sub	cx, ax				;subtract left icon widths
	sub	cx, bp				;and right icon widths
	pop	ax
20$:
	call	MenuBarPassMarginInfo
	call	OpenRecalcCtrlSize

	ret
OLMenuBarRecalcSize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuBarPositionBranch -- 
		MSG_VIS_POSITION_BRANCH for OLMenuBarClass

DESCRIPTION:	Positions a branch.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_POSITION_BRANCH

		cx, dx  - new position for composite

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
	chris	2/ 6/92		Initial Version

------------------------------------------------------------------------------@

OLMenuBarPositionBranch	method dynamic	OLMenuBarClass, \
				MSG_VIS_POSITION_BRANCH
	;
	; Code added 2/ 6/92 to put in header when in maximized mode.  We
	; will force the menu bar to be to the right of the icons if max'ed.
	;
	call	OpenCheckMenusInHeaderOnMax
	jnc	20$

	push	ax
	mov	ax, MSG_OL_WIN_IS_MAXIMIZED
	call	VisCallParent
	pop	ax
	jnc	20$
	push	ax
	mov	ax, MSG_OL_WIN_GET_HEADER_TITLE_BOUNDS
	call	VisCallParent
	mov	cx, ax				;use title left edge 
	pop	ax
20$:
	call	MenuBarPassMarginInfo	

	call	VisCompPosition

	ret
OLMenuBarPositionBranch	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	MenuBarPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLMenuBarRecalcSize, OLMenuBarPositionBranch

PASS:		*ds:si -- MenuBar bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

MenuBarPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OLMenuBarGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OLMenuBarGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
MenuBarPassMarginInfo	endp


; I can find no need whatso-ever for this -- superclasses in the spui don't
; use these messages, & the VisClass default handler just sends them on to
; the visible parent, which is all that OLCI_visParent it.  Let's give it 
; a shot -- Doug 2/5/93
;
;
;MenuBarFupKbdChar	method	dynamic	OLMenuBarClass,
;				MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR,
;				MSG_META_MUP_ALTER_FTVMC_EXCL
;	mov	bx, ds:[di].OLCI_visParent.handle
;	mov	si, ds:[di].OLCI_visParent.chunk
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	GOTO	ObjMessage
;MenuBarFupKbdChar	endm

MenuBarCommon	ends

CommonFunctional	segment resource

CommonFunctional	ends
