COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	dBase III
MODULE:		Export		
FILE:		exportFile.asm

AUTHOR:		Ted H. Kim, 9/14/92

ROUTINES:
	Name			Description
	----			-----------
	TransExport		Library routine called by Impex
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/92		Initial revision

DESCRIPTION:
	Contains all of file export routines.

	$Id: exportFile.asm,v 1.1 97/04/07 11:42:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Export	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library routine called by Impex

CALLED BY:	Impex

PASS:		ds:si - ExportFrame

RETURN:		ax - TransError 

DESTROYED:	bx, cx, dx, si, di, bp, es, ds

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransExport	proc	far
	TE_Local	local	ImpexStackFrame
	TE_SSMeta	local	SSMetaStruc

	.enter

	; check to see if transfer VM file is empty
	mov	ax, TE_EXPORT_INVALID_CLIPBOARD_FORMAT	; just in case...
	cmp	ds:[si].EF_clipboardFormat, CIF_SPREADSHEET
	LONG	jne	exit
	cmp	ds:[si].EF_manufacturerID, MANUFACTURER_ID_GEOWORKS
	LONG	jne	exit

	mov	ax, ds:[si].EF_transferVMChain.low	
	or	ax, ds:[si].EF_transferVMChain.high
	jne	notEmpty			; skip if not empty

	mov	ax, TE_EXPORT_FILE_EMPTY	; ax - TransError
	jmp	exit
