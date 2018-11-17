Comment @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit	/ Document
FILE:		documentSearch.asm

AUTHOR:		Cassie Hartzog, Jan 20, 1993

ROUTINES:
	Name			Description
	----			-----------
EXT	DocumentSearch		MSG_SEARCH
INT	HandleMatch
INT	SearchText
INT	SearchTextCallback
INT	SearchTextCallbackCallback
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	1/20/93		Initial revision


DESCRIPTION:
	Code for handling search and replace.

	$Id: documentSearch.asm,v 1.1 97/04/04 17:14:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentSearchCode	segment	resource


;---

DocSearch_ObjMessage_stack	proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocSearch_ObjMessage_stack	endp

DocSearch_ObjMessage_send		proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocSearch_ObjMessage_send		endp

DocSearch_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocSearch_ObjMessage_call		endp

	ForceRef DocSearch_ObjMessage_send
	ForceRef DocSearch_ObjMessage_stack

;---


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the translation file for a string.

CALLED BY:	MSG_SEARCH

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

		^hdx - block containing SearchReplaceStruct
			(should be freed by handler)

RETURN:		carry set if match was found
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSearch		method  ResEditDocumentClass,
						MSG_SEARCH
	.enter

	sub	sp, size SearchReplaceParams
	mov	bp, sp

	clr	ss:[bp].SRP_flags

	mov	ax, ds:[di].REDI_curResource
	mov	ss:[bp].SRP_curResource, ax	;start with this resource
	mov	ax, ds:[di].REDI_curChunk
	mov	ss:[bp].SRP_curChunk, ax	;start with this chunk
	mov	al, ds:[di].REDI_curTarget
	mov	ss:[bp].SRP_curSource, al		
	mov	ss:[bp].SRP_chunkSource, al

	; are we starting in the OrigText or EditText object?
	;
	push	si
	movdw	bxsi, ds:[di].REDI_editText
	cmp 	al, ST_ORIGINAL
	jne	getRange
	mov	si, offset OrigText

getRange:
	; get text position to start at based on what's selected now
	;
	push	dx, bp
	mov	dx, ss
	lea	bp, ss:[bp].SRP_textRange		;dx:bp <- buffer
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	call	DocSearch_ObjMessage_call
	pop	dx, bp
	pop	si

	pushdw	ss:[bp].SRP_textRange.VTR_start	;save this for backward search
	movdw	bxax, ss:[bp].SRP_textRange.VTR_end
	movdw	ss:[bp].SRP_textRange.VTR_start, bxax	;start from here
EC <	tst	bx						>
EC <	ERROR_NZ RESEDIT_INTERNAL_LOGIC_ERROR			>
	mov	ss:[bp].SRP_endRange, ax	;stop searching here if the
						; search wraps 

	mov	bx, dx				;bx <- SearchReplaceStruct
	call	MemLock
	mov	ss:[bp].SRP_searchStructSeg, ax
	mov	es, ax
	mov	al, es:[SRS_params]
	mov	ss:[bp].SRP_searchOptions, al

	test	al, mask SO_BACKWARD_SEARCH
	jnz	backward
	add	sp, size dword			;clear stack
	push	bx				;save SearchStruct handle

search:
	call	SearchText
	jc	foundMatch			;branch if match found

	;
	; If we didn't find a match, tell the SearchReplaceControl
	; (or whoever is listening at the other end) about it.
	;
	mov	ds, ss:[bp].SRP_searchStructSeg
	movdw	bxsi, ds:[SRS_replyObject]
	mov	ax, ds:[SRS_replyMsg]
	call	DocSearch_ObjMessage_send
	clc					;carry <- not found

foundMatch:

	pop	bx				;bx <- SearchReplaceStruct
	pushf
	call	MemFree
	popf
	jnc	done				;branch if not found

	;
	; If we have a match, update the display to show it
	;
	call	HandleMatch
done:
	add	sp, size SearchReplaceParams
	.leave
	ret

backward:
	popdw	axcx
EC <	tst 	ax						>
EC <	ERROR_NZ RESEDIT_INTERNAL_LOGIC_ERROR			>
	movdw	ss:[bp].SRP_textRange.VTR_start, axcx	;start from here
	mov	ss:[bp].SRP_endRange, cx	;stop searching here 
	push	bx				;save file handle
	jmp	search

DocumentSearch		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A match was found. Display the chunk with the
		matching text selected.

CALLED BY:	DocumentSearch

PASS:		*ds:si  - document
		ds:di	- document instance data
		ss:bp	- SearchReplaceParams

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,si,di,es

PSEUDO CODE/STRATEGY:
	Change resource, chunk and target, if necessary, to display the match.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleMatch		proc	near
	
	mov	al, ss:[bp].SRP_chunkSource
	mov	cx, ss:[bp].SRP_resourceNum
	mov	dx, ss:[bp].SRP_chunkNum

	; if the current chunk changes as a result of this call, 
	; the text selection will be set when the highlight changes.
	; 
	call	DocumentGoToResourceChunkTarget
	call	SetEditMenuState

	movdw	bxsi, ds:[di].REDI_editText
	cmp	ss:[bp].SRP_chunkSource, ST_TRANSLATION
	je	haveOD
	mov	si, offset OrigText
haveOD:
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	mov	dx, size VisTextRange
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	lea	bp, ss:[bp].SRP_textRange
	call	ObjMessage

	ret

HandleMatch		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the search string.

CALLED BY:	DocumentSearch

PASS:		*ds:si 	- document
		ds:di	- document		
		ss:bp	- SearchReplaceParams

