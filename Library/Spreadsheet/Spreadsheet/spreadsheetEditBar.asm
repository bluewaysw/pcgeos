COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetEditBar.asm

AUTHOR:		Gene Anderson, Feb 27, 1991

ROUTINES:
	Name			Description
	----			-----------
MSG_SPREADSHEET_GOTO_CELL	Goto a cell entered in "cell goto" box
MSG_SPREADSHEET_ENTER_DATA	Enter data from edit bar
MSG_SPREADSHEET_MAKE_FOCUS	Make ourselves the focus

	SetEditContents		Set edit bar contents from active cell
	FormatCellContents	Call appropriate formatting routine
	EditFormatTextCell	Format a text cell for edit bar display
	EditFormatFormulaCell	Format a formula cell for edit bar display
	EditFormatConstantCell	Format a constant cell for edit bar display
	ClearEditBar		Clear contents of edit bar
	SetEditBarText		Set text for edit bar
	SpreadsheetGrabFocus	Make ourselves the focus

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/27/91		Initial revision

DESCRIPTION:
	SpreadsheetClass routines related to the edit bar

	$Id: spreadsheetEditBar.asm,v 1.1 97/04/07 11:13:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goto a cell

CALLED BY:	via MSG_SPREADSHEET_GOTO_CELL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		dx - handle of text block
		cx - length of text (w/o NULL) (unused)

