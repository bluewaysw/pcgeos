COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		winDisplayControlClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDisplayGroupClass	Open look DisplayControl class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version
	Eric	4/90		Overhaul for new maximize scheme

DESCRIPTION:

	$Id: cwinDisplayControl.asm,v 2.154 95/06/15 04:04:48 joon Exp $

-------------------------------------------------------------------------------@

	;
	;	For documentation of the OLDisplayGroupClass see:
	;	/staff/pcgeos/Spec/olDisplayGroupClass.doc
	; 


CommonUIClassStructures segment resource

	OLDisplayGroupClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

	method	VupCreateGState, OLDisplayGroupClass, MSG_VIS_VUP_CREATE_GSTATE

CommonUIClassStructures ends


;---------------------------------------------------

AppAttach segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupInitialize -- MSG_META_INITIALIZE for
		OLDisplayGroupClass

DESCRIPTION:	Initialize an MDI (Multiple Document Interface) Display Control
		portal window.

PASS:		*ds:si - instance data
		es - segment of OLDisplayGroupClass (dgroup)
		ax - MSG_META_INITIALIZE
		cx, dx, bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		NOTE: since the superclass is VisCompClass, no need to
			call superclass with MSG_META_INITIALIZE.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	11/89		Updated with new positioning/sizing code

------------------------------------------------------------------------------@


OLDisplayGroupInitialize	method dynamic	OLDisplayGroupClass, \
							MSG_META_INITIALIZE
	CallMod	VisCompInitialize

	;determine if displays are to be put on the field or on this object
					;es:di = hint table
	push	es			; save dgroup
	segmov	es, cs
	mov	di, offset cs:DCInitHintHandlers
	mov	ax, length (cs:DCInitHintHandlers)
	call	ObjVarScanData
	pop	es			; restore dgroup

	;make children not managed

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset ;ds:di = VisSpec instance data
;	test	ds:[di].OLDGI_states, mask OLDGS_ON_FIELD
;	jnz	OLDGI_onField		;skip if displays outside MDI area...

	;determine full-sized/overlapping status
					; default to full-sized
	ornf	ds:[di].OLDGI_states, mask OLDGS_MAXIMIZED
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication	; al - ApplicationStates
	test	al, mask AS_ATTACHED_TO_STATE_FILE
					; assume restoring from state
	mov	ax, ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE
	jnz	haveVarData		; yes, use state flag
	push	es
	segmov	es, dgroup, ax		; es = dgroup
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es
	jz	notTransparentDoc
	mov	ax, HINT_DISPLAY_GROUP_FULL_SIZED_IF_TRANSPARENT_DOC_CTRL_MODE
	call	ObjVarFindData		; carry set if found
	jc	afterMax		; if so, leave full-sized
notTransparentDoc:
					; else, use startup hint
	mov	ax, HINT_DISPLAY_GROUP_OVERLAPPING_ON_STARTUP
haveVarData:
	call	ObjVarFindData		; carry set if found
	jnc	afterMax		; not overlapping, leave full-sized
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; else, set overlapping mode
	andnf	ds:[di].OLDGI_states, not mask OLDGS_MAXIMIZED
	mov	ax, ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE or \
							mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
afterMax:

	;displays are put here (the MDI area) -> this object is visible

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].VI_typeFlags, mask VTF_IS_PORTAL

	;optimize -> we can use the standard VisSetPosition and VisSetSize
	;ask that we be notified when geometry has changed, so we can
	;update a maximized GenDisplay. Make children not managed.

	ORNF	ds:[di].VI_geoAttrs, mask VGA_USE_VIS_SET_POSITION \
				  or mask VGA_NOTIFY_GEOMETRY_VALID

	;We'll handle children's geometry on our own.  
	
	ORNF	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	
	;Make sure we completely invalidate the entire object, not just the 
	;margins.
	ANDNF	ds:[di].VCI_geoAttrs, not mask VCGA_ONLY_DRAWS_IN_MARGINS
	
	ORNF	ds:[di].VCI_geoDimensionAttrs, \
				mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
				mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT

	ret

;OLDGI_onField: ;displays are put on the field -> this object does not manage
;	ANDNF	ds:[di].VI_attrs, not (mask VA_MANAGED)
;	ret

OLDisplayGroupInitialize	endp

DCInitHintHandlers	VarDataHandler \
	< HINT_DEFAULT_FOCUS, offset DCHintMakeDefaultFocus >,
	< HINT_DISPLAY_GROUP_SIZE_INDEPENDENTLY_OF_DISPLAYS, \
		offset DCSizeIndependently>


;DISABLED by doug.
;	< HINT_DISPLAYS_ON_FIELD, offset DCInitHintDisplaysOnField >

DCSizeIndependently	proc	far
	class	OLDisplayGroupClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLDGI_states, mask OLDGS_SIZE_INDEPENDENTLY_OF_DISPLAYS
	ret
DCSizeIndependently	endp

DCHintMakeDefaultFocus	proc	far
	class	OLDisplayGroupClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].OLDGI_states, mask OLDGS_DEFAULT_FOCUS
	ret
DCHintMakeDefaultFocus	endp

; A CHANGE OF HEART:  We will NOT allow displays to appear out on the field,
; but instead require use of an MDI area.   An application may have multiple
; Primaries, or have Interaction groups containing large things, like Previews,
; etc.  But can not use THIS particular object outside of a DisplayControl,
; nor outside of an MDI area.  This is largely because of unusability problems,
; like how user is able to access global menu items to operate on the display.
; Besides.. the UI world seems to be heading this direction.
;
; NOTE:  If this is changed to allow displays to optionally be on the 
; field, then you MUST also change OLWinClass to correctly provide window
; EXCLUSION for displays if they are on the field window.  Otherwise, 
; the displays will be allowed to be interacted with while a supposed
; "Modal" dialog box is on screen.  -- Doug
;
;DCInitHintDisplaysOnField	proc	far
;	mov	di,ds:[si]
;	add	di,ds:[di].Vis_offset
;	ORNF	ds:[di].OLDGI_states, mask OLDGS_ON_FIELD
;	ret
;DCInitHintDisplaysOnField	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupSpecBuild -- MSG_SPEC_BUILD handler.

DESCRIPTION:	We intercept this here so that we can scan hints
		relating to FOCUS and TARGET. We also force the creation of
		the MDI Windows menu.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLDisplayGroupSpecBuild	method dynamic	OLDisplayGroupClass, MSG_SPEC_BUILD
	
	;call superclass for default VIS BUILD

	mov	di, offset OLDisplayGroupClass
	call	ObjCallSuperNoLock

	; Go ahead & grab the focus & target exclusives, if hints indicate
	; we're the default within this level, & the exclusive is applicable.
	;
	CallMod	ScanFocusTargetHintHandlers

	ret

OLDisplayGroupSpecBuild	endm

AppAttach ends

;-----------------------

MDICommon segment resource

MDICommonFarRet	proc	far
	ret
MDICommonFarRet	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupGrabFocusExcl

DESCRIPTION:	Intercept to indicate this object is a window in grab
		request

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		initial version

------------------------------------------------------------------------------@

OLDisplayGroupGrabFocusExcl	method dynamic	OLDisplayGroupClass, \
					MSG_META_GRAB_FOCUS_EXCL
	mov	bp, mask MAEF_OD_IS_WINDOW or mask MAEF_GRAB or \
		    mask MAEF_FOCUS or mask MAEF_NOT_HERE
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	GOTO	ObjCallInstanceNoLock

OLDisplayGroupGrabFocusExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupAlterFTVMCExcl

DESCRIPTION:	Grab/Release Focus/Target exclusive

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_META_MUP_ALTER_FTVMC_EXCL

	^cx:dx	- OD to grab/release exclusive for
	bp	- MetaAlterFTVMCExclFlags

RETURN:
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupAlterFTVMCExcl	method	OLDisplayGroupClass, \
					MSG_META_MUP_ALTER_FTVMC_EXCL
	test	bp, mask MAEF_NOT_HERE
	jnz	toSuper

next:
	; If no requests for operations left, exit
	;
	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done

	; Check for requests we can handle
	;

	mov	ax, MSG_META_GAINED_FOCUS_EXCL
	mov	bx, mask MAEF_FOCUS
	mov	di, offset OLDGI_focusExcl
	test	bp, bx
	jnz	doHierarchy

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask MAEF_TARGET
	mov	di, offset OLDGI_targetExcl
	test	bp, bx
	jnz	doHierarchy

