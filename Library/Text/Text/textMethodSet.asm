COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textMethodSet.asm

AUTHOR:		John Wedgwood, Nov 21, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/21/91	Initial revision

DESCRIPTION:
	Method(s) for setting text in the text object.

	$Id: textMethodSet.asm,v 1.1 97/04/07 11:18:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSetReplace	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a range of the text object with some text supplied
		by the caller.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_ALL
		ReplaceSelectionWithSomething
		AppendWithSomething
		VisTextDeleteAll
		VisTextDeleteSelection
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		carry - set if replace aborted
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:
	Quit any selection that might be taking place
	Check for that the replace operation is legal
	Remove the selection hilite
	Replace the text
	If the selection is a cursor
	    Position the cursor
	Else
	    Hilite the selection
	Endif
	Force the selection to be visible
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceNew	method VisTextClass, MSG_VIS_TEXT_REPLACE_TEXT
	uses	bx
	.enter

if ERROR_CHECK
	;
	; If the text reference is a pointer, validate that the text is not 
	; in a movable code segment
	;
FXIP<	tstdw	ss:[bp].VTRP_insCount					>
FXIP<	jz	notPointer						>
FXIP<	cmp	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER		>
FXIP<	jne	notPointer						>
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].VTRP_textReference.TR_ref.TRU_pointer	>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
FXIP<	notPointer:							>
endif

	;
	; Convert the range into something meaningful.
	;
	clr	bx				; No context
	call	TA_GetTextRange			; Convert range
	call	TS_GetReplaceSize		; Convert number of characters

	; if there is nothing to do then bail

	movdw	dxax, ss:[bp].VTRP_range.VTR_end
	subdw	dxax, ss:[bp].VTRP_range.VTR_start
	or	ax, dx
	or	ax, ss:[bp].VTRP_insCount.low
	or	ax, ss:[bp].VTRP_insCount.high
	jz	exitNoError

if _CHAR_LIMIT
	call	CheckForTooManyChars
	jc	exit
endif		
	;
	; Make sure that the user isn't trying to nuke a section break.
	;
	; We check for the VTRF_FILTER flag here because if the flag is
	; set (editing), we don't allow the user to nuke a section break.
	;
	; If the flag is clear (eg: delete-section initiated by application)
	; then we do allow nuking of a section break character.
	;
	test	ss:[bp].VTRP_flags, mask VTRF_FILTER
	jz	doReplace
	call	TR_CheckCrossSectionChange	; Illegal to nuke section-break
	jnc	doReplace

	mov	ax, MSG_VIS_TEXT_CROSS_SECTION_REPLACE_ABORTED
	call	Text_ObjCallInstanceNoLock
	jmp	exitError			; Branch if nuking a break

doReplace:
	;
	; Do the replacement if we can.
	;
	call	ReplaceWithoutCrossSectionCheck
	jc	exitError

	;
	; Notify the output if context is desired.
	;
	test	ss:[bp].VTRP_flags, mask VTRF_DO_NOT_SEND_CONTEXT_UPDATE
	jnz	exitNoError
	call	T_CheckIfContextUpdateDesired
	jz	exitNoError
	movdw	dxax, ss:[bp].VTRP_range.VTR_start
	call	SendPositionContext

exitNoError:
	clc					; Signal: no error

exit:
	;
	; Carry set on error.
	;
	.leave
	ret


exitError:
	stc
	jmp	exit

VisTextReplaceNew	endm

if _CHAR_LIMIT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForTooManyChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert that the insert will not push the total number of
		chars over the character limit.

CALLED BY:	VTFInsert
PASS:		*ds:si - text object
		ss:bp - VisTextReplaceParameters
RETURN:		carry clear if replace can proceed
		carry set if not, and warning displayed
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForTooManyChars		proc	near
		class	VisTextClass
		.enter
	;
	; Don't bother checking small text objects.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
		jz	noLimit
	;
	; First, see if this is a deletion. If so, let it proceed.
	;
		tstdw	ss:[bp].VTRP_insCount
		jz	noLimit
	;
	; Then get the char limit, if any.
	;
		call	GetCharLimit		; cx <- char count limit
		jcxz	noLimit
	;
	; Now calculate size of the text if replace happened, and check
	; if it would exceed the limit.
	;
		push	cx
		call	TS_GetTextSize			; dx.ax <- # chars
		movdw	cxbx, ss:[bp].VTRP_range.VTR_end
		subdw	cxbx, ss:[bp].VTRP_range.VTR_start
		subdw	dxax, cxbx			;# chars - # replaced
		pop	cx

		add	ax, ss:[bp].VTRP_insCount.low	;new # chars + # insert
		adc	dx, ss:[bp].VTRP_insCount.high
		jnz	noWayJose
		cmp	ax, cx
		ja	noWayJose
noLimit:		
		clc
		ret
noWayJose:
		mov	cx, handle CharLimitWarningString
		mov	dx, offset CharLimitWarningString
		call	TT_DoWarningDialog
		stc
		.leave
		ret
CheckForTooManyChars		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCharLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum number of characters

