COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1996.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		copenCtrlGeometry.asm

ROUTINES:
	Name			Description
	----			-----------
    INT GetChildExtraSize       Callback routine for VisDrawMoniker.

    MTD MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN 
				Resets a visual tree's geometry to help
				keep the win group onscreen.

    MTD MSG_SPEC_VIS_OPEN_NOTIFY 
				Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    MTD MSG_SPEC_VIS_CLOSE_NOTIFY 
				Handle notification that an object with
				GA_NOTIFY_VISIBILITY has been opened

    INT OpenCtrlCheckCustomSpacing 
				Checks for OLCOF_CUSTOM_SPACING, and uses
				data in HINT_CUSTOM_ CHILD_SPACING if set.
				Also sets certain spacing for toolbox
				controls.  Also deals with CGA.

    INT OpenCtrlCheckCGASpacing Checks for OLCOF_CUSTOM_SPACING, and uses
				data in HINT_CUSTOM_ CHILD_SPACING if set.
				Also sets certain spacing for toolbox
				controls.  Also deals with CGA.

    INT CustomChildSpacingMinSpace 
				Checks for OLCOF_CUSTOM_SPACING, and uses
				data in HINT_CUSTOM_ CHILD_SPACING if set.
				Also sets certain spacing for toolbox
				controls.  Also deals with CGA.

    INT CustomChildSpacing      Checks for OLCOF_CUSTOM_SPACING, and uses
				data in HINT_CUSTOM_ CHILD_SPACING if set.
				Also sets certain spacing for toolbox
				controls.  Also deals with CGA.

    INT MinimizeChildSpacing    Checks for OLCOF_CUSTOM_SPACING, and uses
				data in HINT_CUSTOM_ CHILD_SPACING if set.
				Also sets certain spacing for toolbox
				controls.  Also deals with CGA.

    MTD MSG_VIS_COMP_GET_MARGINS 
				Returns margins for the object.

    INT CalcCtrlMargins         Calculates margins for an OLCtrl.

    INT DoReplyBarMargins       Does reply bar margins, if needed.

    INT CheckIfNeedsExtraMargins 
				Checks to see if we need extra margins for
				our OLCtrl. Sometimes if our parent is an
				OLGadgetArea, it may not have been able to
				provide the required margins itself due to
				a DisplayControl being around.

    INT OpenRecalcCtrlSize      Does normal OLCtrl class stuff for
				MSG_VIS_RECALC_SIZE.

    INT CalcCentersIfCenteringByMonikers 
				Calculates the largest moniker below us if
				we're centering that way.

    INT AddFullBoundsToUpdateRegion 
				Adds our full bounds to the update region,
				to absolutely ensure everything is redrawn,
				since apparently moniker widths are
				changing, and the update mechanism deals
				poorly with changing margins in
				ONLY_DRAWS_IN_MARGINS composites.

    MTD MSG_SPEC_CTRL_GET_LARGEST_CENTER 
				Gets the moniker space for all the objects
				under the head object with
				HINT_CENTER_CHILDREN_ON_MONIKERS.

    INT SetExpandHeightInHorizToolbox 
				Expands height if we're the child of a
				horizontal toolbox. Actually, sets or
				clears the expand flag depending on whether
				there are children involved.

    INT OpenCtrlCalcMonikerOffsets 
				Sets moniker offsets for the OLCtrl, if
				needed.

    INT PassSpacingArgsIfWeCan  Sets up spacing and margin arguments if
				they fit in a word.

    INT SubtractReservedMonikerSpace 
				Subtracts space that must be left clear for
				sibling monikers. If we're centering, and
				some of the another sibling has a larger
				left-of-center value than we do, and we're
				expanding to fit, or we have children that
				like to expand to fit us (like a text
				object), we're probably going to run into
				trouble because we'll try to fill up the
				entire width passed to us, which isn't
				really available; only what we have for
				left-of-center plus any space available
				right-of-center is there for us to expand
				to.  If we don't do this routine, the
				parent grows and grows until an eventual
				fatal error.

				(I'm deeming this a hack now.  This only
				helps expand-to-fit composites in a
				center-by-monikers parent.  There must be a
				general case where you only give the child
				a size equal to... I don't know.  The
				problem only happens when the child is
				expanding to fit but keeping the amount of
				space left or right of center fixed.)

    INT CalcExtraSize           Calculates extra size of control.

    MTD MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE 
				Returns typical extra size for a child of
				this object.

    INT CallFirstValidChild     Calls first child that has valid geometry.

    INT ReturnWrapCount         Returns a wrap count for this control.

    MTD MSG_SPEC_GET_MENU_CENTER 
				Returns center of menu, ultimately.

    MTD MSG_VIS_POSITION_BRANCH Positions children.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenCtrl.asm

DESCRIPTION:

	$Id: copenCtrlGeometry.asm,v 1.2 98/03/11 05:49:03 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeometryObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLCtrlClass

DESCRIPTION:	Returns extra (non-moniker) size of the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE
		bp      - number of children to get extra size for

RETURN:		cx  - extra width
		dx  - extra height
		bp  - number of children unaccounted for

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		call MSG_GET_SPACING
		extraLength = leftMargin + rightMargin - childSpacing
		extraWidth = 0
		numChildren = 0
       		while unaccountedChildren
			retLength = -CHILD_SPACING
			call MSG_SPEC_GET_EXTRA_SIZE
				returns childWidth, childHeight
			SwapIfVertical (cx <- comp length, dx <- comp width)
			if childWidth > retWidth
				width = childWidth
			retLength = retLength + childLength + childSpacing
			unaccountedChildren--
		retWidth = retWidth + topMargin + bottomMargin

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 6/89		Initial version

------------------------------------------------------------------------------@

OLCtrlGetExtraSize	method OLCtrlClass, MSG_SPEC_GET_EXTRA_SIZE
	push	bp	
	call	GetNonMonikerMarginTotals	;cx, dx margin length and width
	pop	bp				; ax <- child spacing
	
	push	dx				;save top/bottom margins
	clr	dx				;initialize return width
	
	tst	bp				;any children at all?
	jz	afterChildren			;nope, branch
	
	sub	cx, ax				;subtract childSpacing from
						;    retLength

	clr	bx				;initial child (first
	push	bx				;	child of
	push	bx				;	composite)
	mov	bx,offset VI_link		
	push	bx				;pass offset to LinkPart
	mov	bx, SEGMENT_CS						    
	push	bx				; pass callback routine (seg)
	mov	bx,offset GetChildExtraSize
	push	bx				;pass callback routine (off)

	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren

afterChildren:
	pop	ax				;restore top/bottom margins
	add	dx, ax				;add them to retWidth
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	exit				;not vertical, exit
	xchg	cx, dx				;else make into width & height
	
exit:
	ret
OLCtrlGetExtraSize	endm
			


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetChildExtraSize

SYNOPSIS:	Callback routine for VisDrawMoniker.

CALLED BY:	OLCtrlGetExtraSize 
		(as callback routine from ObjCompProcessChildren)

PASS:		*ds:si - handle of child
		*es:di - handle of composite
		ax - child spacing
		cx - return length (in direction of children)
		dx - return width
		bp - number of children unaccounted for

RETURN:		cx, dx, bp updated appropriately

DESTROYED:	bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 6/89		Initial version

------------------------------------------------------------------------------@

GetChildExtraSize	proc	far
	class	OLCtrlClass
	
	push	bp				;save count
	push	ax				;also save child spacing
	add	cx, ax				;add child spacing to retLength
	push	cx				;save retLength
	mov	bx, dx				;keep retWidth in bx
	mov	ax, MSG_SPEC_GET_EXTRA_SIZE	;get child's extra size
	call	ObjCallInstanceNoLockES
	pop	ax				;restore retLength into ax
	mov	di, es:[di]			;point to instance
	add	di, es:[di].Vis_offset		;ds:[di] -- VisInstance
	test	es:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	addChildSize			;not vertical, branch
	xchg	cx, dx				;else orient child with parent
	
addChildSize:
	cmp	bx, dx				;compare retWidth to child width
	jae	addLength			;small child, skip
	mov	bx, dx				;else store a new retWidth
	
addLength:
	add	ax, cx				;add child length to retLength
	mov	cx, ax				;return length back in cx
	mov	dx, bx				;return width back in dx

	pop	ax				;restore child spacing	
	pop	bp				;and number of children
	dec	bp				;another child accounted for
	cmp	bp, 1				;sets carry flag if bp = 0
	ret
GetChildExtraSize	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlResetSizeToStayOnscreen -- 
		MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN for OLCtrlClass

