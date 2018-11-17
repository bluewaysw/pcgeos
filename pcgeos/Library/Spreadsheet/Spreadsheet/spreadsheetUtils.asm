COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		uiSpreadsheet.asm

AUTHOR:		Gene Anderson, Feb 20, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	SpreadsheetCellReplaceData	Replace data portion of specified cell
EXT	SpreadsheetCreateEmptyCell Create an empty cell
EXT	SpreadsheetNotifyUserOfError Tell user about some sort of error
EXT	SpreadsheetNotifyChange	Notify subclass of structure change

EXT	SpreadsheetMakeDirty	Mark spreadsheet file as dirty
METHOD	SpreadsheetChangeRecalcMode Switch between auto & manual recalculation
METHOD	SpreadsheetRecalc	Peform manual recalcuation
METHOD	SpreadsheetGetSelectedRange Get currently selected range

METHOD	SreadsheetNotesEnum		Do callback for each note
METHOD	SpreadsheetAlterDrawFlags	Alter drawing flags / options
METHOD	SpreadsheetAlterTitleStyles	Alter type of row/column titles
METHOD	SpreadsheetGetTitleAndDrawFlags Get title styles and draw options
METHOD	SpreadsheetGetRowHeight		Get height of a row
METHOD	SpreadsheetGetColumnWidth	Get width of a column

INT	NotesEnumCallback	Callback routine for each note

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/20/91		Initial revision

DESCRIPTION:
	Utility routines for drawing elements of the spreadsheet.

	$Id: spreadsheetUtils.asm,v 1.1 97/04/07 11:14:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetNameCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetNotifyUserOfError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user about some sort of error.

CALLED BY:	Utility
PASS:		ds:si	= Pointer to spreadsheet instance
		al	= ParserScannerEvaluatorError
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This should only be called when there is no opportunity to return
	an error to the application.

	A good example of a place to call this would be from the method that
	enters data from the edit-bar. Here the application is out of the
	loop so it makes sense to notify it of the error.
	
	A good example of a place NOT to call this would be in the method
	handlers which parse text. The error can be returned to the caller
	so it makes no sense to notify the user this way.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetNotifyUserOfError	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, bp, di, si
	.enter
EC <	call	ECCheckInstancePtr		;>
	mov	dl, al				; dl <- error code
	mov	si, ds:[si].SSI_chunk		; *ds:si <- instance ptr
	mov	ax, MSG_SPREADSHEET_ERROR	; ax <- method
	call	ObjCallInstanceNoLock		; Notify user of error
	.leave
	ret
SpreadsheetNotifyUserOfError	endp

SpreadsheetNameCode	ends

RareCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetChangeRecalcParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the recalculation parameters

CALLED BY:	via MSG_SPREADSHEET_CHANGE_RECALC_PARAMS
PASS:		ds:di	= Instance ptr
		ss:bp	= Pointer to SpreadsheetRecalcParams
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetChangeRecalcParams	method	SpreadsheetClass,
				MSG_SPREADSHEET_CHANGE_RECALC_PARAMS
	mov	si, di			; ds:si <- instance ptr
	;
	; First check to see if there are any differences
	;
	mov	bx, ds:[si].SSI_flags	; ax <- current flags
	andnf	bx, SRP_FLAGS		; Mask off uninteresting flags
	
	cmp	bx, ss:[bp].SRP_flags	; Check for any change
	jne	paramsChanged		; Branch if different
	
	;
	; Check the iteration count.
	;
	mov	dx, ds:[si].SSI_circCount

	cmp	dx, ss:[bp].SRP_circCount
	jne	paramsChanged		; Branch if different
	
	;
	; Check the convergence value.
	;
	segmov	es, ss, ax		; es:di <- ptr to the data
	lea	di, ss:[bp].SRP_converge

	push	di, si			; Save ptr to number, instance ptr
					; ds:si <- ptr to number
	lea	si, ds:[si].SSI_converge
	mov	cx, size FloatNum	; cx <- # of bytes to check
	
	repe	cmpsb			; Compare the convergence values
	pop	di, si			; Restore ptr to number, instance ptr

	je	quit			; Branch if the same
	
