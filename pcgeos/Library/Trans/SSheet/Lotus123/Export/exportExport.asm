
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportExport.asm

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
	Code to export the various cell types.
		
	$Id: exportExport.asm,v 1.1 97/04/07 12:03:55 newdeal Exp $

-------------------------------------------------------------------------------@


;
; For use in translating GEOS character set to LICS 
;
ExportTable	label	byte
	db	0xc4			;C_UA_DIERESIS
	db	0xc5			;C_UA_RING	
	db	0xc7			;C_UC_CEDILLA	
	db	0xc9			;C_UE_ACUTE	
	db	0xd1			;C_UN_TILDE	
	db	0xd6			;C_UO_DIERESIS	
	db	0xdc			;C_UU_DIERESIS	
	db	0xe1			;C_LA_ACUTE	
	db	0xe0			;C_LA_GRAVE	
	db	0xe2			;C_LA_CIRCUMFLEX	
	db	0xe4			;C_LA_DIERESIS	
	db	0xe3			;C_LA_TILDE	
	db	0xe5			;C_LA_RING	
	db	0xe7			;C_LC_CEDILLA	
	db	0xe9			;C_LE_ACUTE	
	db	0xe8			;C_LE_GRAVE
	db	0xea			;C_LE_CIRCUMFLEX	
	db	0xeb			;C_LE_DIERESIS	
	db	0xed			;C_LI_ACUTE	
	db	0xec			;C_LI_GRAVE	
	db	0xee			;C_LI_CIRCUMFLEX	
	db	0xef			;C_LI_DIERESIS	
	db	0xf1			;C_LN_TILDE	
	db	0xf3			;C_LO_ACUTE	
	db	0xf2			;C_LO_GRAVE	
	db	0xf4			;C_LO_CIRCUMFLEX	
	db	0xf6			;C_LO_DIERESIS	
	db	0xf5			;C_LO_TILDE	
	db	0xfa			;C_LU_ACUTE	
	db	0xf9			;C_LU_GRAVE	
	db	0xfb			;C_LU_CIRCUMFLEX	
	db	0xfc			;C_LU_DIERESIS	
	db	C_PERIOD		;C_DAGGER	
	db	0xb0			;C_DEGREE
	db	0xa2			;C_CENT		
	db	0xa3			;C_STERLING	
	db	0xa7			;C_SECTION	
	db	0x9a			;C_BULLET	
	db	0xb6			;C_PARAGRAPH	
	db	0xdf			;C_GERMANDBLS	
	db	C_PERIOD		;C_REGISTERED	
	db	0xa9			;C_COPYRIGHT	
	db	0xb8			;C_TRADEMARK	
	db	0x91			;C_ACUTE		
	db	0x93			;C_DIERESIS	
	db	C_PERIOD		;C_NOTEQUAL	
	db	0xc6			;C_U_AE		
	db	0xd8			;C_UO_SLASH	
	db	C_PERIOD		;C_INFINITY	
	db	0xb1			;C_PLUSMINUS	
	db	0xbe			;C_LESSEQUAL	
	db	0xae			;C_GREATEREQUAL	
	db	0xa5			;C_YEN		
	db	0xb5			;C_L_MU		
	db	C_PERIOD		;C_L_DELTA	
	db	C_PERIOD		;C_U_SIGMA	
	db	C_L_PI			;C_U_PI	
	db	0xad			;C_L_PI		
	db	C_PERIOD		;C_INTEGRAL	
	db	0xaa			;C_ORDFEMININE	
	db	0xba			;C_ORDMASCULINE	
	db	C_PERIOD		;C_U_OMEGA	
	db	0xe6			;C_L_AE		
	db	0xf8			;C_LO_SLASH	
	db	0xbf			;C_QUESTIONDOWN	
	db	0xa1			;C_EXCLAMDOWN	
	db	C_PERIOD		;C_LOGICAL_NOT	
	db	C_PERIOD		;C_ROOT		
	db	0xa0			;C_FLORIN	
	db	C_PERIOD		;C_APPROX_EQUAL	
	db	0xac			;C_U_DELTA	
	db	0xab			;C_GUILLEDBLLEFT	
	db	0xbb			;C_GUILLEDBLRIGHT
	db	C_PERIOD		;C_ELLIPSIS	
	db	C_PERIOD		;C_NONBRKSPACE	
	db	0xc0			;C_UA_GRAVE	
	db	0xc3			;C_UA_TILDE	
	db	0xd5			;C_UO_TILDE	
	db	0xd7			;C_U_OE		
	db	0xf7			;C_L_OE		
	db	0x96			;C_ENDASH
	db	0x96			;C_EMDASH	
	db	0xa4			;C_QUOTEDBLLEFT	
	db	0xb4			;C_QUOTEDBLRIGHT	
	db	C_PERIOD		;C_QUOTESNGLEFT	
	db	C_PERIOD		;C_QUOTESNGRIGHT	
	db	0xaf			;C_DIVISION	
	db	0x9a			;C_DIAMONDBULLET
	db	0xfd			;C_LY_DIERESIS
	db	0xdd			;C_UY_DIERESIS	
	db	C_SLASH			;C_FRACTION
	db	0xa8			;C_CURRENCY	
	db	C_LESS_THAN		;C_GUILSNGLEFT	
	db	C_GREATER_THAN		;C_GUILSNGRIGHT	
	db	C_SMALL_Y		;C_LY_ACUTE
	db	C_CAP_Y			;C_UY_ACUTE
	db	C_PERIOD		;C_DBLDAGGER	
	db	0xb7			;C_CNTR_DOT	
	db	C_PERIOD		;C_SNGQUOTELOW	
	db	C_PERIOD		;C_DBLQUOTELOW	
	db	C_PERIOD		;C_PERTHOUSAND	
	db	0xc2			;C_UA_CIRCUMFLEX	
	db	0xca			;C_UE_CIRCUMFLEX	
	db	0xc1			;C_UA_ACUTE	
	db	0xcb			;C_UE_DIERESIS	
	db	0xc8			;C_UE_GRAVE	
	db	0xcd			;C_UI_ACUTE	
	db	0xce			;C_UI_CIRCUMFLEX	
	db	0xcf			;C_UI_DIERESIS	
	db	0xcc			;C_UI_GRAVE	
	db	0xd3			;C_UO_ACUTE	
	db	0xd4			;C_UO_CIRCUMFLEX	
	db	C_PERIOD		;C_LOGO		
	db	0xd2			;C_UO_GRAVE	
	db	0xda			;C_UU_ACUTE	
	db	0xdb			;C_UU_CIRCUMFLEX	
	db	0xd9			;C_UU_GRAVE	
	db	0x95			;C_LI_DOTLESS
	db	0x92			;C_CIRCUMFLEX	
	db	0x94			;C_TILDE		
	db	C_PERIOD		;C_MACRON	
	db	C_PERIOD		;C_BREVE		
	db	C_PERIOD		;C_DOTACCENT	
	db	C_PERIOD		;C_RING		
	db	C_PERIOD		;C_CEDILLA	
	db	C_PERIOD		;C_HUNGARUMLAT	
	db	C_PERIOD		;C_OGONEK	
	db	C_PERIOD		;C_CARON		



COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportProcessString

DESCRIPTION:	Export a text string to Lotus.

CALLED BY:	INTERNAL (ExportProcessSingleCell)

PASS:		ExportStackFrame
		ds:si - string to export
		es:di - location to place exported string

RETURN:		nothing

DESTROYED:	ax,bx,cx,ds,si,es,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus label cell records are variable in length to 245 bytes
	byte 0		format byte
	bytes 1-2	column number
	bytes 3-4	row number
	bytes5-245	ASCIIZ string, 240 bytes max

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportProcessString	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near
 
	;-----------------------------------------------------------------------
	; Read the first byte of the cell data: if it is a format char,
	; copy it to the Lotus cell, else put a default format char and
	; then copy the char to the Lotus cell.
	;
	call	ExportMapFormat			; cx <- Lotus format char length
	;-----------------------------------------------------------------------
	; copy the string, truncating if necessary

CheckHack <(LOTUS_MAX_STRING_LEN + size LotusCellInfo) lt EXPORT_STACK_FRAME_BUF_SIZE>

	mov	dx, LOTUS_MAX_STRING_LEN-1	; already stored format char
	call	ExportTranslateText		; dx <- string length
	add	cx, dx				; cx <- cumulative length

	;-----------------------------------------------------------------------
	; error check stack frame & count
	; write record

EC<	call	ECExportCheckStackFrame >
EC<	cmp	cx, LOTUS_MAX_STRING_LEN+2   >	; have we exceeded limit?
EC<	ERROR_G	IMPEX_EXPORTING_INVALID_DATA >

	mov	locals.ESF_token, CODE_LABEL
	add	cx, size LotusCellInfo
	mov	locals.ESF_length, cx
	call	ExportWriteRecord

	.leave
	ret
ExportProcessString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportTranslateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate from GEOS character set to LICS.

CALLED BY:	ExportProcessString
PASS:		dx - max number or chars to store in the destination
		ds:si - source string
		es:di - destination buffer

RETURN:		dx - length of string, including NULL
DESTROYED:	ax,si,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportTranslateText		proc	near
	uses	bx,cx
	.enter

	mov	cx, dx
	clr	dx			; initialize count to 0
	mov	bx, offset ExportTable

translate:	
	lodsb				; al <- byte of string
	shl	al			; see if high bit was set...
	jnc	noMap			; if not, byte is < 80h
	shr	al			; al = al - 80h
	cs:xlat				; translate the byte
	shl	al			; shift left for rcr below 
noMap:
	rcr	al			; restore high bit of the char
	stosb				; store the new char
	inc	dx			; inc the count of chars
	tst	al			; was the char a NULL?
	loopne	translate		; if yes, or buffer full, stop.

	;
	; if last char stored was a NULL, we're done
	;
	tst	al
	jz	done					
	;
	; Else the buffer is full, so store a NULL in the last byte
	;
	mov	{byte}es:[di-1], 0
