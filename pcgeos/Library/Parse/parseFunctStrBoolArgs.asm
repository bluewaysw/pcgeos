COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Parse Library
FILE:		parseFunctStrBoolArgs.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of parseFunctions.asm

DESCRIPTION:

Expected behavior of routines:
------------------------------

	A function is called with a list (possibly empty) of arguments
	on the argument stack.  These entries describe what arguments
	have been passed and in the case of numbers, they will have
	corresponding floating point numbers on the floating point stack.

	The function routine then uses these arguments to compute the
	desired result.

	Ranges are processed by calling DoRangeEnum, passing along
	a callback routine that will process each cell in the range.  

	The functionEnv stack frame should be initialized if any ranges
	are expected.

	When a result is computed, the original arguments are popped
	off and a new descriptor of the result pushed on.  If the
	result is a number, the number will be on the fp stack.  If
	the result is a string, the string will be part of the
	argument descriptor.

Error handling:
---------------
	
	When an error is encountered, the error is propagated via
	PropogateError.  This routine pops the arguments off the
	stacks and pushes on an error descriptor.  Only if a severe
	error occurs, like if PropogateError were unable to complete
	its task, will it return with the carry flag set.  The function
	bails out in such an event.

	Since PropogateError clears the stack and the carry flag,
	deciding when to place the call is important. We don't
	want to do it at a low level because we will then need
	to propagate the fact that an error has been propagated
	upwards through all the callers. This propagation will be
	complicated by the fact that PropogateError can itself return
	an error.

	We therefore adopt the convention that errors will trigger
	the carry flag to be set with the error code placed in al.
	Routines should then bail out whenever one of its subroutines
	return an error.  The routine that makes the call to PropogateError
	will be the highest level function routine.

	$Id: parseFunctStrBoolArgs.asm,v 1.1 97/04/05 01:27:35 newdeal Exp $

-------------------------------------------------------------------------------@

EvalCode	segment resource

;*******************************************************************************
;	ROUTINES THAT OPERATE ON STRINGS
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionChar

DESCRIPTION:	Implements the CHAR() function
		CHAR(x) returns the character that the PC/GEOS character
		set code x produces.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Under DBCS, you can convert any printable char.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionChar	proc	near	uses	dx
	.enter
	call	FunctionCheck1NumericArg
	jc	done			; branch if wrong number of arguments

	call	FloatFloatToDword	; dx:ax <- int

	tst	dx			; illegal number?
	jne	badValue		; branch if so

SBCS<	cmp	ax, 256			; ASCII Limit			>
SBCS<	jge	badValue						>

if PZ_PCGEOS
	push	bx			; LocalDosToGeosChar destroys this
	mov	bx, CODE_PAGE_SJIS	; DosCodePage to use
EC <	tst	dx			; dx <- 0 (primary FSD)		>
EC <	ERROR_NZ	FUNCTION_ASSERTION_FAILED			>
	call	LocalDosToGeosChar	; Convert the SJIS char to Geos
	pop	bx			; restore 
	jc	badValue		; if so, then SJIS out of range
endif

	call	LocalIsPrintable
	jz	badValue

	;
	; legal code, create an argument descriptor of type string
	;
	; Now we create the string on the stack and pass a pointer to it
	;

	call	Pop1Arg			; lose number

	push	ds, si, cx		; Save stuff we munch

	push	ax			; On stack now: char
	segmov	ds, ss, si		; ds:si <- ptr to string
	mov	si, sp
SBCS<	mov	cx, (size char) 	; cx <- size of string		>
DBCS<	mov	cx, (size wchar)	; cx <- size of string		>
					
	call	ParserEvalPushStringConstant  ; Push the string
					; carry set on error, al <- error code

	pop	cx			; Restore stack (preserves flags)
	pop	ds, si, cx		; Restore munched registers
	jc	done			; branch on error

	jmp	short quit		; Branch if no error

badValue:
	mov	al, PSEE_NUMBER_OUT_OF_RANGE
	stc
done:
	jnc	quit

	call	PropogateError

quit:
	.leave
	ret
FunctionChar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionClean

DESCRIPTION:	Implements the CLEAN() function
		CLEAN(string) removes control characters from a string.

		Hmmm, can a control character ever find its way into
		one of the strings???  Perhaps from an imported file...

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		This routine can only be tested by forcing bad input.
		You can bypass the error checking in CHAR(), or munge an
		input file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/93		Actually implemented

-------------------------------------------------------------------------------@

FunctionClean	proc	near
if DBCS_PCGEOS
	uses	cx, dx, ds, si, di, bp
	mov	ax, bp
	FC_local	local	strBuf
	.enter

	mov	FC_local.SB_saveBP, ax

	call	FunctionCheck1StringArg
	jc	errDone			; branch if wrong number of arguments

	;-----------------------------------------------------------------------
	; check string

	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length
	jcxz	doneOK			; nothing to clean!

	cmp	cx, MAX_STRING_LENGTH
	ja	strTooLong		; branch if overflow

	push	es

	segmov	ds, es, si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2
	segmov	es, ss, di
	lea	di, FC_local.SB_buf
	mov	dx, di			; save for length computation

	;-----------------------------------------------------------------------
	; Scrubbing time
	;	ds:si = ptr to source
	;	es:di = ptr to dest (FC_locals.SB_buf)
	;	dx  =  saved ptr to dest (for length count)
	;	cx = length of result string (cx > 0)
