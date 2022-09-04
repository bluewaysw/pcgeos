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

	$Id: copenMenuBar.asm,v 2.102 96/02/21 17:49:22 brianc Exp $

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

if (not _MAC)
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

else

	;
	; popout menu bars not allowed on MAC
	;
	call	MBBuild_DerefVisSpecDI	;set ds:di = VisSpec instance data
	andnf	ds:[di].OLPOI_flags, not mask OLPOF_ALLOWED

endif
	;
	; Initialize Visible characteristics
	;
	call	MBBuild_DerefVisSpecDI	;set ds:di = VisSpec instance data
MAC <	mov	ds:[di].OLMBAR_state, 0					>
    

if _RUDY
	call	CtrlOrientVertically
	call	CtrlExpandHeightToFitParent
	call	CtrlRightJustify
else    
    	call	CtrlExpandWidthToFitParent
	call	CtrlAllowChildrenToWrap
	call	CtrlOrientHorizontally
endif

	;
	; Don't include menu bar in centering operations if the primary is
	; being centered.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].VI_geoAttrs, mask VGA_DONT_CENTER

JEDI <	call	CtrlFullJustifyHorizontally				>
;JEDI <	ornf	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN	>

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

MAC <	test	ds:[di].OLMBAR_state, mask OLMBARS_UNDER_PRIMARY	>
MAC <	jz	10$							>
MAC <	ornf	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_WIN_GROUP >
MAC <10$:								>

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

if _JEDIMOTIF or MENU_BAR_AT_BOTTOM
	mov	bp, CCO_LAST
else
	mov	bp, CCO_FIRST
endif
	mov	ax, MSG_VIS_ADD_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	si				; *ds:si = self

if _JEDIMOTIF
	;
	;  Add ourself to GCN list for sticky-key notifications.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_NOTIFY_KEYBOARD_EVENT
	call	GCNListAdd
if 0
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, MGCNLT_ACTIVE_LIST
	call	GCNListAdd		
endif
endif
	;
	; Since we're just now building this object, visually invalidate it.

if _MAC		; START MAC specific code -------------------------------------
	call	MBBuild_DerefVisSpecDI
	test	ds:[di].OLMBAR_state, mask OLMBARS_UNDER_PRIMARY
	jz	willBeBuiltLater

	mov	cx, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid
	jmp	invalidateComplete

willBeBuiltLater:
endif		; END MAC specific code ---------------------------------------

	mov	cx, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid

MAC <invalidateComplete:						>
	pop	bp

	; Make sure all the sub-items sitting underneath us are built out
	; as well.

if _MAC		; START MAC specific code -------------------------------------
	; need to call the superclass here to get our window created, etc.
	push	bp
	mov	ax, MSG_SPEC_BUILD
	mov	di, offset OLMenuBarClass
	CallSuper	MSG_SPEC_BUILD
	pop	bp
endif		; END MAC specific code ---------------------------------------
	
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

if _MAC		; START MAC specific code -------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuBarSetVisParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the visual parent for a menu bar

CALLED BY:	MSG_OL_CTRL_SET_VIS_PARENT
PASS:		*ds:si	= OLMenuBar object
		^lcx:dx	= vis parent for the object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Menu bars for GenPrimary objects (or subclasses of GenPrimary)
		get visually reparented to the field

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLMenuBarSetVisParent	method	OLMenuBarClass, MSG_OL_CTRL_SET_VIS_PARENT
		.enter
	;
	; See if the passed Vis parent is a primary. If so, we switch it to be
	; the field on which the primary sits instead.
	;
		cmp	cx, ds:[LMBH_handle]
		jne	callSuper

		push	si, es, di
		segmov	es, <segment GenPrimaryClass>, di
		mov	di, offset GenPrimaryClass
		mov	si, dx
		call	ObjIsObjectInClass
		pop	si, es, di
		jnc	callSuper
		call	MBBuild_DerefVisSpecDI
		ornf	ds:[di].OLMBAR_state, mask OLMBARS_UNDER_PRIMARY

	;
	; Passed Vis parent is a primary, so locate the field under which it
	; is sitting and use that as our Vis parent instead.
	;
		push	ax, si, bp
		mov	ax, MSG_SPEC_GUP_QUERY
		mov	bx, cx			; ^lbx:si <- primary
		mov	si, dx
		mov	cx, GUQT_FIELD
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	ax, si, bp
		
