COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonLineInfo.asm

AUTHOR:		John Wedgwood, Dec 31, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/31/91	Initial revision

DESCRIPTION:
	Routines for getting data from LineInfo structures.

	$Id: tlCommonLineInfo.asm,v 1.1 97/04/07 11:21:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCommonLineValidateStructures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check line structures to make sure they're OK.

CALLED BY:	ECLargeLineValidateStructures, ECSmallLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Start of line
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

     --------------------LF_STARTS_PARAGRAPH--------------------
	If line starts paragraph
	    Starting offset must be 0
	    	or
	    Previous character must be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK
	else
	    Starting offset must not be 0
	        and
	    Previous character must not be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK

     --------------------LF_ENDS_PARAGRAPH--------------------
	If line ends paragraph
	    (Ending offset must be last character in text stream
	     Line must be last line)
	    	or
	    Last character of line must be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK
	else
	    Ending offset must not be last character in text stream
	    	and
	    Line must not be last line
	    	and
	    Last character of line must not be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK

     --------------------LF_ENDS_IN_CR--------------------
	if line ends in CR
	    Last character of line must be CR
	    Line flags must contain LF_ENDS_PARAGRAPH
	    Line can not be last in object
	    Line start can not be at end of text
	    None of these can be set:
		LF_ENDS_IN_COLUMN_BREAK
		LF_ENDS_IN_SECTION_BREAK
		LF_ENDS_IN_NULL
	else
	    Last character of line must not be CR

     --------------------LF_ENDS_IN_COLUMN_BREAK--------------------
	if line ends in COLUMN_BREAK
	    Last character of line must be COLUMN_BREAK
	    Line flags must contain LF_ENDS_PARAGRAPH
	    Line must be last line in column
	    Line can not be last in object
	    Line start can not be at end of text
	    None of these can be set:
		LF_ENDS_IN_CR
		LF_ENDS_IN_SECTION_BREAK
		LF_ENDS_IN_NULL
	else
	    Last character of line must not be COLUMN_BREAK

     --------------------LF_ENDS_IN_SECTION_BREAK--------------------
	if line ends in SECTION_BREAK
	    Last character of line must be SECTION_BREAK
	    Line flags must contain LF_ENDS_PARAGRAPH
	    Line must be last line in section
	    Line can not be last in object
	    Line start can not be at end of text
	    None of these can be set:
		LF_ENDS_IN_CR
		LF_ENDS_IN_COLUMN_BREAK
		LF_ENDS_IN_NULL
	else
	    Last character of line must not be SECTION_BREAK
	    Line must not be last line in section

     --------------------LF_ENDS_IN_NULL--------------------
	if line ends in NULL
	    Offset of end of line must be at end of text stream
	    Line must be last line in object
	    Line flags must contain LF_ENDS_PARAGRAPH
	    None of these can be set:
		LF_ENDS_IN_CR
		LF_ENDS_IN_COLUMN_BREAK
		LF_ENDS_IN_SECTION_BREAK
	else
	    Line must not be last line in object

     --------------------LF_ENDS_IN_OPTIONAL_HYPHEN--------------------
	if line ends in optional-hyphen
	    Last char on line must be optional-hyphen
	else
	    Last char on line must not be optional-hyphen


	--------------------SPECIAL CHECKS--------------------
	First line must contain:
		LF_STARTS_PARAGRAPH

	Last line must contain:
		LF_ENDS_PARAGRAPH
		LF_ENDS_IN_NULL

	No line can contain a CR, COLUMN_BREAK, or SECTION_BREAK character
	as anything but the last character on the line.
	
	A line must contain either:
		a) Exactly the same number of TAB characters as there
		   are fields, if the first character on the line is a
		   TAB.

		b) One less TAB character than there are fields, if the
		   first character on the line is not a TAB.

	Field checks:
		A field may begin with a TAB, but may not contain a
		TAB character anywhere else.

		The positions of the fields must be in ascending order.
		
		Only the tab-reference for the first field can contain:
			RULER_TAB_TO_LINE_LEFT
			RULER_TAB_TO_LEFT_MARGIN
			RULER_TAB_TO_PARA_MARGIN

		If a tab-reference contains OTHER_INTRINSIC_TAB, then
		all fields beyond it must contain the same reference.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCommonLineValidateStructures	proc	far
	uses	ax, bx, cx, dx, di, si, bp, es, ds
	pushf
info	local	ECLineValidationInfo
	.enter	inherit
	
	;
	; Check the start paragraph bit.
	;
	mov	bx, offset cs:CheckStartParagraph
	test	es:[di].LI_flags, mask LF_STARTS_PARAGRAPH
	jnz	validateStartPara
	mov	bx, offset cs:CheckNotStartParagraph
validateStartPara:
	call	bx

	;
	; Check the end paragraph bit.
	;
	mov	bx, offset cs:CheckEndParagraph
	test	es:[di].LI_flags, mask LF_ENDS_PARAGRAPH
	jnz	validateEndPara
	mov	bx, offset cs:CheckNotEndParagraph
validateEndPara:
	call	bx

	;
	; Check the end in cr bit.
	;
	mov	bx, offset cs:CheckEndInCR
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR
	jnz	validateEndCR
	mov	bx, offset cs:CheckNotEndInCR
