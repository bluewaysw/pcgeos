COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		openGadgetArea.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLGadgetAreaClass	gadget area class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chrisp	5/91		Initial version

DESCRIPTION:

	$Id: copenGadgetArea.asm,v 1.44 97/02/22 05:27:59 brianc Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLGadgetAreaClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends



Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaSpecBuild -- 
		MSG_SPEC_BUILD for OLGadgetAreaClass

DESCRIPTION:	Handles spec build.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD
		bp	- SpecBuild stuff

RETURN:		nothing

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/91		Initial version

------------------------------------------------------------------------------@

OLGadgetAreaSpecBuild	method OLGadgetAreaClass, MSG_SPEC_BUILD
			
	call	VisCheckIfSpecBuilt
	LONG	jc	exit

	call	VisSpecBuildSetEnabledState	;set enabled state correctly
	
	;add ourself to the visual world

	push	si
	mov	cx,ds:[LMBH_handle]		;cx:dx = ourself
	mov	dx,si

	call	Build_DerefVisSpecDI	;ds:di = VisSpec instance data
	
	mov	bx, ds:[di].OLCI_visParent.handle	;bx:si = vis parent
	mov	si, ds:[di].OLCI_visParent.chunk

	mov	bp,CCO_LAST
	mov	ax,MSG_VIS_ADD_CHILD
	call	Build_ObjMessageCallFixupDS
	pop	si
	
	;
	; Steal all the geometry hints the primary thought it had.  We will
	; actually see them in action here.
	;
	push	si
	call	VisSwapLockParent

if _ODIE
	;
	; add top margin for dialogs (part one)
	;
	push	es, di
	mov	di, segment OLDialogWinClass
	mov	es, di
	mov	di, offset OLDialogWinClass
	call	ObjIsObjectInClass		; carry set if dialog
	pop	es, di
	pushf
endif

	;
	; Set ah if HINT_LEFT_JUSTIFY_MONIKERS, al if HINT_CENTER_CHILDREN...
	; -4/28/93 cbh
	;
	push	bx
	mov	ax, HINT_CENTER_CHILDREN_ON_MONIKERS
	call	ObjVarFindData
	pushf					;save result
	mov	ax, HINT_LEFT_JUSTIFY_MONIKERS
	call	ObjVarFindData			
	mov	ax, 0
	jnc	10$
	dec	ah
10$:	
	popf
	jnc	20$
	dec	al
20$:
	pop	bx

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	cx, {word} ds:[di].VCI_geoAttrs
	mov	dl, ds:[di].VI_geoAttrs
	call	ObjSwapUnlock
if _ODIE
	;
	; add top margin for dialogs (part two)
	;
	popf
	pop	si
	pushf
else
	pop	si
endif

	;
	; Store hints based on ax, set above.
	;
	push	cx
	tst	al
	jz	30$
	push	ax
	clr	cx
	mov	ax, HINT_CENTER_CHILDREN_ON_MONIKERS
	call	ObjVarAddData
	pop	ax
30$:
	tst	ah
	jz	40$
	clr	cx
	mov	ax, HINT_LEFT_JUSTIFY_MONIKERS
	call	ObjVarAddData
40$:
	pop	cx

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
if _ODIE
	;
	; add top margin for dialogs (part three)
	;
	popf
	jnc	notDialog
	ornf	ds:[di].OLGAI_flags, mask OLGAF_ADD_TOP_MARGIN
notDialog:
endif
	and	cx, not mask VCGA_HAS_MINIMUM_SIZE   ;clear flags that aren't
						     ;   applicable
	and	dl, mask VGA_ALWAYS_RECALC_SIZE	

	;
	; Let's always have expand-to-fit set in the gadget area, except when
	; it wants to be wrapping, in which case expand-to-fit causes problems.
	; (Nah, copying the flags from the parent should be more than 
	;  sufficient.  This code blows any chance we have of making windows
	;  not be expand-to-fit.  -cbh 3/12/93)
	;
;	or	ch, mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
;		    mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT

	test	cl, mask VCGA_ALLOW_CHILDREN_TO_WRAP
	jz	storeGeoAttrs
	test	cl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	removeExpandWidth
	and	ch, not mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	jmp	short storeGeoAttrs

