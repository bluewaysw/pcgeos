COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsTextObject.asm

AUTHOR:		Gene Anderson, Jan 26, 1990

ROUTINES:
	Name			Description
	----			-----------
EXT	GrTextObjCalc		Calculate information for text object
EXT	GrTextPosition		Information to help with text selection

INT	InitForTextMetrics	Initialize stuff for above routines
INT	CallStyleCallBack	Callback routine to find # of chars in style
INT	AddWidth		Add character width, accounting for style
INT	GraphicInlineWidth	Find width of inline graphic
INT	UpdateFieldHeightVars	Update field height variables
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/26/90		Broke out from graphicsTextMetrics.asm
	Gene	1/27/90		Consolidated duplicate routines

DESCRIPTION:
	Contains text metrics routines used only for the text object.
		
	$Id: graphicsTextObject.asm,v 1.1 97/04/05 01:13:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTextObjCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate information for a text object.

CALLED BY:	Global
PASS:		di	= graphics state to use
		ss:bp	= pointer to TOC_vars structure, with the TOC_ext
			  structure filled in.
RETURN:		ss:bp	= pointer to TOC_vars structure with the TOC_ext
			  structure filled in.
		ds	= Segment address of the last bit of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

internals	equ	ss:[bp].TOCV_int
externals	equ	ss:[bp].TOCV_ext

		public	GrTextObjCalc
GrTextObjCalc	proc	far
	uses	ax, bx, cx, dx, di, si, es
	.enter

	;
	; This is a fine place to do error checking on the parameters.
	;
EC <	call	ECCheckGStateHandle					>

	mov	cx, size TOC_int		;cx <- # of bytes to clear
	call	InitForTextMetrics		;like it says...
	
	clr	cx
	mov	externals.TOCE_nSpaces, cx
	mov	externals.TOCE_nExtraSpaces, cx
	mov	ss:[bp].TMS_flags, cx
        mov     internals.TOCI_lastMetricFlags, cx

	;
	; Beginning of field is also start of last word.
	;
	mov	internals.TOCI_lastWordStart, cx
	
	;
	; Initialize the position of a tall character to some value which will
	; ensure that we don't assume the presence of a tall character.
	;
	dec	cx				; cx <- -1
	mov	internals.TOCI_tallCharBaselinePos, cx
	mov	internals.TOCI_tallCharHeightPos, cx
	inc	cx				; cx <- 0
	
	mov	di, cx				;di <- start of field (0)

	;
	; Since cx == 0 here we will immediately call the style callback when
	; we enter the loop.
	;

	;
	; ah (the kern-char) is always zeroed when we make the style callback.
	; This means we don't need to initialize it before entering the loop
	; since we will be making the style callback first thing.
	;
SBCS <	clr	bl				; bl <- previous character.>
DBCS <	clr	bx				; bx <- previous character >
charLoop:
	;
	; Check for being out of characters in the current style.
	; If we are, then we call the style callback routine.
	; di	= Offset from start of field
	; cx	= Number of characters in the current style which are left
	; ah	= Kern-char (previous character of same style)
	; bl	= Previous character
	;
	tst	cx				; Branch if there are more chars
	jnz	validChars			;    in the current style

	;
	; No more characters in this style, need to get the new char attributes.
	;
	call	CallStyleCallBack		; ds:si <- ptr to text
						; cx <- # of characters
	;
	; Set the new height and baseline based on the new char attributes
	;
	call	SetHeightAndBaseline
	ornf	ss:[bp].TMS_flags, mask TMSF_STYLE_CHANGED

	;
	; OK. Some special case code here.
	;
	; Basically we always set the field height if we are at the start of
	; the line.
	;
	; Otherwise the field height is updated at the bottom of the loop when
	; we find that at least one character has fit.
	;
SBCS <	mov	ah, ds:[si]			; ah <- 1st character on line.>
DBCS <	mov	ax, ds:[si]			; ax <- 1st character on line >

	tst	di				; Check for first char in field
	jne	skipHeightUpdate		; Skip update if not first.
	call	UpdateFieldHeightVars
skipHeightUpdate:

	;
	; Hah... More special case code here!!!!
	; If the first character in a field is a TAB we want to set the
	; FF_STARTS_WITH_TAB bit in the field flags, and we want to skip over
	; the tab character.
	;
SBCS <	cmp	ah, C_TAB						>
DBCS <	cmp	ax, C_TAB						>
	jne	firstNotTab
	tst	di
	jne	firstNotTab

	;
	; Char was a TAB. Was 1st char on line.
	; Call a callback routine to set the "areaToFill".
	;
NOFXIP<	call	externals.TOCE_tabCallback				>
FXIP<	mov	ss:[TPD_dataBX], bx					>
FXIP<	mov	ss:[TPD_dataAX], ax					>
FXIP<	movdw	bxax, externals.TOCE_tabCallback			>
FXIP<	call	ProcCallFixedOrMovable					>
	call	FixupGStateNukeNothing
	jnc	hasSpace

	;
	; Only character in the field is the TAB and even it doesn't belong
	; here. When this happens we need to load al with something meaningful
	; so that FindLineBreak() will make the break at the proper place.
	;
SBCS <	mov	al, ah				; al <- C_TAB		>
	ornf	externals.TOCE_flags, mask TOCF_ONE_TAB_TOO_LARGE
	jmp	endLoop				; Quit if no room for text.

hasSpace:
	call	CopyFieldHeightVars		; Set height appropriately
	dec	cx				; One less char in this style.
	LocalGetChar ax, dssi			; Skip to next char.
	jmp	nextChar			; Move to next character.

firstNotTab:
SBCS <	clr	ah				; Can't kern around style chang>
DBCS <	clr	ss:[bp].TMS_kernChar		; Can't kern around style chang>
	
validChars:
	;
	; cx should be non-zero here. If it is zero then we have reached the
	; end of our text.
	;
	andnf	ss:[bp].TMS_flags, not mask TMSF_IS_BREAK_CHARACTER

	LocalGetChar ax, dssi			; ax <- current character
	
	;
	; The following cannot be condensed into a 'jcxz' instruction because
	; we are doing a branch-to-branch. Since jcxz does not set the flags
	; the second branch of this pair will fail.
	;
	tst	cx
	jz	gotoEndLoop			; Quit if no characters left

	dec	cx				; One less character to do
	
	;
	; Quick check for character >= space. This works because all the
	; tests below are against values that are <0x20.
	;
if not DBCS_PCGEOS
	LocalCmpChar ax, C_SPACE
	jae	doAddWidth
endif

	;
	; Check for soft-hyphen character. If we found one, then there is
	; some special checking we need to do.
	;
SBCS <	cmp	al, C_OPTHYPHEN			; see if soft hyphen	>
DBCS <	cmp	ax, C_SOFT_HYPHEN		; see if soft hyphen	>
	jne	notSoftHyphen
	call	CheckSoftHyphen			; check for soft hyphen
	LONG jnc nextChar			; branch if hyphen fits

notSoftHyphen:
	;
	; See code above regarding check for values < 0x20
	; The check is moved for DBCS because C_SOFT_HYPHEN is > 0x20
	;
if DBCS_PCGEOS
	LocalCmpChar ax, C_SPACE
	jae	doAddWidth
endif
	;
	; Check for terminating condition based on the current character.
	; We terminate when we reach a TAB, CR, NULL, COLUMN/SECTION_BREAK.
	;
	LocalIsNull ax
	jz	gotoEndLoop			; Branch to branch.
	LocalCmpChar ax, C_CR
	je	gotoEndLoop			; Don't change: (see above).
	LocalCmpChar ax, C_TAB
	je	gotoEndLoop
	LocalCmpChar ax, C_SECTION_BREAK
	je	gotoEndLoop
	LocalCmpChar ax, C_COLUMN_BREAK
	jne	doAddWidth
gotoEndLoop:
	jmp	endLoop

doAddWidth:
	;
	; The character is one we want to add to the field.
	; This is somewhat complex... The information that we need is in the
	; font, but we need to account for the style too. Kerning also needs
	; to be accounted for here. When testing for kerning, we need to know
	; if we are on the first character of a new style-run, since kerning
	; acros style-runs is probably not a good idea.
	;
	call	AddWidth

if (0)	; Removed: we can't always determine LF_INTERACTS_{ABOVE/BELOW}
	; by checking the tall character. - Joon (12/5/94)
	;
	; If the character extended above or below the line we want to record
	; the position of the character so that we can decide later if the line
	; contains any of these characters, in which case we adjust the height
	; of the line.
	;
	test	ss:[bp].TMS_flags, (mask TMSF_EXTENDS_ABOVE or \
				    mask TMSF_EXTENDS_BELOW)
	jz	insideLineBounds
	call	SaveTallCharPos

insideLineBounds:
else
	; Instead, we check the TMS_flags (TMSF_EXTENDS_{ABOVE/BELOW})
	; and set the TOCE_linFlags as appropriate. - Joon (95.9.26)

	test	ss:[bp].TMS_flags, mask TMSF_EXTENDS_ABOVE
	jz	notAbove
	ornf	externals.TOCE_lineFlags, mask LF_INTERACTS_ABOVE
notAbove:
	test	ss:[bp].TMS_flags, mask TMSF_EXTENDS_BELOW
	jz	notBelow
	ornf	externals.TOCE_lineFlags, mask LF_INTERACTS_BELOW
notBelow:
endif
	;
	; Check for non-space character. If we have found a non-space char
	; and the previous character was a space or a tab, then we want 
	; to save this character position as the last word start.
	;
if not PZ_PCGEOS
	LocalCmpChar ax, C_SPACE		; Check for reached non-space
	je	checkWordEnd

        ; Skip if the previous Metric flags were no wrap
        test    internals.TOCI_lastMetricFlags, mask TMSF_NOWRAP
        jne     endSpaceCheck

	;
	; Check previous character for being a space or a tab.
	;	
	LocalCmpChar	bx, C_SPACE
	je	wordStart
	LocalCmpChar	bx, C_TAB
	jne	endSpaceCheck
else
	call	CheckWordStart
	jnc	checkWordEnd			;branch if not word start
endif

wordStart::
	;
	; Found a word-start (space followed by non-space). Save position of
	; the end of the previous word.
	;
	mov	internals.TOCI_lastWordStart, di
	
	push	ax
PZ <	push	bx							>
	call	GetPosBeforeLastChar		; bx.al <- pos
	movwbf	internals.TOCI_lastWordPos, bxal
PZ <	pop	bx							>
	pop	ax
NPZ <	jmp	endSpaceCheck						>
		
checkWordEnd:
PZ <	LocalCmpChar ax, C_SPACE					>
PZ <	jne	checkWordEndNotSpace					>
	;
	; One more space...
	;
	inc	externals.TOCE_nExtraSpaces

PZ <checkWordEndNotSpace:						>
	ornf	ss:[bp].TMS_flags, mask TMSF_IS_BREAK_CHARACTER

	;
	; Check for previous character being a non-space character.
	; If it is a space character, we need to save the current width as
	; the last word-break position.
	;
if not PZ_PCGEOS
	LocalCmpChar bx, C_SPACE
	je	endSpaceCheck
