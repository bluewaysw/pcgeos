COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetSearch.asm

AUTHOR:		John Wedgwood, Jul 30, 1991

METHODS:
	Name			Description
	----			-----------
	MSG_SPREADSHEET_SEARCH	Search for a string in the spreadsheet

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 7/30/91	Initial revision

DESCRIPTION:
	Implementation of the spreadsheets searching code.

	$Id: spreadsheetSearch.asm,v 1.1 97/04/07 11:14:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC

SearchStrings	segment	lmem	LMEM_TYPE_GENERAL

LocalDefString SearchNotFound <"The search string was not found in the search range.", 0>

LocalDefString SearchForwardEnd <"Search has reached the end of the search range. Continue search from the beginning?", 0>

LocalDefString SearchBackwardEnd <"Search has reached the beginning of the search range. Continue search from the end?", 0>

SearchStrings	ends

endif

SpreadsheetSearchCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the spreadsheet to find a string.

CALLED BY:	via MSG_SPREADSHEET_SEARCH
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		
		dx	= handle of SearchReplaceStruct
			  (should be freed by handler)
RETURN:		none
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		'startPos' and 'endPos' are char/wchar offsets into
		formatted string of cell contents.  -1 is not selected.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSearch	method	dynamic SpreadsheetClass, 
							MSG_SEARCH
chunkHandle	local	word	push 	si	;save chunk of this object
searchStructSeg	local	sptr.SearchReplaceStruct
searchArea	local	SpreadsheetSearchArea	;where to look
foundArea	local	SpreadsheetSearchArea	;where we found it
startPos	local	word			;start of selection
endPos		local	word			;end of selection
foundCell	local	CellReference		;cell where found it (if any)
ifdef GPC
abortSearch	local	word			;TRUE if stopped
endif
	.enter

ForceRef	chunkHandle			;referenced in SearchCells
		
PrintMessage <fix when search UI is updated>
;ife _JEDI
;	mov	ss:searchArea, mask SSA_SEARCH_FORMULAS or \
;		mask SSA_SEARCH_NOTES
;else
;	mov	ss:searchArea, mask SSA_SEARCH_FORMULAS
;endif
	clr	ax
	mov	ss:foundArea, al		;nothing found yet
ifdef GPC
	mov	ss:abortSearch, ax
endif
	dec	ax
	mov	ss:startPos, ax
	mov	ss:endPos, ax
	mov	ss:foundCell.CR_row, ax
	mov	ss:foundCell.CR_column, ax

	mov	bx, dx				;bx <- SearchReplaceStruct
	push	bx				;save handle
	call	MemLock
	mov	ss:searchStructSeg, ax

;if _JEDI
	;
	; Find out what note option is used.
	;
	push	ax, si
	push	ds
	mov	ds, ax				;ds = SearchReplaceStruct
	movdw	bxsi, ds:[SRS_replyObject]	;^lbx:si = Search controller
	pop	ds
	Assert objectOD bxsi SearchReplaceControlClass, fixup
	mov	ax, MSG_SRC_GET_NOTE_SEARCH_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax trashed
						;cl = SearchNoteOptionType
	clr	ch
	mov	bx, cx
	mov	cl, cs:[noteOptionsTable][bx]	;cl = area to search
	mov	ss:[searchArea], cl
	pop	ax, si
;endif
	;
	;
	;
	;
	; At this point, we want to know if the search is from top or not.
	; If it is true, then we set the active cell to A1, so we can search
	; from top.
	;
	push	ds
	mov	ds, ax				;ds = SearchReplaceStruct seg
	test	ds:[SRS_params], mask SO_START_FROM_TOP
	pop	ds
	jz	searchStart
	push	ax, cx, dx, bp
	mov	ax, MSG_SPREADSHEET_MOVE_ACTIVE_CELL
	clr	bp, cx
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

searchStart:
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset	;ds:si = ssheet instance
	call	SearchCells
	jc	foundMatch			;branch if match found
	call	SearchTextObjects
	jc	foundMatch			;branch if match found
	;
	; If we didn't find a match, tell the SearchReplaceControl
	; (or whoever is listening at the other end) about it.
	;
ifdef GPC
	;report our own message
	mov	ax, offset SearchNotFound
	call	SearchDoDialog
endif
	mov	ds, ss:searchStructSeg
	movdw	bxsi, ds:SRS_replyObject
ifdef GPC
	mov	ax, MSG_ABORT_ACTIVE_SEARCH
