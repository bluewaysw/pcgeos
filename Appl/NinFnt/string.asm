COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		String Handling
FILE:		string.asm

AUTHOR:		John D. Mitchell

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.22	Initial version
	JDM	91.05.01	Changed register preservation.
	JDM	91.06.04	Added EC code.
	JDM	91.06.06	More EC code.

DESCRIPTION:
	This file contains the definitions of all of the string
	searching/deleting/etc. functions.

	$Id: string.asm,v 1.1 97/04/04 16:16:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fatal Error Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

STRING_TOO_BIG	enum	FatalErrors



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		String Code Resource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SubSearchString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the given sub-string in the main-string.

CALLED BY:	Global

PASS:		DS:SI	= Null-terminated string to search for (sub-).
		ES:DI	= Null-terminated string to be searched (main-).
		CX	= Length of main-string (including terminator).
		DX	= Length of sub-string (including terminator).

RETURN:		Carry Flag:
			Clear iff perfect match.
			Set otherwise.
		CX	= Length of match.  (strlen(sub-string)).
		ES:DI	= Pointer to start of match.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Check the arguments for some pathological cases.
	Save the arguments into locals.
	while (! EndOfString (MainString))
	  {
	  Search for the first character of the sub-string in the
	  main string. (rep scasb.)
	  if (! found) then
	    Exit with error
	  else
	    {
	    Compare remainder of the string for match. (rep cmpsb.)
	    if (equal) then
	      return (Length of match	/* Seems like a good thing	*/,
		      Pointer to start of match in main-string)
	    }
	  }
	/* If we made it here then no match.	*/
	Set error indicator.
	Return.
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:  If carry flag set then other return values are undefined!
	Yep, this is basically just a brute-force searching algorithm (the
	strings to be searched for should tend to be pretty short and
	it's pretty hard to beat rep anything in speed).
	Also, the 'repne scasb' depends on the fact that the null-terminator
	is included in the main-string length.	There's a couple of weird
	cases that (basically having to do with finding the first character
	as the last character in the main-string) are alleviated.
	The 'jcxz' before the `repe cmpsb' takes care of the pathological
	case where the sub-string is only one character.
	Also, if the sub-string passed is only the null-string then the
	a match is signaled.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.22	Initial version
	JDM	91.05.01	Added register preservation.
	JDM	91.06.06	Fixed boundary conditions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SubSearchString proc	far	uses	ax,dx,si

	; Local variables.
	FindThisStringOffset	local	word
	FindThisLengthLessOne	local	word
	CurrSearchPosOffset	local	word
	CurrSearchLength	local	word

	.enter

	; If the sub-string length passed is zero (0) then error.
	; If the sub-string length passed is one (1) then match.
	cmp	dx, 1
	jb	exitBad				; Zero (0)!  Bail!
	ja	checkRelativeSizes		; Copacetic.  Continue.

	; Otherwise, set the return values and exit.
	; NOTE:	DX, DS:SI, ES:DI already set.
	clr	cx				; Null match length.
	clc					; Signal success.
	jmp	exit

checkRelativeSizes:
	; Check to make sure that the sub-string is actually smaller
	; than the main-string.
	cmp	cx, dx
	jb	exitBad

	; Save the arguments into the appropriate locals.
	; NOTE: ES & DS are assumed to be unchanging!
	mov	ss:[FindThisStringOffset], si
	dec	dx				; Forget terminator.
	dec	dx				; Forget first character.
	mov	ss:[FindThisLengthLessOne], dx
	mov	ss:[CurrSearchPosOffset], di
	mov	ss:[CurrSearchLength], cx
	mov	al, ds:[si]			; Character to scan for.

mainLoop:
	; Scan for the first character of the sub-string.
	; NOTE: DS:SI == Start of sub-string,
	;	ES:DI == Current position in main-string.
	;	CX = Number of characters left in main-string.
	;	AX = First character of sub-string.
	repne	scasb
	jcxz	exitBad				; Nothing left!

	; ES:DI == One past the matched character.
	; Save the current position as where to start if we fail.
	mov	ss:[CurrSearchPosOffset], di

	; CX == One less than the match character's position.
	; Save the current character count for later re-start.
	mov	ss:[CurrSearchLength], cx

	; Skip first character.
	inc	si

	; Now check the rest of the strings for equality.
	; NOTE: DS:SI == Second character of sub-string,
	;	ES:DI == Second character of possible match in main-string,
	mov	cx, ss:[FindThisLengthLessOne]	; CX = Length sub-string-1.
	jcxz	exitMatch
	repe	cmpsb
	jz	exitMatch			; We found it!!

	; Otherwise no match so set up for next pass.
	; Re-load to resume search for first character.
	mov	si, ss:[FindThisStringOffset]	; Sub-string.
	mov	al, ds:[si]			; Character to scan for.
	mov	di, ss:[CurrSearchPosOffset]	; Main-string.
	mov	cx, ss:[CurrSearchLength]	; Max. length to search.
	jmp	mainLoop

exitMatch:
	; Set up return values.
	; NOTE: DS assumed unchanged from start.
	mov	di, ss:[CurrSearchPosOffset]	; One past match start.
	dec	di				; ES:DI == Match start.
	mov	cx, ss:[FindThisLengthLessOne]	; Match length - 1.
	inc	cx				; Match length.
	clc					; Signal success.
	jmp	exit				; That's all folks!

exitBad:
	; No match found.
	stc					; Signal failure.

exit:
	; We're outta here!
	.leave
	ret
SubSearchString endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsSubString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the given sub-string in the main-string.

CALLED BY:	Global

PASS:		DS:SI	= Null-terminated string to search for (sub-).
		ES:DI	= Null-terminated string to be searched (main-).

RETURN:		Carry Flag:
			Clear iff perfect match.
			Set otherwise.
		CX	= Length of match. (This is also the length of
			  the sub-string - 1.  FYI.)
		DX	= Length of main-string (Why?!?	 Just because! :-)
		ES:DI	= Pointer to start of match in the main-string.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Find the length of the main-string.
	Find the length of the sub-string.
	Call SubSearchString to do the searching.

CHECKS:
	No null-terminator.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:  If carry flag set then other return values are undefined!
	So in otherwords this function is just a front for SubSearchString.
	Therefore if you have the extra length information hanging around
	you're better off call SubSearchString directly.
	Also, the null-string is considered a sub-string of any string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.23	Initial version
	JDM	91.04.24	Added returning of main-string length.
	JDM	91.05.01	Added register preservation.
	JDM	91.06.04	Added EC code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsSubString	proc	far	uses	ax,bx,si
	.enter

	; Save the pointer to the strings.
	DoPush	es, di, ds, si

	; Figure out how long the main-string is.
	clr	ax				; Search for terminator.
	mov	cx, -1				; Could be big! :-(
	repne	scasb

	; Check for non-terminated string.
EC <	tst	cx							>
EC <	ERROR_E	STRING_TOO_BIG						>
	jcxz	exitBad				; NO terminator!!!!!

	; Otherwise, calculate the length.
	mov	ax, -1
	sub	ax, cx				; AX = 0xffff-ending count.
	mov	bx, ax				; Save the length.

	; Figure out the length of the sub-string.
	segmov	es, ds, ax			; ES:DI=DS:SI (sub-string).
	mov	di, si
	clr	ax				; Search for terminator.
	mov	cx, -1				; Could be big! :-(
	repne	scasb

	; Check for non-terminated sub-string.
EC <	tst	cx							>
EC <	ERROR_E	STRING_TOO_BIG						>
	jcxz	exitBad

	; Otherwise, calculate the sub-string length.
	mov	ax, -1
	sub	ax, cx				; AX = 0xffff-ending count.

	; Go search for the sub-string in the main-string.
	mov	dx, ax				; Length of sub-string.
	mov	cx, bx				; Length of main-string.
	DoPopRV es, di, ds, si			; Restore string pointers.
	push	cx				; Save main-string length.
	call	SubSearchString
	pop	dx				; Restore main-str length.
	jmp	exit

exitBad:
	; Some gnarly demise. Notify caller.
	DoPopRV es, di, ds, si			; Clean up stack.
	stc

exit:
	.leave
	ret
IsSubString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveSubString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the given sub-string from the main-string.

CALLED BY:	Global

PASS:		DS:SI	= Null-terminated string to search for (sub-).
		ES:DI	= Null-terminated string to be searched (main-).

RETURN:		Carry Flag:
			Clear iff found match and deleted.
			Set otherwise.
		CX	= Length of resultant (main-) string (including
			  the null-terminator).

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	This function will search for and delete the first occurrence of
	the passed sub-string from the given main-string.
	Save the arguments.
	Call IsSubString to locate the sub-string.
	If not found then return with appropiate errors.
	Otherwise:
		Overwrite the matched sub-string (in the main-string) with
		the rest of the string after the match (i.e. move each
		character after the match 'match-length' spaces to the
		left).
		Return the length of the resultant string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:  If carry flag set then other return values are undefined!
	Also, if the sub-string is empty (i.e. == null-string) then
	a success/match is reported (because the null-string is a sub-
	string of any string).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.23	Initial version
	JDM	91.05.01	Added register preservation.
	JDM	91.06.05	Added boundary conditions checking.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemoveSubString proc	far	uses	ax,bx,dx

	; Local variables.
	SubStringPtr	local	fptr
	MainStringPtr	local	fptr

	.enter

	; Save the arguments into the appropriate locals.
	mov	ss:[SubStringPtr].segment, ds
	mov	ss:[SubStringPtr].offset, si
	mov	ss:[MainStringPtr].segment, es
	mov	ss:[MainStringPtr].offset, di

	; Find the sub-string in the main-string (or not :-).
	; NOTE: ES:DI, DS:SI already set.
	call	IsSubString
	jc	exit				; Not found! Bail!

	; Otherwise, check to see if the sub-string == null-string.
	; NOTE:	The exit code takes care of the return value set up.
	tst	cx				; Zero match length?
	jz	exit				; Yep.  Bail!

	; Otherwise, nuke the damn thing.
	; CX == match length (sub-string length without terminator),
	; DX == main-string length (including terminator),
	; ES:DI == start of match.
	; Figure out how many bytes to copy.
	; The formula for this is:
	; (1)	[(strlen (main-string) + 1 (for null-terminator)) -
	; (2)	 (Match start offset - original main-string offset) -
	; (3)	 (match length)]
	mov	bx, dx				; Save main-string length.
	sub	dx, cx				; DX = (1) - (3) above.
	mov	ax, di				; AX = (2a) above.
	sub	ax, ss:[MainStringPtr].offset	; AX = (2) above.
	sub	dx, ax				; DX = (1) - (2) - (3).
	xchg	cx, dx				; CX = # of bytes to copy.
						; DX = match length.
	segmov	ds, es, ax			; DS:SI = byte after match.
	mov	si, di				; SI == start of match.
	add	si, dx				; SI == byte after match.
	rep	movsb

	; Calculate the resultant main-string length.
	sub	bx, dx				; Main-string - match len.
	mov	dx, bx				; New Main-string length.

exit:
	; IsSubString returns the length of the main-string in DX so
	; fix it!  Note that DX is set properly if there was a match.
	mov	cx, dx

	; Restore the arguments from the appropriate locals.
	lds	si, ss:[SubStringPtr]
	les	di, ss:[MainStringPtr]

	.leave
	ret
RemoveSubString endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CollapseSpaceString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace runs of spaces with a single space in the given
		string.

CALLED BY:	Global

PASS:		ES:DI	= Null-terminated string to be collapsed.

RETURN:		Carry Flag:
			Set iff error.
			Clear otherwise.
		CX	= Length of resultant string (including the
			  null-terminator).

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	(Think of this as a selective string copy (from InString to
	OutString) even though the destination is the same physical
	space as the source.)
	Point both string pointers to the start of the string.
	OuterSpace = TRUE;	/* Our we in the middle of a space run? */
	while (! EndOfString(InString))
	  {
	  if (OuterSpace)
	    if (InString[icurr] == ' ')
	      {
	      Skip the space (i.e. icurr++;)
	      continue;
	      }
	    else
	      OuterSpace = TRUE;
	  else if (InString[curr] == ' ')
	    OuterSpace = FALSE;
	  OutString[ocurr] = InString[icurr];
	  icurr++;
	  ocurr++;
	  }	
	
CHECKS:
	No null-terminator.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	This thing will run until it finds a nul (`\0`) character!
		In other words, if the string ain't null-terminated you
		lose!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.24	Initial version
	JDM	91.05.02	Added register preservation.
	JDM	91.06.04	Rewrote EC code.
	JDM	91.06.06	Rewrote EC code again.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CollapseSpaceString	proc	far	uses	ax,bx,ds,si,es,di
	.enter

	; Set up for search loop.
	; NOTE:
	;	DS:SI == InString,
	;	ES:DI == OutString,
	;	BX = OuterSpace flag (Zero == FALSE, One == TRUE).
	;	CX = Characters moved to OutString.
	;	AH = ' ' (space character).
	segmov	ds, es, ax			; DS:SI = ES:DI.
	mov	si, di
	mov	ah, 20h				; AH = ' '.
	clr	cx				; # of OutString chars.
	mov	bx, 1				; OuterSpace = TRUE;

reduceLoop:
	; NOTE: SI automatically advanced to next char.
	lodsb					; AL = InString[icurr++];

	; Are we done yet?
	tst	al				; Is it a '\0'?
	jz	done				; Yep!	See ya!

	; Are we in a run of spaces?
	tst	bx				; OutSpace == FALSE?
	jnz	outerSpace			; Nope.

	; Otherwise, check for a redundant space character.
	cmp	al, ah				; AH from above.
	jz	reduceLoop			; Yep, so skip character.

	; Otherwise, no longer in run of spaces.
	inc	bx				; OuterSpace = TRUE;
	jmp	copyChar			; Copy the character.

outerSpace:
	; Otherwise, check for a space character.
	cmp	al, ah				; AH from above.
	jnz	copyChar			; Nope, go copy character.

	; Otherwise, it's the first of a (possible) space run.
	dec	bx				; OuterSpace = FALSE;

	; Fall through!
copyChar:
	; If the count is just about to be incremented back to zero
	; then the damn string wasn't null-terminated!
	; The check is against 0xFFFF because if the string went right
	; up to the end then the null-terminator check above would
	; have succeeded.
	cmp	cx, 0FFFFh			; End of segment?
EC <	ERROR_E	STRING_TOO_BIG						>
	jz	exitBad				; Yep. Bail!

	; Otherwise, store the character and move on.
	; NOTE:
	;	AL already set.
	;	DI automatically updated.
	stosb

	; Count the copied character.
	inc	cx
	jmp	reduceLoop			; Next!

done:
	; Copy and count that final nul character.
	stosb					; Copy it.
	inc	cx				; Count it.
	clc					; Signal copacetic-ness.
	jmp	exit				; Skip death.

exitBad:
	stc					; Signal error.

exit:
	.leave
	ret
CollapseSpaceString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrimTrailingSpaceString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all trailing spaces from given the string.

CALLED BY:	Global

PASS:		ES:DI	= Null-terminated string to be trimmed.

RETURN:		CX	= Length of resultant string (including the
			  null-terminator).

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	curr = strlen (String) - 1;
	while (String [curr] == ' ')
	  {
	  String [curr--] = '\0';
	  }
	
CHECKS:
	No null-terminator.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	This thing will run until it finds a nul (`\0`) character!
		In other words, if the string ain't null-terminated you
		lose!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.26	Initial version
	JDM	91.06.04	Added string length EC checking.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrimTrailingSpaceString	proc	far	uses	ax,bx,ds,si,di
	.enter

	; Figure out how long the string is.
	clr	ax				; Search for terminator.
	mov	cx, -1				; Could be big! :-(
	repne	scasb

	; Check for non-terminated string.
EC <	tst	cx							>
EC <	ERROR_E	STRING_TOO_BIG						>
	jcxz	done				; NO terminator!!!!!

	; Otherwise, calculate the length.
	mov	ax, -1
	sub	ax, cx				; AX = 0xffff-ending count.
	xchg	ax, cx				; CX = length of string.

	; Set up for trimming loop.
	; NOTE:
	;	ES:DI = Last character in the string.
	;	CX = Characters in the string (including terminator).
	;	AH = `\0` (nul character).
	;	BL = ' ' (space character).
	;	Direction Flag:  Set.  We're going down!!!
	segmov	ds, es, ax			; DS:SI = ES:DI.
	dec	di				; Was one past nul.
	dec	di				; Skip nul character.
	mov	si, di
	clr	ax
	mov	bx, 20h
	std

trimLoop:
	; NOTE: SI automatically decremented to previous char.
	lodsb					; AL = InString[icurr--];

	; Is this a blank?
	cmp	al, bl				; BL from above.
	jnz	done				; Nope!  That's all then.

	; Otherwise, this is a space so let's nuke it.
	mov	al, ah				; AH from above.
	dec	cx				; One less character.

	; NOTE:	DI automatically updated.
	stosb
	jmp	trimLoop			; Next!

done:
	; Reset the direction flag.
	cld

	.leave
	ret
TrimTrailingSpaceString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace all occurrences of a given character with another
		given character in the passed string.

CALLED BY:	Global

PASS:		ES:DI	= Null-terminated string to be converted.
		BL	= Character to get rid of.
		BH	= Character to use instead.

RETURN:		Void.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	(Think of this as a selective string copy (from InString to
	OutString) even though the destination is the same physical
	space as the source.)
	Point both string pointers to the start of the string.
	while (! EndOfString(InString))
	  {
	  if (InString[curr] == SearchChar)
	    InString[curr] = ReplacementChar;
	  curr++;
	  }	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	This thing will run until it finds a nul (`\0`) character!
		In other words, if the string ain't null-terminated you
		lose!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.24	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReplaceCharString	proc	far	uses	ax,ds,si,di
	.enter

	; Set up for search loop.
	; NOTE:
	;	DS:SI == InString,
	;	ES:DI == OutString,
	;	BL = Search character.
	;	BH = Replacement character.
	segmov	ds, es, ax			; DS:SI = ES:DI.
	mov	si, di

replaceLoop:
	; NOTE: SI automatically advanced to next char.
	lodsb					; AL = InString[curr++];

	; Are we done yet?
	tst	al				; Is it a '\0'?
	jz	done				; Yep!	See ya!

	; Check for our search character.
	cmp	al, bl				; BL from above.
	jnz	copyChar			; Nope, move on.

	; Otherwise, save the replacement character in its place.
	mov	al, bh				; BH from above.

copyChar:
	; NOTE:
	;	AL already set.
	;	DI automatically updated.
	stosb
	jmp	replaceLoop			; Next!

done:
	.leave
	ret
ReplaceCharString	endp


StringCode	ends
