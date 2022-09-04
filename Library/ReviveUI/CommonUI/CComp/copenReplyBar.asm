COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CComp (common code for several specific ui's)
FILE:		copenReplyBar.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLReplyBarClass		OLCtrlClass subclass object - contains
				response triggers for dialogs

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

DESCRIPTION:
	$Id: copenReplyBar.asm,v 1.22 96/11/18 23:40:47 brianc Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLReplyBarClass	mask CLASSF_DISCARD_ON_SAVE or \
			mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


;---------------------------------------------------

GadgetBuild	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLReplyBarInitialize

DESCRIPTION:	We intercept this to indicate that we want to provide a
		custom vis parent.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLReplyBar)

		ax	= MSG_META_INITIALIZE

		cx, dx, bp - ?

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp
		bx, di, si, es, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		initial version

------------------------------------------------------------------------------@

OLReplyBarInitialize	method dynamic	OLReplyBarClass, \
					MSG_META_INITIALIZE
	;
	; call superclass directly to do stuff first
	;
	call	OLCtrlInitialize
	;
	; then force default SpecBuild handler to MSG_SPEC_GET_VIS_PARENT
	; to this object when looking for a visible parent to attach it to
	;

	call	GB_DerefVisSpecDI
	ornf	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT
	ret
OLReplyBarInitialize	endm

GB_DerefVisSpecDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
GB_DerefVisSpecDI	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLReplyBarGetVisParent

DESCRIPTION:	Returns visual parent for this object

PASS:
	*ds:si - instance data
	es - segment of OLReplyBarClass

	ax - MSG_SPEC_GET_VIS_PARENT

	cx - ?
	dx - ?
	bp - SpecBuildFlags
		mask SBF_WIN_GROUP	- set if building win group

RETURN:
	carry - set if vis parent available, clear to use gen parent
	ax - ?
	cx:dx	- Visual parent to use
	bp - SpecBuildFlags

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		Initial version

------------------------------------------------------------------------------@
OLReplyBarGetVisParent	method	dynamic OLReplyBarClass, \
						 MSG_SPEC_GET_VIS_PARENT
	mov	cx, ds:[di].OLRBI_dialog.handle	; ^lcx:dx = associated dialog
	mov	dx, ds:[di].OLRBI_dialog.chunk
	clc					; assume none
	jcxz	done				; none, use gen parent
	stc					; else, use dialog
done:
	ret
OLReplyBarGetVisParent	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLReplyBarSetDialog

DESCRIPTION:	Store dialog information.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLReplyBar)

		ax	= MSG_OL_REPLY_BAR_SET_DIALOG

		^lcx:dx	= OLDialogWin containing the reply bar

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp
		bx, di, si, es, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		initial version

------------------------------------------------------------------------------@

OLReplyBarSetDialog	method dynamic	OLReplyBarClass, \
					MSG_OL_REPLY_BAR_SET_DIALOG
	mov	ds:[di].OLRBI_dialog.handle, cx
	mov	ds:[di].OLRBI_dialog.chunk, dx
	ornf	ds:[di].OLRBI_flags, mask OLRBF_UNDER_DIALOG
	ret
OLReplyBarSetDialog	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLReplyBarVisAddChild

DESCRIPTION:	We intercept this to ensure that any standard triggers in
		the reply bar is ordered correctly.

PASS:		*ds:si	= instance data for object
		ds:di	= specific instance (OLReplyBar)

		ax	= MSG_VIS_ADD_CHILD

		^lcx:dx	= child to add
		bp	= CompChildFlags

RETURN:		nothing
		cx, dx unchanged

DESTROYED:	ax, bp
		bx, di, si, es, ds

PSEUDO CODE/STRATEGY:
		Normal dialogs shouldn't have strange combinations of triggers,
		so we can just apply these rules:
		move IC_STOP, IC_APPLY, IC_YES, IC_OK to the front in that order
		move IC_RESET, IC_NO, IC_DISMISS to the back in that order
		Results in this order:
		IC_OK IC_YES IC_APPLY IC_STOP <other> IC_RESET IC_NO IC_DISMISS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		initial version

------------------------------------------------------------------------------@

