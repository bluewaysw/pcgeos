COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	UI
MODULE:		Text
FILE:		textMethodSearch.asm

AUTHOR:		Andrew Wilson, Mar 29, 1991

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/91		Initial revision

DESCRIPTION:
	This module contains all the code necessary to implement search and
	replace in text objects.

	$Id: tssMethodSearch.asm,v 1.1 97/04/07 11:19:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextSearchSpell	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSetSearchInProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets bit so we know to notify the search/spell boxes if the
		user clicks/pastes/etc. in this object

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		^lCX:DX - ptr to this object (wrap back around to this object)
DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSetSearchInProgress	proc	far
				; MSG_VIS_TEXT_SET_SEARCH_IN_PROGRESS
	class	VisTextClass

	andnf	ds:[di].VTI_intFlags, not mask VTIF_ACTIVE_SEARCH_SPELL
	ornf	ds:[di].VTI_intFlags, ASST_SEARCH_ACTIVE shl offset VTIF_ACTIVE_SEARCH_SPELL
	Destroy	ax, cx, dx, bp
	ret
VisTextSetSearchInProgress	endp
VisTextSetSpellInProgress	proc	far
				; MSG_VIS_TEXT_SET_SPELL_IN_PROGRESS
	class	VisTextClass

	andnf	ds:[di].VTI_intFlags, not mask VTIF_ACTIVE_SEARCH_SPELL
	ornf	ds:[di].VTI_intFlags, ASST_SPELL_ACTIVE shl offset VTIF_ACTIVE_SEARCH_SPELL
	Destroy	ax, cx, dx, bp
	ret
VisTextSetSpellInProgress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetObjectForSearchSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method handler for
		MSG_META_GET_OBJECT_FOR_SEARCH_SPELL.

CALLED BY:	GLOBAL
PASS:		bp - GetSearchSpellObjectType
		cx:dx - this object
RETURN:		cx:dx - the object specified by the passed
			 GetSearchSpellObjectOption
DESTROYED:	ax, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetObjectForSearchSpell	proc	far
					;MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	.enter

;	We provide default functionality for the single-object case:
;
;	GSSOT_FIRST_OBJECT - this object
;	GSSOT_LAST_OBJECT - this object
;	GSSOT_NEXT_OBJECT - 0:0	(no next object)
;	GSSOT_PREV_OBJECT - 0:0 (no prev object)

	cmp	bp, GSSOT_FIRST_OBJECT
	jz	exit
	cmp	bp, GSSOT_LAST_OBJECT
	jz	exit
	clrdw	cxdx
	
exit:
	.leave
	ret
VisTextGetObjectForSearchSpell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchSpellObjMessageNear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just makes a call to ObjMessage

CALLED BY:	GLOBAL
PASS:		same as ObjMessage
RETURN:		same as ObjMessage
DESTROYED:	same as ObjMessage

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchSpellObjMessageNear	proc	near
	call	ObjMessage
	ret
SearchSpellObjMessageNear	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchSpellObjCallInstanceNoLockNear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just makes a call to ObjCallInstanceNoLock

CALLED BY:	GLOBAL
PASS:		same as ObjCallInstanceNoLock
RETURN:		same as ObjCallInstanceNoLock
DESTROYED:	same as ObjCallInstanceNoLock

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchSpellObjCallInstanceNoLockNear	proc	near
	call	ObjCallInstanceNoLock
	ret
SearchSpellObjCallInstanceNoLockNear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToLowercase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a passed character to lower case if it is alphabetic.

CALLED BY:	GLOBAL
PASS:		ax - character
RETURN:		ax - character (converted if alphabetic)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertToLowercase	proc	near
	.enter
	call	LocalDowncaseChar
	.leave
	ret
ConvertToLowercase	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToUppercase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a passed character to upper case if it is alphabetic.

CALLED BY:	GLOBAL
PASS:		ax - character
RETURN:		ax - character (converted if alphabetic)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertToUppercase	proc	near
	.enter
	call	LocalUpcaseChar
	.leave
	ret
ConvertToUppercase	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfLower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a front end to the DR_LOCAL_IS_LOWER function.

CALLED BY:	GLOBAL
PASS:		ax - char to check
RETURN:		z flag clear if is lower
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfLower	proc	near
	.enter
	call	LocalIsLower
	.leave
	ret
CheckIfLower	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfUpper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a front end to the DR_LOCAL_IS_UPPER function.

CALLED BY:	GLOBAL
PASS:		ax - char to check
RETURN:		z flag clear if is upper
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfUpper	proc	near
	.enter
	call	LocalIsUpper
	.leave
	ret
CheckIfUpper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCaseOfReplaceString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the case of the replace string (if necessary) to match
		that of the source string.

CALLED BY:	GLOBAL
PASS:		ss:di <- ptr to stack frame to store replace string
		es - ptr to this data:
			SearchReplaceStruct<>
			data	Null-Terminated Search String
			data	Null-Terminated Replace string
		BX.CX - offset into current text object to get search string
		DX.AX - # chars in source string
RETURN:		nada
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertCaseOfReplaceString	proc	near	uses	es, ds, si, cx
NO_ALPHABETIC_CHARS	equ	0
STARTS_WITH_LOWER	equ	1
STARTS_WITH_UPPER	equ	2
ALL_UPPER		equ	3
	.enter
	cmp	es:[SRS_replaceSize], 1		;If no text, just exit
	LONG jz	exit

