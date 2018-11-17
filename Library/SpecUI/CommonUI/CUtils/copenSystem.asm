COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Open
FILE:		openSystem.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLSystemClass	Open look System class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:

	$Id: copenSystem.asm,v 1.1 97/04/07 10:54:44 newdeal Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLSystemClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
				;flags for class
CommonUIClassStructures ends

;---------------------------------------------------

Init segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemInitialize -- MSG_META_INITIALIZE for OLSystemClass

DESCRIPTION:	Init the UI system object

PASS:
	*ds:si - instance data (for object in GenSystem class)
	ds:bx - instance data
	ds:di - gen instance data
	es - segment of GenSystemClass

	ax - MSG_META_INITIALIZE

	cx, dx, bp ?

RETURN:
	carry, ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version

------------------------------------------------------------------------------@

OLSystemInitialize	method dynamic	OLSystemClass, MSG_META_INITIALIZE

	CallMod	VisCompInitialize

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; There's only one system object -- start it out as having the
	; first level exclusive, which happens to be named "HGF_APP_EXCL"
	;
	mov	ax, mask HGF_APP_EXCL
	mov	ds:[di].OLSYI_focusExcl.HG_flags, ax
	mov	ds:[di].OLSYI_targetExcl.HG_flags, ax
	mov	ds:[di].OLSYI_modelExcl.HG_flags, ax
	mov	ds:[di].OLSYI_fullScreenExcl.HG_flags, ax

	; Mark as input/FTVMC node, so we get related messages -- Doug 2/5/93
	;
	ornf	ds:[di].VI_typeFlags, mask VTF_IS_INPUT_NODE
	ret

OLSystemInitialize	endm

			
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemGupQueryVisParent -- MSG_SPEC_GUP_QUERY_VIS_PARENT for
					   OLSystemClass

DESCRIPTION:	Respond to a query travaeling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLSystemClass
	ax - MSG_SPEC_GUP_QUERY_VIS_PARENT

	cx - SpecQueryVisParentType

RETURN: carry - set if query acknowledged, clear if not
	cx:dx - object discriptor of object to use for vis parent, else null
			if not acknowledged

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	VIS_PARENT_FOR_FIELD		-> default SCREEN
	VIS_PARENT_FOR_APPLICATION	-> default FIELD
	VIS_PARENT_FOR_BASE_GROUP	-> default FIELD
	VIS_PARENT_FOR_POPUP		-> default FIELD
	VIS_PARENT_FOR_URGENT		-> default FIELD

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

OLSystemGupQueryVisParent method OLSystemClass, MSG_SPEC_GUP_QUERY_VIS_PARENT

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
					; See if it is a field asking
	cmp	cx, SQT_VIS_PARENT_FOR_FIELD
	jne	ForNonField		; if not, branch
				; return OD of default screen
	mov	cx, ds:[di].GSYI_defaultScreen.handle
	mov	dx, ds:[di].GSYI_defaultScreen.chunk
	jmp	short	QueryAnswered

ForNonField:
				; return OD of default visible parent
	mov	cx, ds:[di].GSYI_defaultField.handle
	mov	dx, ds:[di].GSYI_defaultField.chunk
QueryAnswered:
	stc			; return query acknowledged
Done:
	ret

OLSystemGupQueryVisParent	endm

Init ends


HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemConsumeMessage

DESCRIPTION:	Consume the event so that the superclass will NOT provide
		default handling for it.

PASS:		*ds:si 	- instance data
		es     	- segment of OLSystemClass
		ax 	- message to eat

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version

------------------------------------------------------------------------------@

OLSystemConsumeMessage	method	OLSystemClass,	MSG_META_FORCE_GRAB_KBD,
						MSG_VIS_FORCE_GRAB_LARGE_MOUSE,
						MSG_VIS_FORCE_GRAB_MOUSE,
						MSG_META_GRAB_KBD,
						MSG_VIS_GRAB_LARGE_MOUSE,
						MSG_VIS_GRAB_MOUSE,
						MSG_META_RELEASE_KBD,
						MSG_VIS_RELEASE_MOUSE
	ret
	
OLSystemConsumeMessage	endm

HighUncommon ends


HighCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemGupQuery

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass

	ax - MSG_SPEC_GUP_QUERY

	cx - GenUpwardQueryType

RETURN: carry - set if query acknowledged, clear if not
	ax - segment of UI to use

ALLOWED TO DESTROY:
	cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	GUQT_UI_FOR_APPLICATION		-> default UI
	GUQT_UI_FOR_SCREEN		-> default UI
	GUQT_UI_FOR_FIELD		-> default UI


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/8/93		Moved to spui

------------------------------------------------------------------------------@

OLSystemGupQuery	method	OLSystemClass, MSG_SPEC_GUP_QUERY

	cmp	cx,GUQT_UI_FOR_MISC
	je	returnUI
	cmp	cx,GUQT_UI_FOR_APPLICATION
	je	returnUI
	cmp	cx,GUQT_UI_FOR_SCREEN
	je	returnUI
	cmp	cx,GUQT_UI_FOR_FIELD
	je	returnUI

	clc				; can't answer query -- no superclass
					; handler other that the default, &
					; no gen parent for it to call.
	ret

returnUI:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
				; return segment of default UI
	mov	ax, ds:[di].GSYI_defaultUI
	stc			; return query acknowledged
	ret

