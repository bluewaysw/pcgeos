COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988-1996 All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CView
FILE:		cviewScrollbar.asm

ROUTINES:
	Name			Description
	----			-----------
    INT SwapIfHorizontal	Swaps cx and dx if scrollbar is a
				horizontal kind of bar. This should
				probably be removed as it's a pretty big
				time drain.

    MTD MSG_SPEC_BUILD		Builds a scrollbar.

 ?? none ReturnVert		Builds a scrollbar.

 ?? none ConstantUpdate		Builds a scrollbar.

 ?? none MergeDisplays		Builds a scrollbar.

 ?? none DelayedUpdate		Builds a scrollbar.

    MTD MSG_SET_ORIENTATION	Sets scrollbar orientation.

    MTD MSG_VIS_RECALC_SIZE	Sets scrollbar orientation.

 ?? INT SizeFloatingScroller	Sizes the scroller.

    MTD MSG_VIS_DRAW		Draw the Scrollbar

 ?? INT SetScrAreaIfInvalid	If stuff is invalid, set up scrArea.

 ?? INT UpdateEnabledState	White out pixels we know won't be drawn to.
				We only call this if the scrollbar is
				disabled, and drawing with the 50% mask.

    INT SetElevOffset		Sets offset to elevator on screen.  Takes
				the current ranges and the current document
				offset and calculates a new offset for the
				scroll bar elevator.

 ?? INT CalcElevPos		Figure out where elevator will go for a
				certain document offset.

 ?? INT NegateRatioIfVertSlider	Handle read-only vertical scrollbars.

    MTD MSG_GEN_VALUE_SET_MAXIMUM
				Sets the range for the scrollbar.

 ?? INT SetTopBottomFlags	See if we're at or have left the top or
				bottom, causing a change in the arrow
				pattern.

 ?? INT SetTopBottomFlags	See if we're at or have left the top or
				bottom, causing a change in the arrow
				pattern.

 ?? INT MaybeReopenFloaterWindow
				If we've hit (or left) top or bottom,
				change region.

 ?? INT SetElevLen		Calculates length of the motif thumb.

 ?? INT GetDefaultThumbHeight	Get default thumb height.

    MTD MSG_GEN_VALUE_SET_RANGE_LENGTH
				Sets the page size for the scrollbar.

    MTD MSG_REPEAT_SCROLL	Handles repeated presses when window
				finishes redrawing.

    MTD MSG_TIMER_EXPIRED	Handles repeated presses when timer
				expires.

 ?? INT RepeatScrollIfNeeded	Repeats the previous scroll function, if
				it's time to.

    MTD MSG_GEN_VALUE_SET_VALUE	Scrolls the scrollbar.

    MTD MSG_SPEC_GET_LEGOS_LOOK	Get the legos look.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

DESCRIPTION:

	$Id: cviewScrollbar.asm,v 1.2 98/03/11 06:03:07 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonUIClassStructures segment resource

if FLOATING_SCROLLERS
	FloatingScrollerClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
endif	

	OLScrollbarClass 	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
	

; Removed until we decide to send repeat event through the input manager 
; queue method  GenCallApplication, OLScrollbarClass, MSG_GADGET_REPEAT_PRESS

SCROLLBAR_LATITUDE	=	10	;amount of area around scrollbars where
					;a continued press still works

	method	VupCreateGState, OLScrollbarClass, MSG_VIS_VUP_CREATE_GSTATE

CommonUIClassStructures ends


Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapIfHorizontal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swaps cx and dx if scrollbar is a horizontal kind of bar.
		This should probably be removed as it's a pretty big time
		drain.

CALLED BY:	INTERNAL

PASS:		cx, dx -- coordinates
		ds:di  -- SpecInstance of scrollbar

RETURN:		cx, dx -- either the same or reversed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapIfHorizontal	proc	far
	class	OLScrollbarClass
	
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL ;see if horizontal
	jnz	vertical				;no, branch
	xchg	cx, dx					;else xchg parameters
vertical:
	ret
SwapIfHorizontal	endp


Resident ends

	 
GadgetBuild segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds a scrollbar.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_SPEC_BUILD

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLScrollbarSpecBuild	method dynamic OLScrollbarClass, MSG_SPEC_BUILD
	.enter

	mov	di, offset OLScrollbarClass
	call	ObjCallSuperNoLock		;call superclass
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VI_geoAttrs, mask VGA_USE_VIS_SET_POSITION

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLSBI_state, mask OLSS_INVALID_OFFSETS  ;not set yet
	;
	; There is no xor'ed elevator, currently
	;
CUAS <	mov	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR		>

if SLIDER_INCLUDES_VALUES and DRAW_STYLES
	;
	; default draw style is flat, except slider which is lowered
	; (this happens via OpenAddScrollbar from CreateSpinScrollbar,
	;  where we set the actual draw style)
	;
	mov	ds:[di].OLSBI_drawStyle, DS_FLAT
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	notDSSlider
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GI_attrs, mask GA_READ_ONLY
	jnz	notDSSlider			; gauge is flat also
	mov	ds:[di].OLSBI_drawStyle, DS_LOWERED
notDSSlider:
endif
     
     	;
	; Scan hints for vertical orientation.  Until changed via a method,
	; scrollbars with HINT_VALUE_Y_SCROLLER we'll assume to be vertical, 
	; otherwise they're horizontal.  
	;
	segmov	es, cs, di
	mov	di, offset cs:VerticalHint
	mov	ax, length (cs:VerticalHint)
	clr	cl				; assume horizontal
	call	ObjVarScanData			; cl -- vertical flag if vert
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_attrs, not mask OLSA_VERTICAL
	ornf	ds:[di].OLSBI_attrs.low, cl