removeExpandWidth:
	and	ch, not mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT

storeGeoAttrs:

	mov	{word} ds:[di].VCI_geoAttrs, cx	
	mov	ds:[di].VI_geoAttrs, dl
	;
	; The primary should definitely be vertical, no matter what the rest
	; of the world thinks.  We'll also nuke a bunch of hints that are
	; no good for the primary.  (Rudy: changed to always center the
	; children, on the assumption that the gadget area will usually
	; fill up space.  11/29/94 cbh)    (Nuked Rudy stuff. 3/12/95 cbh)
	;
if _RUDY
	clr	cx
	mov	dx, mask VCGA_ORIENT_CHILDREN_VERTICALLY or \
		    mask VCGA_ALLOW_CHILDREN_TO_WRAP or \
		    mask VCGA_ONE_PASS_OPTIMIZATION or \
		    mask VCGA_CUSTOM_MANAGE_CHILDREN or \
		    mask VCGA_WRAP_AFTER_CHILD_COUNT or \
		    (mask VCGDA_WIDTH_JUSTIFICATION shl 8) or \
		    (mask VCGDA_DIVIDE_WIDTH_EQUALLY shl 8) or \
		    (mask VCGDA_DIVIDE_HEIGHT_EQUALLY shl 8)
else
	mov	cx, mask VCGA_ORIENT_CHILDREN_VERTICALLY 
	mov	dx, mask VCGA_ALLOW_CHILDREN_TO_WRAP or \
		    mask VCGA_ONE_PASS_OPTIMIZATION or \
		    mask VCGA_CUSTOM_MANAGE_CHILDREN or \
		    mask VCGA_WRAP_AFTER_CHILD_COUNT or \
		    (mask VCGDA_HEIGHT_JUSTIFICATION shl 8) or \
		    (mask VCGDA_WIDTH_JUSTIFICATION shl 8) or \
		    (mask VCGDA_DIVIDE_WIDTH_EQUALLY shl 8) or \
		    (mask VCGDA_DIVIDE_HEIGHT_EQUALLY shl 8)
endif

	mov	ax, MSG_VIS_COMP_SET_GEO_ATTRS
	call	VisCallParent			;

	;Check for OLBF_TOOLBOX set it parent.  Set ourselves if so.

	call	OpenGetParentBuildFlagsIfCtrl	
	and	cx, mask OLBF_TOOLBOX or mask OLBF_DELAYED_MODE
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLCI_buildFlags, cx
exit:
	ret
	
OLGadgetAreaSpecBuild	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaNukeMargins -- 
		MSG_SPEC_VUP_NUKE_GADGET_AREA_MARGINS for OLGadgetAreaClass

DESCRIPTION:	Nukes gadget area margins, by setting all the disp control
		flags.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VUP_NUKE_GADGET_AREA_MARGINS

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
	chris	3/12/93         	Initial Version

------------------------------------------------------------------------------@

OLGadgetAreaNukeMargins	method dynamic	OLGadgetAreaClass, \
				MSG_SPEC_VUP_NUKE_GADGET_AREA_MARGINS

	;
	; Force no margins.
	;
	or	ds:[di].OLGAI_flags, mask OLGAF_NO_MARGINS
	ret
OLGadgetAreaNukeMargins	endm

			

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLGadgetAreaAddLeftMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add left margin to gadget area for child

CALLED BY:	MSG_SPEC_VUP_ADD_GADGET_AREA_LEFT_MARGIN
PASS:		*ds:si	= OLGadgetAreaClass object
		ds:di	= OLGadgetAreaClass instance data
		ds:bx	= OLGadgetAreaClass object (same as *ds:si)
		es 	= segment of OLGadgetAreaClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if INDENT_BOXED_CHILDREN
OLGadgetAreaAddLeftMargin	method dynamic OLGadgetAreaClass, 
					MSG_SPEC_VUP_ADD_GADGET_AREA_LEFT_MARGIN
	ornf	ds:[di].OLGAI_flags, mask OLGAF_ADD_LEFT_MARGIN
	ret
OLGadgetAreaAddLeftMargin	endm
endif

Build	ends
	