scrubLoop:
	LocalGetChar	ax, dssi
	call	LocalIsPrintable
	jz	scrubNext		; skip the non-printables..

	LocalPutChar	esdi, ax	; store printable chars only

scrubNext:
	loop	scrubLoop

	mov	cx, di
	sub	cx, dx			; cx <- size of result
DBCS<	shr	cx, 1			; cx <- length of result	>

	pop	es

	call	ReplaceWithString
	jmp	short doneOK

strTooLong:
	mov	al, PSEE_GEN_ERR
	stc
	
errDone:
	call	PropogateError

doneOK:
	.leave
	ret
else
	mov	al, 1
	call	FunctionCheckNArgs
	jnc	done			; branch if wrong number of arguments

	call	PropogateError
	ret

done:
	clc
	ret
endif
FunctionClean	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionCode

DESCRIPTION:	Implements the CODE() function
		CODE(string) returns the PC/GEOS character set code that
		corresponds to the first character in string.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionCode	proc	near
	call	FunctionCheck1StringArg
	jc	done

	;
	;  Grab the first character.  If no string, we grab the NULL.
	;
if DBCS_PCGEOS
	mov	ax, {wchar} es:[bx].ASE_data.ESAD_string.ESD_length+2
else
	mov	al, {char} es:[bx].ASE_data.ESAD_string.ESD_length+2
	clr	ah
endif

if PZ_PCGEOS
	push	dx, bx
	mov	bx, CODE_PAGE_SJIS	;DosCodePage
	clr	dx			;Disk Handle = 0
	call	LocalGeosToDosChar	;Convert ax to SJIS value
	jnc	goodChar		;jmp if no error in conversion
		
	;error in conversion	

	mov	al, PSEE_NUMBER_OUT_OF_RANGE
	jmp	donePop

	;  In the case of DB SJIS chars, values returned from
	;  LocalGeosToDosChar have the MSB of ax set.
	;  Since FloatWordToFloat treats ax as a signed value,
	;  we would always get a negative float returned.  Since 
	;  we don't want this, clear dx and convert a double word
	;  to float instead.

goodChar:
	clr	dx			;High word is 0.
	call	FloatDwordToFloat
donePop:
	pop	dx, bx
else	
	call	FloatWordToFloat
endif

done:
	GOTO	FunctionCleanUpNumOp
FunctionCode	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionExact

DESCRIPTION:	Implements the EXACT() function
		EXACT(string1, string2) tests whether string1 and string2
		are the same.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionExact	proc	near
	push	cx,si

	;-----------------------------------------------------------------------
	; see that 2 string args exist

	mov	al, 2
	call	FunctionCheckNArgs
	jc	done

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	jc	done

	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length	; cx <- len(s2)

	push	bx				; save stk pointer
	call	Pop1Arg

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	mov	si, es:[bx].ASE_data.ESAD_string.ESD_length	; si <- len(s1)
	pop	bx				; restore stk pointer
	jc	done

	;-----------------------------------------------------------------------
	; compare their lengths

	cmp	cx, si
	jne	notEqual

	jcxz	equal

	;-----------------------------------------------------------------------
	; comparison required
	; cx = length

	push	bx,ds,es,di

	segmov	ds,es,si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2	; ds:si <- s2

	call	Pop1Arg
	lea	di, es:[bx].ASE_data.ESAD_string.ESD_length+2	; es:di <- s1

SBCS<	repe	cmpsb						>
DBCS<	repe	cmpsw						>

	pop	bx,ds,es,di

	je	equal

notEqual:
	call	Float0
	jmp	short done

equal:
	call	Float1

done:
	pop	cx,si
	GOTO	FunctionCleanUpBooleanOp
FunctionExact	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionFind

DESCRIPTION:	Implements the FIND() function
		FIND(search-string, string, start-number) calculates the
		position in string at which the first occurence of
		search-string is found.  FunctionFind begins searching
		at the position indicated by start-number.

		NOTE:
		-----

		* start-number is an offset. Ie. 0 is the first character
		* the search is case-sensitive
		* if the search is unsuccessful, an error is returned

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	The algorithm employed currently is n^2 but I figure this
	routine won't be:
	    1) invoked often enough
	    2) invoked with lengthy strings
	for a faster algorithm to make a significant difference.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FindData	struct
	searchLen	word	; length of search string
	searchPtr	word	; offset to search string
	stringLen	word	; length of string
	stringPtr	word	; offset to string
	stringPtrBak	word	; offset to string
FindData	ends