OLSystemGupQuery	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSystemBringGeodeToTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Default behavior for window of a geode having been clicekd in -
		raise layer to top, grab focus, target for geode from
		it's parent FT node object, & up CPU priority of the geode's
		thread(s0.

		Is also called from GenApplication's default handler for
		MSG_GEN_BRING_TO_TOP.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP

		cx	- geode, or 0 if no geode to grab FT for
		dx	- LayerID to raise, or 0 if no layer to raise
		bp	- parent window

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLSystemBringGeodeToTop	method	OLSystemClass,
					MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
	tst	cx
	jz	raiseLowerCommon

	; Get GeodeWinFlags for geode -- is this geode focusable? targetable?
	; modelable?  Give it whatever it wants.
	;
	mov	di, mask MAEF_GRAB
	mov	bx, cx
	call	WinGeodeGetFlags
	test	ax, mask GWF_FOCUSABLE
	jz	10$
	ornf	di, mask MAEF_FOCUS
10$:
	test	ax, mask GWF_TARGETABLE
	jz	20$
	ornf	di, mask MAEF_TARGET
20$:
	test	ax, mask GWF_MODELABLE
	jz	30$
	ornf	di, mask MAEF_MODEL
30$:
	test	ax, mask GWF_FULL_SCREEN
	jz	40$
	ornf	di, mask MAEF_FULL_SCREEN
40$:

raiseLowerCommon:
	mov	ax, mask WPF_LAYER
	FALL_THRU	OLSystemRaiseLowerCommon

OLSystemBringGeodeToTop	endm


OLSystemRaiseLowerCommon	proc	far
	push	cx, di			; save geode, ft args

	; Raise/Lower window layer that's been clicked on below field
	;

	mov	di, bp			; get parent window
	tst	di
	jz	noLayer
	tst	dx
	jz	noLayer
	call	WinChangePriority
noLayer:

	pop	bx, di			; get geode, ft args
	tst	bx
	jz	done

	; Grab/Release the geode of focus & target exclusives, from within its
	; parent FT node
	;
	call	WinGeodeGetInputObj
	push	cx, dx
	call	WinGeodeGetParentObj
	mov	bx, cx			; ^lbx:si is parentObj
	mov	si, dx
	pop	cx, dx			; ^lcx:dx is InputObj

	mov	bp, di			; get focus/target flags

	test	di, mask MAEF_GRAB
	pushf

	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	popf
	jnz	grabParent		; if grabbing, tell parent to grab, too.
					; If releasing, ask parent FT node to
					; refigure who should have exclusives.

	; Then, ask parent FT node to make sure something legitimate has the
	; focus/target.
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret

grabParent:
	; Issue the same call to the parent object, telling it to make the
	; same adjustments in *its* parent for itself.

	;
	; Don't send the model up to the parent because the field
	; object is usually a parent, and the field object is not a
	; model node.
	; 8/11/95 - ptrinh
	;
	; Just clear out the MODEL bit and see if there's anything else for
	; the parent to do -- ardeb 10/5/95
	;
	andnf	bp, not mask MAEF_MODEL
	test	bp, mask MAEF_TARGET or mask MAEF_FOCUS
	jz	done

	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	ornf	bp, mask MAEF_NOT_HERE
	movdw	cxdx, bxsi		; ^lcx:dx <- object doing the grab
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	done
OLSystemRaiseLowerCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSystemLowerGeodeToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Lower layer to bottom, release focus, target for geode from
		its parent FT node object, then give anything else that
		should have the focus/target the exclusives.  Is called from 
		GenApplication's default handler for MSG_GEN_LOWER_TO_BOTTOM.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM

		cx	- geode, or 0 if no geode to release FT for
		dx	- LayerID to lower, or 0 if no layer to lower
		bp	- parent window

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLSystemLowerGeodeToBottom	method	OLSystemClass,
					MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM
	mov	ax, mask WPF_LAYER or mask WPF_PLACE_LAYER_BEHIND
	mov	di, mask MAEF_FOCUS or mask MAEF_TARGET or mask MAEF_MODEL or \
			mask MAEF_FULL_SCREEN
	GOTO	OLSystemRaiseLowerCommon


OLSystemLowerGeodeToBottom	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSystemGetModalGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns current modal geode, if any

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_SYSTEM_GET_MODAL_GEODE

RETURN:		^lcx:dx	- InputObj, else NULL 
		bp	- geode, else NULL 

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLSystemGetModalGeode	method dynamic	OLSystemClass, \
				MSG_GEN_SYSTEM_GET_MODAL_GEODE
	mov	cx, ds:[di].OLSYI_modalGeode.BG_OD.handle
	mov	dx, ds:[di].OLSYI_modalGeode.BG_OD.chunk
	mov	bp, ds:[di].OLSYI_modalGeode.BG_data
	ret
OLSystemGetModalGeode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSystemEnsureActiveFT
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

OLSystemEnsureActiveFT	method dynamic	OLSystemClass, \
				MSG_META_ENSURE_ACTIVE_FT

	call	GetDefaultScreenWin	; get di = screen window
	mov	ax, di			; pass in ax
	mov	bx, offset OLSYI_focusExcl
	mov	bp, offset OLSYI_nonModalFocus
	call	EnsureActiveFTCommon
	ret

OLSystemEnsureActiveFT	endm

HighCommon ends

;----------------

HighUncommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSystemNotifyNoFocusWithinNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that a suitable focus object for within
		this system can't be found in our MSG_META_ENSURE_ACTIVE_FT
		handler.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLSystemNotifyNoFocusWithinNode	method dynamic	OLSystemClass, \
				MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE

	; Hmmm.. Well, there's nothing here for the user to do.  Let's bail
	; to DOS, where at least there's a prompt...
	;
	mov	ax, SST_CLEAN_FORCED
	call	SysShutdown
	ret

OLSystemNotifyNoFocusWithinNode	endm

HighUncommon ends

;-----------------

HighCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureActiveFTCommon

DESCRIPTION:	If nothing currently has focus or target exclusives within
		this node, then find most deserving object(s) to give the
		focus & target, & give them the exclusives.  Eligible objects
		are (see enhancements in code comments):

	; Full Screen (used only if in transparent detach mode):
	;	1) Object currently having full screen
	;	2) Top window of LAYER_PRIO_STD  priority that is either
	;	   a GenField in which something has the full screen
	;	   (in which case GenField is given full screen) or
	;	   whose owning geode is GWF_FULL_SCREEN (full screen goes
	;	   to geode)
	;	3) NULL

	; Target:
	;	1) Object currently having target
	;	2) Top window of LAYER_PRIO_STD  priority that is either
	;	   a GenField in which something has the target
	;	   (in which case GenField is given target) or
	;	   whose owning geode is GWF_TARGETABLE (target goes to geode)
	;	3) Top window of LAYER_PRIO_ON_BOTTOM priority that is either
	;	   a GenField in which something has the target
	;	   (in which case GenField is given target) or
	;	4) Top window of LAYER_PRIO_ON_TOP priority that is either
	;	   a GenField in which something has the target
	;	   (in which case GenField is given target) or
	;	   whose owning geode is GWF_TARGETABLE (target goes to geode)
	;	5) NULL
			
	; Focus:
	;	1) Object currently having focus
	;	3) Last non-modal object to have or request the exlusive
	;	4) Object having Target exclusive
	;	5) Top window of LAYER_PRIO_STD priority that is either
	;	   a GenField in which something has the focus
	;	   (in which case GenField is given focus) or
	;	   whose owning geode is GWF_FOCUSABLE (geode is given focus)
	;	6) Top window of LAYER_PRIO_ON_BOTTOM priority that is either
	;	   a GenField in which something has the focus
	;	   (in which case GenField is given focus) or
	;	   whose owning geode is GWF_FOCUSABLE (geode is given focus)
	;	6) Top window of LAYER_PRIO_ON_TOP priority that is either
	;	   a GenField in which something has the focus
	;	   (in which case GenField is given focus) or
	;	   whose owning geode is GWF_FOCUSABLE (geode is given focus)

CALLED BY:	INTERNAL
		OLSystemEnsureActiveFT
		OLFieldEnsureActiveFT

PASS:		*ds:si	- Focus/Target node
		ax	- window to look on (Screen or Field)
		bx	- offset to focusExcl, followed by targetExcl,
			  followed by fullScreenExcl
			  in Vis master part
		bp 	- offset to nonModalFocus, in Vis master part


RETURN:		nothing

DESTROYED:
		bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Initial version
------------------------------------------------------------------------------@

EnsureActiveFTCommon	proc	far

nonModalFocusOffset	local	word	push	bp
focusExclOffset		local	word	push	bx
parentWindow		local	word	push	ax
priority		local	word
avoidOptrTarget		local	optr
avoidOptrFocus		local	optr
windowOwner		local	hptr

	.enter
	;
	; set windowOwner
	;
.assert (offset OLSYI_focusExcl ne OLFI_focusExcl)
	clr	windowOwner			; field - any window owner
	cmp	bx, offset OLFI_focusExcl	; from field object?
	je	fromField			; yes, any window owner

EC <	cmp	bx, offset OLSYI_focusExcl				>
EC <	ERROR_NE	0						>
	mov	windowOwner, handle ui		; only allow windows owned by ui

	;
	; if we have a preferred LayerPrioirty to search first, pass it
	;
fromField:
	clr	ax			; use ax register as a quick zero
	clrdw	avoidOptrTarget, ax
	clrdw	avoidOptrFocus, ax
	mov	priority, ax			; assume no pref
	mov	ax, TEMP_META_ENSURE_ACTIVE_FT_LAYER_PRIORITY_PREFERENCE
	call	ObjVarFindData		; carry set if found, ds:bx = data
	jnc	noPref

	mov	ax, ds:[bx].EAFTPPD_priority	; save preferred LayerPriority
	mov	priority, ax
	mov	ax, ds:[bx].EAFTPPD_avoidOptr.handle	; save avoidOptr
	mov	avoidOptrTarget.handle, ax
	mov	avoidOptrFocus.handle, ax
	mov	ax, ds:[bx].EAFTPPD_avoidOptr.chunk
	mov	avoidOptrTarget.chunk, ax
	mov	avoidOptrFocus.chunk, ax
	call	ObjVarDeleteDataAt	; nuke the vardata (doesn't need AX)
noPref:

	; FULL SCREEN

	;	0) If in transparent detach mode
	;	
	call	UserGetLaunchModel	;ax = UILaunchModel
	cmp	ax, UILM_TRANSPARENT
	jne	fullScreenDone

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;	1) Object currently having full screen
	;
	mov	bx, focusExclOffset
	cmp	ds:[di][bx + 2*(size HierarchicalGrab)].HG_OD.handle, 0
	jnz	fullScreenDone

	;	2) Top full screenable window of LAYER_PRIO_STD priority
	;	   (InputOD if is a GenField run by the UI, else
	;	   InputObj of owning Geode)
	;
	mov	cx, mask GWF_FULL_SCREEN or (LAYER_PRIO_STD shl offset WPD_LAYER)
	mov	di, parentWindow	; put parent window to look under in di
	mov	ax, windowOwner
	call	FindFTObjectOfPrioOnWin
	tst	cx
	jnz	giveFullScreen

	;	3) NULL
	;
	clr	cx, dx

giveFullScreen:

	; Give FULL SCREEN exclusive
	;
	push	bp
	mov	bp, mask MAEF_GRAB or mask MAEF_FULL_SCREEN
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	bp

fullScreenDone:
	; TARGET
	;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;	1) Object currently having target
	;
	mov	bx, focusExclOffset
	cmp	ds:[di][bx + size HierarchicalGrab].HG_OD.handle, 0
	jnz	targetDone

	mov	di, parentWindow	; put parent window to look under in di

	;	1.5) WIN_PRIO_STD and WIN_PRIO_STD+1 windows of passed
	;		LayerPriority and opposite LayerPriority
	;		(LAYER_PRIO_ON_TOP if pref=LAYER_PRIO_STD,
	;		LAYER_PRIO_STD if pref=LAYER_PRIO_ON_TOP), if any
	;
	mov	cx, priority		; cx = priority
	jcxz	noTargetPrefClear	; no default target
	movdw	bxax, avoidOptrTarget
	mov	dx, windowOwner
	call	TryPreferredAndVariations
	jc	giveTarget		; give target to ^lcx:dx
	jz	noTargetPref		; default to avoidOptrTarget if needed
					; else, no default target
