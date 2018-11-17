
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:

TERMINOLOGY:
	Export file = target file

	$Id: export.asm,v 1.1 97/04/07 11:41:48 newdeal Exp $

-------------------------------------------------------------------------------@


;*******************************************************************************
;	OUR OWN CONSTANTS (as opposed to Lotus)
;*******************************************************************************



COMMENT @-----------------------------------------------------------------------

FUNCTION:	TransExport

DESCRIPTION:	Translate the current file into the 123 format.

CALLED BY:	EXTERNAL (MSG_SPREADSHEET_EXPORT)

PASS:		ds:si - ExportFrame

RETURN:		ax - TransError

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    ExportFrame	struct
	EF_formatNumber		word	; number of format to be used
	EF_exportOptions	hptr	; block handle of export options
					; specific to translation library
					; (0 for default)
	EF_outputFile		hptr	; handle of output file
	EF_outputFileName	FileLongName
					; handle of output file
	EF_outputPathName	PathName; handle of output file
	EF_outputPathDisk	hptr	; handle of output file
	EF_transferVMFile	word	; VM file handle of transfer format	
	EF_transferVMChain	dword	; VM chain containing transfer format
					; to export
	EF_manufacturerID	ManufacturerID
	EF_clipboardFormat	ClipboardItemFormat
    ExportFrame	ends

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

TransExport	proc	far	
if PZ_PCGEOS
else
	uses	cx,dx
	locals		local	ExportStackFrame
	SSM_local	local	SSMetaStruc
	.enter

	; check to see if there was an error
	mov	ax, TE_EXPORT_INVALID_CLIPBOARD_FORMAT	; just in case
	cmp	ds:[si].EF_clipboardFormat, CIF_SPREADSHEET
	jne	exit
	cmp	ds:[si].EF_manufacturerID, MANUFACTURER_ID_GEOWORKS
	jne	exit


	mov	ax, ds:[si].EF_transferVMChain.low	
	or	ax, ds:[si].EF_transferVMChain.high
	jne	noError				; skip if no error

	mov	ax, TE_EXPORT_FILE_EMPTY	; ax - TransError
	jmp	exit
noError:

	;
	; zero init stack frame
	;
	push	ax,cx,es,di
	clr	al
	mov	cx, size ExportStackFrame
	segmov	es, ss, di
	lea	di, locals
	rep	stosb
	pop	ax,cx,es,di

	;
	; copy over the info from ImportFrame
	;
	mov	ax, ds:[si].EF_formatNumber
	mov	locals.ESF_formatNumber, ax
	mov	ax, ds:[si].EF_exportOptions
	mov	locals.ESF_exportOptions, ax
	mov	ax, ds:[si].EF_outputFile
	mov	locals.ESF_outputFile, ax
;	mov	ax, ds:[si].EF_transferVMChain.low
;	clr	locals.ESF_transferVMChain.low
	mov	ax, ds:[si].EF_transferVMChain.high
	mov	locals.ESF_transferVMChain.high, ax
	mov	bx, ds:[si].EF_transferVMFile
	mov	locals.ESF_transferVMFile, bx

	;-----------------------------------------------------------------------
	; grab the clipboard item and lock the transfer header

	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaInitForRetrieval
	pop	bp
	jc	noOp

	;
	; perform the export operation...
	;
	call	ExportDoExport
	jc	exit

EC<	call	ECExportCheckStackFrame >
	mov	ax, locals.ESF_transferVMChain.high
	mov	ds:[si].EF_transferVMChain.high, ax
	mov	ax, locals.ESF_transferVMChain.low
	mov	ds:[si].EF_transferVMChain.low, ax

noOp:
	jc	exit
	clr	ax
exit:
	.leave
endif
	ret
TransExport	endp


if PZ_PCGEOS
else
ExportDoExport	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near

	;-----------------------------------------------------------------------
	; start translating to the export file

	call	ExportInit
EC<	call	ECExportCheckStackFrame >
	call	ExportWriteHeader
	jc	exit
EC<	call	ECExportCheckStackFrame >
	call	ExportWriteNameData
EC<	call	ECExportCheckStackFrame >
	call	ExportWriteCellData
EC<	call	ECExportCheckStackFrame >
	call	ExportClose

	clc				; for now
exit:
	.leave
	ret
ExportDoExport	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportInit

DESCRIPTION:	Initialize the export file.

CALLED BY:	INTERNAL (SSheetExport)