if _MOTIF
	;
	; Initialize arrow size properly.  -cbh 11/ 9/92
	;
	push	ds
	mov	ax, segment idata		; get segment of core blk
	mov	ds, ax
	mov	cx, ds:[olArrowSize]		; absolute height to objects
	pop	ds

	;
	; On CGA screens, we'll make vertical scrollbars be little wider, so
	; they're not quite so squished.   But not if something's been set
	; in the .ini file.   (And not if we're also narrow. 12/ 2/92 cbh)
	;
	; Note that OpenCheckIfCGA currently doesn't do the right thing
	; (it returns true any time the CSF_TINY bit is set), so on
	; Jedi & Rudy it made vertical arrows extra large.  The fix,
	; however, is complicated, since it involves going through all
	; places in CommonUI that call OpenCheckIfCGA and seeing if they
	; were really serious about CGA, or they just wanted to see if
	; the tiny bit was set (in which case they should be calling
	; OpenCheckIfTiny).  This can be done later, when we're on the
	; trunk & installs are faster.  For now we just hack this part
	; for Jedi & Rudy.  -stevey 8/10/94
	;
	
	; And stylus. --JimG 4/15/95
	;
if (not _STYLUS)

	cmp	cx, 10
	jne	setSize

	call	OpenCheckIfCGA
	jnc	setSize
	call	OpenCheckIfNarrow
	jc	setSize
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	setSize
	mov	cx, 12				

endif	; not _STYLUS
	
setSize:

if SLIDER_INCLUDES_VALUES
	;
	; make square arrows with size based on font height
	;	(arrow size set for gauges but not used)
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	notSlider
	push	di, si
	call	ViewCreateCalcGState		; di = gstate
	call	SpecGetDisplayScheme		; cx = fontID, dx = point size
	clr	ah
	call	GrSetFont
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			; dx = height
	mov	cx, dx
	add	cx, SLIDER_TEXT_MARGIN*2	; two pixel top/bottom margin
	call	GrDestroyState
	pop	di, si
notSlider:
endif ; SLIDER_INCLUDES_VALUES

if SPINNER_GEN_VALUE
	test	ds:[di].OLSBI_attrs, mask OLSA_SPINNER
	jz	notSpinner
	mov	cx, SPINNER_ARROW_HEIGHT+SPINNER_ARROW_INSET*2
notSpinner:
endif

	mov	ds:[di].OLSBI_arrowSize, cx
endif	; _MOTIF

	.leave
	ret
OLScrollbarSpecBuild	endm

			
VerticalHint	VarDataHandler \
 <HINT_VALUE_Y_SCROLLER, offset ReturnVert>,
 <HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION, offset ConstantUpdate>,
 <HINT_VALUE_DELAYED_DRAG_NOTIFICATION, offset DelayedUpdate>,
if SLIDER_INCLUDES_VALUES and DRAW_STYLES
 <HINT_DRAW_STYLE_FLAT, ScrollerFlat>,
 <HINT_DRAW_STYLE_3D_LOWERED, ScrollerLowered>,
endif
if SPINNER_GEN_VALUE
 <HINT_SPEC_SPINNER, ScrollerSpinner>,
endif
 <HINT_VALUE_MERGE_ANALOG_AND_DIGITAL_DISPLAYS, offset MergeDisplays>
 
if SPINNER_GEN_VALUE
ScrollerSpinner	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLSBI_attrs, mask OLSA_SPINNER
	ret
ScrollerSpinner	endp
endif

if SLIDER_INCLUDES_VALUES and DRAW_STYLES
ScrollerFlat	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLSBI_drawStyle, DS_FLAT
	ret
ScrollerFlat	endp

ScrollerLowered	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLSBI_drawStyle, DS_LOWERED
	ret
ScrollerLowered	endp
endif

ReturnVert	proc	far
	mov	cl, mask OLSA_VERTICAL
	ret
ReturnVert	endp
		
ConstantUpdate	proc	far
	mov	ax, mask OLSA_UPDATE_DURING_DRAGS
	jmp	OLSBSetAttrsFromHint
ConstantUpdate	endp

MergeDisplays	proc	far
	mov	ax, mask OLSA_TEXT_TOO
OLSBSetAttrsFromHint label near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLSBI_attrs, ax
	ret
MergeDisplays	endp

DelayedUpdate	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_attrs, not mask OLSA_UPDATE_DURING_DRAGS
	ret
DelayedUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarSpecUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unbuild scrollbar

CALLED BY:	MSG_SPEC_UNBUILD
PASS:		*ds:si	= OLScrollbarClass object
		ds:di	= OLScrollbarClass instance data
		ds:bx	= OLScrollbarClass object (same as *ds:si)
		es 	= segment of OLScrollbarClass
		ax	= message #
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

OLScrollbarSpecUnbuild	method dynamic OLScrollbarClass, 
					MSG_SPEC_UNBUILD
	;
	; Reset the visbounds of the scrollbar it doesn't invalidate the window
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER or mask OLSA_TWISTED
	jnz	notScrollbar

	clr	cx
	mov	ds:[di].VI_bounds.R_left, cx
	mov	ds:[di].VI_bounds.R_top, cx
	mov	ds:[di].VI_bounds.R_right, cx
	mov	ds:[di].VI_bounds.R_bottom, cx

notScrollbar:
	mov	di, offset OLScrollbarClass
	GOTO	ObjCallSuperNoLock

OLScrollbarSpecUnbuild	endm

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarSetOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets scrollbar orientation.

CALLED BY:	MSG_SET_ORIENTATION

PASS:		*ds:si	= OLScrollbarClass object
		ds:di	= OLScrollbarClass instance data

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SET_ORIENTATION
		
		cl 	- clear if horizontal, 0ffh if vertical

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLScrollbarSetOrientation	method dynamic	OLScrollbarClass, \
						MSG_SET_ORIENTATION
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_attrs, not mask OLSA_VERTICAL
	andnf	cl, mask OLSA_VERTICAL
	ornf	ds:[di].OLSBI_attrs.low, cl
	ret
OLScrollbarSetOrientation	endm

GadgetBuild ends

Geometry segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSID:	Returns the size of the scrollbar.

PASS:		*ds:si 	- instance data
		cx	- RecalcSizeArgs: width info for choosing size
		dx 	- RecalcSizeArgs: height info

RETURN:		cx 	- width to use
		dx 	- height to use

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
       		use length passed, but for open look snap to sizes of
		minimum and abbreviated scrollbars.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/89		Initial version
	Chris	1/23/97		Rudy version rewritten

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CUA_STYLE		;START of unpleasant non-Rudy code -----

OLScrollbarRecalcSize	method dynamic	OLScrollbarClass, \
						MSG_VIS_RECALC_SIZE
	mov	di, ds:[si]			; point to instance data
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLSBI_state, mask OLSS_INVALID_OFFSETS or \
				     mask OLSS_INVALID_IMAGE
	;
	;  Clear the OLSA_TWISTED bit, just in case it was twisted
	;  because of an earlier geometry pass, and start figuring
	;  out whether we need to twist it again (because of a lack
	;  of vertical space in which to fit the scroller).
	;
	andnf	ds:[di].OLSBI_attrs, not mask OLSA_TWISTED

	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jnz	notTwisted			;sliders can't be twisted
	
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	notTwisted			;not vertical, can't be twisted

	test	ds:[di].VI_attrs, mask VA_DRAWABLE or mask VA_DETECTABLE
	jz	notTwisted			;we won't twist hidden bars
						;  -11/ 4/92 cbh
	;
	; motif: cmp to (arrowHeight+2)*2, the minimum height.
	;
MO <	mov	ax, ds:[di].OLSBI_arrowSize				>
MO <	add	ax, 3							>
MO <	shl	ax, 1							>
MO <	cmp	dx, ax							>
NOT_MO <cmp	dx, MO_MIN_HEIGHT		;set height		>
ISU   <cmp	dx, MO_MIN_HEIGHT		;set height		>
	ja	notTwisted			;move on if large enough

twisted::
	;
	; Make a twisty scrollbar, return a fixed size of 2*MO_SCROLLBAR_WIDTH
	; wide and MO_ARROW_HEIGHT high.
	;
	ornf	ds:[di].OLSBI_attrs, mask OLSA_TWISTED
NOT_MO<	mov	cx, MO_SCROLLBAR_WIDTH*2-1	;set width		>
ISU<	mov	cx, MO_SCROLLBAR_WIDTH*2-1	;set width		>

MO    <	mov	cx, ds:[di].OLSBI_arrowSize	;(scr width-1)*2 	>
MO    < add	cx, 1						        >
MO    < shl	cx, 1							>

NOT_MO<	mov	dx, MO_ARROW_HEIGHT		 ;set height		>
ISU<	mov	dx, MO_ARROW_HEIGHT		 ;set height		>

MO    < mov	dx, ds:[di].OLSBI_arrowSize	 ;motif: height + 3	>
MO    < add	dx, 4							>

	; ISUI has up/down buttons arranged vertically.
ISU  <	mov	cx, MO_SCROLLBAR_WIDTH+1	;set width		>
ISU  <	mov	dx, NUI_SPIN_ARROW_HEIGHT*2+3	;set height		>

if _MOTIF
	jmp	exit
else
	;
	; Code added 2/ 7/92 cbh to hopefully make these things shorter in CGA.
	; Mouse press stuff should still work since we don't care about vertical
	; checking.  (Nuked for new size stuff.  -cbh 11/10/92)
	;
	call	OpenCheckIfCGA			;we'll see if this helps
	jnc	exit
	sub	dx, 2				
	jmp	short exit			;and exit

endif	; _MOTIF

notTwisted:
	;
	;  Make a not-twisty scrollbar.
	;
	call	SwapIfHorizontal

MO    <	mov	cx, ds:[di].OLSBI_arrowSize				     >
MO    < add	cx, 2							     >

if SLIDER_INCLUDES_VALUES ;----------------------------------------------------
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
if DRAW_STYLES
	mov	ax, 0				; in case not slider
	jz	noInset
else
	jz	notSlider
endif
	;
	; gauges are taller
	;
if SPINNER_GEN_VALUE
	test	ds:[di].OLSBI_attrs, mask OLSA_SPINNER
	jnz	notGauge			; handle read-only spinner
endif
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jz	notGauge
	add	cx, GAUGE_TB_MARGIN*2
notGauge:
if SPINNER_GEN_VALUE
	;
	; vert spinners use text width
	;
	push	ax				; save inset amount
	mov	ax, ds:[di].OLSBI_attrs
	test	ax, mask OLSA_SPINNER
	jz	notVSpinner
	test	ax, mask OLSA_VERTICAL
	jz	notVSpinner
	mov	bx, offset OLSGI_textWidth
	call	GetParentValueField		; ax = OLSGI_textWidth
	mov	cx, ax
notVSpinner:
	pop	ax				; ax = inset amount
endif
	;
	; sliders get extra room to show draw style
	;	(remove frame width from inset width)
	;
if DRAW_STYLES
.assert (DRAW_STYLE_INSET_WIDTH ge DRAW_STYLE_FRAME_WIDTH)
	cmp	ds:[di].OLSBI_drawStyle, DS_FLAT
	je	haveInsetAmt
	mov	ax, DRAW_STYLE_INSET_WIDTH*2
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jz	haveInitialInset
	mov	ax, DRAW_STYLE_THIN_INSET_WIDTH*2	; thin inset for gauge
haveInitialInset:
	test	ds:[di].OLSBI_attrs, mask OLSA_NO_FRAME
	jz	haveInsetAmt
	sub	ax, DRAW_STYLE_FRAME_WIDTH*2	; subtract frame width
haveInsetAmt:
	add	cx, ax				; adjust with inset
noInset:
	push	ax				; save inset for other way
endif ; DRAW_STYLES
notSlider:
endif ; SLIDER_INCLUDES_VALUES ------------------------------------------------

MO    <	mov	di, ds:[di].OLSBI_arrowSize				     >
MO    <	add	di, 3							     >
MO    <	shl	di, 1							     >

if SLIDER_INCLUDES_VALUES and DRAW_STYLES
	;
	; sliders get extra room to show draw style
	;
	pop	ax				; ax = inset amount
	add	di, ax
endif

if SPINNER_GEN_VALUE
	;
	; spinner width is based on parent size
	;	OLSGI_textWidth for horizontal spinners
	;	OLSGI_desHeight for vertical spinners
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].OLSBI_attrs
	test	ax, mask OLSA_SPINNER
	pop	di
	jz	notSpinner
	mov	bx, offset OLSGI_textWidth	; assume horizontal
	test	ax, mask OLSA_VERTICAL
	jz	addSize				; yes, horizontal
	mov	bx, offset OLSGI_desHeight	; else, vertical
