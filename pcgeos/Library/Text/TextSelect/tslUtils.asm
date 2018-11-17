COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tslUtils.asm

AUTHOR:		John Wedgwood, Dec  9, 1991

ROUTINES:
	Name			Description
	----			-----------
	IsClassGroupEdge
	ClassGroupUnderPoint
	IsWordEdge
	FindNextWordEdge
	FindWordEdgeBackwardsCXBX
	FindWordEdgeBackwards
	FindWordEdgeForwardsCXBX
	FindWordEdgeForwards
	FindPreviousWordEdge
	WordUnderPoint
	FindParagraphEdgeBackwardsCXBX
	FindParagraphEdgeBackwards
	FindParagraphEdgeForwardsCXBX
	FindParagraphEdgeForwards
	IsParagraphEdge

GLBL	TSL_IsParagraphStart
GLBL	TSL_IsParagraphEnd
GLBL	TSL_FindParagraphStart
GLBL	TSL_FindParagraphEnd
GLBL	TSL_ConvertOffsetToCoordinate

	ParagraphUnderPoint
	FindPreviousParagraphEdge
	FindNextParagraphEdge
	IsTextEnd
	IsBeyondTextEnd
	FindNextLineEdge
	FindPreviousLineEdge
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/ 9/91	Initial revision

DESCRIPTION:
	Utility routines to assist in word/line/paragraph selection.

	$Id: tslUtils.asm,v 1.1 97/04/07 11:20:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_IsParagraphStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for offset being at start of paragraph

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= Position to check
RETURN:		carry	= Set if position starts a paragraph
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- A paragraph end is any position preceded by paragraph break
	  character.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_IsParagraphStart	proc	far
	uses	ax, bx, dx
	.enter
	tstdw	dxax			; Check for start of text
	stc				; Assume it is
	jz	quit			; Branch if at start (is para start)

	decdw	dxax			; Move to previous offset

	mov	bx, CC_PARAGRAPH_BOUNDARY
	call	TS_IsCharAtOffsetInClass

	stc				; Assume prev is para-break
	jnz	quit			; Branch if it is

	clc				; Signal: prev is not paragraph break
quit:
	.leave
	ret
TSL_IsParagraphStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_IsParagraphEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for offset being at the end of a paragraph

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= Position to check
RETURN:		carry	= set if position ends a paragraph
		zero	= set if position is the end of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- A paragraph end is any position followed by a paragraph break
	  character.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_IsParagraphEnd	proc	far
	uses	bx, cx
	.enter
	;
	; Check for being at the end of the text
	;
	movdw	cxbx, dxax		; cx.bx <- offset to check
	call	TS_GetTextSize		; dx.ax <- last valid offset

	cmpdw	dxax, cxbx		; Check for at end
	movdw	dxax, cxbx		; Restore offset to check (flags OK)

	stc				; Assume we are at end of text
	je	quit			; Branch if we are (z=1, c=1)

	;
	; Check character at current offset
	;
	mov	bx, CC_PARAGRAPH_BOUNDARY
	call	TS_IsCharAtOffsetInClass
	stc				; Assume current is para break
	jnz	quit			; Branch if it is (z=0, c=1)

	clr	bx
	cmp	bx, 1			; clear zero flag
	clc				; Signal: not paragraph end
quit:
	.leave
	ret
TSL_IsParagraphEnd	endp

TextFixed	ends


PrintMessage <JOHN: Check resource segmentation here>
TextSelect segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsClassGroupEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a position lie on the boundary between characters of
		a given class and characters which are not.

CALLED BY:	IsWordEdge, IsParagraphEdge
PASS:		*ds:si	= Instance ptr
		bx	= CharacterClass
		dx.ax	= Offset to check
