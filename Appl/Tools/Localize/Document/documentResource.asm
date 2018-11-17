COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit	
FILE:		documentResource.asm

AUTHOR:		Cassie Hartzog, Nov 11, 1992

ROUTINES:
	Name			Description
	----			-----------
	ParseResources		The resource groups have all been added, so go 
				through them and look for stuff that can be 
				edited. 
	DeleteChunksAndResources	The geode has been parsed, now delete 
				any non-parseable (CT_NOT_EDITABLE) chunks, and 
				any NOT_EDITABLE or empty resources from the 
				name arrays. 
	ParseResourcesCallback	For each resource, call ChunkArrayEnum on all 
				the chunks in its block. 
	ParseObjectChunks	On the first parse pass, go through all chunks 
				in this resource, looking for objects, and mark 
				their monikers and text chunks for the second 
				pass parse. 
	ParseUnknownChunks	Save editable data from known chunks, and try 
				to parse unknown chunks. 
	DeleteUnknownChunks	This is the third pass of the parse attempt. Go 
				through the ResourceArray, deleting items which 
				are not editable or of unkown type. 
	ParseChunk		Try to parse a chunk about which nothing is 
				known. 
	MarkGCNListOfLists	Since GCNLists are so simple and generic, they 
				can pass the checks for GStrings and Bitmaps. 
				This routine determines whether the chunk 
				contains a GCNListOfLists and should be called 
				before checking for the other types. 
	MarkGCNList		A GCNListOfList may have been detected. See if 
				the passed chunk contains a valid GCNList. 
	MarkObjects		Determine whether an object is a subclass of 
				the passed class. 
	MarkGenClassStuff	An object sublcassed off GenClass has been 
				found. Get its mnemonic and keyboard shortcut, 
				if any. 
	MarkMonikers		Object is a GenClass, see if it has moniker(s). 
	MarkMonikerList		Check if this chunk contains a moniker list. 
	MarkOptrLists		This routine is an attempt to catch Tool lists 
				associated with ToolControl objects. Since many 
				of them are defined in non-ui libraries, I 
				can't detect them without loading those 
				libraries. 
	MarkText		Object is GenClass, see if it is a GenText and 
				has an lptr to some text. 
	StoreObject		Check if the object has a shortcut and its 
				element should therefore not be deleted. 
	GetOptrResourceNumber	Given an unrelocated optr, return the resource 
				number. 
	SetOptrType		An editable chunk, referenced by an optr, has 
				been found. Find its resource:chunk and set its 
				flags. 
	SetChunkType		An editable chunk has been found, set its 
				flags. 
	SetChunkTypeCallback	Find the element which has the passed chunk 
				handle and set its flags. 
	DerefElement		Dereference the current element. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/11/92	Initial revision


DESCRIPTION:
	Contains resource parsing code.

	$Id: documentResource.asm,v 1.1 97/04/04 17:14:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentParseCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The resource groups have all been added, so go through
		them and look for stuff that can be edited.

CALLED BY:	InitializeDocumentFile

PASS:		*ds:si	- document
		ss:bp	- TranslationFileFrame

RETURN:		ax	- number of resources containing chunks

DESTROYED:	cx,dx,di

PSEUDO CODE/STRATEGY:
	Call ChunkArrayEnum to enumerate the ResourceArrays
	for the first pass and second pass parse attempts.
	Then call a routine which deletes all elements for 
	non-editable or non-parseable chunks.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseResources		proc	far
		uses	bx,si,bp
		.enter

	; Set up the ParseFrame for what follows	

		push	ds:[LMBH_handle]
		sub	sp, size ParseFrame
		mov	di, sp
		mov	ss:[di].PF_signature, PARSE_FRAME_SIG
		mov	ax, ss:[bp].TFF_transFile
		mov	ss:[di].PF_transFile, ax
		mov	ax, ss:[bp].TFF_numResources
		mov	ss:[di].PF_numResources, ax
		mov	ss:[di].PF_TFFoffset, bp	;pass pointer to TFF
		clr	ss:[di].PF_flags

		call	LockTransFileMap_DS		;*ds:si <- TransMap
		mov	bp, di				; ss:bp <- ParseFrame

	; If this geode is the UI library, set a flag so that we
	; can properly find all GenClass objects in it.

		mov	di, ds:[si]
		test	ds:[di].TMH_flags, mask TMHF_UI_LIBRARY
		jz	notUI
		ornf	ss:[bp].PF_flags, mask PF_UI_LIBRARY
	
notUI:

	; Parse the geode

		ornf	ss:[bp].PF_flags, mask PF_FIRST_PASS
		mov	bx, cs
		mov	di, offset ParseResourcesCallback
		call	ChunkArrayEnum

	; Make a second pass to examine the unknown chunks, and store
	; data from the known chunks

		xor	ss:[bp].PF_flags, mask PF_FIRST_PASS or \
					mask PF_SECOND_PASS
		mov	bx, cs
		mov	di, offset ParseResourcesCallback
		call	ChunkArrayEnum

	; now make a third, and final, pass to delete the empty resources

		mov	bx, cs
		mov	di, offset DeleteChunksAndResources
		call	ChunkArrayEnum
		call	ChunkArrayGetCount
		mov	ax, cx				;# resources w/chunks
		call	DBUnlock_DS

		add	sp, size ParseFrame
		pop	bx
		call	MemDerefDS			;restore doc segment

		.leave
		ret
ParseResources		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteChunksAndResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The geode has been parsed, now delete any non-parseable 
		(CT_NOT_EDITABLE) chunks, and any NOT_EDITABLE or 
		empty resources from the name arrays.