RETURN:		nothing (block free'd)
DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GotoCell	method dynamic SpreadsheetClass, MSG_SPREADSHEET_GOTO_CELL


	mov	si, di				; ds:si <- ptr to instance
	;
	; Get the text
	;
	mov	bx, dx				;bx <- handle of text
	push	bx
	call	MemLock
	jc	quit				;branch if error
	;
	; Try to parse the text
	;
	mov	dx, ax
	clr	di				;dx:di <- ptr to text
	call	ConvertToCellOrRange
	jc	badRefError			;branch if error

	test	ds:[si].SSI_flags, mask SF_NONZERO_DOC_ORIGIN
	jz	ok

	;
	; Check for a cell or range before the temporary origin
	; (origin used when spreadsheet is in locked rows/columns mode)
	;
	push	ax, si
	mov	si, ds:[si].SSI_chunk
	mov	ax, TEMP_SPREADSHEET_DOC_ORIGIN
	call	ObjVarFindData
	pop	ax, si
	jnc	ok

	cmp	ax, ds:[bx].SDO_rowCol.CR_row
	jb	originError

	cmp	dx, ds:[bx].SDO_rowCol.CR_row
	jb	originError

	cmp	cx, ds:[bx].SDO_rowCol.CR_column
	jb	originError

	cmp	bp, ds:[bx].SDO_rowCol.CR_column
	jb	originError

ok:
	;
	; ax, cx	= Row/column of first cell
	; dx, bp	= Row/column of last cell
	;
	; The range entered is legal. Set the new active
	; cell and set the range in the cell edit.
	;
	push	cx				;active column
	push	ax				;active row
	push	bp				;end column
	push	dx				;end row
	push	cx				;start column
	push	ax				;start row
CheckHack <(size SpreadsheetRangeParams) eq 6*(size word)>
	mov	bp, sp				;ss:bp <- ptr to params
	mov	di, si				;ds:di <- ptr to ssheet	
	call	SpreadsheetSetSelection
	add	sp, (size SpreadsheetRangeParams)
	;
	; Make sure the active cell is visible
	;
	call	KeepActiveCellOnScreen
quit:
	;
	; Free text block
	;
	pop	bx
	call	MemFree


	ret

originError:		
	mov	al, PSEE_CELL_OR_RANGE_IS_LOCKED
	jmp	error
badRefError:
	mov	al, PSEE_RESULT_SHOULD_BE_CELL_OR_RANGE
error:		
	call	SpreadsheetNotifyUserOfError	;tell user about the problem
	jmp	quit
GotoCell	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetEnterData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter data from the edit bar into the active cell
CALLED BY:	MSG_SPREADSHEET_ENTER_DATA

PASS:		ds:*si - instance data
		ds:di - ds:*si
		es - seg addr of SpreadsheetClass
		ax - the method

		dx - handle of text block
		cx - length of text (w/o NULL)

RETURN:		carry - set if data not entered (ie. error)
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: frees the text block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetEnterData	method	SpreadsheetClass, 
						MSG_SPREADSHEET_ENTER_DATA

		mov	si, di			;ds:si <- ptr to instance data
		call	EnterDataFromEditBar
	;
	; Refresh the edit bar
	;
		pushf				; error (carry) flag
		mov	ax, mask SNF_EDIT_BAR
		call	SS_SendNotification
		popf
		ret
SpreadsheetEnterData	endm

EnterDataFromEditBar	proc	near
	class	SpreadsheetClass
	.enter

	push	dx				;save handle of text block
	mov	bx, dx				;bx <- handle of text block
	mov	dx, cx				;dx <- length of text
	call	MemLock
	mov	es, ax
	clr	di				;es:di <- ptr to text
	;
	; Figure out what kind of data this is, and
	; allocate a new cell appropriately.
	;
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column	;(ax,cx) <- active (r,c)
	LocalIsNull	es:[di]			;any text?
	jz	deleteCell			;branch if deleting

	LocalCmpChar	es:[di], '='		;check for formula
	je	allocFormula			;branch if formula
	clr	bx				;bx <- use default attrs
	;
	; Attempt to parse this as a number-constant cell.
	;
	call	AllocConstantCellFromText	;check for constant
	jnc	redrawCell			;branch if it was a constant
	;
	; Not a constant... Default to a text cell.
	;
	call	AllocTextCell

redrawCell:
	;
	; ds:si	= Pointer to spreadsheet instance
	; Need to reload the row/column of the cell we're working on
	;
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column		;(ax,cx) <- active (r,c)

	call	RecalcDependents		;recalc cell dependents
						;also redraws the cell
	clc					;carry <- no error
quit:
	pop	bx
	pushf
	call	MemFree
	popf

	.leave
	ret

deleteCell:
	call	DeleteCell			;delete the cell
	jmp	redrawCell

allocFormula:
	;
	; Skip the "=" at the start of the formula
	;
	LocalNextChar	esdi			;es:di <- ptr to formula
	call	FormulaCellAlloc		;allocate a formula cell
	jnc	redrawCell			;branch if no error
	;
	; There was an error. We want to notify the user about the problem
	; and then keep the focus in the edit bar. 
	;
	; The range of text where the error was found is in cx/dx.
	; We select that text before we notify the user of the problem.
	;
	push	ax, bp				;save error code, frame
	;
	; The problem is that cx/dx really contain the offset from the
	; start of the expression we passed them, which is after the
	; "=" at the start of the text. We need to advance each edge of the
	; range by one character, unless they are at the end of the text.
	; (cx/dx are char indexes)
	;
	cmp	cx, TEXT_ADDRESS_PAST_END_LOW	;check for whole range at end
	je	setSelection			;branch if so
	inc	cx				;advance range start

	cmp	dx, TEXT_ADDRESS_PAST_END_LOW	;check for range end at end
	je	setSelection			;branch if so
	inc	dx				;advance range end
setSelection:

PrintMessage <fix edit bar selection if possible>
if 0
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	mov	di, mask MF_CALL		;di <- flags
	call	SpreadsheetCallEditOD		;call edit object
endif
	pop	ax, bp				;restore error code, frame

	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	GenCallApplication
	pop	ax, cx, dx, bp

	call	SpreadsheetNotifyUserOfError	;tell the user about it

	;
	; Added, 7/ 7/95 -jw
	;
	; Send MSG_SPREADSHEET_REPLACE_TEXT_SELECTION to the edit-bar,
	; but pass nothing as the text to replace with. The side-effects
	; of this message are:
	;
	;	- The edit bar grabs the focus (good)
	;	- The edit bar marks itself as modified (good)
	;
	; The result is that the user is left editing the formula that
	; had the error, and they must correct it in order to do anything.
	;
	; (OK... it's weak, but it does work)
	;
	; Note that I use ObjCallInstanceNoLock() under the assumption
	; that this must somehow get passed to the edit-bar just
	; as a general rule (that's certainly how GeoCalc handles it).
	;
	push	ax, bx, cx, dx, bp, si

	clr	dx				; dx <- handle of block
	clr	bp				; don't select anything
	clr	cx				; null terminated text

	mov	si, ds:[si].SSI_chunk		; *ds:si <- object
	mov	ax, MSG_SPREADSHEET_REPLACE_TEXT_SELECTION
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	UserSendToApplicationViaProcess

	pop	ax, bx, cx, dx, bp, si

	stc					;carry <- error
	jmp	quit				;don't take the focus back
EnterDataFromEditBar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetEnterDataWithEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Same as MSG_SPREADSHEET_ENTER_DATA, but also handle
		the passed event if data entered correctly.

PASS:		*ds:si	- SpreadsheetClass object
		ds:di	- SpreadsheetClass instance data
		es	- segment of SpreadsheetClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetEnterDataWithEvent	method	dynamic	SpreadsheetClass, 
					MSG_SPREADSHEET_ENTER_DATA_WITH_EVENT
		push	bp
		mov	ax, MSG_SPREADSHEET_ENTER_DATA
		call	ObjCallInstanceNoLock
		pop	cx
		jcxz	done
		mov	dx, TO_NULL
		jc	send

		CheckHack <TO_SELF eq (TO_NULL+1)>
		inc	dx
send:
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		GOTO	ObjCallInstanceNoLock 
done:
		ret
SpreadsheetEnterDataWithEvent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatEditContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the contents of a cell for the edit bar
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance data
		dx:bp - ptr to buffer
		*es:di	= cell data
RETURN:		cx - length of text (w/o NULL)
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Routine for things like CT_EMPTY...
;
EditFormatNothing	proc	near
	uses	ds
	.enter

	clr	cx				;cx <- length w/o NULL
	mov	ds, dx				;ds:bp <- ptr to buffer
	mov	ds:[bp][0], cx			;a nothing string.

	.leave
	ret
EditFormatNothing	endp

cellEditFormatRoutines	nptr \
	EditFormatTextCell,			;CT_TEXT
	EditFormatConstantCell,			;CT_CONSTANT
	EditFormatFormulaCell,			;CT_FORMULA
	BadCellType,				;CT_NAME
	BadCellType,				;CT_CHART
	EditFormatNothing,			;CT_EMPTY
	EditFormatFormulaCell			;CT_DISPLAY_FORMULA
CheckHack <(size cellEditFormatRoutines) eq CellType>

FormatEditContents	proc	far
	class	SpreadsheetClass
	uses	ax, bp, es, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column ;(ax,cx) <- active (r,c)
	SpreadsheetCellLock			;lock cell
	jnc	noData				;branch if no data

if _PROTECT_CELL
	;
	; dx = segment of NotifySSheetEditBarChange block, if not, we are
	; skewed.
	;
	push	ds, bx
	mov	ds, dx				;ds = notification block seg 
	mov	bx, es:[di]
	mov	bl, es:[bx].CC_recalcFlags				
	andnf	bl, mask CRF_PROTECTION					
	jz	allSet				;set protection flag if not jmp
	ornf	ds:[NSSEBC_miscData], mask SSEBCMD_PROTECTION	
allSet:
	pop	ds, bx						
endif

	;
	; Pass dx:bp = buffer to use
	;
	call	FormatCellContents		;format contents into buffer
	SpreadsheetCellUnlock			;unlock cell
done:
	.leave
	ret

	;
	; The cell has no data.  Set the edit bar text to NULL.
	;
noData:
	clr	cx				;cx <- length of text
	mov	es, dx
	mov	es:[bp], cx			;NULL-terminate text
CheckHack <C_NULL eq 0>
	jmp	done
FormatEditContents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatCellContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the contents of a cell.

CALLED BY:	FormatEditContents()
PASS:		*es:di	= Pointer to the cell data
		ds:si	= Spreadsheet instance
SBCS<		dx:bp	= Buffer of at least MAX_CELL_TEXT_SIZE+1 size	>
DBCS<		dx:bp	= Buffer of at least MAX_CELL_TEXT_SIZE+2 size	>
		ax	= Row
		cx	= Column
RETURN:		buffer filled with the formatted expression
		cx	= length of string (w/o NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/30/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatCellContents	proc	far
	uses	bx, di
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	di, es:[di]			;es:di <- ptr to data
	mov	bl, es:[di].CC_type		;bl <- CellType
	clr	bh
	call	cs:cellEditFormatRoutines[bx]

	.leave
	ret
FormatCellContents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditFormatTextCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format for text cell data for edit bar display
CALLED BY:	FormatCellContents()

PASS:		es:di - cell data
		dx:bp - ptr to buffer to use
RETURN:		cx - length of formatted string (w/o NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditFormatTextCell	proc	near
	uses	ax, di, si, ds, es
	.enter

	segmov	ds, es
	mov	si, di				;ds:si <- ptr to cell
	ChunkSizePtr	ds, si, cx
	sub	cx, (size CellText)		;cx <- size of string
	add	si, (size CellText)		;ds:si <- ptr to text

	mov	es, dx
	mov	di, bp				;es:di <- ptr to destination

	push	cx				;save size
	rep	movsb				;copy me jesus
	pop	cx
DBCS<	shr	cx, 1				;cx <- length of string    >
	dec	cx				;cx <- length (w/o) NULL

	.leave
	ret
EditFormatTextCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditFormatFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format for text cell data for edit bar display
CALLED BY:	FormatCellContents()

PASS:		es:di - cell data
		ds:si - Spreadsheet instance
		dx:bp - ptr to buffer to use
		ax - row
		cx - column
RETURN:		cx - length of formatted string (w/o NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditFormatFormulaCellFar	proc	far
	call	EditFormatFormulaCell
	ret
EditFormatFormulaCellFar	endp

EditFormatFormulaCell	proc	near
	uses	ax, bx, dx, di, es, bp
	.enter
EC <	call	ECCheckInstancePtr		;>

	push	cx, ax				; push CellReference
	mov	ax, es				; ax:cx <- ptr to the formula
	mov	cx, di
	add	cx, CF_formula

	mov	es, dx				; es:di <- ptr to destination
	mov	di, bp

SBCS<	mov	dx, MAX_CELL_TEXT_SIZE + (size char)	; dx <- size of the buffer  >
DBCS<	mov	dx, MAX_CELL_TEXT_SIZE + (size wchar); dx <- size of the buffer  >

	mov	bx, sp				; ss:bx <- ptr to "current cell"
	call	FormulaCellFormat		; Do the formatting
						; cx <- text length (w/out NULL)
	add	sp, (size CellReference)

	.leave
	ret
EditFormatFormulaCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditFormatConstantCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a constant cell for display in the edit-bar.

CALLED BY:	FormatCellContents()
PASS:		es:di	= Pointer to cell data
		ds:si	= Pointer to spreadsheet instance
		dx:bp	= Pointer to buffer to use
		ax,cx	= Row,Column
RETURN:		cx - length of formatted string
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditFormatConstantCell	proc	near
	uses	ds, si, es, di, ax, bx
	.enter
EC <	call	ECCheckInstancePtr		;>
	segmov	ds, es, si		; ds:si <- ptr to cell constant
	lea	si, es:[di].CC_current

	mov	es, dx			; es:di <- ptr to buffer
	mov	di, bp

	mov	ax, mask FFAF_FROM_ADDR or mask FFAF_NO_TRAIL_ZEROS
	mov	bh, DECIMAL_PRECISION
	mov	bl, DECIMAL_PRECISION - 1
	call	FloatFloatToAscii_StdFormat	; cx <- # chars (w/out NULL)

	.leave
	ret
EditFormatConstantCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGrabFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the focus so the spreadsheet gets keyboard input
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGrabFocus	proc	far
	class	SpreadsheetClass
	uses	cx, dx, si, bp
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Grab the focus by calling ourselves to grab the focus.
	; This allows applications with weird UI (eg. multiple
	; Spreadsheet objects) to handle getting the focus
	; by subclassing the Spreadsheet object.
	;
	mov	si, ds:[si].SSI_chunk	;*ds:si - Spreadsheet object
	mov	ax, MSG_SPREADSHEET_MAKE_FOCUS
	call	ObjCallInstanceNoLock

	.leave
	ret
SpreadsheetGrabFocus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetMakeFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make this Spreadsheet the current focus & target
CALLED BY:	MSG_SPREADSHEET_MAKE_FOCUS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetMakeFocus	method dynamic SpreadsheetClass, 
						 MSG_SPREADSHEET_MAKE_FOCUS
	uses	cx, dx, bp
	.enter

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	.leave
	ret
SpreadsheetMakeFocus	endm

EditCode	ends
