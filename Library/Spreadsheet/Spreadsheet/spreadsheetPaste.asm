COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetPaste.asm

AUTHOR:		Cheng, 6/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial revision

DESCRIPTION:
	The Paste code.

	Paste proceeds thus:

	for each cell {
	    update cell attrs if necessary
	    create the cell
	}

NOTES:
	Optimizations
	-------------

	When pasting to the same spreadsheet, the following can be skipped:
		1) style processing 
		2) format processing
		3) name processing ???
	
	When the source cell is 1x1, the following can be done:
		1) any target is compatible, so no need for the check
		2) don't use RangeEnum
	
	Conflict resolution
	-------------------

	There is no problem with styles because StyleGetTokenByStyle will
	do the right thing.

	For formats, there are 3 cases:

		1) Name unique - no problem, add the format. It doesn't
		   matter if the format is unique.

		2) Name not unique but format matches the entry - no problem,
		   don't add the format.

		3) Name not unique and format does not match the entry -
		   we resolve this as follows

		   The user has to choose between using the new format
		   definition, or choosing a new name.
	
	Names are handled similarly.

TO DO:
	formats
	check for scrap bounds exceeding spreadsheet bounds
	use token to paste existing styles
	names
		
	$Id: spreadsheetPaste.asm,v 1.1 97/04/07 11:14:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CutPasteStrings	segment lmem	LMEM_TYPE_GENERAL
	PrintMessage< Shouldn't these strings be in a UI file? >

if DBCS_PCGEOS
PasteResolveNameConflictStr	chunk.wchar \
	"The name '\1' already exists in this spreadsheet, Do you want to use the spreadsheet's definition?  (If you choose No, the definition in the scrap will be used).", 0
PasteBadShape		chunk.wchar \
	"You have selected an incorrect shape for the scrap.", 0
PasteOffEdge		chunk.wchar \
	"You have reached the size limit of the spreadsheet.", 0
PasteNameNoSpace	chunk.wchar \
	"You have reached the limit for the number of names allowed.", 0
PasteResolveFormatConflictStr	chunk.wchar \
	"The format '\1' already exists in this spreadsheet, Do you want to use the spreadsheet's definition?  (If you choose No, the definition in the scrap will be used).", 0

else
PasteResolveNameConflictStr	chunk.char \
	"The name '\1' already exists in this spreadsheet, Do you want to use the spreadsheet's definition?  (If you choose No, the definition in the scrap will be used).", 0

PasteBadShape		chunk.char \
	"You have selected an incorrect shape for the scrap.", 0
PasteOffEdge		chunk.char \
	"You have reached the size limit of the spreadsheet.", 0
PasteNameNoSpace	chunk.char \
	"You have reached the limit for the number of names allowed.", 0
PasteResolveFormatConflictStr	chunk.char \
	"The format '\1' already exists in this spreadsheet, Do you want to use the spreadsheet's definition?  (If you choose No, the definition in the scrap will be used).", 0
endif

if FLOPPY_BASED_DOCUMENTS
DocumentTooLargeString	chunk.char "The document is getting too large.  Operation aborted.",0
endif

if _PROTECT_CELL
CellProtectionError	chunk.char "This operation is attempting to modify the existing protected cell(s). Operation aborted.", 0

CellProtectEmptyError	chunk.char "The spreadsheet is empty. Operation aborted.", 0
endif

if CHECK_CUT_ERROR
CutCopyErrorString	chunk.char	"Not enough memory to cut or copy items.", 0
endif
CutPasteStrings	ends

CutPasteCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SpreadsheetDoPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	The method handler for MSG_META_CLIPBOARD_PASTE.
		This routine contains the code that interfaces with the
		clipboard.

CALLED BY:	GLOBAL (MSG_META_CLIPBOARD_PASTE)

PASS:		*ds:si - instance data

RETURN:		

DESTROYED:	ax,bx,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetDoPaste	method	dynamic	SpreadsheetClass,
				MSG_META_CLIPBOARD_PASTE
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	ForceRef	locals
	ForceRef	PSF_local
	ForceRef	SSM_local
	ForceRef	PSNP_local
	.enter

	push	si
	clr	ax			; ax <- ClipboardItemFlags
	call	PasteCommon		; destroy si
	pop	si
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset
	call	CutCopyRedrawRange

	.leave
	ret
SpreadsheetDoPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	INTERNAL (SpreadsheetDoPaste, SpreadsheetEndMoveCopy)

PASS:		*ds:si - instance data
		ax - ClipboardItemFlags

RETURN:		carry clear if successful, set if error
		cl - boolean - source ssheet = dest ssheet

DESTROYED:	ax,bx,ch,dx,di,si,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteCommon	proc	near
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	class	SpreadsheetClass
	.enter	inherit near

	xchg	si, di			; ds:si <- instance data
					; *ds:di <- instance data
	mov	bx, ax
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaInitForPaste
	pop	bp
	jc	done			; nothing to paste
doPaste::
	;
	; Perform the paste
	;
					; erase cell data before paste
	mov	PSF_local.PSF_clearDest, FALSE
	call	PasteDoPaste

	;
	; Call SSMetaDoneWithPaste() even in the event of an error,
	; as it calls ClipboardDoneWithItem()
	;
done:
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDoneWithPaste
	pop	bp

	.leave
	ret
PasteCommon	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PasteLow

DESCRIPTION:	Performs a paste that does not originate from the clipboard.

CALLED BY:	EXTERNAL (MSG_SSHEET_PASTE_FROM_DATA_FILE)

PASS:		*ds:si - instance data
		cx - VM file handle
		dx - VM block handle of the SSMetaHeaderBlock
		bp - transferVMChain

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

PasteLow	method	SpreadsheetClass, MSG_SSHEET_PASTE_FROM_DATA_FILE
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	ForceRef	locals
	ForceRef	PSF_local
	ForceRef	SSM_local
	ForceRef	PSNP_local
	.enter
	
	call	SetSelectionAt0_0
	xchg	si, di			; ds:si <- instance data
					; *ds:di <- instance data
	mov	bx, cx
	mov	ax, dx

	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaInitForRetrieval
	pop	bp

					; do not erase cell data before paste
	mov	PSF_local.PSF_clearDest, FALSE
	call	PasteDoPaste

	.leave
	ret
PasteLow	endm


SetSelectionAt0_0	proc	near
	push	cx,dx,bp,si
	sub	sp, size SpreadsheetRangeParams
	mov	bp, sp
	clr	ax
	mov	ss:[bp].SRP_selection.CR_start.CR_row, ax
	mov	ss:[bp].SRP_selection.CR_start.CR_column, ax
	mov	ss:[bp].SRP_selection.CR_end.CR_row, ax
	mov	ss:[bp].SRP_selection.CR_end.CR_column, ax
	mov	ss:[bp].SRP_active.CR_row, ax
	mov	ss:[bp].SRP_active.CR_column, ax
	mov	ax, MSG_SPREADSHEET_SET_SELECTION
	call	ObjCallInstanceNoLock
	add	sp, size SpreadsheetRangeParams
	pop	cx,dx,bp,si
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset
	ret
