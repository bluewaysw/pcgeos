
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetCutCopy.asm

AUTHOR:		Cheng, 5/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial revision

DESCRIPTION:
	The code for cutting and copying.

	$Id: spreadsheetCutCopy.asm,v 1.1 97/04/07 11:13:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CutPasteStrings	segment lmem	LMEM_TYPE_GENERAL

LocalDefString TransferSizeWarning <"Due to memory constraints the \
the number of cells cut or copied was reduced. If you are trying to \
transfer the entire sheet, use the Save As command.", 0>

ifdef GPC_ONLY
LocalDefString QuickPasteConfirm <"Are you sure you want to move or copy these cells?", 0>
endif
CutPasteStrings	ends

CHECK_CUT_ERROR	=	FALSE



CutPasteCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDoCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a cut on the selected range of cells.	

CALLED BY:	MSG_META_CLIPBOARD_CUT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

RETURN:		none

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetDoCut	method	dynamic	SpreadsheetClass, MSG_META_CLIPBOARD_CUT
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef	locals
	ForceRef	SSM_local
	.enter
if _PROTECT_CELL
	;
	; In Jedi version, we have to make sure the range to be cut doesn't 
	; contains any protected cell. We need to abort the operation if it
	; does.
	;
	push	si, ax
	mov	si, di				;ds:si = spreadsheet instance
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bx, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	call	CheckProtectedCell		;jmp if protected cell found
	pop	si, ax
	jc	protectionError
endif
	clr	CCSF_local.CCSF_copyFlag
	clr	CCSF_local.CCSF_transferItemFlag
	call	CutCopyDoCopy
quit::
	.leave
	ret

if _PROTECT_CELL
protectionError:
	;
	; Print out the cell protection error message.
	;
	mov	si, offset CellProtectionError
	call	PasteNameNotifyDB
	jmp	quit
endif
SpreadsheetDoCut	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDoCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a copy on the selected range of cells.

CALLED BY:	MSG_META_CLIPBOARD_COPY

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

RETURN:		none

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Scrap name reference (a comment now, Dec 1993) since SSMeta sets it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetDoCopy	method	dynamic SpreadsheetClass,
				MSG_META_CLIPBOARD_COPY
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef	locals
	ForceRef	SSM_local
	.enter

	mov	CCSF_local.CCSF_copyFlag, -1
	clr	CCSF_local.CCSF_transferItemFlag
	call	CutCopyDoCopy

	.leave
	ret
SpreadsheetDoCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetInitForExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare a clipboard item for the export translation library.

CALLED BY:	MSG_SSHEET_INIT_FOR_EXPORT from Impex

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
		cx - transfer VM file

RETURN:		dx - VM chain of newly created transfer format
		     (transferHdrVMHan)

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetInitForExport	method	dynamic SpreadsheetClass,
				MSG_SSHEET_EXPORT_FROM_DATA_FILE
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	ForceRef	locals
	ForceRef	SSM_local
	.enter

	mov	CCSF_local.CCSF_vmFileHan, cx

	;
	; save the selected range of cells
	;
	sub	sp, size SpreadsheetRangeParams
	mov	dx, sp

	push	bp,si
	mov	bp, dx
	mov	ax, MSG_SPREADSHEET_GET_SELECTION
	call	ObjCallInstanceNoLock		; destroys cx
	mov	dx, bp				; ss:dx<-SpreadsheetRangeParams
	pop	bp,si
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset

	push	dx

	;
	; set the selected range of cells to all data cells
	;
	push	bp,si
	mov	cx, SET_ENTIRE_SHEET
	call	SpreadsheetGetExtent		; destroys bx,di,si
	mov	bx, bp
	pop	bp,si
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset

	;
	; ax,cx <- (r,c) of first cell in extent
	; dx,bx <- (r,c) of last cell in extent
	; ax <- -1 if there is no data in the spreadsheet
	;
	cmp	ax, -1
	stc					; flag restoration necessary
	je	noData

	;
	; select the entire extent
	;
	push	bp,si
	sub	sp, size SpreadsheetRangeParams
	mov	bp, sp

	clr	ax, cx

	mov	ss:[bp].SRP_selection.CR_start.CR_row, ax
	mov	ss:[bp].SRP_selection.CR_start.CR_column, cx
	mov	ss:[bp].SRP_selection.CR_end.CR_row, dx
	mov	ss:[bp].SRP_selection.CR_end.CR_column, bx
	mov	ss:[bp].SRP_active.CR_row, ax
	mov	ss:[bp].SRP_active.CR_column, cx
	mov	ax, MSG_SPREADSHEET_SET_SELECTION
	call	ObjCallInstanceNoLock
	add	sp, size SpreadsheetRangeParams
	pop	bp,si
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset

	mov	CCSF_local.CCSF_copyFlag, -1		; we are copying
	clr	CCSF_local.CCSF_transferItemFlag
	call	SpreadsheetExportCreateTransferItem

	mov	bx, SSM_local.SSMDAS_vmFileHan
	call	VMUpdate

	clc					; flag restoration unnecessary