Geometry	segment	resource





COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLGadgetAreaClass

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

OLGadgetAreaRecalcSize	method dynamic OLGadgetAreaClass, MSG_VIS_RECALC_SIZE
	call	GadgetAreaPassMarginInfo
	call	OpenRecalcCtrlSize
	ret
OLGadgetAreaRecalcSize	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaVisPositionBranch -- 
		MSG_VIS_POSITION_BRANCH for OLGadgetAreaClass

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

OLGadgetAreaVisPositionBranch	method dynamic	OLGadgetAreaClass, \
				MSG_VIS_POSITION_BRANCH

	call	GadgetAreaPassMarginInfo	
	call	VisCompPosition
	ret
OLGadgetAreaVisPositionBranch	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	GadgetAreaPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLGadgetAreaRecalcSize, OLGadgetAreaPositionBranch

PASS:		*ds:si -- GadgetArea bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

GadgetAreaPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OLGadgetAreaGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OLGadgetAreaGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
GadgetAreaPassMarginInfo	endp

		


COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaGetMargins -- 
		MSG_VIS_COMP_GET_MARGINS for OLGadgetAreaClass

DESCRIPTION:	Returns margins.  The whole idea of this object is it allows
		there to be gadget margins in the primary.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_COMP_GET_MARGINS

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/91		Initial version

------------------------------------------------------------------------------@

OLGadgetAreaGetMargins	method OLGadgetAreaClass, \
				MSG_VIS_COMP_GET_MARGINS
	;
	; Any time the geometry is invalid at our level or below us, we'll
	; recalculate our margin flags.  This (hopefully) covers the possibility
	; of children being added somewhere below us which can affect these
	; flags (which they can)...
	;
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID or \
				     mask VOF_GEO_UPDATE_PATH
	jz	everythingCool
	call	RecalcGadgetAreaFlags
everythingCool:

	clr	ax				;assume no margins
	mov	bp, ax
	mov	cx, ax
	mov	dx, ax
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	tst	ds:[di].VCI_comp.CP_firstChild.chunk	
	jz	checkCGA			;no children, no margins.
	mov	ax, GADGET_AREA_MARGINS		;we'll pull this out later
	mov	bp, ax
	mov	cx, ax
	mov	dx, ax

checkCGA:	
if (not _JEDIMOTIF)		; none of this for JEDI
	;
	; In CGA, the top and bottom margins need to be smaller in general.
	; CHECK BW FOR CUA LOOK
	;
	call	OpenCheckIfCGA			;keep reasonable in CGA
	jnc	checkNarrow
	mov	bp, 2				;(the net affect is a one-pixel
	mov	dx, bp				; margin, since things overlap
	inc	cx				; the border by one pixel.)
	inc	ax				;(also account for overlap
						;  in left and right)
