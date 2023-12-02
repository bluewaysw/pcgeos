COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinFieldCommon.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_SPEC_GUP_QUERY_VIS_PARENT
				Respond to a query travaeling up the
				generic composite tree

    MTD MSG_SPEC_VUP_GET_WIN_SIZE_INFO
				Returns margins for use with windows that
				wish to avoid extending over icon areas in
				the parent window.  Also size of window
				area.

    MTD MSG_META_POST_PASSIVE_BUTTON
				Bring down the workspace menu if all
				buttons released

    MTD MSG_SPEC_GUP_QUERY      Answer a generic query or two, specifically
				the SGQT_BUILD_INFO query so the open-look
				workspace menu can actually come up.

    MTD MSG_VIS_DRAW            This procedure draws the field.

    MTD MSG_META_ENSURE_ACTIVE_FT
				If nothing currently has focus or target
				exclusives, find most deserving object(s)
				to give the focus & target, & give them the
				exclusives.

    INT FieldAlterFTVMCCore     Allows object to grab/release any of the
				FTVMC exlusives.

    INT FieldTestForModalGeodeWithin
				Determine if there is a "modal" entity
				within this field. Basically, that means
				that something that has a temporary focus
				from us because of being modal.  That only
				happens if there is a system modal geode
				below us, so check for just that - a system
				modal geode, & the focus heading our way,
				indicating the geode is within us.

    MTD MSG_META_GET_FOCUS_EXCL Returns the current focus/target below this
				point in hierarchy

    MTD MSG_META_GET_TARGET_EXCL
				Returns the current focus/target below this
				point in hierarchy

    INT OLFieldGetCommon        Returns the current focus/target below this
				point in hierarchy

    MTD MSG_OL_FIELD_CREATE_WINDOW_LIST_ENTRY
				Create window list entry

    MTD MSG_OL_FIELD_MOVE_TOOL_AREA
				Move tool area to new location on screen

    MTD MSG_OL_FIELD_SIZE_TOOL_AREA
				Sizes the tool area.

    MTD MSG_OL_FIELD_GET_TOOL_AREA_SIZE
				Returns size of tool area

    MTD MSG_VIS_VUP_QUERY       Respond to a query traveling up the generic
				composite tree

    INT FieldRequestStaggerSlot This procedure is used to assign a new
				"stagger slot #" for a window or icon which
				is opening for the first time.

				Actually, every time a window or icon is
				re-opened, it will send this query (call
				this routine) to confirm that it can still
				use its slot, and to get the coordinates
				for the slot again.

				This becomes important when an application
				is restarted, because another application
				may have been assigned the slot #. Our
				application will be assigned a new slot #.

    INT FieldFreeStaggerSlot    This procedure is used to free-up a
				"stagger slot #" that was previously
				assigned to a window. This is done when a
				window is DETACHED - the window will still
				store its slot number on the ActiveList, so
				that when the window is ATTACHED, it will
				request the same slot, and hopefully will
				get it again.

				The important thing is that when the window
				is ATTACHED, we don't want its request
				denied because the field thinks the window
				is still opened. Also, as windows get
				DETACHED, we want to free up their slots in
				case this is only an application shutdown.

				improvement: when window is requesting a
				NEW slot #, should start at certain place
				in map - just after where we started for
				the last new slot # request. This would
				prevent new windows from grabbing slots
				from DETACHED windows UNLESS it is
				necessary.

    INT FieldCalcStaggerPosition
				This procedure calculates the screen
				position for a window or icon given a
				specific slot number.

    INT FieldFindIconSlot       Given a position, calculates the nearest
				available icon slot.

    MTD MSG_META_START_SELECT   Beeps on all types of presses.

    MTD MSG_META_START_SELECT   Beeps on all types of presses.

    MTD MSG_VIS_VUP_ALTER_INPUT_FLOW
				TEMPORARY HACK!!!!  The UI is not yet an
				application, & so the express menu has
				problems with the new input model.  This
				handler exists solely to help a particular
				problem: The express menu, & submenus,
				still have the field as their visible
				parent.  This is a problem when the window
				goes to set up a passive grab, as the vup
				gets here instead of the intended
				application object (superclass of the
				VisContent having the passive mouse grab
				lists).  SOOOooo.. we just redirect the
				method.

    MTD MSG_OL_FIELD_RELEASE_EXPRESS_MENU
				TEMPORARY HACK!!!!  Dismiss Express menu.
				Sent from OLReleaseAllStayUpModeMenus.

    MTD MSG_GEN_FIELD_ENABLE_EXPRESS_MENU
				Redwood-only, enables the express menu
				items.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cwinField.asm


DESCRIPTION:

	$Id: cwinFieldCommon.asm,v 1.3 98/05/04 07:38:21 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HighCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldGupQueryVisParent -- MSG_SPEC_GUP_QUERY_VIS_PARENT for
					   OLFieldClass

DESCRIPTION:	Respond to a query travaeling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass
	ax - MSG_SPEC_GUP_QUERY_VIS_PARENT

	cx - GenQueryVisParentType
RETURN:
	carry - set if query acknowledged, clear if not
	cx:dx - object discriptor of object to use for vis parent, null if none
	bp    - window handle of field, IF realized (Valid for all attached
		applications of this field, as field can't be closed until
		all applications are detached)

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	VIS_PARENT_FOR_APPLICATION	-> this FIELD
	VIS_PARENT_FOR_BASE_GROUP	-> this FIELD
	VIS_PARENT_FOR_POPUP		-> this FIELD
	VIS_PARENT_FOR_URGENT		-> this FIELD

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	1/90		Added return of field window handle

------------------------------------------------------------------------------@

OLFieldGupQueryVisParent	method	dynamic OLFieldClass,
					MSG_SPEC_GUP_QUERY_VIS_PARENT

	; Sys modal dialogs go on the screen window, so continue the search
	;
	cmp	cx, SQT_VIS_PARENT_FOR_SYS_MODAL
	je	sysModal

	; For all other requests, place on this field window.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].VCI_window
	stc				; return query acknowledged
	ret

sysModal:
	GOTO	GenCallParent

OLFieldGupQueryVisParent	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldGetWinSizeInfo --
		MSG_SPEC_VUP_GET_WIN_SIZE_INFO for OLFieldClass

DESCRIPTION:	Returns margins for use with windows that wish to avoid
		extending over icon areas in the parent window.  Also
		size of window area.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VUP_GET_WIN_SIZE_INFO

RETURN:		cx, dx  - size of window area
		bp low  - margins at bottom edge of object
		bp high - margins to the right edge of object
		ax, cx, dx - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 6/91		Initial version

------------------------------------------------------------------------------@

