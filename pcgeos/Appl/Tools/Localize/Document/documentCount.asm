COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit	
FILE:		documentCount.asm

AUTHOR:		Cassie Hartzog, Sep 27, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	9/27/93		Initial revision


DESCRIPTION:
	Routines for doing word counts.

	$Id: documentCount.asm,v 1.1 97/04/04 17:14:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentCount	segment resource
if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditDocumentCountAllWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the total number of words that appear in the
		original chunks.

CALLED BY:	MSG_RESEDIT_DOCUMENT_COUNT_ALL_WORDS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TotalWordCountStruct		struct
    TWCS_EACS	EnumAllChunksStruct
    TWCS_count	word			; total number of words
TotalWordCountStruct		ends

ResEditDocumentCountAllWords		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_COUNT_ALL_WORDS

	sub	sp, size TotalWordCountStruct
	mov	bp, sp
	mov	ss:[bp].TWCS_EACS.EACS_size, size TotalWordCountStruct
	mov	ss:[bp].TWCS_EACS.EACS_callback.segment, cs
	mov	ss:[bp].TWCS_EACS.EACS_callback.offset, offset CountAllWordsCallback
	clr	ss:[bp].TWCS_count
	call	EnumAllChunks

	mov	dx, ss:[bp].TWCS_count

	add	sp, size TotalWordCountStruct

	call	DocumentDisplayCount

	ret
ResEditDocumentCountAllWords		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDisplayCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		dx - count
RETURN:		nothing
DESTROYED:	ax,bx,cx,si,di,es,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentDisplayCount		proc	near
	.enter

	sub	sp, 10
	mov	di, sp
	segmov	es, ss, cx

	clr	ax, cx				;no fractional part
	call	LocalFixedToAscii

	clr	ax
	pushdw	axax				;SDP_helpContext
	pushdw	axax				;SDP_customTriggers
	pushdw	axax				;SDP_stringArg2
	pushdw	esdi				;SDP_stringArg1

	mov	bx, handle StringsUI
	call	MemLock
	mov	ds, ax
	mov	si, offset TotalWordsString
	mov	si, ds:[si]
	pushdw	dssi				;SDP_customString

	mov	ax, CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_NOTIFICATION, 0>
	push	ax				;SDP_customFlags

	call	UserStandardDialog
	call	MemUnlock
	add	sp, 10

	.leave
	ret
DocumentDisplayCount		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountAllWordsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count all the words in this chunk.

CALLED BY:	ResEditDocumentCountAllWords (via ChunkArrayEnum)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ax	- element size
		dx	- file handle
		cx	- resource group number
		ss:bp	- TotalWordCountStrut
RETURN:		ss:bp.WCS_count - updated 
		dx, cx unchanged
		ds - segment of ResourceArray
DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountAllWordsCallback		proc	far
	uses	cx, dx
	.enter

	test	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT
	jz	done

	mov	bx, dx				; ^hbx <- translation file
	mov	dl, ds:[di].RAE_data.RAD_chunkType
	mov	ax, cx				; ax <- group number
	mov	di, ds:[di].RAE_data.RAD_origItem
	
	call	DBLock_DS			; *ds:si <- origItem
	mov	si, ds:[si]

	call	GetStringLength_DS

prime::
	;
	; prime the loop
	; 
	lodsb					; al <- first char
	dec	cx
	call	CheckIsWhiteSpace		; is it a whitespace char?
	jne	checkCX				; yes, it is whitespace
	inc	ss:[bp].TWCS_count		; no, it is start of new word
EC <	ERROR_Z	WORD_COUNT_OVERFLOW			>
	
checkCX:
	tst	cx				; only 1 char in string?
	jz	done				; if yes, we're done
		
wordLoop:
	lodsb	
	call	CheckIsWhiteSpace		; is it a white space char?
	je	continue			; no, continue
	cmp	cx, 1				; yes, but is it the last char?
	je	notWhiteSpace			; yes, we're done
	dec	cx				; no, go to inner loop

spaceLoop:
	lodsb					; get next char
	call	CheckIsWhiteSpace		; is it yet more white space?
	je	notWhiteSpace			; no, we found another word
	loop	spaceLoop			; yes, continue looping here
	jmp	unlock				; chunk ends with whitespace