checkNarrow:
	call	OpenCheckIfNarrow		;keep reasonable on narrow
	jnc	checkDC
	mov	cx, 2				;(the net affect is a one-pixel
	mov	ax, cx				; margin, since things overlap
checkDC:

	;
	; Now we'll do stuff based on the display control.  We'll be zeroing
	; certain margins if the display control touches that edge, but to make
	; it work in both orientations, We'll swap margins before and after
	; if the gadget control is horizontal, and pretend its vertical.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	pushf
	jnz	checkAnyDC		;vertical, spacing is in correct regs
	xchg	ax, bp			;swap registers 
	xchg	cx, dx

checkAnyDC:
	;
	; If there's a display control, zero the left and right margins.
	; (Overriden by OLGAF_NO_MARGINS)
	;
	test	ds:[di].OLGAI_flags, mask OLGAF_HAS_DISP_CTRL or \
				     mask OLGAF_NO_MARGINS
	jz	checkDCOnTop
	clr	ax		
	mov	cx, ax

checkDCOnTop:
	;
	; If the display control is on top, we'll zero the top margin.
	; (Overriden by OLGAF_NO_MARGINS)
	;
	test	ds:[di].OLGAI_flags, mask OLGAF_DISP_CTRL_FIRST or \
				     mask OLGAF_NO_MARGINS
	jz	checkDCOnBottom
	clr	bp

checkDCOnBottom:
	;
	; If the display control is on the bottom, we'll zero the bottom margin.
	; (Overriden by OLGAF_NO_MARGINS)
	;
	test	ds:[di].OLGAI_flags, mask OLGAF_DISP_CTRL_LAST or \
				     mask OLGAF_NO_MARGINS
	jz	endSwap
	clr	dx

endSwap:
	;
	; Swap the registers back if needed.
	; 
	popf
	jnz	30$			;vertical, spacing is in correct regs
	xchg	ax, bp			;swap registers back
	xchg	cx, dx
30$:

if BUBBLE_DIALOGS and (not (_ODIE or _DUI))
	;
	; If in a bubble dialog, add some top and left margin.     It's better
	; to add the top margin here rather than in OLWin class.
	;
	push	si
	call	VisFindParent
	tst	si
	jz	noBubble
	mov	di, segment OLDialogWinClass
	mov	es, di
	mov	di, offset OLDialogWinClass
	call	ObjIsObjectInClass
	jnc	noBubble
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPWI_flags, mask OLPWF_IS_POPUP
	jz	noBubble
	add	ax, BUBBLE_LEFT_EXTRA_MARGIN
	add	bp, BUBBLE_TOP_EXTRA_MARGIN
	;
	; Added right margin for bubbles when I made bubbles
	; SHRINK_DESIRED_SIZE_TO_FIT_IN_PARENT so there is some space
	; between the contents and the reply bar.  --JimG 7/27/95
	;
	add	cx, BUBBLE_RIGHT_EXTRA_MARGIN
noBubble:
	pop	si
endif	

if INDENT_BOXED_CHILDREN
	;
	; add extra left margin, if desired
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLGAI_flags, mask OLGAF_PREVENT_LEFT_MARGIN
	jnz	noLeftMargin			; prevent left margin
	test	ds:[di].OLGAI_flags, mask OLGAF_ADD_LEFT_MARGIN
	jz	noLeftMargin			; not adding left margin
	add	ax, GADGET_AREA_LEFT_MARGIN
noLeftMargin:
endif

if _ODIE
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLGAI_flags, mask OLGAF_ADD_TOP_MARGIN
	jz	noTopMargin
	add	bp, GADGET_AREA_TOP_MARGIN
noTopMargin:
endif

if _DUI
	;
	; if parent window has HINT_CUSTOM_EXTRA_MARGINS, use it
	;
	push	si
	call	VisSwapLockParent
	jnc	noParent
	push	bx
	push	ax				; save left margin
	mov	ax, HINT_CUSTOM_EXTRA_MARGINS
	call	ObjVarFindData
	pop	ax				; restore left margin
	jnc	noCustomMargin
	add	ax, ds:[bx].R_left
	add	cx, ds:[bx].R_right
	add	bp, ds:[bx].R_top
	add	dx, ds:[bx].R_bottom
noCustomMargin:
	pop	bx
	call	ObjSwapUnlock
noParent:
	pop	si
endif

exit:
endif		; (not _JEDIMOTIF)
	ret
OLGadgetAreaGetMargins	endm
			


COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaGetSpacing -- 
		MSG_VIS_COMP_GET_CHILD_SPACING for OLGadgetAreaClass

DESCRIPTION:	Returns spacing.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_COMP_GET_CHILD_SPACING

RETURN:		cx	- child spacing
		dx	- wrap spacing

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/18/91		Initial version

------------------------------------------------------------------------------@

OLGadgetAreaGetSpacing	method OLGadgetAreaClass, \
				MSG_VIS_COMP_GET_CHILD_SPACING
				
CUA <	mov	cx, CUA_WIN_CHILD_SPACING	;else set regular spacing   >
MO  <	mov	cx, MO_WIN_CHILD_SPACING	;		            >
PMAN <	mov	cx, MO_WIN_CHILD_SPACING	;		            >
CUA <	mov	dx, CUA_WIN_CHILD_WRAP_SPACING				    >
MO <	mov	dx, MO_WIN_CHILD_WRAP_SPACING				    >
PMAN <	mov	dx, MO_WIN_CHILD_WRAP_SPACING				    >

	push	si
	call	VisFindParent
	call	OpenCtrlCheckCustomSpacing	;use custom spacing if there
	pop	si
	call	OpenCtrlCheckCGASpacing		;use CGA spacing if needed
	ret
OLGadgetAreaGetSpacing	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		RecalcGadgetAreaFlags

DESCRIPTION:	Recalculates gadget area flags, based on the existence of 
	 	display controls (or maybe views) below us, and where they
		are (first, last, neither).

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_ADD_CHILD
		cx, dx, bp - usual stuff for this message, unimportant here

RETURN:		ax, cx, dx, bp - usual stuff for this message, unimportant here

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 7/92		Initial Version

------------------------------------------------------------------------------@

RecalcGadgetAreaFlags	proc	near
	;
	; Done with the default stuff, we'll now cycle through the children
	; to see a) if the first child is a doc control, and b) if the last
	; child is a doc control.  cl holds GadgetAreaFlags; ch holds
	; a passed first child flag.
	;
	clr	cx				;pass no flags to start

	clr	bx				;initial child (first
	push	bx				;    child of
	push	bx				;    composite)
	mov	bx,offset VI_link		;pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS
	push	bx				;pass callback routine (seg)
	mov	bx,offset CheckForDispControls
	push	bx				;pass callback routine (off)
						;  beforehand..  -cbh 2/ 3/92
	mov	bx,offset Vis_offset		;pass offset to master part
	mov	di,offset VCI_comp		;pass offset to composite
	call	ObjCompProcessChildren

	;
	; Set flags based on what is returned.
	; 
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLGAI_flags, not (mask OLGAF_HAS_DISP_CTRL or \
				          mask OLGAF_DISP_CTRL_FIRST or \
				          mask OLGAF_DISP_CTRL_LAST)
	ornf	ds:[di].OLGAI_flags, cl
	ret