RETURN:		carry set if search string is found
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchText		proc	near
	uses	si,di,ds
	.enter 

	segmov	es, ds

	mov	al, ds:[di].REDI_stateFilter
	mov	ah, ds:[di].REDI_typeFilter
	mov	ss:[bp].SRP_filters, ax

	call	GetFileHandle
	mov	ss:[bp].SRP_fileHandle, bx
	call	DBLockMap_DS

	;
	; endRange isn't used until examining the curChunk on a wrapped
	; search.  Save it for now, and store -1, so that the string will
	; be searched to the end.  If the search wraps back to curChunk,
	; we will want to search from text position 0 to endRange.
	; For backward searches, we will search from the last text 
	; position to endRange.
	;
	push	ss:[bp].SRP_endRange
	mov	cx, -1				;enum all resources to end
	mov	ss:[bp].SRP_endRange, cx	;go all the way to end of text
	mov	ss:[bp].SRP_lastChunk, cx	;go to last chunk

	mov	ax, ss:[bp].SRP_curResource	;start at curResource
	push	di, es
	mov	bx, cs
	mov	di, offset SearchTextCallback
	call	MyChunkArrayEnumRange
	pop	di, es
	pop	ss:[bp].SRP_endRange		;restore end range
	jc	done				;match was found!

	;
	; If this is a Replace All search, we have now enumerated 
	; all the resources and chunks, so we are done.
	;
	test	ss:[bp].SRP_flags, mask SRF_REPLACE_ALL
	jnz	done

	;
	; If the search was started at resource 0, original chunk 0,
	; at text position 0, then the entire database has been searched.
	;
	tst	ss:[bp].SRP_curResource
	jnz	continue
	tst	ss:[bp].SRP_curChunk
	jnz	continue
	cmp	ss:[bp].SRP_curSource, ST_ORIGINAL
	jne	continue
	tst	ss:[bp].SRP_endRange
	jz	done

continue:
	;
	; No match was found through the last (first, if backward search) 
	; resource.  Start the search over at first (last) resource,
	; stopping at curResource, curChunk, endRange.
	; Start the search at the first (last) text position.
	;
	clrdw	ss:[bp].SRP_textRange.VTR_start
	mov	ax, es:[di].REDI_curChunk
	mov	ss:[bp].SRP_lastChunk, ax	;stop at this chunk

	test	ss:[bp].SRP_searchOptions, mask SO_BACKWARD_SEARCH
	jnz	backward
	clr	ax				;start at resource 0
	mov	cx, ss:[bp].SRP_curResource	;enum this # of resources,
	inc	cx				; counting from 1

enumRange:
	mov	bx, cs
	mov	di, offset SearchTextCallback
	call	MyChunkArrayEnumRange
	
done:
	call	DBUnlock_DS
	.leave
	ret

backward:
	movdw	ss:[bp].SRP_textRange.VTR_start, -1
	call	ChunkArrayGetCount		;# of resources
	mov	ax, cx
	dec	ax				;start at last resource
	mov	bx, ss:[bp].SRP_curResource
	sub	cx, bx				;cx = # elements to enum
	jmp	enumRange

SearchText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchTextCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the ResourceArray for this resource, 
		looking for the passed string.

CALLED BY:	SearchText (via MyChunkArrayEnumRange)
PASS:		*ds:si	- ResourceMapArray
		ds:di	- ResourceMapElement
		ss:bp	- SearchReplaceParams
		ax	- element number

RETURN:		carry set if text found somewhere in a this resource
		resourceNum, chunkNum set to matching chunk

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
	Set curChunk = -1 on first pass (from current resource to
	end).  If no match found in that part of the database, go
	from first resource (last resource if backward search) to
	curResource.  On that pass, curChunk is set to its real value.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchTextCallback		proc	far
	.enter 

	push	ds:[LMBH_handle]
	push	ss:[bp].SRP_endRange

	mov	cx, ax
	mov	ss:[bp].SRP_resourceNum, cx		;set new resource #

	segmov	es, ds
	mov	bx, ss:[bp].SRP_fileHandle
	mov	ax, es:[di].RME_data.RMD_group
	mov	dx, ax					;pass group in dx
	mov	di, es:[di].RME_data.RMD_item
	call	DBLock_DS				;*ds:si <-ResourceArray
	
	; if this is not the current resource, start at first (last)
	; chunk number, and examine all of its text.
	;
	cmp	cx, ss:[bp].SRP_curResource
	je	currentResource

	; if this resource has no chunks which meet the filter criteria
	; don't have anything to enum.
	;
	call	MyChunkArrayGetCount	
	tst	cx
	jz	done

	clr	ax					;start at first chunk,
	mov	ss:[bp].SRP_chunkSource, ST_ORIGINAL	; original item
	clrdw	ss:[bp].SRP_textRange.VTR_start		;start at beginning
	mov	ss:[bp].SRP_endRange, -1		;go to end of text
;	mov	cx, -1					;examine all chunks

	test	ss:[bp].SRP_flags, mask SRF_REPLACE_ALL
	jz	checkBackward
	mov	ss:[bp].SRP_chunkSource, ST_TRANSLATION
	jmp	enumRange

checkBackward:
	test	ss:[bp].SRP_searchOptions, mask SO_BACKWARD_SEARCH
	jz	enumRange

	movdw	ss:[bp].SRP_textRange.VTR_start, -1	;start at end
