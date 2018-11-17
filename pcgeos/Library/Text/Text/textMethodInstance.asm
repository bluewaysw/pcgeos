COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textMethodInstance.asm

AUTHOR:		John Wedgwood, Oct 25, 1989

METHODS:
	Name			Description
	----			-----------
	MSG_VIS_TEXT_SET_MAX_LENGTH
	MSG_VIS_TEXT_GET_MAX_LENGTH
	MSG_SET_MAX_LINES
	MSG_GET_MAX_LINES
	MSG_VIS_TEXT_GET_DOC_OBJECT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/25/89		Initial revision

DESCRIPTION:


	$Id: textMethodInstance.asm,v 1.1 97/04/07 11:18:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextInstance segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextRecreateCachedGStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the cached gstate (if one exists).

CALLED BY:	via MSG_VIS_RECREATE_CACHED_GSTATES
PASS:		ds:*si	= instance pointer.
		es	= class segment.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextRecreateCachedGStates	method	dynamic VisTextClass,
						MSG_VIS_RECREATE_CACHED_GSTATES

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	di, ds:[bx].VTI_gstate
	tst	di				; Check for one existing.
	jz	VTRGS_done			; Quit if none exists.

	call	GrDestroyState 		; Nuke the old gstate.
	
	push	ax				; Save ax
	push	{word} ds:[bx].VTI_gsRefCount	; Save old reference count.
	andnf	ds:[bx].VTI_gsRefCount, not mask GSRCAF_REF_COUNT
						; Force creation and
	mov	ds:[bx].VTI_gstate, 0		;  initialization of a gstate.
	call	TextGStateCreate		; Make a gstate...
	pop	ax				; Get reference count
	mov	ds:[bx].VTI_gsRefCount, al	; Restore in instance data.
	pop	ax				; Restore ax
VTRGS_done:
	ret

VisTextRecreateCachedGStates	endm

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextNotifyGeometryValid -- MSG_VIS_NOTIFY_GEOMETRY_VALID

DESCRIPTION:	Recalculate the object now that the bounds are valid.

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - MSG_VIS_NOTIFY_GEOMETRY_VALID

RETURN:

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@

VisTextNotifyGeometryValid  method VisTextClass, MSG_VIS_NOTIFY_GEOMETRY_VALID
	uses	bp, dx
	.enter

EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID		>
EC <	ERROR_NZ	VIS_TEXT_GEOMETRY_VALID_ERROR			>

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di, offset VisTextClass		; call superclass (VisClass has
	call	ObjCallSuperNoLock		;   a default handler for this)

BEC <	call	CheckRunPositions		>

	;
	; Initialize the gstate
	;
	call	RecalcGStateIfNeeded
	call	TextGStateCreate

	;
	; If no line info chunk exists, create one
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	tst	ds:[bx].VTI_lines		; Check for has lines already
	jnz	gotLines			; Branch if we have them
	clrwbf	ds:[bx].VTI_height		; this only really matters for
						; one line objects
	call	TL_LineStorageCreate		; Otherwise create new ones
gotLines:

	;
	; Recalculate
	;
	call	TextCompleteRecalc		; Recalculate object

	;
	; In the case of a single line object, we must make sure that the
	; left offset is correct
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_state,mask VTS_ONE_LINE
	jz	notOneLine

	;
	; If the object has a valid image, then resetting the left-offset is
	; probably not a good idea. There is no guarantee that we will be
	; redrawn.
	;
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID
	jz	common				; Branch if already drawn

	;
	; Force the cursor on screen.
	;
	mov	ds:[di].VTI_leftOffset, INITIAL_LEFT_OFFSET
	call	TSL_SelectGetCursorCoord
	;
	; cx	= Cursor region
	; ax	= X position
	; dx	= Y position
	;
	mov	cx, ax				; cx <- X position
	call	VisTextScrollOneLine
	jmp	common

notOneLine:
	mov	ds:[di].VTI_leftOffset, 0

common:

	;
	; Position the cursor correctly.
	;
	call	TSL_SelectIsCursor		; Carry set if cursor
	jnc	afterCursor			; Skip if not cursor
	call	TSL_SelectGetCursorCoord	; cx, ax, dx <- position
	mov	di, ds:[si]
	add	di, ds:[di].VisText_offset
	add	ax, ds:[di].VTI_leftOffset

