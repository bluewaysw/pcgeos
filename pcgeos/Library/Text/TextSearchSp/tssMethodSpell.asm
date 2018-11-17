COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	UI
MODULE:		Text
FILE:		textMethodSpell.asm

AUTHOR:		Andrew Wilson, Mar 29, 1991

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/91		Initial revision

DESCRIPTION:
	This file contains the handlers for the various spell check methods.

	$Id: tssMethodSpell.asm,v 1.1 97/04/07 11:19:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextSearchSpell	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spell checks the passed word

CALLED BY:	GLOBAL
PASS:		bx - ICBuff
		ds:si - null terminated string to check
RETURN:		ax - SpellResult
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckWord	proc	near	uses	cx
	.enter
	mov	cx, offset checkWordEntryPoint
	call	CallSpellLibrary
	.leave
	ret
CheckWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetErrorFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the error flags

CALLED BY:	GLOBAL
PASS:		bx - handle of ICBuff
RETURN:		ax - SpellErrorFlagsHigh
		cx - SpellErrorFlags
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetErrorFlags	proc	near
	mov	cx, offset getErrorFlagsEntryPoint
	FALL_THRU	CallSpellLibrary
GetErrorFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSpellLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the spell library

CALLED BY:	GLOBAL
PASS:		cx - offset to variable holding entry point (in dgroup)
		bx - ICBuff
RETURN:		whatever from spell lib
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallSpellLibrary	proc	near	uses	bx
	.enter
	xchg	cx, bx			;CX <- ICBuff
					;BX <- offset to entry point variable
	push	es
	mov	ax, segment udata
	mov	es, ax
	mov	ax, es:[bx].low
	mov	bx, es:[bx].high
	pop	es
	call	ProcCallFixedOrMovable
	.leave
	ret
CallSpellLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetDoubleWordCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the double word check (so if the next word checked
		is the same as the previous word, no error is generated)

CALLED BY:	GLOBAL
PASS:		bx - ICBuff
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetDoubleWordCheck	proc	near	uses	ax, cx
	.enter
	mov	cx, offset resetDoubleWordCheckEntryPoint
	call	CallSpellLibrary
	.leave
	ret
ResetDoubleWordCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextOffsets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if there is embedded punctuation in the word

CALLED BY:	GLOBAL
PASS:		bx - ICBuff
RETURN:		ax - offset to first char of word
		cx - offset to last char in word
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextOffsets	proc	near

	mov	cx, offset getTextOffsetsEntryPoint 
	GOTO	CallSpellLibrary
GetTextOffsets	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIsWhitespace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if passed char is whitespace

CALLED BY:	GLOBAL
PASS:		ax - char to test (Null bytes are not whitespace)
RETURN:		z flag clear if whitespace (jne isWhitespace)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIsWhitespace	proc	far	uses	ax
	.enter
	cmp	ax, C_GRAPHIC		;Treat graphics escapes as whitespace
	jz	whitespace
	call	LocalIsSpace
exit:
	.leave
	ret
whitespace:
	or	ah, 1			;Clear the Z flag
	jmp	exit
CheckIsWhitespace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine adjusts the passed text ptr to point to the
		passed offset

CALLED BY:	GLOBAL
PASS:		dx.cx - offset
		es:di - ptr to text
		*ds:si - vis text object
RETURN:		es:di - ptr to text (updated)
		CX - # consecutive chars at ptr
		dx.si - new offset
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustTextPtr	proc	near	uses	ax
	.enter
	push	cx
	mov	ax, es
	call	TS_UnlockTextPtr		;Unlock old text block

	mov_tr	ax, cx				;DX.AX <- text offset
	call	TS_LockTextPtrESDI		;Lock new text block
	mov_tr	cx, ax				;
	pop	si
	.leave
	ret
AdjustTextPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipWhitespace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine skips whitespace.

CALLED BY:	GLOBAL
PASS:		*ds:si - ptr to VisText object
		ss:bp <- ptr to inherited stack frame
		ES:DI <- ptr to text
		DX.AX <- offset into text to start skipping
		CX <- # chars in this text block
RETURN:		DI <- -1 if we hit the end of the document
		      (either in real life or because we checked the requisite
		       # chars).
		 - else -
		ES:DI <- updated to point to first non-whitespace char
		DX.AX <- updated offset into text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	WARNING: assumptions about the stack are made in doReset:, do
               not change the stack usage without first looking at
               doReset:. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipWhitespace	proc	near	uses	si, bx
	class	VisTextClass

	charsToCheck	local	dword
	flags		local	SpellCheckFromOffsetFlags
	resetSpell	local	byte

	.enter	inherit far
	clr	resetSpell

;	SET BX.BP AS # CHARS TO CHECK (EITHER THE # CHARS PASSED IN,
;	OR -1)

	push	bp
	push	si
	mov_tr	si, ax		;DX.AX <- offset into text
	mov	bx, charsToCheck.high
	test	flags, mask SCFOF_CHECK_NUM_CHARS
	mov	bp, charsToCheck.low
	jnz	10$
	mov	bx, -1
	mov	bp, bx		;BX.BP <- An extremely large # chars to check
10$:
	subdw	bxbp, 1		;Pre-decrement the # chars to check
				;This allows us to check the carry in the loop
				; below instead of testing the entire dword
loopTop:
;	DX.SI <- offset into text
;	BX.BP <- # chars to check
;	ES.DI <- ptr to next char to check

SBCS <	mov	al, es:[di]						>
SBCS <	clr	ah							>
DBCS <	mov	ax, es:[di]						>
if DBCS_PCGEOS
	push	ax
	call	LocalGetWordPartType
	cmp	ax, WPT_ALPHA_NUMERIC
	je	haveResult
	cmp	ax, WPT_FULLWIDTH_ALPHA_NUMERIC
haveResult:
	pop	ax
	je	exit			;is alpha-numeric, done
else
	call	CheckIsWhitespace
	jz	exit
