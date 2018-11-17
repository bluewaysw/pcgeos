COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/COpen (common code for specific UIs)
FILE:		copenValue.asm

METHODS:
 Name			Description
 ----			-----------

ROUTINES:
 Name			Description
 ----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial revision

DESCRIPTION:

	$Id: copenValue.asm,v 1.1 97/04/07 10:54:09 newdeal Exp $


-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLValueClass mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends




Geometry segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLValueSpecVisOpenNotify -- MSG_SPEC_VIS_OPEN_NOTIFY
							for OLValueClass

DESCRIPTION:	Handle notification that an object with GA_NOTIFY_VISIBILITY
		has been opened

PASS:
	*ds:si - instance data
	es - segment of OLValueClass

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
OLValueSpecVisOpenNotify	method dynamic	OLValueClass,
						MSG_SPEC_VIS_OPEN_NOTIFY
	call	VisOpenNotifyCommon
	ret

OLValueSpecVisOpenNotify	endm

;---

OLValueSpecVisCloseNotify	method dynamic	OLValueClass,
						MSG_SPEC_VIS_CLOSE_NOTIFY
	call	VisCloseNotifyCommon
	ret

OLValueSpecVisCloseNotify	endm

Geometry ends

			
CommonFunctional	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckIfOLCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures object is an OLCtrl object.

CALLED BY:	EC utility

PASS:		*ds:si -- GenValue

RETURN:		nothing		

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/95       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not GEN_VALUES_ARE_TEXT_ONLY
if ERROR_CHECK

ECCheckIfOLCtrl	proc	far		uses	es, di
	.enter
	pushf
	mov	di, segment OLCtrlClass
	mov	es, di
	mov	di, offset OLCtrlClass
	call	ObjIsObjectInClass
	ERROR_NC	OL_INTERNAL_ERROR_CANT_ACCESS_OL_CTRL_INSTANCE
	popf
	.leave
	ret
ECCheckIfOLCtrl	endp

endif
endif
	

COMMENT @----------------------------------------------------------------------

METHOD:		OLValueSpecBuild -- 
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

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueSpecBuild	method OLValueClass, MSG_SPEC_BUILD
	push	bp, es, ax
	tst	ds:[di].OLVLI_item		;an item already exists?
	jnz	setInitialValue			;yes, don't create one
	
SBCS <	mov	cx, GEN_VALUE_MAX_TEXT_LEN	;the longest string we'll have>
DBCS <	mov	cx, GEN_VALUE_MAX_TEXT_LEN*2	;the longest string we'll have>
	call	AllocValueText		;allocate a text moniker
	call	CF_DerefVisSpecDI
	mov	ds:[di].OLVLI_item, cx		;store handle of moniker
	
	call	CalculateMaxTextSize		;calculate a size, in dx
	call	CF_DerefVisSpecDI
	mov	ds:[di].OLSGI_desWidth, dx	;set the desired width	
	mov	ds:[di].OLSGI_textWidth, dx	;set the text width	
	mov	ds:[di].OLVLI_maxLength, cx	;save max ascii length
	
setInitialValue:
	;
	; Set current value in the moniker.
	;
	call	CreateValueText		;create text for it

	;
	; Handle GenValue-related hints, which sets a lot of OLSpinGadgetAttrs.
	;	
	call	CF_DerefVisSpecDI

	or	ds:[di].OLSGI_attrs, mask OLSGA_TEXT

	;
	; Rudy doesn't draw a frame by default.
	;
	or	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME

if SPINNER_GEN_VALUE
	;
	; assume spinner, analog hint handler will clear this
	;
	ornf	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER or mask OLSGA_SPINNER
endif

	clr	cx				; use default widths
	clr	dx
	segmov	es, cs				; setup es:di to be ptr to
						; Hint handler table
	mov	di, offset cs:PreValueHintHandler
	mov	ax, length (cs:PreValueHintHandler)
	call	OpenScanVarData

	mov	ax, HINT_VALUE_ORIENT_VERTICALLY
	call	ObjVarFindData
	jnc	5$
	call	ValueOrientVertically		;must handle here...
5$:
	call	CF_DerefVisSpecDI
	tst	cx
	jz	6$
	mov	ds:[di].OLSGI_desWidth, cx
6$:
	tst	dx
	jz	7$
	mov	ds:[di].OLSGI_desHeight, dx
7$:

if SPINNER_GEN_VALUE
	;
	; make sure we can get focus if we're a spinner
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SPINNER
	jz	notSpinner
	andnf	ds:[di].OLSGI_attrs, not mask OLSGA_CANT_EDIT_TEXT
notSpinner:
endif

	pop	bp, es, ax
	mov	di, offset OLValueClass		;call superclass to handle
	call	ObjCallSuperNoLock		;  hints, etc.
	
	call	CF_DerefVisSpecDI
	mov	bp, ds:[di].OLVLI_item		;pass item
	mov	ax, MSG_SPEC_SPIN_SET_ITEM		;set the initial item
	call	CF_ObjCallInstanceNoLock

	segmov	es, cs				; setup es:di to be ptr to
						; Hint handler table
	mov	di, offset cs:ValueHintHandler
	mov	ax, length (cs:ValueHintHandler)
	call	ObjVarScanData			

	;
	; If a slider, enforce certain child orientations.  We don't have
	; time to support everything.  If we're a horizontal slider, orient
	; children vertically, and vice versa.   -cbh 4/ 9/93
	;
	clr	cl
	mov	ch, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	9$
	test	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY
	jnz	9$					
	or	cl, ch				;we'll orient children
						;  vertical flag
9$:
	not	ch
	and	ds:[di].VCI_geoAttrs, ch	;clear vertical flag
	or	ds:[di].VCI_geoAttrs, cl	;set orientation

	;
	; Definitely set to not edit text if read only.
	;
	call	CF_DerefGenDI
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	10$
	call	ValueNotDigitallyEditable
10$:
	mov	ax, HINT_VALUE_FRAME
	call	ObjVarFindData
	jnc	20$
	call	CF_DerefVisSpecDI
	or	ds:[di].OLSGI_states, mask OLSGS_DRAW_FRAME
	ret
20$:

	call	SetupScrollbarMinMax		; setup min and max in bar
	call	SendValueToScrollbar		; init value

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
OLValueSpecBuild	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY


if not GEN_VALUES_ARE_TEXT_ONLY

PreValueHintHandler	VarDataHandler \
 	<ATTR_GEN_VALUE_RUNS_ITEM_GROUP, offset ValueRunsItemGroup>,
	<HINT_VALUE_CUSTOM_RETURN_PRESS, offset ValueCustomReturnPress>,
	<HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS, \
			offset ValueNavigateOnReturnPress>,
 	<HINT_VALUE_NOT_INCREMENTABLE, offset ValueNotIncrementable>,
	<HINT_VALUE_SHOW_MIN_AND_MAX, offset ValueShowMinAndMax>,
	<HINT_VALUE_ANALOG_DISPLAY, offset ValueAnalogDisplay>,
	<HINT_VALUE_NOT_DIGITALLY_EDITABLE, offset ValueNotDigitallyEditable>,
 	<ATTR_GEN_PROPERTY, offset ValueProperty>, 
	<ATTR_GEN_NOT_PROPERTY, offset ValueNotProperty>,
	<HINT_VALUE_ORIENT_HORIZONTALLY, offset ValueOrientHorizontally>

