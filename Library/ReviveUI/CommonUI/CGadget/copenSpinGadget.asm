COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989-1995.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/Open (gadgets)
FILE:		copenSpinGadget.asm

ROUTINES:
	Name			Description
	----			-----------
    INT OLSpinGadgetMakeDefaultFocus 
				Make the default focus.

    INT SetupSpinDesiredSize    Calculates a desired size for the spin
				gadget.

    INT CreateSpinScrollbar     Creates the scrollbar for the spin gadget.

    INT GadgetBuild_DerefVisSpecDI 
				Creates the scrollbar for the spin gadget.

    INT GadgetBuild_DerefGenDI  Creates the scrollbar for the spin gadget.

    MTD MSG_SPEC_UNBUILD_BRANCH Unbuilds the spin gadget.

    MTD MSG_VIS_GET_CENTER      Gets the object's center.

    INT SpinGadgetPassMarginInfo 
				Passes margin info for OpenRecalcCtrlSize.

    INT AddInSpaceForMinMaxMonikers 
				Adds in any needed margins to allow min-max
				monikers to exist.

    INT GetMinMaxMoniker        Returns a min or max moniker to either draw
				or size up.

    INT GetMinMaxMonikerSize    Returns size of a min or max moniker.

    INT DrawMinMaxMoniker       Draws a min or max moniker.

    INT GetSpinTextSize         Returns size of spin text area.

    MTD MSG_VIS_COMP_GET_MINIMUM_SIZE 
				Returns minimum size.

    INT CheckIfLargeHeight      Checks to see if we need a large height for
				pen mode.

    INT PositionSpinText        Positions the spin text object.

    INT ResizeSpinText          Sizes the spin text object.

    MTD MSG_SPEC_SPIN_GET_ATTRS Returns attributes.

    INT ClearBackgroundIfInTitleBar 
				If this gadget is in the title bar, clear
				out background to get rid of black line
				through moniker.

    INT OLSpinGadgetDrawMinMaxMonikers 
				Draws minimum and maximum monikers.

    INT OLSpinGadgetDrawContentsLow 
				Draws contents.

    INT ClipSpinTextIfNeeded    Clips text if the text is larger than our
				area.

    INT SpinSetupMoniker        Sets up arguments to VisDrawMoniker.  We
				will center the moniker vertically in
				motif, and bottom justify in open look.

    INT ClearSpinDisplay        Whites out area where moniker is drawn.

    INT ClearSpinDisplay        Whites out area where moniker is drawn.

    INT ClearSpinDisplay        Whites out area where moniker is drawn.

    INT SGC_DerefVisSpecDI      Whites out area where moniker is drawn.

    INT SGC_DerefGenDI          Whites out area where moniker is drawn.

    INT SGC_ObjCallInstanceNoLock 
				Whites out area where moniker is drawn.

    MTD MSG_SPEC_SPIN_DOWN_PAGE Handles a down page press in a slider.

    MTD MSG_SPEC_SPIN_UP_PAGE   Handles a press in a slider`s page up area.

    INT GetSpinAreaSize         Returns a size for the spin area.

    MTD MSG_SPEC_SPIN_SET_ITEM  Sets a new item to be drawn.  If we're a
				text spin gadget, stores a new text chunk.

    INT GiveTextFocusNow        Gives the text object the focus, if the
				range object still has the focus.

    MTD MSG_META_PRE_PASSIVE_BUTTON 
				Handler for Passive Button events (see
				CTTFM description, top of cwinClass.asm
				file.)

				(We know that REFM mechanism does not rely
				on this procedure, because REFM does not
				request a pre-passive grab.)

    MTD MSG_META_PRE_PASSIVE_START_SELECT 
				Handles pre-passive start selects.  We'll
				take this moment to

    MTD MSG_META_MUP_ALTER_FTVMC_EXCL 
				Messes with exclusives.

    INT CreateSpinText          Creates a vis text object for the spin
				gadget, resizes it, positions it, opens it,
				grabs the focus.

    INT CompareWithCurrentFocus Checks to see if current focus exclusive

    MTD MSG_GET_FIRST_MKR_POS   Returns the start of the moniker.

    MTD MSG_SPEC_NAVIGATION_QUERY 
				This method is used to implement the
				keyboard navigation within-a-window
				mechanism. See method declaration for full
				details.

    INT GetTextPosition         Returns position text should go.

    INT GetTextPosition         Returns position text should go.

    INT CheckIfFloatingText     Checks whether text floats to match slider
				thumb.

    MTD MSG_OL_SPIN_CHECK_FLOATING_TEXT 
				check if slider/gauge (floating text)

    INT PositionFloatingText    Positions floating text to match scrollbar
				thumb.

    INT GetSpinTextWidth        Returns width of spin text.

    INT KeepFloatingTextInBounds 
				Keeps floating text position reasonable
				(within appropriate scrollbar bounds is
				what we'll look for.)

    INT AdjustRectToEntireRange Do horrible things to ensure the space
				above/left of the slider is cleared, since
				the text can move anywhere. May do a
				GrFillRect to do part of the clearing, as
				it has to do two parts now.

    MTD MSG_SPEC_SET_NOT_USABLE Handles being set not usable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/89		Initial version

DESCRIPTION:

	$Id: copenSpinGadget.asm,v 1.173 96/12/03 00:25:37 brianc Exp $


------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLSpinGadgetClass mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;---------------------------------------------------

GadgetBuild segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSpinGadgetInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	<description here>

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_INITIALIZE

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLSpinGadgetInitialize	method OLSpinGadgetClass, MSG_META_INITIALIZE

	call	OLCtrlInitialize	; do superclass stuff, as well

	; VTF_IS_INPUT_NODE is needed only so that we will get
	; MSG_META_MUP_ALTER_FTVMC_EXCL  -- if the need for this handler goes
	; away, so can this bit. -- Doug 2/5/93
	;
	call	GadgetBuild_DerefVisSpecDI
	ornf	ds:[di].VI_typeFlags, mask VTF_IS_INPUT_NODE
	and	ds:[di].VI_geoAttrs, not mask VGA_USE_VIS_CENTER	
	ret

OLSpinGadgetInitialize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetSpecBuild -- 
		MSG_SPEC_BUILD for OLSpinGadgetClass

DESCRIPTION:	Visibly builds a spin gadget.  Tacks on a scrollbar as the
		increment/decrement device.

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
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@
	
OLSpinGadgetSpecBuild	method OLSpinGadgetClass, MSG_SPEC_BUILD
	call	VisCheckIfSpecBuilt		;don't repeat if built
	LONG	jc	exit
	
	push	bp
	mov	di, offset OLCtrlClass
	call	ObjCallSuperNoLock		;call superclass spec build
						;  (avoid OLCtrl class here!)


	call	OLSpinGadgetScanGeometryHints

	;
	; If read-only, set the CANT_EDIT_TEXT and NO_UP_DOWN_ARROWS flags.
	; -cbh 12/ 3/92
	;
	call	GadgetBuild_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	5$

	mov	al, mask OLSGA_CANT_EDIT_TEXT
	call	GadgetBuild_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jnz	3$				;slider, always create bar
	or	al, mask OLSGA_NO_UP_DOWN_ARROWS
3$:
	or	ds:[di].OLSGI_attrs, al
5$:
	
	;
	; Store default width and height for the spin gadget in case
	; no desired-size hint is passed (or no subclass has already set
	; something).
	;

if _JEDIMOTIF
	;
	; in JEDI sliders, HINT_VALUE_NO_DIGITIAL_DISPLAY is the default,
	; so we look for HINT_VALUE_DIGITAL_DISPLAY
	;
	call	GadgetBuild_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
	mov	ax, HINT_VALUE_DIGITAL_DISPLAY
	call	ObjVarFindData
	mov	ax, 0				; do not use clr
	mov	cx, ax				; do not use clr
	jnc	haveDesiredWidthAndHeight	; not found, no desired size
notSlider:
endif

if SLIDER_INCLUDES_VALUES
	;
	; always no digital display for sliders, unless we're a spinner
	;
	clr	ax, cx
	call	GadgetBuild_DerefVisSpecDI
if SPINNER_GEN_VALUE
	test	ds:[di].OLSGI_attrs, mask OLSGA_SPINNER
	jnz	computeSize
endif
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jnz	haveDesiredWidthAndHeight
endif

	;
	; check to see if HINT_VALUE_NO_DIGITAL_DISPLAY is set, if it is
	; then we have no desired size
	;
	mov	ax, HINT_VALUE_NO_DIGITAL_DISPLAY
	call	ObjVarFindData			; carry set if found
	mov	ax, 0				; do not use clr
	mov	cx, ax				; do not use clr
	jc	haveDesiredWidthAndHeight

computeSize::
; Just do it directly. -- Doug 2/5/93
;	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
; 	call	GadgetBuild_ObjCallInstanceNoLock	;get a gstate to work with
; {
	call	ViewCreateCalcGState
; }
	mov	di, bp				;gstate in di
	mov	ax, OL_SPIN_DEFAULT_DESIRED_WIDTH
	call	VisConvertSpecVisSize		;calc a real width in ax
	mov	cx, ax				;keep in cx
if _DUI
	;
	; make just big enough for non-twisted scrollers (matches code in
	; OLScrollbarRecalcSize
	;
	push	ds
	mov	ax, segment idata
	mov	ds, ax
	mov	ax, ds:[olArrowSize]
	pop	ds
	add	ax, 3				; add fudge factor
	shl	ax, 1				; two arrows
	inc	ax				; for comparison
else
	mov	ax, OL_SPIN_DEFAULT_DESIRED_HEIGHT
	call	VisConvertSpecVisSize		;calc a real height in ax
endif
	call	GrDestroyState

haveDesiredWidthAndHeight:

	call	GadgetBuild_DerefVisSpecDI
	tst	ds:[di].OLSGI_textWidth		;any desired width already?
	jnz	8$				;yes, branch
	mov	ds:[di].OLSGI_textWidth, cx
8$:
	tst	ds:[di].OLSGI_desWidth		;any desired width already?
	jnz	10$				;yes, branch
	mov	ds:[di].OLSGI_desWidth, cx
10$:
	tst	ds:[di].OLSGI_desHeight		;any desired height already?
	jnz	20$

if	1
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jnz	15$				;slider, don't squish!
	call	OpenCheckIfCGA
	jnc	15$
	dec	ax
15$:
endif
if SPINNER_GEN_VALUE
	;
	; add margin above and below text for spinner
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SPINNER
	jz	notSpinner
	add	ax, SPINNER_TEXT_MARGIN*2
notSpinner:
endif
	mov	ds:[di].OLSGI_desHeight, ax
20$:
	;
	; Scan hints to get desired height.
	;
	segmov	es, cs				;setup es:di to be ptr to
						;	hint handler table
	mov	di, offset cs:SpinHintHandlers
	mov	ax, length (cs:SpinHintHandlers)
	call	ObjVarScanData
	
	;
	; Set a couple of optimization flags for the geometry manager.  The
	; scrolling list only needs to get called when its geometry is invalid.
	; (Only if not in a toolbox.  We'll expand to fit in that case. -cb
	; 6/25/92)  (Also not if centering-on-moniker.  We want to preserve
	; the ALWAYS_RECALC_SIZE set by the OLCtrl! -cbh 7/20/92)
	; (Nuke this for the moment -- I think there's a problem with putting
	; this under a vertically centered composite now.  -cbh 3/10/93)
	; (Don't nuke NOTIFY_GEOMETRY_VALID bit!  -cbh 6/14/93)
	;
	call	GadgetBuild_DerefVisSpecDI
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	25$
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jnz	25$
	test	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
	jnz	25$

	and	ds:[di].VI_geoAttrs, mask VGA_NOTIFY_GEOMETRY_VALID
	or	ds:[di].VI_geoAttrs, mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
25$:
	;
	; If doing the twisted scrollbar, we must expand height in order to
	; tell the scrollbar to stay small.   Also, we will center horizontally.

	; (In CGA we won't center, because that is causing problems, with the
	; moniker actually a pixel taller than the spin gadget box, and the
	; geometry rounds up, essentially bottom justifying the thing. 12/ 3/92)
	; (I don't know about this.  Let's see if we can undo this. -2/26/93)
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jnz	27$

	or	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT

;	call	OpenCheckIfCGA
;	jc	27$
	or	ds:[di].VCI_geoDimensionAttrs, \
			HJ_CENTER_CHILDREN_VERTICALLY shl offset \
				VCGDA_HEIGHT_JUSTIFICATION
27$:
if _RUDY
	;
	; Avoid drawing selection shadows too far.
	;
	or	ds:[di].OLCI_rudyFlags, mask OLCRF_CLEAR_MONIKER_SPACE_ONLY
endif
	;
	; Always have a minimum size.
	;
	or	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	;
	; Create a scrollbar as a child of the spin gadget.
	;
	pop	bp
	
	; Make sure the fully-enabled bit is clear if this object is not
	; enabled.
	
	test 	ds:[di].OLSGI_attrs, mask OLSGA_NO_UP_DOWN_ARROWS
	jnz	50$				;Don't want arrows, we're done

	call	GadgetBuild_DerefGenDI
	test	ds:[di].GI_states, mask GS_ENABLED
	jnz	30$			; This object's enabled, branch
	and	bp, not mask SBF_VIS_PARENT_FULLY_ENABLED
30$:	
	call	CreateSpinScrollbar		
40$:
	call	SetupSpinDesiredSize		;set up desired size
50$:

	call	GadgetBuild_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT
	jnz	noKbd

;
;	If we can edit text, allow the floating kbd to come up
;
	call	CheckIfKeyboardRequired
	jnc	noKbd
	
if _DUI
	;
	; set keyboard type before bringing it up
	;
	call	SetKeyboardType
endif
	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, SGQT_BRING_UP_KEYBOARD
	call	GenCallParent

noKbd:
	;
	; Set a flag in the parent OLCtrls that we can't be overlapping objects.
	; -cbh 5/ 4/93
	;
	call	OpenCheckIfBW				;not B/W, don't sweat
	jnc	exit
	call	SpecSetFlagsOnAllCtrlParents		;sets CANT_OVERLAP_KIDS
exit:
	ret
OLSpinGadgetSpecBuild	endm

SpinHintHandlers	VarDataHandler \
	<HINT_DEFAULT_FOCUS, offset GadgetBuild:OLSpinGadgetMakeDefaultFocus>
			




COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLSpinGadgetClass

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
	chris	9/30/92		Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetScanGeometryHints	method OLSpinGadgetClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS

	; Initialize Visible characteristics that we'd like to have unless
	; overridden by hints handling
	;
	; Horizontal alignment, no centering vertically (may change this later
	; for twisted scrollbars).   (Don't clear NOTIFY_GEOMETRY_VALID
	; bit!   Will break position stuff.  6/ 3/93 cbh)
	;
	push	di
	call	GadgetBuild_DerefVisSpecDI
	clr	ds:[di].VCI_geoAttrs
	clr	ds:[di].VCI_geoDimensionAttrs
	and	ds:[di].VI_geoAttrs, mask VGA_NOTIFY_GEOMETRY_VALID
	and	ds:[di].OLCI_optFlags, not (mask OLCOF_DISPLAY_BORDER or \
				            mask OLCOF_DISPLAY_MKR_ABOVE  or \
					    mask OLCOF_CUSTOM_SPACING)
	pop	di
	call	DoCtrlHints
	ret

OLSpinGadgetScanGeometryHints	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLSpinGadgetMakeDefaultFocus

SYNOPSIS:	Make the default focus.

CALLED BY:	hint handler

PASS:		*ds:si - object

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/13/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetMakeDefaultFocus	proc	far
	call	GadgetBuild_DerefVisSpecDI
	or	ds:[di].OLSGI_states, mask OLSGS_MAKE_DEFAULT_FOCUS
	ret
OLSpinGadgetMakeDefaultFocus	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupSpinDesiredSize

SYNOPSIS:	Calculates a desired size for the spin gadget.	

CALLED BY:	OLSpinGadgetSpecBuild

PASS:		*ds:si -- handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 6/90		Initial version

------------------------------------------------------------------------------@

SetupSpinDesiredSize	proc	near
	call	GadgetBuild_DerefVisSpecDI
	mov	cx, ds:[di].OLSGI_desWidth
	mov	dx, ds:[di].OLSGI_desHeight	;setup default size
	CallMod	VisApplySizeHints		;use hints
	call	GadgetBuild_DerefVisSpecDI
	mov	ds:[di].OLSGI_desWidth, cx
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER	;slider, don't save as
	jnz	10$					;  text width
	mov	ds:[di].OLSGI_textWidth, cx
10$:
	mov	ds:[di].OLSGI_desHeight, dx	;setup desired size
	ret
SetupSpinDesiredSize	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateSpinScrollbar

SYNOPSIS:	Creates the scrollbar for the spin gadget.

CALLED BY:	OLSpinGadgetBuild

PASS:		*ds:si -- handle of spin gadget
		bp - SpecBuildFlags

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/18/89	Initial version

------------------------------------------------------------------------------@

CreateSpinScrollbar	proc	near
	class	OLSpinGadgetClass

	call	GadgetBuild_DerefVisSpecDI	
EC <	tst	ds:[di].OLSGI_scrollbar		;is there a scrollbar?	   >
EC <	ERROR_NZ	OL_ERROR		;yes, die (could exit...)  >
	;
	; Instantiate a horizontal scrollbar and visibly add it as the first
	; child.
	;
if SPINNER_GEN_VALUE
	;
	; make spinner scrollbar for spinner
	;
	mov	bx, HINT_SPEC_SPINNER
	test	ds:[di].OLSGI_attrs, mask OLSGA_SPINNER
	jnz	10$
else
	mov	bx, HINT_VALUE_X_SCROLLER
endif
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	10$
	mov	bx, HINT_SPEC_SLIDER
10$:
	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	push	bx				;send the hint

	mov	ax, SPIN_MSG_BASE		;set method base
	push	ax				;pass on stack
	call	GadgetBuild_DerefGenDI	
	clr	ax
	push	ax, ax				;minimum
	push	ax, ax				;maximum
	push	ax, ax				;value
	push	ax, ax				;increment
						;upward generic link only
						;delayed drags only (who cares)
	call	OpenAddScrollbar		;handle returned in dx
	
	call	GadgetBuild_DerefVisSpecDI
	mov	ds:[di].OLSGI_scrollbar, dx	;save scrollbar handle	
	;
	; Save whether we were read-only, to pass on to scrollbar.
	;
	push	si
	mov	si, ds:[si]			
	add	si, ds:[si].Gen_offset
	test	ds:[si].GI_attrs, mask GA_READ_ONLY
	pushf

	;
	; Set some scrollbar attributes, to make it twisted and stupid
	; (oblivious of any positions and ranges).    (Twisted happens 
	; automatically now.)  Sliders' orientation based on OLSGA_ORIENT_VERT.
	;
	mov	si, dx				;scrollbar in si

if _JEDIMOTIF	;--------------------------------------------------------------
	mov	cl, mask OLSA_STUPID
	clr	ch
	;
	; Commented out to get rid of all the work we did to make
	; them draw with +/- buttons.  -stevey 5/9/95
	;
	;mov	ch, mask OLSMA_PLUS_MINUS	; assume non-slider, use + -
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jz	15$
	or	cl, mask OLSA_VERTICAL
15$:
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	20$
	andnf	cl, not mask OLSA_STUPID
	andnf	ch, not mask OLSMA_PLUS_MINUS	; slider, don't use + -
elif FLOATING_SCROLLERS	;------------------------------------------------------
	mov	cl, mask OLSA_STUPID or mask OLSA_VERTICAL or mask OLSA_TWISTED
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	20$
	clr	cl
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jz	20$
	mov	cl, mask OLSA_VERTICAL
else		;--------------------------------------------------------------
	mov	cl, mask OLSA_STUPID or mask OLSA_VERTICAL
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	20$
	clr	cl
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jz	20$
	mov	cl, mask OLSA_VERTICAL
endif		;--------------------------------------------------------------

20$:
	call	GadgetBuild_DerefVisSpecDI
	or	ds:[di].OLSBI_attrs.low, cl		;store attributes
JEDI <	or	ds:[di].OLSBI_moreAttrs, ch	;store more attrs	>

	;
	; Pass read-only state on to scrollbar.
	;
	popf
	jz	30$				;not read only, branch
	call	GadgetBuild_DerefGenDI
	or	ds:[di].GI_attrs, mask GA_READ_ONLY
if SLIDER_INCLUDES_VALUES
	;
	; set the spec instance copy of read-only, also
	;
	call	GadgetBuild_DerefVisSpecDI
	or	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
endif
30$:
	
	;
	; Add this so the scrollbar will always send out a message.
	;
	mov	ax, ATTR_GEN_SEND_APPLY_MSG_ON_APPLY_EVEN_IF_NOT_MODIFIED
	clr	cx
	call	ObjVarAddData

if SLIDER_INCLUDES_VALUES
	;
	; if slider (or gauge), copy color hints to scrollbar
	;	*ds:si = scrollbar
	;
	pop	di				; *ds:di = spin gadget
	push	di
	mov	bx, ds:[di]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
	push	es, bp
	segmov	es, ds
	mov	bp, si				; *es:bp = scrollbar
	mov	si, di				; *ds:si = spin gadget
	mov	cx, HINT_GADGET_BACKGROUND_COLORS
	mov	dx, cx
	call	ObjVarCopyDataRange		; ds, es updated
	mov	cx, HINT_GADGET_TEXT_COLOR
	mov	dx, cx
	call	ObjVarCopyDataRange
if DRAW_STYLES
	;
	; set frame flag
	;	*ds:si = spin gadget
	;	*es:bp = scroller/slider
	;
	mov	bp, es:[bp]
	add	bp, es:[bp].Vis_offset		; es:bp = scroller instance
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		; ds:di = spin gadget gen inst
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	notNoFrame			; always frame slider
	mov	ax, HINT_VALUE_NO_FRAME		; gauges are framed unless
	call	ObjVarFindData			;	hint says otherwise
	jnc	notNoFrame
	ornf	es:[bp].OLSBI_attrs, mask OLSA_NO_FRAME
notNoFrame:
	;
	; set draw style
	; (we can't just copy the draw style hints as they're needed before
	;  can copy them)
	;	- sliders default to lowered (in scrollbar spec build)
	;	- gauges default to flat (need to override scroll spec build)
	;	- hints override defaults
	;	- lowered gauge has no frame
	;	*ds:si = spin gadget
	;	ds:di = spin gadget gen instance
	;	es:bp = scroller/slider instance
	;
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	notGauge
	mov	es:[bp].OLSBI_drawStyle, DS_FLAT	; gauge - default flat
notGauge:
	mov	ax, HINT_DRAW_STYLE_FLAT
	call	ObjVarFindData
	jnc	notFlat
	mov	es:[bp].OLSBI_drawStyle, DS_FLAT
notFlat:
	mov	ax, HINT_DRAW_STYLE_3D_LOWERED
	call	ObjVarFindData
	jnc	notLowered
	mov	es:[bp].OLSBI_drawStyle, DS_LOWERED
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	notLowered
	ornf	es:[bp].OLSBI_attrs, mask OLSA_NO_FRAME	; lowered gauge
notLowered:
endif ; DRAW_STYLES
	pop	es, bp
notSlider:
endif ; SLIDER_INCLUDES_VALUES

	pop	si
	
	pop	di
	call	ThreadReturnStackSpace
	ret
CreateSpinScrollbar	endp

GadgetBuild_DerefVisSpecDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
GadgetBuild_DerefVisSpecDI	endp	

GadgetBuild_DerefGenDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	ret
GadgetBuild_DerefGenDI	endp	

GadgetBuild	ends

;-------------------

Unbuild	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetVisUnbuild -- 
		MSG_VIS_UNBUILD for OLSpinGadgetClass

DESCRIPTION:	Unbuilds the spin gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_UNBUILD

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		Release the keyboard grab if we have a text object.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetVisUnbuild	method dynamic OLSpinGadgetClass, MSG_SPEC_UNBUILD_BRANCH
	clr	cx
	mov	ds:[di].OLSGI_text, cx		;text object going away too
	xchg	ds:[di].OLSGI_scrollbar, cx	;get scrollbar handle, zero it

	push	cx
	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	mov	di, offset OLSpinGadgetClass
	call	ObjCallSuperNoLock		;do superclass unbuild

	;
	; Everything unbuilt now, destroy the scrollbar.  -cbh 1/20/93
	;
	pop	si
	tst	si
	jz	exit
	mov	ax, si				;destroy any moniker, but there
						;   won't be one anyway
EC <	call	ECCheckLMemObject					>
	call	OpenDestroyGenericBranch	;nuke the object
exit:
	ret
	
OLSpinGadgetVisUnbuild	endm


Unbuild ends


LessUsedGeometry	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetRerecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLSpinGadgetClass

DESCRIPTION:	Calculates the size of the spin gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - RerecalcSizeArgs: typical resize args

RETURN:		cx, dx  - size to make the thing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetRerecalcSize	method OLSpinGadgetClass, MSG_VIS_RECALC_SIZE
	;
	; A hack to make the spin gadget expand to fit in toolboxes.  The
	; desired height gets mucked around with.  Assumes there won't be
	; any nasty above-monikers or borders to deal with.
	;
	push	dx
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	sizeText
	tst	dx				;passed desired height, branch
	js	sizeText

CUAS <	sub	dx, 1+1				;leave room for top/bot lines >
						; (for some reason, 2+2 no 
						;  longer works here.)
	call	CheckIfLargeHeight
	jnc	17$
	sub	dx, SPIN_EXTRA_PEN_MARGIN*2
17$:
	cmp	dx, ds:[di].OLSGI_desHeight	;can only make larger
	jle	sizeText

	;
	; Don't expand too much if we're in a toolbar, only just enough
	; to line up with other gadgetry.   7/18/94 cbh
	;
	push	dx
	sub	dx, ds:[di].OLSGI_desHeight
	cmp	dx, TOOLBAR_EXPAND_HEIGHT_THRESHOLD
	pop	dx
	jge	sizeText	

	mov	ds:[di].OLSGI_desHeight, dx

sizeText:
	pop	dx
	;
	; Size the text object, if any.
	;
	tst	ds:[di].OLSGI_text		;is there a text around?
	jz	calcSize			;branch if no text object
	push	cx, dx
	call	ResizeSpinText			;resize the text object
	pop	cx, dx

calcSize:
	;
	; Pass a small height to the twisted scrollbar style spin gadgets
	; so they won't create some vertical monstrosity.
	;	
	call	LUG_DerefVisDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jnz	10$

;	clr	dx				;make SMALL;  using desHeight
;						;  is no good since scrollbar
;						;  will return next *larger*
;						;  height, which'll be untwisted
;						;(Hopefully this problem is
;						; gone.  -cbh 2/26/93)
	mov	dx, ds:[di].OLSGI_desHeight
CUAS <	add	dx, 1+1				;magic constants.  Love 'em. >

	call	CheckIfLargeHeight
	jnc	10$
	add	dx, SPIN_EXTRA_PEN_MARGIN*2
	
10$:
	call	SpinGadgetPassMarginInfo
	call	OpenRecalcCtrlSize
	ret
OLSpinGadgetRerecalcSize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGetCenter -- 
		MSG_VIS_GET_CENTER for OLSpinGadgetClass

DESCRIPTION:	Gets the object's center.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_CENTER

RETURN:		cx 	- minimum amount needed left of center
		dx	- minimum amount needed right of center	
		ax 	- minimum amount needed above center
		bp      - minimum amount needed below center

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	3/ 9/93         	Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetGetCenter	method dynamic	OLSpinGadgetClass, \
				MSG_VIS_GET_CENTER
	;
	; If we're doing some center-by-monikers thing, then we'll call our
	; superclass.  Otherwise, we'll just do a VisGetCenter to avoid
	; strange problems with the built in VisComp centering and this object.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jnz	callSuper			;in properties, branch

	call	VisGetCenter			;else just do normal center.
	ret

callSuper:
	mov	di, offset OLSpinGadgetClass
	GOTO	ObjCallSuperNoLock

OLSpinGadgetGetCenter	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	SpinGadgetPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLSpinGadgetRecalcSize, OLSpinGadgetPositionBranch

PASS:		*ds:si -- trigger bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

SpinGadgetPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OLCtrlGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OLSpinGadgetGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
SpinGadgetPassMarginInfo	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGetMargins -- 
		MSG_VIS_COMP_GET_MARGINS for OLSpinGadgetClass

DESCRIPTION:	Subclasses here to make sure there ain't any top and bottom 
		margins.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		
RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/12/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetGetMargins	method OLSpinGadgetClass, MSG_VIS_COMP_GET_MARGINS
	;
	; Call superclass, and eliminate top and bottom margins, if needed.
	;
	mov	ax, MSG_VIS_COMP_GET_MARGINS
	mov	di, offset OLSpinGadgetClass	;call the fine superclass
	call	ObjCallSuperNoLock

	call	LUG_DerefVisDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	jnz	leaveTop
	clr	bp				;no top, bottom margins
leaveTop:
	clr	dx

	push	cx, dx				;save right, bottom margins
if SLIDER_INCLUDES_VALUES
	;
	; no spin text in margin for sliders
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
	clr	cx, dx
	jmp	short 10$

notSlider:
endif
	call	GetSpinTextSize			;get size of spin text area
10$::
	call	LUG_DerefVisDI
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	vertical
	;
	; Horizontally oriented, we'll add the spin width to the
	; left margin.  
	;	
	add	ax, cx
	jmp	short exit
vertical:
	;
	; Vertically oriented, we'll add the spin width to the
	; top margin.  
	;	
	add	bp, dx
exit:
	pop	cx, dx				;restore right & bottom margins
if (not SLIDER_INCLUDES_VALUES)
	;
	; no min/max moniker spacing for SLIDER_INCLUDES_VALUES
	;
	call	AddInSpaceForMinMaxMonikers	;if needed, adds this stuff.
endif
if _RUDY
	call	LUG_DerefVisDI
	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
	jz	reallyExit
	add	ax, RUDY_SPIN_LEFT_AREA_WIDTH	;add space for left "thing"
reallyExit:

endif
if SLIDER_INCLUDES_VALUES and CURSOR_OUTSIDE_BOUNDS
	;
	; make room for focus indication, if focusable
	;
	call	LUG_DerefVisDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	noFocus
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	noFocus
	add	ax, OUTSIDE_CURSOR_MARGIN
	add	bp, OUTSIDE_CURSOR_MARGIN
	add	cx, OUTSIDE_CURSOR_MARGIN
	add	dx, OUTSIDE_CURSOR_MARGIN
noFocus:
endif
	ret
OLSpinGadgetGetMargins	endm





if (not SLIDER_INCLUDES_VALUES)
;
; no min/max moniker spacing for SLIDER_INCLUDES_VALUES
;

COMMENT @----------------------------------------------------------------------

ROUTINE:	AddInSpaceForMinMaxMonikers

SYNOPSIS:	Adds in any needed margins to allow min-max monikers to exist.

CALLED BY:	OLSpinGadgetGetMargins

PASS:		*ds:si -- spin gadget
		ax, bp, cx, dx -- current margins

RETURN:		ax, bp, cx, dx -- possibly updated with extra margins

DESTROYED:	

PSEUDO CODE/STRATEGY:
	for vertical sliders:
		add nothing to left margin
		add 1/2 (minMoniker height) to top margin
		add max (minMoniker width, maxMoniker width) + MIN_MAX_MARGIN
			 to right margin
		add 1/2 (maxMoniker height) to bottom margin.
	else
		add 1/2 (minMoniker width) to left margin
		add nothing to top margin
		add 1/2 (maxMoniker width) to right margin.
		add max (minMoniker height, maxMoniker height) + MIN_MAX_MARGIN
			to bottom margin
	endif

	alternate way (ALIGN_VALUE_MIN_MAX_MONIKERS):
	for vertical sliders:
		add (max((minMkr width), (maxMkr width))-slider width)/2
			to left and right margin
		add (minMoniker height) + MIN_MAX_MARGIN to top
		add (maxMoniker height) + MIN_MAX_MARGIN to bottom
	else
		add (minMoniker width) + MIN_MAX_MARGIN to left
		add (maxMoniker width) + MIN_MAX_MARGIN to right
		add (max((minMkr height), (maxMkr height))-slider height)/2
			to top and bottom margin
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/24/92	Initial version

------------------------------------------------------------------------------@

AddInSpaceForMinMaxMonikers	proc	near
	call	LUG_DerefVisDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SHOW_MIN_MAX_MKRS
	jz	exit				;no special monikers, exit
	push	ax, bp, cx, dx			;save current margins
	clr	bx				;get min moniker size
	call	GetMinMaxMonikerSize		;size in cx, dx
	mov	ax, cx				;move width into left marg reg
	mov	bp, dx				;height into top margin reg
	mov	bx, si				;get max moniker size (cx != 0)
	call	GetMinMaxMonikerSize		;size in cx, dx

	call	LUG_DerefVisDI			;orienting slider vertically?
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jz	horizontal
if ALIGN_VALUE_MIN_MAX_MONIKERS	;---------------------------------------------
	cmp	ax, cx
	jae	10$
	mov	ax, cx				;ax = moniker width
10$:
	push	ax, dx, bp
	mov	ax, MSG_VIS_RECALC_SIZE
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	call	VisCallFirstChild		;cx = slider width, dx = height
	pop	ax, dx, bp
	sub	ax, cx
	jns	vOkay
	mov	ax, 0				;slider wider than monikers
vOkay:
	shr	ax, 1				;ax = left margin
	mov	cx, ax				;cx = right margin
if (MIN_MAX_MARGIN eq 1)
	inc	bp				;bp = top margin
else
	add	bp, MIN_MAX_MARGIN
endif
if (MIN_MAX_MARGIN eq 1)
	inc	dx				;dx = bottom margin
else
	add	dx, MIN_MAX_MARGIN
endif
	jmp	short addToPassedMargins

horizontal:
if (MIN_MAX_MARGIN eq 1)
	inc	ax				;ax = left margin
else
	add	ax, MIN_MAX_MARGIN
endif
if (MIN_MAX_MARGIN eq 1)
	inc	cx				;cx = right margin
else
	add	cx, MIN_MAX_MARGIN
endif
	cmp	bp, dx
	jae	20$
	mov	bp, dx
20$:
	push	ax, cx, bp
	mov	ax, MSG_VIS_RECALC_SIZE
	mov	cx, mask RSA_CHOOSE_OWN_SIZE
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	call	VisCallFirstChild		;cx = slider width, dx = height
	pop	ax, cx, bp
	sub	bp, dx
	jns	hOkay
	mov	bp, 0				;slider taller than monikers
hOkay:
	shr	bp, 1				;bp = top margin
	mov	dx, bp				;dx = bottom margin
else	;---------------------------------------------------------------------
	shr	bp, 1				;vertical, halve min mkr height
	shr	dx, 1				;and max mkr height	
	cmp	cx, ax				;keep width max'es in right
	jae	10$
	mov	cx, ax
10$:
if (MIN_MAX_MARGIN eq 1)
	inc	cx
else
	add	cx, MIN_MAX_MARGIN
endif
	clr	ax				;no left margin
	jmp	short addToPassedMargins	;and we're done

horizontal:
	shr	ax, 1				;horiz, halve min mkr width
	shr	cx, 1				;and max mkr width
	cmp	dx, bp				;keep height max'es in bottom
	jae	20$
	mov	dx, bp
20$:
if (MIN_MAX_MARGIN eq 1)
	inc	dx
else
	add	dx, MIN_MAX_MARGIN
endif
	clr	bp				;no top margin
endif	;--------------------------------------------------------------------

addToPassedMargins:
	;
	; Total margins to add in ax, bp, cx, dx.  Let's add them to what was
	; passed.
	;
	pop	bx				;passed bottom
	add	dx, bx
	pop	bx				;passed right
	add	cx, bx
	pop	bx
	add	bp, bx
	pop	bx
	add	ax, bx
exit:
	ret
AddInSpaceForMinMaxMonikers	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	GetMinMaxMoniker

SYNOPSIS:	Returns a min or max moniker to either draw or size up.

CALLED BY:	DrawMinMaxMoniker, GetMinMaxMonikerSize

PASS:		*ds:si -- spin gadget
		bx -- non-zero for a max moniker
		cx:dx -- buffer to hold text
	
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/24/92       	Initial version

------------------------------------------------------------------------------@

GetMinMaxMoniker	proc	near	uses	ax, bp
	.enter
	mov	bp, GVT_MINIMUM
	tst	bx
	jz	10$
	inc	bp
		CheckHack <((GVT_MAXIMUM - GVT_MINIMUM) eq 1)>
10$:
	mov	ax, MSG_GEN_VALUE_GET_VALUE_TEXT
	call	ObjCallInstanceNoLock		;should return text
	.leave
	ret
GetMinMaxMoniker	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	GetMinMaxMonikerSize

SYNOPSIS:	Returns size of a min or max moniker.

CALLED BY:	AddInSpaceForMinMaxMonikers

PASS:		*ds:si -- spin gadget
		bx -- non-zero for the max moniker, zero for min

RETURN:		cx, dx -- size of the text

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/24/92       	Initial version

------------------------------------------------------------------------------@

GetMinMaxMonikerSize	proc	far		uses	ax, ds, si, bp
	.enter

	call	ViewCreateCalcGState		;bp = gstate (it'd better work)
	call	LUG_DerefVisDI
	sub	sp, GEN_VALUE_MAX_TEXT_LEN*(size TCHAR)
	mov	dx, sp
	mov	cx, ss				;cx:dx <- buffer
	call	GetMinMaxMoniker		;moniker in cx:dx
	movdw	dssi, cxdx
	mov	cx, -1				;look for null termination
	mov	di, bp				;pass gstate
	call	GrTextWidth			;get width in dx
	mov	cx, dx				;cx = width
	add	sp, GEN_VALUE_MAX_TEXT_LEN*(size TCHAR)
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			;dx = height
	call	GrDestroyState
	.leave
	ret
GetMinMaxMonikerSize	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawMinMaxMoniker

SYNOPSIS:	Draws a min or max moniker.

CALLED BY:	DrawMinMaxMonikers

PASS:		*ds:si -- spin gadget
		bx -- non-zero for the max moniker, zero for min
		cx, dx -- position to draw text
		di -- gstate

RETURN:		nothing

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/24/92       	Initial version

------------------------------------------------------------------------------@

DrawMinMaxMoniker	proc	far		uses	ds, si, ax, bx, bp
	.enter
	mov	bp, di				;bp = gstate
	mov	ax, dx				;ax = Y position
	call	LUG_DerefVisDI
	sub	sp, GEN_VALUE_MAX_TEXT_LEN*(size TCHAR)
	mov	dx, sp
	push	cx				;save X position
	mov	cx, ss				;cx:dx <- buffer
	call	GetMinMaxMoniker		;moniker in cx:dx
	movdw	dssi, cxdx
	mov	bx, ax				;bx = Y position
	pop	ax				;ax = X position
	clr	cx				;look for null termination
	mov	di, bp				;pass gstate
	call	GrDrawText			;get width in dx
	mov	cx, dx
	add	sp, GEN_VALUE_MAX_TEXT_LEN*(size TCHAR)
	.leave
	ret
DrawMinMaxMoniker	endp

endif ; (not SLIDER_INCLUDES_VALUES)



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSpinTextSize

SYNOPSIS:	Returns size of spin text area.

CALLED BY:	OLSpinGadgetGetMargins, OLSpinGadgetGetMinimumSize

PASS:		*ds:si -- spin gadget

RETURN:		cx, dx -- size of text area

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/30/92		Initial version

------------------------------------------------------------------------------@

GetSpinTextSize	proc	near
	call	LUG_DerefVisDI
if _JEDIMOTIF
	;
	; if JEDI slider, no extra space unless HINT_VALUE_DIGITAL_DISPLAY
	; in which case, we use the desired height only, the width remains
	; limited by the slider itself
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
	push	ax, bx
	mov	ax, HINT_VALUE_DIGITAL_DISPLAY
	call	ObjVarFindData
	pop	ax, bx
	mov	cx, 0				;no value, no extra space
	mov	dx, 0
	jnc	10$
notSlider:
endif
	mov	cx, ds:[di].OLSGI_desWidth	;add in desired width of area
        mov	dx, ds:[di].OLSGI_desHeight	;and desired height

10$::
	;
	; Add in a frame if we can edit the text.    (Sliders don't need margins
	; either.)
	;
	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
	jz	20$				;read-only, or slider, branch
CUAS <	add	dx, 1+1				;leave room for top/bot lines >
CUAS <    					;and focus rectangle          >

	call	CheckIfLargeHeight
	jnc	17$
	add	dx, SPIN_EXTRA_PEN_MARGIN*2	;extra Y margins
17$:

	add	cx, SPIN_CONTENT_MARGIN*2	;X margins
20$:
	;
	; Add in spacing between value and scrollbar, unless we're not allowing
	; up down arrows.   Or we're narrow minded.
	; 
	call	LUG_DerefVisDI
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	pushf
	jz	30$
	xchg	cx, dx
30$:

if _JEDIMOTIF
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jnz	40$				;no spacing for JEDI slider
endif
	test	ds:[di].OLSGI_attrs, mask OLSGA_NO_UP_DOWN_ARROWS
	jnz	40$
	add	cx, SPIN_SCROLLBAR_SPACING

if (SPIN_SCROLLBAR_SPACING ne NARROW_SPIN_SCROLLBAR_SPACING)
	call	OpenCheckIfLimitedLength
	jnc	40$
	sub	cx, SPIN_SCROLLBAR_SPACING - NARROW_SPIN_SCROLLBAR_SPACING

if (NARROW_NO_EDIT_SCROLLBAR_SPACING ne NARROW_SPIN_SCROLLBAR_SPACING)
	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
	jnz	40$
	sub	cx, NARROW_SPIN_SCROLLBAR_SPACING - \
		    NARROW_NO_EDIT_SCROLLBAR_SPACING
endif
endif

40$:
	popf
	jz	exit
	xchg	cx, dx
exit:
	ret
GetSpinTextSize	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGetMinimumSize -- 
		MSG_VIS_COMP_GET_MINIMUM_SIZE for OLSpinGadgetClass

DESCRIPTION:	Returns minimum size.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_COMP_GET_MINIMUM_SIZE

RETURN:		cx -- min width
		dx -- min height
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	9/30/92		Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetGetMinimumSize	method dynamic	OLSpinGadgetClass, \
				MSG_VIS_COMP_GET_MINIMUM_SIZE

	mov	di, offset OLSpinGadgetClass
	call	ObjCallSuperNoLock		;get superclass size
	
	movdw	axbx, cxdx
	call	GetSpinTextSize			;cx, dx <- size of spin text
	xchgdw	axbx, cxdx			;ax, bx <- size of spin text
						;cx, dx <- superclass min size

	;
	; Set a flag to tell us where the moniker is (if any).
	;
	clr	bp
	call	LUG_DerefVisDI
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	jz	5$
	not	bp				;set if moniker above
5$:
	;
	; Make code work for both vertical and horizontal.  We'll exchange
	; registers and treat the spin gadget as having a horizontal 
	; orientation.
	;
	test	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jz	10$
	xchg	ax, bx				;swap things so we can treat
	xchg	cx, dx				;  as moniker on left case
	not	bp				;
10$:	
	pushf

	;
	; If bp set, moniker is not in-line with spin gadget and scrollbar.
	; We'll subtract off the textWidth from the minWidth (the clever
	; OLCtrl get minimum code added both parts together already) and
	; return the largest.  (We also need to add the text and min heights
	; together here. -cbh 12/ 3/92)
	;
	tst	bp
	jz	20$				;moniker in-line with others

	add	dx, bx				;add textHeight and minHeight
	sub	cx, ax				;cx now moniker width
	cmp	cx, ax
	jae	done
	mov	cx, ax
	jmp	short done
20$:
	;
	; Moniker in-line with other stuff, take the larger of the text height
	; and min height.
	;
	cmp	dx, bx
	jae	done
	mov	dx, bx
done:
	;
	; Restore registers (actually, we only care about cx & dx.)
	;
	popf	
	jz	exit
	xchg	cx, dx				
exit:
	ret
OLSpinGadgetGetMinimumSize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetPosition -- 
		MSG_VIS_POSITION_BRANCH for OLSpinGadgetClass

DESCRIPTION:	Positions the spin gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_POSITION_BRANCH
		cx, dx  - place to position the spin gadget

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       position scrollbar in lower right corner of spin gadget.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetPosition	method OLSpinGadgetClass, MSG_VIS_POSITION_BRANCH
if _JEDIMOTIF		
	;
	;  If we're in the title bar and we're read-only, adjust
	;  the positioning slightly.
	;
	call	SpinGadgetAdjustForTitleBar
endif
	call	VisSetPosition			;position the spin gadget
	;
	; Position the text object, if any.
	;
	call	LUG_DerefVisDI
	tst	ds:[di].OLSGI_text
	jz	positionScrollbar		;branch if no text object
	push	cx, dx
	call	PositionSpinText		;position the spin text
	pop	cx, dx

positionScrollbar:
	call	SpinGadgetPassMarginInfo	
	call	VisCompPosition
	ret

OLSpinGadgetPosition	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpinGadgetAdjustForTitleBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust height if in title bar.

CALLED BY:	OLSpinGadgetRerecalcSize

PASS:		*ds:si	= object
		(cx,dx) = place to position spin gadget

RETURN:		dx = new y position

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF
SpinGadgetAdjustForTitleBar	proc	near
	uses	ax, di
	.enter
	;
	;  If we're not in the title bar, quit.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].OLCI_buildFlags
	andnf	ax, mask OLBF_TARGET
	cmp	ax, OLBT_FOR_TITLE_BAR_RIGHT shl offset OLBF_TARGET
	je	checkReadOnly

	cmp	ax, OLBT_FOR_TITLE_BAR_LEFT shl offset OLBF_TARGET
	jne	done
checkReadOnly:
	;
	;  Not Gen/read-only -> quit.
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	done
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	done
	;
	;  Tweak height.
	;
	inc	dx
done:
	.leave
	ret
SpinGadgetAdjustForTitleBar	endp
endif

LessUsedGeometry	ends

;------------------------

Resident segment resource
	



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfLargeHeight

SYNOPSIS:	Checks to see if we need a large height for pen mode.

CALLED BY:	utility

PASS:		*ds:si -- spin gadget

RETURN:		carry set if large height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/25/93       	Initial version

------------------------------------------------------------------------------@

CheckIfLargeHeight	proc	far		uses	ax, bx, di, es
	.enter

	call	Res_DerefVisDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT or \
				     mask OLSGA_SLIDER
	jnz	exit				;text not editable, exit c=0

if _DUI or _ODIE
	clc					; never make larger
else
	call	SysGetPenMode
	tst	ax
	clc	
	jz	exit			

	stc

	; Bad if we're not a GenValue object...

	mov	di, segment GenValueClass
	mov	es, di
	mov	di, offset GenValueClass
	call	ObjIsObjectInClass
	jnc	notGenValue			;not GenValue, return large
						;	height = true

	mov	ax, HINT_VALUE_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS
	call	ObjVarFindData
notGenValue:
	cmc					;return carry set if NOT found
endif	; _DUI or _ODIE
exit:
	.leave
	ret
CheckIfLargeHeight	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	PositionSpinText

SYNOPSIS:	Positions the spin text object.

CALLED BY:	OLSpinGadgetPosition, OLSpinGadgetStartSelect

PASS:		*ds:si -- spin gadget handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/19/90		Initial version

------------------------------------------------------------------------------@

PositionSpinText	proc	far
	mov	bx, si				;save spin handle
	call	Res_DerefVisDI
	mov	si, ds:[di].OLSGI_text		;get text handle	
	tst	si
	jz	exit				;no text, exit
	call	VisGetSize			;get height of text
	push	si				;save text handle
	mov	si, bx				;restore spin handle
	call	GetTextPosition			;get position of text
	pop	bx				;restore text handle
	mov	cx, ax				;put left edge in cx
	xchg	si, bx				;si <- text handle
	call	VisSetPosition			;move the text object
	call	Res_DerefVisDI
	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)
	or	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	Res_ObjCallInstanceNoLock	;text object requires this
exit:
	mov	si, bx				;si <- spin gadget handle
	ret
PositionSpinText	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ResizeSpinText

SYNOPSIS:	Sizes the spin text object.

CALLED BY:	OLSpinGadgetRerecalcSize, OLSpinGadgetStartSelect

PASS:		*ds:si -- spin gadget handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/19/90		Initial version

------------------------------------------------------------------------------@

ResizeSpinText	proc	far
	mov	bx, si				;save spin gadget handle
	call	Res_DerefVisDI
	mov	si, ds:[di].OLSGI_text		;get text handle
	mov	cx, ds:[di].OLSGI_desWidth	;get desired width

	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	10$
	mov	cx, ds:[di].OLSGI_textWidth	;get text width
10$:
	
	push	cx				;save 
	clr	dx				;don't cache the size
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT	;calculate the height
	call	Res_ObjCallInstanceNoLock		;returned in DX	
	pop	cx				;restore width
	call	VisSetSize			;size the thing while we're here
	mov	si, bx				;restore spin gadget handle
	ret
ResizeSpinText	endp

Resident ends

;---------------------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGetAttrs -- 
		MSG_SPEC_SPIN_GET_ATTRS for OLSpinGadgetClass

DESCRIPTION:	Returns attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_GET_ATTRS

RETURN:		cl 	- OLSpinGadgetAttrs
		ax, ch, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/10/92	Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetGetAttrs	method dynamic	OLSpinGadgetClass, \
				MSG_SPEC_SPIN_GET_ATTRS

	mov	cl, ds:[di].OLSGI_attrs
	ret
OLSpinGadgetGetAttrs	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetDraw -- 
		MSG_VIS_DRAW for OLSpinGadgetClass

DESCRIPTION:	Draws the spin gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW
		bp	- gstate (zero if gstate unavailable to caller)
		cl 	- update flag

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetDraw	method OLSpinGadgetClass, MSG_VIS_DRAW

if _JEDIMOTIF
	call	ClearBackgroundIfInTitleBar
endif
	push	bp
	mov	di, offset OLSpinGadgetClass
	call	ObjCallSuperNoLock		   ;draws moniker, scrollbar
	pop	bp
	push	bp, si
	call    OLSpinGadgetDrawContentsLow	  ;draw contents
	pop	bp, si
if (not SLIDER_INCLUDES_VALUES)
	;
	; no min/max moniker drawing for SLIDER_INCLUDES_VALUES
	;
	call	OLSpinGadgetDrawMinMaxMonikers	   ;draw monikers
endif
	ret
	
OLSpinGadgetDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearBackgroundIfInTitleBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this gadget is in the title bar, clear out
		background to get rid of black line through moniker.

CALLED BY:	OLSpinGadgetDraw

PASS:		bp = gstate
		*ds:si = object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _JEDIMOTIF
ClearBackgroundIfInTitleBar	proc	near
		uses	ax,bx,cx,dx,di
		.enter

		mov	ax, HINT_SEEK_TITLE_BAR_RIGHT
		call	ObjVarFindData
		jc	found
		mov	ax, HINT_SEEK_TITLE_BAR_LEFT
		call	ObjVarFindData
		jnc	done
found:
		mov	di, bp
	;
	;  Save current gstate color, just in case.
	;
		call	GrSaveState
		mov	ax, C_WHITE
		call	GrSetAreaColor
		call	VisGetBounds
		dec	ax			; make some space for moniker
		dec	bx
		inc	cx
		inc	dx			; adjust for area drawing
		call	GrFillRect
	;
	;  Restore GState color.
	;
		call	GrRestoreState
done:
		.leave
		ret
ClearBackgroundIfInTitleBar	endp

endif

COMMENT @----------------------------------------------------------------------

ROUTINE:	OLSpinGadgetDrawMinMaxMonikers

SYNOPSIS:	Draws minimum and maximum monikers.

CALLED BY:	OLSpinGadgetDraw

PASS:		*ds:si -- spin gadget
		bp -- gstate

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/24/92       	Initial version

------------------------------------------------------------------------------@

if (not SLIDER_INCLUDES_VALUES)
;
; no min/max moniker drawing for SLIDER_INCLUDES_VALUES
;

OLSpinGadgetDrawMinMaxMonikers	proc	near
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SHOW_MIN_MAX_MKRS
	LONG jz	exit				;no special monikers, exit

	push	bp				;save gstate

	clr	bx				;get min moniker size
	call	GetMinMaxMonikerSize		;size in cx, dx
	mov	ax, cx				;move width into left marg reg
	mov	bp, dx				;height into top margin reg
	mov	bx, si				;get max moniker size (cx != 0)
	call	GetMinMaxMonikerSize		;size in cx, dx

	;
	; ax, bp -- min moniker width and height
	; cx, dx -- max moniker width and height
	;
	push	si				;save spin gadget
	call	CF_DerefVisSpecDI		;orienting slider vertically?
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	pushf					;save vertical test
	mov	si, ds:[di].OLSGI_scrollbar	;*ds:si = scroller
EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
	call	CF_DerefVisSpecDI
	popf					;vertical?
	jz	horizontal

if ALIGN_VALUE_MIN_MAX_MONIKERS	;---------------------------------------------
	;
	; Vertical, draw min moniker at
	;	scrLeft+1/2(scrRight-scrLeft)-1/2(minMonikerWidth)
	;	scrBottom+MIN_MAX_MARGIN
	; Draw max moniker at:
	;	scrLeft+1/2(scrRight-scrLeft)-1/2(maxMonikerWidth)
	;	scrTop-(minMonikerHeight)-MIN_MAX_MARGIN
	;
	neg	ax
	add	ax, ds:[di].VI_bounds.R_right	
	sub	ax, ds:[di].VI_bounds.R_left
	sar	ax, 1
	add	ax, ds:[di].VI_bounds.R_left
	mov	bp, ds:[di].VI_bounds.R_bottom
if (MIN_MAX_MARGIN eq 1)
	inc	bp
else
	add	bp, MIN_MAX_MARGIN
endif
	neg	cx
	add	cx, ds:[di].VI_bounds.R_right
	sub	cx, ds:[di].VI_bounds.R_left
	sar	cx, 1
	add	cx, ds:[di].VI_bounds.R_left
	neg	dx
	add	dx, ds:[di].VI_bounds.R_top
if (MIN_MAX_MARGIN eq 1)
	dec	dx
else
	sub	dx, MIN_MAX_MARGIN
endif
else	;---------------------------------------------------------------------
	;
	; Vertical, draw min moniker at
	;	scrRight+MINMAX_MARGIN,
	;	scrTop-1/2(minMonikerHeight)
	; Draw max moniker at:
	;	scrRight+MINMAX_MARGIN,
	;	scrBottom-1/2(maxMonikerHeight)
	;
	mov	ax, ds:[di].VI_bounds.R_right
if (MIN_MAX_MARGIN eq 1)
	inc	ax
else
	add	ax, MIN_MAX_MARGIN
endif
	shr	bp, 1
	neg	bp
	add	bp, ds:[di].VI_bounds.R_bottom
	mov	cx, ax
	shr	dx, 1
	neg	dx
	add	dx, ds:[di].VI_bounds.R_top
endif	;---------------------------------------------------------------------
	jmp	short drawThem

horizontal:
if ALIGN_VALUE_MIN_MAX_MONIKERS	;---------------------------------------------
	;
	; Horizontal, draw min moniker at
	;	scrLeft-(minMonikerWidth)-MIN_MAX_MARGIN
	;	scrTop+1/2(scrBottom-scrTop)-1/2(minMonikerHeight)
	; Draw max moniker at:
	;	scrRight+MIN_MAX_MARGIN
	;	scrTop+1/2(scrBottom-scrTop)-1/2(maxMonikerHeight)
	;
	neg	ax
	add	ax, ds:[di].VI_bounds.R_left
if (MIN_MAX_MARGIN eq 1)
	dec	ax
else
	sud	ax, MIN_MAX_MARGIN
endif
	neg	bp
	add	bp, ds:[di].VI_bounds.R_bottom
	sub	bp, ds:[di].VI_bounds.R_top
	sar	bp, 1
	add	bp, ds:[di].VI_bounds.R_top
	mov	cx, ds:[di].VI_bounds.R_right
if (MIN_MAX_MARGIN eq 1)
	inc	cx
else
	add	cx, MIN_MAX_MARGIN
endif
	neg	dx
	add	dx, ds:[di].VI_bounds.R_bottom
	sub	dx, ds:[di].VI_bounds.R_top
	sar	dx, 1
	add	dx, ds:[di].VI_bounds.R_top
else	;---------------------------------------------------------------------
	;
	; Horizontal, draw min moniker at
	;	scrLeft-1/2(minMonikerWidth)
	;	scrBottom+MIN_MAX_MARGIN,
	; Draw max moniker at:
	;	scrRight-1/2(maxMonikerWidth)
	;
	shr	ax, 1
	neg	ax
	add	ax, ds:[di].VI_bounds.R_left
	mov	bp, ds:[di].VI_bounds.R_bottom
if (MIN_MAX_MARGIN eq 1)
	inc	bp
else
	add	bp, MIN_MAX_MARGIN
endif
	shr	cx, 1
	neg	cx
	add	cx, ds:[di].VI_bounds.R_right
	mov	dx, bp
endif	;---------------------------------------------------------------------

drawThem:
	pop	si				;*ds:si = spin gadget
	;
	; What we got is: ax, bp -- position to draw min moniker
	;		  cx, dx -- position to draw max moniker
	;
	pop	di				;restore gstate
	push	di				;save again
	mov	bx, si				
	call	DrawMinMaxMoniker		;draw maximum moniker

	movdw	cxdx, axbp			;min moniker position
	pop	di				;bp = gstate
	clr	bx
	call	DrawMinMaxMoniker		;draw minimum moniker
exit:
	ret
OLSpinGadgetDrawMinMaxMonikers	endp

endif ; (not SLIDER_INCLUDES_VALUES)



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetDrawContents -- 
		MSG_SPEC_SPIN_DRAW_CONTENTS for OLSpinGadgetClass

DESCRIPTION:	Draws the contents of the spin gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_DRAW_CONTENTS
		bp	- 

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 8/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetDrawContents method OLSpinGadgetClass, MSG_SPEC_SPIN_DRAW_CONTENTS
	call	ViewCreateDrawGState		;get a gstate
	tst	bp				;was there one?
	jz	noGState			;no, get out
	call	OLSpinGadgetDrawContentsLow	;draw contents
	call	GrDestroyState			;unload the gstate
noGState:
	ret
OLSpinGadgetDrawContents	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	OLSpinGadgetDrawContentsLow

SYNOPSIS:	Draws contents.

CALLED BY:      OLSpinGadgetDraw, OLSpinGadgetDrawContents

PASS:		*ds:si -- spin gadget
		bp -- gstate

RETURN:		di -- gstate

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/26/92       	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetDrawContentsLow	proc	near
	;
	; If spin gadget is not usable, we'll draw in 50% pattern the rest of
	; the way.
	;
	call	CF_DerefVisSpecDI
if SLIDER_INCLUDES_VALUES ;----------------------------------------------------
	;
	; no need to draw anything for sliders
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
if CURSOR_OUTSIDE_BOUNDS
	;
	; draw focus indicator for slider
	;
	call	SliderDrawFocus
	mov	di, bp				; di = gstate
endif ; CURSOR_OUTSIDE_BOUNDS
	ret				; <-- EXIT HERE

notSlider:
endif ; SLIDER_INCLUDES_VALUES ------------------------------------------------
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	mov	di, bp				;restore gstate
	jnz	20$				;gadget is usable, branch
if USE_COLOR_FOR_DISABLED_GADGETS
	mov	ax, DISABLED_COLOR
	call	GrSetLineColor
	call	GrSetTextColor
else
	mov	al, SDM_50
	call	GrSetTextMask
	call	GrSetLineMask			;else draw in 50% pattern
endif
20$:		
	;
	; Draws parts of the spin gadget's display area, perhaps.
	;
	push	di				;save gstate again
if _JEDIMOTIF
	;
	; in JEDI sliders, HINT_VALUE_NO_DIGITIAL_DISPLAY is the default,
	; so we look for HINT_VALUE_DIGITAL_DISPLAY, if not there, don't
	; bother clearing anything or drawing anything
	;
	push	di				; save gstate
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	pop	di				; di = gstate
	jz	notSlider
	mov	ax, HINT_VALUE_DIGITAL_DISPLAY
	call	ObjVarFindData			; carry set if found
	jnc	exit				; not found, no value
notSlider:
endif
	call	ClearSpinDisplay		;clear display area
	call	CF_DerefVisSpecDI

if	0	
	mov	cl, ds:[di].OLSGI_attrs		;get attributes in cl
	test	cl, mask OLSGA_TEXT		;text spin gadget?
	jnz	drawText			;yes, branch
	test	cl, mask OLSGA_MONIKER		;moniker spin gadget?
	jz	exit				;no, branch
	
;drawMoniker:
	tst	bx				;is there a moniker to draw?
	jz	exit				;no, exit
	
	pop	di				;restore and resave gstate
	push	di
	call	SpinSetupMoniker		;set up moniker args

	sub	sp, size OpenMonikerArgs	;make room for args
	mov	bp, sp				;bp points to top of args
	mov	ss:[bp].OMA_gState, di		;store gstate
	mov	ss:[bp].OMA_leftInset, ax		;x inset
	mov	ss:[bp].OMA_rightInset, cx		;x inset
	mov	ss:[bp].OMA_topInset, dx		;y inset
	mov	ss:[bp].OMA_bottomInset, dx		;y inset
						;desired width set in routine	
if _JEDIMOTIF
	;
	; pass DMF_UNDERLINE_ACCELERATOR manually
	;
	mov	ss:[bp].OMA_drawMonikerFlags, (J_LEFT shl offset DMF_X_JUST) or \
		    			 (J_LEFT shl offset DMF_Y_JUST) or \
		    			 mask DMF_CLIP_TO_MAX_WIDTH or \
					 mask DMF_UNDERLINE_ACCELERATOR
else
	mov	ss:[bp].OMA_drawMonikerFlags, (J_LEFT shl offset DMF_X_JUST) or \
		    			 (J_LEFT shl offset DMF_Y_JUST) or \
		    			 mask DMF_CLIP_TO_MAX_WIDTH
endif
	;
	; Calculate where to draw the puppy.
	;
	mov	cx, mask OLMA_DISP_SELECTION_CURSOR or \
	 	    mask OLMA_LIGHT_COLOR_BACKGROUND
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_states, mask OLSGS_HAS_FOCUS
	jz	30$				;we don't have focus, branch
	or	cx, mask OLMA_SELECTION_CURSOR_ON
30$:
	mov	ss:[bp].OMA_monikerAttrs, cx	;save attrs
EC <	call	ECInitOpenMonikerArgs		;			   >
   	mov	di, bx				;*ds:di holds moniker
	mov	bx, si				;*ds:bx is generic obj
	call	OpenDrawVisMoniker		;draw as a moniker
	add	sp, size OpenMonikerArgs	;unload args
	jmp	short exit			;and exit
drawText:
endif

	tst	ds:[di].OLSGI_text		;text object built?
	jnz	exit				;yes, it will draw itself.

	;
	; check to see if HINT_VALUE_NO_DIGITAL_DISPLAY is set, if it is
	; we do not draw the value.  SK 04/20/94
	;
	mov	ax, HINT_VALUE_NO_DIGITAL_DISPLAY
	call	ObjVarFindData			; carry set if found
	jc	exit

	pop	di				;restore gstate
	push	di				;save again

	call	SpinSetupMoniker		;else set up moniker args
if _JEDIMOTIF and 0
	;
	;  Hack for read-only GenValues in the title bar.  If instead
	;  I hack them to be 14 pixels tall, the title-bar still
	;  positions them too high, and I haven't figured out how to
	;  make them get positioned lower, so I'm simply drawing
	;  the text lower here.  Sigh.  -stevey
	;
	push	bx, di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		
	mov	bx, ds:[di].OLCI_buildFlags
	andnf	bx, mask OLBF_TARGET
	cmp	bx, OLBT_FOR_TITLE_BAR_RIGHT shl offset OLBF_TARGET
	je	inTitleBar
	cmp	bx, OLBT_FOR_TITLE_BAR_LEFT shl offset OLBF_TARGET
	jne	doneJedi
inTitleBar:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	doneJedi

	inc	dx
doneJedi:		
	pop	bx, di
endif
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	add	dx, ds:[si].VI_bounds.R_top	;make absolute top position
	add	ax, ds:[si].VI_bounds.R_left	;make absolute left position
	mov	si, ds:[si].OLSGI_desWidth	;si <- width available

	segmov	ds, es, cx			;have *ds:bx point to string
	call	ClipSpinTextIfNeeded		;clip the text if need be.
	pushf					;save whether clipped

	push	ds:[bx]				;point to text and save
	mov	bx, dx				;and pass top in bx

if _RUDY
	clr	dx				;seems to be messing things
						;  up (cbh 5/16/95)
else
	mov	si, GFMI_ABOVE_BOX or GFMI_ROUNDED	
	call	GrFontMetrics
endif
	sub	bx, dx				;subtract top box from our top
	pop	si				;restore text ptr
	clr	cx				;draw all the characters
	call	GrDrawText			;draw the text

	popf					;restore whether clipped
	jnc	exit				;no, branch
	call	GrRestoreState			;else restore state
	
exit:
	pop	di				;restore created gstate
if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	al, SDM_100			;set this back if we need to
	call	GrSetTextMask
	call	GrSetLineMask			;
endif
	ret
OLSpinGadgetDrawContentsLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SliderDrawFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw focus indicator for slider

CALLED BY:	INTERNAL
			OLSpinGadgetDrawContentsLow
PASS:		*ds:si = spin gadget
		bp = gstate
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SLIDER_INCLUDES_VALUES and CURSOR_OUTSIDE_BOUNDS

SliderDrawFocus	proc	near
	uses	bp
	.enter
	;
	; only for slider
	;
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	LONG jz	done
	;
	; check if focusable
	;
	call	CF_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	LONG jnz	done
	;
	; get bounds for outside cursor
	;	*ds:si = spin gadget
	;	bp = gstate
	;
	call	CF_DerefVisSpecDI
	mov	ax, ds:[di].OLSGI_scrollbar
	tst	ax
	jz	done
	mov	di, bp				; di = gstate
	push	si
	mov	si, ax
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock		; ax,bp,cx,dx = slider bounds
	mov	bx, bp				; ax,bx,cx,dx = slider bounds
	pop	si
	;
	; if not focus, erase any previous cursor
	;	*ds:si = spin gadget
	;	ax,bx,cx,dx = slider bounds
	;	di = gstate
	;
	push	di				; save gstate
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_states, mask OLSGS_HAS_FOCUS
	pop	di				; di = gstate
	jnz	showFocus
	push	bp
	mov	bp, ax				; bp = left bound
	call	OpenGetWashColors		; ax = spin gadget wash colors
	push	ax				; save mask color
	clr	ah
	call	GrSetLineColor			; set main color
	sub	bp, OUTSIDE_CURSOR_MARGIN
	mov	ax, bp				; ax = left bound
	sub	bx, OUTSIDE_CURSOR_MARGIN
	add	cx, OUTSIDE_CURSOR_MARGIN-1	; rect/line adjustment
	add	dx, OUTSIDE_CURSOR_MARGIN-1
	call	GrDrawRect			; erase focus ring
	pop	ax				; ah = mask color
	cmp	al, ah				; any mask color?
	je	noMaskColor
	mov	al, ah
	clr	ah
	call	GrSetLineColor			; set mask color
	mov	al, SDM_50
	call	GrSetLineMask
	mov	ax, bp				; ax = left bound
	call	GrDrawRect
	mov	al, SDM_100
	call	GrSetLineMask
noMaskColor:
	pop	bp
	jmp	short done

showFocus:
	;
	; draw cursor if focused
	;	*ds:si = spin gadget
	;	di = gstate
	;	ax,bx,cx,dx = slider bounds
	;
	call	OpenDrawOutsideCursor
done:
	.leave
	ret
SliderDrawFocus	endp

endif ; SLIDER_INCLUDES_VALUES and CURSOR_OUTSIDE_BOUNDS



COMMENT @----------------------------------------------------------------------

ROUTINE:	ClipSpinTextIfNeeded

SYNOPSIS:	Clips text if the text is larger than our area.

CALLED BY:	OLSpinGadgetDrawContents

PASS:		*ds:bx -- text chunk
		ax -- left edge of where to draw text
		di -- gstate

RETURN:		carry set if clipping was needed

DESTROYED:	si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 1/92		Initial version

------------------------------------------------------------------------------@

ClipSpinTextIfNeeded	proc	near		uses	bx, cx, dx
	.enter
	push	si				;save available width 
	mov	si, ds:[bx]			;point to text
	pop	bx				;bx <- available width
	clr	cx
	call	GrTextWidth			;width of text in dx

	cmp	dx, bx				;compare to width available
	clc					;assume it fits
	jle	exit				;it does, exit (must be jle!)

	push	ax
	call	GrSaveState			;save graphics state
	mov	cx, ax				;cx,ax <- left edge to clip
	add	cx, bx				;cx <- right edge to clip
	mov	bx, MIN_COORD
	mov	dx, MAX_COORD
	mov	si, PCT_REPLACE			;new clip region
	call	GrSetClipRect
	pop	ax
	stc
exit:
	.leave
	ret
ClipSpinTextIfNeeded	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SpinSetupMoniker

SYNOPSIS:	Sets up arguments to VisDrawMoniker.  We will center the
		moniker vertically in motif, and bottom justify in open look.
		

CALLED BY:	OLSpinGadgetDraw, OLSpinGadgetMonikerPos

PASS:		*ds:si -- handle of spin gadget
		di -- gstate

RETURN:		cx -- right x inset (right inset)
		*es:bx -- moniker handle
		dx -- y offset to draw moniker (left inset)
		ax -- x offset to draw moniker

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/89	Initial version

------------------------------------------------------------------------------@

SpinSetupMoniker	proc	near
	class	OLSpinGadgetClass
	
	push	di				;save gstate
	mov	ax, C_BLACK
if USE_COLOR_FOR_DISABLED_GADGETS
	call	CF_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jnz	setColorOK			;enabled, OK, branch
	mov	ax, DISABLED_COLOR
setColorOK:
	pop	di
	push	di	
endif
	call	GrSetTextColor
	call	GrSetLineColor

	mov	ax, MSG_SPEC_SPIN_GET_ITEM	;get current item
	call	CF_ObjCallInstanceNoLock
	mov	bx, bp				;keep in bx
	call	CF_DerefVisSpecDI
	mov	dx, ds:[di].OLSGI_desWidth	;desired width in dx	
	
	pop	bp				;restore gstate
	push	dx				;save maximum moniker width
	push	bx				;save moniker handle
	segmov	es, ds				;vis moniker in *es:bx

if	0
	test	ds:[di].OLSGI_attrs, mask OLSGA_TEXT
	mov	di, bx				;moniker in es:di
	jnz	textHt				;if text, branch
	call	SpecGetMonikerSize		;get height of moniker
	mov	di, bp				;gstate into di
	jmp	short getPos			;and branch
textHt:
endif

	mov	di, bp				;gstate in di
	push	si				;
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED	;si <- info to return, rounded
	call	GrFontMetrics			;dx -> height
	pop	si
getPos:
	push	di				;save gstate
	push	es:[LMBH_handle]
	call	GetTextPosition			;get position to put moniker

	;
	; hack to avoid position change when text object replaces value
	; on CGA-like pen systems - brianc 6/4/93
	;
	call	OpenCheckIfCGA
	jnc	20$
	call	CheckIfLargeHeight
	jnc	20$				;not large height, no adjustment
	inc	dx				;move text down a pixel
20$:

	pop	bx				;
	call	MemDerefES			;
	call	CF_DerefVisSpecDI
	sub	dx, ds:[di].VI_bounds.R_top	;get offset to top
	sub	ax, ds:[di].VI_bounds.R_left	;get offset to left edge
	pop	di				;restore gstate to di
	pop	bx				;restore moniker handle
	pop	cx				;restore maximum moniker width
	push	di
	call	CF_DerefVisSpecDI
	sub 	cx, ds:[di].VI_bounds.R_right	;cx <- overall width - moniker
	add	cx, ds:[di].VI_bounds.R_left	;  width - offset to left
	dec	cx
	neg	cx
	sub	cx, ax
	pop	di
	ret
SpinSetupMoniker	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ClearSpinDisplay

SYNOPSIS:	Whites out area where moniker is drawn.

CALLED BY:	OLSpinGadgetDraw

PASS:		*ds:si -- handle of gadget
		di     -- gstate
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if	_OL_STYLE
	
ClearSpinDisplay	proc	near
	class	OLSpinGadgetClass
	
	mov	ax, C_BLACK			;in case we draw text later
	call	GrSetTextColor
	
	push	di
	mov	ax,GIT_PRIVATE_DATA
	call	GrGetInfo			;returns ax, bx, cx, dx
	;
	; al = color scheme, ah = display type
	;
	mov	ch, cl				;Pass DrawFlags in ch
	mov	cl, al				;Pass color scheme in cl
	and	ah, mask DF_DISPLAY_TYPE	;if color, branch
	cmp	ah, DC_GRAY_1
	mov	ax, C_WHITE			;assume b/w, we'll use white
	mov	bx, C_BLACK			;and black for the frame     
	jz	clear				;yes, branch to clear

	mov	bx, cx				;set up dark color	     
	and	bx, mask CS_darkColor		;use dark color		     
     
	mov	ax, cx				;else set up color
	ANDNF	ax, mask CS_lightColor		;use light color
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	clr	ah
clear:
	pop	di				;restore gstate
	call	GrSetAreaColor			;set area color
	
	mov	ax, bx				;get dark color		    
	call	GrSetLineColor			;set line color		    
     
	push	di				;save gstate
	call	OLSpinGadgetGetBounds		;get draw bounds of spin gadget
	mov	bx, bp				;top in bx
	
	;
	; If we're have a text object, we'll skip clearing the display area.
	;
	call	CF_DerefVisSpecDI
	mov	bp, di				;keep text ptr in bp
	tst	ds:[di].OLSGI_text		;any text object?
	pop	di				;restore gstate
	jnz	drawTextUnderline		;doing text, branch
	call	GrFillRect			;clear area
	dec	cx				;adjust for line drawing
	dec	dx
	
drawTextUnderline:
	xchg 	di, bp				;di <- text ptr, bp <- gstate

if	0
	test	ds:[di].OLSGI_attrs, mask OLSGA_TEXT
	mov 	di, bp				;restore gstate
	jz	exit				;not doing text, done
endif

	mov	bx, dx				;get bottom of this thing
	sub	ax, SPIN_CONTENT_MARGIN		;get past edges of the content
	add	cx, SPIN_CONTENT_MARGIN
	call	GrDrawHLine			;draw a line
	dec	bx				;move up
	push	ax
	mov	ax, C_WHITE			;draw a white line
	call	GrSetLineColor
if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	al, SDM_50 or mask SDM_INVERSE	;in case disabled
	call	GrSetAreaMask
endif
	pop	ax
	call	GrDrawHLine			;draw another line
	push	di
	call	CF_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	pop	di
	jnz	exit				;enabled, branch
	inc	cx				;adjust for area drawing
	inc	dx
	call	GrFillRect			;else grey out the other dots
exit:
	ret
ClearSpinDisplay	endp

endif
	
	
if	_CUA or _MAC

ClearSpinDisplay	proc	near
	class	OLSpinGadgetClass
	
if	_CUA or _MAC
	mov	ax, C_WHITE			;assume b/w, we'll use white
	call	GrSetAreaColor			;set area color
	mov	ax, C_BLACK			;and black for the frame     
	call	GrSetLineColor			;set line color		    
	call	GrSetTextColor
endif
	;
	; If enabled
	;	If not text object
	;		clear spin gadget drawing area
	; else
	;	clear spin gadget, including frame
	;
	push	di				;save gstate
	call	OLSpinGadgetGetBounds		;get draw bounds of spin gadget
	mov	bx, bp				;top in bx
	
	call	CF_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	disabled			;if disabled, always clear
	
	call	CF_DerefVisSpecDI
	tst	ds:[di].OLSGI_text		;any text object?
	jmp	short maybeClear
	
disabled:	
	sub	ax, SPIN_CONTENT_MARGIN		;get outside these margins  
	add	cx, SPIN_CONTENT_MARGIN		;get outside these margins  
	dec	bx				;get up to border
	inc	dx
	test	dx, 0				;force zero flag
	
maybeClear:
	pop	di				;restore gstate
	jnz	drawFrame			;doing text and enabled, branch
	call	GrFillRect			;else clear area
	
drawFrame:
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
 	pop	di				;restore gstate
 	jz	exit				;no frame, we're done
 	
	push	di				;save gstate
	call	OLSpinGadgetGetBounds		;get draw bounds of spin gadget
	mov	bx, bp				;top in bx
	sub	ax, SPIN_CONTENT_MARGIN		;get outside these margins  
	add	cx, SPIN_CONTENT_MARGIN		;get outside these margins  
						;  (frame overlaps scrollbar)
	dec	bx				;get up to border
	pop	di				;restore gstate
	call	GrDrawRect			;draw a frame		      
exit:
	ret
ClearSpinDisplay	endp

endif
	
	
if	_MOTIF or _PM

ClearSpinDisplay	proc	near
	class	OLSpinGadgetClass
	ltColor		local	word
	rbColor		local	word
JEDI <	oldMask		local	word					>
	
	.enter
	push	di
	mov	ltColor, C_BLACK			;and black for the frame     
	mov	rbColor, C_BLACK
	
	mov	ax,GIT_PRIVATE_DATA
	call	GrGetInfo			;returns ax, bx, cx, dx
	;
	; al = color scheme, ah = display type
	;
	mov	ch, cl				;Pass DrawFlags in ch
	mov	cl, al				;Pass color scheme in cl
	and	ah, mask DF_DISPLAY_TYPE	;
	cmp	ah, DC_GRAY_1
	mov	ax, C_WHITE			;assume fill color to be C_WHITE
	jz	clear				;black and white, branch 

	mov	bx, cx				;set up dark color	     
	and	bx, mask CS_darkColor		;use dark color		     
	mov	ltColor, bx			;store as left/top color
	mov	rbColor, C_WHITE		;store right/bottom color
     
	mov	ax, cx				;else set up color
	ANDNF	ax, mask CS_lightColor		;use light color
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	clr	ah
clear:
	call	GrSetAreaColor			;set area color
	mov	ax, ltColor			;and black for the frame     
	call	GrSetLineColor			;set line color		    
     
	;
	; If enabled
	;	If not text object
	;		clear spin gadget drawing area
	; else
	;	clear spin gadget, including frame
	;
	push	di				;save gstate
	push	bp
	call	OLSpinGadgetGetBounds		;get draw bounds of spin gadget
	mov	bx, bp				;top in bx
	pop	bp
	
	call	CF_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	disabled			;if disabled, always clear
	
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jnz	doSlider

	tst	ds:[di].OLSGI_text		;any text object?
	pop	di
	jz	fillRect			;no text, do clear
	jmp	short drawFrame			;text object, draw frame

doSlider:
	pop	di				;slider

	call	CheckIfFloatingText
	jnc	10$
	call	AdjustRectToEntireRange		 ;clear entire text range
10$:
	jmp	short fillRect
		
	
disabled:	
	sub	ax, SPIN_CONTENT_MARGIN		;get outside these margins  
	add	cx, SPIN_CONTENT_MARGIN		;get outside these margins  
	dec	bx				;get up to border
	inc	dx
	pop	di
	
fillRect:
if _JEDIMOTIF
	;
	; We need to fill the entire bounds (specifically the
	; right edge) if we're in the title bar.  Apparently
	; nobody has had this problem until Jedi, probably
	; because the background wash color for spin gadgets
	; is always the same as the color for the parent. -stevey
	;
	inc	cx
endif
	call	GrFillRect			;else clear area
	
drawFrame:
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
 	pop	di				;restore gstate
 	jz	exit				;no frame, we're done
 	
	push	di				;save gstate
	push	bp				;save local vars pointer
	call	OLSpinGadgetGetBounds		;get draw bounds of spin gadget
if not _RUDY
	dec	cx				;adjust for line drawing
	dec	dx
endif
	mov	bx, bp				;top in bx
	pop	bp				;restore local vars pointer
	sub	ax, SPIN_CONTENT_MARGIN		;get outside these margins  
	add	cx, SPIN_CONTENT_MARGIN		;get outside these margins  
	dec	bx				;get up to border
	inc 	dx				;
	pop	di				;restore gstate

if _RUDY
	push	bp
	mov	bp, C_LIGHT_GREY or (C_LIGHT_GREY shl 8)
	push	ax, bx
	push	ax, bx, bp
	call	OpenDrawRect
	pop	ax, bx, bp
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	call	OpenDrawRect
	inc	cx
	inc	dx

	mov	ax, C_LIGHT_GREY
	call	GrSetAreaColor
	pop	ax, bx

	mov	cx, ax
	sub	ax, RUDY_SPIN_LEFT_AREA_WIDTH
	call	GrFillRect
	pop	bp
else
if _JEDIMOTIF
	;
	; frame is always in 50% pattern
	;
	push	ax				; save line left
	mov	al, GMT_ENUM
	call	GrGetLineMask			; al = current line mask
	mov	oldMask, ax
	mov	al, SDM_50			; draw 50%
	call	GrSetLineMask
	pop	ax				; ax = line left
endif
	call	GrDrawVLine			; draws left line
	call	GrDrawHLine			; draws top line
	
	push	ax				; save left edge
	mov	ax, rbColor			; now r/b color
	call	GrSetLineColor			; set as line color
	mov	ax, cx				; doing right edge
	call	GrDrawVLine
	pop	ax				; restore left edge
	mov	bx, dx				; doing bottom  line
	call	GrDrawHLine			;
if _JEDIMOTIF
	mov	ax, oldMask			; restore line mask
	call	GrSetLineMask
endif
endif

exit:
	.leave
	ret

ClearSpinDisplay	endp



endif



CommonFunctional ends

;--------------------------

SpinGadgetCommon segment resource

SGC_DerefVisSpecDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
SGC_DerefVisSpecDI	endp

SGC_DerefGenDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
SGC_DerefGenDI	endp

SGC_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
SGC_ObjCallInstanceNoLock	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetDownPage -- 
		MSG_SPEC_SPIN_DOWN_PAGE for OLSpinGadgetClass

DESCRIPTION:	Handles a down page press in a slider.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_DOWN_PAGE

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
	chris	10/17/92		Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetDownPage	method dynamic	OLSpinGadgetClass, \
				MSG_SPEC_SPIN_DOWN_PAGE
	mov	bx, MSG_SPEC_SPIN_INCREMENT
	mov	ax, MSG_SPEC_SPIN_DECREMENT
	GOTO	ScrollBasedOnOrientation

OLSpinGadgetDownPage	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetUpPage -- 
		MSG_SPEC_SPIN_UP_PAGE for OLSpinGadgetClass

DESCRIPTION:	Handles a press in a slider`s page up area.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_UP_PAGE

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
	chris	10/17/92	Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetUpPage	method dynamic	OLSpinGadgetClass, \
				MSG_SPEC_SPIN_UP_PAGE

	mov	bx, MSG_SPEC_SPIN_DECREMENT
	mov	ax, MSG_SPEC_SPIN_INCREMENT

