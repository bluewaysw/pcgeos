COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tslMethodSelect.asm

AUTHOR:		John Wedgwood, Nov 25, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/25/91	Initial revision

DESCRIPTION:
	Methods related to setting and getting the range of the selection.

	$Id: tslMethodSelect.asm,v 1.1 97/04/07 11:20:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextSelect2	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSelectRangeNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a range of text.

CALLED BY:	via MSG_VIS_TEXT_SELECT_RANGE
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextRange
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSelectRangeNew	proc	far		; MSG_VIS_TEXT_SELECT_RANGE
	class	VisTextClass

	mov	ax, size VisTextRange
	push	ax
	call	SwitchStackWithData

	;
	; limit end of selection to end of text (if VTR_end is
	; TEXT_ADDRESS_PAST_END, we'll just stuff it in again)
	;
	call	TS_GetTextSize			; dx.ax <- size of text.
	cmpdw	ss:[bp].VTR_end, dxax
	jbe	endOkay
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
endOkay:

	clr	bx				; No context
	call	TA_GetTextRange			; Make the range real

	call	TextGStateCreate		; Make me a gstate

	;
	; Load up the start/end of the new selection.
	;
	movdw	dxax, ss:[bp].VTR_start
	movdw	cxbx, ss:[bp].VTR_end

	call	TextCheckCanDraw
	jnc	canSelect			; Branch if we can draw

	;
	; If the object is suspended then we really can't update the cursor
	; or the selection or anything at all actually, so we store the range
	; to select it later.
	;
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jz	notSuspended

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changed,  4/22/93 -jw
; Doing this requires jumping through some hoops to make sure the selection
; stays updated. We can avoid these hoops by just using the selection values
; in the instance data.
;
;	push	bx
;	push	ax
;	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
;	call	ObjVarFindData
;EC <	ERROR_NC VIS_TEXT_SUSPEND_LOGIC_ERROR				>
;	pop	ax
;	movdw	ds:[bx].VTSD_selectRange.VTR_start, dxax
;	pop	ax					;cxax = end
;	movdw	ds:[bx].VTSD_selectRange.VTR_end, cxax
	
	call	TSL_SelectSetSelection		; Save new selection
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	jmp	done

notSuspended:
	;
	; Can't draw, but we still need to do some special stuff.
	; If the selection is a cursor (cx == dx) then we want to make sure that
	; the cursor is enabled.
	; If the selection is not a cursor we want to disable the cursor.
	;
	call	TSL_SelectSetSelection		; Save new selection

	mov	ax, -1
	call	TSL_UpdateCursorRegion		; Figure cursor region

	;
	; Check for a cursor.
	;
	call	TSL_SelectIsCursor		; carry set if it's a cursor
	jnc	disableCursor			; Branch if it's not a cursor

	;
	; Is a cursor, enable it.
	;
	or	ds:[di].VTI_intSelFlags, mask VTISF_CURSOR_ENABLED
	jmp	done

disableCursor:
	and	ds:[di].VTI_intSelFlags, not mask VTISF_CURSOR_ENABLED
	jmp	done

canSelect:
	;
	; Special case here: if the selection has not changed then don't biff
	; the insertion token(s)
	;
	cmpdw	dxax, ds:[di].VTI_selectStart
	jnz	compareDone
	cmpdw	cxbx, ds:[di].VTI_selectEnd
compareDone:
	pushf
	;
	; We can draw so we can select the range.
	;
	call	UpdateSelectedArea		; Update the selection

;	We need to update the goalPosition here, as otherwise it won't
;	be set correctly, so if you try to navigate to the next line, and
;	there is no next line, the cursor will be moved to the start of
;	the current line.

	call	Text_DerefVis_DI
	push	ax
	mov	ax, ds:[di].VTI_cursorPos.P_x
	mov	ds:[di].VTI_goalPosition, ax
	pop	ax
	
	;
	; Show the selection start
	;
	clr	bp				; say we're not dragging
	call	TextCallShowSelection		; Force selection to display.

	popf
	jz	afterNukeInsertionToken
	call	TA_UpdateRunsForSelectionChange
afterNukeInsertionToken:

	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification

done:
	call	TextGStateDestroy

	pop	di
	add	sp, size VisTextRange
	call	ThreadReturnStackSpace

	ret
VisTextSelectRangeNew	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSelectedArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the selected area on the screen.

CALLED BY:	AdjustSelectionToPosition, VisTextSetSelection
PASS:		*ds:si	= instance ptr.
		dx.ax	= New selection start
		cx.bx	= New selection end
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSelectedArea	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, bp, di
	.enter
	call	Text_DerefVis_DI
	
;
; Quit if the object isn't selectable.
;
; This test was nuked (3/18/93) because we want to be able to scroll
; non-selectable, display-only one-line text objects to the front/end by
; setting the selection appropriately - atw
;
;	test	ds:[di].VTI_state, mask VTS_SELECTABLE
;	LONG jz	quit

	

	sub	sp, size VisTextRange		; Allocate a range on the stack
	mov	bp, sp				; ss:bp <- range

	;
	; Save the new range on the stack.
	;
	movdw	ss:[bp].VTR_start, dxax
	movdw	ss:[bp].VTR_end, cxbx
	
	cmpdw	dxax, cxbx			; Check for new being a cursor
	je	newSelection			; Branch if it is

	;
	; Check for no selection before. (cursor on screen).
	;
	call	TSL_SelectIsCursor
	jc	newSelection			; Branch if cursor

	call	TSL_SelectGetSelection		; dx.ax <- old select start
						; cx.bx <- old select end

	;
	; We check for an overlap here. An overlap indicates that we are
	; either extending or contracting the selection. If the new range
	; does not share any inverted area with the old range then it is
	; considered a new range. This includes the case of the new selection
	; adjoining but not overlapping the old one.
	;
	; In the comparisons below the "above/below" cases correspond to
	; having no overlaps or adjacencies. The "equal" cases correspond
	; to the new selection adjoining the old selection.
	;
	cmpdw	ss:[bp].VTR_end, dxax		; if non overlapping then
	jbe	newSelection			; cannot extend
	cmpdw	ss:[bp].VTR_start, cxbx		; if non overlapping then
	jae	newSelection			; cannot extend

	call	TextSetDrawMask			; Make an appropriate mask.
	jc	afterSel
	;
	; Now either the selection overlaps entirely or it overlaps at one
	; end or the other.
	;
	cmpdw	ss:[bp].VTR_start, dxax		; Check for newStart = oldStart
	je	afterStart			; Branch if nothing to change

	;
	; If we get here we know that the new overlaps the old.
	;	newEnd   >  oldStart
	;	newStart <  oldEnd
	; We also know that:
	;	newStart != oldStart
	;
	; The implication here is that the overlap must be at the start of the 
	; old selection.
	;
	pushdw	cxbx				; Save old select end
	movdw	cxbx, ss:[bp].VTR_start		; cx.bx <- start of new selection
	call	InvertRange			; Invert oldStart<->newStart
	popdw	cxbx				; Restore old select end

afterStart:

	cmpdw	ss:[bp].VTR_end, cxbx		; Check for newEnd = oldEnd
	je	afterEnd

	;
	; If we get here we know that the new overlaps the old.
	;	newEnd   >  oldStart
	;	newStart <  oldEnd
	; We also know that:
	;	newStart == oldStart
	;	newEnd   != oldEnd
	;
	; The implication here is that the overlap must be at the end of the old
	; selection.
	;
	movdw	dxax, ss:[bp].VTR_end		; dx.ax <- end of new selection
	call	InvertRange			; Invert oldEnd<->newEnd

afterEnd:
	call	TextSetSolidMask		; Restore the mask.
afterSel:
	;
	; Save the new selection.
	;
	movdw	dxax, ss:[bp].VTR_start		; dx.ax <- new selection start
	movdw	cxbx, ss:[bp].VTR_end		; cx.bx <- new selection end
	call	TSL_SelectSetSelection		; Save new selection
	jmp	checkUpdateCursorRegion

newSelection:
	;
	; Selection is completely different, no overlaps.
	;
	call	EditUnHilite			; Deselect the old area.
	movdw	dxax, ss:[bp].VTR_start		; dx.ax <- new selection start
	movdw	cxbx, ss:[bp].VTR_end		; cx.bx <- new selection end
	call	TSL_SelectSetSelection
	pushf					; Save "start is different" flag
	call	EditHilite			; Select the new area.
	popf					; Rstr "start is different" flag

checkUpdateCursorRegion:
	;
	; <nz> if the start-select has changed
	;
	jnz	updateCursorRegion		; Branch if different start

done:
	add	sp, size VisTextRange		; Restore the stack

	.leave
	ret

updateCursorRegion:
	call	Text_DerefVis_DI
	mov	ax, ds:[di].VTI_cursorRegion	; ax <- old cursor region
	call	TSL_UpdateCursorRegion		; Update the cursor-region
	jmp	done

UpdateSelectedArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_UpdateCursorRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the cursor region if it needs it.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ax	= Old cursor region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_UpdateCursorRegion	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	checkSendNotification		; Branch if large

quit:
	.leave
	ret

;-----------------------------------------------------------------------------
checkSendNotification:
	;
	; It's a large object... We need to do something...
	; ds:di	= Instance ptr
	; ax	= Old cursor region
	;
	push	ax, cx, dx, bp			; Save registers

	mov	bp, ax				; bp <- old region
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- current region

	call	TSL_SelectGetSelectionStart	; dx.ax <- selection start
						; carry clear if it's a cursor
	jnc	checkSameRegion			; Branch if it is
	
	;
	; The selection is not a cursor. Compute the region that contains
	; selectStart. If that region is the same as the cursor region
	; then we can quit.
	;
	call	TR_RegionFromOffset		; cx <- current region

checkSameRegion:
	;
	; bp	= Old cursor region
	; cx	= New cursor region
	;
	mov	ds:[di].VTI_cursorRegion, cx	; Save current region...

	cmp	bp, cx				; Check for same
	je	done				; Branch if no region change

	;
	; Cursor has changed regions. Notify someone.
	;
EC <	call	T_AssertIsVisLargeText					>
	mov	ax, MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED
	call	ObjCallInstanceNoLock

done:
	pop	ax, cx, dx, bp			; Restore registers
	jmp	quit
TSL_UpdateCursorRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select all the text in the object.

CALLED BY:	via MSG_VIS_TEXT_SELECT_ALL
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSelectAll	proc	far		; MSG_VIS_TEXT_SELECT_ALL
	sub	sp, size VisTextRange	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- stack frame
	
	clrdw	ss:[bp].VTR_start	; range <- entire object
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
	
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	
	add	sp, size VisTextRange	; Restore stack
	ret
VisTextSelectAll	endp

TextSelect2 ends

TextSelect segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSelectStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor to the start of the object.

CALLED BY:	via MSG_VIS_TEXT_SELECT_START
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSelectStart	proc	far		; MSG_VIS_TEXT_SELECT_START
	sub	sp, size VisTextRange	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- stack frame
	
	clrdw	ss:[bp].VTR_start	; range <- start
	clrdw	ss:[bp].VTR_end
	
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	
	add	sp, size VisTextRange	; Restore stack
	ret
VisTextSelectStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSelectEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the selection to the end of the object.

CALLED BY:	via MSG_VIS_TEXT_SELECT_END
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSelectEnd	proc	far		; MSG_VIS_TEXT_SELECT_END
	sub	sp, size VisTextRange	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- stack frame
	
	movdw	ss:[bp].VTR_start, TEXT_ADDRESS_PAST_END
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
	
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	
	add	sp, size VisTextRange	; Restore stack
	ret
VisTextSelectEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSelectRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the cursor position relative to where it is now.

CALLED BY:	vis MSG_VIS_TEXT_SELECT_RELATIVE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Relative change in start
		dx	= Relative change in end
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSelectRelative	proc	far		; MSG_VIS_TEXT_SELECT_RELATIVE
	class	VisTextClass

	sub	sp, size VisTextRange	; Allocate a stack frame
	mov	bp, sp			; ss:bp <- stack frame
	
	;
	; Adjust the start
	;
	push	dx			; Save adjustment for the end
	mov	ax, cx			; ax <- adjustment for the start
	cwd				; dx.ax <- adjustment for the start
	
	movdw	cxbx, ds:[di].VTI_selectStart
	adddw	cxbx, dxax
	movdw	ss:[bp].VTR_start, cxbx
	
	;
	; Adjust the end
	;
	pop	ax			; ax <- adjustment for the end
	cwd				; dx.ax <- adjustment for the end

	movdw	cxbx, ds:[di].VTI_selectEnd
	adddw	cxbx, dxax
	movdw	ss:[bp].VTR_end, cxbx

	;
	; Now force the values to be legal.
	;
	call	TS_GetTextSize		; dx.ax <- size of text

	tst	ss:[bp].VTR_start.high	; Check for start negative
	jns	startNotNegative
	clrdw	ss:[bp].VTR_start	; Force to zero if negative
startNotNegative:

	cmpdw	ss:[bp].VTR_start, dxax	; Check for beyond end
	jbe	startOK
	movdw	ss:[bp].VTR_start, dxax	; Force to end if beyond
startOK:
	
	tst	ss:[bp].VTR_end.high	; Check for end negative
	jns	endNotNegative
	clrdw	ss:[bp].VTR_end		; Force to zero if negative
endNotNegative:

	cmpdw	ss:[bp].VTR_end, dxax	; Check for beyond end
	jbe	endOK
	movdw	ss:[bp].VTR_end, dxax	; Force to end if beyond
endOK:
	
	movdw	dxax, ss:[bp].VTR_end	; Check for start > end
	cmpdw	ss:[bp].VTR_start, dxax
	jbe	startLess
	movdw	ss:[bp].VTR_start, dxax	; Force start to end if larger
startLess:
	
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
	
	add	sp, size VisTextRange	; Restore stack
	ret
VisTextSelectRelative	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetSelectionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection range for an object.

CALLED BY:	via MSG_VIS_TEXT_GET_SELECTION_RANGE
PASS:		*ds:si	= Instance ptr
		dx:bp	= Pointer to VisTextRange to fill in.
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetSelectionRange	proc	far ; MSG_VIS_TEXT_GET_SELECTION_RANGE
	mov	es, dx			; es:di <- dest buffer
	mov	di, bp
	
	call	TSL_SelectGetSelection	; dx.ax <- start
					; cx.bx <- end

	movdw	es:[di].VTR_start, dxax
	movdw	es:[di].VTR_end, cxbx
	ret
VisTextGetSelectionRange	endp

TextSelect	ends