ValueHintHandler	VarDataHandler \
	<HINT_VALUE_DISPLAY_INTERVALS, ValueDisplayIntervals>

endif	;not GEN_VALUES_ARE_TEXT_ONLY


if not GEN_VALUES_ARE_TEXT_ONLY

ValueNotDigitallyEditable	proc	far
	call	CF_DerefVisSpecDI
	or	ds:[di].OLSGI_attrs, mask OLSGA_CANT_EDIT_TEXT
if (not (SLIDER_INCLUDES_VALUES and DRAW_STYLES))
;
; don't turn off frame
;
	and	ds:[di].OLSGI_states, not (mask OLSGS_DRAW_FRAME)
endif
	ret
ValueNotDigitallyEditable	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY


if not GEN_VALUES_ARE_TEXT_ONLY

ValueNotIncrementable	proc	far
	call	CF_DerefVisSpecDI
	or	ds:[di].OLSGI_attrs, mask OLSGA_NO_UP_DOWN_ARROWS
	ret
ValueNotIncrementable	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY


if not GEN_VALUES_ARE_TEXT_ONLY

ValueOrientVertically	proc	near
	;
	; Must follow pre-hints, must precede superclass hints!
	;
	call	CF_DerefVisSpecDI
	or	ds:[di].OLSGI_attrs, mask OLSGA_ORIENT_VERTICALLY

	;
	; Set a default height if we're a slider.
	; VERTICALLY is NOT present.   Use old default width.
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	exit
if SPINNER_GEN_VALUE
	;
	; don't set default height for spinner, let OLSpinGadgetSpecBuild
	; set default to one text line height
	;
	test	ds:[di].OLSGI_attrs, mask OLSGA_SPINNER
	jnz	clrWidth
endif
	mov	dx, OL_SLIDER_DEFAULT_HEIGHT
clrWidth::
	clr	cx
exit:
	ret
ValueOrientVertically	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY


if not GEN_VALUES_ARE_TEXT_ONLY

ValueOrientHorizontally	proc	far
	call	CF_DerefVisSpecDI
	andnf	ds:[di].OLSGI_attrs, not mask OLSGA_ORIENT_VERTICALLY
	ret
ValueOrientHorizontally	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY


if not GEN_VALUES_ARE_TEXT_ONLY

ValueShowMinAndMax	proc	far
	call	CF_DerefVisSpecDI
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER	; only for slider
	jz	exit
	or	ds:[di].OLSGI_attrs, mask OLSGA_SHOW_MIN_MAX_MKRS
exit:
	ret
ValueShowMinAndMax	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY



if not GEN_VALUES_ARE_TEXT_ONLY

ValueAnalogDisplay	proc	far
	call	CF_DerefVisSpecDI
	or	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
if (not (SLIDER_INCLUDES_VALUES and DRAW_STYLES))
;
; don't turn off frame
;
	and	ds:[di].OLSGI_states, not (mask OLSGS_DRAW_FRAME)
endif

if SPINNER_GEN_VALUE
	;
	; slider, clear spinner
	;
	andnf	ds:[di].OLSGI_attrs, not mask OLSGA_SPINNER
endif

	;
	; Assuming horizontal, pick a default width.
	;
	mov	cx, OL_SLIDER_DEFAULT_WIDTH
	ret
ValueAnalogDisplay	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY



if not GEN_VALUES_ARE_TEXT_ONLY

ValueRunsItemGroup	proc	far
	push	cx, dx
	mov	ax, MSG_SPEC_VALUE_SET_FROM_ITEM_GROUP
	call	SetItemGroupDestAndStatusMsg
	pop	cx, dx
	ret
ValueRunsItemGroup	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY


ValueCustomReturnPress	proc	far
	call	CF_DerefVisSpecDI
	or	ds:[di].OLVLI_flags, mask OLVF_CUSTOM_RETURN_PRESS	
	ret
ValueCustomReturnPress	endp


ValueNavigateOnReturnPress	proc	far
	call	CF_DerefVisSpecDI
	or	ds:[di].OLVLI_flags, mask OLVF_NAVIGATE_ON_RETURN_PRESS	
	ret
ValueNavigateOnReturnPress	endp



if not GEN_VALUES_ARE_TEXT_ONLY

ValueDisplayIntervals	proc	far
	call	CF_DerefVisSpecDI
	mov	si, ds:[di].OLSGI_scrollbar
	jz	exit				;no scrollbar, later for this.

	push	cx, dx
	or	ds:[di].OLSGI_attrs, mask OLSGA_SHOW_HASH_MARKS
	mov	cx, ds:[bx].GVI_numMajorIntervals
	mov	dx, ds:[bx].GVI_numMinorIntervals
	mov	ax, MSG_SPEC_SLIDER_SET_NUM_INTERVALS	
	call	ObjCallInstanceNoLock
	pop	cx, dx
exit:
	ret
ValueDisplayIntervals	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY


if not GEN_VALUES_ARE_TEXT_ONLY

ValueProperty	proc	far
EC <	call	ECCheckIfOLCtrl					>
	call	CF_DerefVisSpecDI
	or	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
	ret
ValueProperty	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY



if not GEN_VALUES_ARE_TEXT_ONLY

ValueNotProperty	proc	far
EC <	call	ECCheckIfOLCtrl					>
	call	CF_DerefVisSpecDI
	and	ds:[di].OLCI_buildFlags, not mask OLBF_DELAYED_MODE
	ret
ValueNotProperty	endp

endif		;not GEN_VALUES_ARE_TEXT_ONLY



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupScrollbarMinMax

SYNOPSIS:	Sets up scrollbar min and max.

CALLED BY:	OLValueSpecBuild

PASS:		*ds:si -- GenValue object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/11/92		Initial version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

SetupScrollbarMinMax	proc	near		uses	si
	.enter
	;
	; We'll set up 1.0 as the max so we can communicate with the
	; slider via ratios.  (Minimum should already be zero.)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLSGI_scrollbar
	tst	si	
	jz	exit
	mov	dx, 1
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
SetupScrollbarMinMax	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY


COMMENT @----------------------------------------------------------------------

ROUTINE:	CalculateMaxTextSize

SYNOPSIS:	Calculates a size for the gadget, based on min and max values.

CALLED BY:	OLValueSpecBuild, OLValueSetMinimum, OLValueSetMaximum

PASS:		*ds:si -- handle of gadget

RETURN:		dx -- gadget width to use
		cx -- text maxLength to use

DESTROYED:	ax,bx,cx,di,es

PSEUDO CODE/STRATEGY:
       		takes the greater of the strings sizes of the minimum and max

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/22/89	Initial version

------------------------------------------------------------------------------@

CalculateMaxTextSize	proc	near
	class	OLValueClass

EC <	call	ECCheckLMemObject					>
	
	call	ViewCreateCalcGState		;get gstate in bp
	push	ds, si				;save object handle