noData:
	pop	dx				; ss:dx<-SpreadsheetRangeParams
	jc	noDataExit

	;
	; restore the selected range of cells
	;
	push	bp
	mov	bp, dx
	mov	ax, MSG_SPREADSHEET_SET_SELECTION
	call	ObjCallInstanceNoLock
	pop	bp

	mov	dx, CCSF_local.CCSF_transferHdrVMHan

exit:
	add	sp, size SpreadsheetRangeParams
	.leave
	ret

noDataExit:
	clr	dx, CCSF_local.CCSF_transferHdrVMHan
	jmp	exit

SpreadsheetInitForExport	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpreadsheetExportCreateTransferItem

DESCRIPTION:	

CALLED BY:	INTERNAL (SpreadsheetInitForExport)

PASS:		CellLocals, CutCopyStackFrame, SSMetaStruc stack frames

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SpreadsheetExportCreateTransferItem	proc	near	uses	di,si
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication		; changes cx,dx

	xchg	si, di				;ds:si <- instance data
EC <	call	ECCheckInstancePtr		;>
	push	si

	call	SpreadsheetExportInit		; initialize the stack frame
						; and transfer header

	call	CutCopySaveNames

	clr	ss:CCSF_local.CCSF_textObject.handle	;no text transfer

	clr	di				;di.low <- data cells only
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CutCopyCopyCell
	call	CallRangeEnumSelected		; destroys ax,bx,cx,dx,di

	call	CutCopyUpdateTransferHeader

	pop	si				; ds:si = instance data
EC <	call	ECCheckInstancePtr		;>

	;
	; Send a notification, in case the contents of the selection
	; have changed (a cut),  or we're creating a spreadsheet scrap
	; for the first time (a cut or a copy).
	; CutCopyRedrawRange() will update things appropriate for a cut.
	;

;	mov	ax, mask SNF_EDIT_ENABLE
;	call	SS_SendNotification

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	.leave
	ret
SpreadsheetExportCreateTransferItem	endp


SpreadsheetExportInit	proc	near
	class	SpreadsheetClass
	uses	bx,es,di
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC <	call	ECCheckInstancePtr		;>
	mov	locals.CL_styleToken, -1	; init with illegal token

	mov	ax, ds:LMBH_handle
	mov	cx, di
	mov	bx, CCSF_local.CCSF_vmFileHan
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaInitForStorage		; init SSMetaStruc
	pop	bp

	mov	ax, SSM_local.SSMDAS_hdrBlkVMHan
	mov	CCSF_local.CCSF_transferHdrVMHan, ax

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:LMBH_handle
	mov	CCSF_local.CCSF_objBlkHan, ax
	mov	CCSF_local.CCSF_ssheetChunkHan, si

	;
	; init the range size
	;
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	sub	dx, ds:[si].SSI_selected.CR_start.CR_column
	inc	dx
	mov	CCSF_local.CCSF_numCols, dx

	mov	cx, ds:[si].SSI_selected.CR_end.CR_row
	sub	cx, ds:[si].SSI_selected.CR_start.CR_row
	inc	cx
	mov	CCSF_local.CCSF_numRows, cx

	mov	ax, cx			; ax <- num rows
	mov	cx, dx			; cx <- num cols
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaSetScrapSize
	pop	bp

	;
	; init start row and col
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	CCSF_local.CCSF_startCol, ax
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	CCSF_local.CCSF_startRow, ax

	.leave
	ret
SpreadsheetExportInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyDoCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Perform the cut or copy operation.

CALLED BY:	INTERNAL (SpreadsheetDoCut, SpreadsheetDoCopy,
		SpreadsheetInitForExport)

PASS:		CCSF_copyFlag in the CutCopyStackFrame
		CellLocals stack frame
		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

RETURN:		nothing

DESTROYED:	bx, dx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyDoCopy	proc	near	uses	si
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication		; changes cx,dx

	xchg	si, di				;ds:si <- instance data
EC <	call	ECCheckInstancePtr		;>
	push	si

	call	CutCopyInit			; initialize the stack frame
						; and transfer header

	call	GetSheetTransferRangeLimit
	;
	; See if there is a limit to the number of cells we want to
	; copy.  If there is, then count the number of allocated
	; cells, and if it is greater then the limit, reduce the
	; number of rows copied so that the number of copied cells is
	; below the limit
	;
	jc	ok	
	clr	di
	mov	ss:[locals].CL_data1, ax	; CL_data1 <- max # of
						; cells to copy
	clr	ss:[locals].CL_data2		; CL_data2 <- count of cells
	mov	ss:[locals].CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:[locals].CL_params.REP_callback.offset, offset CutCopyCheckLimit
	call	CallRangeEnumSelected
	;
	; CL_data3 contains the last row visited
	; carry flag if set means that we are trying to copy more than
	; the limit
	;
	jnc	ok
	;
	; If we went beyond the limit in the first row, go ahead and
	; copy it.
	;
	mov	ax, ss:[CCSF_local].CCSF_startRow
	cmp	ss:[locals].CL_data3, ax
	jne	noInc
	;
	;  We should copy at least one row.
	;
	inc 	ss:[locals].CL_data3		
noInc:
	;
	; reduce the number of rows to copy so that including the
	; last row in the new range, the number of cells to be copied
	; is below the limit.
	;
	mov	ax, ss:[locals].CL_data3
	sub	ax, ss:[CCSF_local].CCSF_startRow
	mov	ss:[CCSF_local].CCSF_numRows, ax

	mov	ax, offset TransferSizeWarning
	call	WarnUserDB
ok:	

	call	CutCopySaveNames

	call	TextCopyInit

	clr	di				;di.low <- data cells only
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CutCopyCopyCell
	;
	; Previously at this point all of the selected cells would be
	; enumerated. Now we just enumerate through the cells
	; specified bu the range in CCSF_local.  This is done so we
	; can adjust the range if the number of cells to be copied
	; exceeds the set limit
	;
	push	bx, cx, dx
	mov	ax, ss:[CCSF_local].CCSF_startRow
	mov	cx, ss:[CCSF_local].CCSF_startCol
	mov	bx, ss:[CCSF_local].CCSF_numRows
	dec	bx
	add	bx, ax
	mov	dx, ss:[CCSF_local].CCSF_numCols
	dec	dx
	add	dx, cx
	call	CallRangeEnum			; destroys di
	pop	bx, cx, dx

	call	CutCopyUpdateTransferHeader

if not CHECK_CUT_ERROR
	; redraw if CUT
	;
	cmp	CCSF_local.CCSF_copyFlag, 0
	jne	done				; branch if COPY
	call	CutCopyRedrawRange		; destroys ax,bx,cx,dx
done:
endif
	;
	; Initialize the ClipboardItemHeader for spreadsheet transfer
	;
	push	bp
	mov	dx, ss
	lea	bp, SSM_local
	call	SSMetaDoneWithCutCopyNoRegister
	pop	bp

	pop	si				; ds:si = instance data
EC <	call	ECCheckInstancePtr		;>
	;
	; Add stuff for text transfer
	;
	call	TextCopyFinish
	;
	; Register our transfer item with the appropriate authorities.
	; When transfer items are outlawed, only outlaws will have
	; transfer items.
	;
	push	ax, bx, bp
	mov	bx, ss:SSM_local.SSMDAS_vmFileHan
	mov	ax, ss:SSM_local.SSMDAS_tferItemHdrVMHan
	mov	bp, ss:SSM_local.SSMDAS_transferItemFlags
	call	ClipboardRegisterItem
	pop	ax, bx, bp

