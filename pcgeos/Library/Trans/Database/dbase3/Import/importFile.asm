COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	dBase III
MODULE:		Import		
FILE:		importFile.asm

AUTHOR:		Ted H. Kim, 9/14/92

ROUTINES:
	Name			Description
	----			-----------
	TransGetFormat		Check for the format of import file
	TransImport		Import the file
	ImportParseHeader	Read in file header
	ImportGetFieldData	Read in a field from the source file
	ImportAddFieldToArray	Add the field to the huge array
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/92		Initial revision

DESCRIPTION:
		
	Contains all of file import routines.

	$Id: importFile.asm,v 1.1 97/04/07 11:43:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Import	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the file is of dBase III format.	

CALLED BY:	GLOBAL
PASS:		si	- file handle (open for read)	
RETURN:		ax	- TransError (0 = no error)
		cx	- format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransGetFormat	proc	far	uses	bx, dx, ds
	TGF_headerBuffer	local	DBaseHeader
	TGF_fieldBuffer		local	FieldDescriptor

	.enter

	; read in dbase III file header

	mov	cx, FIELD_DESCRIPTOR_SIZE	
	segmov	ds, ss			; read it into local variable 
	lea	dx, TGF_headerBuffer
	clr	al			; flags = 0
	mov	bx,si			; bx - file handle
	call	FileRead		; read in the version number
	jc	notFormat		; skip if error

	; check the version number of this file

	cmp	TGF_headerBuffer.DBH_version, DBASE3_NO_MEMO
	je	okay

	cmp	TGF_headerBuffer.DBH_version, DBASE3_MEMO
	jne	notFormat
okay:
	mov	cx, TGF_headerBuffer.DBH_headerSize 
	sub	cx, FIELD_DESCRIPTOR_SIZE
	dec	cx
mainLoop:
	; cx - number of bytes left to read in 
	; now check to make sure it is not dbase IV file

	push	cx
	mov	cx, size FieldDescriptor; read in a field descriptor	
	segmov	ds, ss			; read it into local variable 
	lea	dx, TGF_fieldBuffer
	clr	al			; flags = 0
	mov	bx,si			; bx - file handle
	call	FileRead		; read in the version number
	pop	cx
	jc	notFormat		; skip if error

	mov	al, TGF_fieldBuffer.FD_fieldType
	call	CheckFieldType		; check for field data type
	jc	notFormat		; exit if illegal data type, 

	sub	cx, size FieldDescriptor; cx - update header size 
	js	notFormat		; if sign bit set, then error
	jne	mainLoop		; if not done, get the next field
	clr	cx			; cx <- format number
done:
	clr	ax			; ax <- TE_NO_ERROR
	.leave
	ret
notFormat:
	mov	cx, NO_IDEA_FORMAT
	jmp	done
TransGetFormat	endp

	; returns carry set if illegal data type
	; returns carry clear if legal data type

CheckFieldType	proc	near
	cmp	al, 'C'
	je	noError
	cmp	al, 'N'
	je	noError
	cmp	al, 'L'
	je	noError
	cmp	al, 'M'
	je	noError
	cmp	al, 'D'
	je	noError
	stc
	jmp	done
noError:
	clc
done:
	ret
CheckFieldType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library routine called by the Impex library.

CALLED BY:	Impex

PASS:           ds:si - ImportFrame

RETURN:         ax - TransError
		bx - handle of error msg if ax = TE_CUSTOM
			else- clipboardFormat CIF_SPREADSHEET
		dx:cx - VM chain containing transfer format
		si    - ManufacturerID
DESTROYED:	di, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransImport	proc	far
	TI_Local  local	ImpexStackFrame
	TI_SSMeta local	SSMetaStruc
	.enter

	; attach the source file for caching

	mov     bx, ds:[si].IF_sourceFile	; bx - handle of source file 
	call	InputCacheAttach		; create the input buffer
	mov	ax, TE_OUT_OF_MEMORY		; ax - TransError
	jc	exit				; exit if memory alloc error
	mov	TI_Local.ISF_cacheBlock, bx	; save cache block handle 

	; save the map entry block handle

	mov	bx, ds:[si].IF_importOptions	; bx - map list block
	mov	TI_Local.ISF_mapBlock, bx	; save it

	; initialize the stack frame for file importing

	push	bp
	clr	ax				; ax:cx - source ID
	clr	cx
        mov     bx, ds:[si].IF_transferVMFile	; bx - handle of transfer file
	mov	dx, ss
	lea	bp, TI_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaInitForStorage		; set up SSMeta header block 	
	pop	bp

	; create a list of column numbers that are not mapped

	;mov	bx, TI_Local.ISF_mapBlock
	;call	ImportCreateNotMappedColumnList
	;mov	TI_Local.ISF_notMappedList, bx	; save the handle

	; read in the source file and create meta file

	call	ImportParseHeader
	jc	error				; skip if error
	call	ImportParseData