OLFieldGetWinSizeInfo	method dynamic	OLFieldClass, \
				MSG_SPEC_VUP_GET_WIN_SIZE_INFO
	call	VisGetSize		;return current size

	;return margin info in bp - is used for staggered windows which
	;want to extend ALMOST to their parent's limits - so that they don't
	;cover the icon area, etc.

	mov	bp, (EXTEND_NEAR_PARENT_MARGIN_X shl 8) or \
		     NON_CGA_EXTEND_NEAR_PARENT_MARGIN_Y
	call	OpenMinimizeIfCGA		;if CGA, change Y value
	jnc	exit
	sub	bp, NON_CGA_EXTEND_NEAR_PARENT_MARGIN_Y - \
			CGA_EXTEND_NEAR_PARENT_MARGIN_Y
exit:
	ret
OLFieldGetWinSizeInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldPostPassiveButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring down the workspace menu if all buttons released

CALLED BY:	MSG_META_POST_PASSIVE_BUTTON
PASS:		cx, dx	= pointer position
		bp	= UIFunctionsActive | buttonInfo
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp?

PSEUDO CODE/STRATEGY:
		This thing is only called after the workspace menu has been
		brought up. Since there is no menu button or primary to
		control the thing, when all the buttons are released, we need
		to send the MSG_GEN_GUP_INTERACTION_COMMAND message with
		IC_INTERACTION_COMPLETE to the menu to get it to go away.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLFieldPostPassiveButton method	dynamic OLFieldClass,
						MSG_META_POST_PASSIVE_BUTTON
	.enter
	;are any buttons pressed?

	test	bp, mask BI_B3_DOWN or mask BI_B2_DOWN or \
		    mask BI_B1_DOWN or mask BI_B0_DOWN
	jnz	done			;Yes -- do nothing

	;Remove our post-passive grab

	call	VisRemoveButtonPostPassive

	;Now tell the menu to go away.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					;Get menu chunk
	mov	si, ds:[di].OLFI_expressMenu
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	call	ObjCallInstanceNoLock
done:
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
OLFieldPostPassiveButton endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldGupQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Answer a generic query or two, specifically the
		SGQT_BUILD_INFO query so the open-look workspace
		menu can actually come up.

CALLED BY:	MSG_SPEC_GUP_QUERY
PASS:		*ds:si	= instance data
		cx	= query type (GenQueryType or SpecGenQueryType)
		bp	= OLBuildFlags
RETURN:		carry	= set if acknowledged, clear if not
		bp	= OLBuildFlags
		cx:dx	= vis parent
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFieldGupQuery	method	dynamic OLFieldClass, MSG_SPEC_GUP_QUERY

	cmp	cx, GUQT_FIELD
	je	fieldObject

	cmp	cx, GUQT_SCREEN
	je	screenObject

	cmp	cx, SGQT_BUILD_INFO	;fieldable?
	je	answer

	mov	di, offset OLFieldClass	;Pass the buck to our superclass
	GOTO	ObjCallSuperNoLock

answer:
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
EC <	test	bp, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	ORNF	bp, OLBR_TOP_MENU shl offset OLBF_REPLY
	jmp	returnCarry

fieldObject:
	; return our OD, in cx:dx, & window handle in bp
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].VCI_window
	jmp	short returnCarry

screenObject:
				; Pass the screen query to our visParent
				; (GenScreen), since CURRENTLY not our generic
				; parent
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GFI_visParent.handle
	mov	si, ds:[di].GFI_visParent.chunk
	mov	di, mask MF_CALL
	GOTO	ObjMessage

returnCarry:
	stc

done:
	ret
OLFieldGupQuery	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure draws the field.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	TRANSPARENT_FIELDS
OLFieldDraw	method	dynamic OLFieldClass, MSG_VIS_DRAW

if not _NO_FIELD_BACKGROUND
;don't call superclass as there are no children that we want to draw
;- brianc 12/10/92
;	push	bp
;	mov	di, offset OLFieldClass		; es:di <- ptr to class.
;	call	ObjCallSuperNoLock		; Let super do the work.
;	pop	bp

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GFI_flags, mask GFF_DETACHING
	jnz	exit				; don't bother if detaching

	;
	; Get background gstring (if any).
	;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLFI_BGFile		; if no gstring to draw, exit
	jz	exit
	mov	di, bp				; di = gstate
	CallMod	OLFieldDrawBG			; draw the background
exit:
endif
	stc
	ret
OLFieldDraw	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldEnsureActiveFT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If nothing currently has focus or target exclusives,
		find most deserving object(s) to give the focus & target, &
		give them the exclusives.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_ENSURE_ACTIVE_FT

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLFieldEnsureActiveFT	method dynamic	OLFieldClass, \
				MSG_META_ENSURE_ACTIVE_FT

	mov	ax, ds:[di].VCI_window

	mov	bx, offset OLFI_focusExcl
	mov	bp, offset OLFI_nonModalFocus
	call	EnsureActiveFTCommon
	ret

OLFieldEnsureActiveFT	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldAlterFTVMCExcl

DESCRIPTION:	Allows object to grab/release any of the FTVMC exlusives.

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_META_MUP_ALTER_FTVMC_EXCL

		^lcx:dx - object requesting grab/release
		bp	- MetaAlterFTVMCExclFlags

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/25/91		Initial version

------------------------------------------------------------------------------@

OLFieldAlterFTVMCExcl	method	OLFieldClass, \
					MSG_META_MUP_ALTER_FTVMC_EXCL
EC<	call	ECCheckODCXDX						>

	push	ds:[di].OLFI_targetExcl.FTVMC_OD.handle

	call	FieldAlterFTVMCCore	; Do all the standard stuff

	pop	ax

if (not TOOL_AREA_IS_TASK_BAR)
	tst	ax
	jz	afterNoTarget
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLFI_targetExcl.FTVMC_OD.handle
	jnz	afterNoTarget
	;
	; Park the tool area
	;
	mov	dx, size OLFieldMoveToolAreaParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].OLFMTAP_geode, 0	; park the tool area off screen
	mov	ss:[bp].OLFMTAP_xPos, 0	; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_yPos, 0	; not needed for parking off-screen
if EVENT_MENU
	mov	ss:[bp].OLFMTAP_eventPos, 0
endif
					; not needed for parking off-screen
	mov	ss:[bp].OLFMTAP_layerPriority, 0
	mov	ax, MSG_OL_FIELD_MOVE_TOOL_AREA
	call	ObjCallInstanceNoLock
	add	sp, size OLFieldMoveToolAreaParams
afterNoTarget:
endif	; (not TOOL_AREA_IS_TASK_BAR)

	Destroy	ax, cx, dx, bp
	ret

OLFieldAlterFTVMCExcl	endm

FieldAlterFTVMCCore	proc	near	uses	cx, dx, bp, si
	.enter
	test	bp, mask MAEF_NOT_HERE
	jnz	toSuper

