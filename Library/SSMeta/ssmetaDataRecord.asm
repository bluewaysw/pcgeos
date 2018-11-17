COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ssmetaDataRecord.asm

AUTHOR:		John Wedgwood, Nov  5, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/ 5/92	Initial revision

DESCRIPTION:
	Code for dealing with the ssmeta scrap as though it were a data-
	record. This code assumes:
		- SSMetaInitForPaste has already been called
		- The DAS_FIELD chain contains field names
		- The DAS_CELL chain contains cell data (see ssheet.def)
		- The DAS_STYLE chain contains style data

	$Id: ssmetaDataRecord.asm,v 1.2 98/03/24 21:39:55 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSMetaDataRecordCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaGetNumberOfDataRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of data-records.

CALLED BY:	Global
PASS:		dx:bp	= SSMetaStruc
RETURN:		ax	= Number of usable data-records
		carry set if error
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If field names (DAS_FIELD) exist, they will be used and the number
	of data records is the number of rows of cell data.

	If there are no field names, the first row of cells (DAS_CELL) will be
	used and the number of data records is the number of rows of cell
	data, minus 1 since the first is used for field names.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaGetNumberOfDataRecords	proc	far
	uses	di, es
	.enter
	movdw	esdi, dxbp			; es:di <- ptr to data
	
	;
	; Get the number of data-records.
	;
	mov	ax, es:[di].SSMDAS_scrapRows	; ax <- # of records
	tst	ax				; Check for none
	jz	error				; Branch if there aren't any
	
	call	CheckHasFieldNames		; carry set if there are fields
	jc	quit				; Branch if has field names
	
	;
	; The first row of data will be used as the field-names
	;
	dec	ax				; ax <- # of usable records
quit:
	clc
	jmp	exit
error:
	stc
exit:
	.leave
	ret
SSMetaGetNumberOfDataRecords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaResetForDataRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the SSMetaStruc for reading the data-records.

CALLED BY:	Global
PASS:		dx:bp	= SSMetaStruc
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaResetForDataRecords	proc	far
	uses	di, es
	.enter
	movdw	esdi, dxbp			; es:di <- ptr to data
	
	;
	; If there are no field names then we start reading at row zero,
	; otherwise we start reading at row one.
	;
	clr	es:[di].SSMDAS_row		; Assume has field names
	clr	es:[di].SSMDAS_col		; Assume has field names
	
	call	CheckHasFieldNames		; Check for having names
	jc	quit
	
	;
	; There are no fields, we are using the zero'th row as field names.
	;
	inc	es:[di].SSMDAS_row		; Start at the first row

quit:
	.leave
	ret
SSMetaResetForDataRecords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHasFieldNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if there are field names.

CALLED BY:	Utility
PASS:		es:di	= SSMetaStruc
RETURN:		carry set if there are field names
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHasFieldNames	proc	near
	uses	ax, bx
	.enter
	mov	bl, es:[di].SSMDAS_dataArraySpecifier

	mov	es:[di].SSMDAS_dataArraySpecifier, DAS_FIELD
	call	SSMetaDataArrayGetNumEntries	; ax <- Non-zero if field-names

	mov	es:[di].SSMDAS_dataArraySpecifier, bl
	
	;
	; ax = non-zero if there are field names
	;
	tst	ax				; Clears the carry
	jz	quit				; Branch if none
	stc					; Signal: has field names
quit:
	.leave
	ret
CheckHasFieldNames	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaFieldNameLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the text of a field name.

CALLED BY:	Global
PASS:		dx:bp	= SSMetaStruc
				SSMDAS_col = Field number
RETURN:		carry set if there is no field name
		carry clear otherwise
			ds:si	= Pointer to the text of the field name
					*NOT* null terminated
			ax	= Size of the text
			bx	= Block handle if a block was allocated to
				  hold the name
				= 0, if no block was allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaFieldNameLock	proc	far
	uses	dx, di, es
	.enter
	movdw	esdi, dxbp			; es:di <- ptr to data

	call	CheckHasFieldNames		; Check for field names
	jc	getFromFieldChain
	
	;
	; There are no field names. Use the zero'th row of data for field 
	; names.
	;
	push	es:[di].SSMDAS_row		; Save old row
	clr	es:[di].SSMDAS_row		; Use zero'th row...
	
	call	SSMetaDataRecordFieldLock	; Do all the work...

	pop	es:[di].SSMDAS_row		; Restore old row