endif
				;Sit in a loop and skip all the whitespace
	subdw	bxbp, 1
	jc	endOfDocumentReached	;Exit if no more chars to check.
	tst	ax			;At the end of the document?
	jz	endOfDocumentReached	;Branch if so
	cmp	ax, C_CR
	je	doReset
	cmp	ax, C_PAGE_BREAK
	je	doReset
	cmp	ax, C_SECTION_BREAK
	je	doReset
	cmp	ax, C_TAB
	je	doReset
if DBCS_PCGEOS
	;
	; For spell-checking in DBCS, we treat Japanese (hiragana,
	; katakana, and Kanji) as whitespace.  However, we want
	; to reset the double-word check if we encounter any.
	;
	push	ax
	call	LocalGetWordPartType
	cmp	ax, WPT_PUNCTUATION
	je	haveResult2
	cmp	ax, WPT_SPACE
haveResult2:
	pop	ax
	jne	doReset			;branch if not whitespace
endif

50$:
	incdw	dxsi			;Inc offset into text
	LocalNextChar	esdi		;Inc ptr to text
	
	loop	loopTop			;Dec # chars left in this block

;	We've reached the end of the text in this block, so unlock it and
;	lock the next.

	mov_tr	cx, si			;DX.CX <- offset to text to get
	pop	si			;*DS:SI <- VisText object
	push	si
	call	AdjustTextPtr
	jmp	loopTop
doReset:

;	We have hit a CR, so return a flag to reset the spell check
;	(2 identical words separated by carriage returns or page breaks
;	should not be flagged as a repeated word).

	mov_tr	ax, bp
	mov	bp, sp
	mov	bp, ss:[bp]+2		;Get ptr to stack frame 2 words down
					; on the stack
	mov	resetSpell, -1
	mov_tr	bp, ax
	jmp	50$

endOfDocumentReached:
	mov	di, -1		;Return DI=-1 to show that we have reached the
				; end of the document
exit:
	mov_tr	ax, si		;DX.AX <- offset to non-whitespace char
	add	sp, 2		;
	adddw	bxbp, 1		;Add one to # chars to check, as we 
				; pre-decremented it above.
	xchg	si, bp		;SI <- low word of # chars skipped
	pop	bp
	movdw	charsToCheck, bxsi
	.leave
	ret

SkipWhitespace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipToWhitespace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine skips to the next whitespace char.

CALLED BY:	GLOBAL
PASS:		*ds:si - ptr to VisText object
		ss:bp <- ptr to inherited stack frame
		ES:DI <- ptr to text
		DX.AX <- offset into text to start skipping
		CX <- # chars in this text block
RETURN:		DI <- -1 if we hit the end of the document
		      (either in real life or because we checked the requisite
		       # chars).
		 - else -
		ES:DI <- updated to point to first non-whitespace char
		DX.AX <- updated offset into text
		CX <- # chars updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	 WARNING: assumptions about the stack are made in doReset:, do
               not change the stack usage without first looking at
               doReset:. 
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/13/91		Initial version
	IP      7/7/94          changed to reset double word check if
                                '.' encountered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipToWhitespace	proc	near	uses	si, bx
	class	VisTextClass

	charsToCheck	local	dword
	flags		local	SpellCheckFromOffsetFlags
	resetSpell	local	byte

	.enter	inherit far
	clr	resetSpell

;	SET BX.BP AS # CHARS TO CHECK (EITHER THE # CHARS PASSED IN,
;	OR -1)

	push	bp
	push	si
	mov_tr	si, ax		;DX.AX <- offset into text
	mov	bx, charsToCheck.high
	test	flags, mask SCFOF_CHECK_NUM_CHARS
	mov	bp, charsToCheck.low
	jnz	10$
	mov	bx, -1
	mov	bp, bx		;BX.BP <- An extremely large # chars to check
10$:
	subdw	bxbp, 1		;Pre-decrement the # chars to check
				;This allows us to check the carry in the loop
				; below instead of testing the entire dword

clearLoop:
	clr	ax		;Last char was a NULL (so we don't accidentally
				; trigger the ellipsis check if the first char
				; is a period and AH *happens* to be a
				; period also).

loopTop:			;Sit in a loop and skip until we hit a
				; whitespace, an ellipsis, or the end of the
				; document.
	push	cx

;	DX.SI <- offset into text
;	BX.BP <- # chars to check
;	ES:DI <- ptr to next char to check
;	AX <- previous char

	mov	cx, ax			;CX = prev char
SBCS <	mov	al, es:[di]						>
SBCS <	clr	ah							>
DBCS <	mov	ax, es:[di]						>
	tst	ax
	jz	endOfDocumentReached
if DBCS_PCGEOS
	push	ax
	call	LocalGetWordPartType
	cmp	ax, WPT_PUNCTUATION
	je	haveResult
	cmp	ax, WPT_ALPHA_NUMERIC
	je	haveResult
	cmp	ax, WPT_FULLWIDTH_ALPHA_NUMERIC
haveResult:
	pop	ax
	jne	exit			;not alpha-numeric, have "whitespace"
else
	call	CheckIsWhitespace
	jnz	exit			;Exit if whitespace
endif
	xchg	cx, ax			;CX <- this char
					;AX <- last char
SBCS <	cmp	ax, C_ELLIPSIS		;Break after ellipsis		>
DBCS <	cmp	ax, C_HORIZONTAL_ELLIPSIS				>
	je	exit
	cmp	cx, '.'
	je	doReset
	jmp	20$
afterReset:	
	cmp	ax, '.'			;Break after 2 periods too.
	je	exit
20$:

	subdw	bxbp, 1
	jc	endOfDocumentReached	;Exit if no more chars to check.
	adddw	dxsi, 1			;Inc offset into text
	LocalNextChar	esdi		;Inc ptr to text
	
	mov	ax, cx			;AX = this char becomes next prev char
	pop	cx
	loop	loopTop			;Dec # chars left in this block

;	We've reached the end of the text in this block, so unlock it and
;	lock the next.

	mov	cx, si			;DX.CX <- offset to text to get
	pop	si			;*DS:SI <- VisText object
	push	si
	call	AdjustTextPtr		;DX.SI <- offset to text
	jmp	clearLoop

