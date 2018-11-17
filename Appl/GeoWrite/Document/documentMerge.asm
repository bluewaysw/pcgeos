COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		documentMerge.asm

AUTHOR:		John Wedgwood, Oct 23, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/23/92	Initial revision

DESCRIPTION:
	Code to implement merging write documents with data-records.

	$Id: documentMerge.asm,v 1.1 97/04/04 15:56:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocMerge	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupForMerge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This sets up for merging by updating the file on disk
		and loading up the SSMetaStruc needed by later merge code.

CALLED BY:	WriteDocumentStartPrinting
PASS:		*ds:si	= Instance ptr
		es	= dgroup
		ss:bp	= Inheritable stack frame
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If there is an error, this routine will display a dialog box.
	This means that the caller can simply note the error and continue.

	The basic algorithm is this:
	    SSMetaInitForPaste -
	    	- Get exclusive access to the scrap, set up the structures
		- Generate an error message and return an error if there
		  is some sort of problem
	
	    mergeCount = 1
	    if (merging all records) then
	        SSMEtaDataArrayGetNumEntries -
	            - Get the number of entries to merge

	    SSMetaDataArrayResetEntryPointer -
	        - Set up for first merge

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupForMerge	proc	far
	uses	ax, cx, dx, di, bp
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Load the ssmeta library.
	;
	call	MergeScrapLoadLibrary		; carry set if error
	jc	quit				; Branch if no library

	;
	; Claim the scrap and get the number of entries.
	;
	call	MergeScrapInit			; Do the setup
	jc	noScrapPresent			; Branch on error
	
	;
	; Merging all records. Save the count in the stack frame.
	;
	call	MergeScrapGetNumberOfEntries	; ax <- # of mergable entries
	jc	scrapErrorNoEntries		; Branch if none
	
	;
	; There is data.
	;
	mov	mergeCount, ax			; Save number to merge
	
ifndef _VS150
	;
	; If we're merging only one record, set the count to one.
	;
	cmp	merging, MT_ONE
	jne	notMergeOne			; Branch if not merging only one
	mov	mergeCount, 1			; Merging one entry
notMergeOne:
endif
	;
	; Build the field-name list and advance the pointer to the first record
	;
	call	BuildFieldNameList		; ^lcx:dx <- field names
	jc	scrapErrorFieldProblem		; Branch if there is a problem

	movdw	fieldNameList, cxdx		; Save the list handle/chunk
	
	;
	; Set up for undo.
	;
	call	SetupContextForMergeUndo
	
	;
	; Copy the merge-feedback string into the buffer and set the offset
	; for the number to go.
	;
	call	SetupMergeFeedbackString
	
quitNoError::
	clc					; Signal: no error

quit:
	;
	; Carry set if there was an error.
	;
	.leave
	ret

scrapErrorNoEntries:
	;
	; Tell the user about the problem.
	;
	mov	ax, offset NoMergeDataMessage
	call	DisplayError

scrapErrorFieldProblem:
	
scrapErrorCommon::
	;
	; Allow someone else to get at the scrap.
	;
	call	MergeScrapFinish		; All done with scrap
	
	;;; Fall through to return the fact that there was an error
	
noScrapPresent:
	;
	; Free up the library, as caller assumes that, on error, it is not
	; loaded - brianc 9/2/94
	;
	call	MergeScrapUnloadLibrary

	stc					; Signal: error
	jmp	quit
SetupForMerge	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupMergeFeedbackString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a merge-feedback string.

CALLED BY:	SetupForMerge
PASS:		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupMergeFeedbackString	proc	near
	uses	ax, bx, cx, di, si, ds, es
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Lock the string block.
	;
	mov	bx, handle StringsUI		; Lock down the string
	call	MemLock				; ax <- segment
	mov	ds, ax				; ds:si <- ptr to string
	mov	si, ds:MergeFeedbackString
	ChunkSizePtr	ds, si, cx		; cx <- string size

	;
	; Make sure the string isn't too large.
	;
EC <	cmp	cx, MAX_MERGE_FEEDBACK_STRING_SIZE		>
EC <	ERROR_AE	-1					>

	;
	; Account for the NULL at the end.
	;