quit:
	.leave
	ret


getFromFieldChain:
	;
	; Lock the n'th entry of the field chain.
	;
	
	;
	; Set the array to DAS_FIELD, saving the old specifier.
	;
	mov	dl, es:[di].SSMDAS_dataArraySpecifier
	mov	es:[di].SSMDAS_dataArraySpecifier, DAS_FIELD

	;
	; Get a pointer to the entry.
	;
	clr	bx				; We never need a block here

	mov	ax, es:[di].SSMDAS_col		; ax <- entry to get
	push	dx, bp
	movdw	dxbp, esdi			; dx:bp <- SSMetaStruc
	call	SSMetaDataArrayGetNthEntry	; carry set if none
	pop	dx, bp
						; ds:si <- ptr to SSMetaEntry
						; cx <- size of entry
	jc	afterField			; Branch if no field
	
	add	si, size SSMetaEntry		; ds:si <- ptr to data
	;
	; The field does exist.
	;
	push	es, di
	lea	si, ds:[si].FIB_fieldName	; ds:si <- ptr to field name

	segmov	es, ds, di			; es:di <- ptr to field name
	mov	di, si
	
	call	LocalStringSize			; cx <- Size of string
	pop	es, di
	
	mov	ax, cx				; ax <- size of string
	
	clc					; Signal: data does exist

afterField:
	;
	; Restore the entry, preserving ds, si, ax, and the flags.
	;
	mov	es:[di].SSMDAS_dataArraySpecifier, dl
	jmp	quit

SSMetaFieldNameLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaDataRecordFieldLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a field of the current data-record.

CALLED BY:	Global
PASS:		dx:bp	= SSMetaStruc
				SSMDAS_col = Field number
RETURN:		carry set if there is no field in this record
		carry clear otherwise
			ds:si	= Pointer to the text of the field data
					*NOT* null terminated
			ax	= Size of the text
			bx	= Block handle if a block was allocated to hold
				  the data.
				= 0, if no block was allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaDataRecordFieldLock	proc	far
	uses	cx, di, es
	.enter
	clr	bx				; Assume no data
	call	SSMetaDataArrayGetEntryByCoord	; ds:si <- ptr to data
						; cx <- size
	jc	quit				; branch if there is no data
	
	; There is data, we need to either reset our pointer, or else format
	; the data to a block which we allocate.
	
	call	SSMetaFormatCellText		; ds:si <- ptr to text
						; ax <- size of text
						; bx <- block (if any)
quit:
	.leave
	ret
SSMetaDataRecordFieldLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaFormatCellText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the text of a cell, allocating a block to hold the
		result, if necessary.

CALLED BY:	SSMetaDataRecordFieldLock
PASS:		dx:bp	= SSMetaStruc
		ds:si	= Ptr to SSMetaDataEntry structure (containing cell)
		cx	= Size of the structure
RETURN:		carry set if there is no field in this record
		carry clear otherwise
			ds:si	= Pointer to the text of the field data
					*NOT* null terminated
			ax	= Size of the text
			bx	= Block handle if a block was allocated to hold
				  the data.
				= 0, if no block was allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaFormatCellText	proc	far
	uses	cx
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif

	movdw	esdi, dxbp			; es:di <- ptr to data
	;
	; Get a pointer to the cell data.
	;
	lea	si, ds:[si].SSME_dataPortion
	sub	cx, size SSMetaEntry		; cx <- size of cell data
	
	;
	; Call a handler for each cell type.
	;
	clr	bh
	mov	bl, ds:[si].CC_type		; bx <- cell type

EC <	cmp	bx, CellType			>
EC <	ERROR_AE SSMETA_BAD_CELL_TYPE		>

	call	cs:formatCellHandlers[bx]	; Call the appropriate handler
	
	;
	; carry set if there is no data
	; carry clear otherwise
	;     ds:si	= Ptr to formatted text from cell (not NULL terminated)
	;     ax	= Size of formatted text
	;     bx	= Block handle of data, if block allocated
	;		= 0, otherwise
	;
	.leave
	ret


