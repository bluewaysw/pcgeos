COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit/Document
FILE:		documentUtilities.asm

AUTHOR:		Cassie Hartzog, Jan 20, 1993

ROUTINES:
	Name			Description
	----			-----------
EXT	GetFileHandle		returns the document's file handle 
				(localization DB file)

EXT	GetDisplayHandle	returns the document's display handle

EXT	DBLockMap_DS		locks the map block to *ds:si

EXT	DBLock_DS		locks a DB item to *ds:si

EXT	DBUnlock_DS		unlocks the block in segment ds

EXT	DBDirty_DS		marks the block in ds as dirty

EXT	EnumAllChunks		enumerate all chunks, with callback 

EXT	DocumentGoToResourceChunkTarget
				change to passed resource, chunk, target

INT	DocumentTransferTarget	moves the target between views

INT	DocumentSetCurTarget	gives target to current text target
				
EXT	SendToContentObjects	sends the passed message to the 2 contents

EXT	FindResourceNumber
INT	FindResourceCallback

EXT	GetChunkBounds		Returns the chunk top and bottom coordinates.

EXT	IsChunkVisible		Determines if a chunk is currently visible.

EXT	IsChunkDirty		Determines if a chunk is currently visible.
EXT	IsSomethingSelected

EXT	ResArrayElementToPtr	Finds the nth element in the ResArray which
				meets the current filter criteria.

EXT	ResArrayPtrToElement	Given an element pointer, return the relative
				number given the filter criteria.

EXT	ResMapGetArrayCount	Get the count of chunks from the resource map
				which meet the filter criteria.
EXT	ResArrayGetCount

EXT	ResMapElemenToPtr

EXT	SetEditMenuState

EXT	ShortcutToAscii

EXT	AssertIsResEditDocument EC code to check for correct object type

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	1/20/93		Initial revision

DESCRIPTION:
	Utility routines used in the Document module.

	$Id: documentUtilities.asm,v 1.1 97/04/04 17:14:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentUtilitiesCode	segment	resource

;---

DocUtil_ObjMessage_stack	proc	near
	ForceRef DocUtil_ObjMessage_stack
	push	di
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	pop	di
	ret
DocUtil_ObjMessage_stack	endp

DocUtil_ObjMessage_send		proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocUtil_ObjMessage_send		endp

DocUtil_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocUtil_ObjMessage_call		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetFileHandle
DESCRIPTION:	Get the file handle from the instance data
CALLED BY:	INTERNAL
PASS:		*ds:si - document object
RETURN:		bx - file handle
DESTROYED:	none

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
GetFileHandle	proc	far	

	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	bx, ds:[si].GDI_fileHandle
	pop	si
	ret

GetFileHandle	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetDisplayHandle
DESCRIPTION:	Get the display handle from the instance data
CALLED BY:	INTERNAL
PASS:		*ds:si - document object
RETURN:		bx - display handle
DESTROYED:	none

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	10/ 9/92	Initial version

------------------------------------------------------------------------------@
GetDisplayHandle	proc	far

	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	bx, ds:[si].GDI_display
	pop	si
	ret

GetDisplayHandle	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DBLockMap_DS
DESCRIPTION:	Lock the map block to DS
CALLED BY:	EXTERNAL - utility
PASS:
	^hbx	- file handle

RETURN:
	*ds:si - map block (locked)

DESTROYED:
	nothing

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 9/92	Initial version

------------------------------------------------------------------------------@
DBLockMap_DS	proc	far	uses es,di
	.enter

	call	DBLockMap
	segmov	ds, es
	mov	si, di
	
	.leave
	ret

DBLockMap_DS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBLock_DS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a DB item into ds.  If ax is passed as zero,
		lock the map block.

CALLED BY:	(EXTERNAL) utility
PASS:		ax:di  	= DBItem to lock 
		bx 	= file handle

RETURN:		*ds:si - name array
DESTROYED:	nothing - flags preserved

PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBLock_DS	proc far
	uses	ax, es, di
	.enter

	pushf
	call	DBLock
	segmov	ds, es
	mov	si, di
	popf

	.leave
	ret
DBLock_DS	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUnlock_DS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a db item whose segment is in ds

CALLED BY:	(EXTERNAL) utility
PASS:		ds - segment to unlock
RETURN:		nothing 
DESTROYED:	nothing - flags preserved 

PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBUnlock_DS	proc far
	push	es
	segmov	es, ds
	call	DBUnlock
	pop	es
	ret
