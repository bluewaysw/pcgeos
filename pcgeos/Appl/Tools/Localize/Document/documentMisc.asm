COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit/Document
FILE:		documentMisc.asm

AUTHOR:		Cassie Hartzog, Oct  9, 1992

ROUTINES:
	Name			Description
	----			-----------
EXT	DocumentSetNameAndNotes
				MSG_RESEDIT_DOCUMENT_SET_NAME_AND_NOTES

EXT	DocumentUpdateGeodeName
				MSG_RESEDIT_DOCUMENT_UPDATE_GEODE_NAME

EXT	DocumentRevertToOriginalItem
				MSG_RESEDIT_DOCUMENT_REVERT_TO_ORIGNAL_ITEM

EXT	DocumentRedrawCurrentChunk
				MSG_RESEDIT_DOCUMENT_REDRAW_CURRENT_CHUNK

EXT	DocumentSetTypeFilterListState
				MSG_RESEDIT_DOCUMENT_SET_TYPE_FILTER_LIST_STATE

EXT	DocumentSetStateFilterListState	
				MSG_RESEDIT_DOCUMENT_SET_STATE_FILTER_LIST_STATE
EXT	DocumentSetChunkTypeFilters
				MSG_RESEDIT_DOCUMENT_SET_CHUNK_TYPE_FILTERS

EXT	DocumentSetChunkStateFilters
				MSG_RESEDIT_DOCUMENT_SET_CHUNK_STATE_FILTERS

EXT	ToggleSelectionState	Toggles DocumentState bit DS_DOING_SELECTION.
				handler for 
				MSG_RESEDIT_DOCUMENT_TOGGLE_SELECTION_STATE

EXT	DocumentSetState	MSG_RESEDIT_DOCUMENT_SET_STATE

EXT	DocumentGetState	MSG_RESEDIT_DOCUMENT_GET_STATE
				
EXT	DocumentDisplayMessage	Displays an error dialog. Handler for
				MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE

EXT	DocumentSetNewTarget	changes REDI_newTarget
EXT	DocumentGainedModelExcl
EXT	DocumentLostModelExcl

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 9/92	Initial revision

DESCRIPTION:
	Miscellaneous document methods.

	$Id: documentMisc.asm,v 1.1 97/04/04 17:14:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceRef	DocMisc_ObjMessage_send

DocumentMiscCode	segment	resource
;---
DocMisc_ObjMessage_stack	proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	pop	di
	ret
DocMisc_ObjMessage_stack	endp

DocMisc_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocMisc_ObjMessage_call		endp
;---


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetCopyright
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the copyright name for the geode from the UI.