ScrollBasedOnOrientation	label	far
	;
	; Page up area clicked in slider -- we'll do the right thing based on
	; the orientation of this thing.
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jnz	10$
	mov	ax, bx
10$:
	GOTO	SetUpRepeatScroll

OLSpinGadgetUpPage	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetUpArrow -- 
		MSG_SPEC_SPIN_UP_ARROW for OLSpinGadgetClass

DESCRIPTION:	Handles scroll up methods coming from the scrollbar.  Basically
		this just turns it into a MSG_SPEC_SPIN_INCREMENT.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_UP_ARROW

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetUpArrow	method OLSpinGadgetClass, MSG_SPEC_SPIN_UP_ARROW
	mov	ax, MSG_SPEC_SPIN_INCREMENT
if SLIDER_INCLUDES_VALUES
	mov	bx, MSG_SPEC_SPIN_DECREMENT
endif
	;
	; Send again to scrollbar.
	;
SetUpRepeatScroll	label	far
if SLIDER_INCLUDES_VALUES
	;
	; Page up area clicked in slider -- we'll do the right thing based on
	; the orientation of this thing.
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	vert
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jnz	vert
	mov	ax, bx
vert:
endif
	call	SGC_ObjCallInstanceNoLock		;send to ourselves
	;
	; Set up a delay.  For the first few repeats, we'll repeat slowly; then
	; we'll crank it up.
	;
	call	SGC_DerefVisSpecDI
	mov	cx, ds:[di].OLSGI_repeatCount	;pass repeat count	
	tst	cx				;no repeats yet?
	jnz	10$				;yes, get normal repeat rate
	mov	cx, SPIN_FIRST_DELAY		;else enforce an initial delay
	jmp	short 20$			;and branch
