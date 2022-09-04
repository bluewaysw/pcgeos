COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for specific UIs)
FILE:		copenValueText.asm

METHODS:
 Name			Description
 ----			-----------

ROUTINES:
 Name			Description
 ----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/95		Initial revision

DESCRIPTION:
	This is the class used for GenValues, when they turn into simple
	text objects rather than spin gadgets.

	$Id: copenValueText.asm,v 1.6 96/04/05 16:28:23 chris Exp $


-------------------------------------------------------------------------------@


CommonFunctional	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLValueTextInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize an OpenLook text display object.

CALLED BY:	via MSG_META_INITIALIZE.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_META_INITIALIZE.
RETURN:		nothing
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
	Build the visual instance.
	    - Use the user specified state block, if one exists.
	    - Translate generic fonts into specific font ids and point sizes.
	    - Mark object as needing recalculation, so that when it is realized
	      it will get word-wrapped correctly.
	    - Copy flags from generic attributes into visual instance flags.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLValueTextInitialize	method dynamic OLValueClass, MSG_META_INITIALIZE
						; Make sure vis built out

if _RUDY
	;
	; For RUDY, set VTS_ONE_LINE before calling superclass so
	; UnderlineVisText can check it.  There's no problem setting it
	; here and again after calling superclass.
	;
	call	CF_DerefVisSpecDI
	ornf	ds:[di].VTI_state, mask VTS_ONE_LINE
endif

	mov	di, segment OLTextClass
	mov	es, di
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			;
	mov	bx, di				;
	add	di, ds:[di].Gen_offset		; get ptr to Generic data
	add	bx, ds:[bx].Vis_offset		; get ptr to Vis, VisTextIns.

	;
	; Init the margins.   Non-editable text needs no margins.
	;
	mov	ds:[bx].VTI_lrMargin, 0
	mov	ds:[bx].VTI_tbMargin, 0

	;
	; Init the rest of the thing.
	;
	mov	ds:[bx].VTI_maxLength, -1

	;
	; Now initialize the flags and attributes in the visual object.
	; Definitely not editable (this is a display object).
	; Default to not selectable, unless otherwise specified.
	; These will be set in the SpecBuild.
	;
	and	ds:[bx].VTI_state, not (mask VTS_EDITABLE or \
					mask VTS_SELECTABLE)
	;
	; Mark as using standard move/resize.
	;
	or	ds:[bx].VI_geoAttrs, mask VGA_USE_VIS_SET_POSITION
	;
	; One-line text, please.
	;
	or	ds:[bx].VTI_state, mask VTS_ONE_LINE
	
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	exit				;is read only, done.

	;
	; Make editable and selectable.
	;
	or	ds:[bx].VTI_state, mask VTS_SELECTABLE or \
				    mask VTS_EDITABLE
	or	ds:[bx].OLTDI_moreState, mask TDSS_SELECTABLE
	ornf	ds:[bx].OLTDI_specState, mask TDSS_EDITABLE
	;
	; Filter TAB's.
	;
	or	ds:[bx].VTI_filters, mask VTF_NO_TABS

exit:
	ret					; <-- RETURN

OLValueTextInitialize	endm
	

COMMENT @----------------------------------------------------------------------

METHOD:		OLValueTextSpecBuild -- 
		MSG_SPEC_BUILD for OLValueClass

DESCRIPTION:	Visibly builds a generic value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD

		bp	- SpecBuildFlags

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      		Left in CommonFunctional for simplicity of code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/19/89	Initial version

------------------------------------------------------------------------------@

OLValueTextSpecBuild	method OLValueClass, MSG_SPEC_BUILD
	push	bp
	tst	ds:[di].VTI_text		;an item already exists?
	jnz	setInitialValue			;yes, don't create one
	
SBCS <	mov	cx, GEN_VALUE_MAX_TEXT_LEN	;the longest string we'll have>
DBCS <	mov	cx, GEN_VALUE_MAX_TEXT_LEN*2	;the longest string we'll have>
	call	AllocValueText			;allocate a text moniker
	call	CF_DerefVisSpecDI
	mov	ds:[di].VTI_text, cx		;store handle of moniker
setInitialValue:

	call	CalculateMaxTextSize		;calculate a size, in dx
	call	CF_DerefVisSpecDI

if 0	;For now, we'll just use the text geometry calculations.
	;This is fine for Rudy, probably not so hot for other UI's.
	;You'll want to check for the existence of HINT_..._SIZE or
	;HINT_EXPAND_WIDTH_TO_FIT_PARENT, and if not there, put your
	;own HINT_FIXED_SIZE on there.   Or else do your own MSG_VIS_-
	;RECALC_SIZE handler or add a flag that OLText can recognize to
	;get the default width from somewhere else (a temp hint?)

	mov	ds:[di].OLSGI_desWidth, dx	;set the desired width	
	mov	ds:[di].OLSGI_textWidth, dx	;set the text width	
