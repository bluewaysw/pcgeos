COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		copenMenuItemGroup.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLMenuItemGroupClass	menu item group class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial coding

DESCRIPTION:

	$Id: copenMenuItemGroup.asm,v 2.47 96/09/24 20:48:02 brianc Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLMenuItemGroupClass		mask CLASSF_DISCARD_ON_SAVE or mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


;---------------------------------------------------

MenuBuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupInitialize -- MSG_META_INITIALIZE for
		OLMenuItemGroupClass

DESCRIPTION:	Initialize an MO Menu Bar class instance

PASS:
	*ds:si - instance data
	es - segment of OLMenuItemGroupClass

	ax - MSG_META_INITIALIZE

	cx, dx, bp	- ?

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
	Eric	7/89		Initial version

------------------------------------------------------------------------------@


OLMenuItemGroupInitialize	method	OLMenuItemGroupClass, MSG_META_INITIALIZE
					;Make sure vis built out

	ORNF	ds:[di].OLMIGI_specState, mask OLMIGSS_SEPARATORS

	;now call superclass (OLCtrlClass) to process hints that can
	;override this geometry

	call	OLCtrlInitialize
	
	;force the default SpecBuild handler to send a MSG_SPEC_GET_VIS_PARENT
	;to this object when looking for a visible parent to attach it to.
	;(Do not want to just use generic parent, because this group may have
	;been adopted to a different menu.)

	call	MB_DerefVisSpecDI
	ORNF	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT

	;Process hints for this object

if _ODIE
	;
	; never use menu seperators for ODIE
	;
	ANDNF	ds:[di].OLMIGI_specState, not (mask OLMIGSS_SEPARATORS)
else
	segmov	es, cs				;setup es:di to be ptr to
						;Hint handler table
	mov	di, offset cs:OLMenuItemGroupHintHandlers
	mov	ax, length (cs:OLMenuItemGroupHintHandlers)
	call	ObjVarScanData
endif
	ret

OLMenuItemGroupInitialize	endp

;Hint handler table

if (not _ODIE)
OLMenuItemGroupHintHandlers	VarDataHandler \
	<HINT_SAME_CATEGORY_AS_PARENT, offset MenuBuild:HintNoSeparators>

HintNoSeparators	proc	far
	call	MB_DerefVisSpecDI
	ANDNF	ds:[di].OLMIGI_specState, not (mask OLMIGSS_SEPARATORS)
	ret
HintNoSeparators	endp
endif

MB_DerefVisSpecDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret	
MB_DerefVisSpecDI	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupSpecBuild -- 
		MSG_SPEC_BUILD for OLMenuItemGroupClass

DESCRIPTION:	Vis build for the menu item group.  Subclassed here to force
		the menu item group to always be visually enabled.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD
		bp	- SpecBuildFlags

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/21/90		Initial version

------------------------------------------------------------------------------@

OLMenuItemGroupSpecBuild	method OLMenuItemGroupClass, MSG_SPEC_BUILD
	mov	di, offset OLMenuItemGroupClass
	call	ObjCallSuperNoLock
	
	mov	di, ds:[si]			;force to be fully enabled
	add	di, ds:[di].Vis_offset
	or	ds:[di].VI_attrs, mask VA_FULLY_ENABLED	
	ret
OLMenuItemGroupSpecBuild	endm




	

COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupGetVisParent

DESCRIPTION:	Returns visual parent for this generic object

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_SPEC_GET_VIS_PARENT

	cx - ?
	dx - ?
	bp - SpecBuildFlags
		mask SBF_WIN_GROUP	- set if building win group

RETURN:
	carry - set
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
	Eric	12/89		Initial version

------------------------------------------------------------------------------@


OLMenuItemGroupGetVisParent	method	dynamic OLMenuItemGroupClass, \
						 MSG_SPEC_GET_VIS_PARENT
	;grab vis parent info from the BUILD_INFO query that we ran during the
	;generic->specific build of this object (see cspecInteraction.asm).

	mov	cx, ds:[di].OLCI_visParent.handle	;bx:si = parent
	mov	dx, ds:[di].OLCI_visParent.chunk
	stc
	ret
