COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		numericMeasure.asm

AUTHOR:		Chris, 1/10/91

ROUTINES:
	Name			Description
	----			-----------
	GetMeasurementType	Get the current measurement Type.
	SetMeasurementType	Set new current measurement Type.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/10/91		Initial revision

DESCRIPTION:
	Handles number measurement stuff.

	$Id: numericMeasure.asm,v 1.1 97/04/05 01:17:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Measurement Type initialized by NumericInitFormats.
;

FileSemiCommon	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetMeasurementType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current measurement Type.

CALLED BY:	Global.

PASS:		nothing

RETURN:		al - MeasurementType (MEASURE_US, MEASURE_METRIC)
		ah - 0

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	1/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LOCALGETMEASUREMENTTYPE	proc	far
	uses	ds, si, bx
	.enter

	mov	bx, handle LocalStrings
	call	MemThreadGrabFar
	mov	ds, ax

	mov	si, offset measurementType
	mov	si, ds:[si]
	clr	ax
	mov	al, {byte} ds:[si]
	sub	al, '0'			; make numeric

	call	MemThreadReleaseFar

	.leave
	ret
LOCALGETMEASUREMENTTYPE	endp

FileSemiCommon	ends

ObscureInitExit	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetMeasurementType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets measurement Type.  Writes the correct thing out to
		the .ini file.

CALLED BY:	Global.

PASS:		al - MeasurementType (MEASURE_US, MEASURE_METRIC)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	1/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalSetMeasurementType	proc	far
	uses	ax, ds, si
	.enter

	call	LockStringsDS

	add	al, '0'			; convert to ascii
	mov	si, offset measurementType
	mov	si, ds:[si]
	mov	{byte} ds:[si], al

	call	UnlockStrings
	;
	; Write the appropriate things out to the .ini file now.
	;
	mov	si, offset measurementType	;first thing to write
	mov	cx, offset measurementType	;last thing to write
	call	NumericWriteFormats

	.leave
	ret
LocalSetMeasurementType	endp

ObscureInitExit	ends

Format	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	LocalDistanceToAscii

DESCRIPTION:	Convert a distance value to an ASCII string

CALLED BY:	GLOBAL

PASS:
	es:di - buffer for ASCII string (LOCAL_DISTANCE_BUFFER_SIZE)
	dx.ax - value to convert
	cl - DistanceUnit
	ch - MeasurementType
	bx - LocalDistanceFlags (LDF_FULL_NAMES)

RETURN:
	cx - length of string, including NULL

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
LocalDistanceToAscii	proc	far	uses ax, bx, dx, si, di, bp, ds
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx, si				>
EC <		movdw	bxsi, esdi			>
EC <		call	ECAssertValidFarPointerXIP	>
EC <		pop	bx, si				>
endif	
	
	call	ConvertUnitsIfFuzzy

	; Convert to the correct units the value now is in points.  The table
	; contains the number of units per point.  The division will give a
	; dword result (dx.ax).

	mov	si, bx				;save flags
	mov_tr	bx, cx
	clr	bh
	shl	bx				;bx = table index
	push	bx				;save index
	shl	bx
	mov	cx, ax				;pass our value in dx:ax
	mov	ax, cs:PointsPerUnit[bx].WWF_frac
	mov	bx, cs:PointsPerUnit[bx].WWF_int

	call	GrSDivWWFixed			;dx.cx = result
	mov	ax, cx				;dx.ax = result

	pop	bx
	push	bx				; bx = units * 2
	mov	cx, 1				; assume millimeters (1 digit)
	cmp	bl, DU_MILLIMETERS*2
	jz	gotPrecision
	inc	cx				; assume centimeters (2 digits)
	cmp	bl, DU_CENTIMETERS*2
	jz	gotPrecision
	inc	cx				; otherwise 3 digits
gotPrecision:
	;
	; V2.1 and above, allow passing of decimal places.
	;
	test	si, mask LDF_PASSING_DECIMAL_PLACES
	jz	10$
	mov	cx, si
	and	cx, mask LDF_DECIMAL_PLACES