DESCRIPTION:	Resets a visual tree's geometry to help keep the win group
		onscreen.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN
		dl 	- VisUpdateMode

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
	chris	2/ 4/93		Initial Version

------------------------------------------------------------------------------@

OLCtrlResetSizeToStayOnscreen	method dynamic	OLCtrlClass, \
				MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN

	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jz	callSuper			;not in menu, nothing to be done
	
	push	ax
	mov	ax, HINT_ALLOW_CHILDREN_TO_WRAP
	call	ObjVarFindData
	pop	ax
	jnc	callSuper			;no wrapping hint, branch

	mov	di, ds:[si]			;else set the attribute (not set
	add	di, ds:[di].Vis_offset		;  on startup in menus)
	or	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ONE_PASS_OPTIMIZATION

callSuper:
	mov	di, offset OLCtrlClass
	GOTO	ObjCallSuperNoLock
OLCtrlResetSizeToStayOnscreen	endm


GeometryObscure	ends
Geometry segment resource


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLCtrlSpecVisOpenNotify -- MSG_SPEC_VIS_OPEN_NOTIFY
							for OLCtrlClass

DESCRIPTION:	Handle notification that an object with GA_NOTIFY_VISIBILITY
		has been opened

PASS:
	*ds:si - instance data
	es - segment of OLCtrlClass

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
OLCtrlSpecVisOpenNotify	method dynamic	OLCtrlClass,
						MSG_SPEC_VIS_OPEN_NOTIFY
	call	VisOpenNotifyCommon
	ret

OLCtrlSpecVisOpenNotify	endm

;---

OLCtrlSpecVisCloseNotify	method dynamic	OLCtrlClass,
						MSG_SPEC_VIS_CLOSE_NOTIFY
	call	VisCloseNotifyCommon
	ret

OLCtrlSpecVisCloseNotify	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetSpacing -- MSG_VIS_COMP_GET_CHILD_SPACING for OLCtrlClass

DESCRIPTION:	Returns spacing for the object.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_GET_SPACING

RETURN:		cx -- spacing between children
        	dx -- spacing between wrapped lines of children
		ax, bp destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This will become better soon.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@
OLCtrlGetSpacing	method OLCtrlClass, MSG_VIS_COMP_GET_CHILD_SPACING
	;
	; Add stuff to margins here if a child of a base window.
	;
	mov	cx, OL_CONTROL_SPACING
	mov	dx, OL_CONTROL_WRAP_SPACING
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	jz	checkCustomSpacing
	mov	cx, MENU_SPACING
	mov	dx, cx
	
checkCustomSpacing:
	;
	;  Title-groups have OLBF_TOOLBOX set on them, so before
	;  checking if we're a toolbox, check if we're a title group.
	;
	test	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_RIGHT shl \
				offset OLBF_TARGET
	jnz	notToolbox
	test	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_LEFT shl \
				offset OLBF_TARGET
	jnz	notToolbox

	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	notToolbox
	mov	cx, TOOLBOX_SPACING			;smaller toolbox spacing
	mov	dx, TOOLBOX_WRAP_SPACING		;no wrap spacing!
	call	OpenCheckIfLimitedLength
	jnc	notToolbox
	dec	cx
notToolbox:

	call	OpenCtrlCheckCGASpacing		;use CGA spacing if needed
	call	OpenCtrlCheckCustomSpacing	;use custom spacing if there.
	ret
OLCtrlGetSpacing	endm
			
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCtrlCheckCustomSpacing

SYNOPSIS:	Checks for OLCOF_CUSTOM_SPACING, and uses data in HINT_CUSTOM_
		CHILD_SPACING if set.  Also sets certain spacing for toolbox
		controls.  Also deals with CGA.

CALLED BY:	OLCtrlGetSpacing, OpenWinGetSpacing

PASS:		*ds:si -- object to check hints
		cx, dx -- spacing, so far

RETURN:		cx -- custom spacing, if hint present, else preserved
		dx preserved

DESTROYED:	?

PSEUDO CODE/STRATEGY:

	- if ctrl is in title bar:
		- if has custom spacing, honor spacing
		- if no custom spacing, minimize space
	- if ctrl is not in title bar:
		- if no custom spacing, exit
		- if has custom spacing, honor it

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/16/91	Initial version
	stevey	10/6/94		rewrote for new title-group code

------------------------------------------------------------------------------@
OpenCtrlCheckCustomSpacing	proc	far
	;
	;  See if ctrl is in title bar, firstly.
	;
	mov	di, ds:[si]						
	add	di, ds:[di].Vis_offset					

	test	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_LEFT shl \
			offset	OLBF_TARGET
	jnz	inTitleBar
	test	ds:[di].OLCI_buildFlags, OLBT_FOR_TITLE_BAR_RIGHT shl \
			offset	OLBF_TARGET
	jz	notInTitleBar

inTitleBar:
	;
	;  If it's got a custom-spacing bit set, pretend it's not
	;  in the title bar, since it appears to know what it wants.
	;
	test	ds:[di].OLCI_optFlags, mask OLCOF_CUSTOM_SPACING
	jnz	scanHints
	;
	;  In title bar without custom spacing => minimize spacing.
	;
	call	MinimizeChildSpacing	;replace 0 with -1 on B/W
	jmp	exit

notInTitleBar:
	;
	;  If there's no custom-spacing hint, bail.
	;
	test	ds:[di].OLCI_optFlags, mask OLCOF_CUSTOM_SPACING
	jz	exit

scanHints:	
	;
	;  We have a custom-spacing hint, so get the spacing from
	;  it.  (cx = spacing from ObjVarScanData)
	;
	segmov	es, cs
	mov	di, offset Geometry:SpacingHintHandlers
	mov	ax, length (Geometry:SpacingHintHandlers)
	call	ObjVarScanData
exit:
	ret
OpenCtrlCheckCustomSpacing	endp


OpenCtrlCheckCGASpacing	proc	far
	;
	; Let's see if we're running CGA.  If so, we won't space children 
	; too much.
	;
	; Pass:	cx -- spacing between children
	;	dx -- spacing between wrapped lines of children
	;	*ds:si -- object to check orientation
	; Ret:	cx, dx -- updated
	;

	; Now here's a good idea -- let's say we dereference this optr
	; before we attempt to follow ds:di.. --JimG 10/12/95
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	pushf
	jz	10$				;horizontal, branch
	xchg	cx, dx				;switch args
10$:
	;cx is now horizontal spacing, dx vertical spacing.

	call	OpenCheckIfCGA
	jnc	tryHoriz
	cmp	dx, MINIMAL_Y_SPACING
	jle	tryHoriz
	mov	dx, MINIMAL_Y_SPACING		;use minimal wrap spacing

tryHoriz:	
	call	OpenCheckIfNarrow
	jnc	done
	cmp	cx, MINIMAL_X_SPACING
	jle	done
	mov	cx, MINIMAL_X_SPACING		;use minimal child spacing
done:
	popf
	jz	20$				;horizontal, branch
	xchg	cx, dx				;switch args
20$:
	;
	; Use zero spacing in reply bars.  The default outline provides 
	; sufficient spacing.  Also if the one or more children take the
	; default outline.  -cbh 12/ 7/92   (We'll have a spacing of 1 for
	; a noDefaultRing system, since there needs at least a little spacing.
	; Only a little, since probably the default rings are being removed
	; for space reasons.  -cbh 4/16/93)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_moreFlags, mask OLCOF_OVERSIZED_CHILDREN
	jnz	replyBarSpacing
	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	jne	exit				;not reply bar, exit

replyBarSpacing:
	clr	cx
	mov	dx, cx
	
	call	OpenCheckDefaultRings		;allowing defaults, exit
	jc	exit
	inc	cx				;else leave a little space.
	inc	dx
exit:
	ret
OpenCtrlCheckCGASpacing	endp

SpacingHintHandlers	VarDataHandler \
	<HINT_CUSTOM_CHILD_SPACING, offset Geometry:CustomChildSpacing>,
	<HINT_CUSTOM_CHILD_SPACING_IF_LIMITED_SPACE, \
				    offset Geometry:CustomChildSpacingMinSpace>,
	<HINT_MINIMIZE_CHILD_SPACING, offset Geometry:MinimizeChildSpacing>,
	<HINT_CUSTOM_CHILD_WRAP_SPACING, offset Geometry:CustomChildWrapSpacing>

CustomChildWrapSpacing	proc	far
	push	cx
	call	CustomChildSpacing
	mov	dx, cx
	pop	cx
	ret