EC <	test	es:[SRS_params], mask SO_PRESERVE_CASE_OF_DOCUMENT_STRING >
EC <	ERROR_Z	-1						>
if 0
;	Removed 3/28/94 - atw, as we no longer copy the string onto the stack
;	when doing a replace that does not preserve the case of the document
;	string.
;
	jnz	10$				;Branch if we don't want to use
						; the capitalization of the
						; replace string

	segmov	ds, es
	segmov	es, ss				;ES:DI <-ptr to dest for string
	mov	si, ds:[SRS_searchSize]
DBCS <	shl	si, 1				;# chars -> # bytes	>
	add	si, size SearchReplaceStruct	;DS:SI <- ptr to replace string
	mov	cx, ds:[SRS_replaceSize]
	dec	cx
	;JMP	straightCopy
endif


;10$:

;	We are preserving the case of the document string. We have a few cases:
;
;	1) The document string starts with lower case - convert all
;	   characters in the replace string to lower case
;
;	2) The document string starts with an upper case letter followed
;	   by lower case letters, in which case we change the first letter of
;	   the replace string to be in upper case, then downcase the rest of
;	   the bunch.
;
;	3) The document string contains no lower-case letters, in which case
;	   we convert all lower case letters in the replace string to upper
;	   case.


;	GET THE STRING WE WILL BE REPLACING

	push	bp
	sub	sp, size VisTextGetTextRangeParameters
	mov	bp, sp
	movdw	ss:[bp].VTGTRP_range.VTR_start, bxcx

;	Check either the entire document string we are replacing, or just the
;	first 60-odd chars.

	cmpdw	dxax, SEARCH_REPLACE_MAX_WORD_LENGTH
	jbe	11$
	mov	ax, SEARCH_REPLACE_MAX_WORD_LENGTH
11$:

;	AX = # chars to get from the text

	inc	ax
	sub	sp, ax
DBCS <	sub	sp, ax							>
	dec	ax

	add	cx, ax			;BX.CX <- offset to end of text we want
	adc	bx, 0

	movdw	ss:[bp].VTGTRP_range.VTR_end, bxcx
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_POINTER
	movdw	ss:[bp].VTGTRP_pointerReference, sssp
	clr	ss:[bp].VTGTRP_flags

	push	bp
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	call	SearchSpellObjCallInstanceNoLockNear
			;Returns DX.AX = # chars copied
	pop	bp
	mov_tr	cx, ax			;CX <- # chars copied

	mov	ah, NO_ALPHABETIC_CHARS
	segmov	ds, ss			;DS:SI <- source string we will be
	mov	si, sp			; replacing.
	push	bx
	mov	bh, ah			;bh = flags
nextChar:
	LocalGetChar	ax, dssi
SBCS <	clr	ah							>
	call	CheckIfLower		;If we have found a lower case
	jnz	foundLower		; character, branch.
	call	CheckIfUpper		;If we have found an upper case char,
	jz	next			; set the "found an upper case flag"
	mov	bh, STARTS_WITH_UPPER
next:
	loop	nextChar
	tst	bh			;We haven't found any lowercase chars.
	jz	done			;Branch if we didn't find uppercase
					; either.
	mov	bh, ALL_UPPER
foundLower:
	tst	bh
	jnz	done
	mov	bh, STARTS_WITH_LOWER
done:
	mov	ah, bh			;ah = flags
	pop	bx
	mov	sp, bp
	add	sp, size VisTextGetTextRangeParameters
	pop	bp
	segmov	ds, es
	segmov	es, ss				;ES:DI <-ptr to dest for string
	mov	si, ds:[SRS_searchSize]
DBCS <	shl	si, 1				;# chars -> # bytes	>
	add	si, size SearchReplaceStruct	;DS:SI <- ptr to replace string
	mov	cx, ds:[SRS_replaceSize]
	dec	cx				;-1 for null terminator
	cmp	ah, NO_ALPHABETIC_CHARS
	je	straightCopy
	cmp	ah, STARTS_WITH_LOWER		
	je	startsWithLower
	cmp	ah, ALL_UPPER
	je	allCaps

	dec	cx				;Decrement count, as we are
SBCS <	clr	ah							>
SBCS <	lodsb					; going to upcase the first>
DBCS <	lodsw					; going to upcase the first>
	call	ConvertToUppercase		; char.
SBCS <	stosb								>
DBCS <	stosw								>
	jcxz	exit



startsWithLower:
SBCS <	clr	ah							>
SBCS <	lodsb								>
DBCS <	lodsw								>
	call	ConvertToLowercase
SBCS <	stosb								>
DBCS <	stosw								>
	loop	startsWithLower
	jmp	exit

allCaps:			;Convert to all uppercase
SBCS <	clr	ah							>
SBCS <	lodsb								>
DBCS <	lodsw								>
	call	ConvertToUppercase
SBCS <	stosb								>
DBCS <	stosw								>
	loop	allCaps

exit:
	.leave
	ret

straightCopy:

;	JUST COPY OVER THE REPLACE STRING

if DBCS_PCGEOS
	rep	movsw
else
	shr	cx, 1
	jnc	5$
	movsb