SetSelectionAt0_0	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteDoPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	The guts of the paste (as opposed to the clipboard interface).

CALLED BY:	INTERNAL (PasteCommon, PasteLow)

PASS:		PasteStackFrame
		ds:si - instance data (SpreadsheetClass)
		*ds:di - instance data
		bx - VM file handle
		ax - VM block handle of the SpreadsheetTransferHeader
		cx:dx - sourceID
		PSF_local.PSF_clearDest - erase cell data before pasting?

RETURN:		bx - vm file handle
		cl - PSF_sourceEqualsDest
		carry set if error, clear otherwise

DESTROYED:	ax,ch,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Header block needs to be unlocked!!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteDoPaste	proc	near
	class	SpreadsheetClass
	uses	bx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	.enter	inherit near

EC<	call	ECCheckInstancePtr >

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication	; destroys cx,dx

	mov	cx, SSM_local.SSMDAS_sourceID.high
	mov	dx, SSM_local.SSMDAS_sourceID.low
	call	PasteInitStackFrame

	call	PasteProcessCells
	LONG jc	error

	push	bx
	mov	bx, PSF_local.PSF_ssheetObjBlkHan
	mov	si, PSF_local.PSF_ssheetObjChunkOffset
	call	MemDerefDS				; ds:si <- SSheet
	pop	bx
EC<	call	ECCheckInstancePtr >

	;
	; If there is only a single selected cell then we need to fake the
	; range
	;
	cmp	PSF_local.PSF_singleCellSelected, 0
	je	done

EC<	cmp	PSF_local.PSF_rowMultiple, 1 >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS>
EC<	cmp	PSF_local.PSF_colMultiple, 1 >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS>

	;
	; fake the range
	;

	push	ax
	mov	ax, SSM_local.SSMDAS_scrapRows	; ax <- num rows in scrap
	add	ax, PSF_local.PSF_selectedRange.R_top
	tst	ax
	je	10$
	dec	ax
10$:
	mov	ds:[si].SSI_selected.CR_end.CR_row, ax

	mov	ax, SSM_local.SSMDAS_scrapCols
	add	ax, PSF_local.PSF_selectedRange.R_left
	tst	ax
	je	20$
	dec	ax
20$:
	mov	ds:[si].SSI_selected.CR_end.CR_column, ax
	pop	ax

	;
	; I won't set the range back to a single cell...
	; I will if there are problems or if enough people complain.
	;

done:
EC<	call	ECCheckInstancePtr >
	call	TransTblCleanUp

	;
	; done,
	; recalc stuff
	; redraw
	; turn off hour-glass
	;
	clc

error:
	pushf
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication
	mov	cl, PSF_local.PSF_sourceEqualsDest
	popf

	.leave
	ret
PasteDoPaste	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteInitStackFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the PasteStackFrame.

CALLED BY:	INTERNAL (PasteDoPaste)

PASS:		ds:si - instance data (SpreadsheetClass)
		*ds:di - instance data
		bx - transfer VM file handle
		ax - VM block handle of SpreadsheetTransferHeader
		cx:dx - sourceID
		PSF_local.PSF_clearDest - erase cell data before pasting?

RETURN:		nothing

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteInitStackFrame	proc	near
	class	SpreadsheetClass
	uses	ds,si,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	.enter	inherit near

	push	ax, es, di
	segmov	es, ss, ax			; es:di <- ptr to CellAttrs stuc
	lea	di, locals.CL_cellAttrs
	mov	ax, DEFAULT_STYLE_TOKEN
	mov	locals.CL_styleToken, ax	; store new token
	call	StyleGetStyleByTokenFar		; get associated styles
	pop	ax, es, di

	;-----------------------------------------------------------------------
	; zero init stack frame (except PSF_clearDest)

	push	ax,cx,di
	clr	ax
.assert (offset PSF_clearDest eq ((size PasteStackFrame)-(size PSF_clearDest)))
	mov	cx, size PasteStackFrame - size PSF_clearDest
	segmov	es, ss, di
	lea	di, PSF_local
	rep	stosb
	pop	ax,cx,di

	mov	PSF_local.PSF_styleEntry.SSME_token, INVALID_STYLE_TOKEN
	mov	PSF_local.PSF_formatTransTbl.TT_sig, TRANS_TABLE_SIG
	mov	PSF_local.PSF_nameTransTbl.TT_sig, TRANS_TABLE_SIG

	;-----------------------------------------------------------------------
	; save pointer to instance data
	; lock transfer header

	push	ax
	mov	ax, ds:LMBH_handle
	mov	PSF_local.PSF_ssheetObjBlkHan, ax
	pop	ax
	mov	PSF_local.PSF_ssheetObjChunkOffset, si
	mov	PSF_local.PSF_ssheetObjChunkHan, di

	mov	PSF_local.PSF_vmFileHan, bx
	mov	PSF_local.PSF_hdrBlkVMHan, ax

	;-----------------------------------------------------------------------
	; is the source spreadsheet the same as the destination spreadsheet?

	mov	PSF_local.PSF_sourceID.high, cx
	mov	PSF_local.PSF_sourceID.low, dx
	cmp	cx, ds:LMBH_handle
	jne	10$				; branch if not the same

	cmp	dx, si
	jne	10$				; branch if not the same

	mov	PSF_local.PSF_sourceEqualsDest, -1	; flag same

10$:
	;-----------------------------------------------------------------------
	; save the selected range

	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	PSF_local.PSF_selectedRange.R_top, ax
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	mov	PSF_local.PSF_selectedRange.R_bottom, ax
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	PSF_local.PSF_selectedRange.R_left, ax
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column
	mov	PSF_local.PSF_selectedRange.R_right, ax

	.leave
	ret
PasteInitStackFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteProcessCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Paste all the cells into the target region.

CALLED BY:	INTERNAL (PasteDoPaste)

PASS:		PasteStackFrame
		ds:si - instance data (SpreadsheetClass)
		PSF_local.PSF_clearDest - erase cell data before pasting?

RETURN:		carry clear if successful
		carry set otherwise
		    ax - error code
		    PASTE_SHAPE_INCOMPATIBLE

DESTROYED:	si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    Terminology:

	SHAPE:
	    The SHAPE of the selected area is considered to be COMPATIBLE
	    if the selected number of rows is a multiple of the scrap's number
	    of rows and the selected number of columns is a multiple of the
	    scrap's number of columns.
	
	INSTANCE:
	    An INSTANCE of a scrap is the entire collection of cells and
	    associated attributes that the scrap contains.  The user may
	    paste several scrap instances into a selected range.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteProcessCells	proc	near	uses	ax,bx,cx,dx
	class	SpreadsheetClass
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	.enter	inherit near


	;-----------------------------------------------------------------------
	; init vars
	; check for shape compatibility
	; check for conflicts in formats and names