10$:
	mov	ax, MSG_SPEC_SPIN_GET_REPEAT_RATE	;get repeat rate in cx
	call	SGC_ObjCallInstanceNoLock
20$:
	call	SGC_DerefVisSpecDI
	push	si				;save our handle
	mov	si, ds:[di].VCI_comp.CP_firstChild.chunk	
	mov	bx, ds:[LMBH_handle]
	mov	dx, MSG_REPEAT_SCROLL
	mov	ax, TIMER_EVENT_ONE_SHOT
	call	TimerStart			;
	pop	si				;restore spin gadget handle
	call	SGC_DerefVisSpecDI
	inc	ds:[di].OLSGI_repeatCount	;bump repeat count
	mov	ds:[di].OLSGI_timerID, ax	;save these	
	mov	ds:[di].OLSGI_timerHandle,bx
	ret

OLSpinGadgetUpArrow	endm

			

COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetDownArrow -- 
		MSG_SPEC_SPIN_DOWN_ARROW for OLSpinGadgetClass

DESCRIPTION:	Handles scroll down methods coming from the scrollbar. Basically
		this just turns it into a MSG_SPEC_SPIN_DECREMENT

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_DOWN_ARROW

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetDownArrow	method OLSpinGadgetClass, MSG_SPEC_SPIN_DOWN_ARROW
	mov	ax, MSG_SPEC_SPIN_DECREMENT