CALLED BY:	
PASS:		nothing
RETURN:		cx - max # chars, or 0 for no limit
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCharLimit		proc	near
		uses	ax, es
		.enter

		segmov	es, dgroup, ax
		mov	cx, es:charLimit
		cmp	cx, -1
		je	initialize
done:		
		.leave
		ret
initialize:
		call	TR_GetTextLimits		; cx <- char limit
		jmp	done
GetCharLimit		endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceWithoutCrossSectionCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a range of text, without checking to see if the
		replacement crosses a section break.

CALLED BY:	VisTextReplaceNew
PASS:		*ds:si	= Instance
		Override file set
		ss:bp	= VisTextReplaceParameters w/ range set
RETURN:		carry set if we couldn't do the replacement
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceWithoutCrossSectionCheck	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di, bp, es
	.enter
	call	TextGStateCreate

	call	TS_CheckLegalChange		; Check for legal replace
	cmc
	LONG jc quit

EC <	call	TS_ECCheckParams					>

	;
	; Do any necessary filtering
	;
	test	ss:[bp].VTRP_flags, mask VTRF_FILTER
	jz	noFilter
	call	FilterReplacement
	LONG jc	quit
noFilter:

	; Setup the undo items for this app.
	;
	call	Text_DerefVis_DI
	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO
	jz	noNewUndoChain

	test	ss:[bp].VTRP_flags, mask VTRF_UNDO
	jnz	noNewUndoChain

	call	GenProcessUndoCheckIfIgnoring	;Don't create any undo chains
	tst	ax				; if actions are being
	jnz	noNewUndoChain			; ignored.

;	If there is no current undo item, or if we are not doing typing,
;	create a new chain.

	mov	ax,  offset ReplacementString
	tstdw	ss:[bp].VTRP_insCount
	jnz	10$
	mov	ax, offset DeleteString
10$:
	test	ss:[bp].VTRP_flags, mask VTRF_KEYBOARD_INPUT
	jz	createNewChain

;	We are typing - see if we have a current typing undo action - if so,
;	we don't want to start a new chain.

	call	TU_DerefUndo
	mov	ax, ds:[bx].VTCUI_vmChain.handle
	tst	ax
	jnz	noNewUndoChain
	mov	ax, offset TypingString
createNewChain:
	call	TU_CreateEmptyChain	;Actions will get inserted in chain 
					; later
noNewUndoChain:

	;
	; If we have an output then see if we have any text
	;
	call	TS_GetTextSize			; dx.ax = size
	mov	bx, ax
	or	bx, dx
	push	bx				; Save "have text" flag
	push	ss:[bp].VTRP_flags

	call	EditUnHilite			; Remove selection hilite

	call	TA_UpdateRunsForReplacement	; Update the runs
	;
	; carry set if runs changed
	; zero set if a paragraph attribute was nuked
	;
	pushf

	;
	; If we are transitioning from having a selection to not having
	; a selection then we must update
	;
	call	TSL_SelectIsCursor		;carry set if cursor
	jc	noRangeSelected
	popf
	stc
	pushf
noRangeSelected:

	;
	; Save the current cursor-region
	;
	call	Text_DerefVis_DI
	popf
	push	ds:[di].VTI_cursorRegion
	pushf					; Save "change" flag

	;
	; Update the selection based on the replacement parameters
	;
	call	AdjustSelectionForReplacement

	;
	; Update any suspend range that might be hanging around...
	;
	call	AdjustSuspendForReplacement

	;
	; Zero flag set if a paragraph attribute was nuked
	;
	call	TextReplace

	;
	; Call SendCharAttrParaAttrChange if needed
	;
	popf
	push	dx
	jc	forceChange

	; If we are inseting text and the cursor is now at the beginning of
	; a paragraph then force an update because moving from "not start
	; of paragraph" to "start of paragraph" (such as inserting a CR) can
	; require an update

	tstdw	ss:[bp].VTRP_insCount
	jz	noChange
	call	TS_GetTextSize			; dx.ax = size
	movdw	cxbx, dxax
	call	TSL_SelectGetSelectionStart	; dxax = cursor
	cmpdw	cxbx, dxax
	jz	noChange
	call	TSL_IsParagraphStart
	jnc	noChange
forceChange:
	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification
	jmp	afterNotify

noChange:
	call	Text_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	afterNotify			; no notif if not editable
	mov	ax, mask VTNF_CURSOR_POSITION	; else, just send cursor pos
	call	TA_SendNotification
afterNotify:
	pop	dx

	;
	; Update the cursor/selection.
	; dx	= New cursor position
	;	= -1 if cursor position can't be known.
	;
	call	TSL_SelectIsCursor		; Check for a cursor
	jnc	hiliteSelection
	cmp	dx, -1				; Check for unknown position
	je	hiliteSelection
	
	;
	; The cursors final resting place is known. Put it there.
	;
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	mov	bx, dx				; Pass position in bx
	add	bx, ds:[di].VTI_leftOffset	; Adjust for scrolled object
	call	TSL_CursorPositionX		; Position the cursor
	jmp	afterHilite

hiliteSelection:
	call	EditHilite			; Hilite the selection

