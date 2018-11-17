COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetScroll.asm

AUTHOR:		Gene Anderson, May 15, 1991

ROUTINES:
	Name				Description
	----				-----------
	MSG_META_CONTENT_TRACK_SCROLLING	Make scrolls on cell boundaries
	MSG_SPREADSHEET_SCALE		Scale the spreadsheet view

EXT	RecalcViewDocSize		Recalculate document size for view

INT	ReturnXScroll16			Finish word-sized x scroll
INT	ReturnXScroll32			Finish dword-sized x scroll
INT	ReturnYScroll16			Finish word-sized y scroll
INT	ReturnYScroll32			Finish dword-sized y scroll

INT	NScrollNoChange			Do nothing scroll handler
INT	NScrollNoScroll			Do not scroll handler
INT	NScrollLeftPage			Normalized scroll left one page
INT	NScrollRightPage		Normalized scroll right one page
INT	NScrollUpPage			Normalized scroll up one page
INT	NScrollDownPage			Normalized scroll down one page
INT	NScrollLeftColumn		Normalized scroll left one column
INT	NScrollRightColumn		Normalized scroll right one column
INT	NScrollUpRow			Normalized scroll up one row
INT	NScrollDownRow			Normalized scroll down one row
INT	NScrollGeneral			Handle general normalized scroll
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/15/91		Initial revision

DESCRIPTION:
	

	$Id: spreadsheetScroll.asm,v 1.1 97/04/07 11:14:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode	segment	resource

scrollRoutines	nptr \
	NScrollNoChange,			;SA_NOTHING		(x)
	NScrollNoChange,			;SA_NOTHING		(y)
	NScrollNoChange,			;SA_TO_BEGINNING	(x)
	NScrollNoChange,			;SA_TO_BEGINNING	(y)
	NScrollLeftPage,			;SA_PAGE_BACK		(x)
	NScrollUpPage,				;SA_PAGE_BACK		(y)
	NScrollLeftColumn,			;SA_INC_BACK		(x)
	NScrollUpRow,				;SA_INC_BACK		(y)
	NScrollRightColumn,			;SA_INC_FWD		(x)
	NScrollDownRow,				;SA_INC_FWD		(y)
	NScrollGeneral,				;SA_DRAGGING		(x)
	NScrollGeneral,				;SA_DRAGGING		(y)
	NScrollRightPage,			;SA_PAGE_FWD		(x)
	NScrollDownPage,			;SA_PAGE_FWD		(y)
	NScrollGeneral,				;SA_TO_END		(x)
	NScrollGeneral,				;SA_TO_END		(y)
	NScrollGeneral,				;SA_SCROLL		(x)
	NScrollGeneral,				;SA_SCROLL		(y)
	NScrollInto,				;SA_SCROLL_INTO		(x)
	NScrollInto,				;SA_SCROLL_INTO		(y)
	NScrollNoChange,			;SA_INITIAL_POS		(x)
	NScrollNoChange,			;SA_INITIAL_POS		(y)
	NScrollKeepVisCell,			;SA_SCALE		(x)
	NScrollKeepVisCell,			;SA_SCALE		(y)
	NScrollGeneral,				;SA_PAN			(x)
	NScrollGeneral,				;SA_PAN			(y)
	NScrollSelect,				;SA_DRAG_SCROLL	(x)
	NScrollSelect,				;SA_DRAG_SCROLL	(y)
	NScrollKeepVisCell,			;SA_SCROLL_FOR_SIZE_CHANGE (x)
	NScrollKeepVisCell			;SA_SCROLL_FOR_SIZE_CHANGE (y)

CheckHack	<ScrollAction eq (length scrollRoutines)/2>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetNormalizePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle normalized scrolling, to keep a cell in the upper left
CALLED BY:	MSG_META_CONTENT_TRACK_SCROLLING

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx:dx - TrackScrollingParams
RETURN:		ss:bp.TSP_change - (x,y) change in position
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/15/91		Initial version
	cbh	6/15/94		Changed to always move the selection on a
				page up/down.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNormalizePosition		method dynamic SpreadsheetClass,
					MSG_META_CONTENT_TRACK_SCROLLING

	push	si
	mov	si, di				;ds:si <- ptr to instance data
	;
	; Common setup for a scroll
	;
	call	GenSetupTrackingArgs
	push	cx				;must save cx
	;
	; Call the appropriate scrolling routine based on
	; the ScrollAction and whether it is horizontal
	; or vertical.
	;
	clr	bh
	mov	bl, ss:[bp].TSP_action		;bx <- ScrollAction
	shl	bx, 1				;*2 for each (x,y) pair
	shl	bx, 1				;*2 for each (size nptr) = 2

	test	ss:[bp].TSP_flags, mask SF_VERTICAL
	jz	horizontal
	add	bx, (size nptr)
horizontal:
	call	cs:scrollRoutines[bx]		;call appropriate routine
EC <	call	ECCheckTrackingArgs		;>
	;
	; Return adjusted scroll amount
	;
	pop	cx
	call	GenReturnTrackingArgs		;sends NORMALIZE_COMPLETE
 	pop	si

	;
	; Try to keep the current selection onscreen.  8/10/93 cbh
	; (Not if we have the target.  8/31/93 cbh)   (And only on page up/down.
	; -cbh 1/25/94).   (And now only on a keyboard-induced scroll. 6/15/94)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset
	test	ds:[di].SSI_flags, mask SF_IS_APP_TARGET
	jz	exit

	test	ss:[bp].TSP_flags, mask SF_KBD_RELATED_SCROLL
	jz	exit

	mov	al, ss:[bp].TSP_action
	cmp	al, SA_PAGE_FWD
	je	adjustSelection
	cmp	al, SA_PAGE_BACK
	jne	exit