addSize:
	call	GetParentValueField		; ax = size
	add	di, ax				; add it in
notSpinner:
endif

NOT_MO<	mov	di, MO_MIN_HEIGHT		;heights to compare with     >
NOT_MO<	mov	cx, MO_SCROLLBAR_WIDTH		;width always this	     >
ISU<	mov	di, MO_MIN_HEIGHT		;heights to compare with     >
ISU<	mov	cx, MO_SCROLLBAR_WIDTH		;width always this	     >

	andnf	dx, not mask RSA_CHOOSE_OWN_SIZE

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE or mask VA_DETECTABLE
	pop	di
	jz	10$				;we won't worry bout hidden bars
						;  -11/ 4/92 cbh
	cmp	dx, di				;see if below min
	ja	10$				;no, branch
useMin::
	mov	dx, di				;if so, use min
10$:
	;
	;  Swap cx & dx if horizontal.
	;		
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL ;see if horizontal
	jnz	exit					;no, branch
	xchg	cx, dx					;else xchg parameters
ISU <	call	OpenMinimizeIfCGA			;check if on CGA  >
ISU <	jnc	exit					;not on CGA, exit >
ISU <	sub 	dx, MO_SCROLLBAR_WIDTH - CGA_HORIZ_SCROLLBAR_WIDTH	  >