CustomChildWrapSpacing	endp

CustomChildSpacingMinSpace	proc	far
	call	OpenCheckIfLimitedLength	;only do spacing if length is
	jc	customSpacing			;  limited.
	ret
customSpacing:
	FALL_THRU	CustomChildSpacing
	
CustomChildSpacingMinSpace	endp

CustomChildSpacing	proc	far
EC <	VarDataSizePtr	ds, bx, ax				>
EC <	cmp	ax, 2						>
EC <	ERROR_B	OL_BAD_HINT_DATA				>
	mov	bx, {word} ds:[bx]		;spacing argument

	call	ViewCreateCalcGState
	mov	di, bp
	mov	ax, bx				;spacing argument
	call	VisConvertSpecVisSize		;calc a real width in ax
	mov	cx, ax
	call	GrDestroyState
afterHintCustomChildSpacing:
EC <	tst	cx							>
EC <	ERROR_S	OL_ERROR		; Hmmm.  Messed up.		>

exit:	
	ret
CustomChildSpacing	endp
			
MinimizeChildSpacing	proc	far
	clr	cx
	call	OpenCheckIfBW
	jnc	exit				;color, return zero spacing

	;
	; Not really a good solution -- does not take into effect views in
	; interactions in toolboxes, for instance -- the flag is not 
	; propagated up to the top ctrl with the MINIMIZE_SPACING flag set.
	; -cbh  2/22/93
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	exit				;not in toolbox, can't overlap
						;  (cbh 2/22/93)
	test	ds:[di].OLCI_moreFlags, mask OLCOF_CANT_OVERLAP_KIDS
	jnz	exit				;can't overlap (cbh 2/22/93)
	dec	cx				;B/W, return -1 spacing
exit:
	ret
MinimizeChildSpacing	endp
	
			

COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetMargins -- MSG_VIS_COMP_GET_MARGINS for OLCtrlClass

DESCRIPTION:	Returns margins for the object.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_GET_MARGINS

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This will become better soon.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@


OLCtrlGetMargins	method static OLCtrlClass, \
			MSG_VIS_COMP_GET_MARGINS
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	call	CalcCtrlMargins		; margins in ax
	;
	; If we're attempting to do center on monikers, then we'll need a
	; large area for the moniker to go.  4/23/93 cbh
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jz	exit

	push	ax
	call	GetParentMonikerSpace	;returns moniker space in ax
	mov	di, ax			;keep in di
	mov	ax, HINT_CENTER_CHILDREN_ON_MONIKERS
	call	ObjVarFindData
	pop	ax
	jc	nestedCenter		; nested centering, branch to save,
					;   but not use in margin.
	mov	ax, di			; a leaf: use as left margin.
	jmp	short exit

nestedCenter:
	mov	bx, ds:[si]		; store overall space so children can
	add	bx, ds:[bx].Vis_offset	;   reach it
	mov	ds:[bx].OLCI_monikerSpace, di
	
exit:					
	.leave
	ret

OLCtrlGetMargins	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcCtrlMargins

SYNOPSIS:	Calculates margins for an OLCtrl.

CALLED BY:	OLCtrlGetMargins, OLCtrlGetLargestCenter

PASS:		*ds:si -- OLCtrl

RETURN:		ax, bp, cx, dx -- margins

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/23/93       	Pulled out of OLCtrlGetMargins

------------------------------------------------------------------------------@

CalcCtrlMargins	proc	near
	;
	; If the control has no children, and there's no moniker, we'll assume
	; it's one of these weird trigger or menu bars that don't really want
	; to take up space.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	jnz	getWinMargins			;there is a moniker, branch
	clr	ax				;assume no margins at all
	clr	cx
	clr	dx
	clr	bp

	;
	; Add in some L/R margins, if needed.  Sometimes the gadget control 
	; can't supply margins because of a display control.
	; CHECK BW FOR CUA LOOK
	;
	call	OpenCheckIfCGA
	jnc	checkExtraMargins
	push	ax
	mov	ax, segment OLPaneClass
	mov	es, ax
	mov	di, offset OLPaneClass
	call	ObjIsObjectInClass
	pop	ax
	jc	noExtraMargins			;pane, no extra margins please.
checkExtraMargins:

	call	CheckIfNeedsExtraMargins	;check to see if we need margins
	jnc	noExtraMargins			;didn't, branch
	add	ax, di				;else add it in.
	mov	cx, ax				
						
noExtraMargins:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	tst	ds:[di].VCI_comp.CP_firstChild.chunk	
	jnz	getWinMargins			;has children, may need margins
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	LONG	jz	exit			;not generic, probably an Eric-
						;  object which may have no
						;  children, skip margins.
						;  (Yes, a hack.)
getWinMargins:
	;
	; Now, if we are displaying a moniker, we'll add margins so the 
	; moniker has room to draw.   This assumes monikers stay less than
	; 256 bytes in length.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	jz	noMoniker			;no moniker, branch

	clr	bp				;no gstate around
    	call	SpecGetGenMonikerSize		;get the moniker size in cx, dx
	jcxz	10$				;no spacing if no moniker

OLS <	add	cx, OL_CONTROL_MKR_X_SPACING		     		     >
CUAS <	add	cx, MO_CONTROL_MKR_X_SPACING		                     >
CUAS <  call	OpenCheckIfNarrow					   >
CUAS <	jnc	10$							   >
CUAS <	sub	cx, MO_CONTROL_MKR_X_SPACING - \
		MO_CONTROL_MKR_X_SPACING_NARROW			           >
CUAS <10$:								   >
	
	tst	dx
	jz	25$				;no spacing if no moniker

	;
	; Add a little spacing.  Not too much if on CGA.
	;
	push	ax
OLS <	mov	ax, OL_CONTROL_MKR_Y_SPACING				   >
CUAS <	mov	ax, MO_CONTROL_MKR_Y_SPACING				   >
CUAS <  call	OpenCheckIfCGA			;zeroes ax if CGA	   >
CUAS <	jnc	20$							   >
CUAS <	mov	ax, MO_CONTROL_MKR_Y_SPACING_CGA			   >
CUAS <20$:								   >

     	add	dx, ax				;add to vertical position
	pop	ax
25$::

	mov	bp, cx				;use width as a minimum width
						;(needed if above the composite)
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	jnz	dispMkrAbove			;branch if displaying above
	clr	dx				;no extra on top if disp to left
	jmp	short finishUp

dispMkrAbove:

	; cx is to be used as left margin
	; dx is to be used as top margin

	clr	cx				;no extra on left if disp above

finishUp:
	mov	ax, cx				;moniker width is left margin
	mov	bp, dx				;moniker height is top margin
	clr	cx				;no right or bottoms, yet.
	clr	dx	

	test	ds:[di].OLCI_moreFlags, mask OLCOF_RIGHT_JUSTIFY_MONIKER
	jz	noMoniker			;not right justifying, branch
	xchg	ax, cx				;else put margins on right

noMoniker:
	;
	; Add a little margin around the bottom and sides of the control if
	; it has a border.  Add margin to top if there isn't any already (due
	; to the lack of a moniker, usually.)
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_BORDER
	jz	checkReplyBar			;branch if not
	cmp	bp, OL_CTRL_BOXED_MARGIN_TOP
	jae	alreadyHaveTop
	mov	bp, OL_CTRL_BOXED_MARGIN_TOP
	call	OpenCheckIfCGA			;running CGA?
	jnc	alreadyHaveTop			;no, branch
	sub	bp, OL_CTRL_BOXED_MARGIN_TOP - OL_CTRL_BOXED_MARGIN_CGA

alreadyHaveTop:

	add	ax, OL_CTRL_BOXED_MARGIN_LEFT
	add	cx, OL_CTRL_BOXED_MARGIN_RIGHT
	call	OpenCheckIfNarrow
	jnc	doBottom
	sub	ax, OL_CTRL_BOXED_MARGIN_LEFT - OL_CTRL_BOXED_MARGIN_CGA
	sub	cx, OL_CTRL_BOXED_MARGIN_RIGHT - OL_CTRL_BOXED_MARGIN_CGA

doBottom:
	add	dx, OL_CTRL_BOXED_MARGIN_BOTTOM
	call	OpenCheckIfCGA			;running CGA?
	jnc	checkReplyBar			;no, branch
	sub	dx, OL_CTRL_BOXED_MARGIN_BOTTOM - OL_CTRL_BOXED_MARGIN_CGA
	
checkReplyBar:
	call	DoReplyBarMargins