5$:
	rep	movsw
endif
	jmp	exit
ConvertCaseOfReplaceString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine replaces text in the text object with the passed
		text.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
		bp:cx - offset into text object to begin replace
		dx:ax - # chars to replace
		es - ptr to this data:
			SearchReplaceStruct<>
			data	Null-Terminated Search String
			data	Null-Terminated Replace string

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: If the replaced area overlaps the selected area, the selection
       	      will be changed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoReplace	proc	near	uses	ax, bx, cx, dx, bp, di	
	class	VisTextClass
	.enter

;	Ensure that there's enough stack space for all the calls we'll make,
;	and, if we are preserving the case of the document string, to
;	contain the replace string as well...

	mov	di, 1000
	test	es:[SRS_params], mask SO_PRESERVE_CASE_OF_DOCUMENT_STRING
	jz	noStringOnStack
	add	di, es:[SRS_replaceSize]
noStringOnStack:
	call	ThreadBorrowStackSpace
	push	di

;	IF OFFSET IS WITHIN THE CURRENT SELECTION, SET SELECTION TO BE AT
;	THE BEGINNING. THIS HELPS SPELL CHECKING, WHICH WANTS TO CHECK 
;	THE JUST REPLACED WORD.

	clr	bx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmpdw	bpcx, ds:[di].VTI_selectStart
	jb	5$
	cmpdw	bpcx, ds:[di].VTI_selectEnd
	ja	5$
	mov	bl, ds:[di].VTI_intFlags
	andnf	bl, mask VTIF_ACTIVE_SEARCH_SPELL
	cmp	bl, ASST_SPELL_ACTIVE shl offset VTIF_ACTIVE_SEARCH_SPELL
	mov	bx, 0		;Don't change to "clr"
	jnz	5$

	mov	bx, -1		;Set the flag that says to change the current
				; selection to the beginning (only if it was
				; a spell check).
5$:

	push	bx	
	mov	bx, bp				;BX.CX <- offset into text
						; to start replace

	sub	sp, size VisTextReplaceParameters
	mov	bp, sp				;SS:BP <- ptr to
						; TextReplaceParams
;
;	AX.DX <- # chars to replace (modify for 32-bit object)
;	CX <- position to replace at
;
	pushdw	bxcx				;Save start offset
	movdw	ss:[bp].VTRP_range.VTR_start, bxcx
	adddw	dxax, bxcx			;dx.ax <- end of range
	movdw	ss:[bp].VTRP_range.VTR_end, dxax
	subdw	dxax, bxcx			;dx.ax <- # chars in range

;	SET UP TEXT REPLACE PARAMS

	mov	di, es:[SRS_replaceSize]
	dec	di
	mov	ss:[bp].VTRP_insCount.low, di
	mov	ss:[bp].VTRP_insCount.high, 0
	mov	ss:[bp].VTRP_flags, mask VTRF_USER_MODIFICATION or mask VTRF_FILTER

	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	push	ax
	mov	ax, es:[SRS_searchSize]
DBCS <	shl	ax, 1				;# chars -> # bytes	>
	add	ax, size SearchReplaceStruct
	movdw	ss:[bp].VTRP_pointerReference, esax
	pop	ax
	test	es:[SRS_params], mask SO_PRESERVE_CASE_OF_DOCUMENT_STRING
	jz	noConvertString

DBCS <	shl	di, 1				;# chars -> # bytes	>
	sub	sp, di				;Make space on stack for string
	movdw	ss:[bp].VTRP_pointerReference, sssp
	mov	di, sp				;SS:DI <- ptr to place to store
	call	ConvertCaseOfReplaceString	; converted replace string
	mov	ax, ss:[bp].VTRP_insCount.low
	jmp	replaceCommon
noConvertString:
	clr	ax
replaceCommon:
	push	ax
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	SearchSpellObjCallInstanceNoLockNear
	pop	cx				;Nuke string on stack
DBCS <	shl	cx, 1				;# chars -> # bytes	>
	add	sp, cx				
	popdw	dxax				;DX.AX <- offset to start
						; of replace
	add	sp, size VisTextReplaceParameters

	pop	cx				;Restore "change selection" 
	jcxz	exit				; flag. If no overlap, exit.
		
;	MODIFY SELECTION TO BE AT BEGINNING OF REPLACE

	sub	sp, size VisTextRange
	mov	bp, sp
	movdw	ss:[bp].VTR_start, dxax
	movdw	ss:[bp].VTR_end, dxax
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	SearchSpellObjCallInstanceNoLockNear
	add	sp, size VisTextRange
exit:
	pop	di
	call	ThreadReturnStackSpace
	.leave
	ret
DoReplace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceCurrent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out by spell check library to tell the text object
		to replace the current word with the passed text.


CALLED BY:	GLOBAL
PASS:		dx - handle of block containing strings (will be freed)
		*ds:si - ptr to object
RETURN:		nada
DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceCurrent	proc	far	; MSG_REPLACE_CURRENT
	push	dx
	mov	bx, dx			;Get data block
	call	MemLock
	mov	es, ax

	call	TSL_SelectGetSelection		;dx.ax, cx.bx = selection
	xchgdw	dxax, cxbx
	subdw	dxax, cxbx			;dxax = count
	mov	bp, cx				;bpcx = offset
	mov	cx, bx
	call	DoReplace
	pop	bx
	call	MemFree
	ret