PASS:		ExportStackFrame
		bx - transfer VM file handle
		ax - VM block handle of SpreadsheetTransferHeader

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportInit	proc	near	uses	ds,si,es,di
	locals		local	ExportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	;
	; init fp stack
	;
	push	ax,bx
	mov	bl, FLOAT_STACK_GROW
	mov	ax, FP_DEFAULT_STACK_SIZE
	call	FloatInit
	pop	ax,bx

	mov	locals.ESF_transferFileHan, bx
	mov	locals.ESF_transferHdrBlkHan, ax
	mov	locals.ESF_overflowMarker, OVERFLOW_SIG

	;
	; copy the DataChainRecords from the SpreadsheetTransferHeader
	;

;	call	ImpexVMLock		; es <- seg addr, cx <- mem han

	mov	ax, SSM_local.SSMDAS_scrapRows
	mov	locals.ESF_numRows,ax
	mov	ax, SSM_local.SSMDAS_scrapCols
	mov	locals.ESF_numCols, ax

;	mov	ax, es:STH_startRow
	clr	ax
	mov	locals.ESF_startRow, ax
	mov	locals.ESF_endRow, ax
	add	ax, locals.ESF_numRows
	dec	ax
	jl	10$
	mov	locals.ESF_endRow, ax
10$:
;	mov	ax, es:STH_startCol
	clr	ax
	mov	locals.ESF_startCol, ax
	mov	locals.ESF_endCol, ax
	add	ax, locals.ESF_numCols
	dec	ax
	jl	20$
	mov	locals.ESF_endCol, ax
20$:
	clr	locals.ESF_operatorStackHan

;	call	ImpexVMUnlock		; unlock transfer header

	.leave
	ret
ExportInit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportWriteHeader

DESCRIPTION:	Write out the file header.

CALLED BY:	INTERNAL (SSheetExport)

PASS:		ExportStackFrame
		es - seg addr of the header block

RETURN:		carry set if error, ax = TransError

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	allocate a block for the header
	copy the template into the block
	modify the necessary fields
	write the block out as the file header

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportWriteHeader	proc	near	uses	bx,cx,dx,ds,si,es,di
	locals	local	ExportStackFrame
	.enter	inherit near

	;-----------------------------------------------------------------------
	; allocate block

	mov	ax, LOTUS_HEADER_SIZE
	mov	cx, (mask HAF_LOCK or mask HAF_NO_ERR) shl 8 or \
		     mask HF_SWAPABLE
	call	MemAlloc
	jc	err

	mov	es, ax
	clr	di				; es:di <- block

	;-----------------------------------------------------------------------
	; copy file header template

	push	bx				; save block handle
	mov	bx, handle ImpexLmemResource
	call	MemLock
	mov	ds, ax
	mov	si, offset LotusFileHeaderStart	; ds:si <- template

	mov	cx, LOTUS_HEADER_SIZE
	rep	movsb

	;-----------------------------------------------------------------------
	; modify fields

	clr	di				; es:di <- header
	mov	ax, locals.ESF_startCol
	mov	es:[di].LFH_range + offset LRH_data + offset LR_startCol, ax
	mov	ax, locals.ESF_startRow
	mov	es:[di].LFH_range + offset LRH_data + offset LR_startRow, ax
	mov	ax, locals.ESF_endCol
	mov	es:[di].LFH_range + offset LRH_data + offset LR_endCol, ax
	mov	ax, locals.ESF_endRow
	mov	es:[di].LFH_range + offset LRH_data + offset LR_endRow, ax

	;-----------------------------------------------------------------------
	; write block

	segmov	ds, es, si
	clr	dx				; ds:dx <- block
	mov	al, dl
	mov	bx, locals.ESF_outputFile
	mov	cx, LOTUS_HEADER_SIZE
	call	FileWrite

	;-----------------------------------------------------------------------
	; clean up

	pop	bx				; retrieve block handle
	call	MemFree				; free block
	mov	bx, handle ImpexLmemResource
	call	MemUnlock			; unlock template resource
	clc
done:
	.leave
	ret
err:
	mov	ax, TE_OUT_OF_MEMORY
	stc
	jmp	short done
ExportWriteHeader	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportWriteNameData

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	for all name entries
	    store name info
	endfor

	problems:
	    Lotus limits names to 16 chars, including the null terminator
	    Lotus ranges are just that - ranges

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportWriteNameData	proc	near	uses	bx,es,di
	locals		local	ExportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_NAME
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayResetEntryPointer
	pop	bp