validateEndCR:
	call	bx

	;
	; Check the end in column-break bit.
	;
	mov	bx, offset cs:CheckEndInColumnBreak
	test	es:[di].LI_flags, mask LF_ENDS_IN_COLUMN_BREAK
	jnz	validateEndColumnBreak
	mov	bx, offset cs:CheckNotEndInColumnBreak
validateEndColumnBreak:
	call	bx

	;
	; Check the end in section-break bit.
	;
	mov	bx, offset cs:CheckEndInSectionBreak
	test	es:[di].LI_flags, mask LF_ENDS_IN_SECTION_BREAK
	jnz	validateEndSectionBreak
	mov	bx, offset cs:CheckNotEndInSectionBreak
validateEndSectionBreak:
	call	bx

	;
	; Check the ends in null bit.
	;
	mov	bx, offset cs:CheckEndInNull
	test	es:[di].LI_flags, mask LF_ENDS_IN_NULL
	jnz	validateEndNull
	mov	bx, offset cs:CheckNotEndInNull
validateEndNull:
	call	bx

	;
	; Check the ends in opt-hyphen bit.
	;
	mov	bx, offset cs:CheckEndInOptionalHyphen
	test	es:[di].LI_flags, mask LF_ENDS_IN_OPTIONAL_HYPHEN
	jnz	validateEndOptionalHyphen
	mov	bx, offset cs:CheckNotEndInOptionalHyphen
validateEndOptionalHyphen:
	call	bx
	
	;
	; If this is the first line, then make sure that it has the right
	; flags set.
	;
	call	CheckFirstLine
	
	;
	; If this is the last line, then make sure that it has the right
	; flags set.
	;
	call	CheckLastLine
	
	;
	; Do standard line/field checking
	;
	call	StandardLineAndFieldCheck

	.leave
	popf
	ret
ECCommonLineValidateStructures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckStartParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line actually starts a paragraph

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY
	    Starting offset must be 0
	    	or
	    Previous character must be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckStartParagraph	proc	near
	uses	ax, dx
	.enter	inherit	ECCommonLineValidateStructures
	;
	; If the line-start is zero, then this line really does 
	; start a paragraph
	;
	tstdw	dxax
	jz	quit			; Branch if at start of text
	
	;
	; It's not at the start of the text. Get the character before
	; the line start and make sure it's a paragraph ending character
	;
	decdw	dxax			; dx.ax <- character before line
	call	TS_GetCharAtOffset	; ax <- character at the offset
	
	LocalCmpChar ax, C_CR
	je	quit
	LocalCmpChar ax, C_COLUMN_BREAK
	je	quit
	LocalCmpChar ax, C_SECTION_BREAK
	je	quit
	
	;
	; The character preceding the line is not a paragraph-ending
	; character.
	;	Stack frame = "info" (of type) ECLineValidationInfo
	;
	ERROR	CHAR_PRECEDING_LINE_SHOULD_BE_PARAGRAPH_ENDING_CHARACTER

quit:
	.leave
	ret
CheckStartParagraph	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotStartParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line does not actually start a paragraph

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Starting offset must not be 0
	        and
	    Previous character must not be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotStartParagraph	proc	near
	uses	ax, dx
	.enter	inherit	ECCommonLineValidateStructures

	;
	; The offset of the line can not be zero.
	;
	tstdw	dxax
	ERROR_Z	OFFSET_OF_ZERO_IMPLIES_THAT_LINE_MUST_START_A_PARAGRAPH
	
	;
	; The line can not be the first one
	;
	tstdw	info.ECLVI_line
	ERROR_Z	LINE_NUMBER_OF_ZERO_IMPLIES_THAT_LINE_MUST_START_A_PARAGRAPH

	;
	; It's not at the start of the text. Get the character before
	; the line start and make sure it's not a paragraph ending character
	;
	decdw	dxax			; dx.ax <- character before line
	call	TS_GetCharAtOffset	; ax <- character at the offset
	
	LocalCmpChar ax, C_CR
	je	error
	LocalCmpChar ax, C_COLUMN_BREAK
	je	error
	LocalCmpChar ax, C_SECTION_BREAK
	je	error
	jmp	quit

error:
	;
	; The character preceding the line is a paragraph-ending
	; character.
	;	Stack frame = "info" (of type) ECLineValidationInfo
	;
	ERROR	CHAR_PRECEDING_LINE_SHOULD_NOT_BE_PARAGRAPH_ENDING_CHARACTER

quit:
	.leave
	ret
CheckNotStartParagraph	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEndParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line actually ends a paragraph

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    (Ending offset must be last character in text stream
	    	and
	     Line must be last line)
	    	or
	    Last character of line must be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEndParagraph	proc	near
	uses	ax, bx, cx, dx
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Get the size of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size of text
	cmpdw	dxax, info.ECLVI_lineStart	; Check for line at end
	je	lineAtEndOfText			; Branch if it is
	
	;
	; If this is the last line, then we should expect that it will
	; end in a NULL.
	;
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line
	cmpdw	dxax, info.ECLVI_line		; Check for last line
	jne	checkLastChar
	
	;
	; It's the last line, therefore it must end in a NULL (which means
	; we don't need to, and actually can't check the last character).
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_NULL
	ERROR_Z	LAST_LINE_MUST_END_IN_NULL
	
	jmp	quit