toSuper:
	; Pass message on to superclass for handling of other hierarhies
	;
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, offset OLDisplayGroupClass
	GOTO	ObjCallSuperNoLock

doHierarchy:
	push	bx, bp
	and	bp, mask MAEF_GRAB
	or	bp, bx			; or back in hierarchy flag
	mov	bx, offset Vis_offset
	call	FlowAlterHierarchicalGrab
	pop	bx, bp
	not	bx			; get not mask for hierarchy
	and	bp, bx			; clear request on this hierarchy
	jmp	short next

done:
	Destroy	ax, cx, dx, bp
	ret

OLDisplayGroupAlterFTVMCExcl	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupLostFocusExcl -- MSG_META_LOST_FOCUS_EXCL

DESCRIPTION:	We've just lost the focus window exclusive.  Add in a
		pre-passive grab if mouse is still over the window, so we'll
		get focus back if clicked in again.

PASS:		*ds:si - instance data
		ax - MSG_META_LOST_FOCUS_EXCL

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Eric	1/90		more doc

------------------------------------------------------------------------------@


OLDisplayGroupLostFocusExcl	method dynamic	OLDisplayGroupClass, \
						MSG_META_LOST_FOCUS_EXCL
	;See if ptr is in universe

	test	ds:[di].OLDGI_states, mask OLDGS_PTR_IN_RAW_UNIV
	jz	afterPrePassive		; if not, skip
					; Otherwise, the ptr is within this
					; window's universe, & yet the window
					; doesn't have the focus.  We need to
					; restart the pre-passive grab so that
					; we can detect if user clicks in the
					; window again.  (This happens when
					; a summons or command window comes
					; up)
	call	VisAddButtonPrePassive	; startup CTTFM mechanisms.

afterPrePassive:

	; NOTE:  ax must be preserved to this point!
	;
	FALL_THRU	OLDisplayGroupUpdateFocusExcl

OLDisplayGroupLostFocusExcl	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupUpdateFocusExcl 

DESCRIPTION:	Provide standard focus node behavior.

PASS:		*ds:si - instance data
		ax - focus message

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupUpdateFocusExcl	method OLDisplayGroupClass, \
					MSG_META_GAINED_FOCUS_EXCL,
					MSG_META_GAINED_SYS_FOCUS_EXCL,
					MSG_META_LOST_SYS_FOCUS_EXCL

	mov	bp, MSG_META_GAINED_FOCUS_EXCL	; pass base message in bp
	mov	bx, offset Vis_offset
	mov	di, offset OLDGI_focusExcl
	GOTO	FlowUpdateHierarchicalGrab

OLDisplayGroupUpdateFocusExcl	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupUpdateTargetExcl 

DESCRIPTION:	Provide standard target node behavior.

PASS:		*ds:si - instance data
		ax - target message

RETURN:

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupUpdateTargetExcl	method dynamic	OLDisplayGroupClass, \
					MSG_META_GAINED_TARGET_EXCL,
					MSG_META_LOST_TARGET_EXCL,
					MSG_META_GAINED_SYS_TARGET_EXCL,
					MSG_META_LOST_SYS_TARGET_EXCL

	mov	bp, MSG_META_GAINED_TARGET_EXCL	; pass base message in bp
	mov	bx, offset Vis_offset
	mov	di, offset OLDGI_targetExcl
	call	FlowUpdateHierarchicalGrab

	cmp	ax, MSG_META_GAINED_TARGET_EXCL
	je	updateUI
	ret

updateUI:

	; if we have a first child, tell it to send a GCN update

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GI_comp.CP_firstChild
	mov	ax, MSG_OL_DISPLAY_SEND_NOTIFICATION
	clr	di
	GOTO	ObjMessage

OLDisplayGroupUpdateTargetExcl	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupGetFocusExcl
METHOD:		OLDisplayGroupGetTargetExcl

DESCRIPTION:	Returns the current focus/target below this point in hierarchy

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_GEN_GET_[FOCUS/TARGET]_EXCL
		
RETURN:		^lcx:dx - handle of object with focus/target
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

OLDisplayGroupGetFocusExcl 	method dynamic OLDisplayGroupClass, \
							MSG_META_GET_FOCUS_EXCL
	mov	cx, ds:[di].OLDGI_focusExcl.FTVMC_OD.handle
	mov	dx, ds:[di].OLDGI_focusExcl.FTVMC_OD.chunk
	Destroy	ax, bp
	stc
	ret
OLDisplayGroupGetFocusExcl	endm

OLDisplayGroupGetTargetExcl 	method dynamic OLDisplayGroupClass, \
							MSG_META_GET_TARGET_EXCL
	mov	cx, ds:[di].OLDGI_targetExcl.FTVMC_OD.handle
	mov	dx, ds:[di].OLDGI_targetExcl.FTVMC_OD.chunk
	Destroy	ax, bp
	stc
	ret
OLDisplayGroupGetTargetExcl	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupSendClassedEvent

DESCRIPTION:	Sends message to focus/target object.
		Any object that wants different behaviors will have
		to intercept this method & do what they want to see done.

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- ClassedEventSendyRequest

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

OLDisplayGroupSendClassedEvent	method	OLDisplayGroupClass, \
						MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_FOCUS
	je	toFocus
	cmp	dx, TO_TARGET
	je	toTarget

	mov	di, offset OLDisplayGroupClass
	GOTO	ObjCallSuperNoLock

toFocus:
	mov	bx, ds:[di].OLDGI_focusExcl.FTVMC_OD.handle
	mov	bp, ds:[di].OLDGI_focusExcl.FTVMC_OD.chunk
	jmp	short toHere

toTarget:
	mov	bx, ds:[di].OLDGI_targetExcl.FTVMC_OD.handle
	mov	bp, ds:[di].OLDGI_targetExcl.FTVMC_OD.chunk
toHere:
	clr	di
	GOTO	FlowDispatchSendOnOrDestroyClassedEvent

OLDisplayGroupSendClassedEvent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayGroupAddRemoveChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update tiling if necessary after adding/removing child

CALLED BY:	MSG_VIS_ADD_CHILD
		MSG_VIS_REMOVE_CHILD
PASS:		*ds:si	= OLDisplayGroupClass object
		ds:di	= OLDisplayGroupClass instance data
		ds:bx	= OLDisplayGroupClass object (same as *ds:si)
		es 	= segment of OLDisplayGroupClass
		ax	= message #
		^lcx:dx	= child object to add/remove
		bp	= flags for how to add/remove child (CompChildFlags)
RETURN:		nothing
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TRACK_TILING	;--------------------------------------------------------------

OLDisplayGroupAddRemoveChild	method dynamic OLDisplayGroupClass, 
					MSG_VIS_ADD_CHILD,
					MSG_VIS_REMOVE_CHILD
	mov	di, offset OLDisplayGroupClass
	call	ObjCallSuperNoLock

if _NIKE;------------------------------------------------

	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication

	test	ax, mask AS_QUITTING or mask AS_DETACHING
	jnz	done

	; ANOTHER HACK: if this GenDisplayGroup has HINT_DUMMY on it, then
	; don't change maximized/tiled

	push	cx, dx
	mov	ax, MSG_VIS_COUNT_CHILDREN
	call	ObjCallInstanceNoLock

	mov	ax, HINT_DUMMY
	call	ObjVarFindData
	jnc	noHack

	cmp	dx, 1
	jbe	popcxdx

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDGI_states, mask OLDGS_TILED
	jnz	tile			; do track tiling
	jmp	popcxdx
noHack:
	cmp	dx, 1
	ja	tile
full:
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED
	jmp	callSelf
tile:
	mov	ax, MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
callSelf:
	call	ObjCallInstanceNoLock
popcxdx:
	pop	cx, dx

else	;------------------------------------------------

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDGI_states, mask OLDGS_TILED
	jz	done

	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication

	test	ax, mask AS_QUITTING or mask AS_DETACHING
	jnz	done

	push	cx, dx
	mov	ax, MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
	call	ObjCallInstanceNoLock
	pop	cx, dx

endif	;------------------------------------------------

done:
	ret
OLDisplayGroupAddRemoveChild	endm

endif		; if TRACK_TILING ---------------------------------------------

MDICommon	ends


InstanceObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupGetTargetAtTargetLevel

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - MSG_META_GET_TARGET_AT_TARGET_LEVEL

	cx	- TargetLevel