else
	call	CheckWordEnd
	jnc	endSpaceCheck			;branch if not word end
endif
        test    ss:[bp].TMS_flags, mask TMSF_NOWRAP
        jnz     endSpaceCheck

	;
	; Found a word-end, previous char was not a space, current char is
	; a space.
	; This means that the entire word fits on the line. We want to add all
	; the uncounted spaces into the nSpaces field here.
	;
	; Also, any hyphen character that we might have found in the last word
	; won't be used as a word break. We zero the 'lastHyphen' field so
	; that we won't try to use it in FindLineBreak().
	;
	; Add in the uncounted spaces
	;
	mov	internals.TOCI_lastHyphen, 0

	mov	dx, externals.TOCE_nExtraSpaces
	dec	dx				; Don't count one just read
						;  which fall before this word
	add	externals.TOCE_nSpaces, dx
	;
	; 1 extra for the space we just read.
	;
PZ <	LocalCmpChar ax, C_SPACE					>
PZ <	jne	notSpace						>
	mov	externals.TOCE_nExtraSpaces, 1
PZ <notSpace:								>

	push	ax
	call	GetPosBeforeLastChar		; bx.al = position.
	rndwbf	bxal, internals.TOCI_lastWordEndPos
	pop	ax
	;
	; found word end, wrapping no longer pending, wrap at end of word
	;
	test	externals.TOCE_otherFlags, mask TOCOF_WAIT_FOR_WORD
	jz	endSpaceCheck
	andnf	externals.TOCE_otherFlags, not mask TOCOF_WAIT_FOR_WORD
	ornf	externals.TOCE_otherFlags, mask TOCOF_FOUND_WORD

endSpaceCheck:
	;
	; If we are not word-wrapping, then we check for an overflow.
	; If we are word-wrapping, then we only check for overflow on non
	; space characters, since spaces at the end of word-wrapped lines
	; don't force a text wrap.
	;
	test	externals.TOCE_flags, mask TOCF_NO_WORD_WRAP
	jnz	checkOverflow

	;
	; If the character is a space, then we don't bother to check to see if
	; the allowable size has been exceeded, because trailing spaces really
	; occupy no space if they extend beyond the word-wrap limits.
	;
	LocalCmpChar ax, C_SPACE
	je	afterOverflowCheck

checkOverflow:
	;
	; Check for this character overflowing the allowable size.
	;
	mov	dx, ss:[bp].TMS_sizeSoFar.WBF_int
	cmp	dx, externals.TOCE_areaToFill
	;
	; if wrapping after overflow, check if wrapping is pending
	; if so, continue to find word end, else wrapping is now pending
	;
	jb	afterOverflowCheck
	test	externals.TOCE_otherFlags, mask TOCOF_WRAP_AFTER_OVERFLOW
	jz	notWrappingAfterOverflow	; not wrapping after overflow

        ; If we declare no wrap, we have no maximum
        test    ss:[bp].TMS_flags, mask TMSF_NOWRAP
        jnz     noMaximum

	LocalCmpChar	ax, C_GRAPHIC	; always allow wrapping graphics
	je	notWrappingAfterOverflow

	tst	externals.TOCE_wrapAfterOverflowWidth
	jz	noMaximum
	cmp	dx, externals.TOCE_wrapAfterOverflowWidth
	LONG jae	endLoop			; reached maximum, wrap now
noMaximum:
	tst	internals.TOCI_lastWordPos.WBF_int	; only for words
	LONG jnz	endLoop				; starting at left
	tst	internals.TOCI_lastWordPos.WBF_frac	; edge
	LONG jnz	endLoop
	test	externals.TOCE_otherFlags, mask TOCOF_WAIT_FOR_WORD
	jnz	afterOverflowCheck	; pending, continue until word end
	test	externals.TOCE_otherFlags, mask TOCOF_FOUND_WORD
	pushf
	andnf	externals.TOCE_otherFlags, not mask TOCOF_FOUND_WORD
	popf
	jnz	endLoop
					; else, set pending and continue
	ornf	externals.TOCE_otherFlags, mask TOCOF_WAIT_FOR_WORD
	jmp	afterOverflowCheck

notWrappingAfterOverflow:
	;
	; Check for the case of a single character causing an overflow in the
	; first field of the line.
	;
	test	externals.TOCE_otherFlags, mask TOCOF_FIRST_CHAR_OVERFLOW
	LONG jnz	endLoop		; overflow already happened
	tst	di
	LONG jnz	endLoop
	;
	; Make sure that this is the only field on the line.
	;
	test	externals.TOCE_otherFlags, mask TOCOF_IS_FIRST_FIELD
	LONG jz endLoop
 	;
	; This is a special case (yea!) that should continue scanning of the
	; the line and include any following spaces or a field terminator.
	; The next time the above test for this flag is made will be when a
	; non-whitespace character is found.  Execution will then branch
	; immediately to endLoop and break the line.
	;
	ornf	externals.TOCE_otherFlags, mask TOCOF_FIRST_CHAR_OVERFLOW

afterOverflowCheck:
	;
	; Check for having found the anchor character. If we have, branch off
	; to save information about it.
	;
SBCS <	cmp	al, externals.TOCE_anchorChar.low	;DBCS:		>
DBCS <	cmp	ax, externals.TOCE_anchorChar		;DBCS:		>
	jne	notAnchor

	test	externals.TOCE_flags, mask TOCF_FOUND_ANCHOR
	jnz	notAnchor			;branch if already found

	;
	; No anchor character found yet....
	; Mark that we have found one, and save the width to this point.
	;
	ornf	externals.TOCE_flags, mask TOCF_FOUND_ANCHOR
	mov	bx, ss:[bp].TMS_sizeSoFar.WBF_int
	mov	externals.TOCE_widthToAnchor, bx

notAnchor:
	;
	; Check for hard-hyphen, we can hypenate on a hard-hyphen.
	;
SBCS <	cmp	al, C_ENDASH						>
DBCS <	cmp	ax, C_EN_DASH						>
	je	isHardHyphen
SBCS <	cmp	al, C_EMDASH						>
DBCS <	cmp	ax, C_EM_DASH						>
	je	isHardHyphen
SBCS <	cmp	al, C_HYPHEN						>
DBCS <	cmp	ax, C_HYPHEN_MINUS					>
	jne	notHardHyphen

isHardHyphen:
	mov	bx, di
	inc	bx
	mov	internals.TOCI_lastHyphen, bx

	;
	; Need to save the position of the end of the hyphen.
	;
	movwbf	internals.TOCI_lastHyphenPos, ss:[bp].TMS_sizeSoFar, bx
	
	andnf	ss:[bp].TMS_flags, not mask TMSF_IS_OPTIONAL_HYPHEN
	ornf	ss:[bp].TMS_flags, mask TMSF_IS_BREAK_CHARACTER

notHardHyphen:
	;
	; Set up stuff so that we can loop around and continue.
	; New previous character. New kerning character.
	;

nextChar:
	;
	; The previous character fit!!! Update the field height variables.
	;
	test	ss:[bp].TMS_flags, mask TMSF_STYLE_CHANGED
	jz	skipHeightUpdate2
	call	UpdateFieldHeightVars

skipHeightUpdate2:
	;
	; Check for a break character.
	;
	test	ss:[bp].TMS_flags, mask TMSF_IS_BREAK_CHARACTER
	jz	notBreakChar
	call	CopyFieldHeightVars		;Update line height.

notBreakChar:
	;
	; Set the 'previous char kerned' flag if appropriate.
	;
	andnf	externals.TOCE_otherFlags, not mask TOCOF_PREV_CHAR_KERNED
	test	ss:[bp].TMS_flags, mask TMSF_NEGATIVE_KERNING
	jz	skipPrevCharKernSet
	ornf	externals.TOCE_otherFlags, mask TOCOF_PREV_CHAR_KERNED
skipPrevCharKernSet:
SBCS <	mov	bl, al				;new previous character	>
DBCS <	mov	bx, ax				;new previous character	>
SBCS <	mov	ah, al				;new kerning character	>
DBCS <	mov	ss:[bp].TMS_kernChar, ax	;new kerning character	>

        ; Record the previous TMSFlags (mainly to track VTES_NOWRAP)
        push    ax
        mov     ax, ss:[bp].TMS_flags
        mov     internals.TOCI_lastMetricFlags, ax
        pop     ax

	inc	di				;one more character
	jmp	charLoop

endLoop:
	;
	; Now is the time to set up the return values.
	;	al = last byte read.
	;
	call	FindLineBreak

	;
	; Set the anchorWidth field.
	;
	test	externals.TOCE_flags, mask TOCF_FOUND_ANCHOR
	jnz	noAnchorWidth			; quit if we have an anchor

	;
	; If no anchor found, set width to 0.
	;
	mov	bx, externals.TOCE_justWidth
	mov	externals.TOCE_widthToAnchor, bx

noAnchorWidth:
	;
	; Unlock the font and the gstate.
	;
	call	UnlockFontAndGState
	.leave
	ret
GrTextObjCalc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPosBeforeLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position before the last character added.

CALLED BY:	GrTextObjCalc()
PASS:		ss:bp	= pointer to TMS_locals.
RETURN:		bx.al	= sizeSoFar - lastCharWidth.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPosBeforeLastChar	proc	near
	call	GetSizeSoFar
	subwbf	bxal, ss:[bp].TMS_lastCharWidth
	ret
GetPosBeforeLastChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSizeSoFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the TMS_sizeSoFar

CALLED BY:	GetPosBeforeLastChar(), FindLineBreak(), CheckSoftHyphen()
PASS:		ss:bp	= ponter to TMS_locals
RETURN:		bx.al	= TMS_sizeSoFar
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSizeSoFar	proc	near
	movwbf	bxal, ss:[bp].TMS_sizeSoFar
	ret
GetSizeSoFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLineBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the width of the field.

CALLED BY:	GrTextObjCalc
PASS:		ss:bp	= TOC_vars
		di	= offset to position where overflow occurred
	SBCS:
		al	= last character read
	DBCS:
		ax	= last character read