;	We need to update the goalPosition here, as otherwise it won't
;	be set correctly, so if you try to navigate to the next line, and
;	there is no next line, the cursor will be moved to the start of
;	the current line.

	mov	ds:[di].VTI_goalPosition, ax
	call	TSL_CursorPosition		; Move the cursor
	
afterCursor:

	call	TextGStateDestroy

BEC <	call	CheckRunPositions		>

quit::
	.leave
	ret

VisTextNotifyGeometryValid	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle MSG_VIS_OPEN by initializing the cursor.

CALLED BY:	External.
PASS:		ds:*si = ptr to instance.
		es     = segment containing VisTextClass.
		ax     = MSG_VIS_OPEN.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/27/89		Initial version
	doug	5/15/91		Added test for line structure not yet built out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextOpen	method dynamic	VisTextClass, MSG_VIS_OPEN

	mov	di, offset VisTextClass
	CallSuper	MSG_VIS_OPEN

	call	TextInstance_DerefVis_DI
	mov	ds:[di].VTI_timerHandle, 0	;no timer yet
	and	ds:[di].VTI_intSelFlags, not (mask VTISF_CURSOR_ON \
					or mask VTISF_DOING_SELECTION \
					or mask VTISF_DOING_DRAG_SELECTION)
	call	RecalcGStateIfNeeded
	pushf					;save focus state

EC <	push	ax							>
EC <	mov	al, ds:[di].VTI_gsRefCount				>
EC <	and	al, mask GSRCAF_REF_COUNT
EC <	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS		>
EC <	jz	10$							>
EC <	dec	al							>
EC <10$:								>
EC <	tst	al							>
EC <	ERROR_NZ	VIS_TEXT_OPEN_BAD_GS_REF_COUNT			>
EC <	pop	ax							>

	call	TextGStateCreate

	;
	; Test to make sure that we've got a line structure built out
	; by this time.  It's possible that we haven't, in the case that
	; this object was setup in a .ui file pre-instantiated with bounds,
	; & geometry disabled. SO.... correct the situation by sending
	; the MSG_VIS_NOTIFY_GEOMETRY_VALID to ourselves, simulating the
	; completion of geometry that normally happens BEFORE we get
	; a MSG_VIS_OPEN.
	;
	;					-- Doug
	;
	; Thanks, Doug.   Now I'll put in a hack to make sure the geometry
	; is valid.  -chris 6/5/91
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test 	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jnz	haveLineStruct			;not valid anyway, skip this

	tst	ds:[di].VTI_lines
	jnz	haveLineStruct
	push	ax
	call	VisTextNotifyGeometryValid
	pop	ax
haveLineStruct:

	popf
	jnc	notFocus
	call	EditHilite
	call	TSL_StartCursorCommon
notFocus:

	; Scroll to show the selected area

	mov	dx, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SHOW_POSITION
	call	ObjCallInstanceNoLock

	; If we have the target then send out notifications

	call	TextInstance_DerefVis_DI
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	avoidNotification
	mov	ax, VIS_TEXT_GAINED_TARGET_NOTIFICATION_FLAGS
	call	TA_SendNotification
avoidNotification:

	call	TextGStateDestroy

	ret

VisTextOpen	endm

;---------

	; return: carry - set if focus

RecalcGStateIfNeeded	proc	near
	class	VisTextClass

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	notFocus				;carry is clear

	call	TextGStateDestroy
	call	TextGStateCreate
	stc
notFocus:
	ret

RecalcGStateIfNeeded	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem MSG_VIS_CLOSE and mark that we are no longer
		realized.

CALLED BY:	External.
PASS:		ds:*si = ptr to instance.
		es     = segment containing VisTextClass.
		ax     = MSG_VIS_CLOSE.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/27/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextClose	method dynamic	VisTextClass, MSG_VIS_CLOSE