RETURN:		carry set if this is an edge.
			zero flag set   (z)  if the edge is to the right.
			zero flag clear (nz) if the edge is to the left.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsClassGroupEdge	proc	near
	uses	ax, cx, dx
	.enter
	;
	; Make quick checks for being at the start or end of the text.
	;
	tstdw	dxax				; Check for nothing to the left
	jz	edgeRight			; Branch if at text start

	call	IsTextEnd			; carry set if dx.ax is at end
	jc	edgeLeft			; Branch if at text end

	;
	; That's all the easy stuff. Now we need to actually look at the text.
	; First check to see if the character we are on is not of the class.
	;
	call	TS_IsCharAtOffsetInClass	; Zero clear (nz) if in class
	jz	checkPrevInClass		; Branch if not in class

	;
	; Next char is in the class.
	; Check to see if the previous character is not in the class.
	; (ie: edge on left edge of group, group is to the right).
	;
	decdw	dxax				; Move to previous character
	call	TS_IsCharAtOffsetInClass	; Zero clear (nz) if in class
	jz	edgeRight			; Branch if not in class
	
	;
	; Both the current character and the previous character are in the
	; class. Therefore this isn't an edge.
	;
	jmp	notEdge				; Not on an edge

checkPrevInClass:
	;
	; Next char is not in the class, check to see if previous character
	; is in the class.
	; (ie: edge on right edge of group, group is to the left).

	decdw	dxax				; Move to previous character
	call	TS_IsCharAtOffsetInClass	; Zero clear (nz) if in class
	jnz	edgeLeft			; Group is to our right.

notEdge:
	clc					; Signal: not an edge
	jmp	done

edgeRight:
	;
	; Set the 'zero' flag to indicate that the group is on the left
	;
	xor	ax, ax
	jmp	isEdge

edgeLeft:
	;
	; Clear the 'zero' flag to indicate that the group is on the right
	;
	xor	ax, ax
	dec	ax

isEdge:
	stc					; Signal: is an edge

done:
	.leave
	ret
IsClassGroupEdge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClassGroupUnderPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the group of characters of a given class at a position.

CALLED BY:	WordUnderPoint, ParagraphUnderPoint
PASS:		*ds:si	= Instance ptr
		bp/bx	= Group boundary. 
			  The start of the group is a position with a
			  character of class <bp> followed by a character
			  of class <bx>.
			  The end of the group is a position with a
			  character of class <bx> followed by a character
			  of class <bp>.
		dx.ax	= Position
RETURN:		dx.ax	= Start of group
		cx.bx	= End of group
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClassGroupUnderPoint	proc	near
	uses	bp
	.enter
	call	IsClassGroupEdge		; Check for on an edge
	jnc	inGroup

	;
	; We are on a group edge, zero flag tells which way the group starts.
	;
	mov	bx, bp
	jz	groupOnRight

	;
	; Group on the left side.
	;
	pushdw	dxax				; Save original position (end)
	call	TS_PrevCharInClass		; dx.ax <- before group start
	jc	gotPrev				; Branch if no previous
	incdw	dxax				; Else move forward past it
gotPrev:
	popdw	cxbx				; cx.bx <- group end
	jmp	done

groupOnRight:
	;
	; Group on the right side.
	;
	pushdw	dxax				; Save original position (start)
	call	TS_NextCharInClass		; dx.ax <- group end
	movdw	cxbx, dxax			; cx.bx <- group end
	popdw	dxax				; dx.ax <- group start
	jmp	done

inGroup:
	;
	; The position is inside either a group of characters of the given
	; class or else is inside a group of characters not of the given class.
	;
	call	TS_IsCharAtOffsetInClass	; Is dx.ax in class <bx> ?
	jz	gotClass
	mov	bx, bp				; bx <- "not in class" class
gotClass:
	
	pushdw	dxax				; Save original position
	call	TS_NextCharInClass		; dx.ax <- group end

	
	movdw	cxbp, dxax			; Save group end
	popdw	dxax				; Restore original position

	call	TS_PrevCharInClass		; dx.ax <- group start
	jc	gotPrev2			; Branch if no previous
	incdw	dxax				; Else move forward past it
gotPrev2:
	mov	bx, bp				; cx.bx <- group end

done:
	.leave
	ret
ClassGroupUnderPoint	endp
if	WINDOWS_STYLE_CURSOR_KEYS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindStartOfPrevWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the start of the previous word in the text

CALLED BY:	GLOBAL
PASS:		dx.ax - current position
		*ds:si - instance ptr
