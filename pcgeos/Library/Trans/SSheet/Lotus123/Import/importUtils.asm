
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial revision

DESCRIPTION:
		
	$Id: importUtils.asm,v 1.1 97/04/07 11:41:40 newdeal Exp $


-------------------------------------------------------------------------------@


if DBCS_PCGEOS	;1994-08-11(Thu)TOK ----------------
else	;----------------
;
; For use in translating LICS to GEOS character set
;
ImportTable	label	byte
	db	C_GRAVE			;0x80 uppercase grave
	db	C_ACUTE			;0x81 uppercase acute
	db	C_CIRCUMFLEX		;0x82 uppercase circumflex
	db	C_DIERESIS		;0x83 uppercase dieresis
	db	C_TILDE			;0x84 uppercase tilde
	db	C_PERIOD		;0x85
	db	C_PERIOD		;0x86
	db	C_PERIOD		;0x87
	db	C_PERIOD		;0x88
	db	C_PERIOD		;0x89
	db	C_PERIOD		;0x8a
	db	C_PERIOD		;0x8b
	db	C_PERIOD		;0x8c
	db	C_PERIOD		;0x8d
	db	C_PERIOD		;0x8e
	db	C_PERIOD		;0x8f
	db	C_GRAVE			;0x90 lowercase grave
	db	C_ACUTE			;0x91 lowercase acute
	db	C_CIRCUMFLEX		;0x92 lowercase circumflex
	db	C_DIERESIS		;0x93 lowercase dieresis
	db	C_TILDE			;0x94 lowercase tilde
	db	C_LI_DOTLESS		;0x95
	db	C_EMDASH		;0x96
	db	C_PERIOD		;0x97 solid up arrow
	db	C_PERIOD		;0x98 solid down arrow
	db	C_PERIOD		;0x99
	db	C_BULLET		;0x9a solid bullet
	db	C_PERIOD		;0x9b left arrow
	db	C_PERIOD		;0x9c
	db	C_PERIOD		;0x9d
	db	C_PERIOD		;0x9e
	db	C_PERIOD		;0x9f
	db	C_FLORIN		;0xa0
	db	C_EXCLAMDOWN		;0xa1
	db	C_CENT			;0xa2
	db	C_STERLING		;0xa3
	db	C_QUOTEDBLLEFT		;0xa4
	db	C_YEN			;0xa5
	db	C_CAP_D			;0xa6 peseta
	db	C_SECTION		;0xa7
	db	C_CURRENCY		;0xa8
	db	C_COPYRIGHT		;0xa9
	db	C_ORDFEMININE		;0xaa
	db	C_GUILLEDBLLEFT		;0xab
	db	C_U_DELTA		;0xac
	db	C_L_PI			;0xad
	db	C_GREATEREQUAL		;0xae
	db	C_DIVISION		;0xaf
	db	C_DEGREE		;0xb0
	db	C_PLUSMINUS		;0xb1
	db	C_TWO			;0xb2 superior numeral two
	db	C_THREE			;0xb3 superior numeral three
	db	C_QUOTEDBLRIGHT		;0xb4
	db	C_L_MU			;0xb5
	db	C_PARAGRAPH		;0xb6
	db	C_CNTR_DOT		;0xb7
	db	C_TRADEMARK		;0xb8
	db	C_ONE			;0xb9 superior numeral one
	db	C_ORDMASCULINE		;0xba
	db	C_GUILLEDBLRIGHT	;0xbb
	db	C_PERIOD		;0xbc 1/4
	db	C_PERIOD		;0xbd 1/2
	db	C_LESSEQUAL		;0xbe
	db	C_QUESTIONDOWN		;0xbf
	db	C_UA_GRAVE		;0xc0
	db	C_UA_ACUTE		;0xc1
	db	C_UA_CIRCUMFLEX		;0xc2
	db	C_UA_TILDE		;0xc3
	db	C_UA_DIERESIS		;0xc4
	db	C_UA_RING		;0xc5
	db	C_U_AE			;0xc6
	db	C_UC_CEDILLA		;0xc7
	db	C_UE_GRAVE		;0xc8
	db	C_UE_ACUTE		;0xc9
	db	C_UE_CIRCUMFLEX		;0xca
	db	C_UE_DIERESIS		;0xcb
	db	C_UI_GRAVE		;0xcc
	db	C_UI_ACUTE		;0xcd
	db	C_UI_CIRCUMFLEX		;0xce
	db	C_UI_DIERESIS		;0xcf
	db	C_CAP_D			;0xd0 uppercase D-strong, Eth
	db	C_UN_TILDE		;0xd1
	db	C_UO_GRAVE		;0xd2
	db	C_UO_ACUTE		;0xd3
	db	C_UO_CIRCUMFLEX		;0xd4
	db	C_UO_TILDE		;0xd5
	db	C_UO_DIERESIS		;0xd6
	db	C_U_OE			;0xd7
	db	C_UO_SLASH		;0xd8
	db	C_UU_GRAVE		;0xd9
	db	C_UU_ACUTE		;0xda
	db	C_UU_CIRCUMFLEX		;0xdb
	db	C_UU_DIERESIS		;0xdc
	db	C_UY_DIERESIS		;0xdd 
	db	C_CAP_P			;0xde uppercase Thorn
	db	C_GERMANDBLS		;0xdf
	db	C_LA_GRAVE		;0xe0
	db	C_LA_ACUTE		;0xe1
	db	C_LA_CIRCUMFLEX		;0xe2
	db	C_LA_TILDE		;0xe3
	db	C_LA_DIERESIS		;0xe4
	db	C_LA_RING		;0xe5
	db	C_L_AE			;0xe6
	db	C_LC_CEDILLA		;0xe7
	db	C_LE_GRAVE		;0xe8
	db	C_LE_ACUTE		;0xe9
	db	C_LE_CIRCUMFLEX		;0xea
	db	C_LE_DIERESIS		;0xeb
	db	C_LI_GRAVE		;0xec
	db	C_LI_ACUTE		;0xed
	db	C_LI_CIRCUMFLEX		;0xee
	db	C_LI_DIERESIS		;0xef
	db	C_SMALL_D		;0xf0 lowercase d-stroke, eth
	db	C_LN_TILDE		;0xf1
	db	C_LO_GRAVE		;0xf2
	db	C_LO_ACUTE		;0xf3
	db	C_LO_CIRCUMFLEX		;0xf4
	db	C_LO_TILDE		;0xf5
	db	C_LO_DIERESIS		;0xf6
	db	C_L_OE			;0xf7
	db	C_LO_SLASH		;0xf8
	db	C_LU_GRAVE		;0xf9
	db	C_LU_ACUTE		;0xfa
	db	C_LU_CIRCUMFLEX		;0xfb
	db	C_LU_DIERESIS		;0xfc
	db	C_LY_DIERESIS		;0xfd
	db	C_SMALL_P		;0xfe lowercase Thorn
	db	C_PERIOD		;0xff
