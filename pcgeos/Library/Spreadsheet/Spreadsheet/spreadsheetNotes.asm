COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetNotes.asm

AUTHOR:		John Wedgwood, Apr 15, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/15/91	Initial revision

DESCRIPTION:
	Methods for adding notes to a spreadsheet cell.

	$Id: spreadsheetNotes.asm,v 1.1 97/04/07 11:14:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NotesCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetNoteForActiveCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the note for a given cell

CALLED BY:	via MSG_SPREADSHEET_SET_NOTE_FOR_ACTIVE_CELL
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Handle of memory block containing the note text.
			= 0 to remove the note
RETURN:		Block is free'd
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSetNoteForActiveCell	method	SpreadsheetClass,
				MSG_SPREADSHEET_SET_NOTE_FOR_ACTIVE_CELL
	mov	dx, ds:[di].SSI_active.CR_row
	mov	bp, ds:[di].SSI_active.CR_column
	call	SpreadsheetSetNote
	ret
SpreadsheetSetNoteForActiveCell	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the note for a given cell

CALLED BY:	via MSG_SPREADSHEET_SET_NOTE
PASS:		ds:di	= Instance ptr
		cx	= Handle of memory block containing the note text.
			= 0 to remove the note
		dx/bp	= Row/Column of the cell whose note we want to add.
RETURN:		Block is free'd
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSetNote	method	SpreadsheetClass, MSG_SPREADSHEET_SET_NOTE
	mov	si, di			; ds:si <- instance ptr

	push	dx, bp, ds, si		; Save cell row/column, instance ptr
	;
	; First we compute the length of the text passed to us.
	;
	jcxz	gotSize			; Branch if nuking the note

	mov	bx, cx			; bx <- block handle
	call	MemLock			; Lock the block handle
	mov	es, ax			; es:di <- ptr to text
	clr	di
	call	LocalStringSize		; cx <- size w/o NULL
	LocalNextChar	escx		; cx <- size w/NULL
	;
	; See if there is any text -- if not, nuke the text block
	;
SBCS<	cmp	cx, (size char)			;any text?	>
DBCS<	cmp	cx, (size wchar)		;any text?	>
	jne	gotText				;branch if text exists
	call	MemFree				;nuke me jesus
	clr	cx				;cx <- delete note, please
gotText:

gotSize:	
	;
	; bx	= Block handle (unless we are nuking the note)
	; es	= Segment address of the block (unless we are nuking the note)
	; cx	= Length of the text in the block (including the NULL).
	; dx	= Row
	; bp	= Column
	;
	push	bx, es, cx		; Save block handle, address, and length

	mov	ax, dx			; ax <- row
	xchg	cx, bp			; cx <- column
					; bp <- size of the text
	SpreadsheetCellLock		; *es:di <- ptr to cell
	jc	gotCell			; Branch if cell exists
	
	;
	; Cell doesn't exist. Create a new one, unless we are erasing the
	; note in which case we can just quit.
	;
	tst	bp			; Check for no text
	LONG jz	quitNoCellOrNote	; Branch to quit if no note or cell

	call	SpreadsheetCreateEmptyCell
	SpreadsheetCellLock		; Lock the cell again
EC <	ERROR_NC CELL_DOES_NOT_EXIST	; Die if it wasn't created	>
gotCell:
	mov	di, es:[di]		; es:di <- ptr to the cell

	;
	; Grab dbase item for the old note and free it.
	;
	push	ax, cx			; Save row/column of the cell
	SpreadsheetCellDirty		; Dirty the cell data now
	
	;
	; Need the file handle in bx in order to do DBase calls.
	;
	mov	bx, ds:[si].SSI_cellParams.CFP_file

	push	di			; Save ptr to cell data
	mov	ax, es:[di].CC_notes.segment
	tst	ax			; Check for no note.
	jz	afterFree		; Skip free'ing the old note
	;
	; Mark the cell has having no note.
	;
	mov	es:[di].CC_notes.segment, 0
	;
	; Now finish up by free'ing the note.
	;
	mov	di, es:[di].CC_notes.offset
	call	DBFree			; Free the old note
afterFree:
	pop	di			; Restore ptr to cell data
	;
	; Create a new dbase item to hold the note.
	;
	mov	cx, bp			; cx <- size to allocate
	jcxz	quitNoNote		; Quit if no new note

	SpreadsheetCellUnlock		; Release the cell before we allocate
	
	mov	ax, DB_UNGROUPED	; Allocate the item ungrouped
	call	DBAlloc			; ax, di <- group/item of the note

	;
	; Save the item into the cell data.
	;
	mov	dx, ax			; dx <- group token
	mov	bp, di			; bp <- item token
	pop	ax, cx			; Restore row/column of the cell
	
	SpreadsheetCellLock		; *es:di <- ptr to cell
	mov	di, es:[di]		; es:di <- ptr to cell
	mov	es:[di].CC_notes.segment, dx
	mov	es:[di].CC_notes.offset,  bp
	
	SpreadsheetCellDirty		; Dirty the cell data
	SpreadsheetCellUnlock		; Release the cell
	
	;
	; Now we need to lock the dbase item and copy the data into it.
	;
	mov	ax, dx			; ax <- group token
	mov	di, bp			; di <- item token
	call	DBLock			; *es:di <- ptr to notes item
	mov	di, es:[di]		; es:di <- ptr to notes item

	pop	bp, ds, cx		; Restore block handle, address, size
	clr	si			; ds:si <- ptr to source
	rep	movsb			; Copy the note
	
	call	DBDirty			; Dirty the note
	call	DBUnlock
	;
	; Unlock and free the text block passed in to us.
	;
	mov	bx, bp			; bx <- handle of the block
	call	MemFree			; Free the block (locked)
