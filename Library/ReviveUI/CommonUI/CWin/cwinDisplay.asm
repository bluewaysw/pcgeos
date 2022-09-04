COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Win
FILE:		winCommand.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDisplayWinClass		Open look command window class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version

DESCRIPTION:

	$Id: cwinDisplay.asm,v 2.129 96/07/18 03:29:42 joon Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLDisplayWinClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

if _NIKE
	DisplayTitleClass
endif

CommonUIClassStructures ends


;---------------------------------------------------

MDICommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinInitialize -- MSG_META_INITIALIZE for OLDisplayWinClass

DESCRIPTION:	Initialize an open look notice

PASS:
	*ds:si - instance data
	es - segment of OLDisplayWinClass

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
	Doug	7/89		Initial version

------------------------------------------------------------------------------@

OLDisplayWinInitialize	method dynamic	OLDisplayWinClass, MSG_META_INITIALIZE

	;set these for FindMonikers in OLMenuedWinInitalize, they may be
	;reset by superclass, so we set them again later

CUAS <	mov	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>

	;call superclass (do not call OpenWinInitialize directly!)

	mov	di, offset OLDisplayWinClass
	CallSuper	MSG_META_INITIALIZE

	call	MDICommon_DerefVisSpec_DI	; ds:di is SpecInstance
				; & give basic base window attributes

CUAS <	ORNF	ds:[di].OLWI_attrs, MO_ATTRS_DISPLAY_WINDOW		>
					;see CWin/cwinClass.asm for definition
NKE <	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_MOVABLE or \
					 mask OWA_HAS_SYS_MENU or \
					 mask OWA_HEADER or \
					 mask OWA_TITLED)		>
ODIE <	ANDNF	ds:[di].OLWI_attrs, not mask OWA_HAS_SYS_MENU		>

CUAS <	mov	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>
					; Store is base window

	;See if GenDisplay is marked as allowing the user to be able to
	;dismiss it.

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di is GenInstance
	test	ds:[di].GDI_attributes, mask GDA_USER_DISMISSABLE
	pop	di
	jz	OLDWI_30		; skip if not.

	;is dismissable:
CUAS <					; Mark as closable		>
CUAS <	ORNF	ds:[di].OLWI_attrs, mask OWA_CLOSABLE			>

OLDWI_30:

;
; NOT just yet..  This is a proposed change for V2.0, in which displays & 
; primarys would always come up if USABLE & ATTACHED.  At this point in
; time, they still need to be INITIATED separately, thought they are
; automatically initiated if on the active list.  See related comment
; in OpenWinAttach.	-- Doug 12/10/91
;
; Now... - brianc 3/3/92
	; Allow windows to come up when USABLE
	ORNF	ds:[di].VI_specAttrs, mask SA_REALIZABLE

	; Set up geometry now.
	call	OLDisplayWinScanGeometryHints


	;process some GenDisplay-specific hints

					;setup es:di to be ptr to
					;Hint handler table
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLDisplayWinHintHandlers
	mov	ax, length (cs:OLDisplayWinHintHandlers)
	call	ObjVarScanData

;	;if this window is marked as MINIMIZED and the specific UI
;	;allows this, set as not SA_REALIZABLE and SA_BRANCH_MINIMIZED
;	;so visible build will not occur
;
;this is handled in MSG_META_UPDATE_WINDOW (of OLMenuedWinClass) and
;MSG_SPEC_SET_USABLE handlers - brianc 3/12/92

	; NOW, set up optimization bit in specific attributes of visual
	; portion of object, accordingly:  If this display is marked to
	; always adopt menus, then we need to make sure that
	; MSG_SPEC_BUILD_BRANCH is sent to this object whenver the 
	; display control is vis built, or in the case that we are usable
	; but not on screen, we will not be built, resulting in no
	; adopted menu.  To prevent this, set SA_SPEC_BUILD_ALWAYS
	; in the case where it is needed.
	;
	call	MDICommon_DerefVisSpec_DI
	test	ds:[di].OLDW_flags, mask OLDWF_ALWAYS_ADOPT_MENUS
	jz	done

					; Set bit indicating this window
					; should be VIS-BUILT as long as it
					; is USABLE, should it's parent ever
					; be vis-built.
;	ORNF	ds:[di].VI_specAttrs, mask SA_SPEC_BUILD_ALWAYS
done:
	ret
OLDisplayWinInitialize	endp


OLDisplayWinHintHandlers	VarDataHandler \
	< HINT_NEVER_ADOPT_MENUS, offset DisplayWinHintNeverAdoptMenus >,
	< HINT_ALWAYS_ADOPT_MENUS, offset DisplayWinHintAlwaysAdoptMenus >,
	< ATTR_GEN_DISPLAY_NOT_MINIMIZABLE, offset DisplayWinAttrGenDisplayNotMinimizable >,
	< ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE, offset DisplayWinAttrGenDisplayNotMaximizable >,
	< ATTR_GEN_DISPLAY_NOT_RESTORABLE, offset DisplayWinAttrGenDisplayNotRestorable >,
	< HINT_DISPLAY_NOT_RESIZABLE, offset DisplayWinHintDisplayNotResizable >,
	< HINT_DISPLAY_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD, offset DisplayDefaultActionIsNavigateToNextField >


DisplayWinHintNeverAdoptMenus	proc	far
	class	OLDisplayWinClass
	call	MDICommon_DerefVisSpec_DI
	ORNF	ds:[di].OLDW_flags, mask OLDWF_NEVER_ADOPT_MENUS
	ret
DisplayWinHintNeverAdoptMenus	endp

DisplayWinHintAlwaysAdoptMenus	proc	far
	class	OLDisplayWinClass
	call	MDICommon_DerefVisSpec_DI
	ORNF	ds:[di].OLDW_flags, mask OLDWF_ALWAYS_ADOPT_MENUS
	ret
DisplayWinHintAlwaysAdoptMenus	endp

DisplayWinAttrGenDisplayNotMinimizable	proc	far
	class	OLWinClass
	call	MDICommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_MINIMIZABLE
	ret
DisplayWinAttrGenDisplayNotMinimizable	endp

DisplayWinAttrGenDisplayNotMaximizable	proc	far
	class	OLWinClass
	call	MDICommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not mask OWA_MAXIMIZABLE
	ret
DisplayWinAttrGenDisplayNotMaximizable	endp

DisplayWinAttrGenDisplayNotRestorable	proc	far
	class	OLWinClass
	call	MDICommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_fixedAttr, not (mask OWFA_RESTORABLE)
	ret
DisplayWinAttrGenDisplayNotRestorable	endp

DisplayWinHintDisplayNotResizable	proc	far
	class	OLWinClass
	call	MDICommon_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_attrs, not (mask OWA_RESIZABLE)
	ret
DisplayWinHintDisplayNotResizable	endp

DisplayDefaultActionIsNavigateToNextField	proc	far
	class	OLWinClass
	call	MDICommon_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_moreFixedAttr, \
			mask OWMFA_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD
	ret
DisplayDefaultActionIsNavigateToNextField	endp

MDICommon_DerefVisSpec_DI	proc	near
	class	VisClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
MDICommon_DerefVisSpec_DI	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLDisplayWinClass

DESCRIPTION:	Scans geometry hints.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

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
	chris	2/ 5/92		Initial Version

------------------------------------------------------------------------------@

OLDisplayWinScanGeometryHints	method static OLDisplayWinClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	mov	di, segment OLDisplayWinClass
	mov	es, di

	;superclasses handle a lot of stuff

	mov	di, offset OLDisplayWinClass
	CallSuper	MSG_SPEC_SCAN_GEOMETRY_HINTS

	;override OLWinClass positioning/sizing behavior:

	call	MDICommon_DerefVisSpec_DI	; ds:di is SpecInstance