if SLIDER_INCLUDES_VALUES
	mov	bx, MSG_SPEC_SPIN_INCREMENT
endif
	GOTO	SetUpRepeatScroll
OLSpinGadgetDownArrow	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGetRepeatRate -- 
		MSG_SPEC_SPIN_GET_REPEAT_RATE for OLSpinGadgetClass

DESCRIPTION:	Sets repeat rate for the spin gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_GET_REPEAT_RATE
		cx	- number of repeats so far

RETURN:		cx 	- repeat rate to use

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 4/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetGetRepeatRate method OLSpinGadgetClass, MSG_SPEC_SPIN_GET_REPEAT_RATE
	push	ds
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	mov	ax, cx				;save number of repeats
	mov	cx, ds:[olGadgetRepeatDelay]	;get delay

	tst	ds:[olGadgetAccelerate]		;should we accelerate?
	jz	10$

	sub	cx, ax				;accelerate as rep increases
	jns	10$
	clr	cx				;no delay
10$:
	pop	ds
	ret
OLSpinGadgetGetRepeatRate	endm

SpinGadgetCommon ends

;------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGetBounds -- 
		MSG_SPEC_SPIN_GET_BOUNDS for OLSpinGadgetClass

DESCRIPTION:	Returns bounds of diaply area.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_GET_BOUNDS

