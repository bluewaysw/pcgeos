COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		numericFormats.asm

AUTHOR:		Chris, 12/13/90

ROUTINES:
	Name			Description
	----			-----------
	DateTimeFormat		Format a date/time generically.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/90	Initial revision

DESCRIPTION:
	Handles number format issues.

	$Id: numericFormats.asm,v 1.1 97/04/05 01:16:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LAST_BOOLEAN_FORMAT =  offset leadingZero ; table offset to last boolean
LAST_DATA_FORMAT    =  offset currencySymbol

; FileCommon is a wierd resource for this, but it is better than having the
; Format resource read in for a couple of routines

FileCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetNumericFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get numeric format info.

CALLED BY:	Global.

PASS:		nothing

RETURN:		al - NumberFormatFlags
		ah - decimal digits
		bx - thousands separator  (i.e. ',')
		cx - decimal separator    (i.e. '.')
		dx - list separator	  (i.e. ';')

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalGetNumericFormat	proc	far
	uses	si, ds
	.enter

	mov	bx, handle LocalStrings
	call	MemThreadGrabFar
	mov	ds, ax

	mov	si, offset leadingZero
	mov	si, ds:[si]
	mov	al, {byte} ds:[si]
	sub	al, '0'			; make numeric, only one flag currently
					;   kept in this byte, the low bit
	mov	si, offset thousandsSeparator
	mov	si, ds:[si]
SBCS <	clr	bx							>
SBCS <	mov	bl, {byte} ds:[si]					>
DBCS <	mov	bx, {wchar} ds:[si]					>

	mov	si, offset decimalSeparator
	mov	si, ds:[si]
SBCS <	clr	cx							>
SBCS <	mov	cl, {byte} ds:[si]					>
DBCS <	mov	cx, {wchar} ds:[si]					>

	mov	si, offset listSeparator
	mov	si, ds:[si]
SBCS <	clr	dx							>
SBCS <	mov	dl, {byte} ds:[si]					>
DBCS <	mov	dx, {wchar} ds:[si]					>

	mov	si, offset decimalDigits
	mov	si, ds:[si]
	mov	ah, {byte} ds:[si]
	sub	ah, '0'			; convert to number

	push	bx
	mov	bx, handle LocalStrings
	call	MemThreadReleaseFar
	pop	bx

	.leave
	ret
LocalGetNumericFormat	endp

FileCommon ends

Format segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetNumericFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set numeric format info.  All items will be added to the .ini
		file.

CALLED BY:	Global.

PASS:		al - NumberFormatFlags
		ah - decimal digits
		bx - thousands separator  (i.e. ',')
		cx - decimal separator    (i.e. '.')
		dx - list separator	  (i.e. ';')

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment resource

LocalSetNumericFormat	proc	far
	uses	ax, bx, cx, si, ds
	.enter

if not DBCS_PCGEOS
EC <	tst	bh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
EC <	tst	ch							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
EC <	tst	dh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

	call	LockStringsDS

	mov	si, offset leadingZero
	mov	si, ds:[si]
	add	al, '0'			; convert to ascii
	mov	{byte} ds:[si], al

	mov	si, offset decimalDigits
	mov	si, ds:[si]
	add	ah, '0'			; convert to ascii
	mov	{byte} ds:[si], ah

	mov	si, offset thousandsSeparator
	mov	si, ds:[si]
SBCS <	mov	{byte} ds:[si], bl					>
DBCS <	mov	{wchar} ds:[si], bx					>

	mov	si, offset decimalSeparator
	mov	si, ds:[si]
SBCS <	mov	{byte} ds:[si], cl					>
DBCS <	mov	{wchar} ds:[si], cx					>

	mov	si, offset listSeparator
	mov	si, ds:[si]
SBCS <	mov	{byte} ds:[si], dl					>
DBCS <	mov	{wchar} ds:[si], dx					>

	call	UnlockStrings
	;
	; Write the appropriate things out to the .ini file now.
	;
	mov	bx, handle leadingZero
	mov	si, offset leadingZero		;first thing to write
	mov	cx, offset listSeparator	;last thing to write
	call	NumericWriteFormats

	mov	si, offset decimalDigits	;first thing to write
	mov	cx, offset decimalDigits	;last thing to write
	call	NumericWriteFormats

	.leave
	ret
LocalSetNumericFormat	endp

ObscureInitExit	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetCurrencyFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get currency format info.

CALLED BY:	Global.

PASS:		es:di -- buffer to put currency symbol

