COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsAccess.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

ROUTINES:
	Name			Description
	----			-----------
GLBL	TS_GetTextSize		Get the number of bytes of text
GLBL	TS_LockTextPtr		Get a pointer to the text into ds:si
GLBL	TS_LockTextPtrESDI	Get a pointer to the text into es:di
GLBL	TS_UnlockTextPtr	Release the text block
GLBL	TS_CheckLegalChange	Check that a change is a legal one
GLBL	TS_GetCharAtOffset	Get the character at a given offset
GLBL	TS_GetTextRange		Get a range of text into a buffer

INT	CallStorageHandler	Call a handler for small or large objects
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	Routines to access text.

	$Id: tsExternal.asm,v 1.1 97/04/07 11:22:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_CheckLegalChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that a change won't result in the size of the
		text object becoming too large.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		ss:bp	= VisTextReplaceParameters
RETURN:		carry set if the change is legal
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_CheckLegalChange	proc	far
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, TSV_CHECK_LEGAL_CHANGE
	call	CallStorageHandler
	.leave
	ret
TS_CheckLegalChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_LockTextPtrESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the text into es:di

CALLED BY:	Global
PASS:		*ds:si	= Text object instance
		dx.ax	= Offset into the text to get
RETURN:		es:di	= Pointer to text at that offset
		ax	= Number of valid characters after ptr
					(including char at ptr)
		cx	= Number of valid characters before ptr
					(including char at ptr)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_LockTextPtrESDI	proc	far	uses	ds, si
	.enter
	call	TS_LockTextPtr
	segmov	es, ds
	mov	di, si
	.leave
	ret
TS_LockTextPtrESDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_GetTextRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a range of text into a buffer.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ss:bx	= VisTextRange filled in
		ss:bp	= TextReference entirely filled in
RETURN:		dx.ax	= Number of chars actually copied
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The range must be valid and there must be characters to copy in it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_GetTextRange	proc	far
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, TSV_GET_TEXT_RANGE
	call	CallStorageHandler
	.leave
	ret
TS_GetTextRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_ReplaceRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a range of text.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_ReplaceRange	proc	far
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, TSV_REPLACE_RANGE
	call	CallStorageHandler
	.leave
	ret
TS_ReplaceRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_FindStringInText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a string in a text object.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.cx   = Offset to char in text object to begin searcn
		dx.ax	= Offset into text object of last char to include
			  in search
		es	= Segment address of SearchReplaceStruct
RETURN:		carry set if string not found
		dx.ax	= Offset to start of string found
		bp.cx	= Number of characters which matched
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_FindStringInText	proc	far	uses	di, bx
	.enter
	mov	di, TSV_FIND_STRING_IN_TEXT
	call	CallStorageHandler
	.leave
	ret
TS_FindStringInText	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallStorageHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a handling routine for a text-storage routine

CALLED BY:	TS_*
PASS:		*ds:si	= Text object instance
		di	= TextStorageVariant
		other registers set for the handler
RETURN:		registers set by the handler
		flags set by the handler
DESTROYED:	di if not returned by handler

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallStorageHandler	proc	far
	class	VisTextClass
	;
	; Choose the routine to call based on the 
	;
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si <- instance ptr
	
	;
	; Choose a table to use for calling the appropriate handler
	;
	; ds:si = Instance ptr.
	;
	test	ds:[si].VTI_storageFlags, mask VTSF_LARGE
	pop	si
	jz	smallObject			; Branch if small format
	
	add	di, offset cs:LargeStorageHandlers
	jmp	di

smallObject:
	add	di, offset cs:SmallStorageHandlers
	jmp	di

;-----------------------------------------------------------------------------
;
; These are tables of handlers for each TextStorageVariant.
; There is one table for the "small" text object and one for the "large".
;
; These tables must have entries in the same order as the definition for
; TextStorageVariant in tsConstant.def.
;
SmallStorageHandlers:
    DefTextCall	SmallReplaceRange		; REPLACE_RANGE
    DefTextCall	SmallCheckLegalChange		; CHECK_LEGAL_CHANGE
    DefTextCall	SmallGetTextRange		; GET_TEXT_RANGE
    DefTextCall	SmallFindStringInText		; FIND_STRING_IN_TEXT