exit:
	ret

OLScrollbarRecalcSize	endm

if SPINNER_GEN_VALUE
;
; pass:
;	*ds:si = spinner scrollbar
;	bx - offset to value to get
; return:
;	ax - value
;
GetParentValueField	proc	near
	uses	di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
EC <	mov	ax, ds:[LMBH_handle]					>
EC <	cmp	ax, ds:[di].GVLI_destination.handle			>
EC <	ERROR_NE	OL_ERROR					>
	mov	di, ds:[di].GVLI_destination.offset
EC <	tst	di							>
EC <	ERROR_Z	OL_ERROR						>
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di][bx]
	.leave
	ret
GetParentValueField	endp
endif

endif		;END of MOTIF/CUA specific code -----------------------


Geometry ends

ScrollbarCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the Scrollbar

PASS:		*ds:si - instance data

		cl - DrawFlags:  set to DF_EXPOSED if updating
		bp - GState to use

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp -- trashed

PSEUDO CODE/STRATEGY:

	- set up the scroll area
	- set up the drawn document offset

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLScrollbarDraw	method	dynamic	OLScrollbarClass, MSG_VIS_DRAW

	;
	; NOTE: If the Geometry is invalid, skip the redraw and figure that
	; someone will validate it soon.  Check added 6/13/93, jimD)
	;
	pushdw	dssi

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jz	tryRedraw
	popdw	dssi
	ret

	;
	; Erase the xor'ed elevator if it's still around.
	;
tryRedraw:
CUAS <	mov	di, ds:[si]						      >
CUAS <	add	di, ds:[di].Vis_offset					      >
CUAS <	cmp	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR		      >
CUAS <	je	continue			;no, do draw		      >
CUAS <	call	XorElevator			;else turn off the xor	      >
CUAS <	mov	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR		      >
CUAS <continue:								      >

	call	UpdateEnabledState		;see if enabled		
	call	SetScrAreaIfInvalid		;setup scroll area

 	;
 	; Let's redraw the whole thing on: a) an expose, or b) the scrollbar's
	; image is invalid.
 	;
	clr	ch
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_state, mask OLSS_INVALID_IMAGE 
	mov	di, bp				;setup gstate
	push	di				;save it
	jnz	drawIt

	test	cl, mask DF_EXPOSED		;definitely redraw if updating
	jnz	drawIt

update:
	;
	; If we're twisted, and don't have an invalid image, there's never
	; anything to draw.  6/ 2/94 cbh
	;
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED
	pop	di
	jnz	exit

	dec	ch				;mark "updating" flag

drawIt:
	;
	; Let's get the drawn document offset correct, and draw. Period.
	;
	push	di, cx
	mov	bp, GVT_VALUE_AS_RATIO_OF_AVAILABLE_RANGE
	mov	ax, MSG_GEN_VALUE_GET_VALUE_RATIO
	call	ObjCallInstanceNoLock		;ratio in dx.cx

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	movdw	ds:[di].OLSBI_drawnDocRatio, dxcx
	
	test	ds:[di].OLSBI_state, mask OLSS_INVALID_OFFSETS
	jz	validOffsets2			;offsets valid, branch

MO   <	call	SetElevLen			;get length of elevator >
ISU <	call	SetElevLen			;get length of elevator >
	call	SetElevOffset			;resize these
	andnf	ds:[di].OLSBI_state, not (mask OLSS_INVALID_OFFSETS)

validOffsets2:
	pop	di, cx

MO <   	call	DrawScrollbar						>
ISU <	call	DrawScrollbar						>
						;note: si trashed at this point.
						;so is ds, for that matter.
exit:
      	pop	di				;restore gstate
	mov	al, SDM_100			;make sure mask OK
	call	GrSetAreaMask
	call	GrSetLineMask

	;
	; Clear the invalid flags!  This seems to no longer get done
	; elsewhere.   6/ 2/94 cbh
	;
	popdw	dssi
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_state, not mask OLSS_INVALID_IMAGE
	ret

OLScrollbarDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetScrAreaIfInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If stuff is invalid, set up scrArea.

CALLED BY:	OLScrollbarDraw

PASS:		*ds:si -- scrollbar

RETURN:		nothing

DESTROYED:	di, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This is the ONLY place that OLSBI_scrArea is set (as a side-
	effect in the MSG_VIS_DRAW handler).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetScrAreaIfInvalid	proc	near
	uses	cx
	.enter
   	;
	; If the offsets and lengths of the scrollbar are invalid, we'll set
	; some things like winLen, and force docOffset if the scrollbar is
	; suddenly too small to be scrolled.
	;
	mov	cx, -1				;assume twisted; no scr area
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED
	jnz	setScrArea			;if twisted, set negative
	
	test	ds:[di].OLSBI_state, mask OLSS_INVALID_OFFSETS
	jz	exit				; offsets valid, branch

	;
	;  Start by assuming the height (if vertical) or width (if
	;  horizontal) is the scrollable area (true for sliders).
	;  For non-sliders, subtract the size of the arrows to get
	;  the actual scrollable area.
	;
	call	VisGetSize			; cx = width, dx = height
if SLIDER_INCLUDES_VALUES and DRAW_STYLES
	;
	; for non-flat sliders, make adjustment for draw style inset
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	noInset
	cmp	ds:[di].OLSBI_drawStyle, DS_FLAT
	je	noInset
	sub	cx, DRAW_STYLE_INSET_WIDTH*2
	sub	dx, DRAW_STYLE_INSET_WIDTH*2
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jz	haveInitialInset
						; thin inset for gauge
	add	cx, (DRAW_STYLE_INSET_WIDTH-DRAW_STYLE_THIN_INSET_WIDTH)*2
	add	dx, (DRAW_STYLE_INSET_WIDTH-DRAW_STYLE_THIN_INSET_WIDTH)*2
haveInitialInset:
	test	ds:[di].OLSBI_attrs, mask OLSA_NO_FRAME
	jz	noInset
	add	cx, DRAW_STYLE_FRAME_WIDTH*2
	add	dx, DRAW_STYLE_FRAME_WIDTH*2
noInset:
endif
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL	; see if vertical
	jz	horizontal			; nope, branch
	xchg	cx, dx				; cx = length of scroller
horizontal:

if SLIDER_INCLUDES_VALUES
	;
	; no arrow for gauges only
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	haveUpArrow
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jnz	sliderSetScrArea		; gauge has no up arrow
haveUpArrow:
else

MO <	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER			>
MO <	jnz	sliderSetScrArea		;no up arrows, branch	>
endif

if	_ISUI
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	pop	di
	jnz	sliderSetScrArea		;read-only, use slider code.
endif

NOT_MO<	sub	cx, MO_UNUSED_HEIGHT				>
ISU <	sub	cx, MO_UNUSED_HEIGHT				>

MO <	push	ax						>
MO <	mov	ax, ds:[di].OLSBI_arrowSize			>
MO <	add	ax, 3						>
MO <	shl	ax, 1						>
if	 _NO_SHADOWS_ON_SCROLL_ARROWS
MO <	dec	ax			;-1 for shadow on arrow	>
endif	;_NO_SHADOWS_ON_SCROLL_ARROWS
MO <	sub	cx, ax						>
MO <	pop	ax						>

	jmp	short setScrArea

sliderSetScrArea:
	;
	;  Special code for sliders.  Don't let the thumb go all
	;  the way to the edge.
	;
EC <	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER			>
EC <	ERROR_Z	OL_ERROR			;shouldn't happen	>

	dec	cx				;slider, account for not going 
;;;	dec	cx				;  to the very edge.  4/ 9/93
;;;					nuked 12/12/94 so slider does go to the
;;;					very edge -- ardeb
;;;
;;;					12/19/94: looked fine in b&w, but
;;;					overwrites the etching in color, so
;;;					just always double-decrement cx -- ardeb
;;;	call	OpenCheckIfBW			;B/W slider, account for
;;;	jnc	setScrArea			;  shadow being put on thumb.
	dec	cx				;  -cbh 4/ 6/93

setScrArea:
	mov	ds:[di].OLSBI_scrArea, cx	; store as scroll area
exit:
	.leave
	ret
SetScrAreaIfInvalid	endp
		

COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateEnabledState

SYNOPSIS:	White out pixels we know won't be drawn to.  We only call
		this if the scrollbar is disabled, and drawing with the 50%
		mask.  

CALLED BY:	OLScrollbarDraw

PASS:		*ds:si -- scrollbar handle

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/29/90		Initial version

------------------------------------------------------------------------------@
UpdateEnabledState	proc	near
	;
	; Set our local enabled flag if we're enabled.
	;
	mov	di, ds:[si]			;get pointer to instance data
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLSBI_attrs, mask OLSA_ENABLED
	mov	bx, ds:[si]			;point to instance
	add	bx, ds:[bx].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[bx].VI_attrs, mask VA_FULLY_ENABLED	
	jnz	10$				;enabled, branch
	andnf	ds:[di].OLSBI_attrs, not mask OLSA_ENABLED
	push	cx				;save draw flags

	;
	;  Get the scroller color.
	;
	push	ds
	mov	ax, segment dgroup
	mov	ds, ax
	mov	al, ds:[moCS_dsLightColor]
	pop	ds

	clr	ah				;ax = color
	mov	di, bp				;pass gstate
	call	GrSetAreaColor			;set as area color
	mov	al, mask SDM_INVERSE or SDM_50	;draw in inverse 50% pattern
	call	GrSetAreaMask
	call	VisGetBounds			;get object bounds 
	call	GrFillRect			;clear the space out
	pop	cx				;restore draw flags
10$:
	;
	; If there is a change in the enabled state, invalidate the image.
	;
	clr	al				;assume not enabled
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLSBI_attrs, mask OLSA_ENABLED
	jz	20$				;not enabled, branch
	mov	al, mask OLSA_DRAWN_ENABLED	;else set this in al
20$:
	xor	al, ds:[di].OLSBI_attrs.low	;xor w/attrs, OLSA_DRAWN_ENABLED
	test	al, mask OLSA_DRAWN_ENABLED	;  the only bit we care about
	jz	exit				;bits matched, exit
	ornf	ds:[di].OLSBI_state, mask OLSS_INVALID_IMAGE
exit:
	ret
	
UpdateEnabledState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetElevOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets offset to elevator on screen.  Takes the current
		ranges and the current document offset and calculates a new
		offset for the scroll bar elevator.

CALLED BY:	INTERNAL

PASS:		*ds:si -- scrollbar handle

RETURN:		ax    -- offset to elevator (also stored in instance data)

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
       	    elevOffset = drawnDocOff * (scrArea-ELEV_LEN) / (docRange - winLen)
	    if elevOffset = 0 and drawnDocOff <> 0
			elevOffset = 2
	    if elevOffset = scrArea and drawnDocOff <> docRange - winLen
		 drawnDocOff = docRange - winLen - 2

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetElevOffset	proc	near
	class	OLScrollbarClass

	mov	di, ds:[si]			; pass drawn doc offset
	add	di, ds:[di].Vis_offset
	movdw	dxcx, ds:[di].OLSBI_drawnDocRatio
	call	CalcElevPos			; figure out elevator position
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLSBI_elevOffset, ax	; store in data structure
	call	SetTopBottomFlags		; set top and bottom flags

	ret
SetElevOffset	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcElevPos

SYNOPSIS:	Figure out where elevator will go for a certain document
		offset.  

CALLED BY:	OLScrollbarDraw (via SetElevOffset)

PASS:		*ds:si -- scrollbar
		dx.cx  -- doc ratio of scrollable bounds to represent

RETURN:		ax -- elevator offset

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
       (docOffset) / (maximum-minimum-page length) * (scrArea - elevLen)
       with several special cases, of course...

KNOWN BUGS/SIDE EFFECTS/IDEAS:

      	In motif: Must calculate the elevator length first, before
		  calculating the position!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 9/89		Initial version

------------------------------------------------------------------------------@
CalcElevPos	proc	far
	class	OLScrollbarClass

	;
	; On read-only, vertical scrollbars, we'll assume we're a gauge and
	; invert the ratio, so as to allow the measurement to take place from
	; the bottom of the gauge.
	;
	call	NegateRatioIfVertSlider
	mov	ax, ds:[di].OLSBI_scrArea	; get scroll area
	
if _MOTIF or _ISUI ;----------------------------------------------------------
	;
	; Stupid (i.e. spin gadget scrollbar), has no thumb.  -cbh 3/ 2/93
	;
	clr	bx				; force no elevator
	test	ds:[di].OLSBI_attrs, mask OLSA_STUPID
	jnz	nonFullElevator

	;
	; Changed to nuke thumb if it fits, but can't move anywhere. -9/15/92
	;
	mov	bx, ax				; bx = ax = scrollable area
	sub	ax, ds:[di].OLSBI_elevLen	; subtract length of thumb
	jg	mult				; full elevator, branch