checkLastChar:
	;
	; Make sure that the character at the end actually is a paragraph
	; ending character.
	;
	call	GetLastChar			; ax <- last char on line
	jc	quit				; Branch if empty line
	call	CheckParaEndingCharacter
	ERROR_NE CHAR_AT_END_OF_LINE_SHOULD_BE_PARAGRAPH_ENDING_CHARACTER

quit:
	.leave
	ret

lineAtEndOfText:
	;
	; The line is at the end of the text. Check:
	;	- LF_ENDS_IN_NULL
	;	- Only one field
	;	- Number of chars in that field is 0
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_NULL
	ERROR_Z	EMPTY_LINE_AT_END_OF_TEXT_MUST_END_IN_NULL
	
	cmp	cx, size LineInfo
	ERROR_NE EMPTY_LINE_AT_END_OF_TEXT_MUST_HAVE_ONLY_ONE_FIELD
	
	tst	es:[di].LI_firstField.FI_nChars
	ERROR_NZ EMPTY_LINE_AT_END_OF_TEXT_CAN_NOT_HAVE_A_FIELD_WITH_TEXT_IN_IT
	
	jmp	quit
	
CheckEndParagraph	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotEndParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line does not actually end a paragraph

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Ending offset must not be last character in text stream
	    	and
	    Line must not be last line
	    	and
	    Last character of line must not be one of:
	    	CR, COLUMN_BREAK, SECTION_BREAK

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotEndParagraph	proc	near
	uses	ax, bx, cx, dx
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Get the size of the text and make sure the line doesn't start
	; at the end of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size of text
	cmpdw	dxax, info.ECLVI_lineStart	; Check for line at end
	ERROR_Z	LINE_AT_END_OF_TEXT_MUST_END_A_PARAGRAPH
	
	;
	; Make sure that the line isn't the last line in the text.
	;
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line
	cmpdw	dxax, info.ECLVI_line		; Check for last line
	ERROR_Z	LAST_LINE_MUST_END_A_PARAGRAPH

	;
	; Make sure that the character at the end is not a paragraph
	; ending character.
	;
	call	GetLastChar			; ax <- last character
	jc	quit				; Branch if empty line

	call	CheckParaEndingCharacter
	ERROR_E CHAR_AT_END_OF_LINE_SHOULD_NOT_BE_PARAGRAPH_ENDING_CHARACTER
quit:
	.leave
	ret
CheckNotEndParagraph	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEndInCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line actually ends in a CR

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Line flags must contain LF_ENDS_PARAGRAPH
	    None of these can be set:
		LF_ENDS_IN_COLUMN_BREAK
		LF_ENDS_IN_SECTION_BREAK
		LF_ENDS_IN_NULL
	    Line start can not be at end of text
	    Line can not be last in object
	    Last character of line must be CR

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEndInCR	proc	near
	uses	ax, dx
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Check that it ends a paragraph
	;
	test	es:[di].LI_flags, mask LF_ENDS_PARAGRAPH
	ERROR_Z	LINE_THAT_ENDS_IN_CR_MUST_ALSO_END_PARAGRAPH
	
	;
	; Check for illegal flag combinations
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_SECTION_BREAK or \
				  mask LF_ENDS_IN_NULL
	ERROR_NZ ONLY_ONE_OF_THE_ENDSIN_LINE_FLAGS_CAN_BE_SET_AT_ONE_TIME

	;
	; Get the size of the text and make sure the line doesn't start
	; at the end of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size of text
	cmpdw	dxax, info.ECLVI_lineStart	; Check for line at end
	ERROR_Z	LINE_AT_END_OF_TEXT_CAN_NOT_END_IN_CR
	
	;
	; Make sure that the line isn't the last line in the text.
	;
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line
	cmpdw	dxax, info.ECLVI_line		; Check for last line
	ERROR_Z	LAST_LINE_CAN_NOT_END_IN_CR
	
	;
	; Check that the last character is actually a CR
	;
	call	GetLastChar			; ax <- last character
	jc	quit				; Branch if empty line

	LocalCmpChar ax, C_CR
	ERROR_NZ LAST_CHARACTER_IS_NOT_A_CR_AND_IT_SHOULD_BE
quit:
	.leave
	ret
CheckEndInCR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotEndInCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line does not actually ends in a CR

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Last character of line must not be CR

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotEndInCR	proc	near
	uses	ax
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Grab the last character and check it
	;
	call	GetLastChar			; ax <- last character
	jc	quit				; Branch if empty line

	cmp	ax, C_CR
	ERROR_Z	LAST_CHARACTER_IS_A_CR_AND_IT_SHOULD_NOT_BE
quit:
	.leave
	ret