else
	mov	ax, ds:SRS_replyMsg
endif
	clr	di
	call	ObjMessage
	clc					;carry <- not found
foundMatch:
	pop	bx				;bx <- SearchReplaceStruct
	pushf
	call	MemFree
	popf
	jnc	done				;branch if not found
ifdef GPC
	tst	ss:abortSearch			;branch if aborted
	jnz	done
endif
	;
	; If we had a match, do something interesting
	;
	call	HandleMatch
done:

	.leave
	ret

noteOptionsTable	byte	\
	mask SSA_SEARCH_FORMULAS or mask SSA_SEARCH_NOTES,
	mask SSA_SEARCH_FORMULAS,
	mask SSA_SEARCH_NOTES

SpreadsheetSearch	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a match in the search code.

CALLED BY:	SpreadsheetSearch
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= inherited locals
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleMatch	proc	near
	uses	ax
	.enter	inherit	SpreadsheetSearch

	;
	; we have to center the cell with the matched str, so turn on the
	; centerFlag here
	; 
	push	ds, bx
	mov	bx, handle dgroup
	call	MemDerefDS				; ds = dgroup
	inc	ds:[centerFlag]				; turn on the flag
	pop	ds, bx

	;
	; A match was found. This means we need to display something...
	;
	mov	ax, offset cs:HandleFormulaMatch
	test	ss:foundArea, mask SSA_SEARCH_FORMULAS
	jnz	found

	mov	ax, offset cs:HandleValueMatch
	test	ss:foundArea, mask SSA_SEARCH_VALUES
	jnz	found

	mov	ax, offset cs:HandleNoteMatch
	test	ss:foundArea, mask SSA_SEARCH_NOTES
	jnz	found

	mov	ax, offset cs:HandleTextObjectMatch
EC <	test	ss:foundArea, mask SSA_SEARCH_TEXT_OBJECTS	>

found:
	call	ax

	;
	; Since we have center the selected cell, so turn the centerFlag off
	;
	push	ds, bx
	mov	bx, handle dgroup
	call	MemDerefDS
	mov	ds:[centerFlag], 0
	pop	ds, bx

	.leave
	ret
HandleMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveToFoundCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move active cell to where we found search pattern
CALLED BY:	UTILITY

PASS:		ss:bp - inherited locals
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MoveToFoundCell	proc	near
	uses	ax, cx, di
	.enter	inherit	SpreadsheetSearch

	;
	; Move to the appropriate cell
	;
	mov	ax, ss:foundCell.CR_row		;ax <- row
	mov	cx, ss:foundCell.CR_column	;cx <- column
	call	MoveActiveCellFar		;move the active cell

	.leave
	ret
MoveToFoundCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleFormulaMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a match in a formula.

CALLED BY:	HandleMatch
PASS:		ss:bp	= inherited locals
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		ss:startPos and ss:endPos are char/wchar offsets.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleFormulaMatch	proc	near
	uses	ax, bx, cx, dx, di, bp, es
	.enter	inherit	SpreadsheetSearch

EC <	call	ECCheckInstancePtr		;>
	;
	; Move to the appropriate cell
	;
	call	MoveToFoundCell
	;
	; Now select the appropriate range in the edit bar.
	;
	mov	cx, ss:startPos			;cx <- start of range
	mov	dx, ss:endPos			;dx <- end of range
PrintMessage <fix when search UI is updated>
;;;	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
;;;	mov	di, mask MF_CALL		;di <- MessageFlags
;;;	call	SpreadsheetCallEditOD		;call edit object
	;
	; Now give the focus to that object.
	;
PrintMessage <fix when search UI is updated>
;;;	mov	ax, MSG_GEN_MAKE_FOCUS
;;;	call	SpreadsheetCallEditOD		;make focus

	.leave
	ret
HandleFormulaMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleValueMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a match in a value.

CALLED BY:	HandleMatch
PASS:		ss:bp	= inherited locals
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleValueMatch	proc	near
	uses	ax, bx, cx, dx, di
	.enter	inherit	SpreadsheetSearch
EC <	call	ECCheckInstancePtr		;>

	;
	; Move to the appropriate cell
	;
	call	MoveToFoundCell

	.leave
	ret
HandleValueMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNoteMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a match in a note.

CALLED BY:	HandleMatch
PASS:		ss:bp	= inherited locals
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNoteMatch	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di
	.enter	inherit	SpreadsheetSearch