error:
	; destroy the cached block

	mov	bx, TI_Local.ISF_cacheBlock	; bx - cache block handle 
	call	InputCacheDestroy		; does not trash flags

	; this carry is the result of "ImportParseHeader" 
	; or "ImportParseData"  
	
	jc	exit				; exit if error	

	; update SSMeta header block

	push	bp
	mov	ax, TI_Local.ISF_curRecord	; ax - number of records
	mov	cx, TI_Local.ISF_numFields	; cx - number of fields
	mov	dx, ss
	lea	bp, TI_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaSetScrapSize
	pop	bp

	; return with VM chain and VM file handle

	mov     dx, TI_SSMeta.SSMDAS_hdrBlkVMHan	
	clr     cx				; dx:cx - VM chain
	mov     ax, TE_NO_ERROR                	; return with no error
	mov	bx, CIF_SPREADSHEET
	mov	si, MANUFACTURER_ID_GEOWORKS

	; clean up

	;mov	bx, TI_Local.ISF_notMappedList	; handle of not-mapped block
	;tst	bx
	;je	exit				; exit if no map block
	;call	MemFree
exit:
	.leave
	ret
TransImport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportParseHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the various sections of file header.

CALLED BY:	INTERNAL (TransImport)

PASS:		ImpexStackFrame

RETURN:		carry set if there was an error (ax = TransError)

DESTROYED:	ax, bx, cx, dx, si, di, es	

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportParseHeader	proc	near
	IPH_Local	local	ImpexStackFrame
	IPH_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	; first check to see if this is indeed dBase III file

	clr	IPH_Local.ISF_numFields		; init. number of fields
	clr	IPH_Local.ISF_mappedNumFields	; init. mapped num of fields
	call	ImportCheckVersionNumber		
	jc	quit				; if not, exit

	mov	cx, LAST_UPDATE			; number of bytes to skip
	call	ImportSkipBytes			; skip four bytes
	jc	fileErr				; exit if file error

	call	ImportGetNumRecords		; get number of records
	jc	fileErr				; exit if file error
	call	ImportGetHeaderSize		; get the size of header
	jc	fileErr				; exit if file error
	call	ImportGetRecordSize		; get the length of a record
	jc	fileErr				; exit if file error

	mov	cx, RESERVED1
	call	ImportSkipBytes			; skip ten bytes
	jc	fileErr				; exit if file error

	; keep track of number of bytes left in the header block

	sub	IPH_Local.ISF_curHeaderSize, size DBaseHeader 
	js	fileErr				; size mismatch, exit

	; allocate a block for storing field length and type

	mov	ax, FIELD_INFO_BLOCK_SIZE  	; ax - size of block to allocate
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8) or 0 
	call	MemAlloc			; allocate a block
	mov	IPH_Local.ISF_fieldInfoBlock, bx; save the handle
	clr	dx				; initialize column number

	; read in field descriptors
next:
	mov	bx, IPH_Local.ISF_cacheBlock	; bx - handle of cache block
        call    InputCacheGetChar		; read in a character
	jc	fileErr				; exit if file error

	cmp	al, CR				; end of header block? 
	je	exit				; if so, exit
	
	call	InputCacheUnGetChar

	; update the number of bytes to be read in the header block

	sub	IPH_Local.ISF_curHeaderSize, FIELD_DESCRIPTOR_SIZE 
	js	fileErr				; size mismatch, exit

	call	ImportGetFieldDescriptor	; read in a field descriptor
	jnc	skip				; skip if field not mapped

	; carry is set.  check to see if there was an error

	cmp	ax, TE_NO_ERROR
	jne	error				; exit if error
	inc	IPH_Local.ISF_mappedNumFields	; up mapped field number counter
skip:
	inc	dx				; up the column number
	jmp	next				; read in the next one
exit:
	; subtract one for the end of header block character

	dec	IPH_Local.ISF_curHeaderSize
	js	fileErr				; if size mismatch, exit

	; are there any more bytes to be read from the header block

	mov	cx, IPH_Local.ISF_curHeaderSize
	jcxz	okay				; if not, skip

	; if so, skip those bytes

	call	ImportSkipBytes			
	jc	fileErr				; exit if file error
okay:
	mov	IPH_Local.ISF_numFields, dx	; update number of fields
	clc					; exit with no error	
	jmp	quit
fileErr:
	mov	ax, TE_FILE_ERROR		; ax - TransError
error:
	stc					; exit with carry set
quit:
	.leave
	ret
ImportParseHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportCheckVersionNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the file has the right version number. 

CALLED BY:	INTERNAL (ImportParseHeader)

PASS:		ImpexStackFrame

RETURN:		carry set if error (ax = TransError)

DESTROYED:	ax, bx

SIDE EFFECTS:	bx - handle of cache block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportCheckVersionNumber	proc	near
        ICVN_Local	local	ImpexStackFrame
	ICVN_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	; get the version number byte from the header

	mov	bx, ICVN_Local.ISF_cacheBlock	
        call	InputCacheGetChar		
	jc	fileErr			; exit if file error

	cmp	al, DBASE3_NO_MEMO
	je	okay
	cmp	al, DBASE3_MEMO
	jne	notOk
okay:
	clc		; we have the correct version, exit with no error
	jmp	exit