paramsChanged:
	;
	; The parameters have changed. Update the spreadsheet.
	; ds:si	= Instance ptr
	;
	
	;
	; Save the new flags, masking out their old values first
	;
	mov	ax, ss:[bp].SRP_flags
	mov	bx, ds:[si].SSI_flags
	
	push	ax, bx			; Save new and old flags for later

	andnf	bx, not SRP_FLAGS	; Clear flags we're setting
	ornf	bx, ax			; Set them
	mov	ds:[si].SSI_flags, bx	; Store them

	;
	; Save new circularity counter
	;
	mov	ax, ss:[bp].SRP_circCount
	mov	ds:[si].SSI_circCount, ax
	
	;
	; Save the new convergence value.
	;
	push	ds, si			; Save instance ptr
	segmov	es, ss, ax		; es:di <- ptr to the data
	lea	di, ss:[bp].SRP_converge

	lea	si, ds:[si].SSI_converge
	segxchg	ds, es			; ds:si <- ptr to new convergence value
	xchg	si, di			; es:di <- ptr to place to put it
	
	mov	cx, size FloatNum	; cx <- # of bytes to move
	rep	movsb			; Copy the new convergence value
	pop	ds, si			; Restore instance ptr

	call	SpreadsheetMakeDirty	; It's dirty now...
	
	pop	ax, bx			; ax <- new flags, bx <- old flags

	;
	; If we're allowing iteration and we weren't before we need to
	; recalculate. Also if we're going the other way too.
	;
	mov	cx, bx			; cx <- old flags
	andnf	cx, mask SF_ALLOW_ITERATION
	xornf	cx, ax			; Check for change in this flag
	test	cx, mask SF_ALLOW_ITERATION
	jnz	doRecalc		; Branch if flag changed

	;
	; If we're making a transition from auto->manual recalc we need to
	; get the spreadsheet up to date by recalculating.
	;
	test	bx, mask SF_MANUAL_RECALC
	jz	quit			; Branch if we weren't in manual-recalc
	test	ax, mask SF_MANUAL_RECALC
	jnz	quit			; Branch if no change in this bit

doRecalc:
	;
	; One of several cases:
	;	- We were in manual recalc (bx had that bit set) and we are
	;	  now in auto recalc (ax had that bit clear).
	;	- The "allow iteration" flag changed.
	;
	; We need to recalculate.
	;
	call	ManualRecalc		; Force recalculation
quit:
	;
	; Update the UI
	;
	mov	ax, mask SNF_DOC_ATTRS
	call	SS_SendNotification
	ret
SpreadsheetChangeRecalcParams	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetRecalcParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current set of recalc parameters

CALLED BY:	via MSG_SPREADSHEET_GET_RECALC_PARAMS
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ax	= Method
		es	= Class segment
		ss:bp	= Pointer to SpreadsheetRecalcParams
RETURN:		ss:bp filled in
		bp unchanged
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetRecalcParams	method	SpreadsheetClass,
				MSG_SPREADSHEET_GET_RECALC_PARAMS
	mov	si, di			; ds:si <- instance ptr

	segmov	es, ss, di		; es:di <- ptr to dest buffer
	mov	di, bp
	
	;
	; Copy the flags
	;
	mov	ax, ds:[si].SSI_flags
	and	ax, SRP_FLAGS		; Mask out the unimportant ones
	mov	es:[di].SRP_flags, ax
	
	;
	; Copy the circularity counter
	;
	mov	ax, ds:[si].SSI_circCount
	mov	es:[di].SRP_circCount, ax
	
	;
	; Copy the convergence value
	;
	mov	cx, size FloatNum	; cx <- # of bytes
	lea	di, es:[di].SRP_converge
	lea	si, ds:[si].SSI_converge
	rep	movsb			; Copy the convergence value

	ret
SpreadsheetGetRecalcParams	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetMakeDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the spreadsheet file as dirty so that it will get written
		out.

CALLED BY:	SpreadsheetChangeRecalcParams
PASS:		ds:si	= Spreadsheet instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetMakeDirty	proc	far
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, bp, di, si
	.enter
EC <	call	ECCheckInstancePtr		;>
	or	ds:[si].SSI_cellParams.CFP_flags, mask CFPF_DIRTY
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	cx, bx				; si <- File handle
	call	MemOwner			; bx <- person to call
	mov	ax, MSG_META_VM_FILE_DIRTY	; Tell them it's dirty
	mov	di, mask MF_INSERT_AT_FRONT or mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret
SpreadsheetMakeDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRecalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate a spreadsheet if it's in manual recalc mode.

CALLED BY:	via MSG_SPREADSHEET_RECALC
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= segment of Spreadsheet Class
		ax	= MSG_SPREADSHEET_RECALC
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetRecalc	method	SpreadsheetClass, MSG_SPREADSHEET_RECALC
	mov	si, di			; ds:si <- instance ptr
	call	SpreadsheetMarkBusy
	call	ManualRecalc		; Do the calculation.
	call	SpreadsheetMarkNotBusy
	ret
SpreadsheetRecalc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetAlterDrawFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the SpreadsheetDrawFlags for a spreadsheet.

CALLED BY:	via MSG_SPREADSHEET_ALTER_DRAW_FLAGS
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ax	= Method
		es	= Class segment
		cx	= Bits to set
		dx	= Bits to clear
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetAlterDrawFlags	method	SpreadsheetClass,
				MSG_SPREADSHEET_ALTER_DRAW_FLAGS
	mov	si, di				; ds:si <- spreadsheet instance

	mov	ax, ds:[si].SSI_drawFlags	; ax <- current draw flags
	or	ax, cx				; Add some bits
	not	dx
	and	ax, dx				; Clear some bits
	
	cmp	ax, ds:[si].SSI_drawFlags	; Check for flags changed
	je	quit				; Branch if unchanged
	;
	; Save new flags and mark spreadsheet as dirty.
	;
	mov	ds:[si].SSI_drawFlags, ax	; Save new draw flags

	call	SpreadsheetMakeDirty		; Mark dirty spreadsheet
	;
	; Redraw everything, and update the UI
	;
	mov	ax, mask SNF_DOC_ATTRS
	call	UpdateUIRedrawAll