adjustSelection:
	mov	bl, ss:[bp].TSP_flags			
	
	sub	sp, size SpreadsheetRangeParams
	mov	bp, sp
	mov	ax, SPREADSHEET_ADDRESS_USE_SELECTION
	mov	ss:[bp].SRP_selection.CR_start.CR_row,ax
	mov	ss:[bp].SRP_selection.CR_start.CR_column,ax
	mov	ss:[bp].SRP_selection.CR_end.CR_row, ax
	mov	ss:[bp].SRP_selection.CR_end.CR_column, ax

	mov	ax, ds:[di].SSI_active.CR_row
	mov	dx, ds:[di].SSI_active.CR_column
	
	test	bl, mask SF_VERTICAL
	mov	bx, SPREADSHEET_ADDRESS_ON_SCREEN
	jz	10$					
	mov	ax, bx				  ;vertical, keep row onscreen
	jmp	short 20$
10$:
	mov	dx, bx				  ;horiz, keep col onscreen
20$:
	mov	ss:[bp].SRP_active.CR_row, ax
	mov	ss:[bp].SRP_active.CR_column, dx
	mov	dx, size SpreadsheetRangeParams
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SPREADSHEET_SET_SELECTION

	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size SpreadsheetRangeParams

exit:
	ret
SpreadsheetNormalizePosition	endm

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTrackingArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the tracking args are valid before we return them

CALLED BY:	SpreadsheetNormalizePosition()
PASS:		ss:bp - TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTrackingArgs		proc	near
	uses	ax, bx, cx, dx, bp
	class	SpreadsheetClass
	.enter

	pushf
	mov	bx, bp				;ss:bx <- TrackScrollingParams
	;
	; Check x offset
	;
	clr	cx				;cx <- column origin
	pushdw	ds:[si].SSI_offset.PD_x
	mov	bp, sp
	incdw	ss:[bp]				;account for initial -1 offset
	call	Pos32ToColRel			;ax <- column #
	cmp	cx, 0				;not at edge?
	je	xOffsetOK
	cmp	dx, 0				;not at edge?
	je	xOffsetOK
	WARNING	SPREADSHEET_SCROLL_RETURNING_BAD_OFFSET
xOffsetOK:
	movdw	dxax, ss:[bx].TSP_oldOrigin.PD_x
	adddw	dxax, ss:[bx].TSP_change.PD_x
	cmpdw	dxax, ss:[bp].PD_x		;at an integral position?
	WARNING_NE SPREADSHEET_SCROLL_RETURNING_BAD_OFFSET
	add	sp, (size SSI_offset.PD_x)
	;
	; Check y offset
	;
	clr	cx				;cx <- row origin
	pushdw	ds:[si].SSI_offset.PD_y
	mov	bp, sp
	incdw	ss:[bp]				;account for initial -1 offset
	call	Pos32ToRowRel			;ax <- row #
	cmp	cx, 0				;not at edge?
	je	yOffsetOK
	cmp	dx, 0				;not at edge?
	je	yOffsetOK
	WARNING SPREADSHEET_SCROLL_RETURNING_BAD_OFFSET
yOffsetOK:
	movdw	dxax, ss:[bx].TSP_oldOrigin.PD_y
	adddw	dxax, ss:[bx].TSP_change.PD_y
	cmpdw	dxax, ss:[bp].PD_x		;at an integral position?
	WARNING_NE SPREADSHEET_SCROLL_RETURNING_BAD_OFFSET
	add	sp, (size SSI_offset.PD_y)

	popf

	.leave
	ret
ECCheckTrackingArgs		endp

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnYDelta32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate and return the delta required to get to a row

CALLED BY:	NScrollKeepVisCell()
PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
		ax - row to return delta for
RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnYDelta32		proc	near
EC <	call	ECCheckInstancePtr		;>

	clr	dx				;dx <- start row
	call	RowGetRelPos32			;ax:dx <- position of row
	subdw	axdx, ss:[bp].TSP_oldOrigin.PD_y
	GOTO	ReturnYScroll32
ReturnYDelta32		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnXDelta32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate and return the delta required to get to a column

CALLED BY:	NScrollKeepVisCell()
PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
		cx - column to return delta for
RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnXDelta32		proc	near
EC <	call	ECCheckInstancePtr		;>

	clr	dx				;dx <- start column
	call	ColumnGetRelPos32		;ax:dx <- position of column
	subdw	axdx, ss:[bp].TSP_oldOrigin.PD_x
	GOTO	ReturnXScroll32
ReturnXDelta32		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnXScroll16, ReturnXScroll32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return x scroll value
CALLED BY:	INTERNAL: ScrollLeftColumn(), ScrollRightColumn()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
		ax:dx - x scroll amount (ReturnXScroll32)
		dx - x scroll amount (ReturnXScroll16)
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReturnXScroll16	proc	near
	mov	ax, dx
	cwd					;sign extend to dword
	xchg	ax, dx				;ax:dx <- dword value
	FALL_THRU	ReturnXScroll32
ReturnXScroll16	endp

ReturnXScroll32	proc	near
	class	SpreadsheetClass
	uses	bx, cx, dx
	.enter
EC <	call	ECCheckInstancePtr		;>

;
; Added  4/10/95, -cassie
; Since the current offset is used to calculate the scroll amount, we 
; want to make sure the offset is valid. It may not be if the spreadsheet
; size has changed, as when there are large point size changes. See bug
; 33261 for more info. (Though I never saw the problem in the X dimension, 
; this code is added as a safeguard, and to keep this routine like its
; Y counterpart.)  Set X offset to MIN(X offset, right bound - 1).
;
	movdw	cxbx, ds:[si].SSI_bounds.RD_right
	decdw	cxbx				; account for strangeness
	jgedw	cxbx, ds:[si].SSI_offset.PD_x, $10
	movdw	ds:[si].SSI_offset.PD_x, cxbx