callSuper:
		mov	di, offset OLMenuBarClass
		CallSuper	MSG_OL_CTRL_SET_VIS_PARENT
		.leave
		ret
OLMenuBarSetVisParent	endp

endif		; END MAC specific code ----------------------------------------





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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuBarRemoveFromNotifyKeyboardEventList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove from GCN list.

CALLED BY:	MSG_SPEC_UNBUILD

PASS:		*ds:si	= OLMenuBarClass object
		ds:di	= OLMenuBarClass instance data
		bp	= SpecBuildFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

OLMenuBarRemoveFromNotifyKeyboardEventList method dynamic OLMenuBarClass, 
					MSG_SPEC_UNBUILD_BRANCH,
					MSG_VIS_CLOSE
		push	ax
		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; ^lcx:dx = self optr
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_NOTIFY_KEYBOARD_EVENT
		call	GCNListRemove
if 0
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, MGCNLT_ACTIVE_LIST
		call	GCNListRemove
endif
		pop	ax
		mov	di, offset OLMenuBarClass
		GOTO	ObjCallSuperNoLock
OLMenuBarRemoveFromNotifyKeyboardEventList	endm

endif	; _JEDIMOTIF ----------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuBarNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle sticky-key notifications...

CALLED BY:	MSG_META_NOTIFY

PASS:		*ds:si	= OLMenuBarClass object
		ds:di	= OLMenuBarClass instance data
		bx	= ManufID
		ax	= list
		bp	= data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

OLMenuBarNotify	method dynamic OLMenuBarClass, 
					MSG_META_NOTIFY
		uses	ax, cx, dx, bp
		.enter
	;
	;  If it's not our list, bail.
	;
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	bail
		cmp	dx, GWNT_KEYBOARD_EVENT
		jne	bail
	;
	;  It's our list -- set or clear the bits in instance
	;  data and redraw ourselves.
	;
		mov	dx, size VisAddRectParams
		sub	sp, dx
		mov	bp, sp
	;
	;  Left & top are OK.
	;
		mov	ax, ds:[di].VI_bounds.R_left
		mov	ss:[bp].VARP_bounds.R_left, ax

		mov	bx, ds:[di].VI_bounds.R_top
		mov	ss:[bp].VARP_bounds.R_top, bx
	;
	;  Right and bottom are offsets from the left & top.
	;
		add	ax, STICKY_AREA_WIDTH
		mov	ss:[bp].VARP_bounds.R_right, ax

		add	bx, STICKY_AREA_HEIGHT
		mov	ss:[bp].VARP_bounds.R_bottom, bx

		clr	ss:[bp].VARP_flags
		mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
		call	ObjCallInstanceNoLock
		add	sp, size VisAddRectParams
bail:
		.leave
		mov	di, offset OLMenuBarClass
		GOTO	ObjCallSuperNoLock
OLMenuBarNotify	endm

endif	; _JEDIMOTIF-----------------------------------------------------------


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
PMAN <	segmov	es, dgroup, cx					>
	mov	bp, MENU_BAR_TOP_MARGIN
	mov	cx, MENU_BAR_RIGHT_MARGIN
	mov	dx, MENU_BAR_BOTTOM_MARGIN

if (not _RUDY)	; no adjustments needed for Rudy
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
PMAN <	test	es:[moCS_flags], mask CSF_BW			>
PMAN <	jz	10$			;skip if is color display...	>
PMAN <	;in CGA, we overlap the header, so we need top margin -cbh 2/15/92 >
PMAN <	call	OpenCheckIfCGA		;CHECK CGA FOR CUA LOOK		>
PMAN <	jc	10$							>
PMAN <	;black & white display: if Motif, set for 0 pixel margin at top,>
PMAN <	;since we don't have etched lines.				>
PMAN <	dec	bp			;else we don't need a top margin>
PMAN <	;same with left margin - brianc 2/14/92  (we need margin back 2/15/92)
PMAN <	dec	ax			;else we don't need a left margin>
PMAN <10$:								>
endif

	;
	;  This is really ugly.  I should fix this.  -stevey
	;
