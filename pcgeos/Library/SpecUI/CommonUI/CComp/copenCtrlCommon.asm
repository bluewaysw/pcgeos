COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1996.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/COpen (common code for several specific ui's)
FILE:		copenCtrlCommon.asm

ROUTINES:
	Name			Description
	----			-----------
    INT PropogatePreApplyCallback 
				Broadcasts MSG_GEN_PRE_APPLY, returning
				carry set if any child returns carry set.

    MTD MSG_SPEC_SET_EMPHASIS   Emphasizes/De-emphasizes an OLCtrl

    MTD MSG_VIS_OPEN            When coming onscreen, register as an
				emphasizable interaction

    INT OLCtrlSendSetEmphasizedObject 
				Sends MSG_SPEC_SET_EMPHASIZED_OBJECT to win
				group

    MTD MSG_SPEC_SET_EMPHASIZED_OBJECT 
				Registers (or removes) an object as the
				emphasized object underneath a windowed
				OLCtrl.

    INT OpenDrawCtrlMoniker     Draws the moniker for OLCtrl and their kin,
				if the moniker is being used.  Also draws a
				box around things if the appropriate flag
				is set.

    INT RedrawCtrlFrame         Draws the frame of an OLCtrl

    INT DrawCtrlFrame           Draws a frame around the control.

    INT DrawLeafIfHaveFocus     Draw the silly leaf if we have the focus.

    INT DrawEtchedVLine         Draws an etched line.

    INT DrawEtchedVLine         Draws an etched line.

    INT DrawEtchedHLine         Draws an etched horizontal line.

    INT EraseOuterFrameIfNoEmphasis 
				After drawing the frame, erases any pixels
				leftover from a previous, thicker frame

    INT DrawEtchedHLine         After drawing the frame, erases any pixels
				leftover from a previous, thicker frame

    INT SetWhiteIfNotClearing   After drawing the frame, erases any pixels
				leftover from a previous, thicker frame

    INT SetBlack                After drawing the frame, erases any pixels
				leftover from a previous, thicker frame

    INT SetColorIfNotClearing   After drawing the frame, erases any pixels
				leftover from a previous, thicker frame

    INT CheckIfDoingShadows     Returns whether we need a shadow

    INT DrawCtrlFrameTopLines   Draws top lines of a framed OLCtrl.

    INT DrawCtrlFrameTopLineSegments 
				Draw OLCtrlClass top line segments

    INT DrawCtrlFrameSegmentsCB Draw OLCtrlClass top line segments

    INT DrawRoundedBoxCorners   Draw rounded corners

    INT ClearMonikerArea        Clears the area behind the moniker.  We
				also must clear the area around the frame,
				if any.

    MTD MSG_VIS_VUP_QUERY       We intercept visual-upward queries here to
				see if we can answer them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenCtrl.asm

DESCRIPTION:

	$Id: copenCtrlCommon.asm,v 1.2 98/03/11 05:49:00 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlInteractionComplete

DESCRIPTION:

PASS:		*ds:si 	- instance data
		es     	- segment of OLCtrlClass
		ax 	- MSG_GEN_GUP_INTERACTION_COMMAND

		cx	- InteractionCommand

RETURN:		carry set - handled

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@


OLCtrlInteractionComplete method OLCtrlClass, \
			  MSG_GEN_GUP_INTERACTION_COMMAND
			  
	cmp	cx, IC_INTERACTION_COMPLETE
	jne	notHandled	; if not, indicate NOT handled
				; Check if this is a GenInteraction, if not
				; (some spec UI objects are off OLCtrlClass,
				; but no GenInteraction), let parent handle
	push	es
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	pop	es
	jnc	done		; nope, let parent handle
				; C clr -> NOT handled here

				; If dialog, stop method here.  If anything
				; wants it, it should subclass this method.
				; (OLDialogWin, OLPopupWin, OLMenuWin do)
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	stc			; assume not, indicate handled
	je	done
notHandled:
	clc			; indicate NOT handled
done:
	ret

OLCtrlInteractionComplete	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlPropogateApplyReset

DESCRIPTION:	Simply passes any MSG_GEN_APPLY or MSG_GEN_RESET that reaches
		here to all generic, usable children, so that they may perform
		the function.  Allows a single MSG_GEN_APPLY/RESET to be sent
		to a GenSummons or GenInteraction, to cause all gadgets to
		APPLY/RESET their changes.  (This because ALL groups holding
		gadgets in OL ARE or are SUBCLASSED from this class)

PASS:		*ds:si 	- instance data
		es     	- segment of OLCtrlClass
		ax 	- MSG_GEN_APPLY, MSG_GEN_RESET

		cx, dx, bp	- ?

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This handler will send MSG_GEN_APPLY or MSG_GEN_RESET on to ANY
	GenInteraction encountered, even if they are merely
	a button leading to a separate window from the current property
	area.  Only objects in the reply bar are skipped.

	THIS MAY OR MAY NOT BE THE DESIRED BEHAVIOR!  We'll just have to
	wait & see IF anyone ever wants to do this, & then see how it should
	work.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

OLCtrlPropogateApplyReset method OLCtrlClass, MSG_GEN_APPLY, MSG_GEN_RESET,
							MSG_GEN_POST_APPLY
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance

				; Don't send to the reply bar.  This area
				; only has triggers, or possibly
				; GenInteractions or GenSummons which we wish
				; to have come up separately from APPLIED area.

	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	jz	Done

	clr	dl		; No flags to compare with.  Call all
				; USABLE children.
	call	VisIfFlagSetCallGenChildren

Done:
	ret
OLCtrlPropogateApplyReset endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlPropogatePreApply

DESCRIPTION:	Pass MSG_GEN_PRE_APPLY to all children, noting if they return
		error.

PASS:		*ds:si 	- instance data
		es     	- segment of OLCtrlClass
		ax 	- MSG_GEN_PRE_APPLY

		cx, dx, bp	- ?

RETURN:		carry set if any children returns carry set

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This handler will send MSG_GEN_PRE_APPLY on to ANY
	GenInteraction encountered, even if they are merely
	a button leading to a separate window from the current property
	area.  Only objects in the reply bar are skipped.

	THIS MAY OR MAY NOT BE THE DESIRED BEHAVIOR!  We'll just have to
	wait & see IF anyone ever wants to do this, & then see how it should
	work.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/11/92		modified

------------------------------------------------------------------------------@

OLCtrlPropogatePreApply method OLCtrlClass, MSG_GEN_PRE_APPLY
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance

				; Don't send to the reply bar.  This area
				; only has triggers, or possibly
				; GenInteractions which we wish
				; to have come up separately from APPLIED area.

	mov	bx, ds:[di].OLCI_buildFlags
	and	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	jz	Done

	clr	dx		; no carry flag returned, yet
	clr	bx		; initial child (first child)
	push	bx
	push	bx
	mov	bx, offset GI_link
	push	bx		; offset to LinkPart
	mov	bx, SEGMENT_CS
	push	bx		; callback routine (seg)
	mov	bx, offset PropogatePreApplyCallback
	push	bx		; callback routine (off)
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren
	tst	dx		; any carry returned?
				; (clears carry)
	jz	Done		; no, return carry clear
	stc			; else, return carry set
Done:
	ret
OLCtrlPropogatePreApply	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PropogatePreApplyCallback

DESCRIPTION:	Broadcasts MSG_GEN_PRE_APPLY, returning carry set if any
		child returns carry set.

CALLED BY:	OLCtrlPropogatePreApply (as call-back)

PASS:
	*ds:si - child
	*es:di - composite
	ax - message
	dx - TRUE if carry flag returned

RETURN:
	carry - set to end processing
	dx - TRUE if carry flag set previously

DESTROYED:
	cx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

PropogatePreApplyCallback	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE	;clears carry
	jz	leaveDX
	push	ax, dx
	call	ObjCallInstanceNoLock
	pop	ax, dx
	jnc	leaveDX
	mov	dx, -1			; carry returned, indicate this in DX
leaveDX:
	ret
PropogatePreApplyCallback	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLCtrlDraw --
		MSG_VIS_DRAW for OLCtrlClass

DESCRIPTION:	Draws the visual moniker, if appropriate.  Also will draw a
		box around the outside, if appropriate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW

		cl - DrawFlags:  DF_EXPOSED set if updating
		bp - GState to use

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/29/89		Initial version

------------------------------------------------------------------------------@

OLCtrlDraw	method OLCtrlClass, MSG_VIS_DRAW

if CTRL_USES_BACKGROUND_COLOR
	call	DrawCtrlBackground
endif

	push	bp
	mov	di, offset OLCtrlClass	;do Vis Comp draw
	CallSuper	MSG_VIS_DRAW
	pop	bp
	call	OpenDrawCtrlMoniker		;and go draw moniker

	ret
OLCtrlDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCtrlBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw OLCtrlBackground

CALLED BY:	INTERNAL
			OLCtrlDraw
PASS:		*ds:si = OLCtrl
		bp = gstate
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CTRL_USES_BACKGROUND_COLOR

DrawCtrlBackground	proc	near
	uses	ax,bx,cx,dx,di, es
	.enter
	call	GetCtrlCustomColor
	jnc	done				; no custom color
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	mov	cx, ax				; cx = colors
	mov	di, bp				; di = gstate
	jnz	fullyEnabled
	mov	al, SDM_50
	call	GrSetAreaMask			; 50% if disabled
fullyEnabled:
	call	GrGetAreaColor
	pushdw	bxax				; save current color
	push	cx				; save colors
	mov_tr	ax, cx				; ax = colors
	clr	ah
	call	GrSetAreaColor			; set main color
	call	VisGetBounds
	call	GrFillRect
	pop	ax				; al = main, ah = mask color
	cmp	al, ah				; same color?
	je	washDone			; yes, done
	clr	ah
	call	GrSetAreaColor
	mov	al, SDM_50
	call	GrSetAreaMask
	call	VisGetBounds
	call	GrFillRect
washDone:
	popdw	bxax
	call	GrSetAreaColor			; restore color
	mov	al, SDM_100
	call	GrSetAreaMask			; restore mask
done:
	.leave
	ret
DrawCtrlBackground	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCtrlCustomColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get custom color for OLCtrl, if any

CALLED BY:	INTERNAL
			DrawCtrlBackground
			ClearMonikerArea
PASS:		*ds:si = OLCtrl
RETURN:		carry set if custom color
			al = main color
			ah = mask color
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCtrlCustomColor	proc	near
	;
	; only have custom color if we are a OLItemGroup or a
	; GIV_SUB_GROUP GenInteraction
	;
	mov	di, segment GenInteractionClass
	mov	es, di
	mov	di, offset GenInteractionClass
	call	ObjIsObjectInClass
	jnc	checkItemGroup
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_SUB_GROUP
	je	checkColor
	clc					; indicate no custom color
	jmp	short done

checkItemGroup:
	mov	di, segment OLItemGroupClass
	mov	es, di
	mov	di, offset OLItemGroupClass
	call	ObjIsObjectInClass
	jnc	done				; carry clear, no custom color
	mov	ax, HINT_ITEM_GROUP_TAB_STYLE
	call	ObjVarFindData
	cmc					; carry clear if tabs
	jnc	done				; no custom color for tabs
	;
	; get custom background color
	;
checkColor:
	mov	ax, 0				; unselected color, please
	call	OpenGetBackgroundColor		; carry set if custom color
done:
	ret
GetCtrlCustomColor	endp

endif ; CTRL_USES_BACKGROUND_COLOR


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenDrawCtrlMoniker

SYNOPSIS:	Draws the moniker for OLCtrl and their kin, if the moniker
		is being used.   Also draws a box around things if the
		appropriate flag is set.

CALLED BY:	OLCtrlDraw, OLScrollingListDraw

PASS:		*ds:si -- handle of object
		bp - graphics state

RETURN:		nothing

DESTROYED:	cx, dx, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89		Initial version

------------------------------------------------------------------------------@

OpenDrawCtrlMoniker	proc	far
	class	OLCtrlClass

	;
	; Set patterns to 50% if not enabled.
	;
	push	bp				;save gstate
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jnz	drawFrame			;enabled, OK, branch

clearEm:	
	call	ClearMonikerArea		;clear area behind monikers

if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	di, bp			        ;else pass gstate
	mov	al, SDM_50			;use a 50% mask
	call	GrSetLineMask
	call	GrSetTextMask
endif	
drawFrame:
	;
	; Set up line and text draw colors.
	;
if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	di, bp
endif
	mov	ax, C_BLACK
if USE_COLOR_FOR_DISABLED_GADGETS
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jnz	setColorOK			;enabled, OK, branch
	mov	ax, DISABLED_COLOR
setColorOK:
	mov	di, bp
	call	GrSetAreaColor
endif
	call	GrSetLineColor			;set line color to black
	call	GrSetTextColor			;and text color

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	push	di
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_rudyFlags, mask OLCRF_HAS_FOCUS
	pop	di
	jz	afterFocusWeirdness

	mov	ax, HINT_INTERACTION_FOCUSABLE
	call	ObjVarFindData
	jc	afterFocusWeirdness		;don't change color if this
						;  hint is present! 10/21/94 cbh
	mov	di, bp
	mov	ax, C_BLACK
	call	GrSetLineColor			;set line color to black
	call	GrSetTextColor			;and text color

afterFocusWeirdness:
	
endif

	clr	dx				;assume no x margins

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_BORDER
	jz	skipRect

	call	DrawCtrlFrame			;draw frame around control	

   	mov	dx, TOP_FRAME_AT_END_MARGIN + OL_CTRL_MKR_MARGIN	
						;default x margin, for use if
						; left or right justifying
skipRect:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	LONG	jz	exit			;not doing monikers, exit

	;
	; Center the object if drawing a frame, otherwise left justify.
	; X margin kept in dx.
	;
    
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	cx, ds:[di].OLCI_monikerPos.P_y

	;
	; If aligning with child object, substitute that now.  Must be
	; set along with DISPLAY_MKR_ABOVE.
	;
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	jz	noMaligning

	test	ds:[di].OLCI_moreFlags, \
			mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD
	jz	noMaligning
	mov	dx, ds:[di].OLCI_monikerPos.P_x	;use our special left inset

noMaligning:
	test	ds:[di].OLCI_optFlags, mask OLCOF_CENTER_ON_MONIKER
	jz	noCenter
	test	ds:[di].OLCI_optFlags, mask OLCOF_LEFT_JUSTIFY_MONIKERS
	jnz	noCenter
	push	ax
	call	GetParentMonikerSpace		;get parent space
	add	dx, ax
	pop	ax
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	sub	dx, ds:[di].OLCI_monikerSpace	;subtract our space

noCenter:
	mov	di, bp				;gstate in di
	sub	sp, size OpenMonikerArgs	;make room for args
	mov	bp, sp				;pass pointer in bp
EC <	call	ECInitOpenMonikerArgs	        ;save IDs on stack for testing>
	mov	ss:[bp].OMA_gState, di		;pass gstate
	mov	ss:[bp].OMA_leftInset, dx	;pass left inset
	mov	ss:[bp].OMA_rightInset, dx	;pass right inset
	mov	ss:[bp].OMA_topInset, cx	;pass top inset 
	mov	ss:[bp].OMA_bottomInset, cx	;pass bottom inset 
	mov	ss:[bp].OMA_monikerAttrs, mask OLMA_DRAW_SHORTCUT_TO_RIGHT or \
		    			  mask OLMA_DISP_KBD_MONIKER

	mov	cl, (J_LEFT shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST)
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_moreFlags, mask OLCOF_LEFT_JUSTIFY_MONIKER
	jnz	draw				;left justifying, branch
	
	mov	cl, (J_RIGHT shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST)
	test	ds:[di].OLCI_moreFlags, mask OLCOF_RIGHT_JUSTIFY_MONIKER
	jnz	draw				;right justifying, branch

	mov	cl, (J_CENTER shl offset DMF_X_JUST) or \
		    (J_LEFT shl offset DMF_Y_JUST) 

draw:
	clr	ch
; pass flag to underline accelerator
	mov	ss:[bp].OMA_drawMonikerFlags, cx
	segmov	es, ds				;*es:bx - generic object
	mov	bx, si
	call	OpenDrawMoniker			;draw the moniker
EC <	call	ECVerifyOpenMonikerArgs	;make structure still ok	>

	add	sp, size OpenMonikerArgs	;dump args
	
exit:
	pop	di				;restore gstate
if not USE_COLOR_FOR_DISABLED_GADGETS
	mov	al, SDM_100			;restore masks to 100%
	call	GrSetLineMask
	call	GrSetTextMask
endif
	ret
OpenDrawCtrlMoniker	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawCtrlFrame

SYNOPSIS:	Draws a frame around the control.

CALLED BY:	OpenDrawCtrlMoniker

PASS:		*ds:si -- object
		bp -- gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/29/90		Initial version

------------------------------------------------------------------------------@

if DRAW_STYLES

CtrlDrawHints	VarDataHandler \
	<HINT_DRAW_STYLE_FLAT, CtrlDrawFlat>,
	<HINT_DRAW_STYLE_3D_RAISED, CtrlDrawRaised>,
	<HINT_DRAW_STYLE_3D_LOWERED, CtrlDrawLowered>,
	<HINT_INTERACTION_NOTEBOOK_STYLE, CtrlDrawNotebook>

CtrlDrawFlat	proc	far
	tst	dx
	jnz	done			; something overrides us
	mov	cx, ((mask DIAFF_FRAME or mask DIAFF_NO_WASH) shl 8) or DS_FLAT
done:
	ret
CtrlDrawFlat	endp

CtrlDrawRaised	proc	far
	tst	dx
	jnz	done			; something overrides us
	mov	cx, ((mask DIAFF_NO_WASH) shl 8) or DS_RAISED
done:
	ret
CtrlDrawRaised	endp

CtrlDrawLowered	proc	far
	cmp	dx, 1
	ja	done			; something overrides us
	mov	dx, 1			; we have medium priority
	mov	cx, ((mask DIAFF_NO_WASH) shl 8) or DS_LOWERED
done:
	ret
CtrlDrawLowered	endp

CtrlDrawNotebook	proc	far
	mov	dx, 2			; highest priority
	mov	cx, ((mask DIAFF_FRAME or mask DIAFF_NO_WASH) shl 8) or DS_FLAT
	ret
CtrlDrawNotebook	endp

endif ; DRAW_STYLES

DrawCtrlFrame	proc	near

if DRAW_STYLES ;---------------------------------------------------------------

	;
	; get draw flags based on draw style
	;
	push	es
	clr	dx				; no override yet
						; default to lowered
	mov	cx, ((mask DIAFF_NO_WASH) shl 8) or DS_LOWERED
	mov	di, segment OLItemGroupClass
	mov	es, di
	mov	di, offset OLItemGroupClass
	call	ObjIsObjectInClass
	jnc	haveDefault			; not item group, lowered def.
						; item group, flat default
	mov	cx, ((mask DIAFF_FRAME or mask DIAFF_NO_WASH) shl 8) or DS_FLAT
haveDefault:
	segmov	es, cs
	mov	di, offset CtrlDrawHints
	mov	ax, length CtrlDrawHints
	call	ObjVarScanData			; cx = draw flags
	pop	es
	;
	; draw OLCtrl frame for draw styles
	;
	mov	di, bp				; di = gstate
	push	cx				; pass flags
	mov	ax, (DRAW_STYLE_FRAME_WIDTH shl 8) or DRAW_STYLE_THIN_INSET_WIDTH
	push	ax				; pass widths
	call	VisGetBounds
	call	OpenDrawInsetAndFrame

else ;-------------------------------------------------------------------------

if (_MOTIF or _ISUI) and ALLOW_TAB_ITEMS
	;
	; Handle HINT_RAISED_FRAME
	;
	mov	ax, HINT_RAISED_FRAME
	call	ObjVarFindData
	jnc	noRaisedFrame

	mov	di, bp					;di <- GState
	mov	bp, {GenRaisedFrameInfo}ds:[bx]	     ;bp <- GenRaisedFrameInfo
	;
	; Draw top and left in white
	;
	mov	ax, C_WHITE
	call	GrSetLineColor
	call	VisGetBounds

	test	bp, mask GRFI_TOP
	jz	noTopLine
	call	GrDrawHLine
noTopLine:

	test	bp, mask GRFI_LEFT
	jz	noLeftLine
	call	GrDrawVLine
noLeftLine:

	;
	; draw bottom and right in dark color (and black for ISUI)
	;

if _MOTIF
	push	ax
	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax
endif

	test	bp, mask GRFI_BOTTOM
	jz	noBottomLine

if _MOTIF
	xchg	bx, dx				;bx <- bottom
	call	GrDrawHLine
	xchg	bx, dx				;bx <- top
elseif _ISUI
	push	ax, bx
	mov	bx, dx				;bx <- botom
	call	setBlack
	call	GrDrawHLine
	call	setDark
	dec	bx
	inc	ax
	call	GrDrawHLine
	pop	ax, bx
endif
noBottomLine:

	test	bp, mask GRFI_RIGHT
	jz	noRightLine
if _MOTIF
	mov_tr	ax, cx				;ax <- right
	call	GrDrawVLine
elseif _ISUI
	mov_tr	ax, cx
	call	setBlack
	call	GrDrawVLine
	dec	ax
	call	setDark
	call	GrDrawVLine
endif
noRightLine:

	jmp	raisedFrameDone

noRaisedFrame:
endif	
	;	
	; Get the coordinates to use for the box.  We need to inset the box
	; from any window-imposed margins we've added.  Also we won't be
	; drawing the line under the moniker text.
	;
	call	VisGetSize			;get width of the control
	push	cx				;now save the overall width #1
	
	call	SpecGetGenMonikerSize		;get the size of the moniker
	push	cx				;save width		#2
	push	dx				;save height		#3
	push	bp				;save gstate		#4
	clr	cl				;get real ctrl bounds
	call	OpenGetLineBounds		;
	
	pop	bp				;restore gstate		#4
 	pop	di				;restore height		#3

	tst	di				;was there a moniker?
	jz	5$				;no, branch

	add	bx, CTRL_MKR_INSET_Y		;else add offset to text to top
5$:
	shr	di, 1				;divide moniker height by 2
	add	bx, di				;add half moniker ht to top

if DRAW_LEAF_IF_HAVE_FOCUS
	push	di				;save moniker height	#L3
endif
	mov	di, bp				;keep gstate in di
	;
	; Frame coordinates in ax, bx, cx, dx.  Draw the sides and bottom,
	; then do some calculations to do the edges.
	;

if CTRL_ROUNDED_BOX_CORNERS
	call	DrawRoundedBoxCorners					

	push	bx, dx				;			#C4,5
	add	bx, 4							
	sub	dx, 4							
endif

if DRAW_LEAF_IF_HAVE_FOCUS
	push	ax, dx				;save left, top for leaf #L6,7
endif
	clc					;left pos OK
	call	DrawEtchedVLine			;draw left edge

	xchg	ax, cx				;pass right x pos

	stc					;need to fix if etching
	call	DrawEtchedVLine			;draw right edge

if CTRL_ROUNDED_BOX_CORNERS
	pop	bx, dx				;			#C4,5
	sub	ax, 4							
	add	cx, 4							
endif

	xchg	ax, cx				;restore original setup
	xchg	bx, dx				;pass bottom x pos
	stc					;need to fix if etching
	dec	cx				;this pixel already drawn
	call	DrawEtchedHLine			;draw bottom line
	inc	cx

if DRAW_LEAF_IF_HAVE_FOCUS
	pop	di, bx				;left, top to draw leaf...#L6,7
	call	DrawLeafIfHaveFocus		;see if have focus, draw leaf
endif
	;
	; Calculate how much line to draw to the left and right of the 
	; moniker.  And draw them.
	;
	mov	bx, dx				;pass top x pos again
if DRAW_LEAF_IF_HAVE_FOCUS
	pop	di				;restore moniker height   #L3
	add	bx, di				;add to top, for underline
endif
	pop	di				;restore moniker width	 #2
	pop	dx				;restore control width   #1

if CTRL_ROUNDED_BOX_CORNERS
	mov	dx, cx							
	sub	dx, ax				;width = x2-x1		
endif

	call	DrawCtrlFrameTopLines		;draw top lines

if _MOTIF or _ISUI
raisedFrameDone:
endif
endif ; DRAW_STYLES -----------------------------------------------------------

	ret

if _ISUI

setBlack:
	push	ax
	mov	ax, C_BLACK
	call	GrSetLineColor
	pop	ax
	retn

setDark:
	push	ax
	call	GetDarkColor
	call	GrSetLineColor
	pop	ax
	retn

endif
DrawCtrlFrame	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLeafIfHaveFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the silly leaf if we have the focus.

CALLED BY:	DrawCtrlFrame

PASS:		*ds:si -- OLCtrl
		di, bx -- left/bottom corner of leaf if we draw
		bp -- gstate

RETURN:		nothing

DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/25/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DRAW_LEAF_IF_HAVE_FOCUS

DrawLeafIfHaveFocus	proc	near		uses	ax, cx, dx, ds, si
	.enter
	push	bx
	mov	ax, HINT_INTERACTION_FOCUSABLE
	call	ObjVarFindData
	pop	bx
	jnc	exit				;not doing this shme

	mov	ax, di				;left edge
	mov	dx, bx				;bottom edge
	mov	di, bp				;gstate in di
	;
	; Clear out area behind leaf
	;
	push	ax
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax

	mov	bx, dx
	sub	bx, CTRL_LEAF_ICON_HEIGHT
	mov	cx, ax
	add	cx, CTRL_LEAF_ICON_WIDTH
	inc	ax				;back off of outside lines
	dec	dx
	call	GrFillRect
	dec	ax				;restore
	inc	dx

	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_rudyFlags, mask OLCRF_HAS_FOCUS
	pop	di
	jz	exit

	;
	; Doing a leaf, gotta clear some more pixels.
	;
	push	bx				;save bitmap top
	dec	ax
	inc	dx
	inc	dx
	call	GrFillRect
	inc	ax
	pop	bx

	;
	; Now for our fun little leaf!
	;
	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	clr	dx				;no callback
FXIP <	push	bx, ax							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	bx, ax							>
NOFXIP <segmov	ds, cs, si						>

	mov	si, offset LeafBlackBitmap
	call	GrFillBitmap

	push	ax
	mov	ax, C_LIGHT_GREY
	call	GrSetAreaColor
	pop	ax

	mov	si, offset LeafGreyBitmap
	call	GrFillBitmap

FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>
exit:
	.leave
	ret
DrawLeafIfHaveFocus	endp

FXIP < DrawBWRegions	segment resource				>

LeafBlackBitmap	label	word
	word	CTRL_LEAF_ICON_WIDTH		;width
	word	CTRL_LEAF_ICON_HEIGHT		;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	11111111b, 11110000b
	byte	01000000b, 00010000b
	byte	00100000b, 00010000b
	byte	00010000b, 00010000b
	byte	00001000b, 00010000b
	byte	00000100b, 00010000b
	byte	00000010b, 00010000b
	byte	00000001b, 00010000b
	byte	00000000b, 10010000b
	byte	00000000b, 01010000b
	byte	00000000b, 00110000b
	byte	00000000b, 00010000b


LeafGreyBitmap	label	word
	word	CTRL_LEAF_ICON_WIDTH		;width
	word	CTRL_LEAF_ICON_HEIGHT		;height
	byte	BMC_UNCOMPACTED			;method of compaction
	byte	BMF_MONO			;bitmap type
	byte	00000000b, 00000000b
	byte	00111111b, 11100000b
	byte	00011111b, 11100000b
	byte	00001111b, 11100000b
	byte	00000111b, 11100000b
	byte	00000011b, 11100000b
	byte	00000001b, 11100000b
	byte	00000000b, 11100000b
	byte	00000000b, 01100000b
	byte	00000000b, 00100000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b


FXIP <DrawBWRegions	ends						>

endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawEtchedVLine

SYNOPSIS:	Draws an etched line.

CALLED BY:	DrawCtrlFrame

PASS:		ax -- x position
		bx, dx -- top, bottom
		di -- gstate, with GS_areaColor = C_BLACK
		carry set if we should decrement ax if etching
		if RUDY:
			carry set means draw a shadow.


RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/92       	Initial version

------------------------------------------------------------------------------@

if (not DRAW_STYLES)	; not needed for draw styles frame drawing

DrawEtchedVLine	proc	near			uses	ax
	.enter
if _MOTIF or _ISUI
	jnc	10$				;no position problems, branch
	call	OpenCheckIfBW			;B/W, branch
	jc	10$
	dec	ax				;adjust ax for first line
10$:
	call	GrDrawVLine
	call	OpenCheckIfBW
	jc	exit				;B/W, done
	inc	ax
	call	SetWhiteIfNotClearing		
	pushf
	call	GrDrawVLine
	popf
	jc	exit				;didn't change color, exit
	call	SetBlack
exit:

else	;not _MOTIF or _ISUI

	call	GrDrawVLine
endif
	.leave
	ret
DrawEtchedVLine	endp

endif ; (not DRAW_STYLES)


COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawEtchedHLine

SYNOPSIS:	Draws an etched horizontal line.

CALLED BY:	DrawCtrlFrame

PASS:		ax, cx -- left, right
		bx -- y position
		di -- gstate, with GS_areaColor = C_BLACK
		carry set if we should decrement bx if etching
		bp set if we're actually clearing the thing (i.e drawing in
			the window bkgd color)
		if RUDY:
			carry set means draw a shadow.

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Note: Coordinates are line coordinates, so if using GrFillXX,
	make sure to asjust.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/92       	Initial version