exportLoop:
	call	ExportRetrieveEntry
	jc 	done

	;
	; if the name entry contains anything other than a single range,
	; the translation won't be 1 to 1
	;
	call	ExportTranslateName
	jc	ohNo

	mov	locals.ESF_token, CODE_NAME
	mov	locals.ESF_length, 24

	call	ExportWriteRecord
	jmp	short exportLoop

ohNo:
	;
	; rats! the name contains stuff that Lotus doesn't support
	;

done:
	call	ExportUnlockSSMetaDataArrayIfEntriesPresent
	.leave
	ret
ExportWriteNameData	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportWriteCellData

DESCRIPTION:	Traverse the cell data chain and export the information.

CALLED BY:	INTERNAL (SSheetExport)

PASS:		ExportStackFrame

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    traverse the cell chain & generate data

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportWriteCellData	proc	near	uses	bx,dx,ds,si
	locals		local	ExportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	;
	; traverse the cell data chain
	;

	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayResetEntryPointer
	pop	bp

exportLoop:
	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_CELL
	call	ExportRetrieveEntry
	jc 	done

	segmov	ds, ss, si
	lea	si, locals.ESF_entryBuf

EC<	cmp	ds:[si].SSME_signature, 6307h >
EC<	ERROR_NE 0 >
	mov	ax, ds:[si].SSME_coordRow
	mov	locals.ESF_curRow, ax
	mov	ax, ds:[si].SSME_coordCol
	mov	locals.ESF_curCol, ax

	add	si, offset SSME_dataPortion
	call	ExportProcessSingleCell

	jmp	short exportLoop

done:
	call	ExportUnlockSSMetaDataArrayIfEntriesPresent
	.leave
	ret
ExportWriteCellData	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportProcessSingleCell

DESCRIPTION:	Export the information in the current cell.

CALLED BY:	INTERNAL ()

PASS:		ExportStackFrame
		ds:si - buffer containing the cell entry (Cell... structure)

RETURN:		carry set to abort
		carry clear otherwise

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportProcessSingleCell	proc	near	uses	bx,cx,ds,si,es,di
	locals	local	ExportStackFrame
	.enter	inherit near

	;-----------------------------------------------------------------------
	; figure out column / row and format

	;-----------------------------------------------------------------------
	; make
	;     ds:si <- Cell... structure
	;     es:di <- place to place export data
	; initialize LotusCellInfo (format, row/col)

	mov	bl, ds:[si].CC_type		; bl <- cell type

	;
	; es:di <- location to place exported data
	;
	segmov	es, ss, di
	lea	di, locals.ESF_data
	add	di, size LotusCellInfo		; es:di <- dest

	;
	; init format and (row,col) info
	;
	call	ExportInitCellInfo

	;-----------------------------------------------------------------------
	; identify and call appropriate cell processing routine

	cmp	bl, CT_TEXT
	jne	checkConstant

	add	si, size CellCommon		; ds:si <- string
	call	ExportProcessString
	jmp	short done

checkConstant:
	cmp	bl, CT_CONSTANT
	jne	checkFormula

	add	si, size CellCommon		; ds:si <- fp number
	call	ExportProcessConstant
	jmp	short done

checkFormula:
	cmp	bl, CT_FORMULA
	jne	checkEmpty

	;
	; Lotus formula records are different in that they have additional
	; fields.  Pass ds:si = CellFormula
	;
	call	ExportProcessFormula
	jmp	short done

checkEmpty:
	cmp	bl, CT_EMPTY
	jne	done

	;
	; ds:si is ignored
	;
	call	ExportProcessEmpty

done:
	.leave
	ret
ExportProcessSingleCell	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportInitCellInfo

DESCRIPTION:	Initialize the format, current column and current row
		fields in the stack frame.  Called by the cell routines
		prior to calling ExportWriteRecord.

CALLED BY:	INTERNAL (cell routines)

PASS:		ExportStackFrame

RETURN:		ExportStackFrame with format, curCol and curRow fields
		initialized

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	transfer format byte
	transfer col and row

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportInitCellInfo	proc	near	uses	ax
	locals	local	ExportStackFrame
	.enter	inherit near

	mov	locals.ESF_data + offset LCI_format, LOTUS_FORMAT_GENERAL

	mov	ax, locals.ESF_curCol
	mov	locals.ESF_data + offset LCI_colNum, ax
	mov	ax, locals.ESF_curRow
	mov	locals.ESF_data + offset LCI_rowNum, ax

	.leave
	ret
ExportInitCellInfo	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportClose

DESCRIPTION:	Write the EOF token, close the export file, free
		the OperatorStack memory block.

CALLED BY:	INTERNAL (SSheetExport)