DBUnlock_DS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDirty_DS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the RE Dbitem as dirty
CALLED BY:	(INTERNAL) utility

PASS:		ds - segment of dbitem to mark dirty
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBDirty_DS	proc far
	push	es
	segmov	es, ds
	call	DBDirty
	pop	es
	ret
DBDirty_DS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find and lock the passed element number.

CALLED BY:	EXTERNAL - Utility

PASS:		*ds:si	- document
		ax	- element number

RETURN:		ds:di	- ResourceArrayElement
		cx	- element size
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Caller must unlock and dirty the element.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefElement		proc	far
	uses	bx,dx,si
	.enter

EC <	call	AssertIsResEditDocument				>
	call	GetFileHandle			;^hbx <- translation file
	mov	si, ds:[si]
	add	si, ds:[si].ResEditDocument_offset

	push	ax	
	mov	dl, ds:[si].REDI_stateFilter
	mov	dh, ds:[si].REDI_typeFilter
	mov	ax, ds:[si].REDI_resourceGroup
	mov	di, ds:[si].REDI_resArrayItem
	call	DBLock_DS			;*ds:si = ResourceArray
	pop	ax

	call	ResArrayElementToPtr		; ds:di <- ResourceArrayElement
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND

	.leave
	ret
DerefElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumAllChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For each resource, enumerate all its chunks.

CALLED BY:	EXTERNAL - utility

PASS:		*ds:si	- document
		ss:bp	- EnumAllChunksStruct

			passed to EACS_callback:
				*ds:si - ResourceArray
				 ds:di - ResourceArrayElement
				 ss:bp - EnumAllChunksStruct
				 dx - file handle
				 cx - resource group

RETURN:		carry set if enumeration was aborted
		
DESTROYED:	bx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumAllChunks		proc	far
	uses	dx,si,bp
	.enter 

	push	ds:[LMBH_handle]

	call	GetFileHandle
	mov	dx, bx
	call	DBLockMap_DS			; *ds:si <- ResourceMap
	mov	bx, cs
	mov	di, offset EnumAllChunksCallback
	call	ChunkArrayEnum	
	call	DBUnlock_DS

	pop	bx
	call	MemDerefDS

	.leave
	ret
EnumAllChunks		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumAllChunksCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the chunks this ResourceArray, calling
		passed callback for each on.

CALLED BY:	EnumAllChunks
PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement
		dx	- file handle
		ss:bp	- EnumAllChunksStruct

RETURN:		carry set to abort
			ax - ErrorValue
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumAllChunksCallback	proc	far
	uses	cx, bp
	.enter 

	push	ds:[LMBH_handle]

	mov	bx, dx
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBLock_DS			; *ds:si <- ResourceArray

	movdw	bxdi, ss:[bp].EACS_callback
	mov	cx, ax				; cx <- group
	call	ChunkArrayEnum
	call	DBUnlock_DS

	pop	bx
	call	MemDerefDS
	.leave
	ret
EnumAllChunksCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentChangeResourceList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has selected a new resource from the ResourceList.
		Go to that resource, and change to chunk 0 within it.

CALLED BY:	MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE_LIST
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx - resource number
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentChangeResourceList		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE_LIST

	clr	dx				; go to chunk 0
	call	DocumentChangeResourceAndChunk	
	ret
DocumentChangeResourceList		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentChangeResourceAndChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to a given resource and chunk, without first
		checking filters.  Don't change target.
		This will most normally be used when changing to the
		next or previous resource, using it's chunk 0.

CALLED BY:	MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE_AND_CHUNK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx - element # of resource
		dx - element # of chunk
RETURN:		carry set if resource or chunk changed
DESTROYED:	bx,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentChangeResourceAndChunk		method ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE_AND_CHUNK
	uses	ax,si
	.enter

	cmp	cx, ds:[di].REDI_curResource
	jne	changeResource
	cmp	dx, ds:[di].REDI_curChunk
	clc
	je	done
	mov	cx, dx
	jmp	changeChunk

changeResource:
	push	dx
	mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE
	call	ObjCallInstanceNoLock
	pop	cx

changeChunk:
	mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_CHUNK
	call	ObjCallInstanceNoLock	
	stc
done:	
	.leave
	ret
DocumentChangeResourceAndChunk		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentGoToResourceChunkTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to a specific resource, chunk, target.
		The chunk number is absolute, i.e. number in
		the ResourceArray, without any filters applied.