if _NIKE
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_STAGGER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
else
	mov	ds:[di].OLWI_winPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_KEEP_PARTIALLY_VISIBLE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_STAGGER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)
endif

	;now set positioning behavior for icon:

ifdef NO_WIN_ICONS	;------------------------------------------------------

	mov	cx, FALSE

else	;----------------------------------------------------------------------

	mov	ds:[di].OLMDWI_iconWinPosSizeFlags, \
		   mask WPSF_PERSIST \
		or (WCT_NONE shl offset WPSF_CONSTRAIN_TYPE) \
		or (WPT_STAGGER shl offset WPSF_POSITION_TYPE) \
		or (WST_AS_DESIRED shl offset WPSF_SIZE_TYPE)

	mov	ds:[di].OLMDWI_iconWinPosSizeState, \
			  (mask SSPR_ICON shl offset WPSS_STAGGERED_SLOT) \
			or mask WPSS_POSITION_INVALID or mask WPSS_SIZE_INVALID
					;set flag: is icon, so stagger as one.

	;handle window-specific hints

	mov	cx, TRUE		;pass flag: window can have an icon

endif	; ifdef NO_WIN_ICONS --------------------------------------------------

	call	OpenWinProcessHints	;process window positioning and sizing
					;hints from application.
	.leave
	ret
OLDisplayWinScanGeometryHints	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayWinUpdateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove title object when detaching

CALLED BY:	MSG_META_UPDATE_WINDOW
PASS:		*ds:si	= OLDisplayWinClass object
		ds:di	= OLDisplayWinClass instance data
		ds:bx	= OLDisplayWinClass object (same as *ds:si)
		es 	= segment of OLDisplayWinClass
		ax	= message #
		cx	= UpdateWindowFlags
		dl	= VisUpdateMode
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

OLDisplayWinUpdateWindow	method dynamic OLDisplayWinClass, 
					MSG_META_UPDATE_WINDOW
	test	cx, mask UWF_DETACHING
	jz	callSuper

	call	RemoveTitleObjectFromThisDisplay

callSuper:
	mov	di, offset OLDisplayWinClass
	GOTO	ObjCallSuperNoLock

OLDisplayWinUpdateWindow	endm

endif		;--------------------------------------------------------------



COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinVisUnbuildBranch

DESCRIPTION:	Intercept begining of destruction of this display to
		get any traveling objects off of us before they are taken
		down with the ship.

PASS:		*ds:si - instance data
		es - segment of OLDisplayWinClass

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/17/92		Initial version

------------------------------------------------------------------------------@


OLDisplayWinVisUnbuildBranch	method dynamic	OLDisplayWinClass, \
					MSG_SPEC_UNBUILD_BRANCH
NKE <	call	RemoveTitleObjectFromThisDisplay			>
	call	RemoveTravelingObjectsFromThisDisplay
	mov	di, offset OLDisplayWinClass
	GOTO	ObjCallSuperNoLock

OLDisplayWinVisUnbuildBranch	endm

COMMENT @----------------------------------------------------------------------
FUNCTION:	RemoveTravelingObjectsFromThisDisplay

DESCRIPTION:	Remove any traveling objects hooked up to this display.

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenDisplay object
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
RemoveTravelingObjectsFromThisDisplay	proc	near
	push	bp
	clr	bp			; Remove from this display
	call	TravelingObjectsCommon
	pop	bp
	ret
RemoveTravelingObjectsFromThisDisplay	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveTitleObjectFromThisDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove title object

CALLED BY:	OLDisplayWinVisUnbuildBranch
		OLDisplayWinUpdateWindow
PASS:		*ds:si	= OLDisplayWinClass object
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

RemoveTitleObjectFromThisDisplay	proc	near
	uses	ax,cx,dx,si,bp
	.enter

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	clr	si
	xchg	si, ds:[bx].OLDW_titleObject
	tst	si
	jz	done

	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	clr	bp				;bp <- don't dirty
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
RemoveTitleObjectFromThisDisplay	endp

endif		;--------------------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinSpecUpdateVisMoniker

DESCRIPTION:	We intercept this here to make sure that if and only if
		this Display has a moniker, it has a GenItem in the
		MDI Windows menu.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OLDisplayWinSpecUpdateVisMoniker	method dynamic	OLDisplayWinClass, \
						MSG_SPEC_UPDATE_VIS_MONIKER
	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock

if _NIKE
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLDW_titleObject
	tst	si
	jz	notitle
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid
notitle:
	pop	si
endif

	; We must send a complete notification to force the display list(s)
	; to be rebuilt

	call	OLDisplayWinSendCompleteNotification
	call	MDICommon_DerefVisSpec_DI
	test	ds:[di].OLDW_flags, mask OLDWF_TARGET
	jz	done
	mov	bx, 1
	call	OLDisplayWinSendNotification
done:
	ret

OLDisplayWinSpecUpdateVisMoniker	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinSendCompleteNotification

DESCRIPTION:	Send GCN notification for complete list change

CALLED BY:	INTERNAL

PASS:
	*ds:si - OLDisplayWin object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
OLDisplayWinSendCompleteNotification	method OLDisplayWinClass,
					MSG_OL_DISPLAY_SEND_NOTIFICATION
						uses es
	.enter

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	; generate the notification block

	mov	ax, size NotifyDisplayListChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or (mask HAF_ZERO_INIT shl 8) \
				or mask HF_SHARABLE
	call	MemAlloc
	push	bx
	mov	es, ax

	push	si
	call	GenSwapLockParent
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	.warn -private
	inc	ds:[di].OLDGI_notifyCounter
	mov	ax, ds:[di].OLDGI_notifyCounter
	.warn @private
	mov	es:NDLC_counter, ax
	mov	ax, ds:[LMBH_handle]
	movdw	es:NDLC_group, axsi
	call	ObjSwapUnlock
	pop	si

	pop	bx
	call	MemUnlock

	mov	ax, 1
	call	MemInitRefCount

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_LIST_CHANGE
	mov	dx, GWNT_DISPLAY_LIST_CHANGE
	call	SendNotifyCommon

	mov	bx, 1
	call	OLDisplayWinSendNotification

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
OLDisplayWinSendCompleteNotification	endm

;---

SendNotifyCommon	proc	near	uses si
	.enter

	mov	bp, bx
	push	bx, cx
	clrdw	bxsi
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, cx

	mov	ax, mask GCNLSF_SET_STATUS
	tst	bp
	jnz	afterTransitionCheck
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax

	mov	ax, MSG_META_GCN_LIST_SEND
	mov	dx, size GCNListMessageParams

	call	UserCallApplication

; UserCallApplication spelled out here, in case we need to change approach
;	call	GeodeGetAppObject
;	mov	di, mask MF_FIXUP_DS or mask MF_STACK
;	call	ObjMessage

	add	sp, size GCNListMessageParams

	.leave
	ret

SendNotifyCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinSendNotification

DESCRIPTION:	Send GCN notification

CALLED BY:	INTERNAL

PASS:
	*ds:si - OLDisplayWin object
	bx - 0 to send out empty block (lost target), 1 to generate block

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 6/92		Initial version

------------------------------------------------------------------------------@
OLDisplayWinSendNotification	proc	far	uses es
	.enter

	tst	bx
	LONG jz	haveNotificationBlock

	call	MDICommon_DerefVisSpec_DI
	test	ds:[di].OLDW_flags, mask OLDWF_TARGET
	LONG jz	done

	; generate the notification block

	mov	ax, size NotifyDisplayChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or (mask HAF_ZERO_INIT shl 8) \
				or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	push	bx

	; find our child number

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;cxdx = display
	call	GenSwapLockParent

	; while we have our parent locked let's cheat a bit and see if we're
	; in overlapping mode

	mov	ax, ATTR_GEN_DISPLAY_GROUP_OVERLAPPING_STATE
	call	ObjVarFindData
	mov	al, 0
	jnc	notOverlapping
	inc	al