RETURN:		TOCE_fieldWidth, TOCE_nChars set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    There are several cases to consider:
	(1) The field was terminated by a NULL.
		- Break at end of text.
		- Width is sizeSoFar.
		- Justification width is sizeSoFar.
		- LineFlags |= {ENDS_PARAGRAPH ENDS_IN_NULL}
		- Update height information.
		- Can't optimize if current char was kerned.

	(2) The field was terminated by a COLUMN_BREAK.
		- Break after COLUMN_BREAK.
		- Width is sizeSoFar.
		- Justification width is sizeSoFar.
		- LineFlags |= {ENDS_PARAGRAPH ENDS_IN_COLUMN_BREAK}
		- Update height information.
		- Can't optimize if current char was kerned.

		<The same concept holds true for a section break>

	(3) The field was terminated by a CR.
		- Break after CR.
		- Width is sizeSoFar + JustAddCharWidth( C_PARAGRAPH );
		- Justification width is sizeSoFar.
		- LineFlags |= {ENDS_PARAGRAPH ENDS_IN_CR}
		- Update height information.
		- Can't optimize if current char was kerned.

	(4) The field was terminated by a TAB.
		- Break before TAB.
		- Width is sizeSoFar.
		- Justification width is sizeSoFar.
		- LineFlags |= {}
		- Update height information.

	(5) The field was terminated by a word-break.
	    (a) Word-wrap is desired, but isn't possible as there is only 1 word
		on the line.
		- Break before character which overflowed.
		- Width is sizeSoFar - lastCharWidth.
		- Justification width is sizeSoFar - lastCharWidth.
		- LineFlags |= {}
		- Can't optimize if previous char was kerned.

	    (b) Word-wrap is not desired.
		- Break before character which overflowed.
		- Width is sizeSoFar - lastCharWidth.
		- Justification width is sizeSoFar - lastCharWidth.
		- LineFlags |= {}
		- Can't optimize if previous char was kerned.
	    
	    (c) Word-wrap is desired and is possible.
		- Break before start of last word.
		- Width is lastWordPos.
		- Justification width is lastWordEndPos.
		- LineFlags |= {}
		- Can't optimize if last break was kerned.
	    
	    (d) A hyphen character exists and word-break should occur there.
		- Break after hyphen character.
		- Width is lastHyphenPos.
		- Justification width is lastHyphenPos.
		- LineFlags |= {}
		- Can't optimize if last break was kerned.
	    
	    (e) An auto-hyphen exists and word-break should occur there.
		- Break before auto-hyphen position.
		- Width is suggestedHyphenPos.
		- Justification width is suggestedHyphenPos + hyphenWidth.
		- LineFlags |= {ENDS_IN_AUTO_HYPHEN}
	    
	    (f) An optional hyphen exists and word-break should occur there.
		- Break after optional hyphen.
		- Width is lastHyphenPos.
		- Justification width is lastHyphenPos.
		- LineFlags |= {}
		- Can't optimize if last break was kerned.
	    
	    (g) Only one character fit in the field and this is the first field
		on the line.
		- Break after the character.
		- Width is sizeSoFar
		- Justification width is sizeSoFar.
		- LineFlags |= {}.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLineBreak	proc	near
	;
	; We check the TAB first because any other sort of field-end is
	; considered a line-break. This allows us to set the LINE_TERMINATED
	; flag as soon as we decide that we haven't seen a tab.
	;
	LocalCmpChar ax, C_TAB		; Check for TAB
	jne	notTab
	call	BreakAtTab
	jmp	gotValues
notTab:

	;
	; All other field ends are line-terminating.
	;
	ornf	externals.TOCE_flags, mask TOCF_LINE_TERMINATED

	LocalIsNull ax			; Check for ending in a NULL
	jnz	notNull

	call	BreakAtNull
	jmp	gotValues
notNull:

	LocalCmpChar ax, C_COLUMN_BREAK	; Check for ending in a COLUMN_BREAK
	jne	notColumnBreak

	call	BreakAtColumnBreak
	jmp	gotValues
notColumnBreak:

	LocalCmpChar ax, C_SECTION_BREAK ; Check for ending in a SECTION_BREAK
	jne	notSectionBreak

	call	BreakAtSectionBreak
	jmp	gotValues
notSectionBreak:

	LocalCmpChar ax, C_CR		; Check for ending in a CR
	jne	notCR
	call	BreakAtCR
	jmp	gotValues
notCR:

	;
	; Must be a word-wrap or a hyphen break.
	;
	call	BreakAtWordWrapOrHyphen

gotValues:
	;
	; bx.al	= Width of the field
	; cx	= Width of the field for justification purposes
	; dx	= LineFlags
	; di	= Offset into the field where we want to break the line
	; si	= Number of extra spaces on the line
	;
	
if (0)	; Removed: we can't always determine LF_INTERACTS_{ABOVE/BELOW}
	; by checking the tall character. - Joon (12/5/94)
	;
	; Before we do anything else we need to check to see if the set of
	; characters between the field start and the break position contains
	; characters which interact with the line above or below (by sticking
	; outside the bounds of the line).
	;
	call	CheckTallChars
endif
	
	;
	; The height and baseline have been adjusted and flags have been
	; set to indicate if text extends outside the line bounds.
	;
	; Save away the various values.
	;
	movwbf	externals.TOCE_fieldWidth, bxal

	mov	externals.TOCE_justWidth, cx

	or	externals.TOCE_lineFlags, dx

	mov	externals.TOCE_nChars, di

	add	externals.TOCE_nSpaces, si
	ret
FindLineBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break a line because a NULL was encountered.

CALLED BY:	FindLineBreak
PASS:		ss:bp	= TOC_vars
		di	= Offset to position where overflow occurred
		al	= NULL
		bl	= Previous character
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtNull	proc	near
	mov	dx, mask LF_ENDS_PARAGRAPH or mask LF_ENDS_IN_NULL
	clr	ax
	GOTO	BreakAtLineEndChar
BreakAtNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtColumnBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break a line because a COLUMN_BREAK was encountered.

CALLED BY:	FindLineBreak
PASS:		ss:bp	= TOC_vars
		di	= Offset to position where overflow occurred
	SBCS:
		al	= COLUMN_BREAK
		bl	= Previous character
	DBCS:
		ax	= COLUMN_BREAK
		bx	= Previous character

RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtColumnBreak	proc	near
	mov	dx, mask LF_ENDS_PARAGRAPH or mask LF_ENDS_IN_COLUMN_BREAK
	mov	ax, 1
	GOTO	BreakAtLineEndChar
BreakAtColumnBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break a line because a CR was encountered.

CALLED BY:	FindLineBreak
PASS:		ss:bp	= TOC_vars
		di	= Offset to position where overflow occurred
	SBCS:
		al	= CR
		bl	= Previous character
	DBCS:
		ax	= COLUMN_BREAK
		bx	= Previous character

RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtCR	proc	near
	mov	dx, mask LF_ENDS_PARAGRAPH or mask LF_ENDS_IN_CR
	mov	ax, 1
	call	BreakAtLineEndChar
	
	;
	; Add to the field width the size of a paragraph-end character.
	;
	push	cx, dx, di
	clrwbf	dxbl			; No kerning
SBCS <	mov	al, C_PARAGRAPH		; al <- char to add		>
DBCS <	mov	ax, C_PARAGRAPH_SIGN	; ax <- char to add		>
	call	JustAddCharWidth	; Update sizeSoFar
	pop	cx, dx, di
	
	GOTO	GetSizeSoFar		; bx.al <- TMS_sizeSoFar
BreakAtCR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtSectionBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break a line because a SECTION_BREAK was encountered.

CALLED BY:	FindLineBreak
PASS:		ss:bp	= TOC_vars
		di	= Offset to position where overflow occurred
	SBCS:
		al	= SECTION_BREAK
		bl	= Previous character
	DBCS:
		ax	= SECTION_BREAK
		bx	= Previous character

RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtSectionBreak	proc	near
	mov	dx, mask LF_ENDS_PARAGRAPH or mask LF_ENDS_IN_SECTION_BREAK
	mov	ax, 1
	REAL_FALL_THRU BreakAtLineEndChar
BreakAtSectionBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtLineEndChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break at a line-ending character.

CALLED BY:	BreakAtNull, BreakAtColumnBreak, BreakAtSectionBreak, BreakAtCR
PASS:		ss:bp	= TOC_vars
		dx	= LineFlags to start with
		di	= Offset to character we broke at
		ax	= Number of characters after 'di' to include
	SBCS:
		bl	= Previous character
	DBCS:
		bx	= Previous character
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtLineEndChar	proc	near
	add	di, ax			; dx <- offset to break at
	;
	; Special case to handle here. If the previous character (bl) was
	; an optional-hyphen then we want to draw the hyphen. Since we are
	; drawing it, we want the width of the hyphen to be considered as part
	; of the width of the field.
	;
	; The position of the hyphen break is in lastHyphenPos.
	;
SBCS <	cmp	bl, C_OPTHYPHEN						>
DBCS <	cmp	bx, C_SOFT_HYPHEN					>
	je	checkOptHyphen

	;
	; The previous character wasn't an optional hyphen. We can just break
	; the field.
	;
	; The field width is always 'sizeSoFar'. The problem is with the
	; justification width.
	;
	; If the character before the terminator (bl) is a space then we want
	; to set the justification width to lastWordEndPos.
	;
	; If the character before the terminator was not then we want to set
	; the justification width to 'sizeSoFar'.
	;
	call	GetSizeSoFar		; bx.al <- TMS_sizeSoFar
	rndwbf	bxal, cx		; cx <- justification width

setNSpaces:
	mov	si, externals.TOCE_nExtraSpaces

	call	CopyFieldHeightVars	; Update the field height

	;
	; Check for previous character kerned, can't optimize in this case.
	;
	test	externals.TOCE_otherFlags, mask TOCOF_PREV_CHAR_KERNED
	jz	quit
	ornf	dx, mask LF_LAST_CHAR_KERNED
quit:
	;
	; dx	= LineFlags
	; cx	= Width of the field for justification purposes
	; bx.al	= Width of the field
	; di	= Offset into the  field where we want to break the line
	; si	= Number of spaces to add to the paddable spaces
	;
	ret


checkOptHyphen:
	;
	; There is a chance that although the previous character was an
	; optional hyphen, the hyphen character may not fit on the line.
	; If it doesn't, then we want to word-wrap this line if possible.
	;
	test	externals.TOCE_flags, mask TOCF_OPT_HYPHEN_TOO_WIDE
	jnz	hyphenTooWide

	;
	; The hyphen does fit. Set the following:
	;	dx	= Old flags + "ends in optional hyphen" flag
	;	bx.al	= End of last hyphen
	;	cx	= Integer width of the field (bx.al)
	;
	or	dx, mask LF_ENDS_IN_OPTIONAL_HYPHEN
	movwbf	bxal, internals.TOCI_lastHyphenPos
	rndwbf	bxal, cx
	jmp	setNSpaces


hyphenTooWide:
	;
	; The optional hyphen that comes before the break-char didn't fit.
	; Move backwards and try to word-wrap.
	;
	sub	di, ax
	call	BreakAtWordWrapOrHyphen
	jmp	quit
BreakAtLineEndChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break at a tab character.

CALLED BY:	FindLineBreak
PASS:		ss:bp	= TOC_vars
		di	= Offset to character we broke at
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtTab	proc	near
	;
	; One of two possibilities. The previous character was some valid
	; character (!=0) or the only character in the field is a TAB and that
	; tab doesn't even fit.
	;
	test	externals.TOCE_flags, mask TOCF_ONE_TAB_TOO_LARGE
	jnz	onlyCharWideTab		; Branch if one tab and it's too wide

	;
	; The field contains more than just the tab character.
	;
	clr	dx			; No LineFlags
	call	GetSizeSoFar		; bx.al <- TMS_sizeSoFar
	rndwbf	bxal, cx		; cx <- justification width

	mov	si, externals.TOCE_nExtraSpaces

	jmp	CopyFieldHeightVarsAndCheckBreakKerned

onlyCharWideTab:
	;
	; The only character in the field is a tab. The tab is wider
	; than the field.
	;	
	clr	si			; No more spaces to pad
	clrwbf	bxal			; Width of the field
	clr	cx			; Justification width
	clr	dx			; LineFlags
	ret

BreakAtTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtWordWrapOrHyphen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break at either a word-wrap or a hyphen, whatever is most
		appropriate

CALLED BY:	FindLineBreak, BreakAtLineEndChar
PASS:		ss:bp	= TOC_vars
		di	= Offset to character we want to break at
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtWordWrapOrHyphen	proc	near
	;
	; Check for the case of a single character causing an overflow in the
	; first field of the line.
	;
	test	externals.TOCE_otherFlags, mask TOCOF_FIRST_CHAR_OVERFLOW
	LONG jnz BreakAtOneWideChar

	;
	; One character did not overflow the entire field. Check to see if
	; we can word-wrap.
	;
	test	externals.TOCE_flags, mask TOCF_NO_WORD_WRAP
	LONG jnz BreakAtNoWordWrap	; Branch if not word wrapping


	;
	; Word-wrap needs to be done at some point. We need to get the
	; suggested break position from the hyphenation callback, then
	; we need to consider and find the best place for the break.
	;
	test	externals.TOCE_flags, mask TOCF_AUTO_HYPHENATE
	jz	gotHyphens		; Branch if no auto-hyphenation

	;
	; release the font, do callback, and lock font again
	;
	mov	ax, 1
	call	DoCallback 
	
gotHyphens:
	;
	; Decide if we have to choose between the suggestion and a hyphen in
	; the text.
	;
	mov	ax, internals.TOCI_lastHyphen
	or	ax, internals.TOCI_suggestedHyphen
	jz	BreakAtWordWrap		; Branch if no hyphens

	REAL_FALL_THRU BreakAtHyphen
BreakAtWordWrapOrHyphen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtHyphen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break at a hyphen.

CALLED BY:	BreakAtWordWrapOrHyphen
PASS:		ss:bp	= TOC_vars
		di	= Offset to character we want to break at
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtHyphen	proc	near
	clr	dx			; No LineFlags

	;
	; Check to see if we have a simple case of only one position to
	; consider.
	;
	tst	internals.TOCI_lastHyphen
	jz	useSuggestion
	tst	internals.TOCI_suggestedHyphen
	jz	useLastHyphen

	;
	; There are two possible word break positions, the suggested hyphen
	; and the hyphen found in the text.
	;
	; Check to see which break is further down the line. Use the last
	; break possible.
	;
	mov	ax, internals.TOCI_suggestedHyphen
	cmp	ax, internals.TOCI_lastHyphen
	ja	useSuggestion

useLastHyphen:
	;
	; Want to use the hyphen found in the text, fall thru and do the same
	; work as we would if there were no suggestion.
	;
	test	ss:[bp].TMS_flags, mask TMSF_IS_OPTIONAL_HYPHEN
	jz	10$
	ornf	dx, mask LF_ENDS_IN_OPTIONAL_HYPHEN
10$:
	mov	di, internals.TOCI_lastHyphen
	mov	si, externals.TOCE_nExtraSpaces
	movwbf	bxal, internals.TOCI_lastHyphenPos
	rndwbf	bxal, cx
	
	;
	; There aren't any extra spaces at the end of the line when we break
	; at a hyphen.
	;
	clr	externals.TOCE_nExtraSpaces
	jmp	CheckBreakKerned


useSuggestion:
	;
	; Use the auto-hyphen suggested by the hyphen callback.
	;
	mov	di, internals.TOCI_suggestedHyphen
	mov	si, externals.TOCE_nExtraSpaces
	ornf	dx, mask LF_ENDS_IN_AUTO_HYPHEN

	;
	; The width of the field is the width where the hyphen was inserted.
	;
	; The width of the field for justification is the width of the field
	; plus the size of the hyphen.
	;
	; First we compute the width of the field for justification.
	;
	movwbf	bxal, internals.TOCI_suggestedHyphenPos
	addwbf	bxal, externals.TOCE_hyphenWidth
	rndwbf	bxal, cx

	;
	; Get the field width without the hyphen.
	;
	movwbf	bxal, internals.TOCI_suggestedHyphenPos

	;
	; There aren't any extra spaces at the end of the line when we break
	; at a hyphen.
	;
	clr	externals.TOCE_nExtraSpaces
	jmp	CopyFieldHeightVarsAndCheckBreakKerned

BreakAtHyphen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtWordWrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Word-wrap a line.

CALLED BY:	BreakAtWordWrapOrHyphen
PASS:		ss:bp	= TOC_vars
		di	= Offset to character we want to break at
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtWordWrap	proc	near
	;
	; Break the line at the last word break. 
	; There may be only a single word on the line, in which case we want
	; to do word break as though there was no word-wrap.
	;
	tst	internals.TOCI_lastWordStart
	jz	BreakAtNoWordWrap

	;
	; Was not just single word on the line, break at the start of the previous
	; word.
	;
	; Want to break at the start of the last word.
	; But the position of the break, as far as the width of the field is
	; concerned, is at the end of the last word that fit.
	;
	mov	di, internals.TOCI_lastWordStart
	clr	si
	movwbf	bxal, internals.TOCI_lastWordPos
	mov	cx, internals.TOCI_lastWordEndPos

	;
	; Check for break kerned, if it is then we can't optimize this line.
	;
	clr	dx
	jmp	CheckBreakKerned
BreakAtWordWrap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtNoWordWrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break a line at the character that overflowed

CALLED BY:	BreakAtWordWrapOrHyphen
PASS:		ss:bp	= TOC_vars
		di	= Offset to character we want to break at
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtNoWordWrap	proc	near
	;
	; We aren't word-wrapping. Break the line at the character that
	; overflowed.
	;
					; di already holds break pos
	mov	si, externals.TOCE_nExtraSpaces

	call	GetPosBeforeLastChar	; bx.al <- Field width
	rndwbf	bxal, cx		; cx <- Justification width
	clr	dx			; dx <- Flags
	call	CopyFieldHeightVars	; Update the line height

	;
	; Check for previous character kerned, can't optimize in this case.
	;
	test	externals.TOCE_otherFlags, mask TOCOF_PREV_CHAR_KERNED
	jz	quit
	ornf	dx, mask LF_LAST_CHAR_KERNED
quit:
	ret
BreakAtNoWordWrap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakAtOneWideChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Break when a single character is wider than all the space on
		the line.

CALLED BY:	BreakAtWordWrapOrHyphen
PASS:		ss:bp	= TOC_vars
		di	= Offset to character we want to break at
RETURN:		bx.al	= Width of the field
		cx	= Width of the field for justification purposes
		dx	= LineFlags
		di	= Offset into the field where we want to break the line
		si	= Number of extra spaces to include in the set of
			  paddable spaces.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakAtOneWideChar	proc	near
	;
	; One char was too wide for the entire line.
	;
;	inc	di			; Include this character
;	clr	si			; No extra spaces

					; di already holds break pos
	mov	si, externals.TOCE_nExtraSpaces
	call	GetPosBeforeLastChar	; bx.al <- Field width
	rndwbf	bxal, cx		; cx <- justification width
	clr	dx			; dx <- LineFlags (none)
	call	UpdateFieldHeightVars	; Save height for this char

CopyFieldHeightVarsAndCheckBreakKerned	label	near
	;
	; "Called" by:
	;	BreakAtTab, 
	call	CopyFieldHeightVars	; Set the line height

CheckBreakKerned	label	near
	;
	; Check for break kerned, if it is then we can't optimize this line.
	;
	test	externals.TOCE_otherFlags, mask TOCOF_LAST_BREAK_KERNED
	jz	quit
	ornf	dx, mask LF_LAST_CHAR_KERNED
quit:
	ret
BreakAtOneWideChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTallChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a tall character is included in the line.

CALLED BY:	FindLineBreak
PASS:		ss:bp	= TOC_vars structure on stack.
		di	= position of the break.
RETURN:		TOCE_lineHeight and TOCE_lineBLO adjusted.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	/*
	 * A larger baseline indicates extra height above.
	 */
	if tallCharBLOPos < di then
	    if tallCharBLO > lineBLO then
	        Set LF_INTERACTS_ABOVE
	/*
	 * Now check the descents.
	 */
	if tallCharHeightPos < di then
	    if tallCharHeight - tallCharBLO > lineHeight - lineBLO then
		Set LF_INTERACTS_BELOW

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (0)	; Removed: we can't always determine LF_INTERACTS_{ABOVE/BELOW}
	; by checking the tall character. - Joon (12/5/94)

CheckTallChars	proc	near
	uses	ax, bx, cx, dx, si
	.enter
	movwbf	axbl, internals.TOCI_tallCharBaseline ; ax.bl <- tc baseline
	movwbf	cxbh, externals.TOCE_lineBLO	; cx.bh <- line baseline

	cmp	di, internals.TOCI_tallCharBaselinePos
	jbe	afterBaseline			; Branch if no blo change in
						;    this line is possible.
	cmpwbf	axbl, cxbh			; Branch if tall-char has
	jbe	afterBaseline			;  shorter baseline.

	ornf	externals.TOCE_lineFlags, mask LF_INTERACTS_ABOVE
afterBaseline:
	;
	; ax.bl	= tall char baseline
	; cx.bh	= lines baseline
	;
	cmp	di, internals.TOCI_tallCharHeightPos
	jbe	afterHeight

	;
	; Compute the difference between the line height and the lines
	; baseline in order to get the descent for the line.
	; si.dl <- line descent
	;
	movwbf	sidl, externals.TOCE_lineHeight	; si.dl <- line height
	subwbf	sidl, cxbh			; si.dl <- line descent

	movwbf	cxbh, internals.TOCI_tallCharHeight ; cx.bh <- tc height
	subwbf	cxbh, axbl			; cx.bh <- tc descent

	cmpwbf	sidl, cxbh			; Compare descents
	jae	afterHeight			; Branch if no below interaction
	;
	; The descent for the tall-character is larger than the descent for
	; the line. This means that the tall character interacts with the
	; line below it.
	;
	ornf	externals.TOCE_lineFlags, mask LF_INTERACTS_BELOW
afterHeight:
	.leave
	ret
CheckTallChars	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSoftHyphen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a soft-hyphen character will fit on the line.

CALLED BY:	GrTextObjCalc
PASS:		ss:bp - TOC_locals structure on stack.
RETURN:		TOC_lastHyphen, TOC_lastHyphenPos, set
		carry set if the hyphen didn't fit.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Get the width of a hyphen character.
	Add it to the space left on the line and check for an overflow.
	If overflow, then return with no change.
	If no overflow, then save position of hyphen and the width of the text
	   after the expanded hyphen.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/89	Initial version
	JDM	93.02.15	pushwbf modifications.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckSoftHyphen	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	; See how long the text would be with a hyphen at the end
	; Save the current position, and set a flag telling AddWidth
	; to only update the position, so we can not worry about
	; saving the other stuff, which would be painful to push
	; and pop.
	;
	; Note that because we have to push and pop words, the low byte
	; of integer gets pushed and popped twice. C'est la vie...
	;
	call	GetSizeSoFar			;bx.al <- old size so far.

	pushwbf	bxal, cx			;Save old size so far
	pushwbf	ss:[bp].TMS_lastCharWidth, cx	;Save last char width

	ornf	ss:[bp].TMS_flags, mask TMSF_UPDATE_SIZE_ONLY
	mov	ax, C_HYPHEN			;al <- hyphen, ah <- no kern
	call	AddWidth			;update 'sizeSoFar'
	;
	; Check to make sure that the hyphen will fit.
	; If it is the first character on the line, it always fits.
	;
	mov	dx, ss:[bp].TMS_sizeSoFar.WBF_int
	
	tst	di
	je	hyphenFits

	cmp	dx, externals.TOCE_areaToFill
	jb	hyphenFits
	;
	; Hyphen is too wide, mark that this hyphen won't fit if it is
	; expanded.
	;
	ornf	externals.TOCE_flags, mask TOCF_OPT_HYPHEN_TOO_WIDE
	stc					; Signal didn't fit.
	jmp	afterHyphen