FunctionFind	proc	near
	FF_local	local	FindData

	.enter

	;-----------------------------------------------------------------------
	; check arguments

	mov	al, 3
	call	FunctionCheckNArgs
	LONG jc	done

	mov	al, mask ESAT_NUMBER
	call	FunctionCheckArgType
	LONG jc	done

	push	bx
	call	Pop1Arg
	mov	al, mask ESAT_STRING		; check string
	call	FunctionCheckArgType
	jc	10$

	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	mov	FF_local.stringLen, ax
	lea	ax, es:[bx].ASE_data.ESAD_string.ESD_length+2
	mov	FF_local.stringPtr, ax
	mov	FF_local.stringPtrBak, ax

	call	Pop1Arg
	mov	al, mask ESAT_STRING		; check search-string
	call	FunctionCheckArgType
	jc	10$

	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	mov	FF_local.searchLen, ax
	lea	ax, es:[bx].ASE_data.ESAD_string.ESD_length+2
	mov	FF_local.searchPtr, ax

10$:
	pop	bx
	jc	done

	;-----------------------------------------------------------------------
	; more error checking...
	; al = offset, string length - offset = number of bytes to search

	push	bx,cx,ds,di,si
	call	StringOpGetIntArg		; ax <- int, carry if error
	jc	20$

DBCS<	shl	ax, 1				; ax <- byte offset to start >
	add	FF_local.stringPtr, ax		; else search from this location

	cmp	FF_local.searchLen, 0
	je	20$

	mov	cx, FF_local.stringLen
DBCS<	shr	ax, 1				; ax <- char offset	>
	sub	cx, ax				; cx <- num chars to search
	jl	20$

	;-----------------------------------------------------------------------
	; work...

	segmov	ds, es, si
	mov	di, FF_local.stringPtr
	mov	si, FF_local.searchPtr
	LocalGetChar	ax, dssi, NO_ADVANCE	; al <- first char of search str
SBCS<	inc	FF_local.searchPtr				>
DBCS<	add	FF_local.searchPtr, (size wchar)		>
	dec	FF_local.searchLen

searchLoop:
	jcxz	20$				; error if no more chars in str
	LocalFindChar
	jne	20$

	;
	; first char located, do string comparison
	;
	cmp	cx, FF_local.searchLen		; impossible match?
	jl	20$				; branch if so

	push	cx,di
	mov	cx, FF_local.searchLen
	tst	cx				; any chars left in search-str
	je	15$				; branch if not (Z flag is set)
	mov	si, FF_local.searchPtr
SBCS<	repe	cmpsb						>
DBCS<	repe	cmpsw						>
15$:
	pop	cx,di

	;
	; Z flag at this point may be set by either the "tst cx"
	; or the "repe cmpsb".  In either case, Z=1 => match
	;
	jne	searchLoop			; loop if no match

	;-----------------------------------------------------------------------
	; result known

	LocalPrevChar	esdi
	sub	di, FF_local.stringPtrBak
	mov	ax, di
DBCS<	shr	ax, 1				; ax <- char offset	>
	call	FloatWordToFloat
	jmp	short searchDone

20$:	
	mov	al, PSEE_GEN_ERR
	stc

searchDone:
	pop	bx,cx,ds,di,si

done:
	.leave
	GOTO	FunctionCleanUpNumOp
FunctionFind	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLeft

DESCRIPTION:	Implements the LEFT() function
		LEFT(string, n) returns the first n characters in the string.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionLeft	proc	near	uses	cx,dx
	.enter
	mov	al, 2
	call	FunctionCheckNArgs
	jc	done

	;-----------------------------------------------------------------------
	; get n

	call	StringOpGetIntArg		;ax <- n, decrements cx
	jc	done
	push	cx
	mov	cx, ax				;cx <- n
	clr	dx				;dx <- start = 0
	
	;-----------------------------------------------------------------------
	; check string, and do it

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	jc	donePop				;branch if error

	call	FunctionDoMid

donePop:
	pop	cx				;cx <- argument count

done:
	jnc	quit

	call	PropogateError
quit:
	.leave
	ret
FunctionLeft	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLength

DESCRIPTION:	Implements the LENGTH() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionLength	proc	near
	call	FunctionCheck1StringArg
	jc	done

	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	call	FloatWordToFloat
done:
	GOTO	FunctionCleanUpNumOp
FunctionLength	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionLower

DESCRIPTION:	Implements the LOWER() function
		Converts all the letters in a string to lowercase.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionLower	proc	near	uses	cx,ds,di,si
	.enter
	call	FunctionCheck1StringArg
	jnc	ok

	call	PropogateError
	jmp	short done

ok:
	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length	; get length
	tst	cx
	je	done				; carry is cleared by OR (tst)

	segmov	ds, es, si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2

	call	LocalDowncaseString

	clc

done:
	.leave
	ret
FunctionLower	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionMid

DESCRIPTION:	Implements the MID() function.
		MID(string, start, n) returns n characters from the string
		beginning with the number given by start.

		NOTES:
		------

		* The first character has an offset number of 0.

		* If start is greater than the length of the string-1, the
		  result of MID is an empty stirng.
		* if n is <= 0, the result is an empty string

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionMid	proc	near	uses	cx,dx
	.enter
	mov	al, 3
	call	FunctionCheckNArgs
	jc	done

	;-----------------------------------------------------------------------
	; get n

	call	StringOpGetIntArg		;ax <- n
	jc	done
	mov	dx, ax				;dx <- n

	;-----------------------------------------------------------------------
	; get start

	call	StringOpGetIntArg		;ax <- start
	jc	done

	push	cx				;save argument count
	mov	cx, dx				;cx <- n
	mov	dx, ax				;dx <- start

	;-----------------------------------------------------------------------
	; check string, and do it

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	jc	donePop				;branch if error

	call	FunctionDoMid

donePop:
	pop	cx				;cx <- argument count

done:
	jnc	quit

	call	PropogateError
quit:
	.leave
	ret
FunctionMid	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionDoMid

DESCRIPTION:	Utility subroutine.

		MID(string, start, n) returns n characters from the string
		beginning with the number given by start.

		NOTES:
		------

		* The first character has an offset number of 0.

		* If start is greater than the length of the string-1, the
		  result of MID is an empty stirng.
		
		* if n is = 0, the result is an empty string

CALLED BY:	INTERNAL (FunctionLeft, FunctionMid, FunctionRight)

PASS:		cx	- n, the number of characters
		dx	- start, glyph offset from which to begin
		es:bx	- pointer to top of argument stack (string argument)

RETURN:		carry set if error (not possible right now)
		    al - error code (ParserScannerEvaluatorError)
		es:bx   - pointer to top of argument stack (string result)

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionDoMid	proc	near	uses	ds,si
	mov	ax, bp			; save bp
	FDM_local	local	strBuf
	.enter

	mov	FDM_local.SB_saveBP, ax

	jcxz	nullStr				;n = 0?  if so, NULL string

	cmp	dx, es:[bx].ASE_data.ESAD_string.ESD_length
	jae	nullStr				;branch if start > length

	;-----------------------------------------------------------------------
	; ok, real work needed now...

	;
	; Restrict the # of chars to copy to what is actually available
	;
	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	sub	ax, dx				;ax <- # of chars available
	sub	ax, cx				;ax <- available - requested
	jnc	lengthOK			;branch if enough chars
	add	cx, ax				;cx <- adjusted length
lengthOK:
	push	cx,di,es
	;
	; ds:si <- string
	;
	segmov	ds, es, si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2
	add	si, dx
DBCS<	add	si, dx				;si <- bytes offset of start >
	;
	; set things up for a block move
	;
	segmov	es, ss, ax
	lea	di, FDM_local.SB_buf	; es:di <- dest

EC <	cmp	cx, MAX_STRING_LENGTH					>
EC <	ERROR_A	PARSE_STRING_TOO_LONG					>
	LocalCopyNString			;movin' on over..

	pop	cx,di,es
	jmp	haveResult

nullStr:
	clr	cx

haveResult:
	;-----------------------------------------------------------------------
	; cx = length of result

	call	ReplaceWithString	; destroys ax, cx

	.leave
	ret
FunctionDoMid	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionProper

DESCRIPTION:	Implements the PROPER() function.

		PROPER(string) converts the letters in string to proper
		capitalization: the first letter of each word uppercase,
		and the remaining letters in each word lowercase.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

FunctionProper	proc	near
	.enter
	call	FunctionCheck1StringArg
	jnc	ok

	call	PropogateError
	jmp	short quit

ok:
	push	bx,cx,dx,ds,di,si
	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length	; get length
	jcxz	done			; carry is cleared by OR (tst)

	;-----------------------------------------------------------------------
	; work needed

	segmov	ds, es, si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2

	clr	dx			; use dx to flag when upcasing is reqd

processStrLoop:
	LocalGetChar	ax, dssi
	call	LocalIsAlpha		; destroys bx
	jz	nonAlpha

	tst	dx			; has upcasing occured?
	jne	downCase		; branch if so

	;
	; upcase char
	;
	call	LocalUpcaseChar
	dec	dx			; flag that upcase has taken place
	jmp	short storeChar

downCase:
	call	LocalDowncaseChar

storeChar:
SBCS<	mov	ds:[si-(size char)], al				>
DBCS<	mov	ds:[si-(size wchar)], ax			>
	jmp	short next

nonAlpha:
	clr	dx

next:
	loop	processStrLoop
	clc

done:
	pop	bx,cx,dx,ds,di,si

quit:
	.leave
	ret
FunctionProper	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionRepeat

DESCRIPTION:	Implements the REPEAT() function
		REPEAT(string, n) duplicates a string n times.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionRepeat	proc	near	uses	cx,dx,si
	mov	ax, bp
	FR_local	local	strBuf
	.enter

	mov	FR_local.SB_saveBP, ax

	mov	al, 2
	call	FunctionCheckNArgs
	jc	done
	
	;-----------------------------------------------------------------------
	; get n

	call	StringOpGetIntArg	; ax <- n, cx decremented
	jc	done
	mov	si, ax			; si <- n

	;-----------------------------------------------------------------------
	; check string

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	jc	done

	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	xchg	ax, si			; ax <- n, si <- length of source
	mul	si			; dx:ax <- length of result
	jc	strTooLong			;branch if overflow

	cmp	ax, MAX_STRING_LENGTH
	ja	strTooLong			;branch if overflow

	;-----------------------------------------------------------------------
	; do it
	; si = length of source string
	; ax = length of result string

	push	ax			; save length of result
	push	ds,es,di
	mov	dx, si			; dx <- length of source string
	segmov	ds,es,si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2
	segmov	es,ss,di
	lea	di, FR_local.SB_buf
DBCS<	shl	ax, 1			; ax <- result string size	>
	add	ax, di			; location to stop

repLoop:
	push	si			; save ptr to source string
	mov	cx, dx			; cx <- num bytes to move
	LocalCopyNString
	pop	si			; restore ptr to source string

	cmp	di, ax			; done?
	jl	repLoop			; loop if not
	pop	ds,es,di

	pop	cx			; cx <- length of result
	call	ReplaceWithString
	mov	cx, 1
	jmp	short done

strTooLong:
	mov	al, PSEE_GEN_ERR
	stc
	
done:
	jnc	quit

	call	PropogateError

quit:
	.leave
	ret
FunctionRepeat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionReplace

DESCRIPTION:	Implements the REPLACE() function
		REPLACE(original-string,start-number, n, new-string)
		replaces n characters in original-string, beginning at
		start-number, with new-string.

		NOTES:
		------

		start-number is an offset

		0 <= n <= MAX_STRING_LENGTH

		You can perform several procedures with REPLACE:

		* by making n equal to the number of characters in
		  original-string, you can replace the entire string with
		  new-string
		
		* by specifying a position immediately beyond the end of
		  original-string as start-number, you can append new-string
		  to original-string
		
		* by making n equal to 0, you can insert a new-string

		* by making new-string an empty string, you can delete
		  a string

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionReplace	proc	near	uses	cx
	mov	ax, bp
	FR_local	local	strBuf
	.enter

	mov	FR_local.SB_saveBP, ax
	mov	al, 4
	call	FunctionCheckNArgs
	LONG jc	err

	;-----------------------------------------------------------------------
	; get new-string

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	LONG jc	err

	mov	FR_local.SB_str2.segment, es
	lea	ax, es:[bx].ASE_data.ESAD_string.ESD_length+2
	mov	FR_local.SB_str2.offset, ax
	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	mov     FR_local.SB_str2Len, ax

	call	Pop1Arg			; drop arg
	dec	cx			; dec count

	;-----------------------------------------------------------------------
	; get n

	call	StringOpGetIntArg	; ax <- n, cx decremented
	LONG jc	err

	mov	FR_local.SB_wd2, ax

	;-----------------------------------------------------------------------
	; get start-number

	call	StringOpGetIntArg	; ax <- n, cx decremented
	LONG jc	err

	mov	FR_local.SB_wd1, ax

	;-----------------------------------------------------------------------
	; get original-string

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	jc	err

	mov	FR_local.SB_str1.segment, es
	lea	ax, es:[bx].ASE_data.ESAD_string.ESD_length+2
	mov	FR_local.SB_str1.offset, ax
	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	mov     FR_local.SB_str1Len, ax

	;-----------------------------------------------------------------------
	; work...
	; SB_str1	= original-string
	; SB_str1Len	= length(original-string)
	; SB_str2	= new-string
	; SB_str2Len	= length(new-string)
	; SB_wd1	= start-number
	; SB_wd2	= n
	;
	; checks:
	;     start+n <= length(original-string)

	mov	ax, FR_local.SB_wd1	; ax <- start-number
	add	ax,FR_local.SB_wd2
	cmp	ax, FR_local.SB_str1Len
	jg	genErr
	;
	; Make sure the resulting string won't be too long
	;
	mov	ax, FR_local.SB_str1Len
	sub	ax, FR_local.SB_wd2
	add	ax, FR_local.SB_str2Len
	cmp	ax, MAX_STRING_LENGTH
	ja	genErr			;branch if too long

	;-----------------------------------------------------------------------
	; things check-out, do the replacement

workNeeded::
	push	ds,es,di,si		; registers we will trash
	segmov	es, ss, di		; es:di <- string buffer
	lea	di, FR_local.SB_buf
	push	di

	lds	si, FR_local.SB_str1	; ds:si <- original-string
	mov	cx, FR_local.SB_wd1	; cx <- start
	LocalCopyNString		; copy
	add	si, FR_local.SB_wd2	; skip chars that will be replaced
DBCS<	add	si, FR_local.SB_wd2	; skip bytes that will be replaced >

	push	ds,si
	lds	si, FR_local.SB_str2	; ds:si <- new-string
	mov	cx, FR_local.SB_str2Len
	LocalCopyNString
	pop	ds,si

	;
	;  cx <- cx + ((offset1 - si) / (size char))
	;
	mov	cx, FR_local.SB_str1Len