SBCS <	sub	cx, UHTA_NULL_TERM_BUFFER_SIZE + 1		>
DBCS <	sub	cx, UHTA_NULL_TERM_BUFFER_SIZE + 2		>
	
	;
	; Save the place for the number part and the string itself.
	;
	mov	mergeFeedbackNumberBase, cx	; Save location for number
	
	segmov	es, ss, di			; es:di <- ptr to dest
	lea	di, mergeFeedbackBuffer
	
	rep	movsb				; Copy the string
	
	;
	; Release the block
	;
	call	MemUnlock			; See 'ya
	.leave
	ret
SetupMergeFeedbackString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CleanupAfterMerge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after merging by reverting the file from the
		disk and forcing it to recalculate.

CALLED BY:	WriteDocumentStartPrinting
PASS:		*ds:si	= Instance ptr
		ss:bp	= Inheritable stack frame
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	I don't suspect that there's much that the caller can do if this
	routine encounters an error. If it does, it will put up a dialog
	box, so the caller can simply note the problem and continue.
	
	Here is the basic algorithm:
	    Revert the file
	    SSMetaDoneWithPaste -
	    	- Signal that we're done with the file

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CleanupAfterMerge	proc	far
	uses	ax, cx, dx, di, bp
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Tell the ssmeta library we're done with the scrap.
	;
	call	MergeScrapFinish		; All done with scrap

	;
	; Nuke the undo chain so that nothing is around to be undone.
	;
	call	NukeUndoability
	
	;
	; Revert to the old undo context.
	;
	call	RestoreContextAfterMergeUndo
	
	;
	; Free up the library.
	;
	call	MergeScrapUnloadLibrary
	.leave
	ret
CleanupAfterMerge	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeNextEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are merging, set up for the next document.

CALLED BY:	WriteDocumentStartPrinting
PASS:		*ds:si	= WriteDocument class
		ss:bp	= Inheritable stack frame
RETURN:		carry set if we aren't merging, or there isn't more to merge
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Merge the next record:
	    
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeNextEntry	proc	far
	uses	ax, cx, dx, di
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Check for more to do.
	;
	tst	mergeCount
	jz	quitNoMore
	
	;
	; One less after this point...
	;
	dec	mergeCount

	;
	; Substitute for the strings.
	;
	call	SubstituteForFieldNames

	;
	; Move to the next record.
	;
	call	MergeScrapNextRecord
	
	clc					; Signal: there is more
	
quit:
	.leave
	ret


quitNoMore:
	stc					; Signal: no more to do
	jmp	quit
MergeNextEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildFieldNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a block which contains the field-names to use.

CALLED BY:	SetupForMerge
PASS:		ss:bp	= Inheritable stack frame
RETURN:		carry set on error
		carry clear otherwise
		    ^lcx:dx = Block and chunk of the field-name list array.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The process is simple enough... 
	
	Create LMem heap
	Allocate ChunkArray in the LMem heap

	For each column:
	    - Check to see if the block is getting too large
	      If it is, free the block and return an error
	    - Construct search/replace string from data
	    - Append the s/r string to the ChunkArray

	Unlock the LMem heap and return the block and chunk

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildFieldNameList	proc	near
	uses	ax, bx, di, si, ds, es
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Create an lmem heap for the chunk array
	;
	mov	ax, LMEM_TYPE_GENERAL		; ax <- LMemType
	clr	cx				; Default header
	call	MemAllocLMem			; bx <- block handle
	
	call	MemLock				; ax <- segment address
	mov	ds, ax				; ds <- segment address
	
	;
	; Make the chunk-array for the list
	;
	clr	bx				; Variable sized elements
	clr	cx				; No extra header space
	clr	si				; Allocate a chunk please
	clr	al				; No ObjChunkFlags
	call	ChunkArrayCreate		; si <- chunk of the array

	mov	cx, ssmetaData.SSMDAS_scrapCols	; cx <- # of fields
	jcxz	errorNoFields			; Branch if there aren't any