EC <	call	ECCheckInstancePtr		;>
	;
	; Move to the appropriate cell
	;
	mov	ax, ss:foundCell.CR_row		;ax <- row
	mov	cx, ss:foundCell.CR_column	;cx <- column
	call	MoveActiveCellFar		;move the active cell
	;
	; Now tell our superclass to call up the note
	;
	clr	dl				;dl <- SpreadsheetDoubleClick
	call	SendBringUpNote

	.leave
	ret
HandleNoteMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleTextObjectMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a match in a text object.

CALLED BY:	HandleMatch
PASS:		ss:bp	= inherited locals
		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleTextObjectMatch	proc	near
	ERROR	-1			; We don't support graphics now
HandleTextObjectMatch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchDialog, SearchDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query user if search should wrap around. (SearchDialog)
		Report search status. (SearchDoDialog)

CALLED BY:	HandleMatch
PASS:		ax	= string chunk
RETURN:		ax	= IC_YES to wrap around (SearchDialog)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/7/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC
SearchDialog	proc	near
	uses	bx, bp, ds, si
	.enter
	mov	si, ax
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, \
		CDT_QUESTION shl (offset CDBF_DIALOG_TYPE) or \
		GIT_AFFIRMATION shl (offset CDBF_INTERACTION_TYPE)
	movdw	ss:[bp].SDP_stringArg1, 0
	movdw	ss:[bp].SDP_stringArg2, 0
	movdw	ss:[bp].SDP_customTriggers, 0
	movdw	ss:[bp].SDP_helpContext, 0
	mov	bx, handle SearchStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	movdw	ss:[bp].SDP_customString, dssi
	call	UserStandardDialog		; ax = IC
	call	MemUnlock
	.leave
	ret
SearchDialog	endp

SearchDoDialog	proc	near
	uses	bx, cx, dx, bp, ds, si, di
	.enter
	mov	si, ax
	mov	dx, size GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, \
		CDT_NOTIFICATION shl (offset CDBF_DIALOG_TYPE) or \
		GIT_NOTIFICATION shl (offset CDBF_INTERACTION_TYPE)
	movdw	ss:[bp].GADDP_dialog.SDP_stringArg1, 0
	movdw	ss:[bp].GADDP_dialog.SDP_stringArg2, 0
	movdw	ss:[bp].GADDP_dialog.SDP_customTriggers, 0
	movdw	ss:[bp].GADDP_dialog.SDP_helpContext, 0
	mov	bx, handle SearchStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	movdw	ss:[bp].GADDP_dialog.SDP_customString, dssi
	movdw	ss:[bp].GADDP_finishOD, 0
	mov	ss:[bp].GADDP_message, 0
	clr	bx
	call	GeodeGetAppObject		; ^lbx:si = app
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage			; cx = IC
	add	sp, size GenAppDoDialogParams
	mov	ax, cx				; ax = IC
	mov	bx, handle SearchStrings
	call	MemUnlock
	.leave
	ret
SearchDoDialog	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search formulas, values, and notes

CALLED BY:	SpreadsheetSearch
PASS:		ds:si	= Instance ptr
		ss:bp	= inherited locals
RETURN:		carry set if we found the string
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Figure the range to search over
	Process the range in the appropriate order

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchCells	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di

	.enter	inherit SpreadsheetSearch

EC <	call	ECCheckInstancePtr		;>
	sub	sp, size RangeEnumParams	; Alloc stack frame
	mov	bx, sp				; ss:bx <- RangeEnumParams
	
	;
	; The range to search over is either:
	;	The selection (if more than one cell selected)
	;	The entire spreadsheet (if only one cell selected)
	;
	; Assume that we'll be using the selection.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row

	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	di, ds:[si].SSI_selected.CR_end.CR_column

	mov	ss:[bx].REP_bounds.R_top, ax
	mov	ss:[bx].REP_bounds.R_bottom, dx

	mov	ss:[bx].REP_bounds.R_left, cx
	mov	ss:[bx].REP_bounds.R_right, di

	;
	; Now check to make sure we want to use the selection.
	;
	cmp	ax, dx
	jne	gotBounds			; Branch if top != bottom
	
	cmp	cx, di
	jne	gotBounds			; Branch if left != right
	;
	; The selection is a single cell, use the spreadsheet extent.
	;
	call	CellGetExtent			; Grab extent of the spreadsheet

	cmp	ss:[bx].REP_bounds.R_top, -1	; Check for no bounds
	je	quitNotFound			; Branch if not found

	;
	; For Nike, we want to search in the locked cells...
	;
		
	;
	; If there are locked rows and columns, move the origin of the
	; range we are interested, so it does not include the locked
	; cells. 
	;
	push	bx, si
	mov	si, ss:[chunkHandle]
	mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
	call	ObjVarFindData
	mov	di, bx				; ds:di = vardata
	pop	bx, si
	jnc	gotBounds
	;
	; check to see if the extent is less then the origin of the
	; locked rows and columns
	;
	mov	ax, ds:[di].SDO_rowCol.CR_row
	cmp	ax, ss:[bx].REP_bounds.R_bottom
	jg	quitNotFound

	mov	ax, ds:[di].SDO_rowCol.CR_column
	cmp	ax, ss:[bx].REP_bounds.R_right
	jg	quitNotFound
	;
	; move the origin
	;
	mov	ax, ds:[di].SDO_rowCol.CR_row
	mov	ss:[bx].REP_bounds.R_top, ax
	mov	ax, ds:[di].SDO_rowCol.CR_column
	mov	ss:[bx].REP_bounds.R_left, ax		