quit:
	pop	ax, cx, ds, si		; Restore row/column and instance ptr
	call	CellRedraw		; Redraw the cell w/ or w/o note
	;
	; Update the UI
	;
	mov	ax, mask SNF_CELL_NOTES
	call	SS_SendNotification
	ret

quitNoNote:
	;
	; The old note has been free'd and we don't want to create a new note.
	; es:di	= Pointer to the cell data
	; ds:si	= Instance ptr
	; On stack:
	;	ax, cx		<- row/column of the cell
	;	bx, es, cx	<- block handle, address, length
	;		All useless now.
	;
	pop	ax, cx			; ax/cx <- row/column of the cell
	add	sp, 3 * size word	; Remove other stuff
	;
	; Now if the cell is marked as empty and the dependency count is
	; zero we can nuke the cell entirely.
	;
	cmp	es:[di].CC_type, CT_EMPTY
	jne	unlockAndQuit		; Branch if not empty
	cmp	es:[di].CC_attrs, DEFAULT_STYLE_TOKEN
	jne	unlockAndQuit		; Branch if it has a *real* style
	cmp	es:[di].CC_dependencies.segment, 0
	jne	unlockAndQuit		; Branch if no dependencies
if _PROTECT_CELL
	;
	; Make sure the cell is not protected before freeing it
	;
	test	es:[di].CC_recalcFlags, mask CRF_PROTECTION ;protected cell?
	jnz	unlockAndQuit
endif

	;
	; The cell is nukable
	;
	SpreadsheetCellUnlock		; Release the cell
	clr	dx			; dx == 0 means remove the cell
	SpreadsheetCellReplaceAll
	jmp	quit			; Branch to return

unlockAndQuit:
	SpreadsheetCellUnlock		; Release the cell
	jmp	quit			; Branch to return

quitNoCellOrNote:
	;
	; There is no cell and there is no note. Do nothing... But there is
	; stuff on the stack.
	;
	add	sp, 3 * size word	; Remove garbage from the stack
	jmp	quit			; Quit
SpreadsheetSetNote	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetNoteForActiveCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the note for the active cell

CALLED BY:	via MSG_SPREADSHEET_GET_NOTE_FOR_ACTIVE_CELL
PASS:		*ds:si	= instance ptr
		ds:si	= instance ptr
RETURN:		cx	= Size of the text (w/o NULL)
			= 0 if there is no text
		dx	= Block handle of the block containing the note text.
		NOTE: the block will always be returned
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetNoteForActiveCell	method	SpreadsheetClass,
				MSG_SPREADSHEET_GET_NOTE_FOR_ACTIVE_CELL
	mov	dx, ds:[di].SSI_active.CR_row
	mov	bp, ds:[di].SSI_active.CR_column
	call	SpreadsheetGetNote
	ret
SpreadsheetGetNoteForActiveCell	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the note for a given cell

CALLED BY:	via MSG_SPREADSHEET_GET_NOTE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		dx/bp	= Row/Column of the cell whose note we want to add.
RETURN:		cx	= Size of the text (w/o NULL)
			= 0 if there is no text
		dx	= Block handle of the block containing the note text.
		NOTE: the block will always be returned
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetNote	method	SpreadsheetClass, MSG_SPREADSHEET_GET_NOTE
	mov	si, di			; ds:si <- instance ptr
	
	mov	ax, dx			; ax <- row
	mov	cx, bp			; cx <- column
	SpreadsheetCellLock		; *es:di <- ptr to the cell
	jnc	noNote			; Branch if no cell
	
	;
	; The cell exists, get the dbase item for the note.
	;
	mov	di, es:[di]		; es:di <- ptr to the cell
	mov	ax, es:[di].CC_notes.segment
	mov	di, es:[di].CC_notes.offset
	SpreadsheetCellUnlock		; Release the cell
	
	tst	ax			; Check for no note
	jz	noNote			; Branch if no note
	
	;
	; A note exists for this cell.
	; ax/di = Group/Item of the note.
	;
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	call	DBLock			; *es:di <- ptr to the note
	mov	di, es:[di]		; es:di <- ptr to the note
	ChunkSizePtr	es, di, cx	; cx <- size of the note