next:
	; If no requests for operations left, exit
	;
	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	LONG	jz	done

	; Check FIRST for focus, while ds:di still points to instance data
	;
	test	bp, mask MAEF_FOCUS
	jz	afterFocus

						; Save focus so we can see if
						; it changes
	push	cx, dx				; save passed in cx, dx
	push	ds:[di].OLFI_focusExcl.FTVMC_OD.handle
	push	ds:[di].OLFI_focusExcl.FTVMC_OD.chunk

	; OK.  Now set non-zero if there is a modal geode within our field
	;
	call	FieldTestForModalGeodeWithin	; returns non-zero if there's
						; a modal geode in our midst
	pushf
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, di
	add	ax, offset OLFI_nonModalFocus	; ds:ax is nonModalFocus
	mov	bx, offset Vis_offset		; bx is master offset,
	mov	di, offset OLFI_focusExcl	; di is offset, to focusExcl
	popf
	call	AlterFExclWithNonModalCacheCommon

	; Check to see if focus has changed
	;
	pop	dx, cx				; get original focus
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	cx, ds:[di].OLFI_focusExcl.FTVMC_OD.handle
	jne	focusChanged
	cmp	dx, ds:[di].OLFI_focusExcl.FTVMC_OD.chunk
	je	doneWithFocus
focusChanged:

	; Set new keyboard grab, if necessary.
	;
						; If doesn't have exclusive,
						; kbd grab shouldn't be changed
	test	ds:[di].OLFI_focusExcl.FTVMC_flags, mask HGF_APP_EXCL
	jz	doneWithFocus
	mov	cx, ds:[di].OLFI_focusExcl.FTVMC_OD.handle
	mov	dx, ds:[di].OLFI_focusExcl.FTVMC_OD.chunk
	call	SysUpdateKbdGrab

doneWithFocus:
	pop	cx, dx				; restore passed in cx, dx
	jmp	short next
afterFocus:

	; Check for requests we can handle
	;

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask MAEF_TARGET
	mov	di, offset OLFI_targetExcl
	test	bp, bx
	jnz	doHierarchy

	mov	ax, MSG_META_GAINED_FULL_SCREEN_EXCL
	mov	bx, mask MAEF_FULL_SCREEN
	mov	di, offset OLFI_fullScreenExcl
	test	bp, bx
	jnz	doHierarchy

toSuper:
	; Pass message on to superclass for handling of other hierarchies
	;
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, offset OLFieldClass
	call	ObjCallSuperNoLock
	jmp	short done

doHierarchy:
	push	bx, bp
	and	bp, mask MAEF_GRAB
	or	bp, bx			; or back in hierarchy flag
	mov	bx, offset Vis_offset
	call	FlowAlterHierarchicalGrab
	pop	bx, bp
	not	bx			; get not mask for hierarchy
	and	bp, bx			; clear request on this hierarchy
	jmp	next

done:
	.leave
	ret
FieldAlterFTVMCCore	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FieldTestForModalGeodeWithin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if there is a "modal" entity within this field.
		Basically, that means that something that has a temporary
		focus from us because of being modal.  That only happens
		if there is a system modal geode below us, so check for
		just that - a system modal geode, & the focus heading our
		way, indicating the geode is within us.

CALLED BY:	INTERNAL
		OLFieldAlterFTVMCExcl
PASS:		*ds:si	- GenField
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/14/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FieldTestForModalGeodeWithin	proc	near	uses	cx, dx, bp
	.enter
	mov	ax, MSG_GEN_SYSTEM_GET_MODAL_GEODE
	call	UserCallSystem
	tst	cx				; set non-zero if in modal state
	jz	done				; if no sys modal geodes, then
						;	return no locally

	mov	ax, MSG_META_GET_FOCUS_EXCL
	call	UserCallSystem
	cmp	cx, ds:[LMBH_handle]
	jne	notModal
	cmp	dx, si
	jne	notModal
	or	cl, 0ffh			; return NON-ZERO
	jmp	short done

notModal:
	and	cl, 0				; return ZERO
done:
	.leave
	ret

FieldTestForModalGeodeWithin	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldGetFocusExcl
METHOD:		OLFieldGetTargetExcl

DESCRIPTION:	Returns the current focus/target
		below this point in hierarchy

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_META_GET_[FOCUS/TARGET]_EXCL

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

OLFieldGetFocusExcl 	method dynamic OLFieldClass, MSG_META_GET_FOCUS_EXCL
	mov	bx, offset OLFI_focusExcl
	GOTO	OLFieldGetCommon
OLFieldGetFocusExcl	endm

OLFieldGetTargetExcl 	method dynamic OLFieldClass, MSG_META_GET_TARGET_EXCL
	mov	bx, offset OLFI_targetExcl
	FALL_THRU	OLFieldGetCommon
OLFieldGetTargetExcl	endm

OLFieldGetCommon	proc	far
	mov	cx, ds:[di][bx].FTVMC_OD.handle
	mov	dx, ds:[di][bx].FTVMC_OD.chunk
	Destroy	ax, bp
	stc
	ret
OLFieldGetCommon	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldSendClassedEvent

DESCRIPTION:	Sends message to focus/target object.  If other behavior is
		desired, this message should be subclassed & the modified
		behavior added.


PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TargetObject

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

OLFieldSendClassedEvent	method	OLFieldClass, \
					MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_FOCUS
	je	sendToFocus
	cmp	dx, TO_TARGET
	je	sendToTarget

	mov	di, offset OLFieldClass
	GOTO	ObjCallSuperNoLock

sendToFocus:
	mov	bx, ds:[di].OLFI_focusExcl.FTVMC_OD.handle
	mov	bp, ds:[di].OLFI_focusExcl.FTVMC_OD.chunk
	jmp	short sendHere
sendToTarget:
	mov	bx, ds:[di].OLFI_targetExcl.FTVMC_OD.handle
	mov	bp, ds:[di].OLFI_targetExcl.FTVMC_OD.chunk
sendHere:
	clr	di
	call	FlowDispatchSendOnOrDestroyClassedEvent
	ret

OLFieldSendClassedEvent	endm

HighCommon ends
HighCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldCreateWindowListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Create window list entry

PASS:		*ds:si	= OLFieldClass object
		ds:di	= OLFieldClass instance data
		ds:bx	= OLFieldClass object (same as *ds:si)
		es 	= segment of OLFieldClass
		ax	= message #

RETURN:		^lcx:dx = object
		cx = 0, if no window list entry created

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TOOL_AREA_IS_TASK_BAR