10$:
	call	LocalFixedToAscii		; convert to ASCII
	cmpdw	dxax, 0x10000
	jnz	plural
	andnf	si, not mask LDF_PRINT_PLURAL_IF_NEEDED
plural:

	; find end of string

	mov	bp, di				; save start of string
SBCS <	clr	al							>
DBCS <	clr	ax							>
	mov	cx, 100
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	LocalPrevChar esdi			; es:di = null terminator

	; Add units string

	test	si, mask LDF_OMIT_UNITS_STRING
	jnz	noUnits
	LocalLoadChar ax, ' '
	LocalPutChar esdi, ax

	call	LockStringsDS
	pop	ax				;recover index

	test	si, mask LDF_FULL_NAMES
	jnz	fullNames
	mov	si, offset LocalUnitStringTable
	mov	si, ds:[si]		; ds:si <- LocalUnitStringTable
	add	si, ax			; move to appropriate offset
	mov	si, ds:[si]		
	mov	si, ds:[si]		; go to chunk
	ChunkSizePtr ds, si, cl		; get size for memcpy
	jmp	common
fullNames:
	test	si, mask LDF_PRINT_PLURAL_IF_NEEDED
	mov	si, offset LocalUnitLongStrings
	jz	30$
	mov	si, offset LocalUnitLongPluralStrings
30$:
	add	si, ax
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
DBCS <	shr	cx, 1							>
	dec	cx
common:
	LocalCopyNString			;rep movsb/movsw
	call	UnlockStrings
done:
	clr	ax				;store null terminator
	LocalPutChar esdi, ax
	sub	di, bp				;calculate length
	mov	cx, di				;return in cx

	.leave
	ret

noUnits:
	pop	ax				;clear stack
	jmp	done
LocalDistanceToAscii	endp

;-------

if	1
PointsPerUnit	label	WWFixed
	WWFixed	<0, 1>				;points		     1.000000
	WWFixed	<0, 72>				;inches		    72.000000
	WWFixed	<22705, 28>			;centimeters	    28.346465
	WWFixed	<54699, 2>			;millimeters	     2.834646
	WWFixed	<0, 12>				;picas		    12.000000
	WWFixed	<4299, 1>			;european points     1.0656
	WWFixed	<51590, 12>			;ciceros	    12.7872

DPointsPerUnit	label	DWFixed
	DWFixed	<0, (0 + (1 shl 16))>		;points		     1.000000
	DWFixed	<0, (0 + (72 shl 16))>		;inches		    72.000000
	DWFixed	<60948, (22705 + (28 shl 16))>	;centimeters	    28.346465
	DWFixed	<25755, (54699 + (2 shl 16))>	;millimeters	     2.834646
	DWFixed	<0, (0 + (12 shl 16))>		;picas		    12.000000
	DWFixed	<10591, (4299 + (1 shl 16))>	;european points     1.0656
	DWFixed	<61538, (51589 + (12 shl 16))>	;ciceros	    12.7872