appendNameLoop:
	;
	; Get the next name, construct a s/r string and append it to the array.
	;
	; *ds:si= Chunk array
	; ss:bp	= Stack frame
	; cx	= Number of fields to do
	;
	;
	; Get the field name and append an element for it to the chunk array
	;
	push	cx
	call	LockFieldName			; es:bx <- ptr to field name
						; ax <- size of new field name
	pop	cx
	jc	errorFreeBlock			; Branch if there's a problem
	
	push	ax				; Save original size
	call	ComputeSearchStringSize		; ax <- total size of string
	call	ChunkArrayAppend		; ds:di <- new element
	pop	ax				; Restore original size
	
	push	cx, ds, si			; Save number of fields, array

	;
	; Construct the search/replace string.
	;
	segxchg	ds, es, si			; es:di <- ptr to destination
						; ds:bx <- ptr to source
	mov	si, bx				; ds:si <- ptr to source
	mov	cx, ax				; cx <- size (in bytes)

	;
	; First put in the "start-merge" character
	;
	call	InsertMergePrefixString		; Add the prefix
	rep	movsb				; Copy in the string
	call	InsertMergeSuffixString		; Add the suffix
	
	;
	; Release the field name
	;
	call	ReleaseFieldName
	
	pop	cx, ds, si			; Restore # of fields, array
	loop	appendNameLoop			; Loop to do the next one
	
	;
	; There was no error... We get ready to merge the data.
	;
	call	MergeScrapResetForData

endLoop::
	;
	; Release the array and return the block/chunk to the caller.
	;
	mov	bx, ds:LMBH_handle		; bx <- block handle
	call	MemUnlock			; Release it
	
	movdw	cxdx, bxsi			; ^lcx:dx <- list
	
	clc					; Signal: no error

quit:
	.leave
	ret

;---------------

errorNoFields:
	;
	; Tell the user that no fields were found.
	;
	mov	ax, offset NoFieldsMessage
	call	DisplayError
	
	;;; Fall through to free up the block

errorFreeBlock::
	;
	; Release and free the block
	;
	mov	bx, ds:LMBH_handle
	call	MemUnlock
	call	MemFree
	
	stc					; Signal: error
	jmp	quit

BuildFieldNameList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeSearchStringSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the total size of the search-string

CALLED BY:	BuildFieldNameList
PASS:		ax	= Size of the field-name itself
RETURN:		ax	= Total size of the string
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeSearchStringSize	proc	near
	uses	bx, cx, si, ds
	.enter
	push	ax				; Save field-name size
	mov	bx, handle StringsUI		; bx <- handle of strings
	call	MemLock				; ax <- segment of block
	mov	ds, ax				; ds <- segment

	mov	si, ds:MergeReplacePrefixString	; ds:si <- ptr to string
	call	GetNullTermStringChunkSize	; cx <- size of string
	push	cx				; Save prefix size

	mov	si, ds:MergeReplaceSuffixString	; ds:si <- ptr to string
	call	GetNullTermStringChunkSize	; cx <- size of suffix
	pop	si				; si <- prefix size
	
	add	cx, si				; cx <- size of prefix + suffix
	pop	ax				; Restore field name size
	add	ax, cx				; ax <- total size
	
	call	MemUnlock			; Release the block
	.leave
	ret
ComputeSearchStringSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNullTermStringChunkSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of the string in a null-terminated chunk.

CALLED BY:	ComputeSearchStringSize
PASS:		ds:si	= Pointer to the string
RETURN:		cx	= Size
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNullTermStringChunkSize	proc	far
	ChunkSizePtr	ds, si, cx
SBCS <	dec	cx			>	; Account for the NULL
DBCS <	sub	cx, 2			>	; Account for the NULL
	ret
GetNullTermStringChunkSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertMergePrefixString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the merge prefix.

CALLED BY:	BuildFieldNameList
PASS:		es:di	= Place to put it
RETURN:		es:di	= Pointers past the inserted prefix
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertMergePrefixString	proc	near
	uses	si
	.enter
	mov	si, offset MergeReplacePrefixString
	call	InsertMergeChunk
	.leave
	ret
