COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importCell.asm

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial revision

DESCRIPTION:
		
	$Id: importCell.asm,v 1.1 97/04/07 11:41:39 newdeal Exp $


-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessName

DESCRIPTION:	Process a Lotus Name record.

CALLED BY:	INTERNAL (ImportCallProcessingRoutine)

PASS:		ds:si - Lotus record
		ax - number of bytes in the record

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

ImportProcessName	proc	near
	locals	local	ImportStackFrame
	.enter	inherit near

	clc

	.leave
	ret
ImportProcessName	endp


if 0
COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessBlank

DESCRIPTION:	Process a Lotus Blank record.

CALLED BY:	INTERNAL (ImportCallProcessingRoutine)

PASS:		ds:si - Lotus record
		ax - number of bytes in the record

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

ImportProcessBlank	proc	near
	locals		local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	call	ImportTranslateCellHdr
	clc

	.leave
	ret
ImportProcessBlank	endp

endif

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessInteger

DESCRIPTION:	Process a Lotus Integer record.

CALLED BY:	INTERNAL (ImportCallProcessingRoutine)

PASS:		ds:si - Lotus record
		ax - number of bytes in the record

RETURN:		carry set if error
			ax - TransError (returned by ImportSaveNumber)

DESTROYED:	ax, bx, es, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportProcessInteger	proc	near
	locals		local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

if DBCS_PCGEOS	;1994-07-08(Fri)TOK ----------------
EC<	cmp	ax, 8 >	;print attribute byte exists in Japanese 1-2-3.
else	;----------------
EC<	cmp	ax, 7 >
endif	;----------------
EC<	ERROR_NE IMPEX_ASSUMING_INCORRECT_RECORD_SIZE >

	call	ImportTranslateCellHdr
	lodsw					; ax <- integer
	call	FloatWordToFloat		; fp stack <- fp num
	call	ImportSaveNumber

	.leave
	ret
ImportProcessInteger	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessNumber

DESCRIPTION:	Process a Lotus Number record.

CALLED BY:	INTERNAL (ImportCallProcessingRoutine)

PASS:		ds:si - Lotus record
		ax - number of bytes in the record

RETURN:		

DESTROYED:	ax, bx, es, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportProcessNumber	proc	near
	locals		local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near
;
; Commented this out because we are now treating number records as variable
; length, since QPro to 123 files use a longer record than 123. cassie 5/93
;
;EC<	cmp	ax, 13 >
;EC<	ERROR_NE IMPEX_ASSUMING_INCORRECT_RECORD_SIZE >

	call	ImportTranslateCellHdr		; ds:si <- IEEE 64 bit number
	call	FloatIEEE64ToGeos80		; fp stack <- number
	call	ImportSaveNumber
	jc	done
	add	si, FPSIZE_IEEE64
	clc
done:
	.leave
	ret
ImportProcessNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportSaveNumber

DESCRIPTION:	Common routine that initializes a CellConstant structure,
		grabs the number from the fp stack and stores the cell.

CALLED BY:	INTERNAL (ImportProcessInteger, ImportProcessNumber)

PASS:		fp num on fp stack

RETURN:		carry set if error
			ax - TransError

DESTROYED:	ax, bx, es, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportSaveNumber	proc	near
	locals	local	ImportStackFrame
	.enter	inherit near

	mov	ax, size CellConstant
	mov	bl, CT_CONSTANT
	call	ImportInitCellStruc		; bx <- mem handle,
	jc	done				; es:di <- info portion

	call	FloatPopNumber
	mov	ax, size CellConstant		; specify cell size
	call	ImportSaveCell			; destroys ax,es,di
	call	MemFree
	clc
done:
	.leave
	ret
ImportSaveNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessLabel

DESCRIPTION:	Process a Lotus Label record.

CALLED BY:	INTERNAL (ImportCallProcessingRoutine)

PASS:		ImportStackFrame
		ax - number of bytes in the record

RETURN:		carry set if error
			ax - TransError