nonFullElevator:
	call	GetDefaultThumbHeight		; di = default thumb height
	cmp	bx, di				; not at minimum height; we're
	jg	mult				;  not small, go show it
						;  (changed to jg to handle case
						;   of twisted scr, bx = -1)
	;
	; If we get here it means we can't display the thumb,
	; for whatever reason.  Return a no-thumb offset.
	;

if (not _MOTIF)
; Can't use NO_THUMB_ELEV_OFFSET since we might be in CGA.  JS  (11/18/92)
;	mov	ax, NO_THUMB_ELEV_OFFSET	;otherwise, very small, can't

	mov	ax, di
	neg	ax				;otherwise, very small, can't
endif

MO <	mov	di, ds:[si]						>
MO <	add	di, ds:[di].Vis_offset					>
MO <	mov	ax, ds:[di].OLSBI_arrowSize				>
MO <	neg	ax							>
	jmp	short exit			;  show thumb  

endif	; if _MOTIF or _ISUI -------------------------------------------------

mult:
	;
	;  dx.cx = dx.cx * bx.ax
	;  What does this mean?  Well, we multiply the doc ratio of
	;  the scrollable bounds by the length of the scrollable
	;  area, and it gives us the offset of the thumb.  Easy!
	;
	mov_tr	bx, ax				; (integer) scrollable area
	clr	ax				; fractional part
	call	GrMulWWFixed			; multiply, result in dx.cx
	tst	cx
	jns	80$
	inc	dx				; round if needed
80$:
	mov_tr	ax, dx				; result within 16 bits, into ax
exit:
	ret
CalcElevPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegateRatioIfVertSlider
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle read-only vertical scrollbars.

CALLED BY:	CalcElevPos

PASS:		dxcx -- ratio
		*ds:si --scrollbar
	
RETURN:		dxcx -- ratio, possibly inverted
		ds:di -- scrollbar VisInstance

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	On read-only, vertical scrollbars, we'll assume we're a gauge and
	invert the ratio, so as to allow the measurement to take place from
	the bottom of the gauge.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	Chris	8/ 9/89			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegateRatioIfVertSlider		proc	near
	uses	ax, bx, di
	.enter

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	done

	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	done

	movdw	bxax, dxcx
	mov	dx, 1				; read-only, subtract from 1.0
	clr	cx				;  so stuff is displayed
	subdw	dxcx, bxax
done:
	.leave
	ret
NegateRatioIfVertSlider		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarSetMaximum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the range for the scrollbar.

CALLED BY:	INTERNAL

PASS:		ds:*si -- instance data
		dx:cx -- new maximum

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLScrollbarSetMaximum	method dynamic	OLScrollbarClass, \
						MSG_GEN_VALUE_SET_MAXIMUM, \
						MSG_GEN_VALUE_SET_MINIMUM
	;
	; Mark the offsets as invalid so they'll be updated later.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ornf 	ds:[di].OLSBI_state, mask OLSS_INVALID_OFFSETS

	call	SetTopBottomFlags		; make sure this is still right

	call	VisCheckIfSpecBuilt		; see if there's a vis yet
	jnc	exit				; nope, exit

	test	ds:[di].OLSBI_state, mask OLSS_INVALID_IMAGE
	jnz	redraw				; if invalid as drawn, redraw

	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID or \
				     mask VOF_GEOMETRY_INVALID
	jnz	exit				; don't redraw if vis invalid
redraw:
	call	OpenDrawObject			; redraw parts of scrollbar
exit:
	ret
OLScrollbarSetMaximum	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTopBottomFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're at or have left the top or bottom,  causing
		a change in the arrow pattern.

CALLED BY: 	OLScrollbarSetDocSize

PASS:		*ds:si -- scrollbar

RETURN:		ds:[di].OLSBI_state -- OLSS_AT_TOP or OLSS_AT_BOTTOM set if 
			we are at the top or bottom of the document.

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

SetTopBottomFlags	proc	near
	class	OLScrollbarClass
	uses	bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_state, \
			not (mask OLSS_AT_TOP or mask OLSS_AT_BOTTOM)
	;
	; Let's try a different approach for determining top/bottom flags.
	;
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock		; dx.cx = value
	movdw	bxdi, dxcx			; bx.di = value

	mov	ax, MSG_GEN_VALUE_GET_MINIMUM
	call	ObjCallInstanceNoLock		; dx.cx = minimum
	cmpdw	bxdi, dxcx
	jg	checkBottom

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	ornf	ds:[bp].OLSBI_state, mask OLSS_AT_TOP

checkBottom:
	mov	ax, MSG_GEN_VALUE_GET_RANGE_LENGTH
	call	ObjCallInstanceNoLock		; dx.cx = range
	adddw	bxdi, dxcx			; bx.di = value + range

	mov	ax, MSG_GEN_VALUE_GET_MAXIMUM
	call	ObjCallInstanceNoLock		; dx.cx = maximum
	cmpdw	bxdi, dxcx
	jl	done

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	ornf	ds:[bp].OLSBI_state, mask OLSS_AT_BOTTOM
done:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	.leave
	ret
SetTopBottomFlags	endp

else	; not FLOATING_SCROLLERS

SetTopBottomFlags	proc	near
	uses	bp
	class	OLScrollbarClass
	.enter

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].OLSBI_state		;keep state in al, assume clear
	andnf	al, not (mask OLSS_AT_TOP or mask OLSS_AT_BOTTOM)

	;
	;  Floating scrollers use the top/bottom flags to turn the
	;  arrows on & off.  In reality, other UIs (e.g. Jedi) could
	;  probably benefit from having these flags enabled for
	;  stupid scrollers so they can disable arrows as needed. -stevey
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_STUPID
	jnz	storeFlag			; stupid scrollbars are never
						;   at the top or bottom

	push	ax
	mov	bp, GVT_VALUE_AS_RATIO_OF_AVAILABLE_RANGE
	mov	ax, MSG_GEN_VALUE_GET_VALUE_RATIO
	call	ObjCallInstanceNoLock
	pop	ax

	;
	; On read-only, vertical scrollbars, we'll assume we're a gauge and
	; invert the ratio, so as to allow the measurement to take place from
	; the bottom of the gauge.
	;
	call	NegateRatioIfVertSlider

	tstdw	dxcx				; at minimum?
	jnz	checkBottom
	ornf	al, mask OLSS_AT_TOP		; else set at-top flag