afterHilite:
	;
	; Update the goal-position
	;
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	mov	ax, ds:[di].VTI_cursorPos.P_x	; ax <- cursor position
	add	ax, ds:[di].VTI_leftOffset	; Adjust for scrolled object
	mov	ds:[di].VTI_goalPosition, ax	; Make cursor position into
						;   goal position.
	;
	; Set the minimum selection and the current selection mode.
	;
	call	TSL_SelectGetSelectionStart	; dx.ax <- start
	movdw	ds:[di].VTI_selectMinStart, dxax
	movdw	ds:[di].VTI_selectMinEnd, dxax

	and	ds:[di].VTI_intSelFlags, not mask VTISF_SELECTION_TYPE

	pop	ax				; ax <- old cursor region
	call	TSL_UpdateCursorRegion		; Update the cursor region

	;
	; Display the cursor/selection on screen.
	;
	clr	bp				; We are not dragging
	call	TSL_SelectGetSelectionStart	; dx.ax <- position to show
	call	TextCallShowSelection		; Force selection on visible

	;
	; if the replace was due to a user action then mark the object as
	; user modified, otherwise mark the object as not user modified
	;
	pop	cx				;CX <- flags
	test	cx, mask VTRF_USER_MODIFICATION
	jnz	modified
	call	TextMarkNotUserModified
	jmp	common
modified:
	call	TextMarkUserModified
common:
	pop	cx				; Restore "have text" flag

	;
	; Send EMPTY_STATUS_CHANGED if needed
	;

	call	TS_GetTextSize
	or	ax, dx				; ax = "have text now" flag
	jnz	haveTextNow
	jcxz	noEmptyChange
	jmp	emptyChange
haveTextNow:
	tst	cx
	jnz	noEmptyChange
emptyChange:
	mov_tr	bp, ax				; bp = "have text now" flag
	mov	ax, MSG_META_TEXT_EMPTY_STATUS_CHANGED
	call	Text_ObjCallInstanceNoLock_save_cxdxbp
noEmptyChange:

	clc					; Signal: replace succeeded
quit:
	pushf					; Save "error" flag
	call	TextGStateDestroy
	popf					; Restore "error" flag
	.leave
	ret

ReplaceWithoutCrossSectionCheck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSelectionForReplacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection after a replace operation.

CALLED BY:	VisTextReplace, VisTextReplaceWithTransferItem
PASS:		ds:*si	= instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		nothing
DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:
	There are a few kinds of replacements:
	    1) Paste
	    2) Quick move/copy
	    3) Normal (editing, etc)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSelectionForReplacement	proc	far
	class	VisTextClass
	uses	bx, di
	.enter
	pushf
	call	Text_DerefVis_DI		; ds:di <- instance ptr.

	ExtractField	byte, ds:[di].VTI_intFlags, VTIF_ADJUST_TYPE, bl
	clr	bh
	shl	bx, 1				; Use bx as index into table
	
	call	cs:adjustSelectionForReplacementHandlers[bx]
	popf
	.leave
	ret
AdjustSelectionForReplacement	endp

adjustSelectionForReplacementHandlers	word \
	offset cs:AdjustSelectionNormal,	; AT_NORMAL
	offset cs:AdjustSelectionPaste,		; AT_PASTE
	offset cs:AdjustSelectionQuick		; AT_QUICK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSelectionNormal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a selection in a normal fashion.

CALLED BY:	AdjustSelectionForReplacement via adjustSelectionHandlers
PASS:		ds:di	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		Selection updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if changePos > selectStart
	    no change
	else if changePos == selectStart
	    selectStart = changePos+insCount
	else if (changePos + delCount) > selectStart
	    selectStart += insCount-delCount
	endif

	if changePos > selectEnd
	    no change
	else if (changePos == selectEnd
	    selectEnd = changePos+insCount
	else if (changePos + delCount) > selectEnd
	    selectEnd += insCount-delCount
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSelectionNormal	proc	near
	uses	ax, bx, cx, dx
	.enter
	;
	; Get the selection start and update it.
	;
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	call	AdjustOffsetNormal		; dx.ax <- adjusted start
	
	xchgdw	dxax, cxbx			; dx.ax <- select end
						; cx.bx <- adjusted start
	call	AdjustOffsetNormal		; dx.ax <- adjusted end
	
	xchgdw	dxax, cxbx			; dx.ax <- adjusted start
						; cx.bx <- adjusted end
	
	call	TSL_SelectSetSelectionWithoutNukingUndo
	.leave
	ret
AdjustSelectionNormal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustOffsetNormal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust an offset in a "normal" fashion.

CALLED BY:	AdjustSelectionNormal
PASS:		dx.ax	= Offset to adjust
		ss:bp	= VisTextReplaceParameters
RETURN:		dx.ax	= Adjusted offset
DESTROYED:	nothign

PSEUDO CODE/STRATEGY:
	Here are the cases:
	1) offset before changed area
		X   +--del--+
	   Do nothing

	2) offset after changed area
		+--del--+   X
	   offset = offset - (changeEnd - changeStart) + insCount

	3) offset in changed area
		+--del--X--+
	   offset = changePos + insCount

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustOffsetNormal	proc	near
	.enter
	cmpdw	dxax, ss:[bp].VTRP_range.VTR_start
	jb	quit			; Branch if offset before change
	
	;
	; The offset to adjust is after the change position.
	;
	cmpdw	dxax, ss:[bp].VTRP_range.VTR_end
	ja	adjustAfterRange
	
	;
	; Offset is in the range.
	;
	movdw	dxax, ss:[bp].VTRP_range.VTR_start
	adddw	dxax, ss:[bp].VTRP_insCount