NKE <	mov	ax, HINT_DISPLAY_GROUP_TILE_VERTICALLY			>
NKE <	call	ObjVarFindData						>
NKE <	mov	al, 1							>
NKE <	jc	notOverlapping						>
NKE <	mov	al, 2							>

notOverlapping:
NKE <	push	cx, dx							>
NKE <	push	ax							>
NKE <	mov	ax, MSG_VIS_COUNT_CHILDREN				>
NKE <	call	ObjCallInstanceNoLock					>
NKE <	shl	dx, 1							>
NKE <	shl	dx, 1							>
NKE <	shl	dx, 1							>
NKE <	shl	dx, 1							>
NKE <	pop	ax							>
NKE <	ornf	al, dl				;child count in high nibble>
NKE <	pop	cx, dx							>

	mov	es:NDC_overlapping, al	

	clr	ax				;child number
	push	ax, ax				;initial child
	mov	bx, offset GI_link
	push	bx				;LinkPart
	mov	bx, SEGMENT_CS
	push	bx
	mov	bx, offset FindDisplayCallback
	push	bx
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren		;ax = child number

	mov	bx, cx
	call	ObjSwapUnlock
	mov	si, dx

EC <	ERROR_NC	OL_ONE_WAY_UPWARD_LINK_FROM_DISPLAY_TO_DISPLAY_GROUP_NOT_ALLOWED	>

	mov	es:NDC_displayNum, ax

	; copy vis moniker text

	mov	di, offset NDC_name
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	si, ds:[si].GI_visMoniker
	tst	si
	jz	afterCopyName
	mov	si, ds:[si]			;ds:si = vis moniker
	ChunkSizePtr	ds, si, cx
	add	si, offset VM_data.VMT_text
	sub	cx, offset VM_data.VMT_text
DBCS <	shr	cx, 1							>
	dec	cx				;nuke null at end
SBCS <	cmp	cx, (size NDC_name) - (type NDC_name)			>
DBCS <	cmp	cx, ((size NDC_name) - (type NDC_name))/(size wchar)	>
	jbe	gotNameSize
SBCS <	mov	cx, (size NDC_name) - (type NDC_name)			>
DBCS <	mov	cx, ((size NDC_name) - (type NDC_name))/(size wchar)	>
gotNameSize:
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
afterCopyName:
	clr	ax
	LocalPutChar esdi, ax
	pop	si

	pop	bx
	call	MemUnlock

	mov	ax, 1
	call	MemInitRefCount

haveNotificationBlock:
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE
	mov	dx, GWNT_DISPLAY_CHANGE
	call	SendNotifyCommon

done:
	.leave
	ret

OLDisplayWinSendNotification	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindDisplayCallback

DESCRIPTION:	Find a display

CALLED BY:	INTERNAL

PASS:
	*es:di - display group
	*ds:si - display
	cx:dx - display that we're looking for
	ax - count so far

RETURN:
	carry - set if found
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
FindDisplayCallback	proc	far
	cmp	cx, ds:[LMBH_handle]
	jnz	notFound
	cmp	dx, si
	stc
	jz	done
notFound:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	10$

	; Removed on 11/13/93 by Don, as minimized windows should still
	; be accessed via the Window menu. Logic here *must* match that
	; in FindNumDisplaysCallback() in cwinDisplayControl.asm
	;
;;;	mov	di, ds:[si]
;;;	add	di, ds:[di].Vis_offset
;;;	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
;;;	jnz	10$
	inc	ax
10$:
	clc
done:
	ret

FindDisplayCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayWinSetDisplayTitleView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a title object to place in the horizontal scroller
		area of GenView

CALLED BY:	MSG_OL_WIN_SET_DISPLAY_TITLE_VIEW
PASS:		*ds:si	= OLDisplayWinClass object
		ds:di	= OLDisplayWinClass instance data
		ds:bx	= OLDisplayWinClass object (same as *ds:si)
		es 	= segment of OLDisplayWinClass
		ax	= message #
		^lcx:dx	= GenView
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

OLDisplayWinSetDisplayTitleView	method dynamic OLDisplayWinClass, 
					MSG_OL_WIN_SET_DISPLAY_TITLE_VIEW
	tst	ds:[di].OLDW_titleObject
	LONG jnz done

	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	pushf

	mov	bp, si				; *ds:bp <- OLDisplayWinClass

	push	cx, dx				; save GenView
	mov	di, segment DisplayTitleClass
	mov	es, di
	mov	di, offset DisplayTitleClass	; es:di <- ptr to class
	mov	bx, ds:[LMBH_handle]		; bx <- block to create in
	call	GenInstantiateIgnoreDirty

	mov	bx, offset Gen_offset
	call	ObjInitializePart

	mov	bx, offset Vis_offset
	call	ObjInitializePart

	mov	di, ds:[bp]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLDW_titleObject, si

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].DTI_display, bp

	mov	ax, HINT_SEEK_X_SCROLLER_AREA
	clr	cx
	call	ObjVarAddData

	mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
	call	ObjVarAddData

	mov	ax, HINT_MINIMUM_SIZE
	mov	cx, size SpecWidth + size SpecHeight
	call	ObjVarAddData

	push	ds
	mov	ax, segment idata		; get segment of core blk
	mov	ds, ax
	mov	ax, ds:[olArrowSize]		; absolute height to objects
	inc	ax
	inc	ax
	pop	ds

	mov	{word} ds:[bx], 0
	mov	{word} ds:[bx+2], ax

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; ^lcx:dx <- DisplayTitle
	pop	bx, si				; ^lbx:si <- GenView

	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_FIRST
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	popf					; maximized?
	jnz	done				; then don't set usable

	mov	si, dx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	GOTO	ObjCallInstanceNoLock
done:
	ret
OLDisplayWinSetDisplayTitleView	endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayTitleVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw display title

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= DisplayTitleClass object
		ds:di	= DisplayTitleClass instance data
		ds:bx	= DisplayTitleClass object (same as *ds:si)
		es 	= segment of DisplayTitleClass
		ax	= message #
		cl	= DrawFlags:
			  DF_EXPOSED set if GState is set to update window
		^hbp	= GState to draw through
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

DisplayTitleVisDraw	method dynamic DisplayTitleClass, 
					MSG_VIS_DRAW
	push	si
	mov	si, ds:[di].DTI_display		; *ds:si <- OLDisplayWinClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDW_flags, mask OLDWF_TARGET
	pop	si

	mov	di, bp				; di <= GState

	push	ds
	mov	ax, segment idata		; get segment of core blk
	mov	ds, ax
	mov	al, ds:[moCS_activeTitleBar]
	mov	bl, C_WHITE
	jnz	10$
	mov	al, ds:[moCS_inactiveTitleBar]
	mov	bl, C_BLACK
10$:	pop	ds

	clr	ah
	call	GrSetAreaColor

	mov	al, bl
	call	GrSetTextColor

	mov	al, MO_ETCH_COLOR
	call	GrSetLineColor

	mov	bp, ax
	call	OpenCheckIfBW
	jc	20$
	mov	bp, C_WHITE
20$:
	call	VisGetBounds
	dec	cx
	dec	dx

	call	GrFillRect

if (0)	; Put back in if you want title in a box
	call	GrDrawVLine
	call	GrDrawHLine

	push	ax
	mov	ax, bp
	call	GrSetLineColor
	mov	ax, cx
	call	GrDrawVLine
	pop	ax

	push	bx
	mov	bx, dx
	call	GrDrawHLine
	pop	bx