CALLED BY:	ParseResourcesCallback (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement
		ss:bp	- ParseFrame

RETURN:		nothing

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteChunksAndResources		proc	far

	test	ds:[di].RME_data.RMD_resourceType, mask RT_NOT_EDITABLE
	jnz	delete

	; save the ResourceMap's handle, and this element`s number
	;
	call	ChunkArrayPtrToElement
	push	ds:[LMBH_handle], ax

	; lock this resource's ResourceArray
	;
	mov	bx, ss:[bp].PF_transFile
	mov	ax, ds:[di].RME_data.RMD_group
	mov	ss:[bp].PF_group, ax
	mov	di, ds:[di].RME_data.RMD_item	;ax:di <- ResourceArray GIPtr
	call	DBLock_DS			;*ds:si <- ResourceArray

	; save the ResourceArray's optr in the ParseFrame
	;
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].PF_resArray.handle, bx
	mov	ss:[bp].PF_resArray.chunk, si

	; delete the unparseable chunks from this resource
	;
	mov	bx, cs
	mov	di, offset DeleteUnknownChunks
	call	ChunkArrayEnum				
	call	ChunkArrayGetCount		;cx <- # of parseable chunks

	; unlock the ResourceArray
	;
	call	DBUnlock_DS
	pop	bx, ax

	; restore ResourceMap segment and element ptr
	;
	call	MemDerefDS
	mov	bx, cx
	call	ChunkArrayElementToPtr
	mov	ds:[di].RME_data.RMD_numChunks, bx

	; do any chunks remain?
	;
	tst	bx
	jnz	done
delete:
	mov	bx, ss:[bp].PF_transFile
	mov	ax, ds:[di].RME_data.RMD_group
	call	DBGroupFree
	call	ChunkArrayDelete
done:
	clc					; carry clear to continue
	ret
DeleteChunksAndResources		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseResourcesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For each resource, call ChunkArrayEnum on all the
		chunks in its block.

CALLED BY:	ParseResources (via ChunkArrayEnum)
		
PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement
		ss:bp	- ParseFrame
		
RETURN:		carry set if error
			ax - ErrorValue

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseResourcesCallback		proc	far
		uses	bx,cx,dx
		.enter

	; If resource is not editable, we're done.

		test	ds:[di].RME_data.RMD_resourceType, \
				mask RT_NOT_EDITABLE
		clc
		LONG	jnz	done

	; Save ResourceMap optr.

		mov	bx, ds:[LMBH_handle]
		push	bx, si

	; Save resource number.

		mov	ax, ds:[di].RME_data.RMD_number
		mov	ss:[bp].PF_resource, ax

	; Load this resource from the geode into a block

		push	bp
		mov	bp, ss:[bp].PF_TFFoffset
		call	LoadResource			;ax <- LRE
		pop	bp

	; Handle unexpected errors.  These resources should have been weeded
	; out when initializing the resource arrays

EC<		cmp	ax, LRE_NOT_LMEM				>
EC<		ERROR_E UNEXPECTED_LOAD_RESOURCE_ERROR			>
EC<		cmp	ax, LRE_NO_HANDLES				>
EC<		ERROR_E UNEXPECTED_LOAD_RESOURCE_ERROR			>
		mov	ax, EV_LOAD_RESOURCE
		jc	failure

	; Save resource handle.

		mov	ss:[bp].PF_object.handle, bx

	; Lock this resource's ResourceArray.

		mov	bx, ss:[bp].PF_transFile
		mov	ax, ds:[di].RME_data.RMD_group
		mov	ss:[bp].PF_group, ax
		mov	di, ds:[di].RME_data.RMD_item	;ax:di <- ResArray GIPtr
		call	DBLock_DS			;*ds:si <- ResArray
		call	DBDirty_DS
		mov	bx, ds:[LMBH_handle]
		movdw	ss:[bp].PF_resArray, bxsi

	; Call the appropriate parsing routine for each pass

		mov	bx, cs
		test	ss:[bp].PF_flags, mask PF_FIRST_PASS
		jz	notFirst
		mov	di, offset ParseObjectChunks
		jmp	callEnum
notFirst:

EC <		test	ss:[bp].PF_flags, mask PF_SECOND_PASS		>
EC <		ERROR_Z	RESEDIT_INTERNAL_LOGIC_ERROR			>
		mov	di, offset ParseUnknownChunks

callEnum:
		call	ChunkArrayEnum

		mov	bx, ss:[bp].PF_object.handle
		push	bp
		mov	bp, ss:[bp].PF_TFFoffset
		call	MyMemFree	
		pop	bp
		call	DBUnlock_DS			;unlock ResourceArray
		clc
failure:
		pop 	bx, si
		call	MemDerefDS			;*ds:si <- ResourceMap

done:
		.leave
		ret
ParseResourcesCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseObjectChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On the first parse pass, go through all chunks in
		this resource, looking for objects, and mark their
		monikers and text chunks for the second pass parse.