CheckNotEndInCR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEndInColumnBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line actually ends in a column-break

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Line flags must contain LF_ENDS_PARAGRAPH
	    None of these can be set:
		LF_ENDS_IN_CR
		LF_ENDS_IN_SECTION_BREAK
		LF_ENDS_IN_NULL
	    Line start can not be at end of text
	    Line can not be last in object
	    Last character of line must be COLUMN_BREAK
	    Line must be last line in column

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEndInColumnBreak	proc	near
	uses	ax, bx, cx, dx, di
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Check that it ends a paragraph
	;
	test	es:[di].LI_flags, mask LF_ENDS_PARAGRAPH
	ERROR_Z	LINE_THAT_ENDS_IN_COLUMN_BREAK_MUST_ALSO_END_PARAGRAPH

	;
	; Check for illegal flag combinations
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_SECTION_BREAK or \
				  mask LF_ENDS_IN_NULL
	ERROR_NZ ONLY_ONE_OF_THE_ENDSIN_LINE_FLAGS_CAN_BE_SET_AT_ONE_TIME

	;
	; Get the size of the text and make sure the line doesn't start
	; at the end of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size of text
	cmpdw	dxax, info.ECLVI_lineStart	; Check for line at end
	ERROR_Z	LINE_AT_END_OF_TEXT_CAN_NOT_END_IN_COLUMN_BREAK
	
	;
	; Make sure that the line isn't the last line in the text.
	;
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line
	cmpdw	dxax, info.ECLVI_line		; Check for last line
	ERROR_Z	LAST_LINE_CAN_NOT_END_IN_COLUMN_BREAK
	
	;
	; Check that the last character is actually a column-break
	;
	call	GetLastChar			; ax <- last character
	jc	afterCheck			; Branch if empty line

	LocalCmpChar ax, C_COLUMN_BREAK
	ERROR_NZ LAST_CHARACTER_IS_NOT_A_COLUMN_BREAK_AND_IT_SHOULD_BE
afterCheck:
	
	;
	; Check that the line is actually the last in it's column
	;
	movdw	bxdi, info.ECLVI_line		; bx.di <- line
	call	TR_RegionFromLine		; cx <- region of line
	mov	ax, cx				; Save region of current line
	
	incdw	bxdi				; bx.di <- next line
	call	TR_RegionFromLine		; cx <- region of next line
	
	;
	; If this line truly ends in a column break then the difference
	; between the region of the next line and the region of the
	; current line *must* be 1.
	;
	sub	cx, ax				; cx <- 1 if the world is good
	cmp	cx, 1
	ERROR_NZ REGION_OF_NEXT_LINE_DOES_NOT_FOLLOW_IMMEDIATELY_AFTER_REGION_OF_LINE_ENDING_IN_COLUMN_BREAK
	.leave
	ret
CheckEndInColumnBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotEndInColumnBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line does not actually end in a column-break

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Last character of line must not be COLUMN_BREAK

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotEndInColumnBreak	proc	near
	uses	ax
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Grab the last character and check it
	;
	call	GetLastChar			; ax <- last character
	jc	quit				; Branch if empty line

	cmp	ax, C_COLUMN_BREAK
	ERROR_Z	LAST_CHARACTER_IS_A_COLUMN_BREAK_AND_IT_SHOULD_NOT_BE
quit:
	.leave
	ret
CheckNotEndInColumnBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEndInSectionBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line actually ends in a section-break

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Line flags must contain LF_ENDS_PARAGRAPH
	    None of these can be set:
		LF_ENDS_IN_CR
		LF_ENDS_IN_COLUMN_BREAK
		LF_ENDS_IN_NULL
	    Line start can not be at end of text
	    Line can not be last in object
	    Last character of line must be SECTION_BREAK
	    Line must be last line in section

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEndInSectionBreak	proc	near
	uses	ax, bx, cx, dx, di
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Check that it ends a paragraph
	;
	test	es:[di].LI_flags, mask LF_ENDS_PARAGRAPH
	ERROR_Z	LINE_THAT_ENDS_IN_SECTION_BREAK_MUST_ALSO_END_PARAGRAPH

	;
	; Check for illegal flag combinations
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_NULL
	ERROR_NZ ONLY_ONE_OF_THE_ENDSIN_LINE_FLAGS_CAN_BE_SET_AT_ONE_TIME

	;
	; Get the size of the text and make sure the line doesn't start
	; at the end of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size of text
	cmpdw	dxax, info.ECLVI_lineStart	; Check for line at end
	ERROR_Z	LINE_AT_END_OF_TEXT_CAN_NOT_END_IN_SECTION_BREAK
	
	;
	; Make sure that the line isn't the last line in the text.
	;
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line
	cmpdw	dxax, info.ECLVI_line		; Check for last line
	ERROR_Z	LAST_LINE_CAN_NOT_END_IN_SECTION_BREAK
	
	;
	; Check that the last character is actually a column-break
	;
	call	GetLastChar			; ax <- last character
	jc	afterCheck			; Branch if empty line

	LocalCmpChar ax, C_SECTION_BREAK
	ERROR_NZ LAST_CHARACTER_IS_NOT_A_SECTION_BREAK_AND_IT_SHOULD_BE
afterCheck:
	
	;
	; Check that the line is actually the last in it's section
	;
	movdw	bxdi, info.ECLVI_line		; bx.di <- line
	call	TR_RegionFromLine		; cx <- region of line
	mov	ax, cx				; Save region of current line
	
	incdw	bxdi				; bx.di <- next line
	call	TR_RegionFromLine		; cx <- region of next line
	
	;
	; The region numbers must differ.
	;
	cmp	cx, ax
	ERROR_BE REGION_OF_NEXT_LINE_DOES_NOT_FOLLOW_AFTER_REGION_OF_LINE_ENDING_IN_SECTION_BREAK

	;
	; The regions do differ. Make sure that the region for the line is
	; actually the last one in its section.
	;
	mov	cx, ax				; cx <- region of line
	call	TR_RegionIsLastInSection
	ERROR_NC LINE_ENDING_IN_SECTION_BREAK_IS_NOT_IN_LAST_REGION_OF_SECTION
	
	;
	; It is the last region of the section. Make sure it's not the last
	; region of them all, since it couldn't possibly end in a section
	; break if it was.
	;
	ERROR_Z	LINE_ENDING_IN_SECTION_BREAK_CAN_NOT_BE_IN_VERY_LAST_REGION
	.leave
	ret
CheckEndInSectionBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotEndInSectionBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line does not actually end in a section-break

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Last character of line must not be SECTION_BREAK
	    Line must not be last line in section

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotEndInSectionBreak	proc	near
	uses	ax, bx, cx, di
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Grab the last character and check it
	;
	call	GetLastChar			; ax <- last character
	jc	afterCheck			; Branch if empty line

	cmp	ax, C_SECTION_BREAK
	ERROR_Z	LAST_CHARACTER_IS_A_SECTION_BREAK_AND_IT_SHOULD_NOT_BE
afterCheck:

	;
	; Check for the line being the last in it's column
	;
	movdw	bxdi, info.ECLVI_line		; bx.di <- line
	call	TR_RegionFromLine		; cx <- region of line
	mov	ax, cx				; Save region of current line
	
	incdw	bxdi				; bx.di <- next line
	call	TR_RegionFromLine		; cx <- region of next line
	
	cmp	ax, cx
	je	quit				; Branch if not last in column
	
	;
	; The line is the last in its column. Make sure that the region
	; is not the last in the section.
	;
	xchg	cx, ax				; cx <- region of line
						; ax <- next region
	call	TR_RegionIsLastInSection
	jnc	quit				; branch if not last in section
	ERROR_NZ LAST_LINE_IN_SECTION_MUST_END_IN_SECTION_BREAK
	
quit:
	.leave
	ret
CheckNotEndInSectionBreak	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEndInNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line actually ends in a NULL

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Line flags must contain LF_ENDS_PARAGRAPH
	    None of these can be set:
		LF_ENDS_IN_CR
		LF_ENDS_IN_COLUMN_BREAK
		LF_ENDS_IN_SECTION_BREAK
	    Offset of end of line must be at end of text stream
	    Line must be last line in object

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEndInNull	proc	near
	uses	ax, bx, cx, dx
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Check that it ends a paragraph
	;
	test	es:[di].LI_flags, mask LF_ENDS_PARAGRAPH
	ERROR_Z	LINE_THAT_ENDS_IN_NULL_MUST_ALSO_END_PARAGRAPH

	;
	; Check for illegal flag combinations
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_SECTION_BREAK
	ERROR_NZ ONLY_ONE_OF_THE_ENDSIN_LINE_FLAGS_CAN_BE_SET_AT_ONE_TIME

	;
	; Get the size of the text and check for the line starting at
	; the end of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size of text

	cmpdw	dxax, info.ECLVI_lineStart	; Check for line at end
	je	skipNullCheck
	
	pushdw	dxax				; Save offset to end of text 
	call	GetOffsetPastLineEnd		; dx.ax <- offset past line end
	popdw	bxcx				; Restore offset to end of text

	cmpdw	dxax, bxcx			; Line end must be at text end
	ERROR_NZ LINE_ENDING_IN_NULL_MUST_END_AT_END_OF_TEXT
	
skipNullCheck:

	;
	; Check that it is the last line
	;
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line
	cmpdw	dxax, info.ECLVI_line		; Check for last line
	ERROR_NZ LINE_WHICH_ENDS_IN_NULL_MUST_BE_LAST_LINE
	.leave
	ret
CheckEndInNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotEndInNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line does not actually end in a NULL

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	    Line must not be last line in object

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotEndInNull	proc	near
	uses	ax, bx, cx, dx
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Get the size of the text and check for the line starting at
	; the end of the text.
	;
	call	TS_GetTextSize			; dx.ax <- size of text
	pushdw	dxax				; Save offset to end of text

	cmpdw	dxax, info.ECLVI_lineStart	; Check for line at end
	ERROR_E	LINE_THAT_DOES_NOT_END_IN_NULL_CAN_NOT_START_AT_TEXT_END
	
	call	GetOffsetPastLineEnd		; dx.ax <- offset past line end

	popdw	bxcx				; Restore offset to end of text
	cmpdw	dxax, bxcx		     ; Line end must not be at text end
	;
	; This check turns out not to be correct. If the line is 
	; the next-to-last line, and if the last line is empty, the
	; end of this line *will* fall at the end of the text.
	;
;;;	ERROR_Z LINE_THAT_DOES_NOT_END_IN_NULL_CAN_NOT_END_AT_END_OF_TEXT
	
	;
	; Check that it is not the last line
	;
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line
	cmpdw	dxax, info.ECLVI_line		; Check for last line
	ERROR_Z	LINE_WHICH_DOES_NOT_END_IN_NULL_CAN_NOT_BE_LAST_LINE
	.leave
	ret
CheckNotEndInNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEndInOptionalHyphen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line actually ends in an optional-hyphen

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEndInOptionalHyphen	proc	near
	uses	ax
	.enter	inherit	ECCommonLineValidateStructures
	;
	; It is possible for a line to end in an optional hyphen and also
	; for that line to end in a line-break character. This special case
	; allows opt-hyphens to appear at the end of lines ending in line-
	; break characters so the user knows that it is there.
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_SECTION_BREAK
	jnz	quit
		
	;
	; Grab the last character and check it
	;
	call	GetLastChar			; ax <- last character
	jc	quit				; Branch if empty line

