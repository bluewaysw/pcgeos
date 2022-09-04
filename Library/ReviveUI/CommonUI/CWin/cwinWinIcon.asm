COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinWinIcon.asm

ROUTINES:
	Name			Description
	----			-----------
	OLWinIconClass		Icon for OLWinClass objects which are minimized.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial version

DESCRIPTION:

	$Id: cwinWinIcon.asm,v 2.53 94/10/14 15:54:58 dlitwin Exp $

-------------------------------------------------------------------------------@

	;
	;	For documentation of the OLWinIconClass see:
	;	/staff/pcgeos/Spec/olWinIconClass.doc
	; 

CommonUIClassStructures segment resource

	OLWinIconClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends

;---------------------------------------------------

if	not _REDMOTIF

WinIconCode segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconInitialize -- MSG_META_INITIALIZE for OLWinIconClass

DESCRIPTION:	Initialize an icon which opens a GenPrimary or GenDisplay.

PASS:		*ds:si - instance data
		es - segment of OLWinIconClass

		ax - MSG_META_INITIALIZE
		cx, dx, bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

------------------------------------------------------------------------------@


OLWinIconInitialize	method dynamic	OLWinIconClass, MSG_META_INITIALIZE
	;Do super class (OLWinClass) INITIALIZATION

	call	OpenWinInitialize	;direct call for speed

	;override some OLWinClass settings

	call	WinIcon_DerefVisSpec_DI
				; & give basic base window attributes

	ORNF	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON
	mov	ds:[di].OLWI_attrs, OL_ATTRS_WIN_ICON
OLS <	mov	ds:[di].OLWI_type, OLWT_WINDOW_ICON			>
CUAS <	mov	ds:[di].OLWI_type, MOWT_WINDOW_ICON			>

;	;turn off the SA_CUSTOM_VIS_PARENT flag, so that we will not use
;	;the OLCI_visParent field of this window during SPEC_BUILD. We go through
;	;the trouble of making a one-way upward link to the GenApp object;
;	;it should be used when finding a visible parent for this icon.
;
;	ANDNF	ds:[di].VI_specAttrs, not (mask SA_CUSTOM_VIS_PARENT)
;SEE OpenWinGetVisParent... cannot assume that OLCI_visParent is cool!
;try running installed code...

	;NOTE: OLWI_winPosSizeFlags and OLWI_winPosSizeState is set
	;by MSG_OL_WIN_ICON_SET_STATE, so no need to set here.

	;set this OLWinIcon object as discardable, so when system shuts down
	;it is thrown out. GenPrimary will rebuild it later.

	mov	ax, si			;*ds:ax = chunk of OLWinIcon object
	mov	bx, mask OCF_IGNORE_DIRTY ;bl = bits to set
	call	ObjSetFlags		;set LMem flags for Object chunk
	ret
OLWinIconInitialize	endp

WinIcon_DerefVisSpec_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
WinIcon_DerefVisSpec_DI	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconSpecBuild -- 
		MSG_SPEC_BUILD for OLWinIconClass

DESCRIPTION:	Handles spec build of the icon.  Called when the icon comes
		up for the first time, but not when it gets restored and 
		iconified a second time.  We'll take this moment to load
		in stuff stored in the active list.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD

RETURN:		

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/ 3/90		Initial version

------------------------------------------------------------------------------@

OLWinIconSpecBuild	method dynamic OLWinIconClass, MSG_SPEC_BUILD
	;This object is NOT stored on the window list
	;Since this object will not get MSG_META_UPDATE_WINDOW, we need to
	;check now for data that may have been saved.

	push	ax, bp

	sub	sp, size GetVarDataParams + size GenSaveWindowInfo
	mov	bp, sp
	mov	ss:[bp].GVDP_buffer.segment, ss
	lea	ax, ss:[bp]+(size GetVarDataParams)
	push	ax				; save GenSaveWindowInfo offset
	mov	ss:[bp].GVDP_buffer.offset, ax
	mov	ss:[bp].GVDP_bufferSize, size GenSaveWindowInfo
	mov	ss:[bp].GVDP_dataType, TEMP_GEN_SAVE_ICON_INFO
	mov	dx, size GetVarDataParams
	mov	ax, MSG_META_GET_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	OLWinIconObjMessagePrimaryObject
	pop	bx				; restore offset
	cmp	ax, -1
	je	notFound
	call	WinIcon_DerefVisSpec_DI		; ds:di = OLWinIcon Vis instance
	mov	ax, ss:[bx].GSWI_winPosSizeState
	mov	ds:[di].OLWI_winPosSizeState, ax
	mov	ax, ss:[bx].GSWI_winPosition.SWSP_x
	mov	{word} ds:[di].VI_bounds+0, ax
	mov	ax, ss:[bx].GSWI_winPosition.SWSP_y
	mov	{word} ds:[di].VI_bounds+2, ax
	mov	ax, ss:[bx].GSWI_winSize.SWSP_x
	mov	{word} ds:[di].VI_bounds+4, ax
	mov	ax, ss:[bx].GSWI_winSize.SWSP_y
	mov	{word} ds:[di].VI_bounds+6, ax

	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	cx, TEMP_GEN_SAVE_ICON_INFO
	call	OLWinIconCallPrimaryObject