doReset:
;     We have hit a '.', so return a flag to reset the spell check
;     (2 identical words separated by '.'should not be flagged as a
;     repeated word). 
 
	xchg	ax, bp
	mov     bp, sp
	mov     bp, ss:[bp]+4           ;Get ptr to stack frame 2 words down
	                                ; on the stack
	mov     resetSpell, -1
	xchg	bp, ax
	jmp     afterReset
 

endOfDocumentReached:
	mov	di, -1		;Return DI=-1 to show that we have reached the
				; end of the document
exit:
	pop	cx		;get char count
	mov_tr	ax, si		;DX.AX <- offset to non-whitespace char
	add	sp, 2		;
	adddw	bxbp, 1		;Add one to # chars to check, as we 
				; pre-decremented it above.
	xchg	si, bp		;SI <- low word of # chars skipped
	pop	bp
	movdw	charsToCheck, bxsi
	.leave
	ret

SkipToWhitespace	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumCharsInSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the number of non-optional-hyphen chars in the passed
o		range

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		dx:ax <- # visible chars in selection
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumCharsInSelection	proc	near		uses	bx
	class	VisTextClass
	.enter

	call	TSL_SelectGetSelection	;dx.ax - selection start
					;cx.bx - selection end
	subdw	cxbx, dxax
	movdw	dxax, cxbx
	.leave
	ret
GetNumCharsInSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindWordBoundaryBeforeSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the offset of the beginning of the word that the
		start of the selection lies in.