RETURN:
	cx:dx	- OD of target at level requested (0 if none)
	ax:bp	- Class of target object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupGetTargetAtTargetLevel	method dynamic	OLDisplayGroupClass,
					MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	ax, TL_GEN_DISPLAY_CTRL
	mov	bx, Vis_offset
	mov	di, offset OLDGI_targetExcl
	call	FlowGetTargetAtTargetLevel
	ret
OLDisplayGroupGetTargetAtTargetLevel	endm

InstanceObscure	ends


MDICommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupGQVP -- MSG_SPEC_GUP_QUERY_VIS_PARENT for
		OLDisplayGroupClass

DESCRIPTION:	Answer a request for a vis parent for a display if we're
		running in MDI mode

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - MSG_SPEC_GUP_QUERY_VIS_PARENT

	cx - GupQueryVisParentType
	dx - ?
	bp - ?

RETURN:
	carry - set if responded to
	ax - ?
	cx:dx - parent
	bp - window handle, if realized

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupGQVP	method dynamic	OLDisplayGroupClass, \
				MSG_SPEC_GUP_QUERY_VIS_PARENT

	;only answer request for vis parent for display

	cmp	cx, SQT_VIS_PARENT_FOR_DISPLAY
	jnz	OLDCG_up

;	;only use ourself if in MDI mode
;
;	test	ds:[di].OLDGI_states, mask OLDGS_ON_FIELD
;	jnz	OLDCG_up

	;put the display here

	mov	cx,ds:[LMBH_handle]
	mov	dx,si

	call	VisQueryWindow		; If a window handle exists,
					; return it in bp
	mov	bp, di

	stc
exit:
	ret

OLDCG_up:
	mov	di, offset OLDisplayGroupClass
	call	ObjCallSuperNoLock
	jc	exit		; something ultimately found, exit
	clr	cx
	mov	dx, cx		; else return cx:dx = null
	jmp	short exit	;  (and carry clear)

OLDisplayGroupGQVP	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupDraw -- MSG_VIS_DRAW for OLDisplayGroupClass

DESCRIPTION:	Draw the frame for the DisplayClass

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

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

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Chris	12/ 4/92	Changed to be an inset rect for Motif.

------------------------------------------------------------------------------@

if _MOTIF

OLDisplayGroupDraw	method dynamic	OLDisplayGroupClass, MSG_VIS_DRAW
	mov	di, bp	
	call	OpenSetInsetRectColors		;get inset rect colors
	call	VisGetBounds			;get normal bounds
	call	OpenDrawRect
	ret

OLDisplayGroupDraw	endp

else

OLDisplayGroupDraw	method dynamic	OLDisplayGroupClass, MSG_VIS_DRAW
	mov	di, bp				;di = GState
	mov	ax, C_BLACK			;force C_BLACK for now
	call	GrSetAreaColor

	;draw a rectangle the size of the port window.  Will actually turn
	;out as a frame but this is faster

	call	VisGetBounds
	GOTO	GrFillRect

OLDisplayGroupDraw	endp

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupRawUnivEnter -- MSG_RAW_RAW_UNIV_ENTER

DESCRIPTION:	Process RAW_UNIV_ENTER for OLDisplayClass object. Similar
		to CTTFM/REFM mechanisms in OLDisplayGroupClass.

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - method

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupRawUnivEnter	method dynamic	OLDisplayGroupClass,
						MSG_META_RAW_UNIV_ENTER
					; Set flag to indicate ptr is in
					; this window's universe
	ORNF	ds:[di].OLDGI_states, mask OLDGS_PTR_IN_RAW_UNIV
	call	VisAddButtonPrePassive	;startup CTTFM mechanisms.
	ret
OLDisplayGroupRawUnivEnter	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupRawUnivLeave -- MSG_META_RAW_UNIV_LEAVE

DESCRIPTION:	Process RAW_UNIV_LEAVE for OLDisplayGroupClass object. See
		comments at top of cwinClass.asm file.

			;mechanisms: CTTFM, REFM
			;Received when ptr leaves this window, or when covering
			;window opens which contains ptr.


PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - method

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	8/89		Updated according to Tony's new UI methods

------------------------------------------------------------------------------@


OLDisplayGroupRawUnivLeave	method dynamic	OLDisplayGroupClass,
					MSG_META_RAW_UNIV_LEAVE

					; If already NOT in universe according
					; to this obj, skip redundant operations
	test	ds:[di].OLDGI_states, mask OLDGS_PTR_IN_RAW_UNIV
	jz	done

					; Clear flag to indicate ptr is NOT
					; in this window's universe
	ANDNF	ds:[di].OLDGI_states, not mask OLDGS_PTR_IN_RAW_UNIV

	;SPACE-SAVER: whether CTTFM or REFM, we want to remove pre-passive
	;grab, so do it here. (If CTTFM and press-release already occurred,
	;may have been removed already.)

	call	VisRemoveButtonPrePassive ;turn off mechanisms

done:
	ret
OLDisplayGroupRawUnivLeave	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupPrePassiveButton -- MSG_META_PRE_PASSIVE_BUTTON

DESCRIPTION:	Handler for Passive Button events (see CTTFM description,
		top of cwinClass.asm file.)

	(We know that REFM mechanism does not rely on this procedure, because
	REFM does not request a pre-passive grab.)

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	Nothing

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@

OLDisplayGroupPrePassiveButton	method dynamic	OLDisplayGroupClass, \
						MSG_META_PRE_PASSIVE_BUTTON

	; Check to see if mouse is allowed to interact with this window or not.
	; Since we set up a pre-passive grab whenever the mouse is over us,
	; regardless of mouse grabs or modal status, we have to do this check
	; to make sure user presses can actually affect this window.
	;
	call	CheckIfInteractable
	jnc	exit				; not interactable

	;translate method into MSG_META_PRE_PASSIVE_START_SELECT etc. and
	;send to self. (See OpenWinPrePassStartSelect)

	mov	ax, MSG_META_PRE_PASSIVE_BUTTON
	call	OpenDispatchPassiveButton

exit:
	ret

OLDisplayGroupPrePassiveButton	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupPrePassiveStartSelect

DESCRIPTION:	Handler for SELECT button being pressed while we have a
		passive mouse grab.
PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version

------------------------------------------------------------------------------@

OLDisplayGroupPrePassiveStartSelect	method dynamic	OLDisplayGroupClass, \
					MSG_META_PRE_PASSIVE_START_SELECT, \
					MSG_META_PRE_PASSIVE_START_MOVE_COPY

	;now inform our parent that this window should have the
	;FOCUS_EXCL and TARGET_EXCL.

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	call	VisRemoveButtonPrePassive	;turn off CTTFM mechanism

	mov	ax, mask MRF_PROCESSED	; show processed, no event destruction
	ret
OLDisplayGroupPrePassiveStartSelect	endp

MDICommon	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for OLDisplayGroupClass

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
	OLDisplayGroupClass handler:
	    identical to standard VisCompClass handler, except we don't
	    error check for !WIN_GROUP, since we know this is a win-group.
	    We also set the NCF_BAR_MENU_RELATED flag,
	    so that menu bar navigation queries can skip drop into the
	    targeted GenDisplay.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLDisplayGroupNavigate	method dynamic	OLDisplayGroupClass, \
						MSG_SPEC_NAVIGATION_QUERY
	;other ERROR CHECKING is in VisNavigateCommon

	;call utility routine, passing flags to indicate that this is
	;NOT a composite node (we don't want the children called).
	;This routine will check the passed NavigationFlags and decide
	;what to respond.

	mov	bl, mask NCF_IS_FOCUSABLE
;	clr	bl			;pass flags: is not composite, is not
				  	;root node, not focusable.
	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon
	ret
OLDisplayGroupNavigate	endm

KbdNavigation	ends


MDICommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupVupQuery -- MSG_VIS_VUP_QUERY for
					   OLDisplayGroupClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass
	ax - MSG_VIS_VUP_QUERY
	cx - Query type (VisQueryType or SpecVisQueryType)

RETURN:
	carry - set if query acknowledged, clear if not
	ax, cx, dx, bp - data if query acknowledged

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
	DISPLAY_SCHEME			-> Open look DEFAULT CURRENT
						display scheme (displayType
						returned 0)

	SVQT_REQUEST_STAGGER_SLOT 	-> used to assign staggered MDI/screen
						positions to windows and icons.

	SVQT_FREE_STAGGER_SLOT 		-> used to free-up a staggered MDI/scr
						position - as a window is
						DETACHED.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Eric	11/89		new staggered slot code.

------------------------------------------------------------------------------@

OL_DC_INITIAL_MIN_SPACE	=	10

.assert (offset SSPR_SLOT eq 0)

OLDisplayGroupVupQuery	method dynamic	OLDisplayGroupClass, MSG_VIS_VUP_QUERY
	cmp	cx, SVQT_REQUEST_STAGGER_SLOT
	je	OLDCVQ_MDIRequestStaggerSlot

	cmp	cx, SVQT_FREE_STAGGER_SLOT
	je	OLDCVQ_MDIFreeStaggerSlot

	mov	di, offset OLDisplayGroupClass
	GOTO	ObjCallSuperNoLock

OLDCVQ_MDIRequestStaggerSlot:
	add	di, offset OLDGI_staggerSlotMap
	mov	cl, dl
	call	FieldRequestStaggerSlot

	clr	ch			;set bp = staggered slot # for return
	push	es
	segmov	es, dgroup, bp		;es = dgroup
	mov	bp, cx
	call	FieldCalcStaggerPosition ;use new slot # to calculate position.
					 ;returns (cx, dx)
	pop	es
	stc
	ret

OLDCVQ_MDIFreeStaggerSlot:
	add	di, offset OLDGI_staggerSlotMap
	mov	cl, dl
	call	FieldFreeStaggerSlot
	stc
	ret

OLDisplayGroupVupQuery	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}. We respond to this
		broadcast method here so that the Primary knows that
		this DisplayControl has a HINT_DEFAULT_FOCUS

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