if CHECK_CUT_ERROR
	jnc	cutItOut
	mov	ax, SST_ERROR
	call	UserStandardSound		; make error sound
	push	si
	mov	si, offset CutCopyErrorString
	call	PasteNameNotifyDB		; generates no error beep
	pop	si
	jmp	done				; if error, not cut

cutItOut:
	cmp	CCSF_local.CCSF_copyFlag, 0
	jne	done				; branch if COPY
	clr	di				;di.low <- data cells only
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, offset CutCopyCutCell
	mov	ax, ss:[CCSF_local].CCSF_startRow
	mov	cx, ss:[CCSF_local].CCSF_startCol
	mov	bx, ss:[CCSF_local].CCSF_numRows
	dec	bx
	add	bx, ax
	mov	dx, ss:[CCSF_local].CCSF_numCols
	dec	dx
	add	dx, cx
	call	CallRangeEnum			; destroys di
	call	CutCopyRedrawRange		; destroys ax,bx,cx,dx
done:
endif

	;
	; Send a notification, in case the contents of the selection
	; have changed (a cut),  or we're creating a spreadsheet scrap
	; for the first time (a cut or a copy).
	; CutCopyRedrawRange() will update things appropriate for a cut.
	;
	mov	ax, mask SNF_EDIT_ENABLE
	call	SS_SendNotification

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	.leave
	ret
CutCopyDoCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WarnUserDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog box to warn the user that the range of
		the text transfer has changed.

CALLED BY:	EXTERNAL
PASS:		ax - offset of string within CutPasteStrings resource
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WarnUserDB	proc	far
	uses bp, ds, si, bx
	.enter

	mov	si, ax
	sub	sp, (size StandardDialogParams)
	mov	bp, sp			;ss:bp <- ptr to params
	mov	ss:[bp].SDP_customFlags, CDT_WARNING shl (offset CDBF_DIALOG_TYPE) or \
				 GIT_NOTIFICATION shl (offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].SDP_stringArg1.segment, 0
	mov	ss:[bp].SDP_stringArg1.offset, 0
	mov	ss:[bp].SDP_helpContext.segment, 0
	mov	ss:[bp].SDP_helpContext.offset, 0
	mov	bx, handle CutPasteStrings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
EC <	call	ECCheckLMemChunk				>

	movdw	ss:[bp].SDP_customString, dssi
	call	UserStandardDialog
	call	MemUnlock

	.leave
	ret
WarnUserDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CutCopyCheckLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the number of cells we are copying, if it is
		greater than the limit specified in CL_data1, then
		quit. 

CALLED BY:	INTERNAL, CutCopyDoCopy
PASS:		ax, cx 	= (row, col) of cell
RETURN:		carry set if we passed the limit
		CL_data3= row of last cell enumerated

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CutCopyCheckLimit	proc	far
	class	SpreadsheetClass
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	uses	ax
	.enter	inherit far

	mov	ss:[locals].CL_data3, ax	; CL_data3 = row
	inc	ss:[locals].CL_data2		; increment count of
						; cells
	mov	ax, ss:[locals].CL_data1	; ax = limit
	;
	; if CL_data2 > CL_data1 then we have reached our limit.  The
	; cmp will set the carry flag, which will stop the enumeration
	;
	cmp	ax, ss:[locals].CL_data2
					
	.leave
	ret

CutCopyCheckLimit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSheetTransferRangeLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum number of cells to copy as specified
		in the ini file. 

CALLED BY:	VisTextCreateTransferFormat
PASS:		nothing
RETURN:		if limit if found 
			carry clear
			ax	= range limit
		else
			carry set
DESTROYED:	if carry set ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
textCategory	char	"sheet",0
limitKey	char	"transferLimit",0

GetSheetTransferRangeLimit	proc	far
	uses	ds,si,cx,dx,bx
	.enter

	mov	cx, cs
	mov	ds, cx			;DS:SI <- category string
	mov	si, offset textCategory
	mov	dx, offset limitKey	;CX:DX <- key string
	call	InitFileReadInteger

	.leave
	ret
GetSheetTransferRangeLimit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initializes the CutCopyStackFrame and SpreadsheetTransferHeader.

CALLED BY:	INTERNAL (SpreadsheetDoCopy)