CALLED BY:	(EXTERNAL) UTILITY
PASS:		*ds:si	- document
		al	- target
		cx	- element # of resource
		dx	- element # of chunk

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentGoToResourceChunkTarget		proc	far
	uses	ax,bx,cx,dx,di,bp,es
	.enter

	DerefDoc
	segmov	es, ds				
	mov	bl, es:[di].REDI_typeFilter
	mov	bh, es:[di].REDI_stateFilter

	; Check to see if the desired chunk is visible with
	; the current filters.
	;
	push	ax, cx, dx, si, di, ds
	mov	ax, cx				;ax <- resource number
	push	bx				;save the filters
	call	GetFileHandle
	call	DBLockMap_DS
	call	ChunkArrayElementToPtr		;ds:di <- ResMapElement
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBUnlock_DS
	call	DBLock_DS			;*ds:si <- ResArray
	mov	ax, dx				;ax <- chunk number
	call	ChunkArrayElementToPtr		;ds:di <- ResArrayElement
	pop	dx				;restore the filters
	call	ResArrayPtrToElement
	mov	bp, ax				;bp <- relative element number
	call	DBUnlock_DS
	pop	ax, cx, dx, si, di, ds

	cmp	bp, -1		
	jne	chunkPassesFilters
	mov	bp, dx

	; Turn off all filters in case the chunk we are supposed
	; to change to is currently filtered out.
	;
	push	cx
	clr	cl	
	mov	ax, MSG_RESEDIT_DOCUMENT_SET_STATE_FILTER_LIST_STATE
	call	ObjCallInstanceNoLock

	clr	cl	
	mov	ax, MSG_RESEDIT_DOCUMENT_SET_TYPE_FILTER_LIST_STATE
	call	ObjCallInstanceNoLock
	pop	cx

chunkPassesFilters:
	mov	dx, bp				;dx <- relative elmt number
	;
	; Take the target from the current View to the View which has
	; the match.  This has to be done before the resource or chunk
	; is changed, or the text object won't get the target.
	;
	call	DocumentTransferTarget

	; Set REDI_newTarget so CHANGE_RESOURCE and CHANGE_CHUNK
	; know which text object to give the target to.
	;
	mov	ds:[di].REDI_newTarget, al
	call	ObjMarkDirty

	call	DocumentChangeResourceAndChunk
	jc	targetIsAlreadySet
	call	DocumentSetCurTarget
targetIsAlreadySet:
	call	SetEditMenuState	

	.leave
	ret

DocumentGoToResourceChunkTarget		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentTransferTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If changing the source type, need to give the new view 
		the target and focus exclusives so that when the chunk 
		is changed, the text object will get the target.

CALLED BY:	DocumentGoToResourceChunkTarget

PASS:		ds:di	- document instance data
		al	- new target
		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentTransferTarget		proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; match was found in same source, so we're okay.
	;
	cmp	al, ds:[di].REDI_curTarget
	je	done

	cmp	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	notText

	; We have to unselect everything here in case only the source type
	; is changing.  (If chunk changes, it would get unselected there.)
	;
	movdw	bxsi, ds:[di].REDI_editText
	cmp	ds:[di].REDI_curTarget, ST_TRANSLATION
	je	$10
	mov	si, offset OrigText
$10:
	push	ax
	mov	ax, MSG_VIS_TEXT_SELECT_END
	call	DocUtil_ObjMessage_send
	pop	ax

notText:
	; grab the target and focus for the new source's view
	;
	mov	si, offset RightView
	cmp	al, ST_TRANSLATION
	je	$20
	mov	si, offset LeftView
$20:
	mov	bx, ds:[di].GDI_display
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	DocUtil_ObjMessage_send

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	DocUtil_ObjMessage_send

done:
	.leave
	ret

DocumentTransferTarget		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSetCurTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only the source type has changed.  Give the target
		and focus to the correct text object.

CALLED BY:	DocumentGoToResourceChunkTarget
PASS:		ds:di	- document
		al	- new target 

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSetCurTarget		proc	near
	uses	si,di,bp
	.enter

	cmp	al, ds:[di].REDI_curTarget
	je	done
	mov	ds:[di].REDI_curTarget, al		;save new curTarget

	call	ObjMarkDirty

	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	done

	; grab the target for the correct text object
	;
	movdw	bxsi, ds:[di].REDI_editText
	cmp	al, ST_TRANSLATION
	je	$30
	mov	si, offset OrigText