OLDisplayGroupBroadcastForDefaultFocus	method dynamic \
		OLDisplayGroupClass, MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	test	ds:[di].OLDGI_states, mask OLDGS_DEFAULT_FOCUS
	jz	done			;skip if not...

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, mask MAEF_OD_IS_WINDOW

done:
	ret
OLDisplayGroupBroadcastForDefaultFocus	endm

MDICommon	ends


KbdNavigation	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayGroupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Default handler for MSG_META_KBD_CHAR.  Pass on to current
		focus below this node, else pass on to superclass (which will
		most likey FUP it).

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_KBD_CHAR

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLDisplayGroupKbdChar	method dynamic	OLDisplayGroupClass, MSG_META_KBD_CHAR
	mov	bx, ds:[di].OLDGI_focusExcl.FTVMC_OD.handle
	tst	bx
	jz	callSuper
	mov	si, ds:[di].OLDGI_focusExcl.FTVMC_OD.chunk
	clr	di
	GOTO	ObjMessage

callSuper:
	mov	di, offset OLDisplayGroupClass
	GOTO	ObjCallSuperNoLock

OLDisplayGroupKbdChar	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupFindKbdAccelerator

DESCRIPTION:	Give target GenDisplay first shot at checking for a
		keyboard accelerator match.

PASS:	*ds:si 	- instance data
	ds:di	- OLDisplayGroup instance
	es     	- segment of object
	ax 	- MSG_GEN_FIND_KBD_ACCELERATOR

	same as MSG_META_KBD_CHAR:
		cl - Character		(Chars or VChar)
		ch - CharacterSet	(CS_BSW or CS_CONTROL)
		dl - CharFlags
		dh - ShiftState		(left from conversion)
		bp low - ToggleState
		bp high - scan code

RETURN:	carry set if accelerator found and dealt with

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/4/92		Initial version

------------------------------------------------------------------------------@

OLDisplayGroupFindKbdAccelerator	method dynamic OLDisplayGroupClass,
						MSG_GEN_FIND_KBD_ACCELERATOR
	;
	; First check to see whether we are enabled.
	;

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	pop	di
	jz	exit

	;
	; Let target display handle it first
	;
					 	; ^lbx:si = target
	mov	bx, ds:[di].OLDGI_targetExcl.FTVMC_OD.handle
	tst	bx				; no target
	jz	callSuper
	push	si, cx, dx, bp
	mov	si, ds:[di].OLDGI_targetExcl.FTVMC_OD.offset
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, cx, dx, bp
	jc	short exit			; if handled, done

callSuper:
	;
	; now, let superclass call all our children in reguler order
	;
	mov	ax, MSG_GEN_FIND_KBD_ACCELERATOR
	mov	di, offset OLDisplayGroupClass
	call	ObjCallSuperNoLock		; let superclass deal with it
exit:
	Destroy	ax, cx, dx, bp
	ret
OLDisplayGroupFindKbdAccelerator	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayGroupSpecActivateObjectWithMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	only let target GenDisplay process the mnemonic

CALLED BY:	MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC

PASS:		*ds:si	= OLDisplayGroup object
		ds:di	= OLDisplayGroup instance data
		es 	= segment of OLDisplayGroup
		ax	= MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC

		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if mnemonic found

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/8/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDisplayGroupSpecActivateObjectWithMnemonic	method	dynamic	OLDisplayGroupClass, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	;
	; Only let target display handle, we ignore our own mnemonic
	;
					 	; ^lbx:si = target
	mov	bx, ds:[di].OLDGI_targetExcl.FTVMC_OD.handle
	tst	bx				; no target
	jz	done				; (exit with carry clear)
	mov	si, ds:[di].OLDGI_targetExcl.FTVMC_OD.offset
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; carry set if handled
done:
	Destroy	ax, cx, dx, bp
	ret
OLDisplayGroupSpecActivateObjectWithMnemonic	endm

KbdNavigation	ends


MDICommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupOpenWin -- MSG_VIS_OPEN_WIN for
		OLDisplayGroupClass

DESCRIPTION:	Open a window for a OLDisplayClass object.

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - MSG_VIS_OPEN_WIN

	cx - ?
	dx - ?
	bp - window to make parent of this window

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

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@


OLDisplayGroupOpenWin	method dynamic	OLDisplayGroupClass, MSG_VIS_OPEN_WIN
EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>
EC <	cmp	ds:[di].VCI_window, 0	; already have a window?	>
EC <	ERROR_NZ	OPEN_WIN_ON_OPEN_WINDOW				>

	push	si			; save chunk handle

	call	GeodeGetProcessHandle	; Get owner for this window
	push	ax			; Push layer ID to use
	push	bx			; Push owner

	push	bp			; push parent window to use

	clr	ax			; pass region (rectangular)
	push	ax
	push	ax

	clr	cl			; normal bounds
	call	OpenGetLineBounds	; push parameters to region
	
	inc	ax			; insert one from vis bounds for a
	inc	bx			; border
	dec	cx
	dec	dx
	push	dx
	push	cx
	push	bx
	push	ax

OLS <	push	es							>
OLS <	segmov	es, dgroup, ax						>
OLS <	mov	al, es:[moCS_dsDarkColor]; get display scheme to figure color >
OLS <	pop	es							>
OLS <	; use CMM_ON_BLACK -> any color but black maps to white		      >
OLS <	; map to either black or white on a BW display			      >
OLS <	mov	ah,mask CMM_ON_BLACK or CMT_CLOSEST or mask WCF_PLAIN      >

if	(0)

CUAS <	mov	al, C_DARK_GREY		; Force to dark grey, since it's not >
CUAS <					;   in the display scheme.	     >
CUAS <	; use CMM_ON_BLACK -> any color but black maps to white		      >
CUAS <	; map to either black or white on a BW display			      >
CUAS <	mov	ah,mask CMM_ON_BLACK or CMT_CLOSEST or mask WCF_PLAIN      >

else

CUAS <	push	es							>
CUAS <	segmov	es, dgroup, ax						>
CUAS <	mov	al, C_DARK_GREY						     >
CUAS <	mov	ah, CMT_CLOSEST or mask WCF_PLAIN			     >
CUAS <	test	es:[moCS_flags], mask CSF_BW	; B&W?			     >
CUAS <	pop	es							>
CUAS <	jz	haveColors						     >
CUAS <	mov	al, C_BW_GREY						     >
CUAS <	mov	ah, CMT_DITHER or mask WCF_PLAIN			     >
CUAS <haveColors:							     >

endif

	; pass this object for the enter/leave OD

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	di,cx			;draw OD = this object also
	mov	bp,si

	clr	si			;no WFP_ flags
	call	WinOpen

	; store the new window handle

	pop	si
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VCI_window, bx
	ret

OLDisplayGroupOpenWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupVisOpen -- MSG_VIS_OPEN handler.