endif

	sub	cx, ax
	sub	cx, 2 * CUAS_TITLE_TEXT_MARGIN
	jns	30$
	clr	cx
30$:	mov_tr	ax, cx
	sub	dx, bx

	push	si, dx
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	si, ds:[si].DTI_display		;*ds:si = OLDisplayWinClass
	mov	bp, di
	call	OpenWinGetMonikerSize
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	mov	bx, ds:[bx].GI_visMoniker	;*ds:bx = visMoniker
	pop	si, dx

	cmp	ax, cx
	mov	cl, mask DMF_CLIP_TO_MAX_WIDTH or \
		    (J_CENTER shl offset DMF_Y_JUST)
	jbe	40$
	ornf	cl, (J_CENTER shl offset DMF_X_JUST)
40$:
	segmov	es, ds
	sub	sp, size DrawMonikerArgs	; make room for args
	mov	bp, sp				; pass pointer in bp
	mov	ss:[bp].DMA_gState, di		; pass gstate
	mov	ss:[bp].DMA_xMaximum, ax	; pass maximum size
	mov	ss:[bp].DMA_yMaximum, dx
	mov	ss:[bp].DMA_xInset, CUAS_TITLE_TEXT_MARGIN
	clr	ss:[bp].DMA_yInset		; no y inset
	call	SpecDrawMoniker
	add	sp, size DrawMonikerArgs	;dump args
	ret

DisplayTitleVisDraw	endm

endif		;--------------------------------------------------------------

MDICommon	ends


MDIAction	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayWinSetOverlapping --
		MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING for OLDisplayWinClass

DESCRIPTION:	Set overlapping mode

PASS:
	*ds:si - instance data
	es - segment of OLDisplayWinClass

	ax - MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING

	dl - VisUpdateMode

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 7/92		Initial version

------------------------------------------------------------------------------@
OLDisplayWinSetOverlapping	method dynamic	OLDisplayWinClass,
				MSG_GEN_DISPLAY_INTERNAL_SET_OVERLAPPING,
				MSG_GEN_DISPLAY_INTERNAL_SET_FULL_SIZED

	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock

	call	OLDisplayWinSendNotification

	ret

OLDisplayWinSetOverlapping	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinReMaximize - MSG_OL_DISPLAY_RE_MAXIMIZE

DESCRIPTION:	This method is used by applications to override a window's
		sizing attributes and update the window.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OLDisplayWinReMaximize	method dynamic	OLDisplayWinClass, \
					MSG_OL_DISPLAY_RE_MAXIMIZE

	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_SIZE_INVALID

	;if window is not visible, abort now. Will update its size when
	;it is re-opened.

	test	ds:[di].VI_attrs, mask VA_VISIBLE
	jz	done

	;now update the window according to new info. IMPORTANT: if this sets
	;visible size = 4000h (DESIRED), it will set geometry invalid
	;so that this is converted into a pixel value before we try to display
	;or convert into a Ratio as window closes...

	call	UpdateWinPosSize	;update window position and size if
					;have enough info. If not, then wait
					;until OpenWinOpenWin to do this.
					;(VisSetSize call will set window
					;invalid)

	mov	dl, VUM_NOW		;get VisUpdateMode
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	call	ObjCallInstanceNoLock
done:
	ret
OLDisplayWinReMaximize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayWinResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize display

CALLED BY:	MSG_OL_DISPLAY_RESIZE
PASS:		*ds:si	= OLDisplayWinClass object
		ds:di	= OLDisplayWinClass instance data
		ds:bx	= OLDisplayWinClass object (same as *ds:si)
		es 	= segment of OLDisplayWinClass
		ax	= message #
		cl	= direction to resize (OLWinMoveResizeState)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

OLDisplayWinResize	method dynamic OLDisplayWinClass, 
					MSG_OL_DISPLAY_RESIZE
	push	cx
	mov	ax, MSG_MO_SYSMENU_SIZE
	call	ObjCallInstanceNoLock
	pop	bx

	call	OLWMRStartResize
	ret
OLDisplayWinResize	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayWinMoveResizeWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify parent (GenDisplayGroup) of move/resize

CALLED BY:	MSG_VIS_MOVE_RESIZE_WIN
PASS:		*ds:si	= OLDisplayWinClass object
		ds:di	= OLDisplayWinClass instance data
		ds:bx	= OLDisplayWinClass object (same as *ds:si)
		es 	= segment of OLDisplayWinClass
		ax	= message #
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

OLDisplayWinMoveResizeWin	method dynamic OLDisplayWinClass, 
					MSG_VIS_MOVE_RESIZE_WIN
	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_FIND_CHILD
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GenCallParent

	mov	ax, MSG_OL_DISPLAY_GROUP_REFIT_DISPLAY
	mov	cx, bp			; cx <= this display
	xor	cl, 1			; refit the other display
	GOTO	GenCallParent

OLDisplayWinMoveResizeWin	endm

endif		;--------------------------------------------------------------

MDIAction ends

;--------------------------

MDICommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinGupQuery -- MSG_SPEC_GUP_QUERY for OLDisplayWinClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLDisplayWinClass

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
		;is below a display window: then this group could become a
		;menu on this object or could be combined into a primary
		;above.  First, see if there is a display control above

	    if (MENUABLE or SEEK_MENU_BAR) and not (AVOID_MENU_BAR) {
		    ;this display is in a DisplayControl, which might
		    ;prefer that menus appear in the menu bar of the GenPrimary.
		    ;If query returns with valid info, this is the case.
		MSG_SPEC_GUP_QUERY(temp, SGQT_BUILD_INFO);
		if visParent != null then {
		    set ABOVE_DISP_CTRL = TRUE
		    return info;
		{
	    } else {
		    ;call OLMenuedWinClass to see if menu or trigger sits in
		    ;menu bar or trigger bar in this Display.
		CallSuper;
	    }
	} else {
		send query to superclass (will send to generic parent)
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@


OLDisplayWinGupQuery	method dynamic	OLDisplayWinClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO		;can we answer this query?
	je	answer				;skip if so...
	jmp	short callSuper			;else let superclass handle

	;we can't answer this query: call super class to handle

callSuperBuildInfo:
	mov	cx, SGQT_BUILD_INFO		;required if looping from below
	and	bp, not mask OLBF_MENU_IN_DISPLAY

callSuper:
	mov	di, offset OLDisplayWinClass
	GOTO	ObjCallSuperNoLock

answer:

	test	bp, mask OLBF_MENUABLE
	jz	callSuperBuildInfo

;In cspecInteraction.asm, we prevent HINT_SYS_MENU and HINT_IS_EXPRESS_MENU
;from using the BUILD_INFO query. So we should not be in this routine!

EC <	mov	di, bp							>
EC <	ANDNF	di, mask OLBF_TARGET					>
EC <	cmp	di, OLBT_SYS_MENU shl offset OLBF_TARGET		>
EC <	ERROR_E OL_ERROR						>
EC <	cmp	di, OLBT_IS_EXPRESS_MENU shl offset OLBF_TARGET		>
EC <	ERROR_E OL_ERROR						>

;CUAS <	;keep sys menu icon in GenDisplay				>
;CUAS <	mov	di, bp							>
;CUAS <	and	di, mask OLBF_TARGET					>
;CUAS <	cmp	di, OLBT_SYS_MENU shl offset OLBF_TARGET		>
;CUAS <	jz	callSuperBuildInfo					>

	;This is a menu within a GenDisplay. If HINT_NEVER_ADOPT_MENUS,
	;then keep these menus here.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDW_flags, mask OLDWF_NEVER_ADOPT_MENUS
	jnz	callSuperBuildInfo	;skip to keep menus here...

	;if this button is permanent, set flag so that OLMenuButtonClass
	;creates button as visible.

	test	ds:[di].OLDW_flags, mask OLDWF_ALWAYS_ADOPT_MENUS
	jz	sendToMenuBar		;skip if button will be enabled
					;when TARGET exclusive changes...
	or	bp, mask OLBF_ALWAYS_ADOPT

sendToMenuBar:
	;send query to GenDisplayGroup, passing flag so that an OLCtrlClass
	;object is created within to menu bar for these flakey-type menu buttons

	or	bp, mask OLBF_MENU_IN_DISPLAY
	call	GenCallParent
	jnc	callSuperBuildInfo	;if no answer...
 	tst	cx			;or if returns null vis parent
	jz	callSuperBuildInfo	;then let our superclass deal with it...

	;return handle of visible parent, with flag indicating that some
	;serious adoption is occuring here

	or	bp, mask OLBF_ABOVE_DISP_CTRL
	stc
	ret

OLDisplayWinGupQuery	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinOpenWin

DESCRIPTION:	Perform MSG_VIS_OPEN_WIN

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
	Eric	12/89		Initial version
------------------------------------------------------------------------------@


OLDisplayWinOpenWin	method dynamic	OLDisplayWinClass, MSG_VIS_OPEN_WIN
	;first call super class

	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock

	;now update our menus which have been adopted by the GenPrimary's
	;menu bar. If HINT_ALWAYS_ADOPT_MENUS, tell them to appear now!

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDW_flags, mask OLDWF_ALWAYS_ADOPT_MENUS
	jnz	done			;skip if not...

	;send notification to all Generic children: if you are a menu, and
	;have a menu button, change the button's visibility status.

	mov	ax, MSG_SHOW_MENU_BUTTON
	call	GenSendToChildren

	;
	; to coordinate with the effort to have the vis children ordering
	; reflect the visual ordering of the GenDisplays under a
	; GenDisplayGroup, move this GenDisplay to the end of the
	; GenDisplayGroup's visible children list (unless OWFA_OPEN_ON_TOP was
	; set), as the default MSG_VIS_OPEN_WIN will place this GenDisplay
	; behind others while placing it at the front of the visible children
	; list.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLWI_fixedAttr, mask OWFA_OPEN_ON_TOP
	jnz	done				; leave at front if on-top
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = this GenDisplay
	mov	dx, si
	mov	ax, MSG_VIS_MOVE_CHILD
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
	call	GenCallParent

done:
	ret
OLDisplayWinOpenWin	endm

MDICommon	ends


MDIAction	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinTogglePushpin -- MSG_OL_POPUP_TOGGLE_PUSHPIN
				for OLDisplayWinClass

DESCRIPTION:	Toggles pushpin on a display.  Since the pushpin on a display
		can only be intialized pushed in, it must be comming out,
		so bring down the display.

PASS:
	*ds:si - instance data
	es - segment of OLDisplayWinClass

	ax - METHOD

	cx, dx	- ?
	bp	- ?

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
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

if _OL_STYLE	;START of OPEN LOOK specific code ------------------------------

PrintMessage <DisplayWin shouldn't support pushpins!>

OLDisplayWinTogglePushpin	method dynamic	OLDisplayWinClass, \
					MSG_OL_POPUP_TOGGLE_PUSHPIN

	;Don't mark as unpinnned - display is never shown as unpinned
	;ALSO - this would be screwed up if app intercepted GEN_CLOSE & didn't
	;follow through & dismiss the window.

					; Toggling the pushpin indicates the
					; user wishes to CLOSE this display,
					; a behavior which the application may
					; wish to intercept & change.
	mov	ax, MSG_GEN_CLOSE_INTERACTION
	GOTO	ObjCallInstanceNoLock
OLDisplayWinTogglePushpin	endp

endif		;END of OPEN LOOK specific code -------------------------------


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinGenCloseInteraction

DESCRIPTION:	This method is invoked when the user wants this window to
		permanently close.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - METHOD
		cx:dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:
		MSG_OL_WIN_CLOSE is handled by OLMenuedWinClass where it
		its transformed into MSG_GEN_DISPLAY_CLOSE.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		Initial version
	brianc	3/3/92		change to MSG_GEN_DISPLAY_CLOSE handler

------------------------------------------------------------------------------@

OLDisplayWinGenCloseInteraction	method dynamic	OLDisplayWinClass, \
					MSG_GEN_DISPLAY_CLOSE

EC <	call	GenCheckGenAssumption	; Make sure gen data exists >

	; if this display is connected to a document, close the document
	; but don't close the display.  If the document is really closed
	; then that will cause the display to close.  If the user cancels
	; the close, we don't want to close the display

	mov	di, ds:[si]		;check if is USER_DISMISSABLE
	add	di, ds:[di].Gen_offset	;ds:di is GenInstance
	test	ds:[di].GDI_attributes, mask GDA_USER_DISMISSABLE
	jz	done
	mov	bx, ds:[di].GDI_document.handle
	tst	bx
	jz	noDocument
	mov	si, ds:[di].GDI_document.chunk
	clr	bp			;user initiated
	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

noDocument:

	; otherwise, subclass must handle

done:
	ret
OLDisplayWinGenCloseInteraction	endm

MDIAction	ends


MDICommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinSpecSetUsable

DESCRIPTION:	Intercept MSG_SPEC_SET_USABLE.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - MSG_SPEC_SET_USABLE
		dl	- VisUpdateMode

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@

OLDisplayWinSpecSetUsable	method dynamic	OLDisplayWinClass, \
						MSG_SPEC_SET_USABLE

	; usable means visible for GenDisplays, so an active list entry will
	; get added when it becomes visible (OpenWinOpenWin), though not if we
	; are minimized, so... we'll just add ourselves here

;
; this is now done in the generic UI as we want it to work for displays that
; are not fully usable - brianc 1/25/93
;
if 0
	push	ax, dx
	call	OpenWinEnsureOnWindowList
	pop	ax, dx
endif

	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock

	call	OLDisplayWinSendCompleteNotification

	ret

OLDisplayWinSpecSetUsable	endm

MDICommon	ends


MDIAction	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinSpecSetNotUsable -- MSG_SPEC_SET_NOT_USABLE

DESCRIPTION:	This method is invoked when the user wants this window to
		permanently close.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - METHOD
		cx:dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		Initial version

------------------------------------------------------------------------------@

OLDisplayWinSpecSetNotUsable	method dynamic	OLDisplayWinClass,
						MSG_SPEC_SET_NOT_USABLE

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock

	;force display control to ensure that top object is given the
	;focus & target.

	mov	ax, MSG_OL_DISPLAY_GROUP_BRING_FIRST_DISPLAY_TO_TOP
	call	GenCallParent

	;
	; send to target display -- if MSG_SPEC_SET_NOT_USABLE is sent to
	; a non-target display (e.g. GeoManager's LRU displays), the
	; MSG_OL_DISPLAY_GROUP_BRING_FIRST_DISPLAY_TO_TOP does nothing, causing
	; a simple call to OLDisplayWinSendCompleteNotification here to fail to
	; update the window list correctly.  Send with MF_INSERT_AT_FRONT to
	; allow this display (the one being set not usable to actually remove
	; itself from the display group before the notification is generated)
	; - brianc 4/9/93
	;
	; Hmm...need to do both as the simple
	; OLDisplayWinSendCompleteNotification call handles the case of
	; the last window being set not usable - brianc 4/20/93
	; (comment out "if 0", "else", and "endif")
	;
;if 0
	call	OLDisplayWinSendCompleteNotification
;else
	push	si
	mov	bx, segment OLDisplayWinClass
	mov	si, offset OLDisplayWinClass
	mov	ax, MSG_OL_DISPLAY_SEND_NOTIFICATION
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si
	push	si
	call	GenFindParent			; ^lbx:si = display group
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, di				; cx = event
	mov	dx, TO_TARGET
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	pop	si
;endif

	pop	di
	call	ThreadReturnStackSpace
	ret
OLDisplayWinSpecSetNotUsable	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinSetMinimized

DESCRIPTION:	We intercept this method here to translate it into
		making the display not visible (but keeping its entry
		in MDI Window menu).

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version
	brianc	3/5/92		updated to MSG_GEN_DISPLAY_SET_MINIMIZED

------------------------------------------------------------------------------@

;NOTE: the icon should be updated so it sends a different method!

OLDisplayWinSetMinimized	method dynamic	OLDisplayWinClass, \
						MSG_GEN_DISPLAY_SET_MINIMIZED

	test	ds:[di].OLWI_attrs, mask OWA_MINIMIZABLE
	jz	done			; not minimizable, do nothing
	test	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED
	jnz	done			; already minimized

	; Get the display window itself off screen
	;
	call	OLDisplayMinimizeCommon
done:
	ret
OLDisplayWinSetMinimized	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			OLDisplayMinimizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to take care of common "knock display off
		screen" code.

CALLED BY:	INTERNAL
		OLDisplayWinSetMinimized
		OLDisplayDestroyAndFreeBlock
PASS:		*ds:si	- display
RETURN:		nothing
ALLOWED TO DESTROY:
		ax, bx, cx, dx, bp, es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLDisplayMinimizeCommon	proc	near
; Not sure where this should be - to be fixed w/travelling objects in general
;	call	RemoveTravelingObjectsFromThisDisplay

	;Make THIS object non-realizable and branch minimized.  This will cause
	;the GAGCNLT_WINDOWS list to be processed, removing any windowed
	;children of the GenDisplay.

	ornf	ds:[di].OLWI_specState, mask OLWSS_MINIMIZED

	mov	cl, mask SA_BRANCH_MINIMIZED
	mov	ch, mask SA_REALIZABLE
	mov	dl, VUM_NOW		; update now
	mov	ax, MSG_SPEC_SET_ATTRS
	call	ObjCallInstanceNoLock

	;Force display control to ensure that top object is given the
	;focus & target.

	mov	ax,MSG_OL_DISPLAY_GROUP_BRING_FIRST_DISPLAY_TO_TOP
	call	GenCallParent

	;
	; Free up this display's slot in the display control.
	;
	call	OpenWinFreeStaggeredSlot
	ret
OLDisplayMinimizeCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayDestroyAndFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle specific-UI part of this -- take off screen, make
		sure no FTVMC, gadget, etc. exclusives, no app GCN etc.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_DESTROY_AND_FREE_BLOCK

RETURN:		carry set, to use optimized approach

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLDisplayDestroyAndFreeBlock	method dynamic	OLDisplayWinClass, \
				MSG_GEN_DESTROY_AND_FREE_BLOCK
if _JEDIMOTIF
	;
	; Arrgh...for JEDI we can't optimize as we could have a view under
	; us whose scrollbars seek the primary title bar -- we need the
	; normal build to remove those suckers
	;
	clc
else
	call	OLDisplayMinimizeCommon
	;
	; remove downward link so that display control will deal with
	; notification correctly
	;
	clr	bp
	call	GenRemoveDownwardLink

	call	OLDisplayWinSendCompleteNotification	; Fix "Windows" menu
							; list so we're not
							; on it.

	; Tell new target display to send notification, so it will be
	; correctly selected on the display list

	push	si
	mov	ax, MSG_OL_DISPLAY_SEND_NOTIFICATION
	mov	bx, es
	mov	si, offset OLDisplayWinClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di
	pop	si
	push	si
	call	GenFindParent			; ^lbx:si = DisplayControl
	mov	dx, TO_TARGET
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	si

	; Get us off any active lists we think we might still be on.
	; Remember that no objects within the block are on an active list,
	; or this routine wouldn't have been called in the first place.
	; We're also off-screen, meaning nothing is visible, has the focus,
	; target, or mouse grab.

	mov	ax, GAGCNLT_WINDOWS
	call	TakeObjectsInBlockOffList

        mov	ax, GAGCNLT_CONTROLLED_GEN_VIEW_OBJECTS
	call	TakeObjectsInBlockOffList

	stc				; yes, we're optimizing.
endif
done::
	ret
OLDisplayDestroyAndFreeBlock	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinNextWindow

DESCRIPTION:	Cycle to next window, if any.

PASS:		*ds:si - instance data
		es - segment of OLWinClass

		ax - MSG_MO_NEXT_WIN
		cx:dx	- ?
		bp	- ?

RETURN:		carry - ?
		ax, cx, dx, bp - ?

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/5/92		Initial version

------------------------------------------------------------------------------@

OLDisplayWinNextWindow	method dynamic	OLDisplayWinClass, \
					MSG_MO_NEXT_WIN

	;lower ourselves to the bottom

	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	call	ObjCallInstanceNoLock

	;force display control to ensure that top object is given the
	;focus & target.

	mov	ax, MSG_OL_DISPLAY_GROUP_BRING_FIRST_DISPLAY_TO_TOP
	call	GenCallParent

	ret
OLDisplayWinNextWindow	endm

MDIAction ends

;--------------------------

MDICommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLDisplayWinGetTargetAtTargetLevel

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of OLDisplayClass

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


OLDisplayWinGetTargetAtTargetLevel	method dynamic	OLDisplayWinClass, \
					MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	ax, TL_GEN_DISPLAY
	mov	bx, Vis_offset
	mov	di, offset OLWI_targetExcl
	call	FlowGetTargetAtTargetLevel
	ret
OLDisplayWinGetTargetAtTargetLevel	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinUpdPriFocusState

DESCRIPTION:	This procedure forwards the given METHOD on to the GenPrimary.
		This is important when these MDI windows are inside the
		DisplayControl -- we have to keep the Primary up-to-date
		on our target status.

CALLED BY:	MSG_META_GAINED_TARGET_EXCL
		MSG_META_LOST_TARGET_EXCL

PASS:		ds:*si	- instance data

RETURN:

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version
	Doug	10/90		Removed handling of GAINED/LOST_FOCUS,
				as shouldn't affect Windows menu.

------------------------------------------------------------------------------@

OLDisplayWinUpdPriFocusState	method dynamic	OLDisplayWinClass, \
					MSG_META_GAINED_TARGET_EXCL, \
					MSG_META_LOST_TARGET_EXCL

	andnf	ds:[di].OLDW_flags, not (mask OLDWF_TARGET or \
				 mask OLDWF_NEED_TO_GRAB_MODEL_FOR_DOCUMENT)
					;assume lost target

	push	ax, cx, dx, bp		;save method and data

if _NIKE
	push	si
	mov	si, ds:[di].OLDW_titleObject
	tst	si
	jz	notitle
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid
notitle:
	pop	si
endif

	; if gaining target, update document

	clr	bx
	cmp	ax, MSG_META_GAINED_TARGET_EXCL
	jnz	notGained

	ornf	ds:[di].OLDW_flags, mask OLDWF_TARGET	;gained target

	; Move any traveling objects to this display
	call	MoveTravelingObjectsToThisDisplay

	call	OLDisplayGrabModelForDocument

	mov	bx, 1

notGained:
	push	ax
	call	OLDisplayWinSendNotification
	pop	ax

;------------------------------------------------------------------------------
	;now update our menus which have been adopted by the GenPrimary's
	;menu bar. If HINT_NEVER_ADOPT_MENUS or HINT_ALWAYS_ADOPT_MENUS, do not
	;change their status!

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDW_flags, mask OLDWF_NEVER_ADOPT_MENUS \
				 or mask OLDWF_ALWAYS_ADOPT_MENUS
	jnz	callSuper		;skip to ignore menus...

	;this Display's menu buttons (which have been adopted) appear
	;and disappear according to 

;FUTURE: need a state flag here, because can get the Target several times.

	cmp	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bp, MSG_SHOW_MENU_BUTTON
	je	notifyMenus		;skip if gained target exclusive

	cmp	ax, MSG_META_LOST_TARGET_EXCL
	jne	callSuper

	;lost target exclusive

	mov	bp, MSG_HIDE_MENU_BUTTON

notifyMenus:
	;send notification to all Generic children: if you are a menu, and
	;have a menu button, change the button's visibility status.

	mov	ax, bp				; ax = method for children
	call	GenSendToChildren

;------------------------------------------------------------------------------
callSuper:
	;now call superclass to handle TARGET status change
	;(NOT NECESSARY to call OpenWinAttemptNotifyDispCtrl, because OLWinClass
	;handler will do so if this is a TARGET exclusive change.)

	pop	ax, cx, dx, bp		;get method and data
	mov	di, offset OLDisplayWinClass
	GOTO	ObjCallSuperNoLock


OLDisplayWinUpdPriFocusState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplayGrabModelForDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab model for document

CALLED BY:	OLDisplayWinUpdPriFocusState, 
PASS:		*ds:si	= OLDisplayClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDisplayGrabModelForDocument	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GDI_document

	tstdw	bxsi
	jnz	grabModel		;grab model for document

	ornf	ds:[bp].OLDW_flags, mask OLDWF_NEED_TO_GRAB_MODEL_FOR_DOCUMENT
	jmp	done			;no document,
					;grab model for document later
grabModel:
	andnf	ds:[bp].OLDW_flags, \
				not mask OLDWF_NEED_TO_GRAB_MODEL_FOR_DOCUMENT
	movdw	cxdx, bxsi
	mov	bp, mask MAEF_GRAB or mask MAEF_MODEL or mask MAEF_NOT_HERE
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave
	ret
OLDisplayGrabModelForDocument	endp



COMMENT @----------------------------------------------------------------------
FUNCTION:	MoveTravelingObjectsToThisDisplay

DESCRIPTION:	Checks to see if this display has traveling objects set up
		for it.   If so, moves them all to this display.

CALLED BY:	INTERNAL

PASS:		*ds:si	- GenDisplay object
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@
MoveTravelingObjectsToThisDisplay	proc	far
	push	bp
	mov	bp, -1			; Move objects TO this display
	call	TravelingObjectsCommon
	pop	bp
	ret
MoveTravelingObjectsToThisDisplay	endp

TravelingObjectsCommon	proc	far	uses	ax, bx, cx, dx, si, di
	.enter
EC <	call	SysGetECLevel						>
EC <	push	ax, bx							>
EC <	mov	ax, (mask ErrorCheckingFlags) and (not (mask ECF_BLOCK_CHECKSUM or mask ECF_SEGMENT or mask ECF_UNLOCK_MOVE))>
if	(1)
EC <	call	SysSetECLevel						>
endif

EC <	call	ECCheckLMemObject					>
	mov	ax, ATTR_GEN_DISPLAY_TRAVELING_OBJECTS
	call	ObjVarFindData
	LONG jnc	done
	mov	bx, ds:[bx]		; fetch chunk of Traveling objects
	mov	di, ds:[bx]
	ChunkSizePtr	ds, di, ax	; get size of chunk
	mov	cl, size TravelingObjectReference
	div	cl			; figure out how many objects to do
	tst	al
	LONG	jz	done
	clr	ah
	mov	cx, ax
	clr	di			; start at first
moveObjectLoop:
	push	bx, cx, di, bp

	mov	bx, ds:[bx]		; deref
	add	di, bx		; ds:di is ptr to TravelingObjectReference

	mov	bx, ds:[LMBH_handle]
	mov	cx, ds:[di].TIR_travelingObject.handle
	mov	al, RELOC_HANDLE
	call	ObjDoRelocation
	mov	bx, cx
	mov	si, ds:[di].TIR_travelingObject.chunk

	mov	cx, ds:[LMBH_handle]		; get new parent
	mov	dx, ds:[di].TIR_parent
	mov	ax, ds:[di].TIR_compChildFlags	; & CompChildFlags

	call	ObjSwapLock
EC <	call	ECCheckLMemObject					>

	push	bx, si
	call	GenFindParent
	cmp	bx, cx
	jne	10$
	cmp	si, dx
10$:
	pop	bx, si
	je	alreadyOnParent
;notOnParent:
	tst	bp				; see if moving here...
	jnz	continue			; if so, keep going
	jmp	short unlockNext		; if nuking, we're OK -- next!

alreadyOnParent:
	tst	bp				; see if moving here...
	jnz	unlockNext			; if so, we're done -- next!
	; otherwise, we need to remove... continue.
continue:
	push	bp				; save operation flag
	push	dx				; save new parent
	mov	bp, ax				; CompChildFlags
	call	RemoveObject
	call	ObjSwapUnlock
	pop	si				; get new parent
	pop	ax				; get operation flag
	tst	ax				; see if adding
	jz	next				; if not, done -- next!
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
next:
	pop	bx, cx, di, bp
	add	di, size TravelingObjectReference
	loop	moveObjectLoop
done:
EC <	pop	ax, bx							>
EC <	call	SysSetECLevel			; restore EC level	>
	.leave
	ret

unlockNext:
	call	ObjSwapUnlock
	jmp	short next

TravelingObjectsCommon	endp

;---

RemoveObject	proc	near
	push	bp				; save CompChildFlags
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	mov	cx, ds:[LMBH_handle]		; get self in cx:dx
	mov	dx, si
	pop	bp				; get CompChildFlags
	push	bp				; save again
	and	bp, mask CCF_MARK_DIRTY		; only flag valid on remove
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	GenCallParent			; remove from tree
	pop	bp				; get CompChildFlags
	ret
RemoveObject	endp

MDICommon	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayFupKbdChar - MSG_META_FUP_KBD_CHAR handler

DESCRIPTION:	This method is sent by child which 1) is the focused object
		and 2) has received a MSG_META_FUP_KBD_CHAR
		which is does not care about. Since we also don't care
		about the character, we forward this method up to the
		parent in the focus hierarchy.

		At this class level, the parent in the focus hierarchy is
		is the generic parent.