notWhiteSpace:
	inc	ss:[bp].TWCS_count		; we're at start of another word
EC <	ERROR_Z	WORD_COUNT_OVERFLOW			>

continue:	
	loop	wordLoop

unlock:
	call	DBUnlock_DS
done:	
	clc
	.leave
	ret
CountAllWordsCallback		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditDocumentCountUniqueWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CountUniqueWords interaction has opened or closed.  
		If opened, count the words and update its UI.
		If closed, delete the block holding the WordCountArray.

CALLED BY:	MSG_RESEDIT_DOCUMENT_COUNT_UNIQUE_WORDS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		bp - non-zero if open, 0 if close
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WordCountStruct		struct
    WCS_EACS		EnumAllChunksStruct
    WCS_count		word		; running count of # unique words
    WCS_totalCount	word		; running count of all words
    WCS_array		optr		; optr of WordCountElement array
    WCS_endWord		nptr		; points to end of current word
    WCS_wordLength	word		; length of current word
    WCS_charsLeft	word		; number of chars left in string
WordCountStruct		ends

ResEditDocumentCountUniqueWords		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_COUNT_UNIQUE_WORDS

	call	MarkBusyAndHoldUpInput

	sub	sp, size WordCountStruct
	mov	bp, sp
	call	CreateWordTree
	
DBCS <	mov	ss:[bp].WCS_count, 30					>
DBCS <	mov	ss:[bp].WCS_totalCount, 40				>

	mov	ax, TEMP_RESEDIT_DOCUMENT_WORD_COUNT_ARRAY
	mov	cx, size optr
	call	ObjVarAddData		; ds:bx <- extra data
	movdw	axcx, ss:[bp].WCS_array
	movdw	ds:[bx], axcx

	GetResourceHandleNS	UniqueWords, bx
	mov	si, offset UniqueWords
	mov	dx, ss:[bp].WCS_count
	call	ReplaceCountText

	mov	si, offset TotalWords
	mov	dx, ss:[bp].WCS_totalCount
	call	ReplaceCountText

	add	sp, size WordCountStruct

	call	MarkNotBusyAndResumeInput

	mov	si, offset WordCount
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	GOTO	ObjMessage

ResEditDocumentCountUniqueWords		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditDocumentDestroyWordCountArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has closed the CountUniqueWords dialog.
		Free the WordCountArray now.

CALLED BY:	MSG_RESEDIT_DOCUMENT_DESTROY_WORD_COUNT_ARRAY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditDocumentDestroyWordCountArray	method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_DESTROY_WORD_COUNT_ARRAY

	mov	ax, TEMP_RESEDIT_DOCUMENT_WORD_COUNT_ARRAY
	call	ObjVarFindData		; ds:bx <- extra data
	jnc	done
	push	ds:[bx+2]
	call	ObjVarDeleteDataAt
	pop	bx
	call	MemFree
done:
	ret
ResEditDocumentDestroyWordCountArray		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateWordTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a binary tree of all words found in the text
		chunks of the localization file.

CALLED BY:	ResEditDocumentCountUniqueWords
PASS:		*ds:si	- document
		ss:bp	- WordCountStruct
RETURN:		carry set if out of memory	
DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateWordTree		proc	near
	.enter 

	mov	ss:[bp].WCS_EACS.EACS_size, size WordCountStruct
	mov	ss:[bp].WCS_EACS.EACS_callback.segment, cs
	mov	ss:[bp].WCS_EACS.EACS_callback.offset, offset CreateWordTreeCallback 
	clr	ax, cx
	mov	ss:[bp].WCS_count, ax
	mov	ss:[bp].WCS_totalCount, ax
	movdw	ss:[bp].WCS_array, axcx

	;
	; alloc an initial block of memory to hold WordCountArray
	;
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx				; default block header size
	call	MemAllocLMem
	jc	done
	mov	ss:[bp].WCS_array.handle, bx

	push	ds:[LMBH_handle], si		; save document OD
	call	MemLock
	mov	ds, ax				; ds <- block for new array
	clr	cx				; no extra space for header
	clr	si				; create a chunk handle
	mov	bx, size WordCountElement	; bx <- element size
	mov	al, mask OCF_DIRTY
	call	ChunkArrayCreate		; *ds:si <- array
	mov	ss:[bp].WCS_array.chunk, si

	pop	bx, si
	call	MemDerefDS