$10:

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added  3/28/93, -jw
; This code is designed to ensure that we never mistakenly return an offset
; that is less than zero. This just ain't allowed.
;
	;
	; Now we grovel... We simply can not return an offset that is
	; less than zero. To make sure this doesn't happen we force
	; oldOrigin+change >= -1.
	;
	adddw	axdx, ds:[si].SSI_offset.PD_x
	jgedw	axdx, -1, changeInBounds

	;
	; axdx needs to hold the final value we want if we scroll too far back.
	;
	movdw	axdx, -1

changeInBounds:

	;
	; So now ax.dx = The new origin. We refigure the change by subtracting
	; off the old origin.
	;
	subdw	axdx, ds:[si].SSI_offset.PD_x

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added  3/30/93 -jw
; This code handles the fact that the origin of the view will not always
; be what we tell it to be. This messes up our idea of a cached position.
;
; To handle this we make a few assumptions:
;	SSI_offset is where the view *should* have been
;	TSP_oldOrigin is where the view is
;
; The idea here is that we want the origin to end up at a row/column boundary.
; SSI_offset will always hold a value that falls on a column boundary. Since
; all of the scrolling code uses this as the basis for computing the scroll
; amount, adding the suggested change (axdx) to SSI_offset will always get
; us to a cell boundary.
;
; The problem here is that we need to return a scroll amount to the view
; to allow it to scroll to the proper location.
;
; Here's how we make that work:
;	(SSI_offset + 1) - TSP_oldOrigin
;		This is how far off the last scroll was from where we
;		told it to go.
;
; Poof, we take this amount and add it to the distance that we would suggest
; the view scrolled if TSP_oldOrigin had been where we told it to go last time.
;
; In essence we are saying "I know you screwed up last time, so here's a little
; extra to put you in the right place this time".
;
	;
	; Get the old "correct" origin for later computation.
	;
	movdw	cxbx, ds:[si].SSI_offset.PD_x	; cx.bx <- old value

	;
	; The value passed to us should always put us on a column boundary.
	;
	adddw	ds:[si].SSI_offset.PD_x, axdx	; Set new value

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Added  4/19/95, -cassie
; This code is designed to ensure that we never mistakenly return an offset
; that is outside the spreadsheet bottom. This can happen when scaling
; (see bug 35189), by adding the change amount to the old (unscaled) origin.
;
	cmp	ss:[bp].TSP_action, SA_SCALE	
	jne	haveOffset
	;
	; Calculate the offset of the last row.
	;
	pushdw	cxbx				;save old offset
	pushdw	axdx				;save the change amount
	mov	cx, ds:[si].SSI_maxCol
	clr	dx				;dx <- start column
	call	ColumnGetRelPos32		;ax.dx <- offset of last row
	decdw	axdx				;account for strangeness
	movdw	cxbx, axdx			;cx.bx <- offset of last row
	popdw	axdx				;ax.dx <- change
	;
	; If the new offset falls before the last column, we can use it.
	; Else use the last column as the new offset. Calculate what the
	; old offset would have been if adding the change amount to
	; it landed on the last column.
	;
	jledw	ds:[si].SSI_offset.PD_x, cxbx, noScale
	movdw	ds:[si].SSI_offset.PD_x, cxbx	;save it as new offset
	subdw	cxbx, axdx			;calculate old origin
	add	sp, size dword			;remove cx, bx from stack
	jmp	haveOffset
noScale:
	popdw	cxbx				;restore old offset
haveOffset:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	;
	; Figure the amount that the view origin should change in order to get
	; it to where our offset is:
	;	change + ((SSI_offset + 1) - TSP_oldOrigin)
	;
	; axdx	= change amount
	;
	adddw	axdx, cxbx		; Add in the old SSI_offset
	incdw	axdx			; Account for the strangeness
	subdw	axdx, ss:[bp].TSP_oldOrigin.PD_x

	;
	; Save this as the final change amount
	;
	movdw	ss:[bp].TSP_change.PD_x, axdx
	
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

EC <	jgedw	ds:[si].SSI_offset.PD_x, -1, offsetOK >
EC <	ERROR SPREADSHEET_SCROLL_OFFSET_OFF_DOCUMENT >
EC <offsetOK:					>
	andnf	ds:[si].SSI_gsRefCount, not (mask SSRCAF_TRANSFORM_VALID)
	.leave
	ret
ReturnXScroll32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnYScroll16, ReturnYScroll32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return y scroll value
CALLED BY:	INTERNAL: ScrollUpRow(), ScrollDownRow()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
		ax:dx - y scroll amount (ReturnYScroll32)
		dx - y scroll amount (ReturnYScroll16)
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReturnYScroll16	proc	near
	mov	ax, dx
	cwd					;sign extend to dword
	xchg	ax, dx				;ax:dx <- dword
	FALL_THRU	ReturnYScroll32
ReturnYScroll16	endp

ReturnYScroll32	proc	near
	class	SpreadsheetClass
	uses	bx, cx, dx
	.enter
EC <	call	ECCheckInstancePtr		;>

;
; Added  4/10/95, -cassie
; Since the current offset is used to calculate the scroll amount, we 
; want to make sure the offset is valid. It may not be if the spreadsheet
; size has changed, as when there are large point size changes. See bug
; 33261 for more info. Set Y offset to MIN(Y offset, bottom bound - 1).
;
	movdw	cxbx, ds:[si].SSI_bounds.RD_bottom	
	decdw	cxbx				; account for strangeness
	jgedw	cxbx, ds:[si].SSI_offset.PD_y, $10
	movdw	ds:[si].SSI_offset.PD_y, cxbx
$10:		