PASS:		*ds:si	= instance data for object
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
	chris	7/90		initial version

------------------------------------------------------------------------------@

OLDisplayFupKbdChar	method dynamic	OLDisplayWinClass, \
						MSG_META_FUP_KBD_CHAR

if _KBD_NAVIGATION and _USE_KBD_ACCELERATORS
   
   	push	ax			;save method
	
	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper		;ignore character...

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		;skip if not press event...

					;set es:di = table of shortcuts
					;and matching methods
	push	es			;save class segment
	segmov	es, cs
	mov	di, offset cs:OLDisplayKbdBindings
	call	ConvertKeyToMethod	
	pop	es			;restore class segment
	jnc	callSuper		;skip if not found...

	;found an escape: send method to self, after a slight delay to let
	;cancel buttons invert, etc.

	pop	bx			;throw away method on stack
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	
	;call a utility routine to send a method to the Flow object that
	;will force the dismissal of all menus in stay-up-mode.

	call	OLReleaseAllStayUpModeMenus
	stc				;say handled
	ret
	
callSuper:
	pop	ax			;restore method
	
endif	;----------------------------------------------------------------------
	
	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock
exit:
	ret
OLDisplayFupKbdChar	endm
			
if _KBD_NAVIGATION and _USE_KBD_ACCELERATORS

