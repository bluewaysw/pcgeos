COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		
FILE:		mainSearch.asm

AUTHOR:		Jonathan Magasin, Jul 18, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/18/94   	Initial revision
	martin	8/4/94		Made to work

DESCRIPTION:
	Search code for the ContentText.
		

	$Id: mainSearch.asm,v 1.1 97/04/04 17:49:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ContentLibraryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiates a search.

CALLED BY:	MSG_SEARCH
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		ax	= message #
		dx - handle of block containing words 
			Format of block:
				SearchReplaceStruct<>
				data	Null-Terminated Search String

RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	if a match is found, will cause the displayed text to change

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVSearch				method dynamic ContentGenViewClass, 
					MSG_SEARCH
SEARCH_LOCALS
		.enter

		push	bp
		
		call	AppHoldUpInput
		call	MSPrepareForSearch		;saves dx, ds, si
		jc	exit				;no search if error

		call	MSSearchText			;cx = match offset
		jc	noMatch
	;
	; A match was found.  Update the display to show the 
	; matching text.
	;
		call	MSDisplayMatch
		call	MSSelectTextAndMakeTarget
	;
	; Free the SearchReplaceStruct.
	;
		call	MSGetSearchData
		mov	di, bx
		clr	bx
		xchg	bx, ds:[di].CSD_searchStruct
		call	MemFree
exit:		
		call	AppResumeInput

		pop	bp
		.leave
		ret

noMatch:
		call	MSFailSearch
		jmp	exit

CGVSearch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSSearchText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the text.

CALLED BY:	CGVSearch
PASS:		*ds:si - ContentGenView, with vardata
			ContentSearchData initialized
RETURN:		carry clear if match found, cx = offset of match
		carry set if match not found or error
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/11/95		Initial version - adapted from
				VisTextSearchFromOffset
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSSearchText		proc	near
		.enter inherit CGVSearch

		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC -1						>
		mov	di, bx			;ds:bp <- ContentSearchData
		mov	cx, ds:[di].CSD_flags
		call	MSGetSearchStartOffset	;ax <- start offset
		mov	ds:[di].CSD_currentOffset, ax
		
		mov	bx, ds:[di].CSD_searchStruct
		push	bx
		call	MemLock
		mov	es, ax			;es <- SearchReplaceStruct
searchLoop:

		test	ds:[di].CSD_flags, mask CSF_getNextPage
		jnz	notFound
		
	; IF THE CALLER PASSED IN TEXT_ADDRESS_PAST_END AS ANY OFF THE 
	; OFFSETS, RESET THEM TO POINT TO THE END OF THE TEXT INSTEAD.

		call	MSGetTextSize		; ax <- size of text
		dec	ax			; convert to text offset
		jns	$2			; if ax was 0, don't want
		inc	ax			;  to decrement it
$2:		
		cmp	ds:[di].CSD_currentOffset, TEXT_ADDRESS_PAST_END_LOW
		jne	3$
		mov	ds:[di].CSD_currentOffset, ax
3$:

	; DETERMINE THE STOPPING POINT - THIS IS USUALLY THE START OR 
	; THE END OF THE OBJECT, DEPENDING UPON WHETHER OR NOT IT IS A 
	; FORWARD OR BACKWARD SEARCH

		test	es:[SRS_params], mask SO_BACKWARD_SEARCH
		jz	5$
		clr	ax
5$:
	; ACTUALLY DO THE SEARCH

		mov	cx, ds:[di].CSD_currentOffset

	; CX <- offset to *start* search
	; AX <- offset to *stop* search 

		call	MSFindString	;Returns CX as offset to match
		jc	notFound	;Branch if string not in this page
exit:
	;
	; Unlock the SearchReplaceStruct.
	;		
		pop	bx
		call	MemUnlock

		.leave
		ret

notFound:
	;
	; GO TO THE START OF THE NEXT PAGE IN THE CHAIN
	;
	; We try to get the next/prev page in the chain. If carry is
	; SET on return, the search has wrapped completely.
	;
		mov	ax, ds:[di].CSD_flags
		andnf	ax, not mask CSF_getNextPage
		mov	ds:[di].CSD_flags, ax
		clr	ds:[di].CSD_currentOffset
		test	ah, mask SO_BACKWARD_SEARCH
		je	forwardSearch
		mov	ds:[di].CSD_currentOffset, TEXT_ADDRESS_PAST_END_LOW
forwardSearch:
		call	MSGetNextPage
		jc	searchComplete

		call	MSGetSearchData
		mov	di, bx		;ds:bp <- ptr to ContentSearchData

		jmp	searchLoop

searchComplete:
		
	; String not found on any page. Return cx 0 to signify this.
		
		mov	cx, 0		;preserve flags
		jmp	exit

MSSearchText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSFindString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the text for the find string.

CALLED BY:	
PASS:		*ds:si  - ContentGenView
		ds:bp	- ContentSearchData
		cx 	- offset to *start* search
		ax 	- offset to *stop* search 
RETURN:		carry set if error or string not found,
			else cx = offset of match
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
;
;	Finds an occurrence of a string (str2) in another string (str1).
; 	Pass: ES:BP - ptr to first char in string we are searching in (str1)
;	      ES:DI - ptr to character to start search at in string (str1)
;	      ES:BX - ptr to last char to include in search
;	      DX - # chars of str1 pointed to by ES:DI
;	      DS:SI - ptr to str2 (string to match)
;		      May contain WildCard chars
;	      CX - # chars in str2 (or 0 if null-terminated)
;	      AL - SearchOptions

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSFindString		proc	near
		uses	si, di, ds, es, bp
		.enter

		push	ax, cx
		clr	dx				; allocate a block
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		call	MSCallContentSearchText		; ^hcx = block,
		mov	dx, ax				; dx = str1 len

		segmov	ds, es, ax
		lea	si, ds:[SRS_searchString]	; ds:si <- str2

		mov	bx, cx
		call	MemLock
		mov	es, ax				; es:0 <- text
		clr	bp				; es:bp <- str2 start
		pop	bx, di				; es:di <- search start
							; es:bx <- search end

		push	cx				; save block handle

		clr	cx				; str2 is null-term.
		mov	al, ds:[SRS_params]		; al <- SearchOptions
		call	TextSearchInString

		pop	bx
		pushf
		call 	MemFree
		clr	cx				; assume no match
		popf
		jc	done
	;
	; A match was found, it is pointed to by es:di.
	;
		mov	cx, di				; cx = offset of match
		