PASS:		ExportStackFrame

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportClose	proc	near	uses	bx
	locals	local	ExportStackFrame
	.enter	inherit near

	mov	locals.ESF_token, CODE_EOF	; EOF
	clr	locals.ESF_length		; no data
	call	ExportWriteRecord

	clr	al
	mov	bx, locals.ESF_outputFile	; bx <- file handle
	call	FileCommit

	call	FloatExit			; notify float library

	mov	bx, locals.ESF_operatorStackHan
	tst	bx
	jz	done
	call	MemFree

done:
	.leave
	ret
ExportClose	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportCopyData

DESCRIPTION:	Copy the default data into the ExportStackFrame.

CALLED BY:	INTERNAL (NOT IN USE)

PASS:		ExportStackFrame
		ESF_length - number of data bytes
		si - offset from cs to data

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

if 0
ExportCopyData	proc	near	uses	cx,ds,si,es,di
	locals	local	ExportStackFrame
	.enter	inherit near

	segmov	ds, cs, di			; ds:si <- source
	segmov	es, ss, di			; es:di <- dest
	lea	di, locals.ESF_data
	mov	cx, locals.ESF_length		; cx <- num data bytes
	rep	movsb
	.leave
	ret
ExportCopyData	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportWriteRecord

DESCRIPTION:	Write a lotus record out to the export file.

CALLED BY:	INTERNAL (Utility)

PASS:		ExportStackFrame with the following filled:
		    ESF_token
		    ESF_length
		    ESF_data

RETURN:		carry set if error
		    ax - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportWriteRecord	proc	near	uses	bx,cx,dx,ds
	locals	local	ExportStackFrame
	.enter	inherit near

EC<	call	ECExportCheckStackFrame >

	mov	cx, locals.ESF_length
	add	cx, size LotusRecordHeader	; cx <- num bytes to write

	mov	bx, locals.ESF_outputFile	; bx <- file handle
	segmov	ds, ss
	lea	dx, locals.ESF_token		; ds:dx <- record

	clr	al				; al <- flags
	call	FileWrite

	.leave
	ret
ExportWriteRecord	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportRetrieveEntry

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		SSMDAS_dataArraySpecifier

RETURN:		carry clear if entry found
		    ESF_local.ESF_entryBuf - cell entry
		    cx - size of entry
		carry set otherwise

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

ExportRetrieveEntry	proc	near	uses	dx,ds,si,es,di
	locals		local	ExportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayGetNextEntry	; cx <- entry size
	pop	bp
	jc	done

	;
	; If the stack frame buffer is not large enough to hold the
	; entire entry, we are in trouble, because a formula might
	; get truncated, and we would be unable to parse it.  The
	; buffer better be large enough to hold the largest possible
	; cell.  The file lotus123Constant.def sets the size of 
	; ESF_entryBuf to be big enough to hold the largest cell -
	; formula cells are larger than text cells, which ought to 
	; be larger than every other type of cell.
	;
	; GeoFile and GeoCalc should be well-behaved and never create 
	; entries that are too large to be retrieved in our stack frame.
	; GeoDex, however, creates text entries which can be very large.
	; To catch this case, we will truncate the entry so as not to
	; overflow our buffer.
	;
CheckHack <(size locals.ESF_entryBuf) eq (EXPORT_STACK_FRAME_ENTRY_BUF_SIZE)>
	cmp	cx, EXPORT_STACK_FRAME_ENTRY_BUF_SIZE
	jbe	okay
	mov	cx, EXPORT_STACK_FRAME_ENTRY_BUF_SIZE
okay:
	push	cx
	segmov	es, ss, di
	lea	di, locals.ESF_entryBuf
	rep	movsb
	pop	cx
	clc

done:
	.leave
	ret
ExportRetrieveEntry	endp


ExportUnlockSSMetaDataArrayIfEntriesPresent	proc	near
	uses	ax,dx
	locals		local	ExportStackFrame
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
ExportUnlockSSMetaDataArrayIfEntriesPresent	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECExportCheckStackFrame

DESCRIPTION:	Checks integrity of ExportStackFrame.

CALLED BY:	INTERNAL ()

PASS:		ExportStackFrame

RETURN:		nothing, flags remain intact
		dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

if ERROR_CHECK

ECExportCheckStackFrame	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near
	pushf

	cmp	locals.ESF_overflowMarker, OVERFLOW_SIG
	ERROR_NE IMPEX_TRASHED_STACK_FRAME

	popf
	.leave
	ret
ECExportCheckStackFrame	endp

endif

endif