checkBottom:
	tst	dx				; at maximum?
	jz	storeFlag			; not at max, branch
	ornf	al, mask OLSS_AT_BOTTOM		; else keep at bottom

storeFlag:

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLSBI_state, al		; store new flags

	.leave
	ret
SetTopBottomFlags	endp

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetElevLen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates length of the motif thumb.

CALLED BY:	OLScrollbarDraw

PASS:		*ds:si -- scrollbar

RETURN:		nothing

DESTROYED:	cx, dx, ax, bx

PSEUDO CODE/STRATEGY:

	elevLen = max (rangeLengthRatio * scrArea,
			       MO_THUMB_HEIGHT)
				
	In English this means:

		* the scroller range (max-min) is set to the length
		  of the document.

		* the scrollable area is the space between the arrows
		  (OLSBI_scrArea)

		* the thumb size needs to be a percentage of the
		  scrollable area.  This percentage is the ratio of
		  the displayed area of the document (aka "range length",
		  stored in HINT_VALUE_DISPLAYS_RANGE) to the total doc
		  length (aka "GVLI_maximum")

		* the thumb has a minimum size requirement

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_MOTIF or _ISUI
	
SetElevLen	proc	near
	uses	bp
	class	OLScrollbarClass
	.enter

if USE_PROPORTIONAL_THUMB
	
	clr	dx				;assume read-only, no thumb.
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	exit				; yep, done.

if SLIDER_INCLUDES_VALUES
	;
	; use arrow size for sliders
	;	(not used for gauges)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	dx, ds:[di].OLSBI_arrowSize
	add	dx, 1*2				; room for frame
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jnz	exit
endif

	mov	bp, GVT_RANGE_LENGTH
	mov	ax, MSG_GEN_VALUE_GET_VALUE_RATIO
	call	ObjCallInstanceNoLock	     ;dx.cx <- value ratio

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

	;
	; Changed to check against default thumb, even if at maximum (if it's
	; smaller than the thumb height, it will disappear anyway, but we
	; need this to be set right.)  -cbh 12/10/92
	;
	tst	dx				; at maximum?
	mov	dx, ds:[di].OLSBI_scrArea	; (assume full elevator, will
						;  just return scrArea)
	jnz	ensureLargerThanDefault

	;
	; We're not at maximum, so figure out our height.
	;
	mov_tr	ax, cx				; ax = value ratio
	mov	cx, dx				; scrArea in cx
	mul	cx				; multiply, result in dx

ensureLargerThanDefault:
endif

	call	GetDefaultThumbHeight		; di = default height
	
	cmp	dx, di				; smaller than elevator?
	jge	exit				; no, and positive, branch
	
	mov	dx, di				; else use this size	    
exit:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLSBI_elevLen, dx	;store

	.leave
	ret
SetElevLen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultThumbHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get default thumb height.

CALLED BY:	SetElevLen, CalcElevLen

PASS:		ds:di = scrollbar instance

RETURN:		di = default thumb height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	Chris	4/ 6/90			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultThumbHeight	proc	near			

if	_CUA_STYLE and (not _MOTIF)

	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL			
	mov	di, MO_THUMB_HEIGHT					
	jz	10$							

	call	OpenCheckIfCGA						
	jnc	10$							
	mov	di, MO_CGA_THUMB_HEIGHT					
10$:									
endif	; _CUA_STYLE and (not _MOTIF)

if	_MOTIF
	;
	; Motif, use arrow size (triple size for sliders)
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
 	mov	di, ds:[di].OLSBI_arrowSize				
	jz	10$
	push	ax
	mov	ax, di
	add	di, ax				;double min height for sliders
 	add	di, ax				;triple it
	pop	ax
10$:
endif
	ret
GetDefaultThumbHeight	endp

endif	; _MOTIF


COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollbarSetPageSize -- 
		MSG_GEN_VALUE_SET_RANGE_LENGTH for OLScrollbarClass

DESCRIPTION:	Sets the page size for the scrollbar.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_RANGE_LENGTH
		cx      - new page size (section length)

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/26/90		Initial version

------------------------------------------------------------------------------@
OLScrollbarSetPageSize	method dynamic	OLScrollbarClass, \
					MSG_GEN_VALUE_SET_RANGE_LENGTH
	;
	; Set this so the page/specific drawing happens again.
	;
	ornf	ds:[di].OLSBI_state, mask OLSS_INVALID_OFFSETS
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID or \
				     mask VOF_GEOMETRY_INVALID
	jnz	exit				;don't redraw if vis invalid

	call	OpenDrawObject			;redraw things
exit:
	ret
OLScrollbarSetPageSize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollbarRepeatScroll --
		MSG_REPEAT_SCROLL for OLScrollbarClass

DESCRIPTION:	Handles repeated presses when window finishes redrawing.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_REPEAT_SCROLL

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@
OLScrollbarRepeatScroll method dynamic	OLScrollbarClass, \
						MSG_REPEAT_SCROLL
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_optFlags, not mask OLSOF_REPEAT_SCROLL_PENDING
	call	RepeatScrollIfNeeded

	ret
OLScrollbarRepeatScroll	endm

			

COMMENT @----------------------------------------------------------------------

METHOD:		OLScrollbarTimerExpired --
		MSG_TIMER_EXPIRED for OLScrollbarClass

DESCRIPTION:	Handles repeated presses when timer expires.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_TIMER_EXPIRED

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@
OLScrollbarTimerExpired method dynamic	OLScrollbarClass, \
						MSG_TIMER_EXPIRED
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_optFlags, not mask OLSOF_TIMER_EXPIRED_PENDING
	call	RepeatScrollIfNeeded

	ret
OLScrollbarTimerExpired	endm
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	RepeatScrollIfNeeded

SYNOPSIS:	Repeats the previous scroll function, if it's time to.

CALLED BY:	OLScrollbarRepeatScroll, OLScrollbarTimerExpired

PASS:		*ds:si -- scrollbar

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 5/90		Initial version

------------------------------------------------------------------------------@
RepeatScrollIfNeeded	proc	near

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_optFlags, mask OLSOF_REPEAT_SCROLL_PENDING or \
					mask OLSOF_TIMER_EXPIRED_PENDING
	jnz	exit				;either of these flags still
						;    set, exit
	mov	al, ds:[di].OLSBI_state		;get current state
	andnf	al, mask OLSS_DOWN_FLAGS	;see if anything pressed
	jz	exit				;nope, exit

	cmp	al, OLSS_DRAG_AREA		;don't handle drag area
	je	exit