EC <    DefTextCall ECSmallCheckVisTextReplaceParameters ; CHECK_PARAMS>

;   TextCallPlaceHolder	SmallGetTextSize	; GET_TEXT_SIZE
;   TextCallPlaceHolder	SmallLockTextPtr	; LOCK_TEXT_PTR
;   TextCallPlaceHolder	SmallUnlockTextPtr	; UNLOCK_TEXT_PTR
;   TextCallPlaceHolder	SmallGetCharAtOffset	; GET_CHAR_AT_OFFSET
;   TextCallPlaceHolder	SmallNextCharInClass	; NEXT_CHAR_IN_CLASS
;   TextCallPlaceHolder	SmallPrevCharInClass	; PREV_CHAR_IN_CLASS

;-----------------------------------------------------------------------------

LargeStorageHandlers:
    DefTextCall	LargeReplaceRange		; REPLACE_RANGE
    DefTextCall	LargeCheckLegalChange		; CHECK_LEGAL_CHANGE
    DefTextCall	LargeGetTextRange		; GET_TEXT_RANGE
    DefTextCall	LargeFindStringInText		; FIND_STRING_IN_TEXT

EC <    DefTextCall ECLargeCheckVisTextReplaceParameters ; CHECK_PARAMS>

;   TextCallPlaceHolder	LargeGetTextSize	; GET_TEXT_SIZE
;   TextCallPlaceHolder	LargeLockTextPtr	; LOCK_TEXT_PTR
;   TextCallPlaceHolder	LargeUnlockTextPtr	; UNLOCK_TEXT_PTR
;   TextCallPlaceHolder	LargeGetCharAtOffset	; GET_CHAR_AT_OFFSET
;   TextCallPlaceHolder	LargeNextCharInClass	; NEXT_CHAR_IN_CLASS
;   TextCallPlaceHolder	LargePrevCharInClass	; PREV_CHAR_IN_CLASS

CallStorageHandler	endp

Text	ends

;****************************************************************************
;			    Fixed Routines
;****************************************************************************

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_GetTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of bytes of text in the text object.

CALLED BY:	Global
PASS:		*ds:si	= Text object instance
RETURN:		dx.ax	= Number of bytes of text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_GetTextSize	proc	far
	class	VisTextClass
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject

	call	SmallGetTextSize
quit:
	.leave
	ret

isLargeObject:
	call	LargeGetTextSize
	jmp	quit
TS_GetTextSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_LockTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the text into ds:si

CALLED BY:	Global
PASS:		*ds:si	= Text object instance
		dx.ax	= Offset into the text to get
RETURN:		ds:si	= Pointer to text at that offset
		ax	= Number of valid characters after ptr
					(includes char at ptr)
		cx	= Number of valid characters before ptr
					(includes char at ptr)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_LockTextPtr	proc	far
	class	VisTextClass
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject

	call	SmallLockTextPtr
quit:
EC <	tst	cx							>
EC <	ERROR_Z	TS_LOCK_TEXT_PTR_INVALID_RETURN_VALUE			>
EC <	cmp	cx, 20000						>
EC <	ERROR_AE TS_LOCK_TEXT_PTR_INVALID_RETURN_VALUE			>
	.leave
	ret

isLargeObject:
	call	LargeLockTextPtr
	jmp	quit
TS_LockTextPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_UnlockTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a block of text.

CALLED BY:	Global
PASS:		*ds:si	= Text object instance
		ax	= Segment address of the text block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_UnlockTextPtr	proc	far
	class	VisTextClass
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject

	call	SmallUnlockTextPtr
quit:
	.leave
	ret

isLargeObject:
	call	LargeUnlockTextPtr
	jmp	quit
TS_UnlockTextPtr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_IsCharInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a character is in a given class.

CALLED BY:	Global
PASS:		ax	= Character
		bx	= CharacterClass
