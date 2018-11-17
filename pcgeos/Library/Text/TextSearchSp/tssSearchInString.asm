COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Text Library
FILE:		tssSearchInString.asm

AUTHOR:		Andrew Wilson, Oct  8, 1991

ROUTINES:
	Name			Description
	----			-----------
	TextSearchInString	General search routines for <64K of text
	TextSearchInHugeArray	Search routines for > 64K of text

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/91	Initial revision

DESCRIPTION:
	

	$Id: tssSearchInString.asm,v 1.1 97/04/07 11:19:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


TextSearchSpell	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIsWordBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if passed char is word break.

CALLED BY:	CheckLeftWordBoundary, CheckRightWordBoundary
PASS:		ax - char to test
RETURN:		z flag clear if word break (jne isWordBreak)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIsWordBreak	proc	near	uses	ax
	.enter

		;A word (in my mind, anyway)
		; is broken by any non-alphanumeric char.
	call	LocalIsAlpha
	jnz	notWordBreak		;If is an alpha char, branch
	cmp	ax, '0'
	jb	exit
	cmp	ax, '9'
	ja	exit
notWordBreak:
	clr	ah
exit:
	.leave
	ret
CheckIsWordBreak	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLeftWordBoundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the character preceding the current one is
		a word boundary.

CALLED BY:	GLOBAL
PASS:		ES:BX - pointer to start of current portion of string
		ES:DI - pointer to first char in string
		SS:BP - pointer to TextSearchInHugeArrayFrame
		DX - # chars in block pointed to by ES:BX
RETURN:		carry set if not a word boundary
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLeftWordBoundary	proc	near
	cmp	di, bx
	je	getPrevBlock
SBCS <	mov	al, es:[di][-1]		;				>
DBCS <	mov	ax, es:[di][-2]		;				>
doCheckExit:
	call	CheckIsWordBreak
	clc
	jne	exit
	stc
exit:
	ret

getPrevBlock:		;Previous char lies in previous block
	mov	ax, ss:[bp].TSIHAF_curOffset.low
	tst	ss:[bp].TSIHAF_curOffset.high
	jnz	10$
	tst_clc	ax	;If char was the first one, then return that it was on
	jz	exit	; a word boundary	
10$:
	push	cx, dx
	mov	dx, ss:[bp].TSIHAF_curOffset.high
	sub	ax, 1
	sbb	dx, 0
	call	HugeArrayCallback	;Load previous block
	mov	di, bx
	add	di, dx
SBCS <	mov	al, es:[di][-1]						>
DBCS <	mov	al, es:[di][-2]						>
	push	ax
	movdw	dxax, ss:[bp].TSIHAF_curOffset
	call	HugeArrayCallback	;Load original block again
	pop	ax
	pop cx, dx
	jmp	doCheckExit
CheckLeftWordBoundary	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfMatchFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a match is found at the current character.

CALLED BY:	GLOBAL
PASS:		ES:BX - pointer to start of current portion of string
		ES:DI - pointer to first char in string
		SS:BP - pointer to TextSearchInHugeArrayFrame
		DX - # chars in block pointed to by ES:BX
		DS:SI - pointer to string to match
		CX - # chars in DS:SI string
RETURN:		carry set if not a match
			- else -
		AX:CX - # chars in match
		ES:BX - pointer to start of current portion of string
		ES:DI - ptr to first char in string
		DX - # chars in block ptd to by ES:BX
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

LOOPTOP:
	while (charsLeftToMatch--)
	{	
		charToMatch = *matchString++;
		if (charToMatch != "*") {
			charToTest = *searchInString++;
			if (!charToTest) 
				goto FAILED;
			if (!Matches(charToTest, charToMatch)) 
				goto FAILED;
		} else {
			goto MATCH_WC;
		} 
	}
SUCCESS:
	return(TRUE)
	
FAILED:
	if (savedStates)
		PopState(matchString, searchInString,charsLeftToMatch);
		goto LOOPTOP;
	else
		return (FALSE);

MATCH_WC:
	if (charsLeftToMatch) {
		charToMatch = *matchString++;
		charsLeftToMatch--;
		if (charToMatch == "*")
			goto MATCH_WC;
		do {
			charToTest = *searchInString++;
				if (!charToTest)
					goto FAILED;
				else if (Matches(charToTest, charToMatch)) 
					PushState (matchString, searchInString, charsLeftToMatch);
		} while (!IsWhitespace(charToTest));
		goto FAILED;
	} else {
		do {
			charToTest = *searchInString++;
 		} while (charToTest && !IsWhitespace(charToTest));
		goto SUCCESS;
	}


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAX_SEARCH_STATES	equ	70
CheckIfMatchFound	proc	near
	matchChar	local	word
	len		local	word
	charsLeft	local	dword
	curOffset	local	dword
	flags		local	SearchOptions
	stackFrame	local	nptr.TextSearchInHugeArrayFrame
	charsMatching	local	dword
	reloadFlag	local	byte	;Set by GetCharFromSearchString()
	numStates	local	byte
	wcMatchEverything local	byte