OLFieldCreateWindowListEntry method dynamic OLFieldClass,
					MSG_OL_FIELD_CREATE_WINDOW_LIST_ENTRY
	clr	cx			; assume no window list dialog
	tst	ds:[di].OLFI_windowListDialog
	jz	done

	push	ds:[di].OLFI_windowListList

	; create item

	mov	bx, ds:[LMBH_handle]
	mov	di, segment OLWindowListItemClass
	mov	es, di
	mov	di, offset OLWindowListItemClass
	call	GenInstantiateIgnoreDirty	; *ds:si = new item

	mov	cx, si
	mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
	call	ObjCallInstanceNoLock

	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = new item
	mov	dx, si
	pop	si			; *ds:si = window list
	mov	bp, CCO_LAST		; not dirty
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock

	; Set object USABLE (now that is generically attached and is setup)
	; (Will be setting moniker later)

	mov	si, dx			; *ds:si = new item
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, ds:[LMBH_handle]	; return entry in ^lcx:dx
	mov	dx, si
done:
	ret
OLFieldCreateWindowListEntry endm

endif	;TOOL_AREA_IS_TASK_BAR

HighCommon ends
HighCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldMoveToolArea

DESCRIPTION:	Move tool area to new location on screen

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLField object
		ss:bp	- OLFieldMoveToolAreaParams
		dx	- size OLFieldMoveToolAreaParams

RETURN:

DESTROYED:
		bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version
------------------------------------------------------------------------------@

;never change priority of task bar -- brianc 11/12/99
if (not TOOL_AREA_IS_TASK_BAR)

OLFieldMoveToolArea	method	dynamic OLFieldClass, \
					MSG_OL_FIELD_MOVE_TOOL_AREA
if (not TOOL_AREA_IS_TASK_BAR)

if EVENT_MENU
	;
	; move event menu tool area, using OLFMTAP_eventPos
	;
	push	ss:[bp].OLFMTAP_xPos
	mov	ax, ss:[bp].OLFMTAP_eventPos
	mov	ss:[bp].OLFMTAP_xPos, ax	; use eventPos
	push	si				; save OLField
	mov	si, ds:[di].OLFI_eventToolArea	; *ds:si = event tool area
	call	moveToolArea
	pop	si				; *ds:si = OLField
	pop	ss:[bp].OLFMTAP_xPos
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; re-dereference for lmem move
						; fall thru to do tool area
endif

.assert (UIEP_NONE eq 0)
	push	es
	segmov	es, dgroup, cx
	test	es:[olExpressOptions], mask UIEO_POSITION
	pop	es
	LONG jz	done

endif ; (not TOOL_AREA_IS_TASK_BAR)

	mov	si, ds:[di].OLFI_toolArea	; get *ds:si = tool area
if EVENT_MENU
moveToolArea	label	far
endif
	tst	si
	LONG jz	done

if (not TOOL_AREA_IS_TASK_BAR)

	;
	; First, mark the position flags in the window as WPF_AS_REQUIRED
	; so that it will keep its new position when messed with.
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLWI_winPosSizeFlags, not mask WPSF_POSITION_TYPE
	or	ds:[di].OLWI_winPosSizeFlags, \
			WPT_AS_REQUIRED shl offset WPSF_POSITION_TYPE
	pop	di

	;
	; If UIEP_LOWER_LEFT, then always position at lower left
	;
	push	es
	segmov	es, dgroup, ax			;es = dgroup
	mov	ax, es:[olExpressOptions]
	pop	es
	andnf	ax, mask UIEO_POSITION
	cmp	ax, UIEP_LOWER_LEFT shl offset UIEO_POSITION
	jne	notLowerLeft
	call	OpenGetParentWinSize		; cx = width, dx = height
	clr	cx				; place at left bounds,
						;	below botom of screen
	jmp	short doItInUILayer

notLowerLeft:

	mov	cx, ss:[bp].OLFMTAP_xPos	; in case of real geode
	mov	dx, ss:[bp].OLFMTAP_yPos
	tst	ss:[bp].OLFMTAP_geode	; Check to see if tool area should be
	jnz	realGeode		; "parked".  Skip if not

	call	VisGetBounds		; Move to "home" position
	sub	cx, ax
	shr	cx, 1
	shr	cx, 1
	sub	dx, bx
	shr	dx, 1
	shr	dx, 1

doItInUILayer:
	mov	ax, handle ui		; Move to UI's layer
	jmp	short doIt

endif ; (not TOOL_AREA_IS_TASK_BAR)

realGeode:
	; Ignore request if not from geode owning current target
	;
	mov	bx, ds:[di].OLFI_targetExcl.FTVMC_OD.handle
	tst	bx
	jz	done
	call	MemOwner
	mov	ax, ss:[bp].OLFMTAP_geode
	cmp	bx, ax
	jne	done

	mov	ax, ss:[bp].OLFMTAP_layerID
doIt:
	;
	; cx, dx = position
	; ax = geode
	; ss:[bp] = OLFieldMoveToolAreaParams
	;
	call	VisQueryWindow		; get window, if up
	tst	di
	jz	done

	push	ax			; save layerID

if (not TOOL_AREA_IS_TASK_BAR)
	;
	; Convert coordinates from screen-absolute to parent-relative
	;
	push	si
	push	di
	mov	si, WIT_PARENT_WIN
	call	WinGetInfo
	mov_tr	di, ax
	mov	ax, cx
	mov	bx, dx
	call	WinUntransform
	pop	di
	pop	si

	mov	cx, ax
	mov	dx, bx

	call	VisSetPosition		; set position, too!
	mov	si, mask WPF_ABS	; move to new absolute position
	call	WinMove

endif ; (not TOOL_AREA_IS_TASK_BAR)

	pop	dx			; Pass handle of Geode as
					; new LayerID
	mov	si, WIT_PRIORITY
	call	WinGetInfo		; al = WinPriorityData
	andnf	al, mask WPD_WIN	; keep window priority
	mov	ah, ss:[bp].OLFMTAP_layerPriority
	mov	cl, offset WPD_LAYER
	shl	ah, cl
	ornf	al, ah			; al = new WinPriorityData
	clr	ah			; no WinPassFlags
	call	WinChangePriority

done:
	ret
OLFieldMoveToolArea	endm

endif ; (not TOOL_AREA_IS_TASK_BAR)


COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldSizeToolArea --
		MSG_OL_FIELD_SIZE_TOOL_AREA for OLFieldClass

DESCRIPTION:	Sizes the tool area.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_FIELD_SIZE_TOOL_AREA
		cx	- new height1

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
	chris	6/29/92		Initial Version

------------------------------------------------------------------------------@
if (not TOOL_AREA_IS_TASK_BAR)
OLFieldSizeToolArea	method dynamic	OLFieldClass, \
				MSG_OL_FIELD_SIZE_TOOL_AREA