RETURN:		ax, bp, cx, dx -- bounds of display area
		(bx has top if called internally)

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OLSpinGadgetGetBounds	method OLSpinGadgetClass, MSG_SPEC_SPIN_GET_BOUNDS

	mov	ax, MSG_VIS_COMP_GET_MARGINS	;get control margins
	mov	di, segment OLSpinGadgetClass
	mov	es, di
	mov	di, offset OLSpinGadgetClass
	call	ObjCallSuperNoLock		;  in ax/bp/cx/dx

	call	CF_DerefVisSpecDI
	add	ax, ds:[di].VI_bounds.R_left	;add in real bounds
	add	bp, ds:[di].VI_bounds.R_top

	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
	jz	10$				;no frame on gadget, branch
CUAS <	inc	bp				;get off border		       >
CUAS <	add	ax, SPIN_CONTENT_MARGIN		;move left edge over a bit     >
10$:     
	mov	cx, ax				;left edge in cx
	mov	dx, bp				;right edge in dx
	call	GetSpinAreaSize			;returns size in di, bx
	add	cx, di				;add desired width to get right	
	add	dx, bx
	mov	bx, bp				;return top in bx as well
	ret
OLSpinGadgetGetBounds	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSpinAreaSize

SYNOPSIS:	Returns a size for the spin area.

CALLED BY:	OLSpinGadgetGetBounds

PASS:		*ds:si -- spin gadget
		ds:di -- SpecInstance