UnitMax		label	word	;max value convertible for each unit (trunc'd)
				;   = 32766/pointsPerUnit
	word	32766				;points
	word	455				;inches
	word	1155				;centimeters
	word	11559				;millimeters
	word	2730				;picas
	word	30748				;european points
	word	2562				;ciceros

else

PointsPerUnitX8	label	WWFixed
	WWFixed	<0, 1*8>			;points		     8.0000
	WWFixed	<0, 72*8>			;inches		   576.0000
	WWFixed	<50572, 226>			;centimeters	   226.7717
	WWFixed	<44379, 22>			;millimeters	    22.6772
	WWFixed	<0, 12*8>			;picas		    96.0000
	WWFixed	<34393, 8>			;european points     8.5248
	WWFixed	<19504, 102>			;ciceros	   102.2976


UnitMax		label	word	;max value convertible for each unit (trunc'd)
				;   = 32766/pointsPerUnit*8
	word	4095				;points
	word	56				;inches
	word	144				;centimeters
	word	1444				;millimeters
	word	341				;picas
	word	3843				;european points
	word	320				;ciceros
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	LocalDistanceFromAscii

DESCRIPTION:	Convert to distance value from an ASCII string

CALLED BY:	GLOBAL

PASS:
	ds:di - ASCII string to convert
	cl - DistanceUnit
	ch - MeasurementType

RETURN:
	dx.ax - value (0 if illegal)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version
	Chris	6/ 3/92		Changed to return WWFixed values

------------------------------------------------------------------------------@
LocalDistanceFromAscii	proc	far	uses bx, cx, bp, es, si, di
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si				>
EC <	movdw	bxsi, dsdi			>
EC <	call	ECAssertValidFarPointerXIP	>
EC <	pop	bx, si				>
endif
	
	; get fixed point number from string

	call	ConvertUnitsIfFuzzy		;al now contains real units

SBCS <	mov	bp, cx				;bp = flags		>
	call	LocalAsciiToFixed		;dx.ax = result

	push	ax				;save fraction

DBCS <	push	cx				;save flags		>

	; try to parse a unit type

	segmov	es, ds
	LocalLoadChar ax, ' '
	mov	cx, 999
SBCS <	repe	scasb				;skip spaces		>
DBCS <	repe	scasw				;skip spaces		>
	LocalPrevChar esdi

	mov	ax, es:[di]			;al = 1st char, ah = 2nd char
DBCS <	mov	bp, es:[di][2]			;bp <- 2nd char		>
	mov	cx, DU_INCHES
SBCS <	cmp	al, "\\""			;double quote means inches >
DBCS <	cmp	ax, "\\""			;double quote means inches >
if DBCS_PCGEOS
	jne	noUnitsYet
	pop	ax				;throw away flags & units
	jmp	gotUnits

noUnitsYet:
else
	jz	gotUnits
endif

	push	ds
	call	LockStringsDS
	segmov	es, ds, ax
		assume	es:nothing
	pop	ds
	mov	si, di				; ds:si = source string to parse
	mov	cx, RealDistanceUnit		;number of chunk handles in table
	clr	bx				; start with chunk zero in table

nextChunk:	
	;
	; dereference current chunk in table
	;
	mov	di, es:[LocalUnitStringTable]
	mov	di, es:[di][bx]			
	mov	di, es:[di]			; es:di = destination compare string

	;
	; compare the strings
	;
	push	cx	
	clr	cx	
	call	LocalCmpStrings
	pop	cx
	jz	foundUnits
	add	bx, 2				; next chunk in table
	loop	nextChunk
DBCS <	pop	bp				; bp <- flags & units	>
	dec	cx				; clear Z flag
	;
	; Z flag is clear, fall through to unlock strings then branch
	; to noUnits. No units case was leaving strings locked. -eca 2/5/01
	;

foundUnits:
	call	UnlockStrings
DBCS <	pop	bp				;bp <- flags & units	>
	jnz	noUnits

	sub	cx, RealDistanceUnit					
	neg	cx				;cx = units
	jmp	gotUnits

noUnits:
	mov	cx, bp
	clr	ch				;isolate DistanceUnit
						;(nuke MeasurementType)

	; cx = units

gotUnits:

	mov	bx, cx
	shl	bx				;bx = table index

	mov	ax, dx				;get our value to convert
	tst	ax				;see if negative
	jns	10$
	neg 	ax				;negative, make positive for cmp
10$:
	cmp	ax, cs:UnitMax[bx]		;make sure not too big
	jbe	getMultiplier			;no, branch
	mov	ax, cs:UnitMax[bx]		;else limit the size
	tst	dx
	jns	20$				;was positive, branch
	neg	ax				;else make negative again
20$:
	mov	dx, ax				;store as the value to use

getMultiplier:
	mov	ax, bx
	shl	bx
	add	bx, ax				;multiply to handle 3 word items
	mov	ax, cs:DPointsPerUnit[bx].DWF_frac
	mov	si, cs:DPointsPerUnit[bx].DWF_int.high
	mov	bx, cs:DPointsPerUnit[bx].DWF_int.low
	pop	cx				
	clr	di				;di.dx.cx = #1
	tst	dx
	jns	30$
	not	di				;sign extend di.dx
30$:
	call	GrMulDWFixed			;dx.cx.bx = result 
	mov	ax, cx				;use top dword, in dx.ax
	.leave
	ret

LocalDistanceFromAscii	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertUnitsIfFuzzy

DESCRIPTION:	Convert units that are based on the current app's mode into
		real uinits

CALLED BY:	INTERNAL

PASS:
	cl - DistanceUnit

RETURN:
	cl - DistanceUnit with real units

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/90		Initial version

------------------------------------------------------------------------------@
ConvertUnitsIfFuzzy	proc	near

	cmp	cl, DU_POINTS_OR_MILLIMETERS
	jb	done

	cmp	ch, MEASURE_US
	jnz	metric

	; U.S. units

	cmp	cl, DU_POINTS_OR_MILLIMETERS
	mov	cl, DU_POINTS
	jz	done
	mov	cl, DU_INCHES
	jmp	done

	; metric units

metric:
	cmp	cl, DU_POINTS_OR_MILLIMETERS
	mov	cl, DU_MILLIMETERS
	jz	done
	mov	cl, DU_CENTIMETERS

done:
	ret

ConvertUnitsIfFuzzy	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AsciiToUnsignedInt

DESCRIPTION:	Convert an ASCII number to a signed value

CALLED BY:	INTERNAL

PASS:
	ds:di - ASCII string

RETURN:
	ax - number
	di - pointing after last digit

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
AsciiToUnsignedInt	proc	far
	clr	ax
digit:
SBCS <	clr	cx							>
SBCS <	mov	cl, ds:[di]						>
DBCS <	mov	cx, ds:[di]						>
SBCS <	sub	cl, '0'							>
DBCS <	sub	cx, '0'							>
	jb	done
SBCS <	cmp	cl, 9							>
DBCS <	cmp	cx, 9							>
	ja	done
	LocalNextChar dsdi			;next digit

	push	cx
	mov	cx, 10
	mul	cx				;multiply result so far by 10
	pop	cx

	add	ax, cx
	adc	dx, 0
	jnz	overflow
	tst	ah
	jns	digit
overflow:
	mov	ax, 32767			;overflow
	jmp	digit

done:
	ret

AsciiToUnsignedInt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalAsciiToFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a real number in ascii (no exponent) to WWFixed

CALLED BY:	LocalDistanceFromAscii
PASS:		ds:di	= string to evaluate
RETURN:
		dx:ax	= value
		di = pointing after last digit parsed
DESTROYED:	none

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version
	JimG	6/20/94		Added more precision to fraction table to get
				more accurate results for fractional part.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalAsciiToFixed	proc	far	uses bx, cx
	.enter

if 	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si				>
EC <	movdw	bxsi, dsdi			>
EC <	call	ECAssertValidFarPointerXIP	>
EC <	pop	bx, si				>
endif
	clr	ax
	LocalCmpChar ds:[di], '+'		; just skip over a '+', as we
	je	skipChar			; assume the number is positive
	LocalCmpChar ds:[di], '-'
	jne	notNegative
	not	ax
skipChar:
	LocalNextChar dsdi
notNegative:
	not	ax
	push	ax		; Save whether result should be positive
	;
	; Convert integer to 16-bit number and store it in the result
	;
	call	AsciiToUnsignedInt
	push	ax				;save integer
	clr	cx
	push	ax
SBCS <	mov	al, ds:[di]						>
DBCS <	mov	ax, ds:[di]						>
	call	IsDecimalSeparator		; Ended on a decimal point?
	pop	ax
	LONG	jne final			; Nope => no fraction

	;
	; Calculcate the fraction part:
	;   (1) Get the fractional part as a normal integer into ax
	;       (4 digits max + 5th digit to round, extras ignored)
	;   (2) Multiply by correct entry in fractionTable (DDFixed Multiply)
	;	Result left in cx
	;
	
	;
	; 1. Get fractional part as integer into ax
	;
	; ax = integer fractional part
	; bx = number of digits - 1 (max 3)
	;
	LocalNextChar	dsdi			; advance to next char
	mov	bx, -1				; start counter at -1
	clr	ax				; clear initial number
readFracLoop:	
SBCS <	clr	cx							>
	LocalGetChar	cx, dsdi, NO_ADVANCE
SBCS <	sub	cl, '0'							>
DBCS <	sub	cx, '0'							>
	jb	fracPart2
	LocalCmpChar	cx, 9
	ja	fracPart2
	inc	bx				; inc digit counter
	LocalNextChar	dsdi			; advance to next char
	
	mov	dx, 10
	mul	dx				; multiply result so far by 10
						; ignore upper word, won't
						; overflow anyway
	
	add	ax, cx				; add in new digit
	
	cmp	bx, 3				; do we already have 4 chars?
	jb	readFracLoop			; no, continue reading
	
	; Here we already have 4 chars.  See if we have a fifth.. if so,
	; then use that to round the number.
	LocalGetChar	cx, dsdi, NO_ADVANCE
SBCS <	sub	cl, '0'							>
DBCS <	sub	cx, '0'							>
	jb	fracPart2
	LocalCmpChar	cx, 9
	ja	fracPart2
	
eatExtraDigits:
	LocalNextChar	dsdi			; advance to next char
	LocalGetChar	dx, dsdi, NO_ADVANCE
	LocalCmpChar	dx, '0'
	jb	checkRound
	LocalCmpChar	dx, '9'
	ja	checkRound
	jmp	short eatExtraDigits
	
checkRound:
	cmp	cl, 5				; check value to round result
	jb	fracPart2
	inc	ax
	
	cmp	ax, 10000			; did we overflow four digits?
	jb	fracPart2
	pop	dx				; YES! Okay, get the integer
	inc	dx				; part into dx and add 1.
	clr	ax				; clear fractional & bail!
	jmp	short unsignedDone
	
	;
	; 2. Multiply by correct table entry
	;
	; ax = integer fractional part
	; bx = number of digits - 1 (max 3)
	;
fracPart2:
	; if ax = 0, then skip the multiply.  Just clear the fractional part
	; and bail.
	tst	ax
	jnz	doMultiply
	clr	cx
	jmp	short final
	
doMultiply:
    	push	ds, si, es, di
	segmov	ds, cs, si
    
    CheckHack < (size DDFixed) eq 8 >
	shl	bx, 1					; calculate index
	shl	bx, 1
	shl	bx, 1
	
	lea	si, cs:[fractionTable][bx]

	; Copy fraction onto stack for FXIP
FXIP <	mov	cx, size DDFixed					>
FXIP <	call	SysCopyToStackDSSIFar					>
	
	segmov	es, ss, di
	sub	sp, size DDFixed			; multiplicand on stack
	mov	di, sp
	mov	es:[di].DDF_int.low, ax
	clr	es:[di].DDF_int.high
	clrdw	es:[di].DDF_frac
	
	call	MulDDF
	add	sp, size DDFixed			; restore stack ptr

FXIP <	call	SysRemoveFromStackFar					>

	; dx:cx = integer result, bx:ax = fractional result
	
	; Check if the fractional result is > .5 (i.e., bx > 8000h, or, sign
	; bit is set.)  If so, then round cx up one.
	
	tst	bx
	jns	doneWithMultiply
	inc	cx
	
doneWithMultiply:
	pop	ds, si, es, di

	; final fractional result is now in cx.
final:
	pop	dx
	mov	ax, cx

unsignedDone:
	;
	; Negate the result if there was a leading '-' on the string.
	;
	pop	cx
	jcxz	negate
done:
	.leave
	ret

negate:
	neg	ax
	not	dx
	cmc
	adc	dx, 0
	jmp	done

LocalAsciiToFixed	endp

; table to convert ascii to word fixed point.  each entry contains the
; conversion to multiply the "integer" fractional part by for a 1, 2, 3, and
; 4 digit fractional part.

fractionTable	label	word
	DDFixed	<39321 + (39321 shl 16), 6553>			;6553.6
	DDFixed <62914 + (23592 shl 16), 655>			;655.36
	DDFixed <19398 + (35127 shl 16), 65>			;65.536
	DDFixed <47815 + (36280 shl 16), 6>			;6.5536
	
Format ends

;------------------------

FileSemiCommon segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalFixedToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a WWFixed number to its ascii equivalent

CALLED BY:	LocalDistanceToAscii
PASS:		es:di	= Place to store result
		dx:ax	= Number to convert
		cx	= number of digits of fraction
RETURN:		Nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalFixedToAscii	proc	far	uses ax, bx, cx, dx, si, di, bp
	.enter

if 	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si					>
EC <	movdw	bxsi, esdi				>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx, si					>
endif

	mov	bp, di			;bp saves buffer address
					;(Moved here from after storeTemp,
					; which seemed like it couldn't
					; possibly work -- es:bp wasn't pointing
					; at the negative sign. -cbh 10/17/92)

	mov	bx, ax			;bx = fraction
	;
	; If the number is negative, store a - at the front and negate the
	; number before we stick it in temp. This allows us to forget about the
	; sign for the rest of the time, unless we round the thing to 0, of
	; course, when we have to be careful not to say something stupid like
	; -0
	;
	tst	dx
	jns	storeTemp
	LocalLoadChar ax, '-'
	LocalPutChar esdi, ax

	clr	ax
	neg	bx			;0 - bx
	sbb	ax, dx
	mov	dx, ax
storeTemp:

	;
	; Convert the integer to ascii first (already in dx)
	;
	push	cx
	call	SignedToAscii
DBCS <	shl	cx, 1							>
	add	di, cx
	LocalPrevChar esdi			;point at null
	pop	cx
	;
	; Now multiply the fraction by 10 (with shifts) until the fraction is
	; 0.
	;
	tst	bx
	jz	done

	call	GetDecimalSeparator	; get decimal separator into al
 	LocalPutChar esdi, ax
	jcxz	round			; if no digits after decimal ...
fracLoop:
	;
	; Multiply the remaining fraction by 10 to get the next digit.
	;
	call	BXTimes10
	LocalPutChar esdi, ax
	tst	bx		; Anything in this fractional word?
	jz	storeNull	; no -- terminate
	loop	fracLoop

round:
	;
	; We ran out of precision. Figure another digit and use that to round
	; the rest of the digits.
	;
	call	BXTimes10

SBCS <	lea	si, [di-1] 	; es:si = last fractional digit		>
DBCS <	lea	si, [di-2] 	; es:si = last fractional digit		>
	std
	LocalCmpChar ax, '5'
	jl	trimZeroes
roundTrimLoop:				;First deal with trailing zeroes caused
					; by rippling in the rounding carry
SBCS <	lodsb	es:							>
DBCS <	lodsw	es:							>
	call	IsDecimalSeparator	;check al
	je	noFractionRoundUp
	inc	ax
	LocalPrevChar esdi		;es:di = byte from which al came in case
					; we need to store it back
	LocalCmpChar ax, <'9'+1>
	jz	roundTrimLoop
		;
		; Have a fractional digit that doesn't need to ripple to
		; the next and, thus, is not 0. Store the adjusted digit back
		; in, setting DI to just after it as the location for the null
		; terminator, then go convert the fractional digits to ascii
		;
saveThisOne:
	cld
	LocalPutChar esdi, ax

storeNull:
SBCS <	clr	al							>
DBCS <	clr	ax							>
	LocalPutChar esdi, ax
done:
	.leave
	ret

noFractionRoundUp:
	mov	ax, 1
noFractionLeft:
	;
	; Need to round the integer up as well. Rather than trying to do it
	; with the already-converted ascii representation, it seems easier
	; to just reconvert an incremented version of the thing.
	;
	cld
	mov	di, bp
	add	dx, ax			; do rounding
SBCS <	cmp	{char} es:[di], '-'	; Number started out negative?	>
DBCS <	cmp	{wchar} es:[di], '-'	; Number started out negative?	>
	jne	reconvert		; No -- just convert

	; Assume we'll reserve the '-', move off of it.  -Added cbh 10/17/92
SBCS <	pushf								>
	LocalNextChar esdi
SBCS <	popf								>

	tst	dx
	jnz	reconvert		; no '-0'
	LocalPrevChar esdi		; nuke negative sign
reconvert:
	call	SignedToAscii
	jmp	done

trimZeroes:
	;
	; Trim any trailing zeroes.
	;
SBCS <	lodsb	es:							>
DBCS <	lodsw	es:							>
	call	IsDecimalSeparator	;check al
	je	noFractionThere
	LocalPrevChar esdi		;es:di = source of al
	LocalCmpChar ax, '0'
	jne	saveThisOne
	jmp	trimZeroes

noFractionThere:
	;
	; Another special case. Don't want to have a '.' if no precision
	; allowed or fraction is actually non-existent. Also don't want
	; to show -0...
	;
	mov	ax, 0		; no increment required
	jmp	noFractionLeft

LocalFixedToAscii	endp

;---------

BXTimes10	proc	near	uses cx, dx
	.enter

	clr	ax
	shl	bx		;*2
	rcl	ax

	mov	dx, ax		;dl:cx = frac * 2
	mov	cx, bx

	shl	bx		;*4
	rcl	ax
	shl	bx		;*8
	rcl	ax

	add	bx, cx
	adc	ax, dx
	add	al, '0'

	.leave
	ret

BXTimes10	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	SignedToAscii

SYNOPSIS:	Converts signed word to ascii.

CALLED BY:	LocalFixedToAscii

PASS:		dx -- value
		es:di -- buffer sufficient to hold number, hopefully

RETURN:		cx -- length of string, including null

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/14/90		Initial version

------------------------------------------------------------------------------@

SignedToAscii	proc	far
	;
	; Add a negative sign if the number is negative
	;
	push	di				;save pointer to our buffer
	tst	dx				;see if negative
	jns	30$				;no, branch
	LocalLoadChar ax, '-'
	LocalPutChar esdi, ax
	neg	dx				;and make positive
30$:
	clr	ax				;clear high word of 32 bit num
	xchg	ax, dx
	mov	cx, mask UHTAF_NULL_TERMINATE	
	call	UtilHex32ToAscii		;es:di <- positive ascii number
	xchg	ax, dx	
	pop	di				;restore pointer to end
	push	di
	mov	cx, -1				;get the length of the string
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	not	cx				;cx holds the length, plus null
	pop	di
	ret
SignedToAscii	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	GetDecimalSeparator, GetDecimalSeparatorInBL

SYNOPSIS:	Returns decimal separator in al.

CALLED BY:	CalcFToA

PASS:		nothing
		direction flag can be set (i.e. I've been forced to deal with
			a set direction flag)

RETURN:		al -- decimal separator char (bl in GetDecimalSeparatorInBL)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 8/91		Initial version

------------------------------------------------------------------------------@

GetDecimalSeparator	proc	near
	push	bx
	call	GetSeparatorInBL
SBCS <	mov	al, bl							>
DBCS <	mov	ax, bx							>
	pop	bx
	ret
GetDecimalSeparator	endp

GetSeparatorInBL	proc	near
	push	cx
	pushf					;save the stupid direction flag
	cld					;clear stupid direction flag
	push	ax, bx, dx
	call	LocalGetNumericFormat
	pop	ax, bx, dx
SBCS <	mov	bl, cl							>
DBCS <	mov	bx, cx							>
	popf					;restore stupid direction flag
	pop	cx
	ret
GetSeparatorInBL	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	IsDecimalSeparator

SYNOPSIS:	Compares value in al to decimal separator.

CALLED BY:	CalcFToA, CalcAToF

PASS:		al -- character to check
		direction flag can be set (i.e. I've been forced to deal with
			a set direction flag)

RETURN:		zero flag set if a match

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 8/91		Initial version

------------------------------------------------------------------------------@
IsDecimalSeparator	proc	far
	push	bx
	call	GetSeparatorInBL
SBCS <	cmp	al, bl							>
DBCS <	cmp	ax, bx							>
	pop	bx
	ret
IsDecimalSeparator	endp


FileSemiCommon ends