noTargetPrefClear:
	clrdw	avoidOptrTarget
noTargetPref:

	;	2) Top targetable window of LAYER_PRIO_STD priority
	;	   (InputOD if is a GenField run by the UI, else
	;	   InputObj of owning Geode)
	;
	mov	cx, mask GWF_TARGETABLE or (LAYER_PRIO_STD shl offset WPD_LAYER)
	mov	ax, windowOwner
	call	FindFTObjectOfPrioOnWin
	tst	cx
	jnz	giveTarget

	;	3) Top targetable window of LAYER_PRIO_ON_BOTTOM priority
	;	   (InputOD if is a GenField run by the UI, else
	;	   InputObj of owning Geode)
	;
	mov	cx, mask GWF_TARGETABLE or \
			(LAYER_PRIO_ON_BOTTOM shl offset WPD_LAYER)
				; ax is still windowOwner
	call	FindFTObjectOfPrioOnWin
	tst	cx
	jnz	giveTarget

	;	4) Top targetable window of LAYER_PRIO_ON_TOP priority
	;	   (InputOD if is a GenField run by the UI, else
	;	   InputObj of owning Geode)
	;
	mov	cx, mask GWF_TARGETABLE or \
			(LAYER_PRIO_ON_TOP shl offset WPD_LAYER)
				; ax is still windowOwner
	call	FindFTObjectOfPrioOnWin
	tst	cx
	jnz	giveTarget

	;	default to the thing that just gave up the focus/target
	;
	;	5) NULL (avoidOptrTarget may be null)
	;
	movdw	cxdx, avoidOptrTarget
giveTarget:

	; Give TARGET, MODEL exclusives
	;
	push	bp
	mov	bp, mask MAEF_GRAB or mask MAEF_TARGET or mask MAEF_MODEL
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	bp

targetDone:
	
	;  FOCUS
	;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;	1) Object currently having focus
	mov	bx, focusExclOffset
	tst	ds:[di][bx].HG_OD.handle
	LONG jnz	focusDone

	;	1.5) WIN_PRIO_STD and WIN_PRIO_STD+1 windows of passed
	;		LayerPriority and opposite LayerPriority
	;		(LAYER_PRIO_ON_TOP if pref=LAYER_PRIO_STD,
	;		LAYER_PRIO_STD if pref=LAYER_PRIO_ON_TOP), if any
	;
	mov	cx, priority		; cx = priority
	jcxz	noFocusPrefClear	; no default focus
	mov	di, parentWindow	; put parent window to look under in di
	movdw	bxax, avoidOptrFocus
	mov	dx, windowOwner
	call	TryPreferredAndVariations
	jc	giveFocus		; give focus to ^lcx:dx
	jz	noFocusPref		; default to avoidOptrFocus if needed
					; else, no default focus
noFocusPrefClear:
	clrdw	avoidOptrFocus
noFocusPref:

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

;
; Modal object should already have focus, & be covered under (1) above.  Should
; code be added to "force" reevaluation, should still be OK not to have this,
; as end MSG_META_MUP_ALTER_FTVMC_EXCL doesn't pass MAEF_MODAL, & hence, won't
; mess with any current modal state.
;	;	2) Geode owning top system modal window
;	;
;	mov	cx, ds:[di].OLSYI_modalGeode.BG_OD.handle
;	mov	dx, ds:[di].OLSYI_modalGeode.BG_OD.chunk
;	tst	cx
;	jnz	giveFocus
;
	;	3) Last non-modal geode to have or request the exlusive
	;
	mov	bx, nonModalFocusOffset
	mov	cx, ds:[di][bx].handle
	mov	dx, ds:[di][bx].chunk
	tst	cx
	jnz	giveFocus

	;	4) Geode having Target exclusive
	;
	mov	bx, focusExclOffset
	mov	cx, ds:[di][bx + size HierarchicalGrab].HG_OD.handle
	mov	dx, ds:[di][bx + size HierarchicalGrab].HG_OD.chunk
	tst	cx
	jnz	giveFocus

	mov	di, parentWindow	; put parent window to look under in di

	;	5) Top focusable window of LAYER_PRIO_STD priority
	;	   (InputOD if is a GenField run by the UI, else
	;	   InputObj of owning Geode)
	;
	mov	cx, mask GWF_FOCUSABLE or (LAYER_PRIO_STD shl offset WPD_LAYER)
	mov	ax, windowOwner
	call	FindFTObjectOfPrioOnWin
	tst	cx
	jnz	giveFocus

	;	6) Top focusable window of LAYER_PRIO_ON_BOTTOM priority
	;	   (InputOD if is a GenField run by the UI, else
	;	   InputObj of owning Geode)
	;
	mov	cx, mask GWF_FOCUSABLE or \
				(LAYER_PRIO_ON_BOTTOM shl offset WPD_LAYER)
					; ax is still windowOwner
	call	FindFTObjectOfPrioOnWin
	tst	cx
	jnz	giveFocus

	;	7) Top focusable window of LAYER_PRIO_ON_TOP priority
	;	   (InputOD if is a GenField run by the UI, else
	;	   InputObj of owning Geode)
	;
	mov	cx, mask GWF_FOCUSABLE or \
				(LAYER_PRIO_ON_TOP shl offset WPD_LAYER)
					; ax is still windowOwner
	call	FindFTObjectOfPrioOnWin
	tst	cx
	jnz	giveFocus

	;	default to the thing that just gave up the focus/target
	;
	; Later:
	;	8) UI geode
	; For now:
	;	8) NULL (avoidOptrFocus may be null)
	;
	movdw	cxdx, avoidOptrFocus
;PrintMessage <BRIANC: give UIApp focus here!>
;	tstdw	cxdx
;	jnz	giveFocus
;	mov	cx, handle UIApp	; XXX: GeodeGetAppObject w/handle ui?
;	mov	dx, offset UIApp

giveFocus:
	push	bp
	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	bp

focusDone:
	; Check to see if something within the field has the focus
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, focusExclOffset
	tst	ds:[di][bx].HG_OD.handle
	jnz	afterFocusCheck
	;
	; if system object, no focus is okay if we have a modal geode
	;
	cmp	bx, offset OLSYI_focusExcl
	jne	noFocus
	tst	ds:[di].OLSYI_modalGeode.BG_OD.handle
	jnz	afterFocusCheck
noFocus:
	;
	; Otherwise, deal with the problem of no focus by sending notification
	; of this event.  (The most likely cause is that the last focusable
	; application has been shut down within the field, or there is nothing
	; focusable within the system)
	;
	push	bp
	mov	ax, MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
	call	ObjCallInstanceNoLock
	pop	bp
afterFocusCheck:
	.leave
	ret

EnsureActiveFTCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryPreferredAndVariations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try WIN_PRIO_STD and WIN_PRIO_STD+1 windows of passed
		LayerPriority and opposite LayerPriority (LAYER_PRIO_ON_TOP
		if pref=LAYER_PRIO_STD, LAYER_PRIO_STD if
		pref=LAYER_PRIO_ON_TOP)

CALLED BY:	INTERNAL
			EnsureActiveFTCommon

PASS:		cx = preferred WinPriorityData (only WPD_LAYER set)
		di = parent window
		^lbx:ax = avoid optr
		dx = owing geode for windows to search (0 for any)

RETURN:		carry set if FT found
			^lcx:dx = FT
		carry clear if no FT found
			Z set if avoid optr found

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TryPreferredAndVariations	proc	near

priority	local	word	push	cx
avoidHandle	local	word	push	bx
avoidChunk	local	word	push	ax
windowOwner	local	word	push	dx
foundAvoid	local	word

	.enter

.assert (LAYER_PRIO_STD eq 12)		; 12 = 1100
.assert (LAYER_PRIO_ON_TOP eq 8)	; 8 = 1000

	mov	foundAvoid, 0

	tst	priority		; (clears carry)
	jz	done			; don't default to avoidOptrTarget

EC <	mov	cx, priority						>
EC <	tst	ch			; WinPriorityData is byte only	>
EC <	ERROR_NZ	OL_ERROR					>
EC <	test	cl, not mask WPD_LAYER	; must only pass LayerPriority	>
EC <	ERROR_NZ	OL_ERROR					>

	;
	; try primaries of preferred layer
	;
	mov	cx, priority
	ornf	cx, WIN_PRIO_STD shl offset WPD_WIN or mask GWF_TARGETABLE
	call	findAndCheck
	jc	done			; found (^lcx:dx)