RETURN:		di, bx -- height, width of spin text area

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/23/92		Initial version

------------------------------------------------------------------------------@

GetSpinAreaSize	proc	near		uses	ax, bp, cx, dx, si
	.enter
	mov	cx, ds:[di].OLSGI_desWidth	;add desired width to get right	
	mov	dx, ds:[di].OLSGI_desHeight

	call	CheckIfLargeHeight
	jnc	10$
	add	dx, SPIN_EXTRA_PEN_MARGIN*2
10$:

	;
	; If using a non-slider scrollbar, take the larger or the heights.
	;	
	test 	ds:[di].OLSGI_attrs, mask OLSGA_NO_UP_DOWN_ARROWS or \
				     mask OLSGA_SLIDER
	jz	doScrollbars			;Don't have arrows, or slider,
						;  skip all this

	;
	; No scrollbars, account for frame if there is one, then get out.
	; 8/25/94 cbh
	;
	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
	jz	done
	add	dx, 1+1							
	jmp	short done

doScrollbars:
	push	cx, dx
	clr	cx
	clr	dx

	;
	; Pass a reasonable height to the scrollbar.  -cbh 2/26/93
	;
	mov	dx, ds:[di].OLSGI_desHeight
CUAS <	add	dx, 1+1				;magic constants.  Love 'em. >
	call	CheckIfLargeHeight
	pushf
	jnc	15$
	add	dx, SPIN_EXTRA_PEN_MARGIN*2
15$:
	mov	si, ds:[di].VCI_comp.CP_firstChild.chunk	
EC <	tst	si				;is there a scrollbar?	   >
EC <	ERROR_Z	OL_ERROR			;yes, die 		   >

	mov	ax, MSG_VIS_RECALC_SIZE		;scrollbar height in dx
	call	ObjCallInstanceNoLock

	popf					;large height, knock off space
	jnc	17$
	sub	dx, SPIN_EXTRA_PEN_MARGIN*2
17$:
	pop	cx, bx				;calc'ed height in bx
	sub	dx, 1+1				;account for edges when doing
						;  this.
	cmp	dx, bx				;take the larger
	jge	done
	mov	dx, bx
done:	
	mov	di, cx
	mov	bx, dx
	.leave
	ret
GetSpinAreaSize	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetSetItem -- 
		MSG_SPEC_SPIN_SET_ITEM for OLSpinGadgetClass

DESCRIPTION:	Sets a new item to be drawn.  If we're a text spin gadget, 
		stores a new text chunk.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_SET_ITEM
		bp      - handle of new moniker or text chunk.

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetSetItem	method dynamic OLSpinGadgetClass, MSG_SPEC_SPIN_SET_ITEM
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
if SLIDER_INCLUDES_VALUES
	;
	; nothing to redraw if slider
	;
	jnz	exit
endif
	jz	10$
if _JEDIMOTIF
	;
	; in JEDI sliders, HINT_VALUE_NO_DIGITIAL_DISPLAY is the default,
	; so we look for HINT_VALUE_DIGITAL_DISPLAY, if not there, don't
	; bother clearing anything or drawing anything
	;
	mov	ax, HINT_VALUE_DIGITAL_DISPLAY
	call	ObjVarFindData			; carry set if found
	jnc	10$				; not found
endif
	push	bp
	call	ViewCreateDrawGState
	tst	di
	jz	5$
	push	di
	call	ClearSpinDisplay		;clear old text now.
	pop	di
	call	GrDestroyState
5$:
	call	PositionSpinText		;make text follow scrollbar
	pop	bp
10$:

	call	CF_DerefVisSpecDI
	tst	ds:[di].OLSGI_text		;is there a text object around?
	jnz	doText				;yes, go deal with it
	
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID
	jnz	exit				;get out if invalid
	mov	ax, MSG_SPEC_SPIN_DRAW_CONTENTS	;else redraw the moniker
	call	CF_ObjCallInstanceNoLock
	jmp	short exit
	
doText:

if SELECT_ENTIRE_SPIN_GADGET_TEXT_ON_GAINED_FOCUS

	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	pushf
endif
	mov	si, ds:[di].OLSGI_text		;set a new text chunk
	call	CF_DerefVisSpecDI
	mov	ds:[di].VTI_text, bp		;set new text chunk.

	ChunkSizeHandle	ds, bp, dx		;dx <- text length.
DBCS <	shr	dx, 1							>
	dec	dx
	mov	cx, dx				;assume we're selecting end

if SELECT_ENTIRE_SPIN_GADGET_TEXT_ON_GAINED_FOCUS
	popf					;slider?  Then don't select text
	jnz	selectEndOnly
	clr	cx				;select entire range
selectEndOnly:			
endif

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	CF_ObjCallInstanceNoLock

redrawOnly:
	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW	;
	GOTO	ObjCallInstanceNoLock		;
exit:						;
	ret					;
OLSpinGadgetSetItem	endm

CommonFunctional ends

;-----------------------

SpinGadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetStartSelect -- 
		MSG_META_START_SELECT for OLSpinGadgetClass

DESCRIPTION:	Does normal things, but also clears the repeat count.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_START_SELECT
		cx, dx	- button position
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:		bp = InkDestinationParams (if msg = QUERY_IF_PRESS_IS_INK)

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetStartSelect	method OLSpinGadgetClass, MSG_META_START_SELECT,
						  MSG_META_QUERY_IF_PRESS_IS_INK
	flags	local	word	\
		push	bp
;
;	NOTE! We use the fact that "flags" is a push-initialized local var to
;	assign a return value to BP. Don't change it!
;

	xPos	local	word	\
		push	cx
	yPos	local	word	\
		push	dx
	msg	 local	word	\
		push	ax
	.enter
	;
	; Turn off repeating flag so we can have a long initial delay.
	;
	push	di
	call	SGC_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
	LONG	jnz	exitReplay		;not editable, get out!

	test 	ds:[di].OLSGI_attrs, mask OLSGA_NO_UP_DOWN_ARROWS
	jnz	10$				;Don't want arrows, branch

	clr	ds:[di].OLSGI_repeatCount	;clear the repeat count
	mov	ax, ds:[di].OLSGI_timerID	;turn off timer, if any
	mov	bx, ds:[di].OLSGI_timerHandle
	call	TimerStop
10$:	
	mov	di, offset OLSpinGadgetClass	;go handle click
	mov	ax, msg
	push	bp
	mov	bp, flags
	call	ObjCallSuperNoLock		;cx = pointer image handle
	pop	bp
	
	;
	; On any click, we'll build a text object so that editing can be done
	; on the value.  
	;
	call	SGC_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT
	LONG jnz	exitReplay			;get out if can't edit.

	tst	ds:[di].OLSGI_text		;have we built a text object?
if _JEDIMOTIF
	;
	; if have text, give focus to it (needed for click on inc/dec buttons)
	;
	jz	noText
	push	ax, cx, dx, bp, si
	call	GiveTextFocusNow
	pop	ax, cx, dx, bp, si
	jmp	sendPressThrough

noText:
else
	jnz	sendPressThrough		;yes, don't need to build
endif
	
	;
	; Let's make sure the range has the focus here, unless it's in a
	; toolbox.  (New code here to take the focus, but make it menu-related 
	; instead.   This will allow returning the focus to the previous 
	; holder when the user presses return.  -cbh 11/16/92.)
	;
	push	ax, cx, dx, bp
	clr	bp				;assume not menu related
	call	SGC_DerefVisSpecDI
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	notInToolbox			;not toolbox, not menu related
	mov	bp, mask MAEF_OD_IS_MENU_RELATED
notInToolbox:
	or	bp, mask MAEF_GRAB or mask MAEF_FOCUS or mask MAEF_NOT_HERE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp			;restore method args

sendPressThrough:	
	cmp	msg, MSG_META_START_SELECT	;fixed 4/ 9/93 cbh
	je	checkAlreadyProcessed

	cmp	ax, IRV_NO_INK
	je	exit				;child returned no ink, exit
						; (pre-passive set up when
						;  START_SELECT comes through.)
	jmp	short sendToText	

checkAlreadyProcessed:
	test	ax, mask MRF_PROCESSED		;see if event handled
	jnz	exitWithPrePassive		;yes, don't need to send on.

sendToText:
	call	SGC_DerefVisSpecDI
	mov	di, ds:[di].OLSGI_text		;else send on to text object
	tst	di				;is there a text object?
	jz	exitReplay			;no, don't send this to it
	mov	cx, xPos
	mov	dx, yPos
	mov	ax, msg

	push	bp, si
	mov	si, di
	mov	bp, flags
	call	ObjCallInstanceNoLock
	mov	di, bp
	pop	bp, si
	mov	flags, di		;Return value in BP - since "flags"
					; was push-initialized with BP, 
					; when we exit the app, BP will be
					; reloaded with the value in that
					; local variable.

exitWithPrePassive:
	;
	; Code to set up a pre-passive mouse grab, so we can give up the focus
	; on any future click.  -cbh 11/16/92
	;
	call	SGC_DerefVisSpecDI
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	exit			;not toolbox, not menu related
	push	ax, cx, dx, bp
	call	VisAddButtonPrePassive
	pop	ax, cx, dx, bp
	jmp	short exit

exitReplay:
	mov	ax, mask MRF_REPLAY		;assume start select
	cmp	msg, MSG_META_START_SELECT
	je	exit
	mov	ax, IRV_NO_INK
exit:
	.leave
	ret
	
OLSpinGadgetStartSelect	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGainedFocusExcl -- 
		MSG_META_GAINED_FOCUS_EXCL for OLSpinGadgetClass

DESCRIPTION:	Called when navigation gives the range object the focus.
		Builds out a fine text object and passes the focus along to it.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_GAINED_FOCUS_EXCL

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/23/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetGainedFocusExcl method OLSpinGadgetClass, MSG_META_GAINED_FOCUS_EXCL

if 0
EC <	test 	ds:[di].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT		>
EC <	ERROR_NZ  OL_ERROR			;shouldn't happen	>
endif

	or	ds:[di].OLSGI_states, mask OLSGS_HAS_FOCUS
	;
	; If running text, we'll build a text object so that editing can be done
	; on the value.  
	;
if	0
	test	ds:[di].OLSGI_attrs, mask OLSGA_TEXT	
	jnz	istext				;if text, branch
	call	OpenDrawObject			;else redraw the moniker
	jmp	short exit			;and exit
istext:
endif

if SLIDER_INCLUDES_VALUES
	;
	; if slider, redraw to show focus
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
	call	OpenDrawObject			; redraw to show focus
	jmp	short exit

notSlider:
endif

	call	CheckIfFloatingText		;floating text, forget all this
	jc	exit				;yep, exit.

	tst	ds:[di].OLSGI_text		;have we built a text object?
	jz	create				;yes, don't need to build
	;
	; Give the text the focus, after a trip through the queueueueueue.
	;
	clr	bp
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	mov	ax, MSG_SPIN_GIVE_TEXT_FOCUS
	call	ObjMessage	
	jmp	short exit
create:
	call	CreateSpinText			;let's create the object
exit:
if _JEDIMOTIF
	;
	; if JEDI slider/gauge, redraw if we have moniker (focus is shown
	; with cursor around moniker)
	;
	call	SGC_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	notSlider
	call	SGC_DerefGenDI
	tst	ds:[di].GI_visMoniker
	jz	notSlider
	call	OpenDrawObject
notSlider:
endif
	ret
OLSpinGadgetGainedFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSpinGadgetGainedSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set floating keyboard type

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL
PASS:		*ds:si	= OLSpinGadgetClass object
		ds:di	= OLSpinGadgetClass instance data
		ds:bx	= OLSpinGadgetClass object (same as *ds:si)
		es 	= segment of OLSpinGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DUI

OLSpinGadgetGainedSysFocusExcl	method dynamic OLSpinGadgetClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL
	.enter
	;
	; call superclass for default handling
	;
	mov	di, offset OLSpinGadgetClass
	call	ObjCallSuperNoLock
	;
	; set keyboard type, if doing keyboard
	;
	call	CheckIfKeyboardRequired
	jnc	done
	call	SetKeyboardType
done:
	.leave
	ret
OLSpinGadgetGainedSysFocusExcl	endm

endif
				


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGiveTextFocus -- 
		MSG_SPIN_GIVE_TEXT_FOCUS for OLSpinGadgetClass

DESCRIPTION:	Gives the text object the focus, if the range object still
		has the focus.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPIN_GIVE_TEXT_FOCUS

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/31/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetGiveTextFocus method OLSpinGadgetClass, MSG_SPIN_GIVE_TEXT_FOCUS
	mov	dx, si
	call	CompareWithCurrentFocus		;see if range has current focus
	jne	exit				;we lost it somehow, branch

if _JEDIMOTIF
	call	GiveTextFocusNow

	clr	cx
	clr	dx
	dec	dx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	clr	di
	call	ObjMessage
exit:
	ret
OLSpinGadgetGiveTextFocus	endm

GiveTextFocusNow	proc	far
endif

	;
	; Give the text object the focus.
	;
	call	SGC_DerefVisSpecDI
	mov	bx, ds:[LMBH_handle]
	mov	si, ds:[di].OLSGI_text
	tst	si				;get out if no text
						;92.07.29 cbh
	jz	exit

	;
	; Changed to make the thing menu related if in a toolbox, so toolbox
	; spin gadgets will give back the focus when needed.  -cbh 11/16/92
	;
	clr	bp				;assume not menu related
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	notInToolbox			;not toolbox, not menu related
	mov	bp, mask MAEF_OD_IS_MENU_RELATED
notInToolbox:
	or	bp, mask MAEF_GRAB or mask MAEF_FOCUS or mask MAEF_NOT_HERE
if _JEDIMOTIF
	;
	; grab target as well, if targetable
	;
EC <	push	es							>
EC <	mov	di, segment VisTextClass				>
EC <	mov	es, di							>
EC <	mov	di, offset VisTextClass					>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	-1						>
EC <	pop	es							>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_state, mask VTS_TARGETABLE
	jz	noTarget
	ornf	bp, mask MAEF_TARGET
noTarget:
endif
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

if _JEDIMOTIF
	;
	; selection is done in OLSpinGadgetGiveTextFocus, as we don't want
	; it for OLSpinGadgetStartSelect (which calls GiveTextFocusNow)
	;
exit:
	ret
GiveTextFocusNow	endp

else

if SELECT_ENTIRE_SPIN_GADGET_TEXT_ON_GAINED_FOCUS
	clr	cx
	clr	dx
	dec	dx
else
	call	SGC_DerefVisSpecDI
	mov	di, ds:[di].VTI_text
	ChunkSizeHandle	ds, di, dx		;dx <- text length.	
DBCS <	shr	dx, 1							>
	dec	dx				
	mov	cx, dx				;select end
endif
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
OLSpinGadgetGiveTextFocus	endm

endif



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetPrePassiveButton -- MSG_META_PRE_PASSIVE_BUTTON

DESCRIPTION:	Handler for Passive Button events (see CTTFM description,
		top of cwinClass.asm file.)

	(We know that REFM mechanism does not rely on this procedure, because
	REFM does not request a pre-passive grab.)

PASS:
	*ds:si - instance data
	es - segment of OLSpinGadgetClass

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

OLSpinGadgetPrePassiveButton	method dynamic	OLSpinGadgetClass, \
						MSG_META_PRE_PASSIVE_BUTTON

	;translate method into MSG_META_PRE_PASSIVE_START_SELECT etc. and
	;send to self. (See OpenWinPrePassStartSelect)

	mov	ax, MSG_META_PRE_PASSIVE_BUTTON
	call	OpenDispatchPassiveButton
	ret

OLSpinGadgetPrePassiveButton	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetPrePassiveStartSelect -- 
		MSG_META_PRE_PASSIVE_START_SELECT for OLSpinGadgetClass

DESCRIPTION:	Handles pre-passive start selects.  We'll take this moment
		to 

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_PRE_PASSIVE_START_SELECT

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	11/16/92        Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetPrePassiveStartSelect	method dynamic	OLSpinGadgetClass, \
				MSG_META_PRE_PASSIVE_START_SELECT

	push	cx, dx, bp
	;
	; Don't do anything on double-presses.  Either the second click of
	; the double press was on the spin gadget itself, or else we wouldn't
	; be here.  -cbh 11/25/92
	;
	test	bp, mask BI_DOUBLE_PRESS
	jnz	exit

	;
	; We just want to lose our focus if we're in a toolbox.
	; 
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	exit
	;
	; remove pre-passive, if in toolbox, we won't gain or lose focus, so
	; we'll never lose focus, and hence never remove button pre-passive
	; what the heck is this pre-passive for anyway? - brianc 1/17/94
	;
	call	VisRemoveButtonPrePassive
	mov	si, ds:[di].OLSGI_text
	tst	si				;get out if no text
	jz	exit
	mov	bp, mask MAEF_OD_IS_MENU_RELATED or mask MAEF_FOCUS or \
		    mask MAEF_NOT_HERE
	mov	cx, ds:[LMBH_handle]
	mov	bx, cx
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	pop	cx, dx, bp
	mov	ax, mask MRF_PROCESSED
	ret
OLSpinGadgetPrePassiveStartSelect	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetAlterFTVMCExcl -- 
		MSG_META_MUP_ALTER_FTVMC_EXCL for OLSpinGadgetClass

DESCRIPTION:	Messes with exclusives.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_MUP_ALTER_FTVMC_EXCL
		^lcx:dx - object requesting excl
		bp      - MetaAlterFTVMCExclFlags

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
	chris	11/16/92         	Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetAlterFTVMCExcl	method dynamic	OLSpinGadgetClass, \
				MSG_META_MUP_ALTER_FTVMC_EXCL

	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	notInToolbox			;not toolbox, not menu related
	or	bp, mask MAEF_OD_IS_MENU_RELATED
notInToolbox:

	mov	di, offset OLSpinGadgetClass
	call	ObjCallSuperNoLock
	ret
OLSpinGadgetAlterFTVMCExcl	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateSpinText

SYNOPSIS:	Creates a vis text object for the spin gadget, resizes it,
		positions it, opens it, grabs the focus.