VisTextReplaceCurrent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllOccurrences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out by spell check library to tell the text object
		to replace the all occurrences of the passed source string
		with the passed replace string.


CALLED BY:	GLOBAL
PASS:		dx - handle of block containing strings
		cx - non-zero if we want to start from the start of the doc
		*ds:si - ptr to object
RETURN:		nada
DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllOccurrences	proc	far	; MSG_REPLACE_ALL_OCCURRENCES
	class	VisTextClass

	mov	bx, dx
	call	MemLock
	mov	es, ax
	pushdw	es:[SRS_replyObject]
	push	es:[SRS_replyMsg]
	call	MemUnlock

	
	push	bx

;	Do the replace

	sub	sp, size ReplaceAllFromOffsetStruct
	mov	bp, sp
	mov	ss:[bp].RAFOS_data, dx
	clr	ss:[bp].RAFOS_flags
	jcxz	currentOffset

;	Start from the beginning of the document
	mov	ax, GSSOT_FIRST_OBJECT
	call	GetSearchSpellObject
	movdw	bxsi, cxdx
	clrdw	ss:[bp].RAFOS_startOffset
	jmp	common

currentOffset:
	call	TSL_SelectGetSelectionStart	;dx.ax = selection
	movdw	ss:[bp].RAFOS_startOffset, dxax
	mov	bx, ds:[LMBH_handle]
common:
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_FROM_OFFSET
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	add	sp, size ReplaceAllFromOffsetStruct

	pop	bx
	call	MemFree

;	Notify the object if no replaces were done

	pop	ax
	popdw	bxsi
	jcxz	noReplaces
exit:
	ret

noReplaces:
	tst	bx			;If no object to reply to, exit
	jz	exit
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage	
	jmp	exit
VisTextReplaceAllOccurrences	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllOccurrencesInSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out by spell check library to tell the text object
		to replace the all occurrences of the passed source string
		with the passed replace string.


CALLED BY:	GLOBAL
PASS:		dx - handle of block containing strings
		*ds:si - ptr to object
RETURN:		nada
DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllOccurrencesInSelection	proc	far	; MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION
	class	VisTextClass

	mov	bx, dx
	call	MemLock
	mov	es, ax
	pushdw	es:[SRS_replyObject]
	push	es:[SRS_replyMsg]
	call	MemUnlock

;	Do the replace

	push	dx
	sub	sp, size ReplaceAllInRangeStruct
	mov	bp, sp
	mov	ss:[bp].RAIRS_data, dx
	call	TSL_SelectGetSelection		;dx.ax, cx.bx = selection
	movdw	ss:[bp].RAIRS_range.VTR_start, dxax
	movdw	ss:[bp].RAIRS_range.VTR_end, cxbx

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_IN_RANGE
	call	SearchSpellObjCallInstanceNoLockNear
	add	sp, size ReplaceAllInRangeStruct
	pop	bx
	call	MemFree

;	Notify the object if no replaces were done

	pop	ax
	popdw	bxsi
	jcxz	noReplaces
exit:
	ret

noReplaces:
	tst	bx			;If no object to reply to, exit
	jz	exit
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage	
	jmp	exit
VisTextReplaceAllOccurrencesInSelection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches the current text object for the passed string

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
		bx:cx - offset between chars in text object to begin search
		dx:ax - offset into text object of last char to include
			in search.
		    (or TEXT_ADDRESS_PAST_END if we want to search to the 
		     last char in the object)
		es - ptr to this data:
			SearchReplaceStruct<>
			data	Null-Terminated Search String
			data	Null-Terminated Replace string

RETURN:		carry set if not found in this object
		BP.CX - offset to string if found
		DX.AX - # chars in match
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindString	proc	near	uses	si, di, ds, es
	class	VisTextClass	
	.enter

;	If passed-in size was TEXT_ADDRESS_PAST_END (search to end) then
;	convert it to be "(string size)-1"

	cmpdw	dxax, TEXT_ADDRESS_PAST_END
	jne	5$
	call	TS_GetTextSize		;dx.ax <- size of text
	tstdw	dxax			;If no text in object, then fail search
	jz	failed
	decdw	dxax
5$:
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
	je	forwardSearch

;	If backward search, change start offset to be char *before* the
;	current cursor pos.

	subdw	bxcx,1		;
	jc	exit		;Branch if we were at the start of the object

doSearch:
	call	TS_FindStringInText
exit:
	.leave
	ret

forwardSearch:
	

;	If forward search, check to see if we are starting the search beyond
;	the end offset. If so, return that we didn't find the string.

	cmpdw	bxcx, dxax
	jbe	doSearch

failed:
	stc	
	jmp	exit
FindString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the process.

CALLED BY:	GLOBAL
PASS:		ax, cx, dx, bp, si - msg params
RETURN:		nada
DESTROYED:	will nullSeg es, ds as appropriate!
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallProcess	proc	near	uses	ax, bx, cx, dx, bp, di, si
	.enter
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
CallProcess	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSS_CheckForUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns Z flag clear if undoable (jnz isUndoable)

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		z flag clear if undoable (jnz isUndoable)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSS_CheckForUndo	proc	near	uses	si
	class	VisTextClass
	.enter
	mov	si, ds:[si]
	add	si, ds:[si].VisText_offset
	test	ds:[si].VTI_features, mask VTF_ALLOW_UNDO
	.leave
	ret