formatCellHandlers	word	\
	offset	cs:FormatTextCell,		; CT_TEXT
	offset	cs:FormatConstantCell,		; CT_CONSTANT
	offset	cs:FormatFormulaCell,		; CT_FORMULA
	offset	cs:FormatEmptyCell,		; CT_NAME
	offset	cs:FormatEmptyCell,		; CT_CHART
	offset	cs:FormatEmptyCell,		; CT_EMPTY
	offset	cs:FormatEmptyCell		; CT_DISPLAY_FORMULA

SSMetaFormatCellText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatTextCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell appropriately.

CALLED BY:	FormatCellText
PASS:		ds:si	= Pointer to cell
		cx	= Size of cell data
RETURN:		carry set if there is no data
		carry clear otherwise
			ds:si	= Pointer to formatted text
			ax	= Size of text
			bx	= Block handle if a block was allocated to hold
				  the data.
				= 0, if no block was allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatTextCell	proc	near
	uses	cx, di, es
	.enter
	segmov	es, ds, di			; es:di <- ptr to text
	lea	di, ds:[si].CT_text
	
	call	LocalStringSize			; cx <- size of string
	mov	ax, cx				; ax <- size of string
	
	mov	si, di				; ds:si <- ptr to text
	clr	bx				; No extra data, clears carry
	.leave
	ret
FormatTextCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatConstantCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell appropriately.

CALLED BY:	FormatCellText
PASS:		es:di	= Pointer to SSMetaStruc
		ds:si	= Pointer to cell
		cx	= Size of cell data
RETURN:		carry set if there is no data
		carry clear otherwise
			ds:si	= Pointer to formatted text
			ax	= Size of text
			bx	= Block handle if a block was allocated to hold
				  the data.
				= 0, if no block was allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatConstantCell	proc	near
	mov	ax, ds:[si].CC_attrs		; ax <- Attributes to use
	lea	si, ds:[si].CC_current		; ds:si <- ptr to the number
	call	FormatNumberIntoBlock		; Do all the real work.
	ret
FormatConstantCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatNumberIntoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a number into a block.

CALLED BY:	FormatConstantCell, FormatFormulaCell
PASS:		es:di	= Pointer to SSMetaStruc
		ds:si	= Pointer to a FloatNum
		ax	= Token of attribute entry to use
RETURN:		carry set if there is no number (not-a-number)
		carry clear if there is a number
			bx	= Block containing the formatted number
			ds:si	= Pointer to the block
			ax	= Size of the formatted number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatNumberIntoBlock	proc	near
	uses	cx, di, bp, es
	.enter
	;
	; Get the format information for the number.
	;
	call	GetFormatToken			; ax <- format to use
	jnc	gotFormatToken			; Branch if it exists
	mov	ax, FORMAT_ID_GENERAL		; Otherwise use something good
gotFormatToken:
	cmp	ax, FORMAT_ID_PREDEF		; user format?
	jb	userFormat			; branch if so

	call	AllocNumberBlock		; bx <- handle, es:di <- ptr
	call	FloatFormatNumber		; cx <- # of characters
afterFormat:
	jcxz	freeBlockNoData			; Branch if not-a-number
	
	;
	; All finished...
	;
	mov	ax, cx				; ax <- # of chars in buffer
DBCS<	shl	ax, 1				; ax <- buffer byte count    >
						; bx holds the block handle
	segmov	ds, es, si			; ds:si <- ptr to buffer
	clr	si				; Clears the carry

quit:
	.leave
	ret


freeBlockNoData:
	;
	; Some error was encountered. Return that there is no number.
	;
	call	MemFree				; Release the block

	clr	bx				; No data block
	clr	ax				; No data size
	stc					; Signal: no data
	jmp	quit

userFormat:
	call	UserFormatNumber
	jmp	afterFormat

FormatNumberIntoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocNumberBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block to format a number into

CALLED BY:	FormatNumberIntoBlock, UserFormatNumber()
PASS:		none
RETURN:		bx - block handle
		es:di - ptr to start of block
DESTROYED:	cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/16/98		broke out from FormatNumberIntoBlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocNumberBlock	proc	near
	uses	ax
	.enter

	;
	; Allocate the block.
	;