SBCS <	call	EnumAllChunks						>
	
done:
	.leave
	ret
CreateWordTree		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateWordTreeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the words in this element to the WordCountArray.

CALLED BY:	CreateWordTree (via EnumAllChunks)
PASS:		*ds:si - ResourceArray
		 ds:di - ResourceArrayElement
		 ss:bp - WordCountStruct
		 dx - file handle
		 cx - resource group number
RETURN:		carry clear to continue enumeration
DESTROYED:	ax,bx,si,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateWordTreeCallback		proc	far
	uses	cx, dx
	.enter

	test	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT
	jz	exit

	push	ds:[LMBH_handle]

	mov	bx, dx
	mov	ax, cx
	mov	dl, ds:[di].RAE_data.RAD_chunkType
	mov	dh, ds:[di].RAE_data.RAD_mnemonicType
	mov	di, ds:[di].RAE_data.RAD_origItem
	call	DBLock
	mov	di, es:[di]			; es:di <- orig item 

	call	GetStringLength			

	mov	ss:[bp].WCS_endWord, di
	mov	ss:[bp].WCS_charsLeft, cx

wordLoop:
	tst	ss:[bp].WCS_charsLeft
	jz	done
	call	FindNextWord			; es:di <- ptr to next word
	jnc	done
	inc	ss:[bp].WCS_totalCount		; up the total count

	clr	cx				; first element
	mov	ax, ss:[bp].WCS_count		; ax <- number of elements
	movdw	bxsi, ss:[bp].WCS_array
	call	MemDerefDS			; *ds:si <- WordCountArray

	tst	ax
	jz	addNewWord

	dec	ax				; last element number
	call	FindInsertionPoint		; ax <- element number
	jc	addNewWord			; word not found - add it

	call	ChunkArrayElementToPtr
	inc	ds:[di].WCE_count
	jmp	wordLoop

done:
	call	DBUnlock			; unlock the DBItem

	pop	bx
	call	MemDerefDS			; ds - segment of ResourceArray
	clc
exit:
	.leave
	ret

addNewWord:
	call	AddNewWord
	jmp	wordLoop

CreateWordTreeCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates length of actual text portion of chunk.

CALLED BY:	CreateWordTreeCallback
PASS:		es:di	- text
		dl	- ChunkType
		dh	- mnemonic type
RETURN:		cx	- string length
		es:di	- points to string
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStringLength		proc	near

	ChunkSizePtr	es, di, cx
	
	test	dl, mask CT_MONIKER
	jz	notMoniker
	add	di, MONIKER_TEXT_OFFSET
	sub	cx, MONIKER_TEXT_OFFSET

	cmp	dh, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	notMoniker
	dec	cx				

notMoniker:
	dec	cx				; don't count the NULL

	ret
GetStringLength		endp

GetStringLength_DS	proc	near
ForceRef GetStringLength_DS
	push	di, es
	segmov	es, ds, cx
	mov	di, si
	call	GetStringLength
	mov	si, di				; JM added this 4/26/95
						; to save new si
	pop	di, es
	ret
GetStringLength_DS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next word in a text string.

CALLED BY:	CreateWordTreeCallback
PASS:		es - segment of text
		ss:bp - WordCountStruct
RETURN:		es:di - next to word
		carry clear if no more words
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextWord		proc	near
	uses	si,ds
	.enter

	mov	di, ss:[bp].WCS_endWord		; es:di <- pts to char after
						;  the last word
	mov	cx, ss:[bp].WCS_charsLeft

	mov	si, di
	segmov	ds, es, ax

	;
	; prime the loop
	; 
	clr	ss:[bp].WCS_wordLength
	lodsb					; al <- first char
	call	CheckIsWhiteSpace		; is it a whitespace char?
	jz	foundWord			; no, it's a word