CALLED BY:	ParseResourcesCallback (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ss:bp	- ParseFrame
		
RETURN:		carry set if unsuccessful

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseObjectChunks	proc	far
	uses	bx,cx,dx
	.enter

	push	ds:[LMBH_handle]

	; if this chunk was already marked while parsing another, done
	;
	tst	ds:[di].RAE_data.RAD_chunkType	
	clc
	LONG	jnz	done	

	; save the chunk handle and number in ParseFrame
	;
	mov	ax, ds:[di].RAE_data.RAD_handle	;^lax <- chunk handle
	mov	ss:[bp].PF_object.chunk, ax		; save the chunk handle
	call	ChunkArrayPtrToElement
	mov	ss:[bp].PF_element, ax
	mov	dx, ax

	mov	bx, ss:[bp].PF_object.handle
EC <	call	ECCheckMemHandle				>
	push	bp
	mov	bp, ss:[bp].PF_TFFoffset
	call	MyMemLock
	mov	ds, ax
	pop	bp

	; get the number of handles, and offset to the first one
	; and type of lmem block
	;
EC <	cmp	dx, ds:[LMBH_nHandles]				>
EC <	ERROR_AE	INVALID_CHUNK_NUMBER			>
	mov	di, ds:[LMBH_offset]		;^ldi <- flags block handle

	; See if it is an object block (in which case it has flags).
	; This assumes an object can't be in block that does not have 
	; LMEM_TYPE_OBJ_BLOCK flag set.
	;
	clr	bx
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jne	finishUp
	tst	dx				; Is this the first chunk?
	jnz	checkForObject			;   then it contains only flags

markNotEditable:		
	call	DerefElement_DS
	mov	ds:[di].RAE_data.RAD_chunkType, mask CT_NOT_EDITABLE
	jmp	finishUp

checkForObject:
	; get the chunk's flags, check if it is an object
	;
	mov	bx, ds:[di]			; ds:bx <- flags block
	add	bx, dx				; get this object's flag
	test	{byte}ds:[bx], mask OCF_IS_OBJECT
	jz	finishUp

	;
	; look for GenClass objects, so that their monikers
	; can be extracted.  If it's not GenClass, mark it as
	; not editable, since it IS an object chunk.
	;
	mov	ax, enum GenClass
	call	MarkObjects		
	jnc	markNotEditable			; not a GenClass object

	;
	; It's subclassed off GenClass, so get its VisMoniker, KbdShortcut,
	; text, ....
	;
	call	MarkGenClassStuff		; carry set if error

finishUp:
	clc
	pushf
	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS			;*ds:si <- ResourceArray
	mov	bx, ss:[bp].PF_object.handle
	call	MemUnlock
	popf

done:
	pop	bx
	call	MemDerefDS

	.leave
	ret

ParseObjectChunks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseUnknownChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save editable data from known chunks, and try to 
		parse unknown chunks.

CALLED BY:	ParseResources, CopyGeodeToLoc (via ChunkArrayEnum)
		
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ss:bp	- ParseFrame

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	If the calling routine is CopyGeodeToLoc, then the only
	data in the ResourceArray is from the localization file,
	and it may not be complete (e.g. chunk handle, chunk type).
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseUnknownChunks	proc	far
	uses	bx,cx,dx,es
	.enter

	; if it's already known to be not editable, don't go any further
	; (eg, some object not subclassed from GenClass) 
	;
	test	ds:[di].RAE_data.RAD_chunkType, mask CT_NOT_EDITABLE
	LONG	jnz	notEditable

	; save ResourceArray optr, the chunk's element #, chunk handle
	;
	mov	bx, ds:[LMBH_handle]
	movdw	ss:[bp].PF_resArray, bxsi

	call	ChunkArrayPtrToElement
	mov	ss:[bp].PF_element, ax
	mov	cx, ds:[di].RAE_data.RAD_number	;get the real chunk number

	mov	dx, ds:[di].RAE_data.RAD_handle
	mov	ss:[bp].PF_object.chunk, dx
	segmov	es, ds, ax

	; lock the resource block
	;
	mov	bx, ss:[bp].PF_object.handle
EC <	call	ECCheckMemHandle				>
	push	bp
	mov	bp, ss:[bp].PF_TFFoffset
	call	MyMemLock
	mov	ds, ax
	pop	bp
EC <	cmp	cx, ds:[LMBH_nHandles]				>
EC <	ERROR_AE	INVALID_CHUNK_NUMBER			>

	; if no handle is given, calculate it using the chunk number
	;
	mov	si, dx
	tst	si
	jnz	haveHandle
	mov	si, ds:[LMBH_offset]		;offset of first handle
	mov	ax, size word			;size of chunk handle
	mul	cx				;ax <- offset to chunk's handle
	add	si, ax
	mov	es:[di].RAE_data.RAD_handle, si
	mov	ss:[bp].PF_object.chunk, si
haveHandle:
	mov	si, ds:[si]			;ds:si <- object to be tested

	ChunkSizePtr	ds, si, cx
	mov	ss:[bp].PF_size, cx		; size of the chunk

	; if it is an unknown type, try to parse it now
	;
	mov	dl, es:[di].RAE_data.RAD_chunkType
	tst	dl
	jnz	tryObject
	call	ParseChunk
	jmp	done

tryObject:
	test	dl, mask CT_OBJECT
	jz	tryMoniker
	call	StoreObject
	jmp	done

tryMoniker:
	; if it is a moniker (list, gstring, text), save it now
	;
	test	dl, mask CT_MONIKER
	jz	tryText
	call	StoreMoniker
	jmp	done

tryText:
	test	dl, mask CT_TEXT
	jz	tryGString
	stc					; check the text
	call	StoreText
	jmp	done

tryGString:
	test	dl, mask CT_GSTRING
	jz	tryBitmap
	stc					; check the gstring 
 	call	StoreGString
	jmp	done

tryBitmap:
	test	dl, mask CT_BITMAP
	jz	done
	call	StoreBitmap

done:
	; if the item was not added successfully, mark the chunk
	; as not editable so it will be deleted in next pass
	;
	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS
	jc	success
	mov	ax, ss:[bp].PF_element
	call	ChunkArrayElementToPtr
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND		>
	ornf	ds:[di].RAE_data.RAD_chunkType, mask CT_NOT_EDITABLE
success:
	mov	bx, ss:[bp].PF_object.handle
	call	MemUnlock
notEditable:
	clc					; continue enumeration
	.leave
	ret
ParseUnknownChunks 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteUnknownChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the third pass of the parse attempt.  Go through
		the ResourceArray, deleting items which are not editable
		or of unkown type.

CALLED BY:	ParseResources (via ChunkArrayEnum)
		
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		ss:bp	- ParseFrame
		cx	- number of editable chunks in this resource

RETURN:		cx	- number of editable chunks in this resource

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	If this chunk was not marked on the first pass, and
	ParseChunk could not determine its type on the second pass,
	it will have the CT_NOT_EDITABLE flag set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteUnknownChunks		proc	far

	test	ds:[di].RAE_data.RAD_chunkType, mask CT_NOT_EDITABLE
	jz	done
	call	ChunkArrayDelete
done:
	ret

DeleteUnknownChunks		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to parse a chunk about which nothing is known.

CALLED BY:	ParseUnknownChunks

PASS:		ss:bp	- ParseFrame

RETURN:		carry set if successful in finding an editable chunk

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:
	Don't bother checking for objects, since that was done on the
	first pass.

	Monikers from GenClass objects should have been marked already,
	but monikers and moniker lists from objects subclassed off of 
	objects not in the UI library will not have ben marked.

	Chunks declared in data segments that weren't caught in the
	first pass still need to be parsed, such as GCNLists, 
	ToolGroupLists, text strings, etc.

	Many simple chunks fall through the tests for gstrings and
	bitmaps, so the other things should be checked for first.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseChunk		proc	near

	; Check if this chunk contains a moniker list
	; 
	mov	cx, 1				;don't set flags, just check
	call	MarkMonikerList		
	jnc	monikerList			;carry CLEAR => is moniker list

	; make sure this is not a GCNList before continuing, since
	; they pass through the checks for GStrings and bitmaps.
	;
	mov	cx, 1				;don't set flags, just check
	call	MarkGCNListOfLists
	jnc	gcnList				;carry CLEAR => GCNListofLists
	
	; Look for list of optrs, such as those used by 
	; ToolControl objects.  These also pass through the checks
	; for gstrings and bitmaps, so must check it first.
	; 
	call	MarkOptrLists
	jnc	done			;it's a list of optrs, so not editable

	call	StoreMoniker
	jc	done				;it's a moniker

	; carry set forces a byte-by-byte check for text
	;
	stc					;force call to CheckIfText
	call	StoreText
	jc	done				;it's text

;;; try moving StoreBitmap before StoreGString???
;;; and getting rid of store gstring, since gstrings should only be
;;; pointed to by VisMonikers, anyways.
	call	StoreBitmap

;	stc					;force call to CheckIfGString
;	call	StoreGString
;	jc	done				;it's a gstring

done:
	ret

gcnList:
	clr	cx			;now set the flags and clear the
	call	MarkGCNListOfLists	; carry bit so the callee knowns
	clc				; this is not an editable chunk
	ret

monikerList:
	clr	cx			;now set the flags and clear the
	call	MarkMonikerList		; carry bit so the callee knows
	clc				; this is not an editable chunk
	ret

ParseChunk		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkGCNListofLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since GCNLists are so simple and generic, they can pass
		the checks for GStrings and Bitmaps.  This routine 
		determines whether the chunk contains a GCNListOfLists
		and should be called before checking for the other types.

CALLED BY:	ParseChunk

PASS:		ss:bp	- ParseFrame
		cx	- 0 to set flags, 1 to not set
		
RETURN:		carry CLEAR if it is a GCNList

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:
	
	Structure of the GCN list of lists (resides in a chunk)
	
		GCNListOfListsHeader	struct
			GCNLOL_meta	ChunkArrayHeader
			GCNLOL_data	label	GCNListOfListsElement
			; Start of GCNListOfListsElement's
		GCNListOfListsHeader	ends

		GCNListOfListsElement	struct
			GCNLOLE_ID		GCNListType
			GCNLOLE_list		lptr.GCNListHeader
		GCNListOfListsElement	ends

	The ChunkArray element size must equal size of GCNListOfListsElement.
	The ChunkArray offset to first element must be equal to the
	size of the GCNListOfListsHeader.

	If this chunk contains a GCNListOfLists, its size must be
	large enough to hold the header, plus the size of the
	element times the number of chunks stored in the ChunkArrayHeader.
	If the size is correct, then check for valid lptrs in the
	GCNLOLE_list fields, by calling MarkGCNList.

	If everything checks out okay, mark this chunk as not editable.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version
	JM	 4/23/95	bug fix = don't enum elts in
				 checkElement if count==0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkGCNListOfLists		proc	near
	uses	si,di,ds
	.enter

	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS		
	mov	di, ds:[si]
	mov	si, cx
EC <.norcheck								>
	mov	cx, ds:[di].GCNLOL_meta.CAH_elementSize
	cmp	cx, size GCNListOfListsElement
	jne	failure

	mov	cx, ds:[di].GCNLOL_meta.CAH_offset
	cmp	cx, size GCNListOfListsHeader
	jne	failure

	ChunkSizePtr	ds, di, dx		;actual size of the chunk
	mov	ax, ds:[di].GCNLOL_meta.CAH_count
	mov	cl, size GCNListOfListsElement
	mul	cl				;ax <- size of data part
	add	ax, size GCNListOfListsHeader	;ax <- size of entire array
	cmp	dx, ax				;compare actual & calc'd size
	jne	failure

EC <	.rcheck								>
	mov	bx, ss:[bp].PF_object.handle	;block containing this chunk
	call	MemDerefES			
	mov	ax, es:[LMBH_offset]		;first handle
	mov	dx, es:[LMBH_nHandles]		
	shl	dx, 1				;size of handle table

	push	si				;save set/clear flag
	mov	cx, ds:[di].GCNLOL_meta.CAH_count
	lea	si, ds:[di].GCNLOL_data		;ds:si <- first element
	pop	di				;di <- set/clear flag

	jcxz	markNotEditable
checkElement:
	mov	bx, ds:[si].GCNLOLE_list	;^lbx <- gcnlist chunk handle

	test	bx, 1				;is it an odd number?
	jnz	failure

	cmp	bx, ax				;is it too low to be a handle?
	jl	failure

	push	cx
	mov	cx, di				;cx <- set/clear flag
	call	MarkGCNList			;does it contain a valid list?
	pop	cx
	jnc	failure
		
	push	ax
	add	ax, dx				;add size of table
	cmp	bx, ax				;is it too big to be a handle?
	pop	ax
	jge	failure

	add	si, size GCNListOfListsElement
	loop	checkElement

	; now mark this chunk containing the ListOfLists as not editable
	;
markNotEditable:
	mov	bx, ss:[bp].PF_object.chunk
	mov	cx, di				;cx <- set/clear flag
	mov	dl, mask CT_NOT_EDITABLE
	call	SetChunkType

	clc
done:
	.leave
	ret
failure:
EC <	.rcheck								>
	stc
	jmp	done
MarkGCNListOfLists		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A GCNListOfList may have been detected.  See if
		the passed chunk contains a valid GCNList.

CALLED BY: 	(INTERNAL) MarkGCNListOfLists

PASS:		ss:bp	- ParseFrame
		^lbx	- chunk containing the list to check
		ds	- segment of LMemBlock containg this chunk
		cx	- 0 to set flags, 1 to not set them

RETURN:		carry set if it is a valid GCNList

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Structure of a GCN list:
	
		GCNListHeader	struct
			GCNLH_meta		ChunkArrayHeader
			GCNLH_statusEvent	hptr
			GCNLH_statusData	hptr
			GCNLH_statusCount	word
			; Start of GCNList
		GCNListHeader	ends

		GCNListElement	struct
			GCNLE_item		optr
		GCNListOfListsElement	ends

	The ChunkArray element size must equal size of GCNListElement.
	The ChunkArray offset to first element must be equal to the
	size of the GCNListHeader.

	If this chunk contains a GCNList, its size must be
	large enough to hold the header, plus the size of the
	element times the number of chunks stored in the ChunkArrayHeader.
	If the size is correct, then check for valid optrs in the
	GCNLE_item field by calling SetOptrType passing no flags in dl.
	It will return with the carry bit set if it found the requested
	resource number, chunk handle pair in the resource map.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkGCNList		proc	near
	uses	ax,bx,cx,dx,si,di
	.enter

	push	bx				;save the list's chunk handle
	push	cx				;save the set/clear flag
	mov	dx, cx				;dx <- set/clear flag
	mov	si, bx
	mov	di, ds:[si]
	ChunkSizePtr	ds, di, bx
	cmp	bx, size GCNListHeader
	jl	failurePop2

	mov	cx, ds:[di].GCNLH_meta.CAH_elementSize
	cmp	cx, size GCNListElement
	jne	failurePop2

	mov	cx, ds:[di].GCNLH_meta.CAH_offset
	cmp	cx, size GCNListHeader
	jne	failurePop2

	mov	ax, ds:[di].GCNLH_meta.CAH_count
	mov	cl, size GCNListElement
	mul	cl				;ax <- size of data part
	add	ax, size GCNListHeader		;ax <- size of entire array
	cmp	ax, bx				;compare actual & calculated 
	jne	failurePop2			;  size

	mov	cx, ds:[di].GCNLH_meta.CAH_count
	mov	si, ds:[di].GCNLH_meta.CAH_offset 
	add	si, di				;si <- offset of first element
	clr	dx				;no ChunkType flags
	pop	di				;restore the set/clear flag

checkElement:
	movdw	bxax, ds:[si].GCNLE_item
	push	cx
	mov	cx, di				;restore set/clear flag
	call	SetOptrType
	pop	cx
	jc	failurePop1
	add	si, size GCNListElement
	loop	checkElement

	pop	bx 				;^lbx <- chunk containing list
	mov	cx, di				;  cx <- set/clear flag
	mov	dl, mask CT_NOT_EDITABLE	;flag to set
	call	SetChunkType			
	jc	failureNoPop
	stc					;it's a valid list!

done:
	.leave
	ret

failurePop2:
	add	sp, 2				;clear 1 word off the stack
failurePop1:
	add	sp, 2				;clear 1 word off the stack
failureNoPop:
	clc
	jmp	done

MarkGCNList		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether an object is a subclass of the passed 
		class.

CALLED BY:	ParseObjectChunks

PASS:		ss:bp	- ParseFrame
		ax	- class enum

RETURN:		carry set if a object is a subclass of passed class

DESTROYED:	ax,bx,si,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkObjects		proc	near
	uses	di,es
	.enter

	call	CheckIfUIObject
	jnc	done
	
	call	DerefElement_DS
	ornf	ds:[di].RAE_data.RAD_chunkType, mask CT_OBJECT
	stc
done:
	.leave
	ret
MarkObjects		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkGenClassStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An object sublcassed off GenClass has been found.
		Get its mnemonic and keyboard shortcut, if any.

CALLED BY:	ParseObjectChunks
PASS:		ss:bp	- ParseFrame
RETURN:		carry set if moniker chunk is bad
DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkGenClassStuff		proc	near
	.enter

	call	MarkText			; find its text, if any
						;   (ignore errors)

	movdw	bxsi, ss:[bp].PF_object
	push	si				; save object's chunk
	call	MemDerefES			; *es:si <- object
	mov	si, es:[si]
	add	si, es:[si].Gen_offset
	mov	ax, es:[si].GI_kbdAccelerator

	call	DerefElement_DS
	mov	ds:[di].RAE_data.RAD_kbdShortcut, ax

	mov	si, es:[si].GI_visMoniker	;^lsi <- visMoniker
	mov	ss:[bp].PF_object.chunk, si	; save it here for MarkMonikers

	call	MarkMonikers			; carry set on error
	pop	ss:[bp].PF_object.chunk		; restore object chunk
	jc	done

	clc
done:
	.leave
	ret
MarkGenClassStuff		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Object is a GenClass, see if it has moniker(s).

CALLED BY:	(INTERNAL) ParseObjectChunks

PASS:		ss:bp	- ParseFrame

RETURN:		carry set if unsuccessful: moniker chunk contains
		unexpected data.

DESTROYED:	ax,bx,cx,di,ds

PSEUDO CODE/STRATEGY:
	If it is a simple moniker, mark the chunk as such.

	If the chunk contains a moniker list, mark it as not editable,
	and call MarkMonikerList to mark all list entries as either 
	text or gstring monikers.

	If the first call to MarkMonikerList fails, 
	it has to be called again to unmark any of the chunks it may 
	have marked on the first call before it failed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkMonikers		proc	far
	uses	dx
	.enter

	; get the moniker chunk
	;
	movdw	bxdi, ss:[bp].PF_object		;^lbx:di <- moniker chunk
	call	MemDerefDS
	tst	di				;is there a moniker?
	clc
	jz	done				;nope, done.

	mov	bx, di					;^lbx <- moniker chunk
	mov	di, ds:[di]				;ds:di <- VisMoniker
	test	ds:[di].VM_type, mask VMT_MONIKER_LIST
	jnz	monikerList				;it's a list!

	mov	dl, mask CT_TEXT			;default is text
	test	ds:[di].VM_type, mask VMT_GSTRING	;is it a gstring?
	jz	setChunkType				;no, it's text
	mov	dl, mask CT_GSTRING	

setChunkType:
	; pass dl - CT flags, bx - chunk handle, ss:bp
	ornf	dl, mask CT_MONIKER
	clr	cx					;set the flags in dx
	call	SetChunkType

done:
	.leave
	ret

monikerList:
	; Check all the VisMoniker list entries.  If this call fails,
	; this chunk is not a VisMoniker.
	;
	mov	cx, 1					;don't set the CT flags
	call	MarkMonikerList
	jc	done					;not a monikerList
	
	; It's a valid VisMoniker list.  Now go back and set the
	; ChunkType flags for the monikers in the list.
	; 
	clr	cx					;set the CT flags
	call	MarkMonikerList				;if errors, don't know
EC <	ERROR_C	SET_CHUNK_TYPE_FAILED_UNEXPECTEDLY		>

	; mark the VisMonikerList chunk itself as not editable	
	; ^lbx - chunk containing moniker list
	;
	clr	cx					;set the flag
	mov	dl, mask CT_NOT_EDITABLE
	call	SetChunkType				;
EC <	ERROR_C	SET_CHUNK_TYPE_FAILED_UNEXPECTEDLY		>
	jmp	done

MarkMonikers		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkMonikerList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if this chunk contains a moniker list.

CALLED BY:	MarkMonikers, ParseChunks

PASS:		ss:bp	- ParseFrame
		cx	- 0 to set, 1 to clear flags
	
RETURN:		carry set if unsuccessful

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkMonikerList		proc	near
	uses	ax,bx,dx,si,di
	.enter

	mov	si, cx

	; get the moniker chunk
	;
	movdw	bxdi, ss:[bp].PF_object
	call	MemDerefDS
	tst	di
	stc
	jz	done
	mov	di, ds:[di]

	ChunkSizePtr	ds, di, ax			;ax <- size of list
	clr	dx					
	mov	bx, size VisMonikerListEntry
	div	bx
	tst	dx					;doesn't divide evenly,
	stc
	jnz	done					; so can't be a list
	mov	cx, ax

nextEntry:
	; if this chunk is not marked as a moniker list, we're in trouble
	;
	test	ds:[di].VMLE_type, mask	VMLET_MONIKER_LIST
	stc
	jz	done
	mov	dl, mask CT_TEXT			;default is text
	test	ds:[di].VMLE_type, mask	VMLET_GSTRING	;is it a gstring?
	jz	setOptrType				;no, it's text
	mov	dl, mask CT_GSTRING

setOptrType:	
	; pass flags in dl, set or clear flag in cx, 
	; PF in ss:bp, optr to mark in bx:ax
	;
	push	cx
	mov	cx, si
	ornf	dl, mask CT_MONIKER
	movdw	bxax, ds:[di].VMLE_moniker
	call	SetOptrType		
	pop	cx
	jc	done					;error, don't continue
	add	di, size VisMonikerListEntry
	loop	nextEntry
	clc
done:
	.leave
	ret
MarkMonikerList		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkOptrLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is an attempt to catch Tool lists
		associated with ToolControl objects.  Since many of
		them are defined in non-ui libraries, I can't detect
		them without loading those libraries.  
		
CALLED BY:	ParseObjectChunks

PASS:		ss:bp	- ParseFrame
	
RETURN:		carry set if not a list of optrs

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkOptrLists		proc	near
	uses	ax,bx,dx,si,ds
	.enter

	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	si, ds:[si]			;ds:si <- list of optrs?

	; see if the size is a dword multiple
	;
	mov	ax, ss:[bp].PF_size
	clr	dx
	mov	cx, size optr
	div	cx
	tst	dx
	stc
	jnz	done

	mov	cx, ax				;cx <- # of optrs in list

nextOptr:
	push	cx
	mov	cx, 1				;don't set flags, just check
						; if optr exists
	movdw	bxax, ds:[si]	
	call	SetOptrType
	pop	cx
	jc	done				;it was not a valid optr
	add	si, size dword			;add size of optr to ptr
	loop	nextOptr
	clc

done:
	.leave
	ret
MarkOptrLists		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Object is GenClass, see if it is a GenText and has
		an lptr to some text.

CALLED BY:	ParseObjectChunks

PASS:		ss:bp	- ParseFrame

RETURN:		carry set if error marking text chunk

DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkText		proc	near
	uses	di,ds
	.enter

	; first, see it is a subclass of GenTextClass
	;
	mov	ax, enum GenTextClass
	call	CheckIfUIObject
	jnc	notGenText

	; get the text chunk handle
	;
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GTXI_text

setType:
	; set the ChunkType flag for the text chunk
	;
	clr	cx				; set the flags in dl
	mov	dl, mask CT_TEXT		; 
	mov	bx, di
	call	SetChunkType			; carry set if error

done:
	.leave
	ret

notGenText:
	; okay, see it is a subclass of VisTextClass
	;
	mov	ax, enum VisTextClass
	call	CheckIfUIObject
	jnc	done

	; deref the text handle
	;
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].VTI_text
	jmp	setType