;	call	MyChunkArrayGetCount	
	dec	cx					;cx <- last chunk's #
	mov	ax, cx					;start at last chunk
	mov	ss:[bp].SRP_chunkSource, ST_TRANSLATION ;start w/trans item
	mov	cx, -1					;go to chunk 0

enumRange:
	mov	bx, cs
	mov	di, offset SearchTextCallbackCallback
	call	MyChunkArrayEnumRange			;carry set if found

done:
	call	DBUnlock_DS
	pop	ss:[bp].SRP_endRange
	pop	bx
	call	MemDerefDS

	.leave
	ret

currentResource:
	;
	; If curChunk = -1, there are no visible chunks in this resource
	; (becuase of filters). So don't enum them.
	;
	mov	ax, ss:[bp].SRP_curChunk	;start at curChunk
	cmp	ax, -1				;are there no chunks?
	je	done

	;
	; This is the current resource, so don't examine the whole thing.
	; If this is the first pass (lastChunk = -1), start at chunkNum
	; and go to last chunk.  (When cx = -1, MyChunkArrayEnumRange 
	; goes backwards to chunk 0 or forwards to the last chunk.)
	;
	mov	cx, ss:[bp].SRP_lastChunk	;# of last chunk to enum
	cmp	cx, -1
	je	enumRange

	;
	; If the search has wrapped and we've come back to curResource,
	; start at chunk 0 for a forward search and go to lastChunk.
	; On a backward search, start at the last chunk and go to lastChunk.
	;
	test	ss:[bp].SRP_searchOptions, mask SO_BACKWARD_SEARCH
	jnz	backward

	clr	ax					;start at chunk 0
	inc	cx					;# of chunks to enum 
	jmp	enumRange


backward:
	call	MyChunkArrayGetCount		;cx <- #chunks passing filters
	mov	ax, cx
	dec	ax				;start at last element
	mov	bx, ss:[bp].SRP_lastChunk
	sub	cx, bx				;cx = # elements to enum
	jmp	enumRange

SearchTextCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchTextCallbackCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the search string in this ResourceArrayElement.

CALLED BY:	SearchTextCallback (via MyChunkArrayEnumRange)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ss:bp	- SearchReplaceParams
		dx	- resource group number
		ax	- element number

RETURN:		carry set if found,
		chunkNum set to matching element
		textRange set to range of matching text

DESTROYED:	ax,cx

PSEUDO CODE/STRATEGY:
	If this the start of a search, the first chunk examined is
	curChunk.  Want to start from textRange.VTR_start.
	If the search fails, set it to 0 so the next search will
	start from the beginning of the next chunk's text.

	If this is the end of a search, last chunk to be examined is
	curChunk.  In this case, start searching from 0 (passed in
	textRange) but stop at the position given in endRange.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchTextCallbackCallback		proc	far
	uses	dx
	.enter

	push	ds:[LMBH_handle]
	push	ss:[bp].SRP_endRange		;save character to stop at
						; if = -1, go to end of string
	mov	ss:[bp].SRP_chunkNum, ax	;save this chunk's number

	; If not text, don't need to bother with it.
	;
	mov	cl, ds:[di].RAE_data.RAD_chunkType
	test	cl, mask CT_TEXT
	clc
	LONG	jz	done

	; If this is the last item to be examined, used the passed
	; endRange value, else set it to -1 to search to end of string.
	; 
	mov	bx, ss:[bp].SRP_curResource
	cmp	bx, ss:[bp].SRP_resourceNum
	jne	goToEnd
	cmp	ax, ss:[bp].SRP_lastChunk
	jne	goToEnd
	mov	al, ss:[bp].SRP_chunkSource
	cmp	al, ss:[bp].SRP_curSource
	je	continue
goToEnd:
	mov	ss:[bp].SRP_endRange, -1		;go to end of string

continue:
	; see if we need to start on the transItem, which is the
	; case if we're starting in a transItem
	;
	mov	ax, dx				;ax <- group
	mov	dx, ds:[di].RAE_data.RAD_origItem
	cmp	ss:[bp].SRP_chunkSource, ST_ORIGINAL
	je	firstSearch
	
	tst	ds:[di].RAE_data.RAD_transItem
	jz	firstSearch
	mov	dx, ds:[di].RAE_data.RAD_transItem
firstSearch:
	call	SearchStringInItem
	LONG	jc	done

	test	ss:[bp].SRP_searchOptions, mask SO_BACKWARD_SEARCH
	jz	forward

	; if this is an orig item, set chunkSource to translation and
	; continue the enumeration
	;
	movdw	ss:[bp].SRP_textRange.VTR_start, -1	;start at end
	cmp	ss:[bp].SRP_chunkSource, ST_ORIGINAL
	mov	ss:[bp].SRP_chunkSource, ST_TRANSLATION	;set for next callback
	clc
	LONG	je	done
	mov	cl, ST_ORIGINAL
	jmp	nextItem

forward:
	clrdw	ss:[bp].SRP_textRange.VTR_start		;start at beginning
	;
	; if this is a "Replace All" search, don't want to examine
	; the original item so leave chunkSource = ST_TRANSLATION and quit
	clc
	test	ss:[bp].SRP_flags, mask SRF_REPLACE_ALL
	jnz	done

	; If this is a trans item, set chunkSource to original and
	; enumerate the next chunk.
	;
	cmp	ss:[bp].SRP_chunkSource, ST_TRANSLATION
	mov	ss:[bp].SRP_chunkSource, ST_ORIGINAL	;set for next callback
	clc
	je	done
	mov	cl, ST_TRANSLATION

