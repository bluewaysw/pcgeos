COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		setupSerialNum.asm

AUTHOR:		Cheng, 6/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial revision
	Adam	10/90		Substantial revision to add extended mouse
				driver support.
	brianc	10/92		Copied as template for serial number

DESCRIPTION:

	$Id: setupSerialNum.asm,v 1.1 97/04/04 16:28:14 newdeal Exp $

-------------------------------------------------------------------------------@

SERIAL_NUMBER_BUFFER_SIZE       equ     32


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupSerialNumberEntered

DESCRIPTION:	Verify serial number entered by user.

CALLED BY:	MSG_SETUP_SERIAL_NUMBER_ENTERED

PASS:		ds,es - dgroup

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version
	Adam	10/90		Revised for extended drivers
	brianc	10/92		Modified for serial number

-------------------------------------------------------------------------------@

NUM_SERIAL_DIGITS	equ	16

SBCS <FIRST_CHECKSUM_OFFSET	equ	9				>
SBCS <SECOND_CHECKSUM_OFFSET	equ	19				>
DBCS <FIRST_CHECKSUM_OFFSET	equ	9*(size wchar)			>
DBCS <SECOND_CHECKSUM_OFFSET	equ	19*(size wchar)			>
SBCS <laserSerial	char	"1000-0022-0278-1056",0			>
DBCS <laserSerial	wchar	"1000-0022-0278-1056",0			>

SetupSerialNumberEntered	method	SetupClass, MSG_SETUP_SERIAL_NUMBER_ENTERED

SBCS <destBuffer	local	SERIAL_NUMBER_BUFFER_SIZE dup (char)	>
DBCS <destBuffer	local	SERIAL_NUMBER_BUFFER_SIZE dup (wchar)	>
SBCS <srcBuffer	local	SERIAL_NUMBER_BUFFER_SIZE dup (char)		>
DBCS <srcBuffer	local	SERIAL_NUMBER_BUFFER_SIZE dup (wchar)		>

	.enter

	push	bp
	mov	dx, ss				;DX:BP <- ptr to dest buffer
	lea	bp, srcBuffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, handle SerialNumberEntry
	mov	si, offset SerialNumberEntry
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	segmov	es, ss
	lea	di, destBuffer			;ES:DI <- ptr to dest buffer
	segmov	ds, ss				;DS:SI <- ptr to source buffer
	lea	si, srcBuffer
	tst	cx
	LONG jz	badSerialNumber
	clr	cx				;CX <- serial number current
						; value.
	mov	dx, cx				;DX <- current # digits read
30$:
;	Top of loop:
;		DS:SI <- ptr to next digit in string
;		CH <- checksum #1 (to this point)
;		CL <- checksum #2 (to this point)
;		DL <- # digits read


SBCS <	lodsb								>
SBCS <	tst	al				;If at end of string, branch>
DBCS <	lodsw								>
DBCS <	tst	ax				;If at end of string, branch>
	jz	doneString			;

;	CONVERT ASCII DIGIT TO NUMERAL

;
;	Get one digit at a time, ignoring all non-digits. Add up all the
;	digits, ignoring the 2 checksum digits (digit 8 and digit 16).
;

DBCS <	tst	ah							>
DBCS <	jnz	30$				;ignore if non-numeric	>
	mov	ah, al				;Move digit to AH for
						; conversion from ASCII to 
						; hex.	
	sub	ah, '0'				;Skip if non-numeric
	js	30$				;
	cmp	ah, 9				;
	ja	30$				;
SBCS <	stosb					;Copy over the serial number>
DBCS <	push	ax							>
DBCS <	clr	ah							>
DBCS <	stosw					;Copy over the serial number>
DBCS <	pop	ax							>
	inc	dx				;DX <- # digits read

;	INSERT A DASH EVERY 4TH DIGIT 

	test	dl, 0x03			;Is DX a multiple of 4?
	jnz	40$				;Branch if not.
	cmp	dl, NUM_SERIAL_DIGITS		;If this is the last digit, 
	jae	30$				; do not add a dash, and loop