;	Inherited by GetCharfromSearchString() and CheckIfCharMatches()
	mov	ax, bp

;	We push the variables *outside* of where the stack frame is created,
;	because there are cases where we leave stuff on the stack (when
;	dealing with wildcard chars -- searching for "*lo" in "hello"), and
;	we don't want to pop the saved regs until the stack frame has been
;	restored.

	push	dx, si, di
	.enter
	clr	reloadFlag
	clr	numStates
	mov	len, cx

;	COPY APPROPRIATE DATA INTO LOCAL STACK FRAME

	push	di
	mov_tr	di, ax
	mov	stackFrame, di
	movdw	curOffset, ss:[di].TSIHAF_curOffset, ax
	mov	al, ss:[di].TSIHAF_searchFlags
	mov	flags, al
	clrdw	charsMatching
	mov	ax, ss:[di].TSIHAF_str1Size.low
	sub	ax, ss:[di].TSIHAF_curOffset.low
	mov	charsLeft.low, ax
	mov	ax, ss:[di].TSIHAF_str1Size.high
	sbb	ax, ss:[di].TSIHAF_curOffset.high
	mov	charsLeft.high, ax
	pop	di

;	CHECK TO SEE IF THE WORD STARTS AT A WORD BOUNDARY IF DESIRED

	test	flags, mask SO_PARTIAL_WORD
	jne	top	;We can match partial words, so skip this check