notEmpty:
	; set up the output file for writing

	mov	bx, ds:[si].EF_outputFile	; bx - handle of output file
	call	OutputCacheAttach		; create output cache block
	mov	ax, TE_OUT_OF_MEMORY		; not enough memory
	LONG	jc	exit			; exit if error
	mov	TE_Local.ISF_cacheBlock, bx	; save handle of cache block 

	; get the handle of map entry block from the stack frame

	mov	bx, ds:[si].EF_exportOptions	; bx - map list block
	mov	TE_Local.ISF_mapBlock, bx	; save it

	; initialize the stack frame for file exporting

	mov	bx, ds:[si].EF_transferVMFile	; bx - VM file handle
	mov	ax, ds:[si].EF_transferVMChain.high	; ax - VM block handle 
	push	bp
	mov	dx, ss
	lea	bp, TE_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaInitForRetrieval	
	pop	bp

	; now grab the number of records and fields from the transfer file

	mov	ax, TE_SSMeta.SSMDAS_scrapRows
	mov	TE_Local.ISF_numRecords.low, ax	; ax - number of records
	mov	TE_Local.ISF_numRecords.high, 0	
	mov	ax, TE_SSMeta.SSMDAS_scrapCols
	mov	TE_Local.ISF_numSourceFields, ax; ax - number of fields

	; allocate a block for storing field length and type

	mov	ax, FIELD_INFO_BLOCK_SIZE  ; ax - size of block to allocate
	mov     cx, ((mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8) or 0 
	call	MemAlloc			; allocate a block
	mov	TE_Local.ISF_fieldInfoBlock, bx	; save the handle

	; convert to dBase III

	call	ExportFileHeader
	jc	fileErr				; skip if error

	; check to see if there is a map block

	tst	TE_Local.ISF_mapBlock		
	jne	mapBlk				; if there is, skip

	call	ExportFileFast			; no map block, do fast export
	jnc	noError				; skip if no error
	jmp	fileErr
mapBlk:
	call	ExportRecordData
	jnc	noError				; skip if no error

	; delete the FieldInfo data block
fileErr:
	push	ax				; ax - TransError
	mov	bx, TE_Local.ISF_fieldInfoBlock
	call	MemFree
	mov	bx, TE_Local.ISF_cacheBlock	; bx - handle of cache block 
	call	OutputCacheFlush		; flush out the buffer
	call	OutputCacheDestroy		; destroy cache block
	pop	ax				; ax = TransError
	jmp	exit	
noError:
	call	ExportEndOfFileChar		; write out EOF character
	mov	bx, TE_Local.ISF_fieldInfoBlock
	call	MemFree

	; clean up the cached block

	mov	bx, TE_Local.ISF_cacheBlock	; bx - handle of cache block 
	call	OutputCacheFlush		; flush out the buffer
	jc	error				; exit if error
	call	OutputCacheDestroy		; destroy cache block
	mov	ax, TE_NO_ERROR			; return with no error
	jmp	exit
error:
	mov	ax, TE_FILE_ERROR		; return with file error
exit:
	.leave
	ret
TransExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a block with file header and write it out 

CALLED BY:	TransExport

PASS:		ImpexStackFrame

RETURN:		ImpexStackFrame
		carry set if error (ax = TransError)

DESTROYED:	ax, bx, cx, dx, es, ds, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportFileHeader	proc	near
	EFH_Local	local	ImpexStackFrame
	EFH_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; check to see if there are too many fields 

	mov     ax, EFH_Local.ISF_numSourceFields
	cmp	ax, MAX_NUM_FIELDS	; the limit is 128
	jle	skip			; if not over the limit, skip
	mov	al, MAX_NUM_FIELDS	; al - 128 fields
skip:
	; calculate the size of file header to allocate

	inc	al			; add one for other info
	mov	cl, FIELD_DESCRIPTOR_SIZE
	mul	cl
	inc	ax			; ax - size of file header block

	; now allocate file header block

	mov     cx, ((mask HAF_LOCK or mask HAF_ZERO_INIT) shl 8) or 0
	call	MemAlloc		; allocate a block
	LONG	jc	noMem		; exit if not enough memory
	mov	EFH_Local.ISF_fileHeader, bx	; save the handle
	mov	es, ax
	clr	di
	mov	es:[di].DBH_version, DBASE3_NO_MEMO	; write out ver. num.
	mov	ax, EFH_Local.ISF_numRecords.low
	mov	es:[di].DBH_numRecords.low, ax		; write out num records

	mov	EFH_Local.ISF_recordSize, 1 ; initialize record size to one
	clr	dx			; dx - field counter
	mov	di, size DBaseHeader	; es:di - ptr to field descriptors
nextField:
	call	ExportFieldDescriptor	; write out field descriptor
	jnc	notMapped		; skip if the field not mapped	

	; lock the field info block

	push	es, dx, di
	mov	bx, EFH_Local.ISF_fieldInfoBlock
	call	MemLock

	; calculate place to insert FieldHeaderInfo 

	mov	es, ax
	mov	ax, dx
	mov	cx, size FieldHeaderInfo	
	mul	cx
	mov	di, ax			; es:di - place to insert

	; update field infor block for this field

	mov	al, EFH_Local.ISF_fieldType
	mov	es:[di].FHI_type, al	
	mov	ax, EFH_Local.ISF_fieldLength
	mov	es:[di].FHI_length, ax
	call	MemUnlock
	pop	es, dx, di

	; don't update the pointer if field size was zero

	tst	ax
	je	notMapped

	; check to see if we are done 

	add	di, size FieldDescriptor
notMapped:
	inc	dx
	cmp	dx, EFH_Local.ISF_numSourceFields
	jne	nextField

	; write out record length and header size

	mov	byte ptr es:[di], CR	; file header terminator
	inc	di
	mov	ax, EFH_Local.ISF_recordSize
	mov	es:[DBH_recordSize], ax	
	mov	es:[DBH_headerSize], di	

	; if done, write out file header block

	segmov	ds, es
	clr	dx			; ds:dx - fptr to string
	mov	cx, di			; cx - number of bytes to write out
        mov	bx, EFH_Local.ISF_cacheBlock	
	call	OutputCacheWrite	; write out file header block

	; delete the file header block

	pushf
	mov	bx, EFH_Local.ISF_fileHeader
	call	MemFree
	popf
	jnc	quit			; skip if no error
	mov	ax, TE_FILE_ERROR	; ax - TransError
	jmp	quit
noMem:
	mov	ax, TE_OUT_OF_MEMORY	; ax - TransError
quit:
	.leave
	ret
ExportFileHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportFieldDescriptor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new file descriptor and copies it into file header

CALLED BY:	INTERNAL (ExportFileHeader)

PASS:		es:di - ptr to file header block
		dx - current column (field) number

RETURN:		carry clear if the field has not been mapped
		carry set if mapped

DESTROYED:	ax, bx, cx, ds, si 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportFieldDescriptor	proc	near	uses	dx, di
	EFD_Local	local	ImpexStackFrame
	EFD_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; get true column number after the field has been mapped

        mov     ax, dx				; ax - column number
	mov	bx, EFD_Local.ISF_mapBlock	; bx - handle map block
        mov     cl, mask IF_EXPORT              ; do export
	call	GetMappedRowAndColNumber
	jnc	exit				; skip if not mapped

	; get FieldBlockInfo info from FIELD array

	mov	EFD_SSMeta.SSMDAS_dataArraySpecifier, DAS_FIELD
	mov	EFD_SSMeta.SSMDAS_col, ax	; ax - column number	
	mov	EFD_SSMeta.SSMDAS_row, 0	; row number
	push	bp
	mov	dx, ss
	lea	bp, EFD_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayGetEntryByCoord	; get this element
	pop	bp
	jnc	notEmpty			; exit if empty

	call	ExportGetDefaultFieldInfo	; get default field info
	jmp	done
notEmpty:
	add	si, size SSMetaEntry		; ds:si - ptr to FieldBlockInfo

	; check to see if this is an empty column

	tst	ds:[si].FIB_fieldSize
	je	skip				; if so, just exit

	push	si, di

	; copy the field name into file descriptor

	clr	cx
	add	si, offset FIB_fieldName	; ds:si - ptr to field name
next:
	lodsb	
	stosb
	inc	cx
	cmp	cx, FIELD_NAME_SIZE-1
	je	doneCopy
	tst	al
	jne	next
doneCopy:
	pop	si, di

	; get the field data type
skip:
	mov	al, ds:[si].FIB_fieldType
	mov	EFD_Local.ISF_fieldType, al

	; get the field data length

	call	ExportGetFieldLength		; al - dbase III data type 
	mov	es:[di].FD_fieldType, al	; save it

	cmp	EFD_Local.ISF_fieldType, FDT_REAL ; float format?
	jne     notFloat			; if not, skip

	; if float format, update the decimal count in field descriptor

	; I AM USING A DEFAULT VALUE FOR ALL FLOAT FIELDS BECAUSE THERE
	; IS NOT AN EASY WAY OF GETTING DECIMAL OFFSETS FOR EACH FIELD

	mov     es:[di].FD_decCount, DEFAULT_DECIMAL_OFFSET
notFloat:
	mov	es:[di].FD_fieldSize, bl	; bx - field length
	mov	EFD_Local.ISF_fieldLength, bx
	add	EFD_Local.ISF_recordSize, bx	; update record length

	; unlock the data array 

	push	bp
	mov	dx, ss
	lea	bp, EFD_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayUnlock
	pop	bp
done:
	stc					; return with carry set
exit:
	.leave
	ret
ExportFieldDescriptor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportGetDefaultFieldInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a default field info block.

CALLED BY:	INTERNAL ExportFieldDescriptor 

PASS:		ax - column number		
		es:di - ptr to file header block 

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportGetDefaultFieldInfo	proc	near
	EGDFI_Local	local	ImpexStackFrame
	EGDFI_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; get field name from CELL array

	mov	EGDFI_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	EGDFI_SSMeta.SSMDAS_col, ax	; ax - column number	
	mov	EGDFI_SSMeta.SSMDAS_row, 0	; row number
	push	bp, ax
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	clr     bx                              ; Assume no data
	call	SSMetaDataArrayGetEntryByCoord  ; ds:si <- ptr to data
						; cx <- size
	pop	bp, dx
	jc	noCell 				; branch if there is no data

	; There is data, we need to either reset our pointer, 
	; or else format the data to a block which we allocate.

	push	bp, dx, es, di
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	call	SSMetaFormatCellText		; ds:si <- ptr to text
	pop	bp, dx, es, di			; ax <- size of text
	jnc	notEmpty			; skip if cell exists

	; if there is no cell, get a default field name

	mov	cx, FIELD_NAME_SIZE-1		; cx - maximum field name length
	call	GetDefaultFieldName
	jmp	unlock

	; if this cell is empty get a default field name
noCell:
	mov	cx, FIELD_NAME_SIZE-1		; cx - maximum field name length
	call	GetDefaultFieldName
	jmp	getSize
notEmpty:
	push	si, di

	; copy the field name into file descriptor

	clr	cx
next:
	lodsb	
	stosb
	inc	cx
	cmp	cx, FIELD_NAME_SIZE-1
	je	doneCopy
	tst	al
	jne	next
doneCopy:
	pop	si, di

	; unlock the data array 
unlock:
	push	bp, dx
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	call	SSMetaDataRecordFieldUnlock
	pop	bp, dx
getSize:
	; get field size from CELL array

	mov	EGDFI_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	EGDFI_SSMeta.SSMDAS_col, dx	; dx - column number	
	mov	EGDFI_SSMeta.SSMDAS_row, 1	; row number
	push	bp, dx
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	clr     bx                              ; Assume no data
	call	SSMetaDataArrayGetEntryByCoord  ; ds:si <- ptr to data
						; cx <- size
	pop	bp, dx
	jc	empty 				; branch if there is no data

	; There is data, we need to either reset our pointer, 
	; or else format the data to a block which we allocate.

	push	bp, dx, es, di
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	call	SSMetaFormatCellText		; ds:si <- ptr to text
	pop	bp, dx, es, di			; ax <- size of text
						; bx <- block (if any)
	; unlock the data array 

	pushf	
	push	bp, dx
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	call	SSMetaDataRecordFieldUnlock
	pop	bp, dx
	popf
	jc	empty

	; make the column a little bit wider just in case

	add	al, FIELD_WIDTH_ADJUSTMENT
	jmp	common
empty:
	mov	al, DEFAULT_FIELD_WIDTH		; use the default field size	
common:
	mov	es:[di].FD_fieldSize, al	; ax - field length
	mov	EGDFI_Local.ISF_fieldLength, ax
	add	EGDFI_Local.ISF_recordSize, ax	; update record length

	; get field type from CELL array

	mov	EGDFI_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	EGDFI_SSMeta.SSMDAS_col, dx	; dx - column number	
	mov	EGDFI_SSMeta.SSMDAS_row, 1	; row number
	push	bp, dx
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	call	SSMetaDataArrayGetEntryByCoord	; get this element
	pop	bp, dx
	jc	noType

	; unlock the data array 

	push	bp
	mov	dx, ss
	lea	bp, EGDFI_SSMeta		; dx:bp - SSMetaStruc
	call	SSMetaDataArrayUnlock
	pop	bp

	add	si, size SSMetaEntry		; ds:si - ptr to CellCommon
	mov	al, ds:[si].CC_type		; al - field data type
	call	ConvertCellType
	jmp	skip
noType:
	mov	al, FDT_GENERAL_TEXT
skip:
	mov	EGDFI_Local.ISF_fieldType, al

	call	ConvertFieldType		; convert to dbase field type
	mov	es:[di].FD_fieldType, al	; save it

	.leave
	ret
ExportGetDefaultFieldInfo	endp

FDT_IGNORE 		equ	255 
FDT_FORMULA_TEXT  	equ	254
FDT_FORMULA_CONST  	equ	253

ConvertCellType	proc	near	uses	si
	.enter

	cmp	al, CT_TEXT
	jne	checkConst
	mov	al, FDT_GENERAL_TEXT
	jmp	exit
checkConst:
	cmp	al, CT_CONSTANT
	jne	checkFormula
	mov	al, FDT_REAL
	jmp	exit
checkFormula:
	cmp	al, CT_FORMULA
	jne	checkName
formula:
	add	si, size CellCommon		; ds:si - ptr to ReturnType
	mov	al, ds:[si]			; al - ReturnType
	cmp	al, RT_VALUE			; numeric value?	
	jne	checkText			; if not, skip
	mov	al, FDT_FORMULA_CONST		; numeric field
	jmp	exit
checkText:
	cmp	al, RT_TEXT			; text string?
	jne	error				; if not, error value
	mov	al, FDT_FORMULA_TEXT		; text field
	jmp	exit
error:
	mov	al, FDT_FORMULA_CONST		; text field
	jmp	exit
checkName:
	cmp	al, CT_NAME
	jne	checkChart
	mov	al, FDT_IGNORE
	jmp	exit
checkChart:
	cmp	al, CT_CHART
	jne	checkEmpty
	mov	al, FDT_IGNORE
	jmp	exit
checkEmpty:
	cmp	al, CT_EMPTY
	jne	formula
	mov	al, FDT_IGNORE
exit:
	.leave
	ret
ConvertCellType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertFieldType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts FieldDataType to dBase III field type.

CALLED BY:	(INTERNAL) ExportGetDefaultFieldInfo

PASS:		al - FieldDataType

RETURN:		al - dBase III field data type

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	1/26/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertFieldType	proc	near
	CFT_Local	local	ImpexStackFrame
	CFT_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; check to see if this is a text field

	cmp	al, FDT_GENERAL_TEXT
	jne	checkComputed
	mov	al, 'C'				; al - dBase III field type
	jmp	exit

	; check to see if this is a computed field
checkComputed:
	cmp	al, FDT_COMPUTED
	jne	checkInteger
	mov	al, 'N'				; convert it to numeric field
	jmp	exit

	; check to see if this is an integer field
checkInteger:
	cmp	al, FDT_INTEGER
	jne	checkReal
	mov	al, 'N'				; convert it to numeric field
	jmp	exit
		
	; check to see if this is a read field
checkReal:
	cmp	al, FDT_REAL
	jne	checkDate
	mov	al, 'N'				; convert it to numeric field
	jmp	exit

	; check to see if this is a date field
checkDate:
	cmp	al, FDT_DATE
	jne	checkTime
	mov	al, 'D'				; convert it to date field
	jmp	exit

	; check to see if this is a time field
checkTime:
	cmp	al, FDT_TIME
	jne	checkIgnore
	mov	al, 'C'				; convert it to text field
	jmp	exit
checkIgnore:
	cmp	al, FDT_IGNORE
	jne	checkFormula1
	mov	al, 'C'
	jmp	exit
checkFormula1:
	cmp	al, FDT_FORMULA_CONST
	jne	checkFormula2
	mov	al, 'N'				; numeric field
	jmp	exit
checkFormula2:
	mov	al, 'C'				; assume text value
exit:
	.leave
	ret
ConvertFieldType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportGetFieldLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a field data type, returns field length and dBase III
		data type.

CALLED BY:	INTERNAL (ExportFieldDescriptor)

PASS:		ds:si - ptr to FieldDescriptor

RETURN:		al - dBase III field data type
		bx - field size

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportGetFieldLength	proc	near
	EGFL_Local	local	ImpexStackFrame
	EGFL_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; check to see if this is a text field

	cmp	al, FDT_GENERAL_TEXT
	jne	checkComputed
	mov	al, 'C'				; al - dBase III field type
	mov	bx, ds:[si].FIB_fieldSize 

	; check to see if the field size is too big

	cmp	bx, TEXT_FIELD_SIZE
	jle	exit
	mov	bx, TEXT_FIELD_SIZE		; bx - field length
	jmp	exit

	; check to see if this is a computed field
checkComputed:
	cmp	al, FDT_COMPUTED
	jne	checkInteger
	mov	al, 'N'				; convert it to numeric field
	mov	bx, FLOAT_FIELD_SIZE		; bx - field length
	jmp	exit

	; check to see if this is an integer field
checkInteger:
	cmp	al, FDT_INTEGER
	jne	checkReal
	mov	al, 'N'				; convert it to numeric field
	mov	bx, INTEGER_FIELD_SIZE		; bx - field length
	jmp	exit
		
	; check to see if this is a read field
checkReal:
	cmp	al, FDT_REAL
	jne	checkDate
	mov	al, 'N'				; convert it to numeric field
	mov	bx, FLOAT_FIELD_SIZE		; bx - field size
	jmp	exit

	; check to see if this is a date field
checkDate:
	cmp	al, FDT_DATE
	jne	checkTime
	mov	al, 'D'
	mov	bx, DATE_FIELD_SIZE 		; bx - field size
	jmp	exit

	; it has to be a time field
checkTime:
	mov	al, 'C'				; convert it to numeric field
	mov	bx, TIME_FIELD_SIZE 		; bx - field size
exit:
	.leave
	ret
ExportGetFieldLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportFileFast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out data portion of the meta file using 
		'SSMetaDataArrayGetNext'.

CALLED BY:	TransExport

PASS:		ImportStackFrame		

RETURN:		carry set if error (ax = TransError)

DESTROYED:	ax, bx, cx, dx, si, di, es, ds

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportFileFast	proc	near
	EFF_Local	local	ImpexStackFrame
	EFF_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; initialize some flags

	mov	EFF_Local.ISF_endOfFile, FALSE	
	mov	EFF_Local.ISF_endOfLine, FALSE	

	; point to the beginning of DAS_CELL data chain

	mov	EFF_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	push	bp
	mov	dx, ss
	lea	bp, EFF_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayResetEntryPointer
	pop	bp

	; allocate a block for storing field data

	mov	ax, TEXT_FIELD_SIZE		; ax - size of block to allocate
	mov     cx, (HAF_STANDARD_NO_ERR shl 8) or 0	; HeapAllocFlags
	call	MemAlloc			; allocate a block
	mov	EFF_Local.ISF_fieldBlock, bx 	; save the handle of this block 

	clr	EFF_Local.ISF_rowNumber		; record number counter
nextRecord:
	; write out a space character to indicate the beg. of a record

	push	ds
	segmov	ds, cs
	mov	dx, offset space		; ds:dx - fptr to string
	mov	cx, 1				; cx - # of bytes to write out
        mov	bx, EFF_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		
	pop	ds
	LONG	jc	fileErr			; skip if file error

	clr	EFF_Local.ISF_colNumber		; field number counter
nextField:
	; check to see if the field data we are about to parse has already
	; been lock by a previous call to 'SSMetaDataArrayGetNextEntry'

	tst	EFF_Local.ISF_endOfLine
	jne	locked				; if locked, skip

	; get an element from DAS_CELL data chain 

	push	bp
	mov	dx, ss
	lea	bp, EFF_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayGetNextEntry
	pop	bp
	jnc	locked				; skip if not end of chain

	; end of data chain, set end of file flag

	mov	EFF_Local.ISF_endOfFile, TRUE	
	jmp	checkEOL	
locked:
	; check to see if we are at the end of a record

	mov	ax, EFF_Local.ISF_rowNumber
	cmp	ax, ds:[si].SSME_coordRow
	je	checkField
checkEOL:
	; we are at the end of a record, write out some empty
	; data fields, if necessary

	mov	dx, EFF_Local.ISF_colNumber
	cmp	dx, EFF_Local.ISF_numSourceFields
	jne	writeEmpty	

	; no need to write out any empty data fields
	; set end of line flag and update row and column counters

	tst	EFF_Local.ISF_endOfFile		; no more data?
	jne	done				; if none, exit

	mov	EFF_Local.ISF_endOfLine, TRUE
	inc	EFF_Local.ISF_rowNumber
	clr	EFF_Local.ISF_colNumber
	jmp	nextRecord
writeEmpty:
	; write out empty fields until we are at the end of a record
	
	mov	EFF_Local.ISF_emptyField, TRUE
	push	ds, si
	call	ExportFieldData			; write out field data
	pop	ds, si
	jc	fileErr				; exit if file error

	inc	EFF_Local.ISF_colNumber		; update column counter
	jmp	checkEOL			; done, parse next record
checkField:
	; check to see if we need to write out some empty data fields

	mov	dx, EFF_Local.ISF_colNumber
	cmp	dx, ds:[si].SSME_coordCol
	je	exportField			; if not, skip to export 

	; empty fields exist between two non-empty cells, write them out
	
	mov	EFF_Local.ISF_emptyField, TRUE
	push	ds, si
	call	ExportFieldData			; write out field data
	pop	ds, si
	jc	fileErr				; exit if file error

	inc	EFF_Local.ISF_colNumber		; update column counter
	jmp	checkField			; if not continue
exportField:
	; finally, we are ready to export this data

	mov	EFF_Local.ISF_emptyField, FALSE
	add	si, size SSMetaEntry		; ds:si - field data 
	call	ExportFieldData			; write out field data
	jc	fileErr				; exit if file error
	inc	EFF_Local.ISF_colNumber		; update column counter
	mov	EFF_Local.ISF_endOfLine, FALSE
	jmp	nextField			; continue	
done:
	; unlock the data chain

	push	bp
	mov	dx, ss
	lea	bp, EFF_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayUnlock
	pop	bp

	; remove the field data block

	mov	bx, EFF_Local.ISF_fieldBlock 	
	call	MemFree				
	clc	
	jmp	quit
fileErr:
	mov	ax, TE_FILE_ERROR		; ax - TransError
	mov	bx, EFF_Local.ISF_fieldBlock 	
	call	MemFree				; remove the field data block
	stc
quit:
	.leave
	ret
ExportFileFast		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportRecordData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out data portion of the meta file	

CALLED BY:	TransExport

PASS:		ImportStackFrame		

RETURN:		carry set if error (ax = TransError)

DESTROYED:	ax, bx, cx, dx, si, di, es, ds

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
        space		byte    SPACE, 0
ExportRecordData	proc	near
	ERD_Local	local	ImpexStackFrame
	ERD_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; allocate a block for storing field data

	mov	ax, TEXT_FIELD_SIZE		; ax - size of block to allocate
	mov     cx, (HAF_STANDARD_NO_ERR shl 8) or 0	; HeapAllocFlags
	call	MemAlloc			; allocate a block
	mov	ERD_Local.ISF_fieldBlock, bx 	; save the handle of this block 

	clr	cx				; record number counter
nextRecord:
	push	cx
	mov	ERD_SSMeta.SSMDAS_row, cx	; cx - row number
	segmov	ds, cs
	mov	dx, offset space		; ds:dx - fptr to string
	mov	cx, 1				; cx - # of bytes to write out
        mov	bx, ERD_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out space character
	jc	fileErr				; skip if file error
	clr	dx				; field number counter
nextField:
	; get true column number after the field has been mapped

	push	dx
        mov     ax, dx				; ax - column number
	mov	bx, ERD_Local.ISF_mapBlock	; bx - handle map block
        mov     cl, mask IF_EXPORT              ; do export
	call	GetMappedRowAndColNumber
	jnc	skip				; skip if not mapped

	; get field data from CELL array

	mov	ERD_Local.ISF_emptyField, FALSE	; assume not empty
	mov	ERD_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	ERD_SSMeta.SSMDAS_col, ax	; ax - mapped column number	
	push	bp
	mov	dx, ss
	lea	bp, ERD_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayGetEntryByCoord	; get this element
	pop	bp
	jnc	notEmpty			; skip if not empty
	mov	ERD_Local.ISF_emptyField, TRUE	; set empty field flag
notEmpty:
	pop	dx				; dx - current column number
	push	dx
	add	si, size SSMetaEntry		; ds:si - field data 
	call	ExportFieldData			; write out field data

	; no need to unlock a data entry that was non extant

	pushf					; save the carry flag
	cmp	ERD_Local.ISF_emptyField, TRUE	; was it an empty field? 
	je	empty				; skip if empty

	; unlock the huge array block

	push	bp
	mov	dx, ss
	lea	bp, ERD_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayUnlock
	pop	bp
empty:
	popf					; restore the carry flag
	jc	fileErr0			; exit if file error
skip:
	; get the next field if not done

	pop	dx
	inc	dx
	cmp	dx, ERD_Local.ISF_numSourceFields
	jne	nextField

	; get the next record if not done

	pop	cx
	inc	cx
	cmp	cx, ERD_Local.ISF_numRecords.low
	jne	nextRecord

	; remove the field data block

	mov	bx, ERD_Local.ISF_fieldBlock 	
	call	MemFree				
	clc	
	jmp	quit
fileErr0:
	pop	dx
fileErr:
	pop	cx
	mov	ax, TE_FILE_ERROR		; ax - TransError
	mov	bx, ERD_Local.ISF_fieldBlock 	
	call	MemFree				; remove the field data block
	stc
quit:
	.leave
	ret
ExportRecordData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportFieldData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the field data to export file.

CALLED BY:	INTERNAL (ExportRecordData)

PASS:		ds:si - ptr to CellCommon
		dx - current field number

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, es, ds, si, di

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportFieldData		proc	near	uses	cx, dx
	EFD_Local	local	ImpexStackFrame
	EFD_SSMeta	local	SSMetaStruc
	.enter	inherit	near	

	; lock the field info block

	mov	bx, EFD_Local.ISF_fieldInfoBlock
	call	MemLock

	; locate the field info for the current field

	mov	es, ax
	mov	ax, dx
	mov	cx, size FieldHeaderInfo	
	mul	cx
	mov	di, ax			; es:di - FieldHeaderInfo
	mov	al, es:[di].FHI_type
	mov	cx, es:[di].FHI_length
	call	MemUnlock

	; save FieldHeaderInfo

	mov	EFD_Local.ISF_fieldType, al
	mov	EFD_Local.ISF_fieldLength, cx

	; check to see if the current cell data type matches field data type

	push	ax
	mov	al, ds:[si].CC_type	; al - CellType
	call	CompareDataTypes	; check for data type conflict
	pop	ax
	jne	emptyCell		; if so, write out empty cell

	add	si, size CellCommon	; ds:si - pointer to field data

	; check to see if this is an empty column

	cmp	EFD_Local.ISF_emptyField, TRUE	
	jne	notEmpty		; if not, skip

	; if this is an empty field in a non empty column 
	; then write out the empty field data
emptyCell:
	jcxz	exit
	call	ExportEmptyFieldData	;  write out empty field
	jmp	exit
notEmpty:
	cmp	al, FDT_GENERAL_TEXT
	jne	checkInteger
	call	ExportTextField
	jmp	exit

	; check to see if this is an integer field
checkInteger:
	cmp	al, FDT_INTEGER
	jne	checkReal
	call	ExportIntegerField
	jmp	exit

	; check to see if this is a real field
checkReal:
	cmp	al, FDT_REAL
	jne	checkDate
	call	ExportIntegerField
	jmp	exit

	; check to see if this is a date field
checkDate:
	cmp	al, FDT_DATE
	jne	checkTime
	call	ExportDateField
	jmp	exit

	; check to see if this is a time field
checkTime:
	cmp	al, FDT_TIME
	jne	checkIgnore
	call	ExportTimeFieldData
	jmp	exit

	; check to see if this is an ignored  field
checkIgnore:
	cmp	al, FDT_IGNORE
	jne	checkFormula1
	call	ExportEmptyFieldData	;  write out empty field
	jmp	exit

	; check to see if this is a text formula field
checkFormula1:
	cmp	al, FDT_FORMULA_TEXT	
	jne	checkFormula2		
	call	ExportTextFormulaFieldData
	jmp	exit

	; check to see if this is a numeric formula field
checkFormula2:
	cmp	al, FDT_FORMULA_CONST	; is this a numeric formula field?
	je	formula			; if so, skip to handle it
	stc				; if not a formula field, 
	jmp	exit			; exit with carry set
formula:
	call	ExportNumericFormulaFieldData
exit:
	.leave
	ret
ExportFieldData		endp

CompareDataTypes	proc	near
	CDT_Local	local	ImpexStackFrame
	CDT_SSMeta	local	SSMetaStruc
	.enter	inherit	near	

	cmp	al, CT_CONSTANT
	jne	other

	; treat FDT_REAL, FDT_INTEGER, FDT_DATE, and FDT_TIME the same

	cmp	CDT_Local.ISF_fieldType, FDT_REAL
	je	exit
	cmp	CDT_Local.ISF_fieldType, FDT_INTEGER
	je	exit
	cmp	CDT_Local.ISF_fieldType, FDT_DATE
	je	exit
	cmp	CDT_Local.ISF_fieldType, FDT_TIME
	jmp	exit
other:
	call	ConvertCellType
	cmp	CDT_Local.ISF_fieldType, al
exit:
	.leave
	ret
CompareDataTypes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes out text field data

CALLED BY:	INTERNAL (ExportFieldData)

PASS:		ds:si - ptr to field data

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, cx, es, si, di   	

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportTextField		proc	near
	ETF_Local	local	ImpexStackFrame
	ETF_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; lock the data block

	mov	bx, ETF_Local.ISF_fieldBlock 	
	call	MemLock			
	mov	cx, TEXT_FIELD_SIZE		; cx - size of data block

	; initialize this data block with space characters

	mov	es, ax
	clr	di
	mov	al, SPACE
	rep	stosb

	; copy the text string in ds:si to this data block

	mov	cx, TEXT_FIELD_SIZE		; cx - size of data block
	clr	di
next:
	lodsb
	tst	al			; do not copy null terminator
	je	exitLoop
	stosb
	loop	next
exitLoop:
	; write out this data block to export file

	mov	cx, ETF_Local.ISF_fieldLength	; cx - # of bytes to write out
	segmov	ds, es
	clr	dx				; ds:dx - fptr to string
        mov	bx, ETF_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write header block

	pushf					; save the flags
	mov	bx, ETF_Local.ISF_fieldBlock 	
	call	MemUnlock			
	popf					; restore the flags

	.leave
	ret
ExportTextField		endp

ExportIntegerField	proc	near
	EIF_Local	local	ImpexStackFrame
	EIF_SSMeta	local	SSMetaStruc
	.enter	inherit	near
	
	; lock the data block

	mov	bx, EIF_Local.ISF_fieldBlock 	
	call	MemLock			
	mov	cx, TEXT_FIELD_SIZE		; cx - size of data block

	; initialize this data block with space characters

	mov	es, ax
	clr	di
	mov	al, SPACE
	rep	stosb

	; convert number to ascii string

	mov	di, INTEGER_FIELD_SIZE		; es:di - destination addr 
	mov     al, EIF_Local.ISF_fieldType     ; al - field data type
	call	ExportIntegerToAscii		; convert the number	
	tst	cx				; successful conversion?
	jne	noError				; if so, skip

	; if error, get the size of error string

        call	LocalStringSize                 ; cx <- Size of string
noError:
	; write out this data field to export file

	mov	dx, EIF_Local.ISF_fieldLength	; dx - field length
	cmp	cx, dx				; ascii string too long?
	jge	tooLong				; if so, skip 

	; figure out where the start of string to copy is

	sub	dx, cx
	mov	ax, INTEGER_FIELD_SIZE
	sub	ax, dx
	xchg	dx, ax
	jmp	common
tooLong:
	mov	dx, INTEGER_FIELD_SIZE		; ds:dx - ptr to field data
common:
	mov	cx, EIF_Local.ISF_fieldLength	; cx - # of bytes to copy
	segmov	ds, es
        mov	bx, EIF_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out data field 

	pushf
	mov	bx, EIF_Local.ISF_fieldBlock 	
	call	MemUnlock			
	popf

	.leave
	ret
ExportIntegerField	endp

ExportIntegerToAscii	proc	near
	EITA_Local	local	FFA_stackFrame
	.enter

	; no header or trailer string

	mov	EITA_Local.FFA_float.FFA_params.header, 0	
	mov	EITA_Local.FFA_float.FFA_params.trailer, 0

	mov	EITA_Local.FFA_float.FFA_params.formatFlags, mask FFAF_FROM_ADDR
	mov	EITA_Local.FFA_float.FFA_params.decimalLimit, 0

	cmp	al, FDT_FORMULA_CONST	; formula number? 
	je	skip			; if so, skip

        cmp     al, FDT_REAL            ; float number field?
	jne     notFloat                ; if not, skip

	; if float format, use the default decimal limit

	; I AM USING A DEFAULT VALUE FOR ALL FLOAT FIELDS BECAUSE THERE
	; IS NOT AN EASY WAY OF GETTING DECIMAL OFFSETS FOR EACH FIELD

skip:
	mov     EITA_Local.FFA_float.FFA_params.decimalLimit, DEFAULT_DECIMAL_OFFSET
notFloat:
	mov	EITA_Local.FFA_float.FFA_params.totalDigits, DECIMAL_PRECISION
	mov	EITA_Local.FFA_float.FFA_params.decimalOffset, 0

	mov	EITA_Local.FFA_float.FFA_params.preNegative, '-'	
	mov	EITA_Local.FFA_float.FFA_params.preNegative+1, 0
	mov	EITA_Local.FFA_float.FFA_params.postNegative, 0
	mov	EITA_Local.FFA_float.FFA_params.postPositive, 0
	mov	EITA_Local.FFA_float.FFA_params.prePositive, 0

	call	FloatFloatToAscii		; convert!
	.leave
	ret
ExportIntegerToAscii	endp

ExportDateField		proc	near
	EDF_Local	local	ImpexStackFrame
	EDF_SSMeta	local	SSMetaStruc
	.enter	inherit	near
	
	; lock the data block

	mov	bx, EDF_Local.ISF_fieldBlock 	
	call	MemLock			
	mov	es, ax
	clr	di

	; initialize the floating point stack

	mov	ax, FP_DEFAULT_STACK_SIZE
	mov	bl, FLOAT_STACK_DEFAULT_TYPE
	call	FloatInit

	; push the float number on to the stack

	call	FloatPushNumber
	call	FloatDateNumberGetYear		; ax - year number
	jnc	noError				; skip if no error
	clr	ax				; just convert zero
noError:
	clr	dx				; dx:ax - number to convert
	mov	cx, mask UHTAF_INCLUDE_LEADING_ZEROS ; cx - UtilHexToAsciiFlags
	call	UtilHex32ToAscii		; convert it to ascii

	; write out year string to export file

	push	ds, si
	mov	cx, DATE_YEAR_SIZE		; cx - # of bytes to write out
	mov	dx, 6				; ds:dx - ptr to field data
	segmov	ds, es
        mov	bx, EDF_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out data field 
	pop	ds, si
	jc	error				; exit if error

	; push the float number on to the stack again

	call	FloatPushNumber
	call	FloatDateNumberGetMonthAndDay	; bl - month, bh - day
	clr	di				; es:di - destination buffer
	clr	dx
	clr	ah
	mov	al, bl				; dx:ax - number to convert
	mov	cx, mask UHTAF_INCLUDE_LEADING_ZEROS ; cx - UtilHexToAsciiFlags
	call	UtilHex32ToAscii		; convert month to ascii

	; write out month string to export file

	push	bx
	mov	cx, 2				; cx - # of bytes to write out
	mov	dx, 8				; ds:dx - ptr to field data
	segmov	ds, es
        mov	bx, EDF_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out data field 
	pop	bx
	jc	error				; exit if error

	clr	di				; es:di - destination buffer
	clr	dx
	clr	ah
	mov	al, bh
	mov	cx, mask UHTAF_INCLUDE_LEADING_ZEROS ; cx - UtilHexToAsciiFlags
	call	UtilHex32ToAscii		; convert day to ascii

	; write out date string to export file

	mov	cx, 2				; cx - # of bytes to write out
	mov	dx, 8				; ds:dx - ptr to field data
	segmov	ds, es
        mov	bx, EDF_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out data field 
error:
	pushf
	call	FloatExit
	mov	bx, EDF_Local.ISF_fieldBlock 	
	call	MemUnlock			
	popf

	.leave
	ret
ExportDateField		endp

ExportTimeFieldData	proc	near
	ETFD_Local	local	ImpexStackFrame
	ETFD_SSMeta	local	SSMetaStruc
	.enter	inherit	near
	
	; lock the data block

	mov	bx, ETFD_Local.ISF_fieldBlock 	
	call	MemLock			
	mov	cx, FLOAT_TO_ASCII_NORMAL_BUF_LEN		

	; initialize this data block with space characters

	mov	es, ax
	clr	di
	mov	al, SPACE
	rep	stosb

	; convert time float number to ascii string

	clr	di				; es:di - destination buffer
	call	ExportTimeToAscii		

	; count the number of bytes in the ascii string

	call	LocalStringSize			; cx - string size
	mov	di, cx
	mov	byte ptr es:[di], SPACE

	; write out time string to export file

	mov	cx, ETFD_Local.ISF_fieldLength	; cx - # of bytes to copy
	clr	dx
	segmov	ds, es				; ds:dx - ptr to string to copy
        mov	bx, ETFD_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out data field 
	
	pushf
	mov	bx, ETFD_Local.ISF_fieldBlock 	
	call	MemUnlock			
	popf

	.leave
	ret
ExportTimeFieldData	endp

ExportTimeToAscii	proc	near 
	ETTA_Local	local   FFA_stackFrame
	.enter

	mov	ax, DTF_HMS		; time format
	mov	bx, mask FFDT_DATE_TIME_OP or mask FFDT_FROM_ADDR
	or	ax, bx
	mov	ETTA_Local.FFA_dateTime.FFA_dateTimeParams.FFA_dateTimeFlags, ax
	call	FloatFloatToAscii	; convert to time

	.leave
	ret
ExportTimeToAscii	endp

ExportEmptyFieldData	proc	near
	EEFD_Local	local	ImpexStackFrame
	EEFD_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; lock the data block

	mov	bx, EEFD_Local.ISF_fieldBlock 	
	call	MemLock			
	mov	cx, TEXT_FIELD_SIZE		; cx - size of data block

	; initialize this data block with space characters

	mov	es, ax
	clr	di
	mov	al, SPACE
	rep	stosb

	; write out empty data block to export file

	mov	cx, EEFD_Local.ISF_fieldLength	; cx - # of bytes to write out
	segmov	ds, es
	clr	dx				; ds:dx - fptr to string
        mov	bx, EEFD_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write header block

	pushf
	mov	bx, EEFD_Local.ISF_fieldBlock 	
	call	MemUnlock			
	popf

	.leave
	ret
ExportEmptyFieldData	endp

ExportTextFormulaFieldData	proc	near
	ETFFD_Local	local	ImpexStackFrame
	ETFFD_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	inc	si
	call	ExportTextField

	.leave
	ret
ExportTextFormulaFieldData	endp

ExportNumericFormulaFieldData	proc	near
	ENFFD_Local	local	ImpexStackFrame
	ENFFD_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	inc	si
	call	ExportIntegerField

	.leave
	ret
ExportNumericFormulaFieldData	endp

        endOF		byte    26, 0
ExportEndOfFileChar	proc	near	uses	ds, cx, bp
	EEOFC_Local	local	ImpexStackFrame
	EEOFC_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	segmov	ds, cs
	mov	dx, offset endOF		; ds:dx - fptr to string
	mov	cx, 1				; cx - # of bytes to write out
        mov	bx, EEOFC_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out these two chars

	.leave
	ret
ExportEndOfFileChar	endp

Export	ends