------------------------------------------------------------------------------@

DrawEtchedHLine	proc	near		uses	bx
	.enter
if _MOTIF or _ISUI
	jnc	10$				;no position problems, branch
	call	OpenCheckIfBW			;B/W, branch
	jc	10$
	dec	bx
10$:
	call	GrDrawHLine
	call	OpenCheckIfBW
	jc	exit				;B/W, done
	inc	bx
	call	SetWhiteIfNotClearing
	pushf
	call	GrDrawHLine
	popf
	jc	exit				;didn't change color, exit
	call	SetBlack
exit:
else	;not _MOTIF or _ISUI
	call	GrDrawHLine
endif
	.leave
	ret
DrawEtchedHLine	endp

if (_MOTIF or _ISUI)

SetWhiteIfNotClearing	proc	near	uses	ax
	.enter
	mov	ax, C_WHITE
	call	SetColorIfNotClearing
	.leave
	ret
SetWhiteIfNotClearing	endp

SetBlack	proc	near	uses	ax
	.enter
	mov	ax, C_BLACK
	call	GrSetLineColor
	.leave
	ret
SetBlack	endp

SetColorIfNotClearing	proc	near
	; ax - color
	; returns carry set if nothing done

	push	ax, bx, ds			;this code makes me sad. 
	call	GrGetLineColor			;returns RGB line color
	tst	al
	jnz	10$
	tst	bx