SBCS <	cmp	ax, C_OPTHYPHEN						>
DBCS <	cmp	ax, C_SOFT_HYPHEN					>
	ERROR_NZ LAST_CHARACTER_IS_NOT_AN_OPTIONAL_HYPHEN_AND_IT_SHOULD_BE
quit:
	.leave
	ret
CheckEndInOptionalHyphen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNotEndInOptionalHyphen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the line does not actually end in an optional-hyphen

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNotEndInOptionalHyphen	proc	near
	uses	ax
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Grab the last character and check it
	;
	call	GetLastChar			; ax <- last character
	jc	quit				; Branch if empty line

SBCS <	cmp	ax, C_OPTHYPHEN						>
DBCS <	cmp	ax, C_SOFT_HYPHEN					>
	ERROR_Z	LAST_CHARACTER_IS_AN_OPTIONAL_HYPHEN_AND_IT_SHOULD_NOT_BE
quit:
	.leave
	ret
CheckNotEndInOptionalHyphen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFirstLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do special checking for the first line.

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	- Must start a paragraph

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFirstLine	proc	near
	.enter	inherit	ECCommonLineValidateStructures
	
	tstdw	info.ECLVI_line			; Check for on first line
	jnz	quit				; Branch if not
	
	test	es:[di].LI_flags, mask LF_STARTS_PARAGRAPH
	ERROR_Z	FIRST_LINE_MUST_START_A_PARAGRAPH
quit:
	.leave
	ret
CheckFirstLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLastLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do special checking for the last line

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLastLine	proc	near
	uses	ax, dx
	.enter	inherit	ECCommonLineValidateStructures
	
	call	TL_LineGetCount			; dx.ax <- # of lines
	decdw	dxax				; dx.ax <- last line

	cmpdw	dxax, info.ECLVI_line		; Check for on last line
	jne	quit				; Branch if not
	
	test	es:[di].LI_flags, mask LF_ENDS_PARAGRAPH
	ERROR_Z	LAST_LINE_MUST_END_A_PARAGRAPH
	
	test	es:[di].LI_flags, mask LF_ENDS_IN_NULL
	ERROR_Z	LAST_LINE_MUST_END_IN_NULL
	
	;
	; The last line can not end in a <cr>, column, or section break
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_SECTION_BREAK
	ERROR_NZ LAST_LINE_CAN_NOT_END_IN_CR_OR_COLUMNxSECTION_BREAK
quit:
	.leave
	ret
CheckLastLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StandardLineAndFieldCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do standard checking that affects every line.

CALLED BY:	ECCommonLineValidateStructures
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + fields
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	No line can contain a CR, COLUMN_BREAK, or SECTION_BREAK character
	as anything but the last character on the line.
	
	A line must contain either:
		a) Exactly the same number of TAB characters as there
		   are fields, if the first character on the line is a
		   TAB.

		b) One less TAB character than there are fields, if the
		   first character on the line is not a TAB.

	Field checks:
		A field may begin with a TAB, but may not contain a
		TAB character anywhere else.

		The positions of the fields must be in ascending order.
		
		Only the tab-reference for the first field can contain:
			RULER_TAB_TO_LINE_LEFT
			RULER_TAB_TO_LEFT_MARGIN
			RULER_TAB_TO_PARA_MARGIN

		If a tab-reference contains OTHER_INTRINSIC_TAB, then
		all fields beyond it must contain the same reference.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StandardLineAndFieldCheck	proc	near
	uses	bx, cx, dx
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Check the characters inside the line to make sure that none of
	; them are <cr> or a break character
	;
	call	CheckCharactersInternalToLine
	
	;
	; Check each field
	;
	add	cx, di				; cx <- offset past last field
	lea	bx, es:[di].LI_firstField
	clr	dx				; Signal: no previous field
	mov	ax, -1				; Signal: no previous field
fieldLoop:
	call	CheckField			; Check the field

	add	bx, size FieldInfo		; es:bx <- next field
	cmp	bx, cx				; Check for finished
	jne	fieldLoop			; Branch if not

	.leave
	ret
StandardLineAndFieldCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCharactersInternalToLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the set of characters internal to a line does not
		contain <cr> or a break character (also checking for NULL)

CALLED BY:	StandardLineAndFieldCheck
PASS:		*ds:si	= Instance
		es:di	= Line
		cx	= Size of line + field
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCharactersInternalToLine	proc	near
	uses	ax, bx, cx, dx, di
	.enter	inherit	ECCommonLineValidateStructures
	
	call	GetOffsetPastLineEnd		; dx.ax <- end of line
	
	;
	; Check for empty line
	;
	cmpdw	dxax, info.ECLVI_lineStart
	je	endLoop				; Branch if empty
	
	;
	; Don't check the very last character if it's a line terminator.
	;
	test	es:[di].LI_flags, mask LF_ENDS_IN_CR or \
				  mask LF_ENDS_IN_COLUMN_BREAK or \
				  mask LF_ENDS_IN_SECTION_BREAK
	jz	useLastChar
	decdw	dxax				; dx.ax <- end of line
useLastChar:

	subdw	dxax, info.ECLVI_lineStart	; dx.ax <- # of chars in line
	movdw	bxdi, dxax			; bx.di <- # of chars in line