notFound:
	add	sp, size GetVarDataParams + size GenSaveWindowInfo

	;now finish up by calling superclass
	pop	ax, bp
	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass
	ret
OLWinIconSpecBuild	endm

WinIcon_ObjCallSuperNoLock_OLWinIconClass	proc	near
	mov	di, offset OLWinIconClass
	call	ObjCallSuperNoLock
	ret
WinIcon_ObjCallSuperNoLock_OLWinIconClass	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinIconSetUsable  - MSG_OL_WIN_ICON_SET_USABLE

DESCRIPTION:	This procedure makes the icon visible and usable.

CALLED BY:	OLMenuedWinGenSetMinimized

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version

------------------------------------------------------------------------------@

OLWinIconSetUsable	method dynamic	OLWinIconClass,
					MSG_OL_WIN_ICON_SET_USABLE

	;if this Icon is appearing for a second time, then will not
	;get another SPEC_BUILD, so we must force an UpdateWinPosSize here
	;to set things up for geometry work.

	test	ds:[di].VI_specAttrs, mask SA_TREE_BUILT_BUT_NOT_REALIZED
	jz	10$			;skip if not...

	;have one-way visible link to parent.

	call	ConvertSpecWinSizePairsToPixels
	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until MSG_VIS_MOVE_RESIZE_WIN to
					;do this.

10$:	;set this object REALIZABLE and update.

	; NOTE-- MUST be delayed via queue to match standard approach for
	; Primary's, Interactions, etc. necessitated by MSG_META_ATTACH
	; processing, or the Icon ends up being visibly opened before the
	; application object, a bad thing now that windows sit visibly on
	; the application object.  -- Doug 12/3/91
	;
	; Changed back to VUM_NOW to match new Primary, Interaction, etc.
	; approach.	-- Doug 4/8/92
	;
	mov	cx, mask SA_REALIZABLE	;set this flag TRUE
	mov	dl, VUM_NOW
	mov	ax, MSG_SPEC_SET_ATTRS
	call	ObjCallInstanceNoLock

	; Give ourselves the focus within the application, having just
	; become the most recent window to come up on screen.
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	ret
OLWinIconSetUsable	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconSetState -- MSG_OL_WIN_ICON_SETUP
		for OLWinIconClass