RecalcGadgetAreaFlags	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckForDispControls

SYNOPSIS:	Checks for display controls under the gadget area.  Also checks
		for views, and does similar things.  

CALLED BY:	OLGadgetAreaAddChild (ObjCompProcessChildren)

PASS:		*ds:si  -- child
		*es:di  -- parent

		cl	-- GadgetAreaFlags
		ch	-- past first child flag

RETURN:		cl, ch	-- possibly updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 7/92		Initial version
	Chris	3/10/93		Now checks for menu bars as well.

------------------------------------------------------------------------------@

CheckForDispControls	proc	far
	mov	ax, segment OLDisplayGroupClass
	mov	es, ax
	mov	di, offset OLDisplayGroupClass
	call	ObjIsObjectInClass
	jc	foundDispCtrl			;display control, done.

	mov	ax, segment OLMenuBarClass
	mov	es, ax
	mov	di, offset OLMenuBarClass
	call	ObjIsObjectInClass
	jc	foundDispCtrl			;menu bar, done.

	;
	; Also look for views in CGA.
	; CHECK BW FOR CUA LOOK
	;
	call	OpenCheckIfCGA			;only on CGA
	jnc	clearFirstFlagAndContinue
	mov	ax, segment OLPaneClass
	mov	es, ax
	mov	di, offset OLPaneClass
	call	ObjIsObjectInClass
	jnc	clearFirstFlagAndContinue	;not a pane, continue

	mov	di, ds:[si]			;leave generic panes alone!
	add	di, ds:[di].Gen_offset		;  -cbh 12/ 3/92
	test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS
	jnz	clearFirstFlagAndContinue

foundDispCtrl:
	or	cl, mask OLGAF_HAS_DISP_CTRL	;mark that we have one
	tst	ch				;see if first child
	jnz	notFirstChild			;no, branch
	or	cl, mask OLGAF_DISP_CTRL_FIRST 
notFirstChild:
	;
	; Always assume the display control is last.  If there are any non-
	; empty objects that follow it, we will clear the last flag.
	; -cbh 12/19/92
	;
	or	cl, mask OLGAF_DISP_CTRL_LAST   ;else mark as last
	jmp	short exit

clearFirstFlagAndContinue:
	;
	; We'll clear the first-child flag, unless this is some kind of stupid
	; empty composite.
	; 
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	normalObject
	tst	ds:[di].VCI_comp.CP_firstChild.handle
	jz	continue
	