if _PROTECT_CELL
	; 
	; For cell protection, check whether it will paste to the protected
	; cell. We need to stop the operation if it will
	;
	call	PasteCheckProtection	;branch if protected cell found
	jc	protectionError	
endif
	call	PasteCheckOffEdge
	jc	offEdge				;branch if off edge

	call	PasteCheckShapeCompatibility
	jnc	compatible			; branch if compatible

	mov	si, offset PasteBadShape
	jmp	errAbort

offEdge:
	mov	si, offset PasteOffEdge
	jmp	errAbort

if _PROTECT_CELL
protectionError:
	mov	si, offset CellProtectionError
	jmp	errAbort
endif

compatible:
	call	PasteHandleFormatConflicts	; no return code yet, but when
;	jc	short errAbort			;   there is...abort

	;
	; if the scrap came from the same spreadsheet, the will be no conflicts
	;
	call	PasteHandleNameConflicts
	jnc	10$

	mov	si, offset PasteNameNoSpace
	jmp	errAbort

10$:

	;-----------------------------------------------------------------------
	
	; erase destination cells, if caller requests

	tst	PSF_local.PSF_clearDest
	jz	afterClear
   ;
   ; Get the rectangle of cells that comprise the paste destination range
   ;
	push	si, bp
	sub	sp, size CellRange	; put CellRange parameters on stack
	mov	bx, sp

	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	ss:[bx].CR_start.CR_row, ax
	add	ax, SSM_local.SSMDAS_scrapRows
	dec	ax
	mov	ss:[bx].CR_end.CR_row, ax
	
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	ss:[bx].CR_start.CR_column, ax
	add	ax, SSM_local.SSMDAS_scrapCols
	dec	ax
	mov	ss:[bx].CR_end.CR_column, ax
   ;
   ; Call a method to delete the cells in the paste destination range
   ;
	mov	bp, bx			; ss:bp -> CellRange parameters
	mov	cx, mask SCF_CLEAR_DATA or \
			mask SCF_CLEAR_ATTRIBUTES

   	call	SpreadsheetClearRange
	add	sp, size CellRange
	pop	si, bp
afterClear:

	;-----------------------------------------------------------------------
	; init coords for the first instance

	mov	ax, PSF_local.PSF_selectedRange.R_top
	mov	cx, PSF_local.PSF_selectedRange.R_left

	mov	bx, ax
	mov	dx, cx
	add	bx, SSM_local.SSMDAS_scrapRows
	dec	bx
	jl	done
	add	dx, SSM_local.SSMDAS_scrapCols
	dec	dx
	jl	done

	;-----------------------------------------------------------------------
	; paste all instances.
	; paste will proceed left to right then down.

pasteLoop:
	call	PastePasteScrapInstance

	dec	PSF_local.PSF_colCount		; dec column count
	je	nextRow

	;-----------------------------------------------------------------------
	; next instance is to the right

	add	cx, SSM_local.SSMDAS_scrapCols	; bump left coord
	add	dx, SSM_local.SSMDAS_scrapCols	; bump right coord
	jmp	short pasteLoop

nextRow:
if FLOPPY_BASED_DOCUMENTS
	call	SpreadsheetCheckDocumentSize
	jc	done
endif
	dec	PSF_local.PSF_rowCount		; dec row count
	je	done

	;-----------------------------------------------------------------------
	; next instance is on the next row

	push	ax
	mov	ax, PSF_local.PSF_colMultiple
	mov	PSF_local.PSF_colCount, ax	; reset column count
	pop	ax

	add	ax, SSM_local.SSMDAS_scrapRows	; bump top coord
	add	bx, SSM_local.SSMDAS_scrapRows	; bump bot coord
	mov	cx, PSF_local.PSF_selectedRange.R_left	; reset left coord
	mov	dx, cx				; reset right coord
	add	dx, SSM_local.SSMDAS_scrapCols
	dec	dx
	jmp	short pasteLoop

done:
	.leave
	ret

errAbort:
	;
	; serious error encountered - PSEE_NOT_ENOUGH_NAME_SPACE
	; inform user that we cannot proceed
	;

	call	PasteNameNotifyDB
	stc
	jmp	short done

PasteProcessCells	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCheckDocumentSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the document is getting too large, and if the
		current paste / fill operation should be aborted.

CALLED BY:	PasteProcessCells

PASS:		ds:si - Spreadsheet instance data

RETURN:		carry SET if error
		carry clear otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/17/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOPPY_BASED_DOCUMENTS
SpreadsheetCheckDocumentSize	proc far
		class	SpreadsheetClass
		uses	bx, cx, dx
		.enter
EC <		call	ECCheckInstancePtr				>

		mov	bx, ds:[si].SSI_cellParams.CFP_file
		call	VMGetUsedSize
		cmpdw	dxcx, MAX_TOTAL_FILE_SIZE
		jae	tooLarge
		clc
done:
		.leave
		ret
tooLarge:
		push	si
		mov	si, offset DocumentTooLargeString
		call	PasteNameNotifyDB
		pop	si
		stc
		jmp	done
SpreadsheetCheckDocumentSize	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteCheckOffEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the paste will take us off the spreadsheet

CALLED BY:	PasteProcessCells()
PASS:		ds:si - Spreadsheet instance
		ss:bp - inherited locals
RETURN:		carry - set if will go off edge
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteCheckOffEdge		proc	near
	uses	ax
	class	SpreadsheetClass
locals		local	CellLocals
PSF_local	local	PasteStackFrame
SSM_local	local	SSMetaStruc
PSNP_local	local	SpreadsheetNameParameters
	.enter	inherit

	mov	ax, PSF_local.PSF_selectedRange.R_left
	add	ax, SSM_local.SSMDAS_scrapCols
	dec	ax
	cmp	ax, ds:[si].SSI_maxCol
	ja	scrapOffEdge

	mov	ax, PSF_local.PSF_selectedRange.R_top
	add	ax, SSM_local.SSMDAS_scrapRows
	dec	ax
	cmp	ax, ds:[si].SSI_maxRow
	ja	scrapOffEdge

	clc					;carry <- scrap OK
done:
	.leave
	ret

scrapOffEdge:
	stc					;carry <- error / off edge
	jmp	done
PasteCheckOffEdge		endp


if _PROTECT_CELL
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteCheckProtection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the paste will modify any protected cells.

CALLED BY:	PasteProcessCells()
PASS:		ds:si	= Spreadsheet instance
		ss:bp	= inherited locals
RETURN:		carry	= set if protected cells found
		carry	= clear if paste operation is safe.
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	* Get the range of cells to check and then do the checking
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteCheckProtection	proc	near
		class	SpreadsheetClass