if EVENT_MENU
	push	cx, si				; save size
	mov	si, ds:[di].OLFI_eventToolArea
	call	sizeToolArea			; size event tool area
	pop	cx, si				; cx = size
	mov	di, ds:[si]			; re-derefence to handle
	add	di, ds:[di].Vis_offset		;	lmem movement
						; fall thru to size tool area
endif
	mov	si, ds:[di].OLFI_toolArea	; get *ds:si = tool area
if EVENT_MENU
sizeToolArea	label	far
endif
	tst	si
	jz	done

	mov	ax, cx
	call	VisGetSize

;	mov	dx, cx
;	mov	cx, CUAS_WIN_ICON_WIDTH

	mov	dx, ax
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock		;force new size of window

	mov	ax, MSG_VIS_MARK_INVALID	;hope it trickles down to kid
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
done:
	ret
OLFieldSizeToolArea	endm
endif ; (not TOOL_AREA_IS_TASK_BAR)


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLFieldGetToolAreaSize

DESCRIPTION:	Returns size of tool area

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLField object

RETURN:		cx - width
		dx - height
if EVENT_MENU
		bp - width of event menu tool area
endif

DESTROYED:
		bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version
------------------------------------------------------------------------------@


OLFieldGetToolAreaSize	method	dynamic OLFieldClass, \
					MSG_OL_FIELD_GET_TOOL_AREA_SIZE
	clr	cx
	clr	dx

;We can't rely on olExpressOptions as this may be called when this field is
;closing because another has just opened.  In that case, olExpressOptions
;reflects the new field's settings.  We'll just depend on OLFI_toolArea being
;0 if UIEO_NONE - brianc 3/9/93
;	test	es:[olExpressOptions], mask UIEO_POSITION
;	jz	done

	mov	si, ds:[di].OLFI_toolArea	; get *ds:si = tool area
	tst	si
	jz	done
	call	VisGetSize
done:
if EVENT_MENU
	clr	bp				; in case no event tool area
	push	cx, dx
	mov	si, ds:[di].OLFI_eventToolArea
	tst	si
	jz	exit
	call	VisGetSize
	mov	bp, cx				; bp = width
exit:
	pop	cx, dx
endif
	ret
OLFieldGetToolAreaSize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldVisUpwardQuery -- MSG_VIS_VUP_QUERY for
					   OLFieldClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLFieldClass

	ax - MSG_VIS_VUP_QUERY

	cx - Query type (VisQueryType or SpecVisQueryType)
	dx -?
	bp -?
RETURN:
	carry - set if query acknowledged, clear if not
	ax, cx, dx, bp - data if query acknowledged

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:


	VUQ_DISPLAY_SCHEME		-> Open look DEFAULT CURRENT
						display scheme (displayType
						returned 0)

	SVQT_REQUEST_STAGGER_SLOT 	-> used to assign staggered screen
						positions to windows and icons.
						returns slot in bp (or zero if
						no slot allotted) and position
						in cx,dx

	SVQT_REQUEST_NEAREST_ICON_SLOT	-> used to assign the nearest available
						icon position

	SVQT_FREE_STAGGER_SLOT 		-> used to free-up a staggered screen
						position - as a window is
						DETACHED.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	11/89		new staggered slot code, field win size query

------------------------------------------------------------------------------@


OLFieldVisUpwardQuery	method	dynamic OLFieldClass, MSG_VIS_VUP_QUERY
				; See if we can handle query
	cmp	cx, VUQ_DISPLAY_SCHEME
	je	OLFVUQ_DisplayScheme
	cmp	cx, SVQT_REQUEST_STAGGER_SLOT
	je	OLFVUQ_FieldRequestStaggerSlot
	cmp	cx, SVQT_REQUEST_NEAREST_ICON_SLOT
	je	OLFVUQ_RequestNearestIconSlot
	cmp	cx, SVQT_FREE_STAGGER_SLOT
	je	OLFVUQ_FieldFreeStaggerSlot

				; If not recognized, call super class to handle
	mov	di, offset OLFieldClass
	GOTO	ObjCallSuperNoLock

OLFVUQ_DisplayScheme:
	call	SpecGetDisplayScheme		; Use FAST routine for this
	mov	bp, dx				; specific UI, which works with
	mov	dx, cx				; only one DisplayScheme at
	mov	cx, bx					; a time.
	stc			; return query acknowledged
	ret

OLFVUQ_RequestNearestIconSlot:
	push	dx, bp
	call	FieldFindIconSlot	;returns nearest slot for pos passed
	cmp	cx, 63			;see if past maximum
	jbe	10$			;no, go assign a slot and return pos
	clr	bp			;return slot 0 (not staggered)
	pop	cx, dx			;return passed position
	stc				;and exit
	ret
10$:
	pop	dx			;unload passed position
	pop	dx
	mov	dl, cl			;pass slot in dl
	or	dl, mask SSPR_REASSIGN_IF_CONFLICT or mask SSPR_ICON

OLFVUQ_FieldRequestStaggerSlot:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, offset OLFI_staggerSlotMap
	mov	cl, dl
	call	FieldRequestStaggerSlot

	clr	ch			;set bp = staggered slot # for return
	push	es
	segmov	es, dgroup, bp
	mov	bp, cx
	call	FieldCalcStaggerPosition ;use new slot # to calculate position.
					 ;returns (cx, dx)
	pop	es
	stc
	ret

OLFVUQ_FieldFreeStaggerSlot:
	add	di, offset OLFI_staggerSlotMap
	mov	cl, dl
	call	FieldFreeStaggerSlot
	stc
	ret

OLFVUQ_Exit:
	stc
	ret

OLFieldVisUpwardQuery	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	FieldRequestStaggerSlot

DESCRIPTION:	This procedure is used to assign a new "stagger slot #"
		for a window or icon which is opening for the first time.

		Actually, every time a window or icon is re-opened, it
		will send this query (call this routine) to confirm
		that it can still use its slot, and to get the coordinates
		for the slot again.

		This becomes important when an application is restarted,
		because another application may have been assigned the
		slot #. Our application will be assigned a new slot #.

NOTE: THIS SHOULD NOT CHANGE ACROSS DIFFERENT SPECIFIC UIs.

CALLED BY:	OLFieldVisUpwardQuery

PASS:		ds:*si	- instance data
		ds:di	- pointer to staggerSlotMap for Field (or DC) object
		cl = StaggerSlotPositionRequest:

StaggerSlotPositionRequest	record
	SSPR_REASSIGN_IF_CONFLICT:1
				;set this TRUE if your window has just been
				;re-attached to the system. If another window
				;has that slot, will return a new slot #.
	SSPR_ICON:1		;TRUE if requesting position for icon
				;FALSE if window.
	SSPR_SLOT:6		;non zero if have been assigned a slot
				;number previously - see if is still OK to use.