DESCRIPTION:	someone else added this

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLDisplayGroupVisOpen	method dynamic	OLDisplayGroupClass, MSG_VIS_OPEN

	; Send VIS_OPEN to superclass, so DisplayControl itself is "open".
	;
	mov	di, offset OLDisplayGroupClass
	call	ObjCallSuperNoLock

	; Make sure the top display is made the focus/target.
	; (To fix no target/focus display on uniconify  bug).
	;
	mov	ax, MSG_OL_DISPLAY_GROUP_BRING_FIRST_DISPLAY_TO_TOP
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_INSERT_AT_FRONT or mask MF_FORCE_QUEUE
	GOTO	ObjMessage

OLDisplayGroupVisOpen	endm

MDIAction segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayGroupSetFullSized --
		MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED for OLDisplayGroupClass

DESCRIPTION:	Set full sized

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

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
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
OLDisplayGroupSetFullSized	method dynamic	OLDisplayGroupClass,
					MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED
	ornf	ds:[di].OLDGI_states, mask OLDGS_MAXIMIZED
	andnf	ds:[di].OLDGI_states, not mask OLDGS_TILED
	mov	ax, MSG_GEN_DISPLAY_INTERNAL_SET_FULL_SIZED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	GenSendToChildren		;maximize all children

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDGI_states, mask OLDGS_SIZE_INDEPENDENTLY_OF_DISPLAYS
	jnz	exit

	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid	
exit:
	ret

OLDisplayGroupSetFullSized	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayGroupSetOverlapping --
		MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING for OLDisplayGroupClass

DESCRIPTION:	Set full sized

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

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
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
OLDisplayGroupSetOverlapping	method dynamic	OLDisplayGroupClass,
					MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLDGI_states, not mask OLDGS_MAXIMIZED
	andnf	ds:[di].OLDGI_states, not mask OLDGS_TILED
	mov	ax, MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	GOTO	GenSendToChildren		;un-maximize all children

OLDisplayGroupSetOverlapping	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayGroupSelectDisplay --
		MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY for OLDisplayGroupClass

DESCRIPTION:	Select a display

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - The message

	cx - display number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
OLDisplayGroupSelectDisplay	method dynamic	OLDisplayGroupClass,
					MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY

	call	FindDisplayByNumber
	jcxz	exit

	push	ds:[LMBH_handle], si
	movdw	bxsi, cxdx				;bxsi = display
	call	ObjLockObjBlock
	mov	ds, ax

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjCallInstanceNoLock

	; Move focus & target, if applicable, to the GenDisplayGroup 
	; itself, so that  if the focus/target was elsewhere, the user may
	; immediately start interacting with the display 

	call	MetaGrabFocusExclLow
	call	MetaGrabTargetExclLow

	call	MemUnlock
	pop	bx, si					;restore disp group

	call	MemDerefDS

	; New code 11/17/92 cbh to mark our geometry invalid if we're maximized
	; in case we need to change to match the new display's geometry.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDGI_states, mask OLDGS_MAXIMIZED
	jz	exit				
	test	ds:[di].OLDGI_states, mask OLDGS_SIZE_INDEPENDENTLY_OF_DISPLAYS
	jnz	exit

	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid	
exit:
	ret

OLDisplayGroupSelectDisplay	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindDisplayByNumber

DESCRIPTION:	Find a display by number

CALLED BY:	INTERNAL

PASS:
	*ds:si - display control
	cx - display number

RETURN:
	cx:dx - display, or cx = 0 if not found

DESTROYED:
	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
FindDisplayByNumber	proc	far	uses bx
	.enter

	inc	cx				;use as 1-based number

	clr	ax				;child number
	push	ax, ax				;initial child
	mov	bx, offset GI_link
	push	bx				;LinkPart
	mov	bx, SEGMENT_CS
	push	bx
	mov	bx, offset FindDisplayByNumCallback
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren		;cx:dx = child

	;
	; Added 6/93: it's possible that the requested child might no
	; longer exist, so if not found, return cx=0.
	;
		
	jc	done
	clr	cx, dx
done:
	.leave
	ret

FindDisplayByNumber	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindDisplayByNumCallback

DESCRIPTION:	Find a display by number

CALLED BY:	INTERNAL

PASS:
	*es:di - display group
	*ds:si - display
	cx - 1-based number

RETURN:
	carry - set if found
	cx:dx - display (if found)

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
FindDisplayByNumCallback	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	10$				; not usable, skip
	dec	cx
	jcxz	found
10$:
	clc
	ret

found:
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	stc
	ret

FindDisplayByNumCallback	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayGroupSetMoniker -- MSG_GEN_DISPLAY_GROUP_SET_MONIKER
					for OLDisplayGroupClass

DESCRIPTION:	Set a moniker

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - The message

	cx:dx - list
	bp - item number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version
	Doug	5/15/92		Added support for NULL string, EC for gstring

------------------------------------------------------------------------------@
OLDisplayGroupSetMoniker	method dynamic	OLDisplayGroupClass,
					MSG_GEN_DISPLAY_GROUP_SET_MONIKER

	pushdw	cxdx
	mov	cx, bp
	call	FindDisplayByNumber		;cxdx = display
	jcxz	notFound
		
	mov	bx, cx
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, dx
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GI_visMoniker
	tst	bx
	jz	noMoniker
	mov	di, ds:[bx]
EC <	test	ds:[di].VM_type, mask VMT_GSTRING			>
EC <	ERROR_NZ	OL_GEN_DISPLAY_CAN_NOT_HANDLE_GSTRING_MONIKER	>
	add	di, offset VM_data.VMT_text	;ds:di = text

havePtrToNullTermText:
	popdw	bxsi
	movdw	cxdx, dsdi
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
done:
	ret

noMoniker:
	; If this display has no VisMoniker, pass a NULL string.  The
	; first byte of the NULL GI_visMoniker field will do fine...
	;

	add	di, offset GI_visMoniker
	jmp	short havePtrToNullTermText

notFound:
	;
	; The child wasn't found -- do nothing
	;
	popdw	cxdx
	jmp	done
		
		
OLDisplayGroupSetMoniker	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayGroupSetNumItems --
		MSG_GEN_DISPLAY_GROUP_SET_NUM_ITEMS for OLDisplayGroupClass

DESCRIPTION:	Set the number of items in a list

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - The message

	cx:dx - list
	bp- selected item

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
OLDisplayGroupSetNumItems	method dynamic	OLDisplayGroupClass,
					MSG_GEN_DISPLAY_GROUP_SET_NUM_ITEMS

	;
	; note that as we are using INSERT_AT_FRONT, we do the
	; MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION first as the
	; MSG_GEN_DYNAMIC_LIST_INITIALIZE sets GIGS_NONE
	;
	call	FindNumDisplays
	push	ax				;save number

	movdw	bxsi, cxdx

	mov	cx, bp				;cx = selected item
	inc	bp				;abort if -1
	jz	noSelection
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
noSelection:

	pop	cx				;cx = number
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

	ret

OLDisplayGroupSetNumItems	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNumDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the number of usable displays

CALLED BY:	OLDisplayGroupSetNumItems, OLDisplayGroupTileDisplays
PASS:		*ds:si	- display group
RETURN:		ax - number of usable displays
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNumDisplays		proc	far
	.enter
	clr	ax				;child number
	push	ax, ax				;initial child
	mov	bx, offset GI_link
	push	bx				;LinkPart
	mov	bx, SEGMENT_CS
	push	bx
	mov	bx, offset FindNumDisplaysCallback
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren		;ax = number
	.leave
	ret
FindNumDisplays		endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindNumDisplaysCallback

DESCRIPTION:	Find a display by number

CALLED BY:	INTERNAL

PASS:
	*es:di - display group
	*ds:si - display
	ax - count

RETURN:
	carry - clear
	ax - updated

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
FindNumDisplaysCallback	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	dontCount			; not usable, don't count

	; Removed on 11/13/93 by Don, as minimized windows should still
	; be accessed via the Window menu. Logic here *must* match that
	; in FindDisplayCallback() in cwinDisplay.asm
	;
;;;	mov	di, ds:[si]
;;;	add	di, ds:[di].Vis_offset
;;;	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
;;;	jnz	dontCount
	inc	ax
dontCount:
	clc
	ret

FindNumDisplaysCallback	endp

MDIAction ends


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupBringDisplayToTop

DESCRIPTION:	Finds first Display in window list & brings it to the top.