EC <	cmp	cx, 0							>
EC <	ERROR_Z RESEDIT_INTERNAL_ERROR					>
	clc					; carry clear - no word
	dec	cx				; Is there only one char?
	jz	exit				; if yes, we're done
		
spaceLoop:
	; Last char was whitespace.  Find next non-whitespace char.
	;
	lodsb					; al <- next char
	call	CheckIsWhiteSpace		; is it a white space char?
	jz	foundWord			; no, find end of word
	loop	spaceLoop
	clc					; only white space - no more
	jmp	exit				;   words

foundWord:
EC <	tst	cx				>
EC <	ERROR_Z	RESEDIT_INTERNAL_ERROR		>
	inc	ss:[bp].WCS_wordLength		; length = 1 so far
EC <	ERROR_Z	WORD_COUNT_OVERFLOW			>
	mov	di, si				; es:di <- start of word + 1
	dec	di				; es:di <- start of word
	dec	cx				; else subtract char just read
	jz	noDec				; if last char, we're done

wordLoop:
	; Last char was non-whitespace.  Find next whitespace char.
	;
	lodsb					; al <- next char
	call	CheckIsWhiteSpace		; is it a white space char?
	jnz	done				; yes, we found end of word
	inc	ss:[bp].WCS_wordLength		; length = length + 1
	loop	wordLoop			; loop while cx != 0
	jmp	noDec				; if we got here, cx = 0.
done:	
	dec	cx				; else subtract char just read
noDec:
	mov	ss:[bp].WCS_charsLeft, cx	; # chars left after this word
	mov	ss:[bp].WCS_endWord, si		; ds:si pts to char after word
	stc					; signal that word was found

exit:
	.leave
	ret
FindNextWord		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNewWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	CreateWordTreeCallback
PASS:		*ds:si	- WordCountArray
		ax - element before which to add this one
		es:di - word
		ss:bp - WordCountStruct
RETURN:		
DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WordCountElement	struct
	WCE_count	word
	WCE_wordChunk	lptr
WordCountElement	ends

AddNewWord		proc	near
	uses	si,es
	.enter

	push	di
	push	ds:LMBH_handle
	call	ChunkArrayElementToPtr		; ds:di <- elt to insert before
	jc	append
	call	ChunkArrayInsertAt

added:
	pop	bx
	call	MemDerefDS
	pop	bx

	;
	; allocate a chunk to hold the word
	;
	push	ax
	mov	al, mask OCF_DIRTY
	mov	cx, ss:[bp].WCS_wordLength
	call	LMemAlloc
	mov	cx, ax
	pop	ax

	; 
	; Deref the new element
	;
	call	ChunkArrayElementToPtr		; ds:di <- new element
	mov	ds:[di].WCE_wordChunk, cx
	mov	ds:[di].WCE_count, 1 

	;
	; Copy the word to its chunk
	mov	si, bx
	segxchg	es, ds				; ds:si <- word
	mov	di, cx
	mov	di, es:[di]			; es:di <- word's chunk
	ChunkSizePtr	es, di, cx
	rep	movsb

	segxchg	es, ds			

	inc	ss:[bp].WCS_count		; up the word count
EC <	ERROR_Z	WORD_COUNT_OVERFLOW			>

	.leave
	ret
append:
	call	ChunkArrayAppend
	jmp	added

AddNewWord		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindInsertionPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the element which contains this word, or if
		this is a new word, the element before which it 
		should be inserted.

CALLED BY:	CreateWordTreeCallback
PASS:		ss:bp - WordCountStruct
		es:di - word
		*ds:si - WordCountArray
		cx - first element number
		ax - last element number
RETURN:		carry set if word not found
			ax - element to insert before
		carry clear if found
			ax - element which matches
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindInsertionPoint		proc	near
	uses	bp,di
	.enter

	;
	; Calcualte the median element between the first and last elements
	;
	mov	dx, ax				; dx <- last element
	cmp	cx, dx				; if first = last,
	je	haveMiddle			;   we have the 'median'
	sub	ax, cx				; ax <- diff bet. first, last
	shr	ax				; ax <- 1/2 the diff
	add	ax, cx				; ax <- element halfway between