$30:
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	clr	di	
	call	ObjMessage

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	clr	di	
	call	ObjMessage

done:
	.leave
	ret
DocumentSetCurTarget		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToContentObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed message to both content objects.

CALLED BY:	
PASS:		*ds:si	= document
		ax	= message
		cx,dx,bp = data passed by calling routine

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Send to the TransView (document object) first, so that
	it will receive draw messages first.  This is important, for
	the SourceView clears the DS_CHANGING_RESOURCE flag, and this flag
	should not be cleared until both source and trans have called
	VisDrawCommon first, which tests this flag.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToContentObjects		proc	far
	uses	cx,dx,bx,si,bp
	.enter

	; Send to the Document object (me) 
	;
	push	ax, cx, dx, bp
	mov	bx, ds:[LMBH_handle]
	call	DocUtil_ObjMessage_send
	pop	ax, cx, dx, bp	

	; Send to the Content object
	;
	DerefDoc
	mov	bx, ds:[di].REDI_editText.handle
	mov	si, offset OrigContent
	call	DocUtil_ObjMessage_send

	.leave
	ret
SendToContentObjects		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChunkBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the top and bottom coordinates of the element.

CALLED BY:	MakeChunkVisible

PASS:		*ds:si 	= document 
		ax	= chunk number

RETURN:		cx, dx	= top and bottom

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChunkBounds		proc	far
	uses	ax,bx,si,di,es
	.enter

	DerefDoc
EC <	cmp	ax, ds:[di].REDI_numChunks			>
EC <	ERROR_AE INVALID_CHUNK_NUMBER				>

	push	ax
	mov	bx, ds:[di].REDI_posArray
	call	MemLock
EC < 	ERROR_C	RESEDIT_POSARRAY_CORRUPT			>
	mov	es, ax
	pop	ax					;ax <- element number
	mov	si, size PosElement
	mul	si
	mov	si, ax

	mov	cx, es:[si].PE_top
	mov	dx, cx
	add	dx, es:[si].PE_height
	add	dx, (SELECT_LINE_WIDTH*2)
;dec dx?
	call	MemUnlock
	.leave
	ret
GetChunkBounds		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMinMaxValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the localization min/max values.

CALLED BY:	SetCurrentInfo
PASS:		ds:di	- document
		^lbx	- file handle

RETURN:		cx	- min value
		dx	- max value
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMinMaxValues		proc	far
	uses	ax, bx, si, di, ds
	.enter

	mov	cx, ds:[di].REDI_curChunk
	cmp	cx, PA_NULL_ELEMENT
	je	noElement

	mov	dl, ds:[di].REDI_stateFilter
	mov	dh, ds:[di].REDI_typeFilter
	mov	ax, ds:[di].REDI_resourceGroup
	mov	di, ds:[di].REDI_resArrayItem
	call	DBLock_DS
	mov	ax, cx
	call	ResArrayElementToPtr
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_NOT_FOUND 		>
	mov	cx, ds:[di].RAE_data.RAD_minSize
	mov	dx, ds:[di].RAE_data.RAD_maxSize
	call	DBUnlock_DS
done:
	.leave
	ret

noElement:
	clr	cx, dx
	jmp	done

GetMinMaxValues		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsChunkVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to know whether the passed chunk is visible in 
		the current view window.

CALLED BY:	INTERNAL
PASS:		*ds:si	= document
		ax	= chunk number

RETURN:		cl	= VisibilityType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsChunkVisible		proc	far
	uses	ax, bx, dx, di
origin	local	PointDWord
	.enter

	DerefDoc
EC <	cmp	ax, ds:[di].REDI_numChunks			>
EC <	ERROR_AE INVALID_CHUNK_NUMBER				>

	mov	dx, ds:[di].REDI_viewHeight
	push	dx					;save view height
	push	ax					;save element number

	push	bp, si
	mov	bx, ds:[di].GDI_display
	mov	si, offset RightView
	mov	cx, ss
	lea	dx, ss:[origin]
	mov	ax, MSG_GEN_VIEW_GET_ORIGIN		
	call	DocUtil_ObjMessage_call
	pop	bp, si

	pop	ax					;ax <- element number
	pop	bx					;bx <- view height
	call	GetChunkBounds				;cx <-top, dx <-bottom

	mov	ax, origin.PD_y.low			;ax <- doc top
	add	bx, ax					;bx <- doc bottom

	; check if chunk is entirely out of the visible bounds
	cmp 	dx, ax					;if bottom before vis
    	jb	notVisible				; region, not visible
    	cmp	cx, bx					;if chunk top is after
    	ja	notVisible				; visible region, done

	; since chunk top <= vis region bottom and chunk bottom >=
	; vis region top, if chunk top < vis region bottom, chunk bottom
	; must be in the vis region ==> it is partly visible
	cmp	cx, ax					; 
	jb	partVisible	 

	; similarly, since chunk top has now been placed in the vis region,
	; if chunk bottom > vis region bottom, chunk is only partly visible
	cmp	dx, bx
	ja	partVisible
	mov	cl, VT_ALL_VISIBLE
	
