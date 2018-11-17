COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportUtils.asm

AUTHOR:		Jim DeFrisco, 20 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
    INT EmitStartObject		Create PostScript code for beginning of
				drawn object
    INT EmitEndObject		Create PostScript code at completion of
				drawn object
    INT EmitTransform		Create PostScript code to set the current
				transform
    INT MatrixToAscii		Convert a transformation Matrix into PS
				ascii representation
    INT EmitBuffer		Write out the ascii buffer
    INT DWFixedToAscii		Convert a fixed point number to ascii
    INT WWFixedToAscii		Convert a fixed point number to ascii
    INT ConvertFraction		Convert a one-word fraction to ASCII
    INT SWordToAscii		Convert a signed word integer to ASCII
    INT SDWordToAscii		Convert a signed dword integer to ASCII
    GLB UWordToAscii		Convert an unsigned word to ascii
    GLB ByteToHexAscii		Convert a byte to ascii
    GLB NibbleToHexAscii	Convert a byte to ascii
    INT EmitLineAttributes	Write PostScript code to set line
				attributes
    INT EmitAreaAttributes	Write PostScript code to set area
				attributes
    GLB EmitColor		Set an RGB drawing color
    INT MapRGBForPrinter	Do some color correction
    INT EmitByteFraction	Write out an equation
    INT TransLineCoord		Do translation on a line coordinate and
				write the ascii to a buffer
    INT CreateTempGString	Create a temporary gstring for use in
				element processing
    INT DestroyTempGString	Companion routine to CreateTempGString
    INT ExtractElement		Special routine for use by EmitBitmap
    INT ExtractElement		Copy a gstring object from the current
				gstring to a separate buffer.
    INT CalcStringLength	Caculate the number of characters in a
				string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision
    JMG 2/01        fixed line style to grow with width

DESCRIPTION:
	This file contains code to emit common sections of PostScript code.
		

	$Id: exportUtils.asm,v 1.1 97/04/07 11:25:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportUtils	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitStartObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for beginning of drawn object

CALLED BY:	all the EmitXXXXX routines that correspond to output elements

PASS:		bx	- object type (2* GSTRING_OPCODE - FIRST_OUTPUT_CODE)
		tgs	- TGSLocals structure is inherited