hyphenFits:
	;
	; The expanded hyphen will fit, save the position.
	;
	mov	internals.TOCI_lastHyphenPos.WBF_int, dx
	mov	dl, ss:[bp].TMS_sizeSoFar.WBF_frac
	mov	internals.TOCI_lastHyphenPos.WBF_frac, dl
	
	mov	dx, di
	inc	dx
	mov	internals.TOCI_lastHyphen, dx
	ornf	ss:[bp].TMS_flags, mask TMSF_IS_BREAK_CHARACTER or \
				      mask TMSF_IS_OPTIONAL_HYPHEN
	andnf	externals.TOCE_flags, not mask TOCF_OPT_HYPHEN_TOO_WIDE
	clc					; Signal did fit.
afterHyphen:
	;
	; Tell AddWidth it's OK to update everything again
	; and restore the position.
	;
	lahf
	andnf	ss:[bp].TMS_flags, not (mask TMSF_UPDATE_SIZE_ONLY)
	
	popwbf	ss:[bp].TMS_lastCharWidth, dx	; Restore last char width
	popwbf	ss:[bp].TMS_sizeSoFar, dx	; Restore size so far

	sahf
	.leave
	ret
CheckSoftHyphen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyFieldHeightVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current field height vars the settings as of the
		last word-break. Also save the amount the line extends above
		or below the line boundaries.

CALLED BY:	GrTextObjCalc.
PASS:		ss:bp	= pointer to TOC_vars structure.
		di	= offset into text where break occurred.
RETURN:		TOCE_lineHeight set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Here's the strategy...
	      - If the descent is larger, the line-height is made taller and
		the baseline is made larger.
	      - If the ascent is larger, the line-height is made taller.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/10/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyFieldHeightVars	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	movwbf	axbl, internals.TOCI_currentHgt	; ax.bl = current height
	movwbf	cxbh, internals.TOCI_currentBlo	; cx.bh = current baseline

	subwbf	axbl, cxbh			; ax.bl = descent
						; cx.bh = ascent
	;
	; Check for a change to the descent (height - blo).
	;
	movwbf	didl, externals.TOCE_lineHeight
	subwbf	didl, externals.TOCE_lineBLO
	;
	; di.dl = lines descent.
	;
	cmpwbf	axbl, didl
	jbe	noDescChange
	;
	; The descents are different, the new one is larger.
	; di.dl = lines descent.
	; ax.bl = current descent.
	;
	; We need to calculate the change in decsent (new - old) and add it
	; to the line height.
	;
	subwbf	axbl, didl			; ax.bl = amount of change.
	
	addwbf	externals.TOCE_lineHeight, axbl
noDescChange:
	;
	; Handle ascent (baseline offset) change.
	;
	movwbf	dibl, externals.TOCE_lineBLO
	;
	; cx.bh = current blo.
	; di.bl	= lines blo.
	;
	cmpwbf	cxbh, dibl			; Compare baselines
	jbe	noBloChange			; Branch if new <= old
	;
	; There is a difference in the baselines, the new one is larger.
	;
	; We need to save the new baseline and adjust the line height.
	; cx.bh = new baseline.
	; di.bl  = old baseline.
	;
	movwbf	externals.TOCE_lineBLO, cxbh

	subwbf	cxbh, dibl
	;
	; cx.bh = difference in the baselines (both rounded) adjust the height.
	;
	addwbf	externals.TOCE_lineHeight, cxbh

noBloChange:
	;
	; If the last character added was kerned then we want to set a bit
	; saying that if we break here, the line is not optimizable.
	;
	andnf	externals.TOCE_otherFlags, not mask TOCOF_LAST_BREAK_KERNED
	test	ss:[bp].TMS_flags, mask TMSF_NEGATIVE_KERNING
	jz	breakNotKerned
	ornf	externals.TOCE_otherFlags, mask TOCOF_LAST_BREAK_KERNED
breakNotKerned:
	.leave
	ret
CopyFieldHeightVars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveTallCharPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the position of a 'tall' character (one that extends above
		or below its font box).

CALLED BY:	GrTextObjCalc().
PASS:		es	= font segment address.
		TMS_locals.TMS_flags with the 'above' or 'below' bit set.
		di	= offset into text where tall char was encountered.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (0)	; Removed: we can't always determine LF_INTERACTS_{ABOVE/BELOW}
	; by checking the tall character. - Joon (12/5/94)

SaveTallCharPos	proc	near
	uses	ax, bx, cx
	.enter
	call	GetHeightAndBaseline
	;
	; Now adjust for the "above" or "below" bits.
	;
	test	ss:[bp].TMS_flags, mask TMSF_EXTENDS_ABOVE
	jz	afterAbove
	addwbf	axbl, es:FB_aboveBox		; Adjust height
	addwbf	cxbh, es:FB_aboveBox		; Adjust baseline
afterAbove:

	test	ss:[bp].TMS_flags, mask TMSF_EXTENDS_BELOW
	jz	afterBelow
	addwbf	axbl, es:FB_belowBox		; Adjust height
afterBelow:

	;
	; Now, ax.bl = height, cx.bh = baseline.
	; If the height is larger than the saved value, save it.
	; If the baseline is larger than the saved value, save it.
	;
	cmpwbf	axbl, internals.TOCI_tallCharHeight
	jbe	afterHeight

	movwbf	internals.TOCI_tallCharHeight, axbl
	mov	internals.TOCI_tallCharHeightPos, di

afterHeight:

	;
	; Check the baseline.
	;
	cmpwbf	cxbh, internals.TOCI_tallCharBaseline
	jbe	afterBaseline
	movwbf	internals.TOCI_tallCharBaseline, cxbh
	mov	internals.TOCI_tallCharBaselinePos, di
afterBaseline:
	.leave
	ret
SaveTallCharPos	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTextPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the offset into a string which is nearest to a given
		position. Return the offset and the nearest valid position.

CALLED BY:	External.
PASS:		cx	= # of characters to check (0 if null terminated).
		dx	= position.(pixel offset into string).
		di	= gstate handle.
		ss:bp	= pointer to GTP_vars structure on stack.
RETURN:		cx	= nearest character boundary to the pixel offset.
		dx	= nearest valid position on line.
		ds	= Segment of last piece of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

USAGE:		ss:bp	= pointer to GTP_locals structure on stack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTextPosition	proc	far
	uses	bx, si, di, es
	push	ax
EC <	call	ECCheckGStateHandle					>
	;
	; Special case for at field start.
	;
	mov	ax, dx				; Save offset in ax.
	clr	dx				; Default return value if
	tst	cx				;   cx == 0.
	jnz	hasCharacters
	jmp	noCharacters
hasCharacters:					;
	mov	dx, ax				; Restore offset into dx.

	.enter

	push	cx	
	mov	cx, size TextMetricStyles	;cx <- # of bytes to init
	call	InitForTextMetrics		;initialize TextMetricStyles
	mov	ss:[bp].GTPL_charCount, 0
	mov	ss:[bp].GTPL_startPosition, dx
	mov	ss:[bp].TMS_flags, \
			mask TMSF_OPT_HYPHENS or mask TMSF_PAD_SPACES
	pop	di				;di <- # chars to check

	clr	bh				;dx.bh <- space left.
SBCS <	clr	ah				;no previous character.	>
	clr	cx				;no valid chars
charLoop:
	;
	; Check for no more characters in this style.
	;
	tst	cx
	jnz	validChars
	
	push	di				; Save max count
	mov	di, ss:[bp].GTPL_charCount	; di <- offset to current pos
	call	CallStyleCallBack		; es <- font seg addr
	pop	di				; Restore max count
	
	cmp	cx, di				; check for count too large.
	jbe	validChars
	mov	cx, di
validChars:
	;
	; We have characters, now we just need to add up the widths.
	; ds:si = pointer to text.
	; es	= segment address of font.
	;
	LocalGetChar ax, dssi, NO_ADVANCE	;ax <- another character

	LocalIsNull ax				;Check for terminator chars.
	jz	noMoreChars
	LocalCmpChar ax, C_CR
	je	noMoreChars
	LocalCmpChar ax, C_TAB
	je	noMoreChars

	LocalNextChar dssi			;Advance pointer
	inc	ss:[bp].GTPL_charCount		;And add one more character

	;
	; If we pass cx == 1 to AddWidth() and the character is an optional
	; hyphen, then the hyphen will be computed as though it were expanded.
	; This is not what we want if this is the last character in the string.
	;
	push	cx				;Save count.
	cmp	cx, di				;Check to see if last time.
	je	addWidth
	mov	cx, 2				;Anything that isn't 1.
addWidth:					;
	call	AddWidth			;add in another character
	pop	cx				;Restore count.
						;
	cmp	ss:[bp].TMS_sizeSoFar.WBF_int, dx	;found position?
	jae	foundPosition
SBCS <	mov	ah, al				;ah <- new kern char	>
DBCS <	mov	ss:[bp].TMS_kernChar, ax				>
	dec	cx				;cx <- one less valid char
	dec	di				;di <- one less char to check
	jne	charLoop			;
noMoreChars:					;
	;
	; Ran out of characters, return:
	;    cx    = length of string.
	;    dx	   = position in string
	;
	mov	cx, ss:[bp].GTPL_charCount	;cx <- offset to string end.
	mov	dx, ss:[bp].TMS_sizeSoFar.WBF_int	;dx <- position
	jmp	done

foundPosition:
	mov	bh, 0
	subwbf	dxbh, ss:[bp].TMS_sizeSoFar

	;
	; dx.bh = -1 * amount of overflow
	; Want:
	;	ax.bl = lastCharWidth / 2.
	;	dx.bh = lastCharWidth - overFlow.
	;
	movwbf	axbl, ss:[bp].TMS_lastCharWidth

	addwbf	dxbh, axbl			; dx.bh = lcw - overFlow
	shrwbf	axbl				; ax.bl = lcw / 2

	;
	; Ran out of room.
	; ax.bl = lastCharWidth / 2.
	; dx.bh = lastCharWidth - overFlow;
	;
	; if (lastCharWidth-overFlow > lastCharWidth/2) then
	;	return( si, passedDX+overFlow);
	; else
	;	return( si-1, passedDX+overFlow-lastCharWidth )
	; endif
	;
	cmp	dx, ax
	jb	returnPrevChar
	ja	returnNextChar
	cmp	bh, bl
	jbe	returnPrevChar