;we do it both now and when we lose focus - brianc 4/19/95
;if (0)	; We now kill the timer when we lose sys focus. - Joon (12/8/94)
	;
	; Kill the timer used to flash the cursor
	;
	clr	bx
	xchg	bx, ds:[di].VTI_timerHandle
	tst	bx
	jz	20$
	mov	ax, ds:[di].VTI_timerID
	call	TimerStop
20$:
;endif

	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO
	call	ObjVarFindData
	jnc	30$
	mov	ax, ds:[bx].TVTNCPID_id
	clr	dx
	xchg	dx, ds:[bx].TVTNCPID_handle
	tst	dx
	jz	25$
	mov	bx, dx
	call	TimerStop
25$:
	mov	ax, TEMP_VIS_TEXT_NOTIFY_CURSOR_POSITION_INFO
	call	ObjVarDeleteData
30$:

	call	TextInstance_DerefVis_DI
	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_SELECTION
	je	notSelecting			; quit if not doing selection.
	call	VisTextLargeEndSelect		; Force end of any select
						; operation in progress,
						; destroy gstate
notSelecting:

	;
	; Stop any quick-transfer in progress, though this might not be ours
	;
	call	TextInstance_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jz	noQT
	mov	bx, ds:[LMBH_handle]		; bx:di = our OD
	mov	di, si
	call	ClipboardClearQuickTransferNotification
	call	ClipboardAbortQuickTransfer
noQT:

	mov	ax, MSG_VIS_CLOSE
	mov	di, offset VisTextClass
	CallSuper	MSG_VIS_CLOSE

	call	RecalcGStateIfNeeded

	ret

VisTextClose	endm

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextGetOneLineWidth -- MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
						for VisTextClass

DESCRIPTION:	Return the width of the text

PASS:	*ds:si	- instance data
	cx	- number of characters to use (0 to use entire string)

RETURN: cx	- width of the string

DESTROYED: ax, di, (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Use the first charAttr run (if there is more than one present)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/2/90		Initial version

------------------------------------------------------------------------------@
VisTextGetOneLineWidth	method	VisTextClass, MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
	uses	dx
	.enter

	;
	; Create the GState, and stuff the charAttr
	;
	tst	cx				; # of chars non-zero
	jnz	continue			; yes, so do nothing
	call	TS_GetTextSize			; # of chars => DX.AX
	mov	cx, ax				; now in CX
continue:

	;
	; cx holds the number of bytes of text to compute over
	;
	call	TextGStateCreate		; Make sure we have a gstate

	clrdw	dxax				; use the first charAttr run
	call	TA_CharAttrRunSetupGStateForCalc ; di <- gstate.

	;
	; Finds the actual length
	;
	push	ds, si

	clrdw	dxax				; dx.ax <- offset to lock down
	call	TS_LockTextPtr			; ds:si <- ptr to the text
	mov_tr	cx, ax				; cx <- characters after offset
	;
	; We make the not terribly radical assumption that the text object
	; is a small text object. If you are creating a large single line
	; text object you deserve what you get :-)
	;
	call	GrTextWidth			; width => DX
	mov	cx, dx				; move it to CX

	;
	; Since it's a small object we don't bother to unlock it.
	;
	pop	ds, si

	;
	; Destroy the GState
	;
	call	TextGStateDestroy		; nuke the GState

	.leave
	ret
VisTextGetOneLineWidth	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetWashColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color for the wash behind the text.

CALLED BY:	via MSG_VIS_TEXT_SET_WASH_COLOR.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ch	= VisTextColorMapMode
		cl	= if (ch == CF_RGB), Red
			  if (ch == CF_INDEX), Color index.
		dl	= Green (if CF_RGB).
		dh	= Blue (if CF_RGB).
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Added 9/10/91:  If this method is called from outside the text
	object, it is necessary to create a gstate, otherwise it
	crashes with a resounding thud!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/89	Initial version
	cdb	9/10/91		Added calls to create/destroy gstate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetWashColor	method dynamic	VisTextClass, MSG_VIS_TEXT_SET_WASH_COLOR
	mov	ds:[di].VTI_washColor.low,cx
	mov	ds:[di].VTI_washColor.high,dx
	call	TextGStateCreate
	clr	ax
	call	TextDraw
	call	TextGStateDestroy
	ret
VisTextSetWashColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetWashColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the color for the wash behind the text.