MarkText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the object has a shortcut and its element should
		therefore not be deleted.

CALLED BY:	ParseUnknownChunks
PASS:		es:di	- ResourceArrayElement
		ss:bp	- ParseFrame
RETURN:		carry set if the object has an editable shortcut 
DESTROYED:	ax,cx,si,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreObject		proc	near	
	uses	bx
	.enter

	mov	ax, es:[di].RAE_data.RAD_kbdShortcut
	tst	ax
	clc
	jz	done

	; If it is not editable, don't bother saving it
	;
	call	CheckIfEditableShortcut
	cmc
	jnc	done

	; convert the shortcut to its textual equivalent
	;
	sub	sp, SHORTCUT_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss, cx			;es:di <- buffer
	mov	ds, cx
	mov	si, di				;ds:si <- buffer
	call	ShortcutToAscii			;cx <- length

	; store the actual KeyboardShortcut after is text representation
	;
DBCS <	shl	cx, 1				; convert length to size>
	add	di, cx				; ds:di <- pts past NULL
	mov	ds:[di], ax			; save KbdShortcut

	add	cx, size KeyboardShortcut	;extra room for KbdShortcut 
	mov	ss:[bp].PF_size, cx
EC<	cmp	cx, SHORTCUT_BUFFER_SIZE			>
EC<	ERROR_A	RESEDIT_INTERNAL_LOGIC_ERROR			>

	; copy the shortcut stored in ds:si to a DBItem
	;
	call	PutDataInItem			; di <- item number
	add	sp, SHORTCUT_BUFFER_SIZE

	push	di
	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS
	mov	ax, ss:[bp].PF_element
	call	ChunkArrayElementToPtr
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND		>
	pop	ds:[di].RAE_data.RAD_origItem

	stc	