fileErr:
	mov	ax, TE_FILE_ERROR	; ax - TransError
	jmp	exit
notOk:
	mov	ax, TE_INVALID_FORMAT	; ax - TransError
	stc		; we have wrong version, exit with carry set
exit:
	.leave
	ret
ImportCheckVersionNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportSkipBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip the given number of bytes in the header block.

CALLED BY:	INTERNAL

PASS:		cx - number of bytes to skip

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, cx

SIDE EFFECTS:	bx - handle cache block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportSkipBytes	proc	near
	ISB_Local	local	ImpexStackFrame
	ISB_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	mov	bx, ISB_Local.ISF_cacheBlock	; bx - handle of cache block
getNext:
        call	InputCacheGetChar		; read in a character  	
	jc	exit				; exit if error
	loop	getNext				; get the next character
	clc
exit:
	.leave
	ret
ImportSkipBytes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetNumRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get total number of records from the header block.

CALLED BY:	INTERNAL (ImportParseHeader)

PASS:		ImpexStackFrame

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx

SIDE EFFECTS:	bx - handle cache block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetNumRecords	proc	near
        IGNR_Local	local	ImpexStackFrame
	IGNR_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	; get the low word of total number of records in database file

	mov	bx, IGNR_Local.ISF_cacheBlock	; bx - handle of cache block
        call	InputCacheGetChar		; read in a character  	
	jc	exit				; exit if error
	mov	ah, al
        call	InputCacheGetChar		; read in a character  	
	jc	exit				; exit if error
	xchg	al, ah
	mov	IGNR_Local.ISF_numRecords.low, ax	; save low word

	; get the high word of total number of records in database file

        call	InputCacheGetChar		; read in a character  	
	jc	exit				; exit if error
	mov	ah, al
        call	InputCacheGetChar		; read in a character  	
	jc	exit				; exit if error
	xchg	al, ah
	mov	IGNR_Local.ISF_numRecords.high, ax	; save high word
	clc
exit:
	.leave
	ret
ImportGetNumRecords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetRecordSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the record size info from the header block.

CALLED BY:	INTERNAL (ImportParseHeader)

PASS:		ImpexStackFrame

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx

SIDE EFFECTS:	bx - handle of cache block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetRecordSize	proc	near
        IGRS_Local	local	ImpexStackFrame
	IGRS_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	; get the size of one record

	mov	bx, IGRS_Local.ISF_cacheBlock	
        call	InputCacheGetChar		; get low byte
	jc	exit				; exit if error
	mov	ah, al
        call	InputCacheGetChar		; get high byte
	jc	exit				; exit if error
	xchg	al, ah
	mov	IGRS_Local.ISF_recordSize, ax	; save record size
	clc
exit:
	.leave
	ret
ImportGetRecordSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetHeaderSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of header from the header block.

CALLED BY:	INTERNAL (ImportParseHeader)

PASS:		ImpexStackFrame

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx

SIDE EFFECTS:	bx - handle of cache block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetHeaderSize	proc	near
        IGHS_Local	local	ImpexStackFrame
	IGHS_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	; get the size of header

	mov	bx, IGHS_Local.ISF_cacheBlock	
        call	InputCacheGetChar		
	jc	exit				; exit if error
	mov	ah, al
        call	InputCacheGetChar		
	jc	exit				; exit if error
	xchg	al, ah
	mov	IGHS_Local.ISF_headerSize, ax	; save it
	mov	IGHS_Local.ISF_curHeaderSize, ax
	clc
exit:
	.leave
	ret
ImportGetHeaderSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetFieldDescriptor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the field descriptor and store it with meta file. 

CALLED BY:	INTERNAL (ImportParseHeader)

PASS:		dx - current column number

RETURN:		ImpexStackFrame
		carry set if current field is mapped (ax = TE_NO_ERROR) 
		carry also set if erorr (ax = TE_FILE_ERROR) 

DESTROYED:	ax, bx, cx, si, di, es, ds

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetFieldDescriptor	proc	near
        IGFD_Local	local	ImpexStackFrame
	IGFD_SSMeta 	local	SSMetaStruc
	.enter	inherit near	

	push	dx

	; allocate a block for storing field property

	mov	ax, size FieldInfoBlock	; ax - size of block to allocate
	mov     cx, ((mask HAF_LOCK or mask HAF_ZERO_INIT or \
			mask HAF_NO_ERR) shl 8) or 0	; HeapAllocFlags
	call	MemAlloc		; allocate a block
	mov	IGFD_Local.ISF_fieldDcptrBlock, bx	; save the handle
	mov	es, ax
	clr	di			; es:di - ptr to FieldProperty struct
	mov	es:[di].FIB_fieldNum, dl; save the column number

        call	ImportGetFieldName	; copy field name into FieldProperty
	LONG	jc	fileErr		; exit if file error
	call	ImportGetFieldType	; get the field type byte
	LONG	jc	fileErr		; exit if file error

	mov	cx, FIELD_DATA_ADDR
	call	ImportSkipBytes		; skip four bytes
	LONG	jc	fileErr		; exit if file error

	; get the field length

        call	InputCacheGetChar	
	LONG	jc	fileErr		; exit if file error
	clr	ah
	mov	IGFD_Local.ISF_fieldLength, ax

	; check to see if this is a logic field

	cmp	IGFD_Local.ISF_fieldType, 'L'
	jne	notLogic		; if not, skip

	; since in GeoFile this field would contain more than
	; one character, use the default logic fied size, which is 32

	mov	al, LOGIC_FIELD_SIZE	