nextItem:	
	; No match found in the first item.  Set up to start searching
	; the other item from the beginning.
	;
	mov	bl, ss:[bp].SRP_chunkSource		;save this chunkSource
	mov	ss:[bp].SRP_chunkSource, cl		;store new source

	; is this the last chunk to be examined?
	;
	mov	dx, ss:[bp].SRP_curResource
	cmp	dx, ss:[bp].SRP_resourceNum
	jne	secondSearch
	mov	dx, ss:[bp].SRP_chunkNum
	cmp	dx, ss:[bp].SRP_lastChunk
	jne	secondSearch				;no, some other chunk

	;
	; The search has wrapped and this is the last chunk to be examined.
	; If the source where the search started is the same as the source
	; of the item just examined, we can stop now.
	;
	pop	ss:[bp].SRP_endRange			;restore endRange
	push	ss:[bp].SRP_endRange	
	cmp	ss:[bp].SRP_curSource, bl
	clc
	je	done

secondSearch:
	mov	dx, ds:[di].RAE_data.RAD_origItem
	cmp	cl, ST_ORIGINAL
	je	haveItem
	tst	ds:[di].RAE_data.RAD_transItem	
	jz	haveItem
	mov	dx, ds:[di].RAE_data.RAD_transItem	;then use origItem
haveItem:
	mov	cl, ds:[di].RAE_data.RAD_chunkType
	call	SearchStringInItem
	jc	done
	
	; set the source type for the next callback so it knows where to start
	;
	mov	al, ST_TRANSLATION
	test	ss:[bp].SRP_searchOptions, mask SO_BACKWARD_SEARCH
	movdw	ss:[bp].SRP_textRange.VTR_start, -1	;start at end
	jnz	saveSource
	mov	al, ST_ORIGINAL
	clrdw	ss:[bp].SRP_textRange.VTR_start		;start at beginning
	
saveSource:
	mov	ss:[bp].SRP_chunkSource, al
	clc
done:
	pop	ss:[bp].SRP_endRange
	pop	bx
	call	MemDerefDS
	.leave
	ret

SearchTextCallbackCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchStringInItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the search string in this item

CALLED BY:	SearchTextCallbackCallback
PASS:		ss:bp	- SearchReplaceParams
		ax	- resource group number
		dx	- item number
		cl	- ChunkType

RETURN:		carry set if found
DESTROYED:	dx,es

PSEUDO CODE/STRATEGY:
    For forward search:
	textRange.VTR_start gives position to start at.  
	If endRange = -1, search to end of string.
	If non-zero, stop at that text position.
	It will never be non-zero unless textRange.VTR_start = 0.

    For backward search:
	textRange.VTR_start gives position to start at.
	If it = -1, start from end of string. Go to beginning.
	If endRange = -1, search backward to start of string.
	else stop at that char.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchStringInItem		proc	near
	uses	ax,bx,cx,si,di,ds
	.enter

	mov	bx, ss:[bp].SRP_fileHandle
	mov	di, dx
	call	DBLock
	mov	di, es:[di]			;es:di <- string to search

	test	cl, mask CT_MONIKER
	jz	notMoniker
	add	di, MONIKER_TEXT_OFFSET

notMoniker:
	push	bp
	mov	ax, ss:[bp].SRP_textRange.VTR_start.low
	mov	si, ss:[bp].SRP_endRange
	mov	ds, ss:[bp].SRP_searchStructSeg

	; look for the search string in string at es:di
	; pass:
	;	es:bp - ptr to first character in string
	;	es:di - ptr to character to start search at
	;	es:bx - ptr to last character to include in search
	;	dx    - # chars in string es:bp (0 for null-terminated)
	;  	ds:si - ptr to string to match
	; 	cx    - # chars in match string
	;       al    - SearchOptions
	;
	; return:
	; 	es:di 	- ptr to start of string found
	;	cx	- # chars matched
	;
	mov	bp, di			;es:bp <- first char in string
	call	GetStringSize		;cx <- # chars in string w/o NULL

	test ds:[SRS_params], mask SO_BACKWARD_SEARCH
	jz	forward
	tst	ax			;if at front of string, done
	jz	popBP

	; if VTR_start = -1, start at last char in string
	;
	mov	bx, bp			;es:bx <- first char in string
	cmp	ax, -1
	jne	$10
	add	di, cx
DBCS <	add	di, cx							>
	dec	di			;es:di <- last char in string
DBCS <	dec	di							>
	jmp	getLastChar

$10:
;	mov	bx, bp			;es:bx <- char to stop at (first char)
	add	di, ax			;es:di <- cursor position
DBCS <	add	di, ax							>
	dec	di			;es:di <- char to start at
DBCS <	dec	di							>
	jmp	search

forward:
	cmp	ax, cx			;if pointing at or beyond last 
	jae	popBP			; character, don't search string

	mov	bx, cx			;bx <- length of string
DBCS <	shl	bx, 1			;bx <- size of string		>
	add	bx, di			;es:bx <- NULL
	dec	bx			;es:bx <- last char in string
DBCS <	dec	bx							>
	add	di, ax			;es:di <- char to start at
DBCS <	add	di, ax							>

getLastChar:
	cmp	si, -1			;go to end if endRange = -1
	je	search			; else si = position to stop at 
	mov	bx, bp
	add	bx, si			;es:bx <- last char to look at
DBCS <	add	bx, si							>
SBCS <	tst	{byte}es:[bx]		;is it a NULL? (which happens when	>
DBCS <	tst	{word}es:[bx]						>
	jnz	search			; cursor is at the end of the text)
	dec	bx			;yes, back up one byte.