done:
	.leave
	ret
StoreObject		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOptrResourceNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an unrelocated optr, return the resource number.

CALLED BY:	INTERNAL - (SetOptrType, GetAllChildren)
PASS:		^lbx:ax	- optr
RETURN:		carry set if error
		ax	- resource number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOptrResourceNumber		proc	near
	uses	bx,cx,dx
	.enter

	; the optr handle is an ObjRelocationID record, the top
	; 4 bits give the source, the lower four the index
	;
	mov	dx, ax				;^ldx <- chunk 
	mov	ax, bx				
	mov	cx, ax				;ax, cx <- ORID
	andnf	ax, mask RID_SOURCE		

	; If the source is a data segment (as for VisMonikers defined in
	; resources marked as data), RID_SOURCE will be ORS_NULL.
	;
	cmp	ax, (ORS_NULL shl offset RID_SOURCE)
	je	nullSource
	
	; If the source is current block, get resource number from ParseFrame.
	;
	test	ax, (ORS_CURRENT_BLOCK shl offset RID_SOURCE)
	jnz	getResourceNumber

	; If the source is OWNDING_GEODE, index gives the resource ID.
	;
	test	ax, (ORS_OWNING_GEODE shl offset RID_SOURCE)
	stc
	jz	done

nullSource:
	mov	ax, cx
	andnf	ax, mask RID_INDEX

	clc