if SPINNER_GEN_VALUE
	;
	; spinner stops timer if we're at end of range since we've disabled
	; the arrow button
	;	al = DownFlags
	;	*ds:si = scrollbar
	;	ds;di = scrollbar spec instance
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SPINNER
	jz	notSpinner
	call	CheckSpinnerAtEnd
	je	exit				; at end, all done
notSpinner:
endif

	mov	bp, (mask UIFA_SELECT shl 8) or mask BI_PRESS	;fake this
	call	HandlePress			;go do some things
exit:
	ret
RepeatScrollIfNeeded	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls the scrollbar.

CALLED BY:	MSG_GEN_VALUE_SET_VALUE

PASS:		*ds:si	= OLScrollbarClass object
		ds:bx	= OLScrollbarClass object
		ds:di	= OLScrollbarClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      Error checking below allows large docOffsets before scrolling
      if the scrollbar is tail oriented.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/23/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLScrollbarScroll	method dynamic	OLScrollbarClass, \
					MSG_GEN_VALUE_SET_VALUE
if FLOATING_SCROLLERS
	;
	; Update OLSS_AT_TOP/OLSS_AT_BOTTOM flags for view scrollbars
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER or mask OLSA_TWISTED
	jnz	notFloater

	push	{word}ds:[di].OLSBI_state
	call	SetTopBottomFlags
	pop	ax

	xor	al, ds:[di].OLSBI_state
	jz	notFloater		; skip update if nothing changed

	mov	ax, MSG_SPEC_VIEW_UPDATE_FLOATING_SCROLLERS
	clr	cx			; don't close before updating
	call	VisCallParent
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
notFloater:
endif	; FLOATING_SCROLLERS

	;
	; Suppressing draw, exit, this will hopefully get covered later.
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SUPPRESS_DRAW
	jnz	exit

	;
	; This seems like a good thing to do.
	;
	ornf	ds:[di].OLSBI_state, mask OLSS_INVALID_OFFSETS

	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID or \
				     mask VOF_GEOMETRY_INVALID
	jnz	exit				;don't redraw if vis invalid
	
	;
	;  Draw ourselves.
	;
	call	OpenDrawObject			;redraw things
exit:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].OLSBI_attrs, not mask OLSA_SUPPRESS_DRAW

	ret
OLScrollbarScroll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatingScrollerMetaExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle exposed event for floating scroller

CALLED BY:	MSG_META_EXPOSED
PASS:		*ds:si	= FloatingScrollerClass object
		ds:di	= FloatingScrollerClass instance data
		ds:bx	= FloatingScrollerClass object (same as *ds:si)
		es 	= segment of FloatingScrollerClass
		ax	= message #
		cx	= Window
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

FloatingScrollerMetaExposed	method dynamic FloatingScrollerClass, 
					MSG_META_EXPOSED
	mov	di, cx			; ^hdi = Window
	call	GrCreateState
	call	GrBeginUpdate

	; determine whether this scroller is being pressed

	mov	bp, ds:[si]
	mov	bx, ds:[bp].FSI_scrollbar
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Vis_offset
	mov	al, ds:[bx].OLSBI_state
	andnf	al, mask OLSS_DOWN_FLAGS

	mov	si, ds:[bp].FSI_bitmap

	cmp	si, offset DownArrowBitmap
	je	checkDown
	cmp	si, offset RightArrowBitmap
	je	checkDown

	cmp	al, OLSS_INC_UP
	jne	drawBitmap
	jmp	depressed
checkDown:
	cmp	al, OLSS_INC_DOWN
	jne	drawBitmap

depressed:
	mov	si, ds:[bp].FSI_selectedBitmap
	
drawBitmap:
	; now draw the bitmap

FXIP <	mov	bx, handle RegionResourceXIP				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
NOFXIP< segmov	ds, cs							>

	clr	ax, bx, dx
	call	GrDrawBitmap

FXIP <	mov	bx, handle RegionResourceXIP				>
FXIP <	call	MemUnlock						>

	call	GrEndUpdate
	GOTO	GrDestroyState

FloatingScrollerMetaExposed	endm

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatingScrollerStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse events for floating scrollers

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= FloatingScrollerClass object
		ds:di	= FloatingScrollerClass instance data
		ds:bx	= FloatingScrollerClass object (same as *ds:si)
		es 	= segment of FloatingScrollerClass
		ax	= message #
		cx	= X position of mouse, in document coordinates of
			  receiving object
		dx	= X position of mouse, in document coordinates of
			  receiving object

		bp low  = ButtonInfo		(In input.def)
			  mask BI_PRESS		- set if press
			  mask BI_DOUBLE_PRESS	- set if double-press
			  mask BI_B3_DOWN	- state of button 3
			  mask BI_B2_DOWN	- state of button 2
			  mask BI_B1_DOWN	- state of button 1
			  mask BI_B0_DOWN	- state of button 0
			  mask BI_BUTTON	- for non-PTR events, is
						  physical button which has
						  caused this event to be
						  generated.

		bp high = UIFunctionsActive	(In Objects/uiInputC.def)

RETURN:		ax	= MouseReturnFlags	(In Objects/uiInputC.def)
 			  mask MRF_PROCESSED - if event processed by gadget.
					       See def. below.

 			  mask MRF_REPLAY    - causes a replay of the button
					       to the modified implied/active
					       grab.   See def. below.

			  mask MRF_SET_POINTER_IMAGE - sets the PIL_GADGET
			  level cursor based on the value of cx:dx:
			  cx:dx	- optr to PointerDef in sharable memory block,
			  OR cx = 0, and dx = PtrImageValue (Internal/im.def)

			  mask MRF_CLEAR_POINTER_IMAGE - Causes the PIL_GADGET
						level cursor to be cleared
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

FloatingScrollerStartSelect	method dynamic FloatingScrollerClass, 
					MSG_META_START_SELECT
	;
	; change the coordinates so the scrollbar know which scroller
	; was selected
	;
	push	ax
	mov	si, ds:[di].FSI_scrollbar
	call	VisGetBounds
	cmp	ds:[di].FSI_windowRegion, offset DownArrowWindowRegion
	je	10$
	cmp	ds:[di].FSI_windowRegion, offset RightArrowWindowRegion
	je	10$
	mov	cx, ax
	mov	dx, bx
10$:	pop	ax

	GOTO	ObjCallInstanceNoLock

FloatingScrollerStartSelect	endm

endif	; FLOATING_SCROLLERS

ScrollbarCommon ends