TSS_CheckForUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllOccurrencesInRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out by spell check library to tell the text object
		to replace the all occurrences of the passed source string
		with the passed replace string in the passed range

CALLED BY:	GLOBAL
PASS:		ss:bp - ReplaceAllInRangeStruct
		*ds:si - ptr to object

RETURN:		cx - # replaces performed
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAX_UNDOABLE_REPLACES	equ	300
; We only allow a fixed number of undo actions to be created, because
; otherwise we run a great risk of running out of handles on large replaces.
VisTextReplaceAllOccurrencesInRange	proc	far
			;MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_IN_RANGE
	class	VisTextClass

	clr	cx
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	LONG jz	exit		;Skip if not editable

;	Create an undo chain if undoable

	call	TSS_CheckForUndo
	jz	noUndo
	mov	ax, offset ReplaceAllString
	call	TU_StartUndoChain
noUndo:

;	Suspend the text object before doing the replace

	push	bp
	mov	ax, MSG_META_SUSPEND
	call	SearchSpellObjCallInstanceNoLockNear
	pop	bp

	mov	bx, ss:[bp].RAIRS_data		;Get data block
	push	bx
	call	MemLock
	mov	es, ax

;		es - ptr to this data:
;			SearchReplaceStruct<>
;			data	Null-Terminated Search String
;			data	Null-Terminated Replace string

;	DX.AX, BX.CX - range to search for string in

	clr	di		;No replaces to begin with...
	movdw	dxax, ss:[bp].RAIRS_range.VTR_end
	movdw	bxcx, ss:[bp].RAIRS_range.VTR_start
	cmpdw	dxax, TEXT_ADDRESS_PAST_END
	je	loopTop
	decdw	dxax		;Convert end of range to "offset to last char"

loopTop:

;	Search for the string in the document - when a match is found, perform
;	a replacement and search for the next match.

	push	di
	push	dx, ax
	call	FindString		;Returns BP.CX as offset to string in
					; this object.
	jc	noMoreReplaces		;Branch if string not found

	movdw	bxdi, dxax		;BX:DI <- # chars to be deleted	
	call	DoReplace		;Replaces this instance of the string
					; in the object.
	pop	dx, ax

;	Adjust the start/end positions of the range
;
;	New starting position = old starting position + replace Size
;		(we resume the replacment right after the old replacment)
;
;	New ending position = old ending position - chars deleted + chars added
;

	cmpdw	dxax, TEXT_ADDRESS_PAST_END
	je	noAdjustEnd
	subdw	dxax, bxdi		;Subtract # chars to be deleted from
					; end of range (see equation above)
	mov	bx, es:[SRS_replaceSize]
	dec	bx			;Add # chars to be inserted
	add	ax, bx
	adc	dx, 0
	js	beyondTheEnd

noAdjustEnd:
	pop	di
	inc	di			;Inc count of # replacements
	cmp	di, MAX_UNDOABLE_REPLACES
	jne	noAbort

;	Ignore all of the following undo actions, if we have too many
;	replaces - this keeps the system from dying from running out of
;	handles with large replace alls.

	call	TSS_CheckForUndo
	jz	noAbort
	push	ax
	push	ds:[OLMBH_header].LMBH_handle
	mov	ax, MSG_GEN_PROCESS_UNDO_ABORT_CHAIN
	call	CallProcess
	pop	bx
	call	MemDerefDS
	pop	ax
noAbort:
	mov	bx, es:[SRS_replaceSize];
	dec	bx			;BX <- # chars in replacement string


	add	cx, bx			;BP.CX <- new offset to start searching
	adc	bp, 0			; at.

	mov	bx, bp
	cmpdw	bxcx, dxax		;If not at end yet, branch back up
	jbe	loopTop

unlockExit:

;	Unlock the SearchReplace data block, end the undo chain, and unsuspend
;	the object.

	pop	bx
	call	MemUnlock

	call	TSS_CheckForUndo
	jz	noEndChain
	call	TU_EndUndoChain
noEndChain:

	mov	ax, MSG_META_UNSUSPEND
	call	SearchSpellObjCallInstanceNoLockNear
	mov	cx, di			;CX <- # replacements
exit:
	ret

noMoreReplaces:
	pop	dx, ax

beyondTheEnd:
	pop	di
	jmp	unlockExit
VisTextReplaceAllOccurrencesInRange	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextReplaceAllFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out by spell check library to tell the text object
		to replace the all occurrences of the passed source string
		with the passed replace string (starts at the passed object).

CALLED BY:	GLOBAL
PASS:		ss:bp - ReplaceAllFromOffsetStruct
		*ds:si - ptr to object

RETURN:		cx - # replaces performed
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextReplaceAllFromOffset	proc	far
			    ; MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_FROM_OFFSET
	class	VisTextClass

	test 	ss:[bp].RAFOS_flags, mask RAFOF_CONTINUING_REPLACE
	jnz	noNewUndoChain
	call	TSS_CheckForUndo
	jz	noNewUndoChain
	ornf	ss:[bp].RAFOS_flags, mask RAFOF_HAS_UNDO