PASS:
	*ds:si - instance data
	es - segment of OLDisplayGroupClass

	ax - MSG_OL_DISPLAY_GROUP_BRING_FIRST_DISPLAY_TO_TOP

RETURN:
	Nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupBringDisplayToTop	method dynamic	OLDisplayGroupClass, \
		MSG_OL_DISPLAY_GROUP_BRING_FIRST_DISPLAY_TO_TOP

	;FIRST, check to see if any window currently has the target window
	;exclusive -- if so, we don't want to mess with anything at all.

	tst	ds:[di].OLDGI_targetExcl.FTVMC_OD.handle
	jnz	done			;skip if have a targeted window...

	; Since we change the vis children ordering of the GenDisplayGroup when 
	; a GenDisplay is brought to the top or lowered to the bottom, we can
	; just use the first visible child (hopefully it is a GenDisplay).

	mov	cx, 0			; get first child
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock	; carry clear if found (^lcx:dx)
	jc	done			; not found

	mov	bx, cx
	mov	si, dx

	;If a GenDisplay found, bring it to the top.

	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

done:
	ret
OLDisplayGroupBringDisplayToTop	endm

MDICommon	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupSpecSetUsable

DESCRIPTION:	Update child GenDisplays on MSG_SPEC_SET_USABLE.

PASS:		*ds:si - instance data
		es - segment of OLDisplayGroupClass

		ax - MSG_SPEC_SET_USABLE
		dl	- VisUpdateMode

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/16/92		Initial version
	brianc	9/2/92		removed if'ed out code to evaluate startup
					mode

------------------------------------------------------------------------------@

OLDisplayGroupSpecSetUsable	method dynamic	OLDisplayGroupClass, \
						MSG_SPEC_SET_USABLE
	;
	; let superclass handle
	;
	push	dx
	mov	di, offset OLDisplayGroupClass
	call	ObjCallSuperNoLock
	pop	dx
	;
	; Send update message to children GenDisplays.  We cannot use the
	; active list as the GenDisplays remove themselves from it when
	; unbuilt.
	;
	mov	ax, MSG_META_UPDATE_WINDOW
	mov	cx, 0				; UpdateWindowFlags
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	GenSendToChildren
	ret
OLDisplayGroupSpecSetUsable	endm

ActionObscure	ends


MDIAction	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupTileDisplays --
				MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS

DESCRIPTION:	This message are sent by the "tile" menu item in the
		MDIWindowMenu.

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/28/92		initial version

------------------------------------------------------------------------------@

OLDisplayGroupTileDisplays	method dynamic	OLDisplayGroupClass, \
				MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS

numDisplays	local	word
numChildren	local	word
height		local	word
disp		local	optr
dispCounter	local	word
numCols		local	word
colCounter	local	word
numRows		local	word
rowCounter	local	word
dcWidth		local	word
dcHeight	local	word
colWidth	local	word
rowHeight	local	word
vertTiling	local	word

	.enter

if _NIKE
	; must send notification in case we are switching between
	; tiled vertically and tiled horizontally.
	;
	push	bp
	mov	ax, MSG_OL_DISPLAY_SEND_NOTIFICATION
	call	VisCallFirstChild
	pop	bp
endif

	;
	; must go into overlapping mode to do tiling
	;
	push	bp
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; Set tiled.  Must do after setting overlapped.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLDGI_states, mask OLDGS_TILED

	;
	; determine horizontally or vertically based tiling (default to
	; horizontal)
	;
	mov	vertTiling, FALSE
	mov	ax, HINT_DISPLAY_GROUP_TILE_HORIZONTALLY
	call	ObjVarFindData		; horiz hint?
	jc	haveDirection		; yes, horiz
	mov	ax, HINT_DISPLAY_GROUP_TILE_VERTICALLY
	call	ObjVarFindData		; vert hint?
	jnc	haveDirection		; no, horiz
	mov	vertTiling, TRUE	; else, vert
haveDirection:
	;
	; get number of children (hopefully all GenDisplays), do nothing if
	; no children
	;
	call	FindNumDisplays		; ax = num USABLE displays
	tst	ax			; if no displays, done
	LONG jz	done
	mov	numDisplays, ax
	;
	; get vis-bounds of GenDisplayGroup
	;
	mov	ax, MSG_VIS_GET_BOUNDS
	push	bp
	call	ObjCallInstanceNoLock	; ax=left, bp=top, cx=right, dx=bottom
	sub	cx, ax			; cx = width
	sub	dx, bp			; dx = height
	pop	bp
	mov	dcWidth, cx
	mov	dcHeight, dx
	;
	; compute layout of displays (number of rows X number of columns)
	;
	mov	dx, numDisplays
	clr	cx			; dx.cx = WWFixed
	call	GrSqrRootWWFixed	; dx.cx = sqrt
	mov	height, dx		; (truncate)

	mov	dispCounter, 0
	;
	; loop over columns, resizing each GenDisplay in that column
	;
	mov	dx, numDisplays		; dx.cx = dividend
	clr	cx
	mov	bx, height		; bx.ax = divisor
	clr	ax
	call	GrUDivWWFixed		; dx.cx = quotient
	mov	numCols, dx		; (truncate)
	;
	; get width of each column
	;
	mov	dx, dcWidth		; dx.cx = dividend
	tst	vertTiling		; vert tiling?
	jz	haveColWidth		; no
	mov	dx, dcHeight		; dx.cx = dividend
haveColWidth:
	clr	cx
	mov	bx, numCols		; bx.ax = divisor
	clr	ax
	call	GrUDivWWFixed		; dx.cx = quotient
	mov	colWidth, dx		; (truncate)

	mov	colCounter, 0
colLoop:
	mov	ax, colCounter
	cmp	ax, numCols
	LONG jge	afterColLoop

	mov	ax, numDisplays
	sub	ax, dispCounter
	cmp	ax, height
	jle	notLastCol

	mov	ax, numDisplays
	sub	ax, dispCounter
	mov	bx, height
	shl	bx, 1
	cmp	ax, bx
	jae	notLastCol

	mov	ax, numDisplays
	sub	ax, dispCounter
	mov	numRows, ax
	jmp	afterNumRows

notLastCol:
	mov	ax, height
	mov	numRows, ax
afterNumRows:
	;
	; loop over GenDisplays in each column
	;

	;
	; get height of each GenDisplay in this column
	;
	mov	dx, dcHeight		; dx.cx = dividend
	tst	vertTiling		; vert tiling?
	jz	haveDCHeight		; no
	mov	dx, dcWidth		; dx.cx = dividend
haveDCHeight:
	clr	cx
	mov	bx, numRows		; bx.ax = divisor
	clr	ax
	call	GrUDivWWFixed		; dx.cx = quotient
	mov	rowHeight, dx		; (truncate)

	mov	rowCounter, 0
rowLoop:
	mov	ax, rowCounter
	cmp	ax, numRows
	LONG jge	afterRowLoop

	mov	cx, dispCounter
	call	FindDisplayByNumber
	mov	disp.handle, cx
	mov	disp.chunk, dx
	or	cx, dx
	jcxz	nextItemInRow
	;
	; compute y position
	;
	mov	dx, rowHeight
	clr	cx
	mov	bx, rowCounter
	clr	ax
	call	GrMulWWFixed		; dx.cx = answer
	mov	di, dx			; save temporarily
	;
	; compute x position
	;
	mov	dx, colWidth
	clr	cx
	mov	bx, colCounter
	clr	ax
	call	GrMulWWFixed		; dx.cx = answer
	mov	cx, dx			; cx = x position
	;
	; set GenDisplay position
	;
	push	si, bp
	mov	bx, disp.handle
	mov	si, disp.chunk
	mov	ax, MSG_GEN_SET_WIN_POSITION
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	dh, WPT_AT_RATIO
	tst	vertTiling		; vert tiling? (check before bp trashed)
	mov	bp, di			; retreive y position
	jz	havePos			; no
	xchg	cx, bp
havePos:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bp
	;
	; set GenDisplay size
	;
	push	si, bp
	mov	bx, disp.handle
	mov	si, disp.chunk
	tst	vertTiling		; vert tiling? (check before bp trashed)
	mov	cx, colWidth		; cx = width
	mov	bp, rowHeight		; bp = height
	jz	haveSize		; no
	xchg	cx, bp
haveSize:
	mov	ax, MSG_GEN_SET_WIN_SIZE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	dh, WST_AS_RATIO_OF_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bp