JEDI <		inc	dx						>
JEDI <		inc	ax						>

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
PMAN <	mov	dl, ah				; Pass Display type in dl >
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
PMAN <	push	es						>
PMAN <	segmov	es, dgroup, cx					>
PMAN <	test	es:[moCS_flags], mask CSF_BW			>
PMAN <	pop	es						>
PMAN <	jz	10$			;skip if is color display...	>
PMAN <	;black & white display: if Motif, set for 0 pixel margin at top,>
PMAN <	;since we don't have etched lines.				>
PMAN <	sub	bx, (MENU_BAR_TOP_MARGIN+ 1)				>
PMAN <10$:								>
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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawStickyKeyArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw sticky-key indicator.

CALLED BY:	OLMenuBarDraw

PASS:		ds:si	= OLMBAR instance datan
		di	= gstate

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

DrawStickyKeyArea	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	;  Get various pointers set up.
	;
		call	VisGetBounds		; (ax, bx) (cx, dx)

		segmov	ds, dgroup, cx
		mov	cl, ds:[stickyState]

FXIP <		push	ax, bx			; save top, left	>
FXIP <		mov	bx, handle DrawBWRegions			>
FXIP <		call	MemLock						>
FXIP <		mov	ds, ax						>
FXIP <		mov	bp, bx			; save handle		>
FXIP <		pop	ax, bx			; restore top, left	>
FXIP <		push	bp						>

NOFXIP <	segmov	ds, cs, dx					>
	;
	;  Draw or erase each sticky indicator.
	;
		mov	bp, (NUM_STICKY_KEY_INDICATORS-1) * 2	; word tables
		clr	dx					; no callback
stickyLoop:
		mov	si, offset stickyBlankBitmap		; assume erase
		test	cx, {word}cs:[maskTable][bp]		; bit set?
		jz	drawIt

		mov	si, {word}cs:[bitmapTable][bp]
drawIt:
	;
	;  Since we're out of registers and I don't feel like rewriting
	;  this to use local variables, we'll keep (ax, bx) as the menu
	;  bar's (top, left) coordinates, except immediately around
	;  the draw.
	;
		add	ax, {word}cs:[xOffsetTable][bp]
		add	bx, {word}cs:[yOffsetTable][bp]
		call	GrDrawBitmap
		sub	ax, {word}cs:[xOffsetTable][bp]
		sub	bx, {word}cs:[yOffsetTable][bp]
	;
	;  Loop to next indicator.
	;
		dec	bp
		dec	bp
		cmp	bp, 0
		jge	stickyLoop

FXIP <		pop	bx						>
FXIP <		call	MemUnlock					>

		.leave
		ret

xOffsetTable	word	\
	ALT_KEY_X_OFFSET,
	FN_KEY_X_OFFSET,
	SHIFT_KEY_X_OFFSET,
	CAPS_KEY_X_OFFSET

yOffsetTable	word	\
	ALT_KEY_Y_OFFSET,
	FN_KEY_Y_OFFSET,
	SHIFT_KEY_Y_OFFSET,
	CAPS_KEY_Y_OFFSET

maskTable	word	\
	mask	TS_ALTSTICK,
	mask	TS_FNCTSTICK,
	mask	TS_SHIFTSTICK,
	mask	TS_CAPSLOCK

bitmapTable	word	\
	offset	stickyAltBitmap,
	offset	stickyFuncBitmap,
	offset	stickyShiftBitmap,
	offset	stickyCapsBitmap

DrawStickyKeyArea	endp

FXIP <  MenuBarCommon	ends						>
FXIP <	DrawBWRegions	segment	resource				>

stickyBlankBitmap	label	byte
	Bitmap < 5, 7, BMC_UNCOMPACTED, <BMF_MONO> >
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

stickyAltBitmap		label	byte
	Bitmap < 5, 7, BMC_UNCOMPACTED, <BMF_MONO> >
	db	11111000b
	db	10001000b
	db	10101000b
	db	10001000b
	db	10101000b
	db	10101000b
	db	11111000b
	db	00000000b