endif

	mov	ds:[di].OLVLI_maxLength, cx	;save max ascii length

	
	;
	; Set current value in the moniker.
	;
	call	CreateValueText		;create text for it

	;
	; Do text stuff, normal done in OLTextSpecBuild:
	;	
	call	CF_DerefVisSpecDI
	ORNF	ds:[di].OLTDI_moreState, mask TDSS_STAY_OUT_OF_VIEW

	call	SetupDelayedModeFar
	call	OLTextScanGeometryHints
	call	SetValueTextFiltersFar		;we can do this early
	call	SetDefaultBGColorFar		; Set colors (pass cx)

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
 	tst	ds:[di].GI_visMoniker		; see if there's a vis moniker	
 	jz	noComposite			; nope, don't need comp, branch
	call	CreateCompositeFar		; create composite to be in
						;    and build it.
noComposite:

if not _RUDY
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	noFrame
	call	ValueTextFrame			;frame is there by default
noFrame:
endif

if _RUDY
	;
	; No underline in Rudy.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	underline
	call	ValueTextNoUnderline
underline:
endif
	;Check for default action behavior

	mov	ax, MSG_OL_WIN_IS_DEFAULT_ACTION_NAVIGATE_TO_NEXT_FIELD
	call	CallOLWin			; carry set if so
	jnc	notNavigateToNextField
	call	CF_DerefVisSpecDI
	ornf	ds:[di].OLTDI_moreState, \
			mask TDSS_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD
notNavigateToNextField:

	clr	cx				; use default widths
	clr	dx
	segmov	es, cs				; setup es:di to be ptr to
						; Hint handler table
	mov	di, offset cs:PreValueHintHandler
	mov	ax, length (cs:PreValueHintHandler)
	call	OpenScanVarData

	pop	bp
	mov	di, offset OLTextClass
	mov	ax, segment OLTextClass
	mov	es, ax
	mov	ax, MSG_SPEC_BUILD
	CallSuper	MSG_SPEC_BUILD		; build it please. (skip OLText)


	call	ValueTextSetItem		; select the item, etc.
	
	call	OpenGetParentBuildFlagsIfCtrl	
	test	cx, mask OLBF_DELAYED_MODE
	jz	notDelayed
	call	CF_DerefVisSpecDI
	or	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
notDelayed:

	;
	; Set a flag in the OLCtrl that we can't be overlapping objects.
	; -cbh 2/22/93
	;
	call	OpenCheckIfBW				;not B/W, don't sweat
	jnc	checkNoRightArrow
	call	SpecSetFlagsOnAllCtrlParents		;sets CANT_OVERLAP_KIDS
checkNoRightArrow:

if _RUDY
	clr	cx				;  no arrow desired
	mov	ax, MSG_SPEC_NOTIFY_DESIRE_RIGHT_ARROW
	call	VisCallParent
endif

	;
	; Mark the dialog box applyable if we're coming up modified, via
	; the queue, to ensure the dialog box is all set up.
	; -cbh 2/ 9/93
	;
	call 	CF_DerefGenDI
	test	ds:[di].GVLI_stateFlags, mask GVSF_MODIFIED
	jz	exit
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage
exit:
	ret
OLValueTextSpecBuild	endm

if _RUDY
PreValueHintHandler	VarDataHandler \
	<HINT_VALUE_CUSTOM_RETURN_PRESS, offset ValueCustomReturnPress>,
	<HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS, \
			offset ValueNavigateOnReturnPress>, 
 	<ATTR_GEN_PROPERTY, offset ValueTextProperty>, 
	<ATTR_GEN_NOT_PROPERTY, offset ValueTextNotProperty>,
	<HINT_VALUE_NO_UNDERLINE, offset ValueTextNoUnderline>
else ;not _RUDY
PreValueHintHandler	VarDataHandler \
	<HINT_VALUE_CUSTOM_RETURN_PRESS, offset ValueCustomReturnPress>,
	<HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS, \
			offset ValueNavigateOnReturnPress>, 
 	<ATTR_GEN_PROPERTY, offset ValueTextProperty>, 
	<ATTR_GEN_NOT_PROPERTY, offset ValueTextNotProperty>,
	<HINT_VALUE_FRAME, offset ValueTextFrame>
endif ;_RUDY


ValueTextProperty	proc	far
	call	CF_DerefVisSpecDI
	or	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
	ret
ValueTextProperty	endp

ValueTextNotProperty	proc	far
	call	CF_DerefVisSpecDI
	and	ds:[di].OLTDI_moreState, not mask TDSS_DELAYED
	ret
ValueTextNotProperty	endp


if not _RUDY
ValueTextFrame		proc	far
	call	CF_DerefVisSpecDI
	or	ds:[di].OLTDI_specState, mask TDSS_IN_FRAME
CUAS <	mov	ds:[di].VTI_lrMargin, FRAME_TEXT_MARGIN			     >
CUAS <	mov	ds:[di].VTI_tbMargin, FRAME_TEXT_MARGIN			     >
	ret
ValueTextFrame		endp
endif