CALLED BY:	via MSG_VIS_TEXT_GET_WASH_COLOR.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
RETURN:		ch	= VisTextColorMapMode
		cl	= if (ch == CF_RGB), Red
			  if (ch == CF_INDEX), Color index.
		dl	= Green (if CF_RGB).
		dh	= Blue (if CF_RGB).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetWashColor	method dynamic	VisTextClass, MSG_VIS_TEXT_GET_WASH_COLOR
	mov	cx, ds:[di].VTI_washColor.low
	mov	dx, ds:[di].VTI_washColor.high
	ret

VisTextGetWashColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetMaxLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new maximum length of the text.

CALLED BY:	via MSG_VIS_TEXT_SET_MAX_LENGTH
PASS:		ds:*si = pointer to VisTextInstance.
		ax     = MSG_VIS_TEXT_SET_MAX_LENGTH.
		es     = segment containing VisTextClass.
		cx     = new maximum length.
RETURN:		nothing
DESTROYED:	all (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetMaxLength	method dynamic	VisTextClass, MSG_VIS_TEXT_SET_MAX_LENGTH
EC <	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE		>
EC <	ERROR_NZ CAN_NOT_SET_MAX_LENGTH_FOR_LARGE_TEXT_OBJECT		>

	call	TextGStateCreate

	cmp	cx, ds:[di].VTI_maxLength	; if raising the limit, then
	jae	setMax				;    just set it.

	;
	; Lowering the limit we might have to clip off some text
	; at the end of the object. Check to see if the new max length is
	; less than the current size. If it is we can just set it.
	;
	call	TS_GetTextSize			; dx.ax <- size of text
	;
	; Since this can't be a large text object (or we would have generated
	; a fatal-error above) the high word must be zero. This means we can
	; treat ax as the size.
	;

	cmp	cx, ax				; if above amount entered then
	jae	setMax				;    Just set it.

	;
	; We must trim something from the text in order to make it fit in the
	; new maximum size.
	;
	; Save the current selection, so we can restore it below (if it still
	; falls into the valid range).
	;
	; cx	= New maximum size
	; ax	= Text object size
	;
	call	EditUnHilite			; Remove old selection.
	push	di				; Save object's offset
	push	cx				; Save new size twice.
	push	cx

	sub	sp, size VisTextReplaceParameters
	mov	bp, sp
	mov	ss:[bp].VTRP_range.VTR_start.low, cx
	mov	ss:[bp].VTRP_range.VTR_start.high, 0

	mov	ss:[bp].VTRP_range.VTR_end.low, ax
	mov	ss:[bp].VTRP_range.VTR_end.high, 0
	mov	ss:[bp].VTRP_flags, 0

	clrdw	ss:[bp].VTRP_insCount		; Nothing to insert.

	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock		; Do the replace.
	add	sp, size VisTextReplaceParameters

	pop	di				; di <- new maximum size

	call	TSL_SelectGetSelection		; dx.ax <- selection start
						; cx.bx <- selection end
	;
	; di	= New maximum size of the text
	; dx.ax	= Selection start
	; cx.bx	= Selection end
	;
	; Since this is a small text object both dx and cx must be zero.
	;
	cmp	ax, di				; Check for start too large
	jbe	startOK
	mov	ax, di				; start <- max offset
startOK:

	cmp	bx, di				; Check for end too large
	jbe	endOK
	mov	bx, di				; end <- max offset
endOK:

	;
	; dx.ax	= Adjusted select start
	; cx.bx	= Adjusted select end
	;
	call	TSL_SelectSetSelection

	;
	; Now that the selection is fixed up, display the selection.
	;
	call	EditHilite
	pop	cx				; Recover new max text size.
	pop	di				; Recover object's offset.

setMax:
	mov	ds:[di].VTI_maxLength, cx	; Save new length
	call	TextGStateDestroy
	call	SendGenericUpdate		;Update generic data
	ret
VisTextSetMaxLength	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetMaxLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum number of characters allowed in this text
		object.

CALLED BY:	via MSG_VIS_TEXT_GET_MAX_LENGTH.
PASS:		ds:*si	= instance ptr
		es	= class segment.
		ax	= MSG_VIS_TEXT_GET_MAX_LENGTH.