EC <	tst	cx			; Check for zero sized note	>
EC <	ERROR_Z	NOTE_SHOULD_NOT_BE_ZERO_SIZED				>

	;
	; The note exists and we have a pointer to it in es:di. We now
	; allocate a block (locked) and 
	;
	push	cx, es, bx		; Save size, note segment, file handle

	push	cx, es, di		; Save size, ptr to the note
	mov	ax, cx			; ax <- size of block to allocate
	mov	cx, (mask HAF_LOCK or \
			mask HAF_ZERO_INIT or \
			mask HAF_NO_ERR) shl 8 or \
			mask HF_SHARABLE
	call	MemAlloc		; bx <- block handle
	mov	es, ax			; es:di <- ptr to the block
	clr	di
	
	mov	dx, bx			; dx <- block handle
	pop	cx, ds, si		; Restore size of note, ptr to note
	
	rep	movsb			; Copy the note text
	;
	; Now we unlock the block containing the note text and then unlock
	; the note itself.
	;
	call	MemUnlock		; Unlock block containing note text
	mov	dx, bx			; dx <- block handle
	pop	cx, es, bx		; Restore size, note segment, file handle
	LocalPrevChar	escx		; Don't count the NULL as part of the
					;   size.
	
	call	DBUnlock		; Release the note

quitAfterUnlock:
	ret

noNote:
	;
	; The cell didn't have any notes...allocate an empty block.
	;
	mov	ax, 2			;ax <- 1 byte for NULL
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8
	call	MemAlloc
	mov	dx, bx			;dx <- handle of text
	clr	cx			;cx <- Size of zero...
	jmp	quitAfterUnlock		;Branch to quit
	
SpreadsheetGetNote	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetNotesEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback for each note.

CALLED BY:	via MSG_SPREADSHEET_NOTES_ENUM
PASS:		ax	= MSG_SPREADSHEET_NOTES_ENUM
		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		bp	= Parameters to callback routine
		cx:dx	= Pointer to callback
		( The callback routine *must* be vfptr for XIP. )
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SEPRangeEnumParams	struct
    SEPREP_rep		RangeEnumParams		; The basic RangeEnumParams
    SEPREP_appCallback	dword			; Application callback
SEPRangeEnumParams	ends

SpreadsheetNotesEnum	method	SpreadsheetClass,
				MSG_SPREADSHEET_NOTES_ENUM
	mov	si, di			; ds:si <- Spreadsheet instance

	sub	sp, size SEPRangeEnumParams
	mov	bx, sp			; ss:bx <- ptr to RangeEnumParams, etc
	
	;
	; Fill in the stack frame.
	; cx:dx = Callback routine
	; We want all the data in the entire spreadsheet
	;

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	ss:[bx].SEPREP_appCallback.segment, cx
	mov	ss:[bx].SEPREP_appCallback.offset,  dx

	mov	ss:[bx].REP_callback.segment, SEGMENT_CS
	mov	ss:[bx].REP_callback.offset,  offset cs:NotesEnumCallback
	
	mov	ss:[bx].REP_bounds.R_top,    MIN_ROW
	mov	ss:[bx].REP_bounds.R_left,   MIN_ROW
	mov	ax, ds:[si].SSI_maxRow
	mov	ss:[bx].REP_bounds.R_bottom, ax
	mov	ax, ds:[si].SSI_maxCol
	mov	ss:[bx].REP_bounds.R_right,  ax

	clr	dl			; Examining data only
	call	RangeEnum		; Do the enum...

	add	sp, size SEPRangeEnumParams
	ret
SpreadsheetNotesEnum	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotesEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for SpreadsheetNotesEnum

CALLED BY:	SpreadsheetNotesEnum via RangeEnum
PASS:		*es:di	= Pointer to the cell
		ss:bx	= Pointer to SEPRangeEnumParams
		bp	= Parameters to pass to app callback
		ax	= Row of cell
		cx	= Column of cell

RETURN:		carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotesEnumCallback	proc	far
	class	SpreadsheetClass
	uses	ax, bx, dx, di
	.enter
	mov	di, es:[di]			; es:di <- ptr to cell
	cmp	es:[di].CC_notes.segment, 0	; Check for no note
	je	quit				; Branch if no note
						; If we branch, carry is clear

	push	es				; Save segment address of cell
	
	push	ax, bx				; Save the row, frame ptr
EC <	call	ECCheckInstancePtr		;>
	mov	bx, ds:[si].SSI_cellParams.CFP_file

	mov	ax, es:[di].CC_notes.segment	; ax <- DB group
	mov	di, es:[di].CC_notes.offset	; di <- DB item
	call	DBLock				; *es:di <- ptr to note
	pop	ax, bx				; Restore the row, frame ptr
	;
	; Call the application callback...
	;
	push	si				; Save instance ptr
	mov	dx, ds:LMBH_handle		; ^ldx:si <- instance OD
	mov	si, ds:[si].SSI_chunk
if FULL_EXECUTE_IN_PLACE
	mov	ss:[TPD_dataBX], bx
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, ss:[bx].SEPREP_appCallback	; Handle the note
	call	ProcCallFixedOrMovable
else
	call	ss:[bx].SEPREP_appCallback	; Handle the note
endif
	pop	si				; Restore instance ptr
	
	call	DBUnlock			; Release the note

	pop	es				; Restore seg address of cell
quit:
	clc					; Signal: continue
	.leave
	ret
NotesEnumCallback	endp

NotesCode	ends