nextItemInRow:
	inc	dispCounter
	inc	rowCounter
	jmp	rowLoop

afterRowLoop:
	inc	colCounter
	jmp	colLoop
	
afterColLoop:

done:
	.leave
	ret

OLDisplayGroupTileDisplays	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayGroupSwapDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap display positions

CALLED BY:	MSG_GEN_DISPLAY_GROUP_SWAP_DISPLAYS
PASS:		*ds:si	= OLDisplayGroupClass object
		ds:di	= OLDisplayGroupClass instance data
		ds:bx	= OLDisplayGroupClass object (same as *ds:si)
		es 	= segment of OLDisplayGroupClass
		ax	= message #
		cx	= display vis position (0..n-1)
		dx	= display vis position (0..n-1)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

OLDisplayGroupSwapDisplays	method dynamic OLDisplayGroupClass, 
					MSG_GEN_DISPLAY_GROUP_SWAP_DISPLAYS
dispPos		local	word		push	dx
display		local	optr
displaySize	local	Point
displayPosition	local	Point
	.enter

	test	ds:[di].OLDGI_states, mask OLDGS_MAXIMIZED
	jnz	nextWin			; if maximed, no need to swap positions

	call	findDisplay
	jc	done			; do nothing if not found

	movdw	ss:[display], cxdx

	push	si
	call	getDisplayPositionAndSize
	pop	si

	mov	ss:[displayPosition].P_x, ax
	mov	ss:[displayPosition].P_y, di
	mov	ss:[displaySize].P_x, cx
	mov	ss:[displaySize].P_y, dx

	mov	cx, ss:[dispPos]
	call	findDisplay
	jc	done			; do nothing if not found

	push	si
	call	getDisplayPositionAndSize

	xchg	ss:[displayPosition].P_x, ax
	xchg	ss:[displayPosition].P_y, di
	xchg	ss:[displaySize].P_x, cx
	xchg	ss:[displaySize].P_y, dx
	call	setDisplayPositionAndSize

	movdw	bxsi, ss:[display]
	mov	ax, ss:[displayPosition].P_x
	mov	di, ss:[displayPosition].P_y
	mov	cx, ss:[displaySize].P_x
	mov	dx, ss:[displaySize].P_y
	call	setDisplayPositionAndSize
	pop	si
nextWin:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	bxsi, ds:[di].OLDGI_targetExcl.FTVMC_OD
	mov	ax, MSG_MO_NEXT_WIN
	clr	di
	call	ObjMessage
done:
	.leave
	ret


findDisplay label near
	push	bp
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock
	pop	bp
	retn

getDisplayPositionAndSize label near
	push	bp
	movdw	bxsi, cxdx
	mov	ax, MSG_VIS_GET_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	sub	cx, ax
	sub	dx, bp
	mov	di, bp
	pop	bp
	retn

setDisplayPositionAndSize label near
	push	bp
	push	cx, dx
	mov	cx, ax
	mov	bp, di
	mov	ax, MSG_GEN_SET_WIN_POSITION
	mov	dx, WPT_AT_SPECIFIC_POSITION shl 8 or VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, bp

	mov	ax, MSG_GEN_SET_WIN_SIZE
	mov	dx, WST_AS_RATIO_OF_PARENT shl 8 or VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	retn

OLDisplayGroupSwapDisplays	endm

endif	; if _NIKE ------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayGroupRefitDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Refit display, so displays will remain "tiled".

CALLED BY:	MSG_OL_DISPLAY_GROUP_REFIT_DISPLAY
PASS:		*ds:si	= OLDisplayGroupClass object
		ds:di	= OLDisplayGroupClass instance data
		ds:bx	= OLDisplayGroupClass object (same as *ds:si)
		es 	= segment of OLDisplayGroupClass
		ax	= message #
		cx	= display to refit (display 0 or 1)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

OLDisplayGroupRefitDisplay	method dynamic OLDisplayGroupClass, 
					MSG_OL_DISPLAY_GROUP_REFIT_DISPLAY
refitDisplayNum	local	word		push	cx
refitDisplay	local	optr
otherDisplay	local	optr
displaySize	local	Point
displayPosition	local	Point
	.enter

	test	ds:[di].OLDGI_states, mask OLDGS_TILED
	LONG jz	done				; if ~tiled, no need to refit

	push	bp
	mov	ax, MSG_VIS_COUNT_CHILDREN
	call	ObjCallInstanceNoLock
	pop	bp
	cmp	dx, 2
	LONG jne done				; can't deal with more than 2
						; and no need to refit if < 2

	mov	cx, ss:[refitDisplayNum]	; cx = display to refit
EC <	cmp	cx, 2							>
EC <	ERROR_AE -1				; must be 0 or 1	>
	call	findDisplay
	LONG jc	done

	movdw	ss:[refitDisplay], cxdx

	mov	cx, ss:[refitDisplayNum]	; cx = display to refit
	xor	cx, 1				; cx = other display
	call	findDisplay
	LONG jc	done

	movdw	ss:[otherDisplay], cxdx

	push	si
	call	getDisplayPositionAndSize	; pos = (ax,di), size = (cx,dx)
	pop	si

	mov	ss:[displayPosition].P_x, ax
	mov	ss:[displayPosition].P_y, di
	mov	ss:[displaySize].P_x, cx
	mov	ss:[displaySize].P_y, dx

	mov	ax, HINT_DISPLAY_GROUP_TILE_VERTICALLY
	call	ObjVarFindData

	pushf
	movdw	cxdx, ss:[refitDisplay]
	call	getDisplayPositionAndSize
	popf
	jc	vertical

	tst	ss:[displayPosition].P_x
	jg	easyHorizontal

	tst	ax				; it's possible that both
	jnz	5$				;  displays are at x.pos = 0

	cmp	cx, ss:[displaySize].P_x	; then we leave the narrower
	jl	easyHorizontal			;  display on the left side
5$:
	sub	ax, ss:[displaySize].P_x
	jz	done				; skip if no change

	add	cx, ax
	jns	10$
	clr	cx
10$:
	mov	ax, ss:[displaySize].P_x
	call	setDisplayPositionAndSize
	jmp	done

easyHorizontal:
	cmp	cx, ss:[displayPosition].P_x
	je	done				; skip if no change

	mov	cx, ss:[displayPosition].P_x
	mov	dx, ss:[displaySize].P_y
	call	setDisplaySize			; set display size and 'pop bp'
	jmp	done

vertical:
	tst	ss:[displayPosition].P_y
	jg	easyVertical

	tst	di				; it's possible that both
	jnz	15$				;  displays are at y.pos = 0

	cmp	dx, ss:[displaySize].P_y	; then we leave the shorter
	jl	easyVertical			;  display on top
15$:
	sub	di, ss:[displaySize].P_y
	jz	done				; skip if no change

	add	dx, di
	jns	20$
	clr	dx
20$:
	mov	di, ss:[displaySize].P_y
	call	setDisplayPositionAndSize
	jmp	done

easyVertical:
	cmp	dx, ss:[displayPosition].P_y
	je	done				; skip if no change

	mov	cx, ss:[displaySize].P_x
	mov	dx, ss:[displayPosition].P_y
	call	setDisplaySize			; set display size and 'pop bp'
done:
	.leave
	ret

setDisplaySize:
	push	bp
	mov	bp, dx
	mov	ax, MSG_GEN_SET_WIN_SIZE
	mov	dx, WST_AS_RATIO_OF_PARENT shl 8 or VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	retn

OLDisplayGroupRefitDisplay	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayGroupResizeDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize displays

CALLED BY:	MSG_GEN_DISPLAY_GROUP_RESIZE_DISPLAYS
PASS:		*ds:si	= OLDisplayGroupClass object
		ds:di	= OLDisplayGroupClass instance data
		ds:bx	= OLDisplayGroupClass object (same as *ds:si)
		es 	= segment of OLDisplayGroupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

OLDisplayGroupResizeDisplays	method dynamic OLDisplayGroupClass, 
					MSG_GEN_DISPLAY_GROUP_RESIZE_DISPLAYS
	test	ds:[di].OLDGI_states, mask OLDGS_TILED
	jz	done			; if ~tiled, no need to resize

	mov	ax, MSG_VIS_COUNT_CHILDREN
	call	ObjCallInstanceNoLock
	cmp	dx, 2
	jb	done

	mov	ax, MSG_VIS_GET_BOUNDS
	call	VisCallFirstChild

	push	ax
	mov	ax, HINT_DISPLAY_GROUP_TILE_VERTICALLY
	call	ObjVarFindData
	pop	ax
	jc	vertical

	mov	cl, mask OLWMRS_RESIZING_LEFT
	tst	ax
	jg	resize
	mov	cl, mask OLWMRS_RESIZING_RIGHT
	jmp	resize