RETURN:		cx	= max # of characters allowed in this object.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 9/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetMaxLength	method dynamic	VisTextClass, MSG_VIS_TEXT_GET_MAX_LENGTH
	mov	cx, ds:[di].VTI_maxLength	; cx <- max # of characters.
	ret
VisTextGetMaxLength	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection start.

CALLED BY:	MSG_VIS_TEXT_GET_SELECTION_START
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #
RETURN:		dx.cx	= Selection start
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionStart	method dynamic VisTextClass, 
					MSG_VIS_TEXT_GET_SELECTION_START
		.enter
		movdw	dxcx, ds:[di].VTI_selectStart
		.leave
		ret
VisTextGetSelectionStart	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the gstate.

CALLED BY:	MSG_VIS_TEXT_GET_GSTATE
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #
RETURN:		cx	= gstate
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	10/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetGState	method dynamic VisTextClass, 
					MSG_VIS_TEXT_GET_GSTATE
		.enter
		mov	cx, ds:[di].VTI_gstate
		.leave
		ret
VisTextGetGState	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextGetTextSize -- MSG_VIS_TEXT_GET_TEXT_SIZE
							for VisTextClass

DESCRIPTION:	Get the size of the text

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

RETURN:
	dxax - text size

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/10/92		Initial version

------------------------------------------------------------------------------@
VisTextGetTextSize	method dynamic	VisTextClass, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	TS_GetTextSize		; dx.ax <- size of text.
	ret

VisTextGetTextSize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextSetNotUserModified --
		MSG_VIS_TEXT_SET_NOT_USER_MODIFIED for VisTextClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

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
	Tony	7/29/92		Initial version

------------------------------------------------------------------------------@
VisTextSetNotUserModified	method dynamic	VisTextClass,
					MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	andnf	ds:[di].VTI_state, not mask VTS_USER_MODIFIED
	ret

VisTextSetNotUserModified	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextSetUserModified --
		MSG_VIS_TEXT_SET_USER_MODIFIED for VisTextClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

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
	Tony	7/29/92		Initial version

------------------------------------------------------------------------------@
VisTextSetUserModified	method dynamic	VisTextClass,
					MSG_VIS_TEXT_SET_USER_MODIFIED
	ornf	ds:[di].VTI_state, mask VTS_USER_MODIFIED
	ret

VisTextSetUserModified	endm

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextGetTextState -- MSG_VIS_TEXT_GET_STATE for VisTextClass

DESCRIPTION:	Get the VTI_state field

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

RETURN:
	cl - VTI_state (VisTextStates)

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@
VisTextGetState	method dynamic	VisTextClass, MSG_VIS_TEXT_GET_STATE
	mov	cl,ds:[di].VTI_state
	Destroy	ax, ch, dx, bp
	ret

VisTextGetState	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextGetUserModifiedState --
		MSG_VIS_TEXT_GET_USER_MODIFIED_STATE for VisTextClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

RETURN:
	cx - non-zero if user-modified

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/29/92		Initial version

------------------------------------------------------------------------------@
VisTextGetUserModifiedState	method dynamic	VisTextClass,
					MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	cl, ds:[di].VTI_state
	and	cx, mask VTS_USER_MODIFIED
	ret

VisTextGetUserModifiedState	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the VTI_features bits

CALLED BY:	GLOBAL
PASS:		ds:di - VisTextInstance data
RETURN:		cx - VisTextFeatures
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetFeatures	method	dynamic VisTextClass, MSG_VIS_TEXT_GET_FEATURES
	.enter
	mov	cx, ds:[di].VTI_features
	Destroy	ax, dx, bp
	.leave
	ret
VisTextGetFeatures	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the VTI_features bits

CALLED BY:	GLOBAL
PASS:		ds:di - VisTextInstance data
		cx - bits to set
		dx - bits to clear
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetFeatures	method	dynamic VisTextClass, MSG_VIS_TEXT_SET_FEATURES
	.enter