if DBCS_PCGEOS
	mov	ax, FR_local.SB_str1.offset
	sub	ax, si			; (ax goes negative)
	sar	ax, 1			; signed divide by 2
	add	cx, ax			; cx <- num chars remaining
else
	add	cx, FR_local.SB_str1.offset
	sub	cx, si			; cx <- num chars remaining
endif
	LocalCopyNString
	;
	; length of result = di - SB_buf
	;
	mov	cx, di
	pop	di
	sub	cx, di
DBCS<	shr	cx, 1			; cx <- length of string	>
	pop	ds,es,di,si		; restore registers

	;-----------------------------------------------------------------------
	; done, result is in the stack frame buffer
	;	cx = length of string

;doReplace:
	call	ReplaceWithString
	mov	cx, 1
	jmp	short done

genErr:
	mov	al, PSEE_GEN_ERR
	stc

done:
	jnc	quit

err:
	call	PropogateError

quit:
	.leave
	ret
FunctionReplace	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionRight

DESCRIPTION:	Implements the RIGHT() function
		RIGHT(string, n) returns the last n characters in the string.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionRight	proc	near	uses	cx,dx
	.enter
	mov	al, 2
	call	FunctionCheckNArgs
	jc	done

	;-----------------------------------------------------------------------
	; get n

	call	StringOpGetIntArg		;ax <- n
	jc	done
	push	cx
	mov	cx, ax				;cx <- n

	;-----------------------------------------------------------------------
	; check string, and do it

	mov	al, mask ESAT_STRING
	call	FunctionCheckArgType
	jc	donePop				;branch if error

	clr	dx				;dx <- assume start=0
	mov	ax, es:[bx].ASE_data.ESAD_string.ESD_length
	sub	ax, cx				;ax <- end - start
	;
	; if n > length
	;     start = 0
	; else
	;     start = length - n
	;
	jc	startGotten			;branch if borrow (n > length)
	mov	dx, ax				;dx <- start
startGotten:
	call	FunctionDoMid

donePop:
	pop	cx				;cx <- argument count

done:
	jnc	quit

	call	PropogateError
quit:
	.leave
	ret
FunctionRight	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionString

DESCRIPTION:	Implements the STRING() function
		STRING(x, n) converts the value x into a string with n
		decimal places.

		NOTES:
		------
		x can be any value

		n can be any value from 0 to DECIMAL_PRECISION

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionString	proc	near	uses	cx
	mov	ax, bp
	FS_local	local	strBuf
	.enter

	mov	FS_local.SB_saveBP, ax

	mov	ax, 2
	call	FunctionCheckNNumericArgs
	jc	done

	call	GetByteArg		; ax <- int, dec cx
	jc	done

	cmp	ax, DECIMAL_PRECISION
	jg	err

	push	bx,es,di
	segmov	es, ss, di		; es:di <- stack frame buffer
	lea	di, FS_local.SB_buf
	mov	bh, DECIMAL_PRECISION	; bh <- number of sig digits
	mov	bl, al			; bl <- number of decimal places

	clr	ax			; convert number on top of stack
	call	FloatFloatToAscii_StdFormat	; cx <- num chars
	pop	bx,es,di

	call	ReplaceWithString
	jmp	short done

err:
	mov	al, PSEE_GEN_ERR
	stc
done:
	jnc	quit

	call	PropogateError
quit:
	.leave
	ret
FunctionString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTrim

DESCRIPTION:	Implements the TRIM() function
		Removes leading, trailing, and consecutive spaces from a string.

CALLED BY:	INTERNAL ()

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:
		For SBCS ah is a flag; under DBCS flag is on stack.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/93		Conversion for DBCS

-------------------------------------------------------------------------------@

FunctionTrim	proc	near	uses	cx,dx,ds,si
	mov	ax, bp			; save bp
	FT_local	local	strBuf	
DBCS<	FT_trimFlag	local	word		; SBCS ah register	>
	.enter

	mov	FT_local.SB_saveBP, ax

	call	FunctionCheck1StringArg
	jnc	ok

	call	PropogateError
	jmp	short done

ok:
	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length
	tst	cx			; 0 length?
	je	done			; done if so

	;-----------------------------------------------------------------------
	; work needed

	push	es,di
	;
	; point ds:si at string
	;
	segmov	ds, es, si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2
	;
	; point es:di at strBuf
	;
	segmov	es, ss, di
	lea	di, FT_local.SB_buf

	;-----------------------------------------------------------------------
	; do the TRIMming

DBCS<	clr	ss:[FT_trimFlag]					>
SBCS<	clr	ah			; ah=0 will get us to skip leading  >
					; white space
	clr	dx			; dx = count of resulting chars
trimLoop:
	LocalGetChar	ax, dssi	; get char
if DBCS_PCGEOS
	call	LocalIsSpace		; white space?
	jnz	doSpace			; branch if so
	mov	ss:[FT_trimFlag], -1	; ah = 0ffh will get us to trim