if _MOTIF or _ISUI
	;
	; deal with custom extra margins
	;
	push	ax
	mov	ax, HINT_CUSTOM_EXTRA_MARGINS
	call	ObjVarFindData
	pop	ax
	jnc	noExtra

	add	ax, ds:[bx].R_left
	add	bp, ds:[bx].R_top
	add	cx, ds:[bx].R_right
	add	dx, ds:[bx].R_bottom
noExtra:
endif

exit:
	ret
CalcCtrlMargins	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	DoReplyBarMargins

SYNOPSIS:	Does reply bar margins, if needed.

CALLED BY:	OLCtrlGetMargins

PASS:		*ds:si -- OLCtrl
		ax, bp, cx, dx -- margins so far

RETURN:		ax, bp, cx, dx -- updated if needed

DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/23/93       	Initial version

------------------------------------------------------------------------------@

DoReplyBarMargins	proc	near
	;
	; If this is a reply bar, add a little space on top to separate it
	; from the other controls a little.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	jnz	exit				;not reply bar, exit
	add	bp, OL_REPLY_BAR_SPACE		;add extra space above reply bar
MO <	add	dx, OL_REPLY_BAR_SPACE		;and below		>
MO <	add	ax, MO_REPLY_BAR_X_INSET				>
MO <	add	cx, MO_REPLY_BAR_X_INSET				>

EC <	push	di							>
EC <	mov	di, segment OLReplyBarClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLReplyBarClass				>
EC <	call	ObjIsObjectInClass					>
EC <	pop	di							>
EC <	ERROR_NC	OL_ERROR					>

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLRBI_flags, mask OLRBF_UNDER_DIALOG
	jnz	10$				;if not under dialog,
	inc	bp				;  improve top margin slightly
10$:

MO <	call	OpenCheckIfCGA						>
MO <	jnc	exit				; if not CGA, exit	>
MO <						; if CGA, compensate vert >
MO <	sub	bp, OL_REPLY_BAR_SPACE - OL_CGA_REPLY_BAR_SPACE		>
;MO <	add	dx, OL_CGA_REPLY_BAR_BOTTOM_SPACE			>

ISU <	call	OpenCheckIfCGA						>
ISU <	jnc	exit				; if not CGA, exit	>
ISU <						; if CGA, compensate vert >
ISU <	sub	bp, OL_REPLY_BAR_SPACE - OL_CGA_REPLY_BAR_SPACE		>
ISU <	add	dx, OL_CGA_REPLY_BAR_BOTTOM_SPACE			>

exit:
	ret
DoReplyBarMargins	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfNeedsExtraMargins

SYNOPSIS:	Checks to see if we need extra margins for our OLCtrl.
		Sometimes if our parent is an OLGadgetArea, it may not have
		been able to provide the required margins itself due to a 
		DisplayControl being around.

CALLED BY:	OLCtrlGetMargins

PASS:		*ds:si -- OLCtrl

RETURN:		carry set if needed margins, with:
			di -- amount of margin

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/20/92		Initial version

------------------------------------------------------------------------------@

CheckIfNeedsExtraMargins	proc	near	uses	ax, si
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	je	exit				;reply bar, don't add extras!
						; -cbh 1/23/93

	call	VisSwapLockParent		;get parent in *ds:si
	jnc	exit				;no parent, exit
	mov	di, segment OLGadgetAreaClass
	mov	es, di
	mov	di, offset OLGadgetAreaClass
	call	ObjIsObjectInClass		;see if parent is a gadget area
	jnc	unlockParent			;nope, done
	mov	ax, MSG_SPEC_CHECK_IF_NEEDS_MARGINS
	call	ObjCallInstanceNoLock		;parent gadget control may 
	mov	di, ax				;   request a L/R margin in ax

unlockParent:
	call	ObjSwapUnlock
exit:
	.leave
	ret
CheckIfNeedsExtraMargins	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlRerecalcSize --
		MSG_VIS_RECALC_SIZE for OLCtrlClass

DESCRIPTION:	Returns the size of a control object.  This has to be done 
		specially because for some reason we need to avoid passing
		space that we know is used for other left monikers.  

		Having desired sizes for controls sets a minimum for all 
		controls.  If we're wrapping, it also sets a maximum.
		
PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - size args

RETURN:		cx, dx  - size to use

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		call superclass get center
       		if displaying vis moniker to left of composte
			return width of moniker + OL_CTRL_LEFT_MARGIN
						+ OL_CTRL_SPACING

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/29/89		Initial version

------------------------------------------------------------------------------@

OLCtrlRerecalcSize	method private static OLCtrlClass, MSG_VIS_RECALC_SIZE
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	call	PassSpacingArgsIfWeCan
	call	OpenRecalcCtrlSize	

	pop	di
	call	ThreadReturnStackSpace

	;
	; Must mark that we're no longer messing with our children's size, so 
	; they'll know they're sizing themselves or something, and shouldn't
	; do the SubtractReservedMonikerSpaceIfNeeded stuff.  -cbh 11/12/92
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLCI_moreFlags, not mask OLCOF_SIZING_CHILDREN

	.leave
	ret
OLCtrlRerecalcSize	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenRecalcCtrlSize

SYNOPSIS:	Does normal OLCtrl class stuff for MSG_VIS_RECALC_SIZE.

CALLED BY:	utility

PASS:		*ds:si -- object
		cx, dx -- size suggestions
		bp     -- VisCompSpacingMarginsInfo

RETURN:		cx, dx -- size to use.

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

OpenRecalcCtrlSize	proc	far
	push	bp
	call	SetExpandHeightInHorizToolbox	;do some stupid expand height
						;  stuff if a child of a 
						;  horizontal toolbox
						;  -cbh 1/25/93

	;
	; Next, see if ther user specified a desired size, and convert it
	; if it hasn't yet been.  (We do it here to be sure that the orientation
	; has been permanently set.)
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	jz	callSuper			;do superclass if reply bar

	call	CalcCentersIfCenteringByMonikers
	
checkDesired:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_optFlags, mask OLCOF_IGNORE_DESIRED_SIZE_HINTS	
	jnz	callSuper			;if ignoring, branch
	CallMod	VisApplySizeHints		;adjust passed stuff
						;  according to size hints
callSuper:
	pop	bp
	call	OpenCtrlCalcMonikerOffsets	;calc moniker offsets here.

	mov	ax, segment VisCompClass	;make sure es is correct
	mov	es, ax
	CallMod	VisCompRecalcSize		;and call directly
	ret
OpenRecalcCtrlSize	endp








COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcCentersIfCenteringByMonikers

SYNOPSIS:	Calculates the largest moniker below us if we're centering
		that way.

CALLED BY:	OpenRecalcCtrlSize

PASS:		*ds:si -- menu

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/23/93		Initial version

------------------------------------------------------------------------------@

CalcCentersIfCenteringByMonikers	proc	near	uses cx, dx
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jz	exit			;nothing invalid, quit now.

	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jnz	exit			;we're at best an intermediate leaf,
					;  let this be handled by the top guy.

	mov	ax, HINT_CENTER_CHILDREN_ON_MONIKERS
	call	ObjVarFindData
	jnc	exit			;not centering, get out.

	clr	bp			;everybody valid so far
	clr	cx			;moniker space
	mov	dx, cx			;accelerator space
	mov	ax, MSG_SPEC_CTRL_GET_LARGEST_CENTER
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	cx, ds:[di].OLCI_monikerSpace
	je	exit				;moniker space not changing..
	
	;
	; If the menu item sizes changed, we'll store the new values and 
	; reset the geometry of all the objects underneath us, so the children
	; will be guaranteed to get their sizes recalculated.  
	;
	mov	ds:[di].OLCI_monikerSpace, cx

	push	bp
	call	AddFullBoundsToUpdateRegion	;ensure entire thing inval'ed
	pop	bp

	tst	bp			;no children had valid geometry, don't
	jz	exit			;   waste our time.

	mov	dl, VUM_MANUAL		
	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
	call	VisSendToChildren
exit:
	.leave
	ret
CalcCentersIfCenteringByMonikers	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	AddFullBoundsToUpdateRegion

SYNOPSIS:	Adds our full bounds to the update region, to absolutely
		ensure everything is redrawn, since apparently moniker widths
		are changing, and the update mechanism deals poorly with
		changing margins in ONLY_DRAWS_IN_MARGINS composites.

CALLED BY:	Don't know yet.

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/26/93		Sigh.

------------------------------------------------------------------------------@