notLogic:
	mov	es:[di].FIB_fieldSize, ax	; save it

	; get decimal count for interger field

        call	InputCacheGetChar		
	LONG	jc	fileErr		; exit if file error

	; check to see if this is a numeric field

	cmp	IGFD_Local.ISF_fieldType, 'N'
	jne	notInteger		; if not a numeric field, skip

	; check to see if the decimal count is zero

	tst	al
	je	notInteger		; if zero, then integer field

	; if not zero, then treat this field as a float field

	mov	es:[di].FIB_fieldType, FDT_REAL	
	mov     IGFD_Local.ISF_fieldType, 'F'
notInteger:
	mov	cx, RESERVED2
	call	ImportSkipBytes			; skip four bytes
	jc	fileErr				; exit if file error

	; get true column number after the field has been mapped

	clr	ah
	mov	al, es:[di].FIB_fieldNum	; ax - column number
	mov	bx, IGFD_Local.ISF_mapBlock	; bx - handle of map block
        mov     cl, mask IF_IMPORT              ; do import
	call	GetMappedRowAndColNumber	; ax - mapped column number
	jnc	empty				; skip if not mapped

	; add FieldInfoBlock to DAS_FIELD data array 

	;mov	bx, IGFD_Local.ISF_notMappedList
	;call	ImportGetActualColumnNumber
	mov	IGFD_SSMeta.SSMDAS_col, ax
	mov	IGFD_SSMeta.SSMDAS_row, 0	; row number
	mov	IGFD_SSMeta.SSMDAS_dataArraySpecifier, DAS_FIELD
	segmov	ds, es				; ds:si - ptr to data
	clr	si
	mov	cx, size FieldInfoBlock		; cx - size of block

	mov	al, SSMAEF_ADD_IN_ROW_ORDER	; al - SSMetaAddEntryFlags

	; check to see if there is map block

	tst	IGFD_Local.ISF_mapBlock
	jne	mapExists			; skip if it exists

	; if no map block, append the cell at the end

	mov	al, SSMETA_ADD_TO_END		; al - SSMetaAddEntryFlags
mapExists:
	push	bp
	mov	dx, ss
	lea	bp, IGFD_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayAddEntry		; add the new entry
	pop	bp
	stc
empty:
	pop	dx
	pushf

	; lock the data block with FieldHeaderInfo

	push	dx
	mov	bx, IGFD_Local.ISF_fieldInfoBlock	
	call	MemLock	
	mov	es, ax
	mov	ax, size FieldHeaderInfo 
	mul	dx
	mov	di, ax				; es:di - place to insert

	; update the FieldHeaderInfo for this field

	mov	al, IGFD_Local.ISF_fieldType
	mov	es:[di].FHI_type, al
	mov	ax, IGFD_Local.ISF_fieldLength
	mov	es:[di].FHI_length, ax
	call	MemUnlock			; unlock the data block

	; free FieldProperty block

	mov	bx, IGFD_Local.ISF_fieldDcptrBlock
	call	MemFree
	pop	dx
	popf
	jnc	exit				; if carry not set, exit 

	; carry is set but here it means that current field is
	; being mapped.  So return with ax = TE_NO_ERROR 

	mov	ax, TE_NO_ERROR			; ax - TransError
	jmp	exit

	; handle the error case
fileErr:
	pop	dx
	mov	bx, IGFD_Local.ISF_fieldDcptrBlock
	call	MemFree
	mov	ax, TE_FILE_ERROR		; ax - TransError
	stc					; return with carry set
exit:
	.leave
	ret
ImportGetFieldDescriptor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the field name into FieldInfoBlock block.

CALLED BY:	INTERNAL (ImportGetFieldDescriptor)

PASS:		es - address of FieldInfoBlock block

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, cx

SIDE EFFECTS:	bx - handle of cache block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetFieldName	proc	near	uses	di
        IGFN_Local	local	ImpexStackFrame
	IGFN_SSMeta 	local	SSMetaStruc
	.enter	inherit near	

	; copy the field name into FieldInfoBlock block

	mov	di, offset FIB_fieldName; es:di - destination
	mov	cx, FIELD_NAME_SIZE	; cx - number of bytes to copy
	mov	bx, IGFN_Local.ISF_cacheBlock	
nextChar:
        call	InputCacheGetChar	; read in a character		
	jc	exit			; exit if error
	stosb				; store it
	loop	nextChar		; get the next character
	clc
exit:
	.leave
	ret
ImportGetFieldName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetFieldType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in field type byte and convert it to FieldDataType. 

CALLED BY:	INTERNAL (ImportGetFieldDescriptor)

PASS:		es:di - ptr to FieldInfoBlock block

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx

SIDE EFFECTS:	al - FieldDataType
		bx - handle of cache block

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetFieldType	proc	near
        IGFT_Local	local	ImpexStackFrame
	IGFT_SSMeta 	local	SSMetaStruc
	.enter	inherit near	

	; read in the field type byte from the header block

	mov	bx, IGFT_Local.ISF_cacheBlock	
        call	InputCacheGetChar	
	jc	exit				; exit if error
	mov	IGFT_Local.ISF_fieldType, al	; save it

	; check to see if character field type

	cmp	al, 'C'
	jne	checkNum
	mov	al, FDT_GENERAL_TEXT 		; assign FDT_GENERAL_TEXT
	jmp	common

	; check to see if numeric field type
checkNum:
	cmp	al, 'N'
	jne	checkLogic

	mov	al, FDT_INTEGER 		; assume integer field
	mov	es:[di].FIB_minValue.F_exponent, FP_NAN
	mov     es:[di].FIB_maxValue.F_exponent, FP_NAN
	jmp	common

	; check to see if logical field type
checkLogic:
	cmp	al, 'L'
	jne	checkMemo
	mov	al, FDT_GENERAL_TEXT 		; convert it into text field
	jmp	common
		
	; check to see if memo field type
checkMemo:
	cmp	al, 'M'
	jne	date
	mov	al, FDT_GENERAL_TEXT 		; convert it into text field
	jmp	common

	; check to see if date field type
date:
	cmp	al, 'D'
	je	ok
	stc					; if not 'D'
	jmp	exit				; exit with carry set
ok:
	mov	al, FDT_DATE
	mov	es:[di].FIB_minValue.F_exponent, FP_NAN
	mov     es:[di].FIB_maxValue.F_exponent, FP_NAN
common:
	mov	es:[di].FIB_fieldType, al	; save FieldDataType
	clc
exit:
	.leave
	ret
ImportGetFieldType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportParseData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in data portion of import file.

CALLED BY:	INTERNAL (TransImport)

PASS:		ImpexStackFrame

RETURN:		carry set if there was an error (ax = TransError)

DESTROYED:	bx, cx, dx, es, ds, si, di

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportParseData		proc	near
        IPD_Local	local	ImpexStackFrame
	IPD_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	clr	ax
	mov	IPD_SSMeta.SSMDAS_entryPos.high, ax
	mov	IPD_SSMeta.SSMDAS_entryPos.low, ax

	; allocate a block for storing field data

	mov	ax, FIELD_BLOCK_SIZE		; ax - size of block to allocate
	mov     cx, (HAF_STANDARD_NO_ERR shl 8) or 0	; HeapAllocFlags
	call	MemAlloc			; allocate a block
	mov	IPD_Local.ISF_fieldBlock, bx 	; save the handle of this block 

	mov	cx, IPD_Local.ISF_numRecords.low; cx - record loop counter
	clr	IPD_Local.ISF_curRecord
nextEntry:
	; save the entry position 

	mov	ax, IPD_SSMeta.SSMDAS_entryPos.high
	mov	IPD_Local.ISF_entryPos.high, ax
	mov	ax, IPD_SSMeta.SSMDAS_entryPos.low
	mov	IPD_Local.ISF_entryPos.low, ax

	push	cx
	clr	IPD_Local.ISF_curNumFields	; init. current column number
	mov	cx, IPD_Local.ISF_numFields	; cx - field loop counter
	clr	di			; di - offset to FieldHeaderInfo block

	; initialize ISF_curRecSize

	mov	ax, IPD_Local.ISF_recordSize
	mov	IPD_Local.ISF_curRecSize, ax

	; get the first character of field data

	mov	bx, IPD_Local.ISF_cacheBlock	; bx - handle of cache block
        call	InputCacheGetChar		
	jc	fileErr

	dec	IPD_Local.ISF_curRecSize	; update current record size
	cmp	al, SPACE			; record deleted?  
	je	nextField			; if not, read in data

	cmp	al, ASTERISK			; deleted record?
	je	delete				; if so, skip

	tst	al				; if zero, 
	je	delete				; treat it as a deleted entry

	stc					; carry set
	jmp	fileErr				; if not, file error
delete:
	; this record has been deleted, just skip it

        mov	cx, IPD_Local.ISF_curRecSize	; cx - # of bytes to skip
	call	ImportSkipBytes			; skip the entire field
	jc	fileErr
	jmp	next
nextField:
	; lock FieldHeaderInfo data block

	push	cx
	mov	bx, IPD_Local.ISF_fieldInfoBlock	
	call	MemLock	
	mov	es, ax

	; get field length, field type, and decimal count

	push	di
	mov	ax, es:[di].FHI_length
	mov	IPD_Local.ISF_fieldLength, ax
	mov	al, es:[di].FHI_type
	mov	IPD_Local.ISF_fieldType, al
	call	MemUnlock

	; read in the field data and add it to ssmeta file 

	call	ImportGetFieldData		; get field data
	jc	fileErr0			; exit if file error 
	call	ImportAddFieldToArray		; add it to huge array 
	pop	di				; dx - ptr to FieldHeaderInfo 
	add	di, size FieldHeaderInfo	; update the pointer
	inc	IPD_Local.ISF_curNumFields	; update column number

	; figure out how many bytes are left in current record

	mov	ax, IPD_Local.ISF_fieldLength	; ax - current field length
	sub	IPD_Local.ISF_curRecSize, ax
	pop	cx
	loop	nextField			; check the next field

	; check for record size error

	tst	IPD_Local.ISF_curRecSize
	je	okay
	stc
	jmp	fileErr				; exit if file error