haveMiddle:
	;
	; Now 	cx = first element
	;	dx = last element
	;	ax = median element
	;
	mov	bx, di				; es:bx <- word
	call	ChunkArrayElementToPtr		; ds:di <- median element
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_NOT_FOUND			>
	call	CompareWords
	jz	found				; word was found!

	jc	rightSide			; look from median to last

leftSide::
	;
	; The new word is less than that of the median element. 
	; If the first element is the last element, or the median is
	; the first element, add the word before the median element.
	;
	cmp	dx, cx				; first = last element?
	stc					; word not found
	je	done				; nowhere else to look
	cmp	ax, cx				; median = first element?
	stc					; then can't go further left
	je	done			
	;
	; This word is less than the word in element ax.  Continue
	; looking in that element's left subtree.
	;   cx = first element, ax = median - 1
	;
	dec	ax				; ax <- median -1
	call	FindInsertionPoint
	
done:
	.leave
	ret

found:
	clc
	jmp	done

rightSide:
	;
	; The new word is greater than that of the median element.
	; If the first element is the last element, add the word after 
	; this element, add the word before the NEXT element.
	;
	inc	ax				; ax <- next element
	cmp	cx, dx				; first = last element?
	stc					; word not found
	je	done				; nowhere else to look
	;
	; This word is greater than the word at the root.  Continue
	; looking in the subtree rooted in the root's right child.
	;
	mov	cx, ax				; first element gets median+1
	mov	ax, dx				; last element stays the same
	call	FindInsertionPoint
	jmp	done

FindInsertionPoint		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare two words

CALLED BY:	FindInsertionPoint

PASS:		*ds:si - WordCountArray
		ds:di  - WordCountArrayElement
		es:bx  - word
		ss:bp  - WordCountStruct
RETURN:		
		if new word =  element's word : if (z)
		if new word >  element's word : if (c)
		if new word <  element's word : if !(c)

DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareWords		proc	near
	uses	ax,cx,si
	.enter

	mov	si, ds:[di].WCE_wordChunk
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, ax
	mov	di, bx
	mov	cx, ss:[bp].WCS_endWord
	sub	cx, di
	cmp	cx, ax
	jle	compare
	mov	cx, ax
compare:
	call	LocalCmpStringsNoCase

	.leave
	ret
CompareWords		endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditDocumentPrintUniqueWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_RESEDIT_DOCUMENT_PRINT_UNIQUE_WORDS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BLOCK_SIZE = 100h

ResEditDocumentPrintUniqueWords		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_PRINT_UNIQUE_WORDS
SBCS <fileName	local	20h dup(char)					>
DBCS <fileName	local	20h dup(wchar)					>
	.enter

	;
	; Change to document directory
	;	
	call	FilePushDir	
	mov	ax, SP_DOCUMENT
	call	FileSetStandardPath

	;
	; Get the file name from Text object.
	;
	push	bp
	lea	bp, ss:[fileName]
	mov	dx, ss				; dx:bp <- filename buffer

	push	si
	GetResourceHandleNS	PrintFileName, bx
	mov	si, offset PrintFileName
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	;
	; Try to create file.  Complain if it already exists.
	;
	mov	ah, (mask FCF_NATIVE_WITH_EXT_ATTRS or \
			FILE_CREATE_TRUNCATE shl offset FCF_MODE)
	mov	al, FILE_DENY_RW or FILE_ACCESS_W
	clr	cx
	push	ds
	mov	ds, dx
	mov	dx, bp				; ds:dx <- filename
	call	FileCreate
	pop	ds
	pop	bp
	jc	error
	mov	dx, ax				; dx <- word count file handle

	;
	; Write all words to file, separated by a newline.
	;
	mov	ax, TEMP_RESEDIT_DOCUMENT_WORD_COUNT_ARRAY
	call	ObjVarFindData
	mov	si, ds:[bx]	
	mov	bx, ds:[bx+2]
	call	MemLock	
	mov	ds, ax				;*ds:si <- WordCountArray

	mov	cx, BLOCK_SIZE
	sub	sp, cx
	mov	bp, sp				; ss:bp <- curPointer
	mov	ax, bp				; ss:ax <- start of buffer
	mov	bx, cs
	mov	di, offset PrintWordToFile
	call	ChunkArrayEnum

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	add	sp, BLOCK_SIZE

	;
	; Close the file.
	; 
	clr	al
	mov	dx, bx
	call	FileClose