OLMenuItemGroupGetVisParent	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupGupQuery -- MSG_SPEC_GUP_QUERY
		for OLMenuItemGroupClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLMenuWinClass

	ax - MSG_SPEC_GUP_QUERY
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
	Eric	8/89		Initial version

------------------------------------------------------------------------------@


OLMenuItemGroupGupQuery	method	OLMenuItemGroupClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO		;can we answer this query?
	je	MOMIGGUQ_answer			;skip if so...

	;we can't answer this query: call super class to handle
	mov	di, offset OLCtrlClass
	GOTO	ObjCallSuperNoLock

MOMIGGUQ_answer:
EC <	test	bp, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	or	bp, OLBR_SUB_MENU shl offset OLBF_REPLY
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	stc					;return query acknowledged
	ret

OLMenuItemGroupGupQuery	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuItemGroupSpecChangeUsable -- MSG_SPEC_SET_USABLE,
			 MSG_SPEC_SET_NOT_USABLE handler.

DESCRIPTION:	We intercept this method here to update the separators which
		are drawn within the menu.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLMenuItemGroupSpecChangeUsable method	OLMenuItemGroupClass, \
			 MSG_SPEC_SET_USABLE, MSG_SPEC_SET_NOT_USABLE

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

	push	ax, cx
	mov	di, offset OLMenuItemGroupClass
	call	ObjCallSuperNoLock
	pop	ax, cx

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

	;update separators in this menu

	mov	ax, MSG_SPEC_UPDATE_MENU_SEPARATORS
	call	VisCallParent
	ret
OLMenuItemGroupSpecChangeUsable	endm


MenuBuild ends

;----------------------------------

MenuSepQuery	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuItemGroupSpecMenuSepQuery --
			 MSG_SPEC_MENU_SEP_QUERY handler

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

OLMenuItemGroupSpecMenuSepQuery	method	OLMenuItemGroupClass, \
						 MSG_SPEC_MENU_SEP_QUERY
EC<	call	VisCheckVisAssumption	;Make sure vis data exists >
EC<	call	GenCheckGenAssumption	;Make sure gen data exists >

	;see if this group is GS_USABLE

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	LONG	jz notUsable		;skip if not...

	;let's make sure is really usable: some menuItemGroups (pin group)
	;are USABLE and ENABLED, but not DRAWABLE.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	LONG jz	notUsable

isUsable:
	;see which case this is: were we called from sibling/parent, or child?

	test	ch, mask MSF_FROM_CHILD
	jnz	fromChild		;skip if called from child

fromSibling:
	;this method was sent by the previous sibling or the parent of this
	;object. First save the current TOP and BOTTOM separator status.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bl, ds:[di].OLMIGI_specState
	push	bx
	ANDNF	ds:[di].OLMIGI_specState, not (mask OLMIGSS_BOTTOM_SEP or \
						 mask OLMIGSS_TOP_SEP)

	;now save the SEP and USABLE status for this level, and
	;send query to first child, to see if any children are usable.

	mov	bh, ch
	ANDNF	bh, mask MSF_SEP or mask MSF_USABLE
	ANDNF	ds:[di].OLMIGI_specState, not (mask OLMIGSS_ABOVE_SEP or \
						 mask OLMIGSS_ABOVE_USABLE)
	ORNF	ds:[di].OLMIGI_specState, bh

	ANDNF	ch, not (mask MSF_SEP or mask MSF_USABLE)
					 ;init for traversal of kids: no
					 ;usable child yet, do not draw sep
					 ;because your parent will.

	call	ForwardMenuSepQueryToFirstChildOrSelf
					 ;forwards query through remainder of
					 ;menu. Returns flags.