AddFullBoundsToUpdateRegion	proc	near
	class	VisClass

	call	VisGetBounds
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jnz	10$			; leave contents alone
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jz	10$			; not a window, branch
	;
	; If a window, we need coordinates to be 0,0,...
	;
	sub	cx, ax			; adjust right
	clr	ax			; and left
	sub	dx, bx			; and bottom
	clr	bx			; and top
10$:
	sub	sp, size VisAddRectParams
	mov	bp, sp
	mov	ss:[bp].VARP_bounds.R_left, ax
	mov	ss:[bp].VARP_bounds.R_top, bx
	mov	ss:[bp].VARP_bounds.R_right, cx
	mov	ss:[bp].VARP_bounds.R_bottom, dx
	mov	cx, di
	clr	ss:[bp].VARP_flags	; no special redrawing to be done, just
					;   inval everything.
	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	call	ObjCallInstanceNoLock
	add	sp, size VisAddRectParams
	ret
AddFullBoundsToUpdateRegion	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetLargestCenter -- 
		MSG_SPEC_CTRL_GET_LARGEST_CENTER for OLCtrlClass

DESCRIPTION:	Gets the moniker space for all the objects under the head
		object with HINT_CENTER_CHILDREN_ON_MONIKERS.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CTRL_GET_LARGEST_CENTER
		cx	- largest moniker found so far
		bp	- set if any child with valid geometry found

RETURN:		cx, bp	- possibly updated
		ax, dx  - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	chris	4/23/93         Initial Version

------------------------------------------------------------------------------@

OLCtrlGetLargestCenter	method dynamic	OLCtrlClass, \
				MSG_SPEC_CTRL_GET_LARGEST_CENTER
	
	push	ax
	mov	ax, HINT_CENTER_CHILDREN_ON_MONIKERS
	call	ObjVarFindData
	pop	ax
	jnc	centeringNode		;no hint, handle as a node

	;
	; Call all children with the message, propagating cx and bp to each.
	;
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	;DO NOT CHANGE THIS TO A GOTO!  We are passing stuff on the stack.
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	ret


centeringNode:
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jz	exit
	;	
	; Update valid-geometry flag as appropriate.
	;
	tst	bp
	jnz	10$
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jnz	10$
	dec	bp
10$:
	push	cx, bp				;save current value
	call	CalcCtrlMargins			;ax <- left margin
	pop	cx, bp

	mov	di, ds:[si]			;save our moniker space for
	add	di, ds:[di].Vis_offset		;  drawing later.
	mov	ds:[di].OLCI_monikerSpace, ax

	cmp	cx, ax
	jae	exit
	mov	cx, ax
exit:
	ret
OLCtrlGetLargestCenter	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	SetExpandHeightInHorizToolbox

SYNOPSIS:	Expands height if we're the child of a horizontal toolbox.
		Actually, sets or clears the expand flag depending on whether
		there are children involved.

CALLED BY:	OpenRecalcCtrlSize

PASS:		*ds:si -- OLCtrl

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/25/93       	Initial version

------------------------------------------------------------------------------@

SetExpandHeightInHorizToolbox	proc	near		uses cx
	.enter

	; If we're inside a toolbox, and we're not the top node, we'll set
	; ourselves to expand our height to fit our parent, to ensure even 
	; heights in toolbox.

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	exit				
	mov	ax, HINT_TOOLBOX
	call	ObjVarFindData
	jc	exit				;top item, don't expand

	push	si
	call	VisSwapLockParent		;not in Vis tree, look up 
						; random memory. Who cares?
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	call	ObjSwapUnlock
	pop	si
	jnz	exit				;in vertical bar, don't expand

	clr	cl				;assume not expanding
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	tst	ds:[di].VCI_comp.CP_firstChild.chunk
	jz	10$
	mov	cl, mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
10$:
	and	ds:[di].VCI_geoDimensionAttrs, \
			not mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	or	ds:[di].VCI_geoDimensionAttrs, cl
exit:
	.leave
	ret
SetExpandHeightInHorizToolbox	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCtrlCalcMonikerOffsets

SYNOPSIS:	Sets moniker offsets for the OLCtrl, if needed.

CALLED BY:	OpenRecalcCtrlSize
		OLPaneRecalcSize (via CallMod)

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/14/92       	Initial version

------------------------------------------------------------------------------@

OpenCtrlCalcMonikerOffsets	proc	far
	;
	; Set some default moniker positions, just in case.
	;
	push	cx, dx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLCI_monikerPos.P_y, CTRL_MKR_INSET_Y
	mov	ds:[di].OLCI_monikerPos.P_x, 0

	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	jz	exit				;not displaying moniker, get out
	test	ds:[di].OLCI_moreFlags,mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD
	jnz	getPos				;always get pos in this case
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE 
	jnz	exit				;displaying above, exit
getPos:
	mov	ax, MSG_GET_FIRST_MKR_POS
	call	ObjCallInstanceNoLock
	jnc	exit				;no special handler, exit
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	sub	cx, ds:[di].VI_bounds.R_top	;subtract top
	sub	ax, ds:[di].VI_bounds.R_left	;subtract left
	mov	dx, cx				;top
	mov	cx, ax				;left
	call	OLCtrlSetMonikerOffset		;set the offsets
exit:
	pop	cx, dx
	ret
OpenCtrlCalcMonikerOffsets	endp








COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlSetMonikerOffset -- 
		MSG_SPEC_CTRL_SET_MONIKER_OFFSET for OLCtrlClass

DESCRIPTION:	Manually sets a moniker offset.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CTRL_SET_MONIKER_OFFSET
		cx 	- x offset
		dx	- y offset

RETURN:		nothing
		ax, cx, dx, bp - destroyed
		called externally -- does not destroy ds, si

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	11/15/92         	Initial Version

------------------------------------------------------------------------------@

OLCtrlSetMonikerOffset	method 	OLCtrlClass, \
				MSG_SPEC_CTRL_SET_MONIKER_OFFSET
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_moreFlags,mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD
	jz	10$				;clear, don't bother with x
	mov	ds:[di].OLCI_monikerPos.P_x, cx	
10$:
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE 
	jnz	exit				;displaying above, don't do y
	mov	ds:[di].OLCI_monikerPos.P_y, dx	
exit:
	ret
OLCtrlSetMonikerOffset	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	PassSpacingArgsIfWeCan

SYNOPSIS:	Sets up spacing and margin arguments if they fit in a word.

CALLED BY:	OLCtrlRerecalcSize

PASS:		*ds:si -- object

RETURN:		bp -- VisCompSpacingMarginsInfo

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/30/92		Initial version

------------------------------------------------------------------------------@

PassSpacingArgsIfWeCan	proc	near		uses	cx, dx
	.enter
	call	OLCtrlGetSpacing		;first, get spacing
	push	cx, dx				;save spacing
	call	OLCtrlGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
PassSpacingArgsIfWeCan	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	SubtractReservedMonikerSpace

SYNOPSIS:	Subtracts space that must be left clear for sibling monikers.
		If we're centering, and some of the another sibling has a
		larger left-of-center value than we do, and we're expanding
		to fit, or we have children that like to expand to fit us (like
		a text object), we're probably going to run into trouble because
		we'll try to fill up the entire width passed to us, which isn't
		really available; only what we have for left-of-center plus
		any space available right-of-center is there for us to expand
		to.  If we don't do this routine, the parent grows and grows
		until an eventual fatal error.

		(I'm deeming this a hack now.  This only helps expand-to-fit
		composites in a center-by-monikers parent.  There must be a
		general case where you only give the child a size equal to...
		I don't know.  The problem only happens when the child is
		expanding to fit but keeping the amount of space left or right
		of center fixed.)
		
CALLED BY:	OLCtrlRerecalcSize

PASS:		*ds:si -- handle of moniker
		cx, dx -- passed resize args

RETURN:		cx, dx -- possibly adjusted size

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 9/90		Initial version

------------------------------------------------------------------------------@

SubtractReservedMonikerSpace	proc	far
	class	OLCtrlClass
	
if	0
	push	cx, dx				;save geometry passed
	tst	cx				;see if desired width
	js	normalCalc			;yes, skip special stuff

	;	
	; We don't need to be doing any of this stuff if we're not being
	; sized by our parent OLCtrl, so skip it.  -cbh 11/12/92
	;
	push	cx
	call	OpenGetParentMoreFlagsIfCtrl	
	test	cl, mask OLCOF_SIZING_CHILDREN
	pop	ax
	jz	normalCalc
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jz	normalCalc			;not special center, exit normal
	
	mov	ax, MSG_VIS_COMP_GET_MARGINS	;looking for parent's left edge
	call	VisCallParent			;
	push	ax				;save it
	
	call	VisGetParentCenter
	mov	bx, cx				;keep left part
	pop	dx				;restore parent's top edge
	clr	dh				;clear high byte
	sub	bx, dx				;and subtract from parent center
	call	VisSendCenter
	sub	bx, cx				;subtract it from parent center
	jae	10$				;got a positive result, branch
	clr	bx				;else we won't subtract anything