;-----------------------------------------------------------------------------
	movdw	dxax, info.ECLVI_lineStart	; dx.ax <- line start
checkLoop:
	;
	; Check for no more characters
	;
	tstdw	bxdi
	jz	endLoop				; Branch if no more chars

	;
	; Lock down the text and scan for the wrong characters
	;
	; *ds:si= Instance
	; dx.ax	= Offset to lock text at
	; bx.di	= # of chars left in line
	;
	pushdw	dxax				; Save offset
	pushdw	dssi				; Save instance
	call	TS_LockTextPtr			; ds:si <- ptr to the text
						; ax <- # after the ptr
						; cx <- # before the ptr
	mov	cx, ax				; cx <- # after

	;
	; Compute the number of characters to check
	;
	tst	bx				; Check for >64K
	jnz	checkChars

	cmp	cx, di				; Use minimum of lineSize
	jbe	checkChars			;    and number available
	mov	cx, di

checkChars:
	call	CheckLegalInnerLineCharacters

	mov	ax, ds				; ax <- segment of text
	popdw	dssi				; Restore instance

	;
	; Release the locked text
	;
	call	TS_UnlockTextPtr		; Release text at ax:***
	popdw	dxax				; Restore offset

	;
	; Advance past the locked text
	;
	; *ds:si= Instance
	; bx.di	= # of chars left to do *before* we entered this loop
	; dx.ax	= Offset we were looking at
	; cx	= Number of characters we checked
	;
	sub	di, cx				; bx.di <- # left to check
	sbb	bx, 0
	
	add	ax, cx				; dx.ax <- offset to next hunk
	adc	dx, 0

	jmp	checkLoop			; Loop to do next piece
;-----------------------------------------------------------------------------

endLoop:
	.leave
	ret
CheckCharactersInternalToLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that a field is valid.

CALLED BY:	StandardLineAndFieldCheck
PASS:		*ds:si	= Instance
		es:di	= Line
		es:bx	= Field
		cx	= Offset past last field
		dx	= Position of previous field (0 for none)
		ax	= TabReference for previous field (-1 for none)
		ss:bp	= Inheritable stack frame
			ECLVI_lineStart as offset to current field
RETURN:		dx	= Position of this field
		ax	= TabReference for this field
			ECLVI_lineStart as offset to next field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Field checks:
		A field may begin with a TAB, but may not contain a
		TAB character anywhere else.

		The positions of the fields must be in ascending order.
		
		Only the tab-reference for the first field can contain:
			RULER_TAB_TO_LINE_LEFT
			RULER_TAB_TO_LEFT_MARGIN
			RULER_TAB_TO_PARA_MARGIN

		If a tab-reference contains OTHER_INTRINSIC_TAB, then
		all fields beyond it must contain the same reference.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckField	proc	near
	uses	ax, bx, cx, dx, di, si, ds
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Make sure that the position of the current field is beyond that
	; of the previous field.
	;
	cmp	es:[bx].FI_position, dx
	ERROR_B FIELD_POSITION_IS_NOT_BEYOND_PREVIOUS_FIELD_POSITION

	mov	dx, es:[bx].FI_position

	;
	; If this is not the last field on the line, make sure that the
	; current position, plus the field width, does not exceed the
	; position of the next field.
	;
	sub	cx, size FieldInfo
	cmp	cx, bx
	je	skipNextFieldCheck
	
	push	dx				; Save position
	add	dx, es:[bx].FI_width		; dx <- end of field
	
	cmp	dx, es:[bx][size FieldInfo].FI_position
	ERROR_A	FIELD_POSITION_PLUS_FIELD_WIDTH_IS_BEYOND_NEXT_FIELD_POSITION
	pop	dx				; Restore position

skipNextFieldCheck:
	
	;
	; Check that if the previous field contained an intrinsic tab
	; that we do as well.
	;
	cmp	ax, OTHER_INTRINSIC_TAB or (TRT_OTHER shl offset TR_TYPE)
	jne	skipIntrinsicTabCheck
	cmp	es:[bx].FI_tab, al
	ERROR_NE PREVIOUS_FIELD_CONTAINS_INTRINSIC_TAB_AND_CURRENT_ONE_DOES_NOT

skipIntrinsicTabCheck:
	
	;
	; Check for the first character in the field being a TAB if the field
	; is not the first one on the line.
	;
	lea	ax, es:[di].LI_firstField
	cmp	ax, bx
	je	doFirstFieldCheck		; Branch if first field

	;
	; Is not the first field, check for TAB being first character
	;
	movdw	dxax, info.ECLVI_lineStart	; dx.ax <- offset to field
	call	TS_GetCharAtOffset		; ax <- character at field start
	LocalCmpChar ax, C_TAB
	ERROR_NE FIRST_CHAR_OF_ALL_FIELDS_AFTER_THE_FIRST_MUST_BE_A_TAB
	
	;
	; The tab-reference for any field other than the first can not
	; contain RULER_TAB_TO_LINE_LEFT
	;
	cmp	es:[bx].FI_tab, RULER_TAB_TO_LINE_LEFT
	ERROR_Z	ONLY_FIRST_FIELD_CAN_CONTAIN_RULER_TAB_TO_LINE_LEFT