SBCS <	mov	al, '-'				; back to get the next #>
SBCS <	stosb					;			>
DBCS <	mov	ax, '-'				; back to get the next #>
DBCS <	stosw					;			>
40$:

;
;	See the serial number spec for more information on the checksum
;	generation. I will not go into it in much detail here. 
;

	test	dl, 0x03			;Should we subtract this one?
	jpo	notNeg				;If this is the 3rd or 4th
						; number, we do not subtract.
	neg	ah				;If we should subtract it, 
						; negate the value.
notNeg:
	test	dl, 0x01			;Alternating digits get added/
	jz	secondChecksum			; subtracted to different 
	add	ch, ah				; checksum digits. 
	jmp	30$				;
secondChecksum:
	add	cl, ah				;
	jmp	30$				;
doneString:
SBCS <	clr	al				;Null terminate the string.>
SBCS <	stosb					;			>
DBCS <	clr	ax				;Null terminate the string.>
DBCS <	stosw					;			>
	;
	;ES:DI <- pts to beyond the string in the dest buf (to the null)
	;CX <- sum of all the digits (except the checksums)
	;

;	CHECK TO SEE IF THIS IS THE LASER SERIAL NUMBER

	push	cx, di
	lea	di, destBuffer			;ES:DI <- ptr to serial #
	mov	cx, size laserSerial
	segmov	ds, cs				;DS:SI <- ptr to laser serial
	mov	si, offset laserSerial
	repe	cmpsb
	pop	cx, di
	jz	goodSerialNumber		;If we match the laser serial
						; number, then branch.
	call	CheckIfCannedNumber
	jz	badSerialNumber
	cmp	dx, NUM_SERIAL_DIGITS		;
	jne	badSerialNumber

	test	ch, 0x80			;If either checksum digit is
	jz	firstNotNeg			; negative, convert it to be
	neg	ch				; positive before moding it.
firstNotNeg:
	test	cl, 0x80
	jz	secondNotNeg
	neg	cl
secondNotNeg:
	mov	al, ch				;AL <- first checksum #
	clr	ah
	mov	ch, 10				;
	div	ch				;AL <- first checksum div 10
						;AH <- first checksum mod 10
	add	ah, '0'				;Convert to a digit
	;
	; Compare checksum #2
	;
SBCS <	cmp	ah, ss:[destBuffer][FIRST_CHECKSUM_OFFSET-1] 		>
;DBCS: assume high byte is zero and check low byte only
DBCS <	cmp	ah, {char} ss:[destBuffer][FIRST_CHECKSUM_OFFSET-2]	>
	jne	badSerialNumber			;Whine if mismatch

	mov	al, cl				;AL <- second checksum #
	clr	ah
	div	ch				;AL <- second checksum div 10
						;AH <- second checksum mod 10
	add	ah, '0'				;Convert to a digit
	;
	; Compare checksum #1
	;
SBCS <	cmp	ah, ss:[destBuffer][SECOND_CHECKSUM_OFFSET-1] 		>
;DBCS: assume high byte is zero and check low byte only
DBCS <	cmp	ah, {char} ss:[destBuffer][SECOND_CHECKSUM_OFFSET-2]	>
	jz	goodSerialNumber
	
badSerialNumber:

;	PUT UP THE BAD SERIAL NUMBER BOX

	push	bp
	mov	bp, offset badSerialNumberString
	call	MyError
	pop	bp
	jmp	short exit

;	WE HAVE A GOOD SERIAL NUMBER HERE, SO THANK THE USER AND CONTINUE.

goodSerialNumber:

;	Insert the serial number into the middle of the text	

	push	bp
	mov	cx, ss
	lea	dx, destBuffer
	mov	bx, handle SerialNumberGoodText
	mov	si, offset SerialNumberGoodText
	mov	ax, MSG_STD_REPLACE_PARAM
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, handle SerialNumberGoodScreen
	mov	si, offset SerialNumberGoodScreen
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage
	pop	bp