if _RUDY
ValueTextNoUnderline		proc	far
	clr	cx
	mov	ax, ATTR_UNDERLINED_VIS_TEXT_NO_UNDERLINES
	call	ObjVarAddData
	ret
ValueTextNoUnderline		endp
endif



CommonFunctional	ends



Build	segment resource


SetupDelayedModeFar	proc	far
	call	SetupDelayedMode
	ret
SetupDelayedModeFar	endp

CreateCompositeFar	proc	far
	call	CreateComposite
	ret
CreateCompositeFar	endp

SetDefaultBGColorFar	proc	far
	call	SetDefaultBGColor
	ret
SetDefaultBGColorFar	endp

Build 	ends


SpinGadgetCommon	segment resource

SetValueTextFiltersFar	proc	far
	call	SetValueTextFilters
	ret
SetValueTextFiltersFar	endp

SpinGadgetCommon	ends


CommonFunctional	segment resource





COMMENT @----------------------------------------------------------------------

METHOD:		ValueTextSetItem -- 

DESCRIPTION:	Sets a new item to be drawn.  If we're a text spin gadget, 
		stores a new text chunk.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_SET_ITEM

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/20/95		Initial version

------------------------------------------------------------------------------@

ValueTextSetItem	proc	near

	call	CF_DerefVisSpecDI
	mov	bp, ds:[di].VTI_text		;set new text chunk.

	ChunkSizeHandle	ds, bp, dx		;dx <- text length.
DBCS <	shr	dx, 1							>
	dec	dx
	mov	cx, dx				;assume we're selecting end

if SELECT_ENTIRE_SPIN_GADGET_TEXT_ON_GAINED_FOCUS
	clr	cx				;select entire range
endif

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	CF_ObjCallInstanceNoLock

redrawOnly:
	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock	
	ret

ValueTextSetItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLValueTextKbdChar -- 
		MSG_META_KBD_CHAR for OLValueClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handles keyboard chars.

PASS:		*ds:si 	- instance data
		es     	- segment of OLValueClass
		ax 	- MSG_META_KBD_CHAR

		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

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
	chris	7/19/95         	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLValueTextKbdChar	method dynamic	OLValueClass, \
				MSG_META_KBD_CHAR
	.enter
	;
	; Left out of here (for non-Rudy only, please!) is code to do 
	; increment and decrement.  Scarf it from OLValueKbdChar, 
	; although actually that only handles page up and down, but 
	; increment is very easy to add.
	;
	mov	di, segment OLTextClass
	mov	es, di
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock
	.leave
	ret
OLValueTextKbdChar	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLValueTextDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invoked when the text object changes size.

CALLED BY:	via MSG_VIS_TEXT_HEIGHT_NOTIFY.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_VIS_TEXT_HEIGHT_NOTIFY.
		dx	= new height.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89	Initial version
	cbh	5/15/91		Fixed for new bounds convention

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
OLValueTextDoNothing method dynamic OLValueClass, MSG_VIS_TEXT_HEIGHT_NOTIFY, \
					MSG_META_TEXT_EMPTY_STATUS_CHANGED, \
					MSG_VIS_TEXT_SHOW_SELECTION, \
					MSG_VIS_TEXT_UPDATE_GENERIC

	;
	; Do nothing.
	;
	ret		
	
OLValueTextDoNothing	endm

CommonFunctional	ends

Unbuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueUnbuild -- 
		MSG_SPEC_UNBUILD for OLValueClass

DESCRIPTION:	Handles unbuilding.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UNBUILD_BRANCH
		bp 	- SpecBuildFlags

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
	chris	4/21/93         Initial Version

------------------------------------------------------------------------------@

OLValueUnbuild	method dynamic	OLValueClass, \
				MSG_SPEC_UNBUILD

	;
	; Before nuking all references to the text, save it if dirty
	;
	call	SetValueIfUserDirtiedFar

	;
	; Nuke the spin gadget item.  This used to happen via the queue on
	; a MSG_SPIN_UNBUILD, but that code's been thrown out.  -4/21/93 cbh
	;
	clr	ax
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	xchg	ax, ds:[di].VTI_text		;get current item, and clear it
	tst	ax
	jz	10$				;no was no item, branch
	call	LMemFree
10$:

 	mov	bx, ds:[si]			;point to instance
 	add	bx, ds:[bx].Vis_offset		;ds:[bx] -- SpecInstance

 	test	ds:[bx].OLTDI_specState, mask TDSS_IN_COMPOSITE
	jz	20$				;not in view or composite...
	mov	di, ds:[bx].OLTDI_viewObj	;else *ds:si <- parent
	clr	bx				;pass view flag in bl
	mov	ax, -1				;yes! destroy moniker here
	call	OpenUnbuildCreatedParent	; unbuild parent, then remove
20$:						;  ourselves
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLTDI_specState, not (mask TDSS_IN_VIEW or \
					      mask TDSS_IN_COMPOSITE)
	clr	ds:[di].OLTDI_viewObj
	ret

OLValueUnbuild	endm


Unbuild	ends
