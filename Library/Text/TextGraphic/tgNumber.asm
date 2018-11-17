COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextGraphic
FILE:		tgNumber.asm

METHODS:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	...

	$Id: tgNumber.asm,v 1.1 97/04/07 11:19:38 newdeal Exp $

------------------------------------------------------------------------------@

TextGraphic segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisTextFormatNumber

DESCRIPTION:	Format a number into a buffer

CALLED BY:	INTERNAL

PASS:	(on stack, pushed in this order):
	fptr.char - buffer
	dword - number
	word - VisTextNumberType

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
VISTEXTFORMATNUMBER	proc	far	numType:VisTextNumberType,
					num:dword, buf:fptr.char
						uses ax, bx, cx, dx, di, es
	.enter

EC <	cmp	numType, VisTextNumberType				>
EC <	ERROR_AE	VIS_TEXT_BAD_NUMBER_TYPE			>

	les	di, buf
	movdw	dxax, num

	mov	bx, numType
	cmp	bx, VTNT_NUMBER
	jnz	notNumber
number:
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	jmp	done
notNumber:

	; display 0 as '0', even for letters or roman numerals

	tstdw	dxax
	jz	number

	cmp	bx, VTNT_LETTER_LOWER_A
	ja	roman

	; letter style

	cmpdw	dxax, (26*3)			;if too big then bail
	ja	number
	dec	ax				;zero based
	push	di
	clr	cx				;cx = repeat count
getLetterRepeatCount:
	inc	cx
	sub	ax, 26
	jge	getLetterRepeatCount
	add	ax, 26+'A'
SBCS <	rep	stosb							>
DBCS <	rep	stosw							>
	clr	ax
SBCS <	stosb								>
DBCS <	stosw								>
	pop	di
	cmp	bx, VTNT_LETTER_UPPER_A
	LONG jz	done

	; convert to lower case

convertToLower:
SBCS <	mov	al, es:[di]						>
DBCS <	mov	ax, es:[di]						>
	LocalIsNull ax
	LONG jz	done
SBCS <	sub	al, 'A' - 'a'						>
DBCS <	sub	ax, 'A' - 'a'						>
	LocalPutChar esdi, ax
	jmp	convertToLower

	; roman numeral style

roman:

	cmpdw	dxax, 3000			;bail if too big
	jae	number

	push	di
	mov_tr	cx, ax				;cx = number

	; if num >= 1000 then add M for each 1000

DBCS <	clr	ah							>
	mov	dx, 1000
	mov	al, 'M'
	call	addLetters

	; if num >= 900 then add CM

	cmp	cx, 900
	jb	under900
	mov	al, 'C'
	LocalPutChar esdi, ax
	mov	al, 'M'
	LocalPutChar esdi, ax
	sub	cx, 900
under900:

	; if num >= 500 then add D

	cmp	cx, 500
	jb	under500
	mov	al, 'D'
	LocalPutChar esdi, ax
	sub	cx, 500
under500:

	; if num >= 400 then add CD

	cmp	cx, 400
	jb	under400
	mov	al, 'C'
	LocalPutChar esdi, ax
	mov	al, 'D'
	LocalPutChar esdi, ax
	sub	cx, 400
under400:

	; if num >= 100 then add C for each 100

	mov	dx, 100
	mov	al, 'C'
	call	addLetters

	; if num >= 90 then add XC

	cmp	cx, 90
	jb	under90
	mov	al, 'X'
	LocalPutChar esdi, ax
	mov	al, 'C'
	LocalPutChar esdi, ax
	sub	cx, 90
under90:

	; if num >= 50 then add L

	cmp	cx, 50
	jb	under50
	mov	al, 'L'
	LocalPutChar esdi, ax
	sub	cx, 50
under50:

	; if num >= 40 then add XL

	cmp	cx, 40
	jb	under40
	mov	al, 'X'
	LocalPutChar esdi, ax
	mov	al, 'L'
	LocalPutChar esdi, ax
	sub	cx, 40
under40:

	; if num >= 10 then add X for each 10

	mov	dx, 10
	mov	al, 'X'
	call	addLetters

	; if num >= 9 then add IX

	cmp	cx, 9
	jb	under9
	mov	al, 'I'
	LocalPutChar esdi, ax
	mov	al, 'X'
	LocalPutChar esdi, ax
	sub	cx, 9
under9:

	; if num >= 5 then add V

	cmp	cx, 5
	jb	under5
	mov	al, 'V'
	LocalPutChar esdi, ax
	sub	cx, 5
under5:

	; if num >= 4 then add IV

	cmp	cx, 4
	jb	under4
	mov	al, 'I'
	LocalPutChar esdi, ax
	mov	al, 'V'
	LocalPutChar esdi, ax
	sub	cx, 4
under4:

	; if num >= 1 then add I for each 1

	mov	dx, 1
	mov	al, 'I'
	call	addLetters
	clr	ax
	LocalPutChar esdi, ax
	pop	di
	cmp	bx, VTNT_ROMAN_NUMERAL_UPPER
	LONG jnz convertToLower

done:
	.leave
	ret	@ArgSize

;---

	; cx = num, dx = unit, al = letter
addLetters:
	cmp	cx, dx
	jb	addLetterDone
SBCS <	stosb								>
DBCS <	stosw								>
	sub	cx, dx
	jmp	addLetters
addLetterDone:
	retn

VISTEXTFORMATNUMBER	endp

TextGraphic ends