SBCS<	mov	ax, FLOAT_TO_ASCII_HUGE_BUF_LEN	; ax <- block size	>
DBCS<	mov	ax, FLOAT_TO_ASCII_HUGE_BUF_LEN*(size wchar)		>
	mov     cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or mask HF_SWAPABLE
	call	MemAlloc			; bx <- block
						; ax <- segment
	mov	es, ax				; es:di <- ptr to block
	clr	di

	.leave
	ret
AllocNumberBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserFormatNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a number using a user-defined format

CALLED BY:	FormatNumberIntoBlock
PASS:		es:di	- ptr to SSMetaStruc
		ds:si	- ptr to a FloatNum
		ax	- number format to use
RETURN:		carry set if no token exists
		carry clear otherwise
		  bx - block w/extra data
		  cx - # of chars, 0 if number is NAN
DESTROYED:	es, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/16/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserFormatNumber	proc	near
	uses	dx
ffa	local	FFA_stackFrame
	.enter

	call	GetUserFormat
	call	AllocNumberBlock		;bx <- handle, es:di <- ptr
	ornf	ss:ffa.FFA_float.FFA_params.formatFlags, mask FFAF_FROM_ADDR
	call	FloatFloatToAscii

	.leave
	ret
UserFormatNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUserFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a user defined format

CALLED BY:	UserFormatNumber
PASS:		es:di	- ptr to SSMetaStruc
		ss:dx	- ptr to FFA_stackFrame
		ax	- number format to use
RETURN:		ss:dx	- filled in
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/16/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetUserFormat	proc	near
	uses	bx, dx, ds, si
	.enter	inherit	UserFormatNumber

	mov	bl, es:[di].SSMDAS_dataArraySpecifier
	mov	es:[di].SSMDAS_dataArraySpecifier, DAS_FORMAT
	;
	; Extract the correct entry from the format array
	;
	push	bp
	movdw	dxbp, esdi			;dx:bp <- ptr to structure
	call	SSMetaDataArrayGetEntryByToken	;carry set if not found
						;ds:si <- ptr to entry
						;cx <- size of entry
	pop	bp				;ss:ax <- ptr to FFA_stackFrame
	jc	quit				;branch if not found
	;
	; ds:si <- ptr to FormatParams.FFAP_FLOAT = FloatFloatToAsciiParams
	;
	push	es, di
	lea	si, ds:[si].SSME_dataPortion
CheckHack <offset FP_params.FFAP_FLOAT eq 0>
	segmov	es, ss
	lea	di, ss:ffa			;es:di <- stack frame
CheckHack <offset FFA_float.FFA_params eq 0>
	mov	cx, (size FloatFloatToAsciiParams)	;cx <- # of bytes
	rep	movsb				;copy me
	pop	es, di
	;
	; Release the entry
	;
	push	bp
	movdw	dxbp, esdi			;dx:bp <- ptr to structure
	call	SSMetaDataArrayUnlock
	pop	bp
quit:
	mov	es:[di].SSMDAS_dataArraySpecifier, bl

	.leave
	ret
GetUserFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFormatToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the token to lookup in the format list.

CALLED BY:	GetNumberFormat
PASS:		es:di	= SSMetaStruc
		ax	= Attribute token
RETURN:		carry set if no token exists
		carry clear otherwise
			ax	= Format Token
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFormatToken	proc	near
	uses	bx, cx, dx, bp, si, ds
	.enter
	mov	bl, es:[di].SSMDAS_dataArraySpecifier
	mov	es:[di].SSMDAS_dataArraySpecifier, DAS_STYLE
	
	;
	; Extract the correct entry from the style array.
	;
	movdw	dxbp, esdi			; dx:bp <- ptr to structure
	call	SSMetaDataArrayGetEntryByToken	; carry set if not found
						; ds:si <- ptr to entry
						; cx <- size of entry
	jc	quit				; Branch if none
	
	;
	; The entry was found. Extract the format flags and release it.
	;
	lea	si, ds:[si].SSME_dataPortion
	mov	ax, ds:[si].CA_format		; ax <- format flags

	;
	; Release the entry.
	;
	call	SSMetaDataArrayUnlock
	
	clc					; Signal: format exists

quit:
	mov	es:[di].SSMDAS_dataArraySpecifier, bl
	.leave
	ret
GetFormatToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatFormulaCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell appropriately.