;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added  3/28/93, -jw
; This code is designed to ensure that we never mistakenly return an offset
; that is less than zero. This just ain't allowed.
;
	;
	; Now we grovel... We simply can not return an offset that is
	; less than zero. To make sure this doesn't happen we force
	; oldOrigin+change >= -1.
	;
	adddw	axdx, ds:[si].SSI_offset.PD_y
	jgedw	axdx, -1, changeInBounds

	;
	; axdx needs to hold the final value we want if we scroll too far back.
	;
	movdw	axdx, -1

changeInBounds:

	;
	; So now ax.dx = The new origin. We refigure the change by subtracting
	; off the old origin.
	;
	subdw	axdx, ds:[si].SSI_offset.PD_y

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added  3/30/93 -jw
; This code handles the fact that the origin of the view will not always
; be what we tell it to be. This messes up our idea of a cached position.
;
; To handle this we make a few assumptions:
;	SSI_offset is where the view *should* have been
;	TSP_oldOrigin is where the view is
;
; The idea here is that we want the origin to end up at a row/column boundary.
; SSI_offset will always hold a value that falls on a column boundary. Since
; all of the scrolling code uses this as the basis for computing the scroll
; amount, adding the suggested change (axdx) to SSI_offset will always get
; us to a cell boundary.
;
; The problem here is that we need to return a scroll amount to the view
; to allow it to scroll to the proper location.
;
; Here's how we make that work:
;	(SSI_offset + 1) - TSP_oldOrigin
;		This is how far off the last scroll was from where we
;		told it to go.
;
; Poof, we take this amount and add it to the distance that we would suggest
; the view scrolled if TSP_oldOrigin had been where we told it to go last time.
;
; In essence we are saying "I know you screwed up last time, so here's a little
; extra to put you in the right place this time".
;
	;
	; Get the old "correct" origin for later computation.
	;
	movdw	cxbx, ds:[si].SSI_offset.PD_y	; cx.bx <- old value
	;
	; The value passed to us should always put us on a row boundary.
	;
	adddw	ds:[si].SSI_offset.PD_y, axdx	; Set new value

;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Added  4/19/95, -cassie
; This code is designed to ensure that we never mistakenly return an offset
; that is outside the spreadsheet bottom. This can happen when scaling
; (see bug 35189), by adding the change amount to the old (unscaled) origin.
;
	cmp	ss:[bp].TSP_action, SA_SCALE	
	jne	haveOffset
	;
	; Calculate the offset of the last row.
	;
	pushdw	cxbx				;save old offset
	pushdw	axdx				;save the change amount
	mov	ax, ds:[si].SSI_maxRow
	clr	dx				;dx <- start row
	call	RowGetRelPos32			;ax.dx <- offset of last row
	decdw	axdx				;account for strangeness
	movdw	cxbx, axdx			;cx.bx <- offset of last row
	popdw	axdx				;ax.dx <- change
	;
	; If the new offset falls before the last row, we can use it.
	; Else use the last row as the new offset. Calculate what the
	; old offset would have been if adding the change amount to
	; it landed on the last row.
	;
	jledw	ds:[si].SSI_offset.PD_y, cxbx, noScale
	movdw	ds:[si].SSI_offset.PD_y, cxbx	;save it as new offset
	subdw	cxbx, axdx			;calculate old origin
	add	sp, size dword			;remove cx, bx from stack
	jmp	haveOffset
noScale:
	popdw	cxbx				;restore old offset
haveOffset:
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

	;
	; Figure the amount that the view origin should change in order to get
	; it to where our offset is:
	;	change + ((SSI_offset + 1) - TSP_oldOrigin)
	;
	; axdx	= change amount
	; cxbx	= old SSI_offset
	;
	adddw	axdx, cxbx		; Add in the old SSI_offset
	incdw	axdx			; Account for the strangeness
	subdw	axdx, ss:[bp].TSP_oldOrigin.PD_y

	;
	; Save this as the final change amount
	;
	movdw	ss:[bp].TSP_change.PD_y, axdx
	
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

EC <	jgedw	ds:[si].SSI_offset.PD_y, -1, offsetOK >
EC <	ERROR	SPREADSHEET_SCROLL_OFFSET_OFF_DOCUMENT >
EC <offsetOK:					>
	andnf	ds:[si].SSI_gsRefCount, not (mask SSRCAF_TRANSFORM_VALID)
	.leave
	ret
ReturnYScroll32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollNoChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine for no change in passed scrolling offsets
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollNoChange	proc	near
	ret
NScrollNoChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollUpPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling up a page.
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This (and NScrollLeftPage) would be much more efficient
	if there were a PositionToCell() routine that dealt with
	negative offsets.
	Another (perhaps easier) optimization would be adding a routine
	to round (actually truncate) to the nearest cell row boundary.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollUpPage	proc	near
	class	SpreadsheetClass
locals	local	CellLocals

	.enter

EC <	call	ECCheckInstancePtr		;>
	call	CreateGState			;di <- handle of GState
	call	GetWinBounds32			;(cx,dx) <- window size
	call	DestroyGState
	;
	; Figure out where the top of the window, minus the height of
	; the window is.  In other words, we want to move up the height
	; of the window.
	;
	dec	dx				;so we don't go too far
	sub	ss:locals.CL_docBounds.RD_top.low, dx
	sbb	ss:locals.CL_docBounds.RD_top.high, 0

	;
	; This is just wrong. We want to compute the distance
	; relative to <zero> and then we want to limit ourselves
	; to scrolling only as far as the minimum row.
	;