PASS:		CutCopyStackFrame
		ds:si - instance data (SpreadsheetClass)
		*ds:di - instance data (SpreadsheetClass)

RETURN:		CutCopyStackFrame initialized
		SpreadsheetTransferHeader allocated and initialized

DESTROYED:	ax,bx,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Some routine needs to be called later to copy info over to the
	SpreadsheetTransferHeader:
	    STH_numRows
	    STH_numCols
	    STH_cells
	    STH_styles
	    STH_formats
	    STH_names

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyInit	proc	near
	class	SpreadsheetClass
	uses	es,di
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC <	call	ECCheckInstancePtr		;>
	mov	locals.CL_styleToken, -1	; init with illegal token

	mov	ax, ds:LMBH_handle
	mov	cx, si
	mov	bx, CCSF_local.CCSF_transferItemFlag
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaInitForCutCopy		; init SSMetaStruc
	pop	bp

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:LMBH_handle
	mov	CCSF_local.CCSF_objBlkHan, ax
	mov	CCSF_local.CCSF_ssheetChunkHan, si

	;
	; init the range size
	;
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	sub	dx, ds:[si].SSI_selected.CR_start.CR_column
	inc	dx
	mov	CCSF_local.CCSF_numCols, dx

	mov	cx, ds:[si].SSI_selected.CR_end.CR_row
	sub	cx, ds:[si].SSI_selected.CR_start.CR_row
	inc	cx
	mov	CCSF_local.CCSF_numRows, cx

	mov	ax, cx			; ax <- num rows
	mov	cx, dx			; cx <- num cols
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaSetScrapSize
	pop	bp

	;
	; init start row and col
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	CCSF_local.CCSF_startCol, ax
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	CCSF_local.CCSF_startRow, ax

	.leave
	ret
CutCopyInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopySaveNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Saves the relevant names into the data chain for names

CALLED BY:	INTERNAL (CutCopyDoCopy)

PASS:		CutCopyStackFrame

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	CreateNamePrecedentsListForSelection returns a block in the form:
	    NameListHeader
	    NameListEntry #1
	    NameListEntry #2
	    ...

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopySaveNames	proc	near	uses	ax,bx,cx,dx,ds,si,es,di
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	call	CreateNamePrecedentsListForSelectionFar	; bx <- blk han
	tst	bx				; anything?
	je	done

	push	bx				; save mem handle
	call	MemLock				; ax <- seg addr
	mov	ds, ax
	mov	si, size NameListHeader		; ds:si <- first NameListEntry

processLoop:
	mov	cx, ds:[si].NLE_textLength	; cx <- text length
	mov	dx, ds:[si].NLE_defLength	; dx <- definition length

	;
	; save the entry
	;
	push	cx
	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_NAME
DBCS <	shl	cx, 1				; # chars -> # bytes	>
	add	cx, size NameListEntry		; compute size of entry
	add	cx, dx				; cx <- size of entry
	mov	ax, ds:[si].NLE_token		; ax <- token
	mov	SSM_local.SSMDAS_token, ax
	push	dx,bp
	mov	dx, ss
	lea	bp, SSM_local
	call	SSMetaDataArrayLocateOrAddEntry
	pop	dx,bp
	pop	cx

	;
	; on to next entry
	;
	add	si, size NameListEntry
	add	si, cx				; add text length
DBCS <	add	si, cx				; char offset -> byte offset>
	add	si, dx				; add definition length

	cmp	si, ds:NLH_endOfData		; done?
	jb	processLoop			; loop if not

	pop	bx				; retrieve mem handle
	call	MemFree

done:
	.leave
	ret
CutCopySaveNames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CutCopyCutCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clear cell data

CALLED BY:	CutCopyDoCopy via CellRangeEnum
PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any
RETURN:		carry - set to abort enum
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if CHECK_CUT_ERROR
CutCopyCutCell	proc	far
	class	SpreadsheetClass
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit far

EC <	ERROR_NC	BAD_CALLBACK_FOR_EMPTY_CELL >