else
	call	IsWhiteSpace		; white space?
	jnc	doSpace			; branch if so

	mov	ah, 0ffh		; ah = 0ffh will get us to trim
endif
					; non-leading white space down to
					; 1 character
	jmp	short doStore

doSpace:
	;
	; if ah started out as 0, all white space will be skipped
	; if ah started out as 0ffh, all but the first space will be skipped
	;
DBCS<	inc	ss:[FT_trimFlag]				>
SBCS<	inc	ah						>
	jne	next

	LocalLoadChar	ax, ' '		; force space

doStore:
	LocalPutChar	esdi, ax
	inc	dx			; inc count
next:
	loop	trimLoop
	pop	es,di

	tst	dx
	je	haveResult

	;
	; ok, now check for a trailing space
	;
	LocalCmpChar	ax, ' '
	jne	haveResult

	dec	dx

haveResult:
	;-----------------------------------------------------------------------
	; string TRIMmed
	; dx = length

	mov	cx, dx			; cx <- trimmed string length
	call	ReplaceWithString	; destroys ax, cx
	mov	cx, 1
	jnc	done

	call	PropogateError

done:
	.leave
	ret
FunctionTrim	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionUpper

DESCRIPTION:	Implements the UPPER() function
		Converts all the letters in a string to uppercase.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionUpper	proc	near	uses	cx,ds,di,si
	.enter
	call	FunctionCheck1StringArg
	jnc	ok

	call	PropogateError
	jmp	short done

ok:
	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length	; get length
	tst	cx
	je	done				; carry is cleared by OR (tst)

	segmov	ds, es, si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2

	call	LocalUpcaseString

	clc

done:
	.leave
	ret
FunctionUpper	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionValue

DESCRIPTION:	Implements the VALUE() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionValue	proc	near	uses	cx,ds,si
	.enter
	call	FunctionCheck1StringArg
	jc	done
	
	mov	cx, es:[bx].ASE_data.ESAD_string.ESD_length	; get length
	tst	cx
	jne	notNull

	call	Float0
	jmp	short done

notNull:
	segmov	ds, es, si
	lea	si, es:[bx].ASE_data.ESAD_string.ESD_length+2

	mov	al, mask FAF_PUSH_RESULT
	call	FloatAsciiToFloat
	mov	al, PSEE_WRONG_TYPE		;al <- in case of error
done:
	.leave
	GOTO	FunctionCleanUpNumOp
FunctionValue	endp


;*******************************************************************************
;	BOOLEAN ROUTINES
;*******************************************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionAnd

DESCRIPTION:	Implements the AND() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code (ParserScannerEvaluatorError)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionAnd	proc	near
	mov	ax, bp
	FP_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FP_local.FE_argProcessingRoutine.handle, handle FuncAndNums
	mov	FP_local.FE_argProcessingRoutine.offset, offset FuncAndNums
	mov	FP_local.FE_argsReqForProcRoutine, 2
	mov	FP_local.FE_returnSingleArg, 0ffh
	call	ProcessListOfArgs
	jc	done

	cmp	FP_local.FE_cellCount, 2
	jae	done				; carry is clear (JAE = JNC)

	; carry is set
	mov	al, PSEE_BAD_ARG_COUNT

done:
	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave
	GOTO	FunctionChangeArgToBoolean
FunctionAnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FuncAndNums
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	And two numbers

CALLED BY:	FunctionAnd via ProcessListOfArgs
PASS:		FP-Stack with two numbers on it
RETURN:		FP-Stack with one number on it:
			one  - if both one
			zero - otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FuncAndNums	proc	far
	uses	ax
	.enter
	call	FloatEq0		; carry set if 1st is zero
					; Removed from stack
	jc	popAndSave0		; Branch if is zero

	call	FloatEq0		; carry set if 2nd is zero
					; Removed from stack
	jc	save0			; Branch if is zero

	;
	; Both are non-zero
	;
	call	Float1

quit:
	.leave
	ret

popAndSave0:
	call	FloatDrop

save0:
	call	Float0			; One or the other is zero
	jmp	quit

FuncAndNums	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionFalse

DESCRIPTION:	Implements the FALSE() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionFalse	proc	near
	call	FunctionCheck0Args
	GOTO	FunctionReturnFalse
FunctionFalse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConsumeOneNumericArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop one number off the FP stack if needed

CALLED BY:	FunctionIsErr(), FunctionIsNumber(), FunctionIsString()
PASS:		es:bx - ptr to top of argument stack
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/31/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConsumeOneNumericArg		proc	near
	.enter

	pushf
	test	es:[bx].ASE_type, mask ESAT_NUMBER
	jz	notNumber			;branch if not number
	call	FloatDrop			;drop one number off FP stack
notNumber:
	popf

	.leave
	ret
ConsumeOneNumericArg		endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionIsErr

DESCRIPTION:	Implements the ISERR() function
		ISERR returns TRUE for the value ERR, FALSE for any other value.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionIsErr	proc	near
	mov	al, 1
	call	FunctionCheckNArgs
	call	ConsumeOneNumericArg
	jc	false			; doesn't matter, error will be
					; propogated

	test	es:[bx].ASE_type, mask ESAT_ERROR
	je	false

	GOTO	FunctionReturnTrue

false:
	GOTO	FunctionReturnFalse
FunctionIsErr	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionIsNumber

DESCRIPTION:	Implements the ISNUMBER() function
		ISNUMBER returns TRUE for numeric value, NA, ERR, or a
		blank cell, and FALSE for any other value.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	!!! still have yet to deal with NA !!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionIsNumber	proc	near
	mov	al, 1
	call	FunctionCheckNArgs
	call	ConsumeOneNumericArg
	jc	false			; doesn't matter, error will be
					; propogated

	test	es:[bx].ASE_type, mask ESAT_NUMBER	; number?
	jne	true					; true if so
	test	es:[bx].ASE_type, mask ESAT_ERROR	; error?
	jne	false					; false if so
	test	es:[bx].ASE_type, mask ESAT_EMPTY	; empty?
	je	false					; false if not empty

true:
	GOTO	FunctionReturnTrue

false:
	GOTO	FunctionReturnFalse
FunctionIsNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionIsString

DESCRIPTION:	Implements the ISSTRING() function
		ISSTRING returns TRUE for the a STRING, FALSE for a
		numeric value, NA, ERR or a blank cell.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionIsString	proc	near
	mov	al, 1
	call	FunctionCheckNArgs
	call	ConsumeOneNumericArg
	jc	false			; doesn't matter, error will be
					; propogated

	test	es:[bx].ASE_type, mask ESAT_STRING
	je	false

;true:
	GOTO	FunctionReturnTrue

false:
	GOTO	FunctionReturnFalse
FunctionIsString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionOr

DESCRIPTION:	Implements the OR() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionOr	proc	near
	mov	ax, bp
	FS_local	local	functionEnv
	.enter

	call	InitFunctionEnv

	mov	FS_local.FE_argProcessingRoutine.handle, handle FuncOrNums
	mov	FS_local.FE_argProcessingRoutine.offset, offset FuncOrNums
	mov	FS_local.FE_argsReqForProcRoutine, 2
	mov	FS_local.FE_returnSingleArg, 0ffh
	call	ProcessListOfArgs

	call	FunctionCleanUpNumOpWithFunctionEnv
	.leave

	GOTO	FunctionChangeArgToBoolean
FunctionOr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FuncOrNums
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Or two numbers

CALLED BY:	FunctionOr via ProcessListOfArgs
PASS:		FP-Stack with two numbers on it
RETURN:		FP-Stack with one number on it:
			zero - if both zero
			one  - otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FuncOrNums	proc	far
	uses	ax
	.enter
	call	FloatEq0		; carry set if 1st is zero
					; Removed from stack
	jnc	popAndSave1		; Branch if non-zero

	call	FloatEq0		; carry set if 2nd is zero
					; Removed from stack
	jnc	save1			; Branch if non-zero

	;
	; Both are zero.
	;
	call	Float0

quit:
	.leave
	ret

popAndSave1:
	call	FloatDrop

save1:
	call	Float1			; One or the other is zero
	jmp	quit

FuncOrNums	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTrue

DESCRIPTION:	Implements the TRUE() function

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionTrue	proc	near
	call	FunctionCheck0Args
	GOTO	FunctionReturnTrue
FunctionTrue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FunctionFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implements the FILENAME() function.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)
PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.
RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FunctionFilename	proc	near
	mov	ax, SF_FILENAME
	GOTO	DoSpecialFunction
FunctionFilename	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FunctionPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implements the PAGE() function.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)
PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.
RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FunctionPage	proc	near
	mov	ax, SF_PAGE
	GOTO	DoSpecialFunction
FunctionPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FunctionPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implements the PAGES() function.

CALLED BY:	INTERNAL (PopOperatorAndEval via functionHandlers)
PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.
RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FunctionPages	proc	near
	mov	ax, SF_PAGES
	GOTO	DoSpecialFunction
FunctionPages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSpecialFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to handle a special function.

CALLED BY:	FunctionFilename, FunctionPage, FunctionPages
PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ax	- SpecialFunction enum
		ss:bp	- pointer to EvalParameters on the stack.
RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSpecialFunction	proc	near
	uses	cx, dx
	.enter
	mov	dx, ax			; Save special function type

	call	FunctionCheck0Args	; Make sure there are no arguments
	jc	propogateError		; Branch if wrong number of arguments
	
	mov	al, CT_SPECIAL_FUNCTION	; al <- callback type
	mov	cx, dx			; cx <- special function type
if FULL_EXECUTE_IN_PLACE
	pushdw	ss:[bp].CP_callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
else
	call	ss:[bp].CP_callback	; call the application
endif
	jnc	quit			; Branch if no error

propogateError:
	call	PropogateError

quit:
	.leave
	ret
DoSpecialFunction	endp


EvalCode	ends