10$:
	pop	ax, bx, ds
	stc
	jnz	exit				;not doing black (0.0.0), exit
	call	GrSetLineColor
	clc
exit:
	ret
SetColorIfNotClearing	endp

endif

if (not DRAW_STYLES)	; not needed for draw styles frame drawing


COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawCtrlFrameTopLines

SYNOPSIS:	Draws top lines of a framed OLCtrl.

CALLED BY:	DrawCtrlFrame

PASS:		*ds:si -- ctrl
		ax -- left edge to draw from
		cx -- right edge to draw to
		bx -- y position of top
		di -- moniker width
		dx -- control width
		bp -- gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/17/92		Initial version

------------------------------------------------------------------------------@

DrawCtrlFrameTopLines	proc	near		uses	si

	.enter
	mov	si, ds:[si]			
	add	si, ds:[si].Vis_offset
	;
	; First, calculate how far to draw the left part of the line to, based 
	; on the justification being used.
	;

	tst	di				;no moniker, draw whole thing
	jz	gotLeftLineLen

	test	ds:[si].OLCI_moreFlags, mask OLCOF_LEFT_JUSTIFY_MONIKER
	jnz	leftJustified			;left justified, branch

	sub	dx, di				;dx <- length - mkrWidth
	sub	dx, OL_CTRL_MKR_MARGIN * 2	;leave margins around moniker
	tst	dx
	jns	10$
	clr	dx