;;;	push	bp
;;;	lea	bp, ss:locals.CL_docBounds.RD_top
;;;	call	SSGetMinRow
;;;	mov	cx, dx				; minimum row
;;;	call	Pos32ToRowRel			;ax <- nearest row
;;;	pop	bp

	push	bp
	lea	bp, ss:locals.CL_docBounds.RD_top
	clr	cx				;relative to top
	call	Pos32ToRowRel			;ax <- nearest row
	pop	bp

	;
	; Now check that we haven't gone too far.
	;	
	call	SSGetMinRow			;dx <- min row
	
	cmp	ax, dx
	jae	rowOK
	mov	ax, dx				;use min row
rowOK:

	mov	ds:[si].SSI_visible.CR_start.CR_row, ax
	.leave
	GOTO	ReturnYDelta32
NScrollUpPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollDownPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling down a page.
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollDownPage	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_visible.CR_end.CR_row
	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	cmp	ax, dx				;single row?
	ja	scrollOK			;branch if more than one row

	cmp	ax, ds:[si].SSI_maxRow		;already at max, don't bump!
	jae	scrollOK			;  (cbh 3/15/94)

	inc	ax				;ax <- row below

scrollOK:
	call	RowGetRelPos16			;dx <- position of bottom row

	mov	ds:[si].SSI_visible.CR_start.CR_row, ax

	GOTO	ReturnYScroll16
NScrollDownPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollLeftPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling left a page
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollLeftPage	proc	near
	class	SpreadsheetClass
locals	local	CellLocals

	.enter

EC <	call	ECCheckInstancePtr		;>
	call	CreateGState			;di <- handle of GState
	call	GetWinBounds32			;(cx,dx) <- size
	call	DestroyGState
	;
	; Figure out where the left of the window, minus the width of
	; the window is.  In other words, we want to move left the
	; width of the window.
	;
	dec	cx				;so we don't go too far
	sub	ss:locals.CL_docBounds.RD_left.low, cx
	sbb	ss:locals.CL_docBounds.RD_left.high, 0

	;
	; This is just wrong. We want to compute the distance
	; relative to <zero> and then we want to limit ourselves
	; to scrolling only as far as the minimum column.
	;
;;;	push	bp
;;;	lea	bp, ss:locals.CL_docBounds.RD_left
;;;	call	SSGetMinColumn
;;;	mov	cx, dx				; minimum column
;;;	call	Pos32ToColRel			;ax <- nearest column
;;;	pop	bp
	
	push	bp
	lea	bp, ss:locals.CL_docBounds.RD_left
	clr	cx				;relative to left
	call	Pos32ToColRel			;ax <- nearest column
	pop	bp

	;
	; Now check that we haven't gone too far.
	;	
	call	SSGetMinColumn			;dx <- min column
	
	cmp	ax, dx
	jae	colOK
	mov	ax, dx				;use min column
colOK:

	mov	ds:[si].SSI_visible.CR_start.CR_column, ax
	mov	cx, ax				;cx <- column
	.leave
	GOTO	ReturnXDelta32
NScrollLeftPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollRightPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling right a page
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollRightPage	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_visible.CR_end.CR_column
	mov	dx, ds:[si].SSI_visible.CR_start.CR_column
	cmp	cx, dx				;single column?
	ja	scrollOK			;branch if more than one column

	cmp	cx, ds:[si].SSI_maxCol		;already at max, don't bump!
	jae	scrollOK			;  (3/15/94 cbh)

	inc	cx				;cx <- column to right

scrollOK:
	call	ColumnGetRelPos16
	mov	ds:[si].SSI_visible.CR_start.CR_column, cx

	GOTO	ReturnXScroll16
NScrollRightPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollUpRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling up a row.
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollUpRow	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_visible.CR_start.CR_row	;ax <- top row
	call	GetPreviousRow			;ax <- row above top
	jc	noScroll
	mov	ds:[si].SSI_visible.CR_start.CR_row, ax	;store new top
	call	RowGetHeight			;dx <- height of row above first
	neg	dx				;dx <- scroll up
	GOTO	ReturnYScroll16

noScroll:
	clr	dx				;dx <- no scroll
	GOTO	ReturnYScroll16
NScrollUpRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollDownRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling down one row.
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollDownRow	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetHeight			;dx <- height of first row
	call	GetNextRow			;ax <- top row + 1
	jc	noScroll			;branch if at bottom
	mov	ds:[si].SSI_visible.CR_start.CR_row, ax	;store new top
	GOTO	ReturnYScroll16

noScroll:
	clr	dx				;dx <- no scroll
	GOTO	ReturnYScroll16
NScrollDownRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollLeftColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling left one column
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollLeftColumn	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_visible.CR_start.CR_column	;cx <- left column
	call	GetPreviousColumn		;cx <- column to left
	jc	noScroll			;branch if at left
	mov	ds:[si].SSI_visible.CR_start.CR_column, cx	;store new left
	call	ColumnGetWidth			;dx <- width
	neg	dx				;dx <- scroll left
	GOTO	ReturnXScroll16

noScroll:
	clr	dx				;dx <- no scroll
	GOTO	ReturnXScroll16
NScrollLeftColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollRightColumn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling right one column
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		dx:cx - x scroll amount
		bx:ax - y scroll amount
DESTROYED:	ax, bx, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollRightColumn	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_visible.CR_start.CR_column
	call	ColumnGetWidth			;dx <- width of first column
	call	GetNextColumn			;cx <- left column + 1
	jc	noScroll
	mov	ds:[si].SSI_visible.CR_start.CR_column, cx	;store new left
	GOTO	ReturnXScroll16

noScroll:
	clr	dx				;dx <- no scroll
	GOTO	ReturnXScroll16
NScrollRightColumn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollGeneral
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling to generalized position.
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	optimization: As with page left and page up, this would be quicker
	if there were a PosRoundToCell() routine...except it would be
	difficult to deal with the negative positions correctly.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollGeneral	proc	near
	class	SpreadsheetClass