endif	;----------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportTranslateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate from LICS to GEOS character set.

CALLED BY:	ImportProcessLabel
PASS:		cx - source text length, including NULL
		dx - max number or chars to store in the destination
		ds:si - source string
		es:di - destination buffer

RETURN:		al - last char written
DESTROYED:	ax,dx,si,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportTranslateText		proc	far
	uses	bx,cx
	.enter

if DBCS_PCGEOS	;1994-07-06(Wed)TOK ----------------
	push	ax
	push	bx
	push	dx
	push	ds
	push	si

	dec	cx	;subtract print attribute byte(Japanese only)
	dec	cx	;subtract NULL
	mov	ax, C_CTRL_A
	mov	bx, CODE_PAGE_SJIS
	clr	dx
	call	LocalDosToGeos

	mov	ax, es
	mov	ds, ax
	mov	ax, di
	mov	si, ax
	mov	dx, ax
Working:
	LocalGetChar ax, dssi
	LocalCmpChar ax, C_TAB
	jz	Store
	LocalCmpChar ax, C_CR
	jz	Store
	LocalCmpChar ax, C_PAGE_BREAK
	jz	Store
	LocalCmpChar ax, ' '
	jb	Skip
Store:
	LocalPutChar esdi, ax
Skip:
	loop	Working
	mov	ax, 0000h
	stosw	;store NULL
	sub	di, dx	;di = text byte size(return to ImportProcessLabel)

	pop	si
	pop	ds
	pop	dx
	pop	bx
	pop	ax