;	We now do a check to see if the first character of the string we
;	are searching for is a word-break character (for example, if you
;	are searching for "<CR>hello", it seems silly to have to set the
;	SO_PARTIAL_WORD flags for it to find the search string in text like
;	"goodbye<CR>hello".

;	The wildcard characters look like word-break characters to the
;	CheckIsWordBreak routine, so handle them specially...

SBCS <	mov	al, ds:[si]						>
SBCS <	clr	ah							>
DBCS <	mov	ax, ds:[si]						>
	test	flags, mask SO_NO_WILDCARDS
	jne	checkIfWordBreak	;Branch if no whitespace chars
					; (whitespace chars will be treated
					; as word-break characters below)

;	We allow wildcards in the search string. If the first character is
;	a match-only-whitespace wildcard, then we can skip the word boundary
;	check (as it can only match whitespace). If it is a match-non-whtspace
;	wildcard, then we want to do the boundary check.
;	

	cmp	ax, WC_MATCH_SINGLE_CHAR
	je	doLeftWordBoundaryCheck
	cmp	ax, WC_MATCH_MULTIPLE_CHARS
	je	doLeftWordBoundaryCheck
	cmp	ax, WC_MATCH_WHITESPACE_CHAR
	je	top
		
checkIfWordBreak:
	call	CheckIsWordBreak
	jne	top

doLeftWordBoundaryCheck:
	push	bp
	mov	bp, stackFrame
	call	CheckLeftWordBoundary
	pop	bp
	jc	failed			;If not on a word boundary, branch
	clr	ax
top:
	jcxz	success
SBCS <	lodsb								>
SBCS <	clr	ah							>
DBCS <	lodsw								>
	mov	matchChar, ax
	test	flags, mask SO_NO_WILDCARDS
	jne	10$
	cmp	ax, WC_MATCH_MULTIPLE_CHARS
	LONG je	doWCMatch
10$:
	call	GetCharFromSearchString	;If we reached the end of the string,
	jc	failed			; branch.

;	matchChar - char from match string
;	AX - char from search string

	push	cx
	mov	cx, matchChar
	call	CheckIfCharMatches
	pop	cx
	jc	failed		;Branch if chars do not match
	loop	top		;Continue matching. Return with carry clear
				; when no chars left
success:
;
;	We found the longest match. Make sure it ends with a word break
;	(if possible).
;
	test	flags, mask SO_PARTIAL_WORD
	jne	noCheckFinalChar

;	If last char matched was whitespace, then branch. This way, if
;	you search for "foo ", it should match the first 4 chars of "foo foo"
;	whether or not you have the match-partial-word flag set.
;
					;If last char matched was whitespace,
	call	CheckIsWordBreak	; branch
	jne	noCheckFinalChar	
	call	GetCharFromSearchString	;ax = char from search string
	jc	noCheckFinalChar
	call	CheckIsWordBreak
	je	failed	
	decdw	charsMatching
noCheckFinalChar:
	movdw	axcx, charsMatching
	tstdw	axcx		;We must match at least one char
	jz	failed		;Exit with failure if we did not
	clc			;
exit:
	pushf
	tst	reloadFlag		
	jnz	doReload
realExit:
	popf
	.leave
	pop	dx, si, di
	ret
failed:	
	tst	numStates
	mov	cx, len
	stc
	je	exit
;
;	Restore a previously saved state
;
	pop	cx
	pop	si
	pop	di
	popdw	charsMatching
	popdw	curOffset
	popdw	charsLeft

	dec	numStates		;Decrement various offsets, etc, 
	incdw	charsLeft		; as they point to the character
	decdw	curOffset		; *after* the matching one.
	decdw	charsMatching		;
	LocalPrevChar	esdi
	LocalPrevChar	dssi

	tst	reloadFlag		;Did this text string span blocks?
	LONG je	top			;If not, branch

	push	bp, ax
	movdw	dxax, curOffset
	mov	bp, stackFrame
	call	HugeArrayCallback
	pop	bp, ax
	jmp	top

doReload:

;	Reload ES:BX,DI and DX with the appropriate information about the
;	current segment

	push	bp, ax
	mov	bp, stackFrame
	movdw	dxax, ss:[bp].TSIHAF_curOffset
	call	HugeArrayCallback
	pop	bp, ax
	jmp	realExit

doWCMatch:
	mov	wcMatchEverything, FALSE
doWCMatch2:		
	dec	cx
	jcxz	scanToEnd
SBCS <	lodsb								>
SBCS <	clr	ah							>
DBCS <	lodsw								>
	mov	matchChar, ax
	cmp	ax, WC_MATCH_MULTIPLE_CHARS	;Ignore multiple WCs in a row
	jne	nextChar			;
	mov	wcMatchEverything, TRUE		;Match everything if multiple
	jmp	doWCMatch2			; WC_MATCH_MULTIPLE_CHARS
nextChar:
	call	GetCharFromSearchString		;Get next char from search
	LONG jc	failed				; string. If none, fail match
	push	cx
	mov	cx, matchChar			;cx = char from match string
	call	CheckIfCharMatches
	pop	cx
	jc	noWCMatch

;	Found a match - push the current information

	cmp	numStates, MAX_SEARCH_STATES
	je	noWCMatch
	pushdw	charsLeft
	pushdw	curOffset
	pushdw	charsMatching
	push	di				;Save ptr into search string
	push	si				;Save ptr into restore string
	push	cx				;Save # chars left in restore 
						; string
	inc	numStates
	mov	wcMatchEverything, FALSE	;since we found a match go back
						; to matching only non-whitespc
		
noWCMatch:
	tst	wcMatchEverything		;skip whitespace check if 
	jnz	nextChar			; matching everything
						;Check if the char
	call	CheckIsWhitespace		; was whitespace.
	jz	nextChar
	jmp	failed				;Failed the match - branch back
						; up to try any pushed states.

scanToEnd:

;	The match string ends with a wildcard, so just scan until a whitespace
;	or the end of the string.

	call	GetCharFromSearchString	;Scan until we hit a whitespace or
	jc	gotoWordBoundary	; end of string (branch if EOS).
	call	CheckIsWhitespace	;If not whitespace, branch back up
	je	scanToEnd		;
	decdw	charsMatching		;Do not match trailing whitespace char
gotoWordBoundary:
	jmp	noCheckFinalChar
CheckIfMatchFound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCharFromSearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the char at curOffset.

CALLED BY:	GLOBAL
PASS:		ES:BX - pointer to start of current portion of string
		ES:DI - pointer to first char in string
		DX - # chars in this block
		SS:BP - pointer to stack inherited frame
RETURN:		ax - character (unchanged & carry set if end of string reached)
		es:di, es:bx, dx - updated if necessary
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCharFromSearchString	proc	near	uses	si
	.enter	inherit	CheckIfMatchFound

;	Check to see if we have reached the end of the string

10$:
	tstdw	charsLeft
   	stc
	je	exit			;If we've reached the end of the
					; string, leave.
	mov	si, bx
	add	si, dx			;ES:SI <- ptr past last char in block
DBCS <	add	si, dx			;# chars -> # bytes		>
	cmp	si, di
EC <	ERROR_B	SEARCH_EXTENDED_BEYOND_END_OF_BLOCK			>
	je	loadNextBlock
15$:
SBCS <	mov	al, es:[di]						>
SBCS <	clr	ah							>
DBCS <	mov	ax, es:[di]						>
	LocalNextChar	esdi
	decdw	charsLeft
	incdw	curOffset
	incdw	charsMatching
;
;	If the char we just retrieved is a soft hyphen, and we want to ignore
;	soft hyphens, then branch back up to get the next char
;
SBCS <	cmp	al, C_OPTHYPHEN						>
DBCS <	cmp	ax, C_SOFT_HYPHEN					>
	jne	20$
	test	flags, mask SO_IGNORE_SOFT_HYPHENS
	jne	10$
20$:
	clc
exit:
	.leave
	ret
loadNextBlock:
	mov	reloadFlag, TRUE
	push	bp, ax
	movdw	dxax, curOffset
	mov	bp, stackFrame
	call	HugeArrayCallback
	pop	bp, ax
	jmp	15$
GetCharFromSearchString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfCharMatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed chars match.

CALLED BY:	GLOBAL
PASS:	       	ss:bp - ptr to inherited stack frame
		ax - char from search string
		cx - char from match string
RETURN:		carry set if they match
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfCharMatches	proc	near	uses	ax, bx, cx
	.enter inherit CheckIfMatchFound
	test	flags, mask SO_NO_WILDCARDS
	jne	25$
	mov	bx, offset CheckForNonWhitespaceMatch
	cmp	cx, WC_MATCH_SINGLE_CHAR
	je	common
	mov	bx, offset CheckForWhitespaceMatch
	cmp	cx, WC_MATCH_WHITESPACE_CHAR
	je	common
25$:
	mov	bx, offset CheckForIgnoreCaseMatch
	test	flags, mask SO_IGNORE_CASE
	jne	common
	mov	bx, offset CheckForNormalMatch
common:
	call	bx
	.leave
	ret
CheckIfCharMatches	endp



;
;	Callback routines for ScanForCharInBlock
;	Pass: AX - char in search string
;	      CX - char we are matching
;	Return: carry clear if match
;	Destroyed: AX
;
CheckForWhitespaceMatch	proc	near
	call	CheckIsWhitespace
	clc
	jnz	10$
	stc
10$:
	ret
CheckForWhitespaceMatch	endp

CheckForNonWhitespaceMatch	proc	near
	call	CheckIsWhitespace
	clc
	jz	10$
	stc
10$:
	ret
CheckForNonWhitespaceMatch	endp

CheckForIgnoreCaseMatch		proc	near	uses	cx
	.enter
	call	LocalCmpCharsNoCase
	clc
	je	10$
	stc
10$:
	.leave
	ret
CheckForIgnoreCaseMatch		endp

CheckForNormalMatch		proc	near
	cmp	ax, cx		;Clears carry if equal
	je	10$
	stc
10$:
	ret
CheckForNormalMatch		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks through the current block for a match for the passed
		char.

CALLED BY:	GLOBAL
PASS:		ax - char to look for
		ds:si - ptr to first char to look at
		dx - offset to last char to include in search
		ch - SearchOptions
RETURN:		ds:si - ptr to last char looked at (or at character found)
		carry clear if char found
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindChar	proc	near	uses	di, dx
	.enter
DBCS <	shl	dx, 1			; char offset -> ptr		>
	test	ch, mask SO_NO_WILDCARDS
	jne	notWildCard
	mov	di, offset CheckForWhitespaceMatch
	cmp	ax, WC_MATCH_WHITESPACE_CHAR
	je	doSearch
	mov	di, offset CheckForNonWhitespaceMatch
	cmp	ax, WC_MATCH_MULTIPLE_CHARS
	je	doSearch
	cmp	ax, WC_MATCH_SINGLE_CHAR
	je	doSearch
notWildCard:

	mov	di, offset CheckForIgnoreCaseMatch
	test	ch, mask SO_IGNORE_CASE
	je	optimizedSearch
doSearch:
;
;	Doing a non-optimizable search (either an ignore case search or a
;	wildcard-search), where we have to do something special with each
;	char.
;
;	AX - char we are trying to match
;	DI - routine to call to see if the current char matches
;
	push	cx			;save SearchOptions
	push	ax			;save match char
	mov	cx, ax			;cx = char we are trying to match
SBCS <	mov	al, ds:[si]		;Get char from string		>
SBCS <	clr	ah							>
DBCS <	mov	ax, ds:[si]		;Get char from string		>
	call	di			;Exit if it matches
	pop	ax			;ax = match char
	pop	cx			;ch = SearchOptions
	jnc	exit
	cmp	si, dx			;Was this the last char to match?
;
;	This branch used to be a 'je', but the way that the bounds
;	of the scan are calculated (chars instead of offsets), produces a
;	roundoff error in the DBCS version when the characters lie at odd
;	addresses, which leaves si and dx off by one, and so the 'je' is
;	never triggered. Switching this to a 'jae' works, but is kind of
;	sloppy; I'd rather have fixed SetBoundsOfScan to return a ptr to
;	the last character, but it was tough to figure out exactly why
;	things were as they were there, so 'jae' it is. Since jae = jnc,
;	and we need the carry set to indicate not found, we'll use cmc and
;	jc, instead. - jon 18 jun 96
;
	cmc
	jc	exit			;Branch if so (return not found)

	LocalNextChar	dssi		;Get ptr to next char and loop
	test	ch, mask SO_BACKWARD_SEARCH
	je	doSearch		;
SBCS <	sub	si, 2			;				>
DBCS <	sub	si, 4			;				>
	jmp	doSearch		;

optimizedSearch:

;	Not looking for a wildcard or ignoring case - so do an optimized
;	search, using scasb.
;
;	AX - search char

	test	ch, mask SO_BACKWARD_SEARCH
	je	10$
	std				;If backward search, set backward
					; search flag
10$:
	push	es, cx
	segmov	es, ds
	mov	di, si			;ES:DI <- ptr to string to look through
	mov	cx, dx			;
	sub	cx, di			;CX <- # chars to search through
	jns	11$			;
	neg	cx			;
11$:
DBCS <	shr	cx, 1			;# bytes -> # chars		>
DBCS <	EC <ERROR_C	ODD_SIZE_FOR_DBCS_TEXT				>>
	inc	cx			;
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	pop	es, cx
	clc
	je	15$
	stc
15$:
	pushf
	mov	si, di			;DS:SI <- ptr past last char looked at
	LocalPrevChar	dssi		;Modify SI to point to char we matched
	test	ch, mask SO_BACKWARD_SEARCH	;
	je	20$			;
SBCS <	add	si, 2			;				>
DBCS <	add	si, 4			;				>
20$:
	popf
	cld
exit:
	.leave
	ret
FindChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBoundsOfScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the bounds of the scan

CALLED BY:	GLOBAL
PASS:		es:di - ptr to next char to look at
		es:bx - ptr to first char in block
		dx - # chars in block (es:bx+dx-1 = last char in block)
		ss:bp - ptr to TextSearchInHugeArrayFrame
		ch - SearchFlags
RETURN:		dx - set to offset of last char in block to include in search
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBoundsOfScan	proc	near	uses	bx, di
	.enter
	test	ch, mask SO_BACKWARD_SEARCH
	jne	setBWSearchBounds
DBCS <	shr	bx, 1			;ptr -> char offset		>
DBCS <	EC <WARNING_C	WARNING_TEXT_AT_ODD_ADDRESS			>>
	add	dx, bx
	dec	dx			;DX <- offset of last char in block
	mov	bx, dx
DBCS <	shr	di, 1			;ptr -> char offset		>
DBCS <	EC <WARNING_C	WARNING_TEXT_AT_ODD_ADDRESS			>>
	sub	bx, di			;BX <- # chars from curOffset until
	clr	ax			; end of block
	adddw	axbx, ss:[bp].TSIHAF_curOffset
					;AX:BX <- 32-bit offset of last char in
					; block
	cmpdw	axbx, ss:[bp].TSIHAF_endOffset				
	jb	exit			;If last char in block is < endOffset,
					; then exit (return offset of last char
					; in block)

;	endOffset lies before the end of the chars in this block, so return
;	the offset to "endOffset"

	mov	ax, ss:[bp].TSIHAF_endOffset.low
	sub	ax, ss:[bp].TSIHAF_curOffset.low ;AX <- # chars from endOffset
						; to curOffset
	mov	dx, di				;(DI is char offset)
	add	dx, ax				;
	jmp	exit	
setBWSearchBounds:
	mov	dx, bx				;DX <- offset of first char 
						; in block (which is last char
						; to include in a BW search)
DBCS <	shr	dx, 1				;ptr -> char offset	>
DBCS <	EC <WARNING_C	WARNING_TEXT_AT_ODD_ADDRESS			>>
	movdw	axbx, ss:[bp].TSIHAF_curOffset
DBCS <	shr	di, 1				;ptr -> char offset	>
DBCS <	EC <WARNING_C	WARNING_TEXT_AT_ODD_ADDRESS			>>
	sub	bx, di
	sbb	ax, 0
	add	bx, dx
	adc	ax, 0				;BX:AX <- offset of first char
						; in block
	cmpdw	axbx, ss:[bp].TSIHAF_endOffset				
	ja	exit				;If first char in block is past
						; endOffset, then exit
	mov	ax, ss:[bp].TSIHAF_endOffset.low
	sub	ax, bx				;AX <- # chars endOffset is
						; beyond start of block
	add	dx, ax				;DX <- last char to include in
						; search
exit:
	.leave
	ret
SetBoundsOfScan	endp

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanForCharInBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for the first char from the search string in the 
		current block.

CALLED BY:	GLOBAL
PASS:		es:di - ptr to next char to look at
		es:bx - ptr to first char in block
		dx - # chars in block (es:bx+dx-1 = last char in block)
		ds:si - ptr to char to look for
		ss:bp - ptr to TextSearchInHugeArrayFrame
RETURN:		carry set if not found in block (TSIHAF_curOffset updated)
			- else -
		es:di - updated to point to matching char
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanForCharInBlock	proc	near	uses	bx, cx, dx, ds, si
	.enter
SBCS <	mov	al, ds:[si]		;AX <- char to look for		>
SBCS <	clr	ah							>
DBCS <	mov	ax, ds:[si]		;AX <- char to look for		>
	push	ax
	mov	ch, ss:[bp].TSIHAF_searchFlags
	segmov	ds, es			;DS:SI <- string to search in
	mov	si, di
	call	SetBoundsOfScan		;Set the bounds of the scan to end at
					; endOffset, or the end of the block
	pop	ax
	call	FindChar

;	Modify TSIHAF_curOffset to reflect the # chars we've scanned through

	pushf				;Save return value
	mov	ax, si
	sub	ax, di			;AX <- # bytes we looked through
					; (assuming forward search)
DBCS <	sar	ax, 1			;# bytes -> # chars (signed)	>
DBCS <	EC <ERROR_C	ODD_SIZE_FOR_DBCS_TEXT				>>
	clr	dx
	test	ch, mask SO_BACKWARD_SEARCH
	jz	20$
	cwd
20$:
	adddw	ss:[bp].TSIHAF_curOffset, dxax
	popf
	segmov	es, ds
	mov	di, si			;ES:DI <- ptr to last char we checked
	.leave
	ret

ScanForCharInBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads in text from a huge array

CALLED BY:	GLOBAL
PASS:		ss:bp - ptr to TextSearchInHugeArrayFrame
		dx:ax -  offset into huge array
RETURN:		es:bx - ptr to first char in block
		es:di - ptr to requested char
		dx - total # chars in block
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextFromHugeArray	proc	near	uses	ds, si, cx
	.enter

;	Load in desired char from huge array

	mov	bx, ss:[bp].TSIHAF_hugeArrayVMFile
	mov	di, ss:[bp].TSIHAF_hugeArrayVMBlock
	call	HugeArrayLock
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
	dec	cx			;CX <- # chars before curOffset in this
					; block
	segmov	es, ds
	mov	di, si			;ES:DI <- ptr to requested char
	mov	bx, di
	sub	bx, cx			;ES:BX <- ptr to first char in block
DBCS <	sub	bx, cx			;# chars -> # bytes		>
	add	cx, ax			;DX <- total # chars in block
	mov	dx, cx
	.leave
	ret
GetTextFromHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the callback routine to retrieve the next blob of text.

CALLED BY:	GLOBAL
PASS:		DX:AX - offset of char to return
		ES - segment of last bunch of text
		SS:BP - TextSearchInHugeArrayFrame
RETURN:		es:di - ptr to char requested
		es:bx - start of block
		dx - # chars in block
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayCallback	proc	near	uses	cx, bp, ds, si
	.enter
;
;	If not searching through a huge array, we should never get here.
;
EC <	tst	ss:[bp].TSIHAF_hugeArrayVMBlock				>
EC <	ERROR_Z	SEARCH_EXCEEDED_BLOCK_BOUNDS				>

;	Unlock the old block

	segmov	ds, es		       
	call	HugeArrayUnlock

	call	GetTextFromHugeArray

	.leave
	ret
HugeArrayCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSearchCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds an occurrence of a string (str2) in another string (str1)

CALLED BY:	GLOBAL
PASS:		ES:BX - ptr to portion of str1 containing char at
			TSIHAF_curOffset		
		ES:DI - ptr to character at TSIHAF_curOffset
		DX - # chars of str1 pointed to by ES:BX
			(If all of str1 is in one segment, pass the same value
			 in TSIHAF_stringSize)
		DS:SI - ptr to str2 (string to match)
			May contain WildCards
		CX - # chars in str2 (or 0 if null-terminated)
		SS:BP - pointer to TextSearchInHugeArrayFrame

RETURN:		ES:BX - pointer to start of current portion of string
			(may need to be unlocked)
		ES:DI - pointer to last char in string checked
		carry set if string not found
		DX:AX - offset to match found
		BP:CX - # chars matched

DESTROYED:	nothing (values in TextSearchInHugeArrayFrame may be altered)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSearchCommon	proc	near	uses si, ds
	.enter
EC <	call	ECCheckBounds						>
EC <	push	ds, si							>
EC <	segmov	ds, es							>
EC <	mov	si, bx							>
EC <	add	si, dx							>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
EC <	cmpdw	ss:[bp].TSIHAF_endOffset, ss:[bp].TSIHAF_str1Size, ax	>
EC <	ERROR_AE END_OFFSET_IS_GREATER_THAN_THE_STRING_SIZE		>
EC <	test	ss:[bp].TSIHAF_searchFlags, mask SO_BACKWARD_SEARCH	>
EC <	jne	1$							>
EC <	cmpdw	ss:[bp].TSIHAF_curOffset, ss:[bp].TSIHAF_endOffset, ax	>
EC <	ERROR_A	CUR_OFFSET_IS_BEYOND_END_OFFSET				>
EC <	jmp	2$							>   
EC <1$:									>
EC <	cmpdw	ss:[bp].TSIHAF_curOffset, ss:[bp].TSIHAF_endOffset, ax	>
EC <	ERROR_B	CUR_OFFSET_IS_BEYOND_END_OFFSET				>
EC <2$:									>
EC <	test	ss:[bp].TSIHAF_searchFlags, not mask SearchOptions	>
EC <	ERROR_NZ	BAD_SEARCH_FLAGS				>
	tst	cx
	LONG jz	getLen
doSearch:
	call	ScanForCharInBlock
	jc	notFound		;Branch if match not found

	call	CheckIfMatchFound	;Returns AX:CX = # chars in match if 
	LONG jnc	found		; found, branch to exit.

notFound:				;Not found in this block, go to next
					; one
;	Check to see if we are at the end of the range of text we are supposed
;	to check.

	cmpdw	ss:[bp].TSIHAF_curOffset, ss:[bp].TSIHAF_endOffset, ax
	stc				;If we've checked the range without
	LONG je	exit			; a match, exit w/ carry set

;	If backward search, decrement current offset
;	If forward search, increment current offset
;	If we are at the end of the current block, then call the callback
;		routine to fetch the next block

	test	ss:[bp].TSIHAF_searchFlags, mask SO_BACKWARD_SEARCH
	je	doInc
EC <	cmpdw	ss:[bp].TSIHAF_curOffset, ss:[bp].TSIHAF_endOffset, ax	>
EC <	ERROR_B	SEARCH_EXTENDED_BEYOND_END_OFFSET			>

	decdw	ss:[bp].TSIHAF_curOffset
	cmp	di, bx			;If at start of block, go to next 
	je	getNext			; block
	LocalPrevChar	esdi
	jmp	doSearch		;
doInc:
EC <	cmpdw	ss:[bp].TSIHAF_curOffset, ss:[bp].TSIHAF_endOffset, ax	>
EC <	ERROR_A	SEARCH_EXTENDED_BEYOND_END_OFFSET			>
	incdw	ss:[bp].TSIHAF_curOffset
	LocalNextChar	esdi		;Go to next character
	mov	ax, di			;AX <- offset from start of
	sub	ax, bx			; text in this block
DBCS <	shr	ax, 1			;# bytes -> # chars		>
DBCS <	EC <ERROR_C	ODD_SIZE_FOR_DBCS_TEXT				>>
	cmp	ax, dx
EC <	ERROR_A	SEARCH_EXTENDED_BEYOND_END_OF_BLOCK			>
	LONG jne	doSearch
getNext:
	movdw	dxax, ss:[bp].TSIHAF_curOffset
	call	HugeArrayCallback
	jmp	doSearch
found:
	push	ax
	movdw	dxax, ss:[bp].TSIHAF_curOffset	;DX:AX <- offset to first char
	pop	bp				;BP:CX <- # chars in match
exit:
	.leave
	ret
getLen:
	push	es, di
	segmov	es, ds
	mov	di, si
	call	LocalStringLength		;CX <- # chars in str2
	pop	es, di
EC <	jcxz	nullErr							>
	jmp	doSearch
EC <nullErr: ERROR NULL_STRING_PASSED_TO_TEXT_SEARCH_IN_STRING		>
TextSearchCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSearchInHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds an occurrence of a string (str2) in another string (str1)

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to str2 (string to match)
		cx - # chars in str2 (or 0 if null-terminated)
		ss:bp - pointer to TextSearchInHugeArrayFrame
RETURN:		carry set if string not found
		DX:AX - offset to match found
		BP:CX - # chars in match
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/91	Initial version
	sh	05/12/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSearchInHugeArray	proc	far		uses	ds, es, bx, di
	.enter

if ERROR_CHECK
	;
	; Validate that the string to match is *not* in a movable code segment
	;
FXIP<	push	bx							>
FXIP<	mov	bx, ds							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx							>
endif

;	Load in the first block of text from the huge array

	movdw	dxax, ss:[bp].TSIHAF_curOffset
	call	GetTextFromHugeArray

	call	TextSearchCommon

;	Unlock any locked blocks of text

	pushf					;Save return status
	segmov	ds, es
	call	HugeArrayUnlock			;Unlock the last allocated text
	popf
	.leave
	ret
TextSearchInHugeArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSearchInString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds an occurrence of a string (str2) in a <64K string (str1)

CALLED BY:	GLOBAL

PASS:		ES:BP - ptr to first char in string we are searching in
		ES:DI - ptr to character to start search at in string (str1)
		ES:BX - ptr to last char to include in search
		       (for forward searches, will not match any word that
			begins after this char, but will match words that
			start or at this char and extend beyond it)
		DX - # chars of str1 pointed to by ES:BP
			(zero if str1 is null terminated)
	  	DS:SI - ptr to str2 (string to match)
		      May contain C_WILDCARD or C_SINGLE_WILDCARD
	      	CX - # chars in str2 (or 0 if null-terminated)
	      	AL - SearchOptions

Example:
	Want to search for the string "foo" in "I want some food", starting
	with the "w" in "want":

	ES:DI	     ES:BX
	  V	       V
	I want some food
	^
      ES:BP
	

RETURN:		carry set if string not found
		ES:DI - ptr to last char checked
			- else -
		ES:DI - ptr to start of string found
		CX - # chars matched

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/91	Initial version
	sh	05/12/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSearchInString	proc	far	uses	ax, bp, dx, bx
	startOffset	local	word	\
			push	bp
	stackFrame	local	TextSearchInHugeArrayFrame
	.enter

if ERROR_CHECK
	;
	; Validate that the string to search is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, es							>
FXIP<	mov	si, startOffset						>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	si							>
	;
	; Validate that the string to match is not in a movable code segment
	;
FXIP<	mov	bx, ds							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx							>
endif
	tst	dx
	jz	figureLength

setupParams:

;	Massage data to match pass params of TextSearchCommon

	mov	stackFrame.TSIHAF_str1Size.low, dx
	mov	stackFrame.TSIHAF_searchFlags, al
	clr	ax
	mov	stackFrame.TSIHAF_str1Size.high, ax
	mov	stackFrame.TSIHAF_curOffset.high, ax
	mov	stackFrame.TSIHAF_endOffset.high, ax
EC <	mov	stackFrame.TSIHAF_hugeArrayVMBlock,ax			>

	mov	ax, di
	sub	ax, startOffset
DBCS <	shr	ax, 1			;byte offset -> char offset	>
DBCS <	EC <WARNING_C	WARNING_TEXT_AT_ODD_ADDRESS			>>
	mov	stackFrame.TSIHAF_curOffset.low, ax

	sub	bx, startOffset
DBCS <	shr	bx, 1			;byte offset -> char offset	>
DBCS <	EC <WARNING_C	WARNING_TEXT_AT_ODD_ADDRESS			>>
	mov	stackFrame.TSIHAF_endOffset.low, bx

	mov	bx, startOffset		;ES:BX <- ptr to first char in block
	push	bp
	lea	bp, stackFrame
	call	TextSearchCommon
	pop	bp
	.leave
	ret

figureLength:
	;
	;	Sets DX = # non-null chars at ES:BP
	;
	push	di, ax
	mov	di, startOffset
	mov	dx, cx
	call	LocalStringLength	;CX <- # bytes in string w/o null
	xchg	dx, cx			;DX <- # bytes in string w/o null
					;CX <- old CX value
	pop	di, ax
	jmp	setupParams
TextSearchInString	endp

TextSearchSpell	ends