RETURN:		dx.ax - position of start of previous word
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindStartOfPrevWord	proc	near
	.enter

notAtWordEdge:
	call	FindPreviousWordEdge
	tstdw	dxax		;If we are at the start of the text, just get
	jz	exit		; out...
	call	IsWordEdge
EC <	ERROR_NC	COULD_NOT_FIND_WORD_EDGE			>
	jnz	notAtWordEdge	;Branch back up if we are not at the *left*
				; edge of a word yet.
exit:
	.leave
	ret
FindStartOfPrevWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindStartOfNextWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the start of the previous word in the text

CALLED BY:	GLOBAL
PASS:		dx.ax - current position
		*ds:si - instance ptr
RETURN:		dx.ax - position of start of previous word
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindStartOfNextWord	proc	near	uses	bx, cx
	.enter
	movdw	bxcx, dxax
	call	TS_GetTextSize
	xchgdw	bxcx, dxax	;BX.CX <- text size		

notAtWordEdge:
	call	FindNextWordEdge
	cmpdw	bxcx, dxax	;If we are at the end of the text, just get
	jz	exit		; out...
	call	IsWordEdge
EC <	ERROR_NC	COULD_NOT_FIND_WORD_EDGE			>
	jnz	notAtWordEdge	;Branch back up if we are not at the *left*
				; edge of a word yet.
exit:
	.leave
	ret
FindStartOfNextWord	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsWordEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Is a position on a word boundary?

CALLED BY:	AdjustToWordEdges(2), WordUnderPoint
PASS:		*ds:si	= Instance ptr
		dx.ax	= position to check.
RETURN:		carry set if this is a word edge.
			zero flag set if the word-edge is to the right.
			zero flag clear if the word-edge is to the left.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsWordEdge	proc	near
	uses	bx
	.enter
if DBCS_PCGEOS
	call	TS_GetWordPartAtOffset
	mov	bl, CC_WORD_PART_MISMATCH
	call	IsClassGroupEdge
	jnc	notWordEdge
	;
	; If we are at a word edge (which in DBCS is the transition
	; between runs of the same WordPartType), give preference
	; to WPT_SPACE and non-WPT_SPACE transitions in the appropriate
	; direction; otherwise to the right:
	;
	;	WPT_SPACE	not WPT_SPACE	=> right (Z)
	;	not WPT_SPACE	WPT_SPACE	=> left  (NZ)
	;	not WPT_SPACE	not WPT_SPACE	=> right (Z)
	;
	cmp	bh, WPT_SPACE			;current char space?
	je	wordEdgeLeft			;yes, word edge to left
	clr	bl				;set Z flag (JZ) below
wordEdgeLeft:
	tst	bl				;clear Z flag (JNZ) (if bl!=0)
		CheckHack <CC_WORD_PART_MISMATCH ne 0>
wordEdge:
	stc					;carry <- word edge
notWordEdge:

else
	mov	bx, CC_WORD_PART
	call	IsClassGroupEdge
endif
	.leave
	ret
IsWordEdge	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextWordEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next edge of a word.

CALLED BY:	AdjustToWordEdges, VTFDeleteWord, VTFForwardWord,
		VTFSelectAdjustForwardWord, WordUnderPoint(2)

PASS:		ds:*si	= instance ptr.
		dx.ax	= Offset to position to search from.
RETURN:		dx.ax	= Offset to next word edge.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextWordEdge	proc	near
	uses	bx
	.enter
if DBCS_PCGEOS
	;
	; We want to skip to the next character of a different WordPartType
	;
	call	TS_GetWordPartAtOffset		; bh <- WordPartType
	mov	bl, CC_WORD_PART_MISMATCH
	call	TS_NextCharInClass

else
	mov	bx, CC_WORD_PART
	call	TS_IsCharAtOffsetInClass	; Zero clear (nz) if word part
	jnz	skipToNonWordPart
	;
	; The current character is not part of a word. We want to skip until
	; we get to a character that is part of a word.
	;
	call	TS_NextCharInClass
	jmp	quit