okay:
	inc	IPD_Local.ISF_curRecord		; update row number
next:
	pop	cx
	dec	cx
	LONG	jne	nextEntry		; check the next record
	clc					; exit with carry clear	
	jmp	exit

	; restore the stack and delete some mem blocks

fileErr0:
	pop	di
	pop	cx
fileErr:
	pop	cx
exit:
	pushf
	mov	bx, IPD_Local.ISF_fieldInfoBlock	
	call	MemFree	
	mov	bx, IPD_Local.ISF_fieldBlock 
	call	MemFree	
	popf
	jnc	done				; exit if carry not set

	; if carry is set, ax = TransError

	mov     ax, TE_FILE_ERROR               ; ax - TransError
done:
	.leave
	ret
ImportParseData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetFieldData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in field data 

CALLED BY:	INTERNAL (ImportParseData)

PASS:		nothing

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, cx, dx, es, ds, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetFieldData	proc	near		
        IGFD_Local  	local	ImpexStackFrame
	IGFD_SSMeta	local	SSMetaStruc
	.enter	inherit near

	; lock the field data block

	mov	bx, IGFD_Local.ISF_fieldBlock 
	call	MemLock	
	mov	es, ax
	clr	di

	; initialize CellCommon 
	
	mov	al, 0
	mov	cx, size CellCommon	; cx - number of bytes to initialize
	rep	stosb			; clear the header
	clr	di			; restore the pointer
	
	; check to see if this is a text field

	mov	al, IGFD_Local.ISF_fieldType 
	cmp	al, 'C'
	jne	checkNum
	call	ImportTextField		; if text field, handle it
	jmp	common
	
	; check to see if this is a numeric field
checkNum:
	cmp	al, 'N'
	jne	checkFloat
	call	ImportNumericField	; if numeric field, handle it
	jmp	common

	; check to see if this is a float field
checkFloat:
	cmp	al, 'F'
	jne	checkLogic
	call	ImportNumericField	; call the same routine as 'N'
	jmp	common

	; check to see if this is a logical field
checkLogic:
	cmp	al, 'L'
	jne	checkMemo
	call	ImportLogicField	; if logical field, handle it
	jmp	common

	; check to see if this is a memo field
checkMemo:
	cmp	al, 'M'
	jne	date
	call	ImportMemoField		; if memo field, handle it
	jmp	common
date:
	; check to see if this is a date field

	cmp	al, 'D'
	je	dateField
	stc				; if not date field, exit with error
	jmp	common
dateField:
	call	ImportDateField		; if date field, handle it
common:
	pushf
	mov	bx, IGFD_Local.ISF_fieldBlock 
	call	MemUnlock	
	popf

	.leave
	ret
ImportGetFieldData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in text field data

CALLED BY:	INTERNAL (ImportGetFieldData)

PASS:		es:di - ptr to read field data into

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, cx	

SIDE EFFECTS:	di - size of field data

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportTextField		proc	near
	ITF_Local  	local	ImpexStackFrame
	ITF_SSMeta	local	SSMetaStruc
	.enter	inherit near

	mov	es:[di].CC_type, CT_TEXT	; this is a text field 
	add	di, size CellCommon		; es:di - ptr to destination
	mov	bx, ITF_Local.ISF_cacheBlock	; bx - handle of cache block
	mov	cx, ITF_Local.ISF_fieldLength	; cx - number of bytes to copy
	jcxz	exit
nextChar:
	call	InputCacheGetChar		; get a character
	jc	error				; exit if error
	stosb					; copy it to field block
	loop	nextChar			; read in the next character
 
	; At this point, the buffer has been filled with the field's
	; text.  Now scan backwards, looking for the first non-space
	; character.

	mov     cx, ITF_Local.ISF_fieldLength   ; cx <- number of bytes to scan
	mov     al, C_SPACE			; Looking for a space char
	dec     di				; di <- last char in string
 
	std					; we're scanning backwards
	repz scasb				; do the scan
	cld					; reset the direction flag
	jz      allSpaces			; jump if there were
						; nothing but spaces
	inc     di				; di <- last non-space char
allSpaces:
	inc     di				; di <- last non-space char + 1
exit:
	mov	al, 0
	stosb					; null terminate the data block
	sub	di, size CellCommon		; di - size of field data
	mov	ITF_Local.ISF_sizeFieldData, di ; save it 
	clc
error:
	.leave
	ret
ImportTextField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportNumericField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in a numeric field data

CALLED BY:	INTERNAL (ImportGetFieldData)

PASS:		es:di - ptr to read field data into

RETURN:		carry set if there was an error