10$:

	test	ds:[si].OLCI_moreFlags, mask OLCOF_RIGHT_JUSTIFY_MONIKER
	jnz	rightJustified			;right justified, branch

	shr	dx, 1				;else centering: divide by two
	jmp	short gotLeftLineLen

rightJustified:
	sub	dx, TOP_FRAME_AT_END_MARGIN	;right justified, leave a bit
	jmp	short gotLeftLineLen		;  of a line on right side	

leftJustified:
	test	ds:[si].OLCI_moreFlags, \
			mask OLCOF_ALIGN_LEFT_MKR_EDGE_WITH_CHILD
	jz	noMaligning
	mov	dx, ds:[si].OLCI_monikerPos.P_x	;use our special left inset
	sub	dx, OL_CTRL_MKR_MARGIN
	jnz	gotLeftLineLen
	clr	dx
	jmp	short gotLeftLineLen

noMaligning:
	mov	dx, TOP_FRAME_AT_END_MARGIN	;leave a little line on left

gotLeftLineLen:

	push	cx				;save right edge
	mov	cx, ax				;left edge in cx
	add	cx, dx				;add line before moniker
	dec	cx				;adjust for strange text place
	push	di				;save length of moniker
	mov	di, bp
	inc	ax				;this pixel already drawn
	clc					;position OK

	call	DrawEtchedHLine			;draw the line left of moniker

	pop	ax				;restore moniker length

	tst	ax
	jz	doneEarly			;no moniker, done.

	add	ax, cx				;add right edge of line
	add	ax, OL_CTRL_MKR_MARGIN*2	;add space around moniker

	pop	cx				;restore right edge
	dec	ax				;adjust for strange text place