CALLED BY:	OLSpinGadgetBuild

PASS:		*ds:si -- handle of spin gadget

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/18/89	Initial version

------------------------------------------------------------------------------@

CreateSpinText	proc	near
	class	OLSpinGadgetClass
	
	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	push	si				;save spin gadget handle
	mov	ax, MSG_SPEC_SPIN_GET_ITEM	;get current item in bp
	call	SGC_ObjCallInstanceNoLock

	call	CheckIfLargeHeight		;save whether doing large height
	pushf	

if SELECT_ENTIRE_SPIN_GADGET_TEXT_ON_GAINED_FOCUS
	call	SGC_DerefVisSpecDI		;slider? save whither...
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	pushf
endif

	push	bp				;save it
	;
	; Instantiate a vis text object.
	;
if _RUDY
	mov	di, offset UnderlinedVisTextClass
	mov	ax, segment UnderlinedVisTextClass
else
	mov	di, offset VisTextClass		;instantiate the text
	mov	ax, segment VisTextClass
endif
	mov	es, ax
	mov	bx,ds:[LMBH_handle]
	call	GenInstantiateIgnoreDirty
	mov	bx, offset Vis_offset
	call	ObjInitializePart		;will initialize text
	;
	; Set some instance data things.
	; 
	call	SGC_DerefVisSpecDI
	pop	bp				;restore current text handle
	mov	ds:[di].VTI_text, bp		;store current item (text chunk)
	
	;
	; Set up text object to filter TABs and send them to us so we
	; can do proper navigation.
	;
	or	ds:[di].VTI_filters, mask VTF_NO_TABS
	
	ChunkSizeHandle	ds, bp, dx		;dx <- text length.	
DBCS <	shr	dx, 1							>
	dec	dx				;
	mov	cx, dx				;assume selecting end

if SELECT_ENTIRE_SPIN_GADGET_TEXT_ON_GAINED_FOCUS
	popf					;slider?
	jnz	16$				;yes, select end only
	clr	cx				;select entire range.
16$:
endif

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	SGC_ObjCallInstanceNoLock

	call	SGC_DerefVisSpecDI
	or	ds:[di].VTI_state, mask VTS_EDITABLE or mask VTS_ONE_LINE

	popf
	jnc	17$
	mov	ds:[di].VTI_tbMargin, SPIN_EXTRA_PEN_MARGIN
17$:

	;
	; Make sure the text is unmanaged, so we can place it where we want.
	;
	and	ds:[di].VI_attrs, not mask VA_MANAGED

	;
	; If we're not allowing the spin gadget to be editable, don't
	; allow the text object to be editable either.    We still may
	; be creating one for spin gadgets to show focus.  6/ 5/94 cbh
	;
	pop	bx				;get spin gadget handle
	push	bx				;save again
	mov	bx, ds:[bx]			
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT
	jz	18$
	and	ds:[di].VTI_state, not mask VTS_EDITABLE
18$:

if _JEDIMOTIF
	;
	; If gen object is marked targetable, mark text as targetable as well
	;
	test	ds:[bx].VI_typeFlags, mask VTF_IS_GEN
	jz	notTargetable
	pop	bx				;get spin gadget handle
	push	bx				;save again
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GI_attrs, mask GA_TARGETABLE
	jz	notTargetable
	ornf	ds:[di].VTI_state, mask VTS_TARGETABLE
notTargetable:
endif

	;
	; Set the output of the text object.
	;
	pop	bx				;get spin gadget handle
	push	bx				;save again
	mov	ds:[di].VTI_output.chunk, bx	
	mov	bx, ds:[LMBH_handle]		
	mov	ds:[di].VTI_output.handle, bx
	
	mov	ax, segment dgroup
	mov	es, ax
	mov	al, es:[moCS_dsLightColor]	; al <- bg color
	mov	cl, al				; Red (or color) component
	clr	ah
   
	mov	ch, CF_INDEX
	clr	dx				; 
	mov	ax, MSG_VIS_TEXT_SET_WASH_COLOR	;
	call	SGC_ObjCallInstanceNoLock		;
	
	;
	; Add the text object to the parent.
	;
	mov	cx, ds:[LMBH_handle]		;add text object to parent
	mov	dx, si
	pop	si				;restore parent handle
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	ds:[di].OLSGI_text, dx		;save text handle in spin inst	
	push	dx				;save text handle
	mov	bp, CCO_LAST			;add at end
	mov	ax, MSG_VIS_ADD_CHILD
	call	SGC_ObjCallInstanceNoLock
	pop	di				;restore text handle
	
	push	di				;save handle of text
	call	ResizeSpinText			;resize it
	call	PositionSpinText		;position it.
	mov	bx, si				;save spin gadget handle
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED	;spin gadget realized?
	pop	si				;restore handle of text
	push	bx				;save spin gadget handle
	jz	noOpen				;not realized, don't open yet
	mov	ax, MSG_VIS_OPEN		;realize it.
	call	ObjCallInstanceNoLock
noOpen:
	call	SGC_DerefVisSpecDI
	and	ds:[di].VI_optFlags, not (mask VOF_IMAGE_INVALID or \
			                  mask VOF_IMAGE_UPDATE_PATH)

	;
	; Redraw the text object.  It may be that for some reason, the actual
	; text used is something other than what was previously on the screen.
	;
	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock

	;
	; Give the text object the focus.
	;
	pop	si				;restore spin gadget handle
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	mov	ax, MSG_SPIN_GIVE_TEXT_FOCUS
	call	ObjMessage	
	
	pop	di
	call	ThreadReturnStackSpace
	ret
	
CreateSpinText	endp

SpinGadgetCommon ends

;-----------------------

KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetKbdChar -- 
		MSG_META_KBD_CHAR for OLSpinGadgetClass

DESCRIPTION:	Handle keyboard characters.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_KBD_CHAR

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/11/90		Initial version

------------------------------------------------------------------------------@

if not _RUDY		;this behavior not needed in Rudy -- we use up/down
			;  arrows for tabbing

OLSpinGadgetKbdChar	method OLSpinGadgetClass, MSG_META_KBD_CHAR, \
						  MSG_META_FUP_KBD_CHAR
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		;skip if not press event...

	push	es

					;set es:di = table of shortcuts
					;and matching methods
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLSpinGadgetKbdBindings
	call	ConvertKeyToMethod
	pop	es
	jnc	callSuper		;skip if none found...

	;found a shortcut: send method to self.

sendToSelf:
	GOTO	ObjCallInstanceNoLock

callSuper:
	;we don't care about this keyboard event. Call our superclass
	;so it will be forwarded up the focus hierarchy.

	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	VisCallParent
	
OLSpinGadgetKbdChar	endm

;Keyboard shortcut bindings for OLSpinGadgetClass (do not separate tables)

if DBCS_PCGEOS
OLSpinGadgetKbdBindings	label	word
	word	length OLSGShortcutList
	;P     C  S  C
	;h  A  t  h  h
	;y  l  r  f  a
	;s  t  l  t  r
OLSGShortcutList KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;Increment spin gadget
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;Decrement spin gadget
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;Increment spin gadget
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>	;Decrement spin gadget
else
OLSpinGadgetKbdBindings	label	word
	word	length OLSGShortcutList
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLSGShortcutList KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_UP>,	;Increment spin gadget
	<0, 0, 0, 0, 0xf, VC_DOWN>,	;Decrement spin gadget
	<0, 0, 0, 0, 0xf, VC_RIGHT>,	;Increment spin gadget
	<0, 0, 0, 0, 0xf, VC_LEFT>	;Decrement spin gadget
endif
	
;OLSGMethodList	label word
	word	MSG_SPEC_SPIN_INCREMENT
	word	MSG_SPEC_SPIN_DECREMENT
	word	MSG_SPEC_SPIN_INCREMENT
	word	MSG_SPEC_SPIN_DECREMENT

endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLSpinGadgetActivateObjectWithMnemonic --
		MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC handler

DESCRIPTION:	Looks at its vis moniker to see if its mnemonic matches
		that key currently pressed.

PASS:		*ds:si	= instance data for object
		ax = MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		carry set if found, clear otherwise

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetActivateObjectWithMnemonic	method	OLSpinGadgetClass, \
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	call	VisCheckIfFullyEnabled
	jnc	noActivate
	;XXX: skip if menu?
	call	VisCheckMnemonic
	jnc	noActivate
	;
	; mnemonic matches, grab focus
	;
	call	MetaGrabFocusExclLow
	stc				;handled
	jmp	short exit

noActivate:
	;
	; let superclass call children, since either were are not fully
	; enabled, or our mnemonic doesn't match, superclass won't be
	; activating us, just calling our children
	;
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, offset OLSpinGadgetClass
	call	ObjCallSuperNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret
OLSpinGadgetActivateObjectWithMnemonic	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetSendToFocusParent -- 
		MSG_META_TEXT_TAB_FILTERED for OLSpinGadgetClass

DESCRIPTION:	Deals with a tab press.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_TEXT_TAB_FILTERED

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/22/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetSendToFocusParent method OLSpinGadgetClass, \
						  MSG_META_TEXT_TAB_FILTERED, 
						  MSG_META_TEXT_CR_FILTERED
	;
	; Code stuck in to allow the focus exclusive to go back to the
	; correct object.  Hopefully people won't go sticking HINT_TOOLBOX
	; in a dialog box and whine about losing the focus later. -cbh 11/16/92
	;
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	exit

	mov	bx, ds:[LMBH_handle]
	mov	di, ds:[di].OLSGI_text
	tst	di				;get out if no text
	jz	10$				;no text, use spin gadget
	mov	si, di
10$:
	mov	bp, mask MAEF_OD_IS_MENU_RELATED or mask MAEF_FOCUS or \
		    mask MAEF_NOT_HERE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
GOTO	ObjCallInstanceNoLock

exit:
	;
	; We no longer FUP, the text filtered stuff does it for us.
	; -cbh 12/15/92
	;
	ret
OLSpinGadgetSendToFocusParent	endm

KbdNavigation	ends


SpinGadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetLostFocusExcl -- 
		MSG_META_LOST_FOCUS_EXCL for OLSpinGadgetClass
		MSG_META_TEXT_LOST_FOCUS for OLSpinGadgetClass

DESCRIPTION:	Handles lost focus.  In both cases, removes the text object 
		after it sits on Death Queue for a little while. (MSG_META_LOST_
		FOCUS_EXCL happens when the text object loses the focus).

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- method

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 7/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetLostFocusExcl method OLSpinGadgetClass, MSG_META_TEXT_LOST_FOCUS, 
					  	    MSG_META_LOST_FOCUS_EXCL
	;
	; Set an internal flag.
	;
	and	ds:[di].OLSGI_states, not mask OLSGS_HAS_FOCUS
	mov	di, ds:[di].OLSGI_text		;get text object handle		
	
	tst	di				;is there one?
	jnz	istext				;yes, branch
	call	OpenDrawObject			;else redraw things
	jmp	short exit
	
istext:	
if (not _JEDIMOTIF)		; don't remove text for JEDI -- it will be
				; removed when spin gadget is unbuilt.  We
				; need the text object around to hold the
				; target -- yes, targetable GenValues (sigh).
				; - brianc 5/23/95
	mov	bx, ds:[LMBH_handle]		
	mov	ax, MSG_SPIN_DISCARD_TEXT	;possibly discard text
	mov	di, mask MF_FORCE_QUEUE	or mask MF_INSERT_AT_FRONT
	call	ObjMessage
endif
exit:
	call	VisRemoveButtonPrePassive
if _JEDIMOTIF
	;
	; if JEDI slider/gauge, redraw if we have moniker (focus is shown
	; with cursor around moniker)
	;
	call	SGC_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	notSlider
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	notSlider
	call	SGC_DerefGenDI
	tst	ds:[di].GI_visMoniker
	jz	notSlider
	call	OpenDrawObject
notSlider:
endif
	ret
OLSpinGadgetLostFocusExcl endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetDiscardText -- 
		MSG_SPIN_DISCARD_TEXT for OLSpinGadgetClass

DESCRIPTION:	Decides whether to discard the text object or not.  If it's
		still got the focus, we won't discard it.  In some cases,
		like when the spin gadget's window is losing the focus, the 
		spin gadget will take the focus itself.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPIN_DISCARD_TEXT

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/18/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetDiscardText	method OLSpinGadgetClass, MSG_SPIN_DISCARD_TEXT
	call	SGC_DerefVisSpecDI
	mov	dx, ds:[di].OLSGI_text		;get text object handle		
	mov	cx, ds:[LMBH_handle]
	tst	dx	
	jz	exit				;no text object, exit
   
	;
	; New code added to not bother releasing or grabbing the focus
	; if we've already been visually closed.  -cbh 6/12/92
	;
	call	SGC_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	exit				
	
	call	CompareWithCurrentFocus		;see if text has current focus
if _JEDIMOTIF
	jne	checkMenu
else
	jne	removeText			;nope, skip onwards
endif
	test	bp, mask HGF_APP_EXCL		;if spin text has focus, and
	jnz	exit				;   it's still in effect, exit

grabFocus::
	;
	; Give the focus back to the spin gadget if we're just switching 
	; windows.  
	;
	call	MetaGrabFocusExclLow

removeText:
	call	SGC_DerefVisSpecDI
	clr	ds:[di].OLSGI_text		;clear our pointer

	mov	si, dx
	call	SGC_DerefVisSpecDI
	clr	ds:[di].VTI_text		;remove pointer to chunk
						;  so the text object won't
						;  destroy it.
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_DESTROY
	call	SGC_ObjCallInstanceNoLock
exit:
	ret

if _JEDIMOTIF
	;
	; if menu related OD has focus, give focus back to spin gadget
	;
checkMenu:
	test	bp, mask MAEF_OD_IS_MENU_RELATED
	jz	removeText
	jmp	short grabFocus
endif
OLSpinGadgetDiscardText	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	CompareWithCurrentFocus

SYNOPSIS:	Checks to see if current focus exclusive

CALLED BY:	OLSpinGadgetDiscardText, OLSpinGadgetGiveTextFocus

PASS:		*ds:dx -- object to check
		
RETURN:		zero flag set if current focus exclusive, clear if not
		bp    -- Hierarchical grab flags of parent focus node

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 4/90		Initial version

------------------------------------------------------------------------------@

CompareWithCurrentFocus	proc	near
	push	cx, dx
	mov	di, dx				;save current dx
	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL	;get object with current focus
	call	VisCallParent			
	cmp	cx, ds:[LMBH_handle]		;make sure handle matches
	jne	exit				;nope, exit
	cmp	dx, di				;make sure chunk matches
exit:
	DoPop	dx, cx
	ret
CompareWithCurrentFocus	endp

SpinGadgetCommon ends

;------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetMonikerPos -- 
		MSG_GET_FIRST_MKR_POS for OLSpinGadgetClass

DESCRIPTION:	Returns the start of the moniker.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_FIRST_MKR_POS

RETURN:		carry set if a moniker pos returned, with:
			ax, cx  - position of moniker

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/89	Initial version

------------------------------------------------------------------------------@

OLSpinGadgetMonikerPos	method dynamic OLSpinGadgetClass, MSG_GET_FIRST_MKR_POS

if	_MOTIF
	call	CheckIfFloatingText		;floating text, forget all this
	cmc					;c=0 if floating text
	jnc	exit				;yep, exit.
endif
	call	ViewCreateCalcGState		;unfortunate, but necessary
	push	di				;save gstate
	call	SpinSetupMoniker		;returns x and y offset in ax,dx
	mov	cx, dx				;return y in cx
	call	CF_DerefVisSpecDI
	add	ax, ds:[di].VI_bounds.R_left	;make absolute
	add	cx, ds:[di].VI_bounds.R_top
	pop	di				;gstate
	call	GrDestroyState			;kill him!
	stc					;say handled
exit:
	ret
OLSpinGadgetMonikerPos	endm

CommonFunctional ends

;---------------------

SpinGadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLSpinGadgetNavigate - MSG_SPEC_NAVIGATION_QUERY handler for
			OLSpinGadgetClass

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
	OLSpinGadgetClass handler:
	    call utility routine, passing flags to indicate the status
	    of this node: is not root, is not composite, may be focusable,
	    is not menu-related.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@

OLSpinGadgetNavigate	method	dynamic OLSpinGadgetClass, 
					MSG_SPEC_NAVIGATION_QUERY

	clr	bl				;assume not anything
if _KBD_NAVIGATION
 
	;
	; If this is both not incrementable and not editable, don't
	; allow the focus.  (We used to check READ_ONLY here, but some
	; programmers may try to set both hints, rather than setting read-only)
	; 6/ 5/94 cbh
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT
	jz	10$				
	test	ds:[di].OLSGI_attrs, mask OLSGA_NO_UP_DOWN_ARROWS
	jnz	haveFlags	