fromSiblingReturning:
	;un-recursing: if have usable kids and MSF_SEP was set when the
	;query first arrived at this node, then we need a top separator.
	;Then return info so that objects above us in the menu can decide
	;whether they need bottom separators.  (Code changed a little bit.
	;Now, when the group doesn't have any usable children, we'll preserve
	;the SEP flag coming back from the siblings below.  The thing is, if
	;the item group has no children, we want to pretend like it's not
	;even there.  The old code, with automatically set the SEP flag when
	;returning in this case, caused a double border (a bottom sep on the
	;interaction above, a top sep on the interaction below).  I don't
	;know about the no ABOVE_SEP case, so I'll leave it alone. -cbh 11/27/92

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMIGI_specState, mask OLMIGSS_HAS_USABLE_CHILD
	jz	15$

	test	ds:[di].OLMIGI_specState, mask OLMIGSS_ABOVE_SEP
	jz	10$

	ORNF	ds:[di].OLMIGI_specState, mask OLMIGSS_TOP_SEP
	ANDNF	ch, not (mask MSF_SEP)	;objects above do not need sep below.
	jmp	short 15$

10$:	;this composite is usable, but does not have a top separator.
	;Objects above will need one.

	ORNF	ch, mask MSF_SEP

15$:	;finish up for "fromSibling" case: if TOP or BOTTOM separators have
	;changed state, mark this object invalid so menu will redo geometry.

	pop	bx
	xor	bl, ds:[di].OLMIGI_specState
	test	bl, mask OLMIGSS_TOP_SEP or mask OLMIGSS_BOTTOM_SEP
	jz	19$			;skip if not change...

	push	cx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	cl, mask VOF_GEOMETRY_INVALID
	call	VisMarkInvalid		;does not trash ax
	pop	cx

19$:	;return with carry set
	stc
	ret

fromChild:
	;this method was sent by the last child of this object. Store the
	;computed HAS_USABLE_CHILD status for later.

	ANDNF	ch, not (mask MSF_FROM_CHILD)	;reset flag

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ch, mask MSF_USABLE
	jz	fromChildNoUsableKids

	ORNF	ds:[di].OLMIGI_specState, mask OLMIGSS_HAS_USABLE_CHILD

	;Pass separator info on to next object in menu (USABLE = TRUE)

	call	ForwardMenuSepQueryToNextSiblingOrParent

fromChildReturning:
	;now we are travelling back up the menu: see if a separator should
	;be drawn below this object.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ch, mask MSF_SEP	;test flag from lower objects in menu
	jz	20$

	ORNF	ds:[di].OLMIGI_specState, mask OLMIGSS_BOTTOM_SEP
	ANDNF	ch, not (mask MSF_SEP)

20$:
	stc
	ret

fromChildNoUsableKids:
	;this method was sent by the last child of this object, and there
	;are no usable kids. Restore the MSF_SEP and MSF_USABLE flags as
	;they were before, so the method can continue as if this composite
	;never even existed.

	ANDNF	ds:[di].OLMIGI_specState, not (mask OLMIGSS_HAS_USABLE_CHILD)

	mov	bh, ds:[di].OLMIGI_specState
	ANDNF	bh, mask OLMIGSS_ABOVE_SEP or mask OLMIGSS_ABOVE_USABLE

	ANDNF	ch, not (mask MSF_SEP or mask MSF_USABLE)
	ORNF	ch, bh

	;Pass separator and usable info on to next object in menu

	call	ForwardMenuSepQueryToNextSiblingOrParent

fromChildNoUsableKidsReturning:
	;now we are travelling back up the menu: since this object has no
	;usable kids, preserve returned flags

	ret

;SAVE BYTES (after debugging)

notUsable:
	;this object is not usable: pass the SEP and USABLE flags as is,
	;and return them as is.

	call	ForwardMenuSepQueryToNextSiblingOrParent
	ret
OLMenuItemGroupSpecMenuSepQuery endm


ForwardMenuSepQueryToFirstChildOrSelf	proc	near
	call	VisCallFirstChild
	jc	done			;skip if called child (which sent
					 ;to siblings and then back to this
					 ;object with MSF_FROM_CHILD set)

	;no visible children: simulate what would happen if we had
	;one not-usable child.

	ORNF	ch, mask MSF_FROM_CHILD
	call	ObjCallInstanceNoLock	;call self.

done:
	ret
ForwardMenuSepQueryToFirstChildOrSelf	endp

MenuSepQuery	ends



Geometry segment resource






COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLMenuItemGroupClass

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

OLMenuItemGroupRecalcSize	method dynamic OLMenuItemGroupClass, MSG_VIS_RECALC_SIZE
	call	MenuItemGroupPassMarginInfo
	call	OpenRecalcCtrlSize
	ret
OLMenuItemGroupRecalcSize	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupVisPositionBranch -- 
		MSG_VIS_POSITION_BRANCH for OLMenuItemGroupClass

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

OLMenuItemGroupVisPositionBranch	method dynamic	OLMenuItemGroupClass, \
				 MSG_VIS_POSITION_BRANCH

	call	MenuItemGroupPassMarginInfo	
	call	VisCompPosition
	ret
OLMenuItemGroupVisPositionBranch	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	MenuItemGroupPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLMenuItemGroupRecalcSize, OLMenuItemGroupPositionBranch

PASS:		*ds:si -- MenuItemGroup bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

MenuItemGroupPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OLMenuItemGroupGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OLMenuItemGroupGetMargins	;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
MenuItemGroupPassMarginInfo	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupGetSpacing
		-- MSG_VIS_COMP_GET_CHILD_SPACING for OLMenuItemGroupClass

DESCRIPTION:	Returns spacing and margins for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_VIS_COMP_GET_CHILD_SPACING

RETURN:		cx	- spacing between children
		dx	- spacing between lines of wrapped children

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	NOTE: A MENU ITEM GROUP IS A VERTICAL COMPOSITE!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@


OLMenuItemGroupGetSpacing	method	OLMenuItemGroupClass, \
				 MSG_VIS_COMP_GET_CHILD_SPACING
	clr	cx				;no spacing between kids
	clr	dx				;(menu buttons) or between lines


if _MENUS_PINNABLE	;------------------------------------------------------
if _OL_STYLE	;--------------------------------------------------------------

	mov	cx, 1			;assume not pinned, use minimal spacing

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLMIGI_specState, mask OLMIGSS_MENU_PINNED
	jz	haveSpacing		;skip if not pinned...

	mov	cx, OLS_WIN_CHILD_SPACING
					 ;is pinned: return spacing as if was
					 ;standard window.
haveSpacing:
endif		;--------------------------------------------------------------
endif
	ret
OLMenuItemGroupGetSpacing	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupGetMargins
		-- MSG_VIS_COMP_GET_MARGINS for OLMenuItemGroupClass

DESCRIPTION:	Returns margins and margins for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_VIS_COMP_GET_MARGINS

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@


OLMenuItemGroupGetMargins	method	OLMenuItemGroupClass, \
				 MSG_VIS_COMP_GET_MARGINS
	mov	ax, 0				;no left or right margin -
	mov	cx, ax				;menu window handles that
	mov	bp, ax				;assume no separators: no top
	mov	dx, ax				;or bottom margin

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = specificInstance
	test	ds:[di].OLMIGI_specState, mask OLMIGSS_SEPARATORS
	jz	done

	test	ds:[di].OLMIGI_specState, mask OLMIGSS_TOP_SEP
	jz	checkBottomSep			;skip if no top sep...
	call	GetMenuSepHeight		;set in bp

checkBottomSep:
	test	ds:[di].OLMIGI_specState, mask OLMIGSS_BOTTOM_SEP
	jz	done				;skip if no bottom sep...

	xchg	dx, bp
	call	GetMenuSepHeight		;set in dx
	xchg	dx, bp

done:	;set up margins for inside this group, as if we were an OLMenuWin.

if	OL_MENU_ITEM_SEP_HEIGHT gt 1
	call	OpenMinimizeIfCGA		;see if on CGA
	jnc	10$				;no, branch
	shr	bx,1				;else divide bx and bp by 2
	shr	bp,1
10$:
endif
	ret
OLMenuItemGroupGetMargins	endp

GetMenuSepHeight	proc	near
	mov	bp, OL_MENU_ITEM_SEP_HEIGHT
if	_MOTIF
	call	OpenCheckIfBW
	jc	exit
	mov	bp, OL_MENU_ITEM_ETCHED_SEP_HEIGHT
exit:
endif
	ret
GetMenuSepHeight	endp

Geometry ends

;---------------------------------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLMenuItemGroupSetButtonBordered

DESCRIPTION:	This method is sent to GenTriggers within a menu when the
		menu enters or leaves pinned state. We intercept it here
		so that we can update our "PINNED" flag, which affects the
		geometry of this object.

PASS:		ds:*si	- instance data
		ax	- MSG_OL_BUTTON_SET_BORDERED
		cx 	- TRUE / FALSE

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

if _OL_STYLE	;--------------------------------------------------------------

OLMenuItemGroupSetButtonBordered	method	OLMenuItemGroupClass, \
						MSG_OL_BUTTON_SET_BORDERED
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ANDNF	ds:[di].OLMIGI_specState, not (mask OLMIGSS_MENU_PINNED)

	tst	cx
	jz	callSuper

	ORNF	ds:[di].OLMIGI_specState, mask OLMIGSS_MENU_PINNED

callSuper:
	mov	di, offset OLMenuItemGroupClass
	GOTO	ObjCallSuperNoLock
OLMenuItemGroupSetButtonBordered	endm

endif 		;--------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupDraw -- MSG_VIS_DRAW for OLMenuItemGroupClass

DESCRIPTION:	Draw the menu bar

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_VIS_DRAW

	cl - DrawFlags:  DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState to use

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
	Draw the top and bottom separators if necessary.
	Assume the menu window will draw the background.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@


OLMenuItemGroupDraw	method	OLMenuItemGroupClass, MSG_VIS_DRAW
	push	ax, bp, si, es, cx, dx

	segmov	es, ds
EC<	call	VisCheckVisAssumption	;Make sure vis data exists >
EC<	call	GenCheckGenAssumption	;Make sure gen data exists >

	;get display scheme data

	mov	di, bp			;put GState in di
	push	cx
	mov	ax, GIT_PRIVATE_DATA	;pass di, ax
	call	GrGetInfo		;returns ax, bx, cx, dx
	pop	cx

	;get SpecificState info about MenuItemGroup Object: does
	;it have top and/or bottom separators?

	push	si				;save handle of object
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		;ds:di = specificInstance
	mov	dl, ds:[si].OLMIGI_specState	;get SpecState from instance
	pop	si				;get handle of object

	;al = color scheme, ah = display type, cl = update flag
	;dl = SpecState

	and	ah, mask DF_DISPLAY_TYPE
	cmp	ah, DC_GRAY_1			;B&W display?

	mov	ch, cl				; Pass DrawFlags in ch
	mov	cl, al				; Pass color scheme in cl
						; (ax & bx get trashed)

;NOTE: ERIC: Motif is forced to B&W now.
;	jnz	MOMIGD_color			;skip to draw color button...

	;draw black & white button

	CallMod	DrawBWMenuItemGroup
;	jmp	short MOMIGD_common
;
;	;draw color button
;
;MOMIGD_color:
;	CallMod	DrawColorMenuItemGroup

	;both B&W and Color draws finish here:


	pop	ax, bp, si, es, cx, dx
	mov	di, offset OLMenuItemGroupClass
						;set es:di = class to call
						;superclass of.

	call	ObjCallSuperNoLock		;send MSG_VIS_DRAW to OLCtrlClass
						;so will send to kids
	ret

OLMenuItemGroupDraw	endp

CommonFunctional ends

;---------------------------------------------------

;OPT: since this is used for both color and BW, move to CommonFunctional
;- brianc 4/30/92
;DrawBW segment resource
CommonFunctional	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBWMenuItemGroup

DESCRIPTION:	Draw an Motif/PM menu item group on a black and white display

CALLED BY:	OLMenuItemGroupDraw

PASS:
	*ds:si - instance data
	cl - color scheme
	ch - DrawFlags:  DF_EXPOSED set if updating
	di - GState to use
	dl = SpecState

RETURN:
	carry - set

DESTROYED:
	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	Draw the top and bottom separators if necessary.
	Assume the menu window will draw the background.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@


DrawBWMenuItemGroup	proc	far
	class	OLMenuItemGroupClass
	
	push	ds, si

	push	ax				;preserve color scheme
	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax				;get color scheme

EC<	call	VisCheckVisAssumption		;Make sure vis data exists >

	mov	bp, dx				;bp = SpecState
	push	si				;save handle of object
	mov	si, ds:[si]			;ds:si = instance data
	add	si, ds:[si].Vis_offset		;ds:si = VisInstance
	mov	ax, ds:[si].VI_bounds.R_left
	mov	bx, ds:[si].VI_bounds.R_top
	mov	cx, ds:[si].VI_bounds.R_right
	mov	dx, ds:[si].VI_bounds.R_bottom
	dec	cx				;adjust for line drawing
	dec	dx
	pop	si				;get handle of object

	;check on top and bottom separators

	test	bp, mask OLMIGSS_SEPARATORS
	jz	DBWMIG_30

	test	bp, mask OLMIGSS_TOP_SEP
	jz	DBWMIG_20			;skip if no top sep...

	push	bx, dx
OLS <	test	bp, mask OLMIGSS_MENU_PINNED				>
OLS <	jnz	10$							>
OLS <	add	bx, OL_MENU_ITEM_SEP_TOP_INSET_NOT_PINNED		>
OLS <	jmp	short 20$						>
OLS <10$:								>
OLS <	add	bx, OL_MENU_ITEM_SEP_TOP_INSET_PINNED			>
OLS <20$:								>
CUAS <	add	bx, OL_MENU_ITEM_SEP_TOP_INSET				>
CUAS <  push	ax						        >
CUAS <	call	OpenMinimizeIfCGA		;see if on CGA		>
CUAS <	pop	ax							>
CUAS <	jnc	11$				;no, branch		>
CUAS <	sub	bx, OL_MENU_ITEM_SEP_TOP_INSET shr 1			>
CUAS <11$:					;else halve our inset   >
	mov	dx, bx
						;pass di = gstate

if _MOTIF
	clc
	call	DrawEtchedHLine			;draw thin line (in copenCtrl)
else
	call	GrDrawLine
endif
	pop	bx, dx

DBWMIG_20:
	test	bp, mask OLMIGSS_BOTTOM_SEP
	jz	DBWMIG_30			;skip if no top sep...

OLS <	test	bp, mask OLMIGSS_MENU_PINNED				>
OLS <	jnz	30$							>
OLS <	sub	dx, OL_MENU_ITEM_SEP_BOTTOM_INSET_NOT_PINNED		>
OLS <	jmp	short 40$						>
OLS <30$:								>
OLS <	sub	dx, OL_MENU_ITEM_SEP_BOTTOM_INSET_PINNED		>
OLS <40$:								>

CUAS <	sub	dx, OL_MENU_ITEM_SEP_BOTTOM_INSET			>
CUAS <  push	ax						        >
CUAS <	call	OpenMinimizeIfCGA		;see if on CGA		>
CUAS <	pop	ax							>
CUAS <	jnc	21$				;no, branch		>
CUAS <	add	dx, OL_MENU_ITEM_SEP_BOTTOM_INSET shr 1			>
CUAS <21$:					;else halve our inset   >

	mov	bx, dx
						;pass di = gstate
if _MOTIF
	stc					;move up if etched
	call	DrawEtchedHLine			;draw thin line (in copenCtrl)
else
	call	GrDrawLine
endif

DBWMIG_30:
	pop	ds, si
	ret
DrawBWMenuItemGroup	endp

;OPT: since this is used for both color and BW, move to CommonFunctional
;- brianc 4/30/92
;DrawBW ends
CommonFunctional	ends


CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupNotifyEnabledState -- 
		MSG_SPEC_NOTIFY_ENABLED for OLMenuItemGroupClass
		MSG_SPEC_NOTIFY_NOT_ENABLED for OLMenuItemGroupClass

DESCRIPTION:	Handles spec stuff for this.  Basically eats the method so
		the object isn't ever disabled.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_NOT_ENABLED

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/21/90		Initial version

------------------------------------------------------------------------------@

OLMenuItemGroupNotifyEnabledState	method OLMenuItemGroupClass, \
					MSG_SPEC_NOTIFY_ENABLED,
					MSG_SPEC_NOTIFY_NOT_ENABLED
	stc					;say handled, to ensure that
						;  any children get updated 
						;  correctly.
	ret
OLMenuItemGroupNotifyEnabledState	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupEnsureNoMenusInStayUpMode -- 
		MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE for OLMenuItemGroupClass

DESCRIPTION:	Close any submenus.

PASS:		*ds:si 	- instance data
		es     	- segment of class
		ax 	- MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE

		ss:bp - EnsureNoMenusInStayUpModeParams

RETURN:		bp preserved

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		This is a hack to get the Startup and DOS Programs menu in the
		Express menu closed when we close the Express menu from
		OLReleaseAllStayUpMenus.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/6/92		Initial version

------------------------------------------------------------------------------@

OLMenuItemGroupEnsureNoMenusInStayUpMode	method OLMenuItemGroupClass, \
					MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE
	;
	; pass msg on to children, which may be sub-menus
	;
	call	GenSendToChildren
	ret
OLMenuItemGroupEnsureNoMenusInStayUpMode	endm



CommonFunctional ends



ActionObscure	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuItemGroupResetSizeToStayOnscreen -- 
		MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN for OLMenuItemGroupClass

DESCRIPTION:	Resets size, trying to keep the parent win group onscreen.

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
	chris	2/15/93         Initial Version

------------------------------------------------------------------------------@

OLMenuItemGroupResetSizeToStayOnscreen	method dynamic	OLMenuItemGroupClass, \
				MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN

	;
	; If this menu item group has a moniker assigned to it and has one
	; or more children, we'll turn it into a submenu.  -cbh 2/21/93
	;
	tst	ds:[di].VCI_comp.CP_firstChild.chunk
	jz	callSuper			;no children, forget it

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GI_visMoniker
	jz	callSuper

	;
	; Cheat so we can set this thing not usable via VUM_MANUAL.
	;
	push	ax
	and	ds:[di].GI_states, not mask GS_USABLE
	push	dx
	mov	dl, VUM_MANUAL
	mov	ax, MSG_SPEC_SET_NOT_USABLE
	call	ObjCallInstanceNoLock

	mov	cl, GIV_POPUP			;change to a submenu
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	call	ObjCallInstanceNoLock

	;
	; Set usable, cheating a little bit again.
	;
;	call	GenSpecShrink			;lose vis part.

	mov	dl, VUM_NOW			
;	mov	dl, VUM_MANUAL
	mov	ax, MSG_GEN_SET_USABLE
;	mov	ax, MSG_SPEC_SET_USABLE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
;	call	ObjCallInstanceNoLock
	pop	dx
	pop	ax

callSuper:
	mov	di, offset OLMenuItemGroupClass
	GOTO	ObjCallSuperNoLock

OLMenuItemGroupResetSizeToStayOnscreen	endm


ActionObscure	ends