10$:
	;
	; try primaries of opposite layer
	;
	mov	cx, priority
	xor	cx, 4 shl offset WPD_LAYER	; toggle between 12 and 8
	ornf	cx, WIN_PRIO_STD shl offset WPD_WIN or mask GWF_TARGETABLE
	call	findAndCheck
	jc	done			; found (^lcx:dx)

20$:
	;
	; try icons of preferred layer
	;
	mov	cx, priority
	ornf	cx, WIN_PRIO_STD+1 shl offset WPD_WIN or mask GWF_TARGETABLE
	call	findAndCheck
	jc	done			; found (^lcx:dx)

30$:
	;
	; try icons of opposite layer
	;
	mov	cx, priority
	xor	cx, 4 shl offset WPD_LAYER	; toggle between 12 and 8
	ornf	cx, WIN_PRIO_STD+1 shl offset WPD_WIN or mask GWF_TARGETABLE
	call	findAndCheck
	jc	done			; found (^lcx:dx)

	cmp	foundAvoid, 1		; set Z if avoidOptr found
	clc				; indicate not found
done:
	.leave
	ret			; <-- EXIT HERE

findAndCheck	label	near
	mov	ax, windowOwner
	call	FindFTObjectOfPrioOnWin	; ^lcx:dx = desired win, if any
	jcxz	notFound		; not found
	cmp	cx, avoidHandle		; trying to avoid this one?
	jne	giveFT
	cmp	dx, avoidChunk
	jne	giveFT			; nope, give it the FT
	mov	foundAvoid, 1
notFound:
	clc				; indicate not found
	retn
giveFT:
	stc				; indicate FT found
	retn

TryPreferredAndVariations	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFTObjectOfPrioOnWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the object to give the focus/target to given
		an owning geode.

CALLED BY:	INTERNAL:
		EnsureActiveFTCommon, TryPreferredAndVariations

PASS:		ax	= owning Geode
RETURN:		^lcx:dx	= optr of object to give focus/target
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/31/94    	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFTObjectOfPrioOnWin	proc	near
	uses bp
	.enter

	clr	bx			; any LayerID
if FIND_HIGHER_LAYER_PRIORITY
	call	FindHigherLayerPriorityWinOnWin
else
	call	FindWinOnWin
endif
	call	GetFTObject		; Convert to object we can give
					; focus/target to
	.leave
	ret
FindFTObjectOfPrioOnWin	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetFTObject

DESCRIPTION:	Given InputOD of a child window, figure out whether we can
		give it the focus or target directly, or whether we need to
		give the focus or target to its owning geode's InputObj.

		Logic:  If it is a GenField object run by the main UI thread
		itself, then the object itself should be given the focus.
		For anything else, the InputObj of the owning Geode should be
		used.

CALLED BY:	INTERNAL

PASS:		^lcx:dx	- InputOD from window
		bp	- window

RETURN:		^lcx:dx	- object that should be given focus/target

DESTROYED:	bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Initial version
------------------------------------------------------------------------------@

GetFTObject	proc	near	uses	bx
	.enter
	call	TestIfCXDXGenFieldObject
	jc	done		; If is a GenField object, done, return it
	mov	bx, cx
				; Otherwise... fetch owning Geode's InputObj
	call	GetOwningInputObj
done:
	.leave
	ret
GetFTObject	endp


TestIfCXDXGenFieldObject	proc	near
					; Returns carry set if cx:dx is 
					; GenField object run by current thread.
	tst	cx
	jz	notGenField

	push	bx
	mov	bx, cx
	call	ObjTestIfObjBlockRunByCurThread
	pop	bx
	jne	notGenField		; If run by a different thread, can't
					; test.  GenField's are all run by
					; global UI thread, so this shouldn't be
					; a problem.

	; If run by the same thread, check to see if a GenField object
	;
	push	bx, si, di, es
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock
	mov	di, segment GenFieldClass
	mov	es, di
	mov	di, offset GenFieldClass
	call	ObjIsObjectInClass
	call	ObjSwapUnlock
	pop	bx, si, di, es
	ret

notGenField:
	clc
	ret
TestIfCXDXGenFieldObject	endp

HighCommon ends

;----------------

HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemNotifySysModalWinChange

DESCRIPTION:	Check up on which is the top-most system modal window.  Make
		it the active geode, restrict auto-raise, auto-focus, & give
		its geode the focus until another system modal dialog becomes
		active or there are no more.  Once there are no more, return
		focus to where it should be.

		NOTE that this is different than the application object
		equivalent, MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE, due to the
		fact that only the system object can synchronously figure out
		who should have the focus & shift it there.  (The app
		equivalent does not deal with focus, for windows within an
		app are responsible for grabbing it themselves).

CALLED BY:	OLPopupBringToTop method OLPopupWinClass, MSG_GEN_BRING_TO_TOP

PASS:		*ds:si	- Object instance data

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

OLSystemNotifySysModalWinChange	method dynamic	OLSystemClass, \
				MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE

	call	GetDefaultScreenWin

	; di = screen window

	clr	ax			; any geode
	clr	bx			; any LayerID


	mov	cx, (LAYER_PRIO_MODAL shl offset WPD_LAYER) or WIN_PRIO_MODAL
					; Get cx:dx = InputOD of top window
					; having both LAYER_PRIO_MODAL &
					; WIN_PRIO_MODAL, bp = win
if FIND_HIGHER_LAYER_PRIORITY
	call	FindHigherLayerPriorityWinOnWin
else
	call	FindWinOnWin
endif
keepFocusHere::
	call	GetOwningInputObj	; Convert to geode InputObj (app obj)

	; Update flow object, so Geode may be made "Active" for ptr image
	; control
	;
	push	cx, dx, bp
	mov	ax, MSG_FLOW_SET_MODAL_GEODE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	UserCallFlow
	pop	cx, dx, bp

	; FOCUS.  Now, we have to fix up the focus mess.

	; Get parent object, so we've got all the players in one place
	;
	mov	bx, bp
	clr	ax
	tst	bx
	jz	haveParentObj
	push	cx, dx
	call	WinGeodeGetParentObj	; get parent FT node (usually field)
	mov	bx, cx			; place in bx:ax
	mov	ax, dx
	pop	cx, dx
haveParentObj:
					; Store new, get old
EC <	call	ECCheckIfSystemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	xchg	ds:[di].OLSYI_modalGeode.BG_OD.handle, cx
	xchg	ds:[di].OLSYI_modalGeode.BG_OD.chunk, dx
	xchg	ds:[di].OLSYI_modalGeode.BG_data, bp
	xchg	ds:[di].OLSYI_modalParentObj.handle, bx
	xchg	ds:[di].OLSYI_modalParentObj.chunk, ax

	; Exit out if no change.
	;
	cmp	ds:[di].OLSYI_modalGeode.BG_data, bp
	je	done

	tst	bp
	jz	toModalState		; branch to handle case of first
					; entry into system modal state
	tst	ds:[di].OLSYI_modalGeode.BG_data
	jz	exitModalState		; branch to handle case of exiting
					; system modal state

	; We're in transition, from one modal geode to another. Joy.

	cmp	bx, ds:[di].OLSYI_modalParentObj.handle
	jne	differentParentObjs
	cmp	ax, ds:[di].OLSYI_modalParentObj.chunk
	je	toModalState		; branch if transitioning within
					; same parent FT node object -- just
					; grab focus for new modal object,
					; old optr will lose exclusive.
differentParentObjs:
	; In the case of different parent object nodes, start by releasing
	; the exclusives grabbed by the prior sys modal geode.
	;
	mov	bp, mask MAEF_FOCUS or mask MAEF_MODAL
	call	ModalGrabReleaseCommon

	; Then transition to new modal state
	jmp	short toModalState

sysEnsureFTDone:
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	ObjCallInstanceNoLock
	;
	; ensure that new focus in system (OLField) has focus also
	;
	mov	ax, MSG_META_GET_FOCUS_EXCL
	call	ObjCallInstanceNoLock	; ^lcx:dx = focus, if any
	jnc	done			; no response
	jcxz	done			; no focus
	push	si
	movdw	bxsi, cxdx		; ^lbx:si = focus field
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
done:
	call	OLSysUpdatePtrImage
	ret

toModalState:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLSYI_modalGeode.BG_OD.handle
	mov	dx, ds:[di].OLSYI_modalGeode.BG_OD.chunk
	mov	bx, ds:[di].OLSYI_modalParentObj.handle
	mov	ax, ds:[di].OLSYI_modalParentObj.chunk

	mov	bp, mask MAEF_GRAB or mask MAEF_FOCUS or mask MAEF_MODAL
	call	ModalGrabReleaseCommon
	jmp	short done

