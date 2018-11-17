
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptUtils.asm

AUTHOR:		Jim DeFrisco, 6 March 1991

ROUTINES:
	Name			Description
	----			-----------
	EmitTransform		convert a transformation matrix to ascii

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/91		Initial revision


DESCRIPTION:
	This code implements some support routines for writing out PostScript
	code.
		

	$Id: pscriptUtils.asm,v 1.1 97/04/18 11:56:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code to set the current transform

CALLED BY:	all the EmitXXXXX routines that correspond to output elements

PASS:		ds:si	- pointer to TransMatrix structure
		di	- file handle to write to
		dx	- options block handle
		es	- PState segment

RETURN:		carry	- set if some error returned from TransExportRaw

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		emit in the following order:
			[ matrix array ] SDT

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitTransform	proc	near
		uses	ax, bx, cx, di, es, ds, si
scratchBuffer	local	60 dup(char)
		.enter

		; grab EPS library handle out of PState

		mov	bx, es:[PS_epsLibrary]

		; set up pointers to ASCII buffer for translation

		push	di				; save file handle
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer

		; change it to ascii, add SCT command and send it out

		call	MatrixToAscii			; uses internal buffer
		segmov	ds, cs, si
		mov	si, offset emitSPT
		mov	cx, length emitSPT
		rep	movsb
		segmov	ds, ss, si
		lea	si, scratchBuffer		; ds:si -> buffer
		sub	di, si				; di = #chars to write
		mov	cx, di
		pop	di				; restore file handle
		mov	ax, TR_EXPORT_RAW		; routine to call
		call	CallEPSLibrary			; send buffer content

		.leave
		ret
EmitTransform	endp

emitSPT		char	" SPT", NL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write some PostScript code to set the paper size

CALLED BY:	INTERNAL
		PrintSetPageTransform

PASS:		bp	- points at locked PState
		di	- file handle to write to

RETURN:		nothing

DESTROYED:	ds

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPaperSize	proc	far
		uses	bx, cx, di, es, si, dx, ax
scratchBuffer	local	60 dup(char)
		push	ds
		mov	ds, bp				; ds -> PState
		.enter					;  before bp trashed

		; set up pointers to ASCII buffer for translation

		push	ds:[PS_epsLibrary]		; save library handle
		push	di				; save file handle
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer

		; change it to ascii, add SCT command and send it out

		mov	cx, ds:[PS_customWidth]	; get width and height
		mov	dx, ds:[PS_customHeight] 

		; cx = width, dx = height

		push	dx				; save height
		mov	bx, cx				; convert width
		call	UWordToAscii			; convert to ascii
		mov	al, ' '				; space separator
		stosb
		pop	bx				; restore height
		call	UWordToAscii			; convert that too
		segmov	ds, cs, si
		mov	si, offset emitSPS
		mov	cx, length emitSPS
		rep	movsb
		segmov	ds, ss, si
		lea	si, scratchBuffer		; ds:si -> buffer
		sub	di, si				; di = #chars to write
		mov	cx, di
		pop	di				; restore file handle
		pop	bx				; restore library han
		mov	ax, TR_EXPORT_RAW
		call	CallEPSLibrary

		.leave
		pop	ds
		ret
EmitPaperSize	endp

emitSPS		char	" SPS", NL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatrixToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a transformation Matrix into PS ascii representation

CALLED BY:	INTERNAL
		EmitTransform

PASS:		es:di	- pointer to buffer to store string 
			  (buffer must be at least 52 characters)
		ds:si	- points to TransMatrix structure

RETURN:		es:di	- pointer into buffer after last character

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		change each fixed point element into ascii and create a
		PostScript array in the following format

		[1.23435 1.2345 1.2345 1.2345 1.2345 1.2345]

		The conversion code will optimize for creating the smallest
		string possible.  This means that numbers that can be
		represented by integers will not include four significant
		figures after the decimal point.  A maximum of four digits after
		the decimal point will be used when necessary.  
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version
		jim	3/91		copied/altered from Translation lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MatrixToAscii	proc	near
		uses	ax, bx, cx
		.enter	

		; di will hold the current offset into the buffer.
		; Start it out at the beginning, and put in the left bracket

		mov	al, '['
		stosb

		; for each real number in the matrix, load it up and write
		; it out.  Separate each number with a space character.
		; Each WWFixed gets loaded into bx.ax

		mov	bx, ds:[si].TM_e11.WWF_int
		mov	ax, ds:[si].TM_e11.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '				; separate w/spaces
		stosb
		mov	bx, ds:[si].TM_e12.WWF_int
		mov	ax, ds:[si].TM_e12.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '
		stosb
		mov	bx, ds:[si].TM_e21.WWF_int
		mov	ax, ds:[si].TM_e21.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '
		stosb
		mov	bx, ds:[si].TM_e22.WWF_int
		mov	ax, ds:[si].TM_e22.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '
		stosb
		mov	cx, ds:[si].TM_e31.DWF_int.high
		mov	bx, ds:[si].TM_e31.DWF_int.low
		mov	ax, ds:[si].TM_e31.DWF_frac
		call	DWFixedToAscii
		mov	al, ' '
		stosb
		mov	cx, ds:[si].TM_e32.DWF_int.high
		mov	bx, ds:[si].TM_e32.DWF_int.low
		mov	ax, ds:[si].TM_e32.DWF_frac
		call	DWFixedToAscii

		; write out the closing bracket 

		mov	al, ']'
		stosb

		.leave
		ret
MatrixToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DWFixedToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a fixed point number to ascii

CALLED BY:	INTERNAL
		MatrixToAscii

PASS:		cxbxax	- DWFixed number
		es:di	- points at buffer of where to store ascii for number

RETURN:		es:di	- points at first byte after the number written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		convert the number, using as few digits as possible.  Integer
		representation is used where possible.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DWFixedToAscii	proc	far
		uses	cx, dx, si, ax, bx
		.enter	

		; check for negative number
		; if there is any fractional part, then increment the
		; integer part, since the fractional part is added to the 
		; negative number, making the integer part less negative...

		tst	cx
		jns	checkForMaxFrac
		mov	{byte} es:[di], '-'	; do minus sign ourselves
		inc	di

		negdwf	cxbxax			; negate WWFixed number

		; check for .9999+ and round here
		; 65530 is the lowest value that will round to 1.0
checkForMaxFrac:
		cmp	ax, FRAC_MAXIMUM	; see if we will round up anyway
		jb	doInteger
		clr	ax			; forget fraction and..
		incdw	cxbx			; ..increase integer
doInteger:
		push	ax
		movdw	dxax, cxbx
		clr	cx
		call	UtilHex32ToAscii	; convert remaining unsigned 
		add	di, cx			; bump pointer
		pop	ax

		call	ConvertFraction		; convert fractional part

		.leave
		ret
DWFixedToAscii	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WWFixedToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a fixed point number to ascii

CALLED BY:	INTERNAL
		MatrixToAscii

PASS:		bx.ax	- WWFixed number
		es:di	- points at buffer of where to store ascii for number

RETURN:		es:di	- points at first byte after the number written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		convert the number, using as few digits as possible.  Integer
		representation is used where possible.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FRAC_MINIMUM	equ	3	; smallest fraction (less than this = 0.0)
FRAC_MAXIMUM	equ	65530	; largest fraction (more than this = 1.0)

WWFixedToAscii	proc	far
		uses	cx, dx, si, ax, bx
		.enter	

		; check for negative number
		; if there is any fractional part, then increment the
		; integer part, since the fractional part is added to the 
		; negative number, making the integer part less negative...

		tst	bx
		jns	checkForMaxFrac
		mov	{byte} es:[di], '-'	; do minus sign ourselves
		inc	di

		neg	ax			; negate WWFixed number
		not	bx
		cmc
		adc	bx, 0

		; check for .9999+ and round here
		; 65530 is the lowest value that will round to 1.0
checkForMaxFrac:
		cmp	ax, FRAC_MAXIMUM	; see if we will round up anyway
		jb	doInteger
		clr	ax			; forget fraction and..
		inc	bx			; ..increase integer
doInteger:
		call	UWordToAscii		; convert remaining unsigned 
		
		; time to do the fractional part...

		call	ConvertFraction		; write out fractional part

		.leave
		ret
WWFixedToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertFraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a one-word fraction to ASCII

CALLED BY:	INTERNAL
		WWFixedToAscii, DWFixedToAscii
PASS:		ax	- fraction to convert
		es:di	- buffer pointer
RETURN:		es:di	- points past converted ascii fraction
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertFraction		proc	near
		.enter
		; first check for no fraction
		; the value 3 == 0.00005 is the lowest significant value

		cmp	ax, FRAC_MINIMUM	; check for null fraction
		jb	done
		mov	{byte} es:[di], '.'	; add decimal point
		mov	si, offset cs:tenths	; cs:si -> tenths table
doNextFracDigit:
		inc	di
		cmp	ax, FRAC_MINIMUM	; check for null fraction
		jb	done
		mov	{byte} es:[di], '0'	; init next digit
		push	si			; save offset
		cmp	ax, cs:[si]		; check if any tenths
		jb	doneFDigit
fdigitLoop:
		inc	{byte} es:[di]
		add	si, 2
		cmp	ax, cs:[si]		; see if at least a tenth
		jae	fdigitLoop
		sub	ax, cs:[si-2]