10$:
	DoPop	dx, cx				;restore args passed in
	mov	ah, ch				;put width in ax, sort of
	sub	cx, bx				;subtract unused left-of-center
	jns	20$				;got a positive result, branch
	clr	cx				;else use zero
20$:
	jmp	short argsPopped		;and branch
	
normalCalc:
	DoPop	dx, cx				;restore args
	
argsPopped:
endif

	ret
SubtractReservedMonikerSpace	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetMinSize -- 
		MSG_GET_MIN_SIZE for OLCtrlClass

DESCRIPTION:	Returns minimum size for the control.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_MIN_SIZE

RETURN:		cx	- minimum composite width
		dx	- minimum composite height

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 9/89	Initial version

------------------------------------------------------------------------------@

OLCtrlGetMinSize	method	OLCtrlClass, MSG_VIS_COMP_GET_MINIMUM_SIZE
	mov	ax, MSG_VIS_COMP_GET_MARGINS	;we need margins added to
	call	ObjCallInstanceNoLock		;whatever is returned...
	push	dx, bp, ax, cx			;save them

	;
	; If we're in a menu, let's not worry about the size of the moniker --
	; it's probably just a moniker for the menu button, anyway.  
	; -cbh 12/19/92
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_optFlags, mask OLCOF_IN_MENU
	mov	cx, 0				;assume in menu, no min size
	mov	dx, 0
	jnz	gotMonikerSize

	clr	bp				;size of moniker in cx, dx
	call	SpecGetGenMonikerSize		;

	;
	; This seems very lame, to add margins into every OLCtrl.  We're 
	; not doing it for space-hungry Rudy.
	;
	add	dx, CTRL_MKR_INSET_Y		;this inset gets added to the
						;  moniker position when 
						;  no one responds to the 
						;  MONIKER_POS request
;
; All SPUIs already have this added in the margins, but we'll only fix this
; for RUDY, for now.  Note that it is still valid to subtract off the
; left margin below, if aligning -- brianc 3/5/96
;
	;
	; Added 3/ 3/93 cbh to have proper margins when drawing a frame.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_BORDER
	jz	1$
   	add	cx, (TOP_FRAME_AT_END_MARGIN + OL_CTRL_MKR_MARGIN)*2
						;default x margin, for use if
						; left or right justifying
1$:
	;
	; This isn't quite right, but if there's a moniker margin, let's take
	; it into account on the width.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	jz	2$
	test	ds:[di].OLCI_moreFlags, \
				mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD
	jz	2$
	add	cx, ds:[di].OLCI_monikerPos.P_x
   	sub	cx, TOP_FRAME_AT_END_MARGIN + OL_CTRL_MKR_MARGIN
						;Nuke the default left margin
						;  -cbh 3/ 3/93
2$:

	;
	; If displaying moniker above, the width of the moniker is used in 
	; minimum width calculations.  If displaying moniker to the left,
	; the height will be used.   (The other dimension already in
	; the margins in each case).
	;
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE	
	jnz	3$				;branch if above
	clr	cx				;else don't use width
	jmp	short gotMonikerSize		;branch
3$:
	clr	dx				;don't use height if above

gotMonikerSize:
	;
	; Add in margins to size returned.
	;
	pop	ax, bx				;restore right, left margin
	add	cx, ax				;add to minimum width
	add	cx, bx
	
	pop	ax, bx				;restore right, left margin
	add	dx, ax				;add to minimum width
	add	dx, bx
	
	push	cx, dx
	clr	cx
	clr	dx

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_IGNORE_DESIRED_SIZE_HINTS	
	jnz	8$				;if ignoring, branch
	CallMod	VisApplySizeHints		;hopefully, will use the best
8$:
	mov	ax, cx				;  minimum...
	mov	bx, dx
	pop	cx, dx
	
	;	
	; Desired composite width in ax, desired composite height in bx.
	;
	cmp	cx, ax 				;use desired length if bigger
	ja	10$
	mov	cx, ax
10$:
	cmp	dx, bx				;and width
	ja	20$
	mov	dx, bx
20$:
	ret
OLCtrlGetMinSize	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcDesiredCtrlSize
		MSG_SPEC_CONVERT_DESIRED_SIZE_HINT for OLCtrlClass

SYNOPSIS:	Converts a desired size hint for the control.

PASS:		*ds:si -- handle of control
		cx -- width of the composite (SpecSizeSpec)
		dx -- child height to reserve (SpecSizeSpec)
		bp -- number of children to reserve space for

RETURN:		cx, dx -- converted size
		ax, bp -- destroyed

DESTROYED:	di