DBCS <	dec	bx							>
search:
	lea	si, ds:[SRS_searchString]
	clr	cx			;search string is null-terminated
	clr	dx			;string to seardch is null-terminated
	mov	al, ds:[SRS_params]	;al <- SearchOptions
	call	TextSearchInString	;carry set if not found
	cmc				;now carry clear, to continue enum
	jnc	popBP
	
	; Search string was found. Calculate its range.
	;
	sub	di, bp			;di <- start of match range
if (DBCS_PCGEOS and ERROR_CHECK)
	test	di, 1
	ERROR_NZ	RESEDIT_IS_ODD
endif
DBCS <	shr	di, 1							>
	pop	bp
	clr	ax
	movdw	ss:[bp].SRP_textRange.VTR_start, axdi
	add	di, cx			;di <- end of match range
	movdw	ss:[bp].SRP_textRange.VTR_end, axdi
	stc

unlock:
	call	DBUnlock
	
	.leave
	ret
popBP:
	pop	bp
	clc
	jmp	unlock

SearchStringInItem		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of chars in the string, not counting
		the null, if present.

CALLED BY:	SearchStringInItem
PASS:		es:di	- string (in a chunk)
RETURN:		cx - number of chars
DESTROYED:	

PSEUDO CODE/STRATEGY:
	String may not be null terminated, so count returned by
	LocalStringLength could be invalid.  Take the lesser of the
	chunk size and string length.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStringSize		proc	near
		uses	ax
		.enter

		call	LocalStringLength	; cx <- # chars
		mov	ax, cx
		ChunkSizePtr	es, di, cx	; cx <- # bytes in chunk
DBCS <		shr	cx			; cx <- # chars in chunk >
		cmp	cx, ax
		jb	done
		mov	cx, ax
done:
		.leave
		ret
GetStringSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyChunkArrayGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of chunks meeting the filter criteria
		in this ResourceArray.

CALLED BY:	(INTERNAL) MyChunkArrayEnumRange, 

PASS:		*ds:si	- ChunkArray
		ss:bp	- SearchReplaceParams
		
RETURN:		cx	- number of elements meeting filter criteria

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If this is a ResourceMap chunk array, just call ChunkArrayGetCount,
	since there are no filters for resources.

	Otherwise, call ResArrayGetCount, which works only on ResourceArrays
	and takes the chunk filters into account.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyChunkArrayGetCount		proc	near

	push	di
	mov	di, ds:[si]
	cmp	ds:[di].RAH_arrayType, AT_RESOURCE_ARRAY
	jne	resourceMap

	push	dx
	mov	dx, ss:[bp].SRP_filters
	call	ResArrayGetCount
	pop	dx
	pop	di
	ret

resourceMap:
	call	ChunkArrayGetCount
	pop	di
	ret

MyChunkArrayGetCount		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyChunkArrayElementToPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a pointer the desired chunk array element.

CALLED BY:	MyChunkArrayEnumRange

PASS:		*ds:si	- ChunkArray
		ax	- element number

RETURN:		ds:di	- element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If this is a ResourceMap chunk array, call ChunkArrayElementToPtr,
	since there are no filters for resources.

	Otherwise, call ResArrayElementToPtr, which returns a pointer
	to the ax'th chunk in the resource which meets the filter criteria.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyChunkArrayElementToPtr		proc	near

	mov	di, ds:[si]
	cmp	ds:[di].RAH_arrayType, AT_RESOURCE_ARRAY
	jne	resourceMap

	push	dx
	mov	dx, ss:[bp].SRP_filters
	call	ResArrayElementToPtr
	pop	dx
	ret

resourceMap:
	call	ChunkArrayElementToPtr
	ret

MyChunkArrayElementToPtr		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyChunkArrayEnumRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An enumeration that can go backwards, as well as
		forwards.

CALLED BY:	
PASS:		*ds:si	- ChunkArray
		ax	- element number to start at
		cx	- # elements to enum, or -1 to go to end
		bx:di	- callback
		ss:bp	- SearchReplaceParams

		dx,bp,es - passed data

		Passed to callback:
			*ds:si	- ResourceArray
			ds:di	- ResourceArrayElement
			ax	- element number
			dx,bp,es
			
RETURN:		carry set if enumeration aborted by callback

DESTROYED:	ax,bx,cx,di,es

PSEUDO CODE/STRATEGY:
	On backward searches, start from element ax and go backwards
	cx elements, or to 0 if cx = -1.
	On forward searches, if cx = -1, go from element ax to end.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyChunkArrayEnumRange		proc	near

passedBP	local	word	push	bp
callback	local	fptr	
	.enter

	movdw	ss:[callback], bxdi
	push	bp
	mov	bp, ss:[passedBP]
	mov	bl, ss:[bp].SRP_searchOptions
	test	bl, mask SO_BACKWARD_SEARCH
	pop	bp
	jz	forward

	cmp	{word}cx, -1
	je	toEnd

EC <	push	ax					>
EC <	inc	ax					>
EC <	cmp	ax, cx					>
EC <	ERROR_L RESEDIT_INTERNAL_LOGIC_ERROR		>
EC <	pop	ax					>
EC <	jmp	enumLoop				>

toEnd:
	mov	cx, ax
	inc	cx
	jmp	enumLoop