vertical:
	mov	cl, mask OLWMRS_RESIZING_UP
	tst	bp
	jg	resize
	mov	cl, mask OLWMRS_RESIZING_DOWN
resize:
	mov	ax, MSG_OL_DISPLAY_RESIZE
	GOTO	VisCallFirstChild
done:
	ret
OLDisplayGroupResizeDisplays	endm

endif		; if _NIKE ----------------------------------------------------

MDIAction	ends

;--------------------------------

LessUsedGeometry segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupNotifyGeometryValid 
		-- MSG_VIS_NOTIFY_GEOMETRY_VALID for OLDisplayGroupClass

DESCRIPTION:	We intercept this here to detect when the DisplayControl
		has resized. If we have a maximized display, we want it
		to refit itself.

PASS:		*ds:si 	- instance data
		ax 	- METHOD

RETURN:		nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@

OLDisplayGroupNotifyGeometryValid	method dynamic	OLDisplayGroupClass,
						MSG_VIS_NOTIFY_GEOMETRY_VALID

	mov	di, offset OLDisplayGroupClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDGI_states, mask OLDGS_MAXIMIZED
	jz	checkTile		;skip if not maximized...

	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID
	jz	done			;a little weird, but we'll assume 
					;  geometry didn't change if this is
					;  clear, and thus can avoid the RE_-
					;  MAXIMIZE and subsequent visual
					;  invalidation of the display.  -cbh
					;  11/17/92.  

	mov	ax, MSG_OL_DISPLAY_RE_MAXIMIZE
	call	GenSendToChildren
done:
	ret

checkTile:
if TRACK_TILING
	test	ds:[di].OLDGI_states, mask OLDGS_TILED
	jz	done
	mov	ax, MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
	call	ObjCallInstanceNoLock
endif
	ret
OLDisplayGroupNotifyGeometryValid	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupRerecalcSize = MSG_VIS_RECALC_SIZE handler

DESCRIPTION:	This procedure returns the desired size of the DisplayControl,
		as specified in the application's .UI file.

PASS:		ds:*si	- instance data
		cx, dx = suggested size

RETURN:		cx, dx = desired size

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

DISPLAY_CONTROL_MIN_WIDTH	= 20
DISPLAY_CONTROL_MIN_HEIGHT	= 10

OLDisplayGroupRerecalcSize	method dynamic	OLDisplayGroupClass, \
							MSG_VIS_RECALC_SIZE
EC <	call    VisCheckVisAssumption      ;Make sure specific data exists >

	call	VisApplySizeHints	   ;do this early, to apply initial size
	;
	; No initial size set up, or only partially set up, get a desired size
	; from the child display and use that, but only if we're currently
	; maximizing things.
	;
	test	ds:[di].OLDGI_states, mask OLDGS_MAXIMIZED
	jz	doneWithDesired		   ;not maximized, get out.
	test	ds:[di].OLDGI_states, mask OLDGS_SIZE_INDEPENDENTLY_OF_DISPLAYS
	jnz	doneWithDesired		   ;sizing independently, get out

	push	cx, dx
	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock		; carry clear if found
	movdw	bxsi, cxdx
	pop	cx, dx
	jc	doneWithDesired			; not found, give up
	cmp	cx, 2				;RSA_CHOOSE_OWN_SIZE, 0, or 1:
	jle	3$				; 	skip this stuff
	dec	cx				;subtract 2 pixels for border
	dec	cx
3$:
	cmp	dx, 2				;RSA_CHOOSE_OWN_SIZE, 0, or 1:
	jle	6$				; 	skip this stuff
	dec	dx				;subtract 2 pixels for border
	dec	dx
6$:
	mov	ax, MSG_OL_WIN_RECALC_DISPLAY_SIZE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	inc	cx				;add 2 pixels for border
	inc	cx
	inc	dx
	inc	dx

doneWithDesired:
	mov	ax, DISPLAY_CONTROL_MIN_WIDTH	;minimum width
	mov	bx, DISPLAY_CONTROL_MIN_HEIGHT	;minimum height
	call	VisHandleMinResize	;keeps cx and dx over minimum
	ret
OLDisplayGroupRerecalcSize	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayGroupGetExtraSize = MSG_SPEC_GET_EXTRA_SIZE handler

DESCRIPTION:	This procedure returns the extra size for the DisplayControl.

PASS:		ds:*si	- instance data

RETURN:		cx, dx = extra size

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/17/92		initial version

------------------------------------------------------------------------------@

OLDisplayGroupGetExtraSize	method	dynamic	OLDisplayGroupClass, \
							MSG_SPEC_GET_EXTRA_SIZE
	clr	cx			; no extra size
	clr	dx
	ret
OLDisplayGroupGetExtraSize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupMoveResizeWin -- MSG_VIS_MOVE_RESIZE_WIN
		for OLDisplayGroupClass

OVERRIDES DEFAULT HANDLER BECAUSE DEFAULT HAS ERROR-CHECK WE DON'T WANT

DESCRIPTION:	DEFAULT routine to move/resize a window.  Calls WinResize
		to set window to be rectangular, with offset & size as
		specified by VI_bounds

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of OLDisplayGroupClass

	ax - MSG_VIS_MOVE_RESIZE_WIN

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
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@


OLDisplayGroupMoveResizeWin	method dynamic	OLDisplayGroupClass, \
						MSG_VIS_MOVE_RESIZE_WIN
	;check for window visibility preferences

;	call	OpenWinCheckVisibleConstraints	;this is a horrible thing to do.
						;  -cbh 4/28/93

;WHY ARE WE NOT CALLING THE SUPERCLASS HERE?

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	di, ds:[di].VCI_window
EC <	tst	di							>
EC <	ERROR_Z	OL_MOVE_RESIZE_NO_WINDOW				>

   	clr	cl				;normal bounds
	call	OpenGetLineBounds
	inc	ax				;allow for border
	inc	bx
	dec	cx
	dec	dx

	mov	si, mask WPF_ABS		;resize absolute (i.e. move)
	push	si
	clr	si
	clr	bp
	call	WinResize
	ret
OLDisplayGroupMoveResizeWin	endp

				
				


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupGetWinSizeInfo -- 
		MSG_SPEC_VUP_GET_WIN_SIZE_INFO for OLDisplayGroupClass

DESCRIPTION:	Returns size of window area, and any margins we use for icon
		areas.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VUP_GET_WIN_SIZE_INFO

RETURN:		cx, dx  - size of window area
		bp low  - margins at bottom edge of object
		bp high - margins to the right edge of object
		ax, cx, dx, bp - destroyed

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

OLDisplayGroupGetWinSizeInfo	method dynamic	OLDisplayGroupClass, \
				MSG_SPEC_VUP_GET_WIN_SIZE_INFO
	call	VisGetSize		;get our size
if (not _JEDIMOTIF)		; allow busting out of seams for JEDI
	sub	cx, 2			;account for two pixel border
	sub	dx, 2
endif
	clr	bp			;no margins
	ret
OLDisplayGroupGetWinSizeInfo	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayGroupInvalAllGeometry -- 
		MSG_VIS_INVAL_ALL_GEOMETRY for OLDisplayGroupClass

DESCRIPTION:	Invalidates all geometry in this win group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_INVAL_ALL_GEOMETRY

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
	chris	1/27/93         	Initial Version

------------------------------------------------------------------------------@

OLDisplayGroupInvalAllGeometry	method dynamic	OLDisplayGroupClass, \
				MSG_VIS_INVAL_ALL_GEOMETRY
	;
	; Force invalidation of our child displays.  
	; But only if our displays are maximized and
	; we're interacting with them for geometry.
	;
	test	ds:[di].OLDGI_states, mask OLDGS_MAXIMIZED
	jz	exit			   ;not maximized, get out.
	test	ds:[di].OLDGI_states, mask OLDGS_SIZE_INDEPENDENTLY_OF_DISPLAYS
	jnz	exit			   ;sizing independently, get out
	call	VisSendToChildren
exit:
	ret
OLDisplayGroupInvalAllGeometry	endm

LessUsedGeometry ends