RETURN:		al - CurrencyFormatFlags
		ah - currency digits
		bx - thousands separator  (i.e. ',')
		cx - decimal separator    (i.e. '.')
		dx - list separator	  (i.e. ';')
		es:di - currency symbol

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version
	JDM	93.03.25	Fixed internal register trashing problem.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalGetCurrencyFormat	proc	far
	uses	ds, si, di

	.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx, si					>
EC <		movdw	bxsi, esdi				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>
endif

	call	LocalGetNumericFormat	; load numeric stuff (bx,cx,dx)
	push	bx, cx			; Save trashed regs.

	call	LockStringsDS

	clr	al			; start with no CurrencyFormatFlags set
	mov	si, offset currencyLeadingZero
	call	AddFlagToAL		; rotate a flag into al
	mov	si, offset spaceAroundSymbol
	call	AddFlagToAL		; rotate a flag into al
	mov	si, offset useNegativeSign
	call	AddFlagToAL		; rotate a flag into al
	mov	si, offset symbolBeforeNumber
	call	AddFlagToAL		; rotate a flag into al
	mov	si, offset negativeSignBeforeNumber
	call	AddFlagToAL		; rotate a flag into al
	mov	si, offset negativeSignBeforeSymbol
	call	AddFlagToAL		; rotate a flag into al

	mov	si, offset currencyDigits
	mov	si, ds:[si]
	mov	ah, {byte} ds:[si]
	sub	ah, '0'			; make numeric

	push	ax
	mov	si, offset currencySymbol
	call	StoreResourceString
SBCS <	clr	al			;null terminate destination	>
DBCS <	clr	ax							>
	LocalPutChar esdi, ax
	pop	ax

	call	UnlockStrings
	pop	bx, cx			; Restore trashed regs.

	.leave
	ret
LocalGetCurrencyFormat	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	AddFlagToAL

SYNOPSIS:	Gets a flag from a resource chunk and rotates it into al.

CALLED BY:	GetCurrencyFormat

PASS:		al -- byte to rotate into
		ds:si -- chunk to find '0' or '1' flag in

RETURN:		al -- updated

DESTROYED:	si, cl

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/90		Initial version

------------------------------------------------------------------------------@

AddFlagToAL	proc	near
	mov	si, ds:[si]		; de-ref the chunk
	mov	cl, {byte} ds:[si]	; get the current value
	sub	cl, '0'			; make a number (1 or 0)
	rcr	cl, 1			; rotate bit into al
	rcl	al, 1
	ret
AddFlagToAL	endp

Format ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetCurrencyFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set currency format info.  All items will be added to the .ini
		file.

CALLED BY:	Global.

PASS:		al - CurrencyFormatFlags
		ah - currency digits
		es:di - currency symbol

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
LocalSetCurrencyFormat	proc	far
	mov	ss:[TPD_dataBX], handle LocalSetCurrencyFormatReal
	mov	ss:[TPD_dataAX], offset LocalSetCurrencyFormatReal
	GOTO	SysCallMovableXIPWithESDI
LocalSetCurrencyFormat	endp
CopyStackCodeXIP	ends

else

LocalSetCurrencyFormat	proc	far
	FALL_THRU	LocalSetCurrencyFormatReal
LocalSetCurrencyFormat	endp

endif

LocalSetCurrencyFormatReal	proc	far
	uses	ax, bx, cx, si, ds
	.enter

	call	LockStringsDS

	mov	si, offset currencyDigits
	mov	si, ds:[si]
	add	ah, '0'			; make ascii
	mov	{byte} ds:[si], ah

	;
	; Based on al, our CurrencyFormatFlags, we'll set all the appropriate
	; chunks.
	;
	mov	si, offset negativeSignBeforeSymbol
	call	SetFlagFromAL
	mov	si, offset negativeSignBeforeNumber
	call	SetFlagFromAL
	mov	si, offset symbolBeforeNumber
	call	SetFlagFromAL
	mov	si, offset useNegativeSign
	call	SetFlagFromAL
	mov	si, offset spaceAroundSymbol
	call	SetFlagFromAL
	mov	si, offset currencyLeadingZero
	call	SetFlagFromAL

	mov	si, offset currencySymbol
	call	SetResourceString

	call	UnlockStrings

	;
	; Write the appropriate things out to the .ini file now.
	;
	mov	bx, handle symbolBeforeNumber
	mov	si, offset symbolBeforeNumber	;first thing to write
	mov	cx, offset currencyLeadingZero	;last thing to write
	call	NumericWriteFormats

	mov	si, offset currencySymbol	;first thing to write
	mov	cx, offset currencyDigits	;last thing to write
	call	NumericWriteFormats

	.leave
	ret