doneFDigit:
		pop	si			; restore pointer
		add	si, FRAC_TABLE_SIZE	; skip 10 words
		cmp	si, offset tenthousanths ; done ?
		jbe	doNextFracDigit
		inc	di

		cmp	{byte} es:[di-1], '9'
		ja	roundIt
		cmp	ax, FRAC_MINIMUM	; check for need to round
		jb	done
		inc	{byte} es:[di-1]		; bump to next digit
		cmp	{byte} es:[di-1], '9'	; round up ?
		jbe	done
roundIt:
		mov	{byte} es:[di-1], '0'
		inc	{byte} es:[di-2]	; bump to next digit
		cmp	{byte} es:[di-2], '9'	; round up ?
		jbe	done
		mov	{byte} es:[di-2], '0'
		inc	{byte} es:[di-3]	; bump to next digit
		cmp	{byte} es:[di-3], '9'	; round up ?
		jbe	done
		mov	{byte} es:[di-3], '0'
		inc	{byte} es:[di-4]	; bump to next digit
done:
		.leave
		ret
ConvertFraction		endp

;----------------------------------------------------------------------
;	Fraction Translation Tables
;----------------------------------------------------------------------

;	1/10ths
tenths		word	 6553,  13107, 19660, 26214, 32768 ; 0.1 thru 0.5
		word	39321,  45872, 52428, 58982, 65535 ; 0.6 thru 0.99+

FRAC_TABLE_SIZE	equ $-tenths


;	1/100ths
;hundreths	
		word	  655,   1310,  1966,  2621,  3276 ; 0.01 thru 0.05
		word	 3932,   4587,  5242,  5898,  6553 ; 0.06 thru 0.099+

;	1/1000ths
;thousanths	
		word	   65,    131,   196,   262,   327 ; 0.001 thru 0.005
		word	  393,    458,   524,   589,   655 ; 0.006 thru 0.0099+

;	1/10000ths
tenthousanths	word	    6,     13,    19,    26,    32 ; 0.0001 thru 0.0005
		word	   39,     45,    52,    58,    65 ; 0.0006 thru 0.00099


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SWordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a signed word integer to ASCII

CALLED BY:	INTERNAL
		WWFixedToAscii

PASS:		bx	- value to convert
		es:di	- buffer to write to

RETURN:		es:di	- points after word written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		writes minus sign, if neccesary
		omits leading zeroes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SWordToAscii	proc	near
		uses	bx
		.enter

		; check for negative number, output minus sign if needed

		tst	bx
		jns	doUnsigned
		mov	{byte} es:[di], '-'	; write a minus sign
		inc	di			; bump pointer
		neg	bx			; make it positive
doUnsigned:
		call	UWordToAscii		; now that it is unsigned...
		.leave
		ret
SWordToAscii	endp
ForceRef	SWordToAscii


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UWordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an unsigned word to ascii

CALLED BY:	GLOBAL

PASS:		bx	- unsigned word
		es:di	- location to put string (must be at least 7 chars)

RETURN:		es:di	- points to byte after string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		nothing earth-shattering

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UWordToAscii	proc	near
		uses	ax, bx, si, dx
		.enter

		; check for 0 and 1 since they are so popular...

		mov	{byte} es:[di], '0'	; always need at least one zero
		tst	bx			; if this is zero, all done
		jz	trivialDone
		cmp	bx, 1			; check for 1 too...
		jne	doInteger
		inc	{byte} es:[di]		; make it a '1'
trivialDone:
		inc	di			; bump past the one
		jmp	done

		; OK, no easy out.  Set up some translation regs
doInteger:
		mov	ax, 10000		; cx is kind of a divisor
		mov	si, 10
		clr	dx

		; skip leading zeroes
skipZeroes:
		cmp	bx, ax			; get down to where it matters
		jae	digitLoop
		div	si
		tst	ax			; if not zero yet, keep going
		jnz	skipZeroes
		jmp	done

		; convert the remaining integer part
digitLoop:
		sub	bx, ax			; do next digit
		jb	nextDigit		
		inc	{byte} es:[di]		; bump number
		jmp	digitLoop
nextDigit:
		inc	di			; onto next digit place
		add	bx, ax			; add it back in
		div	si
		tst	ax			; if zero
		jz	done			; done, do fraction part
		mov	{byte} es:[di], '0'	; init next digit
		jmp	digitLoop		; continue
done:		
		.leave
		ret
UWordToAscii	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallEPSLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a call into the EPS library

CALLED BY:	EXTERNAL
PASS:		ax	- TransRoutine enum, including extentions for EPS lib
		bx	- EPS library handle
RETURN:		depends on routine
DESTROYED:	depends on routine

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallEPSLibrary	proc	far
		.enter
		call	ProcGetLibraryEntry	; bxax = virtual far pointer
		call	ProcCallFixedOrMovable
		.leave
		ret
CallEPSLibrary	endp

CommonCode	ends