returnNextChar:
	;
	; Return next character we are closer to it.
	;
	subwbf	dxbh, ss:[bp].TMS_lastCharWidth
	jmp	checkRounding

returnPrevChar:
	dec	ss:[bp].GTPL_charCount		;back up one character

checkRounding:
	mov	cx, ss:[bp].GTPL_charCount	;cx <- offset past overflow
	neg	dx
	tst	bh
	jz	alreadyRounded
	dec	dx
alreadyRounded:
	add	dx, ss:[bp].GTPL_startPosition

done:
	;
	; Unlock gstate and font.
	;
	call	UnlockFontAndGState
	.leave
noCharacters:
	pop	ax
	ret
GrTextPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockFontAndGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a font and a gstate.

CALLED BY:	
PASS:		ss:bp	= pointer to TMS_locals structure on the stack.
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockFontAndGState	proc	near
	push	ds				; Save last string seg.
	mov	bx, ss:[bp].TMS_fontHandle	; bx <- handle of font
	call	NearUnlockFont			; unlock the font
	mov	di, ss:[bp].TMS_gstateHandle
	LoadVarSeg	ds			; ds <- idata seg addr
	FastUnLock	ds, di, ax		; unlock the gstate
	pop	ds				; Restor last string seg.
	ret
UnlockFontAndGState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitForTextMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize some stuff for calculating text metrics.
CALLED BY:	GrTextObjCalc, GrTextPosition

PASS:		cx - # of bytes to clear
		di - handle of gstate
		ss:bp - ptr to TextMetricStyle structure on stack
RETURN:		TextMetricStyle structure initialized
		specifically:
		    TMS_gstateHandle
		    TMS_
DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
	ss:bp is passed as the pointer to a TextMetricStyle structure,
	which may be part of either TOC_vars or GTP_vars, hence passing
	the number of bytes to clear.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitForTextMetrics	proc	near
	uses	ax, ds, es
	.enter

	push	di
	segmov	es, ss
	mov	di, bp				;es:di <- ptr to TMS structure
	add	di, offset TMS_sizeSoFar	;don't nuke before this
	sub	cx, offset TMS_sizeSoFar
	clr	al				;al <- byte to store
	rep	stosb				;clear the structure
	pop	di
	;
	; save arguments someplace we can get at them
	;
	mov	ss:[bp].TMS_gstateHandle, di

	;
	; lock the gstate, and save its segment
	;
	LoadVarSeg	ds			; ds <- kernel segment.
	FastLock1	ds, di, ax, IFTM_gsLock1, IFTM_gsLock2, file-global

	mov	ss:[bp].TMS_gstateSegment, ax

	;
	; mark the font as invalid, to force getting the first style run
	;
	mov	ss:[bp].TMS_textAttr.TA_font, FID_INVALID
	;
	; get some stuff from the gstate
	;
	mov	ds, ax
	movwbf	ss:[bp].TMS_textAttr.TA_spacePad, ds:GS_textSpacePad, ax

if CHAR_JUSTIFICATION
	mov	al, ds:GS_textMiscMode
	mov	ss:[bp].TMS_textMiscMode, al
endif

	.leave
	ret
InitForTextMetrics	endp

FastLock2FG	ds, di, ax, IFTM_gsLock1, IFTM_gsLock2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallStyleCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the style-run callback routine to find out how many
		characters are in the same style.

CALLED BY:	GrTextPosition
PASS:		ss:bp - ptr to TextMetricStyle structure on stack.
		di - offset into this text field
RETURN:		cx - # of chars in this style
		ah - new kerning character (none)
		es - seg addr of the locked font
		ds:si - ptr to text
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Call the style-run callback routine to find out how many characters
  are in the same style. The callback routine returns to us the number of
  characters in the same style, and the style information. If the font or
  point-size has changed, we need to unlock our old font, and lock this new
  one. We also need to save the handle of the new font so we can unlock it
  later on.

  The definition of the callback routine is:
	Pass:		ss:bx	= TOC_vars
			di	= Offset into the field
			ds	= Segment address of old text pointer
	Return:		TMS_textAttr set
			ds:si	= Pointer to text at this offset
			cx	= # of characters in this style
	Destroyed:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Currently, the code forces a recalculation of the font if the
	track kerning changes. At a slight sacrifice in space, but a
	potentially larger savings in time, the code could just
	recalculate the track kerning if that is the only thing that
	changed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4-Dec-89	Initial version
	eca	01/26/89	Combined {GTP,GTOC}_callStyleCallBack

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallStyleCallBack	proc	near
	uses	ax, bx, dx, di
	.enter

FXIP<	mov	ss:[TPD_dataBX], bx					>
FXIP<	mov	ss:[TPD_dataAX], ax					>
FXIP<	movdw	bxax, ss:[bp].TMS_styleCallBack				>
FXIP<	call	ProcCallFixedOrMovable					>

NOFXIP<	call	ss:[bp].TMS_styleCallBack				>
	;
	; ds:si	= Text
	; cx	= Number of characters in this style
	; TMS_textAttr set correctly
	;

	push	ds				;save seg addr of text

	;
	; Stuff the font/pt-size into the gstate, clear the handle, then use
	; the existing routines to lock the font.
	;
	; ds <- gstate segment address
	;
	call	FixupGStateGetInDS		;ds <- gstate segment
	
	mov	ax, ss:[bp].TMS_textAttr.TA_trackKern
	mov	ds:GS_trackKernDegree, ax	;set track kerning

	mov	al, ss:[bp].TMS_textAttr.TA_styleSet
	mov	ds:GS_fontAttr.FCA_textStyle, al

	mov	ax, ss:[bp].TMS_textAttr.TA_font
	mov	ds:GS_fontAttr.FCA_fontID, ax

	movwbf	ds:GS_fontAttr.FCA_pointsize, ss:[bp].TMS_textAttr.TA_size, ax

	mov	ax, {word}ss:[bp].TMS_textAttr.TA_fontWeight
	mov	{word}ds:GS_fontAttr.FCA_weight, ax
CheckHack <(offset TA_fontWidth) eq (offset TA_fontWeight)+1>
CheckHack <(offset FCA_width) eq (offset FCA_weight + 1)>

	;
	; Unlock the old font (if there was one).
	;
	mov	bx, ss:[bp].TMS_fontHandle	;bx <- handle of font
	tst	bx
	jz	noOldFont			;branch if no old font
	call	NearUnlockFont			;unlock old font
noOldFont:
	;
	; We need to invalidate the font handle in the gstate.
	;
	call	InvalidateFont			;invalidate me jesus
	;
	; Lock the new font, and save the new text settings.
	;
	call	NearLockFont
	mov	ss:[bp].TMS_fontHandle, bx	;save font handle
	mov	es, ax				;es <- font segment
	
	mov	ax, {word}ds:GS_trackKernValue	;save new character spacing
	mov	{word}ss:[bp].TMS_trackKernValue, ax
	mov	al, ds:GS_textMode
	mov	ss:[bp].TMS_textAttr.TA_modeSet, al ;optimizations may change
	pop	ds				;ds <- seg addr of text

	.leave
	ret
CallStyleCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupGStateGetInDS, FixupGStateNukeNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference the gstate handle to get the segment address
		of the gstate and save it in the stack frame again.

CALLED BY:	Anyone who calls a callback and wants the gstate segment to
		be up to date
PASS:		ss:bp	= TMS_vars
RETURN:		TMS_gstateSegment up to date
		ds	= Segment address of gstate
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupGStateGetInDS	proc	near
	uses	bx
	.enter
	mov	bx, ss:[bp].TMS_gstateHandle	; bx <- gstate handle
	call	MemDerefDS			; ds <- gstate segment
	mov	ss:[bp].TMS_gstateSegment, ds	; Save the new segment
	.leave
	ret
FixupGStateGetInDS	endp

FixupGStateNukeNothing	proc	near
	uses	ds
	pushf
	.enter
	call	FixupGStateGetInDS
	.leave
	popf
	ret
FixupGStateNukeNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicInLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a non-breaking graphic in the line.

CALLED BY:	AddWidth
PASS:		ss:bp	= pointer to TOC_vars structure on stack.
		es	= segment address of font.
RETURN:		dx.bl	= width of the graphic.
		es	= segment address of font. (May have changed).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Use callback routine to get width and height of graphic.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GraphicInLineWidth	proc	near
	uses	ax, cx, ds
	.enter

	clr	ax
	call	DoCallback

	;
	; Change "styleHeight" and "styleBaseline".
	; The graphic is considered to be a character that has no descent.
	; The result is that the graphic 'rides' the baseline. The entire
	; graphic is above the baseline.
	;
	; if pictHeight > styleBaseline then
	;	styleHeight += (pictHeight - styleBaseline)
	;	styleBaseline = pictHeight
	; endif
	;
	cmp	cx, ss:[bp].TMS_styleBaseline.WBF_int
	jbe	noChange

	mov	ax, cx
	sub	ax, ss:[bp].TMS_styleBaseline.WBF_int
	add	ss:[bp].TMS_styleHeight.WBF_int, ax

	mov	ss:[bp].TMS_styleBaseline.WBF_int, cx
	mov	ss:[bp].TMS_styleBaseline.WBF_frac, 0
	;
	; We fake a style change to that UpdateFieldHeightVars() will be
	; called if this graphic fits on the line. This updates the line
	; height correctly.
	;
	ornf	ss:[bp].TMS_flags, mask TMSF_STYLE_CHANGED
noChange:
	clr	bl				; dx.bl <- picture width.
	.leave
	ret
GraphicInLineWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Releases the font so callback can lock it if needed, then
		does the callback, and re-locks the font. 

CALLED BY:	GraphicInLineWidth, BreakAtWordWrapOrHyphen
PASS:		ax 	= nonzero for BreakAtWordHyphen, 0 for GraphicILW
		ss:bp 	= TOC_vars on stack
		di	= Offset to character we want to break at
RETURN:		(see CalculateGraphicsCallback or CalculateHyphenCallBack)

DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/ 5/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoCallback	proc	near
	uses	ds, ax, bx
	.enter

	;
	; Need to release the font so that the callback can lock it if
	; it needs to as part of computing the hyphen related information.
	;
	mov	bx, ss:[bp].TMS_fontHandle
	call	NearUnlockFont

	tst	ax
FXIP<	mov	ss:[TPD_dataAX], ax				>
FXIP<	mov	ss:[TPD_dataBX], bx				>
	jz	doGraphicsCallback

NOFXIP<	call	externals.TOCE_hyphenCallback			>
FXIP<	movdw	bxax, externals.TOCE_hyphenCallback		>
	jmp	done

doGraphicsCallback:
NOFXIP<	call	ss:[bp].TMS_graphicCallBack			>
FXIP<	movdw	bxax, ss:[bp].TMS_graphicCallBack		>

done:

FXIP<	call	ProcCallFixedOrMovable				>

	;
	; Patch up the gstate segment in case the gstate moved.
	;
	call	FixupGStateGetInDS

	;
	; Re-lock the font in case we need it for some reason...
	;
	call	NearLockFont			; ax <- segment
						; bx <- handle
	mov	es, ax				; Establish seg addr of font.
DBCS <	mov	ss:[bp].TMS_fontHandle, bx	; may have changed	>

	.leave
	ret