;Keyboard shortcut bindings for OLDisplayWinClass (do not separate tables)

OLDisplayKbdBindings	label	word
	word	length OLDKShortcutList
	
if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLDKShortcutList KeyboardShortcut \
	 <1, 0, 1, 0, C_SYS_F4 and mask KS_CHAR>,	;close shortcut
	 <1, 0, 1, 0, C_SYS_F6 and mask KS_CHAR>	;next window shortcut

else
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLDKShortcutList	KeyboardShortcut \
		 <1, 0, 1, 0, 0xf, VC_F4>,	;close shortcut
		 <1, 0, 1, 0, 0xf, VC_F6>	;next window shortcut
endif
		 
;OLNMethodList	label word
	word	MSG_GEN_DISPLAY_CLOSE
	word	MSG_MO_NEXT_WIN

endif	;----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDisplaySpecActivateObjectWithMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	turn off pending menu navigation if mnemonic match

CALLED BY:	MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC

PASS:		*ds:si	= OLDisplayWinClass object
		ds:di	= OLDisplayWinClass instance data
		es 	= segment of OLDisplayWinClass
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
		This is needed as code menu toggling isn't allowed at the
		OLDisplay level, so Alt ends up toggling at the OLBaseWin
		level.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/8/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDisplaySpecActivateObjectWithMnemonic	method	dynamic	OLDisplayWinClass, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	;
	; let superclass handle
	;
	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock		; carry set if handled
	jnc	done
	;
	; if handled, we must turn off OLWMS_TOGGLE_MENU_NAV_PENDING at
	; OLBaseWin
	;
	call	OpenClearToggleMenuNavPending
	stc					; indicate handled