quit:
	.leave
	ret

adjustAfterRange:
	subdw	dxax, ss:[bp].VTRP_range.VTR_end
	adddw	dxax, ss:[bp].VTRP_range.VTR_start
	adddw	dxax, ss:[bp].VTRP_insCount
	jmp	quit

AdjustOffsetNormal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSelectionPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a selection after a paste

CALLED BY:	AdjustSelectionForReplacement via adjustSelectionHandlers
PASS:		ds:di	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		Selection updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	After a paste the selection becomes a cursor after the paste position.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSelectionPaste	proc	near
	uses	ax, bx, cx, dx
	.enter
	movdw	dxax, ss:[bp].VTRP_range.VTR_start
	adddw	dxax, ss:[bp].VTRP_insCount	; dx.ax <- after change pos
	;
	; Save the position in selectStart/End
	;
	movdw	cxbx, dxax			; cx.bx <- same position
	call	TSL_SelectSetSelectionWithoutNukingUndo
	.leave
	ret
AdjustSelectionPaste	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSelectionQuick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a selection after a quick move or copy.

CALLED BY:	AdjustSelectionForReplacement via adjustSelectionHandlers
PASS:		ds:di	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		Selection updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	After a quick-move/copy we select the range.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSelectionQuick	proc	near
	uses	ax, bx, cx, dx
	.enter
						; dx.ax <- change position
						; cx.bx <- after change pos
	movdw	dxax, ss:[bp].VTRP_range.VTR_start
	movdw	cxbx, ss:[bp].VTRP_range.VTR_end
	adddw	cxbx, ss:[bp].VTRP_insCount
	
	call	TSL_SelectSetSelectionWithoutNukingUndo
	.leave
	ret
AdjustSelectionQuick	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSuspendForReplacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the start/end suspend offsets after a replacement.

CALLED BY:	VisTextReplaceNew
PASS:		*ds:si	= Instance
		ss:bp	= VisTextReplaceParameters
		zero flag set if a paragraph attribute was nuked
RETURN:		Suspend offsets updated
DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSuspendForReplacement	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx
	.enter
	pushf

	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA	; ax <- data to find
	call	ObjVarFindData			; ds:bx <- VisTextSuspendData
	LONG jnc quit				; Branch if no such data

	mov	ds:[bx].VTSD_needsRecalc, BB_TRUE

;-----------------------------------------------------------------------------
;			     Update Start
;-----------------------------------------------------------------------------
	;
	; We update the start becomes the minimum of the old start and
	; the change position... Unless of course the end is zero, in which
	; case we haven't actually made any change yet, and we therefore
	; set the start to whatever the range is currently.
	;
	tstdw	ds:[bx].VTSD_recalcRange.VTR_end
	jz	setStart

	movdw	dxax, ds:[bx].VTSD_recalcRange.VTR_start
	cmpdw	dxax, ss:[bp].VTRP_range.VTR_start
	jbe	gotStart

setStart:
	movdw	dxax, ss:[bp].VTRP_range.VTR_start

gotStart:
	movdw	ds:[bx].VTSD_recalcRange.VTR_start, dxax

;-----------------------------------------------------------------------------
;			      Update End
;-----------------------------------------------------------------------------
	;
	; The problem here is that the VTSD_range really isn't like a cursor.
	; It really doesn't accurately reflect the area that needs changing.
	; If this is the first call here, the end of the range is zero. 
	; Adjusting this position is the wrong thing to do. 
	;
	; Imagine the case where the change is made to text at offset 10 by
	; inserting 5 characters. No adjustment will be done for an offset 
	; of zero (it falls before the position of the change) so the end
	; of the range will be set to zero. Clearly we really want the end
	; of the range to be set to 15 sinc that is the last affected character
	; offset.
	;
	; How do we do this? We do it by setting the end of the range to the
	; maximum of the current end and the position of the change.
	;
	movdw	dxax, ss:[bp].VTRP_range.VTR_start

; was->	cmpdw	ds:[bx].VTSD_range.VTR_end, dxax
	cmpdw	ds:[bx].VTSD_recalcRange.VTR_end, dxax
	jae	gotTempEnd
; was->	movdw	ds:[bx].VTSD_range.VTR_end, dxax
	movdw	ds:[bx].VTSD_recalcRange.VTR_end, dxax