EC <	call	ECCheckInstancePtr		;>
	push	ds:[si].SSI_active.CR_row
	push	ds:[si].SSI_active.CR_column

	mov	ds:[si].SSI_active.CR_row, ax
	mov	ds:[si].SSI_active.CR_column, cx
	mov	SSM_local.SSMDAS_row, ax
	mov	SSM_local.SSMDAS_col, cx

	call	CutCopyClearCell		; clear the cell

	;
	; dl	= RangeEnumFlags returned from CutCopyClearCell()
	;
	; If the REF_CELL_FREED bit is not set, then we want to recalc
	; any dependents of this cell.
	;
	test	dl, mask REF_CELL_FREED
	jnz	done				; Branch if it was free'd

	;
	; Cell still exists, recalc the cell and dependents
	;
	; ax	= Row of cell
	; cx	= Column of cell
	; ds:si	= Spreadsheet instance
	;
	call	RecalcDependentsNoRedraw	; Recalc cell dependents

done:

	;
	; cell neither allocated nor freed, dx unchanged.
	;
	clc

EC <	call	ECCheckInstancePtr		;>
	pop	ds:[si].SSI_active.CR_column
	pop	ds:[si].SSI_active.CR_row
	.leave
	ret
CutCopyCutCell	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyCopyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the contents of the cells to the clipboard.

CALLED BY:	SpreadsheetSetNumFormat() via RangeEnum()

PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any

RETURN:		carry - set to abort enum
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	store cell
	store style
	store format
	store name

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyCopyCell	proc	far
	class	SpreadsheetClass
	locals		local	CellLocals
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit far

EC <	ERROR_NC	BAD_CALLBACK_FOR_EMPTY_CELL >

EC <	call	ECCheckInstancePtr		;>
	push	ds:[si].SSI_active.CR_row
	push	ds:[si].SSI_active.CR_column

	mov	ds:[si].SSI_active.CR_row, ax
	mov	ds:[si].SSI_active.CR_column, cx
	mov	SSM_local.SSMDAS_row, ax
	mov	SSM_local.SSMDAS_col, cx

	push	ax,bx,cx,dx
	;
	; Save the cell contents.
	; We need to have the call to CutCopySaveStyle first to initialize
	; the style info.
	;
	call	CutCopySaveCell			; destroys ax,bx,cx,dx
	;
	; save style
	;
	call	CutCopySaveStyle		; destroys ax,bx,cx,dx
	;
	; save format
	;
	call	CutCopySaveFormat
	pop	ax,bx,cx,dx
	;
	; Copy the cell data to a text scrap, too
	;
	call	TextCopyCell
if not CHECK_CUT_ERROR
	;
	; if operation is a CUT, clear the cell
	;
	cmp	CCSF_local.CCSF_copyFlag, 0
	jne	done

	call	CutCopyClearCell		; clear the cell

	;
	; dl	= RangeEnumFlags returned from CutCopyClearCell()
	;
	; If the REF_CELL_FREED bit is not set, then we want to recalc
	; any dependents of this cell.
	;
	test	dl, mask REF_CELL_FREED
	jnz	done				; Branch if it was free'd

	;
	; Cell still exists, recalc the cell and dependents
	;
	; ax	= Row of cell
	; cx	= Column of cell
	; ds:si	= Spreadsheet instance
	;
	call	RecalcDependentsNoRedraw	; Recalc cell dependents

done:
endif

	;
	; cell neither allocated nor freed, dx unchanged.
	;
	clc

EC <	call	ECCheckInstancePtr		;>
	pop	ds:[si].SSI_active.CR_column
	pop	ds:[si].SSI_active.CR_row
	.leave
	ret
CutCopyCopyCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopySaveCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save the cell contents in the cell data chain.

CALLED BY:	INTERNAL (CutCopyCopyCell)

PASS:		carry set if cell has data
		*es:di - ptr to cell data, if any
		(ax,cx) - cell coordinates (r,c)

RETURN:		

DESTROYED:	ax,bx,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	SpreadsheetTransferCellItem	struct
		STCI_cellAttr	CellCommon
		... extra info
	SpreadsheetTransferCellItem	ends

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

emptyCellStruct	CellCommon <
	0,			;CC_dependencies
	CT_EMPTY,		;CC_type
	0,			;CC_recalcFlags
	DEFAULT_STYLE_TOKEN,	;CC_attrs
	0			;CC_notes
>