locals		local	CellLocals
PSF_local	local	PasteStackFrame
SSM_local	local	SSMetaStruc
PSNP_local	local	SpreadsheetNameParameters
		uses	ax, bx, cx, dx
		.enter	inherit
EC <		call	ECCheckInstancePtr 				>
	;
	; Find out the range which the data will paste to
	;
		mov	cx, PSF_local.PSF_selectedRange.R_left	;cx =left bound
		mov	dx, PSF_local.PSF_selectedRange.R_right	;dx=right bound
		mov	ax, PSF_local.PSF_selectedRange.R_top	;ax = top bound
		mov	bx, PSF_local.PSF_selectedRange.R_bottom ;bx =bot bound
	;
	; Having got the bounds to be pasted, make sure this range doesn't
	; have any protected cell.
	;
		call	CheckProtectedCell
		jc	done
	;
	; Next, test the scrap size.
	;
		mov	dx, cx
		add	dx, SSM_local.SSMDAS_scrapCols
		dec	dx				;dx = scrap right
		mov	bx, ax
		add	bx, SSM_local.SSMDAS_scrapRows
		dec	bx				;bx = scrap bottom
		call	CheckProtectedCell
done:
		.leave
		ret
PasteCheckProtection		endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteCheckShapeCompatibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Checks to see that the selected area is compatible with
		the scrap.

		The shape of the selected area is considered to be compatible
		if the selected number of rows is a multiple of the scrap's
		number of rows and the selected number of columns is a multiple
		of the scrap's number of columns.

CALLED BY:	INTERNAL (PasteProcessCells)

PASS:		PasteStackFrame