10$:
	;
	; Redundantly check for the read-only flag, to cover the slider
	; case (which doesn't set NO_UP_DOWN_ARROWS).   6/ 6/94 cbh
	;
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
	jnz	haveFlags			

	
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	haveFlags			;toolbox, don't take focus.

	tst	ds:[di].OLSGI_text		;get text object handle		
	jz	setFocusable			;no text object, make not
						;  composite but focusable
	mov	bl, mask NCF_IS_COMPOSITE 	;else make composite but not
	jmp	short haveFlags			;  focusable

setFocusable:
	
	;see if this RangeObject is enabled
	
	call	SGC_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	haveFlags			;not enabled, branch

	ORNF	bl, mask NCF_IS_FOCUSABLE ;indicate that node is focusable
endif

haveFlags:
	;call utility routine, passing flags to indicate that this is
	;a leaf node in visible tree, and whether or not this object can
	;get the focus. This routine will check the passed NavigationFlags
	;and decide what to respond.

	mov	di, si			;if is a generic object, gen hints
					;will be in same object.
	call	VisNavigateCommon
	ret
OLSpinGadgetNavigate	endm

SpinGadgetCommon ends

;---------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetConvertDesiredSizeHint -- 
		MSG_SPEC_CONVERT_DESIRED_SIZE_HINT for OLSpinGadgetClass

DESCRIPTION:	Converts a desired size.  Subclassed here so that no extra
		size is added -- currently we just want to get the size of
		the box when converting a desired size (other stuff is added
		in at other times.)

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_CONVERT_DESIRED_SIZE
		cx, dx	- desired size args

RETURN:		cx, dx 	- converted args
		ax, bp  - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/26/91		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetConvertDesiredSizeHint	method OLSpinGadgetClass, \
				MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
	push	dx, cx				;save size args
; Just do it directly. -- Doug 2/5/93
;	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
; 	call	CF_ObjCallInstanceNoLock	;get a gstate to work with
; {
	call	ViewCreateCalcGState
; }
	mov	di, bp				;gstate in di
	pop	ax				;restore passed width in ax
	call	VisConvertSpecVisSize		;calc a real width in ax
	mov	cx, ax				;put in cx
	pop	ax				;restore passed height
	call	VisConvertSpecVisSize		;calc a real height in ax
	mov	dx, ax				;put in dx
	call	GrDestroyState
	Destroy	ax, bp
	ret
OLSpinGadgetConvertDesiredSizeHint	endm

CommonFunctional ends			

;--------------------------------

Resident segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetTextPosition

SYNOPSIS:	Returns position text should go.

CALLED BY:	SpinSetupMoniker, OLSpinGadgetPosition

PASS:		*ds:si -- handle of spin gadget
		dx     -- height of text

RETURN:		dx -- top of text
		ax -- left edge of text

DESTROYED:	bx, cx, bp, di

PSEUDO CODE/STRATEGY:
		Hack, hack, hack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/18/89	Initial version
	Chris	6/15/92		Updated for new graphics coords.

------------------------------------------------------------------------------@

if	_OL_STYLE
	
GetTextPosition	proc	far
	class	OLSpinGadgetClass

	call	GetSpinLineThickness		;return thickness of line
	push	dx				;save height
	push	ax				;and line thickness	    
	call	OLSpinGadgetGetBounds		;get bounds of display area
	pop	bp				;restore line thickness	    
	sub	dx, bp				;leave room for underline   
	sub	dx, bx				;subtract top from bottom
	pop	bp				;restore moniker height
	sub	dx, bp				;subtract moniker height
	add	dx, bx				;add top + top margin back in
	ret
GetTextPosition	endp

endif
	
if	_CUA_STYLE

GetTextPosition	proc	far
	class	OLSpinGadgetClass

	push	dx				;save height
	call	OLSpinGadgetGetBounds		;get bounds of display area

	xchg	dx, bx				;top in dx, bottom in bx
	pop	bp				;restore moniker height

	call	CheckIfFloatingText		;floating, skip center stuff
	jc	20$

	call	Res_DerefVisDI			;don't center on gauges
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	5$
	call	Res_DerefGenDI			
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	20$		
5$:
	xchg	dx, bx				;top in bx, bottom in dx
	sub	dx, bx				;subtract top from bottom
	sub	dx, bp				;subtract moniker height
	jns	10$
	clr	dx				;zero (how'd it get negative?)
10$:
	shr	dx, 1				;divide by two for offset    

RUDY <	inc	dx				;Mystery adjustment...	>
RUDY <	inc	ax				;			>

	add	dx, bx				;add top + top margin back in
;	call	OpenCheckIfCGA
;	jnc	20$
;	dec	dx				;move text up a pixel
20$:
	mov	bx, dx				;top into bx
	add	bx, bp				;add font height
	;
	; A bunch of code to align the text object with the scrollbar thumb
	; if we're a slider.  -cbh 4/ 9/93
	;
	; ax - text left, dx - text top, bx - text bottom.
	;
if	_MOTIF
	call	CheckIfFloatingText
	jnc	exit
	call	PositionFloatingText
endif

exit:
	ret
GetTextPosition	endp

endif





COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfFloatingText

SYNOPSIS:	Checks whether text floats to match slider thumb.  

CALLED BY:	GetTextPosition

PASS:		*ds:si -- spin gadget

RETURN:		carry set if floating

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 9/93       	Initial version

------------------------------------------------------------------------------@

if SLIDER_INCLUDES_VALUES

CheckIfFloatingText	proc	far
	clc					; never floating text
	ret
CheckIfFloatingText	endp

else

CheckIfFloatingText	proc	far		uses	di
	.enter
	call	Res_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	exit				;a gauge, no floaters (c=0)
	call	Res_DerefVisDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	exit				;not a slider, exit (c=0)
	stc
exit:
	.leave
	ret
CheckIfFloatingText	endp

endif ; SLIDER_INCLUDES_VALUES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLSGOlSpinCheckFloatingText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if slider/gauge (floating text)

CALLED BY:	MSG_OL_SPIN_CHECK_FLOATING_TEXT
PASS:		*ds:si	= OLSpinGadgetClass object
		ds:di	= OLSpinGadgetClass instance data
		ds:bx	= OLSpinGadgetClass object (same as *ds:si)
		es 	= segment of OLSpinGadgetClass
		ax	= message #
RETURN:		carry set if floating text 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _JEDIMOTIF
OLSGOlSpinCheckFloatingText	method dynamic OLSpinGadgetClass, 
					MSG_OL_SPIN_CHECK_FLOATING_TEXT
	.enter
	call	CheckIfFloatingText		; carry set if so
	.leave
	ret
OLSGOlSpinCheckFloatingText	endm
endif



Resident ends

;--------------------------------------


Slider	segment resource




COMMENT @----------------------------------------------------------------------

ROUTINE:	PositionFloatingText

SYNOPSIS:	Positions floating text to match scrollbar thumb.

CALLED BY:	FAR: GetTextPosition

PASS:		*ds:si -- spin gadget
		ax -- text left
		dx -- text top

RETURN:		ax -- x position (left edge) of text
		dx -- y position (top)

DESTROYED:	bx, cx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/93       	Initial version

------------------------------------------------------------------------------@

PositionFloatingText	proc	far
	mov	bx, ax
	call	GetSystemFontHeightFar		;ax <- text height
	xchg	ax, bx				;now in bx; ax <- text left

	call	GetSpinTextWidth		;cx <- width of current text

	call	Slider_DerefVisDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	pushf
	jz	30$
	xchg	ax, dx				;exchange left, top
	xchg	cx, bx				;exchange width, height
30$:
	; Assuming horizontal now.  Adjust left edge to scrollbar arrow.

	push	cx				;save "width"
	shr	cx, 1				;divide "width" by 2
	jnc	32$
	inc	cx				;(round result up)
32$:
	neg	cx
	add	ax, cx				;add "left" edge
if	_MOTIF
	mov	di, ds:[di].OLSGI_scrollbar
	mov	di, ds:[di]			
	add	di, ds:[di].Vis_offset
	add	ax, ds:[di].OLSBI_elevOffset
	mov	cx, ds:[di].OLSBI_arrowSize	;add 1.5 arrow sizes (slider
	add	ax, cx				;  thumbs are 3 arrows long)
	shr	cx, 1
	add	ax, cx
	inc	ax				;for good measure...
endif
if	_PM
	add	ax, MO_ARROW_HEIGHT + (MO_THUMB_HEIGHT / 2)
endif
	pop	cx				;restore "width"
	popf	
	pushf
	call	KeepFloatingTextInBounds	;adjust "left","right" to bounds
	popf
	jz	exit
	xchg	ax, dx				;exchange top, left
exit:
	ret
PositionFloatingText	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetSpinTextWidth

SYNOPSIS:	Returns width of spin text.

CALLED BY:	GetTextPosition

PASS:		*ds:si -- spin gadget

RETURN:		cx -- width of text

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/93       	Initial version

------------------------------------------------------------------------------@

GetSpinTextWidth	proc	near		uses 	si, ax, dx, bp
	class	OLValueClass			;cheat horribly
	.enter
	
EC <	push	es, di							>
EC <	mov	di, segment OLValueClass				>
EC <	mov	es, di							>
EC <	mov	di, offset OLValueClass					>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	OL_ERROR					>
EC <	pop	es, di							>

	clr	cx				;assume no text (can happen?)
	call	Slider_DerefVisDI
	mov	si, ds:[di].OLVLI_item
	tst	si
	jz	exit
	mov	si, ds:[si]			;point to text

	
	call	ViewCreateCalcGState
	mov	di, bp				;gstate

	clr	cx				;null terminated text
	call	GrTextWidth			;returns dx = width
	mov	cx, dx
	call	GrDestroyState			;nuke the gstate
exit:
	.leave
	ret
GetSpinTextWidth	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	KeepFloatingTextInBounds

SYNOPSIS:	Keeps floating text position reasonable (within appropriate
		scrollbar bounds is what we'll look for.)

CALLED BY:	GetTextPosition

PASS:		*ds:si -- spin gadget
		zero flag set set if horizontal		
		ax -- left edge of text (or top if vertical)
		cx -- width of text (or height of vertical)
	
RETURN:		ax -- updated if needed

DESTROYED:	bx, cx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/93       	Initial version

------------------------------------------------------------------------------@

KeepFloatingTextInBounds	proc	near	uses	dx
	.enter
	push	ax, cx
	pushf					;save vertical flag
	call	Slider_DerefVisDI
	mov	di, ds:[di].OLSGI_scrollbar	;get bounds of scrollbar
	tst	di
	jz	popfAxCxAndExit			;no scrollbar, bail

	xchg	si, di				;save si
	call	VisGetBounds			;returns bounds
	mov	si, di				;restore si
	popf					;if vert, bx, dx has our range.
	jnz	gotRange			;vertical, branch
	movdw	bxdx, axcx			;use left and right as range
gotRange:
	pop	ax, cx				;restore pos, size

	;zero flag still set if horizontal.  Let's substitute the text object
	;width in this case, otherwise we run into text greying out of bounds
	;problems.

	jnz	5$				;vertical, branch
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLSGI_textWidth	;use as text width
5$:
	sub	dx, cx				;subtract size from max

	cmp	ax, bx				;smaller than left, adjust
	jge	10$
	mov	ax, bx
10$:
	cmp	ax, dx
	jle	20$
	mov	ax, dx
20$:
	.leave
	ret


popfAxCxAndExit:
	popf
	pop	ax, cx				
	jmp	short 20$
	
KeepFloatingTextInBounds	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	AdjustRectToEntireRange

SYNOPSIS:	Do horrible things to ensure the space above/left of the
		slider is cleared, since the text can move anywhere.
		May do a GrFillRect to do part of the clearing, as it
		has to do two parts now.

CALLED BY:	ClearSpinDisplay

PASS:		*ds:si -- spin gadget
		ax, bx, cx, dx -- rect to do
		di -- gstate

RETURN:		ax, bx, cx, dx -- rect, changed somewhat

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 9/93       	Initial version
	Chris	4/27/93		Changed to work around number, rather than on
				it.

------------------------------------------------------------------------------@

AdjustRectToEntireRange	proc	far		uses	bp
	.enter
	;
	; Instead of doing the numeric area, do the part to the left
	; and to the right of it instead.  (Or above and below, in a
	; vertical slider.)  (Changed to do entire area for now. -4/28/93 cbh)
	;
	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jz	horiz
;vert:
if not _JEDIMOTIF		; not needed for JEDI, for some reason
	dec	cx				;avoid overlap with slider
endif
	call	pointToScrollbar

if	1
	mov	bx, ds:[bp].VI_bounds.R_top
	mov	dx, ds:[bp].VI_bounds.R_bottom
else
	push	dx
	mov	dx, ds:[bp].VI_bounds.R_top
	call	GrFillRect
	pop	bx
	mov	dx, ds:[bp].VI_bounds.R_bottom
endif

	jmp	short	exit
horiz:
	dec	dx				;avoid overlap with slider
	call	pointToScrollbar

if	1
	mov	ax, ds:[bp].VI_bounds.R_left
	mov	cx, ds:[bp].VI_bounds.R_right
else
	push	cx
	mov	cx, ds:[bp].VI_bounds.R_left
	call	GrFillRect
	pop	ax
	mov	cx, ds:[bp].VI_bounds.R_right
endif
exit:
	.leave
	ret

pointToScrollbar	label	near
 	mov 	bp, ds:[bp].OLSGI_scrollbar
	mov	bp, ds:[bp]			
	add	bp, ds:[bp].Vis_offset
	retn

AdjustRectToEntireRange	endp



Slider	ends


;--------------------------------------

Unbuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetNotifyNotEnabled -- 
		MSG_SPEC_NOTIFY_NOT_ENABLED for OLSpinGadgetClass

DESCRIPTION:	Notifies an object that can be enabled, if it wants.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_NOT_ENABLED
		dl	- update mode
		dh	- NotifyEnabledFlags
		
RETURN:		carry set if visual state changed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/10/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetNotifyNotEnabled 	method OLSpinGadgetClass, \
			  		MSG_SPEC_NOTIFY_NOT_ENABLED
	;
	; Unload the text object.
	;
	push	si
if (not SLIDER_INCLUDES_VALUES)		; spin gadget directly has focus
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLSGI_text		;point to text	
	tst	si				;is there one?
	jz	exit				;no! forget it
endif

	call	OpenNavigateIfHaveFocus		;get rid of focus if we have it
 	call	MetaReleaseFocusExclLow	 	;release focus
exit:	
	pop	si
	call	OLSpinGadgetNotifyEnabled
	ret
	
OLSpinGadgetNotifyNotEnabled	endm
	



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetSetNotUsable -- 
		MSG_SPEC_SET_NOT_USABLE for OLSpinGadgetClass

DESCRIPTION:	Handles being set not usable.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SET_NOT_USABLE

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
	chris	10/26/92		Initial Version

------------------------------------------------------------------------------@

OLSpinGadgetSetNotUsable	method dynamic	OLSpinGadgetClass, \
				MSG_SPEC_SET_NOT_USABLE
	push	si
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLSGI_text		;point to text	
	tst	si				;is there one?
	jz	done				;no! forget it
	call	OpenNavigateIfHaveFocus		;get rid of focus if we have it
done:
	pop	si
	mov		di, offset OLSpinGadgetClass
	CallSuper	MSG_SPEC_SET_NOT_USABLE
	ret
OLSpinGadgetSetNotUsable	endm
			
Unbuild	ends

				
CommonFunctional	segment resource
				
COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetNotifyEnabled -- 
		MSG_SPEC_NOTIFY_ENABLED for OLSpinGadgetClass

DESCRIPTION:	Notifies an object that can be enabled, if it wants.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED
		dl	- update mode
		dh	- NotifyEnabledFlags
		
RETURN:		carry set if visual state changed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/10/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetNotifyEnabled 	method OLSpinGadgetClass, \
					MSG_SPEC_NOTIFY_ENABLED
	push	dx, ax
	mov	di, offset OLSpinGadgetClass	;call superclass
	call	ObjCallSuperNoLock
	DoPop	ax, dx
	jnc	exit				;nothing special happened, exit
	
	call	VisSendToChildren		;send to scrollbar
exit:
	ret
OLSpinGadgetNotifyEnabled	endm

CommonFunctional	ends

			
Build	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetGetExtraSize -- 
		MSG_SPEC_GET_EXTRA_SIZE for OLSpinGadgetClass

DESCRIPTION:	Returns extra space around main moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_EXTRA_SIZE

RETURN:		cx 	- extra width
		dx 	- extra height

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       extra width = (right-left) - (dispRight-dispLeft)
       extra height =(bottom-top) - (dispBottom-dispTop)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/22/90		Initial version

------------------------------------------------------------------------------@

OLSpinGadgetGetExtraSize	method OLSpinGadgetClass, \
						MSG_SPEC_GET_EXTRA_SIZE

	call	OLSpinGadgetGetBounds		;returns bounds of moniker

	call	Build_DerefVisSpecDI
	test 	ds:[di].OLSGI_attrs, mask OLSGA_NO_UP_DOWN_ARROWS
	jnz	5$				;Don't have arrows, branch

	push	si
	mov	si, ds:[di].VCI_comp.CP_firstChild.chunk	
	
EC <	tst	si				;is there a scrollbar?	   >
EC <	ERROR_Z	OL_ERROR			;yes, die 		   >

	mov	ax, MSG_VIS_RECALC_SIZE
	call	ObjCallInstanceNoLock	;get scrollbar size
	pop	si

	add	cx, SPIN_SCROLLBAR_SPACING	;and spacing betw spin and bar
if (SPIN_SCROLLBAR_SPACING ne NARROW_SPIN_SCROLLBAR_SPACING)
	call	OpenCheckIfNarrow
	jnc	5$
	sub	cx, SPIN_SCROLLBAR_SPACING - NARROW_SPIN_SCROLLBAR_SPACING
endif
5$:	
	clr	bx
	call	Build_DerefVisSpecDI
	test	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
	jnz	7$				;frame is drawn, no margins

	add	cx, SPIN_CONTENT_MARGIN*2	;add left and right edges
CUAS <	mov	bx, 1+1				;leave room for top/bot lines  >
CUAS <						;  and selection rectangle     >

	call	CheckIfLargeHeight
	jnc	7$
	add	bx, SPIN_EXTRA_PEN_MARGIN*2

7$:
	add	bx, ds:[di].OLSGI_desHeight	;get desired height	
	mov	ax, bx				;keep in ax as well
     	cmp	bx, dx				;see if scrollbar is bigger
	jbe	10$				;yes, branch
	mov	dx, bx				;else use desired height value
10$:
	sub	dx, ax				;subtract desired height off
	ret
OLSpinGadgetGetExtraSize	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLSpinGadgetBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}.

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

OLSpinGadgetBroadcastForDefaultFocus	method	OLSpinGadgetClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	test 	ds:[di].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT
	jnz	done				;Not editable, forget it...

	test	ds:[di].OLSGI_states, mask OLSGS_MAKE_DEFAULT_FOCUS
	jz	done				;skip if not...

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	clr	bp
done:
	ret
OLSpinGadgetBroadcastForDefaultFocus	endm

Build	ends