stickyFuncBitmap	label	byte
	Bitmap < 5, 7, BMC_UNCOMPACTED, <BMF_MONO> >
	db	11111000b
	db	10001000b
	db	10111000b
	db	10001000b
	db	10111000b
	db	10111000b
	db	11111000b
	db	00000000b

stickyShiftBitmap	label	byte
	Bitmap < 5, 7, BMC_UNCOMPACTED, <BMF_MONO> >
	db	00100000b
	db	01110000b
	db	11111000b
	db	01110000b
	db	01110000b
	db	01110000b
	db	00000000b
	db	00000000b

stickyCapsBitmap	label	byte
	Bitmap < 5, 7, BMC_UNCOMPACTED, <BMF_MONO> >
	db	00100000b
	db	00100000b
	db	01110000b
	db	01110000b
	db	11111000b
	db	11111000b
	db	00000000b
	db	00000000b

FXIP <  DrawBWRegions	ends						>
FXIP <	MenuBarCommon	segment	resource				>

endif		; JEDIMOTIF ----------------------------------------------------

endif		;CUA_STYLE -----------------------------------------------------

endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorOrBWMenuBar

DESCRIPTION:	Draw an Motif/CUA/PM menu bar on a B&W or color display.

CALLED BY:	OLMenuBarDraw

PASS:
	*ds:si - instance data
	cl - color scheme
	ch - DrawFlags:  DF_EXPOSED set if updating
	dl - Display type
	di - GState to use

RETURN:
	carry - set

DESTROYED:
	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if _CUA or _MAC ;-------------------------------------------------
   
.assert (@CurSeg eq CommonFunctional)	;used for both B&W and color!!!

DrawColorOrBWMenuBar	proc	far
	class	OLMenuBarClass
	
if _JEDIMOTIF
	;
	;  If DF_EXPOSED is not set, then we'll assume we're trying
	;  to redraw the sticky keys.
	;
	test	cl, mask DF_EXPOSED
	jnz	doneSticky

	call	DrawStickyKeyArea
	jmp	done
doneSticky:
endif
	push	dx, si, ds
MO <	cmp	dl, DC_GRAY_1		;B&W display?			>
MO <	pushf								>
PMAN <	cmp	dl, DC_GRAY_1		;B&W display?			>
PMAN <	pushf								>

	;
	; CUA/Motif: grab color value from color scheme variables in idata
	;
	push	ds
	mov	ax, segment idata	;get segment of core blk
	mov	ds, ax
	clr	ah
	mov	al, ds:[moCS_menuBar]
	call	GrSetAreaColor

	mov	al, ds:[moCS_windowFrame]
	call	GrSetLineColor
	pop	ds

	;
	; get the visible bounds for this menu bar
	;
	call	OpenGetLineBounds

	;
	; CUA: The menu bar overlaps the line border of the GenPrimary,
	; so we don't want to erase the far left or far right pixel columns.
	; BUT: the left-most menu button will draw and erase its border on
	; this pixel column, so let's go ahead and draw a black line on the
	; left side, in case the button has just erased this area.
	;
if _CUA_STYLE and (not _MOTIF) and (not _PM)	;-------------------------------
	call	GrDrawVLine		;draw vertical line on left side
	inc	ax			;assume window has LINE_BORDER,
	dec	cx			;move in on sides
endif		;--------------------------------------------------------------

	push	bx			;can assume top line drawn,
	mov	bx, dx			;so only draw bottom line
	call	GrDrawHLine		;pass coords, di=gstate
	pop	bx

if _MOTIF or _PM;---------------------------------------------------------------
	popf				;Recover display type test flag
	je	10$			;skip if is B&W...

	;
	; Is color Motif: draw the etch lines.
	;
	push	ax
	mov	ax, cx
	call	GrDrawVLine		;Draw rest of the bottom/right
	mov	ax, C_WHITE		;Color: "raised" frame
	call	GrSetLineColor
	pop	ax
	dec	dx			;don't draw bottom pixel
	dec	cx			;or rightmost pixel
	call	GrDrawHLine		;Draw the top/left edge
	call	GrDrawVLine
	inc	dx			;makes up for above dec
	inc	ax
10$:
endif	; _MOTIF or _PM --------------------------------------------------------

	inc	bx			;move inside top and bottom
	inc	cx			;but adjust for fills, too
	call	GrFillRect

	mov	ax, C_BLACK
	call	GrSetLineColor
	call	GrSetAreaColor
	pop	dx, si, ds

	ret