DESTROYED:	ax, bx, es, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportProcessLabel	proc	near	uses	cx, dx
	locals		local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	sub	ax, size LotusCellInfo		; ax <- size of null-term text
	mov	cx, ax				; cx <- size
	cmp	cx, 2				; if no text, we're outta here
	jb	done

	;
	; It would probably be better to just truncate the text, but
	; for now, leave this here.  Actually, we should not run into this
	; case, since the max size of a Lotus 123 label is 245 bytes.
	;
;.assert (CELL_TEXT_BUFFER_SIZE lte 2*MAX_NAME_DEF_LENGTH)
	add	ax, size CellText
	mov	dx, ax				; dx <- Cell size
	cmp	dx, CELL_TEXT_BUFFER_SIZE
EC<	ERROR_A IMPEX_RECORD_TOO_LONG_TO_IMPORT 	>
NEC<	jna	notTooLong				>
NEC<	mov	ax, TE_IMPORT_ERROR			>
NEC<	stc						>
NEC<	jmp	exit					>
NEC<notTooLong:						>

	call	ImportTranslateCellHdr		; destroys ax,bx,es,di

	mov	ax, dx				; ax <- size to allocate
if DBCS_PCGEOS	;1994-07-06(Wed)TOK ----------------
	shl	ax
endif	;----------------
	mov	bl, CT_TEXT
	call	ImportInitCellStruc		; bx <- mem handle,
	jc	exit				; es:di <- info portion

	call	ImportTranslateLabelFormat	
	jc	exit
	
if DBCS_PCGEOS	;1994-07-06(Wed)TOK ----------------
	mov	ah, 00h
	stosw
else	;----------------
	stosb					; store label format char
endif	;----------------
	dec	cx				; subtract 1 char 

	push	dx
if DBCS_PCGEOS	;1994-08-11(Thu)TOK ----------------
	mov	dx, MAX_CELL_TEXT_SIZE - 1
else	;----------------
	mov	dx, MAX_CELL_TEXT_LENGTH-1		; subtract the format char
endif	;----------------
	call	ImportTranslateText
	pop	ax

if DBCS_PCGEOS	;1994-07-06(Wed)TOK ----------------
	add	di, 2	;di = text byte size(return from ImportTranslateText)
			;2 = format prefix byte size
	add	di, size CellText
	mov	ax, di
endif	;----------------
	call	ImportSaveCell			; destroys ax,es,di
	call	MemFree
done:
	clc
exit:
	.leave
	ret
ImportProcessLabel	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ImportTranslateLabelFormat

SYNOPSIS:	Translate Lotus label justification character

CALLED BY:	ImportProcessLabel

PASS:		ds:si	- Lotus record, pointing to label justification

RETURN:		ds:si	- updated to point to text
		carry set if invalid justification character encountered
			ax - TransError

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Since we don't translate any formatting or attribute info
	just yet, just translate all justification markers to the 
	single quote char.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/16/93		Initial version
-------------------------------------------------------------------------------@