RETURN:		Zero flag clear (nz) if the character is in the class
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_IsCharInClass	proc	far
	call	IsCharInClass
	ret
TS_IsCharInClass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_IsCharAtOffsetInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the character at an offset is in a given class.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset of character
		bx	= CharacterClass
RETURN:		Zero flags clear (nz) if character at offset is in class
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_IsCharAtOffsetInClass	proc	far
	uses	ax
	.enter
	call	TS_GetCharAtOffset	; ax <- character at offset
	call	TS_IsCharInClass	; Zero flag clear (nz) if in class
	.leave
	ret
TS_IsCharAtOffsetInClass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_GetCharAtOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the character at a given offset.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset of character to get
RETURN:		ax	= Character
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_GetCharAtOffset	proc	far
	class	VisTextClass
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject

	call	SmallGetCharAtOffset
quit:
	.leave
	ret

isLargeObject:
	call	LargeGetCharAtOffset
	jmp	quit
TS_GetCharAtOffset	endp

TextFixed	ends

;----

PrintMessage <JOHN: Check resource segmentation here>
TextSelect segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_NextCharInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next character of a given class.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset of to start at
		bx	= CharacterClass
RETURN:		dx.ax	= Offset of next character of this class
		carry set if there is no next character in this
			class.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_NextCharInClass	proc	far
	class	VisTextClass
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject

	call	SmallNextCharInClass
quit:
	.leave
	ret

isLargeObject:
	call	LargeNextCharInClass
	jmp	quit
TS_NextCharInClass	endp

if DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_GetWordPartAtOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the WordPartType at the given offset

CALLED BY:	Global
PASS:		*ds:si	= instance ptr
		dx:ax	= offset of character
RETURN:		bh	= WordPartType
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_GetWordPartAtOffset		proc	far
		uses	ax
		.enter

		call	TS_GetCharAtOffset		;ax <- character
		call	LocalGetWordPartType
			CheckHack <WordPartType lt 256>
		mov	bh, al				;bh <- WordPartType

		.leave
		ret
TS_GetWordPartAtOffset		endp

endif

TextSelect ends

TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TS_PrevCharInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the previous character of a given class.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
		bx	= CharacterClass
RETURN:		dx.ax	= Offset of previous character in this class
		carry set if there is no previous character in this class
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TS_PrevCharInClass	proc	far
	class	VisTextClass
	uses	di
	.enter
EC <	call	T_AssertIsVisText			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject

	call	SmallPrevCharInClass
quit:
	.leave
	ret

isLargeObject:
	call	LargePrevCharInClass
	jmp	quit
TS_PrevCharInClass	endp

TextFixed	ends

TextObscure segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TS_GetWordCount

DESCRIPTION:	Get the word count

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	dxax - word count

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
TS_GetWordCount	proc	far	uses bx, cx, di
	.enter

	clrdw	cxdi				;counter
	clrdw	dxax				;offset

if DBCS_PCGEOS
	;
	; In DBCS "words" are runs of consecutive runs of the same
	; WordPartType.  For English, this means runs of spaces and
	; non-spaces; for Japanese it means runs of hiragana, katakana
	; and Kanji as well.
	;
	mov	bl, CC_WORD_PART_MISMATCH	;bl <- count word parts
countLoop:
	call	TS_GetWordPartAtOffset		;bh <- WordPartType
	cmp	bh, WPT_PUNCTUATION		;punctuation?
	je	notWord				;don't count punctuation
	cmp	bh, WPT_SPACE			;space?
	je	notWord				;don't count spaces
	incdw	cxdi				;cxdi <- 1 more word
notWord:
	call	TS_NextCharInClass
	jnc	countLoop			;branch if more chars

else

countLoop:
	mov	bx, CC_WORD_PART
	call	TS_NextCharInClass
	jc	done
	incdw	cxdi
	mov	bx, CC_NOT_WORD_PART
	call	TS_NextCharInClass
	jnc	countLoop

done:

endif
	movdw	dxax, cxdi

	.leave
	ret

TS_GetWordCount	endp

TextObscure ends