gotBounds:
	;
	; We have the REP_bounds filled in and we know that it's not an
	; empty range. Call a callback for each cell.
	;
	mov	ss:[bx].REP_callback.segment, SEGMENT_CS
	mov	ss:[bx].REP_callback.offset,  offset cs:SearchCellCallback
	mov	es, ss:searchStructSeg
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
	jz	forwardSearch
	call	ProcessRowWiseRangeBackwards
	jmp	quit
forwardSearch:
	call	ProcessRowWiseRange

quit:
	;
	; Carry is set if we've found a match
	;
	lahf					; Save "found match" flag
	add	sp, size RangeEnumParams	; Restore stack frame
	sahf					; Save "found match" flag
	.leave
	ret

quitNotFound:
	clc					; Signal: not found
	jmp	quit
SearchCells	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessRowWiseRangeBackwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the range in a row-wise fashion.

CALLED BY:	ProcessRange
PASS:		ss:bx	= RangeEnumParams
		ds:si	= Spreadsheet instance
		ss:bp	= inherited locals
RETURN:		carry set if a match was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If row-wise (meaning across then down):
		Area 1	active cell -> start of active cell row
		Area 2	range of cells above active cell row
		Area 3	range of cells below active cell row
		Area 4	end of row -> right edge of range
	---------
	|2222222|
	|2222222|
	|11+4444|
	|3333333|
	---------

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessRowWiseRangeBackwards	proc	near
	class	SpreadsheetClass
	uses	ax
	.enter	inherit SpreadsheetSearch

EC <	call	ECCheckInstancePtr					>

	;
	; First process from the active cell to the start of the row.
	; If the active cell is at the start of the row, we don't need to do
	; this.
	;
	mov	ax, ds:[si].SSI_active.CR_column
	cmp	ax, ss:[bx].REP_bounds.R_left
	je	skipArea1
	
	push	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_right
	
	mov	ax, ds:[si].SSI_active.CR_row
	mov	ss:[bx].REP_bounds.R_top, ax
	mov	ss:[bx].REP_bounds.R_bottom, ax

	mov	ax, ds:[si].SSI_active.CR_column
	dec	ax
	mov	ss:[bx].REP_bounds.R_right, ax
	
	call	RangeEnumBackwards		; Process the first part
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_right
	
	LONG jc	quit				; Branch if found a match

skipArea1:
	;
	; Now check the range above the active cell. If the active cell is
	; at the top of the range to search then we don't need to do this.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ax, ss:[bx].REP_bounds.R_top
	je	skipArea2

	tst	ax				;If no rows above this cell,
	jz	skipArea2			; branch

	push	ss:[bx].REP_bounds.R_bottom
						; ax already holds the curRow
	dec	ax
	mov	ss:[bx].REP_bounds.R_bottom, ax
	
	call	RangeEnumBackwards		; Process the next part
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_bottom
	
	LONG jc	quit				; Branch if found a match

skipArea2:
ifdef GPC
	;
	; Ask if we should wrap around, if there's anything to wrap to
	;
ifdef GPC_ONLY
	cmp	ds:[si].SSI_active.CR_row, 127
	jne	notLast
	cmp	ds:[si].SSI_active.CR_column, 127
	je	dontAsk				; at end, no wrapping
else
	mov	ax, ds:[si].SSI_maxRow
	cmp	ax, ds:[si].SSI_active.CR_row
	jne	notLast
	mov	ax, ds:[si].SSI_maxCol
	cmp	ax, ds:[si].SSI_active.CR_column
	jne	dontAsk				; an end, no wrapping