LocalSetCurrencyFormatReal	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetFlagFromAL

SYNOPSIS:	Gets a flag from al and sets a resource chunk appropriately.

CALLED BY:	GetCurrencyFormat

PASS:		al -- byte to rotate from (we'll get the low bit)
		ds:si -- chunk to set '0' or '1' flag in

RETURN:		al -- rotated right once

DESTROYED:	si, cl

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/90		Initial version

------------------------------------------------------------------------------@

SetFlagFromAL	proc	near
	rcr	al, 1			; get a bit from al
	mov	cl, 0
	rcl	cl, 1			; rotate bit into cl
	add	cl, '0'			; make ascii '0' or '1'
	mov	si, ds:[si]		; de-ref the chunk
	mov	{byte} ds:[si], cl	; set the new value
	ret
SetFlagFromAL	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	NumericWriteFormats

SYNOPSIS:	Writes any .ini formats that we need from our resource.

CALLED BY:	SetNumericFormats, SetCurrencyFormats

PASS:		bx -- block handle of objects to write to
		si -- chunk handle of first object to write to the .ini file
		cx -- chunk handle of last object to write to the .ini file

RETURN:		nothing

DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/90	Initial version

------------------------------------------------------------------------------@
NumericWriteFormats	proc	near
	uses	dx, bp, di, es
	.enter

	sub	sp, CURRENCY_SYMBOL_LENGTH+1	; leave room for format string
	mov	di, sp				; have di point to format buffer
	segmov	es, ss				; have es point to format buffer

doFormat:
	push	cx				; save last entry, current
	push	si
	;
	; Get resource string from the chunk indexed by si.
	;
	push	di
	call	StoreResourceString		; string in es:di
SBCS <	clr	al				; null terminate destination>
DBCS <	clr	ax							>
	LocalPutChar esdi, ax
	pop	di				; point to beginning again
	;
	; Figure out what key to use for this format.
	;
	segmov	ds, cs, cx
	assume	ds:ObscureInitExit
	push	si
	sub	si, offset symbolBeforeNumber
	mov	dx, ds:numericFormatKeys[si]
	pop	si
	mov	bp, offset localizationCategory	;
	cmp	si, LAST_BOOLEAN_FORMAT		; doing a boolean?
	jbe	writeBoolean			; yes, branch
	cmp	si, LAST_DATA_FORMAT		; doing straight data?
	mov	si, bp				; (ds:si holds category string)
	jbe	writeData			; yes, branch

;writeString:
	call	InitFileWriteString		; store to .ini as a string
	jmp	short gotIt

writeData:
	call	LocalWriteStringAsData		; store to .ini as data
	jmp	short gotIt

writeBoolean:
	mov	si, bp				; (ds:si holds category string)
	mov	al, es:[di]			; 1st char of string, '0' or '1'
	sub	al, '0'				; make 1 = true, 0 = false
	clr	ah
	neg	ax				; ax: -1 = true, 0 = false
	call	InitFileWriteBoolean		; store to .ini as boolean

gotIt:
	pop	si				; restore format
	add	si, 2				; next format
	pop	cx
	cmp	si, cx				; see if we've gone far enough
	jbe	doFormat			; do another format if not done

	add	sp, CURRENCY_SYMBOL_LENGTH+1	; restore stack

	.leave
	ret
NumericWriteFormats	endp

	assume	ds:dgroup

ObscureInitExit	ends


COMMENT @----------------------------------------------------------------------

ROUTINE:	NumericInitFormats

SYNOPSIS:	Loads in any .ini formats and stuffs them into our resource.

CALLED BY:	LocalInit

PASS:		nothing

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/90	Initial version

------------------------------------------------------------------------------@

LAST_BOOLEAN_KEY	= offset leadingZeroString
LAST_DATA_KEY		= offset currencySymbolString

ObscureInitExit	segment

NumericInitFormats	proc	near
	sub	sp, CURRENCY_SYMBOL_LENGTH+1	; leave room for format string
	mov	di, sp				; have di point to format buffer
	segmov	es, ss				; have es point to format buffer

	mov	si, ((length numericFormatKeys)-1)*2	; do all the formats
doFormat:
	push	si
	;
	; Figure out what key to use for this format.
	;
	segmov	ds, cs, cx
	assume	ds:ObscureInitExit
	mov	dx, ds:numericFormatKeys[si]	; cx:dx holds key
	mov	bp, offset localizationCategory	;
	cmp	dx, LAST_BOOLEAN_KEY
	jbe	getBoolean			; one of the booleans, branch

	cmp	dx, LAST_DATA_KEY
	mov	si, bp				; (ds:si holds category string)
	mov	bp, CURRENCY_SYMBOL_LENGTH	; (max size to read in)
	jbe	getData				; straight data to read, branch

;getString:
	call	InitFileReadString
	jmp	short gotIt

getData:
	call	LocalGetStringAsData		; destroys cx
	jmp	short gotIt

getBoolean:
	mov	si, bp				; (ds:si holds category string)
	call	InitFileReadBoolean		; boolean value in ax
	pushf
	push	di
	neg	al				; 1 = true, 0 = false
	add	al, '0'				; make '1' = true, '0' = false
	stosb					; store in our buffer as asciz
	clr	al
	stosb
	pop	di				; restore start
	popf

gotIt:
	pop	si				; restore format
	jc	doNext				; nothing read, go do next one

	mov	bx, handle symbolBeforeNumber	; setup ^lbx:si to proper chunk
	push	si
	add	si, offset symbolBeforeNumber	;
	call	SetResourceString		; set the resource string
	pop	si
doNext:
	sub	si, 2				; next format
	jns	doFormat			; do another format if not done

	add	sp, CURRENCY_SYMBOL_LENGTH+1	; restore stack
	ret
NumericInitFormats	endp

	assume	ds:dgroup

numericFormatKeys	word 	\
		offset	symbolBeforeNumberString,  	;booleans
		offset	spaceAroundSymbolString,
		offset	useNegativeSignString,
		offset	negativeSignBeforeNumberString,
		offset	negativeSignBeforeSymbolString,
		offset	currencyLeadingZeroString,
		offset	leadingZeroString,

		offset	thousandsSeparatorString,	;data
		offset	decimalSeparatorString,
		offset	listSeparatorString,
		offset	currencySymbolString,

		offset	currencyDigitsString,		;strings
		offset	decimalDigitsString,
		offset	measurementSystemString


;BOTH ORDER OF KEYS AND ABOVE OFFSETS MUST MATCH ORDER OF CHUNKS IN
;localStrings.asm!!!

symbolBeforeNumberString	char	"symbolBeforeNumber",0
spaceAroundSymbolString		char	"spaceAroundSymbol",0
useNegativeSignString		char	"useNegativeSign",0
negativeSignBeforeNumberString	char	"negativeSignBeforeNumber",0
negativeSignBeforeSymbolString	char	"negativeSignBeforeSymbol",0
currencyLeadingZeroString	char	"currencyLeadingZero",0
leadingZeroString		char	"leadingZero",0

thousandsSeparatorString	char	"thousandsSeparator",0
decimalSeparatorString		char	"decimalSeparator",0
listSeparatorString		char	"listSeparator",0
currencySymbolString		char	"currencySymbol",0

currencyDigitsString		char	"currencyDigits",0
decimalDigitsString		char	"decimalDigits",0
measurementSystemString		char	"measurementSystem",0



COMMENT @----------------------------------------------------------------------

ROUTINE:	LocalWriteStringAsData

SYNOPSIS:	Does an InitFileWriteData, after getting the string's length.

CALLED BY:	utility

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		es:di - buffer containing data

RETURN:		nothing

DESTROYED:	bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@

LocalWriteStringAsData	proc	near
if DBCS_PCGEOS
	push	cx
	call	LocalStringSize
	mov	bp, cx				;bp <- size w/o NULL
	pop	cx
else
	push	di, cx
	mov	cx, -1
	clr	al
	repne	scasb				; find null byte to get size
	not	cx
	mov	bp, cx				; keep in bp
	dec	bp				; don't write null byte
	pop	di, cx
endif

	call	InitFileWriteData		; write as hex data
	ret
LocalWriteStringAsData	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	LocalGetStringAsData

SYNOPSIS:	Does an InitFileReadData, and null terminates the resulting
		string.

CALLED BY:	utility

PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		es:di - buffer to put data
		bp - size of buffer

RETURN:		carry clear if something read, with:
			cx - number of bytes read, excluding null

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@

LocalGetStringAsData	proc	near
	call	InitFileReadData			; read as hex data
	jc	exit				; nothing read, exit
	push	di
	add	di, cx				; advance to end of string
SBCS <	mov	{byte} es:[di], 0		; and store a null	>
DBCS <	mov	{wchar} es:[di], 0		; and store a null	>
	pop	di
	clc					; clear carry for successful
						;    read
exit:
	ret
LocalGetStringAsData	endp

ObscureInitExit	ends