forward:
	cmp	cx, -1
	jne	enumLoop

	push	bp
	mov	bp, ss:[passedBP]		;ss:bp <- SearchReplaceParams
	call	MyChunkArrayGetCount		;cx <- # of elements meeting
						; the filter criteria
	sub	cx, ax				;cx <- # elements to search
	pop	bp
	cmp	cx, 0
	clc
	jl	done

enumLoop:
EC <	cmp	ax, -1					>
EC <	ERROR_E	CHUNK_ARRAY_ELEMENT_NOT_FOUND		>
	push	ax, bx, cx, bp
	lea	bx, ss:[callback]		;bx:di <- callback routine
	mov	bp, ss:[passedBP]		;ss:bp <- SearchReplaceParams

	call	MyChunkArrayElementToPtr	;ds:di <- element, cx <- size
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND		>

	call	{dword} ss:[bx]			; call the callback routine
	pop	ax, bx, cx, bp
	jc	done
	
	inc	ax			;assume this is a forward search
	push	bp
	mov	bp, ss:[passedBP]
	test	ss:[bp].SRP_searchOptions, mask SO_BACKWARD_SEARCH
	pop	bp
	jz	doLoop
	sub	ax, 2				
doLoop:
	loop	enumLoop
	clc
done:
	.leave
	ret

MyChunkArrayEnumRange		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentReplaceCurrent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SearchReplaceControl sends this when user wants to
		replace current selection with the passed string.

CALLED BY:	MSG_REPLACE_CURRENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		dx - data block

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	May want to disable the replace buttons when the current
	selection is in the original, if possible.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentReplaceCurrent		method dynamic ResEditDocumentClass,
						MSG_REPLACE_CURRENT

	cmp 	ds:[di].REDI_curTarget, ST_ORIGINAL
	LONG	je	noReplace

	; Pass the MSG_REPLACE_CURRENT on to the text object.
	; This will cause a MSG_RESEDIT_DOCUMENT_USER_MODIFIED_TEXT 
	; message to be sent.  Its handler will update the mnemonic list.
	;
	push	si
	movdw	bxsi, ds:[di].REDI_editText
	mov	ax, MSG_REPLACE_CURRENT
	call	DocSearch_ObjMessage_call
	pop	si

	; XXX: We would like EditText to regain the focus, but this
	; doesn't quite do it....
	;
	call	GetDisplayHandle
	mov	si, offset RightView
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	DocSearch_ObjMessage_send

noReplace:
	ret

DocumentReplaceCurrent		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentReplaceAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	SearchReplaceControl sends this when user wants to
		replace All selection with the passed string.

CALLED BY:	MSG_REPLACE_ALL_OCCURRENCES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		dx - data block
		cx - non-zero if should replace throughout document,
			0 to replace from current position

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	Save the current chunk, so the database is up to date.
	Save the filters and then clear them.
	
	Start searching from resource 0, chunk 0, translation item,
	text position 0.  If a match is found, replace it.
	
	Update the SRP_cur* values to the match values.
	Continue the search until no more matches are found in translation
	items.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Because of the way SearchText works, wrapping the search if
	nothing is found from where it started to the end, it may
	make two complete searches through all the translation items
	before stopping.  When the last match has been found, the next
	search will cycle through all chunks until it returns to that 
	one, where it started.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentReplaceAll		method dynamic ResEditDocumentClass,
						MSG_REPLACE_ALL_OCCURRENCES

	sub	sp, size SearchReplaceParams
	mov	bp, sp

	mov	ss:[bp].SRP_flags, mask SRF_REPLACE_ALL

	; save current filters, then clear them so that nothing is
	; skipped in the search
	;
	mov	al, ds:[di].REDI_typeFilter
	mov	ah, ds:[di].REDI_stateFilter
	push	ax			
	clr	ds:[di].REDI_typeFilter
	clr	ds:[di].REDI_stateFilter
	
	mov	bx, dx				; bx <- SearchReplaceStruct
	push	bx
	call	MemLock
	mov	ss:[bp].SRP_searchStructSeg, ax
	clr	ax
	mov	ss:[bp].SRP_curResource, ax
	mov	ss:[bp].SRP_curChunk, ax
	mov	ss:[bp].SRP_curSource, ST_TRANSLATION
	mov	ss:[bp].SRP_chunkSource, ST_TRANSLATION
	clrdw	ss:[bp].SRP_textRange.VTR_start	; start from text position 0
	clr	ss:[bp].SRP_endRange		; stop at 0 if search wraps

searchLoop:
					
	call	SearchText
	jnc	done
	call	HandleReplaceMatch		;dx <- new transItem
	call	UpdateTextRange			;update SRP_textRange to
						; continue the search

	; continue the search from resourceNum
	;
	mov	bx, ss:[bp].SRP_resourceNum
	mov	ss:[bp].SRP_curResource, bx

	; 
	; if the match was found in the current resource, we need to
	; know later so that we can update the display to show the changes
	;
	cmp	bx, ds:[di].REDI_curResource
	jne	nextChunk
	ornf	ss:[bp].SRP_flags, mask SRF_RESOURCE_DIRTY

	; 
	; if the match was found in the current chunk, we need to
	; save the new transItem in the document's instance data
	;
	mov	cx, ss:[bp].SRP_chunkNum
	cmp	cx, ds:[di].REDI_curChunk
	jne	nextChunk

	; if no TransItem was created, don't save it
	; (this will happen if attempt is made to alter an OrigItem)
	;
EC <	tst	dx						>
EC <	jz	nextChunk					>
	mov	ds:[di].REDI_transItem, dx

nextChunk:
	; continue the search from chunkNum
	;
	mov	cx, ss:[bp].SRP_chunkNum
	mov	ss:[bp].SRP_curChunk, cx
	jmp	searchLoop