DrawColorOrBWMenuBar	endp

endif	; CUA_STYLE ------------------------------------------------------------

if 	not NO_MENU_BAR_DRAWING		
if	_MOTIF or _PM
	
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
   	dec	ax				;left
	inc	cx				;right
10$:								  

if _JEDIMOTIF
	call	DrawHorizontalLineSegments
	call	DrawStickyKeyArea
endif

if not _JEDIMOTIF
	call	OpenDrawRect
endif
done::
	ret			
DrawColorOrBWMenuBar	endp

endif
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHorizontalLineSegments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw horizontal line segments

CALLED BY:	DrawColorOrBWMenuBar

PASS:		*ds:si	= menu bar
		di	= gstate

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/29/94    	Initial version
	stevey	10/21/94	changed to have Comp draw lines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------

DrawHorizontalLineSegments	proc	near
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Set up the gstate.
	;
		mov	ax, (CF_INDEX shl 8) or C_WHITE
		call	GrSetAreaColor

		mov	ax, (CF_INDEX shl 8) or C_BLACK
		call	GrSetLineColor
	;
	;  Until proven wrong, I'll assume this happens before
	;  the child buttons draw, and just draw the whole line
	;  all the way across.
	;
		call	VisGetBounds		; (ax,bx) (cx,dx)
		push	bx			; save top
		add	bx, dx
		shr	bx			; bx = midpoint top-bottom

		add	ax, 20			; sneak under left button
		sub	cx, 20			; sneak under right button

		call	GrDrawHLine		; draw top half
		inc	bx
		call	GrDrawHLine		; make it 2 pixels tall
	;
	;  Now draw 5 blank buttons, in case there are empty slots.
	;  First set up loop variables.
	;
		clr	bp			; start at 1st slot
		mov	si, MENU_BAR_BUTTON_RADIUS
	;
	;  The top & bottom of coords each button are the same.
	;  Set them up now.  Note that GrDrawRoundRect requires
	;  parameters to be squished in by 1 pixel for it to draw
	;  correctly.
	;
		pop	bx					; bx = top
		inc	bx					; move down
		inc	bx					; once again
		mov	dx, bx
		add	dx, JEDI_MENU_BAR_BUTTON_HEIGHT-2	; dx = bottom
buttonLoop:
	;
	;  Load the next button from a table.  We happen to have
	;  the x-offsets defined in a table below; we don't need
	;  the first entry in the table so we skip it.
	;
		mov	ax, {word}cs:[jediPositionTable][bp]	; ax = left
		mov	cx, ax					; not mov_tr!!
		add	cx, JEDI_MENU_BAR_BUTTON_WIDTH-2	; cx = right
		call	GrFillRect
		call	GrDrawRoundRect

		inc	bp
		inc	bp
		cmp	bp, MENU_BAR_NUMBER_OF_SLOTS * 2
		jbe	buttonLoop

		.leave
		ret
DrawHorizontalLineSegments	endp

endif	; _JEDIMOTIF ----------------------------------------------------------


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

if _JEDIMOTIF
	;
	;  Menu bar is fixed-height on the Jedi; we can't use
	;  the height returned by OpenRecalcCtrlSize because if
	;  there are more than 5 menu-bar items, the height will
	;  be some multiple of the correct value.
	;
	mov	dx, JEDI_MENU_BAR_HEIGHT
endif

if _RUDY
	;
	;  Menu bar is fixed-height on the Rudy too; we can't use
	;  the height returned by OpenRecalcCtrlSize because if
	;  there are more than 4 menu-bar items.
	;
	;  Include top/bottom margins as well -- brianc 2/16/96
	;
	mov	dx, RUDY_MENU_BAR_HEIGHT + RUDY_SLOT_TOP_MARGIN*2
endif
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

if _JEDIMOTIF
	;
	;  Turn off geometry management during the position.  We
	;  do the VisCompPosition in Jedi for the benefit of sizing
	;  the children properly.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
endif
	call	VisCompPosition

if _JEDIMOTIF
	;
	;  Turn management back on (for later) but position children
	;  manually.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VCI_geoAttrs, not mask VCGA_CUSTOM_MANAGE_CHILDREN

	call	PositionChildren