if	_MOTIF
	call	OpenCheckIfBW
	jc	rightEdgeOK
	sub	cx, 2				;these 2 pixels already drawn
rightEdgeOK:
endif
	clc					;position OK
	
	call	DrawEtchedHLine			;and draw the right line
	jmp	short exit

doneEarly:
	pop	cx
exit:
	.leave
	ret
DrawCtrlFrameTopLines	endp

endif ; (not DRAW_STYLES)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRoundedBoxCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw rounded corners

CALLED BY:	DrawCtrlFrame
PASS:		*ds:si		= ctrl
		(ax,bx,cx,dx)	= box corners
		di		= gstate, with GS_areaColor = C_BLACK
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CTRL_ROUNDED_BOX_CORNERS	;----------------------------------------------

DrawRoundedBoxCorners	proc	near
	uses	cx,dx,si,ds
	.enter

	push	ax
	mov	ax, C_BLACK
	call	GrSetAreaColor
	pop	ax

	segmov	ds, cs
	mov	si, offset RoundedBoxCorners
	sub	cx, ax
	sub	dx, bx
	call	GrDrawRegion

	.leave
	ret
DrawRoundedBoxCorners	endp

RoundedBoxCorners	label	Region
	word	0, 0, PARAM_2-1, PARAM_3-1	;bounds
	word	0,						EOREGREC
	word	1,		2, 3, PARAM_2-3, PARAM_2-2,	EOREGREC
	word	3,		1, 1, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-4,					EOREGREC
	word	PARAM_3-2,	1, 1, PARAM_2-1, PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	2, 3, PARAM_2-3, PARAM_2-2,	EOREGREC
	word	EOREGREC