;	Start a new undo chain for this REPLACE_ALL - this chain will encompass
;	all of the chains created by VisTextReplaceAllOccurrencesInRange()

	mov	ax, offset ReplaceAllString
	call	TU_StartUndoChain

noNewUndoChain:
EC <	push	bp							>
EC <	mov	ax, MSG_VIS_TEXT_GET_FEATURES				>
EC <	call	SearchSpellObjCallInstanceNoLockNear			>
EC <	mov	ax, mask RAFOF_HAS_UNDO					>
EC <	test	cx, mask VTF_ALLOW_UNDO					>
EC <	jnz	10$							>
EC <	clr	ax							>
EC <10$:								>
EC <	pop	bp							>
EC <	xor	ax, ss:[bp].RAFOS_flags					>
EC <	test	ax, mask RAFOF_HAS_UNDO					>
EC <	ERROR_NZ	ALL_OBJECTS_IN_REPLACE_ALL_MUST_HAVE_SAME_VTF_ALLOW_UNDO_VALUE>

;
;	Call MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_IN_RANGE to actually do the
;	replace in this object.
;

	push	bp
	movdw	dxax, ss:[bp].RAFOS_startOffset
	mov	bx, ss:[bp].RAFOS_data
	sub	sp, size ReplaceAllInRangeStruct
	mov	bp, sp
	mov	ss:[bp].RAIRS_data, bx
	movdw	ss:[bp].RAIRS_range.VTR_start, dxax	
	movdw	ss:[bp].RAIRS_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_IN_RANGE
	call   	SearchSpellObjCallInstanceNoLockNear
	add	sp, size ReplaceAllInRangeStruct
	pop	bp
	mov	di, cx				;DI <- # replacements

;	Continue this replace in the next object

	mov	ax, GSSOT_NEXT_OBJECT
	call	GetSearchSpellObject
	jcxz	freeExit			;Exit if no next object

	mov	ss:[bp].RAFOS_data, bx
	clrdw	ss:[bp].RAFOS_startOffset 	;Start at beginning of next obj
	ornf	ss:[bp].RAFOS_flags, mask RAFOF_CONTINUING_REPLACE
	movdw	bxsi, cxdx		  	;BX.SI <- handle of next object

;	Recursively call this message handler to continue the replacement
;	(oooh, ahhhh).

	call	ObjSwapLock
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OCCURRENCES_FROM_OFFSET
	call	SearchSpellObjCallInstanceNoLockNear
	call	ObjSwapUnlock
	add	di, cx
exit:
	mov	cx, di				;CX <- # replaces
	ret

freeExit:
	test	ss:[bp].RAFOS_flags, mask RAFOF_HAS_UNDO
	jz	exit
	call	TU_EndUndoChain
	jmp	exit

VisTextReplaceAllFromOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler searches for the passed string.

CALLED BY:	GLOBAL
PASS:	*ds:si, ds:di - ptr to VisText object
	 dx - handle of block containing words (should be freed by method
	       	   handlers)
		Format of block:
			SearchReplaceStruct<>
			data	Null-Terminated Search String

RETURN:		nada
DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSearch	proc	far	; MSG_SEARCH
	class	VisTextClass

	mov	bx, dx
	call	MemLock
	mov	es, ax

	call	TSL_SelectGetSelectionStart	;dx.ax <- selection start

;	If no search is active, start a search from the start of the
;	 current selection.
;	If a search is already active, continue the search from the end
;	 of the current selection
;	If a spell is active, abort the spell, and start a search from the
;	 start of the current selection.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cl, ds:[di].VTI_intFlags
	andnf	cl, mask VTIF_ACTIVE_SEARCH_SPELL
	cmp	cl, ASST_SEARCH_ACTIVE shl offset VTIF_ACTIVE_SEARCH_SPELL
	jz	searchActive
	cmp	cl, ASST_NOTHING_ACTIVE shl offset VTIF_ACTIVE_SEARCH_SPELL
if KEYBOARD_ONLY_UI
	je	5$				;always start from end of word,
						;  otherwise you can't use
						;  kbd shortcuts while the
						;  search box is offscreen.
else
	je	10$
endif

;	Abort any active spell checks.	

	call	SendAbortSearchSpellNotification
	jmp	10$

searchActive:
	andnf	ds:[di].VTI_intFlags, not mask VTIF_ACTIVE_SEARCH_SPELL

;	WE ARE ALREADY IN A SEARCH. SKIP SELECTED AREA

if KEYBOARD_ONLY_UI
5$:
endif
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
						;Always use start of selected
	jnz	10$				; area if we are searching
						; backward. Else, we are
						; doing a progressive forward
						; search, so skip to end of
						; selection.
	call	TSL_SelectGetSelectionEnd	;DX.AX <- place to start search


10$:
	pushdw	es:[SRS_replyObject]
	push	es:[SRS_replyMsg]
	sub	sp, size SearchFromOffsetReturnStruct + \
				size SearchFromOffsetStruct
	call	MemUnlock