normalObject:
	dec	ch				;not first child anymore

clearLastFlagIfNotEmpty:
	;
	; Here is where we clear the DISP_CTRL_LAST flag if there are any
	; non-empty children after the initial display control.  (I need to
	; get this right on the first try to impress my mom.) -cbh 12/19/92
	;
	test	cl, mask OLGAF_HAS_DISP_CTRL	;have we already found a 
						;  display control?
	jz	continue			;nope, don't bother with this
	
	mov	di, ds:[si]			;empty composite, don't bother
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	clearLastFlag
	tst	ds:[di].VCI_comp.CP_firstChild.handle
	jz	continue			

clearLastFlag:
	and	cl, not mask OLGAF_DISP_CTRL_LAST	;clear last flag

continue:
	clc					;continue
exit:
	ret
CheckForDispControls	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaCheckIfNeedsMargins -- 
		MSG_SPEC_CHECK_IF_NEEDS_MARGINS for OLGadgetAreaClass

DESCRIPTION:	Returns margins if there needed for the children.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CHECK_IF_NEEDS_MARGINS

RETURN:		carry set if margins needed, with:
			ax -- appropriate margin amoung
		cx, dx, bp - preserved

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 7/92		Initial Version

------------------------------------------------------------------------------@

OLGadgetAreaCheckIfNeedsMargins	method dynamic	OLGadgetAreaClass, \
				MSG_SPEC_CHECK_IF_NEEDS_MARGINS

if _JEDIMOTIF
	;
	; no special margins for JEDI
	;
	clc
else
	test	ds:[di].OLGAI_flags, mask OLGAF_HAS_DISP_CTRL
	jz	exit				;nothing special exit, C=0
	stc					;else return carry set
	mov	ax, GADGET_AREA_MARGINS		;and margin to use
exit:
endif
	ret
OLGadgetAreaCheckIfNeedsMargins	endm


Geometry	ends

CommonFunctional	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetAreaDraw -- 
		MSG_VIS_DRAW for OLGadgetAreaClass

DESCRIPTION:	Draws.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW
		bp 	- gstate
		cl - DrawFlags:  DF_EXPOSED set if updating

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
	chris	12/ 1/92         	Initial Version

------------------------------------------------------------------------------@

if _MOTIF and (not _ODIE)

OLGadgetAreaDraw	method dynamic	OLGadgetAreaClass, \
				MSG_VIS_DRAW

	;
	; Don't draw a frame if we're not expanding-to-fit.  We can't set 
	; expand-to-fit if the window isn't expand-to-fit, but there are still
	; situations (due to a window's minimum width) where this will get us
	; in trouble trying to draw a frame out to the edge of the window.
	; -cbh 3/12/93
	;
	test	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
	jz	callSuper
	test	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	jz	callSuper

	call	OpenCheckIfBW
	jc	callSuper

	mov	di, bp	
	push	ax, cx, bp, es
	call	OpenSetInsetRectColors		;get inset rect colors
	xchg	ax, bp
	xchg	al, ah				;make outset rect
	xchg	ax, bp
	call	VisGetBounds			;get normal bounds
	call	OpenDrawRect
	pop	ax, cx, bp, es

callSuper:
	mov	di, offset OLGadgetAreaClass
	mov	ax, MSG_VIS_DRAW
	GOTO	ObjCallSuperNoLock	

OLGadgetAreaDraw	endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLGadgetAreaSetFlags -- 
		MSG_SPEC_GADGET_AREA_SET_FLAGS for OLGadgetAreaClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Sets flags.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GADGET_AREA_SET_FLAGS
		cl	- flags to set
		ch 	- flags to clear

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
	chris	7/26/94		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY		;currently only needed here
	
OLGadgetAreaSetFlags	method dynamic	OLGadgetAreaClass, \
				MSG_SPEC_GADGET_AREA_SET_FLAGS
	.enter
	or	ds:[di].OLGAI_flags, cl
	not	ch
	and	ds:[di].OLGAI_flags, ch
	.leave
	ret
OLGadgetAreaSetFlags	endm

endif

CommonFunctional	ends