RETURN:		ax	- error code (zero if no error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		emit in the following order:
			%%BeginObject: <type>	
			SO

	NOTE:  	5/24/91  The %%BeginObject part of the code was removed to 
		save on the size of the created files

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitStartObject	proc	far
		uses	cx, dx
tgs		local	TGSLocals
		.enter	inherit

		; if we're in the middle of defining a path, then skip this.

		tst	tgs.TGS_pathgs
		jnz	done

		mov	dx, offset emitSO
		mov	cx, length emitSO
		call	EmitPSCode
		jc	exit

		; if we're exporting a bitmap, then skip clip path.

		push	ds
		segmov	ds, tgs.TGS_options
		test	ds:[PSEB_status], mask PSES_EXPORTING_BITMAP
		pop	ds
		jnz	done

		call	EmitClipPath		; set the current clip path
done:
		clr	ax			; clear it if no error
exit:
		.leave
		ret
EmitStartObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitEndObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code at completion of drawn object

CALLED BY:	all the EmitXXXXX routines that correspond to output elements

PASS:		tgs	- TGSLocals structure is inherited

RETURN:		ax	- error code (zero if no error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		emit in the following order:
			EO
			%%EndObject 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

	NOTE:  	5/24/91  The %%EndObject part of the code was removed to 
		save on the size of the created files

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitEndObject	proc	far
		uses	bx, cx, dx
tgs		local	TGSLocals
		.enter	inherit

		; if going to a path, leave

		tst	tgs.TGS_pathgs
		jnz	done

		mov	dx, offset emitEO
		mov	cx, length emitEO
		call	EmitPSCode
		jc	exit
done:
		clr	ax
exit:
		.leave
		ret
EmitEndObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code to set the current transform

CALLED BY:	all the EmitXXXXX routines that correspond to output elements

PASS:		tgs	- TGSLocals structure is inherited

RETURN:		ax	- error code (zero if no error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		emit in the following order:
			[ matrix array ] SOT

		if we're doing the path transform, and it hasn't changed
		since the last one, then don't output it.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

identMatrix	TransMatrix <>		; struct defined as the identity matrix

EmitTransform	proc	far
		uses	bx, cx, dx, di, es, ds, si
tgs		local	TGSLocals
		.enter	inherit

		; get the current transform

		mov	di, tgs.TGS_pathGState		; get the gstate
		tst	di
		jnz	getXform
		mov	di, tgs.TGS_gstate		; get the gstate
getXform:
		segmov	ds, ss, si
		lea	si, tgs.TGS_matrix		; ds:si -> scratch area
		call	GrGetTransform

		; if we are doing the path thing, and the transform is the
		; same as last time, forget this.  Or if the current matrix
		; is the identity matrix - bail.  (we can only do the these
		; tricks if we're interested in the path matrix)

		segmov	es, ss, di
		tst	tgs.TGS_pathGState		; only check if non-0
		jz	checkMatrix

		push	es, si
		segmov	es, cs, di
		mov	di, offset identMatrix
		mov	cx, (size TransMatrix)/2
		repe	cmpsw
		pop	es, si
		tst	cx
		jnz	checkAgainstOldMatrix
		jmp	done

checkAgainstOldMatrix:
		push	si 
		lea	di, tgs.TGS_pathmatrix		; es:di -> saved one
		mov	cx, (size TransMatrix)/2
		repe	cmpsw
		pop	si
		tst	cx
		jnz	restoreOldMatrix
		jmp	done				; if no change, bail

		; restore the previously saved matrix(before path construction)
		; and save the new matrix
restoreOldMatrix:
		lea	si, tgs.TGS_matrix
		lea	di, tgs.TGS_pathmatrix
		mov	cx, (size TransMatrix)/2
		rep	movsw

		mov	dx, offset emitRPM
		mov	cx, length emitRPM
		call	EmitPSCode

		; check to see that matrix is OK.  If not, fix it.
		; We do some inverse transforms in PostScript.  PS is unhappy
		; about this if the matrix in uninvertible, so look to make
		; sure that it is invertible.
checkMatrix:
		mov	tgs.TGS_xfactor, 1		; assume OK
		mov	tgs.TGS_yfactor, 1
		mov	ax, tgs.TGS_matrix.TM_e11.WWF_int
		or	ax, tgs.TGS_matrix.TM_e11.WWF_frac
		or	ax, tgs.TGS_matrix.TM_e12.WWF_int
		or	ax, tgs.TGS_matrix.TM_e12.WWF_frac
		jnz	xOK
		mov	tgs.TGS_xfactor, 0
		mov	tgs.TGS_matrix.TM_e11.WWF_int, 1
		mov	ax, tgs.TGS_matrix.TM_e22.WWF_int
		or	ax, tgs.TGS_matrix.TM_e22.WWF_frac
		jnz	xOK
		mov	tgs.TGS_matrix.TM_e11.WWF_int, 0
		mov	tgs.TGS_matrix.TM_e12.WWF_int, 1
xOK:
		mov	ax, tgs.TGS_matrix.TM_e22.WWF_int
		or	ax, tgs.TGS_matrix.TM_e22.WWF_frac
		or	ax, tgs.TGS_matrix.TM_e21.WWF_int
		or	ax, tgs.TGS_matrix.TM_e21.WWF_frac
		jnz	yOK
		mov	tgs.TGS_yfactor, 0
		mov	tgs.TGS_matrix.TM_e22.WWF_int, 1
		mov	ax, tgs.TGS_matrix.TM_e11.WWF_int
		or	ax, tgs.TGS_matrix.TM_e11.WWF_frac
		jnz	yOK
		mov	tgs.TGS_matrix.TM_e22.WWF_int, 0
		mov	tgs.TGS_matrix.TM_e21.WWF_int, 1

		; set up pointers to ASCII buffer for translation.  
yOK:
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer		; es:di -> buffer

		; change it to ascii, add SCT command and send it out

		call	MatrixToAscii			; uses internal buffer
		call	EmitBuffer			; send buffer content
		jc	done

		; put out the EndObject call

		mov	dx, offset emitSOT
		mov	cx, length emitSOT
		tst	tgs.TGS_pathGState		; if path, diff opcode
		jz	haveCode
		mov	dx, offset emitSPT
		mov	cx, length emitSPT
haveCode:
		call	EmitPSCode
		jc	done
		clr	ax
done:
		.leave
		ret
EmitTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPSCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to write out some string

CALLED BY:	INTERNAL
PASS:		tgs	- inherited locals
		dx	- offset to string in PSCode resource
		cx	- length of string
RETURN:		carry	- set if some stream error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmitPSCode	proc	far
		uses	bx, ax, ds
tgs		local	TGSLocals
		.enter	inherit

		; lock down the right resource

		mov	bx, handle PSCode
		call	MemLock		; lock it down
		mov	ds, ax				; ds -> PSCode
		mov	bx, tgs.TGS_stream		; get stream block
		call	SendToStream			; write out the comment
		mov	bx, handle PSCode
		call	MemUnlock			; release resource
		jnc	done
		mov	tgs.TGS_writeErr, ax
done:
		.leave
		ret
EmitPSCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatrixToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a transformation Matrix into PS ascii representation

CALLED BY:	INTERNAL
		EmitTransform

PASS:		es:di	- pointer to buffer to store string 
			  (buffer must be at least 52 characters)

RETURN:		es:di	- pointer into TGS_buffer after last character

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MatrixToAscii	proc	far
		uses	ax, bx, cx
tgs		local	TGSLocals
		.enter	inherit

		; di will hold the current offset into the buffer.
		; Start it out at the beginning, and put in the left bracket

		mov	al, '['
		stosb

		; for each real number in the matrix, load it up and write
		; it out.  Separate each number with a space character.
		; Each WWFixed gets loaded into bx.ax

		mov	bx, tgs.TGS_matrix.TM_e11.WWF_int
		mov	ax, tgs.TGS_matrix.TM_e11.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '				; separate w/spaces
		stosb
		mov	bx, tgs.TGS_matrix.TM_e12.WWF_int
		mov	ax, tgs.TGS_matrix.TM_e12.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '
		stosb
		mov	bx, tgs.TGS_matrix.TM_e21.WWF_int
		mov	ax, tgs.TGS_matrix.TM_e21.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '
		stosb
		mov	bx, tgs.TGS_matrix.TM_e22.WWF_int
		mov	ax, tgs.TGS_matrix.TM_e22.WWF_frac
		call	WWFixedToAscii
		mov	al, ' '
		stosb
		mov	cx, tgs.TGS_matrix.TM_e31.DWF_int.high
		mov	bx, tgs.TGS_matrix.TM_e31.DWF_int.low
		mov	ax, tgs.TGS_matrix.TM_e31.DWF_frac
		call	DWFixedToAscii
		mov	al, ' '
		stosb
		mov	cx, tgs.TGS_matrix.TM_e32.DWF_int.high
		mov	bx, tgs.TGS_matrix.TM_e32.DWF_int.low
		mov	ax, tgs.TGS_matrix.TM_e32.DWF_frac
		call	DWFixedToAscii

		; write out the closing bracket 

		mov	al, ']'
		stosb

		.leave
		ret
MatrixToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the ascii buffer

CALLED BY:	INTERNAL
		EmitTransform

PASS:		TGSLocals - inherited stack frame
		di	- pointer into TGS_buffer *after* string to write
			  (string assumed to start at beginning of buffer)
			  ((di-offset tgs.TGS_buffer) #bytes are written)

RETURN:		ax	- error code (zero of no error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitBuffer	proc	far
		uses	ds, dx, cx, bx
tgs		local	TGSLocals
		.enter	inherit

		segmov	ds, ss, dx
		lea	dx, tgs.TGS_buffer
		mov	cx, di
		sub	cx, dx
		mov	bx, tgs.TGS_stream	; get stream block handle
		call	SendToStream		; write out the comment
		jc	recordErr
		clr	ax			; if no error, clear error code
done:
		.leave
		ret
recordErr:
		mov	tgs.TGS_writeErr, ax
		jmp	done
EmitBuffer	endp

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
		je	doneEarly
		ja	fdigitLoop
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

doneEarly:
		inc	{byte} es:[di]
		cmp	{byte} es:[di], '9'
		jbe	resultOK
		mov	{byte} es:[di], '9'
resultOK:
		inc	di
		pop	si			; restore stack
		jmp	done
ConvertFraction		endp

;----------------------------------------------------------------------
;	Fraction Translation Tables
;----------------------------------------------------------------------

;	1/10ths
tenths		word	 6553,  13107, 19660, 26214, 32768 ; 0.1 thru 0.5
		word	39321,  45872, 52428, 58982, 65535 ; 0.6 thru 0.99+

FRAC_TABLE_SIZE	equ $-tenths


;	1/100ths
		word	  655,   1310,  1966,  2621,  3276 ; 0.01 thru 0.05
		word	 3932,   4587,  5242,  5898,  6554 ; 0.06 thru 0.099+

;	1/1000ths
		word	   65,    131,   196,   262,   327 ; 0.001 thru 0.005
		word	  393,    458,   524,   589,   656 ; 0.006 thru 0.0099+

;	1/10000ths
tenthousanths	word	    6,     13,    19,    26,    32 ; 0.0001 thru 0.0005
		word	   39,     45,    52,    58,    66 ; 0.0006 thru 0.00099


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

SWordPlusSpaceToAscii	proc	far
		call	SWordToAscii
		mov	al, ' '
		stosb
		ret
SWordPlusSpaceToAscii	endp

SWordToAscii	proc	far
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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SDWordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a signed dword integer to ASCII

CALLED BY:	INTERNAL
		WWFixedToAscii

PASS:		cxbx	- value to convert
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

SDWordToAscii	proc	far
		uses	bx, cx, dx, ax
		.enter

		; check for negative number, output minus sign if needed

		tst	cx
		jns	doUnsigned
		mov	{byte} es:[di], '-'	; write a minus sign
		inc	di			; bump pointer
		negdw	cxbx			; make it positive
doUnsigned:
		movdw	dxax, cxbx
		clr	cx			; no flags
		call	UtilHex32ToAscii	; now that it is unsigned...
		add	di, cx			; bump by length of string
		.leave
		ret
SDWordToAscii	endp


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

UWordToAscii	proc	far
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
		ByteToHexAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a byte to ascii

CALLED BY:	GLOBAL

PASS:		al	- byte to converyt
		es:di	- location to put string (must be at least 2 chars)

RETURN:		es:di	- points to byte after string

DESTROYED:	ah, bx

PSEUDO CODE/STRATEGY:
		nothing earth-shattering

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ByteToHexAscii	proc	far

		; mask off each nibble, and convert separately

		clr	bh
		mov	bl, al			; get into position
		shr	bl, 1			; do high nibble first
		shr	bl, 1
		shr	bl, 1
		shr	bl, 1
		mov	ah, cs:hexDigits[bx]	; get hex ascii digit
		mov	es:[di], ah		; store it
		inc	di
		mov	bl, al
		and	bl, 0xf			; isolate low nibble
		mov	ah, cs:hexDigits[bx]
		mov	es:[di], ah		; store it
		inc	di

		ret
ByteToHexAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NibbleToHexAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a byte to ascii

CALLED BY:	GLOBAL

PASS:		al	- nibble to convert
		es:di	- location to put string (must be at least 2 chars)

RETURN:		es:di	- points to byte after string

DESTROYED:	ah, bx

PSEUDO CODE/STRATEGY:
		nothing earth-shattering

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NibbleToHexAscii	proc	far

		; mask off each nibble, and convert separately

		clr	bh
		mov	bl, al			; get into position
		and	bl, 0xf			; isolate low nibble
		mov	ah, cs:hexDigits[bx]
		mov	es:[di], ah		; store it
		inc	di

		ret
NibbleToHexAscii	endp

hexDigits	char	"0123456789abcdef"

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitLineAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write PostScript code to set line attributes

CALLED BY:	all the EmitXXXX routines that draw lines

PASS:		ax	- single or multi-line object flag.  Will not set 
			  line join type if single line.

			  ax  = 0 -> single line
			  ax != 0 -> multi-line

RETURN:		ax	- StreamWrite error code (zero for no error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the line width
		set the join type
		set the end type
		set the color
		set the mask 
		set the dash pattern

		this routine only sets those attributes that have changed
		from the defaults, which are:

			line width	1.0
			line join	mitered
			line end	butt end
			line color	black
			line dash	solid
			miter limit	10
			line mask	solid

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		NOTE:	This routine makes use of one of the stack frame
			variables, tgs.TGS_bmType, to record a condition 
			that we have to handle specially.  If the line width
			is zero and there is a draw mask, PostScript will
			barf.  So we set the line style to dotted and ignore
			the mask.  We set this byte to non-zero if this case
			is encountered (it's tested for here, used here and
			elsewhere).

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		JMG     02/01           line style now is relative to width

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitLineAttributes proc	far
		uses	ax, bx, cx, ds, si, es, di
tgs		local	TGSLocals
		.enter	inherit

		push	ax				; save single line flag

		; lock down the right resource

		mov	bx, handle PSCode
		call	MemLock		; lock it down
		mov	ds, ax				; ds -> PSCode

		; check them one at a time...

		mov	di, tgs.TGS_gstate		; load up gstate
		call	GrGetLineWidth			; get current width
		mov	bx, dx				; bxax = line width

		; we have a problem doing zero width lines with a draw mask
		; (cause setstrokepath is unhappy), so we need to catch
		; that case and do something interesting.  In this case,
		; set the line style to dotted and forget the mask.

		clr	tgs.TGS_bmType			; use this for a flag
		or	dx, ax				; check for zero
		jnz	setupBuffer
		call	CheckFullLineMask		; check for draw mask
		jc	setupBuffer			; if solid, we're OK
		inc	tgs.TGS_bmType			;  else set the flag
setupBuffer:
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer		; es:di -> buffer

		; set the line width
		cmp	bx, 1				; is it one ?
		jne	setWidth
		tst	ax
		jz	checkJoin			;  yes, don't set it
setWidth:
		call	WWFixedToAscii			; write out line width
		mov	si, offset emitLW		; add the SL proc
		mov	cx, length emitLW
		rep	movsb				; copy code
		; now set the line join type
checkJoin:
		pop	cx				; restore single line
		jcxz	checkCap			; if single, don't care
		push	di				; save buffer offset
		mov	di, tgs.TGS_gstate		; load up gstate
		call	GrGetLineJoin			; get current join
		pop	di				; restore buffer off
		cmp	al, LJ_MITERED		; if mitered, leave it
		jne	setJoin

		; it's mitered, check to make sure limit is OK

		push	di				; save buffer offset
		mov	di, tgs.TGS_gstate		; load up gstate
		call	GrGetMiterLimit			; get current join
		pop	di				; restore buffer off
		call	WWFixedToAscii
		mov	si, offset emitLM	; write opcode
		mov	cx, length emitLM
		rep	movsb
		jmp	checkCap

setJoin:
		clr	ah				; make it a word
		mov	bx, ax
		call	UWordToAscii
		mov	si, offset emitLJ	; add the SL proc
		mov	cx, length emitLJ
		rep	movsb				; copy code

		; set the line cap type
checkCap:
		push	di				; save buffer offset
		mov	di, tgs.TGS_gstate		; load up gstate
		call	GrGetLineEnd			; get current join
		pop	di				; restore buffer off
		cmp	al, LE_BUTTCAP			; check for default
		je	setDashPattern
		clr	ah
		mov	bx, ax
		call	UWordToAscii
		mov	si, offset emitLC	; add the SL proc
		mov	cx, length emitLC
		rep	movsb				; copy code
		
		; set the style (dashing...)
		; NOTE: The 1.1 kernel does not support return of custom
		; style info.  This code here will revert the style to dashed
		; if there is some custom style.  This should be changed for
		; 2.0
setDashPattern:
		tst	tgs.TGS_bmType			; check for special 
		jz	fetchStyle			;  handling (see above)
		mov	al, LS_DOTTED			;  for draw masked zero
		jmp	haveValidStyle			;  width lines.
fetchStyle:
		push	di
		mov	di, tgs.TGS_gstate		; set up gstate handle
		call	GrGetLineStyle			; al = LineStyle
		pop	di
		cmp	al, LS_CUSTOM		; if custom, more work
		jne	haveValidStyle
		mov	al, LS_DASHED
haveValidStyle:
		cmp	al, LS_SOLID			; if solid, don't send
		je	setLineColor

		; OK, grab the proper offset
                push    di,ax
		mov	di, tgs.TGS_gstate		; load up gstate
		call	GrGetLineWidth		; get current width (we need only DX)
		pop     di,ax
		tst     dx                      ; (minimum factor 1)
		jne     putstyle
		inc     dx
putstyle:
		mov	si, offset emitOpenBracket	; add the open bracket
		mov	cx, length emitOpenBracket
		rep	movsb				; copy code
                dec     al
                clr     ah
                shl     ax,3
                mov     bx,ax
                mov     cl,cs:styleValues[bx]
                clr     ch
stloop:         inc     bx
                mov     al,cs:styleValues[bx]
                clr     ah
                mul     dl
                xchg    ax,bx
                call    UWordToAscii
                mov     bx,ax
                mov	{byte} es:[di], ' '
                inc     di
                loop    stloop
		mov	si, offset emitLD	; finish up dotted style
		mov	cx, length emitLD
		rep	movsb				; copy code

		; set the line color
setLineColor:
		push	di				; save offset
		mov	di, tgs.TGS_gstate		; load up gstate
		call	GrGetLineColor			; get current width
		pop	di				; restore string offset
		call	EmitColor

;
;	NOTE: still have to do mask
;

		; now that we're all done with the attributes, emit a 
		; CRLF combination.

		mov	si, offset emitCRLF
		mov	cx, length emitCRLF
		rep	movsb

		call	EmitBuffer			; write it out

		mov	bx, handle PSCode		; release the block
		call	MemUnlock

		.leave
		ret
EmitLineAttributes endp

; line style patterns (length + 7 bytes, 0-padded)
styleValues db  1,4,0,0,0,0,0,0   ; STYLE_DASHED
            db  2,1,2,0,0,0,0,0   ; STYLE_DOTTED
            db  4,4,4,1,4,0,0,0   ; STYLE_DASHDOT
            db  6,4,4,1,4,1,4,0   ; STYLE_DASHDDOT



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitAreaAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write PostScript code to set area attributes

CALLED BY:	all the EmitXXXX routines that do fills

PASS:		inherits TGSLocals structure

RETURN:		ax	- StreamWrite error code (zero for no error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the area color
		set the pattern mask

		this routine only sets those attributes that have changed
		from the defaults, which are:

			area color	black
			area mask	solid

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitAreaAttributes proc	far
		uses	ax, bx, cx, ds, si, es, di
tgs		local	TGSLocals
		.enter	inherit

		; lock down the right resource

		mov	bx, handle PSCode
		call	MemLock				; lock it down
		mov	ds, ax				; ds -> PSCode

		; check them one at a time...

		mov	di, tgs.TGS_gstate		; load up gstate
		call	GrGetAreaColor			; get current width

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer
		call	EmitColor

		mov	bx, handle PSCode
		call	MemUnlock

		.leave
		ret
EmitAreaAttributes endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an RGB drawing color

CALLED BY:	GLOBAL

PASS:		al	- R
		bl	- G
		bh	- B
		ds	- points to PSCode resource (locked)
		es:di	- points to string buffer

RETURN:		carry	- set if some error
				(ax = error code)
		di	- reset to beginning of buffer if color was written,
			  else left as it was in the beginning.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just output the individual quantities

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitColor	proc	far
		uses	cx, dx, si
tgs		local	TGSLocals
		.enter	inherit

		ForceRef tgs

		mov	ah, al			; check for black
		or	ah, bl
		or	ah, bh
		jz	done			; if black, don't write it

		; map RGB value to another value that looks nicer on 
		; the printer.  This is a kludge for 1.2, but should be
		; elegant and sophisticated for later versions (hee, hee)

		call	MapRGBForPrinter

		; save G and B for now

		mov	dx, bx
		mov	bl, al			; set up as int
		clr	bh
		call	UWordToAscii		; write R
		mov	al, ' '
		stosb
		mov	bl, dl
		clr	bh
		call	UWordToAscii		; write G
		mov	al, ' '
		stosb
		mov	bl, dh
		clr	bh
		call	UWordToAscii		; write B

		mov	si, offset emitSC
		mov	cx, length emitSC
		rep	movsb
		mov	si, offset emitCRLF
		mov	cx, length emitCRLF
		rep	movsb
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset the buffer pointer
done:
		.leave
		ret
EmitColor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapRGBForPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some color correction

CALLED BY:	EmitColor

PASS:		al, bl, bh - RGB value

RETURN:		al, bl, bh - RGB value (corrected for printer)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for 1.2 do a straight mapping.  Later we need something
		more sophisticated

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MapRGBForPrinter	proc	far
		uses	cx, ds, si
		.enter

		; search the default table for a match

		segmov	ds, cs, si
		mov	si, offset defaultB
		mov	cx, 16
scanLoop:
		cmp	bh, ds:[si]		; check for a match
		jne	nextEntry
		cmp	bl, ds:[si+16]		; check green
		jne	nextEntry
		cmp	al, ds:[si+32]		; check red
		je	foundMatch
nextEntry:
		inc	si
		loop	scanLoop
		jmp	done

		; found a match.  reload the values
foundMatch:
		mov	bh, ds:[si+48]		; grab new blue
		mov	bl, ds:[si+64]		; grab new green
		mov	al, ds:[si+80]		; grab new red
		jmp	done
done:
		.leave
		ret
MapRGBForPrinter	endp

; default mapping from kernel.  We search this table for a match
;
defaultB	label	byte
		byte	0x00,0xaa,0x00,0xaa,0x00,0xaa,0x00,0xaa
		byte	0x55,0xff,0x55,0xff,0x55,0xff,0x55,0xff
;defaultG	
		byte	0x00,0x00,0xaa,0xaa,0x00,0x00,0x55,0xaa
		byte	0x55,0x55,0xff,0xff,0x55,0x55,0xff,0xff
;defaultR	
		byte	0x00,0x00,0x00,0x00,0xaa,0xaa,0xaa,0xaa
		byte	0x55,0x55,0x55,0x55,0xff,0xff,0xff,0xff

; DON'T PUT ANYTHING BETWEEN THESE TWO TABLES

; desired kludge mapping to make colors come out better
;
;desiredB	label	byte
		byte	0x00,0xff,0x22,0xbc,0x00,0xff,0x00,0x9a
		byte	0x44,0xff,0x00,0xff,0x9a,0xff,0x00,0xff
;desiredG	
		byte	0x00,0x9a,0xff,0xff,0x00,0x00,0x66,0x9a
		byte	0x44,0xff,0xff,0xff,0x44,0x66,0xff,0xff
;desiredR	
		byte	0x00,0x00,0x55,0x33,0xcd,0x44,0xcd,0x9a
		byte	0x44,0x00,0x77,0x66,0xff,0x9a,0xff,0xff

if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitByteFraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out an equation

CALLED BY:	INTERNAL
		EmitColor

PASS:		bl	- BFixed number
		es:di	- pointer to buffer
		ds	- points to locked PSCode resource

RETURN:		es:di	- point after string written

DESTROYED:	cx, si, bx

PSEUDO CODE/STRATEGY:
		write integer
		write 255
		write div

		NOTE:  needs at least 11 character buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitByteFraction proc	far
		uses	ax
		.enter

		clr	bh
		call	UWordToAscii		; do it
		mov	al, ' '
		stosb
		mov	bl, 255
		call	UWordToAscii		; let PostScript to the math
		mov	si, offset emitDiv
		mov	cx, length emitDiv
		rep	movsb

		.leave
		ret
EmitByteFraction endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransLineCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do translation on a line coordinate and write the ascii
		to a buffer

CALLED BY:	INTERNAL
		EmitDrawLine, EmitDrawRect

PASS:		es:di	- points to buffer to emit
		ax, bx	- coordinate to emit (x,y)
		TGSLocals structure inherited

RETURN:		es:di	- points after the two fixed point values emitted 
			  (a final space character is tacked on)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		translate coordinates
		use WWFixedToAscii to output

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransLineCoord	proc	far
		uses	ax, bx, cx, dx
tgs		local	TGSLocals
		.enter	inherit

		push	di
		mov	di, tgs.TGS_gstate
		mov	dx, ax
		clr	cx
		clr	ax
		call	GrTransformWWFixed
		pop	di			; restore string pointer
		push	bx, ax			; push transformed y coord
		mov	bx, dx
		mov	ax, cx			; get x coord in bx.ax
		call	WWFixedToAscii		; write out x coord
		mov	al, ' '
		stosb
		pop	bx, ax			; restore y coord
		call	WWFixedToAscii		; transform that too
		mov	al, ' '
		stosb

		.leave
		ret
TransLineCoord	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTempGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a temporary gstring for use in element processing

CALLED BY:	INTERNAL
		EmitBitmap, mostly
PASS:		tgs	- inherited local vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTempGString	proc	far
		uses	ax, bx, cx, dx, si, di, ds
tgs		local	TGSLocals
		.enter	inherit

		; destroy any chunk that is there.
		; lock down our scratch block, clear out the scratch chunk

		mov	bx, tgs.TGS_chunk.handle
		call	MemLock			; 
		mov	ds, ax			; ds -> block

		clr	cx			; resize to zero
		mov	ax, tgs.TGS_chunk.chunk	; ax = chunk handle
		tst	ax			; if already zero, bail
		jz	unlockBlock
		call	LMemFree
unlockBlock:
		call	MemUnlock

		; first set up to draw into our buffer

		push	si			; save source GString handle
		mov	cl, GST_CHUNK		; it's a memory type gstring
		call	GrCreateGString		; di = gstring handle
		mov	tgs.TGS_chunk.chunk, si	; store new chunk
		pop	si			; restore source gstring

		mov	tgs.TGS_tempgs, di	;

		.leave
		ret
CreateTempGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyTempGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Companion routine to CreateTempGString

CALLED BY:	INTERNAL
		EmitBitmap
PASS:		tgs	- locals
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyTempGString	proc	far
		uses	di, si
tgs		local	TGSLocals
		.enter	inherit

		; that's all we need, so biff the string

		mov	dl, GSKT_LEAVE_DATA	; don't kill the data
		mov	si, tgs.TGS_tempgs	; si = GString handle
		clr	di			; di = GState handle (0)
		call	GrDestroyGString
		
		clr	tgs.TGS_tempgs		; set to zero

		.leave
		ret
DestroyTempGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special routine for use by EmitBitmap

CALLED BY:	INTERNAL
PASS:		tgs	- inherited locals
		si	- gstring handle
RETURN:		ds:si	- pointer to next part of data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtractElement		proc	far
		uses	di, dx, cx, bx, ax
tgs		local	TGSLocals
		.enter	inherit

		; lock down our scratch block, clear out the scratch chunk

		mov	bx, tgs.TGS_chunk.handle
		call	MemLock			; 
		mov	ds, ax			; ds -> block
		clr	cx			; resize to zero

		; this has to work with either a path or the real gstring.

		mov	ax, tgs.TGS_pathchunk	; ax = chunk handle
		mov	di, tgs.TGS_pathgs	; get temp gstring.
		tst	di
		jnz	reallocChunk
		mov	ax, tgs.TGS_chunk.chunk	; ax = chunk handle
		mov	di, tgs.TGS_tempgs	; get temp gstring.
reallocChunk:
		push	ax			; save chunk handle
		call	LMemReAlloc
		call	MemUnlock

		; now draw the one element into our buffer

		mov	dx, mask GSC_ONE or mask GSC_PARTIAL ; return after 1
		call	GrCopyGString
		mov	tgs.TGS_emitRetType, dx	; store GSRetType

		; set up a pointer to the data

		mov	bx, tgs.TGS_chunk.handle
		call	MemLock			; 
		mov	ds, ax
		pop	si			; restore chunk handle
		mov	si, ds:[si]		; ds:si -> data

		.leave
		ret
ExtractElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Caculate the number of characters in a string
CALLED BY:	INTERNAL
		various routines

PASS:		ds:dx	- ptr to string
RETURN:		cx	- number of characters in string (not including NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		guess.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		carry is always returned clear

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcStringLength	proc	far
	uses	ax, ds, es, di
	.enter

	segmov	es, ds, di
	mov	di, dx				; es:di <- ptr to string
	mov	cx, PATH_BUFFER_SIZE		; cx <- our largest string
	clr	al				; al <- looking for null
	repne	scasb				; find it 
	sub	di, dx				; di = #chars into string
	mov	cx, di
	dec	cx
						; carry always clear on exit
	.leave
	ret
CalcStringLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data to stream

CALLED BY:	INTERNAL

PASS:		bx	= handle of EPSExportLowStreamStruct
		cx	= number of bytes to write
		ds:dx	= buffer from which to write

RETURN:		carry set if error:
			ax	= STREAM_SHORT_READ_WRITE (possible disk full)
		carry clear if no error:
			ax	= destroyed
			cx 	= number of bytes written

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EY	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToStream	proc	far
	uses	bx,dx,si,di,es
	.enter
ifdef PRINT_TO_FILE
	;
	; Write to the file instead...
	;
		mov	al, FILE_NO_ERRORS
		call	FileWrite			
else
		
	call	MemLock
	push	bx				; save block handle

	mov	es, ax				; es - Port segment
	mov	di, DR_STREAM_WRITE		; stream driver function #
	mov	ax, STREAM_BLOCK		; wait for it
	mov	bx, es:[ESPELSS_token]		; get stream token
	mov	si, dx				; ds:si - buffer
	call	es:[ESPELSS_strategy]		; make the call

	pop	bx				; restore block handle
	call	MemUnlock
endif
		
	.leave
	ret
SendToStream	endp

ExportUtils	ends