endif
notLast:
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ax, ss:[bx].REP_bounds.R_bottom
	jne	ask
	mov	ax, ds:[si].SSI_active.CR_column
	cmp	ax, ss:[bx].REP_bounds.R_right
	je	dontAsk				; nothing to wrap to
ask:
	mov	ax, offset SearchBackwardEnd
	call	SearchDialog
	cmp	ax, IC_YES
	mov	ss:abortSearch, TRUE
	stc					; pretend match found
	jne	quit				; don't wrap around
	mov	ss:abortSearch, FALSE
dontAsk:
endif
	;
	; Now check the range of cells below the active cell row.
	; If the active cell row is at the bottom of the range we don't need
	; to.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ax, ss:[bx].REP_bounds.R_bottom
	je	skipArea3
	
	cmp	ax, ds:[si].SSI_maxRow
	je	skipArea3

	push	ss:[bx].REP_bounds.R_top
						; ax already holds the curRow
	inc	ax
	mov	ss:[bx].REP_bounds.R_top, ax
	
	call	RangeEnumBackwards		; Process the next part
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_top
	
	jc	quit				; Branch if found a match

skipArea3:
	;
	; Finally, check the area between the right edge of the range and the
	; active cell. We always do this so that we will include the active
	; cell.
	;
	mov	ax, ds:[si].SSI_active.CR_column
	cmp	ax, ds:[si].SSI_maxCol
	clc
	je	quit

	push	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_left

	mov	ss:[bx].REP_bounds.R_left, ax

	mov	ax, ds:[si].SSI_active.CR_row
	mov	ss:[bx].REP_bounds.R_top, ax
	mov	ss:[bx].REP_bounds.R_bottom, ax

	call	RangeEnumBackwards		; Process the final range
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_left
quit:
	.leave
	ret
ProcessRowWiseRangeBackwards	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RangeEnumBackwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls a callback routine for each cell in a range

CALLED BY:	ProcessRowWiseRangeBackwards
PASS:		(same as RangeEnum)
		ss:bx - ptr to RangeEnumParams
		bp - data to pass to callback 
RETURN:		carry set if callback returned carry set (aborted enum)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RangeEnumBackwards	proc	near	uses	ax, cx, es, di
	.enter
	mov	ax, ss:[bx].REP_bounds.R_bottom
beginRow:
	mov	cx, ss:[bx].REP_bounds.R_right
lockCell:
	call	CellLock
	jnc	prevCol
FXIP<	pushdw	ss:[bx].REP_callback					>
FXIP<	call	PROCCALLFIXEDORMOVABLE_PASCAL				>
NOFXIP<	call	ss:[bx].REP_callback					>
	call	CellUnlock

	jc	exit
prevCol:
	dec	cx
	js	prevRow
	cmp	cx, ss:[bx].REP_bounds.R_left
	jae	lockCell
prevRow:
	dec	ax
	js	noMatch
	cmp	ax, ss:[bx].REP_bounds.R_top
	jae	beginRow
noMatch:
	clc
exit:
	.leave
	ret
RangeEnumBackwards	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessRowWiseRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the range in a row-wise fashion.

CALLED BY:	ProcessRange
PASS:		ss:bx	= RangeEnumParams
		ds:si	= Spreadsheet instance
		ss:bp	= inherited locals
RETURN:		carry set if a match was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If row-wise (meaning across then down):
		Area 1	active cell -> end of active cell row
		Area 2	range of cells below active cell row
		Area 3	range of cells above active cell row
		Area 4	left edge of range -> active cell
	---------
	|3333333|
	|3333333|
	|44+1111|
	|2222222|
	---------

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessRowWiseRange	proc	near
	class	SpreadsheetClass
	uses	ax, dx

	.enter	inherit	SpreadsheetSearch