;	WRITE SERIAL NUMBER TO .INI FILE

	segmov	es, ss
	lea	di, destBuffer
	mov	cx, cs
	mov	ds, cx
	mov	dx, offset serNumKey
	mov	si, offset serNumCategory
	call	InitFileWriteString

exit:

	.leave
	ret
SetupSerialNumberEntered	endm

serNumKey	char	"serialnumber",0
serNumCategory	char	"system",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfCannedNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the # the user entered was one of the canned
		invalid numbers.

CALLED BY:	GLOBAL
PASS:		ES:DI <- pts to beyond the string in the dest buf (to the null)
		ES:BP <- pts to the beginning of the string in the dest buf
		CX <- sum of all the digits (except the checksums)
		DS <- code segment
RETURN:		Z flag set if number was invalid
DESTROYED:	SI
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
zeroSerial	wchar	"0000-0000-0000-0000",0
twoOneSerial	wchar	"2111-1111-1111-1111",0
oneFourSerial	wchar	"1111-1111-1111-1114",0
else
zeroSerial	char	"0000-0000-0000-0000",0
twoOneSerial	char	"2111-1111-1111-1111",0
oneFourSerial	char	"1111-1111-1111-1114",0
endif

CheckIfCannedNumber	proc	near
	uses	di, cx
	.enter
	mov	si, offset zeroSerial
	mov	cx, size zeroSerial
	mov	di, bp
	repe	cmpsb
	je	exit

	mov	di, bp
	mov	cx, size twoOneSerial
	mov	si, offset twoOneSerial
	repe	cmpsb
	je	exit

	mov	di, bp
	mov	cx, size oneFourSerial
	mov	si, offset oneFourSerial
	repe	cmpsb
exit:
	.leave
	ret
CheckIfCannedNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSerialNumberEnterLater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let user do nothing about serial number.

CALLED BY:	MSG_SETUP_SERIAL_NUMBER_ENTER_LATER
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version
	brianc	10/92		Modified for serial number

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSerialNumberEnterLater	method	SetupClass, MSG_SETUP_SERIAL_NUMBER_ENTER_LATER
		.enter
		mov	si, offset InstallDoneText
		call	SetupComplete
		.leave
		ret
SetupSerialNumberEnterLater	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSerialNumberComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge user acknowledgement of good serial number.

CALLED BY:	MSG_SETUP_SERIAL_NUMBER_COMPLETE
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version
	brianc	10/92		Modified for serial number

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSerialNumberComplete	method	SetupClass, MSG_SETUP_SERIAL_NUMBER_COMPLETE
		.enter
		mov	si, offset InstallDoneText
		call	SetupComplete
		.leave
		ret
SetupSerialNumberComplete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupAskForSerialNumber?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if we should ask for serial number.

CALLED BY:	EXTERNAL
			at completion of mouse portion of setup
PASS:		ds = es = dgroup
RETURN:		carry set if we should ask for serial number
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For now, just check of existance of serial number key
		in .ini file.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupAskForSerialNumber?	proc	far
	uses	ax, cx, dx, bp, ds, si, es, di
	.enter
	mov	cx, cs
	mov	ds, cx
	mov	dx, offset serNumKey
	mov	si, offset serNumCategory
	push	ax			; allocate two bytes on stack
DBCS <	push	ax			; allocate space for null	>
	segmov	es, ss			; es:di = word just pushed on stack
	mov	di, sp

	;
	; one byte+null on stack
	;

DBCS <	mov	bp, InitFileReadFlags <IFCC_INTACT,,,4>			>
SBCS <	mov	bp, InitFileReadFlags <IFCC_INTACT,,,2>			>
	call	InitFileReadString	; carry clear if found
	pop	ax			; deallocate
DBCS <	pop	ax							>
					; exit with carry set if we should ask
					;	(i.e. serial number not found)
	.leave
	ret
SetupAskForSerialNumber?	endp