DoCallback	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the width of the current character accounting for style.

CALLED BY:	INTERNAL:
		GrTextObjCalc, GTOC_checkSoftHyphen, GTOC_findBreakPositions,
		GrTextPosition
PASS:		ss:bp - ptr to TextMetricStyles on stack
		al - current character
		ah - kerning character
		es - seg addr of font
		if TMSF_OPT_HYPHENS set:
		     cx - # of chars to check (1 if last char)
		     ds:si - ptr to next character
RETURN:		TMS_sizeSoFar - accumulated position
		TMS_lastCharWidth - width of character (including kerning)
		carry set if there was pair kerning or track kerning done
		   on this character.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	The compares and branches in this routine are optimized for
	the following assumptions:
	    (1) the most common character is one of [a-z][A-Z]
	    (2) the next most common is [ ] (space)
	    (3a) track and pair-wise kerning are less common
	    (3b) graphics are less common
	    (3c) hyphens are less common
	The current arrangement allows for 4 branches not taken,
	instead of 8 branches taken as was previously the case.
	This adds up rather quickly since:
	    branch not taken = 4 cycles
	    branch taken = 16 cycles
	    50 chars * (16 cycles * 8 - 4 cycles * 4) = 5,600 cycles

	If necessary, handle optional hyphens
	Adjust position if the current character is kerned
	Handle missing characters
	Add in the size of the character

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/89	Initial version
	eca	 1/26/90	Consolidated from GTOC_addWidth, GTP_addWidth

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddWidth	proc	near
	uses	ax, bx, cx, dx, di
	.enter

	andnf	ss:[bp].TMS_flags, not mask TMSF_NEGATIVE_KERNING
	mov	bh, ss:[bp].TMS_textAttr.TA_modeSet	;bh <- optimization flags
	clr	dx
	clr	bl				;dx.bl <- width of char

if CHAR_JUSTIFICATION
	test	bh, mask TM_PAD_SPACES
	jnz	isSpecialChar2
endif
	LocalCmpChar ax, C_SPACE		;before space?
	jbe	isSpecialChar			;might be special character
afterSpecialChar:
	test	bh, mask TM_PAIR_KERN or mask TM_TRACK_KERN
	jnz	isKerning
afterKerning:
	;
	; Add actual character width.
	;
	call	JustAddCharWidth		;add char width
	test	al, mask CTF_NEGATIVE_LSB
	jnz	hasNegativeLSB
setCharWidth:
	test	ss:[bp].TMS_flags, mask TMSF_UPDATE_SIZE_ONLY
	jnz	done				;special case for hyphens

	movwbf	ss:[bp].TMS_lastCharWidth, dxbl
done:
	.leave
	ret

	;
	; The character just added has a negative left-side bearing.
	; We need to note this specially since it wreaks havoc
	; on updating.
	;
hasNegativeLSB:
	ornf	ss:[bp].TMS_flags, mask TMSF_NEGATIVE_KERNING
	jmp	setCharWidth

if CHAR_JUSTIFICATION
isSpecialChar2:
	test	ss:[bp].TMS_textMiscMode, mask TMMF_CHARACTER_JUSTIFICATION
	jnz	doSpacePad			;branch if doing char just.
	LocalCmpChar ax, C_SPACE
endif
	;
	; Character is before or equal to a space (C_SPACE)
	; It may be a space, an inline graphic, an optional hyphen,
	; or none of the above.
	; NOTE: flags are set based on "cmp al, C_SPACE"
	;
isSpecialChar:
	jne	notSpace
	;
	; The character is a space. See if we need to do any
	; space padding for full justified text.
	;
if CHAR_JUSTIFICATION
doSpacePad:
endif
	test	bh,  mask TM_PAD_SPACES
	jz	afterSpecialChar		;branch if no space padding
	test	ss:[bp].TMS_flags, mask TMSF_PAD_SPACES
	jz	afterSpecialChar		;branch if we should ignore
	addwbf	dxbl, ss:[bp].TMS_textAttr.TA_spacePad
notSpace:
SBCS <	cmp	al, C_OPTHYPHEN			;optional hyphen?	>
DBCS <	cmp	ax, C_SOFT_HYPHEN		;optional hyphen?	>
	je	isOptHyphen			;branch if optional hyphen
	LocalCmpChar ax, C_GRAPHIC		;inline graphic?
	jne	afterSpecialChar		;branch if not a special char
	;
	; The character is an inline graphic. Get its width and
	; use that for the character width.
	;
	call	GraphicInLineWidth		;dx.bl == width of graphic
	addwbf	ss:[bp].TMS_sizeSoFar, dxbl
	jmp	setCharWidth

isOptHyphen:
	;
	; Character is an optional hyphen. If this is the last
	; character to check, or the last character in the text,
	; then pretend it is a real hyphen, otherwise ignore it.
	;
	test	ss:[bp].TMS_flags, mask TMSF_OPT_HYPHENS
	je	afterSpecialChar		;don't deal with it...
	dec	cx				;see if last char to check
;;;	cmp	cx, 1				;see if last char to check
	jz	convertOptHyphen
SBCS <	cmp	{byte} ds:[si], 0		;see if last char of text >
DBCS <	cmp	{wchar} ds:[si], 0		;see if last char of text >
	je	convertOptHyphen
	jmp	done				;else ignore
convertOptHyphen:
	test	bh, mask TM_DRAW_OPTIONAL_HYPHENS
	jz	afterSpecialChar		;branch if not drawing them
SBCS <	mov	al, C_HYPHEN			;pretend it's a real hyphen >
DBCS <	mov	ax, C_HYPHEN_MINUS		;pretend it's a real hyphen >
	jmp	afterSpecialChar

	;
	; There is pair-wise and/or track kerning.
	;
isKerning:
	push	ax
	test	bh, mask TM_PAIR_KERN		;see if any pair kerning
	jz	noPairKerning			;branch if no pair kerning
	;
	; Adjust the size so far based on the kerning pair of
	; the previous and current characters.
	;	al = current character
	;	ah = previous character
	;
if DBCS_PCGEOS
	PrintMessage <fix AddWidth for DBCS>
	ERROR	-1
endif
	mov	cx, es:FB_kernCount		;cx <- # of kerning  pairs
	mov	di, es:FB_kernPairPtr		;es:di = kerning table
						;
	repne scasw				;find kerning pair (al, ah)
	jne	noPairKerning			;quit if not found
	;
	; Kerning pair was found, adjust width.
	;
	sub	di, es:FB_kernPairPtr		; di = offset to char (+1)
	add	di, es:FB_kernValuePtr		; di = offset to value (+1)
	mov	ax, es:[di-2]			; cx <- change (BBFixed)
	add	bl, al
	mov	al, ah
	cbw
	adc	dx, ax				;dx.bl += pair kerning
noPairKerning:
	test	bh, mask TM_TRACK_KERN		;see if any kerning
	jz	noTrackKerning			;branch if no kerning
	;
	; Adjust width by track kerning value.
	;
	mov	ax, {word}ss:[bp].TMS_trackKernValue
	add	bl, al
	mov	al, ah
	cbw					;sign extend
	adc	dx, ax				;dx.bl += track kerning
noTrackKerning:
	pop	ax
	;
	; Check for negative kerning.
	;
	tst	dx
	jns	notNegKerning
	ornf	ss:[bp].TMS_flags, mask TMSF_NEGATIVE_KERNING
notNegKerning:
	jmp	afterKerning
	
AddWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JustAddCharWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just add a character width to TMS_sizeSoFar.

CALLED BY:	AddWidth, FindLineBreak
PASS:		es	= font segment address.
		ax	= character to add.
		dx.bl	= any kerning, etc that might be needed.
		ss:bp	= TextMetricStyles
RETURN:		TMS_sizeSoFar updated
		dx.bl	= width of character, including any kerning
		TMS_flags w/ TMSF_TOO_TALL or TMSF_TOO_SHORT bits set
		   if the character extends above or below the line.
		al = CharTableFlags for this character.
DESTROYED:	bh, cx, di

PSEUDO CODE/STRATEGY:
	The branches and compares are arranged under the assumption
	that most characters do not go above or below the standard
	font box. Characters that do include upper case letters with
	accents, some stylized / scripted characters, and other
	special-use characters.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JustAddCharWidth	proc	near

if DBCS_PCGEOS

afterDefault:
	cmp	ax, es:FB_lastChar		;after last char?
	ja	afterLastChar			;branch if after last char
	sub	ax, es:FB_firstChar		;convert to index
	jb	beforeFirstChar			;branch if before first

else

	cmp	al, es:FB_lastChar		;after last char?
	ja	useDefaultChar			;branch if after last char
afterDefault:					;
	sub	al, es:FB_firstChar		;convert to index
	jb	useDefaultChar			;branch if before first

endif
						;
	mov	di, ax				;di <- index of character
SBCS <	andnf	di, 0x00ff			;ah was garbage...	>
	FDIndexCharTable di, ax			;di <- offset into char table
	tst	es:FB_charTable.CTE_dataOffset[di]
	jz	useDefaultChar			;use default if missing

	addwbf	dxbl, es:FB_charTable[di].CTE_width
	;
	; dx.bl = width of the character, including kerning
	; al = the chararcter
	;
	tst	dh				;see if negative
	js	isBackwardsMove			;don't go backwards

	addwbf	ss:[bp].TMS_sizeSoFar, dxbl	;add width of char
afterMove:
	;
	; We need to check if this character goes outside the
	; font box. If it does, we need to either: (a) adjust
	; the line height so it doesn't interact with other lines
	; (b) find out which lines it did interact with and
	; redraw them and ourselves appropriately.
	;
	andnf	ss:[bp].TMS_flags, \
		not (mask TMSF_EXTENDS_ABOVE or \
		     mask TMSF_EXTENDS_BELOW)

	mov	al, es:FB_charTable[di].CTE_flags
	test	al, mask CTF_ABOVE_ASCENT
	jnz	isAbove
afterAbove:
	test	al, mask CTF_BELOW_DESCENT
	jnz	isBelow
afterBelow:
	ret

isAbove:
	ornf	ss:[bp].TMS_flags, mask TMSF_EXTENDS_ABOVE
	jmp	afterAbove

isBelow:
	ornf	ss:[bp].TMS_flags, mask TMSF_EXTENDS_BELOW
	jmp	afterBelow

isBackwardsMove:
	clr	bl
	clr	dx				;no character width
	jmp	afterMove


if DBCS_PCGEOS
	;
	; The character in question is not in the current section
	; of the font.  Lock down the correct section and try again.
	;
beforeFirstChar:
	add	ax, es:FB_firstChar		;re-adjust character
afterLastChar:
	push	ax, ds
	mov	ds, ss:[bp].TMS_gstateSegment
	call	LockCharSet
	mov	es, ax				;es <- seg addr of font
	mov	ax, ds:GS_fontHandle		;ax <- font handle
	mov	ss:[bp].TMS_fontHandle, ax	;store new font handle
	pop	ax, ds
	jnc	afterDefault			;branch if char exists
useDefaultChar:
	mov	ax, es:FB_defaultChar
	jmp	afterDefault

else