OLReplyBarVisAddChild	method dynamic	OLReplyBarClass, MSG_VIS_ADD_CHILD
	push	cx, dx			; save child
	;
	; first add child normally
	;
	mov	di, offset OLReplyBarClass
	call	ObjCallSuperNoLock
					; preserves ^lcx:dx = child
	;
	; if the reply isn't under a dialog, we don't support reply bar
	; ordering, get out
	;
	call	GB_DerefVisSpecDI
	test	ds:[di].OLRBI_flags, mask OLRBF_UNDER_DIALOG
	LONG jz	done
	;
	; then check if this is trigger, if so check if this is a replacement
	; standard trigger
	;
	mov	bx, cx				; ^lbx:si = child
	xchg	si, dx				; *ds:dx = OLReplyBar
	call	ObjSwapLock			; *ds:si = child
						; ^lbx:dx = OLReplyBar
	push	bx				; save OLReplyBar block
	mov	di, segment GenTriggerClass
	mov	es, di
	mov	di, offset GenTriggerClass
	call	ObjIsObjectInClass
	mov	ax, IC_NULL			; assume not standard trigger
	jnc	notStandardTrigger		; not trigger
	mov	ax, ATTR_GEN_TRIGGER_INTERACTION_COMMAND
	call	ObjVarFindData
	mov	ax, IC_NULL			; assume not standard trigger
	jnc	notStandardTrigger
EC <	VarDataFlagsPtr	ds, bx, ax					>
EC <	test	ax, mask VDF_EXTRA_DATA					>
EC <	ERROR_Z	OL_ERROR_ATTR_GEN_TRIGGER_INTERACTION_COMMAND_WITHOUT_DATA >
	mov	ax, ds:[bx]			; ax = InteractionCommand
notStandardTrigger:
	pop	bx				; restore OLReplyBar block
	call	ObjSwapUnlock			; ds = OLReplyBar segment
						; bx = trigger block
	xchg	si, dx				; *ds:si = OLReplyBar
						; ^lbx:dx = child
	;
	; now ensure the ordering of the triggers
	;	*ds:si = OLReplyBar
	;	^lbx:dx = newly added child
	;	ax = InteractionCommand of newly added child
	;		or IC_NULL if newly added child is not standard trigger
	;
	mov	bp, CCO_FIRST			; triggers to the front
	mov	cx, IC_STOP
	call	MoveStandardTriggerIfFound
	mov	cx, IC_APPLY
	call	MoveStandardTriggerIfFound
	mov	cx, IC_YES
	call	MoveStandardTriggerIfFound
	mov	cx, IC_OK
	call	MoveStandardTriggerIfFound
if _ODIE
	mov	cx, IC_NEXT
	call	MoveStandardTriggerIfFound
	mov	cx, IC_PREVIOUS
	call	MoveStandardTriggerIfFound
endif
	mov	bp, CCO_LAST			; triggers to the end
	mov	cx, IC_RESET
	call	MoveStandardTriggerIfFound
	mov	cx, IC_NO
	call	MoveStandardTriggerIfFound
	mov	cx, IC_DISMISS
	call	MoveStandardTriggerIfFound
	mov	cx, IC_HELP
	call	MoveStandardTriggerIfFound	; help should be last

done:
	pop	cx, dx				; restore child
	ret
OLReplyBarVisAddChild	endm

;
; pass:
;	*ds:si - OLReplyBar
;	cx - InteractionCommand of trigger to move
;	^lbx:dx - newly added trigger
;	ax - InteractionCommand of newly added trigger
;	bp - move flags for standard trigger
; return:
;	nothing
; destroys:
;	cx, di
;
MoveStandardTriggerIfFound	proc	near
	uses	ax, bx, dx, si, bp
	.enter
	;
	; check if newly added child is the standard trigger that we wish
	; to move, if so, move it
	;
	cmp	cx, ax
	jne	notPassedTrigger
	mov	cx, bx				; ^lcx:dx = passed trigger
	jmp	short moveTrigger

notPassedTrigger:
	;
	; ask OLDialogWin for the standard trigger corresponding to this
	; InteractionCommand, if any
	;	cx = InteractionCommand of trigger to move
	;
	push	si, bp				; save OLReplyBar chunk
						; save move flags
	call	GB_DerefVisSpecDI
	mov	bx, ds:[di].OLRBI_dialog.handle
	mov	si, ds:[di].OLRBI_dialog.chunk
EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR						>
	mov	ax, MSG_OL_DIALOG_WIN_FIND_STANDARD_TRIGGER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ^ldx:bp = trigger, if found
	pop	si, ax				; restore OLReplyBar chunk
						; restore move flags
	jnc	done				; not found, done
	;
	; make sure that the standard trigger is a child of ours, it will not
	; be if the developer supplied it and it doesn't have
	; HINT_SEEK_REPLY_BAR
	;
	push	ax				; save move flags
	mov	cx, dx				; ^lcx:dx = standard trigger
	mov	dx, bp
	mov	ax, MSG_VIS_FIND_CHILD
	call	ObjCallInstanceNoLock
	pop	bp				; bp = move flags
	jc	done				; not found, done