CutCopySaveCell	proc	near	
	uses	ds,es,di,si
	
	locals		local	CellLocals	; not used
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	SSM_local.SSMDAS_token, 0
	pushf
	sub	ax, CCSF_local.CCSF_startRow
	mov	SSM_local.SSMDAS_row, ax
	sub	cx, CCSF_local.CCSF_startCol
	mov	SSM_local.SSMDAS_col, cx
	popf
	jc	cellNotEmpty

;;;
;;; Changed, 3/25/93 -jw
;;; Changed to "::" so that it won't show up as an unreferenced symbol.
;;; Truly though, this label will never be reached as far as I can tell.
;;;
cellEmpty::
	;
	; cell is empty
	;

	;
	; RangeEnum is guaranteed to send stuff in row, then column order
	;
;	mov	al, SSMAEF_ADD_IN_ROW_ORDER
	mov	al, SSMETA_ADD_TO_END
	segmov	ds, cs, si
	mov	si, offset emptyCellStruct
	mov	cx, size CellEmpty
FXIP<	call	SysCopyToStackDSSI		; ds:si = struct on stack >
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayAddEntry
	pop	bp
FXIP<	call	SysRemoveFromStack		; release stack space	>

	;
	; output tab to text scrap
	;
	jmp	short done

cellNotEmpty:
	mov	di, es:[di]			; es:di <- ptr to the cell
	mov	al, es:[di].CC_type		; al <- CellType
	mov	CCSF_local.CCSF_curCellType, al
	call	CutCopyGetCellSize		; ax <- cell size
	mov	CCSF_local.CCSF_curCellSize, ax
;;;
;;; Changed, 3/25/93 -jw
;;; This should never happen. If we get here then the cell must exist
;;; and we do want to copy it, even if the type is CT_EMPTY.
;;;
;;;	tst	ax
;;;	je	cellEmpty

	;
	; ax = size of structure
	; realloc cell data block
	; copy structure over
	;

	mov	cx, ax			; cx <- size
	;
	; RangeEnum is guaranteed to send stuff in row, then column order
	;
;	mov	al, SSMAEF_ADD_IN_ROW_ORDER
	mov	al, SSMETA_ADD_TO_END
	segmov	ds, es, si		; ds:si <- cell addr
	mov	si, di
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayAddEntry
	pop	bp

	;
	; output formatted string to text scrap
	;
done:
	.leave
	ret
CutCopySaveCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopySaveStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Process the current style by creating a new data entry
		for it if it doesn't already exist.

CALLED BY:	INTERNAL (CutCopyCopyCell)

PASS:		CutCopyStackFrame
		ds:si - SpreadsheetInstance

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopySaveStyle	proc	near	uses	ds,si,es,di
	locals		local	CellLocals	; not used
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC <	call	ECCheckInstancePtr		;>
	;
	; make ds:si point at CellAttrs
	; and ax contain the style token id
	;
	call	CutCopyUpdateStackFrameStyleInfo ; ds:si <- CellAttrs
						; ax <- style token ID

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_STYLE
	mov	SSM_local.SSMDAS_token, ax
	mov	cx, size CellAttrs
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayLocateOrAddEntry
	pop	bp

	.leave
	ret
CutCopySaveStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopySaveFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Process the current format by creating a new data entry
		for it if it is user-defined and if it doesn't already exist.

CALLED BY:	INTERNAL (CutCopyCopyCell)