skipToNonWordPart:
	;
	; The current character is part of a word. We want to skip until
	; we get to a character that is not part of a word.
	;
	mov	bx, CC_NOT_WORD_PART
	call	TS_NextCharInClass

quit:

endif
	.leave
	ret
FindNextWordEdge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindWordEdgeBackwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a word edge moving backwards in the text if needed.

CALLED BY:	SelectByModeWord
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
RETURN:		dx.ax	= Offset where a word edge was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindWordEdgeBackwardsCXBX	proc	near
	xchgdw	dxax, cxbx		; dx.ax <- offset to move from
					; cx.bx <- saved dx.ax
	call	FindWordEdgeBackwards
	xchgdw	dxax, cxbx		; dx.ax <- saved dx.ax
					; cx.bx <- offset to return
	ret
FindWordEdgeBackwardsCXBX	endp

FindWordEdgeBackwards	proc	near
	call	IsWordEdge		; Is this a word edge?
	jc	gotWordEdge		; Branch if it is
	call	FindPreviousWordEdge	; dx.ax <- next word edge
gotWordEdge:
	ret
FindWordEdgeBackwards	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindWordEdgeForwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a word edge moving forwards in the text if needed.

CALLED BY:	SelectByModeWord
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
RETURN:		dx.ax	= Offset where a word edge was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindWordEdgeForwardsCXBX	proc	near
	xchgdw	dxax, cxbx		; dx.ax <- offset to move from
					; cx.bx <- saved dx.ax
	call	FindWordEdgeForwards
	xchgdw	dxax, cxbx		; dx.ax <- saved dx.ax
					; cx.bx <- offset to return
	ret
FindWordEdgeForwardsCXBX	endp


FindWordEdgeForwards	proc	near
	call	IsWordEdge		; Is this a word edge?
	jc	gotWordEdge		; Branch if it is
	call	FindNextWordEdge	; dx.ax <- next word edge
gotWordEdge:
	ret
FindWordEdgeForwards	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPreviousWordEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the previous edge of a word.

CALLED BY:	AdjustToWordEdges, VTFBackwardWord, VTFDeleteBackwardWord,
		VTFSelectAdjustBackwardWord, WordUnderPoint(2)

PASS:		ds:*si	= instance ptr.
		dx.ax	= Offset to start looking from
RETURN:		dx.ax	= Offset of previous word edge
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPreviousWordEdge	proc	near
	uses	bx
	.enter
	tstdw	dxax				; Check for at text object start
	jz	quit				; Branch if at start

	decdw	dxax				; Check prev character
if DBCS_PCGEOS
	;
	; We want to skip to the previous char of a different WordPartType
	;
	call	TS_GetWordPartAtOffset
	mov	bl, CC_WORD_PART_MISMATCH
	call	TS_PrevCharInClass
	jc	gotPrev				; Branch if no previous
	incdw	dxax				; Else move forward past it
gotPrev:

else
	mov	bx, CC_WORD_PART
	call	TS_IsCharAtOffsetInClass	; Zero clear (nz) if word part
	jnz	skipToNonWordPart

	;
	; The current character is not part of a word. We want to skip until
	; we get to a character that is part of a word.
	;
	call	TS_PrevCharInClass
	jc	gotPrev				; Branch if no previous
	incdw	dxax				; Else move forward past it
gotPrev:
	jmp	quit

skipToNonWordPart:
	;
	; The current character is part of a word. We want to skip until
	; we get to a character that is not part of a word.
	;
	mov	bx, CC_NOT_WORD_PART
	call	TS_PrevCharInClass
	jc	gotPrev2			; Branch if no previous
	incdw	dxax				; Else move forward past it
gotPrev2:

endif

quit:

	.leave
	ret
FindPreviousWordEdge	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WordUnderPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the word under a given position.

CALLED BY:	AdjustToWordEdges, VisTextStartSelect
PASS:		*ds:si	= Instance ptr
		dx.ax	= position
RETURN:		dx.ax	= Start of word range
		cx.bx	= End of word range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
WordUnderPoint	proc	far
	uses	bp
	.enter
	mov	bp, CC_NOT_WORD_PART		; This class followed by...
	mov	bx, CC_WORD_PART		; ...this class
	call	ClassGroupUnderPoint
	.leave
	ret