done:		
		.leave
		ret
MSFindString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppHoldUpInput, AppResumeInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the app object to hold up or resume input,
		and mark busy or not busy.

CALLED BY:	UTILITY
PASS:		ds - segment of an object block
RETURN:		ds - fixed-up
DESTROYED:	ax, es, di 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppHoldUpInput		proc	far
		uses	dx
		.enter
		mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT
		call	callApp
		call	AppMarkBusy
		.leave
		ret
AppHoldUpInput		endp

AppResumeInput		proc	far
		call	AppMarkNotBusy
		mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT
		call	callApp
		ret
AppResumeInput		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVAbortActiveSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search is done, destroy search text object and
		remove all search-related vardata

CALLED BY:	MSG_ABORT_ACTIVE_SEARCH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		ax - the message
RETURN:		nada
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVAbortActiveSearch		method dynamic ContentGenViewClass,
						MSG_ABORT_ACTIVE_SEARCH
		uses	bp
		.enter

		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
		jnc	done

		mov	di, bx
		mov	bx, ds:[bx].CSD_searchStruct
		tst	bx
		jz	noFree
		call	MemFree

noFree:
		tst	ds:[di].CSD_searchObject.handle
		jz	done
		
		push	si
		mov	bp, ds:[di].CSD_curFile
		mov	si, ds:[di].CSD_searchObject.chunk
		mov	bx, ds:[di].CSD_searchObject.handle

		clr	cx				;no notification msg
		mov	ax, MSG_CT_FREE_STORAGE_AND_FILE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_VIS_DESTROY
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS 
		call	ObjMessage
		pop	si

		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarDeleteData
done:
		.leave
		ret
CGVAbortActiveSearch		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSFailSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles the end of a search, when either the string was
		not found at all, or the search has wrapped and there are
		no more occurrences of the string.  Tell the user which
		has occurred.

CALLED BY:	CGVStringNotFound
PASS:		*ds:si - ContentGenView
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSFailSearch	proc	far
	;
	; Was any match found in a previous search?
	;
		call	MSGetSearchData
		test	ds:[bx].CSD_flags, mask CSF_matchFound
		jz	noMatch
	;
	; Clear the selection from the content text object, by
	; setting the selection start and end to the same position.
	;
		push	si
		clr	di
		call	ContentGetText			;^lbx:si<-display text
		mov	ax, MSG_CT_UNSELECT_TEXT
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	si
	;
	; Some matches were found, and we are here just becase the search
	; has wrapped around to start.  We need a special message to
	; notify users of that, instead of the normal "string not found
	; anywhere in document" message.
	;
		mov	ax, MSG_ABORT_ACTIVE_SEARCH
		call	ObjCallInstanceNoLock

		mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE) or\
			mask CDBF_SYSTEM_MODAL
		mov	di, offset NoMoreMatchesString
		GOTO	MUPutUpDialog

noMatch:
	;
	; No matches were found at all.  Send the search control
	; the message it expects to receive in such a case, which we
	; had stored in our vardata.
	;
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
	
		mov	bx, ds:[bx].CSD_searchStruct
		call	MemLock
		mov	es, ax
		movdw	bpdi, es:[SRS_replyObject], ax
		mov	ax, es:[SRS_replyMsg]
		call	MemUnlock

		push	ax, bp, di
		mov	ax, MSG_ABORT_ACTIVE_SEARCH
		call	ObjCallInstanceNoLock
		pop	ax, bx, si

		clr	di
		GOTO	ObjMessage

MSFailSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetNextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the next page of text to search.

CALLED BY:	
PASS:		*ds:si	= ContentGenViewClass object
		ax - ContentSearchFlags
RETURN:		carry set if search wrapped to beginning
DESTROYED:	ax, bx, bp, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetNextPage		proc	near
		uses	es
		.enter	inherit CGVSearch	
		
		test	ah, mask SO_BACKWARD_SEARCH
		mov	ax, offset PNAE_nextPage	;assume forward search
		jz	forward
		mov	ax, offset PNAE_prevPage
forward:
		call	MSGetCurrentPageNameArrayElement ;cx <- start page #
							 ;bx <- CSD_flags
		add	di, ax
		mov	ax, {word}ds:[di]		;ax = next/prev page
		call	MSGetPageFromToken		;carry set if error
		movdw	bxsi, ss:[conGenView]	
		call	MemDerefDS

		.leave
		ret
MSGetNextPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetCurrentPageNameArrayElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the PageNameArrayElement for the current page.
		Caller must unlock the NameArray.

CALLED BY:	INTERNAL
PASS:		*ds:si - ContentGenView
RETURN:		*ds:si - page name array
		ds:di - PageNameArrayElement
		cx - starting context number
		bx - ContentSearchFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetCurrentPageNameArrayElement		proc	near
		uses	ax, dx
		.enter

		call	MSGetSearchData			;ds:bx <- CSD
		push	ds:[bx].CSD_pageNumber
		mov	dx, ds:[bx].CSD_startContext
		mov	bx, ds:[bx].CSD_flags
		mov	ax, mask CTRF_searchText		
		call	MNLockNameArray			;*ds:si <- name array
		pop	ax

		call	ChunkArrayElementToPtr		;ds:di <- name elt