DESTROYED:	ax, bx, cx, ds, si, di 

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	1/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportNumericField	proc	near
	INF_Local  	local	ImpexStackFrame
	INF_SSMeta	local	SSMetaStruc
	.enter	inherit near

	mov	es:[di].CC_type, CT_CONSTANT	; this is a numeric field 
	add	di, size CellCommon		; es:di - destination

	; allocate a temporary block 

	mov	ax, INF_Local.ISF_fieldLength	; ax - size of ascii string
	mov     cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0 ; HeapAllocFlags
	push	ax
	call	MemAlloc			; allocate a block
	pop	cx
	push	bx				; save the handle
	mov	ds, ax
	clr	si				

	; copy the numeric string into the data block

	mov	bx, INF_Local.ISF_cacheBlock	
next:
	call	InputCacheGetChar		; read in a character
	jc	error				; exit if error
	mov	ds:[si], al
	inc	si
	loop	next

	; convert the ascii string to float number

	mov	cx, INF_Local.ISF_fieldLength	; cx - size of ascii string
	clr	si				; ds:si - ptr to string
	mov	al, mask FAF_STORE_NUMBER	; al - FloatAsciiToFloatFlags
	call	FloatAsciiToFloat		; returns FloatNum in es:di
	clc					; no error

	; delete the temporary data block
error:
	pop	bx
	pushf
	call	MemFree
	mov	INF_Local.ISF_sizeFieldData, size FloatNum ; save size  
	popf					

	.leave
	ret
ImportNumericField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportLogicalField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in logical field data

CALLED BY:	INTERNAL (ImportGetFieldData)

PASS:		es:di - ptr to read field data into

RETURN:		carry set if there was an error

DESTROYED:	ax, bx, si, di, ds 

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportLogicField	proc	near
	ILF_Local  	local	ImpexStackFrame
	ILF_SSMeta	local	SSMetaStruc
	.enter	inherit near

	mov	es:[di].CC_type, CT_TEXT	; this is a text field 
	add	di, size CellCommon		; es:di - destination

	; get logic field data

	mov	bx, ILF_Local.ISF_cacheBlock	
	call	InputCacheGetChar
	jc	exit				; exit if error

	; check to see if it is empty

	cmp	al, SPACE
	jne	checkYes
	mov	di, 1				 ; empty field
	jmp	empty

	; check to see if "Yes" 
checkYes:
	cmp	al, 'Y'
	jne	checkNo
	mov	si, offset ImportYesString
	jmp	common

	; check to see if "No" 
checkNo:
	cmp	al, 'N'
	jne	checkTrue
	mov	si, offset ImportNoString
	jmp	common

	; check to see if "True" 
checkTrue:
	cmp	al, 'T'
	jne	checkFalse
	mov	si, offset ImportTrueString
	jmp	common

	; check to see if "False" 
checkFalse:
	cmp	al, 'F'
	je	noError
	stc				; if not 'F', then exit with 
	jmp	exit			; carry set
noError:
	mov	si, offset ImportFalseString

	; locate the string to copy
common:
	mov	bx, handle Strings
	call	MemLock	
	mov	ds, ax
	mov	si, ds:[si]		; ds:si - source string

	; copy the string
next:
	lodsb
	stosb
	tst	al
	jne	next

	call	MemUnlock
	sub	di, size CellCommon		; di - size of field data
empty:
	mov	ILF_Local.ISF_sizeFieldData, di ; save it 
	clc					; no error
exit:
	.leave
	ret
ImportLogicField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportMemoField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in a memo field data

CALLED BY:	INTERNAL (ImportGetFieldData)

PASS:		es:di - ptr to read field data into

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, cx

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportMemoField		proc	near
	IMF_Local  	local	ImpexStackFrame
	IMF_SSMeta	local	SSMetaStruc
	.enter	inherit near

	; skip the memo field for now

	mov	cx, IMF_Local.ISF_fieldLength	
	mov	bx, IMF_Local.ISF_cacheBlock	
next:
	call	InputCacheGetChar
	jc	exit				; exit if file error
	loop	next

	mov	IMF_Local.ISF_sizeFieldData, 1	; empty field 
	clc
exit:
	.leave
	ret
ImportMemoField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportDateField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in a date field data

CALLED BY:	INTERNAL (ImportGetFieldData)

PASS:		es:di - ptr to read field data into

RETURN:		carry set if there was an error 

DESTROYED:	ax, bx, cx, si, di 

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	9/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportDateField		proc	near
	IDF_Local  	local	ImpexStackFrame
	IDF_SSMeta	local	SSMetaStruc
	.enter	inherit near

	mov	es:[di].CC_type, CT_CONSTANT	; this is a constant field 
	add	di, size CellCommon		; es:di - destination

	; initialize the floating point stack

	mov	ax, FP_DEFAULT_STACK_SIZE
	mov	bl, FLOAT_STACK_DEFAULT_TYPE
	call	FloatInit

	; allocate a temporary block 

	mov	ax, IDF_Local.ISF_fieldLength	; ax - size of ascii string
	mov     cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0 ; HeapAllocFlags
	push	ax
	call	MemAlloc			; allocate a block
	pop	cx
	push	bx				; save the handle
	mov	ds, ax
	clr	si				

	; copy year into this temporary data block

	mov	cx, DATE_YEAR_SIZE		; read in four bytes
	mov	bx, IDF_Local.ISF_cacheBlock	