;	DX.AX <- offset into area to start search

	mov	bp, sp
	clr	ss:[bp].SFOS_flags
	mov	ss:[bp].SFOS_data, bx
	movdw	ss:[bp].SFOS_startOffset, dxax
	movdw	ss:[bp].SFOS_currentOffset, dxax

	mov	dx, bx			;DX <- handle of SearchFromOffsetStruct
	mov	bx, ds:[LMBH_handle]	;^lBX:SI <- this object

	mov	ss:[bp].SFOS_startObject.handle, bx
	mov	ss:[bp].SFOS_startObject.chunk, si
	mov	ss:[bp].SFOS_retStruct.segment, ss
	mov	ss:[bp].SFOS_retStruct.offset, bp
	add	ss:[bp].SFOS_retStruct.offset, size SearchFromOffsetStruct
	mov	ax, MSG_VIS_TEXT_SEARCH_FROM_OFFSET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	dx, size SearchFromOffsetStruct
	call	SearchSpellObjMessageNear
	add	sp, size SearchFromOffsetStruct

		;SS:SP <- ptr to SearchFromOffsetReturnStruct
	mov	bp, sp
	mov	bx, ss:[bp].SFORS_object.handle
	tst	bx
	jz	notFound	;Branch if string not found in any object

;	SELECT THE STRING (CLEAR THE SELECTION FIRST SO THE SELECTION WILL
;	"FLASH" IF IT IS THE SAME AS THE OLD SELECTION).

	mov	si,ss:[bp].SFORS_object.chunk	;^lBX:SI <- ptr to object
	call	ObjSwapLock			;*ds:si = object
	movdw	cxdx, ss:[bp].SFORS_offset
	sub	sp, size VisTextRange
	mov_tr	ax, bp
	mov	bp, sp
	push	ax
	movdw	ss:[bp].VTR_start, cxdx
	movdw	ss:[bp].VTR_end, cxdx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	clr	di
	call	SearchSpellObjCallInstanceNoLockNear
	pop	bp

	movdw	dxax, ss:[bp].SFORS_offset
	mov	cx, ss:[bp].SFORS_len.low
	call	SelectTextAndMakeTarget
	add	sp, size VisTextRange

;	SET BIT IN OBJECT SO IT WILL NOTIFY THE SEARCH BOX IF THE USER
;	CLICKS IN THE BOX, OR THE BOX LOSES THE TARGET OR ANYTHING.

	mov	ax, MSG_VIS_TEXT_SET_SEARCH_IN_PROGRESS
	clr	di
	call	SearchSpellObjCallInstanceNoLockNear
	call	ObjSwapUnlock
	add	sp, size SearchFromOffsetReturnStruct + size optr + size word
exit:
	ret

notFound:

	add	sp, size SearchFromOffsetReturnStruct

;	THE STRING WASN'T FOUND. NOTIFY THE SEARCH BOX

	pop	ax
	popdw	bxsi
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage	
	jmp	exit

VisTextSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextSearchFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method searches for the passed string from the passed
		offset into the text, wrapping around at the beginning.

CALLED BY:	GLOBAL
PASS:		dx - size of SearchFromOffsetStruct
	      	ss:bp - ptr to SearchFromOffsetStruct


RETURN:		Values in passed SearchFromOffsetReturnStruct

DESTROYED:	various important but undocumented things

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextSearchFromOffset	proc	far	; MSG_VIS_TEXT_SEARCH_FROM_OFFSET
	class	VisTextClass

	; save the handle of the original object

	push	ds:[LMBH_handle]

objectLoop:
	mov	bx, ss:[bp].SFOS_data
	push	bx
	call	MemLock
	mov	es, ax

;		es - ptr to this data:
;			SearchReplaceStruct<>
;			data	Null-Terminated Search String
;			data	Null-Terminated Replace string


;	IF THE CALLER PASSED IN TEXT_ADDRESS_PAST_END AS ANY OFF THE OFFSETS,
;	RESET THEM TO POINT TO THE END OF THE TEXT INSTEAD.

	call	TS_GetTextSize	;DX:AX <- size of text

	cmpdw	ss:[bp].SFOS_currentOffset, TEXT_ADDRESS_PAST_END
	jne	3$
	movdw	ss:[bp].SFOS_currentOffset, dxax
3$:
	cmpdw	ss:[bp].SFOS_startOffset, TEXT_ADDRESS_PAST_END
	jne	4$
	movdw	ss:[bp].SFOS_startOffset, dxax
4$:

;	DETERMINE THE STOPPING POINT - THIS IS USUALLY THE START OR THE END
;	OF THE OBJECT, DEPENDING UPON WHETHER OR NOT IT IS A FORWARD OR
;	BACKWARD SEARCH

	movdw	dxax, TEXT_ADDRESS_PAST_END
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
	jz	5$
	clrdw	dxax
