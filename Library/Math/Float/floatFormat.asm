
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatFormat.asm

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:
		
	$Id: floatFormat.asm,v 1.1 97/04/05 01:23:12 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGenerateFormatStr

DESCRIPTION:	Generates an Excel-like format string from the options
		given in the stack frame.

CALLED BY:	GLOBAL ()

PASS:		al - POSITIVE? boolean
		     non-zero to use positive sign
		     0 to use negative
		FFA_stackFrame
		es:di - location to place format string

RETURN:		es:di - format string

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatGenerateFormatStr	proc	far	uses	cx,dx,di,ds
	locals	local	FFA_stackFrame
	.enter	inherit far

	call	FloatEnter			; ds <- fp stack seg

	;-----------------------------------------------------------------------
	; push a number according to al

	mov	locals.FFA_float.FFA_saveDI, di	; save di
	push	ax
	call	Float1				; push number, assume positive
	pop	ax
	tst	al				; assumption correct?
	jne	numGotten			; branch if so
	call	FloatNegate			; else negate number
numGotten:

	;-----------------------------------------------------------------------
	; deal with header, sign, offset and percentage

	call	FloatDoPreNumeric

	;-----------------------------------------------------------------------
	; deal with number

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	jne	scientificNormalized

	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_USE_COMMAS
	je	doneComma

if DBCS_PCGEOS
	mov	ax, ','
	stosw
	mov	ax, '#'
	stosw
	stosw
	stosw
else
	mov	ax, ',' shl 8 or '#'
	stosw
	mov	ax, '#' shl 8 or '#'
	stosw
endif

doneComma:
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_NO_LEAD_ZERO
	LocalLoadChar	ax, '#'
	jne	doneLeadZero
scientificNormalized:
	LocalLoadChar	ax, '0'
doneLeadZero:
	LocalPutChar	esdi, ax

	mov	cl, locals.FFA_float.FFA_params.decimalLimit	; cl <- number of decimals
	tst	cl
	je	doneDecimals

	clr	ch
	LocalLoadChar	ax, '.'
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, '0'			; assume 0 padding
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_NO_TRAIL_ZEROS
	je	decimalLoop
	LocalLoadChar	ax, '#'			; else user does not want 0s
decimalLoop:
	LocalPutChar	esdi, ax
	loop	decimalLoop

doneDecimals:
	test	locals.FFA_float.FFA_params.formatFlags, mask FFAF_SCIENTIFIC
	je	doneNumber

if DBCS_PCGEOS
	mov	ax, '+'
	stosw
	mov	ax, 'E'
	stosw
	mov	ax, '0'
	stosw
	stosw
else
	mov	ax, '+' shl 8 or 'E'
	stosw
	mov	ax, '0' shl 8 or '0'
	stosw
endif

doneNumber:
	;-----------------------------------------------------------------------
	; deal with percentage, trailer and sign

	call	FloatDoPostNumeric

	;-----------------------------------------------------------------------
	; deal with offset

	cmp	locals.FFA_float.FFA_params.decimalOffset, 0
	je	done

	;-----------------------------------------------------------------------

if 0
DBCS<	ErrMessage <This code section NOT DBCS compliant>	>
	;
	; offsets will be displayed thus: */% 10^x
	;
	mov	ax, '*' shl 8 or ' '
	jg	10$
	mov	ax, C_DIVISION shl 8 or ' '
10$:
	stosw
	;
	; store ' 10^'
	;
	mov	ax, '1' shl 8 or ' '
	stosw
	mov	ax, '^' shl 8 or '0'
	stosw
else
	;
	; offsets will be displayed thus: <</>> x
	;  Flags set from decimalOffset compare.
	;
	LocalLoadChar	ax, ' '
	LocalPutChar	esdi, ax
 if DBCS_PCGEOS
	mov	ax, '<'
	jg	10$
	mov	ax, '>'
10$:
	stosw
	stosw
 else
	mov	ax, '<' shl 8 or '<'
	jg	10$
	mov	ax, '>' shl 8 or '>'
10$:
	stosw
 endif
	LocalLoadChar	ax, ' '
	LocalPutChar	esdi, ax
endif

	;-----------------------------------------------------------------------

	mov	al, locals.FFA_float.FFA_params.decimalOffset
	cbw
	tst	ax
	jns	20$				; branch if positive
	neg	ax				; else ax <- -ax
20$:
	call	ConvertWordToAscii

done:
SBCS<	clr	al				; null-terminator	>
DBCS<	clr	ax				; null-terminator	>
	LocalPutChar	esdi, ax

	FloatDrop trashFlags
	call	FloatOpDone
	.leave
	ret
FloatGenerateFormatStr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatNumber

DESCRIPTION:	Displays the number using the format token.

CALLED BY:	GLOBAL ()

PASS:		ax - format token (FormatIdType)
		cx - VM block handle of array containing user defined formats
		     OR 0 if none
		if cx is non-zero (ie. format array passed),
		     bx = file handle of file containing the format array
		ds:si - address of number to display
		es:di - address at which to store result