DESCRIPTION:	
	This method is sent to initialize some instance data in this object,
	including its position and Icon Slot # if necessary. This is called
	when the icon is created, to pass info about its GenPrimary
	(such as moniker handles) and other info from previous shutdowns
	(such as position and icon slot #).

PASS:		*ds:si - instance data
		es - segment of OLWinIconClass
		ax - MSG_OL_WIN_ICON_SETUP
		ss:bp	- pointer to bottom of data passed on stack
		dx	- size of data passed on stack
		on stack: (in order pushed)
			word	- WinPosSizeFlags <> (positioning requests)
			word	- WinPosSizeState <> (which icon slot #)
			2 words - VI_bounds.R_left, R_top (position)
			word	- handle of OLWinClass object associated w/icon
			OD	- OD of GenApplication

NOTE: the lptrs passed on the stack point to chunks within this ObjectBlock.

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version
	Eric	10/90		Added generic upward link code.

------------------------------------------------------------------------------@


OLWinIconSetState	method dynamic	OLWinIconClass,
					MSG_OL_WIN_ICON_SET_STATE

EC <	cmp	dx, size IconPassData					>
EC <	ERROR_NZ OL_ERROR						>

	;save OD of GenPrimary which is opened by this icon
	;and initialize the OLWinClass attribute record for this object

	mov	ax, ss:[bp].IPD_window.handle
	mov	ds:[di].OLWII_window.handle, ax

	mov	ax, ss:[bp].IPD_window.chunk
	mov	ds:[di].OLWII_window.chunk, ax

	mov	ax, ss:[bp].IPD_winPosSizeState
	mov	ds:[di].OLWI_winPosSizeState, ax

	mov	ax, ss:[bp].IPD_winPosSizeFlags
	mov	ds:[di].OLWI_winPosSizeFlags, ax

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	ax, ss:[bp].IPD_left
	mov	ds:[di].VI_bounds.R_left, ax

	mov	ax, ss:[bp].IPD_top
	mov	ds:[di].VI_bounds.R_top, ax
	ret
OLWinIconSetState	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconUpdateMoniker

DESCRIPTION:	Update our moniker and our title glyph's moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of OLWinIconClass
		ax 	- MSG_OL_WIN_ICON_UPDATE_MONIKER

		ss:bp	- IconMonikerPassData

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
	
OLWinIconUpdateMoniker	method dynamic OLWinIconClass, \
						MSG_OL_WIN_ICON_UPDATE_MONIKER

	push	ds:[di].OLWII_iconMoniker
	push	ds:[di].OLWII_iconCaptionMoniker

	;
	; copy icon moniker
	;
	mov	bx, bp				; ss:bx = IconMonikerPassData
	sub	sp, size CreateVisMonikerFrame
	mov	bp, sp
	mov	ax, ss:[bx].IMPD_iconMoniker.handle
	mov	ss:[bp].CVMF_source.handle, ax
	mov	ax, ss:[bx].IMPD_iconMoniker.chunk
	mov	ss:[bp].CVMF_source.chunk, ax
	mov	ss:[bp].CVMF_sourceType, VMST_OPTR
	mov	ss:[bp].CVMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[bp].CVMF_flags, 0		; not dirty
	mov	dx, size CreateVisMonikerFrame
	mov	ax, MSG_VIS_CREATE_VIS_MONIKER
	call	ObjCallInstanceNoLock		; ax = new moniker
	call	WinIcon_DerefVisSpec_DI
	mov	ds:[di].OLWII_iconMoniker, ax
	;
	; copy icon caption moniker
	;	ss:bx = IconMonikerPassData
	;
	mov	bp, sp				; ss:bp = stack frame
	mov	ax, ss:[bx].IMPD_iconCaptionMoniker.handle
	mov	ss:[bp].CVMF_source.handle, ax
	mov	ax, ss:[bx].IMPD_iconCaptionMoniker.chunk
	mov	ss:[bp].CVMF_source.chunk, ax
	mov	dx, size CreateVisMonikerFrame
	mov	ax, MSG_VIS_CREATE_VIS_MONIKER
	call	ObjCallInstanceNoLock		; ax = new moniker
	call	WinIcon_DerefVisSpec_DI
	mov	ds:[di].OLWII_iconCaptionMoniker, ax
	add	sp, size CreateVisMonikerFrame
	;
	; tell glyph, if already created, about new icon caption moniker
	;
	mov	dx, ax				; *ds:dx = new caption moniker
	mov	bp, si				; *ds:bp = this object (icon)
	mov	ax, MSG_OL_WIN_GLYPH_DISP_SET_MONIKER
	push	si				; save OLWinIcon
	mov	si, ds:[di].OLWII_titleGlyphWin	; *ds:si = icon caption
	tst	si
	jz	noGlyph
	call	ObjCallInstanceNoLock
noGlyph:
	pop	si				; restore OLWinIcon
	;
	; then invalidate, to get stuff to update
	;
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid
	;
	; finally, free old monikers
	;
	pop	ax			; handle icon caption moniker
	tst	ax
	jz	10$
	call	ObjFreeChunk
10$:
	pop	ax			; handle icon moniker
	tst	ax
	jz	done
	call	ObjFreeChunk
done:
	ret
OLWinIconUpdateMoniker endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconEnsureTitleGlyphDisplay

DESCRIPTION:	

PASS:		*ds:si - instance data

RETURN:		carry - ?
		dx - glyph display

DESTROYED:	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version

------------------------------------------------------------------------------@


OLWinIconEnsureTitleGlyphDisplay	proc	far
	class	OLWinIconClass

	;see if we have an OLWinGlyphDisplay object yet

	call	WinIcon_DerefVisSpec_DI
	mov	dx, ds:[di].OLWII_titleGlyphWin	; get chunk of glyph we have
	tst	dx				;See if already built
	jnz	done				;skip if so...

	;create an OLWinGlyphDisplay object to hold the title below the
	;icon. (We don't have the monikers yet - the GenPrimary has
	;yet to send SETUP to us.)

	push	si				;save WinIcon handle
	push	ds:[di].OLWII_iconCaptionMoniker ;save chunk handle of moniker

	mov	bx, ds:[LMBH_handle]		;put OLWinGlyph in same block
	mov	di, offset OLWinGlyphDisplayClass
	call	GenInstantiateIgnoreDirty	;returns si = handle of object

	;send MSG_OL_WIN_GLYPH_DISP_SET_MONIKER so WinGlyph object
	;has chunk handle of our GenPrimary's generic moniker

	pop	dx				;dx = chunk of moniker
	pop	bp				;bp = win icon
	push	bp
	mov	ax, MSG_OL_WIN_GLYPH_DISP_SET_MONIKER
	call	ObjCallInstanceNoLock
	mov	dx, si				;dx = chunk handle of OLWinGlyph
	pop	si				;get WinIcon handle

	call	WinIcon_DerefVisSpec_DI
	mov	ds:[di].OLWII_titleGlyphWin, dx	;store handle of OLWinGlyph

	push	si
	call	VisFindParent		;returns ^lbx:si = parent of OLWinIcon

EC <	tst	bx							>
EC <	ERROR_Z	OL_SPEC_BUILD_NO_PARENT					>

	mov	cx, ds:[LMBH_handle]	;set ^lcx:dx = OLWinGlyph object
	mov	bp, CCO_LAST	; add at the end
	mov	ax, MSG_VIS_ADD_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

done:
	ret
OLWinIconEnsureTitleGlyphDisplay	endp

WinIconCode ends

;---------------------------------------

LessUsedGeometry segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconRerecalcSize -- MSG_VIS_RECALC_SIZE for OLWinIconClass

DESCRIPTION:	Returns the size of the button.

PASS:
	*ds:si - instance data
	es - segment of OLWinIconClass
	di - MSG_VIS_GET_SIZE
	cx - width info for choosing size
	dx - height info

RETURN:
	cx - width to use
	dx - height to use

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@


OLWinIconRerecalcSize	method dynamic	OLWinIconClass, MSG_VIS_RECALC_SIZE

	mov     di, ds:[di].OLWII_iconMoniker	;*ds:di = VisMoniker
	segmov	es, ds				;*es:di = VisMoniker
	clr	bp			;pass no GState - will create one using
					;VUP query if necessary (text icon?)
	call	SpecGetMonikerSize	;returns cx, dx = size of moniker
	ret

OLWinIconRerecalcSize	endp
			
LessUsedGeometry ends

;---------------------------------------

WinIconCode segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinIconOpenWin

DESCRIPTION:	Perform MSG_VIS_OPEN_WIN given an OLWinPart

CALLED BY:	VisOpen

PASS:
	*ds:si - instance data
RETURN:		
	cl - DrawFlags: DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState to use

DESTROYED:
	ax, bx, dx, di, bp, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Lifted from OLWinClass

------------------------------------------------------------------------------@


OLWinIconOpenWin	method dynamic	OLWinIconClass, MSG_VIS_OPEN_WIN
	push	si

	; cause icon to open on top of other applicatin windows (such as other
	; primarys)

	ornf	ds:[di].OLWI_fixedAttr, mask OWFA_OPEN_ON_TOP

	;call superclass to for this object

	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass

	; must reset this after we've used it

	call	WinIcon_DerefVisSpec_DI
	andnf	ds:[di].OLWI_fixedAttr, not mask OWFA_OPEN_ON_TOP

	;make sure we have a title display object (will set moniker,
	;which sets geometry and image invalid)

	call	OLWinIconEnsureTitleGlyphDisplay	; dx = glyph display

	;now tell our OLWinGlyphDisplay object where we are on the screen -
	;it will position itself relative to the middle of our bottom bound.

	push	dx
	call	OLWinIconUpdateTitleGlyphWin	
	pop	dx

	;and make it visible

	mov	si, dx
	mov	ax, MSG_VIS_SET_ATTRS
	mov	cx, mask VA_VISIBLE		;SET this bit
						;(sets WINDOW_INVALID)
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	; At this point, we should have a slot all set up for us.  Let's
	; send the slot number back to our window.
	;	
	pop	si
	call	OLWinIconSendSlot	

	;AFTER doing all that, make sure we are completely on-screen by
	;faking a window move

	mov	ax, MSG_VIS_MOVE_RESIZE_WIN
	call	ObjCallInstanceNoLock

	;
	; add win icon and title glyph to always-interactible list
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	FALL_THRU	AddOrRemoveWinIconAndTitleGlyphToGCNList

OLWinIconOpenWin	endp

;
; pass:
;	*ds:si = OLWinIcon
;	ax = MSG_META_GCN_LIST_ADD or MSG_META_GCN_LIST_REMOVE
; return:
;	nothing
; destroyed:
;	bx, cx, dx, bp, di
;
AddOrRemoveWinIconAndTitleGlyphToGCNList	proc	far
gcnParams	local	GCNListParams
	.enter
	;
	; add/remove win icon
	;
	mov	di, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS
	call	AddOrRemoveToGCNListCommon

	mov	di, GAGCNLT_CONTROLLERS_WITHIN_USER_DO_DIALOGS
	call	AddOrRemoveToGCNListCommon
	;
	; add/remove title glyph
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLWII_titleGlyphWin
	tst	si
	jz	done
	mov	di, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS
	call	AddOrRemoveToGCNListCommon
done:
	pop	si
	.leave
	ret
AddOrRemoveWinIconAndTitleGlyphToGCNList	endp

;
; pass:
;	*ds:si = object to add/remove
;	ax = MSG_META_GCN_LIST_ADD or MSG_META_GCN_LIST_REMOVE
;	DI = GCNList to add to
; return:
;	nothing
; destroyed:
;	bx, cx, dx, di
;
AddOrRemoveToGCNListCommon	proc	near
	uses	ax, si
gcnParams       local   GCNListParams
	.enter	inherit
	mov	gcnParams.GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
						; don't save to state
	mov	gcnParams.GCNLP_ID.GCNLT_type, di
	mov	bx, ds:[LMBH_handle]
	mov	gcnParams.GCNLP_optr.handle, bx
	mov	gcnParams.GCNLP_optr.chunk, si
	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	noAppObj
	push	bp
	lea	bp, gcnParams
	mov	dx, size gcnParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
noAppObj:
	.leave
	ret
AddOrRemoveToGCNListCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinIconCheckIfInteractableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current object is interactable while
		a UserDoDialog is up

CALLED BY:	GLOBAL
PASS:		cx:dx - object that a message is destined for
RETURN:		carry set if interactable
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinIconCheckIfInteractableObject	method	dynamic OLWinIconClass,
					MSG_META_CHECK_IF_INTERACTABLE_OBJECT
	.enter
	cmp	cx, ds:[LMBH_handle]
	jne	noMatch
	cmp	dx, si
	je	matchExit
	cmp	dx, ds:[di].OLWII_titleGlyphWin
	jne	noMatch
matchExit:
	stc
exit:
	.leave
	ret
noMatch:
	clc
	jmp	exit
OLWinIconCheckIfInteractableObject	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinIconCloseWin

DESCRIPTION:	We intercept this here so that we can visibly remove our
		title glyph window from the field.

CALLED BY:	VisClose

PASS:
	*ds:si - instance data
RETURN:		
	cl - DrawFlags: DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState to use

DESTROYED:
	ax, bx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@


OLWinIconCloseWin	method dynamic	OLWinIconClass, MSG_VIS_CLOSE_WIN

	;
	; remove from always-interactible list
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	AddOrRemoveWinIconAndTitleGlyphToGCNList
	pop	ax, cx, dx, bp

	;call superclass to for this object

	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass

	call	WinIcon_DerefVisSpec_DI
	mov	si, ds:[di].OLWII_titleGlyphWin
	tst	si
	jz	done
						; Clear flag to indicate we
						; don't have one anymore
	clr	ds:[di].OLWII_titleGlyphWin

	; Visibly close & destroy the title glyph (Doug's handiwork :)

	mov	dl, VUM_NOW			; Update window now
	mov	ax, MSG_VIS_DESTROY		; Unrealize, remove & destroy
	call	ObjCallInstanceNoLock
done:
	ret

OLWinIconCloseWin	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconMoveResizeWin -- MSG_VIS_MOVE_RESIZE_WIN
		for OLWinIconClass

DESCRIPTION:	This icon is being moved - update the position of our
		OLWinGlyphDisplay object.

PASS:		*ds:si 	- instance data
		es     	- segment of OLWinIconClass
		ax 	- MSG_WIN_MOVE_RESIZE

RETURN:		nothing		

DESTROYED:	ax, cx, dx, bp, si, di
		
REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version

------------------------------------------------------------------------------@

	
OLWinIconMoveResizeWin	method dynamic	OLWinIconClass, MSG_VIS_MOVE_RESIZE_WIN
	;FIRST snap the icon to the nearest grid position (this could
	;be optional, but we must at least make sure the icon is on the screen)

	push	ax
;	call	OLWinIconSnapToGrid
;instead, just keep it onscreen - brianc 3/3/92
	call	OLWinIconKeepOnScreen
	pop	ax

	;call superclass to move this object

	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass

	;now tell our OLWinGlyphDisplay object where we are on the screen -
	;it will position itself relative to the middle of our bottom bound.

	call	OLWinIconUpdateTitleGlyphWin	
	ret
OLWinIconMoveResizeWin	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLWinIconSendSlot

SYNOPSIS:	Sends the slot to our corresponding window.

CALLED BY:	OLWinIconMoveResizeWin, OLWinIconSetUsable

PASS:		*ds:si -- handle

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/29/90		Initial version

------------------------------------------------------------------------------@

OLWinIconSendSlot	proc	far
	class	OLWinIconClass

	call	WinIcon_DerefVisSpec_DI
	mov	cx, ds:[di].VI_bounds.R_left			
	mov	dx, ds:[di].VI_bounds.R_top
	mov	al, {byte} ds:[di].OLWI_winPosSizeState+1
	clr	ah
	and	al, mask WPSS_STAGGERED_SLOT shr 8
	mov	bp, ax

	mov	ax, MSG_OL_MW_SET_ICON_POS
	call	OLWinIconCallPrimaryObject
	ret
OLWinIconSendSlot	endp

;pass *ds:si = instance data for this icon

OLWinIconCallPrimaryObject	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	OLWinIconObjMessagePrimaryObject
OLWinIconCallPrimaryObject	endp

;pass: di = MessageFlags

OLWinIconObjMessagePrimaryObject	proc	near
	push	si
	push	di			; save MessageFlags
	call	WinIcon_DerefVisSpec_DI
	mov	bx, ds:[di].OLWII_window.handle
	mov	si, ds:[di].OLWII_window.chunk
	pop	di			; retreive MessageFlags
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
	call	ObjMessage
	pop	si
	ret
OLWinIconObjMessagePrimaryObject	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinIconSnapToGrid

DESCRIPTION:	This procedure moves a window icon to the nearest icon plot.
		(See cwinConstant.def for a discussion of Icon Plots)

CALLED BY:	OLWinIconMoveResizeWin

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

------------------------------------------------------------------------------@

if 0	;just keep on-screen for 2.0 - brianc 3/3/92

OLWinIconSnapToGrid	proc	near
	class	OLWinIconClass

	; Let's remove the old slot number.

	call	WinIcon_DerefVisSpec_DI
	mov	dl, {byte} ds:[di].OLWI_winPosSizeState+1
	ANDNF	dl, mask WPSS_STAGGERED_SLOT shr 8
	test	dl, mask SSPR_SLOT		;test slot # (ignore ICON flag)
	jz	10$				;skip if not STAGGERED...

	mov	cx, SVQT_FREE_STAGGER_SLOT
	call	WinIcon_VisCallParent_VUP_QUERY
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent

10$:	;Find the nearest available slot.

	call	WinIcon_DerefVisSpec_DI
	mov	dx, ds:[di].VI_bounds.R_left	;get position
	mov	bp, ds:[di].VI_bounds.R_top
	mov	cx, SVQT_REQUEST_NEAREST_ICON_SLOT
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent			;returns cx, dx = size
	jnc	exit				;If no response, don't care...
	
	call	VisSetPosition				;Adjust coords accordingly

	;Store new slot number locally as well.

	call	WinIcon_DerefVisSpec_DI
	mov	dl, {byte} ds:[di].OLWI_winPosSizeState+1
	and	dl, not (mask WPSS_STAGGERED_SLOT shr 8)
	or	dx, bp				;put slot in cl
	mov	{byte} ds:[di].OLWI_winPosSizeState+1, dl

exit:	;Send our window the new slot number and position.

	call	OLWinIconSendSlot
	ret
OLWinIconSnapToGrid	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinIconKeepOnScreen

DESCRIPTION:	This procedure keeps a window icon on the screen.

CALLED BY:	OLWinIconMoveResizeWin

PASS:		ds:*si	- instance data

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/30/92		initial version

------------------------------------------------------------------------------@

OLWinIconKeepOnScreen	proc	near
	class	OLWinIconClass

	mov	ax, MSG_VIS_GET_BOUNDS
	call	VisCallParent			; ax, bp, cx, dx = (l, t, r, b)
	push	cx, dx
	call	WinIcon_DerefVisSpec_DI
	mov	cx, ds:[di].VI_bounds.R_left
	cmp	cx, ax
	jge	leftOkay
	mov	cx, ax				; else, update left
leftOkay:
	mov	dx, ds:[di].VI_bounds.R_top
	cmp	dx, bp
	jge	topOkay
	mov	dx, bp				; else, update top
topOkay:
	pop	ax, bp				; ax, bp = parent (r, b)
	mov	bx, ds:[di].VI_bounds.R_right
	cmp	bx, ax
	jle	rightOkay
	sub	bx, ds:[di].VI_bounds.R_left	; bx = width
	sub	ax, bx				; inset from parent right
	mov	cx, ax				; use as new icon left
rightOkay:
	push	si, di, cx, dx
	call	WinIcon_DerefVisSpec_DI
	mov	si, ds:[di].OLWII_titleGlyphWin
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
	call	VisGetSize			; dx = glyph height
EC <	tst	dx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	ax, dx				; ax = glyph height
	add	ax, WIN_ICON_GLYPH_Y_SPACING	; ax = total glyph height
	pop	si, di, cx, dx
	mov	bx, ds:[di].VI_bounds.R_bottom
	add	bx, ax				; bx = total bottom
	cmp	bx, bp
	jle	bottomOkay
	sub	bx, ds:[di].VI_bounds.R_top
	sub	bp, bx				; inset from parent bottom
	mov	dx, bp				; use as new icon top
bottomOkay:
	call	VisSetPosition

exit:	;Send our window the new slot number and position.

	call	OLWinIconSendSlot
	ret
OLWinIconKeepOnScreen	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinIconUpdateTitleGlyphWin

DESCRIPTION:	This procedure updates the OLWinGlyphDisplay object
		which holds the title for this icon. This involves moving
		the OLWinGlyph object.

CALLED BY:	OLWinIconMoveResizeWin
		OLWinIconOpenWindow

PASS:		ds:*si	- instance data

RETURN:		ax, cx, dx, bp = same

DESTROYED:	ax, cx, dx, bp, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

------------------------------------------------------------------------------@

OLWinIconUpdateTitleGlyphWin	proc	far
	class	OLWinIconClass

	;now tell our OLWinGlyphDisplay object where we are on the screen -
	;it will position itself relative to the middle of our bottom bound.

EC <	call	VisCheckVisAssumption	; Make sure vis data exists >

	call	WinIcon_DerefVisSpec_DI
	mov	cx, ds:[di].VI_bounds.R_left	;average left and right
	add	cx, ds:[di].VI_bounds.R_right
	shr	cx, 1
	mov	dx, ds:[di].VI_bounds.R_bottom	;get bottom bound

	;send on to our OLWinGlyphDisplay object so it moves with us

	mov	si, ds:[di].OLWII_titleGlyphWin
	mov	ax, MSG_OL_WIN_GLYPH_DISP_MOVE
	call	ObjCallInstanceNoLock
	ret
OLWinIconUpdateTitleGlyphWin	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconDraw -- MSG_VIS_DRAW for OLWinIconClass

PASS:
	*ds:si - instance data
	bp - handle of graphics state
RETURN:
	cl - DrawFlags: DF_EXPOSED set if updating
	ch - ?
	dx - ?
	bp - GState to use

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	9/89		Initial Version

------------------------------------------------------------------------------@


OL_WIN_ICON_MAX_WIDTH	= 1023

OLWinIconDraw	method dynamic	OLWinIconClass, MSG_VIS_DRAW
	push	es
	push	cx			;save draw flags

	;get display scheme data (bp = gstate)

	mov	di, bp			;di = GState
	mov	ax, GIT_PRIVATE_DATA
	call	GrGetInfo		;ax = <display scheme><display type>

	;Draw flat background & thin black line border, and shadow/resize border
	;if necessary.
	;(al = color scheme, ah = display type, cl = DrawFlags,
	;ds:*si = instance, ds:bp = SpecificInstance, di = GState)

;	mov	al, C_WHITE
;
;	and	ah, mask DF_DISPLAY_TYPE
;	cmp	ah, DC_GRAY_1
;	jnz	OWID_color
;
;	mov	al, C_BLACK
;OWID_color:

	;draw icon (bp = GState)

	mov	di, bp				;pass di = gstate
;OL <	mov	ax, C_WHITE						>
	mov	ax, C_BLACK
	call	GrSetAreaColor

	segmov	es, ds				;pass *es:bx = VisMoniker
	call	WinIcon_DerefVisSpec_DI
	mov	bx, ds:[di].OLWII_iconMoniker

	push	bp			;save GState
	mov	di, bp

	mov	cl, mask DMF_NONE	;draw at pen position, no justification
	sub	sp, size DrawMonikerArgs
	mov	bp, sp			;ss:bp <- DrawMonikerArgs
	mov	ss:[bp].DMA_gState, di
	mov	ss:[bp].DMA_xMaximum, OL_WIN_ICON_MAX_WIDTH
	mov	ss:[bp].DMA_yMaximum, MAX_COORD
	mov	dx, 1
	mov	ss:[bp].DMA_xInset, dx
	mov	ss:[bp].DMA_yInset, dx
	call	SpecDrawMoniker		 ;draw moniker onto our window
	add	sp, size DrawMonikerArgs ;clean up stack
	pop	bp			;get GState
	mov	di, bp				;pass di = gstate
	mov	ax, C_BLACK		;set back to black
	call	GrSetAreaColor

	pop	cx			;recover DrawFlags
	pop	es
	ret
OLWinIconDraw	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconGainedSystemFocusExcl

DESCRIPTION:	We've just gained the window focus exclusive.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_META_GAINED_SYS_FOCUS_EXCL

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
	Eric	10/89		Initial version

------------------------------------------------------------------------------@


OLWinIconGainedSystemFocusExcl	method dynamic	OLWinIconClass,
					MSG_META_GAINED_SYS_FOCUS_EXCL

	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass

	;Bring this object to the front...

	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
	
	push	si
	call	WinIcon_DerefVisSpec_DI
	mov	si, ds:[di].OLWII_titleGlyphWin
	tst	si
	jz	done

	mov	ax, MSG_OL_WIN_GLYPH_BRING_TO_TOP
	call	ObjCallInstanceNoLock

	;
	; invalidate the glyph so that it redraws with focus indication
	;
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid

done:
	pop	si
	ret

OLWinIconGainedSystemFocusExcl	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconLostSystemFocusExcl

DESCRIPTION:	We've just lost the window focus exclusive.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_META_LOST_SYS_FOCUS_EXCL

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
	brianc	2/12/92		Initial version

------------------------------------------------------------------------------@


OLWinIconLostSystemFocusExcl	method dynamic	OLWinIconClass,
					MSG_META_LOST_SYS_FOCUS_EXCL

	push	ax, si

	mov	si, ds:[di].OLWII_titleGlyphWin
	tst	si
	jz	done

	;
	; invalidate the glyph so that it redraws without focus indication
	;
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid

done:
	pop	ax, si
	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass
	ret

OLWinIconLostSystemFocusExcl	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconStartSelect -- MSG_META_START_SELECT

DESCRIPTION:	Handler for SELECT button pressed on Window Icon.
		If this is a double-click, we want to open the GenPrimary
		associated with this icon. Otherwise, we just call the
		superclass (OLWinClass) so it can handle as usual.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

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
	Eric	10/89		Initial version

------------------------------------------------------------------------------@


OLWinIconStartSelect	method dynamic	OLWinIconClass, MSG_META_START_SELECT
	;Now is this is a window icon, and the event is double-press,
	;open the window up

	test	bp, mask BI_DOUBLE_PRESS
	jz	OLWISS_50			;skip if not...

	;send MSG_OL_RESTORE_WIN to self

	mov	ax, MSG_OL_RESTORE_WIN
	call	ObjCallPreserveRegs
	mov	ax, mask MRF_PROCESSED
	ret

OLWISS_50:
	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass
	ret
OLWinIconStartSelect	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconMaximizeFromIcon --
			MSG_OL_MAXIMIZE_FROM_ICON

DESCRIPTION:	This is invoked when the user presses on the MAXIMIZE
		item in the system menu.

PASS:		*ds:si - instance data
		es - segment of OLWinIconClass

		ax - MSG_OL_MAXIMIZE_FROM_ICON
		cx:dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:
		Send MSG_GEN_DISPLAY_SET_MAXIMIZED to GenPrimary.
		Send MSG_GEN_DISPLAY_SET_NOT_MINIMIZED to GenPrimary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version
	Eric	10/90		updated to use OD to get to Primary

------------------------------------------------------------------------------@

OLWinIconMaximizeFromIcon	method dynamic	OLWinIconClass,
						MSG_OL_MAXIMIZE_FROM_ICON

	;tell the GenPrimary to wake up (and MAXIMIZE if necessary)
	;	ds:di	= instance data

	mov	ax, MSG_GEN_DISPLAY_SET_MAXIMIZED
	call	OLWinIconCallPrimaryObject

	FALL_THRU OLWinIconRestoreWin
OLWinIconMaximizeFromIcon	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLWinIconRestoreWin -- MSG_OL_RESTORE_WIN

DESCRIPTION:	This is invoked when the user presses on the RESTORE
		item in the system menu, or when they double-click
		on this OLWinIcon object.

PASS:		*ds:si - instance data
		es - segment of OLWinIconClass

		ax - MSG_OL_RESTORE_WIN
		cx:dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:
		Send MSG_GEN_DISPLAY_SET_NOT_MINIMIZED to GenPrimary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		Initial version
	Eric	10/90		updated to use OD to get to Primary

------------------------------------------------------------------------------@

;note FALL_THRU above

OLWinIconRestoreWin	method OLWinIconClass, MSG_OL_RESTORE_WIN

	;tell the GenPrimary to wake up (and MAXIMIZE if necessary)

	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	mov	dl, VUM_NOW

	call	WinIcon_DerefVisSpec_DI
	mov	bx, ds:[di].OLWII_window.handle
	mov	si, ds:[di].OLWII_window.chunk
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
OLWinIconRestoreWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLWinIconFupKbdChar - MSG_META_FUP_KBD_CHAR handler

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

		At this class level, the parent in the focus hierarchy is
		is the generic parent.

PASS:		*ds:si	= instance data for object
		ds:di = specific instance data for object
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/12/92		Initial version (adapted from similar handlers)

------------------------------------------------------------------------------@

OLWinIconFupKbdChar	method dynamic	OLWinIconClass, MSG_META_FUP_KBD_CHAR

	push	ax			;save method

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper		;ignore character...

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		;skip if not press event...

	push	es			;set es:di = table of shortcuts
	segmov	es, cs
	mov	di, offset cs:OLWinIconKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jnc	callSuper		;skip if none found...

	call	ObjCallInstanceNoLock	;send message to self

	pop	ax			;restore method
	stc				;say handled
	ret

callSuper:
	pop	ax			;restore method

	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass
exit:
	ret
OLWinIconFupKbdChar	endm

if _USE_KBD_ACCELERATORS	;---------------------------------------------

OLWinIconKbdBindings	label	word
	word	length	OLWinIconShortcutList
		;p  a  c  s   c
		;h  l  t  h   h
		;y  t  r  f   a
		;s     l  t   r
		;
if DBCS_PCGEOS
OLWinIconShortcutList	KeyboardShortcut \
		<0, 1, 0, 0, C_SYS_F5 and mask KS_CHAR>,	;RESTORE
		<0, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>	;RESTORE
else
OLWinIconShortcutList	KeyboardShortcut \
		<0, 1, 0, 0, 0xf, VC_F5>,	;RESTORE
		<0, 0, 0, 0, 0xf, VC_ENTER>	;RESTORE
endif

;OLWinIconMethodList	label word
	word	MSG_OL_RESTORE_WIN
	word	MSG_OL_RESTORE_WIN


else	;--------------------------------------------------------------------

OLWinIconKbdBindings	label	word
	word	length	OLWinIconShortcutList
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
if DBCS_PCGEOS
OLWinIconShortcutList	KeyboardShortcut \
		<0, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>	;RESTORE
else
OLWinIconShortcutList	KeyboardShortcut \
		<0, 0, 0, 0, 0xf, VC_ENTER>	;RESTORE
endif

;OLWinIconMethodList	label word
	word	MSG_OL_RESTORE_WIN


endif	;---------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinIconGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update task entry list

CALLED BY:	MSG_META_GAINED_SYS_TARGET_EXCL

PASS:		*ds:si	= OLWinIconClass object
		ds:di	= OLWinIconClass instance data
		es 	= segment of OLWinIconClass
		ax	= MSG_META_GAINED_SYS_TARGET_EXCL

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/29/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinIconGainedSysTargetExcl	method	dynamic	OLWinIconClass,
					MSG_META_GAINED_SYS_TARGET_EXCL

	call	WinIcon_ObjCallSuperNoLock_OLWinIconClass

	call	UpdateAppMenuItemCommon
	ret
OLWinIconGainedSysTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLWinIconTestWinInteractibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	respond that we are interactible

CALLED BY:	MSG_META_TEST_WIN_INTERACTIBILITY

PASS:		*ds:si	= OLWinIconClass object
		ds:di	= OLWinIconClass instance data
		es 	= segment of OLWinIconClass
		ax	= MSG_META_TEST_WIN_INTERACTIBILITY

		^lcx:dx	= InputOD of window to check
		^hbp	= Window to check

RETURN:		carry	= set if mouse allowed in window, clear if not.

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLWinIconTestWinInteractibility	method	dynamic	OLWinIconClass,
					MSG_META_TEST_WIN_INTERACTIBILITY
	tst_clc	cx
	jz	done			; no window, not allow
	cmp	cx, ds:[LMBH_handle]
	jne	notSelf
	cmp	dx, si
	stc				; assume is us
	je	done
notSelf:
	clc				; else, not allowed
done:
	ret
OLWinIconTestWinInteractibility	endm

WinIconCode ends

endif