quit:
	ret
SpreadsheetAlterDrawFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetDrawFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current row/column title style and drawing options.

CALLED BY:	via MSG_SPREADSHEET_GET_DRAW_FLAGS
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ax	= Method
		es	= Class segment
RETURN:		dx	= SSI_drawFlags
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetDrawFlags	method	SpreadsheetClass,
				MSG_SPREADSHEET_GET_DRAW_FLAGS
	mov	dx, ds:[di].SSI_drawFlags
	ret
SpreadsheetGetDrawFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the file handle associated with a spreadsheet

CALLED BY:	via MSG_SPREADSHEET_GET_FILE
PASS:		ds:di	= Spreadsheet instance
RETURN:		cx	= File handle
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetFile	method	SpreadsheetClass,
				MSG_SPREADSHEET_GET_FILE
	mov	cx, ds:[di].SSI_cellParams.CFP_file
	ret
SpreadsheetGetFile	endm


RareCode	ends

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetRowHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of a row
CALLED BY:	MSG_SPREADSHEET_GET_ROW_HEIGHT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx - row #
RETURN:		dx - height of row

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetRowHeight	method dynamic SpreadsheetClass, \
						MSG_SPREADSHEET_GET_ROW_HEIGHT
	mov	si, di				;ds:si <- ptr to instance
	mov	ax, cx				;ax <- row #
	mov	dx, -1				;dx <- for missing row
	cmp	ax, ds:[si].SSI_maxRow		;is this a legal row?
	ja	done				;branch if not legal row
	call	RowGetHeight			;dx <- row height
done:
	ret
SpreadsheetGetRowHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetColumnWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of a column
CALLED BY:	MSG_SPREADSHEET_GET_COLUMN_WIDTH

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx - column #
RETURN:		dx - column width

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetColumnWidth	method dynamic SpreadsheetClass, \
						MSG_SPREADSHEET_GET_COLUMN_WIDTH
	mov	si, di				;ds:si <- ptr to instance
	mov	dx, -1				;dx <- for missing column
	cmp	cx, ds:[si].SSI_maxCol		;is this a legal column?
	ja	done				;branch if not legal column
	call	ColumnGetWidth			;dx <- column width
done:
	ret
SpreadsheetGetColumnWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetRowAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the row at the specified position
CALLED BY:	MSG_SPREADSHEET_GET_ROW_AT_POSITION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		dx:cx - 32-bit y position
RETURN:		ax - row #
		cx - position from row bottom edge (<=0)
		dx - position from row top edge (>=0)

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetRowAtPosition	method dynamic SpreadsheetClass, \
					MSG_SPREADSHEET_GET_ROW_AT_POSITION
	mov	si, di				;ds:si <- ptr to spreadsheet
	pushdw	dxcx				;pass sdword
	clr	cx				;cx <- origin row
	mov	bp, sp				;ss:bp <- ptr to point
	call	Pos32ToRowRel
	add	sp, (size sdword)
	ret
SpreadsheetGetRowAtPosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetColumnAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the column at the specified position
CALLED BY:	MSG_SPREADSHEET_GET_COLUMN_AT_POSITION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		dx:cx - 32-bit x position
RETURN:		ax - column #
		cx - position from column right edge (<=0)
		dx - position from column left edge (>=0)

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetColumnAtPosition	method dynamic SpreadsheetClass, \
					MSG_SPREADSHEET_GET_COLUMN_AT_POSITION
	mov	si, di				;ds:si <- ptr to spreadsheet
	pushdw	dxcx				;pass sdword
	clr	cx				;cx <- origin row
	mov	bp, sp				;ss:bp <- ptr to point
	call	Pos32ToColRel
	add	sp, (size sdword)
	ret
SpreadsheetGetColumnAtPosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to our rulers
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		ax - message to send
RETURN:		depends on message
DESTROYED:	depends on message

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendToRuler	proc	far
	class	SpreadsheetClass
	uses	bx, si, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_ruler.handle
	mov	si, ds:[si].SSI_ruler.chunk	;^lbx:si <- OD of ruler
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
SendToRuler	endp

DrawCode	ends

AttrCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetMarkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the busy cursor

CALLED BY:	UTILITY
PASS:		ds - fixup'able block
RETURN:		ds - fixed up if necessary
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetMarkBusy		proc	far
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	UserCallApplication

	.leave
	ret
SpreadsheetMarkBusy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take down the busy cursor

CALLED BY:	UTILITY
PASS:		ds - fixup'able block
RETURN:		ds - fixed up if necessary
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetMarkNotBusy		proc	far
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	UserCallApplication

	.leave
	ret
SpreadsheetMarkNotBusy		endp

AttrCode	ends