exitModalState:
	mov	bp, mask MAEF_FOCUS or mask MAEF_MODAL
	call	ModalGrabReleaseCommon
	jmp	short sysEnsureFTDone

OLSystemNotifySysModalWinChange	endm



ModalGrabReleaseCommon	proc	near

	; Alter focus excl for geode from its parent FT object
	;
	push	bp
	push	si
	mov	si, ax			; get bx:si = parent obj
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; If parent FT object IS system object, we're done.
	;
	pop	ax			; get chunk handle of system object
	cmp	bx, ds:[LMBH_handle]
	jne	alterForParentObj
	cmp	si, ax
	je	popBPdone
alterForParentObj:
	push	ax
					; In case releasing, be sure to
					; re-evaluate focus, so will be restored
					; to cached non-modal focus
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, bx
	mov	dx, si
	pop	si			; *ds:si is again system object
	pop	bp

					; ^lcx:dx is now parent FT object
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
done:
	ret

popBPdone:
	pop	bp
	ret
ModalGrabReleaseCommon	endp

HighUncommon ends

;------------------

HighCommon segment resource

; This is a redundant copy of routine in userFlowInput.asm, that should
; go away when sys & flow are merged.
;
GetOwningInputObj	proc	far	uses	bx, si
	.enter
	clr	cx
	clr	dx
	tst	bp
	jz	done
	mov	bx, bp
	call	MemOwner
	mov	bp, bx
	call	WinGeodeGetInputObj
done:
	.leave
	ret
GetOwningInputObj	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemAlterFTVMCExcl

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

OLSystemAlterFTVMCExcl	method	OLSystemClass, MSG_META_MUP_ALTER_FTVMC_EXCL
EC<	call	ECCheckODCXDX						>

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
	push	ds:[di].OLSYI_focusExcl.HG_OD.handle
	push	ds:[di].OLSYI_focusExcl.HG_OD.chunk

	mov	ax, di
	add	ax, offset OLSYI_nonModalFocus	; ds:ax is nonModalFocus
						; set non-zero if in modal state
	tst	ds:[di].OLSYI_modalGeode.BG_OD.handle
	mov	bx, offset Vis_offset		; bx is master offset,
	mov	di, offset OLSYI_focusExcl	; di is offset, to focusExcl
	call	AlterFExclWithNonModalCacheCommon

	; Check to see if focus has changed
	;
	pop	dx, cx				; get original focus
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	cx, ds:[di].OLSYI_focusExcl.HG_OD.handle
	jne	focusChanged
	cmp	dx, ds:[di].OLSYI_focusExcl.HG_OD.chunk
	je	doneWithFocus
focusChanged:

	; Set new keyboard grab, if necessary.
	;
	mov	cx, ds:[di].OLSYI_focusExcl.HG_OD.handle
	mov	dx, ds:[di].OLSYI_focusExcl.HG_OD.chunk
	call	SysUpdateKbdGrab

doneWithFocus:
	pop	cx, dx				; restore passed in cx, dx
	jmp	short next
afterFocus:

	; Check for other requests we can handle
	;

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask MAEF_TARGET
	mov	di, offset OLSYI_targetExcl
	test	bp, bx
	jnz	doHierarchy

	mov	ax, MSG_META_GAINED_MODEL_EXCL
	mov	bx, mask MAEF_MODEL
	mov	di, offset OLSYI_modelExcl
	test	bp, bx
	jnz	doHierarchy

	mov	ax, MSG_META_GAINED_FULL_SCREEN_EXCL
	mov	bx, mask MAEF_FULL_SCREEN
	mov	di, offset OLSYI_fullScreenExcl
	test	bp, bx
	jnz	doHierarchy

	; The system object is as far up as you can go -- anything not handled
	; here goes off the end of the earth.
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
	Destroy	ax, cx, dx, bp
	ret

OLSystemAlterFTVMCExcl	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	AlterFExclWithNonModalCacheCommon

DESCRIPTION:	Used to implement MAEF_FOCUS exlusive change request in
		MSG_META_MUP_ALTER_FTVMC_EXCL handlers, in objects which
		desire special handling of the focus for modal states.  The
		special handling is this:  If in a modal state, only requests
		by modal objects (those requests in which MAEF_MODAL is set)
		are actually be granted.  All other requests simply operate
		on a seperate "nonModalFocus variable.  The optr stored there
		is usually then given the focus once the modal state ends.
		This routine keeps the "nonModalFocus" variable up to date,
		but that's it -- the caller is responsible for managing the
		restoration of focus after the modal state ends.

CALLED BY:	INTERNAL
		OLSystemAlterFTVMCExcl
		OLFieldAlterFTVMCExcl
		OLApplicationAlterFTVMCExcl

PASS:		*ds:si	- focus node instance
		ds:ax	- ptr to nonModalFocus structure
		bx	- master offset of focusExcl struct within instance
		di	- offset to focusExcl struct within instance

		^lcx:dx - object requesting grab/release
		bp	- MetaAlterFTVMCExclFlags:
				MAEF_FOCUS
				MAEF_GRAB
				MAEF_MODAL

		zero flag	- non-zero if node is currently in a modal state

RETURN:		bp	- same as passed, but with MAEF_FOCUS bit masked out

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

AlterFExclWithNonModalCacheCommon	proc	far
	pushf
	test	bp, mask MAEF_FOCUS
	jz	done

	xchg	ax, bx				; master offset to ax,
						; ds:bx is ptr to nonModalFocus

	test	bp, mask MAEF_GRAB
	jz	release
	tst	cx				; If forcing null grab, allow
	jz	saveLastContinue

	; If not in a modal state, just let the focus change happen.
	;
	popf
	pushf
	jz	saveLastContinue

						; If there is modal activity,
						; however, and this object is
						; NOT part of it, then we've
						; got us a claim jumper here --
						; shoo him off by refusing to
						; hand over the focus win
						; exclusive.
	test	bp, mask MAEF_MODAL
	jnz	continue

;saveLastNonModal:
	; Save away last non-modal window to ask for focus.  Once there are
	; no more modal windows up, we'll return the focus there.
	;
	mov	ds:[bx].handle, cx
	mov	ds:[bx].chunk, dx
	jmp	short done

release:
	; Clear out last non-modal focus cache, if object is requesting a
	; release of the focus exclusive
	;
	cmp	cx, ds:[bx].handle
	jne	continue
	cmp	dx, ds:[bx].chunk
	jne	continue
	clr	ds:[bx].handle
	clr	ds:[bx].chunk
	jmp	short continue

saveLastContinue:
	mov	ds:[bx].handle, cx
	mov	ds:[bx].chunk, dx

continue:
	push	bp
	and	bp, mask MAEF_GRAB
	or	bp, mask MAEF_FOCUS		; or back in hierarchy flag
	mov	bx, ax				; get master offset in bx
	mov	ax, MSG_META_GAINED_FOCUS_EXCL
	call	FlowAlterHierarchicalGrab
	pop	bp
done:
	and	bp, not mask MAEF_FOCUS
	popf
	ret

AlterFExclWithNonModalCacheCommon	endp





COMMENT @----------------------------------------------------------------------

FUNCTION:	SysUpdateKbdGrab

DESCRIPTION:	Give passed OD the keyboard grab, if it is an app object, or
		run by a different thread, or NULL.

CALLED BY:	INTERNAL
		OLSystemAlterFTVMCExcl
		OLFieldAlterFTVMCExcl

PASS:		*ds:si	- System or field object
		cx:dx	- object just having gained focus, or NULL if nothing
			  has focus

RETURN:		nothing

DESTROYED:	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

SysUpdateKbdGrab	proc	far	uses	cx, dx, bp
	.enter
	tst	cx
	jz	setNewKbdGrab

	; See if new focus object is run by same thread or not
	;
	mov	bx, cx
	call	ObjTestIfObjBlockRunByCurThread
	jne	setNewKbdGrab		; If run by a different thread, we
					; have to grab the keyboard grab for it.
	; If run by the same thread, check to see if a GenApplication object
	;
	push	bx, si, di, es
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock
	mov	di, segment GenApplicationClass
	mov	es, di
	mov	di, offset GenApplicationClass
	call	ObjIsObjectInClass
	call	ObjSwapUnlock
	pop	bx, si, di, es

	jc	setNewKbdGrab		; If so, we also must set kbd grab
	jmp	short exit		; otherwise, it'll deal with itself.

setNewKbdGrab:
	call	FlowGrabKbdExcl
exit:
	.leave
	ret
SysUpdateKbdGrab	endp



COMMENT @----------------------------------------------------------------------

METHOD:		FlowGrabKbdExcl