PSEUDO CODE/STRATEGY:
 	    extraWidth, extraHeight = margin total width and height
     	    if (width or height) and (SST_AVG_CHAR_WIDTHS
		 or SST_WIDE_CHAR_WIDTHS or SST_LINES_OF_TEXT
			call MSG_SPEC_GET_EXTRA_SIZE on ourselves
				(returns extraWidth, extraHeight, childCount)
			if !childCount
			   width = GENERIC_EXTRA_WIDTH
			if VERTICAL
			   multiply GENERIC_EXTRA_HEIGHT by (numChildren -
			   number of gen children counted) & add to extraHeight
			else
			   at end multiply GENERIC_EXTRA_WIDTH by (numChildren -
			   number of gen children counted) and add to extraWidth
	    width = VisConvertSpecVisSize(width) + extraWidth
	    if VERTICAL
		 height = VisConvertSpecVisSize(height)*numChildren + extraHt
	    else
	    	 height = VisConvertSpecVisSize(height) + extraHeight

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/3/89		Initial version
	Chris	4/30/91		Made into method handler

------------------------------------------------------------------------------@

CalcDesiredCtrlSize	method	OLCtrlClass, MSG_SPEC_CONVERT_DESIRED_SIZE_HINT

	mov	di, 500				;sad but true, we need lots
	call	ThreadBorrowStackSpace		;of stack space
	push	di
	xchg	cx, bp				;lazy switcheroo on the args
	push	cx, dx, bp			;push our fine args
	call	GetNonMonikerMarginTotals	;extra length & width = margins
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	DoneWithMarginExtras		;branch if not vertical
	xchg	cx, dx				;else switch to get width,height
DoneWithMarginExtras:
	
	mov	ax, cx				;extraWidth
	mov	bx, dx				;extraHeight
	pop	cx, dx, bp
	mov	di, bp				;di <- width passed
	and	di, mask SSS_TYPE		;get just the type flags
	cmp	di, SST_AVG_CHAR_WIDTHS shl 10
	je	addChildExtras			;add up extra space if this
	cmp	di, SST_WIDE_CHAR_WIDTHS shl 10
	je	addChildExtras			;or this
	cmp	di, SST_PIXELS shl 10
	je	addChildExtras
	
	mov	di, dx				;di <- height passed
	and	di, mask SSS_TYPE		;mask off type bits
	cmp	di, SST_PIXELS shl 10		
	je	addChildExtras			;if pixel height, branch
	cmp	di, SST_LINES_OF_TEXT shl 10
	jne	convertSpecSize			;none of these, skip extra calc
	
addChildExtras:
	push	si				;save si
	push	bx, ax				;save the margin values
	call	CalcExtraSize			;calculate extra width and ht
	mov	di, bp				;di <- width passed
	and	di, mask SSS_TYPE		;get just the type flags
	pop	si				;restore margin total width
	cmp	di, SST_AVG_CHAR_WIDTHS shl 10
	je	checkDx				;use added up extra if this
	cmp	di, SST_WIDE_CHAR_WIDTHS shl 10
	je	checkDx				;or this
	cmp	di, SST_PIXELS shl 10
	je	checkDx				;or this
	
	mov	ax, si				;else use margin total width
	
checkDx:
	mov	di, dx				;di <- height passed
	pop	si				;get the margin total height
	and	di, mask SSS_TYPE		;mask off type bits
	tst	di				;if no desired height, branch
	cmp	di, SST_LINES_OF_TEXT shl 10
	je	doneAddingExtras		;this is set, keep calced extra
	cmp	di, SST_PIXELS shl 10
	je	doneAddingExtras		;or this
	
	mov	bx, si				;else use total margin height
	
doneAddingExtras:
	pop	si				;restore this
	
convertSpecSize:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	pushf					;save vertical flag
	push	ax				;save extra length
	push	bp				;save passed width
	call	ViewCreateCalcGState
	mov	di, bp				;gstate in di
	pop	ax				;restore passed width in ax
	call	VisConvertSpecVisSize		;calc a real width in ax
	mov	bp, ax				;move back to bp
	mov	ax, dx				;get passed height
	call	VisConvertSpecVisSize		;calc a real height in ax
	mov	dx, ax				;move back to dx
	call	GrDestroyState
	pop	ax				;restore passed extra length
	popf					;restore vertical
	jz	finishConvert			;not vertical, branch
	
;	push	ax				;save extra length
;	mov	ax, dx				;converted height in ax
;	mul	cx				;multiply by number of children
;	mov	dx, ax				;result back in dx
;	pop	ax				;restore extra length
	
finishConvert:
	mov	cx, bp				;move width to cx
	tst	cx				;see if any desired width
	jz	10$				;if not, skip extra
	add	cx, ax				;add extra width to width
10$:
	tst	dx				;see if any desired width
	jz	20$				;if not, skip extra
	add	dx, bx				;add extra height to height
20$:
	pop	di
	call	ThreadReturnStackSpace
	ret
CalcDesiredCtrlSize	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcExtraSize

SYNOPSIS:	Calculates extra size of control.  

CALLED BY:	CalcDesiredCtrlSize

PASS:		*ds:si -- handle of control.
		cx -- number of desired children

RETURN:		ax - extra width
		bx - extra height

DESTROYED:	di, es

PSEUDO CODE/STRATEGY:
       		Call MSG_SPEC_GET_EXTRA_SIZE to get extra sizes of existing
			children
		calculate number of children that are desired but don't exist
			yet, and either use typical inset amounts or 
			the extra size of the first child to calculate
			extra sizes for these as yet non-existant children.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 6/89	Initial version

------------------------------------------------------------------------------@

CalcExtraSize	proc	far			uses dx, bp
	class	OLCtrlClass
	.enter
	
	push	cx				;save number of desired children
	mov	bp, cx				;pass in bp
	mov	ax, MSG_SPEC_GET_EXTRA_SIZE	;get our total extra size
	call	ObjCallInstanceNoLock		;returns children not accounted
						;   for in bp
	;
	; If there are no children, we need to set a reasonable width (if we're
	; vertical) or height (if we're horizontal).  And zero the other
	; direction (the "length" of the composite).
	;
	tst	bp				;all children accounted for?
	jz	returnAxBx			;yes, exit now
	
	pop	bx				;restore desired childen
	push	bx				;save back
	cmp	bx, bp				;compare with children left
	je	noChildren			;none were found, branch
	
	mov	bx, bp				;keep unaccounted children in bx
	push	cx, dx				;save current extra size
	mov	ax, MSG_SPEC_GET_EXTRA_SIZE	;and get extra size of 1st child
	call	VisCallFirstChild		;  to use for non-present childs

	mov	al, bl				;put number of non-existent
						;   children in al
	mov	bl, cl				;put x extra size in bl
	mov	bh, dl				;put y extra size in bh
	DoPop	dx, cx				;restore
	jmp	short addNonPresentExtras	;and branch to calculate
	
noChildren:
	;
	; No children -- query ourselves to get a typical child extra size.
	; Maybe we'll have a good idea of what kind of items will be added
	; to this object.  Or maybe not.
	;	al -- num children to account for
	;
	push	bx
	mov	ax, MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE
	call	ObjCallInstanceNoLock		;returned in al, ah
	mov	bx, ax				;now in bl, bh
	pop	ax				;# children in al

addNonPresentExtras:
	;
	; Before calculating, get child spacing.
	;
	push	cx, dx				;height and width totals
	push	ax				;num children
	mov	ax, MSG_VIS_COMP_GET_CHILD_SPACING
	call	ObjCallInstanceNoLock
	tst	ch				;do the best we can for > 255
	jz	10$
	mov	cl, 255
10$:
	pop	ax				;restore num children in al
	mov	ah, cl				;child spacing in ah
	pop	cx, dx				;restore height and width totals
	;
	; bl contains x inset to use for children that don't yet exist
	; bh contains y inset to use for children that don't yet exist
	; al has number of children that don't yet exist
	; ah has child spacing
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	horizAddNonPresent		;horizontal, branch

	add	bh, ah				;add child spacing to yInset
	mul	bh				;ax <- yInset * numChildren
	add	dx, ax				;and add to extraHeight
	jmp	short returnAxBx		;and we're done
	
horizAddNonPresent:
	add	bl, ah				;add child spacing to xInset
	mul	bl				;ax <- xInset * numChildren
	add	cx, ax				;and add to extra width
	
returnAxBx:
	mov	ax, cx				;total extra length in ax
	mov	bx, dx				;total extra height in bx
	pop	cx				;restore number of children
	.leave
	ret
CalcExtraSize	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetTypicalChildExtraSize -- 
		MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE for OLCtrlClass

DESCRIPTION:	Returns typical extra size for a child of this object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE

RETURN:		al	- typical x extra size
		ah	- typical y extra size
		cx, dx, bp - preserved

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/25/92		Initial Version

------------------------------------------------------------------------------@

OLCtrlGetTypicalChildExtraSize	method dynamic	OLCtrlClass, \
				MSG_SPEC_GET_TYPICAL_CHILD_EXTRA_SIZE

OLS <	mov	ax, ((TYPICAL_INSET_Y*2) shl 8) or (TYPICAL_INSET_X*2)
CUAS <	mov	ax, ((MO_TYPICAL_INSET_Y*2) shl 8) or (MO_TYPICAL_INSET_X*2)
	ret
OLCtrlGetTypicalChildExtraSize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetFirstMkrPos -- 
		MSG_GET_FIRST_MKR_POS for OLCtrlClass

DESCRIPTION:	Returns moniker position of the first child.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_FIRST_MKR_POS

RETURN:		carry set if something to return
		ax, cx - position of first child's vis moniker

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/89		Initial version

------------------------------------------------------------------------------@

OLCtrlGetFirstMkrPos	method OLCtrlClass, MSG_GET_FIRST_MKR_POS
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset VI_link
	push	bx			;push offset to LinkPart
	mov	bx, SEGMENT_CS
	push	bx			; push callback routine (seg)
	mov	bx,offset CallFirstValidChild
	push	bx			; push callback routine (off)

	mov	bx,offset Vis_offset
	mov	di,offset VCI_comp
	call	ObjCompProcessChildren	;find a suitable result
	jnc	exit			;no child found with valid geometry
	tst	dl			;else see if child handled method
	clc				;assume not
	jz	exit			;return carry clear if not
	stc				;else return carry set
exit:
	ret

OLCtrlGetFirstMkrPos	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	CallFirstValidChild

SYNOPSIS:	Calls first child that has valid geometry.

CALLED BY:	OLCtrlGetFirstMkrPos  (callback for ObjCompProcessChildren)

PASS:		*ds:si -- child handle
		*es:di -- parent	

RETURN:		carry set if child found, clear otherwise
		dl	- set if child returned carry set, clear otherwise
		ax, cx  - position of first moniker if child handles method

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 8/90		Initial version

------------------------------------------------------------------------------@

CallFirstValidChild	proc	far
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	clc					;assume geometry's bad, continue
	jnz	exit				;try next child if bad geometry
	mov	ax, MSG_GET_FIRST_MKR_POS
	call	ObjCallInstanceNoLock		;else call the child
	mov	dl, 0				;assume it didn't handle method
	jnc	foundAppropriateChild		;nope, exit (but we are done.)
	dec	dl				;else we'll leave dl set
	
foundAppropriateChild:
	stc					;time to quit now
exit:
	ret
CallFirstValidChild	endp

			


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetWrapCount -- 
		MSG_VIS_COMP_GET_WRAP_COUNT for OLCtrlClass

DESCRIPTION:	Returns a wrap count for this control.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_COMP_GET_WRAP_COUNT

RETURN:		cx	- number of initial children before doing the wrap thang
		ax, dx, bp destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/19/91		Initial version

------------------------------------------------------------------------------@

OLCtrlGetWrapCount	method OLCtrlClass, MSG_VIS_COMP_GET_WRAP_COUNT
					; Process alignment hints
	segmov	es, cs			; setup es:di to be ptr to
					; Hint handler table
EC <	mov	cx, -1							>
	mov	di, offset Geometry:WrapHintHandlers
	mov	ax, length (Geometry:WrapHintHandlers)
	call	ObjVarScanData
EC <	tst	cx							>
EC <	ERROR_S	OL_ERROR		; Hmmm.  Fucked up.		>
EC <	ERROR_Z	OL_CTRL_CANT_HAVE_A_WRAP_COUNT_OF_ZERO			>
EC <	cmp	cx, 1000						>
EC <	ERROR_A	OL_CTRL_CANT_HAVE_A_HUGE_WRAP_COUNT			>
	ret
OLCtrlGetWrapCount	endm

ReturnWrapCount	proc	far
EC <	VarDataSizePtr	ds, bx, ax				>
EC <	cmp	ax, 2						>
EC <	ERROR_B	OL_BAD_HINT_DATA		>
	mov	cx, {word} ds:[bx]			;wrap count
	ret
ReturnWrapCount	endp
			
WrapHintHandlers	VarDataHandler \
	<HINT_WRAP_AFTER_CHILD_COUNT_IF_VERTICAL_SCREEN, offset Geometry:ReturnWrapCount>,
	<HINT_WRAP_AFTER_CHILD_COUNT, offset Geometry:ReturnWrapCount>






COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlGetMenuCenter -- 
		MSG_SPEC_GET_MENU_CENTER for OLCtrlClass

DESCRIPTION:	Returns center of menu, ultimately.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_MENU_CENTER

		cx	- menu item moniker space, so far
		dx	- menu item accelerator space, so far
		bp 	- SpecGetMenuCenterFlags

RETURN:		cx, dx, bp  - possibly updated
		ax - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/20/92		Initial Version

------------------------------------------------------------------------------@

OLCtrlGetMenuCenter	method dynamic	OLCtrlClass, \
				MSG_SPEC_GET_MENU_CENTER

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	;
	; If we're allowing wrapping here, return the flag as such.
	; (Moved before processing children so they'll see the flag set.
	;  -cbh 1/18/93)
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	jz	10$
	or	bp, mask SGMCF_ALLOWING_WRAPPING
10$:
	;
	; Call all children with the message, propagating cx and dx to each.
	;
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	;DO NOT CHANGE THIS TO A GOTO!  We are passing stuff on the stack.
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack

	;
	; Now see if whether ourselves or one of our children is allowing 
	; wrapping.  If so, clear the one pass optimization flag.
	;
	test	bp, mask SGMCF_ALLOWING_WRAPPING
	jz	exit
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].VCI_geoAttrs, not mask VCGA_ONE_PASS_OPTIMIZATION
	or	ds:[di].VCI_geoDimensionAttrs, \
				mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
exit: 

	pop	di
	call	ThreadReturnStackSpace

	ret
OLCtrlGetMenuCenter	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlPositionBranch -- 
		MSG_VIS_POSITION_BRANCH for OLCtrlClass

DESCRIPTION:	Positions children.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_POSITION_BRANCH
		cx, dx  - origin for this object

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
	chris	4/30/92		Initial Version

------------------------------------------------------------------------------@

OLCtrlPositionBranch	method dynamic	OLCtrlClass, MSG_VIS_POSITION_BRANCH

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	call	PassSpacingArgsIfWeCan
	call	VisCompPosition

	call	OpenCtrlCalcMonikerOffsets	;recalc moniker offsets here,
						;   based on positioning.
	pop	di
	call	ThreadReturnStackSpace

	ret
OLCtrlPositionBranch	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookBinderRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save suggested size in vardata for future use

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= NotebookBinderClass object
		ds:di	= NotebookBinderClass instance data
		ds:bx	= NotebookBinderClass object (same as *ds:si)
		es 	= segment of NotebookBinderClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
RETURN:		cx	= width to use
		dx	= height to use
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/31/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

NotebookBinderRecalcSize	method dynamic NotebookBinderClass, 
					MSG_VIS_RECALC_SIZE
	push	cx
	mov	ax, TEMP_OL_CTRL_SUGGESTED_SIZE
	mov	cx, size word
	call	ObjVarAddData
	pop	cx

	mov	ds:[bx], cx

	mov	ax, MSG_VIS_RECALC_SIZE
	mov	di, offset NotebookBinderClass
	GOTO	ObjCallSuperNoLock

NotebookBinderRecalcSize	endm

endif	; NOTEBOOK_INTERACTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookBinderGetChildSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine child spacing

CALLED BY:	MSG_VIS_COMP_GET_CHILD_SPACING
PASS:		*ds:si	= NotebookBinderClass object
		ds:di	= NotebookBinderClass instance data
		ds:bx	= NotebookBinderClass object (same as *ds:si)
		es 	= segment of NotebookBinderClass
		ax	= message #
RETURN:		cx	= spacing between children
		dx	= spacing between lines of wrapping children
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/ 2/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

NotebookBinderGetChildSpacing	method dynamic NotebookBinderClass, 
					MSG_VIS_COMP_GET_CHILD_SPACING
	mov	cx, VIS_COMP_DEFAULT_SPACING
	mov	dx, cx

	mov	ax, HINT_CUSTOM_CHILD_SPACING
	call	ObjVarFindData
	jnc	done

	call	CustomChildSpacing
done:
	ret
NotebookBinderGetChildSpacing	endm

endif	; NOTEBOOK_INTERACTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookBinderGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine margins

CALLED BY:	MSG_VIS_COMP_GET_MARGINS
PASS:		*ds:si	= NotebookBinderClass object
		ds:di	= NotebookBinderClass instance data
		ds:bx	= NotebookBinderClass object (same as *ds:si)
		es 	= segment of NotebookBinderClass
		ax	= message #
RETURN:		ax	= left margin
		bp	= top margin
		cx	= right margin
		dx	= bottom margin
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/ 2/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

NotebookBinderGetMargins	method dynamic NotebookBinderClass, 
					MSG_VIS_COMP_GET_MARGINS

	; default margins are left=1, top=0, right=1, bottom=1 to account
	; for the border around the left, right, and bottom of binder

	mov	ax, 1
	mov	bp, 0
	mov	cx, ax
	mov	dx, ax
	ret
NotebookBinderGetMargins	endm

endif	; NOTEBOOK_INTERACTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookPageRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc size for notebook page

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= NotebookPageClass object
		ds:di	= NotebookPageClass instance data
		ds:bx	= NotebookPageClass object (same as *ds:si)
		es 	= segment of NotebookPageClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
RETURN:		cx	= width to use
		dx	= height to use
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

NotebookPageRecalcSize	method dynamic NotebookPageClass, 
					MSG_VIS_RECALC_SIZE
	push	dx
	mov	bx, cx			; bx = passed width

	call	NotebookPageGetParentSuggestedSize
	test	cx, mask RSA_CHOOSE_OWN_SIZE
	jnz	afterCalc

	; calculate page size based on parent's suggested size

	mov	bx, cx			; bx = parent width

	mov	ax, MSG_VIS_COMP_GET_MARGINS
	call	VisCallParent
	sub	bx, ax			; bx -= left margin
	sub	bx, cx			; bx -= right margin

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].NBPI_notebookRings
	mov	ax, MSG_VIS_RECALC_SIZE
	call	ObjCallInstanceNoLock
	pop	si

	sub	bx, cx			; bx -= rings width

	mov	ax, MSG_VIS_COMP_GET_CHILD_SPACING
	call	VisCallParent		; cx = child spacing
	shr	bx, 1			; bx = page width
	sub	bx, cx			; bx -= child spacing

afterCalc:
	mov	cx, bx
	pop	dx

	mov	ax, MSG_VIS_RECALC_SIZE
	mov	di, offset NotebookPageClass
	GOTO	ObjCallSuperNoLock

NotebookPageRecalcSize	endm

; Pass:		nothing
; Return:	cx = suggested width of visparent
; Destroyed:	ax, dx, di
;
NotebookPageGetParentSuggestedSize	proc	near
	uses	bx, si
	.enter

	mov	bx, offset Vis_offset
	mov	di, offset VI_link
	call	ObjSwapLockParent
	push	bx

	mov	cx, mask RSA_CHOOSE_OWN_SIZE	; assume no size hint

	mov	ax, TEMP_OL_CTRL_SUGGESTED_SIZE
	call	ObjVarFindData
	jnc	unlock

	mov	cx, ds:[bx]			; use suggested size
unlock:
	pop	bx
	call	ObjSwapUnlock

	.leave
	ret
NotebookPageGetParentSuggestedSize	endp

endif	; NOTEBOOK_INTERACTION

Geometry ends