error:
	call	FilePopDir	
	.leave
	ret
ResEditDocumentPrintUniqueWords		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintWordToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	- WordCountArray
		ds:di	- WordCountElement
		dx - output file
		es:bp - write buffer
		es:ax - current location in buffer
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Should buffer the writes.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintWordToFile		proc	far
	uses	cx,dx,bp
	.enter

	mov	bx, dx
	push	ax
	mov	si, ds:[di].WCE_wordChunk
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
	mov	ax, cx
	inc	ax				; add NULL
	inc	ax				; add newline
	not	ax				; ax <-  -ax
	add	ax, BLOCK_SIZE			; ax <- bytes left in buffer
	pop	di				; es:di <- cur Pointer
	js	writeBuffer			; not enough room in buffer

	;
	; Now cx = length of word, es:di points to current location
	; in buffer, and ds:si points to the word.  Copy it to buffer
	; and store a null and a newline after it.
	;
	LocalCopyNString		; rep	movs[bw]
	LocalClrChar	ax		; clr	a[lx]
	LocalPutChar	ax, esdi	; stos[bw]
	LocalLoadChar	ax, C_LINEFEED	; mov	a[lx], C_LINEFEED
	LocalPutChar	ax, esdi	; stos[bw]

	mov	ax, di				; ax <- end of buffer

done:
	clc
	.leave
	ret

writeBuffer:
	push	ds
	segmov	ds, es, ax			; ds:bp <- buffer
	mov	cx, di				; di points to end of buff
	sub	cx, bp				; cx <- # used bytes in buff
	clr	al
	mov	dx, bp				
	call 	FileWrite
	pop	ds
	mov	ax, bp				; 
	jmp	done

PrintWordToFile		endp
endif

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortByCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort the WordCountArray by count.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortByCount		proc	near
	uses	bp
	.enter

	mov	cx, ss:[bp].WCS_count
	movdw	bxsi, ss:[bp].WCS_array
	call	MemDerefDS			; *ds:si Chunkarray
	mov	cx, cs
	mov	dx, offset SortCountCompareCallback
	call	ChunkArraySort

	.leave
	ret
SortByCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortCountCompareCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two elements to determine which has a higher count.

CALLED BY:	ArrayQuickSort

PASS:		ds:si	- first array element
		es:di	- second array element

RETURN:		flags set so that caller can jl, je, or jg
		according as first element is less than, equal to,
		or greater than second.

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortCountCompareCallback		proc	far

	mov	ax, es:[di].WCE_count
	cmp	ax, ds:[si].WCE_count

	ret
SortCountCompareCallback		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIsWhitespace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if passed char is whitespace

CALLED BY:	GLOBAL
PASS:		al - char to test (Null bytes are not whitespace)
RETURN:		z flag clear if whitespace
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIsWhiteSpace	proc	near	
	uses	ax
	.enter
	LocalCmpChar	ax, C_GRAPHIC	;cmp	a[lx], C_GRAPHIC
	jz	whitespace
SBCS <	clr	ah							>
	call	LocalIsSpace
exit:
	.leave
	ret
whitespace:
	or	ah, 1			;Clear the Z flag
	jmp	exit
CheckIsWhiteSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceCountText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert count to ascii and put in text object.

CALLED BY:	DocumentCountUniqueWords
PASS:		dx - count
		si - offset of text object 
RETURN:		nothing
DESTROYED:	ax,cx,dx,si,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceCountText		proc	near
	uses	bx,bp
	.enter

SBCS <	sub	sp, 10							>
DBCS <	sub	sp, 20							>
	mov	di, sp
	segmov	es, ss, ax			; es:di - text buffer
	clr	ax, cx				; no fractional part
	call	LocalFixedToAscii

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; text is null-terminated
	movdw	dxbp, esdi
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
SBCS <	add	sp, 10							>
DBCS <	add	sp, 20							>

	.leave
	ret
ReplaceCountText		endp

DocumentCount	ends