endif		;--------------------------------------------------------------

	

COMMENT @----------------------------------------------------------------------

ROUTINE:	ClearMonikerArea

SYNOPSIS:	Clears the area behind the moniker.  We also must clear the
		area around the frame, if any.

CALLED BY:	DrawCtrlMoniker

PASS:		*ds:si -- handle of moniker
		bp     -- gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/29/90		Initial version

------------------------------------------------------------------------------@

ClearMonikerArea	proc	near		     ;CANNOT BE FAR ROUTINE
						     ;  AS WRITTEN!

if CTRL_USES_BACKGROUND_COLOR
	;
	; use wash color or custom background color to clear moniker area
	;
	call	OpenGetWashColors			; ax = colors
	mov	cx, ax
	call	GetCtrlCustomColor			; any custom color?
	jnc	useColor				; use wash color
	mov	cx, ax					; use custom color
useColor:
	clr	ax					; CF_INDEX
	mov	al, cl					; main color
else
						     ;al <- color scheme.
	push	ds
	mov	ax, segment moCS_dsLightColor
	mov	ds, ax
	mov	al, ds:[moCS_dsLightColor]	     ;get the light display
						     ;	scheme color
	pop	ds

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	mov	di, ds:[si]			     ;point to instance
	add	di, ds:[di].Vis_offset	             ;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_rudyFlags, mask OLCRF_HAS_FOCUS
	jz	afterFocusWeirdness
	mov	al, SELECTED_TEXT_BACKGROUND
afterFocusWeirdness:
endif

	clr	ah
endif ; CTRL_USES_BACKGROUND_COLOR
	mov	di, bp				     ;pass gstate
	call	GrSetAreaColor			     ;set as area color
	call	GrSetLineColor			     ;and line color
	
	mov	di, ds:[si]			     ;point to instance
	add	di, ds:[di].Vis_offset	     ;ds:[di] -- SpecInstance
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MONIKER
	pushf					     ;save display mkr flag
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_BORDER
	jz	clearMkr			     ;no border, branch
if DRAW_STYLES
	;
	; for draw styles, just clear rect as DrawCtrlFrame always draws
	; with fixed colors
	;	bp = gstate
	;
if CTRL_USES_BACKGROUND_COLOR
	; cx = wash colors
	push	cx				; save wash colors
	push	cx				; save wash colors again
	mov	di, bp				; di = gstate
	call	VisGetBounds
	dec	cx				; adjust for ?
	dec	dx
	call	GrDrawRect
	mov	bp, ax				; bp = left bound
	pop	ax				; ax = wash colors
	cmp	al, ah
	je	noLineMaskColor
	mov	al, ah
	clr	ah
	call	GrSetLineColor			; set mask color
	mov	al, SDM_50
	call	GrSetLineMask
	mov	ax, bp				; ax = left bound
	call	GrDrawRect
	mov	al, SDM_100
	call	GrSetLineMask
noLineMaskColor:
	mov	bp, di				; bp = gstate
	pop	cx				; cx = wash colors
else
	call	VisGetBounds
	dec	cx				; adjust for ?
	dec	dx
	call	GrDrawRect
endif ; CTRL_USES_BACKGROUND_COLOR
else
	call	DrawCtrlFrame			     ;clear out the damn frame.
endif ; DRAW_STYLES
clearMkr:
	popf					     ;restore display mkr flag
	jz	exit			     	     ;no moniker, branch
if CTRL_USES_BACKGROUND_COLOR
	mov	di, cx				; save wash colors
endif
	call	VisGetBoundsInsideMargins
	mov	dx, bx				     ;dx - top of area
	push	cx				     ;save right edge of area
if CTRL_USES_BACKGROUND_COLOR
	push	di				; save wash colors
endif
	mov	cx, ax				     ;cx - left edge of area
	mov	di, ds:[si]			     ;point to instance
	add	di, ds:[di].Vis_offset	     	     ;ds:[di] -- VisInstance
	mov	ax, ds:[di].VI_bounds.R_left	     ;real left and top
	mov	bx, ds:[di].VI_bounds.R_top
if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	add	bl, ds:[di].OLCI_invTopMargin
	adc	bh, 0
endif
	test	ds:[di].OLCI_optFlags, mask OLCOF_DISPLAY_MKR_ABOVE
	jnz	above				     ;displaying above, branch
;left:
	; Do stuff to left.

	mov	dx, ds:[di].VI_bounds.R_bottom	     

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	sub	dl, ds:[di].OLCI_invBotMargin
	sbb	dh, 0
endif

if CTRL_USES_BACKGROUND_COLOR
	pop	di				; di = wash colors