DESCRIPTION:	Grab kbd exclusive for app

PASS:		*ds:si - instance data

		cx:dx	- object to grab kbd for

RETURN:

DESTROYED:
	ax, bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

FlowGrabKbdExcl	proc near
	mov	al, mask VIFGF_KBD or mask VIFGF_GRAB or mask VIFGF_FORCE
	mov	ah, VIFGT_ACTIVE
	call	FlowGrabCommon
	ret
FlowGrabKbdExcl	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	FlowGrabCommon		

DESCRIPTION:	Grabs/releases kbd/mouse grabs for object passed, from
		flow object.

PASS:		*ds:si	- instance data
		^lcx:dx -- object to grab for
		al	- VisInputFlowGrabFlags
		ah	- VisInputFlowGrabType
			
RETURN:		*ds:si	- intact

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@
FlowGrabCommon	proc	far	uses	ax, cx, dx, bp
	.enter
	sub	sp, size VupAlterInputFlowData	; create stack frame
	mov	bp, sp				; ss:bp points to it
	mov	ss:[bp].VAIFD_object.handle, cx	; copy object OD into frame
	mov	ss:[bp].VAIFD_object.chunk, dx
	mov	ss:[bp].VAIFD_flags, al		; copy flags into frame
	mov	ss:[bp].VAIFD_grabType, ah

	clr	ax				; init to no translation
	mov	ss:[bp].VAIFD_translation.PD_x.high, ax
	mov	ss:[bp].VAIFD_translation.PD_x.low, ax
	mov	ss:[bp].VAIFD_translation.PD_y.high, ax
	mov	ss:[bp].VAIFD_translation.PD_y.low, ax
	mov	ss:[bp].VAIFD_gWin, ax		; app doesn't want mouse data
						; translated.

	mov	dx, size VupAlterInputFlowData	; pass size of structure in dx
	mov	ax, MSG_VIS_VUP_ALTER_INPUT_FLOW	; send method
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	UserCallFlow
	add	sp, size VupAlterInputFlowData	; restore stack
	.leave
	ret

FlowGrabCommon	endp

HighCommon ends

;----------------

HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemVupAlterInputFlow

DESCRIPTION:	Relay message onto flow object (such as might come from
		field object, or children thereof)

PASS:		*ds:si 	- instance data
		es     	- segment of class
		ax 	- MSG_VIS_VUP_ALTER_INPUT_FLOW
		dx	- size VupAlterInputFlowData
		ss:bp	- ptr to VupAlterInputFlowData

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
	doug	3/92		Initial Version

------------------------------------------------------------------------------@

OLSystemVupAlterInputFlow	method dynamic	OLSystemClass,
					MSG_VIS_VUP_ALTER_INPUT_FLOW

						; Clear "not yet" flag, since
						; we're safely past the first
						; object
	and	ss:[bp].VAIFD_flags, not mask VIFGF_NOT_HERE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	UserCallFlow
	ret

OLSystemVupAlterInputFlow	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemGetFocusExcl
METHOD:		OLSystemGetTargetExcl
METHOD:		OLSystemGetModelExcl

DESCRIPTION:	Returns the current focus/target/model
		below this point in hierarchy

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_META_GET_[FOCUS/TARGET/MODEL]_EXCL
		
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

OLSystemGetFocusExcl 	method dynamic OLSystemClass, MSG_META_GET_FOCUS_EXCL
	mov	bx, offset OLSYI_focusExcl
	GOTO	OLSystemGetCommon
OLSystemGetFocusExcl	endm

OLSystemGetModelExcl 	method dynamic OLSystemClass, MSG_META_GET_MODEL_EXCL
	mov	bx, offset OLSYI_modelExcl
	GOTO	OLSystemGetCommon
OLSystemGetModelExcl	endm

OLSystemGetTargetExcl 	method dynamic OLSystemClass, MSG_META_GET_TARGET_EXCL
	mov	bx, offset OLSYI_targetExcl
	FALL_THRU	OLSystemGetCommon
OLSystemGetTargetExcl	endm

OLSystemGetCommon	proc	far
	mov	cx, ds:[di][bx].HG_OD.handle
	mov	dx, ds:[di][bx].HG_OD.chunk
	Destroy	ax, bp
	stc
	ret
OLSystemGetCommon	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemSendClassedEvent

DESCRIPTION:	Sends message to target object at level requested
		Focus, Target, & Model requests are all
		passed on to whatever object has the exlusive.

PASS:
	*ds:si - instance data
	es - segment of OLSystemClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TargetObject

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@

OLSystemSendClassedEvent	method	OLSystemClass, \
					MSG_META_SEND_CLASSED_EVENT
	mov	bp, di				; save offset to master part

	mov	di, offset OLSYI_focusExcl
	cmp	dx, TO_FOCUS
	je	sendHere

	mov	di, offset OLSYI_targetExcl
	cmp	dx, TO_TARGET
	je	sendHere

	mov	di, offset OLSYI_modelExcl
	cmp	dx, TO_MODEL
	je	sendHere

	mov	di, offset OLSystemClass
	GOTO	ObjCallSuperNoLock

sendHere:
	add	di, bp			; Get ptrs to instance data
	tst	ds:[di].BG_OD.handle	; See if primary hierarchy in use
	mov	bx, ds:[di].BG_OD.handle
	mov	bp, ds:[di].BG_OD.chunk
	clr	di
	call	FlowDispatchSendOnOrDestroyClassedEvent
	ret

OLSystemSendClassedEvent	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSystemGetTargetAtTargetLevel

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of OLSystemClass

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


OLSystemGetTargetAtTargetLevel	method dynamic	OLSystemClass, \
					MSG_META_GET_TARGET_AT_TARGET_LEVEL

	mov	ax, TL_GEN_SYSTEM
	mov	bx, Vis_offset
	mov	di, offset OLSYI_targetExcl
	call	FlowGetTargetAtTargetLevel
	ret

OLSystemGetTargetAtTargetLevel	endm

HighUncommon ends

;------------------

HighCommon segment resource


GetDefaultScreenWin	proc	far
	; Loop up the current most eligible system model window
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
					; Fetch OD of default screen, so we
					; can ask it its window handle
	mov	bx, ds:[di].GSYI_defaultScreen.handle
	mov	si, ds:[di].GSYI_defaultScreen.chunk
					; Fetch bp = window handle of screen
	mov	cx, GUQT_SCREEN
	mov	ax, MSG_SPEC_GUP_QUERY
	call	ObjMessageCallFixupDS
	mov	di, bp			; place in di
	pop	si
	ret
GetDefaultScreenWin	endp

if FIND_HIGHER_LAYER_PRIORITY

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindHigherLayerPriorityWinOnWin

DESCRIPTION:	Looks through all child windows of the passed window, looking
		for the first one having a higher layer priority, or
		at least the minimum specified layer priority.

CALLED BY:	INTERNAL

PASS:		*ds:si	- system object
		ax	- Owning geode of window to look for (or 0 for any)
		bx	- LAYER ID of window to look for (or 0 for any)
		cl	- Layer & Window priority to look for, (or 0 in either
			  field to allow any match for field)
		ch	- High byte of GeodeWinFlags, indicating any
			  characteristics that the owning geode of any window
			  must have, in order for it to qualify.
			  NOTE:  GenFieldClass objects run by the UI are
				 exempted from this check, as we always wish
				 for them to be focusable & targetable even
				 though their owning app, the UI app, is not.
		di	- Window whose children we are to look at (or 0 if
			  no window, in which case return values will indicate
			  nothing found)

RETURN:		cx:dx	- set to InputOD of first such window
			else 0:0
		bp	- handle of window, else 0

DESTROYED:	nothing
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
	reza	7/11/95		stolen from FindWinOnWin
------------------------------------------------------------------------------@

FindHigherLayerPriorityWinOnWin	proc	far	uses	ax, bx, si, di
	.enter

	tst	di
	jz	nullDone

	push	cx
	call	CreateChunkArrayOnWindows

					; We now have a list of the windows
					; belonging to this app, in *ds:si
	clr	cx			; Haven't found one yet.

	pop	dx			; Get priority to look for, in dl

	mov	bx, cs			; prepare for ChunkArrayEnum
	mov	di, offset FindWinOfHigherLayerPrioInChunkArrayCallBack

	test	dl, mask WPD_LAYER	; any specific layer priority?
	jz	regularFind		; NO, search for anything else
					; that matches.

	clr	ah
	mov	al, dl
	and	al, mask WPD_LAYER	; al = layer priority only
	mov	cl, offset WPD_LAYER
	shr	al, cl			; al = minimal layer priority

	and	dl, not mask WPD_LAYER	; dl = WinPriority only