EC <	call	ECCheckInstancePtr		;>
	;
	; First process from after the active cell to the end of the row.
	; If the active cell is at the end of the row, we don't need to do this
	;
	mov	ax, ds:[si].SSI_active.CR_column
	cmp	ax, ss:[bx].REP_bounds.R_right
	je	skipArea1
	;
	; Are there any cells to the right of the active cell?
	; (if not, we're at the right of the spreadsheet)
	;
	cmp	ax, ds:[si].SSI_maxCol		; at right?
	je	skipArea1			; branch if at right
	
	push	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_left
	
	mov	ax, ds:[si].SSI_active.CR_row
	mov	ss:[bx].REP_bounds.R_top, ax
	mov	ss:[bx].REP_bounds.R_bottom, ax

	mov	ax, ds:[si].SSI_active.CR_column
	inc	ax
	mov	ss:[bx].REP_bounds.R_left, ax
	
	clr	dl				; Not all cells
	call	RangeEnum			; Process the first part
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_left
	
	LONG jc	quit				; Branch if found a match

skipArea1:
	;
	; Now check the range below the active cell. If the active cell is
	; at the bottom of the range to search then we don't need to do this.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ax, ss:[bx].REP_bounds.R_bottom
	je	skipArea2
	;
	; Any cells below?
	; (if not, we're at the bottom of the spreadsheet)
	;
	cmp	ax, ds:[si].SSI_maxRow		; any cells below?
	je	skipArea2			; branch if no cells below

	push	ss:[bx].REP_bounds.R_top
						; ax already holds the curRow
	inc	ax
	mov	ss:[bx].REP_bounds.R_top, ax
	
	clr	dl				; Not all cells
	call	RangeEnum			; Process the next part
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_top
	
	LONG jc	quit				; Branch if found a match

skipArea2:
ifdef GPC
	;
	; Ask if we should wrap around, if there's anything to wrap to
	;
	mov	ax, ds:[si].SSI_active.CR_row
	or	ax, ds:[si].SSI_active.CR_column
	jz	dontAsk				; at top left, no wrap
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ax, ss:[bx].REP_bounds.R_top
	jne	ask
	mov	ax, ds:[si].SSI_active.CR_column
	cmp	ax, ss:[bx].REP_bounds.R_left
	je	dontAsk				; nothing to wrap to
ask:
	mov	ax, offset SearchForwardEnd
	call	SearchDialog
	cmp	ax, IC_YES
	mov	ss:abortSearch, TRUE
	stc					; pretent match found
	jne	quit				; don't wrap around
	mov	ss:abortSearch, FALSE
dontAsk:
endif
	;
	; Now check the range of cells above the active cell row.
	; If the active cell row is at the top of the range we don't need to.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	cmp	ax, ss:[bx].REP_bounds.R_top
	je	skipArea3
	;
	; Are there any cells above the active cell?
	; (if not, we're at the top of the spreadsheet)
	;
	tst	ax				; at top?
	jz	skipArea3			; branch if at top

	push	ss:[bx].REP_bounds.R_bottom
						; ax already holds the curRow
	dec	ax
	mov	ss:[bx].REP_bounds.R_bottom, ax
	
	clr	dl				; Not all cells
	call	RangeEnum			; Process the next part
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_top
	
	jc	quit				; Branch if found a match

skipArea3:
	;
	; Finally, check the area between the left edge of the range and the
	; active cell. We always do this so that we will include the active
	; cell.
	;
	push	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_right

	mov	ax, ds:[si].SSI_active.CR_row
	mov	ss:[bx].REP_bounds.R_top, ax
	mov	ss:[bx].REP_bounds.R_bottom, ax

	mov	ax, ds:[si].SSI_active.CR_column
	mov	ss:[bx].REP_bounds.R_right, ax

	clr	dl				; Not all cells
	call	RangeEnum			; Process the final range
						; Carry set if we found a match
	pop	ss:[bx].REP_bounds.R_top, \
		ss:[bx].REP_bounds.R_bottom, \
		ss:[bx].REP_bounds.R_right
quit:
	.leave
	ret
ProcessRowWiseRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchTextObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search text objects

CALLED BY:	SpreadsheetSearch
PASS:		ds:si	= Instance ptr
		ss:bp	= inherited locals
RETURN:		carry set if we found the string
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchTextObjects	proc	near
	clc				; No text objects supported yet
	ret
SearchTextObjects	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a cell for a string.

CALLED BY:	RangeEnum
PASS:		carry set if the cell exists (always)
		ss:bp	= inherited locals
		*es:di	= Cell data
		ax	= Row
		cx	= Column
RETURN:		dl unchanged
		carry set if we found a match (and want to abort)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchCellCallback	proc	far
	.enter	inherit	SpreadsheetSearch
	
	mov	ss:foundCell.CR_row, ax
	mov	ss:foundCell.CR_column, cx

	test	ss:searchArea, mask SSA_SEARCH_FORMULAS
	jz	skipFormulas
	call	SearchFormula
	jc	found

skipFormulas:
	test	ss:searchArea, mask SSA_SEARCH_VALUES
	jz	skipValues
	call	SearchValue
	jc	found

skipValues:
	test	ss:searchArea, mask SSA_SEARCH_NOTES
	jz	skipNotes			;branch (carry clear)
	call	SearchNotes
skipNotes:

found:
	.leave
	ret
SearchCellCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchFormula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a cell formula looking for a match.

CALLED BY:	SearchCellCallback
PASS:		*es:di	= Cell data
		(ax,cx)	= (r,c) of cell
		ss:bp	= inherited locals
RETURN:		carry set if a match was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version
	witt	 1/ 5/94	DBCS-ized string searching

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchFormula	proc	near
	uses	ax, bx, cx, dx, di, si, bp, es, ds
	.enter	inherit SpreadsheetSearch

SBCS<	sub	sp, MAX_CELL_TEXT_SIZE+(size char)			>
DBCS<	sub	sp, MAX_CELL_TEXT_SIZE+(size wchar)			>
	mov	bx, sp				;ss:bx <- ptr to the buffer

	;
	; Format the cell text into the buffer.
	;	ss:bx	= Pointer to the buffer
	;	*es:di	= Cell data
	;	ds:si	= Spreadsheet instance
	;
	push	bp
	mov	bp, bx
	mov	dx, ss				;ss:bp <- ptr to buffer
	call	FormatCellContents		;cx <- length of string
	mov	di, bp				;ss:di <- ptr to text
	pop	bp
	clc					;If no string, no match
	jcxz	quit
	;
	; For TextSearchInString(), we want:
	;	es:bp - ptr to start of string
	;	es:di - ptr to string to search in
	;	es:bx - end of string to search in
	;	dx - length of string to search in
	;
	;	ds:si - ptr to search string
	;	cx - length of search string
	;
	;	al - SearchOptions
	;
	push	di
	mov	bx, di
	add	bx, cx				;es:bx <- ptr to NULL
DBCS<	add	bx, cx				; (byte offset)		>
	LocalPrevChar	esbx			;es:bx <- ptr to end of string
	mov	es, dx				;es:di <- ptr to string to srch
	mov	dx, cx				;dx <- length of string

	mov	ds, ss:searchStructSeg
	mov	si, offset SRS_searchString	;ds:si <- ptr to search string
	clr	cx				;cx <- NULL-terminated

	mov	al, ds:SRS_params		;al <- SearchOptions
	andnf	al, not mask SO_BACKWARD_SEARCH	;The "backward" search 
						; refers to cells/records,
						; not to the type of search
						; we do within the cells - we
						; always do a forward search
						; here.	
	push	bp
	mov	bp, di   			;(dx = length)
	call	TextSearchInString
	pop	bp
	pop	si				;ds:si <- ptr to start of string
	cmc					;reverse carry
	jnc	quit				;branch if not found
	;
	; A match was found.
	;	ds:si - ptr to string to match (from dialog).
	;	es:bp - ptr to start of string (from cell).
	;	es:di - ptr to start of where string found.
	;	cx - # chars matched
	;
	sub	di, si				;di <- offset from 0
DBCS<	shr	di, 1				;di <- char offset		>
	mov	ss:startPos, di			;save char start pos
	add	di, cx
	mov	ss:endPos, di			;save end pos
	ornf	ss:foundArea, mask SSA_SEARCH_FORMULAS
	stc					;carry <- match found

	;;; Carry must be set here
quit:
	lahf				; Save "found match" flag (carry)
SBCS<	add	sp, MAX_CELL_TEXT_SIZE+(size char)	; Restore the stack	>
DBCS<	add	sp, MAX_CELL_TEXT_SIZE+(size wchar)	; Restore the stack	>
	sahf				; Restore "found match" flag (carry)
	.leave
	ret
SearchFormula	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a cell value looking for a match.

CALLED BY:	SearchCellCallback
PASS:		*es:di	= Cell data
		ss:bp	= inherited locals
RETURN:		carry set if a match was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchValue	proc	near
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter	inherit	SpreadsheetSearch

	mov	di, es:[di]		; es:di <- ptr to cell.
	;
	; Allocate a stack frame for any string we need to format.
	;
SBCS<	sub	sp, MAX_CELL_TEXT_SIZE + (size char)	;allocate stack frame	>
DBCS<	sub	sp, MAX_CELL_TEXT_SIZE + (size wchar)	;allocate stack frame	>
	mov	bx, sp				;ss:bx <- ptr to stack frame

	call	FormatCellResult		;format the result into ss:bx

	push	bp
	mov	bp, di
	andnf	al, not mask SO_BACKWARD_SEARCH
PrintMessage <DX should have length in it>
DBCS<	clr	cx			; should be in SBCS too		>
	call	TextSearchInString
	pop	bp
	cmc					;reverse carry
	jnc	quit				;branch if no match
	;
	; We found a match. Save the appropriate information.
	;
	mov	ss:foundArea, mask SSA_SEARCH_VALUES
	;;; Carry must be set here.

quit:
	lahf				; Save "found match" flag (carry)
SBCS<	add	sp, MAX_CELL_TEXT_SIZE + (size char)	; Restore stack frame	>
DBCS<	add	sp, MAX_CELL_TEXT_SIZE + (size wchar)	; Restore stack frame	>
	sahf				; Restore "found match" flag (carry)
	.leave
	ret
SearchValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatCellResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell into a buffer.

CALLED BY:	SearchValue
PASS:		es:di	= Cell ptr
		ds:si	= Spreadsheet instance
		ss:bx	= Buffer to format into
RETURN:		es:di	= ptr to formatted result
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatCellResult	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, bp, di, es
	.enter

EC <	call	ECCheckInstancePtr		;>

	cmp	es:[di].CC_type, CT_FORMULA
	je	formatFormula
	;
	; Not a formula, either text or value.
	;
	cmp	es:[di].CC_type, CT_TEXT
	je	formatText
	;
	; It's a number. Format the number into the buffer and return a
	; pointer to the formatted result.
	;
	; ds:si	= Spreadsheet instance
	; es:di	= Cell data
	;
	push	bx			; Save buffer pointer
	mov	ax, es:[di].CC_attrs	; ax <- attributes token
	mov	bx, offset CA_format	; bx <- field
	call	StyleGetAttrByTokenFar	; ax <- format token

	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	cx, ds:[si].SSI_formatArray

	segmov	ds, es, si		; ds:si <- ptr to the number
	lea	si, es:[di].CC_current

	segmov	es, ss, di		; es:di <- destination
	pop	di

	call	FloatFormatNumber	; Format the number

quit:
	.leave
	ret

formatFormula:
	;
	; Format the expression and get a pointer to the result.
	;
	mov	dx, es			; dx:bp <- ptr to cell data
	mov	bp, di

	segmov	es, ss, di		; es:di <- buffer to fill
	mov	di, bx

	call	FormulaCellGetResult	; Format the result
	jmp	quit

formatText:
	;
	; Get a pointer to the text in the cell.
	;
	add	di, (size CellText)		;es:di <- ptr to text
	jmp	quit
FormatCellResult	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a cell note looking for a match.

CALLED BY:	SearchCellCallback
PASS:		ds:si	= Spreadsheet instance
		*es:di	= Cell data
		ss:bp	= SpreadsheetSearchParams
RETURN:		carry set if a match was found
		    SSP_found with SSF_SEARCH_VALUES set
		    SSP_start/endPos set to the range to select
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchNotes	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter	inherit	SpreadsheetSearch

	mov	di, es:[di]			; es:di <- cell ptr
	tst	es:[di].CC_notes.segment	; Check for a note
	jz	quit				; Branch if not found (c == 0)
	;
	; The note exists, lock it down and search it.
	;
	mov	ax, es:[di].CC_notes.segment
	mov	di, es:[di].CC_notes.offset
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	call	DBLock				; Lock the note down
						; es:di -> note text
PrintMessage <DX should have length in it!>
	;
	; Set up the pointers and do the search.
	;
	push	bp
	mov	bp, di
DBCS<	clr	cx			; ds:si string null terminated	>
	call	TextSearchInString
	pop	bp, bx
	pushf					; Save "found match" flag
	;
	; Unlock the note.
	;
	segmov	es, ds, ax			; es <- segment address of note
	call	DBUnlock			; Release the note
	popf					; carry set if not found
	jnc	quit				; Branch if no match
	;
	; There was a match.
	; di = Offset to start of match
	; dx = Offset to end of match
	;
	mov	ss:foundArea, mask SSA_SEARCH_NOTES
	mov	ss:startPos, di
	add	di, cx
	mov	ss:endPos, di
	stc					;carry <- match found
	
	;;; Carry must be set here
quit:
	.leave
	ret
SearchNotes	endp


SpreadsheetSearchCode	ends