endif
	call	fillIfAnything

	; Do stuff to right. 6/ 5/94 cbh

	pop	ax				     ;get right edge of kids
if CTRL_USES_BACKGROUND_COLOR
	call	getRightBound			; cx = right bound
else
	mov	cx, ds:[di].VI_bounds.R_right
endif
	jmp	short fillIfAnything		     ;and go clear things
above:	
if CTRL_USES_BACKGROUND_COLOR
	pop	di				; di = wash colors
endif
	pop	cx				     ;toss saved right edge	
if CTRL_USES_BACKGROUND_COLOR
	call	getRightBound			; cx = right bound
else
	mov	cx, ds:[di].VI_bounds.R_right	     ;clear to right edge	
endif

fillIfAnything:
	;
	; rect = ax, bx, cx, dx 
	; bp = gstate
if CTRL_USES_BACKGROUND_COLOR
	; di = wash colors
endif
	; preserves di
	;
	push	di
	cmp	ax, cx
	jge	nope				     ;ax=cx does nothing
	cmp	bx, dx
	jge	nope
	mov	di, bp				     ;gstate in di

if PARENT_CTRLS_INVERTED_ON_CHILD_FOCUS
	inc	cx				     ;and hope for the best

	;Another terrible hack to limit the size of the inverted area.

	push	bp
	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_rudyFlags, mask OLCRF_HAS_FOCUS
	pop	di
	jz	afterHack
	
	mov	bp, dx
	sub	bp, bx
	cmp	bp, 24				    ;avoid too large an outline
	jbe	afterHack
	mov	dx, bx
	add	dx, 16
afterHack:
	pop	bp

endif

	call	GrFillRect			     ;and fill in the rectangle
if CTRL_USES_BACKGROUND_COLOR
	;
	; handle wash mask color, if any
	;	ax, bx, cx, dx = bounds
	;	bp = di = gstate
	;	on stack: wash colors
	;
	pop	di				; di = wash colors
	push	di				; save again
	push	bp				; save gstate
	xchg	ax, di				; ax = wash colors, di = left
	xchg	bp, di				; bp = left, di = gstate
	cmp	al, ah				; any mask color?
	je	noAreaMaskColor
	mov	al, ah
	clr	ah
	call	GrSetAreaColor			; set mask color
	mov	al, SDM_50
	call	GrSetAreaMask
	mov	ax, bp				; ax = left bound
	call	GrFillRect
	mov	al, SDM_100
	call	GrSetAreaMask
noAreaMaskColor:
	mov	ax, bp				; ax = left bound
	pop	bp				; bp = gstate
endif
nope:
	pop	di
exit:
	retn					     

if CTRL_USES_BACKGROUND_COLOR
getRightBound	label	near
	push	di				; save wash colors
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VI_bounds.R_right
	pop	di				; di = save wash colors
	retn
endif

ClearMonikerArea	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCtrlBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}. We handle here so that
		the broadcast can be propogated into GenInteractions (OLCtrl)
		which are inside a window.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= OD of object with hint
		carry set if broadcast handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version
	Eric	5/90		rewritten to use broadcast which scans entire
					window.

------------------------------------------------------------------------------@

OLCtrlBroadcastForDefaultFocus	method	OLCtrlClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	exit			;toolbox, exit, carry clear

	;send MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS to all visible
	;children which are FULLY_ENABLED. Returns OD of last object in visible
	;tree which has HINT_DEFAULT_FOCUS{_WIN}.

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	mov	bx, offset OLBroadcastForDefaultFocus_callBack
					;pass offset to callback routine,
					;in Resident resource
	call	OLResidentProcessVisChildren

	lahf
	pop	di
	call	ThreadReturnStackSpace
	sahf

exit:
	ret

OLCtrlBroadcastForDefaultFocus	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCtrlVupQuery

DESCRIPTION:	We intercept visual-upward queries here to see if we
		can answer them.

PASS:		*ds:si	= instance data for object
		cx	= SpecVisQueryType (see cConstant.def)

RETURN:		carry set if answered query

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/90		initial version
	Chris	6/16/92		Added SVQT_BACKGROUND_COLORS

------------------------------------------------------------------------------@

OLCtrlVupQuery	method dynamic	OLCtrlClass, MSG_VIS_VUP_QUERY

if HOLISTIC_SCROLLBAR_POSITIONING
	;
	; Someone's asking us about where scrollbars should go.
	;
	cmp	cx, SVQT_SCROLLBAR_POSITION
	jne	notHolistic

	;
	; bp = ScrollbarPositionQueryFlags

	; We only want to manhandle the scrollbar if we are supplying
	; some margin in which to place it.
	;
	mov	ax, HINT_INDENT_CHILDREN
	call	ObjVarFindData
	jc	isHolistic

	;
	; Don't send this query up past WIN_GROUP's, because we don't
	; care what anyone else has to say.
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	callSuper			; (carry clear)

	;
	; And return "not answered"
	;
	jmp	done

isHolistic:
	;
	; Are they asking for a position, or just whether or not
	; we care?
	;
	test	bp, mask SPQF_IS_MANAGED_BY_VIEW
	jz	figurePosition
	;
	; Tell them we like to play with left scrollbars
	;
	mov	bp, mask SPQF_LEFT
	jmp	setCarry

figurePosition:
	test	bp, mask SPQF_LEFT
	jz	done

	;
	; If indenting children, place the scrollbar inside the
	; indented margin, to the left.
	;
	call	VisGetBoundsInsideMargins	; ax,bx,cx,dx
	push	ax				; save inside X bound
	clr	ax
	call	RudyHandleChildIndent		; ax -> width of indent
	pop	cx
	sub	cx, ax

	mov	bp, mask SPQF_LEFT_JUSTIFY
	jmp	setCarry

notHolistic:
endif ; HOLISTIC_SCROLLBAR_POSITIONING

;Handled in an optimized way in copenUtils.asm
;	cmp	cx, SVQT_BACKGROUND_COLORS
;	jne	checkReplyBar
;
;	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
;	jz	done				;not in toolbox, no custom color
;
;	mov	ax, HINT_BACKGROUND_COLORS
;	call	ObjVarFindData			;see if hint exists
;	jnc	callSuper			;no hint, try superclass
;
;	mov	cx, ds:[bx].BC_unselectedColor
;	mov	dx, ds:[bx].BC_selectedColor
;	jmp	short setCarry			;else return the colors
;
;checkReplyBar:
	cmp	cx, SVQT_QUERY_FOR_REPLY_BAR
	jne	callSuper

	mov	bx, ds:[di].OLCI_buildFlags
	ANDNF	bx, mask OLBF_TARGET
	cmp	bx, OLBT_REPLY_BAR shl offset OLBF_TARGET
	clc					;assume not reply bar
	jne	done
setCarry:
	stc