done:
	pop	bx				; ^hbx <- SearchReplaceStruct
	call	MemFree

	pop	ax
	mov	ds:[di].REDI_typeFilter, al
	mov	ds:[di].REDI_stateFilter, ah

	call	UpdateDisplay
	
	add	sp, size SearchReplaceParams
	ret

DocumentReplaceAll		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateTextRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After a match has been found and the text has
		been replaced, update the text start range so that
		the search continues after the text just inserted.

CALLED BY:	DocumentReplaceAll
PASS:		ss:bp	- SearchReplaceParams

RETURN:		nothing
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
	Text from VTR_start to VTR_end was deleted, and replace
	string was inserted at VTR_start.  So add length of replace
	string to get first unexamined char in original string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateTextRange		proc	near
	push	si
	call	GetReplaceStringAndLength	;cx <- length, es:si <- string
DBCS <	shl	cx, 1							>
	add	ss:[bp].SRP_textRange.VTR_start.low, cx
	pop	si	
	ret
UpdateTextRange		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleReplaceMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A match has been found in the process of a Replace All
		search.  Save the changes.

CALLED BY:	DocumentReplaceAll
PASS:		*ds:si	- document
		ds:di	- document
		ss:bp	- SearchReplaceParams

RETURN:		dx	- new TransItem number
DESTROYED:	

PSEUDO CODE/STRATEGY:
	If there is no TransItem yet, copy the OrigItem to create one.
	Get the length and position of the search string match in 
	the TransItem, and delete those bytes.
	Get the length of the replace string and insert that many 
	bytes into the TransItem at the offset where the text was deleted.
	Copy the replace string into the inserted bytes.
	Store the new DBItem in the ResourceArrayElement.

	If the chunk is a moniker, get the new mnemonic offset and
	update the document's instance.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleReplaceMatch		proc	near
	uses	si,di,ds,bp
	.enter

	; original elements should be filtered out of the search,
	; but just in case....
	;
EC <	clr	dx					>
EC <	cmp	ss:[bp].SRP_chunkSource, ST_ORIGINAL	>
EC <	LONG	je	done				>

	mov	bx, ss:[bp].SRP_fileHandle
	call	DBLockMap_DS			;*ds:si <- ResourceMap
	push	ds:[LMBH_handle]

	mov	ax, ss:[bp].SRP_resourceNum
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBLock_DS			;*ds:si <- ResourceArray

	push	ax
	mov	ax, ss:[bp].SRP_chunkNum
	call	ChunkArrayElementToPtr		; ds:di <- ResourceArrayElement
	pop	ax

	; If already have a transItem, skip the copy below
	;
	mov	cx, ds:[di].RAE_data.RAD_origItem
	tst	ds:[di].RAE_data.RAD_transItem
	jnz	haveItem

	; make a copy of the original item to use below
	;
	push	bp
	mov	di, cx				;copy the orig item
	mov	cx, ax				;put it in the same group
	mov	bp, bx				; and in the same file
	push	ds:[LMBH_handle]
	call	DBCopyDBItem			;di <- new item
	pop	bx
	call	MemDerefDS
	call	DBDirty_DS
	pop	bp

	; deref the element again, and save the new transItem 
	;
	push	ax, di				;save group #, new item #
	mov	ax, ss:[bp].SRP_chunkNum
	call	ChunkArrayElementToPtr
	pop	ax, ds:[di].RAE_data.RAD_transItem

haveItem:
	; calculate the offset at which the search string match is located
	;
	mov	cl, ds:[di].RAE_data.RAD_chunkType
	mov	di, ds:[di].RAE_data.RAD_transItem
	mov	dx, ss:[bp].SRP_textRange.VTR_start.low
DBCS <	shl	dx, 1							>
	test	cl, mask CT_MONIKER
	jz	haveDeleteOffset
	add	dx, MONIKER_TEXT_OFFSET			;dx <- offset to delete

haveDeleteOffset:
	;
	; calculate the length of the search string match and 
	; delete those bytes
	;
	push	cx, si				;save ChunkType, ResArray chunk
	mov	cx, ss:[bp].SRP_textRange.VTR_end.low
	sub	cx, ss:[bp].SRP_textRange.VTR_start.low	;cx<- #chars to delete
DBCS <	shl	cx, 1				;cx <- # bytes to delete>
	mov	bx, ss:[bp].SRP_fileHandle
	call	DBDeleteAt
	;
	; get the length of the replace string and insert that many bytes
	;
	call	GetReplaceStringAndLength	;cx <- # chars to insert
						;es:si <- replace string
DBCS <	shl	cx, 1				;cx <- # bytes to insert>
	call	DBInsertAt			;add bytes for replace string
	;
	; now copy the replace string to the inserted bytes
	;    dx = offset within text string to insert at
	;
	push	cx, ds
	segmov	ds, es				;ds:si <- source string
	call	DBLock
	mov	di, es:[di]
	push	di
	add	di, dx				;es:di <- destination
	rep	movsb				;copy replace string
	pop	di
	pop	dx, ds

	pop	cx, si
	test	cl, mask CT_MONIKER
	jz	unlock
	;
	; If there was no mnemonic char in text, there won't be one now.
	;
	mov	cl, es:[di].VM_data.VMT_mnemonicOffset
	cmp	cl, VMO_NO_MNEMONIC
	je	unlock
	cmp	cl, VMO_CANCEL
	je	unlock
	cmp	cl, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	je	unlock
	;
	; Get the new mnemonic offset.
	;
	push	bp
	lea	bp, ss:[bp].SRP_textRange
	mov	ax, dx 
	clr	dx			
	call	CalculateNewMnemonicOffset
	mov	es:[di].VM_data.VMT_mnemonicOffset, cl
	pop	bp
	;
	; Update mnemonicType in ResourceArrayElement.
	; mnemonicChar won't change (we may have lost the mnemonic in
	; the replace operation, but the the character won't change).
	;
	mov	dl, cl
	mov	ax, ss:[bp].SRP_chunkNum
	call	ChunkArrayElementToPtr		;ds:di <- ResourceArrayElement
	mov	ds:[di].RAE_data.RAD_mnemonicType, dl
	call	DBDirty_DS
	jmp	noDeref