RETURN:		carry clear if compatible
		    PSF_rowMultiple - row multiple
		    PSF_colMultiple - column multiple

		    PSF_rowCount = PSF_rowMultiple
		    PSF_colCount = PSF_colMultiple
		carry set if not compatible

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if the selected range is a single cell then {
	    the scrap is compatible
	} else {
	    see if the number of rows in the selected range is a whole multiple
	        of the scrap's number of rows
	    see if the number of cols in the selected range is a whole multiple
	        of the scrap's number of cols
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteCheckShapeCompatibility	proc	near	uses	cx,dx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	.enter	inherit near

	mov	ax, PSF_local.PSF_selectedRange.R_right
	cmp	ax, PSF_local.PSF_selectedRange.R_left
	jne	notSingleCell

	mov     ax, PSF_local.PSF_selectedRange.R_bottom
	cmp	ax, PSF_local.PSF_selectedRange.R_top
	jne	notSingleCell

	;
	; single cell
	;
	dec	PSF_local.PSF_singleCellSelected
	mov	ax, 1
	mov	PSF_local.PSF_rowMultiple, ax
	mov	PSF_local.PSF_rowCount, ax
	mov	PSF_local.PSF_colMultiple, ax
	mov	PSF_local.PSF_colCount, ax
	clc					; indicate compatible
	jmp	short done

notSingleCell:
	mov     ax, PSF_local.PSF_selectedRange.R_bottom
	sub	ax, PSF_local.PSF_selectedRange.R_top
	inc	ax

	clr	dx
	mov	cx, SSM_local.SSMDAS_scrapRows
	div	cx
	tst	dx				; any remainder?
	stc					; assume not compatible
	jne	done				; branch if assumption correct

	mov	PSF_local.PSF_rowMultiple, ax
	mov	PSF_local.PSF_rowCount, ax

	mov	ax, PSF_local.PSF_selectedRange.R_right
	sub	ax, PSF_local.PSF_selectedRange.R_left
	inc	ax

	clr	dx
	mov	cx, SSM_local.SSMDAS_scrapCols
	div	cx

	mov	PSF_local.PSF_colMultiple, ax
	mov	PSF_local.PSF_colCount, ax
	tst	dx				; any remainder? (carry cleared)
	je	done				; done if none

	stc					; indicate not compatible

done:
	.leave
	ret
PasteCheckShapeCompatibility	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteHandleFormatConflicts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Traverse the format chain to see if there are any conflicts.

CALLED BY:	INTERNAL ()

PASS:		PasteStackFrame
		ds:si - SpreadsheetInstance
		es:0  - FormatInfoStruc

RETURN:		carry set if error

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	traverse format data chain
	for each entry
	    if the format is predefined then {
		new token <- old token
	    } else {
	retryLoop:
		if name is unique then {
		    ; no problem
		    add the format
		    new token <- result of format addition
		} else if name not unique but format matches exactly {
		    ; no problem
		    new token <- token of match
		} else {
		    ; hassle time
		    if this is the first conflict for this token then {
		        ask user - use new format definition or scrap's def
		        if user chooses 'use new format' then {
			    new token <- new format
	                }
		    } else {
			generate new name
			goto retryLoop
		    }
		}
	    }
	
	Implementation notes:
	---------------------
	We will use the PSF_cellEntry buffer as the work space.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteHandleFormatConflicts	proc	near	uses	bx,cx,dx,es,si,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	PSNP_local	local	SpreadsheetNameParameters
	.enter	inherit near

PrintMessage <Need to handle InitFormatInfoStruc return code>
	call	InitFormatInfoStruc	; es <- info struc, bx <- mem han
;	LONG	jc	exit		; use when there is a return code
	push	bx

	;
	; init vars
	;
	clr	PSF_local.PSF_conflictFormatAdded
	clr	PSF_local.PSF_conflictResNum

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_FORMAT
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayResetEntryPointer
	pop	bp

processNextEntry:
	call	PasteRetrieveEntry		; cx <- size of data
	LONG jc	done				; done if all entries processed

EC <	; Let's make sure the data size is FormatParms size		>
EC <	; If CT_TEXT, then an extra null would have been appended	>
EC <	; in PasteRetrieveEntry().					>

EC <	push	si, ds, es						>
EC <	segmov	es, ss							>
EC <	push	bp							>
EC <	lea	bp, SSM_local						>
EC <	mov	ds, es:[bp].SSMDAS_formatEntry.SSMED_ptr.high		>
EC <	mov	si, es:[bp].SSMDAS_formatEntry.SSMED_ptr.low		>
EC <	pop	bp							>

EC <	cmp	ds:[si+(size SSMetaEntry)+(offset CC_type)], CT_TEXT	>
EC <	jne	ecNotText						>

EC <SBCS <	cmp	cx, size FormatParams + size char		>>
EC <DBCS <	cmp	cx, size FormatParams + size wchar		>>
EC <	jmp	ecDoneCmp						>
EC < ecNotText:								>
EC <	cmp	cx, size FormatParams					>
EC < ecDoneCmp:								>
EC <	ERROR_NE REQUESTED_ENTRY_IS_TOO_LARGE				>
EC <	pop	si, ds, es						>

	test	PSF_local.PSF_cellEntry.SSME_token, FORMAT_ID_PREDEF
	jne	processNextEntry

	;-----------------------------------------------------------------------
	; user-defined format

	push	di

checkNameLoop:

	push	bp
	mov	dx, ss
	lea	bp, PSF_local.PSF_cellEntry.SSME_dataPortion
	call	InitFormatParamsField
	call	FloatFormatGetFormatTokenWithName
	pop	bp

	cmp	cx, FLOAT_FORMAT_FORMAT_NAME_NOT_FOUND
	jne	nameNotUnique

	;-----------------------------------------------------------------------
	; name is unique, add the format

	mov	PSF_local.PSF_conflictFormatAdded, TRUE
	push	PSF_local.PSF_cellEntry.SSME_token	; save original token
	push	bp
	mov	dx, ss
	lea	bp, PSF_local.PSF_cellEntry.SSME_dataPortion
	call	FloatFormatAddFormat			; dx <- new token
	pop	bp

EC<	cmp	cx, FLOAT_FORMAT_NO_ERROR >
EC<	ERROR_NE PASTE_TRANS_TBL_CANT_ADD_FORMAT >

	pop	cx				; retrieve old token

addToTransTbl:
	; make note of translation
	;
	lea	bx, PSF_local.PSF_formatTransTbl
	call	TransTblAddEntry
	jmp	short entryProcessed

nameNotUnique:
	;
	; name is not unique
	; check to see if format is the same
	; cx = format token
	;
	push	PSF_local.PSF_cellEntry.SSME_token	; save original token
	push	cx					; save new token

	push	bp
	mov	dx, ss
	lea	bp, PSF_local.PSF_cellEntry.SSME_dataPortion	; dx:bp <- FormatParams
	call	FloatFormatIsFormatTheSame?
	pop	bp

	;-----------------------------------------------------------------------
	; if name's the same and format's the same, use new token
	; make note of translation

	cmp	cx, SPREADSHEET_FORMAT_PARAMS_MATCH
	pop	dx				; retrieve new token
	pop	cx
	je	short addToTransTbl

	;-----------------------------------------------------------------------
	; name's the same but format's different, we have a conflict here...
	; If this is the first conflict, ask the user how to resolve it

	cmp	PSF_local.PSF_conflictResNum, 1
	jae	generateName
	push	cx, dx
	mov	si, offset PasteResolveFormatConflictStr
	mov	cx, ss
	lea	dx, PSF_local.PSF_cellEntry.SSME_dataPortion + \
		offset FP_formatName		; cx:dx <- offending name string
	call	PasteConflictQueryUser
	pop	cx, dx
	jnc	short addToTransTbl		; use spreadsheet's definition

generateName:
	;-----------------------------------------------------------------------
	; The user has chosen to keep the format from the scrap, so
	; generate a new name for it.
	
	push	es
	segmov	es, ss, di
	lea	di, PSF_local.PSF_cellEntry.SSME_dataPortion + \
		offset FP_formatName
	mov	PSF_local.PSF_maxNameLength, MAX_NAME_LENGTH
	call	ConflictGenerateNewName		; destroys ax,cx,dx,di
	pop	es
	jmp	checkNameLoop

entryProcessed:
	pop	di
	clr	PSF_local.PSF_conflictResNum	; start at 0 on next conflict
	jmp	processNextEntry

done:
	pop	bx				; retrieve info struc han
	call	MemFree
	call	PasteUnlockSSMetaDataArrayIfEntriesPresent

	cmp	PSF_local.PSF_conflictFormatAdded, TRUE
	jne	exit

	; 
	; One or names have been added, either to resolve a conflict or
	; because there are new names. Notify the FormatController to
	; update its UI.
	;
	mov	ax, SNFLAGS_FORMAT_LIST_CHANGE	
	mov	si, PSF_local.PSF_ssheetObjChunkOffset
	call	SS_SendNotification

exit:
	.leave
	ret
PasteHandleFormatConflicts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	InitFormatInfoStruc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	INTERNAL (PasteHandleFormatConflicts)

PASS:		ds:si - SpreadsheetInstance

RETURN:		es:0 - FormatInfoStruc with several fields initialized
		bx - mem handle of FormatInfoStruc
		carry set if error
			^lsi - error string

DESTROYED:	ax,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFormatInfoStruc	proc	near
	class	SpreadsheetClass
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	;
	; There used to be a comment about how HAF_NO_ERR
	; shouldn't be passed to MemAlloc here.  Given the size of
	; FormatInfoStruc, however, HAF_NO_ERR is entirely appropriate.
	;
		
	mov	ax, size FormatInfoStruc
	mov	cx, mask HF_SWAPABLE or ((mask HAF_LOCK or mask HAF_ZERO_INIT \
		or mask HAF_NO_ERR) shl 8)
	call	MemAlloc

	mov	es, ax
	mov	es:FIS_signature, FORMAT_INFO_STRUC_ID
	mov	es:FIS_childBlk, -1
	mov	ax, ds:[si].SSI_cellParams.CFP_file
	mov	es:FIS_userDefFmtArrayFileHan, ax
	mov	ax, ds:[si].SSI_formatArray
	mov	es:FIS_userDefFmtArrayBlkHan, ax
done::
	.leave
	ret

;error:
;	mov	si, offset some string name
;	jmp	done

InitFormatInfoStruc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	InitFormatParamsField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	INTERNAL (PasteHandleFormatConflicts)

PASS:		dx:bp - FormatParams
		es:0 FormatInfoStruc
		al - value to store (repeated)

RETURN:		FIS_curParams field in FormatInfoStruc initialized

DESTROYED:	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		Should `al' be passed in ?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFormatParamsField	proc	near	uses	ds,si,di
	.enter
	
	mov	di, offset FIS_curParams
	mov	ds, dx
	mov	si, bp
	mov	cx, size FormatParams
	rep	movsb

	.leave
	ret
InitFormatParamsField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ConflictGenerateNewName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Generate a hopefully unique name by tacking on '_###'.
		The generated name will be checked for uniqueness and
		this routine will be called again if the name isn't unique.

CALLED BY:	INTERNAL (PasteHandleFormatConflicts)

PASS:		PasteStackFrame with the following:
		    PSF_conflictResNum		; the last resolution num used
		    PSF_maxNameLength
		es:di - location of current name

RETURN:		PasteStackFrame with:
		    PSF_conflictResNum incremented
		cx - length of the new name (excluding null)

DESTROYED:	ax,dx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version
	witt	11/93		DBCS-ized strings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RESOLUTION_NUM_CHARS = 6			; '_' + 5 numeric chars

ConflictGenerateNewName	proc	near
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	push	di			; save start address
	;
	; locate end of string
	;
SBCS<	clr	al							>
DBCS<	clr	ax							>
	mov	cx, 0ffffh
	LocalFindChar			; stops just past null
	LocalPrevChar	esdi		; point di at null

	neg	cx
	sub	cx, 2			; cx <- length

	mov	ax, PSF_local.PSF_maxNameLength
	sub	ax, cx			; ax <- chars available for num
	cmp	ax, RESOLUTION_NUM_CHARS
	jge	enoughSpace

SBCS<	sub	di, RESOLUTION_NUM_CHARS*(size char)			>
DBCS<	sub	di, RESOLUTION_NUM_CHARS*(size wchar)			>
	add	di, ax
DBCS<	add	di, ax			; update name ptr		>

enoughSpace:
;	mov	al, '_'
;	stosb

	mov	ax, PSF_local.PSF_conflictResNum
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii

	;
	; calculate the length of the name
	;
	LocalClrChar	ax
	mov	cx, 0ffffh
	LocalFindChar
	LocalPrevChar	esdi		; point di at null
	pop	cx			; retrieve start addr of name
	xchg	cx,di			; cx <- null, di <- start
	sub	cx, di			; cx <- size excl null
DBCS<	shr	cx, 1			; cx <- unique name length	>

	;
	; up PSF_conflictResNum
	;
	inc	PSF_local.PSF_conflictResNum

	.leave
	ret
ConflictGenerateNewName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PastePasteScrapInstance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Paste an instance of a scrap in the selected region.
		If the scrap is a single cell, then we won't rely on RangeEnum.

CALLED BY:	INTERNAL (PasteProcessCells)

PASS:		ds:si - instance data (SpreadsheetClass)
		(ax,cx)
		(bx,dx) - scrap instance to instantiate

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PastePasteScrapInstance	proc	near
	class	SpreadsheetClass
	uses	ax,bx,cx,dx,es,di

	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC<	cmp	si, PSF_local.PSF_ssheetObjChunkOffset >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >

	mov	PSF_local.PSF_instanceRow, ax
	mov	PSF_local.PSF_instanceCol, cx

	call	CreateGStateFar			; di <- gstate handle
	mov	locals.CL_gstate, di		; pass gstate handle

	;
	; init params for CallRangeEnum
	;
	mov	di, ds:[si].SSI_visible.CR_start.CR_row
	mov	locals.CL_origin.CR_row, di
	mov	di, ds:[si].SSI_visible.CR_start.CR_column
	mov	locals.CL_origin.CR_column, di

	mov	di, ds:[si].SSI_drawFlags
	mov	locals.CL_drawFlags, di

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_CELL
	push	dx,bp
	mov	dx, ss
	lea	bp, SSM_local
	call	SSMetaDataArrayResetEntryPointer
	pop	dx,bp

processLoop:
	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_CELL
	call	PasteRetrieveEntry		; cx <- size of cell data
	jc	done

	; 
	; check that the entry is not bigger than the biggest possible
	; buffer for a cell item, which would be a formula.
	;
EC <	cmp	cx, CELL_FORMULA_BUFFER_SIZE		>
EC < 	ERROR_A	REQUESTED_ENTRY_IS_TOO_LARGE		>

	mov	dx, cx				; dx <- size of cell data
	segmov	es, ss, di
	lea	di, PSF_local.PSF_cellEntry

	mov	ax, es:[di].SSME_coordRow

	add	ax, PSF_local.PSF_instanceRow
	mov	cx, es:[di].SSME_coordCol
	add	cx, PSF_local.PSF_instanceCol

	lea	di, PSF_local.PSF_cellBuf
	call	PasteUpdateCellVarsInStackFrame	; destroys bx,cx
	;
	; for PasteCreateCell, pass:
	;	ds:si - pointer to spreadsheet instance
	;	es:di - Cell... structure
	;	dx - size of Cell... structure
	;	(ax,cx) - cell coordinates (r,c)
	;
	call	PasteCreateCell			; destroys bx

	SpreadsheetCellLock			; *es:di <- ptr to the cell
	call	PasteSetAttrsFinish
	SpreadsheetCellUnlock
EC<	test	dl, not RangeEnumFlags			>
EC<	ERROR_NE CUT_COPY_BAD_FLAGS			>
	jmp	short processLoop

done:
	call	DestroyGStateFar
	call	PasteUnlockSSMetaDataArrayIfEntriesPresent

	.leave
	ret
PastePasteScrapInstance	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteUpdateCellVarsInStackFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Checks to see if the CellAttrs in the stack frame match those
		of the current cell.  If they do then we're done else we
		will need to search the style chain and copy the appropriate
		style into the stack frame.
s
CALLED BY:	INTERNAL (PasteCellCallback)

PASS:		es:di - Cell... structure
		es = ss
		dx - cell size

RETURN:		PSF_local.PSF_styleBuf

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	The scrap's data entry needs to be copied into some other
	space (we use the stack frame) because the cell allocation routines
	trash it, whereas the scrap is necessarily read-only.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteUpdateCellVarsInStackFrame	proc	near	uses	ax,bx,cx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	;-----------------------------------------------------------------------
	; see if the style attrs are up to date

	mov	ax, PSF_local.PSF_cellBuf + offset CC_attrs ; scrap's style tok
	cmp	ax, PSF_local.PSF_styleEntry.SSME_token
	je	doneStyles

	;-----------------------------------------------------------------------
	; tokens do not match
	; search required to locate CellAttrs in the style chain

	push	ax,dx,bp
	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_STYLE
	mov	dx, ss
	lea	bp, SSM_local
	call	SSMetaDataArrayGetNumEntries
	tst	ax
	pop	ax,dx,bp
	je	doneStyles

	call	PasteRetrieveStyleEntry

	;
	; translate format token
	;
	push	bx,cx,dx
	mov	cx, PSF_local.PSF_styleEntry.SSME_dataPortion + offset CA_format
	test	cx, FORMAT_ID_PREDEF		; if it's a predefined format,
	jnz	noChange			;   it's not going to change
	lea	bx, PSF_local.PSF_formatTransTbl
	call	TransTblSearch			; dx <- new token
EC<	ERROR_C	PASTE_TRANS_TBL_CANT_LOCATE_FORMAT >
	mov	PSF_local.PSF_styleEntry.SSME_dataPortion + offset CA_format, dx
noChange:
	pop	bx,cx,dx

doneStyles:
	;-----------------------------------------------------------------------
	; see if the format attrs are up to date

	.leave
	ret
PasteUpdateCellVarsInStackFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteCreateCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Creates a single cell given the cell's particulars.

CALLED BY:	INTERNAL (PasteCellCallback)

PASS:		ds:si - pointer to spreadsheet instance
		es:di - Cell... structure in PasteStackFrame
		dx - size of Cell... structure
		(ax,cx) - cell coordinates (r,c)

RETURN:		

DESTROYED:	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteCreateCell	proc	near
	class	SpreadsheetClass
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC<	call	ECCheckInstancePtr >
	;
	; need to fake curRow and Col cos we may be pasting an instance
	; within the selected range
	;
	push	ds:[si].SSI_active.CR_row
	push	ds:[si].SSI_active.CR_column
	mov	ds:[si].SSI_active.CR_row, ax
	mov	ds:[si].SSI_active.CR_column, cx

	mov	bl, es:[di].CC_type

	cmp	bl, CT_TEXT
	jne	checkConstant

	call	InitCellAttrsPtr
	call	PasteCreateTextCell
	jmp	short done

checkConstant:
	cmp	bl, CT_CONSTANT
	jne	checkFormula

	call	InitCellAttrsPtr
	call	PasteCreateConstantCell
	jmp	short done

checkFormula:
	cmp	bl, CT_FORMULA
	je	10$
	cmp	bl, CT_DISPLAY_FORMULA
	jne	checkEmpty

10$:
	call	InitCellAttrsPtr
	call	PasteCreateFormulaCell
	jmp	short done

checkEmpty:
	cmp	bl, CT_EMPTY
	jne	done

	call	InitCellAttrsPtr
	call	PasteCreateEmptyCell

done:
EC<	call	ECCheckInstancePtr >
	;
	; ds:si	= Pointer to spreadsheet instance
	; Need to reload the row/column of the cell we're working on
	;
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column	;(ax,cx) <- active (r,c)

	ornf	ds:[si].SSI_flags, mask SF_SUPPRESS_REDRAW
	call	RecalcDependents		;recalc cell dependents
	andnf	ds:[si].SSI_flags, not mask SF_SUPPRESS_REDRAW

	pop	ds:[si].SSI_active.CR_column
	pop	ds:[si].SSI_active.CR_row

	.leave
	ret
PasteCreateCell	endp

InitCellAttrsPtr	proc	near
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	clr	bx

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_STYLE
	push	ax,dx,bp
	mov	dx, ss
	lea	bp, SSM_local
	call	SSMetaDataArrayGetNumEntries	; ax <- num entries
	tst	ax
	pop	ax,dx,bp
	je	done

	lea	bx, PSF_local.PSF_styleBuf

done:
	.leave
	ret
InitCellAttrsPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteCreate...Cell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Create a cell given the cell data from the scrap.

CALLED BY:	INTERNAL (PasteCreateCell)

PASS:		ds:si - pointer to spreadsheet instance
		es:di - Cell... structure (eg. CellText)
		dx - size of Cell... structure
		(ax,cx) - cell coordinates (r,c)
		ss:bx - CellAttrs for cell
		PasteStackFrame is applicable

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteCreateTextCell	proc	near	uses	dx
	.enter

EC<	cmp	es:[di].CC_type, CT_TEXT >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >
EC<	call	ECPasteCreateCheckES >

SBCS <	sub	dx, size CellCommon + (size char)  ;dx <- size of text only	>
DBCS <	sub	dx, size CellCommon + (size wchar) ;dx <- size of text only	>
DBCS<	shr	dx, 1				;dx <- string length	>
	add	di, (size CellCommon)		;es:di <- ptr to text
	call	AllocTextCell
	.leave
	ret
PasteCreateTextCell	endp


PasteCreateConstantCell	proc	near	uses	bx,dx,di
	.enter

EC<	cmp	es:[di].CC_type, CT_CONSTANT >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >
EC<	call	ECPasteCreateCheckES >

	;
	; need to pass:
	;	ds:si - Spreadsheet instance
	;	(ax,cl) - cell coordinates (r,c)
	;	es:di - FloatNum
	;	ss:bx - CellAttrs for cell
	;
	add	di, (offset CC_current)		;es:di <- ptr to FloatNum
	call	AllocConstantCell

	.leave
	ret
PasteCreateConstantCell	endp


PasteCreateFormulaCell	proc	near	uses	ax,bx,cx,dx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC<	cmp	es:[di].CC_type, CT_FORMULA >
EC<	je	10$ >
EC<	cmp	es:[di].CC_type, CT_DISPLAY_FORMULA >
EC<	ERROR_NE ROUTINE_USING_BAD_PARAMS >
EC< 10$: >
EC<	call	ECPasteCreateCheckES >

	;
	; translate names if necessary
	;
	call	PasteFormulaTranslateNames

	push	bp
	sub	sp, size PCT_vars
	mov	bp, sp

	;
	; initialize the stack frame
	;
	push	bx				; Save attributes token
	push	ax,cx,ds,si
	call	SpreadsheetInitCommonParamsFar
	mov	ss:[bp].PP_parserBufferSize, PARSE_TEXT_BUFFER_SIZE
	mov	ss:[bp].PP_flags, 0

	segmov	ds, es, si			; ds:si <- tokens
	mov	si, di
	mov	cx, ds:[si].CF_formulaSize
	add	si, size CellFormula
	segmov	es, ss, di
	lea	di, ss:[bp].PCTV_parseBuffer
	rep	movsb

	pop	bx,dx,ds,si			; (bx,dx) <- coords

	push	bx, dx				; Save row/column
	call	SpreadsheetAllocFormulaCellNoGC	; destroys ax,bx,dx
	pop	ax, cx				; Restore row/column
	
	;
	; Need to set the attributes for the cell because it isn't possible
	; to pass those attributes to SpreadsheetAllocFormulaCellFar.
	;
	; First we get the token for these attributes.
	;
	pop	bx				; Restore attributes token
	call	CreateNewCellAttrsFar		; bx <- attribute token

	;
	; Then we save it.
	;
	SpreadsheetCellLock			; *es:di <- ptr to the cell
	mov	di, es:[di]			; es:di <- ptr to the cell
	xchg	es:[di].CC_attrs, bx		; Save attribute token
						; bx <- old token
	SpreadsheetCellDirty			; Dirty the cell
	SpreadsheetCellUnlock			; Release the cell

	;
	; Check to see if the attributes have changed, and if they have,
	; then we want to decrement the reference count for the old token.
	;
	cmp	bx, es:[di].CC_attrs		; changed styles?
	je	skipStyleDelete			; branch if no change
	
	mov	ax, bx				; ax <- old token
	call	StyleDeleteStyleByTokenFar
skipStyleDelete:

	add	sp, size PCT_vars		; don't need this anymore
	pop	bp
	.leave
	ret
PasteCreateFormulaCell	endp


PasteCreateEmptyCell	proc	near	uses	bx,es
	.enter
;	push	es:LMBH_handle
	call	AllocEmptyCell
;	pop	bx
;	call	MemDerefES
	.leave
	ret
PasteCreateEmptyCell	endp


if	ERROR_CHECK
ECPasteCreateCheckES	proc	near
	push	ax,bx
	mov	ax, es
	mov	bx, ss
	cmp	ax, bx
	ERROR_NE ROUTINE_USING_BAD_PARAMS
	pop ax,bx
	ret
ECPasteCreateCheckES	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteFormulaTranslateNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initiate a callback for each of the formula's tokens and check
		to see if the token is that of a name that we have a translation
		for.

CALLED BY:	INTERNAL (PasteCreateFormulaCell)

PASS:		ds:si - pointer to spreadsheet instance
		es:di - CellFormula structure
		dx - size of Cell... structure
		(ax,cx) - cell coordinates (r,c)

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteFormulaTranslateNames	proc	near	uses	cx,dx,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	add	di, size CellFormula		; es:di <- tokens
	mov	cx, SEGMENT_CS			; cx:dx <- callback routine
	mov	dx, offset cs:PasteFormulaTranslateNamesCallback
	call	ParserForeachReference

	.leave
	ret
PasteFormulaTranslateNames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteFormulaTranslateNamesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Callback routine.  Check to see if the current token is that
		of a name that we have a translation for.

CALLED BY:	INTERNAL (PasteFormulaTranslateNames via ParserForeachReference)

PASS:		ds:si - Spreadsheet instance
		es:di - Pointer to the cell reference
		al - Type of reference:
			PARSER_TOKEN_CELL
			PARSER_TOKEN_NAME

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteFormulaTranslateNamesCallback	proc	far	uses	bx,cx,dx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit far

	;
	; al is one of PARSER_TOKEN_CELL or PARSER_TOKEN_NAME
	;
	cmp	al, PARSER_TOKEN_NAME		; name?
	jne	done				; done if not

	mov	cx, es:[di].PTND_name		; cx <- token
	lea	bx, PSF_local.PSF_nameTransTbl
	call	TransTblSearch
	jc	done				; done if no match found

	mov	es:[di].PTND_name, dx

	;
	; need to pass:
	;	ax, cx - (r,c)
	;	ds:si - Spreadsheet instance
	;
;;;	SpreadsheetCellDirty

done:
	.leave
	ret
PasteFormulaTranslateNamesCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PasteSetAttrsFinish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	PasteSetAttrsFinish

CALLED BY:	INTERNAL ()

PASS:		ss:bp - ptr to CallRangeEnum() local variables
			CL_styleToken - set for cell
		ds:si - ptr to Spreadsheet instance data
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data

RETURN:		*es:di - updated if cell created
		dl - RangeEnumFlags with REF_CELL_ALLOCATED bit set if we've
		allocated a cell
		carry - clear (ie. don't abort)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteSetAttrsFinish	proc	near	uses	bx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	jc	hasData				;branch if cell exists

	push	es:LMBH_handle
	clr	bx				;bx <- use default attrs
	call	AllocEmptyCell
	pop	bx
	call	MemDerefES

	SpreadsheetCellLock			;*es:di <- ptr to the cell
	ornf	dl, mask REF_CELL_ALLOCATED	;we've allocated a cell

hasData:
	SpreadsheetCellDirty			;mark cell as dirty

	clc

	.leave
	ret
PasteSetAttrsFinish	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PasteRetrieveEntry

DESCRIPTION:	

CALLED BY:	INTERNAL (PasteHandleFormatConflicts, PastePasteScrapInstance) 

PASS:		SSMDAS_dataArraySpecifier

RETURN:		carry clear if entry found
		    PSF_local.PSF_cellEntry - cell entry
		    cx - size of data portion of entry
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

PasteRetrieveEntry	proc	near	uses	dx,ds,si,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayGetNextEntry	; ds:si <- SSMetaEntry
						; cx <- data element size
	pop	bp
	jc	done

	;
	; If this is a text entry, it is possible that it is longer
	; than GeoCalc supports.  Check that the size is no longer than
	; CELL_TEXT_BUFFER_SIZE + size of the SSMetaEntry structure,
	; If it is too long, truncate the text to C_T_B_S + SSME bytes.
	;
	cmp	ds:[si+(size SSMetaEntry)+(offset CC_type)], CT_TEXT	
	jne	lengthOkay
	cmp	cx, (CELL_TEXT_BUFFER_SIZE + size SSMetaEntry)
	jbe	lengthOkay
	mov	cx, (CELL_TEXT_BUFFER_SIZE + size SSMetaEntry)
lengthOkay:
	;
	; In no case can the length of the entry retrieved
	; be greater than the length of the buffer
	;
SBCS< EC<	cmp	cx, (2 * MAX_NAME_DEF_LENGTH)		>  >
DBCS< EC<	cmp	cx, (size SNP_definition)		>  >
EC<	ERROR_A SSHEET_PASTE_ENTRY_TOO_LARGE			>

	;
	; Copy the cell data into the scratch space
	;
	push	cx, si
	segmov	es, ss, di
	lea	di, PSF_local.PSF_cellEntry	
	rep	movsb
	pop	cx, si

	; 
	; If it is text, es:di points to the char after the last char
	; of the text.  If the text was truncated, this should be the
	; last char of the cell text buffer.  Add a null-terminator.  
	;
	cmp	ds:[si+(size SSMetaEntry)+(offset CC_type)], CT_TEXT	
	jne	notText
	;

SBCS<	clr	al						>
DBCS<	clr	ax						>
	LocalPutChar	esdi, ax		; store the null
	LocalNextChar	escx			; add null to data size
	;
	; Double check that the di does not point beyond the end
	; of the maximum number of text bytes.
	;
EC<	lea	ax, PSF_local.PSF_cellBuf			>	
SBCS <EC <	add	ax, (CELL_TEXT_BUFFER_SIZE + (size char))  >
DBCS <EC <	add	ax, (CELL_TEXT_BUFFER_SIZE + (size wchar)) >	>
EC<	cmp	di, ax						>
EC<	ERROR_A SSHEET_PASTE_ENTRY_TOO_LARGE			>

notText:

	sub	cx, size SSMetaEntry			; cx <- size of data
	clc

done:
	.leave
	ret
PasteRetrieveEntry	endp


PasteUnlockSSMetaDataArrayIfEntriesPresent	proc	near
	uses	ax,dx
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near
	pushf

	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayGetNumEntries	; ax <- num entries
	pop	bp

	tst	ax
	je	done

	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayUnlock
	pop	bp
done:
	popf
	.leave
	ret
PasteUnlockSSMetaDataArrayIfEntriesPresent	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PasteRetrieveStyleEntry

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ax - style token of entry to retrieve

RETURN:		carry clear if entry found
		    PSF_local.PSF_styleEntry - style entry
		    cx - size of entry, including SSMetaEntry
		carry set if entry not found

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

PasteRetrieveStyleEntry	proc	near	uses	dx,ds,si,es,di
	locals		local	CellLocals
	PSF_local	local	PasteStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_STYLE

	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayGetEntryByToken	; ds:si <- entry, cx <- size
	pop	bp
	jc	done

	push	cx
	segmov	es, ss, di
	lea	di, PSF_local.PSF_styleEntry
	rep	movsb			; copies SSMetaEntry + CellAttrs
	pop	cx

	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayUnlock
	pop	bp
	clc

done:
	.leave
	ret
PasteRetrieveStyleEntry	endp

CutPasteCode	ends