gotTempEnd:

	; make sure that the end is in range

	call	TS_GetTextSize			;dxax = size
	adddw	dxax, ss:[bp].VTRP_range.VTR_start
	subdw	dxax, ss:[bp].VTRP_range.VTR_end
	adddw	dxax, ss:[bp].VTRP_insCount

	cmpdw	dxax, ds:[bx].VTSD_recalcRange.VTR_start
	jae	afterStartCheck
	movdw	ds:[bx].VTSD_recalcRange.VTR_start, dxax
afterStartCheck:
	cmpdw	dxax, ds:[bx].VTSD_recalcRange.VTR_end
	jae	afterEndCheck
	movdw	ds:[bx].VTSD_recalcRange.VTR_end, dxax
afterEndCheck:

	;
	; Not so fast... If the change nuked a paragraph attribute, we need
	; to compute past the end of the change. This "end" can be gotten
	; by scanning from the current end to the end of the next paragraph.
	;
	popf					; Zero set if para-attr nuked
	pushf
	
	jnz	gotEndIGuess			; Branch if not nuked
	
	;
	; A paragraph attribute was nuked... find the new "end"
	;
	movdw	dxax, ds:[bx].VTSD_recalcRange.VTR_end
	call	TSL_FindParagraphEnd		; dx.ax <- end of paragraph
	movdw	ds:[bx].VTSD_recalcRange.VTR_end, dxax

gotEndIGuess:
	;
	; We update the end as though it were part of the selection
	;
	movdw	dxax, ds:[bx].VTSD_recalcRange.VTR_end
	call	AdjustOffsetNormal		; Update the end
	;
	; We add one special case to this... an end offset of zero is taken
	; as an indicator that nothing actually changed. For this reason
	; we never allow the end offset to be zero.
	;
	tstdw	dxax
	jnz	gotEnd
	inc	ax

gotEnd:
	movdw	ds:[bx].VTSD_recalcRange.VTR_end, dxax
	
quit:
	popf
	.leave
	ret
AdjustSuspendForReplacement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextMarkUserModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the object user modified and send a MSG_META_TEXT_USER_MODIFIED
		if needed

CALLED BY:	Utility
PASS:		*ds:si	= Text instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextMarkUserModified	proc	far	uses ax, di
	class	VisTextClass
	.enter

	call	Text_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_USER_MODIFIED
	jnz	alreadyModified

	;
	; We made the object dirty for the first time, send out a method
	;
	ornf	ds:[di].VTI_state, mask VTS_USER_MODIFIED

	mov	di, 1000
	call	ThreadBorrowStackSpace
	mov	ax, MSG_META_TEXT_USER_MODIFIED
	call	Text_ObjCallInstanceNoLock_save_cxdxbp
	call	ThreadReturnStackSpace

alreadyModified:
	.leave
	ret

TextMarkUserModified	endp

;---
if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckStringForImbeddedNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that there are no nulls in the string we are
		appending.

CALLED BY:	GLOBAL
PASS:		dx:bp - ptr to string
		cx - # bytes
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckStringForImbeddedNull	proc	far	uses	ax, cx, es, di
	jcxz	exit		;Exit if null-terminated
	.enter
	movdw	esdi, dxbp
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
EC <	ERROR_Z	TEXT_STRING_CONTAINS_NULL				>
	.leave
exit:
	ret
CheckStringForImbeddedNull	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all the text in an object with text referenced by
		a pointer.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_ALL_PTR
PASS:		*ds:si	= Instance ptr
		dx:bp	= Text pointer
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllPtr	method dynamic	VisTextClass,
			MSG_VIS_TEXT_REPLACE_ALL_PTR

if ERROR_CHECK
	;
	; Validate that the text is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, dx							>
FXIP<	mov	si, bp							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

EC <	call	CheckStringForImbeddedNull				>
	; optimize here -- if the text is the same then do nothing

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	noOptimize

	push	cx, si, es
	mov	si, ds:[di].VTI_text
	mov	si, ds:[si]			;ds:si = existing text
	ChunkSizePtr	ds, si, cx		;cx = size
DBCS <	shr	cx, 1							>
	movdw	esdi, dxbp
SBCS <	repe	cmpsb							>
DBCS <	repe	cmpsw							>
	pop	cx, si, es
	jz	noChange

noOptimize:
	xchg	dx, bp				; Offset first, then segment
	mov	ax, TRT_POINTER
	GOTO	ReplaceAllWithSomething
noChange:
	FALL_THRU	TextMarkNotUserModified
VisTextReplaceAllPtr	endm

TextMarkNotUserModified	proc	far	uses ax, di
	class	VisTextClass
	.enter

	call	Text_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_USER_MODIFIED
	jz	alreadyNotModified

	;
	; We made the object dirty for the first time, send out a method
	;
	andnf	ds:[di].VTI_state, not mask VTS_USER_MODIFIED
	mov	ax, MSG_META_TEXT_NOT_USER_MODIFIED
	call	Text_ObjCallInstanceNoLock_save_cxdxbp

alreadyNotModified:
	.leave
	ret

TextMarkNotUserModified	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all the text in an object with text referenced by
		an optr.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_ALL_OPTR