topLoop:
	inc	ah
	cmp	ah, al
	ja	notFound
	push	ax, cx, dx, bx
	shl	ah, cl			; ah = next highest layer priority
	or	dl, ah

	call	ChunkArrayEnum
	jc	found
	pop	ax, cx, dx, bx
	jmp	topLoop

found:
	pop	ax, ax, ax, ax		; trash saved bx, cx, dx, values
	jmp	10$

regularFind:
	call	ChunkArrayEnum

	tst	cx			; if no handle returned,
	jnz	10$

notFound:
	clr	cx			; clear again because we might
					; be coming in from the search loop

	clr	dx			; return NULL for chunk as well
	clr	bp			; return NULL for window as well
10$:
					; cx:dx is result, if any
	mov	ax, si
	call	LMemFree

done:
	.leave
	ret

nullDone:
	clr	cx
	clr	dx
	clr	bp
	jmp	short done

FindHigherLayerPriorityWinOnWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindWinOfHigherLayerPrioInChunkArrayCallBack

DESCRIPTION:	Searches the in the chunk array passed, looking for
		a window that matches the passed description or has a
		higher layer priority.

CALLED BY:	INTERNAL

PASS:		*ds:si	- chunk array
		ds:di	- element to process
		dl	- Layer & Window priority to look for, (or 0 in either
			  field to allow any match for field)
		dh	- High byte of GeodeWinFlags, indicating any
			  characteristics that the owning geode of any window
			  must have, in order for it to qualify.

RETURN:		carry set if found, &
		^lcx:dx	- InputOD of window willing to take modal excl.
		^hbp	- window
		ELSE carry clear, cx=0

DESTROYED:	bx, ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
	reza	7/11/95		stolen from FindWinOfPrioInChunkArrayCallBack
------------------------------------------------------------------------------@

FindWinOfHigherLayerPrioInChunkArrayCallBack	proc	far	uses	si, di
	.enter

	mov	di, ds:[di]		; get window
	mov	si, WIT_PRIORITY	; Look for MODAL priority window

	call	WinGetInfo
	test	dl, mask WPD_WIN	; any window priority to compare?
	jnz	compareWinPrio		; YES, skip
	and	al, not mask WPD_WIN
compareWinPrio:
	test	dl, mask WPD_LAYER	; any layer priority to compare?
	jnz	compareLayerPrio	; YES, skip
	and	al, not mask WPD_LAYER