WordUnderPoint	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindParagraphEdgeBackwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a paragraph edge moving backwards in the text if needed.

CALLED BY:	SelectByModePara
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
RETURN:		dx.ax	= Offset where a paragraph edge was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindParagraphEdgeBackwardsCXBX	proc	near
	xchgdw	dxax, cxbx		; dx.ax <- offset to move from
					; cx.bx <- saved dx.ax
	call	FindParagraphEdgeBackwards
	xchgdw	dxax, cxbx		; dx.ax <- saved dx.ax
					; cx.bx <- offset to return
	ret
FindParagraphEdgeBackwardsCXBX	endp

FindParagraphEdgeBackwards	proc	near
	call	IsParagraphEdge			; Is this a paragraph edge?
	jc	gotParaEdge			; Branch if it is
	call	FindPreviousParagraphEdge	; dx.ax <- next paragraph edge
gotParaEdge:
	ret
FindParagraphEdgeBackwards	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindParagraphEdgeForwards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a paragraph edge moving forwards in the text if needed.

CALLED BY:	SelectByModePara
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
RETURN:		dx.ax	= Offset where a paragraph edge was found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindParagraphEdgeForwardsCXBX	proc	far
	xchgdw	dxax, cxbx		; dx.ax <- offset to move from
					; cx.bx <- saved dx.ax
	call	FindParagraphEdgeForwards
	xchgdw	dxax, cxbx		; dx.ax <- saved dx.ax
					; cx.bx <- offset to return
	ret
FindParagraphEdgeForwardsCXBX	endp


FindParagraphEdgeForwards	proc	far
	call	IsParagraphEdge		; Is this a paragraph edge?
	jc	gotParaEdge		; Branch if it is
	call	FindNextParagraphEdge	; dx.ax <- next paragraph edge
gotParaEdge:
	ret
FindParagraphEdgeForwards	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsParagraphEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Is a position on a paragraph boundary?

CALLED BY:	FindParagraphEdgeForwards, FindParagraphEdgeBackwards
PASS:		*ds:si	= Instance ptr
		dx.ax	= Position to check
RETURN:		carry set if this is a paragraph edge.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsParagraphEdge	proc	near
	uses	bx
	.enter
	;
	; If the previous character is a paragraph-boundary or the first
	; (or last) character in the text then this is a paragraph boundary.
	;
	tstdw	dxax				; Check for start of text
	jz	isParagraphEdge			; Branch if at start

	call	IsTextEnd			; Are we at the end of text?
	jc	isParagraphEdge			; Branch if at end

	;
	; Move to previous character and check there.
	;
	pushdw	dxax
	decdw	dxax				; Move to previous offset
	mov	bx, CC_PARAGRAPH_BOUNDARY
	call	TS_IsCharAtOffsetInClass
	popdw	dxax

	jnz	isParagraphEdge			; Branch if prev = para-boundary
	
	clc					; Signal: not paragraph edge
quit:
	.leave
	ret

isParagraphEdge:
	stc
	jmp	quit
IsParagraphEdge	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_FindParagraphStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the beginning of the paragraph containing the given
		position.  A paragraph start is any position preceded by
		a paragraph-break character.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= Position to start from
		carry	= set to return position passed if it is the start
			  of a paragraph
RETURN:		dx.ax	= Position that begins paragraph
		carry set if dx.ax == 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- A paragraph start is any position preceded by a paragraph-break
	  character.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_FindParagraphStart	proc	far
	uses	bx
	.enter

	pushf
	pop	bx				; bx = flags

	tstdw	dxax				; Check for at start
	stc					; Assume we are
	jz	quit				; Branch if we are

	;
	; We are in a strange predicament... If the character before the 
	; current one is a paragraph boundary then we want to scan backwards
	; to get to the boundary before it. Otherwise we will fall through
	; and increment the offset and poof we will be back where we started.
	;
	; If it's not then we can scan backwards from before that point anyway.
	; The result is that we just decrement the offset here and then start
	; scanning.
	;
	test	bx, mask CPU_CARRY
	jnz	10$
	decdw	dxax				; Move to previous offset