else	;----------------
	cmp	cx, dx
	jbe	okay
	mov	cx, dx
okay:
	dec	cx			; subtract NULL
	jcxz	nullText
	mov	bx, offset ImportTable	; assume we're importing

translate:	
	lodsb				; al <- byte of string
	shl	al			; see if high bit is set...
	jnc	noMap			; if not, byte is < 80h
	shr	al			; al = al - 80h
	cs:xlat				; translate the byte
	shl	al			; shift left for rcr below
noMap:
	rcr	al			; restore high bit of char
	stosb				; store the new char
	loop	translate		; loop until no more chars -OR-

nullText:
					;   end of buffer, whichever is less
	mov	al, 0			; store a NULL
	stosb
endif	;----------------

	.leave
	ret
ImportTranslateText		endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportTranslateFormat

DESCRIPTION:	Performs a best match translation of the Lotus format.

CALLED BY:	INTERNAL ()

PASS:		al - Lotus format

RETURN:		ax - GeoCalc format (FormatIdType)

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
ImportTranslateFormat	proc	near	uses	bx
	.enter
	;
	; mask out protection bit
	;
	and	al, not (mask LF_protection)
	clr	ah

	;
	; handle special formats seperately
	;
	mov	bx, ax
	and	bx, mask LF_special		; bx <- number of decimals /
						; special format type

	and	ax, not mask LF_special		; clear special field
	cmp	ax, mask LF_fmtType		; special format?
	je	specialFormat

	;-----------------------------------------------------------------------
	; map normal formats

	cmp	al, LOTUS_FORMAT_FIXED
	jne	checkScientific

	mov	ax, FORMAT_ID_FIXED
	jmp	short normalDone

checkScientific:
	cmp	al, LOTUS_FORMAT_SCIENTIFIC
	jne	checkCurrency

	mov	ax, FORMAT_ID_SCIENTIFIC
	jmp	short normalDone

checkCurrency:
	cmp	al, LOTUS_FORMAT_CURRENCY
	jne	checkPercent

	mov	ax, FORMAT_ID_CURRENCY
	jmp	short normalDone

checkPercent:
	cmp	al, LOTUS_FORMAT_PERCENT
	jne	checkComma

	mov	ax, FORMAT_ID_PERCENTAGE
	jmp	short normalDone

checkComma:
	cmp	al, LOTUS_FORMAT_COMMA
	jne	unknownFormat

	mov	ax, FORMAT_ID_FIXED_WITH_COMMAS

normalDone:
	;
	; if the number of decimals is non-standard, we will need to
	; define a new format...
	;
	cmp	bx, 2
	je	done

	jmp	short done

	;-----------------------------------------------------------------------
	; handle Lotus' special formats

specialFormat:
	cmp	al, LOTUS_FORMAT_PLUS_MINUS
	jne	checkGeneral

	mov	ax, FORMAT_ID_GENERAL
	jmp	short specialDone

checkGeneral:
	cmp	al, LOTUS_FORMAT_GENERAL
	jne	checkDMY

	mov	ax, FORMAT_ID_GENERAL
	jmp	short specialDone

checkDMY:
	cmp	al, LOTUS_FORMAT_DMY
	jne	checkDM

	mov	ax, mask FFDT_DATE_TIME_OP or DTF_LONG_NO_WEEKDAY_CONDENSED
	jmp	short specialDone

checkDM:
	cmp	al, LOTUS_FORMAT_DM
	jne	checkMY

	mov	ax, mask FFDT_DATE_TIME_OP or DTF_MD_LONG_NO_WEEKDAY
	jmp	short specialDone

checkMY:
	cmp	al, LOTUS_FORMAT_MY
	jne	checkText

	mov	ax, mask FFDT_DATE_TIME_OP or DTF_MY_LONG
	jmp	short specialDone