PASS:		*ds:si	= Instance ptr
		dx	= Block handle
		bp	= Chunk handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllOptr	method dynamic	VisTextClass,
			MSG_VIS_TEXT_REPLACE_ALL_OPTR
	xchg	dx, bp				; Chunk first, then block
	mov	ax, TRT_OPTR
	GOTO	ReplaceAllWithSomething
VisTextReplaceAllOptr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all the text in an object with text referenced by
		a handle.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_ALL_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= Block handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllBlock	method dynamic	VisTextClass,
			MSG_VIS_TEXT_REPLACE_ALL_BLOCK
	mov	ax, TRT_BLOCK
	GOTO	ReplaceAllWithSomething
VisTextReplaceAllBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all the text in an object with text referenced by
		a vm-block.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_ALL_VM_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= VM-Block handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllVMBlock	method dynamic	VisTextClass,
				MSG_VIS_TEXT_REPLACE_ALL_VM_BLOCK
	mov	ax, TRT_VM_BLOCK
	GOTO	ReplaceAllWithSomething
VisTextReplaceAllVMBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all the text in an object with text referenced by
		a db-item. The text is assumed to be null terminated

CALLED BY:	via MSG_VIS_TEXT_REPLACE_ALL_VM_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= File handle
		bp	= Group
		cx	= Item
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllDBItem	method dynamic	VisTextClass,
			MSG_VIS_TEXT_REPLACE_ALL_DB_ITEM
	mov	di, cx			; di <- 3rd word of data
	clr	cx			; Null terminated
	
	xchg	bp, di			; Item first, then group
	mov	ax, TRT_DB_ITEM
	GOTO	ReplaceAllWithSomething
VisTextReplaceAllDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all the text in an object with text referenced by
		a huge-array.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_ALL_VM_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= File handle
		bp	= Array handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllHugeArray	method dynamic	VisTextClass,
				MSG_VIS_TEXT_REPLACE_ALL_HUGE_ARRAY
	mov	ax, TRT_HUGE_ARRAY
	FALL_THRU	ReplaceAllWithSomething
VisTextReplaceAllHugeArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceAllWithSomething
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all the text in an object with something.

CALLED BY:	VisTextReplaceAll*
PASS:		*ds:si	= Instance ptr
		ax	= TextReferenceType
		dx,bp,di= Parameters
		cx	= Size, 0 for null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceAllWithSomething	proc	far
	mov	bx, bp			; bx <- parameter passed in bp
	
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:bp <- frame
	
	clrdw	ss:[bp].VTRP_range.VTR_start
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	
	mov	ss:[bp].VTRP_insCount.high, 0
	mov	ss:[bp].VTRP_insCount.low, cx
	mov	ss:[bp].VTRP_flags, 0
	
	;
	; If the passed size is zero then we want to compute the length
	;
	tst	cx			; Check for zero sized
	jnz	gotSize
	mov	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
gotSize:

	;
	; Fill in the frame...
	;
	mov	ss:[bp].VTRP_textReference.TR_type, ax
	mov	{word} ss:[bp].VTRP_textReference.TR_ref, dx
	mov	{word} ss:[bp].VTRP_textReference.TR_ref[2], bx
	mov	{word} ss:[bp].VTRP_textReference.TR_ref[4], di
	
	;
	; Do the replace
	;
	call	VisTextReplaceNew
	
	add	sp, size VisTextReplaceParameters
	ret
ReplaceAllWithSomething	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceSelectionPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the selection with text referenced by a pointer.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_SELECTION_PTR
PASS:		*ds:si	= Instance ptr
		dx:bp	= Text pointer
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceSelectionPtr	method	VisTextClass,
				MSG_VIS_TEXT_REPLACE_SELECTION_PTR

if ERROR_CHECK
	;
	; Validate that the text is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, dx							>
FXIP<	mov	si, bp							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

EC <	call	CheckStringForImbeddedNull				>
	xchg	dx, bp				; Offset first, then segment
	mov	ax, TRT_POINTER
	GOTO	ReplaceSelectionWithSomething
VisTextReplaceSelectionPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceSelectionOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the selection in an object with text referenced by
		an optr.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_SELECTION_OPTR
PASS:		*ds:si	= Instance ptr
		dx	= Block handle
		bp	= Chunk handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceSelectionOptr	method dynamic	VisTextClass,
				MSG_VIS_TEXT_REPLACE_SELECTION_OPTR
	xchg	dx, bp				; Block first, then chunk
	mov	ax, TRT_OPTR
	GOTO	ReplaceSelectionWithSomething
VisTextReplaceSelectionOptr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceSelectionBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the selection in an object with text referenced by
		a handle.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= Block handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceSelectionBlock	method dynamic	VisTextClass,
				MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK
	mov	ax, TRT_BLOCK
	GOTO	ReplaceSelectionWithSomething
VisTextReplaceSelectionBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceSelectionVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the selection in an object with text referenced by
		a vm-block.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_SELECTION_VM_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= VM-Block handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceSelectionVMBlock	method dynamic	VisTextClass,
				MSG_VIS_TEXT_REPLACE_SELECTION_VM_BLOCK
	mov	ax, TRT_VM_BLOCK
	GOTO	ReplaceSelectionWithSomething
VisTextReplaceSelectionVMBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceSelectionDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the selection in an object with text referenced by
		a db-item. The text is assumed to be null terminated

CALLED BY:	via MSG_VIS_TEXT_REPLACE_SELECTION_DB_ITEM
PASS:		*ds:si	= Instance ptr
		dx	= File handle
		bp	= Group
		cx	= Item
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceSelectionDBItem	method dynamic	VisTextClass,
				MSG_VIS_TEXT_REPLACE_SELECTION_DB_ITEM
	mov	di, cx			; di <- 3rd word of data
	clr	cx			; Null terminated

	xchg	bp, di			; Item first, then group
	mov	ax, TRT_DB_ITEM
	GOTO	ReplaceSelectionWithSomething
VisTextReplaceSelectionDBItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceSelectionHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the selection in an object with text referenced by
		a huge-array.

CALLED BY:	via MSG_VIS_TEXT_REPLACE_SELECTION_HUGE_ARRAY
PASS:		*ds:si	= Instance ptr
		dx	= File handle
		bp	= Array handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceSelectionHugeArray	method dynamic	VisTextClass,
					MSG_VIS_TEXT_REPLACE_SELECTION_HUGE_ARRAY
	mov	ax, TRT_HUGE_ARRAY
	FALL_THRU ReplaceSelectionWithSomething
VisTextReplaceSelectionHugeArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceSelectionWithSomething
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the selection with some text.

CALLED BY:	VisTextReplaceSelection*
PASS:		*ds:si	= Instance ptr
		ax	= TextReferenceType
		dx,bp,di= Values to pass in the stack frame
		cx	= Size, 0 for null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceSelectionWithSomething	proc	far
	mov	bx, bp			; bx <- parameter passed in bp
	
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:bp <- frame
	
	mov	ss:[bp].VTRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	
	mov	ss:[bp].VTRP_insCount.high, 0
	mov	ss:[bp].VTRP_insCount.low, cx
	mov	ss:[bp].VTRP_flags, 0
	
	;
	; If the passed size is zero then we want to compute the length
	;
	tst	cx			; Check for zero sized
	jnz	gotSize
	mov	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
gotSize:

	;
	; Fill in the frame...
	;
	mov	ss:[bp].VTRP_textReference.TR_type, ax
	mov	{word} ss:[bp].VTRP_textReference.TR_ref, dx
	mov	{word} ss:[bp].VTRP_textReference.TR_ref[2], bx
	mov	{word} ss:[bp].VTRP_textReference.TR_ref[4], di
	
	;
	; Do the replace
	;
	call	VisTextReplaceNew
	
	add	sp, size VisTextReplaceParameters
	ret
ReplaceSelectionWithSomething	endp


TextSetReplace	ends

TextInstance	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextAppendPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append with text referenced by a pointer.

CALLED BY:	via MSG_VIS_TEXT_APPEND_PTR
PASS:		*ds:si	= Instance ptr
		dx:bp	= Text pointer
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextAppendPtr	method dynamic	VisTextClass, MSG_VIS_TEXT_APPEND_PTR

if ERROR_CHECK
	;
	; Validate that the text is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, dx							>
FXIP<	mov	si, bp							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

EC <	call	CheckStringForImbeddedNull				>

	xchg	dx, bp				; Offset first, then segment
	mov	ax, TRT_POINTER
	GOTO	AppendWithSomething
VisTextAppendPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextAppendOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append to an object with text referenced by an optr.

CALLED BY:	via MSG_VIS_TEXT_APPEND_OPTR
PASS:		*ds:si	= Instance ptr
		dx	= Block handle
		bp	= Chunk handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextAppendOptr	method dynamic	VisTextClass,
			MSG_VIS_TEXT_APPEND_OPTR
	xchg	dx, bp				; Block first, then chunk
	mov	ax, TRT_OPTR
	GOTO	AppendWithSomething
VisTextAppendOptr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextAppendBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append to an object with text referenced by a handle.

CALLED BY:	via MSG_VIS_TEXT_APPEND_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= Block handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextAppendBlock	method dynamic	VisTextClass, MSG_VIS_TEXT_APPEND_BLOCK
	mov	ax, TRT_BLOCK
	GOTO	AppendWithSomething
VisTextAppendBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextAppendVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append to an object with text referenced by a vm-block.

CALLED BY:	via MSG_VIS_TEXT_APPEND_VM_BLOCK
PASS:		*ds:si	= Instance ptr
		dx	= VM-Block handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextAppendVMBlock	method dynamic	VisTextClass,
			MSG_VIS_TEXT_APPEND_VM_BLOCK
	mov	ax, TRT_VM_BLOCK
	GOTO	AppendWithSomething
VisTextAppendVMBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextAppendDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append to an object with text referenced by a db-item.
		The text is assumed to be null terminated

CALLED BY:	via MSG_VIS_TEXT_APPEND_DB_ITEM
PASS:		*ds:si	= Instance ptr
		dx	= File handle
		bp	= Group
		cx	= Item
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextAppendDBItem	method dynamic	VisTextClass,
			MSG_VIS_TEXT_APPEND_DB_ITEM
	mov	di, cx			; di <- 3rd word of data
	clr	cx			; Null terminated

	xchg	bp, di			; Item first, then group
	mov	ax, TRT_DB_ITEM
	GOTO	AppendWithSomething
VisTextAppendDBItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextAppendHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append to an object with text referenced by a huge-array.

CALLED BY:	via MSG_VIS_TEXT_APPEND_HUGE_ARRAY
PASS:		*ds:si	= Instance ptr
		dx	= File handle
		bp	= Array handle
		cx	= Size, 0 if null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextAppendHugeArray	method dynamic	VisTextClass,
			MSG_VIS_TEXT_APPEND_HUGE_ARRAY
	mov	ax, TRT_HUGE_ARRAY
	FALL_THRU AppendWithSomething
VisTextAppendHugeArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendWithSomething
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append with some text.

CALLED BY:	VisTextAppend*
PASS:		*ds:si	= Instance ptr
		ax	= TextReferenceType
		dx,bp,di= Values to pass in the stack frame
		cx	= Size, 0 for null terminated
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendWithSomething	proc	far
	mov	bx, bp			; bx <- parameter passed in bp
	
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp			; ss:bp <- frame
	
	movdw	ss:[bp].VTRP_range.VTR_start, TEXT_ADDRESS_PAST_END
	movdw	ss:[bp].VTRP_range.VTR_end,   TEXT_ADDRESS_PAST_END
	
	mov	ss:[bp].VTRP_insCount.high, 0
	mov	ss:[bp].VTRP_insCount.low, cx
	mov	ss:[bp].VTRP_flags, 0
	
	;
	; If the passed size is zero then we want to compute the length
	;
	tst	cx			; Check for zero sized
	jnz	gotSize
	mov	ss:[bp].VTRP_insCount.high, INSERT_COMPUTE_TEXT_LENGTH
gotSize:

	;
	; Fill in the frame...
	;
	mov	ss:[bp].VTRP_textReference.TR_type, ax
	mov	{word} ss:[bp].VTRP_textReference.TR_ref, dx
	mov	{word} ss:[bp].VTRP_textReference.TR_ref[2], bx
	mov	{word} ss:[bp].VTRP_textReference.TR_ref[4], di
	
	;
	; Do the replace
	;
	call	VisTextReplaceNew
	
	add	sp, size VisTextReplaceParameters
	ret
AppendWithSomething	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDeleteRangeOfChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a range of characters from the text object

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextRange of chars to delete
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDeleteRangeOfChars	method	VisTextClass, 
				MSG_META_DELETE_RANGE_OF_CHARS
	movdw	dxax, ss:[bp].VTR_start
	movdw	cxbx, ss:[bp].VTR_end
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp				; ss:bp <- frame ptr

	movdw	ss:[bp].VTRP_range.VTR_start, dxax
	movdw	ss:[bp].VTRP_range.VTR_end, cxbx
	clrdw	ss:[bp].VTRP_insCount
	mov	ss:[bp].VTRP_flags, mask VTRF_FILTER or \
				    mask VTRF_USER_MODIFICATION
	call	VisTextReplaceNew
	add	sp, size VisTextReplaceParameters
	ret
VisTextDeleteRangeOfChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDeleteAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all the text in an object.

CALLED BY:	via MSG_VIS_TEXT_DELETE_ALL
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDeleteAll	method dynamic	VisTextClass,
			MSG_VIS_TEXT_DELETE_ALL
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp				; ss:bp <- frame ptr

	clr	ax	
	clrdw	ss:[bp].VTRP_range.VTR_start, ax
	movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	clrdw	ss:[bp].VTRP_insCount, ax
	mov	ss:[bp].VTRP_flags, ax
	
	call	VisTextReplaceNew

	add	sp, size VisTextReplaceParameters
	ret
VisTextDeleteAll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the current selection

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDelete	method	VisTextClass, MSG_META_DELETE
	mov	ax, mask VTRF_USER_MODIFICATION or mask VTRF_FILTER
	GOTO	DeleteSelectionCommon
VisTextDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDeleteSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the selection in an object.

CALLED BY:	via MSG_VIS_TEXT_DELETE_SELECTION
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDeleteSelection	method dynamic	VisTextClass, 
			MSG_VIS_TEXT_DELETE_SELECTION

	clr	ax
	FALL_THRU	DeleteSelectionCommon
VisTextDeleteSelection	endm
DeleteSelectionCommon	proc	far
if DBCS_PCGEOS
EC <	mov	di, 1000						>
EC <	call	ThreadBorrowStackSpace					>
EC <	push	di							>
endif
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp				; ss:bp <- frame ptr
	
	mov	ss:[bp].VTRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	clrdw	ss:[bp].VTRP_insCount
	mov	ss:[bp].VTRP_flags, ax
	
	call	VisTextReplaceNew

	add	sp, size VisTextReplaceParameters
if DBCS_PCGEOS
EC <	pop	di							>
EC <	call	ThreadReturnStackSpace					>
endif
	ret
DeleteSelectionCommon	endp
TextInstance	ends