done:
	ret

callSuper:
	mov	ax, MSG_VIS_VUP_QUERY		;ax trashed in some cases
	mov	di,offset OLCtrlClass
	GOTO	ObjCallSuperNoLock
OLCtrlVupQuery	endm



if _HAS_LEGOS_LOOKS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCtrlSpecSetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the hints on an OLCtrl (organizational interaction, or
		Legos "Group" component) according to the legos look
		requested, after removing the hints for its previous look.
		these hintes are stored in tables that each different SpecUI
		will change according to the legos looks they support.

CALLED BY:	MSG_SPEC_SET_LEGOS_LOOK
PASS:		*ds:si	= OLCtrlClass object
		ds:di	= OLCtrlClass instance data
		cl	= legos look
RETURN:		carry	= set if the look was invalid (new look not set)
			= clear if the look was valid (new look set)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLCtrlSpecSetLegosLook	method dynamic OLCtrlClass, 
					MSG_SPEC_SET_LEGOS_LOOK
	uses	ax, cx, dx, bp
	.enter

	clr	bx
	mov	bl, ds:[di].OLCI_legosLook
	cmp	bx, LAST_LEGOS_GROUP_LOOK
	jbe	validExistingLook

	clr	bx		; make the look valid if it wasn't
EC<	WARNING	WARNING_INVALID_LEGOS_LOOK		>

validExistingLook:
	clr	ch
	cmp	cx, LAST_LEGOS_GROUP_LOOK
	ja	invalidNewLook

	mov	ds:[di].OLCI_legosLook, cl
	;
	; remove hint from old look
	;
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosGroupLookHintTable][bx]
	tst	bx
	jz	noHintToRemove

	call	ObjVarDeleteData

	;
	; add hints for new look
	;
noHintToRemove:
	mov	bx, cx
	shl	bx			; byte value to word table offset
	mov	ax, cs:[legosGroupLookHintTable][bx]
	tst	bx
	jz	noHintToAdd		; no hints for look zero

	clr	cx
	call	ObjVarAddData

noHintToAdd:
	clc
done:
	.leave
	ret

invalidNewLook:
	stc
	jmp	done
OLCtrlSpecSetLegosLook	endm

	;
	; Make sure this table matches that in copenCtrlClass.asm.  The
	; only reason the table is in two places it is that I don't want
	; to be bringing in the CommonFunctional resource at build time,
	; and it is really a small table.
	; Make sure any changes in either table are reflected in the other
	;
legosGroupLookHintTable	label word
	word	0
LAST_LEGOS_GROUP_LOOK	equ ((($ - legosGroupLookHintTable)/(size word)) - 1)
CheckHack<LAST_LEGOS_GROUP_LOOK eq LAST_BUILD_LEGOS_GROUP_LOOK>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCtrlSpecGetLegosLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the legos look.

CALLED BY:	MSG_SPEC_GET_LEGOS_LOOK
PASS:		*ds:si	= OLCtrlClass object
		ds:di	= OLCtrlClass instance data
RETURN:		cl	= legos look
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLCtrlSpecGetLegosLook	method dynamic OLCtrlClass,
					MSG_SPEC_GET_LEGOS_LOOK
	.enter
	mov	cl, ds:[di].OLCI_legosLook
	.leave
	ret
OLCtrlSpecGetLegosLook	endm

endif		; if _HAS_LEGOS_LOOKS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLCtrlNotifyEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	forward notification to notebook parts

CALLED BY:	MSG_SPEC_NOTIFY_ENABLED, MSG_SPEC_NOTIFY_NOT_ENABLED
PASS:		*ds:si	= OLCtrlClass object
		ds:di	= OLCtrlClass instance data
		ds:bx	= OLCtrlClass object (same as *ds:si)
		es 	= segment of OLCtrlClass
		ax	= message #
		dl	= update mode
		dh	= NotifyEnabledFlags
RETURN:		carry set if visual state changed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If we are a Background control, we have a NotebookBinderClass
		child (the only vis child) and we have vardata pointing to the
		left and right pages and the notebook ring.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

OLCtrlNotifyEnabled	method dynamic OLCtrlClass, 
					MSG_SPEC_NOTIFY_ENABLED,
					MSG_SPEC_NOTIFY_NOT_ENABLED
	push	ax, dx
	mov	di, offset OLCtrlClass	; call superclass
	call	ObjCallSuperNoLock
	pop	ax, dx
	jnc	exit			; nothing special happened, exit

	push	ax			; save message
	mov	ax, TEMP_OL_CTRL_NOTEBOOK_PARTS
	call	ObjVarFindData
	pop	ax
	jnc	done			; not a Background
	push	ds:[bx].TOCNP_rightPage
	push	ds:[bx].TOCNP_rings
	push	ds:[bx].TOCNP_leftPage
	push	ax, dx
	call	VisCallFirstChild	; send to NotebookBinderClass
	pop	ax, dx
	pop	si			; *ds:si = leftPage
	call	callPart
	pop	si			; *ds:si = rings
	call	callPart
	pop	si			; *ds:si = right page
	call	callPart
done:
	stc				; indicate something changed
exit:
	ret

callPart	label	near
	tst	si
	jz	noPart
	push	ax, dx
	call	ObjCallInstanceNoLock
	pop	ax, dx
noPart:
	retn

OLCtrlNotifyEnabled	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotebookBinderVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw left, right, bottom border

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= NotebookBinderClass object
		ds:di	= NotebookBinderClass instance data
		ds:bx	= NotebookBinderClass object (same as *ds:si)
		es 	= segment of NotebookBinderClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= GState
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/ 1/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTEBOOK_INTERACTION

NotebookBinderVisDraw	method dynamic NotebookBinderClass, 
					MSG_VIS_DRAW
	push	bp
	mov	di, offset NotebookBinderClass
	call	ObjCallSuperNoLock
	pop	di

	mov	ax, C_BLACK
	call	GrSetLineColor

	call	VisGetBounds
	dec	cx			; adjust for line drawing
	dec	dx			; adjust for line drawing

	call	GrDrawVLine		; draw left border
	xchg	ax, cx
	call	GrDrawVLine		; draw right border
	mov	bx, dx
	GOTO	GrDrawHLine		; draw bottom border

NotebookBinderVisDraw	endm

endif	; NOTEBOOK_INTERACTION

if _ISUI

OLCtrlNoInputDestination	method dynamic OLCtrlClass, 
					MSG_SPEC_NO_INPUT_DESTINATION
	cmp	bp, MSG_META_START_MOVE_COPY
	jne	done
	push	ds
	mov	ax, segment olRightClickHelp
	mov	ds, ax
	tst	ds:[olRightClickHelp]
	pop	ds
	jz	done
	call	ShowHelpMenu
done:
	ret
OLCtrlNoInputDestination	endm

endif

CommonFunctional	ends