InsertMergePrefixString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertMergeSuffixString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the merge suffix

CALLED BY:	BuildFieldNameList
PASS:		es:di	= Place to put it
RETURN:		es:di	= Pointers past the inserted suffix
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertMergeSuffixString	proc	near
	uses	si
	.enter
	mov	si, offset MergeReplaceSuffixString
	call	InsertMergeChunk
	.leave
	ret
InsertMergeSuffixString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertMergeChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a null-terminated chunk string from the StringsUI resource

CALLED BY:	InsertMergeSuffixString, InsertMergePrefixString
PASS:		si	= Handle of chunk to insert
		es:di	= Place to insert it
RETURN:		es:di	= Pointer past inserted data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertMergeChunk	proc	near
	uses	ax, bx, cx, si, ds
	.enter
	mov	bx, handle StringsUI		; bx <- handle of strings
	call	MemLock				; ax <- segment of block
	mov	ds, ax				; ds <- segment
	mov	si, ds:[si]			; ds:si <- ptr to chunk

	call	GetNullTermStringChunkSize	; cx <- size of string
	
	rep	movsb				; Copy the string
	
	call	MemUnlock			; Release the block
	.leave
	ret
InsertMergeChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a field name and return a pointer and size.

CALLED BY:	BuildFieldNameList
PASS:		ss:bp	= Inheritable stack frame
RETURN:		es:bx	= Pointer to the field name
		ax	= Size of the field name (w/o NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockFieldName	proc	near
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Get a pointer to the next field name
	;
	call	MergeScrapLockFieldEntry	; es:bx <- ptr to data
						; ax <- size
						; carry set if no data
	jc	errorNoField

	;
	; Advance to the next field.
	;
	call	MergeScrapNextField
	
	clc					; Signal: no error

quit:
	;
	; Carry set on error.
	;
	.leave
	ret


errorNoField:
	;
	; Tell the user about the problem.
	;
	mov	ax, offset ExpectedFieldMessage
	call	DisplayError
	
	stc
	jmp	quit

LockFieldName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReleaseFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a field name.

CALLED BY:	BuildFieldNameList
PASS:		ss:bp	= Inheritable stack frame
		es	= Segment of block containing the field name
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReleaseFieldName	proc	near
	call	MergeScrapUnlockFieldEntry	; Release the entry
	ret
ReleaseFieldName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointAtSomethingSimilarToData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Points at something, usually data.

CALLED BY:	ReplaceFieldNameCallback
PASS:		ss:bp	= Inheritable stack frame
RETURN:		es:bx	= Pointer to the field name
		ax	= Size of the field name (w/o NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointAtSomethingSimilarToData	proc	near
	call	MergeScrapLockDataEntry		; carry set if no data
						; es:bx <- ptr to data
						; ax <- data size
	jnc	quit				; Branch if has data
	
	clr	ax				; ax <- size of empty string

quit:
	call	MergeScrapNextField		; Advance to the next field
	ret
PointAtSomethingSimilarToData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SubstituteForFieldNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Substitute for all field names in a given document.

CALLED BY:	MergeNextEntry
PASS:		*ds:si	= WriteDocument class
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach entry in the chunk-array:
	    Substitute the field-data for the name in the array.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SubstituteForFieldNames	proc	near
	uses	ax, bx, cx, dx, di, es
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Suspend the object so it won't recalc for each replace operation.
	;
	call	SuspendAllTextObjects
	
	;
	; Start a new undo chain.
	;
	call	StartUndoChain

	push	ds, si				; Save instance ptr

	;
	; Use ^lcx:dx to pass the OD of the write document.
	;
	mov	cx, ds				; cx <- segment of doc
	mov	dx, si				; dx <- chunk of doc

	;
	; Get the chunk-array so we can enumerate it.
	;
	mov	bx, fieldNameList.handle	; bx <- field-list block
	call	MemLock				; ax <- field-list segment
	mov	ds, ax				; ds <- field-list segment
	mov	si, fieldNameList.chunk		; *ds:si <- chunk array
	
	mov	bx, cs
	mov	di, offset cs:ReplaceFieldNameCallback
	
	call	ChunkArrayEnum			; Do the replacement
	
	pop	ds, si				; Restore instance ptr
	
	;
	; End the undo chain.
	;
	call	EndUndoChain

	;
	; Unsuspend the object now that we're done.
	;
	call	UnsuspendAllTextObjects
	.leave
	ret
SubstituteForFieldNames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceFieldNameCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a field name with the appropriate field data.

CALLED BY:	SubstituteForFieldNames via ChunkArrayEnum
PASS:		*ds:si	= Field name ChunkArray
		ds:di	= Pointer to the field-name to replace
		ax	= Size of the string
		ss:bp	= Inheritable stack frame (WriteDocumentStartPrinting)
		*cx:dx	= WriteDocument instance to work with
RETURN:		carry clear, always
DESTROYED:	bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceFieldNameCallback	proc	far
	uses	ax, cx, dx, ds, es
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; We are trying to create a stack frame suitable for the
	; search/replace operation we'll be doing.
	;
	push	cx, dx				; Save OD of document

	mov	si, di				; ds:si <- ptr to source
	mov	cx, ax				; cx <- size of source string

	;
	; Get a pointer to the data.
	;
	call	PointAtSomethingSimilarToData	; es:bx <- data pointer
						; ax <- size
	mov	di, bx				; es:di <- data pointer
	
	;
	; Create the block for the search/replace.
	;
	call	CreateSearchReplaceBlock	; dx <- block
	
	;
	; Replace the text...
	;
	pop	ds, si				; *ds:si <- document
	
	;
	; Deliver the message to everyone.
	;
	call	ReplaceInAllObjects
	
	;
	; We do not need to free the block because the handler in the text
	; object does this for us.
	;

	;
	; Release the scrap entry.
	;
	tst	ax				; Check for no data
	jz	quit				; Branch if none
	call	MergeScrapUnlockDataEntry
quit:
	.leave
	ret
ReplaceFieldNameCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceInAllObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a replace-all in all text objects in the document.

CALLED BY:	ReplaceFieldNameCallback
PASS:		dx	= Block handle containing strings
		*ds:si	= Document
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceInAllObjects	proc	near
	uses	ax, cx, dx, bp, di
	.enter
ifdef GPC
	;
	; clear wrap-around search state
	;
	push	dx
	mov	ax, MSG_WRITE_DOCUMENT_CLEAR_SEARCH_WRAP_CHECK
	call	ObjCallInstanceNoLock
	pop	dx
endif
	;
	; Record the message for delivery.
	;
	mov	cx, -1			; search all
	mov	ax, MSG_REPLACE_ALL_OCCURRENCES
	mov	di, mask MF_RECORD
	call	ObjMessage		; di <- block handle

	;
	; Deliver the message
	;
	mov	cx, di			; cx <- event to send
	mov	ax, MSG_WRITE_DOCUMENT_SEND_TO_FIRST_ARTICLE
	call	ObjCallInstanceNoLock	; Do the replace
	.leave
	ret
ReplaceInAllObjects	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSearchReplaceBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a block for the replace-all-occurrences call.

CALLED BY:	ReplaceFieldNameCallback
PASS:		ds:si	= Search string
		cx	= Size of search string
		es:di	= Replace string
		ax	= Size of replace string
RETURN:		dx	= Block handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSearchReplaceBlock	proc	near
	uses	ax, bx, cx, di, si, ds, es
	.enter
	;
	; Save the string pointers, we'll need them later.
	;
	push	ax
	push	es, di, ax			; Save replace string

	push	cx
	push	ds, si, cx			; Save search string

	;
	; Allocate the block to hold the structure and strings.
	;
	add	ax, cx				; ax <- total string size
SBCS <	add	ax, 2				; Account for NULLs	>
DBCS <	add	ax, 4				; Account for NULLs	>
	add	ax, size SearchReplaceStruct	; ax <- total block size
	
	mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
	mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK or mask HAF_NO_ERR
	call	MemAlloc			; bx <- block handle
						; ax <- segment address
	mov	es, ax				; es <- block segment
	
	;
	; Initialize the structure
	;
	mov	es:SRS_params, mask SO_NO_WILDCARDS
	clrdw	es:SRS_replyObject		; No reply object
	
	;
	; Copy the search string in
	;
	pop	ds, si, cx			; ds:si <- string, cx <- size
	mov	di, offset SRS_searchString	; es:di <- destination
	
	rep	movsb				; Copy the string
	
	clr	ax
	LocalPutChar	esdi, ax		; Stuff a NULL
	
	pop	ax				; ax <- string size (again)
DBCS <	shr	ax, 1				; SRS_searchSize is char count>
	add	ax, 1				; Account for NULL
	mov	es:SRS_searchSize, ax		; Save string length
	
	;
	; Copy the dest string in. It may be empty.
	;
	pop	ds, si, cx			; ds:si <- string, cx <- size
	
	jcxz	skipStringCopy			; Branch if no string
	rep	movsb				; Copy the string
skipStringCopy:

	clr	ax
	LocalPutChar	esdi, ax		; Stuff a NULL

	pop	ax				; ax <- string size (again)
DBCS <	shr	ax, 1				; SRS_searchSize is char count>
	add	ax, 1				; Account for NULL
	mov	es:SRS_replaceSize, ax		; Save string length
	
	;
	; bx still holds the block handle.
	;
	call	MemUnlock			; Release the block
	mov	dx, bx				; Return the handle in dx
	.leave
	ret
CreateSearchReplaceBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RevertToOriginalDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the undo mechanism to allow us to undo the merge

CALLED BY:	CleanupAfterMerge, MergeNextEntry
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We used to do a physical-revert on the document here.
	
	The code which ignores undo actions generated from the current
	undo has been commented out because it doesn't work with the
	existing undo stuff.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RevertToOriginalDocument	proc	far
	uses	ax, bx, cx, dx, di, bp
	.enter	inherit	WriteDocumentContinuePrinting
	
	;
	; Suspend the text objects so the undo stuff won't bother.
	;
	call	SuspendAllTextObjects
	

	call	GeodeGetProcessHandle		; bx <- process handle

	;
	; Cause the undo to happen.
	;
	mov	ax, MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	;
	; Now force the text object to update itself.
	;
	call	UnsuspendAllTextObjects

	.leave
	ret
RevertToOriginalDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin a new undoable action.

CALLED BY:	SubstituteForFieldNames
PASS:		*ds:si	= Instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartUndoChain	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter	inherit	WriteDocumentContinuePrinting
	
	;
	; Tell the process to start a new undo chain.
	;
	
	;
	; Allocate a stack frame.
	;
	mov	dx, size StartUndoChainStruct	; dx <- size of frame
	sub	sp, dx				; Allocate space
	mov	bp, sp				; ss:bp <- frame ptr

	;
	; Fill in the blanks.
	;
	mov	ss:[bp].SUCS_title.chunk, offset MergeUndoString
	mov	ss:[bp].SUCS_title.handle, handle StringsUI
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].SUCS_owner, axsi

	;
	; Deliver the message.
	;
	mov	ax, MSG_GEN_PROCESS_UNDO_START_CHAIN
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage

	add	sp, size StartUndoChainStruct	; Restore stack
	.leave
	ret
StartUndoChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a new undoable action.

CALLED BY:	SubstituteForFieldNames
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndUndoChain	proc	near
	uses	ax, bx, cx, dx, di, bp
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Tell the process we're done with the undoable operation.
	;
	mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
	call	GeodeGetProcessHandle
	mov	cx, -1				; Nuke empty chains
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
EndUndoChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeUndoability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the undo chain so the user sees "nothing to undo"

CALLED BY:	CleanupAfterMerge
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeUndoability	proc	near
	uses	ax, bx, cx, dx, di, bp
	.enter	inherit	WriteDocumentContinuePrinting
	;
	; Tell the process we're don't have anything to undo anymore.
	;
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
NukeUndoability	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupContextForMergeUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a context for the merge undo. This allows us to retain
		the old undo context so the user will still have their own
		undo stuff when we're done.

CALLED BY:	SetupForMerge
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
RETURN:		oldUndoContext set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupContextForMergeUndo	proc	near
	uses	ax, bx, cx, dx, di
	.enter	inherit	WriteDocumentContinuePrinting

	push	bp				; Save frame ptr
	mov	cx, ds:LMBH_handle
	mov	dx, si
	mov	ax, MSG_GEN_PROCESS_UNDO_SET_CONTEXT
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx.dx <- old context
	pop	bp				; Restore frame ptr
	
	movdw	oldUndoContext, cxdx

	.leave
	ret
SetupContextForMergeUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreContextAfterMergeUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the old undo context after the merge undo. This
		allows us to recover the old undo context so the user
		will still have their own undo stuff.

CALLED BY:	CleanupAfterMerge
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
			oldUndoContext set
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreContextAfterMergeUndo	proc	near
	uses	ax, bx, cx, dx, di, bp
	.enter	inherit	WriteDocumentContinuePrinting

	movdw	cxdx, oldUndoContext

	mov	ax, MSG_GEN_PROCESS_UNDO_SET_CONTEXT
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx.dx <- old context

	.leave
	ret
RestoreContextAfterMergeUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuspendAllTextObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend all articles in the document.

CALLED BY:	SubstituteForFieldNames, RevertToOriginalDocument
PASS:		*ds:si	= WriteDocument instance
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuspendAllTextObjects	proc	near
	mov	ax, MSG_META_SUSPEND
	call	SendToAllTextObjects
	ret
SuspendAllTextObjects	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnsuspendAllTextObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend all articles in the document.

CALLED BY:	SubstituteForFieldNames, RevertToOriginalDocument
PASS:		*ds:si	= WriteDocument instance
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnsuspendAllTextObjects	proc	near
	mov	ax, MSG_META_UNSUSPEND
	call	SendToAllTextObjects
	ret
UnsuspendAllTextObjects	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToAllTextObjects

DESCRIPTION:	Send a message to all text objects

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	ax - message

RETURN:
	none

DESTROYED:
	ax, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 7/93		Initial version

------------------------------------------------------------------------------@
SendToAllTextObjects	proc	near	uses bx, cx, dx, si, bp, ds, es
	.enter

	call	LockMapBlockES				;es = map block

	; send to all articles

	mov	di, mask MF_RECORD
	call	SendToAllArticles

	call	ObjMessage				;di = message
	mov	bp, di					;bp = message

	; send to main body

	mov	ax, es:MBH_grobjBlock
	call	WriteVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MainBody			;cx:si = main body
	mov	ax, MSG_WRITE_GROBJ_BODY_SEND_TO_ALL_TEXT_OBJECTS
	clr	di
	call	ObjMessage

	; send to all master page bodies

	; enumerate all sections

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset SendToAllTOCallback
	call	ChunkArrayEnum

	mov	bx, bp
	call	ObjFreeMessage

	call	VMUnlockES

	.leave
	ret

SendToAllTextObjects	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToAllTOCallback

DESCRIPTION:	Send a message to all text objects

CALLED BY:	WriteDocumentReportPageSize (via ChunkArrayEnum)

PASS:
	ds:di - SectionArrayElement
	bp - message

RETURN:
	carry - clear (continue enumeration)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
SendToAllTOCallback	proc	far

	; loop through each master page

	mov	cx, ds:[di].SAE_numMasterPages
	clr	bx
sendLoop:
	push	bx, cx, di

	mov	bx, ds:[di][bx].SAE_masterPages
	call	VMBlockToMemBlockRefDS
	mov	si, offset MasterPageBody		;bx:si = body

	mov	ax, MSG_WRITE_GROBJ_BODY_SEND_TO_ALL_TEXT_OBJECTS
	clr	di
	call	ObjMessage

	pop	bx, cx, di
	add	bx, size hptr
	loop	sendLoop

	clc
	.leave
	ret

SendToAllTOCallback	endp

DocMerge	ends