EC <		ERROR_C ILLEGAL_CONTEXT_ELEMENT_NUMBER			>
		mov	cx, dx
		.leave
		ret
MSGetCurrentPageNameArrayElement		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetPageFromToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the page associated with the given NameArray and token.
		If a token of -1 is given, loads the first page of the next
		content file in the book.  If token matches the start context
		token, go to the next content file.  (THIS DOESN'T DEAL WITH
		the case where you search forward a little ways, then search
		backwards.  You won't search all the way back to file start)
		ALSO - need to get next or previous file, depending on
		direction of the search.

CALLED BY:	INTERNAL - MSGetNextPage, MSGetPreviousPage

PASS:		*ds:si	= NameArray
		ax	= # of name to get
		cx	= # of name started on
		bx	= current ContentSearchFlags
RETURN:		carry set if error, or done searching
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetPageFromToken	proc	near
		uses	bp, ds
		.enter inherit CGVSearch

		cmp	ax, -1
		je	nextContentFile
tryAgain:		
	;
	; Check if search has wrapped to start context
	;
		test	bx, mask CSF_inStartFile	;in start file?
		jz	getName				;no, continue
		cmp	ax, cx				;in start context?
		stc
		je	searchWrapped			;yes, we're done
getName:		
	;
	; Get name array element for this context
	;
		segmov	es, ss, bx
		lea	di, ss:[params].CTR_context
		call	MNGetName
		call	MNUnlockNameArray	
	;
	; ss:di	= buffer filled with context
	;
	; Now load in the text for the desired context
	; 
		call	MSGetTextForContext		;carry set if error
done:		
		.leave
		ret
searchWrapped:
	;
	; The search has wrapped around to the context that we started in
	;
		call	MNUnlockNameArray
		stc
		jmp	done
		
nextContentFile:
	;
	; Okay, we've searched every page of this content file.
	; Lets grab the next one and continue the search on the
	; first page of the next/previous file.  
	;
		call	MNUnlockNameArray	;unlock name array before
						; the file is closed
		call	MSGetViewObj		;*ds:si <- ConGenView
		call	MSGetNextContentFile	;bx <- new ContentSearchFlags
		jc	done
	;
	; Find the context token for page 1 of the new file.
	;
		push	bx, cx, bp		;save flags, first page token
		mov	dx, -1			;initialize elt # to -1
		mov	ax, mask CTRF_searchText
		call	MNLockNameArray		;*ds:si <- new name array
		mov	di, offset FindFirstPageCallback
		cmp	ss:searchDirection, 1
		je	$10
		mov	di, offset FindLastPageCallback
		clr	bp			;initialize page # to 0
$10:
		mov	bx, SEGMENT_CS
		call	ChunkArrayEnum		;dx <- element number
EC <		cmp	dx, -1						>
EC <		ERROR_E	 -1						>
		mov	ax, dx			;ax <- token of page
		pop	bx, cx, bp		;get flags, first page token
		jmp	tryAgain
MSGetPageFromToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFirstPageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the name array element for the first page

CALLED BY:	MSGetPageFromToken
PASS:		*ds:si - PageNameArray
		ds:di - PageNameArrayElement
RETURN:		dx - element number of first page 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFirstPageCallback		proc	far
	;
	; if this is a free element, or not a context name, or a context
	; name for a differnt file, bail
	;
		cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
		je	done
		cmp	ds:[di].PNAE_meta.VTNAE_data.VTND_type, VTNT_CONTEXT
		jne	done
		cmp	ds:[di].PNAE_meta.VTNAE_data.VTND_file,
			VIS_TEXT_CURRENT_FILE_TOKEN
		jne	done
		cmp	ds:[di].PNAE_pageNumber, 1
EC <		mov	dx, -1				;assume not 1st page>
		jne	done
		call	ChunkArrayPtrToElement		;ax <- element number
		mov	dx, ax
		stc
		jmp	$10
done:
		clc
$10:
		ret
FindFirstPageCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLastPageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the name array element for the last page

CALLED BY:	MSGetPageFromToken
PASS:		*ds:si - PageNameArray
		ds:di - PageNameArrayElement
		dx - element number of element with max page number
RETURN:		dx - element number of page 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLastPageCallback		proc	far
	;
	; if this is a free element, or not a context name, or a context
	; name for a differnt file, bail
	;
		cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
		je	done
		cmp	ds:[di].PNAE_meta.VTNAE_data.VTND_type, VTNT_CONTEXT
		jne	done
		cmp	ds:[di].PNAE_meta.VTNAE_data.VTND_file,
			VIS_TEXT_CURRENT_FILE_TOKEN
		jne	done
		cmp	bp, ds:[di].PNAE_pageNumber
;;
;; I found a case where a context name still exists, but is not applied so
;; has no page information, so bp = 0 = PNAE_pageNumber (cassie 9/18/94)
;;EC <		ERROR_E -1						>
		ja	done
		mov	bp, ds:[di].PNAE_pageNumber
		call	ChunkArrayPtrToElement		;ax <- element number
		mov	dx, ax
done:
		clc					;don't stop enum...
		ret
FindLastPageCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetNextContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the next content file from the current
		bookfile, and makes its TOC page the current text of the
		text object.  Currently, this is used during a search, after
		all the pages of the current content file have been
		searched.  

CALLED BY:	INTERNAL - MSGetPageFromToken, MSGetFirstPage,

PASS:		CONTENT_LOCALS - conGenView
		
RETURN:		bx = CSD_flags
		carry clear if loaded next file successfully
		carry set if search is complete or error loading file

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetNextContentFile	proc	near
		class	ContentGenViewClass
		uses	cx
		.enter inherit CGVSearch
	;
	; Free text and old text and run/element arrays, and close the
	; file when text has been freed.
	;
		call	MSGetSearchData
		mov	di, bx
		clr	bx
		xchg	bx, ds:[di].CSD_curFile
		clr	cx
		call	MSDestroyTextStorage
	;	
	; Now we need to ask the book for the next content file, 
	; open it, and continue on.
	;
		call	MSGetSearchData
		mov	cx, ds:[bx].CSD_fileNumber	;current file number
		add	cx, ss:searchDirection		;get next/prev file #

		call	MSOpenBook			; ds:0 = BookFileHeader
		jc	error				;ax <- LoadFileError

getContentFile:
	;
	; Check if we searched the first or last content file.  
	;
		cmp	cx, -1
		je	searchWrapped
		cmp	cx, ds:[BFH_count]
		je	searchWrapped

		call	IsFileFirstFile			;is this the start file
		jnz	loadFile			;no, load it
	;
	; This is the file we started the search in.  If the flag
	; CSD_searchWrapped is set, we have searched all other files
	; in the book, and need only search from the first/last
	; context to the starting context.
	;
		call	MSGetSearchDataES		;es:di <- CSD
		test	es:[di].CSD_flags, mask CSF_searchWrapped
		jz	notInFirst			
		ornf	es:[di].CSD_flags, mask CSF_inStartFile
loadFile:
		call	MSGetViewObj
		call	MSGetSearchData			;ds:bx <- CSD
		mov	ds:[bx].CSD_fileNumber, cx
		mov	bx, ds:[bx].CSD_flags		;return new flags

		call	MSCloseBook
	;
	; Open the content file
	;
		call	MSOpenContentFile	
		jc	done				;ax <- LoadFileError
done:
		.leave
		ret

notInFirst:
		add	cx, ss:searchDirection		;else try next file
		jmp	getContentFile

searchWrapped:
		call	MSGetSearchDataES		;es:di <- CSD
		ornf	es:[di].CSD_flags, mask CSF_searchWrapped
	;
	; We're reached the last/first file in the book.  Wrap to
	; the first/last file.
	;
		clr	cx			;go to first file on fwrd srch
		cmp 	ss:searchDirection, 1	;is this a forward search?
		je	getContentFile
		mov	cx, ds:[BFH_count]	;no, it's a backward search
		dec	cx			;go to last file
		jmp	getContentFile

error:
	;
	; clean up after error
	;
		call	MSCloseBook
		stc
		jmp	done
MSGetNextContentFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFileFirstFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the file to check into CTR_filename and compares
		it to the currently displayed file.

CALLED BY:	INTERNAL - 
PASS:		cx - content file number to check
		^hbx - Book file handle
		ds:0 - BookFileHeader
RETURN:		zero set if files match
		params.CTR_filename filled with file number cx
DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsFileFirstFile		proc	near
		uses	bx, cx, si, ds
		.enter inherit CGVSearch

		segmov	es, ss, ax
		lea	di, ss:[params].CTR_filename
		call	BookGetContentFile
	;
	; skip if same as start content file...
	;
		call	MSGetViewObj
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		lea	si, ds:[bx].CSD_startFile
		clr	cx
		call	LocalCmpStrings
		
		.leave
		ret
IsFileFirstFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSOpenBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open book file, if one is specified in vardata

CALLED BY:	INTERNAL - 
PASS:		*ds:si - ContentGenView
		SEARCH_LOCALS
RETURN:		carry set if couldn't open book
			ax - LoadFileError
		else
			ds:0 = BookFileHeader
			bx - book file
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSOpenBook		proc	near
		uses	cx, bp, es
		.enter	inherit CGVSearch

		clr	ss:bookFile		;reset in case of error

		segmov	es, ss, ax
		lea	di, ss:[params].CTR_bookname
		mov	ax, CONTENT_BOOKNAME
		call	ContentGetStringVardata
		cmc
		mov	ax, LFE_ERROR_NO_BOOK_SELECTED
		jc	done

		lea	di, ss:[params].CTR_pathname
		mov	ax, CONTENT_BOOK_PATHNAME
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>

		mov	ax, CONTENT_BOOK_DISK_HANDLE
		call	ObjVarFindData
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		mov	ax, ds:[bx]		
		mov	ss:[params].CTR_diskhandle, ax
	;
	; Now that we have the complete path specification for the 
	; book file, open it.
	;
		push	bp
		lea	bp, ss:[params]
		call	BookOpen		; ds:0 = BookFileHeader
		pop	bp
		mov	ss:bookFile, bx		; ^hbx = VM file,
		mov	ss:mapBlock, cx		; ^hcx = map block
done:		
		.leave
		ret
MSOpenBook		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCloseBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the book file.

CALLED BY:	MSGetNextContentFile
PASS:		inherited locals
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCloseBook		proc	near
		uses	ax, bx, cx
		.enter	inherit CGVSearch

		mov	bx, ss:bookFile
		tst	bx
		jz	done
		mov	cx, ss:mapBlock
		call	BookClose
EC <		clr	ax						>
EC <		mov	ss:bookFile, ax					>
EC <		mov	ss:mapBlock, ax					>
done:		
		.leave
		ret
MSCloseBook		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSOpenContentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	open a content file and connect text attrs

CALLED BY:	INTERNAL
PASS:		ss:bp -
			CTR_filename - name of file to open
RETURN:		carry set if error opening file
			ax - LoadFileError
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSOpenContentFile		proc	near
		uses	bx
		.enter	inherit CGVSearch
	;
	; Open the file
	;
		push	bp
		lea	bp, ss:[params]
		call	MFOpenFile		;bx <- handle of help file,
		pop	bp			; ax <- flags
		jc	errorOpen		;branch if error opening file
	;
	; Save the help file handle in ContentSearchData 
	;
		push	bx
		call	MSGetSearchData
		mov	di, bx
		pop	ds:[di].CSD_curFile
	;
	; Connect various text object attributes, including the
	; ever-important name array
	;
		mov	ax, mask CTRF_searchText ;set CTRF_searchText flag
		call	MTConnectTextAttributes	 ;ax <- VM handle of name array
		mov	di, mask CTRF_searchText ;set CTRF_searchText flag
		call	MNSetNameArray
	;
	; Load or free the compress lib, depending on whether or not
	; it is needed.  Exit if we couldn't load it and needed it.
	;
		mov	ax, mask CTRF_searchText	;set CTRF_searchText
		call	LoadOrFreeCompressLib		;carry set if error
		clc
done:
		.leave
		ret
errorOpen:
		push	bp
		lea	bp, ss:[params]
		mov	ax, LFE_ERROR_LOADING_SEARCH_FILE
		call	ReportLoadFileError
		pop	bp
		jmp	done		
MSOpenContentFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSPrepareForSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds CONTENT_SEARCH_DATA to the ContentGenViewClass object
		if it doesn't already exist.

		Instantiate a search text object and load the current
		page of text into it.

		Also, Modifies SearchReplaceStruct so that text will notify
		the CGView if it can't find the string.  Also records
		SearchReplaceControl instance's optr and
		string-not-found message in CGView so that view can 
		later notify controller if string not found in *any* 
		of the text objects searched.

CALLED BY:	INTERNAL - CGVSearch

PASS:		*ds:si	= ContentGenViewClass object
		dx 	= handle of block containing words
			Format of block:
				SearchReplaceStruct<>
				data	Null-Terminated Search String
				data	Null-Terminated Replace string

RETURN:		carry set if error preparing to search
DESTROYED:	ax,bx,cx,di,es,bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/19/94    	Initial version
	martin	8/9/94		changed to use CONTENT_SEARCH_DATA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSPrepareForSearch	proc	near
		class	ContentGenViewClass
		uses	dx
		.enter inherit CGVSearch

		mov	ax, ds:[LMBH_handle]
		movdw	ss:conGenView, axsi
		call	MSModifySearchStruct		;cx<-ContentSearchFlags
		mov	ss:searchDirection, 1		; assume fwd search
		test	ch, mask SO_BACKWARD_SEARCH
		jz	forward
		mov	ss:searchDirection, -1
forward:		
	;
	; See if we already have a search in progress
	;
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
		jc	searchInProgress
	;
	; This is a new search, instantiate a search text object
	;
		push	cx, dx

		push	si
		mov	bx, segment ContentTextClass
		mov	es, bx
		mov	di, offset ContentTextClass
		mov	bx, ds:[LMBH_handle]	; alloc in this object's block
		call	ObjInstantiate		;^lbx:si <- ContentSearchText
		mov	cx, si			;^lbx:cx <- text
		pop	si
	;
	; Add and initialize vardata
	;
		pushdw	bxcx			; save text object
		mov	ax, CONTENT_SEARCH_DATA
		mov	cx, (size ContentSearchData)
		call	ObjVarAddData
		popdw	ds:[bx].CSD_searchObject

		pop	ds:[bx].CSD_flags, ds:[bx].CSD_searchStruct

		call	MSGetCurrentFileNumber	
		LONG	jc	error		;ax <- LoadFileError
		dec	ax			;dec file number because it is
						; pre-incremented in
						; MSGetNextContentFile
		mov	ds:[bx].CSD_fileNumber, ax
	;
	; Open the file...we can't set CSD_startFile until after it
	; is opened, else MSGetNextContentFile will think the search has
	; already wrapped.
	;
		push	ss:searchDirection	;save real search direction
		mov	ss:searchDirection, 1	;pretend it is forward search
		call	MSGetNextContentFile	;open the file and load page
		pop	ss:searchDirection	;restore real search direction
		LONG	jc	error		;ax <- LoadFileError
	;
	; Set the starting file and context names
	;
		call	MSGetStartContextInfo
	;
	; Load the current page...
	;
		lea	di, ss:[params].CTR_context	;ss:di <- context
		call	MSGetTextForContext		
		LONG	jc	error			;ax <- LoadFileError
	;
	; Set the text selection such that this page is searched
	; entirely from start or end, depending on search direction
	;
.assert (offset CSF_searchOptions eq 8)
.assert (size SearchOptions eq 1)
		call	MSGetSearchData
		mov	cx, ds:[bx].CSD_flags		;ch <- SearchOptions
		mov	cl, ch
		call	MSSetSelectionForSearch
common:		
		clc					; no error
done:
		.leave
		ret

searchInProgress:
	;
	; There is a search in progress.  See if the search direction
	; has changed.
	; 
		mov	di, bx			;ds:di <- ContentSearchData
		mov	ds:[di].CSD_searchStruct, dx

		push	cx				;save new flags
		andnf	ch, mask SO_BACKWARD_SEARCH	;clear all but this bit
		mov	dx, ds:[di].CSD_flags
		andnf	dh, mask SO_BACKWARD_SEARCH	;clear all but this bit
		cmp	ch, dh
		pop	cx
		je	common
	;
	; Direction has changed.  Save new SearchOptions.
	;
		mov	ds:[di].CSD_flags, cx
	;
	; Reset the starting file and context names
	;
		call	MSGetStartContextInfo
		jmp	common

error:
	;
	; Report the error, and abort the search.
	;
		push	bp
		lea	bp, ss:[params]
		call	ReportLoadFileError
		pop	bp
		mov	ax, MSG_ABORT_ACTIVE_SEARCH
		call	ObjCallInstanceNoLock
		stc
		jmp	done
MSPrepareForSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSModifySearchStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the passed SearchReplaceStruct block.

CALLED BY:	MSPrepareForSearch
PASS:		*ds:si - ContentGenView
		^hdx - SearchStruct block
RETURN:		cx - ContentSearchFlags
DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSModifySearchStruct		proc	near
		uses 	bx
		.enter

	; Modify the search flags to ignore case and match partial words

		mov	bx, dx
		call	MemLock
		mov	es, ax
		mov	cl, es:[SRS_params]	
		ornf	cl, mask SO_IGNORE_CASE or mask SO_PARTIAL_WORD
		mov	es:[SRS_params], cl		
		call	MemUnlock
		mov	ch, cl
		clr	cl

		.leave
		ret
MSModifySearchStruct		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSSetSelectionForSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text selection so that the search will search
		the entire page, whether it is a forward or a backward search.

CALLED BY:	MSPrepareForSearch
PASS:		*ds:si - ConGenView
		cl - SearchOptions
RETURN:		nothing
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSSetSelectionForSearch		proc	near
		uses	bp
		.enter
		mov	ax, MSG_VIS_TEXT_SELECT_START	;select start if fwd
		test	cl, mask SO_BACKWARD_SEARCH	; search
		jz	haveMsg
		mov	ax, MSG_VIS_TEXT_SELECT_END	;else select end 
haveMsg:
		call	MSCallContentSearchText
		.leave
		ret
MSSetSelectionForSearch		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetStartContextInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the staring context and file names in vardata

CALLED BY:	MSPrepareForSearch
PASS:		*ds:si - ContentGenView
RETURN:		nothing
DESTROYED:	ax,bx,cx,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetStartContextInfo		proc	near
		.enter inherit MSPrepareForSearch
	;
	; Save the current filename
	;
		segmov	es, ds, ax
		call	MSGetSearchData
		lea	di, ds:[bx].CSD_startFile	;es:di <- destination
		mov	ax, CONTENT_FILENAME
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
	;
	; Get the current context name
	;
		segmov	es, ss, ax
		lea	di, ss:[params].CTR_context	
		mov	ax, CONTENT_LINK
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
	;
	; Figure out the current context number and save in CSD
	;
		sub	sp, size ContentFileNameData
		mov	bx, sp
		lea	di, ss:[params].CTR_context	;ss:di <- context name
		clr	ax				;use display text
		call	MTFindNameForContext		;ax <- context token
		jnc	$10
		clr	ax
$10:
		add	sp, size ContentFileNameData

		call	MSGetSearchData
		mov	ds:[bx].CSD_startContext, ax
		.leave
		ret
MSGetStartContextInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetCurrentFileNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the index of the current file in the book's file list.

CALLED BY:	INTERNAL - MSPrepareForSearch
PASS:		*ds:si - ContentGenView
RETURN:		carry clear if got file number
			ax - content file number
		carry set if couldn't open book
			ax - LoadFileError
DESTROYED:	di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetCurrentFileNumber		proc	near
		uses	bx,cx,dx,si,bp,ds
		.enter inherit CGVSearch

		segmov	es, ss, ax
		lea	di, ss:params.CTR_filename
		mov	ax, CONTENT_FILENAME
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		
		call	MSOpenBook
		jnc	continue
		cmp	ax, LFE_ERROR_BOOK_HAS_NO_FILES
		mov	ax, 0			;use file 0 if no book
		clc
		jz	quit
		stc				;else some other error
		jmp	quit

continue:
		push	bp
		lea	di, ss:params.CTR_filename ;es:di <- filename
		mov	dx, ds:[BFH_count]
		mov	ax, ds:[BFH_nameList]
EC <		tst	ax						>
EC <		ERROR_Z -1						>
		call	VMLock
		mov	ds, ax
		clr	si			;ds:si <- 1st name in list
		clr	ax			; counter
		clr	cx			; strings are null-terminated

contentFileLoop:
		call	LocalCmpStrings
		je	done
		add	si, size FileLongName
		inc	ax
		cmp	ax, dx
		jne	contentFileLoop
EC <		WARNING CURRENT_FILE_NOT_IN_BOOK_LIST			>
EC <		clr	ax						>
done:
		call	VMUnlock
		pop	bp
quit:
		mov	dx, ax
		lahf
		clr	bx, cx
		xchg	bx, ss:bookFile
		xchg	cx, ss:mapBlock
		call	BookClose
		sahf
		mov	ax, dx
		.leave
		ret
MSGetCurrentFileNumber		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetTextForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for a context and stuff it in the search text

CALLED BY:	MSGetTextForToken
PASS:		inherited locals
		ss:di - context name
RETURN:		carry - set if error (context name doesn't exist)
DESTROYED:	ax, bx, cx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetTextForContext		proc	far
		class	ContentGenViewClass
		uses	dx, si, di, bp
		.enter inherit CGVSearch

		call	MSGetViewObj			;*ds:si <- CGV
		
		sub	sp, size ContentFileNameData
		mov	bx, sp				;ss:bx <- name data
	;
	; Get the name data for the context
	;
		mov	ax, mask CTRF_searchText	;set CTRF_searchText
		call	MTFindNameForContext		;ax <- name token
		LONG	jc	error
	;
	; Tell our text object to load the text
	;
		cmp	ss:[bx].CFND_text.VTND_type, VTNT_CONTEXT
		jne 	error
		mov	dx, ss:[bx].CFND_text.VTND_helpText.DBGI_item
		tst	dx			;any item?
		jz	error
		mov	cx, ss:[bx].CFND_text.VTND_helpText.DBGI_group
	;
	; Is this file compressed?
	;
		call	MSGetSearchData
		tst	ds:[bx].CSD_compressLib
		jnz	uncompress
	;
	; If no compression, just have the text be loaded up normally
	;
		mov	ds:[bx].CSD_pageNumber, ax
		mov	si, ds:[bx].CSD_searchObject.chunk
		mov	bx, ds:[bx].CSD_searchObject.handle
		mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM
		clr	bp			 	;bp <- use VTI_vmFile
		call	ObjCallInstanceNoLock

noError:
		clc					;carry <- no error
quit:
		mov	dx, ax
		lahf
		add	sp, size ContentFileNameData
		sahf
		mov	ax, dx
		.leave
		ret
uncompress:
	;
	; CX.DX <- group/item of compressed data
	;
		mov	ds:[bx].CSD_pageNumber, ax
		pushdw	ds:[bx].CSD_searchObject
		mov	ax, ds:[bx].CSD_compressLib
		mov	bx, ds:[bx].CSD_curFile
		call	MTUncompressText		;cx <- data segment
		popdw	bxsi
		jc	error

		push	dx				;save data handle
		clr	dx				;cx:dx <- data
		mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_FORMAT
		call	ObjCallInstanceNoLock
		
		pop	bx
		call	MemFree
		jmp	noError
error:
		mov	ax, LFE_ERROR_LOADING_CONTEXT
		stc
		jmp	quit
MSGetTextForContext		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDisplayMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After a search match has been found, load the proper
		file and page.

CALLED BY:	INTERNAL - CGVSearch
PASS:		*ds:si - ConGenView
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDisplayMatch		proc	near
		class	ContentGenViewClass
		uses	cx
		.enter inherit CGVSearch

EC <		call	AssertIsCGV					>
		mov	ax, ds:[LMBH_handle]
		movdw	ss:conGenView, axsi
	;	
	; Now we need to ask the book for the next content file, 
	; open it, and continue on.  MSOpenBook sets the book's path
	; and disk handle in params, so we must call it before getting
	; the content file path and disk.
	;
		push	ds
		call	MSGetSearchData
		ornf	ds:[bx].CSD_flags, mask CSF_matchFound

		mov	cx, ds:[bx].CSD_fileNumber	;current file number
		call	MSOpenBook			; ds:0 = BookFileHeader
		LONG	jc	noBook
		call	IsFileFirstFile			;loads file name
		call	MSCloseBook
		pop	ds
continue:
	;
	; Get the name of the page to load given its name array element number
	;
		push	ds, si
		call	MSGetSearchData
		mov	cx, ds:[bx].CSD_pageNumber	
		lea	di, ss:[params].CTR_context
		mov	ax, mask CTRF_searchText
		call	MNLockNameArray			;*ds:si <- name array
		mov	ax, cx				;ax <- name token
		call	MNGetName
		call	MNUnlockNameArray	
		pop	ds, si
EC <		call	AssertIsCGV					>
	;
	; Now compare the filename and context name to current file/context
	; to see if we are already on the right page.
	;
		segmov	es, ss, ax
		lea	di, ss:[params].CTR_filename
		mov	ax, CONTENT_FILENAME
		call	cmpStrings
		jne	newPage

		lea	di, ss:[params].CTR_context
		mov	ax, CONTENT_LINK
		call	cmpStrings
		je	done
newPage:		
	;
	; Get the book tools and features for MSG_CGV_LOAD_CONTENT_FILE
	;
		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		mov	ax, ds:[di].CGVI_bookFeatures
		mov	ss:[params].CTR_featureFlags, ax
		mov	ax, ds:[di].CGVI_bookTools
		mov	ss:[params].CTR_toolFlags, ax
	;
	; Now set the content file path and disk in params.
	;
		push 	bp
		mov	dx, ss
		lea	bp, ss:[params].CTR_pathname	;dx:bp <- path buffer
		mov	cx, size PathName
		mov	ax, MSG_GEN_PATH_GET
		call	ObjCallInstanceNoLock
EC <		ERROR_C	-1						>
		pop	bp
		mov	ss:[params].CTR_diskhandle, cx
	;
	; Tell ourselves to load it
	;
		push	bp
		mov	ss:[params].CTR_flags, mask CTRF_searchMatch \
			or mask CTRF_needContext
		lea	bp, ss:[params]
		mov	ax, MSG_CGV_LOAD_CONTENT_FILE
		call	ObjCallInstanceNoLock
		pop	bp
done:		
		.leave
		ret

noBook:
	;
	; Clear the bookname field, and load the filename from vardata
	;
		pop	ds
		mov	{char}ss:[params].CTR_bookname, 0
		mov	ax, CONTENT_FILENAME
		lea	di, ss:[params].CTR_filename	;buffer for filename
		call	ContentGetStringVardata
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		jmp	continue

cmpStrings:		
		push	si
		call	ObjVarFindData
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		mov	si, bx
		clr	cx				;strings are null-term.
		call	LocalCmpStrings
		pop	si
		retn
		
MSDisplayMatch		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSSelectTextAndMakeTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After displaying the page containing the match,
		select the matching text and take focus and target
		away from SearchReplaceControl.

CALLED BY:	CGVSearch
PASS:		*ds:si - ConGenView
		cx - offset of match
RETURN:		nothing
DESTROYED:	ax, bx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSSelectTextAndMakeTarget		proc	near
		uses	si
		.enter

		call	MSGetSearchData
		mov	bx, ds:[bx].CSD_searchStruct
		call	MemLock
		mov	es, ax
		mov	dx, es:[SRS_searchSize]
		call	MemUnlock
	;
	; Tell display text to select the matching text
	;
		sub	sp, size VisTextRange
		mov	bp, sp

		push	si
		clr	di				;get display text optr
		call	ContentGetText			;^lbx:si<-display text

		clr	ax
		pushdw	axcx				;save for SHOW_POSITION

		movdw	ss:[bp].VTR_start, axcx
		dec	dx				;subtract the null
		add	cx, dx				;cx <- match end
EC <		ERROR_C -1						>
		movdw	ss:[bp].VTR_end, axcx

		mov	dx, size VisTextRange
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
		call	ObjMessage
	
		popdw	dxcx				; position to show

		mov	ax, MSG_VIS_TEXT_SHOW_POSITION	; show the match
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		mov	di, si
		pop	si
	;
	; Also select the match in the search text, so we can resume
	; from this point on next go round.
	;
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		call	MSCallContentSearchText
		add	sp, size VisTextRange
	;
	; Return focus to ContentGenView, target to ContentText
	;
		pushdw	bxdi
		mov	bx, ds:[LMBH_handle]
		mov	ax, MSG_META_GRAB_FOCUS_EXCL	;Give focus to CGV
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		popdw	bxsi				;^lbx:si<-display text

		mov	ax, MSG_META_GRAB_TARGET_EXCL	;Give target to text
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
MSSelectTextAndMakeTarget		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDestroyTextStorage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the storage for the text object

CALLED BY:	INTERNAL - HelpControlExit

PASS:		*ds:si 	= ContentGenView instance
		bx 	= VM file handle
		cx	= notification messsage to send to ContentGenView 
			  (0 for none)

RETURN:		ds 	= fixed up

DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version
	martin	8/11/94		Added notification callback

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDestroyTextStorage		proc	near
		uses	ax, bp
		.enter
EC <		call	AssertIsCGV				>
		tst	bx
		jz	noClose
		mov	bp, bx
		mov	ax, MSG_CT_FREE_STORAGE_AND_FILE
		mov	di, mask CTRF_searchText			
		call	MUObjMessageSend
noClose:	
		.leave
		ret
MSDestroyTextStorage		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetViewObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a valid pointer to the ContentGenView instance data
		from the optr in the local variable ss:[conGenView].

CALLED BY:	INTERNAL - MSGetNextContentFile, MSGetPageFromToken

PASS:		CONTENT_LOCALS - conGenView

RETURN:		*ds:si	= ContentGenView object

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetViewObj	proc	near
		uses	bx
		.enter inherit CGVSearch
		
		movdw	bxsi, ss:[conGenView]
		call	MemDerefDS
EC <		call	AssertIsCGV					>
		.leave
		ret
MSGetViewObj	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetSearchData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get ContextSearchData ptr

CALLED BY:	INTERNAL
PASS:		*ds:si - ContentGenView
RETURN:		ds:bx - pointer to extra data
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetSearchData		proc	near
		uses	ax
		.enter
EC <		call	AssertIsCGV					>
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		
		.leave
		ret
MSGetSearchData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetSearchDataES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get ContextSearchData ptr into es:di

CALLED BY:	INTERNAL
PASS:		inherited SEARCH_LOCALS
RETURN:		es:di - pointer to ContentSearchData
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetSearchDataES		proc	near
		uses	ax, bx, ds
		.enter inherit CGVSearch

		call	MSGetViewObj			;*ds:si <- CGV
		mov	ax, CONTENT_SEARCH_DATA
		call	ObjVarFindData
EC <		ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
		segmov	es, ds, ax
		mov	di, bx				;es:di <- CSD
		
		.leave
		ret
MSGetSearchDataES		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get size of text in ContentText object

CALLED BY:	INTERNAL
PASS:		*ds:si - ContentGenView
RETURN:		ax = size of text
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetTextSize		proc	near
		uses	cx, dx, bp, di
		.enter
		
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	MSCallContentSearchText		; dx.ax = size
EC <		tst	dx						>
EC <		ERROR_NZ -1						>

		.leave
		ret
MSGetTextSize		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGetSearchStartOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return start/end of current text selection, which will
		be the start of our next search for backward/forward search.

CALLED BY:	INTERNAL
PASS:		*ds:si - ContentGenView
		cx - ContentSearchFlags
RETURN:		ax - 1 past start/end of current selection
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSGetSearchStartOffset		proc	near
		uses	cx, dx, bp, di
		.enter inherit CGVSearch
		sub	sp, size VisTextRange
		mov	di, sp
		mov	dx, ss

		push	cx, bp
		mov	bp, di
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		call	MSCallContentSearchText
		pop	cx, bp
	;
	; ContentText is a SMALL text object, and can hold no more
	; than 64K of text, so the high byte should never be non-zero.
	;
EC <		tst	ss:[di].VTR_start.high				>
EC <		ERROR_NZ -1						>
EC <		tst	ss:[di].VTR_end.high				>
EC <		ERROR_NZ -1						>
	;
	; If there is no selection (start = end), return the current
	; position as the search start offset.
	;
		mov	ax, ss:[di].VTR_end.low
		cmp	ax, ss:[di].VTR_start.low
		je	done
	;
	; Else add/subtract 1 to the end/start of the last match
	; so that the search starts just after/before it. But check
	; that we don't run off the end of the text in doing so.
	;
		test	ch, mask SO_BACKWARD_SEARCH
		jnz	backward

		call	MSGetTextSize		; ax <- size of text
		mov	bx, ax
		mov	ax, ss:[di].VTR_end.low	
compare:
		cmp	ax, bx
		jne	done
	;
	; Okay, we've run off the end of the search. We want to
	; force MSSearchText to load the next page before proceeding.
	;
		call	MSGetSearchData
		ornf	ds:[bx].CSD_flags, mask CSF_getNextPage
done:
		add	sp, size VisTextRange
		.leave
		ret

backward:
		mov	ax, ss:[di].VTR_start.low
		add	ax, ss:searchDirection
		mov	bx, -1
		jmp	compare
MSGetSearchStartOffset		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCallContentSearchText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the content search text object

CALLED BY:	INTERNAL
PASS:		*ds:si - ContentGenView
		ax - message
		cx, dx, bp - data to pass to message
RETURN:		ax, cx, dx, bp - returned by message
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCallContentSearchText		proc	near
		uses	bx, si, di
		.enter
EC <		call	AssertIsCGV					>
		mov	di, mask CTRF_searchText	; get searchText obj
		call	ContentGetText			;*ds:si <- text
		call	ObjCallInstanceNoLock
		.leave
		ret
MSCallContentSearchText		endp

ContentLibraryCode	ends


