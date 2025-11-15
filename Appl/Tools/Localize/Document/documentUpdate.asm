COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit
FILE:		documentUpdate.asm

AUTHOR:		Cassie Hartzog, Nov 19, 1992

ROUTINES:
	Name			Description
	----			-----------
	DocumentCommitUpdate	Reset translation file to not updated state
				(clear all chunk state flags and remove the
				"Deleted Chunks" resource.
	ClearState		Clear ChunkState flags in this element.
	DocumentUpdateTranslation	Creates the updated translation
				database from new localization file and geode,
				which is then merged with the existing
				translation file for this document.
	SetCommitTriggerState	Enables/Disables the CommitTrigger
				appropriately.
	MergeUpdateAndTrans	Enumerates all the elements in the new
				ResourceMap, merging the updated translation
				database into the existing one.
	MergeResource		For the passed updated resource, looks for a
				matching resource and matching elements in the
				existing translation database.
	FindUnmatchedElements	Enumerate an updated ResourceArray, looking for
				elements which were not matched by a chunk in
				the corresponding ResourceArray in the old
				translation database.
	FindUnmatchedElementsCallback	Enumerate this resource from the old
				translation file, trying to find a match for
				the passed ResourceArrayElement from the
				updated database.
	FindMatchingResource	Search by name for a matching resource in the
				translation file for this updated resource.
	FindMatchingElement	Look for an element in the passed translation
				database ResourceArray which matches (name and
				data) this element from the updated geode.
	VerifyElementsMatch	Check if two elements, one from the translation
				file and from the updated geode, contain the
				same chunk.
	CompareData		Compare the origItem from the old and new
				elements to check for matches.
	FindElementsInResource	Enumerate an updated ResourceArray's elements,
				looking for matches in the passed translation
				file's ResourceArray.
	FindElementsInResourceCallback	Look for a match for this element from
				the updated ResourceArray in the translation
				file's ResourceArray.
	DeleteGeodeGroups	Free all DBGroups used by this ResourceMap.
	FixChunkState		Any unmarked elements in this ResourceArray
				from the new ResourceMap are chunks that have
				been added to the geode since the translation
				file was created or last updated. Set their
				ChunkState to CS_ADDED. Clear the ChunkState of
				CS_UNCHANGED chunks so that the filtering code
				works properly. (Unchanged chunks are shown by
				default.)
	FinishUpdate		Mark all unmarked chunks as "new" (if in the
				new ResourceMap) or "delete" (if in the old
				ResourceMap). Copy the "deleted" chunks to a
				new resource in the updated database, called
				"Deleted_Chunks".
	FinishUpdateCallback	Copy unmarked elements from old DB to new
				"Deleted_Chunks" resource in updated DB.
	ChunkCountCallback	Count the number of new, changed chunks in this
				resource.
	MoveDeletedChunks	Move unmarked chunks to Deleted_Chunks resource
				in update.
	MoveDeletedChunksCallback	No match was found for this chunk in
				the updated database, so move it to the new
				resource in the update created just for this
				purpose.
	DisplayChunkStateCounts	Report the results of the update to user.
	BatchDisplayChunkStateCounts	Report the results of the change to the
				user while in batch mode.
	SetUpdateState		Sets the update flag in the document and TMH.
	MyCopyDBItem		Copy a DBItem, fixing up es or ds.

REVISION HISTORY:
	Name	 Date		Description
	----	 ----		-----------
        cassie	 11/19/92	Initial revision
	canavese 10/9/95	Localization file now found automatically,
				batch functionality added.

DESCRIPTION:

	Code for updating translation files with new localization information.

	The strategy here is to assume that all updates will be taking place
	on geodes that were parsed using localiation VM files, so that the
	resources and chunks have names (not just the generic Resource7 and
	Chunk5 type of names).

	When the user starts the Update, the geode for that localization
	file will be opened and parsed into a ResourceMap/ResourceArray
	structure that is created in the translation file parallel to the
	original Map.  The new map will replace the old when when the update
	is completed.

	For every element in the new (updated) ResourceMapArray, look for a
	element (resource) of the same name in the original map.

	    If not found, mark the resource as a "new".

	    For every element (chunk) in the updated resource's
	    ResourceArray, look for a chunk of the same name
	    in the original ResourceArray.

		If found, compare data in the new and old chunks.
		   If it is different, mark the chunk as "changed"
		   in both new and old ResourceArrays.  Copy the
		   translation item from the old to the new element.

		   If it is the same, mark it as unchanged in both.

		If not found, do a search through every ResourceArray in
		the old map for a chunk containing the same data.

		    If found, mark it as a match, copying the
		    translation item from the original element to the
		    new element.

		    If not found, mark it as a new element.

	After the matching process is completed, any unmarked
	chunks in the old map are assumed not present in the updated
	map, and are marked for deletion.  Any unmarked chunks in the
	new map are assumed to be new chunks and are marked as such.
	The chunks marked for deletion are moved to a newly created
	resource in the updated map, called "Deleted Chunks".  Any
	empty resources are deleted.

	At this point, the new map contains all information from both
	the old and the new versions of the geode, so the old ResourceMap
	and its ResourceArrays are deleted and the new ResourceMap is set
	as the MapItem for the translation file.

	$Id: documentUpdate.asm,v 1.1 97/04/04 17:14:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DocumentUpdateCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentCommitUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset translation file to not updated state
		(clear all chunk state flags and remove the "Deleted
		Chunks" resource.

CALLED BY:	DocumentUpdateTranslation
PASS:		*ds:si	- document
		ds:di	- document

RETURN:		nothing
DESTROYED:	ax,bx,dx,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentCommitUpdate		method  ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_COMMIT_UPDATE
	uses cx,si,bp
	.enter

	push	ds:[LMBH_handle], si

	; disable the CommitTrigger, as document is about to become committed
	;
	clr	al				; disable the trigger
	call	SetCommitTriggerState

	; (should first ask if want to overwrite current translation file
	; before committing it)

	call	MarkBusyAndHoldUpInput

	; save all VMBlocks to file
	;
	call	GetFileHandle
	call	VMSave

	;
	; clear all the chunkState bits from the ResourceArrayElements
	;
	sub	sp, size EnumAllChunksStruct
	mov	bp, sp
	mov	ss:[bp].EACS_size, 0		; no data passed to callback
	mov	ss:[bp].EACS_callback.segment, cs
	mov	ss:[bp].EACS_callback.offset, offset ClearState
	call	EnumAllChunks
	add	sp, size EnumAllChunksStruct

	;
	; delete the "Deleted Chunks" resource
	;
	call	GetFileHandle
	call	DBLockMap_DS			; *ds:si <- ResourceMap
	segmov	es, cs
	mov	di, offset DeletedChunksStr	;es:di <- name
	clr	cx				;name is null-terminated
	clr	dx				;don't return data
	call	NameArrayFind			;ax <- element number
	jnc	notFound

	call	ChunkArrayElementToPtr		;ds:di <- DeletedChunks ResEle.
	call	ChunkArrayDelete
	call	DBDirty_DS
	call	DBUnlock_DS

	; Decrement the count of resources in the translation file.
	;
	pop	bx, si
	call	MemDerefDS
	DerefDoc
	dec	ds:[di].REDI_mapResources

	;
	; Reinitialize the ResourceList with the possibly changed
	; number of resources.
	;
	push	si
	mov	cx, ds:[di].REDI_mapResources
	call	GetDisplayHandle			;^hbx <- display
	mov	si, offset ResourceList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call 	ObjMessage

	clr	cx
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call 	ObjMessage
	pop	si

	;
	; The state of some of the chunks may have changed.  If some
	; of the chunk state filters are on, the display may need to change
	; change to reflect the change in the chunks' state.
	;
	; The easiest way to pick up the changes is to change to the
	; current resource, so all chunks are rechecked against the current
	; filters and it is redrawn.  If the current resource is the
	; "Deleted Chunks" resource, must go to a different resource.
	; However, since resources may be added or deleted, the current
	; resource's number may change after the update.  So to simplify
	; things, I will always change to resource 0 after the update.
	;
	clr	cx, dx
	call	DocumentChangeResourceAndChunk

done:
	;
	; Clear the NOT_COMMITTED flag
	;
	DerefDoc
	mov	al, ds:[di].REDI_state
	andnf	al, not (mask DS_UPDATE_NOT_COMMITTED)
	call	SetUpdateState

	call	MarkNotBusyAndResumeInput

	.leave
	ret

notFound:
	call	DBUnlock_DS
	pop	bx, si
	call	MemDerefDS
	jmp	done

DocumentCommitUpdate		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear ChunkState flags in this element.

CALLED BY:	ClearState (via EnumAllChunks)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearState	proc	far

	call	DBDirty_DS
	clr	ds:[di].RAE_data.RAD_chunkState
	clc
	ret
ClearState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentUpdateTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the updated translation database from new
		localization file and geode, which is then merged with the
		existing translation file for this document.

CALLED BY:	MSG_RESEDIT_DOCUMENT_UPDATE_TRANSLATION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		on error,
			carry set

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:

	Get the name of the file to use for updating.
	(For now, only allow updating from localization files, not geodes)

	Build up parallel DB structure with new info from the updated
	geode, which is refered to as the destination in the TranslationFileFrame
	structure, (this is necessary for ReadLocalizationFile).

	Look for matching elements in the existing translation database,
	will be refered to as the the source Group, Item, Array in the
	TranslationFileFrame structure.

	Significant calls:

		DocumentUpdateTranslation
		\_AllocResourceHandleTable
		\_AllocMapItem
		\_REDOpenLocalizationFile
		\_DocumentCommitUpdate
		\_REDDocumentReadSourceGeode
		\_ReadLocalizationFile
		\_MergeUpdateAndTrans
		  \_ChunkArrayEnum: MergeResource

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentUpdateTranslation		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_UPDATE_TRANSLATION

	; Get the document state.

		mov	cl, ds:[di].REDI_state		; cl <- document state

	; Put up an hourglass and hold input.

		call	MarkBusyAndHoldUpInput

	; Allocate a DocumentHandlesStruct for use in parsing the geode

		call	AllocResourceHandleTable	; es <- DHS segment

	; Allocate a new map item in the translation DB file

		call	GetFileHandle
		call	AllocMapItem		;ax:di <- GIPtr of map block

	; Set up TranslationFileFrame with the destination DBGroup/Item
	; numbers for ReadLocalizationFile.

		sub	sp, size TranslationFileFrame
		mov	bp, sp
EC<		mov	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG >
		mov	ss:[bp].TFF_documentState, cl
		mov	ss:[bp].TFF_handles, es	; DocumentHandlesStruct segment
		mov	ss:[bp].TFF_transFile, bx
		mov	ss:[bp].TFF_destGroup, ax
		mov	ss:[bp].TFF_destItem, di
		clr	ss:[bp].TFF_locFile
		push	ax, di			; save for call to FinishUpdate

	; Open localization file.

		mov	ax, MSG_RESEDIT_DOCUMENT_OPEN_LOCALIZATION_FILE
		call	ObjCallInstanceNoLock
		LONG jc	errorOpen
		mov	ss:[bp].TFF_locFile, ax

	; Commit any previous update -
	; clear ChunkState, delete "Deleted Chunks" resource.

		call	DocumentCommitUpdate

	; Change to source geode directory.

		call	FilePushDir
		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_SOURCE_PATH
		call	ObjCallInstanceNoLock

	; Read the chunk data into the ResourceArrays.

		mov	ax, MSG_RESEDIT_DOCUMENT_READ_SOURCE_GEODE
		call	ObjCallInstanceNoLock	; cx <- # editable resources
		call	FilePopDir
		jc	error

	; Error if geode has no resources.

		mov	ax, EV_NO_RESOURCES
		tst	cx
		jz	error

	; Copy the localization file info into the ResourceArrays.

		call	ReadLocalizationFile
		jc	error

	; Merge the updated info with the translation file info

		call	MergeUpdateAndTrans
		pop	ax, di			;ax:di <- new map GIPtr
		call	FinishUpdate		;cx <- # resources in map

		push	ax, bx, dx		;save chunk state counts

	; Set the document state to "updated but not commited"

		DerefDoc
		mov	al, ds:[di].REDI_state
		ornf	al, mask DS_UPDATE_NOT_COMMITTED
		call	SetUpdateState

	; Update the copyright interaction
		push	cx
		call	SetCopyrightInteraction
		pop	cx

	; Re-initialize the ResourceList w/new number of resources.

		mov	ds:[di].REDI_mapResources, cx	; save new # of resources
		push	si, di
		call	GetDisplayHandle			;^hbx <- display
		mov	si, offset ResourceList
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		clr	di
		call 	ObjMessage
		pop	si, di

	; Go to resource 0, chunk 0, the translation view.
	; In order for this to work, REDI_curResource cannot equal 0.
	; If it does, the call to DocumentChangeResource will be skipped,
	; and the new resource information will not get set in the document.

	; Force the change of resource by setting REDI_curResource to
	; something other than 0.

		mov	ds:[di].REDI_curResource, 1
		clr	cx
		clr	dx
		mov	al, ST_TRANSLATION
		call	DocumentGoToResourceChunkTarget

		mov	al, 1				; enable the commit trigger
		call	SetCommitTriggerState

		call	MarkNotBusyAndResumeInput

		pop	ax, bx, dx			;save chunk state counts
		call	IsBatchMode
		jnc	putUpDialog
		call	BatchDisplayChunkStateCounts
		jmp	restoreStackDone
putUpDialog:
		call	DisplayChunkStateCounts
restoreStackDone:
		pushf
		add	sp, size TranslationFileFrame
		popf
done::								; (For verbose.tcl)
		.leave
		ret

errorOpen:

	; If we are running a batch process, report the open error in the
	; status dialog.

		push	ax
		mov	ax, offset ResEditBatchOpenLocalizationError
		call	BatchReportTab
		call	BatchReportError
		pop	ax

error:
		call	MarkNotBusyAndResumeInput
	; Close all files and free all blocks.

		mov	cx, ax			; ErrorValue.
		call	CloseFilesAndFreeBlocks

	; Was document committed (and a backup copy made)?
	; recover the pre-committed version if so and restore the
	; DS_UPDATE_NOT_COMMITTED flag.

		DerefDoc
		test	ds:[di].REDI_state, mask DS_UPDATE_NOT_COMMITTED
		pop	ax, di					;ax:di <- new map GIPtr
		jnz	noRevert
		push	cx
		mov	bx, ss:[bp].TFF_transFile
		call	VMRevert
		pop	cx

	; Reset the UPDATE_NOT_COMMITTED flag to its previous state.

		mov	al, ss:[bp].TFF_documentState
		andnf	al, mask DS_UPDATE_NOT_COMMITTED	; clear other flags
		DerefDoc
		ornf	ds:[di].REDI_state, al
		call	SetCommitTriggerState

noRevert:

	; If ErrorValue is EV_NO_ERROR, don't put up an error dialog.

		cmp	cx, EV_NO_ERROR
		je	restoreStackDone
		cmp	cx, EV_NUM_RESOURCES
		jne	doIt
		mov	cx, EV_NUM_RESOURCES_UPDATE
doIt:
	; Report the error in a dialog.

		mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
		call	ObjCallInstanceNoLock

		call	MarkNotBusyAndResumeInput
		stc
		jmp	restoreStackDone

DocumentUpdateTranslation		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCommitTriggerState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/Disables the CommitTrigger appropriately.

CALLED BY:	INTERNAL
PASS:		al - non-zero to enable trigger
		   - zero to disable trigger
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCommitTriggerState		proc	near
	uses	bx,cx,dx,si,di,bp
	.enter

	tst	al
	jz	disable
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	setState
disable:
	mov	ax, MSG_GEN_SET_NOT_ENABLED

setState:
	GetResourceHandleNS	CommitTrigger, bx
	mov	si, offset CommitTrigger
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call 	ObjMessage

;	mov	dl, VUM_NOW
;	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
;	mov	di, mask MF_FIXUP_DS
;	call 	ObjMessage

	.leave
	ret
SetCommitTriggerState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeUpdateAndTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerates all the elements in the new ResourceMap, merging
		the updated translation database into the existing one.

CALLED BY:	DocumentUpdateTranslation

PASS:		*ds:si 	- document
		ss:bp	- TranslationFileFrame

RETURN:		carry set if error

DESTROYED:	ax,cx,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeUpdateAndTrans	proc	near
EC <		call	AssertIsResEditDocument			>
		push	ds:[LMBH_handle], si

	; Lock the new (updated) ResourceMap

		call	LockTransFileMap_DS
		call	DBDirty_DS

	; Enumerate all of its elements

		mov	bx, cs
		mov	di, offset MergeResource
		call	ChunkArrayEnum

	; Lock the original ResourceMap

		segmov	es, ds
		mov	di, es:[si]		;es:di <- new map block
		mov	bx, ss:[bp].TFF_transFile
		call	DBLockMap_DS
		mov	si, ds:[si]		;ds:si <- old map block

	; Copy destination name from the old to the new map block

		movdw	axdx, sidi
		lea	si, ds:[si].TMH_destName
		lea	di, es:[di].TMH_destName
		mov	cx, (FILE_LONGNAME_BUFFER_SIZE)
		rep	movsb

	; Copy relative path from the old to the new map block

		movdw	sidi, axdx
		lea	si, ds:[si].TMH_relativePath
		lea	di, es:[di].TMH_relativePath
		mov	cx, size PathName
		rep	movsb

	; Copy user notes from the old to the new map block

		movdw	sidi, axdx
		lea	si, ds:[si].TMH_userNotes
		lea	di, es:[di].TMH_userNotes
SBCS <		mov	cx, GFH_USER_NOTES_BUFFER_SIZE			>
DBCS <		mov	cx, size FileUserNotes			>
		rep	movsb

	; Copy source name from the old to the new map block

		movdw	sidi, axdx
		lea	si, ds:[si].TMH_sourceName
		lea	di, es:[di].TMH_sourceName
		mov	cx, size FileLongName
		rep	movsb

	; Copy path length from old to new map block.

		movdw	sidi, axdx
		mov	cx, ds:[si].TMH_pathLength
		mov	es:[di].TMH_pathLength, cx

	; Copy DOS name from old to new map block.

		movdw	sidi, axdx
		lea	si, ds:[si].TMH_dosName
		lea	di, es:[di].TMH_dosName
		mov	cx, size DosDotFileName
		rep	movsb

	; Copy DB Item and Group handles for Copyright
		movdw	sidi, axdx
		lea	si, ds:[si].TMH_copyrightGroup
		lea	di, es:[di].TMH_copyrightGroup
		movsw
		movsw

	; Get number of resources.

		mov	di, dx
		mov	dx, es:[di].TMH_totalResources

	; Unlock both map blocks.

		call	DBUnlock_DS
		call	DBUnlock

		pop	bx,si
		call	MemDerefDS			;*ds:si <- document
		DerefDoc
		mov	ds:[di].REDI_totalResources, dx

		ret
MergeUpdateAndTrans	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For the passed updated resource, looks for a matching
		resource and matching elements in the existing translation
		database.

CALLED BY:	MergeUpdateAndTrans (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceMap of updated geode
		ds:di	- ResourceMapElement
		ax	- element size
		ss:bp	- TranslationFileFrame

RETURN:		carry set if error

DESTROYED:	es

PSEUDO CODE/STRATEGY:
	See if a resource of the same name exists in the translation file
	If so, look for matching chunks in that resource.
	If not, mark this as a new resource.

	For all unmatched chunks, now look through all resources
	for matching chunks. (same data.  name?)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MergeResource		proc	far
	.enter

	mov	cx, ax				;cx <- ResMapElement size
	mov	bx, ds:[LMBH_handle]
	push	bx

	segmov	es, ds				;es:di <- element to match
	movdw	ss:[bp].TFF_destArray, esdi	;save element to match

	mov	bx, ss:[bp].TFF_transFile
	call	DBLockMap_DS			;*ds:si <- original ResourceMap
	mov	bx, ds:[LMBH_handle]
	movdw	ss:[bp].TFF_sourceArray, bxsi
	push	bx				;save trans ResMap handle

	; look for a resource of the same name, and if found deref element
	;
	call	FindMatchingResource		;ax <- matching trans element#
	jnc	newResource			;no matching resource name

	push	di
	call	ChunkArrayElementToPtr  	;ds:di <- matching ResMapElmt
	mov	ax, ds:[di].RME_data.RMD_group
	mov	ss:[bp].TFF_sourceGroup, ax
	mov	ax, ds:[di].RME_data.RMD_item
	mov	ss:[bp].TFF_sourceItem, ax
	pop	di				;es:di <- element to match
	stc					;restore carry just in case...

lockResArray:
	;
	; now lock the ResourceArray for the ResourceMapElement in the
	; updated map, since the ResMapElement itself doesn't need to be
	; passed to MergeResourceCallback, just the group# and ResArray
	;
	pushf
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, es:[di].RME_data.RMD_group
	mov	ss:[bp].TFF_destGroup, ax
	mov	di, es:[di].RME_data.RMD_item
	call	DBLock_DS			;*ds:si <- updated ResArray
	popf
	jnc	callCallback			;no matching resource, so
						; go through every resource

	; save the OD for the translation file's ResourceMap
	; since TFF_sourceArray is used by MergeElementsIntoResource
	;
	pushdw	ss:[bp].TFF_sourceArray

	;
	; first look for matching chunks in the matching resource from
	; the translation file
	; ss:[bp].TFF_destGroup - updated resource's group
	; ss:[bp].TFF_sourceGroup - matching ResourceMapElement's group#
	; ss:[bp].TFF_sourceItem - matching ResourceMapElement's ResArray item#
	;
	call	FindElementsInResource
	popdw	ss:[bp].TFF_sourceArray		;restore trans ResMap

callCallback:
	;
	; Now *ds:si = ResourceArray for the updated geode.
	; For each unmatched element in this array, find a
	; matching element in the translation database.
	;
	mov	bx, cs
	mov	di, offset FindUnmatchedElements
	call	ChunkArrayEnum

	call	DBUnlock_DS				;unlock new ResArray
	pop	bx
	call	MemDerefDS				;deref ResourceMap
	call	DBUnlock_DS				;unlock trans ResMap
	pop	bx
	call	MemDerefDS				;deref ResourceMap
	.leave
	ret

newResource:
	; mark the updated ResourceMapElement as new, since no
	; match was found in the translation ResourceMap
	;
	movdw	esdi, ss:[bp].TFF_destArray
	ornf	es:[di].RME_data.RMD_resourceType, mask RT_NEW_RESOURCE
	jmp	lockResArray


MergeResource		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindUnmatchedElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate an updated ResourceArray, looking for elements
		which were not matched by a chunk in the corresponding
		ResourceArray in the old translation database.

CALLED BY: 	MergeResource (via ChunkArrayEnum)

PASS:		*ds:si	- updated ResourceArray
		ds:di	- updated ResourceArrayElement
		ax	- element size
		ss:bp	- TranslationFileFrame:
			TFF_sourceArray - OD of translation file ResourceMap

RETURN:		nothing

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindUnmatchedElements	proc	far
	.enter

	call	ChunkArrayPtrToElement		; ax <- this element number
	mov	bx, ds:[LMBH_handle]
	push	ax, bx, si

	tst	ds:[di].RAE_data.RAD_chunkState ; has the chunk been matched?
	jnz	done				; yes, we're done with it

	movdw	ss:[bp].TFF_destArray, bxsi
	mov	cx, ax				;cx <- updated element number

	movdw	bxsi, ss:[bp].TFF_sourceArray
	call	MemDerefDS			;*ds:si <- trans ResMapArray
	push	bx,si				;save old ResMap optr
	mov	bx, cs
	mov	di, offset FindUnmatchedElementsCallback
	call	ChunkArrayEnum
	popdw	ss:[bp].TFF_sourceArray		;restore old ResMap optr

done:
	pop	ax, bx, si
	call	MemDerefDS			;*ds:si <- updated ResArray
	call	FixChunkState
	clc

	.leave
	ret
FindUnmatchedElements	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindUnmatchedElementsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate this resource from the old translation file,
		trying to find a match for the passed ResourceArrayElement
		from the updated database.

CALLED BY:	FindUnmatchedElements (via ChunkArrayEnum)

PASS:		*ds:si	- translation file's ResourceMapArray
		ds:di	- ResourceMapElement
		ax	- element size
		ss:bp	- TranslationFileFrame
		cx	- updated ResourceArrayElement number to match

RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindUnmatchedElementsCallback	proc	far
	uses	cx
	.enter

	push	ds:[LMBH_handle]

	; lock the ResourceArray from the translation database
	;
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, ds:[di].RME_data.RMD_group
	mov	ss:[bp].TFF_sourceGroup, ax
	mov	di, ds:[di].RME_data.RMD_item
	call	DBLock				;*es:di <- old ResourceArray

	mov	bx, es:[LMBH_handle]
	movdw	ss:[bp].TFF_sourceArray, bxdi

	; get the pointer to the updated element we are trying to match
	; and call the routine which goes through all elements in the
	; the old ResourceArray
	;
	push	cx
	movdw	bxsi, ss:[bp].TFF_destArray
	call	MemDerefDS
	mov	ax, cx
	call	ChunkArrayElementToPtr		;ds:di <- element to match
	mov	ax, cx				;ax <- element size
	call	FindElementsInResourceCallback
	pop	ax
	call	ChunkArrayElementToPtr		;ds:di <- element to match
	tst	ds:[di].RAE_data.RAD_chunkState ;was element marked?
	stc					;assume a match was found
	jnz	done				;yes, it has a match!
	clc					;nope, keep looking
done:
	pop	bx
	call	MemDerefDS
	call	DBUnlock
	.leave
	ret
FindUnmatchedElementsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMatchingResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search by name for a matching resource in the translation
		file for this updated resource.

CALLED BY:	(INTERNAL) MergeResource

PASS:		*ds:si	- ResourceMapArray from translation file
		cx	- updated element size
		ss:bp	- TranslationFileFrame

RETURN:		carry set if found
		ax	- element number of matching resource

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindMatchingResource		proc	near
	uses	si,di
	.enter

	; Look for a resource of the same name.
	;
	movdw	esdi, ss:[bp].TFF_destArray	;es:di <- element to match
	add	di, offset RME_data + offset RMD_name	;es:di <- name
	sub	cx, size ResourceMapElement	;cx <- size of name
DBCS <	shr	cx, 1				;cx <- length of name	>
	clr	dx				;don't return data
	call	NameArrayFind			;ax <- trans element number

	.leave
	ret
FindMatchingResource		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMatchingElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for an element in the passed translation database
		ResourceArray which matches (name and data) this element
		from the updated geode.

CALLED BY:	FindElementsInResourceCallback

PASS:		es:di	- new ResourceArrayElement to find a match for
		cx	- element size
		*ds:si	- translation file ResourceArray
		ss:bp	- TranslationFileFrame

RETURN:		carry set if found or name matches
		ax	- MatchType
		cx	- old ResourceArrayElement number which matches

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/20/92	Initial version
	jmagasin 6/19/95	Made "found:" section jump to tryAll....

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindMatchingElement		proc	near
	uses bx,dx,si,di,ds
	.enter

	mov	bx, di

	sub	sp, size ResourceArrayData
	mov	dx, ss
	mov	ax, sp				;dx:ax buffer for ResArrayData

	; see if there is a chunk of the same name
	;
	add	di, offset RAE_data + offset RAD_name	;es:di <- name to find
	sub	cx, size ResourceArrayElement
DBCS <	shr	cx, 1					;convert size to length	>
	call	NameArrayFind				;ax <- element number
	mov	cx, bx				;save new RAE offset
	jc	found

	; loop through all elements in the translation's ResourceArray,
	; looking for one that matches this, or comes close.
	;

	mov	di, cx				;es:di <- ResArrayElement
	call	TryAllTranslationChunks


done:
	mov	cx, ax				;cx <- element number
	lahf					;put flags into ah (MT is in al)
	add	sp, size ResourceArrayData
	sahf					;restore flags
	mov	ax, bx

	.leave
	ret

found:
	; Now es:di = parsed element data we are trying to find a match for,
	; and dx:ax = data from the translation file element with the
	; same name.  See if they really match. (Consider it a match unless
	; the chunk type has changed??)
	; jmagasin: If they don't match, we still need to check the other
	;   chunks in this resource of the translation file.
	; awu: if the names match, but data doesn't we still set the carry
        ;   so that the chunk gets treated as a changed chunk - not as
	;   deleted chunk 7/25/96

	mov	bx, ax				;bx <- matching element #
	mov	ax, sp
	sub	di, offset RAD_name		;es:di <- ResArrayData
	push	cx				;save offset of new RAE
	call	VerifyElementsMatch		;ax <- MatchType
	pop	cx				;recall offset of new RAE
	xchg	bx, ax				;ax <- match #, bx <- MatchType
	mov	dx, ax				; save match #
	test	bx, mask MT_MATCH
	jnz	dontTry
	call	TryAllTranslationChunks
	jc	dontTry				; it matches
        mov	bx, mask MT_DATA_MISMATCH	; name matches, but not data
	mov	ax, dx				; restore the match #
dontTry:
	stc
	jmp	done

FindMatchingElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryAllTranslationChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop through all elements in the translation's ResourceArray
		looking for on that matches this, or comes close.

CALLED BY:	FindMatchingElement
PASS:		es:di	- ResourceArrayElement
		*ds:si	- translation file ResourceArray
RETURN:		carry set if match
		ax	-  element number
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AW	7/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TryAllTranslationChunks	proc	near
	uses	dx,bx,cx,di
	.enter
	add	di, offset RAE_data		;es:di <- updated ResArrayData
	clr	ax
	call	ChunkArrayGetCount		;cx <- #elements in old ResArray
	mov	dx, ds				;dx:ax <- trans ResArrayData

findLoop:
	push	ax, cx				;save element number, count
	push	di
	call	ChunkArrayElementToPtr		;ds:di <- old ResArrayElement
	mov	ax, di
	add	ax, offset RAE_data		;dx:ax <- old ResRarrayData
	pop	di				;es:di <- updated ResArrayData

	call	VerifyElementsMatch
	mov	bx, ax				;ax <- MatchType
	pop	ax, cx				;restore element number, count
	test	bx, mask MT_MATCH
	stc
	jnz	done				;same data, different name

	inc 	ax				;get next element number
	loop 	findLoop
	clc					;no match, clear the carry bit
done:
	.leave
	ret
TryAllTranslationChunks	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyElementsMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if two elements, one from the translation file and
		from the updated geode, contain the same chunk.

CALLED BY:	FindMatchingElement

PASS:		dx:ax	- old ResourceArrayData
		es:di	- updated ResourceArrayData
		ss:bp	- TranslationFileFrame

RETURN:		ax 	- MatchType
		note:  Carry flag has no significance b/c CompareData
		       always return a set cf. -jmagasin

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:
    Elements match only if they have the same ChunkType and the data
    is exactly the same.

    The chunk is considered to have changed if:
    	- ChunkType flags are different
        - sizes are different
        - data in origItem is different

    Everything else being equal, the elements match, even if their
    handles/numbers are different.  (the chunk may have moved without
    changing at all)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyElementsMatch	proc	near
	uses	bx,si,di,ds,es
	.enter

	; if the old element has been marked changed/unchanged,
	; it has already been matched up with an updated chunk.
	;
	movdw	dssi, dxax
	mov	ax, mask MT_ALREADY_MATCHED
	tst	ds:[si].RAD_chunkState
	clc
	jnz	done

	;
	; check the chunk type
	;
	mov	cl, ds:[si].RAD_chunkType
	cmp	cl, es:[di].RAD_chunkType
	mov	ax, mask MT_WRONG_TYPE
	clc
	LONG	jne	done

	; see if they have different handles, which really only means
	; that the chunk has moved. (don't really need this, but it may
	; come in handy at some future time)
	;
	clr	ax
	mov	cx, ds:[si].RAD_handle
	cmp	cx, es:[di].RAD_handle
	je	handlesOK
	mov	ax, mask MT_DIFFERENT_HANDLES

handlesOK:
	; get the item numbers for the chunks containing the original data
	;
	mov	si, ds:[si].RAD_origItem
EC <	tst	si						>
EC <	ERROR_Z INVALID_ITEM					>
	mov	di, es:[di].RAD_origItem
EC <	tst	di						>
EC <	ERROR_Z INVALID_ITEM					>

	push	ax				;save MatchType

	; lock the updated item
	;
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, ss:[bp].TFF_destGroup
	call	DBLock				;*es:di <- updated chunk

	; lock the translation database's item
	;
	push	di
	mov	ax, ss:[bp].TFF_sourceGroup
	mov	di, si
	call	DBLock_DS			;*ds:si <- old chunk
	pop	di

	pop	ax
	call	CompareData			;ax <- MatchType

	call	DBUnlock
	call	DBUnlock_DS

done:
	.leave
	ret

VerifyElementsMatch		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the origItem from the old and new elements to check
		for matches.

CALLED BY:	VerifyElementsMatch

PASS:		*es:di	- updated chunk data
		*ds:si	- old chunk data
		ax	- MatchType so far

RETURN:		carry set
		al	- MatchType
			al = MT_DIFFERENT_HANDLE
		      	al = MT_MATCH
			al = MT_SIZE_MISMATCH
			al = MT_DATA_MISMATCH

DESTROYED:	si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/29/92	Initial version
	jmagasin 6/19/95	fixed so MT_SIZE_MISMATCH is returned
				 if sizes are different

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareData		proc	near
	uses	bx, cx, dx
	.enter

	clr	bx
	mov	si, ds:[si]
	mov	di, es:[di]

	; compare their sizes, get the shorter of the two lengths
	;
	ChunkSizePtr		ds, si, cx
	ChunkSizePtr		es, di, dx
	cmp	cx, dx
	je	haveSize
	ornf	al, mask MT_SIZE_MISMATCH
	cmp	cx, dx
	jb	haveSize			;cx is alredy < dx
	mov	cx, dx				;now cx is < dx

haveSize:
	push	ax				;save MatchType so far
	push	cx,si,di
compare:
	lodsb
	cmp	al, es:[di]
	je	bytesMatch
	inc	bx				;bx <- # of mismatches
bytesMatch:
	inc	di
	loop	compare
	pop	cx,si,di

	pop	ax
	tst	bx
	jz	match
	ornf	al, mask MT_DATA_MISMATCH
;	sub	cx, bx				;cx <- # of matches
;	clc
	stc

done:
	.leave
	ret
match:
	ornf	al, mask MT_MATCH
	stc
	jmp	done
CompareData		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindElementsInResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate an updated ResourceArray's elements, looking for
		matches in the passed translation file's ResourceArray.

CALLED BY:	MergeResource

PASS:		*ds:si	- updated ResourceArray to be merged
		ss:bp	- TranslationFileFrame:
			TFF_sourceGroup	- group# for translation file resource
			TFF_sourceItem	- item# for trans file  ResourceArray

RETURN:		nothing

DESTROYED:	es,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindElementsInResource		proc	near
	uses	ax,bx
	.enter

	; lock the translation file's ResourceArray
	;
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, ss:[bp].TFF_sourceGroup
	mov	di, ss:[bp].TFF_sourceItem
	call	DBLock					;*es:di <- old ResArray

	; save its OD in TranslationFileFrame
	;
	mov	bx, es:[LMBH_handle]
	movdw	ss:[bp].TFF_sourceArray, bxdi

	; now go through every element in the updated ResourceArray,
	; looking for matches in the translation file's ResourceArray
	;
	mov	bx, cs
	mov	di, offset FindElementsInResourceCallback
	call	ChunkArrayEnum

	; unlock the old ResourceArray
	;
	call	DBUnlock

	.leave
	ret

FindElementsInResource		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindElementsInResourceCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a match for this element from the updated
		ResourceArray in the translation file's ResourceArray.

CALLED BY:	FindElementsInResource (via ChunkArrayEnum),
		FindUnmatchedElementsCallback

PASS:		*ds:si	- updated ResourceArray
		ds:di	- updated ResourceArrayElement
		ax	- element size
		ss:bp	- TranslationFileFrame:
			TFF_sourceArray - OD of trans file's ResourceArray
			TFF_sourceGroup - group# of trans file's resource

RETURN:		ds, es updated
DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindElementsInResourceCallback		proc	far
	.enter

DBCS <	push	bp				;need an extra register	>
	push	es:[LMBH_handle]
	push	ds:[LMBH_handle], si

	; if this chunk has already been matched, don't look further
	;
	tst	ds:[di].RAE_data.RAD_chunkState
	LONG	jnz	done

	mov	cx, ax				;cx <- new ResArrayElmt size
	call	ChunkArrayPtrToElement		;ax <- this element's number
	mov	dx, ax

	; move translation's old ResourceArray to *ds:si, updated
	; ResourceArrayElement to es:di
	;
	segmov	es, ds 				;es:di <- new element
	movdw	bxsi, ss:[bp].TFF_sourceArray
	call	MemDerefDS			;*ds:si <- old ResArray
	call	FindMatchingElement		;cx <- matching element #,
						;  ax <- MatchType
	jnc	done				;no match was found in this
						;  old ResourceArray
	;
	;
	; get a pointer to the matching element in the old ResourceArray
	;
	push	ax, di
	mov	ax, cx
	call	ChunkArrayElementToPtr
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND				>
	mov	si, di				;ds:si <- matching element
	pop	ax, di

	;
	; mark both elements as dirty since the chunkState will change,
	; if nothing else
	;
	call	DBDirty_DS
	call	DBDirty

	;
	; if the element has not changed, mark it as such
	;
	mov	ah, mask CS_UNCHANGED
	test	al, mask MT_MATCH		; assume there is a match
	jnz	saveState
	mov	ah, mask CS_CHANGED
saveState:
	mov	ds:[si].RAE_data.RAD_chunkState, ah
	mov	es:[di].RAE_data.RAD_chunkState, ah

	;
	; copy the translation item from the old to the updated element
	; IMPORTANT NOTE: MyCopyDBItem may move the updated ResourceArray,
	; invalidating any stored pointers to it.
	;
	mov	di, ds:[si].RAE_data.RAD_transItem	;di <- source item
	tst	di
	jz	done

	push	ds:[si].RAE_data.RAD_kbdShortcut	;save kbd shortcut
	mov	al, ds:[si].RAE_data.RAD_mnemonicType
if DBCS_PCGEOS
	clr	ah
	push	ax
	mov	ax, ds:[si].RAE_data.RAD_mnemonicChar
	push	ax
else
	mov	ah, ds:[si].RAE_data.RAD_mnemonicChar
	push	ax					;save mnemonic info
endif
	mov	ax, ss:[bp].TFF_sourceGroup		;ax <- source group
	mov	bx, ss:[bp].TFF_transFile		;bx <- source file
	mov	cx, ss:[bp].TFF_destGroup		;cx <- dest group
	push	bp
	mov	bp, bx					;bp <- dest file
	call	MyCopyDBItem_ES				;di <- item created
	pop	bp
if DBCS_PCGEOS
	pop	bp			; bp <- mnemonicChar
	pop	cx			; cl <- mnemonicType
	pop	ax			; ax <- shortcut
else
	pop	ax, cx			; ax <- shortcut, cx <- mnemonic
endif

	; store the new translation item number in the updated element
	;
	xchg	ax, dx					;ax <- element #
	pop	bx, si
	call	MemDerefDS	;removeme: bx -> ds
	push	cx, di
	call	ChunkArrayElementToPtr
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND				>
	pop	ds:[di].RAE_data.RAD_transItem		;save new transItem
	pop	ax
	mov	ds:[di].RAE_data.RAD_mnemonicType, al
SBCS <	mov	ds:[di].RAE_data.RAD_mnemonicChar, ah			>
DBCS <	mov	ds:[di].RAE_data.RAD_mnemonicChar, bp			>
	mov	ds:[di].RAE_data.RAD_kbdShortcut, dx	;save old kbdShortcut
	jmp	exit

done:
	pop	bx, si
	call	MemDerefDS

exit:
	pop	bx
	call	MemDerefES
	clc					;clear so enum will continue

DBCS <	pop	bp							>
	.leave
	ret

FindElementsInResourceCallback 		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteGeodeGroups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free all DBGroups used by this ResourceMap.

CALLED BY:	(INT) FinishUpdate

PASS:		ax:di	- ResourceMap group and item numbers
		^hbx	- translation file handle
		cx	- ErrorValue

RETURN:		nothing

DESTROYED:	bx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteGeodeGroups	proc	near
	uses	ax,cx,di
	.enter

	push	ax
	call	DBLock_DS			;*ds:si <- ResourceMap
	call	ChunkArrayGetCount		; cx <- # resources
	tst	cx
	jz	done

	; free the ResourceArray group for each resource
	;
	clr	dx				;start at resource 0

deleteLoop:
	push	cx				;save count
	mov	ax, dx				;ax <- resource to work on
	call	ChunkArrayElementToPtr
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_NOT_FOUND			>
	pop	cx				;restore count
	mov	ax, ds:[di].RME_data.RMD_group
	call	DBGroupFree			;free the group and its items
	inc	dx				;dx <- next resource
	loop	deleteLoop

done:
	call	DBUnlock_DS
	pop	ax
	call	DBGroupFree

	.leave
	ret
DeleteGeodeGroups	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixChunkState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Any unmarked elements in this ResourceArray from the
		new ResourceMap are chunks that have been added to the
		geode since the translation file was created or last
		updated.  Set their ChunkState to CS_ADDED.  Clear the
		ChunkState of CS_UNCHANGED chunks so that the filtering
		code works properly.  (Unchanged chunks are shown by
		default.)

CALLED BY: 	(INTERNAL) FindElements

PASS:		*ds:si	- updated ResourceArray
		ax	- element number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixChunkState	proc 	near

	push	cx
	call	ChunkArrayElementToPtr
	tst	ds:[di].RAE_data.RAD_chunkState
	jz	markAdded
	test	ds:[di].RAE_data.RAD_chunkState, mask CS_UNCHANGED
	jz	done
	clr	ds:[di].RAE_data.RAD_chunkState
done:
	pop	cx
	clc
	ret

markAdded:
	mov	ds:[di].RAE_data.RAD_chunkState, mask CS_ADDED
	jmp	done
FixChunkState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark all unmarked chunks as "new" (if in the new ResourceMap)
		or "delete" (if in the old ResourceMap).  Copy the
		"deleted" chunks to a new resource in the updated database,
		called "Deleted_Chunks".

CALLED BY:	DocumentUpdateTranslation

PASS:		*ds:si	- document
		ax:di	- GIPtr for updated ResourceMap

RETURN:		cx	- number of elements in the ResourceMap
		bx	- number of deleted chunks
		ax	- number of changed chunks
		dx	- number of new chunks

DESTROYED:	bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString	Resource0Str, <'Resource0', 0>
LocalDefNLString	DeletedChunksStr, <'Deleted Chunks', 0>

FinishUpdate		proc	near
	.enter

		push	ds:[LMBH_handle], si

	; Lock the updated ResourceMap and enumerate it to
	; mark all unmarked elements with ChunkState = CS_ADDED

		push	ax, di
		mov	bx, ss:[bp].TFF_transFile
		call	DBLock_DS	; *ds:si <- updated ResourceMap

	; Add the new resource for the deleted chunks.  (AddNewResource
	; adds a resource with the name ResourceN, where N = ax)
	; Resource0 will not exist at this point, since it is always
	; dgroup it is always deleted when the trans file is created.

		clr	ax			; try adding "Resource0"
		call	AddNewResource		; ax <- token of new element
EC <		ERROR_C	RESEDIT_INTERNAL_LOGIC_ERROR			>

		call	ChunkArrayElementToPtr	; ds:di <- new ResourceMapElement
		mov	ax, ds:[di].RME_data.RMD_group
		mov	ss:[bp].TFF_destGroup, ax
		mov	di, ds:[di].RME_data.RMD_item
		mov	ss:[bp].TFF_destItem, di
		call	DBDirty_DS		; dirty the new ResourceMap
		call	DBUnlock_DS		; unlock it

	; Copy unmarked chunks in the translation database to
	; Resource0 in the udpated database.

		clr	ss:[bp].TFF_chunkNumber	; initialize the chunk number
		call	DBLockMap_DS		; *ds:si <- old ResourceMapArray
		mov	bx, cs
		mov	di, offset MoveDeletedChunks
		call	ChunkArrayEnum
		call	DBUnlock_DS

	; Delete the old translation file's database. (All items,
	; ResourceArrays and the ResourceMap)

		mov	bx, ss:[bp].TFF_transFile
		call	DBGetMap		; ax:di <- GIPtr of old ResourceMap
		call	DeleteGeodeGroups

	; Make the updated ResourceMap be the file's map block

		pop	ax, di
		call	DBSetMap

	; Now lock the new map and find the new resource for deleted
	; chunks, so we can get the number of chunks in it

	call	DBLock_DS			;*ds:si <- new ResourceMap
	segmov	es, cs
	mov	di, offset Resource0Str		;es:di <- name of Resource 0
	clr	cx, dx				;don't return data
	call	NameArrayFind			;ax <- element number
EC <	ERROR_NC RESEDIT_INTERNAL_LOGIC_ERROR			>
	mov	dx, ax				;save Resource0 element #
	call	ChunkArrayElementToPtr		;ds:di <- ResourceMapElement

	push	ds:[LMBH_handle], si
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item

	call	DBLock_DS			;*ds:si <- Resource0's array
	call	ChunkArrayGetCount		;cx <- #chunks in Resource0
	call	DBUnlock_DS
	pop	bx, si
	call	MemDerefDS			;*ds:si <- new ResourceMap

	; if there are no chunks, delete the group it uses
	; and delete the element from the name array
	;
	tst	cx
	jz	noDeletedItems

	; change the resource's name to "Deleted Chunks"
	;
	push	cx				; save # of deleted chunks
	segmov	es, cs
	mov	di, offset DeletedChunksStr	; es:di <- new name
	mov	ax, dx				; ax <-Resource0 element number
	clr	cx				; null-terminated name
	call	NameArrayChangeName
	pop	cx

noDeletedItems:
	push	cx				; save # of deleted chunks
	;
	; now delete any empty resources, count # of new and changed chunks
	;
	clr	cx, dx				; initialize counters
	mov	bx, cs
	mov	di, offset FinishUpdateCallback
	call	ChunkArrayEnum
	mov	ax, cx				; ax <- # changed chunks,
						; dx <- # new chunks
	call	ChunkArrayGetCount		; cx <- # non-empty resources
	call	DBDirty_DS			; dirty and unlock new map
	call	DBUnlock_DS
	pop	di				; di <- # of deleted chunks

	pop	bx, si
	call	MemDerefDS
	mov	bx, di				; bx <- # of deleted chunks

	.leave
	ret

FinishUpdate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishUpdateCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy unmarked elements from old DB to new "Deleted_Chunks"
		resource in updated DB.

CALLED BY:	FinishUpdate (via ChunkArrayEnum)
PASS:		*ds:si - ResourceMapArray
		ds:di - ResourceMapElement
		ss:bp - TFF
		cx - cumulative count of changed chunks
		dx - cumulative count of new chunks

RETURN:		cx, dx updated
DESTROYED:	ax,bx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishUpdateCallback		proc	far
	.enter

	call	ChunkArrayPtrToElement
	push	ax
	push	ds:[LMBH_handle], si
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBLock_DS			;*ds:si <- ResourceArray

	;
	; count the number of new and changed chunks
	;
	mov	bx, cs
	mov	di, offset ChunkCountCallback
	call	ChunkArrayEnum			; cx, dx updated

	;
	; get the total number of chunks in this resource
	;
	push	cx
	call	ChunkArrayGetCount		; cx <- #chunks in Resource
	mov	di, cx
	pop	cx

	call	DBUnlock_DS
	pop	bx, si
	call	MemDerefDS			;*ds:si <- ResourceMapArray
	pop	ax				; ax <- element # of resource

	tst	di				; are there chunks in resource?
	jnz	noDelete			; yes, don't delete it

	push	cx
	call	ChunkArrayElementToPtr		; ds:di <- ResourceMapElement
	pop	cx
	mov	ax, ds:[di].RME_data.RMD_group	; ax <- resource group
	mov	bx, ss:[bp].TFF_transFile
	call	DBGroupFree			; delete the resource's group
	call	ChunkArrayDelete		; delete the ResourceMapElement
	call	DBDirty_DS			; dirty the new map

noDelete:

	.leave
	ret

FinishUpdateCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkCountCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the number of new, changed chunks in this resource.

CALLED BY:	FinishUpdateCallback (via ChunkArrayEnum)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ss:bp 	- TFF
		cx - cumulative count of changed chunks
		dx - cumulative count of new chunks

RETURN:		cx, dx updated
DESTROYED:

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChunkCountCallback		proc	far
	.enter

	test	ds:[di].RAE_data.RAD_chunkState, mask CS_ADDED
	jz	notNew
	inc	dx
	jmp	done
notNew:
	test	ds:[di].RAE_data.RAD_chunkState, mask CS_CHANGED
	jz	done
	inc	cx
done:
	.leave
	ret
ChunkCountCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveDeletedChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move unmarked chunks to Deleted_Chunks resource in update.

CALLED BY:	FinishUpdate (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceMapArray from translation database file
		ds:di	- ResourceMapElement
		ss:bp	- TranslationFileFrame
			TFF_destGroup	- group # of resource to add chunks to
			TFF_destItem	- item# of ResArray to add chunks to

RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveDeletedChunks		proc	far
	.enter

	push	ds:[LMBH_handle]

	; lock the old ResourceArray from the translation database
	;
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, ds:[di].RME_data.RMD_group
	mov	ss:[bp].TFF_sourceGroup, ax
	mov	di, ds:[di].RME_data.RMD_item
	call	DBLock_DS

	; move all of the unmarked chunks from this resource to the
	; new Deleted_Chunks resource in the updated database
	;
	mov 	bx, cs
	mov	di, offset MoveDeletedChunksCallback
	call	ChunkArrayEnum
	call	DBUnlock_DS

	pop	bx
	call	MemDerefDS
	clc
	.leave
	ret
MoveDeletedChunks		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveDeletedChunksCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	No match was found for this chunk in the updated database,
		so move it to the new resource in the update created just
		for this purpose.

CALLED BY:	MoveDeletedChunks (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceArray from translation database
		ds:di	- ResourceArrayElement
		ax	- element size
		ss:bp	- TranslationFileFrame
			TFF_destGroup	- group # of resource to add chunks to
			TFF_destItem	- item # of ResArray to add chunks to
			TFF_sourceGroup	- group # of resource chunks come from

RETURN:		nothing

DESTROYED:	ax, bx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveDeletedChunksCallback	proc	far
	uses	cx,dx
	.enter

	; if this element has been marked (changed, unchanged)
	; it is present in the updated database.
	;
	push	ds:[LMBH_handle]
	tst	ds:[di].RAE_data.RAD_chunkState
	LONG	jnz	done

	mov	cx, ax				;cx <- element size
	mov	si, di				;ds:si <- source element

	;
	; copy element data (not name or element header) from old element
	; to a buffer on the stack, pointed to by TFF_destArray
	;
	sub	sp, size ResourceArrayData
	movdw	ss:[bp].TFF_destArray, sssp

	push	cx					;save element size
	mov	cx, size ResourceArrayData
	movdw	esdi, ss:[bp].TFF_destArray
	add	si, offset RAE_data			;ds:si <- source
	push	si, di
	rep	movsb
	pop	si, di

	;
	; mark the new element's ChunkState as deleted and
	; give it a new number so that no two chunks in this resource
	; will have the same number
	;
	mov	es:[di].RAD_chunkState, mask CS_DELETED
	mov	ax, ss:[bp].TFF_chunkNumber
	inc	ax
	mov	es:[di].RAD_number, ax
	mov	ss:[bp].TFF_chunkNumber, ax

	;
	; copy the original item, translation item and
	; instruction item into the new element's DBGroup
	;
	push	bp, di
	mov	di, ds:[si].RAD_origItem 		;source item
EC <	tst	di					>
EC <	ERROR_Z	INVALID_ITEM				>
	mov	ax, ss:[bp].TFF_sourceGroup
	mov	cx, ss:[bp].TFF_destGroup
	mov	bx, ss:[bp].TFF_transFile
	mov	bp, bx 					;file handles in bp, bx
	call	MyCopyDBItem_DS				;di = new item
	mov	ax, di
	pop	bp, di
	mov	es:[di].RAD_origItem, ax

	clr	ax
	push	bp, di
	mov	di, ds:[si].RAD_transItem	 	;translation item
	tst	di
	jz	copyInst

	mov	ax, ss:[bp].TFF_sourceGroup
	mov	bp, bx 					;file handles in bp, bx
	call	MyCopyDBItem_DS				;di = new item
	mov	ax, di

copyInst:
	pop	bp, di
	mov	es:[di].RAD_transItem, ax

	clr	ax
	push	bp, di
	mov	di, ds:[si].RAD_instItem		;instruction item
	tst	di
	jz	noInfo

	mov	ax, ss:[bp].TFF_sourceGroup
	mov	bp, bx 					;file handles in bp, bx
	call	MyCopyDBItem_DS				;di = new item
	mov	ax, di

noInfo:
	pop	bp, di
	mov	es:[di].RAD_instItem, ax

	pop	cx					;restore element size

	; lock the new ResourceArray for deleted chunks
	;
	push	di
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, ss:[bp].TFF_destGroup
	mov	di, ss:[bp].TFF_destItem
	call	DBLock				;*es:di <- ResourceArray
	mov	dx, ss
	pop	ax				;dx:ax <- ResArrayData to add

	; if the name is already in this ResourceArray - error
	;
	segxchg	es, ds				;*ds:si <- DeletedChunks
	xchg	di, si				;   ResourceArray
	lea	di, es:[di].RAD_name		;es:di <- chunk name
	sub	cx, size ResourceArrayElement	;cx <- length of the name
DBCS <	shr	cx, 1				;convert size to length	>
	clr	bx				;no flags
	call	NameArrayAdd

	add	sp, size ResourceArrayData

	call	DBDirty_DS
	call	DBUnlock_DS

done:
	pop	bx
	call	MemDerefDS
	clc

	.leave
	ret

MoveDeletedChunksCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayChunkStateCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report the results of the update to user.

CALLED BY:	DocumentUpdateTranslation
PASS:		*ds:si - document
		ax	- number of changed chunks
		bx	- number of deleted chunks
		dx	- number of new chunks
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayChunkStateCounts		proc	near
	uses	si
	.enter

	push	ax, bx

	GetResourceHandleNS	NewChunks, bx
	mov	si, offset NewChunks
	clr	bp, cx
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	dx
	mov	si, offset DeletedChunks
	clr	bp, cx
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	dx
	mov	si, offset ChangedChunks
	clr	bp, cx
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset UpdateReport
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	.leave
	ret
DisplayChunkStateCounts		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchDisplayChunkStateCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report the results of the change to the user while in batch
		mode.
CALLED BY:	DocumentUpdateTranslation
PASS:		ax	= number of changed chunks
		bx	= number of deleted chunks
		dx	= number of new chunks
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchDisplayChunkStateCounts	proc	near
		uses	ax,bx,cx,dx,bp
		.enter

	; Check if no chunks changed.

		tst	ax
		jnz	somethingChanged
		tst	bx
		jnz	somethingChanged
		tst	dx
		jnz	somethingChanged

	; No chunks changed.  Report this in status dialog.

		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	BatchStringsUI, dx
		mov	bp, offset ResEditBatchNoChange
		call	BatchReportTab
		call	BatchReportTab
		call	BatchReport
		call	BatchReportReturn
		jmp	done

somethingChanged:

	; Are there changed chunks?

		tst	ax
		jz	deletedChunks	; No changed chunks.

	; Indicate changed chunks in status dialog.

		push	dx
		call	BatchReportTab
		call	BatchReportTab
		call	BatchReportNumber
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	BatchStringsUI, dx
		mov	bp, offset ResEditBatchChunksChanged
		call	BatchReport
		call	BatchReportReturn
		pop	dx

deletedChunks:

	; Are there deleted chunks?

		mov	ax, bx
		tst	ax
		jz	addedChunks	; No deleted chunks.

	; Indicate deleted chunks in status dialog..

		push	dx
		call	BatchReportTab
		call	BatchReportTab
		call	BatchReportNumber
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	BatchStringsUI, dx
		mov	bp, offset ResEditBatchChunksDeleted
		call	BatchReport
		call	BatchReportReturn
		pop	dx

addedChunks:

	; Are there added chunks?

		mov	ax, dx
		tst	ax
		jz	done		; No added chunks.

	; Indicate added chunks in batch dialog..

		call	BatchReportTab
		call	BatchReportTab
		call	BatchReportNumber
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	BatchStringsUI, dx
		mov	bp, offset ResEditBatchChunksAdded
		call	BatchReport
		call	BatchReportReturn

done:
		.leave
		ret
BatchDisplayChunkStateCounts	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpdateState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the update flag in the document and TMH.

CALLED BY:	DocumentCommitUpdate, DocumentUpdateTranslation
PASS:		*ds:si	- document
		ds:di - document
		al - DocumentState to set
RETURN:		nothing
DESTROYED:	bx,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpdateState		proc	near

	mov	ds:[di].REDI_state, al
	call	GetFileHandle
	call	DBLockMap
	mov	di, es:[di]
	mov	es:[di].TMH_stateFlags, al
	call	DBDirty
	call	DBUnlock

	DerefDoc
	ret
SetUpdateState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyCopyDBItem_DS, MyCopyDBItem_ES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a DBItem, fixing up es or ds.

CALLED BY:
PASS: 		bx = Source file handle.
		ax = group of source DB item
		di = source item	(Offset to DBItemInfo in group block).
		ds, es = segments containing ResourceArrays

		bp = dest file handle
		cx = destination group

RETURN:		ax:di	- new item
DESTROYED:	nothing, ds or es fixed up if pointing to DBItem block.

	WARNING: MyCopyDBItem may move the destination group (in this
	case, containing a ResourceArray) invalidating any stored
	pointers to any items in it.

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyCopyDBItem_DS		proc	near

	push	bx
	push	ds:[LMBH_handle]
	call	DBCopyDBItem
	pop	bx
	call	MemDerefDS
	pop	bx

	ret
MyCopyDBItem_DS		endp

MyCopyDBItem_ES		proc	near

	push	bx
	push	es:[LMBH_handle]
	call	DBCopyDBItem
	pop	bx
	call	MemDerefES
	pop	bx

	ret
MyCopyDBItem_ES		endp


DocumentUpdateCode	ends