done:
	.leave
	ret

notVisible:	
	mov	cl, VT_NOT_VISIBLE
	jmp	done

partVisible:
	mov	cl, VT_PART_VISIBLE
	jmp	done

IsChunkVisible		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentInvalidateChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate a single element so that is is redrawn.

CALLED BY:	EXTERNAL - utility
PASS:		*ds:si	- document
		ax	- element number
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentInvalidateChunk		proc	far
	uses	cx,dx,di,bp
	.enter

	DerefDoc

	; get the top and bottom boundaries of this element
	;
	call	GetChunkBounds			; cx <- top, dx <- bottom

	; invalidate the portion of the document that contains this
	; keyboard shortcut's text.
	;
	sub	sp, size VisAddRectParams
	mov	bp, sp
	clr	ss:[bp].VARP_flags
	mov	ss:[bp].VARP_bounds.R_top, cx
	mov	ss:[bp].VARP_bounds.R_bottom, dx
	mov	ss:[bp].VARP_bounds.R_left, 0
	mov	ax, ds:[di].REDI_viewWidth
	mov	ss:[bp].VARP_bounds.R_right, ax
	mov	dx, size VisAddRectParams
	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	call	ObjCallInstanceNoLock
	add	sp, size VisAddRectParams

	.leave
	ret
DocumentInvalidateChunk		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindResourceNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the ResourceMapElement whose number matches value passed.

CALLED BY:	EXTERNAL

PASS:		*ds:si	- ResourceMap
		ax	- resource number to look for

RETURN:		carry clear if successful
			ds:di	- ResourceMapElement
		carry set if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindResourceNumber		proc	far
	uses	ax,bx,cx
	.enter

	mov	cx, ax
	mov	bx, cs
	mov	di, offset FindResourceNumberCallback
	call	ChunkArrayEnum			;ax <- element number
	jnc	notFound
EC <	call	ChunkArrayGetCount				>
EC <	cmp	ax, cx						>
EC <	ERROR_GE	CHUNK_ARRAY_ELEMENT_NOT_FOUND		>
	call	ChunkArrayElementToPtr
	stc
notFound:	
	cmc
	.leave
	ret
FindResourceNumber		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindResourceNumberCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does this ResourceMapElement have the number I'm looking for?