RETURN:		carry set if the number cannot be formatted correctly
		cx - number of characters in the string
			(excluding the null terminator)
		cx == 0 means that the string produced was a Nan, i.e
			either "underflow", "overflow", or "error"

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Things hardwired right now:
	    sig limit = DECIMAL_PRECISION
	    format flags will have  mask FFAF_FROM_ADDR

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	Ted	10/92		returns size of string

-------------------------------------------------------------------------------@

FloatFormatNumber	proc	far
	FFN_local	local	FFA_stackFrame
	.enter

	test	ax, FORMAT_ID_PREDEF
	je	userDef

	call	FloatFormat_PreDef
	jmp	short doConvert

userDef:
	call	FloatFormat_UserDef

doConvert:
	or	FFN_local.FFA_float.FFA_params.formatFlags, mask FFAF_FROM_ADDR
	call	FloatFloatToAscii

	.leave
	ret
FloatFormatNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormat_PreDef

DESCRIPTION:	Initialize the FFA_stackFrame with a pre-defined format
		in preparation for a call to FloatFloatToAscii.

CALLED BY:	INTERNAL (FloatFormatNumber)

PASS:		ax - format token
		ss:bp - FFA_stackFrame

RETURN:		FFA_stackFrame.FFA_params initialized

DESTROYED:	ax,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormat_PreDef	proc	near	uses	ds,si,es,di
	FF_local	local	FFA_stackFrame
	.enter	inherit near

	;
	; get offset into lookup table
	;
	and	ax, not FORMAT_ID_PREDEF	; ax <- 0 based offset
	add	ax, offset FormatPreDefTbl	; ax <- real offset to params
	mov	si, ax

	;
	; ensure that si is aligned and within the lookup table bounds
	;
DBCS< EC<	sub	ax, offset FormatPreDefTbl   ; check it's aligned > >
DBCS< EC<	mov	cl, size FormatParams				> >
DBCS< EC<	div	cl						> >
DBCS< EC<	tst	ah			     ; remainder?	> >
DBCS< EC<	ERROR_NZ FORMAT_BAD_PRE_DEF_TOKEN    ; yes! not aligned :-( > >

EC<	cmp	si, offset FormatPreDefTbl >
EC<	ERROR_B FORMAT_BAD_PRE_DEF_TOKEN >
EC<	cmp	si, offset FormatPreDefTblEnd >
EC<	ERROR_AE FORMAT_BAD_PRE_DEF_TOKEN >

	;
	; copy params from lookup table into stack frame
	;
NOFXIP<	segmov  ds, dgroup, ax			; ds:si <- lookup table	>
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	segmov	es, ss, ax			; es:di <- stack frame params
	lea	di, FF_local.FFA_float.FFA_params
	mov	cx, size FloatFloatToAsciiParams
	rep	movsb

	.leave
	ret
FloatFormat_PreDef	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormat_UserDef

DESCRIPTION:	Initialize the FFA_stackFrame with a user defined format
		in preparation for a call to FloatFloatToAscii.

CALLED BY:	INTERNAL (FloatFormatNumber)

PASS:		ax - format token
		bx - VM file handle containing user def format array
		cx - VM block handle of user def format array
		ss:bp - FFA_stackFrame

RETURN:		FFA_stackFrame.FFA_params initialized

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormat_UserDef	proc	near
	uses	ax,bx,cx,dx,ds,si,es,di
	FF_local	local	FFA_stackFrame
	.enter	inherit near

	push	ax				; save token
	push	bx				; save file han
	push	cx				; save blk han
	;
	; Allocate a wee little block for use with
	; FloatFormatGetFormatParamsWithToken()...
	;
	mov	ax, size FormatInfoStruc
	mov	cx, (mask HAF_LOCK or mask HAF_ZERO_INIT) shl 8 or mask HF_SWAPABLE
	call	MemAlloc
	mov	es, ax

	mov	es:FIS_signature, FORMAT_INFO_STRUC_ID
	mov	es:FIS_childBlk, -1		; force illegal handle
	pop	es:FIS_userDefFmtArrayBlkHan	; store blk han
	pop	es:FIS_userDefFmtArrayFileHan	; store file han
	pop	es:FIS_curToken			; store token

	push	bp
	mov	dx, es
	mov	bp, offset FIS_curParams
	call	FloatFormatGetFormatParamsWithToken
	pop	bp

	mov	ds, dx
	mov	si, offset FIS_curParams + offset FP_params
	segmov	es, ss				; ds:di <- spreadsheet instance
	lea	di, FF_local
	mov	cx, size FloatFloatToAsciiParams_Union
	rep	movsb
	;
	; Now actually free the block we allocated above...
	;
	call	MemFree				;free me jesus

	.leave
	ret
FloatFormat_UserDef	endp