StaggerSlotPositionRequest	end

RETURN:		cl = StaggerSlotPositionRequest, with SSPR_REASSIGN_IF_CONFLICT
			flag clear.

DESTROYED:	ax, bx, ch, dl, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

INITIAL_SLOT	= 1

FieldRequestStaggerSlot	proc	far
	mov	dl, 2			;wrap around twice before FAIL

	;has the requesting object ever been assigned a slot #?

	test	cl, mask SSPR_SLOT
	jne	checkSlot		;skip if so...

	ORNF	cl, INITIAL_SLOT or mask SSPR_REASSIGN_IF_CONFLICT
					;try to assign it slot #1 (not #0)
					;and don't be pushy about it

checkSlot:
	mov	ch, cl			;save CONFLICT request
	ANDNF	cl, not (mask SSPR_REASSIGN_IF_CONFLICT)
					;keep ICON/WINDOW and slot # only

	;now find the bit for this slot # in the map

	mov	bl, cl			;set bx = row*2 (1 word per row)
					;(USE ICON request flag as highest
					;bit in row value)
	and	bl, not mask SSPR_COLUMN
	shr	bl, 1
	shr	bl, 1
	shr	bl, 1			;bl = row*2 (0, 2, 4, ... 14)
	clr	bh
	add	di, bx			;offset into staggerSlotMap
	and	cl, mask SSPR_COLUMN	;cl = bit position within word (15-0)
	mov	ax, ds:[di]		;get value from map

	rcr	ax, cl			;move bit to bit#15 position
	rcr	ax, 1			;move bit into CARRY
	jnc	isNotAssigned

	;this slot is already assigned.

	test	ch, mask SSPR_REASSIGN_IF_CONFLICT
	jz	isNotAssigned		;do not reassign - use this one

tryNextSlot:
	;try the next slot within this word
					;(test instruction dorked it)
	cmp	cl, 15			;at end of row already?
	je	tryNextRow		;move to next row if so...

	inc	cl
	stc				;restore used slot to 1

testThisSlot:
	rcr	ax, 1
	jc	tryNextSlot		;loop if is used...
	jnc	isNotAssigned		;skip if not used...

tryNextRow:
	;try the next row (word) with this section (window/icon) of map
	;(can throw out current word of map)

	mov	bh, bl			;check if in last row of 4
	and	bh, (mask SSPR_ROW) shr 3	;(ignore ICON flag)
	cmp	bh, (mask SSPR_ROW) shr 3
	je	tryWrapAround		;skip if already in last row...

	add	di, 2			;move to next word
	add	bl, 2			;
	mov	cl, 0
	mov	ax, ds:[di]		;get new word value from map
	jmp	short testThisSlot	;loop to shift bit into CY and check

tryWrapAround:
	;try beginning of staggerSlotMap for this icon/window - in case
	;we started searching in middle of map

	mov	cl, 1			;DO NOT START WITH SLOT #0!!!
	and	bl, not (mask SSPR_ROW shr 3)
					;stay within icon map if there
	sub	di, 6			;point to start of map again

	mov	ax, ds:[di]		;get new word value from map
	rcr	ax, 1			;(so will be shifted cl+1 before test)

	dec	dl
	clc				;so we don't ever set slot #0
	jne	testThisSlot
					;ran out of slots, we'll use slot zero.
isNotAssigned:
	;can use this slot:
	;	bl = row*2(0, 2, 4, or 14)
	;	cl = bit position (0-15)
	;	ax = word for this row (shifted right by cl+1 bits, so that
	;		the bit we want is in the carry flag)
	;	ds:[di] = address in staggerSlotMap to replace this word to.

	stc				;assign this slot
	rcl	ax, cl			;rotate word to original position
	rcl	ax, 1
	mov	ds:[di], ax		;save new map word

	shl	bl, 1			;translate row and column to slot #
	shl	bl, 1			;(this also restores ICON flag)
	shl	bl, 1
	or	cl, bl

	;cl = slot number assigned
	ret

FieldRequestStaggerSlot	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FieldFreeStaggerSlot

DESCRIPTION:	This procedure is used to free-up a "stagger slot #" that
		was previously assigned to a window. This is done when a
		window is DETACHED - the window will still store its slot
		number on the ActiveList, so that when the window is
		ATTACHED, it will request the same slot, and hopefully will
		get it again.

		The important thing is that when the window is ATTACHED,
		we don't want its request denied because the field thinks
		the window is still opened. Also, as windows get DETACHED,
		we want to free up their slots in case this is only an
		application shutdown.

	improvement: when window is requesting a NEW slot #, should start
	at certain place in map - just after where we started for the last
	new slot # request. This would prevent new windows from grabbing
	slots from DETACHED windows UNLESS it is necessary.

NOTE: THIS SHOULD NOT CHANGE ACROSS DIFFERENT SPECIFIC UIs.

CALLED BY:	OLFieldVisUpwardQuery

PASS:		ds:*si	- instance data
		ds:di	- pointer to staggerSlotMap for Field (or DC) object
		cl = StaggerSlotPositionRequest (indicates which slot this
			window has been allocated before - see above)

	SSPR_REASSIGN_IF_CONFLICT:1

RETURN:		nothing

DESTROYED:	ax, bx, ch, dl, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

FieldFreeStaggerSlot	proc	far
EC <	push	cx							>
EC <	and	cl, mask SSPR_SLOT	;look at this only		>
EC <	cmp	cl, 63			;don't allow slots over 64	>
EC <	ERROR_A OL_ERROR						>
EC <	pop	cx							>

	and	cl, not mask SSPR_REASSIGN_IF_CONFLICT
					;keep ICON/WINDOW and slot # only

	;now find the bit for this slot # in the map

	mov	bl, cl			;set bx = row*2 (1 word per row)
					;(USE ICON request flag as highest
					;bit in row value)
	and	bl, not mask SSPR_COLUMN
	shr	bl, 1
	shr	bl, 1
	shr	bl, 1			;bl = row*2 (0, 2, 4, ... 14)
	clr	bh
	add	di, bx			;offset into staggerSlotMap
	and	cl, mask SSPR_COLUMN	;cl = bit position within word (15-0)
	inc	cl

	mov	ax, ds:[di]		;get value from map
	rcr	ax, cl			;move bit into CARRY

	clc				;FREE THIS SLOT

	rcl	ax, cl			;rotate word to original position
	mov	ds:[di], ax		;save new map word
	ret

FieldFreeStaggerSlot	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FieldCalcStaggerPosition

DESCRIPTION:	This procedure calculates the screen position for a window
		or icon given a specific slot number.

NOTE: THIS WILL CHANGE ACROSS SPECIFIC UIs.

CALLED BY:	OLFieldVisUpwardQuery