endif
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

if _JEDIMOTIF
jediFunctionKeyTable	word \
	SLOT_1_X_OFFSET + MENU_BAR_BUTTON_WIDTH/2,
	SLOT_2_X_OFFSET + MENU_BAR_BUTTON_WIDTH/2,
	SLOT_3_X_OFFSET + MENU_BAR_BUTTON_WIDTH/2,
	SLOT_4_X_OFFSET + MENU_BAR_BUTTON_WIDTH/2,
	SLOT_5_X_OFFSET + MENU_BAR_BUTTON_WIDTH/2,
	SLOT_6_X_OFFSET + APP_MENU_BUTTON_WIDTH/2
endif
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuBarActivateTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Activate a menu-bar button.

CALLED BY:	MSG_OL_MENU_BAR_ACTIVATE_TRIGGER

PASS:		*ds:si	= OLMenuBarClass object
		ds:di	= OLMenuBarClass instance data
		cx	- child to activate, if possible

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF and FUNCTION_KEYS_MAPPED_TO_MENU_BAR_BUTTONS

OLMenuBarActivateTrigger	method static OLMenuBarClass, \
					MSG_OL_MENU_BAR_ACTIVATE_TRIGGER
	;
	;  Convert CX to the center of the child to activate,
	;  from a table.
	;
		mov	bx, cx
		shl	bx			; word-entry table
		mov	cx, {word}cs:[jediFunctionKeyTable][bx]
		mov	dx, JEDI_MENU_BAR_BUTTON_HEIGHT/2 + \
				MENU_BAR_BUTTON_Y_OFFSET
	;
	;  Adjust to parent's bounds.
	;
		add	cx, ds:[di].VI_bounds.R_left
		add	dx, ds:[di].VI_bounds.R_top
	;
	;  Find child at position (cx, dx) and activate it.
	;
		mov	ax, MSG_META_GET_OPTR
		call	VisCallChildUnderPoint	; ^lcx:dx = child
		jnc	done			; no child
		push	si			; save menu bar
		movdw	bxsi, cxdx		; ^lbx:si = child
		mov	cx, segment OLMenuButtonClass
		mov	dx, offset OLMenuButtonClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; carry set if so
		pop	dx			; *ds:dx = menu bar
		mov	ax, MSG_OL_MENU_BUTTON_TOGGLE_ACTIVATE	; assume so
		jc	haveAction		; is menu button
		call	closeMenus
		mov	ax, MSG_GEN_ACTIVATE	; not menu butotn
haveAction:
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		ret

;
; *ds:dx = menu bar
; ^lbx:si = menu button
;
closeMenus	label	near
	push	bx, si			; save menu button
	mov	ax, MSG_OL_MENU_BUTTON_CLOSE_MENU
	mov	bx, segment OLMenuButtonClass
	mov	si, offset OLMenuButtonClass
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	mov	cx, di			; cx = event
	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	mov	si, dx			; *ds:si = menu bar
	call	ObjCallInstanceNoLock
	pop	bx, si			; ^lbx:si = menu button
	retn
OLMenuBarActivateTrigger	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuBarActivateTrigger -- 
		MSG_OL_MENU_BAR_ACTIVATE_TRIGGER for OLMenuBarClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Activates a trigger.

PASS:		*ds:si 	- instance data
		es     	- segment of OLMenuBarClass
		ax 	- MSG_OL_MENU_BAR_ACTIVATE_TRIGGER
		cx	- child to activate, if possible

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/ 9/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY and FUNCTION_KEYS_MAPPED_TO_MENU_BAR_BUTTONS

OLMenuBarActivateTrigger	method static OLMenuBarClass, \
				MSG_OL_MENU_BAR_ACTIVATE_TRIGGER
	.enter

;	Convert CX from an index to an offset to where the middle of the
;	associated button should be - we then send the message to the button
;	whose bounds overlap that offset - we do this because buttons in
;	different dialog boxes will be at slightly different positions, so
;	we can't just use the upper bounds of the triggers.

	mov	al, RUDY_RIGHT_BUTTON_HEIGHT + MENU_BAR_BETWEEN_LINES
	mul 	cl
	clr	ah
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	ax, ds:[di].VI_bounds.R_top
	add	ax, RUDY_RIGHT_BUTTON_HEIGHT/2

	clr	bx		; Pass 0 to start at the 0th child
	push	bx
	push	bx

	mov	bx, offset VI_link
	push	bx