unlock:
	mov	ax, ss:[bp].SRP_chunkNum
	call	ChunkArrayElementToPtr		;ds:di <- ResourceArrayElement

noDeref:
	mov	dx, ds:[di].RAE_data.RAD_transItem	;return new item #

	call	DBDirty
	call	DBUnlock			;unlock the item

	call	DBUnlock_DS			;unlock the ResourceArray
	pop	bx
	call	MemDerefES
	call	DBUnlock			;unlock the ResourceMap
done::
	.leave
	ret
HandleReplaceMatch		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetReplaceStringAndLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pointer to the replace string and its length.

CALLED BY:	HandleReplaceMatch
PASS:		ss:bp	- SearchReplaceParams
RETURN:		es:si	- replace string
		cx	- its length
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetReplaceStringAndLength	proc	near

	mov	es, ss:[bp].SRP_searchStructSeg
	mov	si, offset SRS_searchString	; es:si <- search string
	add	si, es:[SRS_searchSize]		; es:si <- replace string
DBCS <	add	si, es:[SRS_searchSize]					>
	mov	cx, es:[SRS_replaceSize]	; cx <- string length w/NULL
	dec	cx				; substract the NULL

	ret
GetReplaceStringAndLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace All search and replace has completed, now 
		update the display to reflect any changes in the
		current resource.

CALLED BY:	DocumentReplaceAllOccurrences

PASS:		*ds:si	- document
		ds:di	- document
		ss:bp	- SearchReplaceParams

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	SRF_RESOURCE_DIRTY does not tell anything abuot which chunks
	have changed, and whether or not they meet the current filter
	criteria, so it is possible that the redraw is unnecessary.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDisplay		proc	near
	.enter

	; no chunks in this resource have changed, so we're done
	;
	test	ss:[bp].SRP_flags, mask SRF_RESOURCE_DIRTY
	jz	done

	; in case any of the chunk's sizes have changed as a result
	; of the replace, recalculate the chunk positions here
	; (and set the new document bounds in the views accordingly)
	;
	mov	cx, ds:[di].REDI_viewWidth
	call	RecalcChunkPositions			;dx <- new height
	cmp	dx, ds:[di].REDI_docHeight
	je	noHeightChange

	; invalidate both content and document
	;
	mov	ax, MSG_VIS_INVALIDATE
	call	SendToContentObjects

done:
	.leave
	ret

noHeightChange:
	;
	; invalidate only the document	
	;
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	jmp	done

UpdateDisplay		endp

DocumentSearchCode	ends


;----------------------------------------------------------------------------
;		Methods for spellcheck
;----------------------------------------------------------------------------

DocumentSearchCode	segment resource

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSpellCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue spell checking from current point in document.

CALLED BY:	MSG_SPELL_CHECK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		ss:bp - SpellCheckInfo
		dx - size of SpellCheckInfo
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSpellCheck		method dynamic ResEditDocumentClass,
						MSG_SPELL_CHECK

	; pass the call to the SpellText object
	;
	mov	bx, ds:[di].REDI_editText.handle
	mov	si, offset SpellText
	clr	di
	call	ObjMessage
	ret
DocumentSpellCheck		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGetObjectForSearchSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The search has either just begun or has reached the end 
		of the text in this object and needs the next object in
		which to continue the search.

CALLED BY:	MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		^lcx:dx - object that search/replace is currently in
		bp - GetSearchSpellObjectParam
RETURN:		^lcx:dx - the requested object
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGetObjectForSearchSpell		method dynamic ResEditTextClass,
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL

	push	cx,dx,bp

	mov	ax, bp
	mov	bp, ds:[di].REDI_resArrayGroup
	mov	dx, ds:[di].REDI_transItem

	andnf	ax, mask GetSearchSpellObjectType
	cmp	ax, GSSOT_NEXT_OBJECT
	je	getNextChunk

	; store current res/chunk in "spell position" var

	jmp	getItem
	
getNextChunk:
	call	GetFileHandle
	call	LockMap_DS
	mov	ax, (current resource number)
	call	ChunkArrayPtrToElement
EC<	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	mov	cx, (current chunk number)
	inc	cx
	cmp	cx, ds:[di].RME_data.RMD_numChunks
	jae	goToNextResource
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBUnlock_DS

	call	DBLock_DS

	jmp	getItem

getItem:
	mov	ax, bp
	mov	di, dx
	call	DBLock_DS
	call	
	ret
TextGetObjectForSearchSpell		endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDisplayObjectForSearchSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the object onto the screen.

CALLED BY:	MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentDisplayObjectForSearchSpell	method dynamic ResEditDocumentClass,
				MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
	ret
DocumentDisplayObjectForSearchSpell		endm

DocumentSearchCode	ends