EC <	test	cx, not mask VisTextFeatures				>
EC <	ERROR_NZ	BAD_VIS_TEXT_FEATURES				>
EC <	test	dx, not mask VisTextFeatures				>
EC <	ERROR_NZ	BAD_VIS_TEXT_FEATURES				>
	or	ds:[di].VTI_features, cx
	not	dx
	and	ds:[di].VTI_features, dx
	Destroy	ax, cx, bp
	.leave
	ret
VisTextSetFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetMinimumDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the minimum dimensions of an object that has valid bounds
		and which has already been calculated.

CALLED BY:	via MSG_VIS_TEXT_GET_MINIMUM_DIMENSIONS
PASS:		*ds:si	= Instance
		ds:di	= Instance
		dx:bp	= VisTextMinimumDimensionsParameters to fill in
RETURN:		Parameters filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetMinimumDimensions	method	dynamic VisTextClass,
				MSG_VIS_TEXT_GET_MINIMUM_DIMENSIONS
	uses	ax, cx, dx
	.enter
	mov	es, dx			; es:bp <- ptr to structure
	
	;
	; Figure the height:
	;	textHeight + (2 * tbMargin)
	;
	clr	cx
	mov	cl, ds:[di].VTI_tbMargin
	shl	cx, 1

	movwbf	dxal, ds:[di].VTI_height
	add	dx, cx
	movwbf	es:[bp].VTMDP_height, dxal
	
	;
	; Figure the minimum width...
	;
	clr	cx
	mov	cl, ds:[di].VTI_lrMargin
	shl	cx, 1

	call	TL_LineFindMaxWidth	; dx.al <- width of widest line
	add	dx, cx
	movwbf	es:[bp].VTMDP_width, dxal

	.leave
	ret
VisTextGetMinimumDimensions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextModifyEditableSelectable --
		MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE for VisTextClass

DESCRIPTION:	Modify the editable and/or selectable state of the object

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cl - VisTextStates to set
	ch - VisTextStates to clear

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
VisTextModifyEditableSelectable	method dynamic	VisTextClass,
					MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE

	; Check if we are making the field not editable because we need to
	; mess with the cursor.
	test	ch, mask VTS_EDITABLE
	jnz	clearingEditable
	
setTheBits:
	not	ch
	and	ds:[di].VTI_state, ch
	or	ds:[di].VTI_state, cl

;	If we have the focus, and are becoming editable, then send out the
;	GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS notification.

	test	cl, mask VTS_EDITABLE
	jz	sendStandardNotifications
	
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	sendStandardNotifications

	; Start the cursor flashing in case the timer isn't already running.
	; (Needs *ds:di set to instance data)
    	call	TSL_StartCursorCommon
	
	mov	bp, mask TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	call	SendTextFocusNotification

sendStandardNotifications:
	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification

	ret

clearingEditable:
	; If we are setting the text object NOT editable, then stop the
	; cursor from blinking.
	
	; This also will disable the timer, indirectly, since the FLASH_ON/OFF
	; message handlers will not continue the timer if the object is not
	; editable.
	
	; We are already not editable, so skip this whole shme..
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	setTheBits
	
	mov	al, ds:[di].VTI_intSelFlags
	
	; Make sure that we are the focus, the cursor is enabled, and the image
	; is actually drawn "on" or else we shouldn't mess with it.
	and	al, mask VTISF_IS_FOCUS or \
		    mask VTISF_CURSOR_ENABLED or \
		    mask VTISF_CURSOR_ON
	cmp	al, mask VTISF_IS_FOCUS or \
		    mask VTISF_CURSOR_ENABLED or \
		    mask VTISF_CURSOR_ON
	jne	setTheBits
	
	; Make sure we can draw (we already know that we editable)
	call	TextCheckCanDraw
	jc	setTheBits
		    
	clr	bx			;Don't draw a cursor if someone has
	call	GrGetExclusive		; the exclusive (like, if someone is
	tst	bx			; drawing ink)
	jnz	setTheBits

	push	cx
	call	CursorToggle
	pop	cx
	
	call	TextInstance_DerefVis_DI
	
	; Turn off the cursor_on bit
	andnf	ds:[di].VTI_intSelFlags, not mask VTISF_CURSOR_ON
	
	jmp	setTheBits

VisTextModifyEditableSelectable	endm

TextInstance ends