done:
	.leave
	ret
ExportTranslateText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportMapFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	translate from GeoCalc format to Lotus format
		and store the format byte.

CALLED BY:	ExportProcessString
PASS:		ds:si	- ptr to cell data
RETURN:		si, di	- updated 
		cx	- length of string in es:di so far
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportMapFormat		proc	near
	.enter

	lodsb
	mov	cx, 1				; init count
	cmp	al, '\''			; is it left justified?
	je	stuffIt				; stuff it now
	cmp	al, '\"'			; is it right justified?
	je	stuffIt				; stuff it now
	cmp	al, '\^'			; is it centered?
	je	stuffIt				; stuff it now
	mov	al, '\''			; default - left justified
	dec	si				; back up to first char

stuffIt:
	stosb					; store char

	.leave
	ret
ExportMapFormat		endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportProcessConstant

DESCRIPTION:	Export a numeric constant to Lotus.

CALLED BY:	INTERNAL (ExportProcessSingleCell)

PASS:		ExportStackFrame
		ds:si - float number to export
		es:di - location to place exported number

RETURN:		nothing

DESTROYED:	ax,ds,si,es,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus number cell records are 13 bytes in length
	byte 0		format byte
	bytes 1-2	column number
	bytes 3-4	row number
	bytes 5-12	64 bit IEEE number

	point ds:si at float number
	push number onto fp stack
	point es:di at data area in stack frame
	call FloatGeos80ToIEEE64

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportProcessConstant	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near

	mov	locals.ESF_token, CODE_NUMBER
	mov	locals.ESF_length, 13

	call	FloatPushNumber		; place number on fp stack
	call	FloatGeos80ToIEEE64	; pass es:di = dest addr
	call	ExportWriteRecord

	.leave
	ret
ExportProcessConstant	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportProcessFormula

DESCRIPTION:	Export a formula to Lotus.

CALLED BY:	INTERNAL (ExportProcessSingleCell)

PASS:		ExportStackFrame
		ds:si - CellFormula structure
		es:di - location to place exported formula

RETURN:		nothing

DESTROYED:	ax,cx,ds,si,es,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus formula cell records are variable in length to 2048 bytes
	byte 0		format byte
	bytes 1-2	column number
	bytes 3-4	row number
	bytes 5-12	formula's numeric value (64 bit IEEE)
	bytes 13-14	formula size in bytes
	bytes 15-2063	formula code, 2048 bytes max

	Formulas are stored in "reverse polish internal notation".

	Operator precedence:
	operator	unary prec	binary prec
	--------	----------	-----------
	+		6		4
	-		6		4
	*		na		5
	/		na		5
	^		na		7
	=		na		3
	<>		na		3
	<=		na		3
	>=		na		3
	<		na		3
	>		na		3
	AND		na		1
	OR		na		1
	NOT		2		na

	CellFormula	struct
		CF_common	CellCommon <CT_FORMULA>
		CF_return	ReturnType	;return type
		CF_current	ReturnValue	;return value/string/error
		CF_formulaSize	word		;length of the formula
	CellFormula	ends

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportProcessFormula	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near

	;
	; store numeric value
	;
	cmp	ds:[si].CF_return, RT_VALUE	; value?
	jne	store0				; go store 0 if not

	push	si
	add	si, offset CF_current		; ds:si <- float number
	call	FloatPushNumber
	call	FloatGeos80ToIEEE64
	add	di, FPSIZE_IEEE64		; point es:di past numeric value
	pop	si

	jmp	short doneStoringNumericVal

store0:
	clr	al
	mov	cx, FPSIZE_IEEE64
	rep	stosb

doneStoringNumericVal:
	add	si, size CellFormula

	;
	; ds:si = formula proper
	; es:di = location to store formula length
	;

	push	di
	add	di, 2			; es:di <- location to store formula
	call	ExportFormulaCalcInfixToLotusPostfix
	mov	cx, di
	pop	di
	sub	cx, di			; cx <- length of formula
	sub	cx, 2
	mov	es:[di], cx		; store length
EC<	tst	locals.ESF_operatorCount		>
EC<	ERROR_NZ IMPEX_OPERATOR_STACK_NOT_EMPTY		>
	mov	locals.ESF_token, CODE_FORMULA
	add	cx, size LotusCellInfo + FPSIZE_IEEE64 + 2
	mov	locals.ESF_length, cx
	call	ExportWriteRecord

	.leave
	ret
ExportProcessFormula	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportProcessEmpty

DESCRIPTION:	Export an empty cell to Lotus.

CALLED BY:	INTERNAL (ExportProcessSingleCell)

PASS:		ExportStackFrame

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Lotus blank cell records are 5 bytes in length
	byte 0		format byte
	bytes 1-2	column number
	bytes 3-4	row number

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportProcessEmpty	proc	near
	locals	local	ExportStackFrame
	.enter	inherit near

	mov	locals.ESF_token, CODE_BLANK
	mov	locals.ESF_length, 5
	call	ExportWriteRecord

	.leave
	ret
ExportProcessEmpty	endp