next:
	call	InputCacheGetChar		
	LONG	jc	exit			; exit if file error
	mov	ds:[si], al
	inc	si
	loop	next
	mov	byte ptr ds:[si], 0		; null terminate the string

	clr	si
	call	UtilAsciiToHex32		; conver year to hex number
	jc	error1
	mov	cx, ax				; save the result

	; copy month into the data block

	call	InputCacheGetChar		
	jc	exit				; exit if file error
	mov	ds:[si], al
	call	InputCacheGetChar		
	jc	exit				; exit if file error
	mov	ds:[si+1], al
	mov	byte ptr ds:[si+2], 0
	call	UtilAsciiToHex32		; convert month to hex number
	jc	error2
	push	ax				; save the result

	; copy date into the data block

	call	InputCacheGetChar		
	jc	fileErr0			; exit if file error
	mov	ds:[si], al
	call	InputCacheGetChar		
	jc	fileErr0			; exit if file error
	mov	ds:[si+1], al
	call	UtilAsciiToHex32		; convert date to hex number
	pop	bx
	jc	error3
	mov	bh, al
	mov	ax, cx

	; conver the ascii string to float number
	; ax - year 	bl - month 	bh - date

	call	FloatGetDateNumber		; conver the string
	jc	error3				; exit if error

	; pop the float number from the floating point stack

	call	FloatPopNumber
	mov	IDF_Local.ISF_sizeFieldData, size FloatNum ; save size info 
	clc					; no error
	jmp	exit
error1:
	; read in the rest of date field data

	call	InputCacheGetChar		
	jc	exit				; exit if file error
	call	InputCacheGetChar		
	jc	exit				; exit if file error
error2:
	call	InputCacheGetChar		
	jc	exit				; exit if file error
	call	InputCacheGetChar		
	jc	exit				; exit if file error
error3:
	mov	IDF_Local.ISF_sizeFieldData, 1  ; empty field
	clc					; no error
	jmp	exit
fileErr0:
	pop	ax
exit:
	; delete the temporary data block

	pop	bx
	pushf
	call	MemFree
	call	FloatExit			; destory the stack
	popf

	.leave
	ret
ImportDateField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportAddFieldToArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new field to the huge array.

CALLED BY:	ImportTransferFile

PASS:		cx - number of bytes in the string 

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, es, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportAddFieldToArray		proc	near	uses	ds, bp
	IAFTA_Local  	local	ImpexStackFrame
	IAFTA_SSMeta 	local	SSMetaStruc
	.enter	inherit near

	cmp	IAFTA_Local.ISF_sizeFieldData, 1; empty field?
	je	exit				; exit if so

	; get true column number after the field has been mapped

	mov	ax, IAFTA_Local.ISF_curNumFields ; ax - column number
	mov	bx, IAFTA_Local.ISF_mapBlock	; bx - handle of map block
        mov     cl, mask IF_IMPORT              ; do import
	call	GetMappedRowAndColNumber	; returns ax - mapped col num
	jnc	exit				; exit if not mapped

	; stuff stack frame with the new coordinate and array type

	;mov	bx, IAFTA_Local.ISF_notMappedList
	;call	ImportGetActualColumnNumber
	mov	IAFTA_SSMeta.SSMDAS_col, ax
	mov	ax, IAFTA_Local.ISF_curRecord
	mov	IAFTA_SSMeta.SSMDAS_row, ax
	mov	IAFTA_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	bx, IAFTA_Local.ISF_fieldBlock	; bx - handle of field block
	call	MemLock
	segmov	ds, ax				; ds:si - ptr to data
	clr	si
	mov	cx, IAFTA_Local.ISF_sizeFieldData; cx - size of cell data
	add	cx, size CellCommon		; adjust size of cell data

	mov	al, SSMETA_ADD_TO_END		; al - SSMetaAddEntryFlags

	tst	IAFTA_Local.ISF_mapBlock	; does map block exist?
	je	noMap				; skip if no map block 

	; if map block exists, just add the entry to its correct position

	mov	ax, IAFTA_Local.ISF_entryPos.high
	mov	IAFTA_SSMeta.SSMDAS_entryPos.high, ax
	mov	ax, IAFTA_Local.ISF_entryPos.low
	mov	IAFTA_SSMeta.SSMDAS_entryPos.low, ax
	mov	al, SSMAEF_ENTRY_POS_PASSED	; al - SSMetaAddEntryFlags
noMap:
	push	bp
	mov	dx, ss
	lea	bp, IAFTA_SSMeta		; dx:bp - SSMetaStruc
	call	SSMetaDataArrayAddEntry		; add the new entry
	pop	bp
	mov	bx, IAFTA_Local.ISF_fieldBlock	; bx - handle of field block
	call	MemUnlock			; free it!
exit:
	.leave
	ret
ImportAddFieldToArray		endp

Import	ends