PASS:		cl = StaggerSlotPositionRequest (SSPR_SLOT field contains slot)
		es = dgroup

RETURN:		cx, dx = position relative to this windowed object
			(might be Field or DisplayControl)

DESTROYED:

PSEUDO CODE/STRATEGY:
	if staggering a window {
		slot = (slot-1) mod 16	/* slot = 0 to 15 */
		x = FIRST_BASE_X_POS + slot*STAGGER_X_OFFSET
		y = FIRST_BASE_Y_POS + slot*STAGGER_Y_OFFSET

	} else (staggering an icon) {

		slotsPerRow = (fieldWidth-WIN_ICON_PLOT_MARGIN_X)/
					WIN_ICON_PLOT_WIDTH
		row = (slot-1)/slotsPerRow
				/* row 0 is lowest, increase upwards */
		column = (slot-1) mod slotsPerRow
				/* column 0 is leftmost, increase rightwards */

		x = WIN_ICON_PLOT_MARGIN_X + column*WIN_ICON_PLOT_WIDTH
		y = fieldHeight - (WIN_ICON_PLOT_MARGIN_Y +
					(row+1)*WIN_ICON_PLOT_HEIGHT)
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

OL_WINDOW_STAGGER_SLOT_MASK	= 00000111b	;restrict to 8 positions

FieldCalcStaggerPosition	proc	far

EC <	test	cl, mask SSPR_REASSIGN_IF_CONFLICT			>
EC <	ERROR_NZ OL_ERROR						>

EC <	push	ax							>
EC <	mov	ax, es							>
EC <	cmp	ax, seg dgroup						>
EC <	ERROR_NZ	OL_ERROR					>
EC <	pop	ax							>

	test	cl, mask SSPR_ICON
	jnz	calcIconPosition

	;using stagger slot # (1-63), calculate screen position

	dec	cl			;cl = 0 - 62
	ANDNF	cl, OL_WINDOW_STAGGER_SLOT_MASK ;restrict to 8 positions

	mov	al, STAGGER_Y_OFFSET
	call	OpenCheckIfCGA
	jnc	1$
	mov	al, TINY_STAGGER_Y_OFFSET
1$:
	mul	cl			;ax = al * cl
	mov	dx, ax

	mov	al, STAGGER_X_OFFSET
	call	OpenCheckIfNarrow
	jnc	2$
	mov	al, TINY_STAGGER_X_OFFSET
2$:
	mul	cl			;ax = al * cl
	mov	cx, ax

	mov	ax, FIRST_BASE_X_POS or (FIRST_BASE_Y_POS shl 8)
	call	OpenCheckIfCGA
	jnc	3$
	mov	ah, TINY_FIRST_BASE_Y_POS
3$:
	call	OpenCheckIfNarrow
	jnc	4$
	mov	al, TINY_FIRST_BASE_X_POS
4$:
	add	dl, ah
	adc	dh, 0
	clr	ah
	add	cx, ax		; first position to put application
	ret

calcIconPosition:
	push	di

	and	cl, mask SSPR_SLOT	;keep slot # only
	push	cx			;save slot # (1-64) in LOW BYTE

	;slotsPerRow = (fieldWidth-WIN_ICON_PLOT_MARGIN_X)/ WIN_ICON_PLOT_WIDTH

	call	VisGetSize		;(cx, dx) = width and height of field
	mov	ax, cx
	sub	ax, WIN_ICON_PLOT_MARGIN_X
	mov	bl, WIN_ICON_PLOT_WIDTH
	div	bl			;al = ax/WIDTH
	mov	bl, al			;bl = slotsPerRow

	;row = (slot-1)/slotsPerRow	/* row 0 is lowest, increase upwards */
	;column = (slot-1) mod slotsPerRow
	;			/* column 0 is leftmost, increase rightwards */

	pop	ax			;get slot #
	clr	ah
	dec	al			;slot = slot - 1

	div	bl			;al = ax/bl
					;sets ah = remainder (column)
					;sets al = quotient (row)

if	USE_EVERY_OTHER_SLOT_IF_POSSIBLE

	;let's do some things to the row number so that we skip a slot
	;each time, and fill in the blanks afterwards.

	shl	ah, 1			;double our slot number
	cmp	ah, bl			;are we past the rightmost slot?
	jb	10$			;no, we've got a slot
	test	bl, 1			;number of slots odd?
	jnz	5$			;yes, branch
	dec	bl			;else decrement
5$:
	sub	ah, bl			;put into an odd slot
10$:
endif

	;y = fieldHeight - (WIN_ICON_PLOT_MARGIN_Y +
	;				(row+1)*WIN_ICON_PLOT_HEIGHT)
	;x = WIN_ICON_PLOT_MARGIN_X + column*WIN_ICON_PLOT_WIDTH

	mov	ch, ah			;ch = column
	inc	al			;row = row + 1

	; get constants appropriate to display

	mov	bl, CGA_WIN_ICON_PLOT_HEIGHT
	mov	di, CGA_WIN_ICON_PLOT_MARGIN_Y
	call	OpenCheckIfCGA
	jc	gotValues
	mov	bl, NON_CGA_WIN_ICON_PLOT_HEIGHT
	mov	di, NON_CGA_WIN_ICON_PLOT_MARGIN_Y
gotValues:

	mul	bl			;ax = al * HEIGHT
	add	ax, di
	sub	dx, ax			;dx = pixel Y position

	tst	dx			;keep onscreen!
	jns	20$
	clr	dx
20$:
	mov	al, ch			;al = column
	mov	bl, WIN_ICON_PLOT_WIDTH
	mul	bl			;ax = al * WIDTH
	add	ax, WIN_ICON_PLOT_MARGIN_X
	mov	cx, ax			;cx = pixel X position

	pop	di
	ret

FieldCalcStaggerPosition	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	FieldFindIconSlot

SYNOPSIS:	Given a position, calculates the nearest available icon slot.

NOTE: THIS WILL CHANGE ACROSS SPECIFIC UIs.

CALLED BY:	OLFieldVisUpwardQuery

PASS:		dx     = x position
		bp     = y position

RETURN:		cx     = nearest available slot (only 1-63 will actually be
			 assigned a slot later)

DESTROYED:	ax, bx, dx, bp, di

PSEUDO CODE/STRATEGY:
		slotsPerRow = (fieldWidth-WIN_ICON_PLOT_MARGIN_X)/
					WIN_ICON_PLOT_WIDTH
		column = (x - WIN_ICON_PLOT_MARGIN_X + WIN_ICON_PLOT_WIDTH/2)
				/ WIN_ICON_PLOT_WIDTH
		row = (fieldHeight - WIN_ICON_PLOT_MARGIN_Y - y -
				WIN_ICON_PLOT_HEIGHT/2) / WIN_ICON_PLOT_HEIGHT
		slot = (row * slotsPerRow) + column + 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/28/90		Initial version

------------------------------------------------------------------------------@

FieldFindIconSlot	proc	near
	;
	; column = (x - WIN_ICON_PLOT_MARGIN_X + WIN_ICON_PLOT_WIDTH/2)
	;				/ WIN_ICON_PLOT_WIDTH
	;
	sub	dx, WIN_ICON_PLOT_MARGIN_X - WIN_ICON_PLOT_WIDTH/2
	jns	10$			; still positive, branch
	clr	dx			; else use origin
10$:
	mov 	ax, dx
	mov	cl, WIN_ICON_PLOT_WIDTH
	div	cl			; column in al
	clr	ah
	mov	di, ax			; keep column in di

	;
	; slotsPerRow = (fieldWidth-WIN_ICON_PLOT_MARGIN_X)/ WIN_ICON_PLOT_WIDTH
	;
	call	VisGetSize		;(cx, dx) = width and height of field
	mov	ax, cx
	sub	ax, WIN_ICON_PLOT_MARGIN_X
	mov	bl, WIN_ICON_PLOT_WIDTH
	div	bl			;al = ax/WIDTH
	mov	bl, al			;bl = slotsPerRow

	clr	bh
	cmp	di, bx
	jb	15$
	mov	di, bx
	dec	di			;keep column between 0 and slotsPerRow-1
15$:
	;
	; row = (fieldHeight-WIN_ICON_PLOT_MARGIN_Y - y - WIN_ICON_PLOT_HEIGHT/2
	;			/ WIN_ICON_PLOT_HEIGHT
	;
	mov	ax, dx			;field height in ax
	sub	ax, bp			;subtract passed y position

	; get appropriate constants

	mov	dl, CGA_WIN_ICON_PLOT_HEIGHT
	mov	bp, CGA_WIN_ICON_PLOT_MARGIN_Y + CGA_WIN_ICON_PLOT_HEIGHT/2
	call	OpenCheckIfCGA
	jc	gotValues
	mov	dl, NON_CGA_WIN_ICON_PLOT_HEIGHT
	mov	bp, NON_CGA_WIN_ICON_PLOT_MARGIN_Y + \
					NON_CGA_WIN_ICON_PLOT_HEIGHT/2
gotValues:

	sub	ax, bp
	jns	20$
	clr	ax
20$:
	div	dl			;row in al
	;
	; slot = (row * slotsPerRow) + column + 1
	;
	mul	bl
	mov	cx, di			;column in cl

if	USE_EVERY_OTHER_SLOT_IF_POSSIBLE
	;
	; Make adjustments so columns go 0-5-1-6-2-7-3-8-4...
	; if even column
	;	col = col/2
	; else
	;	col = col/2 + (numCols+1)/2
	;
	mov	ch, cl
	shr	cl, 1			;divide column by 2
	test	ch, 1			;see if an odd column visually
	jz	30$			;column wasn't even, branch
	inc	bl			;else add (numCols+1)/2
	shr	bl, 1
	add	cl, bl
30$:
endif
	clr	ch
	add	ax, cx			;add column
	inc	ax			;add one

	; panic -- don't return over 63

	cmp	ax, 63
	jle	40$
	mov	ax, 63
40$:
	mov	cx, ax			;return in cl
	ret
FieldFindIconSlot	endp


if	(0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLFieldPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Beeps on all types of presses.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CUA_STYLE	;--------------------------------------------------------------
OLFieldPress	method dynamic OLFieldClass, MSG_META_START_SELECT,
				MSG_META_START_MOVE_COPY,
				MSG_META_START_FEATURES,
				MSG_META_START_OTHER
else		;(_OL_STYLE)
PrintMessage <POSSIBLE OPENLOOK BUG!>
OLFieldPress	method dynamic OLFieldClass, MSG_META_START_SELECT,
				MSG_META_START_MOVE_COPY, MSG_META_START_OTHER
endif		;--------------------------------------------------------------
	push	ax
	mov	ax, SST_NO_INPUT	;Make no-input beep, and pass to
	call	UserStandardSound	; superclass.
	pop	ax
	mov	di, offset OLFieldClass
	GOTO	ObjCallSuperNoLock
OLFieldPress	endp
endif



COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldVupGrabWithinView

DESCRIPTION:	TEMPORARY HACK!!!!  The UI is not yet an application, & so
		the express menu has problems with the new input model.  This
		handler exists solely to help a particular problem:  The
		express menu, & submenus, still have the field as their
		visible parent.  This is a problem when the window goes to
		set up a passive grab, as the vup gets here instead of the
		intended application object (superclass of the VisContent
		having the passive mouse grab lists).  SOOOooo.. we just
		redirect the method.

PASS:
	*ds:si - instance data (for object in OLField class)
	es - segment of OLFieldClass

	ax - MSG_VIS_VUP_ALTER_INPUT_FLOW
	cx, dx, bp	- data as defined by above method  (Not used here,
			  just passed on)

RETURN:	nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@


OLFieldVupGrabWithinView method dynamic OLFieldClass,
					MSG_VIS_VUP_ALTER_INPUT_FLOW

	mov	bx, ds:[LMBH_handle]	; Get "app object" this field is
					; associated with (due to ownership
					; changing as express menu moves)
	tst	bx
	jz	done
	clr	bx
	call	GeodeGetAppObject	; ^lbx:si is application object
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; Pass on to application object,
					; where express menu requests of
					; MSG_VIS_VUP_ALTER_INPUT_FLOW should
					; have gone in the first place...
done:
	ret

OLFieldVupGrabWithinView endm



if _EXPRESS_MENU
COMMENT @----------------------------------------------------------------------

METHOD:		OLFieldReleaseExpressMenu

DESCRIPTION:	TEMPORARY HACK!!!!  Dismiss Express menu.  Sent from
		OLReleaseAllStayUpModeMenus.

PASS:
	*ds:si - instance data (for object in OLField class)
	ds:di - OLField instance data
	es - segment of OLFieldClass
	ax - MSG_OL_FIELD_RELEASE_EXPRESS_MENU

	cx:dx - EnsureNoMenusInStayUpModeParams

RETURN:	bp preserved


DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/92		Initial version

------------------------------------------------------------------------------@


OLFieldReleaseExpressMenu method dynamic OLFieldClass,
					MSG_OL_FIELD_RELEASE_EXPRESS_MENU

	mov	si, ds:[di].OLFI_expressMenu	; *ds:si = express menu
	tst	si				; any express menu?
	jz	done				; no
	call	OLProcessAppStayUpModeMenus	; do the express menus
done:
	ret

OLFieldReleaseExpressMenu endm
endif		; if _EXPRESS_MENU

HighCommon ends