useDefaultChar:
	mov	al, es:FB_defaultChar
	jmp	afterDefault
endif

JustAddCharWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFieldHeightVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set new field height/blo/etc variables.

CALLED BY:	CallStyleCallBack.
PASS:		ss:bp	= pointer to TOC_vars structure.
		es	= segment address of locked font block.
RETURN:		TOC_currentFieldHgt set.
		all up to date.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Basically we are going with the following algorithm:
		field <- max( font, field );

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/10/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFieldHeightVars	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter

	clr	si				; change flag

	call	GetHeightAndBaseline
	;
	; ax.bl = height
	; cx.bh = baseline
	;
	; Need to get the acsent/descent.
	;
	sub	bl, bh
	sbb	ax, cx				; ax.bl = descent
						; cx.bh = ascent
	;
	; Check for a change to the descent.
	; If the descent is larger the height gets changed.
	;
	call	CalcDescent			; di.dl = descent
	
	;
	; di.dl = current descent.
	;
	cmp	ax, di
	jb	noDescChange
	ja	descChange
	cmp	bl, dl
	jbe	noDescChange
descChange:
	sub	bl, dl				; ax.bl = amount of change.
	sbb	ax, di

	addwbf	internals.TOCI_currentHgt, axbl

	inc	si				; signal change

noDescChange:
	;
	; Handle ascent (baseline offset) change.
	;
	call	CalcAscent			; di.dl <- ascent

	cmpwbf	cxbh, didl
	jbe	noBloChange

	movwbf	internals.TOCI_currentBlo, cxbh

	subwbf	cxbh, didl			; cx.bh = change in ascent

	addwbf	internals.TOCI_currentHgt, cxbh	; Update the height

	inc	si				; signal change

noBloChange:

	tst	si
	jz	noChange
	;
	; Either the descent or ascent has changed. Regardless, the line
	; height will change so we need to 
	;
	movwbf	axbl, internals.TOCI_currentHgt	; get current height
NOFXIP<	call	externals.TOCE_heightCallback				>
FXIP<	mov	ss:[TPD_dataBX], bx					>
FXIP<	mov	ss:[TPD_dataAX], ax					>
FXIP<	movdw	bxax, externals.TOCE_heightCallback			>
FXIP<	call	ProcCallFixedOrMovable					>
	call	FixupGStateNukeNothing
noChange:

	andnf	ss:[bp].TMS_flags, not mask TMSF_STYLE_CHANGED
	.leave
	ret
UpdateFieldHeightVars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHeightAndBaseline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the adjusted height and adjusted baseline of the font.

CALLED BY:	
PASS:		es	= segment address of the font.
RETURN:		ax.bl	= height (WBFixed).
		cx.bh	= baseline (WBFixed).
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHeightAndBaseline	proc	near
	movwbf	axbl, ss:[bp].TMS_styleHeight
	movwbf	cxbh, ss:[bp].TMS_styleBaseline
	ret
GetHeightAndBaseline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHeightAndBaseline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the height and baseline of a font.

CALLED BY:	
PASS:		es	= segment address of the font.
		ss:bp	= TOC_vars structure on stack.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHeightAndBaseline	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	;
	; First set the style height/baseline for the current style.
	;
	movwbf	axbl, es:FB_height
	addwbf	axbl, es:FB_heightAdjust
	movwbf	ss:[bp].TMS_styleHeight, axbl
	
	movwbf	cxbh, es:FB_baselinePos
	addwbf	cxbh, es:FB_baseAdjust
	movwbf	ss:[bp].TMS_styleBaseline, cxbh
	
	subwbf	axbl, cxbh
	
	;
	; Now figure out if the line will get taller. We do this by figuring
	; the change in the ascent and descent.
	;
	; ax.bl	= Descent for new style
	; cx.bh	= Ascent for new style
	;
	; If the line height will change with this new style, we need to
	; call the callback to adjust the areaToFill based on the new height.
	;
	
	;
	; Compute the larger of the old/new descents and put it in cx.bh
	;
	call	CalcDescent		; di.dl <- old field descent

	cmpwbf	didl, axbl		; Compare old against new
	jbe	noDescentChange		; Branch if new is larger
	movwbf	axbl, didl		; ax.bl <- larger of the descents
noDescentChange:

	;
	; Compute the larger of the old/new ascents and put it in ax.bl
	;
	call	CalcAscent		; di.dl <- new ascent
	cmpwbf	didl, cxbh		; Compare old against new
	jbe	noAscentChange		; Branch if new is larger
	movwbf	cxbh, didl		; cx.bh <- larger of the ascents
noAscentChange:
	
	;
	; ax.bl	= Descent for the line
	; cx.bh	= Ascent for the line
	;
	addwbf	axbl, cxbh		; ax.bl <- new line height
	
	;
	; Compare the new line height against the old one and call the callback
	; if there is a change for the taller.
	;
	cmpwbf	axbl, internals.TOCI_currentHgt
	jbe	quit			; Branch if new height is smaller

	;
	; Either the descent or ascent has changed. Regardless, the line
	; height will change so we need to 
	;
NOFXIP<	call	externals.TOCE_heightCallback				>
FXIP<	mov	ss:[TPD_dataBX], bx					>
FXIP<	mov	ss:[TPD_dataAX], ax					>
FXIP<	movdw	bxax, externals.TOCE_heightCallback			>
FXIP<	call	ProcCallFixedOrMovable					>
	call	FixupGStateNukeNothing

quit:
	.leave
	ret
SetHeightAndBaseline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcAscent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc current ascent for the field.

CALLED BY:	SetHeightAndBaseline, UpdateFieldHeightVars
PASS:		ss:bp	= TOC_vars
RETURN:		di.dl	= ascent
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcAscent	proc	near
	movwbf	didl, internals.TOCI_currentBlo
	ret
CalcAscent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDescent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc current descent for the field.

CALLED BY:	SetHeightAndBaseline, UpdateFieldHeightVars
PASS:		ss:bp	= TOC_vars
RETURN:		di.dl	= descent
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDescent	proc	near
	movwbf	didl, internals.TOCI_currentHgt
	subwbf	didl, internals.TOCI_currentBlo
	ret
CalcDescent	endp

if PZ_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckWordStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're at the start of a word

CALLED BY:	GrTextObjCalc()
PASS:		ax - current character
		bx - previous character
RETURN:		carry - set if word start
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckWordStart		proc	near
	;
	; Check for anything + Kinsoku start --> not word start
	;
		call	CheckKinsokuStart
		jz	notWordStart		;branch if curr kinsoku start
	;
	; Check for Kinsoku end + anything --> not word start
	;
		push	ax
		mov	ax, bx			;ax <- previous char
		call	CheckKinsokuEnd
		pop	ax
		jz	notWordStart		;branch if prev kinsoku end
	;
	; Check for anything + Japanese --> word start
	;
		call	LocalIsNonJapanese
		jz	isWordStart		;branch if curr Japanese
	;
	; Check for space + alpha --> word start
	;
		cmp	bx, C_SPACE
		je	isWordStart
	;
	; Check for Japanese + anything --> word start
	;
		push	ax
		mov	ax, bx			;ax <- previous char
		call	LocalIsNonJapanese
		pop	ax
		jz	isWordStart		;branch if prev Japanese
notWordStart:
		clc				;carry <- not word start
		ret

isWordStart:
		stc				;carry <- is word start
		ret
CheckWordStart		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckWordEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're at the end of a word

CALLED BY:	GrTextObjCalc()
PASS:		ax - current character
		bx - previous character
RETURN:		carry - set if word end
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckWordEnd		proc	near
	;
	; Check for Kinsoku end + anything --> not word end
	;
		push	ax
		mov	ax, bx			;ax <- previous character
		call	CheckKinsokuEnd
		pop	ax
		jz	notWordEnd		;branch if prev kinsoku end
	;
	; Check for anything + Kinsoku start --> not word end
	;
		call	CheckKinsokuStart
		jz	notWordEnd		;branch if curr kinsoku start
	;
	; Check for Japanese + anything --> word end
	;
		push	ax
		mov	ax, bx			;ax <- previous character
		call	LocalIsNonJapanese
		pop	ax
		jz	isWordEnd		;branch if prev Japanese
	;
	; Check alpha + space --> word end
	;
		cmp	ax, C_SPACE
		je	isWordEnd		;branch if curr space
	;
	; Check for anything + Japanese --> word end
	;
		call	LocalIsNonJapanese
		jz	isWordEnd		;branch if curr Japanese
notWordEnd:
		clc				;carry <- not word end
		ret

isWordEnd:
		stc				;carry <- word end
		ret
CheckWordEnd		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckKinsokuStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for Japanese character that cannot start a line

CALLED BY:	GrTextObjCalc()
PASS:		ax - character to check
RETURN:		z flag - set (je) if character is kinsoku
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckKinsokuStart		proc	near
		push	di
		mov	di, offset kinsokuStartChars
		GOTO	CheckKinsokuCommon, di
CheckKinsokuStart		endp

CheckHack <(offset kinsokuStartChars) eq (offset kinsokuStartLength)+2>
ForceRef kinsokuStartLength


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckKinsokuEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for Japanese character that cannot end a line

CALLED BY:	GrTextObjCalc()
PASS:		ax - character to check
RETURN:		z flag - set (je) if character is kinsoku
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckKinsokuEnd		proc	near
		push	di
		mov	di, offset kinsokuEndChars
		FALL_THRU	CheckKinsokuCommon, di
CheckKinsokuEnd		endp

CheckHack <(offset kinsokuEndChars) eq (offset kinsokuEndLength)+2>
ForceRef kinsokuEndLength


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckKinsokuCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to check for a kinsoku character

CALLED BY:	CheckKinsokuStart(), CheckKinsokuEnd()
PASS:		ax - character to check
		di - offset table of kinsoku characters
			*preceded by* length (ie. offset-2)
		on stack:
			saved di
RETURN:		z flag - set (je) if character is kinsoku
DESTROYED:	di

PSEUDO CODE/STRATEGY:
	Should the characters be in localizable chunks?  On one hand, it
	makes this more flexible.  On the other, it will slow it down
	a lot, and these routines are designed around Japanese text,
	so making the characters localizable may not be sufficient in
	any event.

	For more details on kinsoku characters, see Ken Lunde's
	"Understanding Japanese Information Processing", page 148.

	The basic idea is that there are certain characters that should
	not begin a line, and certain characters that should not end
	a line.  Rather than doing word-wrapping at the end of the line
	based on word breaks, lines are broken at character boundaries.
	If the break occurs such that a kinsoku end character would appear
	at the end of a line, or a kinsoku start character at the start,
	additional characters are moved down from the previous line until
	the situation is no longer true.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckKinsokuCommon		proc	near
		uses	es, cx
		.enter

		FastLoadVarSeg	es
		tst	es:kinsokuDisabled	;0=enabled, else=disabled
		jnz	dontCheck
		tst	di			;clear Z flag
EC <		ERROR_Z GASP_CHOKE_WHEEZE				>
		mov	cx, es:[di][-2]		;cx <- length of table
		repne	scasw
dontCheck:
		.leave
		FALL_THRU_POP	di
		ret
CheckKinsokuCommon		endp


endif