moveTrigger:
	;
	; finally, move the sucker
	;
	mov	ax, MSG_VIS_MOVE_CHILD		; else, move it
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
MoveStandardTriggerIfFound	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLReplyBarSpecSetNotUsable -- MSG_SPEC_SET_NOT_USABLE handler.

DESCRIPTION:	We intercept this method here, to notify parent OLWin that
		we are no more.

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/92		initial version

------------------------------------------------------------------------------@

OLReplyBarSpecSetNotUsable method	dynamic OLReplyBarClass,
						MSG_SPEC_SET_NOT_USABLE

	push	ax, dx
	mov	ax, MSG_OL_WIN_NOTIFY_OF_REPLY_BAR
	clr	cx			; no more reply bar group
	mov	dx, cx
	call	CallOLWin
	pop	ax, dx
	mov	di, offset OLReplyBarClass
	call	ObjCallSuperNoLock
	ret
OLReplyBarSpecSetNotUsable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLReplyBarSpecSetUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reply bar is being set usable, make sure any dialog above us
		rebuilds any standard triggers it needs to.

CALLED BY:	MSG_SPEC_SET_USABLE

PASS:		*ds:si	= OLReplyBarClass object
		ds:di	= OLReplyBarClass instance data
		es 	= segment of OLReplyBarClass
		ax	= MSG_SPEC_SET_USABLE

		dl	= VisUpdateMode

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This routine depends on the fact that any reply bar triggers
		are children of the reply bar and not children of the dialog,
		because we want any standard triggers to be recognized
		before we attempt to rebuild standard triggers.  We "recognize"
		those standard triggers by calling the superclass first to
		build the reply bar and its children (any child standard
		triggers will notify the dialog of their existance.

		As only an application-supplied reply bar will be potentially
		set usable, we don't have to worry about the case where
		application-supplied reply bar triggers are not children of
		the specific-UI-supplied reply bar.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/8/92  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLReplyBarSpecSetUsable	method	dynamic	OLReplyBarClass,
							MSG_SPEC_SET_USABLE
	;
	; first, call superclass to build the normal generic tree under us
	;
	mov	di, offset OLReplyBarClass 
	call	ObjCallSuperNoLock
	;
	; then, call associated dialog to re-do standard triggers.
	;
	call	GB_DerefVisSpecDI
	mov	bx, ds:[di].OLRBI_dialog.handle
	mov	si, ds:[di].OLRBI_dialog.chunk
	tst	bx
	jz	done
	mov	ax, MSG_OL_DIALOG_WIN_REBUILD_STANDARD_TRIGGERS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
OLReplyBarSpecSetUsable	endm


GadgetBuild	ends

CommonFunctional segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLReplyBarDraw -- 
		MSG_VIS_DRAW for OLReplyBarClass

DESCRIPTION:	Draws a reply bar.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW
		bp 	- gstate
		cl 	- DrawFlags

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
	chris	1/23/93         	Initial Version

------------------------------------------------------------------------------@

if not NO_REPLY_BAR_DRAWING

if _RUDY
PrintMessage <integrate Rudy's OLReplyBarDraw with "not NO_REPLY_BAR_DRAWING"s>
endif

OLReplyBarDraw	method dynamic	OLReplyBarClass, \
				MSG_VIS_DRAW

if _MOTIF or _PM;---------------------------------------------------------------
	push	ax, cx, dx, bp

	test	ds:[di].OLRBI_flags, mask OLRBF_UNDER_DIALOG
	mov	di, bp
if _MOTIF
	jz	bwReplyBar			;not under dialog, draw etch
	call	OpenCheckIfBW
	jc	bwReplyBar

	call	OpenSetInsetRectColors		;get inset rect colors
	xchg	ax, bp
	xchg	al, ah				;make outset rect
	xchg	ax, bp
	call	VisGetBounds			;get normal bounds
	call	OpenDrawRect
	jmp	short 10$
bwReplyBar:
endif

	;
	; get display scheme data
	push	cx
	mov	ax, GIT_PRIVATE_DATA
	call	GrGetInfo			;returns ax, bx, cx, dx
	pop	cx
	;
	;al = color scheme, ah = display type, cl = update flag
	ANDNF	ah, mask DF_DISPLAY_TYPE	;keep display type bits
	cmp	ah, DC_GRAY_1			;is this a B&W display?
	pushf
	mov	ax, cx
	and	ax, mask CS_darkColor		; assume dark color
	call	GrSetLineColor
	clr	cx
	call	OpenGetLineBounds		; If this is a reply bar,
	add	bx, MO_REPLY_BAR_INSET
	call	OpenCheckIfCGA
	jnc	notCGA
	sub	bx, MO_REPLY_BAR_INSET - MO_CGA_REPLY_BAR_INSET
notCGA:
	call	GrDrawHLine			;   draw line over triggers
	popf					; If it's a B&W display, 
	je	10$				;   then don't draw etch line
	inc	bx
	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax
	call	GrDrawHLine			; Draw etch line for color disp
10$:
	pop	ax, cx, dx, bp
endif		;---------------------------------------------------------------

	mov	di, offset OLReplyBarClass	;do Vis Comp draw
	CallSuper	MSG_VIS_DRAW
	ret
OLReplyBarDraw	endm

else

if _RUDY
OLReplyBarDraw	method dynamic	OLReplyBarClass, MSG_VIS_DRAW
	;
	; set clip rect so reply buttons don't draw outside reply bar
	; bounds
	;
	mov	di, bp				;di = gstate
	call	GrSaveState
	push	cx				;save draw flags
	call	VisGetBounds			;ax, bx, cx, dx = bounds
	push	si				;save reply bar
	mov	si, PCT_REPLACE
	call	GrSetClipRect
	pop	si				;*ds:si = reply bar
	pop	cx				;cx = draw flags
	push	di				;save gstate
	mov	ax, MSG_VIS_DRAW
	mov	di, offset OLReplyBarClass
	CallSuper	MSG_VIS_DRAW
	pop	di				;di = gstate
	call	GrRestoreState			;restore gstate
	ret
OLReplyBarDraw	endm
endif ; _RUDY

endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLReplyBarNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for OLReplyBarClass

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
	OLReplyBarClass handler:
	    identical to standard VisCompClass handler, except we set
	    the NCF_BAR_Reply_RELATED flag, so that non-Reply bar navigation
	    queries can skip this group completely.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/94		initial version

------------------------------------------------------------------------------@

if _RUDY

OLReplyBarNavigate	method dynamic	OLReplyBarClass,
					MSG_SPEC_NAVIGATION_QUERY

	mov	bl, mask NCF_IS_MENU_RELATED or mask NCF_IS_COMPOSITE
					;pass flags: is composite, is not
				  	;root node, not focusable.
	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon
	ret
OLReplyBarNavigate	endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLReplyBarActivateTrigger -- 
		MSG_OL_REPLY_BAR_ACTIVATE_TRIGGER for OLReplyBarClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Activates a trigger.

PASS:		*ds:si 	- instance data
		es     	- segment of OLReplyBarClass
		ax 	- MSG_OL_REPLY_BAR_ACTIVATE_TRIGGER
		cx	- child to activate, if possible

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
	chris	8/ 9/94         Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FUNCTION_KEYS_MAPPED_TO_REPLY_BAR_BUTTONS

OLReplyBarActivateTrigger	method dynamic	OLReplyBarClass, \
				MSG_OL_REPLY_BAR_ACTIVATE_TRIGGER

	GOTO	OLMenuBarActivateTrigger	;same shme

OLReplyBarActivateTrigger	endm

endif



COMMENT @----------------------------------------------------------------------

METHOD:		OLReplyBarRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLReplyBarClass

DESCRIPTION:	Recalcs size for the menu bar.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - suggested size

RETURN:		cx, dx - size to use
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 6/92		Initial Version

------------------------------------------------------------------------------@

if _RUDY

OLReplyBarRecalcSize	method dynamic	OLReplyBarClass, \
				MSG_VIS_RECALC_SIZE

	call	ReplyBarPassMarginInfo
	call	OpenRecalcCtrlSize

if _RUDY
	;
	;  Menu bar is fixed-height on the Rudy; we can't use
	;  the height returned by OpenRecalcCtrlSize because if
	;  there are more than 4 menu-bar items, windows will go
	;  off the screen.
	;
	;  Include top/bottom margins as well -- brianc 2/16/96
	;
	mov	dx, RUDY_MENU_BAR_HEIGHT + RUDY_SLOT_TOP_MARGIN*2
	;
	;  Unless we are in bubble, where we have a smaller top margin
	;
	call	OLReplyBarCheckInBubble
	jnc	noBubble
.assert (RUDY_SLOT_TOP_MARGIN gt RUDY_SLOT_BUBBLE_TOP_MARGIN)
	sub	dx, (RUDY_SLOT_TOP_MARGIN - RUDY_SLOT_BUBBLE_TOP_MARGIN)*2
noBubble:
endif
	ret
OLReplyBarRecalcSize	endm

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLReplyBarPositionBranch -- 
		MSG_VIS_POSITION_BRANCH for OLReplyBarClass

DESCRIPTION:	Positions a branch.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_POSITION_BRANCH

		cx, dx  - new position for composite

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
	chris	2/ 6/92		Initial Version

------------------------------------------------------------------------------@

if _RUDY

OLReplyBarPositionBranch	method dynamic	OLReplyBarClass, \
				MSG_VIS_POSITION_BRANCH
	call	ReplyBarPassMarginInfo	
	call	VisCompPosition
	ret
OLReplyBarPositionBranch	endm

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	ReplyBarPassMarginInfo

SYNOPSIS:	Passes margin info for OpenRecalcCtrlSize.

CALLED BY:	OLReplyBarRecalcSize, OLReplyBarPositionBranch

PASS:		*ds:si -- MenuBar bar

RETURN:		bp -- VisCompMarginSpacingInfo

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 1/92		Initial version

------------------------------------------------------------------------------@

if _RUDY

ReplyBarPassMarginInfo	proc	near		uses	cx, dx
	.enter
	call	OLReplyBarGetSpacing		;first, get spacing

	push	cx, dx				;save spacing
	call	OLReplyBarGetMargins		;margins in ax/bp/cx/dx
	pop	di, bx
	call	OpenPassMarginInfo
exit:
	.leave
	ret
ReplyBarPassMarginInfo	endp

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLReplyBarGetSpacing -- 
		MSG_VIS_COMP_GET_CHILD_SPACING for OLReplyBarClass

DESCRIPTION:	Returns spacing for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_GET_SPACING

RETURN:		cx 	- spacing between children
		dx	- spacing between lines of wrapped children
		
DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@

if _RUDY
OLReplyBarGetSpacing	method OLReplyBarClass, \
			MSG_VIS_COMP_GET_CHILD_SPACING

	mov	dx, MENU_BAR_BETWEEN_LINES
	mov	cx, MENU_BAR_BETWEEN_KIDS
	ret

OLReplyBarGetSpacing	endp
endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLReplyBarGetMargins -- 
		MSG_VIS_COMP_GET_MARGINS for OLReplyBarClass

DESCRIPTION:	Returns margins and margins for the object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_VIS_COMP_GET_MARGINS

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	7/89		Initial version

------------------------------------------------------------------------------@

if _RUDY

OLReplyBarGetMargins method OLReplyBarClass, MSG_VIS_COMP_GET_MARGINS

	mov	bp, MENU_BAR_TOP_MARGIN
	mov	dx, MENU_BAR_BOTTOM_MARGIN
	;
	; If in a bubble dialog, use less top/bottom margin.     It's better
	; to add the top/bottom margin here rather than in OLWin class.
	;
	call	OLReplyBarCheckInBubble
	jnc	noBubble
	mov	bp, BUBBLE_MENU_BAR_TOP_MARGIN
	mov	dx, BUBBLE_MENU_BAR_BOTTOM_MARGIN
noBubble:
	mov	ax, MENU_BAR_LEFT_MARGIN
	mov	cx, MENU_BAR_RIGHT_MARGIN
	ret

OLReplyBarGetMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLReplyBarCheckInBubble
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if in bubble dialog

CALLED BY:	OLReplyBarGetMargins
		OLReplyBarRecalcSize
PASS:		*ds:si = OLReplyBar
RETURN:		carry set if bubble
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLReplyBarCheckInBubble	proc	near
	push	si
	call	VisSwapLockParent	; *ds:si = parent, bx = child handle
	jnc	noBubble		; carry clear
	mov	di, segment OLDialogWinClass
	mov	es, di
	mov	di, offset OLDialogWinClass
	call	ObjIsObjectInClass
	jnc	noBubbleUnlock		; carry clear
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPWI_flags, mask OLPWF_IS_POPUP
	jz	noBubbleUnlock		; carry clear
	stc				; indicate in bubble
noBubbleUnlock:
	call	ObjSwapUnlock		; preserves flags
noBubble:
	pop	si
	ret
OLReplyBarCheckInBubble	endp

endif

CommonFunctional ends