done:
	.leave
	ret

getResourceNumber:
	mov	ax, ss:[bp].PF_resource
	clc
	jmp	done

GetOptrResourceNumber		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetOptrType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An editable chunk, referenced by an optr, has been found.
		Find its resource:chunk and set its flags.

CALLED BY:	(INTERNAL) Utility

PASS:		ss:bp	- ParseFrame
		^lbx:ax	- (unrelocated) optr of editable object
		cx	- 0 to set flags in dl,
			  1 to not set flags, but check for optr's existence
		dl	- ChunkType flags to set

RETURN:		carry set if unsuccessful

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
	If a resource is marked as data, UIC does not generate an object
	relocation for the handle, so RID_SOURCE will be ORS_NULL.  
	The value stored in the handle part of the optr is a resource ID,
	and there's a GeodeRelocationEntry for that offset within that 
	resource. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetOptrType		proc	far
	uses	dx,si,di,ds
	.enter

EC <	cmp	cx, 0				>
EC <	je	okay				>
EC <	cmp	cx, 1				>
EC <	ERROR_NE	SET_CHUNK_TYPE_BAD_FLAGS	>
EC <okay:					>

	; the optr handle is an ObjRelocationID record, the top
	; 4 bits give the source, the lower four the index
	;
	push	dx, cx				; save the flags
	mov	dx, ax				;^ldx <- chunk to be marked

	call	GetOptrResourceNumber		; ax <- resource number
	jc	error
	cmp	ax, ss:[bp].PF_resource		;is it in this resource?
	je	setChunkType

	; lock the map block, get the map array	
	;
	push	ax
	mov	bx, ss:[bp].PF_transFile
	mov	si, ss:[bp].PF_TFFoffset
	mov	ax, ss:[si].TFF_destGroup
	mov	di, ss:[si].TFF_destItem
	call	DBLock_DS
	mov	di, ds:[si]			;ds:di <- TransMapHeader
	pop	ax

	; make sure this is a valid resource number
	;
	cmp	ax, ds:[di].TMH_totalResources
	jae	errorUnlock

	; lock this resource's ResourceArray 
	;
	call	FindResourceNumber
	jc	errorUnlock			;resource not found, get out