ImportTranslateLabelFormat		proc	near
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsb				; al <- data

	cmp	al, 7ch			; printer command string parse format
	je	ok			;  ( | )
	cmp	al, 5ch			; repeating ( \ )
	je	ok
	cmp	al, 27h			; left justify ( ' )
	je	ok
	cmp	al, 22h			; right justify ( " )
	je	ok
	cmp	al, 5eh			; center ( ^ )
	je	ok
	stc
	mov	ax, TE_INVALID_FORMAT
	jne	exit
ok:
	clc
exit:
	.leave
	ret
ImportTranslateLabelFormat	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportProcessFormula

DESCRIPTION:	Process a Lotus Formula record.

CALLED BY:	INTERNAL (ImportCallProcessingRoutine)

PASS:

RETURN:		carry set if error
			ax - TransError

DESTROYED:	ax, bx, es, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportProcessFormula	proc	near
	locals		local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	call	ImportTranslateCellHdr
	mov	ax, SSM_local.SSMDAS_row

	;
	; Initialize a cell structure 
	;
;.assert (CELL_FORMULA_BUFFER_SIZE lte 2*MAX_NAME_DEF_LENGTH)
	mov	ax, CELL_FORMULA_BUFFER_SIZE
	mov	bl, CT_FORMULA
	call	ImportInitCellStruc		; bx <- mem handle,
	jc	exit				; es:di <- size CellCommon

	call	FloatIEEE64ToGeos80		; fp stack <- number
	add	si, FPSIZE_IEEE64		; ds:si <- stream past value
if DBCS_PCGEOS	;1994-07-12(Tue)TOK ----------------
	inc	si	;skip over print attribute byte(Japanese only)
endif	;----------------
	mov	di, offset CF_current		; es:di <- value portion
	call	FloatPopNumber			; get numeric value
	mov	di, size CellFormula		; es:di <- formula portion

	lodsw					; ax <- formula size

	call	ImportFormulaLotusPostfixToCalcInfix
	jc	done

	;-----------------------------------------------------------------------
	; fill in remaining fields in CellFormula
	mov	al, PARSER_TOKEN_END_OF_EXPRESSION
	ImportStosb
	jnc	noError
	;
	; if storing the last byte would overflow the buffer, the error 
	; function is stored at the beginning of the buffer. Now store
	; the end-of-expression token, which can be done using simple
	; stosb instead of the macro, because di has been adjusted and
	; now points to the front of the buffer.
	;
	mov	al, PARSER_TOKEN_END_OF_EXPRESSION
	stosb

noError:
	mov	es:[CF_return], RT_VALUE
;	mov	es:[CF_current], 

	mov	ax, di
	sub	ax, size CellFormula		; ax <- size of formula
	mov	es:[CF_formulaSize], ax
	add	ax, size CellFormula
	call	ImportSaveCell			; destroys ax,es,di
	clc
done:
	pushf
	call	MemFree
	popf
exit:
	.leave
	ret
ImportProcessFormula	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTranslateCellHdr

DESCRIPTION:	Translate the Lotus cell header contents - format, column and
		row.

CALLED BY:	INTERNAL (ImportProcess...)

PASS:		ds:si - cell
		ax - size of record

RETURN:		ds:si - updated

DESTROYED:	ax, bx, es, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportTranslateCellHdr	proc	near	uses	cx,dx
	locals		local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	lodsb				; al <- format
	call	ImportMapFormat

	lodsw				; cx <- column
	mov	SSM_local.SSMDAS_col, ax

	lodsw				; dx <- row
	mov	SSM_local.SSMDAS_row, ax

	.leave
	ret
ImportTranslateCellHdr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportMapFormat

DESCRIPTION:	

CALLED BY:	INTERNAL (ImportProcess...)

PASS:		

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

ImportMapFormat	proc	near
	ret
ImportMapFormat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportInitCellStruc

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ax - size of cell structure
		bl - CellType

RETURN:		bx - mem handle of cell structure
		es:di - pointer to data area of cell structure (caller
			should fill this in and call ImportSaveCell)
		carry set if can't alloc Cell structure
			ax - TE_OUT_OF_MEMORY

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImportInitCellStruc	proc	near	uses	cx
	.enter

	push	bx				; save CellType

	mov	cx, (mask HAF_LOCK or mask HAF_ZERO_INIT) shl 8 or \
		     mask HF_SWAPABLE
	call	MemAlloc
	jc	error
	mov	es, ax
	clr	di

	;
	; init CellCommon structure
	;
;	mov	es:[di].CC_dependencies, 0
	pop	ax				; retrieve CellType
	mov	es:[di].CC_type, al
;	mov	es:[di].CC_recalcFlags, 0
;	mov	es:[di].CC_attrs, 0
;	mov	es:[di].CC_notes, 0
	mov	di, size CellCommon
	clc
done:
	.leave
	ret

error:
	mov	ax, TE_OUT_OF_MEMORY
	jmp	done

ImportInitCellStruc	endp