SBCS<	sub	sp, GEN_VALUE_MAX_TEXT_LEN				>
DBCS<	sub	sp, GEN_VALUE_MAX_TEXT_LEN * size wchar			>
	mov	dx, sp				;dx points to buffer
	segmov	cx, ss				;cx:dx now

	push	bp
	mov	bp, GVT_LONG			;get the longest text available
	mov	ax, MSG_GEN_VALUE_GET_VALUE_TEXT
	call	CF_ObjCallInstanceNoLock	;text returned in cx:dx
	pop	bp

	segmov	ds, ss, si
	mov	es, si				;have es:di point to text
	mov	di, dx
	mov	si, dx				;also ds:si.

if DBCS_PCGEOS
	call	LocalStringLength		;cx <- length w/o NULL
else
	mov	cx, -1				;get the length of the string
	clr	al
	repne	scasb
	not	cx				;cx holds the length, plus null
	dec	cx				;keep non-null text length
endif
	mov	bx, cx				;keep in bx

SBCS <	mov	cx, -1				;look for null termination>
	mov	di, bp				;pass gstate
	call	GrTextWidth			;get width in dx
	mov	di, bp				;unload gstate
	call	GrDestroyState
SBCS<	add	sp, GEN_VALUE_MAX_TEXT_LEN				>
DBCS<	add	sp, GEN_VALUE_MAX_TEXT_LEN * size wchar			>
	pop	ds, si

	mov	cx, bx				;restore max length

	;
	; Call superclass to get the length of the text.  Something else
	; may ultimately be used here if the message is subclassed; otherwise,
	; we'll just use what we calculated.
	;
	push	dx
	mov	ax, MSG_GEN_VALUE_GET_MAX_TEXT_LEN
	call	ObjCallInstanceNoLock
	pop	dx

	;
	; Apply size hints if available, for width only. -cbh 11/13/92
	;
	push	cx
	call	CF_DerefVisSpecDI
	mov	cx, dx
	CallMod	VisApplySizeHints		;adjusts cx (we'll ignore dx)
	mov	dx, cx
	pop	cx
	ret
CalculateMaxTextSize	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLValueGetMaxTextLen -- 
		MSG_GEN_VALUE_GET_MAX_TEXT_LEN for OLValueClass

DESCRIPTION:	Returns maximum text length.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_MAX_TEXT_LEN
		(cx)	- (suggested text length -- not documented)

RETURN:		ax 	- text length to use
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/22/92		Initial Version

------------------------------------------------------------------------------@

OLValueGetMaxTextLen	method dynamic	OLValueClass, \
				MSG_GEN_VALUE_GET_MAX_TEXT_LEN
	mov	ax, cx			;return suggestion
	ret
OLValueGetMaxTextLen	endm


CommonFunctional ends

;---------------------

SpinGadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueSpinIncrement -- 
		MSG_SPEC_SPIN_INCREMENT for OLValueClass

DESCRIPTION:	Handles a press on the spin gadget up arrow.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_INCREMENT

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/19/89	Initial version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueSpinIncrement	method OLValueClass, MSG_SPEC_SPIN_INCREMENT
	mov	ax, MSG_GEN_VALUE_INCREMENT
	clr	bx				;not a scrollbar
	call	SendMsgSetModifiedAndApplyIfNeeded
	ret
	
OLValueSpinIncrement	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueDecrement -- 
		MSG_SPEC_SPIN_DECREMENT for OLValueClass

DESCRIPTION:	Decrements the value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_DECREMENT

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/19/89	Initial version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueDecrement	method OLValueClass, MSG_SPEC_SPIN_DECREMENT
	mov	ax, MSG_GEN_VALUE_DECREMENT
	clr	bx				;not a scrollbar
	call	SendMsgSetModifiedAndApplyIfNeeded
	ret

OLValueDecrement	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY

SpinGadgetCommon ends

;--------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	SendMsgSetModifiedAndApplyIfNeeded

SYNOPSIS:	Handles a user change.

CALLED BY:	OLValueSpinIncrement
		OLValueSpinDecrement
		OLValueKbdChar
		SetValueIfUserDirtied
		various scrollbar routines

PASS:		*ds:si -- GenValue
		ax -- message to send (message must return carry if it causes
			a change in the GenValue's value.)
		bx -- non-zero if scrollbar calling, which causes applies and
			status messages to always be sent.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 1/92		Initial version

------------------------------------------------------------------------------@

SendMsgSetModifiedAndApplyIfNeeded	proc	far
	;
	; Send message to self.  The message should be something that affects
	; the GVLI_value.  The carry will be set if anything changed.  We want
	; to preserve GVSF_MODIFIED across this call, and only set the modified
	; state later under certain circumstances (we never want to clear the
	; state).
	;
	push	bx
	call	CF_DerefGenDI
	mov	bl, ds:[di].GVLI_stateFlags
	and	bl, mask GVSF_MODIFIED		;save this flag
	call	CF_ObjCallInstanceNoLock	;send message (carry returned)
	pushf
	call	CF_DerefGenDI
	and	ds:[di].GVLI_stateFlags, not mask GVSF_MODIFIED
	or	ds:[di].GVLI_stateFlags, bl	;restore flag
	popf
	pop	bx
	jc	doit				;something changed, branch

	tst	bx				;handling scrollbars, branch
	jnz	doit
	push	bx
	mov	ax, ATTR_GEN_VALUE_SET_MODIFIED_ON_REDUNDANT_SELECTION
	call	ObjVarFindData
	pop	bx
	jnc	exit				;attribute not present, exit
doit:
	;
	; Scrollbars always apply -- they never bother with modified state (and
	; setting dialogs applyable) or sending status messages.  -cbh 12/26/92
	; (Modified state forced on so apply message will be sent.)
	;
	tst	bx				
	jz	10$				;scrollbars always apply
	call	CF_DerefGenDI
	or	ds:[di].GVLI_stateFlags, mask GVSF_MODIFIED
	jmp	short doApply
	
10$:
	mov	cx, -1				;mark modified
	mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
	call	CF_ObjCallInstanceNoLock

	mov	cx, -1
	mov	ax, MSG_GEN_VALUE_SEND_STATUS_MSG
	call	CF_ObjCallInstanceNoLock

	;
	; If we're in delayed mode, send an apply and mark the dialog as
	; applyable.  There shouldn't be a reason to mark a non-delayed dialog
	; as applyable, so I've changed the code.
	;
	call	CF_DerefVisSpecDI

if GEN_VALUES_ARE_TEXT_ONLY
	test	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
else
	test	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
endif
	jnz	exit				;in delayed mode, branch

doApply:
	mov	ax, MSG_GEN_APPLY		;else send an apply to ourselves
	tst	bx				;scrollbars are immediate
	jz	sendForceQueue
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	jmp	short sendIt

sendForceQueue:
	;
	; Changed to not use a call here, to match what the GenTrigger does.
	; It appears that when an item group runs something in the UI queue
	; the action takes place before we return here, causing annoying
	; delays in updating the item group and its menu, and causing bugs
	; when the action disables its popup list if it has one. -2/ 6/93 cbh
	;
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or \
		    mask MF_FIXUP_DS
sendIt:
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage
exit:
	ret
SendMsgSetModifiedAndApplyIfNeeded	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLValueIncrement -- 
		MSG_GEN_VALUE_INCREMENT for OLValueClass

DESCRIPTION:	Specific UI handling of increment, decrement.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_INCREMENT

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
	chris	6/ 1/92		Initial Version

------------------------------------------------------------------------------@

OLValueIncrement	method dynamic	OLValueClass, MSG_GEN_VALUE_INCREMENT,
						      MSG_GEN_VALUE_DECREMENT,
						      MSG_GEN_VALUE_GET_VALUE

	call	SetValueIfUserDirtied		;if user typed a new value, 
						;  get it now.
	ret
OLValueIncrement	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLValueSetValue -- 
		MSG_GEN_VALUE_SET_VALUE for OLValueClass

DESCRIPTION:	Sets a new value for the thing.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_VALUE 
		cx 	- new value (ignored here)

RETURN:		nothing

DESTROYED:	bx, di, ds, es, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/21/89	Initial version

------------------------------------------------------------------------------@

OLValueSetValue	method OLValueClass, MSG_GEN_VALUE_SET_VALUE
	call	CreateValueText		 	;set new text in text object

if GEN_VALUES_ARE_TEXT_ONLY
	call	ValueTextSetItem
else
	tst	ah				;check to see changed
	jz	exit				;text didn't change, branch

	call	ValueUpdateItemGroupIfNeeded	;send to item group
	jc	exit				;we are doing this kind of stuff
						;  wait to update until thing
						;  answers back.
	call	SendValueToScrollbar		;send on to scrollbar 

	call	CF_DerefVisSpecDI
	mov	bp, ds:[di].OLVLI_item		;item in bp
	mov	ax, MSG_SPEC_SPIN_SET_ITEM		;redraws the gadget
	call	CF_ObjCallInstanceNoLock
exit:
endif	;not GEN_VALUES_ARE_TEXT_ONLY

	ret
OLValueSetValue	endm
	


COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateValueText

SYNOPSIS:	Creates an ascii string for our value and stuffs in moniker.
		Also sets the text as clean so we'll be notified on a 
		keypress.
		
CALLED BY:	OLValueSetValue, OLValueSpecBuild

PASS:		*ds:si 	- handle of value gadget

RETURN:		ds	- updated appropriately
		ah	- non-zero if text changed
	SBCS:
		cx	- length of non-null string

DESTROYED:	al,bx,dx,es,di,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/21/89	Initial version

------------------------------------------------------------------------------@

CreateValueText	proc	near
	class	OLValueClass
	
	push	ds:[LMBH_handle], si		;save our object's optr
SBCS <	sub	sp, GEN_VALUE_MAX_TEXT_LEN	;make room on stack	>
DBCS <	sub	sp, GEN_VALUE_MAX_TEXT_LEN*2	;make room on stack	>
	mov	di, sp				;di points to buffer
	segmov	es, ss				;es:di now
	;
	; If value passed is indeterminate, just store a null string.
	;
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GVLI_stateFlags, mask GVSF_INDETERMINATE
	jz	convert				;not indeterminate, convert
SBCS <	mov	{byte} es:[di], 0		;else store a null	>
DBCS <	mov	{wchar} es:[di], 0		;else store a null	>
SBCS <	mov	cx, 1				;cx holds length including null>
DBCS <	mov	cx, 2				;cx holds size including null>
	jmp	short common			;and con
	
convert:
	mov	cx, ss
	mov	dx, di				;buffer in cx:dx now
	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_GET_VALUE_TEXT
	call	CF_ObjCallInstanceNoLock		;fills in item text
							;  to ascii in es:di
if DBCS_PCGEOS
	call	LocalStringSize			;cx <- size w/o NULL
	LocalNextChar escx			;cx <- size w/ NULL
else
	push	di
	mov	cx, -1				;get the length of the string
	clr	al
	repne	scasb
	not	cx				;cx holds the length, plus null
	pop	di
endif

common:
SBCS <	push	cx				;save length, we'll return it>
	mov	si, ds:[si]			;point to instance
	add	si, ds:[si].Vis_offset		;ds:[di] -- SpecInstance
if GEN_VALUES_ARE_TEXT_ONLY
	mov	si, ds:[si].VTI_text
else
	mov	si, ds:[si].OLVLI_item		;get handle of moniker
endif	;not GEN_VALUES_ARE_TEXT_ONLY
	tst	si
	jz	doneWithText			;nowhere to store text, branch

EC <	tst	si							>
EC <	ERROR_Z	OL_ERROR						>
	
	ChunkSizeHandle	ds, si, ax		;get chunk size
DBCS <	clr	dl				;assume no size change	>
	cmp	cx, ax				;did size change?
SBCS <	mov	ax, 0				;assume not, set ah = 0	>
	je	sizeSet				;no change, branch
	mov	ax, si
	call	LMemReAlloc			;resize our chunk, if necessary
SBCS <	mov	ah, -1				;mark text as changed	>
DBCS <	mov	dl, -1				;mark text as changed	>

sizeSet:
	mov	si, ds:[si]			;deref it
	segxchg	ds, es				;xchg ds and es
	xchg	si, di				;ds:si source, es:di dest now
	
copy:
	LocalGetChar ax, dssi			;get a char
SBCS <	cmp	al, {byte} es:[di]		;is the char changing?	>
DBCS <	cmp	ax, {wchar} es:[di]		;is the char changing?	>
	je	10$				;nope, branch
SBCS <	mov	ah, -1				;else mark as dirty	>
DBCS <	mov	dl, -1							>
10$:
	LocalPutChar esdi, ax			;store it
	LocalIsNull ax				;see if null found
	jnz	copy				;no, branch

doneWithText:		
SBCS <	pop	cx				;restore string length	>
SBCS <	dec	cx				;don't include null in length >
SBCS <	add	sp, GEN_VALUE_MAX_TEXT_LEN	;unload buffer		>
DBCS <	add	sp, GEN_VALUE_MAX_TEXT_LEN*2	;unload buffer		>

	pop	bx, si				;restore object's optr
	call	MemDerefDS			;dereference object
DBCS <	mov	ah, dl				;ah <- dirty flag	>
	push	ax
	call	SetValueTextNotUserModified	;clear text's dirty bit
	pop	ax				;return ah <- dirty flag
exit:
	ret
CreateValueText	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetValueTextNotUserModified

SYNOPSIS:	Sets the value's text object clean.

CALLED BY:	CreateValueText, OLValueApply

PASS:		*ds:si -- value handle

RETURN:		nothing

DESTROYED:	cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/19/90		Initial version

------------------------------------------------------------------------------@


SetValueTextNotUserModified	proc	near

if not GEN_VALUES_ARE_TEXT_ONLY
	push	si
	call	CF_DerefVisSpecDI
	mov	si, ds:[di].OLSGI_text			;get text handle
	tst	si
	jz	done
endif

	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED	;set the text clean
	call	CF_ObjCallInstanceNoLock
done:

if not GEN_VALUES_ARE_TEXT_ONLY
	pop	si
endif

	ret
SetValueTextNotUserModified	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	IsTextUserModified

SYNOPSIS:	Returns whether text is dirtied.

CALLED BY:	SetValueIfUserDirtied

PASS:		*ds:si -- GenValue object

RETURN:		cx non-zero if text dirty

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 1/92		Initial version

------------------------------------------------------------------------------@


IsTextUserModified	proc	near		

if not GEN_VALUES_ARE_TEXT_ONLY
	push	si
	call	CF_DerefVisSpecDI
	mov	si, ds:[di].OLSGI_text			;get text handle
	clr	cx					;assume no text
	tst	si					;nope, return clean
	jz	exit
endif
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	call	CF_ObjCallInstanceNoLock
exit:

if not GEN_VALUES_ARE_TEXT_ONLY
	pop	si
endif
	ret
IsTextUserModified	endp


CommonFunctional ends

;----------------------

SpinGadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueTextUserModified -- 
		MSG_META_TEXT_USER_MODIFIED for OLValueClass

DESCRIPTION:	Let's us know when text has been typed in.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_TEXT_USER_MODIFIED
		^lcx:dx - text handle

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/14/90		Initial version

------------------------------------------------------------------------------@

OLValueTextUserModified	method OLValueClass, MSG_META_TEXT_USER_MODIFIED

;EC <	call	ECCheckIfOLCtrl					>
;       Nuked, MSG_GEN_MAKE_APPLYABLE sent out by generic object. 2/ 3/93
;	test	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
;	jz	exit				  ;not delayed, exit
;	mov	ax, MSG_OL_VUP_MAKE_APPLYABLE  ;make parent notice applyable
;	call	CF_ObjCallInstanceNoLock

	;	
	; Mark the object modified and send a status message, so the app is
	; aware that the GenValue is now in a modified state.  We'll send the
	; pre-type value however, since the new value is intermediate and 
	; possibly illegal at this point.  Also, we'll set the thing out of
	; date so status handlers won't go off using the value passed.
	;
	mov	ax, MSG_GEN_VALUE_SET_OUT_OF_DATE
	call	SGC_ObjCallInstanceNoLock

	mov	cx, -1				;mark modified
	mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
	call	SGC_ObjCallInstanceNoLock

	mov	cx, -1
	mov	ax, MSG_GEN_VALUE_SEND_STATUS_MSG
	call	SGC_ObjCallInstanceNoLock
exit:
	ret
OLValueTextUserModified	endm


SpinGadgetCommon ends

CommonFunctional segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLValueGenMakeApplyable -- 
		MSG_GEN_MAKE_APPLYABLE for OLValueClass

DESCRIPTION:	Makes the dialog box applyable if needed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_MAKE_APPLYABLE

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
	chris	2/ 1/93         	Initial Version

------------------------------------------------------------------------------@

OLValueGenMakeApplyable	method dynamic	OLValueClass, \
				MSG_GEN_MAKE_APPLYABLE

	;
	; Not a property, do not make dialog boxes applyable!  -cbh 2/ 1/93
	;

if GEN_VALUES_ARE_TEXT_ONLY
	test	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
else
EC <	call	ECCheckIfOLCtrl					>
	test	ds:[di].OLCI_buildFlags, mask OLBF_DELAYED_MODE
endif
	jz	exit				  ;not delayed, exit
	call	VisCallParentEnsureStack
exit:
	ret
OLValueGenMakeApplyable	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLValueSetMinimum -- 
		MSG_GEN_VALUE_SET_MINIMUM for OLValueClass

DESCRIPTION:	Sets a new minimum for the value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_MINIMUM
		bp 	- Flags affecting processing (GadgetChangeFlags)
			     GCF_SUPPRESS_APPLY - don't send out AD (it's 
						  just a cosmetic change)
			     GCF_SUPPRESS_DRAW - don't want to redraw value
		
		cx	- new minimum

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		Doesn't error check for maximum < minimum.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/21/89	Initial version

------------------------------------------------------------------------------@


OLValueSetMinimum	method OLValueClass, MSG_GEN_VALUE_SET_MINIMUM,
					     MSG_GEN_VALUE_SET_MAXIMUM
if not GEN_VALUES_ARE_TEXT_ONLY
	call	SendValueToScrollbar		;send stuff to scrollbar
endif
	call	SetValueIfUserDirtied		;keep current value up-to-date

	;
	; Set a new text maxLength, if necessary...
	;
	call	CalculateMaxTextSize		;get a size for the gadget

if not GEN_VALUES_ARE_TEXT_ONLY
	call	CF_DerefVisSpecDI
	mov	ds:[di].OLVLI_maxLength, cx	;store the max string length
	push	si
	mov	si, ds:[di].OLSGI_text		;get handle of text object
	tst	si				;is there a text object?	
	jz	10$				;no, branch
endif
	call	CF_DerefVisSpecDI
	mov	ds:[di].VTI_maxLength, cx	;store the max length
10$::
	;
	; If the new minimum will not fit in the desired size we have 
	; already allocated, then we must resize the thing.
	;
if not GEN_VALUES_ARE_TEXT_ONLY
	pop	si
	call	CF_DerefVisSpecDI

	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	20$
	mov	ds:[di].OLSGI_textWidth, dx	;slider, adjust textwidth
20$:
	cmp	dx, ds:[di].OLSGI_desWidth	;see if desired size got bigger
	jbe	exit				;no, exit
	mov	ds:[di].OLSGI_desWidth, dx	;else set new desired width
	mov	cl, mask VOF_GEOMETRY_INVALID	;invalidate geometry
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	VisMarkInvalid			
endif

exit:
	ret
	
OLValueSetMinimum	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLValueGetItem -- 
		MSG_SPEC_SPIN_GET_ITEM for OLValueClass

DESCRIPTION:	Returns current item for use by the spin gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_GET_ITEM

RETURN:		bp -- current item

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/19/89	Initial version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueGetItem	method OLValueClass, MSG_SPEC_SPIN_GET_ITEM
	mov	bp, ds:[di].OLVLI_item		;get current item
	ret
OLValueGetItem	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a text moniker, or just a text chunk, for storing 
		text into.   The results depend on whether the thing is
		editable or not (whether we're using monikers or text in the
		spin gadget).

CALLED BY:	GLOBAL
PASS:		ds - object block
		cx - amount of space for text (includes null terminator)
RETURN:		cx - chunk handle of moniker
		
DESTROYED:	ax, cx, di, bp, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/30/89		Initial version
	cbh	12/89		Made useful by Chris

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocValueText	proc	near
	class	OLValueClass
	
	push	si
   	mov	di, cx				;Get size of string + null

if not GEN_VALUES_ARE_TEXT_ONLY
	jnz	10$				;if text, branch
	add	di, VM_data+VMT_text		;else add size of moniker header
10$:
endif

 	mov	al, mask OCF_IGNORE_DIRTY
	mov	cx,di				;# bytes to alloc   
	mov	di,bx				;Get ptr to string in di
	call	LMemAlloc			;Alloc the block
	mov	si,ax
	mov	bp,ax				;save ax
	
exit:
	mov	cx,bp				;Return chunk handle in cx
	pop	si				;restore registers
	ret
AllocValueText	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLValueApply -- 
		MSG_GEN_APPLY for OLValueClass

DESCRIPTION:	Applies the current user value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_APPLY

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/22/89	Initial version

------------------------------------------------------------------------------@

OLValueApply	method OLValueClass, MSG_GEN_APPLY
	call	SetValueIfUserDirtied		;make sure we're up to date
	call	SetValueTextNotUserModified	;a keypress will make applyable
	ret
	
OLValueApply	endm


CommonFunctional ends

;-----------------------

SpinGadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueStartSelect -- 
		MSG_META_START_SELECT for OLValueClass

DESCRIPTION:	Handles start of selection.  We'll use this to reset the
		temp increment to the real (generic) increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_START_SELECT
		cx, dx  - button position
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 4/90	Initial version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueStartSelect	method OLValueClass, MSG_META_START_SELECT
	mov	di, offset OLValueClass		;call superclass
	call	ObjCallSuperNoLock

	call	SetValueTextFilters			;make the text object filtered
	ret
OLValueStartSelect	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY



COMMENT @----------------------------------------------------------------------

METHOD:		OLValueGainedFocusExcl -- 
		MSG_META_GAINED_FOCUS_EXCL for OLValueClass

DESCRIPTION:	Sets the focus exclusive.  Calls superclass, then sets the
		text object created to filter non-numerics and have a maximum
		length.

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
	Chris	4/11/90		Initial version

------------------------------------------------------------------------------@

OLValueGainedFocusExcl	method OLValueClass, MSG_META_GAINED_FOCUS_EXCL
	mov	di, offset OLValueClass
	call	ObjCallSuperNoLock

if not GEN_VALUES_ARE_TEXT_ONLY
	call	SetValueTextFilters			;make it filter numerics
endif

	;
	; For certain default actions, we need to take the default exclusive,
	; so we'll get the activate when the user presses return.
	;
	call	SGC_DerefVisSpecDI
	test	ds:[di].OLVLI_flags, mask OLVF_CUSTOM_RETURN_PRESS or \
				     mask OLVF_NAVIGATE_ON_RETURN_PRESS
	jz	exit				;on neither of these do we 
						;  activate the default

	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_TAKE_DEFAULT_EXCLUSIVE
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	VisCallParent
exit:
	ret
OLValueGainedFocusExcl	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetValueTextFilters

SYNOPSIS:	Sets the spin gadget text object to filter non-numeric chars.
		Also sets the maximum length of the text.

CALLED BY:	OLValueStartSelect, OLValueGainedFocusExcl

PASS:		*ds:si -- handle

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/90		Initial version

------------------------------------------------------------------------------@

SetValueTextFilters	proc	near
	push	ax, cx

	mov	ax, MSG_GEN_VALUE_GET_TEXT_FILTER
	call	SGC_ObjCallInstanceNoLock	;returned in al

	call	SGC_DerefVisSpecDI
	mov	cx, ds:[di].OLVLI_maxLength	;get the maximum length

if not GEN_VALUES_ARE_TEXT_ONLY
	mov	di, ds:[di].OLSGI_text		;get to text object	

	tst	di				;is there a text object?
	jz	exit				;no, exit
	mov	di, ds:[di]			;point to text instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- text VisInstance
endif

	mov	ds:[di].VTI_maxLength, cx	;store a maximum length
	mov	ds:[di].VTI_filters, al

if _DUI
	;
	; if numeric, allow full-width digits
	;
	mov	ax, MSG_GEN_VALUE_GET_DISPLAY_FORMAT
	call	SGC_ObjCallInstanceNoLock	;al = display format
CheckHack <GVDF_INTEGER eq 0>
CheckHack <GVDF_DECIMAL eq 1>
	cmp	al, GVDF_DECIMAL
	ja	noFullWidthDigits
	push	si
if not GEN_VALUES_ARE_TEXT_ONLY
	call	SGC_DerefVisSpecDI
	mov	si, ds:[di].OLSGI_text		;*ds:si = text object
	tst	si
	jz	popNoFull
endif
	mov	ax, ATTR_VIS_TEXT_ALLOW_FULLWIDTH_DIGITS
	clr	cx
	call	ObjVarAddData
popNoFull:
	pop	si
noFullWidthDigits:
endif

exit:
	pop	ax, cx
	ret
SetValueTextFilters	endp


SpinGadgetCommon ends

;----------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueLostFocusExcl -- 
		MSG_META_LOST_FOCUS_EXCL for OLValueClass
		MSG_META_TEXT_LOST_FOCUS for OLValueClass

DESCRIPTION:	Error checks when the keyboard grab is lost.
		Gets the currently input value within value,
		redrawing and sending a method out if necessary.

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

OLValueLostFocusExcl	method OLValueClass, MSG_META_TEXT_LOST_FOCUS,
					     MSG_META_LOST_FOCUS_EXCL
	;
	; First, release the default exclusive if we have it.
	;
	push	ax
	call	CF_DerefVisSpecDI
	test	ds:[di].OLVLI_flags, mask OLVF_CUSTOM_RETURN_PRESS or \
				     mask OLVF_NAVIGATE_ON_RETURN_PRESS
	jz	doneReleasing			;on neither of these did we 
						;  activate the default, branch

	push	es
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_RELEASE_DEFAULT_EXCLUSIVE
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	VisCallParent
	pop	es
	
doneReleasing:
	;
	; Now call superclass.  The text object will be destoyed.
	;
	pop	ax
	mov	di, offset OLValueClass
	call	ObjCallSuperNoLock		
	;
	; Now update the user value.
	;
	call	SetValueIfUserDirtied
	ret
	
OLValueLostFocusExcl	endm

			

COMMENT @----------------------------------------------------------------------

METHOD:		OLValueCarriageReturn -- 
		MSG_META_TEXT_CR_FILTERED for OLValueClass

DESCRIPTION:	Handles carriage returns specially.  Sends something out to
		the action descriptor, to possibly signal the application that
		a default action has occurred.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_TEXT_CR_FILTERED

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/21/90		Initial version

------------------------------------------------------------------------------@

OLValueCarriageReturn	method OLValueClass, MSG_META_TEXT_CR_FILTERED
	mov	di, offset OLValueClass
	call	ObjCallSuperNoLock
	;
	; Make sure the user value is updated correctly.
	;
	call	SetValueIfUserDirtied
	ret
OLValueCarriageReturn	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	ValueUpdateItemGroupIfNeeded

SYNOPSIS:	Updates an item group if we're running one.

CALLED BY:	OLValueCarriageReturn

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/19/92		Initial version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

ValueUpdateItemGroupIfNeeded	proc	near		uses	si
	.enter
	mov	ax, ATTR_GEN_VALUE_RUNS_ITEM_GROUP
	call	ObjVarFindData
	jnc	exit				;do we do this?  No, branch.

	call	CF_DerefGenDI
	mov	cx, ds:[di].GVLI_value.high	;pass integer value
	tst	ds:[di].GVLI_value.low		;round properly
	jns	10$
	inc	cx
10$:
	mov	si, ds:[bx].chunk		;setup to talk to object
	mov	bx, ds:[bx].handle		;  listed in hint

	mov	bp, si				;say it's the value (bp != 0)
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MONIKER_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret
ValueUpdateItemGroupIfNeeded	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY

CommonFunctional ends

;--------------------

SpinGadgetCommon segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLValueSetFromItemGroup -- 
		MSG_SPEC_VALUE_SET_FROM_ITEM_GROUP for OLValueClass

DESCRIPTION:	Sets the text object from the moniker of the item passed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VALUE_SET_FROM_ITEM_GROUP
		cx	- identifier of item group

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
	chris	5/19/92		Initial Version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueSetFromItemGroup	method dynamic	OLValueClass, \
				MSG_SPEC_VALUE_SET_FROM_ITEM_GROUP

	mov	ax, ATTR_GEN_VALUE_RUNS_ITEM_GROUP
	call	ObjVarFindData
EC <	ERROR_NC	OL_ERROR		;Should have found data!  >

	clr	bp				;no indeterminateness
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	SGC_ObjCallInstanceNoLock

	;	
	; Send to scrollbar -- doesn't happen in OLValueSetValue.
	;
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	SendValueToScrollbar
	ret
OLValueSetFromItemGroup	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY

SpinGadgetCommon ends

;------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetValueIfUserDirtied

SYNOPSIS:	If an editable value, converts the current ascii text value.
		
CALLED BY:	many places

PASS:		*ds:si -- handle of value

RETURN:		carry set if anything useful found, else:
			cx -- user value (or INDETERMINATE_VALUE)

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 7/90		Initial version

------------------------------------------------------------------------------@

SetValueIfUserDirtiedFar	proc	far
	call	SetValueIfUserDirtied
	ret
SetValueIfUserDirtiedFar	endp

SetValueIfUserDirtied	proc	near
	class	OLValueClass

	call	VisCheckIfSpecBuilt
	jnc	exit				;not built, exit

	call	IsTextUserModified		;returns cx != 0 if dirty
	tst	cx
	jz	exit				;not dirty, exit (carry clear)

	call	CF_DerefGenDI
	mov	al, ds:[di].GVLI_displayFormat

	call	CF_DerefVisSpecDI

if GEN_VALUES_ARE_TEXT_ONLY
	mov	di, ds:[di].VTI_text		;point to text chunk
else
	mov	di, ds:[di].OLVLI_item		;point to text chunk
endif

EC <	tst	di				;is there an item	   >
EC <	ERROR_Z	OL_ERROR			;can't happen!		   >

	mov	di, ds:[di]			;else dereference text
	;
	; See if null, exit with INDETERMINATE_VALUE if so
	;
SBCS <	cmp	{byte} ds:[di], 0		;null?			>
DBCS <	cmp	{wchar} ds:[di], 0		;null?			>
	je	nullEntry			;yes, exit
	;
	; test for distance mode, in which case we use a different routine
	;
	mov	dx, di
	mov	cx, ds
	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
	clr	bx				;not a scrollbar
	call	SendMsgSetModifiedAndApplyIfNeeded
	call	CreateValueText		 	;set new text, in case limited
						;  to some other value than 
						;  what was typed.
if GEN_VALUES_ARE_TEXT_ONLY
	call	ValueTextSetItem
else
	call	SendValueToScrollbar		;send on to scrollbar 

	call	CheckIfFloatingText	
	jz	exit

	; Do this stuff as well, to force the text to redraw at a new position

	call	CF_DerefVisSpecDI
	mov	bp, ds:[di].OLVLI_item		;pass item
	mov	ax, MSG_SPEC_SPIN_SET_ITEM	;set the initial item
	call	CF_ObjCallInstanceNoLock
endif

exit:
	ret

nullEntry:
	;
	; No user entry, redisplay current value
	;
	call	OLValueSetValue
	jmp	exit

SetValueIfUserDirtied	endp


CommonFunctional ends

;---------------------

SpinGadgetCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueGainedFocus -- 
		MSG_META_TEXT_GAINED_FOCUS for OLValueClass

DESCRIPTION:	Handles gained focus.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_TEXT_GAINED_FOCUS
		^lcx:dx	- OD of object which has lost focus exclusive

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

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueGainedFocus method OLValueClass, MSG_META_TEXT_GAINED_FOCUS
	test	ds:[di].OLVLI_flags, mask OLVF_CUSTOM_RETURN_PRESS or \
				     mask OLVF_NAVIGATE_ON_RETURN_PRESS
	jz	exit				;on neither of these did we 
						;  activate the default, branch
	
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_TAKE_DEFAULT_EXCLUSIVE
	mov	bp, ds:[LMBH_handle]	;pass ^lbp:dx = this object
	mov	dx, si
	call	VisCallParent
exit:
	ret
OLValueGainedFocus	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY



COMMENT @----------------------------------------------------------------------

METHOD:		OLValueActivate -- 
		MSG_GEN_ACTIVATE for OLValueClass

DESCRIPTION:	Activates the text object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ACTIVATE

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

OLValueActivate	method OLValueClass, MSG_GEN_ACTIVATE
	;
	; If navigate on default request set, we'll navigate.
	;
	push	ax, es
	test	ds:[di].OLVLI_flags, mask OLVF_NAVIGATE_ON_RETURN_PRESS
	jz	checkForCustom			;not doing navigate, branch
	mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	call	ObjCallInstanceNoLock
	jmp	short callSuper

checkForCustom:
	;
	; Do the right thing if HINT_CUSTOM_RETURN_PRESS is specified.
	; -cbh 1/21/93
	;
	test	ds:[di].OLVLI_flags, mask OLVF_CUSTOM_RETURN_PRESS
	jz	callSuper
	mov	ax, HINT_VALUE_CUSTOM_RETURN_PRESS
	call	ObjVarFindData
	mov	ax, {word} ds:[bx]
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	cl, ds:[di].GVLI_stateFlags
	call	GenValueSendMsg
	jmp	short callSuper

callSuper:
	pop	ax, es

if GEN_VALUES_ARE_TEXT_ONLY
	mov	di, segment OLTextClass
	mov	es, di
	mov	di, offset OLTextClass
else
	mov	di, offset OLValueClass
endif
	GOTO	ObjCallSuperNoLock
	
OLValueActivate	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		OLValueKbdChar -- 
		MSG_META_KBD_CHAR for OLValueClass

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

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueKbdChar	method OLValueClass, MSG_META_KBD_CHAR, \
				     MSG_META_FUP_KBD_CHAR
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper		;skip if not press event...
	push	ax			;save method
	push	es
					;set es:di = table of shortcuts
					;and matching methods
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLValueKbdBindings
	call	ConvertKeyToMethod
	pop	es
	pop	bx			;get original method
	jnc	callSuperMethodInBX	;skip if no binding found...

	;found a shortcut: send max or min method to self

sendToSelf:
	;
	; ax <- message to send to self
	;
	clr	bx				;not a scrollbar
	call	SendMsgSetModifiedAndApplyIfNeeded	;mark modified, etc.
	ret

callSuperMethodInBX:
	mov	ax, bx			;old method
	
callSuper:
	
	;we don't care about this keyboard event. Call our superclass
	;so it will be forwarded up the focus hierarchy.

	mov	di, offset OLValueClass
	GOTO	ObjCallSuperNoLock
	
OLValueKbdChar	endm

;Keyboard shortcut bindings for OLValueClass (do not separate tables)

if DBCS_PCGEOS

OLValueKbdBindings	label	word
	word	length OLVShortcutList
		;P     C  S  C
		;h  A  t  h  h
		;y  l  r  f  a
	        ;s  t  l  t  r
OLVShortcutList KeyboardShortcut \
		<1, 0, 0, 1, C_SYS_UP and mask KS_CHAR>,	;Maximum
		<1, 0, 0, 1, C_SYS_DOWN and mask KS_CHAR>	;Minimum

else

OLValueKbdBindings	label	word
	word	length OLVShortcutList
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLVShortcutList KeyboardShortcut \
		<1, 0, 0, 1, 0xf, VC_UP>,	;Maximum
		<1, 0, 0, 1, 0xf, VC_DOWN>	;Minimum
endif
	
;OLVMethodList	label word
	word	MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM
	word	MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM

endif	;not GEN_VALUES_ARE_TEXT_ONLY



COMMENT @----------------------------------------------------------------------

METHOD:		OLSpinGadgetValueChanged -- 
		MSG_SPEC_SPIN_VALUE_CHANGED for OLSpinGadgetClass

DESCRIPTION:	If we've gotten here, it means there's a slider around and
		someone moved the thumb.  Do the right thing.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPIN_VALUE_CHANGED
		dx.cx   - value

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
	chris	10/11/92		Initial Version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

OLSpinGadgetValueChanged	method dynamic	OLSpinGadgetClass, \
				MSG_SPEC_SPIN_VALUE_CHANGED

if SLIDER_SNAPS_TO_INCREMENT
	;
	; adjust position of thumb to valid increment
	;
	call	SliderSnapToIncrement
endif

	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_SET_VALUE_FROM_RATIO
;	GOTO	ObjCallInstanceNoLock
	mov	bx, 0				; not scrollbar
	call	SendMsgSetModifiedAndApplyIfNeeded
	ret

OLSpinGadgetValueChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SliderSnapToIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust thumb to valid increment

CALLED BY:	INTERNAL
			OLSpinGadgetValueChanged
PASS:		*ds:si = spin gadget
		ds:di = spin gadget instance
		dx.cx = ratio
RETURN:		dx.cx = adjusted ratio
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SLIDER_SNAPS_TO_INCREMENT

SliderSnapToIncrement	proc	near
	uses	ax, bx, di, si, bp
	.enter
	test	ds:[di].OLSGI_attrs, mask OLSGA_SLIDER
	jz	done
	;
	; trivial cases
	;
	tst	dx
	jnz	done				; assume its 1.0, done
	tstwwf	dxcx
	jz	done				; its zero, done
	;
	; get increment as ratio
	;
	pushwwf	dxcx				; save passed ratio
	mov	bp, GVT_INCREMENT		; get increment
	mov	ax, MSG_GEN_VALUE_GET_VALUE_RATIO
	call	ObjCallInstanceNoLock		; dx.cx = increment ratio
	movwwf	disi, dxcx			; di.si = increment ratio
	popwwf	bxax				; bx.ax = passed ratio
	clrwwf	dxcx				; dx.cx = running total
tryNextIncrement:
	tst	dx				; check overflow before
	jnz	overflow			;	incrementing
	addwwf	dxcx, disi			; try next
	cmpwwf	dxcx, bxax
	je	done				; exactly on increment, done
	jb	tryNextIncrement
	;
	; found increment larger than desired ratio, check if we should
	; round down to previous increment or up to this one
	;	bxax = passed ratio
	;	dxcx = this increment
	;	disi = increment
	;
	pushwwf	dxcx				; save this increment
	pushwwf	disi				; save increment
	shrwwf	disi				; di.si = half increment
	subwwf	dxcx, bxax			; dx.cx = difference w/passed
	cmpwwf	dxcx, disi			; check which increment to use
	popwwf	disi				; di.si = increment
	popwwf	dxcx				; dx.cx = this increment
	jbe	done				; difference less than half,
						;	use this increment
	subwwf	dxcx, disi			; else, use previous increment
done:
	.leave
	ret

overflow:
	mov	dx, 1				; just use 1.0
	clr	cx
	jmp	short done

SliderSnapToIncrement	endp

endif ; SLIDER_SNAPS_TO_INCREMENT

endif	;not GEN_VALUES_ARE_TEXT_ONLY

SpinGadgetCommon ends

;---------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	SendValueToScrollbar

SYNOPSIS:	Updates scrollbar's value.  We might need to set up an
	 	increment, but actually, there's probably no reason the
		slider would need to know about this.

CALLED BY:	utility

PASS:		*ds:si -- value handle

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/19/90		Initial version

------------------------------------------------------------------------------@

if not GEN_VALUES_ARE_TEXT_ONLY

SendValueToScrollbar	proc	far		uses	cx, dx, bp, si
	.enter
	mov	bp, GVT_VALUE
	mov	ax, MSG_GEN_VALUE_GET_VALUE_RATIO
	call	ObjCallInstanceNoLock		;in dx.cx

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLSGI_scrollbar
	tst	si
	jz	exit

	clr	bp
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
SendValueToScrollbar	endp

endif	;not GEN_VALUES_ARE_TEXT_ONLY

CommonFunctional ends

;----------------------

Unbuild	segment resource






COMMENT @----------------------------------------------------------------------

METHOD:		OLValueUnbuildBranch -- 
		MSG_SPEC_UNBUILD_BRANCH for OLValueClass

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

if not GEN_VALUES_ARE_TEXT_ONLY

OLValueUnbuildBranch	method dynamic	OLValueClass, \
				MSG_SPEC_UNBUILD_BRANCH

	;
	; Before nuking all references to the text, save it if dirty
	;
	push	ax, es
	call	SetValueIfUserDirtiedFar
	pop	ax, es
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;
	; Nuke the spin gadget item.  This used to happen via the queue on
	; a MSG_SPIN_UNBUILD, but that code's been thrown out.  -4/21/93 cbh
	;
	push	ax
	clr	ax
	xchg	ax, ds:[di].OLVLI_item		;get current item, and clear it
	tst	ax
	jz	10$				;no was no item, branch
	call	LMemFree
10$:

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLSGI_text		;is there a text object?
	tst	di
	jz	20$
	mov	di, ds:[di]			
	add	di, ds:[di].Vis_offset
	clr	ds:[di].VTI_text		;zero the object's text ptr,
						;  so the text object won't
						;  try to re-nuke it.
20$::
	pop	ax
	mov	di, offset OLValueClass
	GOTO	ObjCallSuperNoLock		;do superclass unbuild

OLValueUnbuildBranch	endm

endif	;not GEN_VALUES_ARE_TEXT_ONLY


Unbuild	ends