EC <	call	ECCheckInstancePtr		;>
	;
	; Figure out cell we should scroll to
	;
	push	ss:[bp].TSP_newOrigin.PD_y.high
	push	ss:[bp].TSP_newOrigin.PD_y.low
	push	ss:[bp].TSP_newOrigin.PD_x.high
	push	ss:[bp].TSP_newOrigin.PD_x.low
	mov	bx, sp				;ss:bx <- ptr to PointDWord
	clr	ax, cx				;(ax,cx) <- cell origin
	call	Pos32ToCellRel			;(ax,cx) <- cell at position
	add	sp, (size PointDWord)
	mov	ds:[si].SSI_visible.CR_start.CR_row, ax
	mov	ds:[si].SSI_visible.CR_start.CR_column, cx
	;
	; Round position to cell boundaries
	;
	call	ReturnYDelta32
	GOTO	ReturnXDelta32
NScrollGeneral	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollKeepVisCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset to keep current cell in upper left,
		after a document size change.
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
			TSP_oldOrigin		PointDWord
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	NOTE: unlike NScrollKeepCell(), this may require scrolling
	to occur, in particular if the change in document size
	occurred above or to the left of the current visible area.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollKeepVisCell	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	;
	; Figure out where the upper-left is, and how far it has moved.
	;
	mov	ax, ds:[si].SSI_visible.CR_start.CR_row
	call	ReturnYDelta32
	mov	cx, ds:[si].SSI_visible.CR_start.CR_column
	GOTO	ReturnXDelta32
NScrollKeepVisCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollInto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling to keep cell visible
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollInto	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; First we try generalized scrolling, and see if that did anything
	;
	pushdw	ss:[bp].TSP_change.PD_x
	pushdw	ss:[bp].TSP_change.PD_y
	call	NScrollGeneral			;try generalized scrolling
	mov	ax, ss:[bp].TSP_change.PD_x.low
	or	ax, ss:[bp].TSP_change.PD_x.high
	or	ax, ss:[bp].TSP_change.PD_y.low
	or	ax, ss:[bp].TSP_change.PD_y.high
	jnz	donePop				;branch if scroll occurred
	;
	; If no scroll occurred, but was supposed to, it was a very
	; small scroll (ie. less than a row or column).  Calling the
	; handler for SA_DRAG_SCROLL handles this case exactly, so
	; we restore the original suggested change and pass it on.
	;
	popdw	ss:[bp].TSP_change.PD_y		;restore suggested y scroll
	popdw	ss:[bp].TSP_change.PD_x		;restore suggested x scroll
	call	NScrollSelect
	jmp	done

donePop:
	add	sp, (size PointDWord)		;ignore saved values
done:

	.leave
	ret
NScrollInto	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NScrollSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust offset for scrolling while selecting
CALLED BY:	SpreadsheetNormalizePosition()

PASS:		ss:bp - ptr to TrackScrollingParams
		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NScrollSelect	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Deal with left or right scrolling
	;
EC <	cmp	ss:[bp].TSP_change.PD_x.high, 0	>
EC <	je	xOK				;>
EC <	cmp	ss:[bp].TSP_change.PD_x.high, -1 >
EC <	je	xOK				;>
EC <	ERROR	SCROLL_AMOUNT_TOO_LARGE		;>
EC <xOK:					;>
	tst	ss:[bp].TSP_change.PD_x.low	;selecting left or right?
	jz	afterXScroll			;branch if no scroll
	js	scrollLeft			;branch if negative (ie. left)
	call	NScrollRightColumn
	jmp	afterXScroll

scrollLeft:
	call	NScrollLeftColumn
afterXScroll:
	;
	; Deal with up or down scrolling
	;
EC <	cmp	ss:[bp].TSP_change.PD_y.high, 0	>
EC <	je	yOK				;>
EC <	cmp	ss:[bp].TSP_change.PD_y.high, -1 >
EC <	je	yOK				;>
EC <	ERROR	SCROLL_AMOUNT_TOO_LARGE		;>
EC <yOK:					;>
	tst	ss:[bp].TSP_change.PD_y.low	;selecting up or down?
	jz	afterYScroll			;branch if no scroll
	js	scrollUp			;branch if negative (ie. up)
	call	NScrollDownRow
	jmp	afterYScroll

scrollUp:
	call	NScrollUpRow
afterYScroll:

	.leave
	ret
NScrollSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcViewDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate document view size
CALLED BY:	UpdateDocUIRedrawAll, SpreadsheetSetDocOrigin

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Functionality of adding on "mystery gray area" has been
	removed. This is to make the spreadsheet more well-behaved in
	the context of a compound document.  CalcSetDocSize has been
	merged into this procedure.	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/91		Initial version
       chrisb	11/18/91	merged CalcSetDocSize into this procedure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcViewDocSize	proc	far
	uses	ax, bx, cx, dx
bounds	local	RectDWord
	class	SpreadsheetClass
	.enter
EC <	call	ECCheckInstancePtr				>

	movdw	ss:[bounds].RD_left, ds:[si].SSI_bounds.RD_left, ax
	movdw	ss:[bounds].RD_top, ds:[si].SSI_bounds.RD_top, ax

	clr	dx				;dx <- minimum column
	mov	cx, ds:[si].SSI_maxCol
	inc	cx
	call	ColumnGetRelPos32Far		;ax:dx <- x size - last col
	movdw	ss:bounds.RD_right, axdx
	movdw	ds:[si].SSI_bounds.RD_right, axdx
	clr	dx				;dx <- minimum row
	mov	ax, ds:[si].SSI_maxRow
	inc	ax
	call	RowGetRelPos32Far		;ax:dx <- y size - last row
	movdw	ss:bounds.RD_bottom, axdx
	movdw	ds:[si].SSI_bounds.RD_bottom, axdx
	;
	; Tell our parent about the change...
	;
	push	bp, si	
	lea	bp, ss:bounds			;ss:bp <- ptr to RectDWord
	mov	dx, (size RectDWord)		;dx <- size of args
	mov	ax, MSG_VIS_CONTENT_SET_DOC_BOUNDS	;ax <- method to send
	mov	si, ds:[si].SSI_chunk
	call	VisCallParent
	pop	bp, si
	.leave
	ret

RecalcViewDocSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToViewStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the view with data on the stack

CALLED BY:	KeepCellOnScreen	

PASS:		ds:si - ptr to Spreadsheet instance
		ax - method to send to view
		ss: bp - stack data
		dx - size of stack data

RETURN:		cx, dx, bp - return from method

DESTROYED:	cx, dx, bp (if not returned)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/91		Initial version
	cbh	8/ 8/91		Changed for new MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	CDB	12/16/91	Changed name to protect the innocent

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendToViewStack	proc	far
	class	SpreadsheetClass
	push	di
	mov	di, mask MF_STACK
	FALL_THRU	SendToViewCommon, di
SendToViewStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToViewCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the view.

CALLED BY:	SendToView, SendToViewStack

PASS:		ax, cx, dx, bp - message data

RETURN:		ax, cx, dx, bp - returned from method called

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/17/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToViewCommon	proc far
	uses	bx,si
	class	SpreadsheetClass
	.enter
EC <	call	ECCheckInstancePtr		;>
	push	si
	ornf	di, mask MF_RECORD
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	call	ObjMessage			
	mov	cx, di				;cx <- event to send to view 
	pop	si

	mov	si, ds:[si].SSI_chunk
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	.leave
	FALL_THRU_POP	di
	ret
SendToViewCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeepSelectCellOnScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep non-anchor cell of keyboard selection on screen
CALLED BY:	{Extend,Contract}Selection{Left,Right,Up,Down}

PASS:		ds:si - ptr to instance data
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KeepSelectCellOnScreen	proc	near
	class	SpreadsheetClass
	uses	ax, cx
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	cmp	ax, ds:[si].SSI_active.CR_row		;anchored at top?
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	jne	notBottom			;branch if not anchored at top
afterRow:
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	cmp	cx, ds:[si].SSI_active.CR_column		;anchored at left?
	mov	cx, ds:[si].SSI_selected.CR_end.CR_column
	jne	notRight			;branch if not anchored at top
afterCol:

	call	KeepCellOnScreen
done:
	.leave
	ret

notBottom:
	cmp	ax, ds:[si].SSI_active.CR_row		;anchored at bottom?
	jne	done				;branch if not anchored at bttm
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	jmp	afterRow

notRight:
	cmp	cx, ds:[si].SSI_active.CR_column		;anchored at right?
	jne	done				;branch if not anchored at right
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	jmp	afterCol
KeepSelectCellOnScreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeepCellOnScreen, KeepActiveCellOnScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep a cell in visible area
CALLED BY:	MoveActiveCellFar())

PASS:		ds:si - ptr to instance data
		(ax,cx) - cell to keep on screen (r,c)
RETURN:		none
DESTROYED:	none (ax,cx)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KeepActiveCellOnScreen	proc	far
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	FALL_THRU	KeepCellOnScreen
KeepActiveCellOnScreen	endp

KeepCellOnScreen	proc	far
	uses	ax, bx, cx, dx, bp
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Set up args for GenView method
	;
	sub	sp, (size MakeRectVisibleParams)
	mov	bp, sp				;ss:bp <- ptr to args
	;
	; We may want to put the active cell in the center of the screen.
	; 
	push	ds, bx							
	mov	bx, handle dgroup
	call	MemDerefDS			; ds = dgroup
	tst	ds:[centerFlag]						
	pop	ds, bx				; restore ds, bx
	jz	dontCenter						
	mov	ss:[bp].MRVP_xMargin, MRVM_50_PERCENT			
	mov	ss:[bp].MRVP_xFlags, mask MRVF_ALWAYS_SCROLL
	mov	ss:[bp].MRVP_yMargin, MRVM_50_PERCENT
	mov	ss:[bp].MRVP_yFlags, mask MRVF_ALWAYS_SCROLL
	jmp	partialVisible
dontCenter:
	mov	ss:[bp].MRVP_xMargin, MRVM_0_PERCENT
	mov	ss:[bp].MRVP_xFlags, 0
	mov	ss:[bp].MRVP_yMargin, MRVM_0_PERCENT
	mov	ss:[bp].MRVP_yFlags, 0
partialVisible:
	;
	; Special case the right column and bottom row.  They are generally
	; only partially visible, so we treat them as being off screen.
	;
if _SCROLL_PARTLY_VISIBLE_CELL_ON_SCREEN_ONLY_WITH_KBD
	;
	; We only do this special case if the user got here via the
	; keyboard. We do this with a hack, which is to see if we
	; have got the grab, which is taken when doing selection.
	;
	test	ds:[si].SSI_flags, mask SF_HAVE_GRAB
	jnz	checkScroll
endif
	cmp	ax, ds:[si].SSI_visible.CR_end.CR_row
	je	doScrollRow
	cmp	cx, ds:[si].SSI_visible.CR_end.CR_column
	je	doScrollColumn
	;
	; See if the cell is already visible -- if so, we're done
	;
checkScroll:
	;
	; If we want to put the cell in the center of the screen, then
	; we don't care if it is already visible or not.
	;
	push	ds, bx							
	mov	bx, handle dgroup					
	call	MemDerefDS			; ds = dgroup		
	tst	ds:[centerFlag]						
	pop	ds, bx				;restore ds		
	jne	getBounds
	call	CellVisible?			;cell visible?
	jc	done				;branch if already on screen
	;
	; Get y bounds
	;