NOFXIP <push	cs							>
FXIP <	mov	bx, SEGMENT_CS						>
FXIP <	push	bx							>
      	mov	bx, offset CallMenuBarTriggerCallback
	push	bx
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompProcessChildren

	.leave
	ret
OLMenuBarActivateTrigger	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallMenuBarTriggerCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Activates the correct trigger, as specified by the passed
		index

CALLED BY:	GLOBAL
PASS:		*ds:si - child
		ax - position within trigger that we want to activate

RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallMenuBarTriggerCallback	proc	far	
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ax, ds:[di].VI_bounds.R_top
	jb	next
	cmp	ax, ds:[di].VI_bounds.R_bottom
	ja	next

	mov	ax, MSG_GEN_ACTIVATE
	call	ObjCallInstanceNoLock
	stc
exit:
	.leave
	ret
next:
	clc
	jmp	exit
CallMenuBarTriggerCallback	endp

endif	; FUNCTION_KEYS_MAPPED_TO_MENU_BAR_BUTTONS ----------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLMenuBarAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Order children properly

CALLED BY:	MSG_VIS_ADD_CHILD

PASS:		*ds:si	= OLMenuBarClass object
		ds:di	= OLMenuBarClass instance data
		^lcx:dx	= child to add
		bp	= CompChildFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- add child normally
	- move glyph (if any) to front
	- move app menu (if any) to back

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	We can safely assume that the only GenGlyph in the menu
	bar is the sticky-key indicator, since the only way for
	a GenGlyph to get into the menu bar is for it to have 
	SA_CUSTOM_VIS_PARENT set, and programmers can't set that
	bit in a GenGlyph (they can after it's built, but by then
	it's too late).

	(sticky-glyph stuff removed, 12/16/94 -- left structure
	of this routine intact in case more special kids arrive
	later).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF	;--------------------------------------------------------------
OLMenuBarAddChild	method dynamic OLMenuBarClass, 
					MSG_VIS_ADD_CHILD
		uses	cx, dx, bp
		.enter
	;
	;  Add the child as requested.
	;
		mov	di, offset OLMenuBarClass	; es:di = class
		call	ObjCallSuperNoLock
	;
	;  If there is an app menu, move it to the end.
	;
		clr	bx			; initial child (first one)
		push	bx
		push	bx
		mov	bx, offset VI_link	;vis children
		push	bx
NOFXIP <	push	cs			; callback segment	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx			; XIP callback segment	>
		mov	bx, offset FindAndMoveAppMenuChild
		push	bx			; callback offset
		mov	bx, offset Vis_offset	; master offset
		mov	di, offset VCI_comp	; composite offset
		call	ObjCompProcessChildren
done:
		.leave
		ret
OLMenuBarAddChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindAndMoveAppMenuChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find App Menu button and move to last child pos

CALLED BY:	OLMenuBarAddChild via ObjCompProcessChildren
PASS:		*ds:si - child
		*es:di - composite
RETURN:		carry set if found, stops enumeration
		carry clear otherwise
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindAndMoveAppMenuChild	proc	far
	push	es, di
	mov	di, segment OLMenuButtonClass
	mov	es, di
	mov	di, offset OLMenuButtonClass
	call	ObjIsObjectInClass
	pop	es, di
	jnc	done				; not found, next child
	mov	ax, TEMP_OL_BUTTON_APP_MENU_BUTTON
	call	ObjVarFindData			; carry set if found
	jnc	done				; not found, next child
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = child
	mov	dx, si
	segmov	ds, es				; *ds:si = composite
	mov	si, di
	mov	ax, MSG_VIS_MOVE_CHILD
	mov	bp, CCO_LAST			; move to lasst position
	call	ObjCallInstanceNoLock
	stc					; indicate found
done:
	ret
FindAndMoveAppMenuChild	endp


endif	; _JEDIMOTIF	;------------------------------------------------------

CommonFunctional	ends