CALLED BY:	FindResourceNumber (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement
		cx	- number to look for

RETURN:		carry set if this element has the number I'm looking for
			ax - element number
		carry clear if no match, to continue enumeration

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindResourceNumberCallback		proc	far
	.enter
	cmp	cx, ds:[di].RME_data.RMD_number
	clc
	jne	continue
	call	ChunkArrayPtrToElement
	stc
continue:
	.leave
	ret
FindResourceNumberCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindChunkNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the ResourceMapElement whose number matches value passed.

CALLED BY:	EXTERNAL

PASS:		*ds:si	- ResourceArray
		ax	- chunk number to look for

RETURN:		carry clear if successful
			ds:di	- ResourceArrayElement
		carry set if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindChunkNumber		proc	far
	uses	ax,bx,cx
	.enter

	mov	cx, ax
	mov	bx, cs
	mov	di, offset FindChunkNumberCallback
	call	ChunkArrayEnum			;ax <- element number
	jnc	notFound
EC <	call	ChunkArrayGetCount				>
EC <	cmp	ax, cx						>
EC <	ERROR_GE	CHUNK_ARRAY_ELEMENT_NOT_FOUND		>
	call	ChunkArrayElementToPtr
	stc
notFound:	
	cmc
	.leave
	ret
FindChunkNumber		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindChunkNumberCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does this ResourceMapElement have the number I'm looking for?

CALLED BY:	FindChunkNumber (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		cx	- number to look for

RETURN:		carry set if this element has the number I'm looking for
			ax - element number
		carry clear if no match, to continue enumeration

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindChunkNumberCallback		proc	far
	.enter
	cmp	cx, ds:[di].RAE_data.RAD_number
	clc
	jne	continue
	call	ChunkArrayPtrToElement
	stc
continue:
	.leave
	ret
FindChunkNumberCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResMapGetArrayCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns number of elements in this ResourceMap's ResourceArray 
		which meet the current filter criteria.

CALLED BY:	(EXTERNAL)  UTILITY

PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement
		^hbx	- file handle
		dl	- ChunkState filters
		dh	- ChunkType filters

RETURN:		cx	- count

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResMapGetArrayCount		proc	far
	uses	ax,bx,si,di,bp,ds
	.enter

	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBLock_DS				;*ds:si <- ResArray

	call	ChunkArrayGetCount			;cx <- total elements

	clr	bp					;no matches yet
	mov	bx, cs
	mov	di, offset ResArrayElementToPtrCallback
	call	ChunkArrayEnum				;bp <- # matches
	mov	cx, bp
	call	DBUnlock_DS

	.leave
	ret

ResMapGetArrayCount		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResArrayGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of chunks meeting the filter criteria
		in this ResourceArray.

CALLED BY:	(EXTERNAL) Utility

PASS:		*ds:si 	- ResourceArray
		dh	- ChunkType filter
		dl	- ChunkState filter

RETURN:		cx	- count

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResArrayGetCount		proc	far
	uses	ax,bx,di,bp
	.enter

	call	ChunkArrayGetCount			;cx <- total elements

	clr	bp					;no matches yet
	mov	bx, cs
	mov	di, offset ResArrayElementToPtrCallback
	call	ChunkArrayEnum				;bp <- # matches
	mov	cx, bp

	.leave
	ret
ResArrayGetCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResArrayElementToPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the nth element in the ResourceArray which meets
		the filter criteria, stored in REDI_filters

CALLED BY:	EXTERNAL - utility routine

PASS:		*ds:si	- ResourceArray
		ax	- element number
		dl	- ChunkState
		dh	- ChunkType

RETURN:		ds:di	- ResourceArrayElement
		cx	- element size
		carry set if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResArrayElementToPtr		proc	far
	uses	ax,bx,dx,bp
	.enter

	mov	bx, cs
	mov	di, offset ResArrayElementToPtrCallback
	inc	ax
	mov	cx, ax				;cx <- cardinal number
	clr	bp				; no matches found yet
	call	ChunkArrayEnum			;ax <- element number
	cmc
	jc	done
	call	ChunkArrayElementToPtr		;ds:di <- element, cx <- size
	clc

done:
	.leave
	ret
ResArrayElementToPtr		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResArrayElementToPtrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the nth element which matches the filter criteria.

CALLED BY:	ResArrayElemenToPtr (via ChunkArrayEnum)

PASS:		*ds:si	- ResoruceArray
		ds:di	- ResourceArrayElement
		dl	- ChunkState
		dh	- ChunkType
		cx	- element number to find
		bp	- number of matches so far

RETURN:		bp	- number of matches
		ax	- real element number of matching element
		carry set if match found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResArrayElementToPtrCallback		proc	far

	mov	ax, dx
	call	FilterElement			;carry set if passes filters
	jnc	done
	
	;
	; this element meets the ChunkType and ChunkState filter criteria
	; but is it the element number we're looking for?
	;
	inc	bp
	call	ChunkArrayPtrToElement		;ax <- element number
	cmp	cx, bp
	stc
	je	done
	clc
	ret
done:
	ret
ResArrayElementToPtrCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResMapElementToPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the nth element in the ResourceMeap which meets
		the filter criteria, stored in REDI_filters

CALLED BY:	EXTERNAL - utility routine

PASS:		*ds:si	- ResourceMapArray
		ax	- element number
		dx	- filters

RETURN:		ds:di	- ResourceMapElement
		carry set if not found

DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResMapElementToPtr		proc	far
	ForceRef	ResMapElementToPtr
	uses	ax,bx,cx,di,bp
	.enter

	mov	bx, cs
	mov	di, offset ResMapElementToPtrCallback
	mov	cx, ax
	clr	bp				; no matches found yet
	call	ChunkArrayEnum
	clr	di
	jnc	notFound
	mov	di, ax
notFound:
	cmc
	.leave
	ret
ResMapElementToPtr		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResMapElementToPtrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the nth element which matches the filter criteria.

CALLED BY:	ResMapElemenToPtr (via ChunkArrayEnum)

PASS:		*ds:si	- ResoruceMap
		ds:di	- ResourceMapElement
		dl	- ResourceType
		cx	- element number to find
		bp	- number of matches so far

RETURN:		bp	- number of matches
		ds:ax	- ptr to matching element
		carry set if match found
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResMapElementToPtrCallback		proc	far

		
	test	ds:[di].RME_data.RMD_resourceType, dl
	clc
	jz	done
	mov	ax, di
	cmp	cx, bp
	stc
	je	done
	inc	bp
	clc
done:
	ret
ResMapElementToPtrCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResArrayPtrToElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the relative element number of this element,
		given the filter criteria

CALLED BY:	EXTERNAL - utility routine

PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		dl	- ChunkState
		dh	- ChunkType

RETURN:		ax	- relative element number, 
			  or -1 if doesn't meet filter criteria

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResArrayPtrToElement		proc	far
	uses	bx,dx,bp
	ForceRef ResArrayPtrToElement
	.enter

	mov	bp, ds:[di].RAE_data.RAD_number	;bp <- chunk number to look for
	call	ChunkArrayGetCount		;cx <- total # of elements

	clr	ax, bx
nextElement:
	push	ax, cx
	call	ChunkArrayElementToPtr		;ds:di <- next element
	mov	ax, dx				;ax <- filters
	call	FilterElement			;does it pass filters?
	jnc	gotoNext			;no, skip it
	inc	bx				;bx <- relative element #
	cmp	bp, ds:[di].RAE_data.RAD_number	;is this the one we want?
gotoNext:
	pop	ax, cx
	je	foundIt				;yes!
	inc	ax
	loop	nextElement
	stc

done:
	pushf
	dec	bx
	mov	ax, bx
	popf

	.leave
	ret

foundIt:	
	clc
	jmp	done

ResArrayPtrToElement		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilterElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this element meets filter criteria.

CALLED BY:	(INTERNAL) RecalcChunkPosCallback, VisDrawCallback

PASS:		ax	- filters
		ds:di	- ResourceArrayElement

RETURN:		carry set if element meets filter criteria

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilterElement	proc	far

	tst	al
	jz	noStateFilter

	; 
	; if this does not have the correct state, don't count it
	;
	cmp	ds:[di].RAE_data.RAD_chunkState, al
	jne	fail

noStateFilter:
	;
	; if there is no type filter, all types are okay
	;
	tst	ah	
	jz	noTypeFilter

	;
	; If the filter and this chunkType have one or more
	; bits in common, don't count this element
	;
	test	ds:[di].RAE_data.RAD_chunkType, ah
	jnz	fail

noTypeFilter:
	stc
	ret

fail:
	clc
	ret
FilterElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkBusyAndHoldUpInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A lengthy operation is about to commence, so mark
		the application busy and hold up input.

CALLED BY:	(UTILITY)
PASS:		nothign
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkBusyAndHoldUpInput		proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	GetResourceHandleNS	ResEditApp, bx
	mov	si, offset ResEditApp
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	clr	di
	call	ObjMessage

	GetResourceHandleNS	ResEditApp, bx
	mov	si, offset ResEditApp
	mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT
	clr	di
	call	ObjMessage

	.leave
	ret
MarkBusyAndHoldUpInput		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkNotBusyAndResumeInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A lengthy operation has completed, so mark
		the application not busy and resume input.

CALLED BY:	(UTILITY)
PASS:		nothign
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkNotBusyAndResumeInput		proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	GetResourceHandleNS	ResEditApp, bx
	mov	si, offset ResEditApp
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	clr	di
	call	ObjMessage

	GetResourceHandleNS	ResEditApp, bx
	mov	si, offset ResEditApp
	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT
	clr	di
	call	ObjMessage

	.leave
	ret
MarkNotBusyAndResumeInput		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShortcutToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a KeyboardShortcut to its Ascii equivalent, 
		in the form of: (Physical Alt Ctrl g) or (Physical Ctrl >).

CALLED BY:	EXTERNAL 
PASS:		es:di	- buffer to copy text to
		ax	- KeyboardShortcut
RETURN:		cx	- string length (including null)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	KeyboardShortcut	record
	    KS_PHYSICAL:1		;TRUE: match key, not character
	    KS_ALT:1			;TRUE: <ALT> must be pressed
	    KS_CTRL:1			;TRUE: <CTRL> must be pressed
	    KS_SHIFT:1			;TRUE: <SHIFT> must be pressed
	    KS_CHAR_SET:4		;lower four bits of CharacterSet
	    KS_CHAR	Chars:8		;character itself (Char or VChar)
	KeyboardShorcut	end
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShortcutToAscii		proc	far
	uses	ax,bx,si,di,ds
	.enter

	push	di

	mov	cx, ax
	GetResourceHandleNS	StringsUI, bx
	call	MemLock
	mov	ds, ax

	tst	cx
	jz	noShortcut

	LocalLoadChar	ax, '('
	LocalPutChar	esdi, ax

	test	cx, mask KS_PHYSICAL
	jz	noPhysical
	mov	si, offset physicalString
	mov	si, ds:[si]
	LocalCopyString
SBCS <	mov	{byte}es:[di-1], 20h		; replace NULL with space	>
DBCS <	mov	{wchar}es:[di-2], 20h					>

noPhysical:
	test	cx, mask KS_ALT
	jz	noAlt
	mov	si, offset altString
	mov	si, ds:[si]
	LocalCopyString
SBCS <	mov	{byte}es:[di-1], 20h		; replace NULL with space	>
DBCS <	mov	{wchar}es:[di-2], 20h					>

noAlt:
	test	cx, mask KS_CTRL
	jz	noCtrl
	mov	si, offset ctrlString
	mov	si, ds:[si]
	LocalCopyString
SBCS <	mov	{byte}es:[di-1], 20h		; replace NULL with space	>
DBCS <	mov	{wchar}es:[di-2], 20h					>

noCtrl:
	test	cx, mask KS_SHIFT
	jz	noShift
	mov	si, offset shiftString
	mov	si, ds:[si]
	LocalCopyString
SBCS <	mov	{byte}es:[di-1], 20h		; replace NULL with space	>
DBCS <	mov	{wchar}es:[di-2], 20h					>

noShift:
SBCS <	mov	al, cl				; al <- shortcut char	>
DBCS <	mov	ax, cx							>
DBCS <	andnf	ax, 0x0fff			; top nibble used for flags	>
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, ')'
stuffIt:
	LocalPutChar	esdi, ax
SBCS <	mov	{byte}es:[di], 0		; store the NULL	>
DBCS <	mov	{wchar}es:[di], 0		; store the NULL	>

	pop	si				; es:si <- first char in string
	mov	cx, di
	sub	cx, si				; cx <- string size
DBCS <	shr	cx, 1				; cx <- string length	>
	inc	cx				; add 1 for the NULL

	call	MemUnlock

	.leave
	ret


noShortcut:
	LocalLoadChar	ax, ' '
	jmp	stuffIt

ShortcutToAscii		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[ok?]		CheckIfEditableShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the keyboard shortcut for this object is 
		editable (contains and ascii character).

CALLED BY:	INTERNAL (DocumentEnableKbdShortcut)
PASS:		ax	- KeyboardShortcut
RETURN:		carry set if not editable
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	In DBCS,
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfEditableShortcut		proc	far
	push	ax
if DBCS_PCGEOS
	andnf	ah, 0x0f		; if this nibble is 'e', it is
	cmp	ah, 0x0e		; unprintable -- see definition
CheckHack < CS_CONTROL_HB eq 0xee >
	clc
	jnz	done			; of KeyboardShortcut for DBCS
	stc
else
	andnf	ax, mask KS_CHAR_SET		; ax <- character set
	tst	ax				; is it in printable Chars?
CheckHack < CS_BSW eq 0 >
	clc
	jz	done
	stc
endif
done:
	pop	ax
	ret
CheckIfEditableShortcut		endp

;============================================================================
;	EC code
;============================================================================

if	ERROR_CHECK

COMMENT @----------------------------------------------------------------------

FUNCTION:	AssertIsResEditDocument

DESCRIPTION:	Assert the *ds:si is a ResEditDocumentClass object

CALLED BY:	INTERNAL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/19/92	Initial version

------------------------------------------------------------------------------@

AssertIsResEditDocument		proc	far	uses di, es
	.enter
	pushf

	GetResourceSegmentNS	ResEditDocumentClass, es
	mov	di, offset ResEditDocumentClass
	call	ObjIsObjectInClass
	ERROR_NC	OBJECT_NOT_A_RESEDIT_DOCUMENT

	popf
	.leave
	ret
AssertIsResEditDocument		endp

endif

DocumentUtilitiesCode	ends