;EC <	ERROR_C CHUNK_ARRAY_ELEMENT_NOT_FOUND		>
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	mov	bx, ss:[bp].PF_transFile
	call	DBUnlock_DS			;unlock map block

	call	DBLock				;*es:di <- ResourceArray

	; put the target resource's ResourceArray optr in the ParseFrame
	;
	pop	bx, cx				;need ChunkType, set/clear flag
	pushdw	ss:[bp].PF_resArray		; on top of stack, so pop them
	push	bx, cx				; before pushing resArray
	mov	bx, es:[LMBH_handle]
	movdw	ss:[bp].PF_resArray, bxdi

	mov	bx, dx				;^lbx <- chunk to be marked
	pop	dx, cx				;restore the ChunkType flags
	call	SetChunkType			;carry set if unsuccessful

	; If the optr was from different block, unlock it's ResourceArray
	;
	popdw	ss:[bp].PF_resArray		;original resource's ResArray
	call	DBUnlock

done:	
	.leave
	ret

setChunkType:
	mov	bx, dx				;^lbx <- chunk to be marked
	pop	dx, cx				;restore the ChunkType flags
	call	SetChunkType
	jmp	done

errorUnlock:
	call	DBUnlock_DS
error:
	pop	dx, cx
	stc
	jmp	done