CALLED BY:	MSG_RESEDIT_DOCUMENT_SET_COPYRIGHT

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	bx, dx, si, di, ds, es (method handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	12/11/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetCopyright	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_SET_COPYRIGHT
noticeString	local	FileCopyrightNotice
	.enter
	call	GetFileHandle			; bx <- DB File handle
	call	DBLockMap			;*es:di <- TransMapHeader
	mov	di, es:[di]

	;
	; Alloc a new DB Item, if necessary.
	;
	mov	si, di			; es:si <- TransMapHeader
	mov	ax, es:[si].TMH_copyrightGroup
	mov	di, es:[si].TMH_copyrightItem
	tst	di
	jnz	allocDone

	mov	ax, DB_UNGROUPED
	mov	cx, GFH_NOTICE_SIZE
	call	DBAlloc		; di <- item handle
				; ax <- group handle
	mov	es:[si].TMH_copyrightGroup, ax
	mov	es:[si].TMH_copyrightItem, di

	; dirty the header and unlock it
	call	DBDirty	

allocDone:
	call	DBUnlock
	; ax <- group handle
	; di <- item handle
	call	DBLock		; es:*di <- item
	call	DBDirty

	; Get the copyright string from the UI
	push	di
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	dx, ss
	push	bp
	lea	bp, ss:[noticeString]		; dx:bp <- noticeString
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset NewCopyrightText	; bx:si <- text obj. optr
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	; Copy the string to the db item
	pop	di	; di <- chunk handle of db item
	mov	di, es:[di]	; es:di <- item contents (dest)
	segmov	ds, ss, ax
	lea	si, ss:[noticeString]	; ds:si (src)
	mov	cx, GFH_NOTICE_SIZE
	rep	movsb
	call	DBUnlock

	.leave
	ret
DocumentSetCopyright	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetNameAndNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has changed geode name and/or notes.

CALLED BY:	MSG_RESEDIT_DOCUMENT_SET_NAME_AND_NOTES
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
	cassie	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetNameAndNotes		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_SET_NAME_AND_NOTES

	call	GetFileHandle
	call	DBLockMap			;*es:di <- TransMapHeader
	mov	di, es:[di]
	;
	; get the longname from the GenText into the map block
	;
	push	di
	lea	bp, es:[di].TMH_destName	;es:bp <- text buffer
	GetResourceHandleNS 	ResEditFileName, bx
	mov	di, offset ResEditFileName	;^lbx:di <- GenText
	mov	cx, FILE_LONGNAME_LENGTH
	call	GetTextField
	pop	di

	lea	bp, es:[di].TMH_userNotes	;es:bp <- text buffer
	mov	di, offset ResEditUserNotes	;^lbx:di <- GenText
	mov	cx, GFH_USER_NOTES_LENGTH	
	call	GetTextField	

	call	DBUnlock
	ret

DocumentSetNameAndNotes		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentUpdateGeodeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used to change name of source geode stored in translation
		file, for times when the geode's longname changes between
		builds.

CALLED BY:	MSG_RESEDIT_DOCUMENT_UPDATE_GEODE_NAME
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
	cassie	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentUpdateGeodeName		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_UPDATE_GEODE_NAME

	call	GetFileHandle
	call	DBLockMap			;*es:di <- TransMapHeader
	mov	di, es:[di]
	;
	; get the longname from the GenText into the map block
	;
	lea	bp, es:[di].TMH_sourceName	;es:bp <- text buffer
	GetResourceHandleNS 	UpdateNameTextEntry, bx
	mov	di, offset UpdateNameTextEntry	
	mov	cx, FILE_LONGNAME_LENGTH
	call	GetTextField
	call	DBUnlock
	;
	; send the dismiss command in case we got here after user pressed
	; enter while in text object (that won't close the interaction)
	;
	mov	cx, IC_DISMISS	
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	si, offset UpdateNameTextEntry
	clr	di		
	call	ObjMessage		

	ret

DocumentUpdateGeodeName		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text from a GenText into TransMapHeader, mark
		it and document dirty.

CALLED BY:	DocumentUpdateGeodeName, DocumentSetNameAndNotes
PASS:		*ds:si - document
		es:bp - destination buffer
		cx - buffer length
		^lbx:di - GenText
RETURN:		
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/11/95		Initial version
	JM	4/24/95		bug fix - push si, mov si,di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextField		proc	near
	.enter

	push	si
	mov	si, di				;^lbx:si = GenText
EC <	push	cx							>
	mov	dx, es				;dx:bp <- string buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR	;cx <- string length
	call	DocMisc_ObjMessage_call
	call	DBDirty
EC <	pop	ax							>
EC <	cmp	cx, ax							>
EC <	ERROR_A	RESEDIT_INTERNAL_LOGIC_ERROR				>

	pop	si
	mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
	call	ObjCallInstanceNoLock
		
	.leave
	ret

GetTextField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentRevertToOriginalItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete translation item.

CALLED BY:	MSG_RESEDIT_DOCUMENT_REVERT_TO_ORIGINAL_ITEM
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)
		cx, dx, bp
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentRevertToOriginalItem		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_REVERT_TO_ORIGINAL_ITEM

document	local	optr
	.enter

	mov	bx, ds:[LMBH_handle]
	movdw 	ss:[document], bxsi
	call	GetFileHandle			;^hbx <- translation file
	segmov	es, ds, ax	

	; if there is a translation item, free it
	;
	mov	ax, es:[di].REDI_resourceGroup
	clr	cx
	xchg	cx, es:[di].REDI_transItem
EC<	tst	cx						>
EC<	jz	noFree						>
	push	di
	mov	di, cx
	call	DBFree
	pop	di

EC<noFree:							>
	; lock the resource array, get the element's ptr, clr transItem
	;
	push	ax				;save group number
	mov	ax, es:[di].REDI_curChunk
	call	DerefElement			;ds:di <- element
	call	DBDirty_DS
	pop	ax
	clr	ds:[di].RAE_data.RAD_transItem	;get rid of transItem nubmer

	; if it is an object, need to lock origItem to get the original
	; KeyboardShortcut.
	;
	mov	cl, ds:[di].RAE_data.RAD_chunkType
	test	cl, mask CT_OBJECT
	jnz	lockIt

	; if not a text moniker, don't have to worry about the mnemonic
	;
	test	cl, mask CT_TEXT or mask CT_MONIKER
	LONG	jz	unlock

lockIt:
	; lock the original item, get its mnemonic and store it in
	; the resource array element
	;
	mov	si, di					;ds:si <- ResArrayElem
	mov	di, ds:[si].RAE_data.RAD_origItem
	call	DBLock				
	mov	di, es:[di]				;es:di <- OrigItem
	test	cl, mask CT_OBJECT
	LONG	jnz	itsAnObject

	mov	ah, es:[di].VM_data.VMT_mnemonicOffset	
	mov	ds:[si].RAE_data.RAD_mnemonicType, ah
	;
	; Now assume that the mnemonic is in the moniker text and add
	; the size of the moniker structure to get the offset to the
	; char within the moniker.
	; DBCS: use cx to hold the mnemonic
	;
	mov	bl, ah					;bl <- mnemonic offset
	clr	bh					;bx <- offset in text
DBCS <	shl	bx, 1					;bx <- offset in text	>
	add	bx, MONIKER_TEXT_OFFSET			;bx <-offset in moniker
SBCS <	clr	al					;no char initially	>
DBCS <	clr	cx					;no char initially	>




	cmp	ah, VMO_CANCEL				; is mnemonic CANCEL?
	je	noMnemonic				;   yes, so no char
	cmp	ah, VMO_NO_MNEMONIC			; is there no mnemonic?
	je	noMnemonic				;   yes, no char
	cmp	ah, VMO_MNEMONIC_NOT_IN_MKR_TEXT	; is it after text?
	jne	inText					;   no, it's in text
	ChunkSizePtr	es, di, bx			; get size of chunk
	dec	bx					; bx <- offset of last
							;   byte in the chunk
DBCS <	dec	bx					; bx <- of last word	>
inText:
	add	di, bx					; di <- mnemonic offset
SBCS <	mov	al, {char}es:[di]			; al <- mnemonic char	>
DBCS <	mov	cx, {wchar}es:[di]			; cx <- mnemonic char	>

	; SBCS note: assume cx destroyed from this point on
	;
noMnemonic:
SBCS <	mov	ds:[si].RAE_data.RAD_mnemonicChar, al	; save the new mnemonic	>
DBCS <	mov	ds:[si].RAE_data.RAD_mnemonicChar, cx	; ack, ah being used	>
	call	DBUnlock_DS				; unlock ResourceArray
	call	DBUnlock				; unlock OrigItem

	movdw	bxsi, ss:[document]
	call	MemDerefDS
	DerefDoc
	mov	ds:[di].REDI_mnemonicType, ah
SBCS <	mov	ds:[di].REDI_mnemonicChar, al				>
DBCS <	mov	ds:[di].REDI_mnemonicChar, cx				>
	
done:
	call	ObjMarkDirty
	call	DocumentRedrawCurrentChunk

	GetResourceHandleNS	EditUndo, bx
	mov	si, offset EditUndo
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	.leave
	ret

itsAnObject:
	; The chunk is an object, get the original kbd shortcut.
	;
	ChunkSizePtr	es, di, bx			; get size of chunk
	sub	bx, 2					; es:bx+di <- KbdShortcut
	add	bx, di
	mov	ax, es:[bx]				; original shortcut
	call	DBUnlock
	mov	ds:[si].RAE_data.RAD_kbdShortcut, ax
	
unlock:
	; The chunk is not a text moniker. Unlock the resource array,
	; and dereference the document.
	;
	call	DBUnlock_DS				;unlock ResourceArray
	movdw	bxsi, ss:[document]
	call	MemDerefDS				;*ds:si <- document

	; If the chunk is an object, it has a shortcut which needs to
	; be reset.  Reinitialize the shortcut UI, as well.
	;
	test	cl, mask CT_OBJECT
	jz	done
	DerefDoc
	mov	ds:[di].REDI_kbdShortcut, ax
	call	InitializeKbdShortcut
	jmp	done
	
DocumentRevertToOriginalItem		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentRedrawCurrentChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current chunk has been changed by undo,
		cut, or paste.  Invalidate the chunk, and chunks below
		it if its height changed.

CALLED BY:	DocumentRevertToOriginalItem, DocumentClipboardCut,
		DocumentClipboardPaste.

PASS:		*ds:si - document instance data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentRedrawCurrentChunk		method  ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_REDRAW_CURRENT_CHUNK
	uses	ax,bx,cx,dx,di,bp
	.enter


	; get the stored chunk bounds
	;
	DerefDoc
	mov	ax, ds:[di].REDI_curChunk
	call	GetChunkBounds				;cx = top, dx = bottom

	mov	ax, dx
	sub	ax, cx
	sub	ax, (2*SELECT_LINE_WIDTH)		;ax <- current height

	; recalculate the translation item's chunk height
	; 
	push	dx
	clc						;get trans item height
	call	GetChunkHeight				;dx <- new trans height
	pop	bx				

	; If the size has not changed, just invalidate the
	; region in which this chunk is drawn.
	;
	cmp	ax, dx
	jne	heightChanged

invalidate:
	sub	sp, size VisAddRectParams
	mov	bp, sp
	mov	ss:[bp].VARP_bounds.R_top, cx
	mov	ss:[bp].VARP_bounds.R_bottom, bx
	clr	ss:[bp].VARP_bounds.R_left
	mov	ax, ds:[di].REDI_viewWidth
	mov	ss:[bp].VARP_bounds.R_right, ax
	clr	ss:[bp].VARP_flags

	mov	dx, size VisAddRectParams
	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	mov	bx, ds:[LMBH_handle]
	call	DocMisc_ObjMessage_stack
	add	sp, size VisAddRectParams

done:
	.leave
	ret

heightChanged:
	;
	; The new trans item is no longer the same size.  See if the
	; old trans item determined the height.  If so, we must resize.  
	; We have:
	;     ax <- height of old trans item
	;     dx <- height of new trans item
	;
	mov	bp, dx				;bp <- height of new transItem
	stc					;get orig item's height
	call	GetChunkHeight			;dx <- height of orig item
	cmp	ax, dx				;is old transItem > OrigItem
	ja	resize
	;
	; Okay, the orig item is bigger than the old trans item.
	; If it is also bigger than the new trans item, no need to
	; resize.
	;
	cmp	dx, bp				;is origItem > new transItem?
	jae	invalidate			;yes, don't need to resize

resize:
	mov	dx, bp				;dx <- height of new transItem

	; 
	; It seems that the new trans item is larger than the old
	; trans item and the orig item, so we will need to update
	; the PosArray and resize the view.
	;
	mov	ax, MSG_RESEDIT_DOCUMENT_HEIGHT_NOTIFY
	call	ObjCallInstanceNoLock
	jmp	done

DocumentRedrawCurrentChunk		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetTypeFilterListState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of the ChunkTypeFilterList to reflect the
		document's internal state.

CALLED BY:	MSG_RESEDIT_DOCUMENT_SET_TYPE_FILTER_LIST_STATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cl - ChunkType filters to set

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetTypeFilterListState		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_SET_TYPE_FILTER_LIST_STATE
	uses	cx,dx,bp
	.enter

	mov	ds:[di].REDI_typeFilter, cl		;set these filters
	clr	ch
	clr	dx

	call	ObjMarkDirty

	GetResourceHandleNS	ChunkTypeFilterList, bx
	mov	si, offset ChunkTypeFilterList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

	.leave
	ret
DocumentSetTypeFilterListState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetStateFilterListState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of the FilterList to reflect the
		document's internal state.

CALLED BY:	MSG_RESEDIT_DOCUMENT_SET_STATE_FILTER_LIST_STATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cl - ChunkState filters to set

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetStateFilterListState		method dynamic ResEditDocumentClass,
			MSG_RESEDIT_DOCUMENT_SET_STATE_FILTER_LIST_STATE
	uses	cx,dx,bp
	.enter

	clr	dx
	clr	ch
	mov	ds:[di].REDI_stateFilter, cl		;set these filters
	
	call	ObjMarkDirty

	GetResourceHandleNS	ChunkStateFilterList, bx
	mov	si, offset ChunkStateFilterList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

	.leave
	ret
DocumentSetStateFilterListState		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetChunkTypeFilters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The ChunkTypeFilterList state has changed.

CALLED BY:	UI - MSG_RESEDIT_DOCUMENT_SET_CHUNK_TYPE_FILTERS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx - Booleans currently selected
		dx - Booleans whose state is indeterminate
		bp - Booleans whose state have been modified

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetChunkTypeFilters	method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_SET_CHUNK_TYPE_FILTERS

	tst	bp			
	jz	done				;if no change, we're done
	mov	ds:[di].REDI_typeFilter, cl
	call	DocumentSetFiltersCommon

done:
	ret

DocumentSetChunkTypeFilters	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetChunkStateFilters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The ChunkStateFilterList state has changed.

CALLED BY:	UI - MSG_RESEDIT_DOCUMENT_SET_CHUNK_TYPE_FILTERS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx - first selected item
		bp - number of items selected
		dl - GenItemGroupStateFlags

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetChunkStateFilters	method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_SET_CHUNK_STATE_FILTERS

	mov	ds:[di].REDI_stateFilter, mask CS_CHANGED
	cmp	cx, CSE_CHANGED
	je	done

	mov	ds:[di].REDI_stateFilter, mask CS_ADDED
	cmp	cx, CSE_ADDED
	je	done

	mov	ds:[di].REDI_stateFilter, mask CS_DELETED
	cmp	cx, CSE_DELETED
	je	done

	clr	ds:[di].REDI_stateFilter

done:
	call	DocumentSetFiltersCommon

	ret
DocumentSetChunkStateFilters	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetFiltersCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with changing display to reflect new filters.

CALLED BY:	
PASS:		*ds:si	- document
		ds:di	- document
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:
	XXX: Could be smarter here and save the RAD_number of the
	current chunk, then after resetting the filters, look for 
	a chunk with that number, get its relative element number,
	and change to that chunk instead of chunk 0.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetFiltersCommon		proc	near
	.enter

	call	ObjMarkDirty

	; Change to the same resource to force a redraw so 
	; filtered chunks won't be shown.  
	;
	mov	cx, ds:[di].REDI_curResource
	mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE
	call	ObjCallInstanceNoLock

	; Check to see if any chunks in this resource passes
	; the new filters - if so, change to chunk 0.
	;
	tst	ds:[di].REDI_numChunks
	jz	done
	clr	cx
	mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_CHUNK
	call	ObjCallInstanceNoLock
			
done:
	.leave
	ret
DocumentSetFiltersCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set and clear the passed DocumentState flags.

CALLED BY:	ContentVisDraw, for one.

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cl - flags to clear
		ch - flags to set

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetState		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_SET_STATE

	not	cl
	andnf	ds:[di].REDI_state, cl
	ornf	ds:[di].REDI_state, ch
	ret
DocumentSetState		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentGetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return current DocumentState

CALLED BY:	ContentVisDraw, for one.

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		cl - DocumentState

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentGetState		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_GET_STATE

	mov	cl, ds:[di].REDI_state
	ret
DocumentGetState		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDisplayMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to show the user a message.

CALLED BY:	MSG_RESEDIT_DOCUMENT_MESSAGE or called directly

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx - ErrorValue
		DX:BP	= Possible data for first string argument
		BX:SI	= Possible data for second string argument

RETURN:		nothing

DESTROYED:	ax,cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentDisplayMessage		method  ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
	uses	bx,dx,si,bp
	.enter

	push	ds:[LMBH_handle]

EC <	cmp	cx, ErrorValue						>
EC <	ERROR_GE	DISPLAY_ERROR_BAD_ERROR_VALUE			>
EC <	cmp	cx, EV_NO_ERROR						>
EC <	ERROR_E		DISPLAY_ERROR_BAD_ERROR_VALUE			>

	clr	ax
	pushdw	axax				;SDP_helpContext
	pushdw	axax				;SDP_customTriggers
	pushdw	bxsi				;SDP_stringArg2
	pushdw	dxbp				;SDP_stringArg1

	mov	bx, handle ErrorStrings
	call	MemLock
	mov	ds, ax
	mov	si, offset ErrorStrings:ErrorArray
	mov	si, ds:[si]			;ds:si <- ErrorArray

	add	si, cx
	mov	si, ds:[si]			;^lsi <- string handle
	mov	si, ds:[si]
	pushdw	dssi				;SDP_customString

	mov	ax, CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION, 0>
	push	ax				;SDP_customFlags
	call	UserStandardDialog
	call	MemUnlock

	pop	bx
	call	MemDerefDS

	.leave
	ret

DocumentDisplayMessage		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetNewTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the target field

CALLED BY:	MSG_RESEDIT_DOCUMENT_SET_TARGET
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		dl - SourceType to set

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetNewTarget		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_SET_NEW_TARGET
	mov	ds:[di].REDI_newTarget, dl 
	call	ObjMarkDirty
	ret
DocumentSetNewTarget		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentGainedModelExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new document has become the current document,
		and needs to add itself to the clipboard notification list.

CALLED BY:	MSG_META_GAINED_MODEL_EXCL
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
	cassie	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentGainedModelExcl		method dynamic ResEditDocumentClass,
						MSG_META_GAINED_MODEL_EXCL

	mov	di, offset ResEditDocumentClass
	call	ObjCallSuperNoLock

	mov	cx, ds:[LMBH_handle]
	mov	dx, si	
	call	ClipboardAddToNotificationList	

	mov	di, ds:[si]
	add	di, ds:[di].ResEditDocument_offset
	call	SetUIState

	ret
DocumentGainedModelExcl		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentLostModelExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current document has lost the model exclusive, so
		needs to remove itself from the notification list.

CALLED BY:	MSG_META_LOST_MODEL_EXCL
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
	cassie	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentLostModelExcl		method dynamic ResEditDocumentClass,
						MSG_META_LOST_MODEL_EXCL

	mov	di, offset ResEditDocumentClass
	call	ObjCallSuperNoLock
	
	mov	cx, ds:[LMBH_handle]
	mov	dx, si	
	call	ClipboardRemoveFromNotificationList

	ret
DocumentLostModelExcl		endm


DocumentMiscCode	ends