5$:
				;DX.AX <- ptr to last char in document to
				;	  search (either -1:-1 (end) or 0:0
				;	  (beginning) depending upon if this
				;	  is a forward or backward search
	mov	bx, -1		;Set flag that says we want to wraparound
	test	ss:[bp].SFOS_flags, mask SFOF_STOP_AT_STARTING_POINT
	jz	doSearch	;If we haven't wrapped yet, go to end of
				; document

				;Else, if this is the same document we started
				; the search in, just search to the starting
				; point, and no further.

	cmp	si, ss:[bp].SFOS_startObject.chunk
	jne	doSearch
	mov	cx, ds:[LMBH_handle]
	cmp	cx, ss:[bp].SFOS_startObject.handle
	jne	doSearch

	clr	bx		;Set flag saying search should not wrap past
				; this object.

;	Map the start offset, which was originally a cursor position, to be
;	the offset of the last char to include in the search.

	movdw	dicx, ss:[bp].SFOS_startOffset
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
	jne	isBackward
	subdw	dicx,1
	jc	outOfRange
isBackward:
	call	TS_GetTextSize
	cmpdw	dicx, dxax
	je	outOfRange
EC <	ERROR_A	-1							>

	movdw	dxax, dicx
doSearch:

;	ACTUALLY DO THE SEARCH

	mov	di, bp			;SS:DI <- ptr to SearchFromOffsetStruct
	push	bx		;Save wrap flag
	movdw	bxcx, ss:[di].SFOS_currentOffset

;	BX.CX <- offset to *start* search
;	DX.AX <- offset to *stop* search (or TEXT_ADDRESS_PAST_END to goto end)

	call	FindString	;Returns BP.CX as offset to string in
				; this object.
	pop	bx		;Restore wrap flag
	jc	notFound	;Branch if string not in this object
freeExit:
	pop	bx		;Free up block with SearchReplaceStruct
	call	MemFree

;	If  SI = 0, store 0:0 in SFORS_object (signifying that 
;	the search was unsuccessful. Else, set it to point to the object.

	push	ds
	mov	bx, ds:[LMBH_handle]
	lds	di, ss:[di].SFOS_retStruct
	mov	ds:[di].SFORS_object.chunk, si
	tst	si
	je	10$
	mov	si, bx
10$:
	movdw	ds:[di].SFORS_offset, bpcx
	mov	ds:[di].SFORS_object.handle, si
	movdw	ds:[di].SFORS_len, dxax
	pop	ds

	; unlock this object and relock the original object
finishUp:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	pop	bx
	call	ObjLockObjBlock

	ret

outOfRange:
	mov	di, bp
notFound:

;	THE STRING WAS NOT FOUND IN THIS OBJECT

	tst	bx		;Check to see if wrap-around flag was set
	je	searchComplete	;If not, branch

;	GO TO THE START OF THE NEXT TEXT OBJECT IN THE CHAIN
;
;	We try to get the next/prev object in the chain. If it is 0:0, this
;	means we've reached the end of the chain, so we want to wraparound
;	to the first/last object (depending upon whether this is a forward
;	or backward search).
;
	mov	ax, GSSOT_NEXT_OBJECT
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
	je	forwardSearch
	mov	ax, GSSOT_PREV_OBJECT
forwardSearch:
	call	GetSearchSpellObject
	tst	cx
	jnz	notAtEnd
	mov	ax, GSSOT_FIRST_OBJECT
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
	je	getFirst
	mov	ax, GSSOT_LAST_OBJECT
getFirst:
	push	ax
	call	GetSearchSpellObject
	pop	ax
	;
	; here is a special case -- wrapping around, if the client
	; doesn't want to wrap, they return 0 here.  We should
	; simulate a successful match with the original object to
	; avoid error message (client implies no error when querying
	; user to wrap or not)
	tst	cx
	jnz	notAtEnd
	pop	bx
	call	MemFree		; free SeachReplaceStruct block
	push	ds
	mov	bp, di
	lds	di, ss:[bp].SFOS_retStruct
	mov	bx, ss:[bp].SFOS_startObject.handle
	mov	ds:[di].SFORS_object.handle, bx
	mov	bx, ss:[bp].SFOS_startObject.chunk
	mov	ds:[di].SFORS_object.chunk, bx
	movdw	ds:[di].SFORS_offset, TEXT_ADDRESS_PAST_END  ; assume forward
	cmp	ax, GSSOT_FIRST_OBJECT
	je	gotOffset
	movdw	ds:[di].SFORS_offset, 0	; else, backward
gotOffset:
	movdw	ds:[di].SFORS_len, 0
	pop	ds
	jmp	finishUp

notAtEnd:

	mov	bp, di		;SS:BP <- ptr to stack frame

;	If forward search, wrap to start of next object

	clrdw	ss:[bp].SFOS_currentOffset
	ornf	ss:[bp].SFOS_flags, mask SFOF_STOP_AT_STARTING_POINT
	test	es:[SRS_params], mask SO_BACKWARD_SEARCH
	jz	80$		;If a forward search, branch

;	If backward search, wrap to end of next object

	movdw	ss:[bp].SFOS_currentOffset, TEXT_ADDRESS_PAST_END	
80$:
	pop	bx
	call	MemUnlock	;Unlock the info block

;	START THE SEARCH ON THE NEXT OBJECT (OR THIS ONE)

	; We don't want to send a send a message to the object to recurse
	; because this can cause nasty problems.  The first problem is that
	; we run out of stack space, which can be solved by borrowing stack
	; space.  The second problem is a TOO_MANY_LOCKS death if there are
	; more than 254 text objects.  This one is really difficult to
	; solve.

	; Thus we will unlock this object, lock the next one and keep going

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	movdw	bxsi, cxdx
	call	ObjLockObjBlock
	mov	ds, ax
	jmp	objectLoop

searchComplete:
				;String not found in any object. Return
	clr	si		; SI as 0 to signify this
	jmp	freeExit
VisTextSearchFromOffset	endp



TextSearchSpell	ends