SetOptrType		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetChunkType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An editable chunk has been found, set its flags.

CALLED BY:	(INTERNAL) Utility

PASS:		ss:bp	- ParseFrame
		^lbx	- chunk handle
		cx	- 0 to set flags in dl,
			  1 to not set flags, but check for optr's existence
		dl	- ChunkType flags to set

RETURN:		carry set if unsuccessful

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetChunkType		proc	near
	uses	bx,si,di,ds,bp
	.enter

EC <	cmp	cx, 0					>
EC <	je	okay					>
EC <	cmp	cx, 1					>
EC <	ERROR_NE	SET_CHUNK_TYPE_BAD_FLAGS	>
EC <okay:						>

	push	cx
	mov	cx, bx				;^lcx <- chunk to mark
	movdw	bxsi, ss:[bp].PF_resArray
	pop	bp				;bp <-set/clear flag 
	call	MemDerefDS
	mov	bx, cs
	mov	di, offset SetChunkTypeCallback
	call	ChunkArrayEnum			;carry set if found this handle
	jnc	notFound
	clc
done:
	.leave
	ret

notFound:
	stc
	jmp	done
SetChunkType		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetChunkTypeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the element which has the passed chunk handle
		and set its flags.

CALLED BY:	SetChunkType (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		^lcx	- chunk handle
		dl	- flags to modify	
		bp	- 0 to set flags in dl, 
			  1 to check for chunk's existence

RETURN:		carry set if chunk handle found, to abort the Enum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetChunkTypeCallback		proc	far
	.enter

	cmp	cx, ds:[di].RAE_data.RAD_handle
	clc	
	jne	continue
	
	; I found it!  Now set or clear the flags.
	;
	tst	bp
	jnz	doNotSet
	ornf	ds:[di].RAE_data.RAD_chunkType, dl
doNotSet:
	stc

continue:
	.leave
	ret

SetChunkTypeCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefElement_DS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference the current element.

CALLED BY:	INTERNAL - utility
PASS:		ss:bp	- ParseFrame
RETURN:		ds:di	- element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefElement_DS		proc	near
	uses	ax,bx,cx,si
	.enter

EC<	cmp	ss:[bp].PF_signature, PARSE_FRAME_SIG		>
EC<	ERROR_NE	RESEDIT_INTERNAL_LOGIC_ERROR		>

	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS
	mov	ax, ss:[bp].PF_element
	call	ChunkArrayElementToPtr		; ds:di <- ResourceArrayElement
EC < 	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>
	
	.leave
	ret
DerefElement_DS		endp

DocumentParseCode	ends