CALLED BY:	GLOBAL
PASS:		dx.ax - offset of start of selection
		*ds:si - ptr to text object
		ss:bx - SpellCheckFromOffsetStruct
				(for updating # chars to check)
RETURN:		dx.ax - offset to start of word spanning selection
DESTROYED:	cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindWordBoundaryBeforeSelection	proc	far	uses	es,di, bx
DBCS <	offsetLow	local	word					>
DBCS <	wpt		local	word					>
	.enter

;	The user wants to spell check the current selection - we want to 
;	start the spell check at the beginning of the current word (if we 
;	are at the start of the text, we just exit).

SBCS <	mov	bp, ax			;DX.BP <- current offset	>
DBCS <	mov	offsetLow, ax		;DX.BP <- current offset	>
loopTop:
	tst	ax
	jnz	doCheck
	tst	dx
	jz	exit			;Branch if at start of text.
doCheck:
	mov	cx, bx
	mov	bx, cx			;SS:BX <- ptr to stack frame

if not KEYBOARD_ONLY_UI

if DBCS_PCGEOS
	call	TS_LockTextPtrESDI	;es:di = text, cx=#before, ax=#after
	mov	ax, es:[di]		;ax = first character in selection
	call	LocalGetWordPartType
	mov	wpt, ax			;save WPT
	LocalPrevChar	esdi		;back one char
	dec	cx			;one less char before
	jnz	haveTextPtr		;if any left, use it
	mov	ax, es			;else, unlock and re-lock
	call	TS_UnlockTextPtr
	mov	ax, offsetLow
endif

	decdw	dxax			;DX.AX <- offset to char before
	call	TS_LockTextPtrESDI	; start of selection
DBCS <haveTextPtr:							>

findWordBoundary:
;	FIND THE FIRST WORD BOUNDARY (WHITESPACE) BEFORE THE SELECTION.
;
;	ES:DI <- ptr to text char to check
;	CX <- # chars in text block
;	DX.BP <- offset to selection point after current char
;
SBCS <	mov	al, es:[di]						>
SBCS <	clr	ah							>
DBCS <	mov	ax, es:[di]						>
EC <	LocalIsNull	ax		;				>
EC <	ERROR_Z	-1							>

if DBCS_PCGEOS
	push	ax
	call	LocalGetWordPartType
	cmp	ax, wpt
	pop	ax
	jne	foundBoundary		;not same as 1st char, have "whitespace"
else
	call	CheckIsWhitespace	;
	jnz	foundBoundary		;Branch if whitespace
endif

else	;KEYBOARD_ONLY_UI
	call	TS_LockTextPtrESDI	; start of selection
	;
	; Decrementing the pointer is not done in Redwood, so that when the 
	; cursor is the last character of the word, we spell check at the start
	; of the following word, not the previous word.
	;
	dec	cx			; decrement number of chars before
					;   ptr, to account for the pointer
					;   not being decremented
findWordBoundary:
;	FIND THE FIRST WORD BOUNDARY (WHITESPACE) BEFORE THE SELECTION.
;
;	ES:DI <- ptr to text char to check
;	CX <- # chars in text block
;	DX.BP <- offset to selection point after current char
;

	mov	al, es:[di]
	tst	al			;null, back up to something useful
	jz	tryPreviousChar

DBCS <PrintMessage <fix DBCS Redwood>>
	call	CheckIsWhitespace	;
	jnz	foundBoundary		;Branch if whitespace
tryPreviousChar:							

endif	;not REDWOOD

	incdw	ss:[bx].SCFOS_numChars	;Inc # chars to check
	LocalPrevChar	esdi		;Goto next one
SBCS <	decdw	dxbp			;				>
DBCS <	sub	offsetLow, 1		;inline decdw dx.offsetLow	>
DBCS <	sbb	dx, 0							>
	loop	findWordBoundary	;

;	WE'VE TRIED ALL THE CHARS IN THIS BLOCK - GO TO THE PREVIOUS ONE

	mov	ax, es
	call	TS_UnlockTextPtr
SBCS <	mov	ax, bp							>
DBCS <	mov	ax, offsetLow						>
	jmp	loopTop
	
foundBoundary:
	mov	ax, es
	call	TS_UnlockTextPtr
SBCS <	mov_tr	ax, bp			;DX.AX <- current offset	>
DBCS <	mov	ax, offsetLow		;DX.AX <- current offset	>
exit:
	.leave
	ret
FindWordBoundaryBeforeSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSearchSpellObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the spell object appropriate to the passed 
		GetSearchSpellObjectOption.

CALLED BY:	GLOBAL
PASS:		ax - GetSearchSpellObjectOption
		*ds:si - text object
RETURN:		^lcx:dx - optr of object
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSearchSpellObject	proc	near	uses	bp
	.enter
	mov_tr	bp, ax
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	call	SearchSpellObjCallInstanceNoLockNear
	.leave
	ret
GetSearchSpellObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSpellCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method spell checks the current object.

CALLED BY:	GLOBAL
PASS:		*ds:si, ds:di - VisTextClass object
		cx - SpellCheckOptions
		bp - handle of ICBuff object
RETURN:		nada

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSpellCheck	proc	far	; MSG_SPELL_CHECK
	class	VisTextClass

	.enter
	sub	sp, size SpellCheckFromOffsetStruct

;	COPY OVER SpellCheckInfo

	mov	bx, sp
	mov	ax, ss:[bp].SCI_ICBuff
	mov	ss:[bx].SCFOS_ICBuff, ax
	movdw	ss:[bx].SCFOS_numChars, ss:[bp].SCI_numChars, ax
	movdw	ss:[bx].SCFOS_replyOptr, ss:[bp].SCI_replyObj, ax
	mov	di, ss:[bp].SCI_options
	clr	ss:[bx].SCFOS_flags
EC <	test	di, mask SCO_CHECK_SELECTION or mask SCO_CHECK_NUM_CHARS>
EC <	jz	5$							>
EC <	jpo	5$							>
EC <	ERROR	SCO_CHECK_SELECTION_AND_NUM_CHARS_BOTH_SET		>
EC <5$:									>
	test	di, mask SCO_CHECK_NUM_CHARS
	jne	setNumCharsFlag
	test	di, mask SCO_CHECK_SELECTION
	je	getOffset

;	GET THE NUM CHARS IN THE SELECTION

	call	GetNumCharsInSelection	;DX.AX <- # chars in selection
	movdw	ss:[bx].SCFOS_numChars, dxax
setNumCharsFlag:
	ornf	ss:[bx].SCFOS_flags, mask SCFOF_CHECK_NUM_CHARS
getOffset:

;	DETERMINE APPROPRIATE OFFSET AND OBJECT TO START SPELL CHECK

.assert offset SCO_START_OPTIONS eq 0

	and	di, mask SCO_START_OPTIONS
	cmp	di, SCSO_BEGINNING_OF_DOCUMENT
	je	getFirstObject
	push	bx
	call	TSL_SelectGetSelectionStart	;dx.ax = start of selection
	pop	bx

	cmp	di, SCSO_BEGINNING_OF_SELECTION
	je	20$
	cmp	di, SCSO_WORD_BOUNDARY_BEFORE_SELECTION
	je	10$
		;Must be SCSO_END_OF_SELECTION, so start at the end of the
		; selected area
	test	ss:[bx].SCFOS_flags, mask SCFOF_CHECK_NUM_CHARS
	jz	8$
	call	GetNumCharsInSelection
	subdw	ss:[bx].SCFOS_numChars, dxax
	jc	skippedToEndOfDocument
8$:	
	call	TSL_SelectGetSelectionEnd
	jmp	20$
10$:
	call	FindWordBoundaryBeforeSelection

20$:
	movdw	ss:[bx].SCFOS_offset,dxax
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
common:

;	SEND SPELL CHECK MSG OFF TO THE APPROPRIATE OBJECT (^lCX:DX)

	mov	ax, MSG_VIS_TEXT_SPELL_CHECK_FROM_OFFSET
	mov	bx, cx
	mov	si, dx
	mov	dx, size SpellCheckFromOffsetStruct
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or mask MF_STACK
	mov	bp, sp
	call	SearchSpellObjMessageNear
exit:
	add	sp, size SpellCheckFromOffsetStruct
	.leave
	ret

skippedToEndOfDocument:
	mov	ax, MSG_SC_SPELL_CHECK_COMPLETED
	mov	cx, SCR_SELECTION_CHECKED
	movdw	bxsi, ss:[bp].SCI_replyObj
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	exit

getFirstObject:
	mov	ax, GSSOT_FIRST_OBJECT
	call	GetSearchSpellObject
	clr	ax
	clrdw	ss:[bx].SCFOS_offset, ax	;Start at beginning of the
	jmp	common				; object.
VisTextSpellCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectTextAndMakeTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects text and makes it the target.

CALLED BY:	GLOBAL
PASS:		DX.AX <- offset to text string to select
		CX <- length of text string to select
		*DS:SI <- ptr to text object
RETURN:		nada
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectTextAndMakeTarget	proc	near	uses	bp, cx
	.enter

ifdef GPC_SEARCH
	;
	; show selection at top of window since search and spell dialogs
	; are at bottom of screen
	;
	push	ax, cx, dx, bp
	sub	sp, size AddVarDataParams
	mov	bp, sp
	movdw	ss:[bp].AVDP_data, 0
	mov	ss:[bp].AVDP_dataSize, 0
	mov	ss:[bp].AVDP_dataType, TEMP_VIS_TEXT_SHOW_SELECTION_AT_TOP
	mov	ax, MSG_META_ADD_VAR_DATA
	call	SearchSpellObjCallInstanceNoLockNear
	add	sp, size AddVarDataParams
	pop	ax, cx, dx, bp

elseifdef GPC_SPELL
	push	ax, cx, dx, bp
	sub	sp, size AddVarDataParams
	mov	bp, sp
	movdw	ss:[bp].AVDP_data, 0
	mov	ss:[bp].AVDP_dataSize, 0
	mov	ss:[bp].AVDP_dataType, TEMP_VIS_TEXT_SHOW_SELECTION_AT_TOP
	mov	ax, MSG_META_ADD_VAR_DATA
	call	SearchSpellObjCallInstanceNoLockNear
	add	sp, size AddVarDataParams
	pop	ax, cx, dx, bp

endif

	push	ax, cx, dx
	mov	ax, MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
	call	SearchSpellObjCallInstanceNoLockNear
	pop	ax, cx, dx

	sub	sp, size VisTextRange
	mov	bp, sp
	movdw	ss:[bp].VTR_start, dxax
	add	ax, cx
	adc	dx, 0
	movdw	ss:[bp].VTR_end, dxax

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	SearchSpellObjCallInstanceNoLockNear
	add	sp, size VisTextRange

	mov	ax, MSG_META_GRAB_FOCUS_EXCL	;Give the target to this object
	call	SearchSpellObjCallInstanceNoLockNear

	mov	ax, MSG_META_GRAB_TARGET_EXCL	;Give the target to this object
	call	SearchSpellObjCallInstanceNoLockNear

ifdef GPC_SEARCH
	push	ax, bx, cx, di
	mov	cx, TEMP_VIS_TEXT_SHOW_SELECTION_AT_TOP
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	ax, bx, cx, di
elseifdef GPC_SPELL
	push	ax, bx, cx, di
	mov	cx, TEMP_VIS_TEXT_SHOW_SELECTION_AT_TOP
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	ax, bx, cx, di
endif
	.leave
	ret
SelectTextAndMakeTarget	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWordFromDocumentText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the next word from the document

CALLED BY:	GLOBAL
PASS:		DX.AX - offset into this object's text
		*DS:SI - VisText object
		SS:BP - ptr to inherited stack frames
RETURN:	        data copied into unknownWordBuf and wordSize
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWordFromDocumentText	proc	near	uses	es, di, cx, bx, dx, ax
	charsToCheck	local	dword	
	flags		local	SpellCheckFromOffsetFlags
	resetSpell	local	byte
	unknownWordBuf	local	UnknownWordInfo
	wordSize	local	word
DBCS <	searchWPT	local	word					>
DBCS <	curChar		local	wchar					>

	.enter	inherit	far
	push	si
	mov	bx, ax
	call	TS_LockTextPtrESDI
	mov_tr	cx, ax			;CX <- # chars in this block
	mov	si, bx
	lea	bx, unknownWordBuf.UWI_word
	clr	ax			;Clear AX so we don't accidentally
					; think we had an ellipsis
	mov	wordSize, ax
DBCS <	mov	searchWPT, -1						>
getChar:
;	ss:bp - ptr to stack frame
;		wordSize = # bytes copied out
;	ss:bx - ptr to where to copy word out to
;	dx.si - offset into text of text object
;	es:di - ptr to text
;	ax - last char loaded
;	cx - char count

	push	cx
	mov	cx, ax			;CX = prev char
DBCS <	mov	ax, es:[di]		;Get char from text		>
SBCS <	mov	al, es:[di]		;Get char from text		>
SBCS <	clr	ah							>
	tst	ax
	LONG jz	nullTermAndExit		;If EOT, then exit
if DBCS_PCGEOS	;-------------------------------------------------------------
	mov	curChar, ax		;save current character		>
	call	LocalGetWordPartType
	cmp	ax, WPT_ALPHA_NUMERIC
	je	saveIt
	cmp	ax, WPT_FULLWIDTH_ALPHA_NUMERIC
	jne	checkWPT		;not alpha-numeric, don't save
saveIt:
	cmp	searchWPT, -1
	jne	checkWPT
	mov	searchWPT, ax
checkWPT:
	tst	wordSize		;Don't check for word breaks at the
	jz	skipWordBreakChecks	; start of a word. (Z set, fall though
					;	'jnz  nullTermAndExit')
	cmp	ax, WPT_ALPHA_NUMERIC
	je	checkIt
	cmp	curChar, C_APOSTROPHE_QUOTE
	je	skipWordBreakChecks	; allow apos in word
	cmp	curChar, C_SINGLE_COMMA_QUOTATION_MARK
	je	skipWordBreakChecks	; allow apos in word
	cmp	ax, WPT_PUNCTUATION
	je	checkIt
	cmp	ax, WPT_FULLWIDTH_ALPHA_NUMERIC
	jne	skipWordBreakChecks	;not alpha-numeric, treat as end of
					;	word
checkIt:
	cmp	searchWPT, ax		;different WPT?
skipWordBreakChecks:
	mov	ax, curChar
	jnz	nullTermAndExit		;yes, found word delimiter
else	;---------------------------------------------------------------------
	tst	wordSize		;Don't check for word breaks at the
	jz	skipWordBreakChecks	; start of a word.
	call	CheckIsWhitespace	;If whitespace, exit too.
	jnz	nullTermAndExit
	cmp	ax, '('
	jz	nullTermAndExit		;Break at left parenthesis, so we
					; deal with words like "person(s)".
skipWordBreakChecks:
endif	;---------------------------------------------------------------------
SBCS <	mov	ss:[bx], al		;Else, store out		>
DBCS <	mov	ss:[bx], ax		;Else, store out		>
	incdw	dxsi
	inc	wordSize
	LocalNextChar	esdi		;
	LocalNextChar	ssbx		;
SBCS <	cmp	ax, C_ELLIPSIS		;Break after point of ellipsis	>
DBCS <	cmp	ax, C_HORIZONTAL_ELLIPSIS				>
	je	nullTermAndExit		
	xchg	cx, ax			;CX <- this char
					;AX <- prev char
	cmp	ax, '.'			;Break after 2 periods in a row
	jne	20$
	cmp	cx, '.'
	je	nullTermAndExit
20$:
	cmp	wordSize, SPELL_MAX_WORD_LENGTH
	je	nullTermAndExit
	mov	ax, cx			;AX = this char becomes next prev char
	pop	cx
	dec	cx
	jne	getChar

;	We've run out of chars in this block. Unlock it and get the next.

	mov	cx, si			;
	pop	si			;
	push	si			;
	call	AdjustTextPtr		;Returns CX = # chars in text,
					; ES:DI = ptr to text
					;DX.SI <- offset to text
	jmp	getChar

nullTermAndExit:
	pop	cx			;clean up stack
	pop	si			;Restore chunk handle of VisText object
SBCS <	clr	al							>
SBCS <	mov	ss:[bx], al						>
DBCS <	clr	ax							>
DBCS <	mov	ss:[bx], ax						>
	mov	ax, es
	call	TS_UnlockTextPtr
	.leave
	ret
GetWordFromDocumentText	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSpellCheckFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spell checks this text object from the current offset.

CALLED BY:	GLOBAL
PASS:		*ds:si <- VisText object
		ss:bp <- ptr to SpellCheckFromOffsetStruct
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSpellCheckFromOffset	proc	far
				; MSG_VIS_TEXT_SPELL_CHECK_FROM_OFFSET
	class	VisTextClass

	charsToCheck	local	dword	
	flags		local	SpellCheckFromOffsetFlags
	resetSpell	local	byte

;	The variables above are inherited by SkipWhitespace/SkipToWhitespace

	unknownWordBuf	local	UnknownWordInfo
	wordSize	local	word
DBCS <	searchWPT	local	word					>
DBCS <ForceRef searchWPT						>
DBCS <	curChar		local	wchar					>

;	The variables above are inherited by GetWordFromDocumentText

	oldTextOffset	local	dword
	numWordsChecked	local	word
	replyOptr	local	optr
	mov	di, bp
	.enter
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisText_offset
	mov	al, ds:[bx].VTI_intFlags
	andnf	al, mask VTIF_ACTIVE_SEARCH_SPELL
	cmp	al, ASST_SEARCH_ACTIVE shl offset VTIF_ACTIVE_SEARCH_SPELL
	jne	noSearchActive
	call	SendAbortSearchSpellNotification
noSearchActive:
	andnf	ds:[bx].VTI_intFlags, not mask VTIF_ACTIVE_SEARCH_SPELL

	segmov	es, dgroup, cx			; SH 06.01.94
	tstdw	es:[checkWordEntryPoint]	;If spell checker not loaded,
	LONG jz	endOfDocument			; exit...

	clr	numWordsChecked
	mov	bx, ss:[di].SCFOS_ICBuff
	call	ResetDoubleWordCheck

	movdw	charsToCheck, ss:[di].SCFOS_numChars, ax
	movdw	replyOptr, ss:[di].SCFOS_replyOptr, ax

	movdw	oldTextOffset, -1

	mov	al, ss:[di].SCFOS_flags
	mov	flags, al

					;Clear the flag denoting a spell check
					; in progress.

	movdw	dxax, ss:[di].SCFOS_offset
	push	ax
	call	TS_LockTextPtrESDI
	mov_tr	cx, ax			;CX <- # chars after ptr
	pop	ax

checkWord:
;
;	ES:DI <- ptr to text to spell check
;	CX <- # chars after ptr (includes null)
;	DX.AX <- current offset into the text
;

;	START SPELL CHECKING THE DOCUMENT

	call	SkipWhitespace
	cmp	di, -1		;If we've reached the end of the
	je	nextObject	; document, branch.
	tst	resetSpell
	jz	noReset

	call	ResetDoubleWordCheck
noReset:

;	GET THE NEXT WORD FROM THE DOCUMENT

	call	GetWordFromDocumentText	;Returns wordSize as # chars copied out

	tst	wordSize
	jz	nextObject		;If at the end of the document, branch

	cmp	wordSize, SPELL_MAX_WORD_LENGTH ;If word has > 64 chars,
	jae	gotoNext			 ; skip it.

;	SPELL CHECK THE WORD


	push	ax, cx, dx

	push	ds, si
	segmov	ds, ss
	lea	si, unknownWordBuf.UWI_word
	inc	numWordsChecked
	call	CheckWord
	pop	ds, si

	mov_tr	dx, ax
	call	GetErrorFlags

;	IF DOUBLE WORD OR A/AN ERROR, HANDLE IT

	test	ax, mask SEFH_AN_ERROR or mask SEFH_A_ERROR
	jne	gotoErrorWithPrevWord
	test	cx, mask SEF_DOUBLE_WORD_ERROR
	je	noPrevWordError
gotoErrorWithPrevWord:
	jmp	errorWithPrevWord
noPrevWordError:
 	cmp	dx, IC_RET_FOUND
	je	popGotoNext
	cmp	dx, IC_RET_PRE_PROC
	je	popGotoNext
	cmp	dx, IC_RET_IGNORED
	LONG jne misspelledWord
popGotoNext:
	pop	ax, cx, dx
gotoNext:

;	SKIP THE CURRENT WORD AND GO TO THE NEXT ONE

;
;	Save offset to current word, in case we have some sort of double word
;	error (misuse of a/an, etc)
;

	movdw	oldTextOffset, dxax

	call	SkipToWhitespace
	cmp	di, -1
	je      nextObject
        tst     resetSpell
;
;	If during skipping to the next white space we
;	encountered a '.' then we should reset the double word check.
;	This takes care of the case "hello(). hello"
;
	jz      checkWord
	call    ResetDoubleWordCheck
	jmp     checkWord               ;If still in same object, continue
					; checking, else we are at the end of
					; this document.

nextObject:

;	Get the next text object. We want to unlock this one, so send a method
;	to the next object via the queue, so this one gets unlocked. We could
;	do this faster by doing ObjSwapLocks and such things, but I don't
;	like that, and we only send the method when going between objects,
;	which isn't that much overhead...

	mov	ax, es
	call	TS_UnlockTextPtr

;	Check to see if we've reached the end of a selection we were checking.
;	If so, don't go to the next object.

	test	flags, mask SCFOF_CHECK_NUM_CHARS
	jne	endOfDocument

;	GET THE NEXT OBJECT TO SPELL CHECK


	mov	ax, GSSOT_NEXT_OBJECT
	call	GetSearchSpellObject
	jcxz	endOfDocument

;	START SPELL CHECKING FROM THE BEGINNING OF THE NEXT OBJECT

	push	bp, si
	movdw	axdi, replyOptr
	sub	sp, size SpellCheckFromOffsetStruct
	mov	bp, sp
	mov	ss:[bp].SCFOS_ICBuff, bx
	movdw	ss:[bp].SCFOS_replyOptr, axdi
	clr	ax
	clrdw	ss:[bp].SCFOS_offset, ax
	mov	ss:[bp].SCFOS_flags, al
	
	mov	ax, MSG_VIS_TEXT_SPELL_CHECK_FROM_OFFSET
	movdw	bxsi, cxdx		;^lBX:SI <- next object
	mov	dx, size SpellCheckFromOffsetStruct
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or mask MF_STACK
	call	SearchSpellObjMessageNear
	add	sp, dx
	pop	bp, si
	jmp	exit

endOfDocument:

;	WE HAVE REACHED THE END OF THE AREA WE WANT TO SPELL CHECK

	mov	cx, SCR_DOCUMENT_CHECKED
	test	flags, mask SCFOF_CHECK_NUM_CHARS
	je	doReply
	mov	cx, SCR_SELECTION_CHECKED
	cmp	numWordsChecked, 1
	jne	doReply
	mov	cx, SCR_ONE_WORD_CHECKED
doReply:
	mov	ax, MSG_SC_SPELL_CHECK_COMPLETED
	push	bp
	movdw	bxsi, replyOptr
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
exit:
	.leave
	ret

prevWordTooBig:
	call	ResetDoubleWordCheck	;Reset the spell check so we don't
					; get bogus double-word errors.
	popdw	dxax
	jmp	gotoNext

errorWithPrevWord:

;	We have encountered one of the "previous word" errors:
;	A repeated word (e.g. "the the") or a screwed up usage of
;	A/An, as in "a hour" or "an fool". We select both words, and
;	copy the text into our stack frame. 


	pop	ax, cx, dx		;DX.AX <- offset to word

	pushdw	dxax
	add	ax, wordSize		;DX.AX <- offset to end of word
	subdw	dxax, oldTextOffset
EC <	ERROR_C	-1						>

	;If words have > 64 chars between them, branch to not display an error

	tst	dx
	jne	prevWordTooBig		
	cmp	ax, SPELL_MAX_WORD_LENGTH
	jae	prevWordTooBig
	mov_tr	cx, ax			;CX <- # chars in both words

	mov	ax, es
	call	TS_UnlockTextPtr	;Unlock the text, as we won't use it
					; anymore

;	SELECT THE 2 WORDS

	movdw	dxax, oldTextOffset
	call	SelectTextAndMakeTarget

;	READ THE TEXT INTO THE STACK FRAME

	movdw	dxax, oldTextOffset
	lea	di, unknownWordBuf.UWI_word	;SS:DI <- dest for string

	push	bp
	sub	sp, size VisTextGetTextRangeParameters
	mov	bp, sp
	movdw	ss:[bp].VTGTRP_range.VTR_start, dxax
	add	ax, cx
	adc	dx, 0
	movdw	ss:[bp].VTGTRP_range.VTR_end, dxax
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_POINTER
	movdw	ss:[bp].VTGTRP_pointerReference,ssdi
	clr	ss:[bp].VTGTRP_flags

	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	call	SearchSpellObjCallInstanceNoLockNear
	add	sp, size VisTextGetTextRangeParameters
	pop	bp

;	CHANGE ANY UNDESIRABLE CHARACTERS TO SPACES

	push	ds, si
	lea	si, unknownWordBuf.UWI_word
	segmov	ds, ss				;DS:SI <- ptr to word
next:
	lodsb
	tst	al
	jz	EOS
EC <	cmp	al, C_CR						>
EC <	ERROR_Z	MISSPELLED_WORDS_CONTAINED_INVALID_CHAR			>
EC <	cmp	al, C_PAGE_BREAK					>
EC <	ERROR_Z	MISSPELLED_WORDS_CONTAINED_INVALID_CHAR			>
EC <	cmp	al, C_SECTION_BREAK					>
EC <	ERROR_Z	MISSPELLED_WORDS_CONTAINED_INVALID_CHAR			>
   	cmp	al, C_GRAPHIC		;Convert graphics chars
	jne	next
	mov	{byte} ds:[si][-1], ' '
	jmp	next
EOS:
	pop	ds, si
	popdw	dxcx				;
	subdw	dxcx, oldTextOffset		;DX.CX <- # chars in prev word
	adddw	dxcx, charsToCheck		;DX.CX <- # chars to check
	clr	ax				; from start of prev word
						;AX <- offset to start of text
						; to display in spell box
	jmp	misspelledWordCommon

misspelledWord:

;	SELECT THE WORD AND GIVE THE OBJECT THE TARGET.

	mov	ax, es
	call	TS_UnlockTextPtr	;

	pop	di, cx, dx		;DX.DI <- offset to string
	call	GetTextOffsets
					;CX <- offset to right edge of string
					;AX <- offset to left edge of string
	sub	cx, ax
	inc	cx			;CX <- # chars in string
	add	ax, di			;DX.AX <- offset into text to start
					; selecting
	call	SelectTextAndMakeTarget

;	SETUP UnknownWordInfo<> AND SEND IT TO THE SPELL BOX

	call	GetTextOffsets
	mov	di, cx			;DI <- offset to last char in string
if DBCS_PCGEOS
	shl	di, 1			; char offset -> byte offset
	mov	{wchar} unknownWordBuf.UWI_word[di][(size wchar)],0
else
	mov	unknownWordBuf.UWI_word[di][1],0 ;Null terminate the string
endif

	movdw	dxcx, charsToCheck

misspelledWordCommon:

;	DX.CX <- # chars left to check
;	AX <- offset from start of UWI_word to display word
;	SS:BP <- stack frame

					;Set the flag denoting a spell check
					; in progress.
	movdw	unknownWordBuf.UWI_numChars, dxcx
if DBCS_PCGEOS
	shl	ax, 1			;char offset -> byte offset
endif
	add	ax, offset UWI_word	;AX <- offset to string from start of
					; unknownWordBuf.
	mov	unknownWordBuf.UWI_offset, ax

	push	bp
	mov	ax, MSG_VIS_TEXT_SET_SPELL_IN_PROGRESS
	call	SearchSpellObjCallInstanceNoLockNear
	pop	bp

	push	bp, si
	movdw	bxsi, replyOptr
	lea	bp, unknownWordBuf
	mov	dx, size UnknownWordInfo
	mov	ax, MSG_SC_UNKNOWN_WORD_FOUND
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	SearchSpellObjMessageNear
	pop	bp, si
	jmp	exit
VisTextSpellCheckFromOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceSelectedWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Currently just calls MSG_VIS_TEXT_REPLACE_SELECTION 
		and sends output message when done.

CALLED BY:	MSG_VIS_TEXT_REPLACE_SELECTED_WORDS
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ss:bp   = ReplaceSelectedWordParameters

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceSelectedWords   proc far	; MSG_THES_REPLACE_SELECTED_WORDS
	class	VisTextClass

	uses	ax, cx, dx, bp
	.enter

	push	bp

	;
	; if the the word has not been selected, select the word on the
	; cursor, so that the the MSG_VIS_TEXT_REPLACE_SELECTION has a
	; selection to replace and does not just become an insert
	;
	; CP 1/94
	;
	mov	cx, VTKF_SELECT_WORD
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	call	SearchSpellObjCallInstanceNoLockNear

	pop	bp

	mov	bx, ss:[bp].RSWP_string			; bx = string blockh
	call	MemLock					; ax = string segment

	push	bp, bx
	mov	dx, ax					; dx:bp -> string 
	clr	bp
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION
	clr	cx 
	call	SearchSpellObjCallInstanceNoLockNear
	pop	bp, bx

	call	MemFree

	;
	; Now we need to send a message out to the output telling it we're done
	;
	push	bp				; Save frame ptr again
	movdw	bxsi, ss:[bp].RSWP_output	; bx.si <- output
	mov	ax, ss:[bp].RSWP_message	; ax <- message to send
						; cx == block handle
						; dx == size of text
	clr	di				; No flags
	call	ObjMessage			; Send the notification
	pop	bp

	.leave
	ret
VisTextReplaceSelectedWords	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSelectWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If no current selection, selects the word nearest the cursor,
		Else does nothing. 

CALLED BY:	MSG_THES_SELECT_WORD
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ss:bp 	= SelectWordParameters

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSelectWord	proc	far	 ;MSG_THES_SELECT_WORD
	uses	ax, cx, dx, bp
	localRange	local	VisTextRange
	objectOffset	local	word
	.enter

	mov	di, ss:[bp]
	mov	objectOffset, si

	; get the selection range

	push 	bp
	mov	dx, ss			; dx:bp -> VisTextRange to fill
	lea	bp, localRange
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	call	SearchSpellObjCallInstanceNoLockNear
	pop 	bp

	; If there is a selection (start and end are different) then exit

	movdw	dxax, localRange.VTR_start
	movdw	cxbx, localRange.VTR_end
	cmpdw	dxax, cxbx
	jne	exit

	; if SWP_type = nonzero then select numChars from cursor position

	tst	ss:[di].SWP_type
	jz	leftEdge
	clr	cx
	mov	bx, ss:[di].SWP_numChars
	subdw	dxax, cxbx
	movdw	localRange.VTR_start, dxax
	jmp	doSelect

leftEdge:

	; Else select the (numChars) characters past the left end of the
	; word that the cursor's currently in the middle of... 

	mov	si, objectOffset	; ds:si -> object
	call	SelectByModeWordFar	; dx.ax = start of word to select
	movdw	localRange.VTR_start, dxax
	clr	cx			
	mov	bx, ss:[di].SWP_numChars; cx.bx = num chars to select
	adddw	dxax, cxbx		; dx.ax = end of range to select
	movdw	localRange.VTR_end, dxax

doSelect:

	push	bp, di
	lea 	bp, localRange			; ss:bp -> localRange
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	mov	dx, size VisTextRange
	call	SearchSpellObjCallInstanceNoLockNear
	pop	bp, di

exit:
	;
	; Now we need to send a message out to the output telling it we're done
	;
	push	bp				; Save frame ptr again
	movdw	bxsi, ss:[di].SWP_output	; bx.si <- output
	mov	ax, ss:[di].SWP_message	; ax <- message to send
						; cx == block handle
						; dx == size of text
	clr	di				; No flags
	call	ObjMessage			; Send the notification
	pop	bp

	.leave
	ret
VisTextSelectWord	endp

TextSearchSpell	ends

TextControlInit segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSetSpellLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the handle of the spell library to make calls to.

CALLED BY:	GLOBAL
PASS:		bx - handle of spell library
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSetSpellLibrary	proc	far	uses	ax, cx, ds
	.enter
	mov	ax, segment udata
	mov	ds, ax
	tst	bx
	jz	exiting

;	Get various entry points for the calls we will make

	mov	ax, SROUT_CHECK_WORD
	call	GetLibraryEntry
	movdw	ds:[checkWordEntryPoint], cxax

	mov	ax, SROUT_RESET_SPELL_CHECK
	call	GetLibraryEntry
	movdw	ds:[resetDoubleWordCheckEntryPoint], cxax

	mov	ax, SROUT_GET_TEXT_OFFSETS
	call	GetLibraryEntry
	movdw	ds:[getTextOffsetsEntryPoint], cxax

	mov	ax, SROUT_GET_ERROR_FLAGS
	call	GetLibraryEntry
	movdw	ds:[getErrorFlagsEntryPoint], cxax
exit:
	.leave
	ret
exiting:

	clrdw	ds:[checkWordEntryPoint], bx
	clrdw	ds:[resetDoubleWordCheckEntryPoint], bx
	clrdw	ds:[getTextOffsetsEntryPoint], bx
	clrdw	ds:[getErrorFlagsEntryPoint], bx
	jmp	exit
TextSetSpellLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the library entry point

CALLED BY:	GLOBAL
PASS:		ax - library entry to get
RETURN:		cx.ax - library entry
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLibraryEntry	proc	near
	.enter
	mov	cx, bx
	call	ProcGetLibraryEntry
	xchg	cx, bx
	.leave
	ret
GetLibraryEntry	endp

TextControlInit ends