checkText:
	cmp	al, LOTUS_FORMAT_TEXT
	jne	unknownFormat

	;
	; unknown format, force general
	;
unknownFormat:
	mov	ax, FORMAT_ID_GENERAL

specialDone:

done:
	.leave
	ret
ImportTranslateFormat	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportTranslateFormat

DESCRIPTION:	Performs a best match translation of the GeoCalc format.

CALLED BY:	INTERNAL ()

PASS:		ax - GeoCalc format (FormatIdType)

RETURN:		al - Lotus format

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	FORMAT_ID_GENERAL
	FORMAT_ID_FIXED
	FORMAT_ID_FIXED_WITH_COMMAS
	FORMAT_ID_FIXED_INTEGER
	FORMAT_ID_CURRENCY
	FORMAT_ID_CURRENCY_WITH_COMMAS
	FORMAT_ID_CURRENCY_INTEGER
	FORMAT_ID_PERCENTAGE
	FORMAT_ID_PERCENTAGE_INTEGER
	FORMAT_ID_THOUSANDS
	FORMAT_ID_MILLIONS
	FORMAT_ID_SCIENTIFIC

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

if 0
ExportTranslateFormatPreDefLookup	label	byte
	byte	LOTUS_FORMAT_GENERAL
	byte	LOTUS_FORMAT_FIXED
	byte	LOTUS_FORMAT_COMMA
	byte	LOTUS_FORMAT_FIXED		; fixed int
	byte	LOTUS_FORMAT_CURRENCY
	byte	LOTUS_FORMAT_CURRENCY		; currency with commas
	byte	LOTUS_FORMAT_CURRENCY		; currency integer
	byte	LOTUS_FORMAT_PERCENT
	byte	LOTUS_FORMAT_PERCENT		; percentage integer
	byte	LOTUS_FORMAT_GENERAL		; thousands
	byte	LOTUS_FORMAT_GENERAL		; millions
	byte	LOTUS_FORMAT_SCIENTIFIC

ExportTranslateFormat	proc	near	uses	bx
	.enter

	test	ax, FORMAT_ID_PREDEF		; predef format?
	je	userDef

	sub	ax, FORMAT_ID_GENERAL		; ax <- 0 based
	mov	bx, ax
	add	bx, offset ExportTranslateFormatPreDefLookup
	mov	al, cs:[bx]
	jmp	short done

userDef:
	mov	al, LOTUS_FORMAT_GENERAL

done:
	.leave
	ret
ExportTranslateFormat	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportSaveCell

DESCRIPTION:	Save the cell contents in the cell data chain.

CALLED BY:	INTERNAL (TransImportProcessInteger)

PASS:		ax - size of cell structure
		es:0 - cell structure

RETURN:		

DESTROYED:	ax,es,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	SpreadsheetTransferCellItem	struct
		STCI_cellAttr	CellCommon
		... extra info
	SpreadsheetTransferCellItem	ends

	allocate mem
	transfer cell common info

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

ImportSaveCell	proc	near	uses	bx,cx,dx,ds,si
	locals	local	ImportStackFrame
	SSM_local	local	SSMetaStruc
	.enter	inherit near

	mov	SSM_local.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	cx, ax				; cx <- size
EC <	cmp	cx, 2*MAX_NAME_DEF_LENGTH		>
EC <	ERROR_A	IMPEX_CELL_DATA_TOO_LARGE		>

	segmov	ds, es, ax
	clr	si				; ds:si <- entry data
	mov	al, SSMAEF_ADD_IN_ROW_ORDER
	mov	dx, ss
	push	bp
	lea	bp, SSM_local
	call	SSMetaDataArrayAddEntry
	pop	bp

	;
	; update the scrap rows and cols
	; 
	mov	ax, SSM_local.SSMDAS_row		; fetch row
	cmp	ax, locals.ISF_endRow			; is it outside scrap?
	jle	haveRow					; no, falls within scrap
	mov	locals.ISF_endRow, ax			; save new max row

haveRow:
	mov	ax, SSM_local.SSMDAS_col		; fetch col
	cmp	ax, locals.ISF_endCol			; is it outside scrap?
	jle	haveCol
	mov	locals.ISF_endCol, ax			; save new max col