10$:

	mov	bx, CC_PARAGRAPH_BOUNDARY
	call	TS_PrevCharInClass		; dx.ax <- paragraph start
	jc	quit				; Branch if one was not found
	incdw	dxax				; Else move to start of para
	clc					; Signal: not at start
quit:
	.leave
	ret
TSL_FindParagraphStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_FindParagraphEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the end of the next starting containing the given
		position.  A paragraph end is any position followed by
		a paragraph-break character.  If the position passed is the
		end of a paragraph then it will be returned.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= Position to start from
RETURN:		dx.ax	= Position that ends paragraph
		carry set if dx.ax == end of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- A paragraph end is any position followed by a paragraph break
	  character.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_FindParagraphEnd	proc	far
	uses	bx
	.enter

	mov	bx, CC_PARAGRAPH_BOUNDARY	; Find this type of character
	call	TS_NextCharInClass		; dx.ax <- next character
						; carry set if none
	;
	; The only way that there can be no more characters of this class
	; is if we have reached the end of the text. This is just what we
	; want to return.
	;
	.leave
	ret
TSL_FindParagraphEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParagraphUnderPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the paragraph under a given point.

CALLED BY:	AdjustToParagraphEdges, VTFDeleteParagraph,
		VTFSelectParagraph, VisTextStartSelect

PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start looking at
RETURN:		dx.ax	= Start of paragraph
		cx.bx	= End of paragraph
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParagraphUnderPoint	proc	near
	uses	bp
	.enter
	mov	bp, CC_PARAGRAPH_BOUNDARY	; This class followed by...
	mov	bx, CC_ANYTHING			; ...this class
	call	ClassGroupUnderPoint
	
	;
	; See if the end of the range is followed by a paragraph boundary
	; character. If it is, include that character.
	;
	xchgdw	dxax, cxbx			; dx.ax <- end, cx.bx <- start
	
	push	bx				; Save low word of start
	mov	bx, CC_PARAGRAPH_BOUNDARY
	call	TS_IsCharAtOffsetInClass	; <nz> if it is...
	jz	noParaBoundary
	incdw	dxax
noParaBoundary:
	pop	bx				; Restore low word of start
	
	xchgdw	dxax, cxbx			; Restore start/end
	.leave
	ret
ParagraphUnderPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPreviousParagraphEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the previous paragraph edge.

CALLED BY:	VTFBackwardParagraph, VTFSelectAdjustBackwardParagraph
PASS:		*ds:si	= instance ptr.
		dx.ax	= Offset to start looking from
RETURN:		dx.ax	= Offset of previous paragraph edge
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPreviousParagraphEdge	proc	near
	clc
	call	TSL_FindParagraphStart		; dx.ax <- start of paragraph
	ret
FindPreviousParagraphEdge	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextParagraphEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next paragraph edge.

CALLED BY:	VTFForwardParagraph, VTFSelectAdjustForwardParagraph
PASS:		*ds:si	= Instance ptr.
		dx.ax	= Offset to start looking from
RETURN:		dx.ax	= Offset of next paragraph edge
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextParagraphEdge	proc	near
	call	TSL_FindParagraphEnd		; dx.ax <- paragraph end
	jc	quit				; Branch if none found
	incdw	dxax				; Include end of paragraph
quit:
	ret
FindNextParagraphEdge	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsTextEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a position is at the end of the text.

CALLED BY:	Utility
PASS:		dx.ax	= Position to check
RETURN:		carry set if position is at the end of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 2/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsTextEnd	proc	near
	uses	ax, bx, cx, dx
	.enter
	movdw	cxbx, dxax			; Save offset
	call	TS_GetTextSize
	cmpdw	cxbx, dxax
	je	atEnd
	clc					; Signal: not beyond
quit:
	.leave
	ret

atEnd:
	stc					; Signal: beyond
	jmp	quit
IsTextEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsBeyondTextEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a position is beyond the end of the text.