PASS:		CellLocals with CL_cellAttrs up to date
		    (ie the call to CutCopySaveFormat should follow a call
		    to CutCopySaveFormat)
		CutCopyStackFrame
		ds:si - SpreadsheetInstance

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopySaveFormat	proc	near
	class	SpreadsheetClass
	uses	ds,si,es,di
	locals		local	CellLocals	; not used
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC <	call	ECCheckInstancePtr		;>
	;
	; if format is pre-defined then don't need to save it
	;
	mov	cx, locals.CL_cellAttrs.CA_format
	test	cx, FORMAT_ID_PREDEF
	jne	done

	;
	; make ds:si point at FormatParams
	; and ax contain the format token id
	;
	push	cx				; save token
	mov	ax, size FormatInfoStruc
	mov	cx, (mask HAF_LOCK or mask HAF_ZERO_INIT) shl 8 or \
							mask HF_SWAPABLE
	call	MemAlloc
	pop	cx				; retrieve token
	mov	es, ax
	push	bx

	mov	es:FIS_signature, FORMAT_INFO_STRUC_ID
	mov	es:FIS_childBlk, -1
	mov	es:FIS_curToken, cx
	mov	ax, ds:[si].SSI_cellParams.CFP_file
	mov	es:FIS_userDefFmtArrayFileHan, ax
	mov	ax, ds:[si].SSI_formatArray
	mov	es:FIS_userDefFmtArrayBlkHan, ax

	mov	dx, es
	push	bp
	mov	bp, offset FIS_curParams
	call	FloatFormatGetFormatParamsWithToken
	pop	bp

	;
	; FormatParams are now in the FormatInfoStruc
	;
	segmov	ds, es
	mov	si, offset FIS_curParams

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_FORMAT
	mov	ax, cx
	mov	SSM_local.SSMDAS_token, ax
	mov	cx, size FormatParams
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayLocateOrAddEntry
	pop	bp

	pop	bx
	call	MemFree

done:
	.leave
	ret
CutCopySaveFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyClearCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Clear one cell

CALLED BY:	INTERNAL ()

PASS:		ds:si - SpreadsheetInstance
		*es:di - ptr to cell data, if any

RETURN:		dl - RangeEnumFlags
		carry set to abort

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyClearCell	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx
	locals		local	CellLocals	; not used
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	mov	dh, mask SCF_CLEAR_ATTRIBUTES or mask SCF_CLEAR_DATA
	stc
	call	ClearCell			; dl <- RangeEnumFlags

	.leave
	ret
CutCopyClearCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyUpdateStackFrameStyleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Checks to see if the style token has changed from the
		previous style to the present one.  If there is a change,
		the new style token will be noted and the CL_cellAttrs field
		in the locals stack frame will be updated.

CALLED BY:	INTERNAL (CutCopySaveStyle)

PASS:		CellLocals stack frame
		ds:si - SpreadsheetInstance

RETURN:		ds:si - CellAttrs
		ax,cx - style token id
		CellLocals stack frame fields that are set:
		    CL_instanceData
		    CL_styleToken
		    CL_cellAttrs

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyUpdateStackFrameStyleInfo	proc	near
	uses	bx
	class	SpreadsheetClass
	locals		local	CellLocals	; not used
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	;-----------------------------------------------------------------------
	; set CL_instanceData

EC <	call	ECCheckInstancePtr		;>
	mov	locals.CL_instanceData.offset, si
	mov	locals.CL_instanceData.segment, ds

	;-----------------------------------------------------------------------
	; see if style token IDs differ

	mov	CCSF_local.CCSF_styleChanged, 0	; init as FALSE

	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column		; (ax,cx) <- current (r,c)
	call	GetCurCellAttrs			; ax <- style token id
	cmp	ax, locals.CL_styleToken	; same?
	je	done				; done if so

	;
	; get the cell attrs
	;
	push	es, di
	segmov	es, ss, cx			; es:di <- ptr to CellAttrs stuc
	lea	di, locals.CL_cellAttrs
	mov	locals.CL_styleToken, ax	; store new token
	call	StyleGetStyleByTokenFar		; get associated styles
	pop	es, di

	dec	CCSF_local.CCSF_styleChanged	; flag TRUE

done:
	mov	cx, ax				; cx <- style token id
	segmov	ds, ss, si			; ds:si <- CellAttrs
	lea	si, locals.CL_cellAttrs

	.leave
	ret
CutCopyUpdateStackFrameStyleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyUpdateTransferHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	The CutCopyStackFrame contains the data for the
		SpreadsheetTransferHeader.  We will copy over the
		pertinent info.

CALLED BY:	INTERNAL (SpreadsheetDoCopy)

PASS:		CutCopyStackFrame

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

CutCopyUpdateTransferHeader	proc	near	uses	ax,bx,cx,dx,es,di
	locals		local	CellLocals	; not used
	CCSF_local	local	CutCopyStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	ax, CCSF_local.CCSF_numRows
	mov	cx, CCSF_local.CCSF_numCols
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaSetScrapSize
	pop	bp

	.leave
	ret
CutCopyUpdateTransferHeader	endp

CutPasteCode	ends