done:
	Destroy	ax, cx, dx, bp
	ret
OLDisplaySpecActivateObjectWithMnemonic	endm

KbdNavigation	ends


MDICommon	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayUpdateFromDocument --
		MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT for OLDisplayWinClass

DESCRIPTION:	Update the GenDisplay based on attributes of the associated
		GenDocument

PASS:
	*ds:si - instance data
	es - segment of OLDisplayWinClass

	ax - The message

	ss:bp - DocumentFileChangedParams

RETURN:
	bp - unchanged
	ax, cx, dx - destroyed

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/31/91		Initial version

------------------------------------------------------------------------------@
OLDisplayUpdateFromDocument	method dynamic	OLDisplayWinClass,
				MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT

	add	bx, ds:[bx].Gen_offset		;ds:bx = gen stuff

	; save document optr

	movdw	ds:[bx].GDI_document, ss:[bp].DFCP_document, ax

	; grab model for document is necessary

	test	ds:[di].OLDW_flags, mask OLDWF_NEED_TO_GRAB_MODEL_FOR_DOCUMENT
	jz	afterModelGrab

	call	OLDisplayGrabModelForDocument
afterModelGrab:

	; If the moniker has not changed then do not set it.  In addition
	; to being an optimization, this fixes a bug in the Window menu.

	mov	bx, ds:[bx].GI_visMoniker
	tst	bx
	jz	setMoniker
	push	si
	mov	si, ds:[bx]			;ds:si = moniker
	add	si, (size VisMoniker) + (size VisMonikerText)	;ds:si = text
	segmov	es, ss
	lea	di, ss:[bp].DFCP_name		;es:di = text passed
cmpLoop:
SBCS <	lodsb								>
DBCS <	lodsw								>
SBCS <	scasb								>
DBCS <	scasw								>
	jnz	cmpDone
SBCS <	tst	al							>
DBCS <	tst	ax							>
	jnz	cmpLoop
cmpDone:
	pop	si
	jz	done				;if strings are the same then
						;there is no need to set the
						;moniker

	; set moniker

setMoniker:
	push	bp
	mov	cx, ss
	lea	dx, ss:[bp].DFCP_name
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
 	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	call	ObjCallInstanceNoLock		;call ourself -- returns
						;ax = new chunk
	pop	bp
done:
	Destroy	ax, cx, dx
	ret

OLDisplayUpdateFromDocument	endm

MDICommon	ends


InstanceObscure	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDisplayWinGetDocument -- MSG_GEN_DISPLAY_GET_DOCUMENT
		for OLDisplayWinClass

DESCRIPTION:	Get the associated document

PASS:
	*ds:si - instance data
	es - segment of OLDisplayWinClass

	ax - The message

RETURN:
	cx:dx - document

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/28/91		Initial version

------------------------------------------------------------------------------@
OLDisplayWinGetDocument	method dynamic	OLDisplayWinClass,
					MSG_GEN_DISPLAY_GET_DOCUMENT

	add	bx, ds:[bx].Gen_offset		;ds:bx = gen stuff
	movdw	cxdx, ds:[bx].GDI_document
	ret

OLDisplayWinGetDocument	endm

InstanceObscure	ends


MDICommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinBringToTop

DESCRIPTION:	OLDisplayWin brought to top, adjust ordering within
		GenDisplayGroup parent.

PASS:	*ds:si	= instance data for object
	es - segment of OLDisplayWinClass

	ax - MSG_GEN_BRING_TO_TOP

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/92		initial version

------------------------------------------------------------------------------@

OLDisplayWinBringToTop	method	OLDisplayWinClass, MSG_GEN_BRING_TO_TOP

	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock
	;
	; Move within children list of of parent GenDisplayGroup, if we are
	; a visible child (may not be if we are doing this when primary
	; containing display group is minimized).
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_FIND_CHILD
	call	GenCallParent			; carry set if not found
	jc	done
	tst	bp				; already first child?
	jz	done				; yes
	mov	ax, MSG_VIS_MOVE_CHILD
	mov	bp, CCO_FIRST or mask CCF_MARK_DIRTY
	call	GenCallParent
done:
	ret
OLDisplayWinBringToTop	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDisplayWinLowerToBottom

DESCRIPTION:	OLDisplayWin lowered to bottom, adjust ordering within
		GenDisplayGroup parent.

PASS:	*ds:si	= instance data for object
	es - segment of OLDisplayWinClass

	ax - MSG_GEN_LOWER_TO_BOTTOM

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/92		initial version

------------------------------------------------------------------------------@

OLDisplayWinLowerToBottom	method	OLDisplayWinClass,
						MSG_GEN_LOWER_TO_BOTTOM
	mov	di, offset OLDisplayWinClass
	call	ObjCallSuperNoLock

	;
	; Move within children list of of parent GenDisplayGroup, if we are
	; a visible child (may not be if we are doing this when primary
	; containing display group is minimized).
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_FIND_CHILD
	call	GenCallParent			; carry set if not found
	jc	done
	mov	ax, MSG_VIS_MOVE_CHILD
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
	call	GenCallParent
done:
	ret
OLDisplayWinLowerToBottom	endm

MDICommon	ends

WinClasses	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TakeObjectsInBlockOffList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes all objects located in current block off the indicated
		GCN list of the application.

CALLED BY:	INTERNAL
		OLDisplayDestroyAndFreeBlock
PASS:		*ds:si	- object
		ax	- GCNListType
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TakeObjectsInBlockOffList	proc	far
        mov     dx, size GCNListParams
        sub     sp, dx
        mov     bp, sp
        mov     bx, ds:[LMBH_handle]
        mov     ss:[bp].GCNLP_optr.handle, bx
	clr	bx
        mov     ss:[bp].GCNLP_optr.chunk, bx
        mov     ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
        mov     ss:[bp].GCNLP_ID.GCNLT_type, ax
        mov     ax, MSG_META_GCN_LIST_REMOVE
        call    OpenCallApplicationWithStack
        add     sp, size GCNListParams
	ret
TakeObjectsInBlockOffList	endp

WinClasses	ends
