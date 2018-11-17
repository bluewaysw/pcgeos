COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tslMethodMouse.asm

AUTHOR:		John Wedgwood, Dec  6, 1991

ROUTINES:
	Name			Description
	----			-----------
	MSG_META_START_SELECT	Handle start-select event
	MSG_META_DRAG_SELECT	Handle drag-select event
	MSG_META_END_SELECT	Handle end-select event
	MSG_META_PTR		Handle ptr movement event
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/ 6/91	Initial revision

DESCRIPTION:
	Mouse event handlers.

	$Id: tslMethodMouse.asm,v 1.1 97/04/07 11:20:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPtrImageAndMouseFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns an optr to a cursor image and appropriate mouse
		return flags for drawing it.

CALLED BY:	GLOBAL
PASS:		ds - object block with VisText object
RETURN:		cx:dx - ptr to cursor image
		ax - appopriate MouseReturnFlags
DESTROYED:	bx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPtrImageAndMouseFlags	proc	far
	.enter
	;
	; Get the cursor to display.
	;
	clr	bx
	call	GeodeGetUIData		; bx = specific UI
	mov	ax, SPIR_GET_TEXT_POINTER_IMAGE
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable	;cxdx = cursor image

	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
	.leave
	ret
GetPtrImageAndMouseFlags	endp

TextFixed ends

TextSelect segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle button presses...

CALLED BY:	External (MSG_META_START_SELECT)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= x position of event
		dx	= y position of event
		bp	= UIFunctionsActive flags.
RETURN:		ax	= MRF_PROCESSED always
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextStartSelect	proc	far	; MSG_META_START_SELECT

	;
	; need to clear up any characters that are displaying the mode
	; of the HWR Library. If we do not clean up the characters
	; now, the macro will get finished at a different selection
	; point and there will be leftover characters at this point.
	;	
	call 	AbortHWRMacro

	mov	bx, bp			; bx <- UIFunctionsActive flags
	sub	sp, size LargeMouseData	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- stack frame
	
	;
	; Initialize the structure
	;
	call	InitLargeMouseStructure

	;
	; Call the large-mouse handler
	;
	call	VisTextLargeStartSelect
	
	add	sp, size LargeMouseData	; Restore stack
quit::
	ret
VisTextStartSelect	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	InitLargeMouseStructure

DESCRIPTION:	Initialize a large mouse data structure

CALLED BY:	INTERNAL

PASS:
	ss:bp - LargeMouseData
	cx - x position of event
	dx - y position of event
	bx - UIFunctionsActive flags.

RETURN:

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/26/92		Initial version

------------------------------------------------------------------------------@
InitLargeMouseStructure	proc	far
	
	;
	; Initialize the structure
	;
	mov_tr	ax, dx
	cwd
	movdw	ss:[bp].LMD_location.PDF_y.DWF_int, dxax
	mov	ss:[bp].LMD_location.PDF_y.DWF_frac, 0

	mov_tr	ax, cx
	cwd
	movdw	ss:[bp].LMD_location.PDF_x.DWF_int, dxax
	mov	ss:[bp].LMD_location.PDF_x.DWF_frac, 0

	mov	ss:[bp].LMD_buttonInfo, bl
	mov	ss:[bp].LMD_uiFunctionsActive, bh

	ret

InitLargeMouseStructure	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLargeStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a large mouse event.

CALLED BY:	via MSG_META_LARGE_START_SELECT and VisTextStartSelect
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= LargeMouseData
RETURN:		ax	= MouseReturnFlags
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLargeStartSelect		proc	far	; MSG_META_LARGE_START_SELECT
	class	VisTextClass
	call	TextGStateCreate		; Make a gstate

	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jz	processed			; quit if not selectable.
	
	;
	; For single-line objects, we really want the event to appear to be
	; somewhere in the line so that a click above or below the text won't
	; turn into an event at the start or end of the text.
	;
	call	AdjustEventForSingleLineObject


	;
	; Make sure that the event really does fall in a region.
	;
	call	TR_RegionFromPoint		; cx <- region
						; ax/dx destroyed
	cmp	cx, CA_NULL_ELEMENT
	LONG je	replay

	;
	; Mark that we are doing a selection and grab the focus, target, and
	; gadget exclusive.
	;
	ornf	ds:[di].VTI_intSelFlags, mask VTISF_DOING_SELECTION
	call	TextTakeGadgetExclAndGrab
	
	call	TextMakeFocusAndTarget

	call	ComputeEventPositionAndOffset
	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; dx.ax	= Offset into text where event happened
	; cx	= Region in which event occurred
	; VTI_startEventPos = position of original selection event
	; ss:bp	= LargeMouseData
	;

	;
	; Now handle the event appropriately
	;
	mov	di, cx				; di <- region of event
	mov	cx, offset cs:StartSelectNoAdjust
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_ADJUST or \
					       mask UIFA_EXTEND
	jz	gotRoutine
	mov	cx, offset cs:StartSelectAdjust
gotRoutine:
	
	;
	; *ds:si= Instance ptr
	; di	= Region in which the event occurred
	; dx.ax	= Offset into text where event happened
	; cx	= Routine to handle the start-select event
	; VTI_startEventPos = position of original selection event
	; ss:bp	= LargeMouseData
	;
	mov	bl, ss:[bp].LMD_buttonInfo	; bl <- ButtonInfo

	push	cs
	call	cx				; Call the handling routine
						;Returns CX non-zero if we
						; released the mouse.

processed:
	call	TextGStateDestroy
	call	CheckForInk
	tst	ax
	mov	ax, mask MRF_PROCESSED
	jne	doPenStuff
exit:
	ret


replay:
	call	TextGStateDestroy
	mov	ax, mask MRF_REPLAY
	jmp	exit


doPenStuff:
	tst	cx				;If we released the mouse, 
	jne	exit				; branch
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	
	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	je	exit
	call	GetPtrImageAndMouseFlags
	jmp	exit
VisTextLargeStartSelect	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextTakeGadgetExclAndGrab

DESCRIPTION:	Grab the gadget exclusive and grab the mouse (requesting large
		pointer exents)

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/18/92		Initial version

------------------------------------------------------------------------------@
TextTakeGadgetExclAndGrab	proc	far
EC <	call	T_AssertIsVisText					>
	push	ax, cx, dx, bp
	mov	cx, ds:[LMBH_handle]		;^lcx:dx = object to grab for
	mov	dx, si
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent
	pop	ax, cx, dx, bp
	call	VisGrabLargeMouse
	ret

TextTakeGadgetExclAndGrab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSelectNoAdjust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a start-select event with no adjustment

CALLED BY:	VisTextStartSelect
PASS:		*ds:si	= Instance ptr
		di	= Region where event occurred
		dx.ax	= Offset into the text where the event occurred
		VTI_startEventPos set
		ss:bp	= PointDWFixed where event occurred
		bl	= ButtonInfo
RETURN:		cx = non-zero if we released the mouse
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	**
	** If it's a multiple click event we want to increment the selection
	** mode to go from char->word->line->paragraph selection.
	**
	mode = VTI-selectMode
	If (multi-click event) {
	    mode++
	} else {
	    mode = charSelection
	}
	
	**
	** If the selection mode has gone beyond paragraph selection we want
	** to select the whole object and release the mouse
	**
	if (mode > paraSelection) {
	    VTI-selectMode = charSelection
	    range = 0, textEnd
	    Select(range)
	    VTI-adjustPos = range.end
	    VTI-minRange = 0,0
	} else {
	    **
	    ** Normal selection
	    **
	    VTI-selectMode = mode
	    VTI-adjustPos = eventOffset
	    minRange = AdjustByMode(eventOffset, eventPos)
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartSelectNoAdjust	proc	far
	class	VisTextClass
	uses	bx
	.enter
	
	;
	; Save the new selection mode if it is a multiple press.
	; We will be using cl to hold the new selection mode.
	;
	clr	cl				; Assume single click

	test	bl, mask BI_DOUBLE_PRESS
	jnz	incrementSelectionMode		; Branch if multiple clicks
	
	;
	; It's a single press which means we just want to position the
	; cursor.
	;
	call	SelectCursor			; Position the cursor...
	jmp	clrCXquit			; And quit

incrementSelectionMode:
	;
	; Assume that we are incrementing the selection mode.
	;
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	mov	cl, ds:[di].VTI_intSelFlags
	and	cl, mask VTISF_SELECTION_TYPE
	add	cl, 1 shl offset VTISF_SELECTION_TYPE
	and	cl, mask VTISF_SELECTION_TYPE


	and	ds:[di].VTI_intSelFlags, not mask VTISF_SELECTION_TYPE
	or	ds:[di].VTI_intSelFlags, cl

	;
	; If we have wrapped around to character selection then we want to
	; select the entire object.
	;
	tst	cl				; Check for char selection
	jnz	selectByMode			; Branch if not
	
	;
	; OK... We want to select the entire object and release the mouse
	;
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	ObjCallInstanceNoLock

	call	VisReleaseMouse
	
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	and	ds:[di].VTI_intSelFlags, not (mask VTISF_DOING_SELECTION or \
					      mask VTISF_DOING_DRAG_SELECTION)

	mov	cx, TRUE
	jmp	quit

selectByMode:
	;
	; The selection mode has changed.
	;
	; We want to set the selection to the correct range.
	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; dx.ax	= Offset into text where event occurred
	; VTI_startEventPos is set
	; 
	movdw	cxbx, dxax			; dxax/cxbx <- range to extend
	stc					; Signal: do set minimum range
	call	SelectRangeByMode		; Select the range appropriately
clrCXquit:
	clr	cx
quit:
	.leave
	ret
StartSelectNoAdjust	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the cursor.

CALLED BY:	StartSelectNoAdjust
PASS:		*ds:si	= Instance ptr
		di	= Region where event occurred
		VTI_startEventPos must be set
		dx.ax	= Offset into text where the event occurred
		ss:bp	= PointDWFixed where event occurred
RETURN:		VTI_cursorRegion set
		VTI_cursorPos	 set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectCursor	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter
	push	di				; Save region of event

	;
	; Remove the old selection.
	;
	call	EditUnHilite

	;
	; Force the selection type back to character level selection.
	;
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	and	ds:[di].VTI_intSelFlags, not mask VTISF_SELECTION_TYPE

	;
	; It's not a multiple click event and we aren't adjusting the selection.
	; This means that we are just positioning the cursor. Set the minimum
	; selection
	;
	movdw	ds:[di].VTI_selectMinStart, dxax
	movdw	ds:[di].VTI_selectMinEnd, dxax
	movdw	cxbx, dxax			; cx.bx <- select end
	call	TSL_SelectSetSelection		; Set select start/end to dx.ax

	;
	; Copy the current event position as the start position.
	;
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	movdw	ds:[di].VTI_startEventPos.PD_x, \
		ss:[bp].PDF_x.DWF_int, ax

	movdw	ds:[di].VTI_startEventPos.PD_y, \
		ss:[bp].PDF_y.DWF_int, ax

	pop	cx				; cx <- region of event
	
	;
	; Convert the event position into something relative to the region.
	;
	call	ConvertToRelativePosition	; ax <- Relative X position
						; dx <- Relative Y position
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	notSmall
	clr	cx				; force small objects to be in
						; the first region
notSmall:
	call	CursorForceOn			; Force visible
	call	TSL_CursorPosition		; Position cursor at cx, ax, dx
	call	TSL_DrawOverstrikeModeHilite	; Draw overstrike cursor
	.leave
	ret
SelectCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToRelativePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a position into one relative to a region.

CALLED BY:	SelectCursor
PASS:		*ds:si	= Instance
		cx	= Region
		ss:bp	= PointDWFixed containing event
RETURN:		ax	= Relative X position
		dx	= Relative Y position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertToRelativePosition	proc	near
	uses	bx, cx, bp
	.enter
	;
	; Save the pointer to the event position and get the top-left corner
	; of the region.
	;
	mov	bx, bp				; ss:bx <- ptr to event pos

	sub	sp, size PointDWord		; Allocate space for region pos
	mov	bp, sp				; ss:bp <- ptr to point
	call	TR_RegionGetTopLeft		; Get region top left
	
	;
	; Figure the relative offsets.
	;
	movdw	dxax, ss:[bx].PDF_x.DWF_int	; dx.ax <- event position
	subdw	dxax, ss:[bp].PD_x		; dx.ax <- relative position
	tst	dx				; Check for > 64K
	jle	gotRelativeX			; Branch if negative or zero
	mov	ax, 0x3fff			; Use something large if it is
gotRelativeX:
	
	movdw	cxdx, ss:[bx].PDF_y.DWF_int	; cx.dx <- event position
	subdw	cxdx, ss:[bp].PD_y		; cx.dx <- relative position
	tst	cx				; Check for > 64K
	jle	gotRelativeY			; Branch if negative or zero
	mov	dx, 0x3fff			; Use something large if it is
gotRelativeY:
	
	add	sp, size PointDWord		; Restore stack

	;
	; ax	= Relative X position
	; dx	= Relative Y position
	;
	.leave
	ret
ConvertToRelativePosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectRangeByMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a range based on the selection mode.

CALLED BY:	StartSelectNoAdjust
PASS:		*ds:si	= Instance ptr
		dx.ax	= Fixed position
		cx.bx	= Adjustable position
		VTI_startEventPos set
		ss:bp	= PointDWFixed
		carry set if caller wants VTI_selectMinStart/End set
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectRangeByMode	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter
	pushf					; Save "set-minimum" flag (carry)
	push	bx				; Save argument

	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	ExtractField	byte, ds:[di].VTI_intSelFlags, VTISF_SELECTION_TYPE, bl
	clr	bh
	shl	bx, 1				; Use as index into table
	mov	di, bx				; di <- offset into table

	pop	bx				; Restore argument
	popf					; Get "set-minimum" flag (carry)

	;
	; *ds:si= Instance ptr
	; di	= Offset into table of handlers
	; dx.ax	= Fixed position
	; cx.bx	= Adjustable position
	; VTI_startEventPos set
	; current event on stack as PointDWord
	; carry set if caller wants VTI_selectMinStart/End set
	;
	jnc	callSelectHandler
	
	;
	; Update the minimum selection.
	;
	push	ax, bx, cx, dx, di		; Save parameters, handler
	call	cs:setMinimumHandlers[di]	; Call the handler
	
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	movdw	ds:[di].VTI_selectMinStart, dxax
	movdw	ds:[di].VTI_selectMinEnd, cxbx
	pop	ax, bx, cx, dx, di		; Restore parameters, handler

callSelectHandler:
	call	cs:selectByModeHandlers[di]	; Call the handler
	push	bp
	mov	bp, di				; bp=SelectionType * 2
	
	;
	; Update the selected area.
	;
	; dx.ax = fixed position
	; cx.bx	= adjustable position
	;
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr

	call	IncludeMinimumSelection		; Force to a reasonable size
	;
	; check to if it is line selection, if it is call
	; AdjustForLastChar to adjust the range if the last char is a
	; page break or a section break.
	;
	cmp	bp, ST_DOING_LINE_SELECTION*2
	jne 	doNotAdjust
	call	AdjustForLastChar
doNotAdjust:
	pop	bp
	call	UpdateSelectedArea		; Set new selection
	.leave
	ret
SelectRangeByMode	endp

setMinimumHandlers	label	word
	word	offset cs:SetMinSelectionChar	; ST_DOING_CHAR_SELECTION
	word	offset cs:SetMinSelectionWord	; ST_DOING_WORD_SELECTION
	word	offset cs:SetMinSelectionLine	; ST_DOING_LINE_SELECTION
	word	offset cs:SetMinSelectionPara	; ST_DOING_PARA_SELECTION

selectByModeHandlers	label	word
	word	offset cs:SelectByModeChar	; ST_DOING_CHAR_SELECTION
	word	offset cs:SelectByModeWord	; ST_DOING_WORD_SELECTION
	word	offset cs:SelectByModeLine	; ST_DOING_LINE_SELECTION
	word	offset cs:SelectByModePara	; ST_DOING_PARA_SELECTION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMinSelectionChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the minimum selection appropriate for character selection.

CALLED BY:	SelectRangeByMode via setMinimumHandlers
PASS:		*ds:si	= Instance ptr
		dx.ax	= Fixed position
RETURN:		dx.ax	= Start of minimum selection
		cx.bx	= End of minimum selection
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMinSelectionChar	proc	near
	movdw	cxbx, dxax			; minimum range is at dxax
	ret
SetMinSelectionChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMinSelectionWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the minimum selection appropriate for word selection.

CALLED BY:	SelectRangeByMode via setMinimumHandlers
PASS:		*ds:si	= Instance ptr
		dx.ax	= Fixed position
RETURN:		dx.ax	= Start of minimum selection
		cx.bx	= End of minimum selection
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMinSelectionWord	proc	near
	movdw	cxbx, dxax			; cx.bx <- adjustable pos
	call	SelectByModeWord		; dx.ax <- new fixed pos
						; cx.bx <- adjust pos
	
	cmpdw	dxax, cxbx			; Order the range
	jbe	rangeOK				; Branch if already ordered
	xchgdw	dxax, cxbx			; Swap the order
rangeOK:
	ret
SetMinSelectionWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMinSelectionLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the minimum selection appropriate for line selection.

CALLED BY:	SelectRangeByMode via setMinimumHandlers
PASS:		*ds:si	= Instance ptr
		VTI_startEventPos set
RETURN:		dx.ax	= Start of minimum selection
		cx.bx	= End of minimum selection
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMinSelectionLine	proc	near
	class	VisTextClass
	uses	di
	.enter
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	movdw	dxax, ds:[di].VTI_startEventPos.PD_x
	movdw	cxbx, ds:[di].VTI_startEventPos.PD_y
	call	LineUnderPosition		; dx.ax <- line start
						; cx.bx <- line end
	.leave
	ret
SetMinSelectionLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMinSelectionPara
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the minimum selection appropriate for paragraph selection.

CALLED BY:	SelectRangeByMode via setMinimumHandlers
PASS:		*ds:si	= Instance ptr
		dx.ax	= Fixed position
RETURN:		dx.ax	= Start of minimum selection
		cx.bx	= End of minimum selection
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMinSelectionPara	proc	near
	call	ParagraphUnderPoint		; dx.ax <- para start
						; cx.bx <- para end
	ret
SetMinSelectionPara	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectByModeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a range between two character offsets.

CALLED BY:	SelectRangeByMode via selectByModeHandlers
PASS:		*ds:si	= Instance ptr
		dx.ax	= Fixed position
		cx.bx	= Adjustable position
RETURN:		dx.ax	= New fixed position
		cx.bx	= New adjustable position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectByModeChar	proc	near
	;
	; Do nothing
	;
	ret
SelectByModeChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectByModeWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do word selection between two character offsets.

CALLED BY:	SelectRangeByMode via selectByModeHandlers
PASS:		*ds:si	= Instance ptr
		dx.ax	= Fixed position
		cx.bx	= Adjustable position
RETURN:		dx.ax	= New fixed position
		cx.bx	= New adjustable position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (fixed < adjustable) {
	    fixed      = PrevWordStart(fixed)
	    adjustable = NextWordStart(adjustable)
	} else {
	    fixed      = NextWordStart(fixed)
	    adjustable = PrevWordStart(adjustable)
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectByModeWordFar	proc	far
	call	SelectByModeWord
	ret
SelectByModeWordFar	endp

SelectByModeWord	proc	near
	class	VisTextClass
	.enter
	cmpdw	dxax, cxbx			; Compare fixed/adjustable
	je	specialSelect			; Branch if at same place
	ja	fixedGreater

standardSelect:
	;
	; Adjust the fixed offset backwards to a word edge.
	; Adjust the movable offset forward to a word edge.
	;
	call	FindWordEdgeBackwards		; dx.ax <- previous word edge
	call	FindWordEdgeForwardsCXBX	; cx.bx <- next word edge

	jmp	quit

fixedGreater:
	;
	; Adjust the movable offset backwards to a word edge.
	; Adjust the fixed offset forward to a word edge.
	;
	call	FindWordEdgeBackwardsCXBX	; cx.bx <- previous word edge
	call	FindWordEdgeForwards		; dx.ax <- next word edge

quit:
	.leave
	ret


specialSelect:
	;
	; When we are doing a word-select and the current selection is a cursor
	; then we want to do something special...
	;
	; If the current position is a word-edge and if the word-edge is to
	; the left then we want to select the word to our left. If the word
	; edge is to our right then we want to select the edge to our right.
	;
	call	IsWordEdge			; Check position in dx.ax
	jnc	standardSelect			; Branch if not word edge
	jz	selectRight
	
	;
	; Select the word to the left.
	;
	call	FindPreviousWordEdge		; dx.ax <- previous word edge
						; (which is new fixed position)
	jmp	quit

selectRight:
	;
	; Select the word to the right.
	;
	call	FindNextWordEdge		; dx.ax <- next word edge
	xchgdw	dxax, cxbx			; cx.bx <- next word edge
						; dx.ax <- start of word
	jmp	quit
SelectByModeWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectByModeLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a range of lines.

CALLED BY:	StartSelectNoAdjust
PASS:		*ds:si	= Instance ptr
		VTI_startEventPos set
		ss:bp	= PointDWFixed where event occurred
RETURN:		dx.ax	= Start of range to select
		cx.bx	= End of range to select
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectByModeLine	proc	near
	class	VisTextClass
	uses	di, si, bp
	.enter
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr

	;
	; Compute start/end of line for starting event.
	;
	movdw	dxax, ds:[di].VTI_startEventPos.PD_x
	movdw	cxbx, ds:[di].VTI_startEventPos.PD_y
	call	LineUnderPosition		; dx.ax <- start of range
						; cx.bx <- end of range

	pushdw	cxbx				; Save end of line
	pushdw	dxax				; Save start of line

	;
	; Compute start/end of line for current event.
	;
	movdw	dxax, ss:[bp].PDF_x.DWF_int
	movdw	cxbx, ss:[bp].PDF_y.DWF_int
	call	LineUnderPosition		; dx.ax <- start of cur-line
						; cx.bx <- end of cur-line
	
	;
	; Assume that the start of the start-event is the fixed position.
	;
	clr	si				; Use si as the signal

	;
	; Use the smallest line-start as the start of the selection.
	;
	popdw	dibp				; di.bp <- startRange.start
	cmpdw	dxax, dibp			; Use the larger
	jbe	gotStart
	
	;
	;   +--cur---+
	;	+--orig--+
	; The current event start is less than the original event start.
	; This means that the start of the final selection is the adjustable
	; position. We need to signal this.
	;
	movdw	dxax, dibp
	mov	si, 1				; Signal: end is fixed
gotStart:

	;
	; Use the largest line-end as the end of the selection.
	;
	popdw	dibp				; di.bp <- startRange.end
	cmpdw	cxbx, dibp			; Use the larger
	jae	gotEnd
	
	;
	;           +--cur---+
	;	+--orig--+
	; The current event end is less than the original event end. This means
	; that the fixed position of the selection is at the end of the original
	; event. We need to signal this.
	;
	movdw	cxbx, dibp
	clr	si				; Signal: start is fixed
gotEnd:

	;
	; dx.ax	= Start of selected range
	; cx.bx	= End of selected range
	;
	; Now we need to figure out which of these should be the fixed point.
	;
	; If the carry is set, then the start of the range is the fixed point.
	;
	tst	si				; Check which is fixed
	jz	quit
	xchgdw	dxax, cxbx			; dx.ax <- fixed position
						; cx.bx <- adjustable position
quit:
	;
	; dx.ax	= Fixed position of range
	; cx.bx	= Adjustable position of range
	;
	.leave
	ret

SelectByModeLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the last char of the selected range is a section
		break or a page break the the end of the range is
		decremented by one

CALLED BY:	(PRIVATE) SelectRangeByMode
PASS:		*ds:si	= Instance ptr
		dx.ax	= Start of range
		cx.bx	= End of range 
RETURN:		cx.bx	= End of range, adjusted
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	7/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustForLastChar	proc	near
lastCharRange	local	VisTextRange
lastCharRef	local	TextReference
lastChar	local	word			;enough room for dbcs
	uses	si,di,bp
	.enter
	cmpdw	dxax,cxbx
	je 	exit				; no last char to check
	;
	; copy the last char to lastChar
	;
	pushdw	cxbx
	movdw	ss:[lastCharRange].VTR_end, cxbx
	decdw	cxbx
	movdw	ss:[lastCharRange].VTR_start, cxbx
	mov	ss:[lastCharRef].TR_type, TRT_POINTER
	mov	ss:[lastCharRef].TR_ref.TRU_pointer.TRP_pointer.segment, ss
	lea	di, ss:[lastChar]
	mov	ss:[lastCharRef].TR_ref.TRU_pointer.TRP_pointer.offset, di
	pushdw	dxax
	push	bp
	lea	bx, ss:[lastCharRange]
	lea	bp, ss:[lastCharRef]		
	call	TS_GetTextRange
	pop	bp
	popdw	dxax
	popdw	cxbx
	;
	; check to see if the last char is a section_brk or a page
	; break
	;
	cmp	ss:[lastChar], C_SECTION_BREAK
	je	decAndExit
	cmp	ss:[lastChar], C_PAGE_BREAK
	je	decAndExit	
exit:
	.leave
	ret
decAndExit:
	decdw	cxbx
	jmp	exit	

AdjustForLastChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectByModePara
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do paragraph selection between two character offsets.

CALLED BY:	SelectRangeByMode via selectByModeHandlers
PASS:		*ds:si	= Instance ptr
		dx.ax	= Fixed position
		cx.bx	= Adjustable position
RETURN:		dx.ax	= Start of range to select
		cx.bx	= End of range to select
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (fixed <= adjustable) {
	    fixed  = ParaStart(fixed)
	    adjust = ParaEnd(adjust)
	} else {
	    adjust = ParaStart(adjust)
	    fixed  = ParaEnd(fixed)
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectByModePara	proc	near
	class	VisTextClass
	.enter
	cmpdw	dxax, cxbx			; Compare fixed/adjust
	ja	fixedGreater
	
	;
	; The fixed address is less than the movable one.
	;	fixed  <- PrevParaStart(fixed)
	;	adjust <- NextParaEnd(adjust)
	;
	call	FindParagraphEdgeBackwards	; dx.ax <- new fixed value
	call	FindParagraphEdgeForwardsCXBX	; cx.bx <- new adjustable value

	jmp	quit

fixedGreater:
	;
	; The fixed address is greater than the movable one.
	;	adjust <- PrevParaStart(adjust)
	;	fixed  <- NextParaEnd(fixed)
	;
	call	FindParagraphEdgeBackwardsCXBX	; cx.bx <- new adjustable value
	call	FindParagraphEdgeForwards	; dx.ax <- new fixed value

quit:
	.leave
	ret
SelectByModePara	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSelectAdjust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a start-select event with the adjust modifier.

CALLED BY:	VisTextStartSelect
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		dx.ax	= Offset into text where event happened
		VTI_startEventPos set
		ss:bp	= PointDWFixed
		carry set to set the minimum selection
RETURN:		cx = 0, signifying that we did not release the mouse
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartSelectAdjust	proc	far
	class	VisTextClass
	uses	ax, bx, dx
	.enter
	pushf					; Save "set minimum" flag
	;
	; We want to load up the fixed position and pass it along with the
	; new event position to the select-by-mode routine.
	;
	pushdw	dxax				; Save adjustable position
	call	TSL_SelectGetSelection		; dx.ax <- start
						; cx.bx <- end
	;
	; Figure which of the start or end is the fixed position. We do this
	; by identifying which is the adjustable position and choosing the
	; other.
	;
	stc					; Adjusting forward
	call	SelectGetFixedPosition		; dx.ax <- fixed position

	popdw	cxbx				; Restore adjustable position
	popf					; Restore "set minimum" flag
	call	SelectRangeByMode		; Select the range
	clr	cx
	.leave
	ret
StartSelectAdjust	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLargeDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the MSG_META_LARGE_DRAG_SELECT method.

CALLED BY:	via MSG_META_DRAG_SELECT.
PASS:		*ds:si	= Instance
		ds:di	= Instance
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLargeDragSelect	proc	far	; MSG_META_LARGE_DRAG_SELECT
	class	VisTextClass
	or	ds:[di].VTI_intSelFlags, mask VTISF_DOING_DRAG_SELECTION
	mov	ax, mask MRF_PROCESSED
	ret
VisTextLargeDragSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLargeEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle button releases...

CALLED BY:	VisTextClose, VisTextReplaceSelection, VisTextSetText
PASS:		*ds:si	= Instance ptr
		ss:bp	= LargeMouseData
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLargeEndSelect	proc	far		; MSG_META_LARGE_END_SELECT
	class	VisTextClass

	call	TextGStateCreate
	call	TextSelect_DerefVis_DI
	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_SELECTION
	je	done				; quit if not doing selection.

	;
	; FIRST: release the mouse grab. The text object grabs the mouse on
	; either START_SELECT or PTR events, so if this is an END_SELECT
	; event, or have been called by VisTextClose because the text object
	; is dying, be sure to release mouse.
	;
	mov	ax, ds:[di].VTI_cursorPos.P_x	; Update the goal position.
	mov	ds:[di].VTI_goalPosition, ax

	and	ds:[di].VTI_intSelFlags, not (mask VTISF_DOING_SELECTION or \
					      mask VTISF_DOING_DRAG_SELECTION)

	call	VisReleaseMouse			; release the ptr.

	call	TA_UpdateRunsForSelectionChange

        mov     ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification

	call	SendAbortSearchSpellNotification

done:
	call	TextGStateDestroy

	call	CheckForInk
	tst	ax
	mov	ax, mask MRF_PROCESSED 
	jnz	doPenStuff
exit:
	ret
doPenStuff:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	jmp	exit
VisTextLargeEndSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse drags.

CALLED BY:	External (MSG_META_PTR)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= X position of event
		dx	= Y position of event
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive
RETURN:		ax	= MouseReturnFlags
		^lcx:dx	= Text edit cursor
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; Put the stub for MSG_META_PTR in fixed code so that we don't bring
	; the TextSelect resource in to move the cursor over a text object

TextFixed segment resource

VisTextPtr	proc	far			; MSG_META_PTR
	class	VisTextClass

	mov	ax, mask MRF_PROCESSED
	mov	bx, bp			; bx <- UIFunctionsActive flags
	test	bh, mask UIFA_MOVE_COPY
	jnz	sendIt
	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jz	bail
	test	bh, mask UIFA_SELECT
	jnz	sendIt

	call	CheckForInk		;If not pen mode, branch
	tst	ax
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE 
	jnz	bail			;Don't set the pointer image in pen

	call	GetPtrImageAndMouseFlags
bail:
	ret


sendIt:
	sub	sp, size LargeMouseData	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- stack frame
	call	InitLargeMouseStructure

	;
	; Call the large-mouse handler
	;
	call	VisTextLargePtr
	
	add	sp, size LargeMouseData	; Restore stack
	ret
VisTextPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see this object can get ink.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		ax - non-zero if ink can come to this object
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForInk	proc	far
	.enter
EC <	call	T_AssertIsVisText					>

;
; If our text doesn't accept ink, then return ax = 0
;
if not _TEXT_NO_INK

	call	SysGetPenMode
	tst	ax
	jz	exit

	mov	ax, ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK
	call	ObjVarFindData
	jnc	exit		;Exit with ax != 0 if vardata not present

endif

	clr	ax
exit::
	.leave
	ret
CheckForInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustEventForSingleLineObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For single-line objects, we want to force the event into
		the bounds of the line so that positions near the top or
		bottom of the object won't become events at the start or
		end of the line.

CALLED BY:	VisTextLargeStartSelect, VisTextLargePtr
PASS:		*ds:si	= Instance
		ss:bp	= LargeMouseData
RETURN:		event data adjusted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustEventForSingleLineObject	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di, bp
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance

	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	quit				; Branch if not one-line
	
	;
	; It's a one-line object, force the event to be inside the line
	;
	mov	bx, bp				; ss:bx <- LargeMouseData
	sub	sp, size PointDWord		; ss:bp <- parameters...
	mov	bp, sp
	
	clr	cx				; Only one region
	call	TR_RegionGetTopLeft		; Fill in PointDWord
	
	;
	; Force the event to be below the top of the line.
	;
	jgedw	ss:[bx].LMD_location.PDF_y.DWF_int, ss:[bp].PD_y, belowTop, ax
	movdw	ss:[bx].LMD_location.PDF_y.DWF_int, ss:[bp].PD_y, ax
belowTop:

	;
	; Now force the event to be less than or equal to the bottom
	; edge of the line.
	;
	push	bx				; Save frame ptr
	clrdw	bxdi				; bx.di <- line
	call	TL_LineGetHeight		; dx.bl <- line height
	pop	bx				; Restore frame ptr
	
	;
	; ss:bp	= Top of region
	; dx	= Height of line
	; ss:bx	= Event position
	;
	dec	dx				; Force *into* the line

	add	ss:[bp].PD_y.low, dx		; Set to bottom of line
	adc	ss:[bp].PD_y.high, 0
	
	jledw	ss:[bx].LMD_location.PDF_y.DWF_int, ss:[bp].PD_y, aboveBot, ax
	movdw	ss:[bx].LMD_location.PDF_y.DWF_int, ss:[bp].PD_y, ax
aboveBot:

	;
	; Restore stack...
	;
	add	sp, size PointDWord
quit:
	.leave
	ret
AdjustEventForSingleLineObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLargePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a large ptr event.

CALLED BY:	via MSG_META_LARGE_PTR
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= LargeMouseData
RETURN:		ax	= MouseReturnFlags
		^lcx:dx	= Text edit cursor
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TEST_VTP	=	0

if	TEST_VTP
PrintMessage <Temporary performance checking in VisTextPtr enabled>
endif

VisTextLargePtr	proc	far			; MSG_META_LARGE_PTR
	class	VisTextClass

	;
	; First, do any quick-transfer feedback necessary
	;
						; quick-transfer in progress?
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_MOVE_COPY
	jz	afterQT				; nope
	call	TT_SetClipboardQuickTransferFeedback	;ax = cursor
	jmp	doneAfterLeave
afterQT:

	;
	; If text is not selectable, then just consume the ptr event, 
	; & return PROCESSED without changing the cursor image.
	;
	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jnz	selectable
	mov	ax, mask MRF_PROCESSED
	jmp	doneAfterLeave
selectable:

	;
	; For us to actually select stuff there are two things that must be
	; true:
	;	- Select button on mouse must be down.
	;	- We must be doing a drag selection.
	;
						; if not selecting then quit.
	test	ss:[bp].LMD_uiFunctionsActive ,mask UIFA_SELECT
	LONG jz	noSelect

	;
	; We are in the process of doing a quick-move/copy and this event
	; is inside the bounds of this object. Check to see if this is our
	; first notification about the quick-move operation.
	;
	; If it is then we want to grab the gadget exclusive and make sure that
	; we get all the pointer events.
	;
	; If it isn't all we need to do is make sure that the cursor
	; is correct.
	;
	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_DRAG_SELECTION
	LONG jz	noSelect			; quit if not doing selection.

if	TEST_VTP
if	_FXIP
	PrintError <Cannot use TEST_VTP on full XIP systems>
endif
	inc	cs:[ptrCount]
endif
	call	TSL_HandlePtrEvent

done:
	call	GetPtrImageAndMouseFlags

doLeave:
	.leave

doneAfterLeave:
	ret

noSelect:
	call	CheckForInk		;If not pen mode, branch
	tst	ax
	jz	done
	mov	ax, mask MRF_PROCESSED	;Don't set the pointer image in pen
	jmp	doLeave			; mode.

VisTextLargePtr	endp

TextFixed ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_HandlePtrEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles a pointer event.

CALLED BY:	VisTextLargePtr
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= LargeMouseData
RETURN:		nothing
DESTROYED:	everything (pretty much...)

PSEUDO CODE/STRATEGY:
	- This code is the guts of VisTextLargePtr.
	- The part that actually checks the event is in fixed code so
	  that moving your mouse over a geowrite document won't cause
	  the TextSelect resource to be loaded.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 2/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_HandlePtrEvent	proc	far
	class	VisTextClass
	;
	; We are selecting.
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; ss:bp	= LargeMouseData
	;
	;
	; For single-line objects, we really want the event to appear to be
	; somewhere in the line so that a drag above or below the text won't
	; turn into an event at the start or end of the text.
	;
	call	AdjustEventForSingleLineObject

	call	TextGStateCreate		; Make gstate for drawing

	call	ComputeEventPositionAndOffset	; dx.ax <- offset of event
						; carry set if offset is the
						;   same as lastOffset
	jc	afterBump			; Branch if same

	;
	; The current event is at a different place than the old event we need
	; to adjust the selection.
	;
	clc					; Signal: don't set minimum
	call	StartSelectAdjust		; Adjust selection
	
	;
	; Force the selection to be displayed.
	;
	push	bp, ds:[di].VTI_leftOffset	; save frame ptr, left offset

	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	afterShowSelection		; Branch if not one-line

	;
	; We need to do this for one-line objects...
	;
	mov	bp, mask VTSSF_DRAGGING		; say we're dragging
	call	TextCallShowSelection		; Show lastAddr.
afterShowSelection:

	pop	bp, cx				; restore frame.
						; cx = old left offset
	call	BumpMouseOnSingleLineObject	; Scroll a single line object

afterBump:
	call	TextGStateDestroy
	ret
TSL_HandlePtrEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeEventPositionAndOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the position and offset of a mouse event.

CALLED BY:	VisTextStartSelect, VisTextPtr
PASS:		*ds:si	= Instance ptr
		ss:bp	= PointDWFixed which is the position of the event
RETURN:		PointDWFixed contains nearest valid coordinate for event
		dx.ax	= Offset into text where event occurred
		VTI-lastOffset holds dx.ax
		carry set if VTI-lastOffset has not changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeEventPositionAndOffset	proc	far
	class	VisTextClass
	uses	bx, cx, di
	.enter
	;
	; Fidget with the event position in order to make it actually fall
	; on some reasonable character boundary.
	;
	call	TSL_FigureNearestValidCoord
	;
	; dx.ax = Nearest character position
	;
	call	TextSelect_DerefVis_DI		; *ds:di <- instance ptr
	cmpdw	dxax, ds:[di].VTI_lastOffset	; Check for lastOffset change
	stc					; Assume no change
	je	quit				; Branch if no change

	movdw	ds:[di].VTI_lastOffset, dxax	; Save new lastOffset field
	clc					; Signal no change
quit:
	.leave
	ret
ComputeEventPositionAndOffset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BumpMouseOnSingleLineObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Single line objects require us to bump the mouse if the user
		drags outside their bounds left or right.

CALLED BY:	VisTextPtr
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Old value of VTI_leftOffset
RETURN:		ax, cx, dx
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BumpMouseOnSingleLineObject	proc	near
	class	VisTextClass
	uses	bp
	.enter
	;
	; If we're in a single line object and the current left-offset is
	; different than the old one we want to bump the mouse so we don't
	; scroll too fast for people.
	;
	sub	cx, ds:[di].VTI_leftOffset	; cx = (old - new)
	jz	noBump

	;
	; left offset changed, bump mouse to compensate
	;
	neg	cx
	clr	dx

	mov	ax, MSG_VIS_VUP_BUMP_MOUSE
	call	ObjCallInstanceNoLock

noBump:
	.leave
	ret
BumpMouseOnSingleLineObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineUnderPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the range of the line at a given position.

CALLED BY:	SelectByModeLine
PASS:		*ds:si	= instance ptr.
		dx.ax	= X coordinate (32 bit)
		cx.bx	= Y coordinate (32 bit)
RETURN:		dx.ax	= Offset of start of line under position
		cx.bx	= Offset of end of line under position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineUnderPosition	proc	near
	uses	di
	.enter
	xchgdw	dxax, cxbx		; dx.ax <- Y position
					; cx.bx <- X position
	
	call	TL_LineFromExtPosition	; bx.di <- line

	call	TL_LineToOffsetStart	; dx.ax <- line start
	pushdw	dxax			; Save line start

	call	TL_LineToOffsetVeryEnd	; dx.ax <- end of line
					; cx <- line flags
	movdw	cxbx, dxax		; cx.bx <- end of line

	popdw	dxax			; Restore line start
	.leave
	ret
LineUnderPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncludeMinimumSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the range to include the minimum selection.

CALLED BY:	SelectRangeByMode
PASS:		ds:di	= Instance ptr
		dx.ax	= Fixed position
		cx.bx	= Adjustable position
RETURN:		dx.ax	= Start of selected range
		cx.bx	= End of selected range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (adjust < fixed) {
	    start = adjust
	    end   = fixed
	} else {
	    start = fixed
	    end   = adjust
	}
	start = Min(start,minStart)
	end   = Max(end,minEnd)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncludeMinimumSelection	proc	near
	class	VisTextClass

	cmpdw	dxax, cxbx
	jbe	ordered
	xchgdw	dxax, cxbx			; dx.ax <- start of range
						; cx.bx <- end of range
ordered:
	;
	; dx.ax	= Start of range
	; cx.bx	= End of range
	;
	cmpdw	dxax, ds:[di].VTI_selectMinStart
	jbe	gotStart
	movdw	dxax, ds:[di].VTI_selectMinStart
gotStart:

	cmpdw	cxbx, ds:[di].VTI_selectMinEnd
	jae	gotEnd
	movdw	cxbx, ds:[di].VTI_selectMinEnd
gotEnd:
	ret
IncludeMinimumSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetTextPositionFromCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the nearest character position to a coordinate

CALLED BY:	MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message

		ss:bp - PointDWFixed to check

RETURN:		dx:ax - nearest character position
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetTextPositionFromCoord		proc	far
				; MSG_VIS_TEXT_GET_TEXT_POSITION_FROM_COORD
	call	TextGStateCreate		; Make a gstate
	call	TSL_FigureNearestValidCoord
	call	TextGStateDestroy
	ret
VisTextGetTextPositionFromCoord		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_FigureNearestValidCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the nearest valid coordinate to a given one.

CALLED BY:	ComputeEventPositionAndOffset
PASS:		*ds:si	= Instance ptr
		ss:bp	= Event position as inheritable PointDWFixed
RETURN:		ss:bp	= Nearest valid X and Y positions replacing
			  the position of the event
		dx.ax	= Nearest character position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_FigureNearestValidCoord	proc	far
	class	VisTextClass
	uses	bx, cx, di
	.enter
	movdw	cxbx, ss:[bp].PDF_x.DWF_int	; cx.bx <- X position
	movdw	dxax, ss:[bp].PDF_y.DWF_int	; dx.ax <- Y position
	call	TL_LineFromExtPosition		; bx.di <- Line under the event

	;
	; Carry set indicates y position is below the bottom of the text.
	;
	pushf					; Save "below text" indicator
	pushdw	bxdi				; Save line

	;
	; *ds:si= Instance ptr
	; bx.di	= Line the event occurred on
	;
	call	TL_LineToExtPosition		; cx.bx <- left edge of line
						; dx.ax <- top edge of line
	;
	; *ds:si= Instance ptr
	; bx.di	= Line the event occurred on
	; cx.bx = Left edge of line
	; dx.ax	= Top edge of line
	; ss:bp	= Actual event position
	; 
	movdw	ss:[bp].PDF_y.DWF_int, dxax	; Save line.top as event pos

	;
	; Convert the event X-position to an offset from the left edge of the
	; line.
	;
	call	TextSelect_DerefVis_DI		; cx.bx <- *real* line-left
	mov	ax, ds:[di].VTI_leftOffset	; ax <- left offset
	cwd					; dx.ax <- left offset
	adddw	cxbx, dxax			; cx.bx <- real left edge

	subdw	ss:[bp].PDF_x.DWF_int, cxbx	; Convert to offset from left

	movdw	dxax, ss:[bp].PDF_x.DWF_int	; dx.ax <- Offset into the line
	movdw	ss:[bp].PDF_x.DWF_int, cxbx	; Save left edge of line

	;
	; This is where we check to see if the Y offset was below the bottom
	; line. If that's the case we fake a huge X offset.
	;
	popdw	bxdi				; Restore line
	popf					; carry set if below last line
	jc	forceLargeXOffset		; Branch if below

	;
	; The offset of the event from the left edge of the line (dx.ax)
	; may be >64K. If it is, and it is positive, we map the result to
	; the largest 16 bit value suitable for this code (0x7fff). If it's
	; negative we force it to zero.
	;
	tst	dx
	jns	notNegative
	clrdw	dxax				; Force offset to zero
notNegative:
	
	cmpdw	dxax, 0x7fff
	jbe	offsetOK

forceLargeXOffset:
	mov	ax, 0x7fff

offsetOK:
	push	bp				; Save frame ptr
	;
	; ax holds a valid offset from the left edge of the line.
	;
	mov	bp, ax				; bp <- X offset
	movdw	dxax, -1			; dx.ax <- Offset to calc up to

	;
	; bx.di	= Line
	; dx.ax	= Text offset to stop calculating at
	; bp	= X offset from left edge of the line
	;
if SIMPLE_RTL_SUPPORT
	push	di
	call	TextSelect_DerefVis_DI
	test	ds:[di].VTI_features, mask VTF_RIGHT_TO_LEFT
	pop	di
	je	notRTL
	call	RTLSwapXForMouseSelect
notRTL:
endif
	call	TL_LineTextPosition		; dx.ax <- Nearest text offset
						; bx <- pixel from line left
	pop	bp				; Restore frame ptr
	
	;
	; Update the event x position for the offset from the left edge of the
	; line.
	;
	add	ss:[bp].PDF_x.DWF_int.low, bx
	adc	ss:[bp].PDF_x.DWF_int.high, 0
	.leave
	ret
TSL_FigureNearestValidCoord	endp

RTLSwapXForMouseSelect	proc near
	; bx.di	= Line
	; dx.ax	= Text offset to stop calculating at
	; bp	= X offset from left edge of the line
	push	bx, di, dx, ax, cx
	call	TL_LineGetLeftEdge
	push	ax
	push	di
	call	TR_RegionFromLine
	pop	di
	; cx = region
	call	TL_LineGetTop
	; dx = top position
	push	dx			; y pos
	call	TL_LineGetHeight
	; dx = line height
	mov	bx, dx			; line height
	pop	dx			; y pos

	; cx = region
	; dx = y pos
	; bx = int height
	call	TR_RegionLeftRight

	; Flip the X position around
	pop	cx
	add	bp, cx

	neg	bp
	add	bp, bx
	add	bp, ax

	sub	bp, cx

	pop	bx, di, dx, ax, cx
	ret
RTLSwapXForMouseSelect	endp

TextSelect	ends