CALLED BY:	Utility
PASS:		dx.ax	= Position to check
RETURN:		carry set if position is beyond the end of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 2/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsBeyondTextEnd	proc	near
	uses	ax, bx, cx, dx
	.enter
	movdw	cxbx, dxax			; Save offset
	call	TS_GetTextSize
	cmpdw	cxbx, dxax
	ja	beyond
	clc					; Signal: not beyond
quit:
	.leave
	ret

beyond:
	stc					; Signal: beyond
	jmp	quit
IsBeyondTextEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextConvertOffsetToCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the passed offset to a document coordinate.
		If offset is beyond the end of the text, returns the
		coordinate of the last valid offset.

CALLED BY:	MSG_VIS_TEXT_CONVERT_OFFSET_TO_COORDINATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisTextClass
		ax - the message
		dx:bp - VisTextConvertOffsetParams
RETURN:		VisTextConvertOffsetParams filled in 
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextConvertOffsetToCoordinate 	proc 	far 
				; MSG_VIS_TEXT_CONVERT_OFFSET_TO_COORDINATE

		call	TextGStateCreate	; create a gstate if needed
	;
	; If passed offset is beyond the end of the text, replace the
	; offset with the last text position
	;
		mov	es, dx			; es:bp <- params
		movdw	cxbx, es:[bp].VTCOP_offset
		call	TS_GetTextSize		; dx.ax <- text size
		cmpdw	cxbx, dxax
		jae	useTextSize
		movdw	dxax, cxbx
useTextSize:		
		movdw	es:[bp].VTCOP_offset, dxax
		call	TSL_ConvertOffsetToCoordinate
		movdw	es:[bp].VTCOP_xPos, cxbx
		movdw	es:[bp].VTCOP_yPos, dxax

		call	TextGStateDestroy	; destroy gstate if
						; one was created
		ret
		
VisTextConvertOffsetToCoordinate		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_ConvertOffsetToCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an offset into the text into a coordinate.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset into the text
RETURN:		cx.bx	= X position of offset
		dx.ax	= Y position of offset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_ConvertOffsetToCoordinate	proc	near
	class	VisTextClass
	uses	bp, di
	.enter
	;
	; Allocate stack frame and get the regions top-left coordinate
	;
	sub	sp, size PointDWord		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame

	clc					; Use second line
	call	TL_LineFromOffset		; bx.di <- Line
	call	TR_RegionFromLine		; cx <- region
	call	TR_RegionGetTopLeft		; Fill in stack frame
	
	;
	; Get the relative position into cx/dx
	;
	call	TSL_ConvertOffsetToRegionAndCoordinate
						; ax <- region
						; cx <- x position
						; dx <- y position

	;
	; Update the extended position
	;
	add	ss:[bp].PD_x.low, cx
	adc	ss:[bp].PD_x.high, 0

	add	ss:[bp].PD_y.low, dx
	adc	ss:[bp].PD_y.high, 0

	;
	; Adjust for leftOffset
	;
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	mov	ax, ds:[di].VTI_leftOffset	; Adjust for left-offset
	cwd
	adddw	ss:[bp].PD_x, dxax

	;
	; Get the return values
	;
	movdw	cxbx, ss:[bp].PD_x
	movdw	dxax, ss:[bp].PD_y
	
	;
	; Restore stack
	;
	add	sp, size PointDWord
	.leave
	ret
TSL_ConvertOffsetToCoordinate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextLineEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the end of the current line.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
RETURN:		dx.ax	= Next line edge
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextLineEdge	proc	near
	uses	bx, di
	.enter
	clc				; Want last line with this offset
	call	TL_LineFromOffset	; bx.di <- line to use
	call	TL_LineToOffsetEnd	; dx.ax <- line end
	.leave
	ret
FindNextLineEdge	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPreviousLineEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the start of the current line.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
RETURN:		dx.ax	= Previous line edge
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPreviousLineEdge	proc	near
	uses	bx, di
	.enter
	stc				; Want first line with this offset
	call	TL_LineFromOffset	; bx.di <- line to use
	call	TL_LineToOffsetStart	; dx.ax <- line start
	.leave
	ret
FindPreviousLineEdge	endp

TextSelect ends