compareLayerPrio:
	cmp	al, dl			; quick compare
	je	exactMatch

	test	dl, mask WPD_LAYER	; any LayerPriority to check?
	jz	skip			; NO, skip

	mov	cl, al
	mov	ch, dl
	and	cl, mask WPD_WIN
	and	ch, mask WPD_WIN
	cmp	cl, ch			; same WinPriority?
	jne	skip			; NO, done

	test	dl, mask WPD_LAYER	; any LayerPriority to check?
	jz	skip			; NO, skip

	mov	cl, al
	mov	ch, dl
	and	cl, mask WPD_LAYER
	and	ch, mask WPD_LAYER
	cmp	cl, ch			; LayerPriority higher (smaller #)?
	ja	skip			; NO, done

exactMatch:
	tst	dh				; If no focusable/targetable
	jz	gotOne				; restrictions, continue
	mov	bx, di
	call	MemOwner			; get owning process
	call	WinGeodeGetFlags		; get GeodeWinFlags for that
						;	geode, in AX
	and	ah, dh
	cmp	ah, dh
	je	gotOne				; if flags meet spec, got it!

	; Otherwise, handle execption case of GenField objects
	;
	push	dx
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo
	call	TestIfCXDXGenFieldObject
	jnc	skipPopDX			; if not GenField, skip out

	; If it is a GenField, check to see if it is focusable/targetable in
	; a somewhat different manner -- see if some object within it has
	; the same exclusive.
	;
	test	ax, mask GWF_FOCUSABLE		; looking for focusable?
	mov	ax, MSG_META_GET_FOCUS_EXCL	; if so, query for focus
	jnz	haveQueryMesssage
	mov	ax, MSG_META_GET_TARGET_EXCL	; otherwise, check for target
haveQueryMesssage:
	mov	bx, cx
	mov	si, dx
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ask it -- who's got it?
	pop	di
	tst	cx				; anyone?
	jz	skipPopDX			; if not, doesn't qualify.

	pop	dx

gotOne:
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo
	mov	bp, di

	stc					; Indicate found
	jmp	short done

skipPopDX:
	pop	dx
skip:
	clr	cx				; return CX = 0
	clc					; go on to do next.
done:
	.leave
	ret
FindWinOfHigherLayerPrioInChunkArrayCallBack	endp

else	; FIND_HIGHER_LAYER_PRIORITY


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindWinOnWin

DESCRIPTION:	Looks through all child windows of the passed window, looking
		for the first one matching the description passed.

CALLED BY:	INTERNAL

PASS:		*ds:si	- system object
		ax	- Owning geode of window to look for (or 0 for any)
		bx	- LAYER ID of window to look for (or 0 for any)
		cl	- Layer & Window priority to look for, (or 0 in either
			  field to allow any match for field)
		ch	- High byte of GeodeWinFlags, indicating any
			  characteristics that the owning geode of any window
			  must have, in order for it to qualify.
			  NOTE:  GenFieldClass objects run by the UI are
				 exempted from this check, as we always wish
				 for them to be focusable & targetable even
				 though their owning app, the UI app, is not.
		di	- Window whose children we are to look at (or 0 if
			  no window, in which case return values will indicate
			  nothing found)

RETURN:		cx:dx	- set to InputOD of first such window
			else 0:0
		bp	- handle of window, else 0

DESTROYED:	nothing
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
------------------------------------------------------------------------------@

FindWinOnWin	proc	far	uses	ax, bx, si, di
	.enter

	tst	di
	jz	nullDone

	push	cx
	call	CreateChunkArrayOnWindows

					; We now have a list of the windows
					; belonging to this app, in *ds:si
	clr	cx			; Haven't found one yet.

	pop	dx			; Get priority to look for, in dl
	mov	bx, cs
	mov	di, offset FindWinOfPrioInChunkArrayCallBack
	call	ChunkArrayEnum

	tst	cx			; if no handle returned,
	jnz	10$
	clr	dx			; return NULL for chunk as well
	clr	bp			; return NULL for window as well
10$:
					; cx:dx is result, if any
	mov	ax, si
	call	LMemFree

done:
	.leave
	ret

nullDone:
	clr	cx
	clr	dx
	clr	bp
	jmp	short done

FindWinOnWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindWinOfPrioInChunkArrayCallBack

DESCRIPTION:	Searches the in the chunk array passed, looking for
		a window that matches the passed description

CALLED BY:	INTERNAL

PASS:		*ds:si	- chunk array
		ds:di	- element to process
		dl	- Layer & Window priority to look for, (or 0 in either
			  field to allow any match for field)
		dh	- High byte of GeodeWinFlags, indicating any
			  characteristics that the owning geode of any window
			  must have, in order for it to qualify.

RETURN:		carry set if found, &
		^lcx:dx	- InputOD of window willing to take modal excl.
		^hbp	- window
		ELSE carry clear, cx=0

DESTROYED:	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

FindWinOfPrioInChunkArrayCallBack	proc	far	uses	si, di
	.enter

	mov	di, ds:[di]			; get window
	mov	si, WIT_PRIORITY		; Look for MODAL priority window

	call	WinGetInfo
	test	dl, mask WPD_WIN
	jnz	compareWinPrio
	and	al, not mask WPD_WIN
compareWinPrio:
	test	dl, mask WPD_LAYER
	jnz	compareLayerPrio
	and	al, not mask WPD_LAYER
compareLayerPrio:
	cmp	al, dl
	jne	skip

	tst	dh				; If no focusable/targetable
	jz	gotOne				; restrictions, continue
	mov	bx, di
	call	MemOwner			; get owning process
	call	WinGeodeGetFlags		; get GeodeWinFlags for that
						;	geode, in AX
	and	ah, dh
	cmp	ah, dh
	je	gotOne				; if flags meet spec, got it!

	; Otherwise, handle execption case of GenField objects
	;
	push	dx
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo
	call	TestIfCXDXGenFieldObject
	jnc	skipPopDX			; if not GenField, skip out

	; If it is a GenField, check to see if it is focusable/targetable in
	; a somewhat different manner -- see if some object within it has
	; the same exclusive.
	;
	test	ax, mask GWF_FOCUSABLE		; looking for focusable?
	mov	ax, MSG_META_GET_FOCUS_EXCL	; if so, query for focus
	jnz	haveQueryMesssage
	mov	ax, MSG_META_GET_TARGET_EXCL	; otherwise, check for target
haveQueryMesssage:
	mov	bx, cx
	mov	si, dx
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ask it -- who's got it?
	pop	di
	tst	cx				; anyone?
	jz	skipPopDX			; if not, doesn't qualify.

	pop	dx

gotOne:
	mov	si, WIT_INPUT_OBJ
	call	WinGetInfo
	mov	bp, di

	stc					; Indicate found
	jmp	short done

skipPopDX:
	pop	dx
skip:
	clr	cx				; return CX = 0
	clc					; go on to do next.
done:
	.leave
	ret
FindWinOfPrioInChunkArrayCallBack	endp
endif	; FIND_HIGHER_LAYER_PRIORITY


COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateChunkArrayOnWindows

DESCRIPTION:	Creates a list of the top-most child of a given window which
		meets the following criteria:

			* Has LayerID equal to that passed

CALLED BY:	GLOBAL (utility)

PASS:		*ds:si	- Object whose block we can use for a temp chunk 
		ax	- owner of window we're looking for (or 0 for any)
		bx	- LAYER ID of window we're looking for (or 0 for any)
		di	- parent window whose children we should check

RETURN:		*ds:si	- chunk array

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@


CreateChunkArrayOnWindows	proc	far	uses	ax, bx, cx, dx, di, bp
	.enter
	push	ax, bx			; owner, layerID

	clr	al			; basic chunk.  we're going to nuke
					; later anyway
	mov	bx, size hptr
	clr	cx
	mov	si, cx
	call	ChunkArrayCreate
	mov	bp, si			; *ds:bp is chunk array

	; cx = 0 at this point
	pop	ax, dx			; owner, layerID

	mov	bx, SEGMENT_CS
	mov	si, offset CreateChunkArrayOnWindowsInLayerCallBack
	push	ds:[LMBH_handle]	;Save handle of segment for fixup later
	call	WinForEach		;Does not fixup DS!
	pop	bx
	call	MemDerefDS		;Fixup LMem segment
					; We now have a list of the windows
					; belonging to this app, in *ds:bp
	mov	si, bp			; pass chunk array in *ds:si
	.leave
	ret
CreateChunkArrayOnWindows	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateChunkArrayOnWindowsInLayerCallBack

DESCRIPTION:	Fill chunk array passed with windows of the given layer
		which are children of the initial window passed

CALLED BY:	INTERNAL
			GenFindTopModalWin

PASS:
	di	- window handle to process
	ax	- owner we're looking for, or zero for any
	cx	- flag:  0 if first (parent) window
	dx	- layer ID we're looking for, or zero for any
	*ds:bp	- chunk array

RETURN:
	carry set	- if done, else:
	di	- next window to do

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
------------------------------------------------------------------------------@

CreateChunkArrayOnWindowsInLayerCallBack	proc	far	uses	ax
	.enter
	tst	cx			; is this the parent window?
	jz	findFirstChild		; if so, branch to get first child

	; See if correct owner
	tst	ax
	jz	afterOwner
	mov	bx, di
	call	MemOwner
	cmp	bx, ax
	jne	doNext

afterOwner:
	; See if in correct layer
	;
	tst	dx
	jz	thisOneOK
	mov	si, WIT_LAYER_ID
	call	WinGetInfo
	cmp	ax, dx			; a match?
	jne	doNext			; if not, skip to do next

thisOneOK:
	push	di
	mov	si, bp			; put chunk array in ds:si
	call	ChunkArrayAppend	; add a new entry in array
					; ds:di = ptr to new element
	mov	si, di			; ds:si = ptr to new element
	pop	di
	mov	ds:[si], di		; store window handle
doNext:
	mov	si, WIT_NEXT_SIBLING_WIN; do next sibling next.
	jmp	short done

findFirstChild:
	mov	si, WIT_FIRST_CHILD_WIN	; fetch first child of this parent win
done:
	call	WinGetInfo
	mov	di, ax			; make that the next window we do
	mov	cx, -1			; not doing parent win
	clc				; keep going until null window
	.leave
	ret

CreateChunkArrayOnWindowsInLayerCallBack	endp


COMMENT @----------------------------------------------------------------------

METHOD:
	MSG_GEN_SYSTEM_MARK_BUSY
	MSG_GEN_SYSTEM_MARK_NOT_BUSY

DESCRIPTION:	These routines handle the inc'ing & dec'ing of variables
	for determining whether the system should be marked as busy.

PASS:
	*ds:si - instance data
	es - segment of OlSystemClass

	ax - MSG_?

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
	Doug	8/89		Initial version

------------------------------------------------------------------------------@

OLSysMarkBusy	method dynamic	OLSystemClass, MSG_GEN_SYSTEM_MARK_BUSY
	inc	ds:[di].OLSYI_busyCount		; Inc busy count
EC <	ERROR_Z	OL_BUSY_COUNT_OVERFLOW					>
if ANIMATED_BUSY_CURSOR
	cmp	ds:[di].OLSYI_busyCount, 1
	jne	noTimer
	push	di
	mov	al, TIMER_EVENT_CONTINUAL
	mov	bx, ds:[LMBH_handle]
	mov	cx, 0
	mov	dx, MSG_OL_SYSTEM_UPDATE_PTR_IMAGE
	mov	di, 60/4			; every 1/4 second
	call	TimerStart
	pop	di
	xchg	bx, ds:[di].OLSYI_busyTimer
	xchg	ax, ds:[di].OLSYI_busyTimerID
	tst	bx
	jz	noTimer
	call	TimerStop
noTimer:
endif
	GOTO	OLSysUpdatePtrImage

OLSysMarkBusy	endp

OLSysMarkNotBusy	method dynamic	OLSystemClass, \
						MSG_GEN_SYSTEM_MARK_NOT_BUSY
	dec	ds:[di].OLSYI_busyCount		; Dec busy count
EC <	ERROR_S OL_BUSY_COUNT_UNDERFLOW					>
if ANIMATED_BUSY_CURSOR
	tst	ds:[di].OLSYI_busyCount
	jnz	noTimer
	clr	bx
	xchg	bx, ds:[di].OLSYI_busyTimer
	mov	ax, ds:[di].OLSYI_busyTimerID
	call	TimerStop
noTimer:
endif
	FALL_THRU	OLSysUpdatePtrImage

OLSysMarkNotBusy	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSysUpdatePtrImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines appropriate PtrImages for PIL_SYSTEM,
		& sets it

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if ANIMATED_BUSY_CURSOR
OLSysUpdatePtrImage	method OLSystemClass, MSG_OL_SYSTEM_UPDATE_PTR_IMAGE
else
OLSysUpdatePtrImage	proc	far
endif
	class	OLSystemClass
EC <	call	ECCheckIfSystemObject					>
	; Check to see if there's a modal geode up (sys modal window)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLSYI_modalGeode.BG_data	; modal geode up?
	jnz	nullPtr			; if so, don't mess with ptr.

	; Else show busy if sys marked "Busy".
	;
	;
    	tst	ds:[di].OLSYI_busyCount
	jz	nullPtr

	mov	cl, OLPI_BUSY		; if any outstanding, set busy

setStatus:
	call	OpenGetPtrImage		; Fetch OL ptr image to use
	mov	bp, PIL_SYSTEM
	call	ImSetPtrImage		; Set it.
	ret

nullPtr:
	mov	cl, OLPI_NONE		; assume we don't
	jmp	short setStatus

OLSysUpdatePtrImage	endp
	
if 	ERROR_CHECK
ECCheckIfSystemObject	proc	far	uses	es, di
	.enter
	mov	di, segment OLSystemClass
	mov	es, di
	mov	di, offset OLSystemClass
	call	ObjIsObjectInClass					
	ERROR_NC	OL_ERROR
	.leave
	ret								
ECCheckIfSystemObject	endp
endif	;ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSystemFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	beep if nothing handled kbd char

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= OLSystemClass object
		ds:di	= OLSystemClass instance data
		ds:bx	= OLSystemClass object (same as *ds:si)
		es 	= segment of OLSystemClass
		ax	= message #
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HighCommon ends

;-----------------

HighUncommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLSystemGenGupEnsureUpdateWindow

DESCRIPTION:	Handle window update.

PASS:
	*ds:si - instance data (offset through Vis_offset)

	cx - UpdateWindowFlags
	dl - VisUpdateMode

RETURN:
	carry set to stop gup
	cx, dl - unchanged
	ax, dh, bp - destroyed
	
DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/92		Initial version

------------------------------------------------------------------------------@


OLSystemGenGupEnsureUpdateWindow	method	OLSystemClass,
					MSG_GEN_GUP_ENSURE_UPDATE_WINDOW

	stc				; stop gup
	Destroy	ax, dh, bp
	ret

OLSystemGenGupEnsureUpdateWindow	endm

HighUncommon ends