afterFieldCheck:
	
	;
	; Update the line start and return the position and tab reference.
	;
	mov	ax, es:[bx].FI_nChars
	add	info.ECLVI_lineStart.low, ax
	adc	info.ECLVI_lineStart.high, 0

	mov	al, es:[bx].FI_tab
	mov	dx, es:[bx].FI_position
	.leave
	ret

;-----------------------------------------------------------------------------

doFirstFieldCheck:
	;
	; The first field must have:
	;		RULER_TAB_TO_LINE_LEFT
	;
	; or else it must start with a TAB
	;
	cmp	es:[bx].FI_tab, RULER_TAB_TO_LINE_LEFT
	je	checkNoTab
	
	;
	; The first field must start with a TAB
	;
	movdw	dxax, info.ECLVI_lineStart
	call	TS_GetCharAtOffset
	LocalCmpChar ax, C_TAB
	ERROR_NZ FIRST_FIELD_MUST_START_WITH_TAB_IF_NOT_RULER_TAB_TO_LINE_LEFT

	jmp	afterFieldCheck

checkNoTab:
	;
	; The first field starts with RULER_TAB_TO_LINE_LEFT and therefore
	; can not have a TAB as the first character.
	;
	movdw	dxax, info.ECLVI_lineStart
	call	TS_GetCharAtOffset
	LocalCmpChar ax, C_TAB
	ERROR_Z	FIELD_SET_TO_RULER_TAB_TO_LINE_LEFT_CAN_NOT_START_WITH_TAB
	
	jmp	afterFieldCheck

CheckField	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckParaEndingCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that a character (in al) is a paragraph ending character

CALLED BY:	Utility
PASS:		ax	= Character
RETURN:		zero set (Z, E) if it is a paragraph ending character
		zero clear (NZ, NE) otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckParaEndingCharacter	proc	near
	LocalCmpChar ax, C_CR
	je	quit
	LocalCmpChar ax, C_COLUMN_BREAK
	je	quit
	LocalCmpChar ax, C_SECTION_BREAK
	je	quit

quit:
	ret
CheckParaEndingCharacter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the last character on the line

CALLED BY:	Utility
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
		es:di	= Line
		cx	= Size of line + fields
RETURN:		carry set if line is an empty one
		ax	= Last character on line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLastChar	proc	near
	uses	dx
	.enter	inherit	ECCommonLineValidateStructures
	
	call	GetOffsetPastLineEnd		; dx.ax <- offset past line
	
	;
	; Check for empty line
	;
	cmpdw	dxax, info.ECLVI_lineStart
	je	emptyLine

	;
	; dx.ax	= Offset past the end of the line, move backwards to examine
	; 	  the previous character.
	;
	decdw	dxax				; dx.ax <- previous char
	
	call	TS_GetCharAtOffset		; ax <- char at end of line
	clc					; Signal: not empty
quit:
	.leave
	ret

emptyLine:
	stc					; Signal: empty
	jmp	quit
GetLastChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOffsetPastLineEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset past the end of the line

CALLED BY:	Utility
PASS:		es:di	= Line
		cx	= Size of line + fields
		ss:bp	= Inheritable stack frame
RETURN:		dx.ax	= Offset past end of line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOffsetPastLineEnd	proc	near
	uses	bx, cx, di
	.enter	inherit	ECCommonLineValidateStructures
	;
	; Compute the offset to the last character in the line
	;
	movdw	dxax, info.ECLVI_lineStart	; Get line start

	add	cx, di				; cx <- offset past last field
	lea	bx, es:[di].LI_firstField	; es:bx <- first field
addLoop:
	add	ax, es:[bx].FI_nChars		; dx.ax <- offset past field
	adc	dx, 0
	
	add	bx, size FieldInfo		; es:bx <- next field
	cmp	bx, cx				; Check for past end
	jne	addLoop				; Loop to add in next field
	
	.leave
	ret
GetOffsetPastLineEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLegalInnerLineCharacters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that a set of characters does not contain any
		characters which are not legal inside a line.

CALLED BY:	CheckCharactersInternalToLine
PASS:		ds:si	= Text to check
		cx	= Number of chars to check
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLegalInnerLineCharacters	proc	near
	uses	ax, cx, si
	.enter	inherit	ECLargeLineValidateStructures
	
	jcxz	endLoop				; Branch if none to check
checkLoop:
	;
	; ds:si	= Current character to check
	; cx	= Number to check
	;
	LocalGetChar ax, dssi			; al <- char to check

	call	CheckIllegalInnerLineChar	; Check the character
	ERROR_C	ILLEGAL_CHARACTER_FOUND_INSIDE_LINE

	loop	checkLoop			; Loop to check next char
endLoop:
	.leave
	ret
CheckLegalInnerLineCharacters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIllegalInnerLineChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that a character is legal inside a line.

CALLED BY:	CheckLegalInnerLineCharacters
PASS:		ax	= Character to check
RETURN:		carry set if the character is not legal
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIllegalInnerLineChar	proc	near
	LocalCmpChar ax, C_CR
	je	error
	LocalCmpChar ax, C_COLUMN_BREAK
	je	error
	LocalCmpChar ax, C_SECTION_BREAK
	je	error
	LocalIsNull ax
	je	error

	clc					; Signal: char OK
quit:
	ret

error:
	stc					; Signal: char not OK
	jmp	quit
CheckIllegalInnerLineChar	endp


endif

TextFixed	ends