haveCol:

	.leave
	ret
ImportSaveCell	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportInputGetByte

DESCRIPTION:	

CALLED BY:	INTERNAL (utility)

PASS:		ImportStackFrame

RETURN:		ax - byte
		carry set if error or EOF
		    (ax = TransError = TE_FILE_READ)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

ImportInputGetByte	proc	near	uses	bx
	locals	local	ImportStackFrame
	.enter	inherit near

EC<	call	ECCheckImportStackFrame >

	mov	bx, locals.ISF_inputCacheHan
	call	InputCacheGetChar	; al <- next byte
	jc	err

if 0
	cmp	al, EOF
	je	err
	clc
endif

done:
	.leave
	ret
err:
	mov	ax, TE_FILE_READ
	stc
	jmp	short done
ImportInputGetByte	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportInputGetWord

DESCRIPTION:	

CALLED BY:	INTERNAL (utility)

PASS:		ImportStackFrame

RETURN:		ax - word
		carry set if error or EOF
		    (ax = TransError = TE_FILE_READ)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

ImportInputGetWord	proc	near	uses	bx,dx
	locals	local	ImportStackFrame
	.enter	inherit near

EC<	call	ECCheckImportStackFrame >

	mov	bx, locals.ISF_inputCacheHan
	call	InputCacheGetChar	; al <- low byte (or EOF)
	jc	err

	mov	dl, al
if 0
	cmp	al, EOF
	je	err
endif

	call	InputCacheGetChar	; al <- high byte
	jc	err

if 0
	cmp	al, EOF
	je	err
endif

	mov	ah, al
	mov	al, dl
	clc

done:
	.leave
	ret

err:
	mov	ax, TE_FILE_READ
	stc
	jmp	short done
ImportInputGetWord	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImportInputBufferLotusRecord

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ImportStackFrame
		ax - number of bytes in the record

RETURN:		carry set if error
		    ax - TransError
		else
		    ds:si - Lotus record
		    ISF_cacheBufHan - handle of block in ds
		    ax - unchanged
DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

ImportInputBufferLotusRecord	proc	near	uses	bx,cx,es,di
	locals	local	ImportStackFrame
	.enter	inherit near

EC<	call	ECCheckImportStackFrame >

	clr	locals.ISF_cacheBufHan
	mov	locals.ISF_cacheBufSize, ax
	tst	ax
	je	done

	mov	cx, (mask HAF_LOCK) shl 8 or mask HF_SWAPABLE
	call	MemAlloc
	jc	memErr

	mov	ds, ax
	mov	es, ax
	clr	si,di
	mov	locals.ISF_cacheBufHan, bx

	mov	cx, locals.ISF_cacheBufSize
bufLoop:
	call	ImportInputGetByte
	jc	exit
	stosb
	loop	bufLoop

	mov	ax, locals.ISF_cacheBufSize		; restore ax
done:
	clc
exit:
	.leave
	ret
memErr:
	mov	ax, TE_OUT_OF_MEMORY
	jmp	short exit

ImportInputBufferLotusRecord	endp


ImportInputClearLotusRecord	proc	near	uses	bx
	locals	local	ImportStackFrame
	.enter	inherit near
	pushf

EC<	call	ECCheckImportStackFrame >

	mov	bx, locals.ISF_cacheBufHan
	tst	bx
	je	done

	call	MemFree

	clr	bx
	mov	locals.ISF_cacheBufHan, bx
	mov	locals.ISF_cacheBufSize, bx

done:
	popf
	.leave
	ret
ImportInputClearLotusRecord	endp


if ERROR_CHECK

ECCheckImportStackFrame	proc	near
	locals	local	ImportStackFrame
	.enter	inherit near
	
	cmp	locals.ISF_signature1, IMPORT_STACK_FRAME_SIG1
	ERROR_NE IMPEX_BAD_IMPORT_STACK_FRAME
	cmp	locals.ISF_signature2, IMPORT_STACK_FRAME_SIG2
	ERROR_NE IMPEX_BAD_IMPORT_STACK_FRAME

	.leave
	ret
ECCheckImportStackFrame	endp

endif