CALLED BY:	FormatCellText
PASS:		es:di	= Pointer to SSMetaStruc
		ds:si	= Pointer to cell
		cx	= Size of cell data
RETURN:		carry set if there is no data
		carry clear otherwise
			ds:si	= Pointer to formatted text
			ax	= Size of text
			bx	= Block handle if a block was allocated to hold
				  the data.
				= 0, if no block was allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatFormulaCell	proc	near
	cmp	ds:[si].CF_return, RT_VALUE	; Check for a number
	je	formatFormulaConstant		; Branch if it is

	cmp	ds:[si].CF_return, RT_TEXT	; Check for text
	je	formatFormulaText		; Branch if it is

	;
	; It must be an error (or something worse :-)
	; Pretend there's nothing there.
	; And unlock the cell, or it will stay locked.
	;
	call	FormatEmptyCell
quit:
	ret


formatFormulaConstant:
	;
	; Format a formula which evaluates to a constant.
	;
	mov	ax, ds:[si].CC_attrs		; ax <- Attributes to use
	lea	si, ds:[si].CF_current.RV_VALUE	; ds:si <- ptr to the number
	call	FormatNumberIntoBlock		; Do all the work
	jmp	quit


formatFormulaText:
	;
	; Get a pointer to the text result. The text string is stored
	; after the formula.
	;
	push	ds:[si].CF_current.RV_TEXT	; save size of text
	mov	ax, ds:[si].CF_formulaSize	; ax <- size of formula
	lea	si, ds:[si].CF_formula		; ds:si <- ptr to formula
	add	si, ax				; ds:si <- ptr to text
	pop	ax				; ax <- size of text
	
	clr	bx				; Signal: no extra block
	clc					; Signal: has data
	jmp	quit

FormatFormulaCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatEmptyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a cell appropriately.

CALLED BY:	FormatCellText
PASS:		ds:si	= Pointer to cell
		cx	= Size of cell data
RETURN:		carry set if there is no data
		carry clear otherwise
			ds:si	= Pointer to formatted text
			ax	= Size of text
			bx	= Block handle if a block was allocated to hold
				  the data.
				= 0, if no block was allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatEmptyCell	proc	near
	call	SSMetaDataArrayUnlock
	clr	bx				; No block
	stc					; No data
	ret
FormatEmptyCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaFieldNameUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a pointer to a field name

CALLED BY:	Global
PASS:		dx:bp	= SSMetaStruc as returned by SSMetaFieldNameLock
		bx	= Block handle returned by SSMetaFieldNameLock
RETURN:		nothing, preserves flags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaFieldNameUnlock	proc	far
	uses	bx, es, di
	pushf	
	.enter

	movdw   esdi, dxbp                      ; es:di <- ptr to data
	mov	al, es:[di].SSMDAS_dataArraySpecifier
	call    CheckHasFieldNames              ; Check for field names
	jnc	skip

        ;
	; Set the array to DAS_FIELD, saving the old specifier.
	;
	mov     es:[di].SSMDAS_dataArraySpecifier, DAS_FIELD
skip:
	;
	; First release the data.
	;
	push	ax
	call	SSMetaDataArrayUnlock		; Release the data
	pop	ax
	;
	; Restore the old specifier
	;
	mov     es:[di].SSMDAS_dataArraySpecifier, al
	;
	; Then free the block (if any).
	;
	tst	bx				; Check for no block
	jz	quit				; Branch if none
	
	;
	; There is a block...
	;
	call	MemFree
	
quit:
	.leave
	popf
	ret
SSMetaFieldNameUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSMetaDataRecordFieldUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a field of a data record.

CALLED BY:	Global
PASS:		dx:bp	= SSMetaStruc as returned by SSMetaDataRecordFieldLock
		bx	= Block handle returned by SSMetaDataRecordFieldLock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSMetaDataRecordFieldUnlock	proc	far
	uses	bx
	pushf	
	.enter
	;
	; First release the data.
	;
	call	SSMetaDataArrayUnlock		; Release the data
	
	;
	; Then free the block (if any).
	;
	tst	bx				; Check for no block
	jz	quit				; Branch if none
	
	;
	; There is a block...
	;
	call	MemFree
	
quit:
	.leave
	popf
	ret
SSMetaDataRecordFieldUnlock	endp

SSMetaDataRecordCode	ends