getBounds::
	clr	dx				;dx <- origin row
	call	RowGetRelPos32			;ax:dx <- position of row
	push	bx
	pushdw	axdx
	;
	; Get x bounds
	;
	clr	dx				;dx <- origin column
	call	ColumnGetRelPos32		;ax:dx <- position of column
setBounds:
	movdw	ss:[bp].MRVP_bounds.RD_left, axdx
	add	dx, bx				;add in column width
	adc	ax, 0
	movdw	ss:[bp].MRVP_bounds.RD_right, axdx
	popdw	axdx				;ax:dx <- position of row
	pop	bx				;bx <- row height
	movdw	ss:[bp].MRVP_bounds.RD_top, axdx
	add	dx, bx				;add in row height
	adc	ax, 0
	movdw	ss:[bp].MRVP_bounds.RD_bottom, axdx
	;
	; Tell her about it...
	;
	mov	dx, (size MakeRectVisibleParams)	;dx <- size of args
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	call	SendToViewStack

done:
	add	sp, (size MakeRectVisibleParams)	;done with args

	.leave
	ret

	;
	; The cell is already partially visible, so we can scroll to it
	; more easily than if it were at an arbitrary position.
	;
	; See if there is only a partial row or column visible.
	;
;
; if there is only one row or one column visible, we still need to ensure
; that the new cell is visible - brianc 5/5/94
;
doScrollRow:
	cmp	ax, ds:[si].SSI_visible.CR_start.CR_row
;	je	done
	je	checkScroll
	jmp	doScroll

doScrollColumn:
	cmp	cx, ds:[si].SSI_visible.CR_start.CR_column
;	je	done
	je	checkScroll
doScroll:
	;
	; Get the bounds relative to the visible range, and make convert
	; them into absolute offsets before passing them to the view.
	;

	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetRelPos32
	adddw	axdx, ds:[si].SSI_offset.PD_y
	push	bx
	pushdw	axdx
	mov	dx, ds:[si].SSI_visible.CR_start.CR_column
	call	ColumnGetRelPos32
	adddw	axdx, ds:[si].SSI_offset.PD_x
	jmp	setBounds
KeepCellOnScreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetDocOrigin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update our SSI_offset field.  Also, add vardata to
		specify the upper left-hand corner of the spreadsheet

PASS:		*ds:si	- SpreadsheetClass object
		ds:di	- SpreadsheetClass instance data
		es	- segment of SpreadsheetClass
		ss:bp 	- PointDWord 

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetDocOrigin	method	dynamic	SpreadsheetClass, 
					MSG_SPREADSHEET_SET_DOC_ORIGIN

		mov	ax, ss:[bp].PD_x.low
		or	ax, ss:[bp].PD_x.high
		or	ax, ss:[bp].PD_y.low
		or	ax, ss:[bp].PD_y.high
		jz	deleteVarData

		mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN or \
				mask VDF_SAVE_TO_STATE
		mov	cx, size SpreadsheetDocOrigin
		call	ObjVarAddData		; ds:bx - vardata

	;
	; Now, re-dereference the spreadsheet.  Store the origin in
	; the vardata, and update the "offset" field
	;
		
		mov	si, ds:[si]
		add	si, ds:[si].Spreadsheet_offset
		
		ornf	ds:[si].SSI_flags, mask SF_NONZERO_DOC_ORIGIN

		movdw	dxcx, ss:[bp].PD_x
		movdw	ds:[si].SSI_bounds.RD_left, dxcx

		decdw	dxcx
		movdw	ds:[si].SSI_offset.PD_x, dxcx

		movdw	dxcx, ss:[bp].PD_y
		movdw	ds:[si].SSI_bounds.RD_top, dxcx

		decdw	dxcx
		movdw	ds:[si].SSI_offset.PD_y, dxcx

	;
	; Also, compute the upper left-hand row & column information
	;
		
		push	bx			; ds:bx - vardata ptr
		clr	ax, cx
		mov	bx, bp
		call	Pos32ToCellRelFar
		pop	bx			; ds:bx - vardata ptr
		
		mov	ds:[bx].SDO_rowCol.CR_row, ax
		mov	ds:[bx].SDO_rowCol.CR_column, cx
		
		mov	ds:[si].SSI_visible.CR_start.CR_row, ax
		mov	ds:[si].SSI_visible.CR_start.CR_column, cx

		call	setSelection
		
	; We'll let the "draw" handler figure out the lower-right hand
	; corner.
		
;		lea	bx, ss:[bounds].RD_right
;		call	Pos32ToVisCellFar
;		mov	ds:[si].SSI_visible.CR_end.CR_row, ax
;		mov	ds:[si].SSI_visible.CR_end.CR_column, cx


done:
	;
	; Tell the view (and the content) about the new document bounds
	;
		call	RecalcViewDocSize
		ret

;------------------------
deleteVarData:
		mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
		call	ObjVarDeleteData

		mov	si, ds:[si]
		add	si, ds:[si].Spreadsheet_offset
		clr	ax
		movdw	ds:[si].SSI_bounds.RD_left, axax
		movdw	ds:[si].SSI_bounds.RD_top, axax
		andnf	ds:[si].SSI_flags, not mask SF_NONZERO_DOC_ORIGIN
		jmp	done

setSelection:
;----------------------
		mov	bp, ax		
		mov	ax, MSG_SPREADSHEET_MOVE_ACTIVE_CELL
		mov	si, ds:[si].SSI_chunk
		call	ObjCallInstanceNoLock
		mov	si, ds:[si]
		add	si, ds:[si].Spreadsheet_offset
		retn
		
		
		
SpreadsheetSetDocOrigin	endm



DrawCode	ends
