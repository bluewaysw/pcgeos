COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit/Document
FILE:		documentDB.asm

AUTHOR:		Cassie Hartzong, Oct  1, 1992

ROUTINES:
	Name			Description
	----			-----------
	AllocMapItem		Allocate a ResourceMap for the passed file. 
	AllocNameArray		Allocate a name array in the db file 
	CreateName		Initializing a NameArray, need a dummy name for 
				this resource or chunk 
	MyMemFree		Free the resource block. 
	MyMemLock		Up the counter for the resource that is being 
				locked. 
	FindFreeResourceHandleTableEntry	Find an unused handle table 
				entry, or one whose 
	LoadResource		Return the handle of the block the resource is 
				in. 
	ResEditLoadResourceLow	Read the requested resource into a memory 
				block. 
	GetResourceFlags	Get the HeapAllocFlags and HeapFlags for a 
				resource in the geode. 
	AllocResourceGroups	Allocate and add ResourceMapElements to the map 
				block in bp:di. 
	AddNewResource		Add a new element to the passed map block. 
				Allocate a DBGroup for the resource and create 
				a ResourceArray in it. 
	InitResArrays		Add elements to ResourceArrays for each chunk 
				in the resource, as read from the geode. 
	InitResArraysCallback	Load the resource, and for each chunk add an 
				element to the ResourceArray. 
	AddChunkItems		For each chunk in this resource, add an element 
				to the chunk name array. 
	CopyLocToTrans		Copy localization file information into the 
				translation file, resource by resouce, using 
				ChunkArrayEnum. 
	CopyLocToTransCallback	Copy localization information for this resource 
				to the translation file. 
	CopyLocElement		Copy info from LocArray to ResourceArray for 
				this chunk. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/92	Initial revision

DESCRIPTION:
	This file contains database routines.	

	Okay,
	_____________________Translation File Overview____________________

	A ResEdit document's map block consists of a TransMapHeader, which
	holds the general information about the document.  The first entry
	in the TransMapHeader is a NameArrayHeader for an array containing
	the name and ResourceMapData for each resource represented in the
	file.

		DBItem:		NameArrayElement + ResourceMapData

	The translation file holds a DBGroup for each resource.  These
	contain: 

		DBMapItem: 	ResourceArrayHeader

	and for each editable chunk in the original geode that falls in this
	resource:

		DBItem:		NameArrayElement + ResourceArrayData
	___________________________________________________________________

	$Id: documentDB.asm,v 1.1 97/04/04 17:14:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DatabaseCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocMapItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a ResourceMap for the passed file.

CALLED BY:	(EXTERNAL) - InitializeDocumentFile,

PASS:		^hbx	- file handle

RETURN:		ax:di	- DBGroup and item of map block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocMapItem		proc	far
	uses	bx,cx, dx, si, ds
	.enter
	
	call	DBGroupAlloc			; ax <- new group
	mov	cx, size TransMapHeader	
	mov	dx, size ResourceMapData
	call	AllocNameArray			; ax:di <- DBItem

	.leave
	ret
AllocMapItem		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a name array in the db file

CALLED BY:	(EXTERNAL) AllocMapItem, AddNewResource
		InitializeDocumentFile, ReadGeodeFile,
		AllocResourceGroups

PASS:		bx = 	file handle
		ax = 	group
		cx =	header size
		dx = 	element data size (not including size NameArrayElement)

RETURN:		ax:di - DBItem of name array

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocNameArray	proc far
	uses	bx,cx,dx,ds,si
	.enter

	call	DBAlloc				; ax:di <- item
	push	ax, di
	call	DBLock_DS			; *ds:si <- ResourceArray

	clr	al
	mov	bx, dx				; element data size
	call	NameArrayCreate
EC <	call	ECCheckChunkArray				>

	mov	si, ds:[si]
	mov	ds:[si].TMH_arrayType, AT_RESOURCE_ARRAY
	call	DBDirty_DS
	call	DBUnlock_DS
	pop	ax, di				; return item number
	
	.leave
	ret
AllocNameArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializing a NameArray, need a dummy name
		for this resource or chunk

CALLED BY:	AddChunkItems

PASS:		es:di	- buffer to put name into
		^lax	- chunk in StringsUI containing name to copy 
		dx	- number to tack onto name
		
RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Assumes that the buffer is big enough to hold a name
	that is no longer than MAX_NAME_LEN chars (not including
	the null-terminator.)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateName		proc	far
	uses	bx,cx,dx,si,di,ds
	.enter

	push	di				;save beginning of buffer
	mov	si, ax				;^lsi <- source name chunk
	mov	cx, dx
	GetResourceHandleNS	StringsUI, bx
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			;ds:si <- source string	
	LocalCopyString
	call	MemUnlock

	LocalPrevChar	esdi			;es:di points to null-term.
	mov	dx, cx
	clr	ax, cx				;no fraction part
	call	LocalFixedToAscii

	pop	di				;es:di points to beginning
	call	LocalStringLength
	cmp	cx, MAX_NAME_LEN
	ERROR_A	RESEDIT_NAME_BUFFER_OVERFLOW

	.leave
	ret
CreateName		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyMemFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the resource block.

CALLED BY:	EXTERNAL - utility
PASS:		^hbx	- block handle
		ax	- TranslationFileFrame segment
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyMemFree		proc	far
	uses	cx,si,ds
	.enter

EC<	cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG	>
EC<	ERROR_NE  BAD_TRANSLATION_FILE_FRAME				>

	segmov	ds, ss:[bp].TFF_handles
EC<	cmp	ds:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG		>
EC<	ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT				>

	lea	si, ds:[DHS_resourceHandleTable]
	mov	cx, RESOURCE_TABLE_SIZE
findLoop:
	cmp	ds:[si].RHT_handle, bx
	jne	continue
	ornf	ds:[si].RHT_handle, 1
	jmp	done
continue:
	add	si, size ResourceHandleTable
	loop	findLoop

EC<	tst	cx						>
EC<	ERROR_Z RESEDIT_INTERNAL_LOGIC_ERROR			>

done:
	;
	; assume user has unlocked block - later check counter
	;
;	call	MemUnlock			; unlock it just in case

	.leave
	ret
MyMemFree		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyMemLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Up the counter for the resource that is being locked.

CALLED BY:	EXTERNAL - utility
PASS:		^hbx	- resource block handle
RETURN:		ax	- segment
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyMemLock		proc	far
	uses cx,si,ds
	.enter

EC<	cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG	>
EC<	ERROR_NE  BAD_TRANSLATION_FILE_FRAME				>

	segmov	ds, ss:[bp].TFF_handles
EC<	cmp	ds:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG		>
EC<	ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT				>

	lea	si, ds:[DHS_resourceHandleTable]
	mov	cx, RESOURCE_TABLE_SIZE

findLoop:
	mov	ax, ds:[si].RHT_handle
	cmp	ax, bx
	je	foundIt
	add	si, size ResourceHandleTable
	loop	findLoop

EC<	tst	cx						>
EC<	ERROR_Z RESEDIT_INTERNAL_LOGIC_ERROR			>


foundIt:
EC<	test	bx, 1						>
EC<	ERROR_NZ RESEDIT_INTERNAL_LOGIC_ERROR			>
	inc	ds:[si].RHT_counter
	mov	bx, ax
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo
	test	al, mask HF_LMEM		; if not LMem block
	jz	nonObjLock			; ...then just use MemLock
	call	ObjLockObjBlock
done:
	.leave
	ret

nonObjLock:
	call	MemLock
	jmp	done
MyMemLock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFreeResourceHandleTableEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an unused handle table entry, or one whose 

CALLED BY:	LoadResource

PASS:		ds	- DocumentHandlesStruct

RETURN:		ds:si	- ResourceHandleTable entry
		carry set if no free entry
			ax - LRE_HANDLE_TABLE_FULL

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	First look for an emtpy entry (has no handle).
	If all are full, look for an unused entry (low bit of handle
	  is set).
	Copy the first entry to the entry just found. 
	Mark the first entry as free. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFreeResourceHandleTableEntry		proc	near
	uses	bx,cx,di
	.enter

	; look for an entry that has no handle at all
	;
	lea	si, ds:[DHS_resourceHandleTable]
	mov	cx, RESOURCE_TABLE_SIZE
findEmptyLoop:
	tst	ds:[si].RHT_handle
	jz	foundOne
	add	si, size ResourceHandleTable
	loop	findEmptyLoop

	; All entries have handles, so look for one that is unused.
	; Start from the last entry.
	;
	sub	si, size ResourceHandleTable	; ds:si <- last RHT entry
	mov	cx, RESOURCE_TABLE_SIZE 
	
findFreeLoop:
	test	ds:[si].RHT_handle, 1		; is it not currently in use?
	jnz	foundOne
	sub	si, size ResourceHandleTable
	loop	findFreeLoop

foundOne:
	mov	ax, LRE_HANDLE_TABLE_FULL
	tst	cx				; if cx = 0, no entries are
	stc					;   available for use
	jz	done

	;
	; either an unused entry was found, or one whose resource block
	; is not currently being used, so can be kicked out of memory
	;
	tst	ds:[si].RHT_handle		; is it an unused entry?
	clc
	jz	done				; yes, we're done

	;
	; actually free the block for real
	;
	mov	bx, ds:[si].RHT_handle
	andnf	bx, 0xfffe			; clear the 'free entry' bit
	call	MemFree				; now really free the block

	;
	; if this *is* the first entry, don't need to move it
	;
	lea	di, ds:[DHS_resourceHandleTable]	;ds:di <- first entry
	cmp	si, di					;ds:si <- free entry
	je	freeIt					;if same, don't move it

	;
	; copy the first entry to this (free one)
	;	
	mov	al, ds:[di].RHT_number
	mov	ds:[si].RHT_number, al
	mov	al, ds:[di].RHT_counter
	mov	ds:[si].RHT_counter, al
	mov	ax, ds:[di].RHT_handle
	mov	ds:[si].RHT_handle, ax
	mov	si, di

freeIt:
	;
	; now mark the first entry as free
	;
	clr	ds:[si].RHT_handle
	mov	ds:[si].RHT_number, -1
	clr	ds:[si].RHT_counter
	clc

done:
	.leave
	ret

FindFreeResourceHandleTableEntry		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the handle of the block the resource is in.

CALLED BY:	EXTERNAL - utility

PASS:		ss:bp	- TranslationFileFrame
		ax	- resource number
RETURN:		
	carry clear - 
		ax  - LRE_NONE
		      LRE_NOT_LMEM	
		      LRE_NO_HANDLES		
		^hbx - handle of editable resource
	carry set -
		ax -  LRE_ZERO_SIZE
		      LRE_FILE_READ
		      LRE_MEMALLOC
		bx - 0

DESTROYED:	dx, ds (if call LoadResourceNoSaveNS)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadResource		proc	far
	uses	cx
	.enter

	push	ds:[LMBH_handle]
	call	LoadResourceHigh
	mov	cx, bx
	pop	bx
	call	MemDerefDS
	mov	bx, cx

	.leave
	ret
LoadResource		endp

;--------------

LoadResourceNoSaveDS		proc	far

	call	LoadResourceHigh
	ret
LoadResourceNoSaveDS		endp

;--------------

LoadResourceHigh		proc	near
	uses	cx,si,di
	.enter

EC<	cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG	>
EC<	ERROR_NE  BAD_TRANSLATION_FILE_FRAME				>

	segmov	ds, ss:[bp].TFF_handles, si
EC<	cmp	ds:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG		>
EC<	ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT				>

	lea	si, ds:[DHS_resourceHandleTable]
	mov	cx, RESOURCE_TABLE_SIZE
	mov	bx, ax				; bl <- resource # to find
	mov	ax, LRE_NONE			; assume no error

findLoop:
	cmp	bl, ds:[si].RHT_number
	je	foundIt
	add	si, size ResourceHandleTable
	loop	findLoop

	;
	; the resource is not currently loaded, must find a free
	; entry and load it in.
	;
tryAgain:
	call	FindFreeResourceHandleTableEntry ; ds:si <- free entry
	jc	done

	mov	ax, bx
	mov	di, ax				; di <- resource # saved
	mov	dx, ss:[bp].TFF_numResources
	mov	cx, ds:[DHS_resourceTable]
	mov	bx, ds:[DHS_geode]
	call	ResEditLoadResourceLow
	jnc	okay

	cmp	ax, LRE_MEMALLOC		; not enought Mem?
	je	tryAgain			; try freeing another entry

	stc					; must have been a file error
	jmp	done

okay:
	mov	ds:[si].RHT_handle, bx
	mov	bx, di
	mov	ds:[si].RHT_number, bl
		
foundIt:
	mov	bx, ds:[si].RHT_handle
	andnf	bx, 0xfffe			; marks the entry as in use
	mov	ds:[si].RHT_handle, bx
	clc

done:
	.leave
	ret
LoadResourceHigh	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditLoadResourceLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the requested resource into a memory block.

CALLED BY:	(EXTERNAL) InitResArraysCallback, CreateExecutable

PASS:		^hbx	- geode file handle
		^hcx	- resource table handle
		ax	- resource number
		dx	- total number of resources in geode

RETURN:		
	carry clear - 
		ax   - LRE_NONE		
		       LRE_NOT_LMEM	- not an LMem resource
		       LRE_NO_HANDLES	- no handles in the resource
		^hbx - handle of editable resource
	carry set -
		ax - LoadResourceError
			LRE_ZERO_SIZE	- empty resource
			LRE_FILE_READ	- error while reading file
			LRE_MEMALLOC 	- couldn't allocate a block for it

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditLoadResourceLow		proc	far
geodeHandle	local	hptr	push 	bx
resNumber	local	word	push	ax
flags		local	word
	uses	si,ds
	.enter

	mov	bx, cx				;^hbx <- resource table
	call	GetResourceFlags		; ax <- HAF and HF flags
	mov	ss:[flags], ax

	; find the resource's position in the file and its size
	;
	mov	cx, ss:[resNumber]
	mov	bx, ss:[geodeHandle]
	clr	dx
	call	GeodeFindResource		;cx:dx <- resource file pos
						;ax <- resource size
	; make sure the resource is a valid size: non-zero, and at least
	; as large as an LMemBlockHeader.
	;
	mov	si, ax				;save the size in si
	tst	si				;if 0 size, don't bother...
	mov	ax, LRE_ZERO_SIZE
	jz	errorNoBlock

	; position the file at the start of the resource
	;
	mov	al, FILE_POS_START
	call	FilePos				;dx:ax <- new file position

	; Round up the resource size to paragraph boundary, as resources
	; are written to the geode that way, and if some fraction of a 
	; paragraph is not read in, when we go to read the relocation table, 
	; the file position will be off by that much.
	add	si, 15
	andnf	si, 0xfff0
	
	; allocate a block big enough to hold the resource
	mov	ax, si
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			;ax <- segment, bx <- handle
	mov	ds, ax
	mov	ax, LRE_MEMALLOC
	jc	errorNoBlock

	; now read it into the block
	push	bx 				;resource block handle
	mov	bx, ss:[geodeHandle]		;^hbx = geode file handle
	clr	dx				;ds:dx <-buffer to read into
	mov	cx, si				;cx <- # of bytes to read
	clr	al
	call	FileRead			;cx <- # bytes actually read
	pop	bx
	mov	ax, LRE_FILE_READ
	jc	errorFree

	; if not possibly large enough to be an LMemBlock, don't 
	; mark it as such
	;
	cmp	cx, size LMemBlockHeader
	jb	notLMem
	
 	; Change the block to a LMemBlock so we can rearrange the contents
        ; and rely on the abilities of LMem to organize the chunks.
	;
	mov	ax, ss:[flags]
	and	ax, mask HF_LMEM
	jz	notLMem
	mov	al, mask HF_LMEM
        call    MemModifyFlags

 	; Set the other info field so that we won't fail in ObjLockObjBlock()
	;
	push	bx
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo			; get current thread's handle
	pop	bx
	call	MemModifyOtherInfo

	; Replace the resource ID with the block handle.
	; 
        mov     ds:[LMBH_handle], bx            ;set handle to itself

	; Find out if this is a resource which contains nothing of interest.
	; if this is a special LMem block (i.e. core block) it will have
	; LMF_NO_HANDLES.  If it is a legitimate block but has no handles
	; (i.e. dgroup), LMBH_nHandles will be 0.
	;
	mov	ax, LRE_NO_HANDLES
	test	ds:[LMBH_flags], mask LMF_NO_HANDLES
	jnz	unlock
	tst	ds:[LMBH_nHandles]
	jz	unlock

	mov	ax, LRE_NONE

unlock:
	call	MemUnlock
	clc

done:
	.leave
	ret

notLMem:
	mov	ax, LRE_NOT_LMEM
	jmp	unlock

errorFree:					;free the block
	call	MemFree

errorNoBlock:					;no block allocated
	clr	bx
	stc
	jmp	done

ResEditLoadResourceLow		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetResourceFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the HeapAllocFlags and HeapFlags for a resource in 
		the geode.

CALLED BY:	EXTERNAL (ResEditLoadResourceLow, UpdateRelocationTable)
PASS:		^hbx	- ResourceTable
		ax	- resource number
		dx	- total number of resources
RETURN:		ax	- flags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetResourceFlags		proc	far
	uses	dx,si,es
	.enter

	; Lock the resource table and go to the allocation flags part:
	; HeapFlags record in the low byte, HeapAllocFlags in the high byte.
	;
	push	ax
	call	MemLock
	mov	es, ax

	; sizeof tables before flags table: 2 bytes for resource size,
	; 4 bytes for resource position, 2 bytes for relocation table size
	;
	mov	ax, dx
	mov	dl, 8				;sizeof tables before flags
	mul	dl
	mov	si, ax				;es:si <- ptr to flags table
	pop	ax

	shl	ax, 1				;ax*2 <- res # * size word
	add	si, ax				;es:si <- resource's flags
	mov	ax, es:[si]
	call	MemUnlock

	.leave
	ret
GetResourceFlags		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocResourceGroups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and add ResourceMapElements to the map block
		in bp:di.

CALLED BY:	(EXTERNAL) REDReadSourceGeode

PASS:		ss:bp	- TranslationFileFrame

RETURN:		carry set if error (a resource was not added)
			ax - ErrorValue
DESTROYED:	ax,di,es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocResourceGroups		proc	far
	uses	cx,dx,si
	.enter

EC<		cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG >
EC<		ERROR_NE  BAD_TRANSLATION_FILE_FRAME			>

	; Remember document block for dereferencing.

		push	ds:[LMBH_handle], si

	; Get the file handle.

		mov     ax, MSG_GEN_DOCUMENT_GET_FILE_HANDLE
		call	ObjCallInstanceNoLock
		mov	bx, ax

	; Lock the TransMapHeader and mark it dirty.

		call	LockTransFileMap_DS	; *ds:si = TransMapHeader
		mov	di, ds:[si]
		call	DBDirty_DS

	; Record the resource count in the TransMapHeader.

		mov	cx, ss:[bp].TFF_numResources
		mov	ds:[di].TMH_totalResources, cx
EC <		tst	cx						>
EC <		ERROR_Z		NO_RESOURCES				>

	; Initialize resource add loop.
		
		mov	ds:[di].TMH_arrayType, AT_RESOURCE_MAP
		clr	ax

	; Add new resources.

addResource:
		; ax 	= current resource number
		; cx 	= resources remaining to process
		; bx 	= file handle
		; ds:si	= map block

		push	ax
		call	AddNewResource
		mov	dx, ax			;save ErrorValue in dx
		pop	ax
		jc	done
		inc	ax
		loop	addResource

done:

	; Unlock the TransMapHeader

		call	DBUnlock_DS

	; Dereference document block.

		pop	bx, si
		call	MemDerefDS

	; Return possible error value.

		mov	ax, dx		;return possible ErrorValue in ax

		.leave
		ret

AllocResourceGroups		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNewResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new element to the passed map block. 
		Allocate a DBGroup for the resource and create a
		ResourceArray in it.

CALLED BY:	(INTERNAL) AllocResourceGroups

PASS:		*ds:si	- map block
		ax	- resource number
		^hbx	- file handle

RETURN:		ax	- new element token
		carry set if error (a resource was not added)
			ax - ErrorValue
DESTROYED:	dx,di,es

	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:
	Allocate a new group for the resource, and create a NameArray
	item in the group.  
	Create a name for the resource: Resource<N>, N = reource number.
	Add a ResourceMapElement to the ResourceMap.
	If the name already exists in the array, or the element cannot
	be added, free the group and item created for it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNewResource		proc	far
		uses	cx,si
element		local	ResourceMapData
SBCS <resName	local	MAX_NAME_LEN+1 dup (char)		>
DBCS <resName	local	MAX_NAME_LEN+1 dup (wchar)		>
	.enter

	; Put resource name in local variable.

		segmov	es, ss
		lea	di, ss:[resName]	; es:di <- resource name
		mov	dx, ax			; dx <-resource number
		mov	ax, offset ResourceName
		call	CreateName

	; Create a DBGroup for the resource.	

		call	DBGroupAlloc		;ax <- group

	; Fill in ResourceMapData fields.

		mov	ss:[element].RMD_group, ax	
		mov	ss:[element].RMD_number, dx
		clr	ss:[element].RMD_resourceType
		clr	ss:[element].RMD_numChunks

	; Allocate a ResourceArray for this resource.

		push	di
		mov	cx, size ResourceArrayHeader
		mov	dx, size ResourceArrayData
		call	AllocNameArray		;di <- ResourceArray item
		mov	ss:[element].RMD_item, di
		pop	di

	; Does our resource name already exist in the resource name array?
	
		clr	cx			;null-terminated name
		clr	dx			;don't return data
		call	NameArrayFind
		mov	ax, EV_NAME_EXISTS
		jc	error			;this name already exists!

	; Add our resource to the resource name array.

		push	bx
		clr	bx			; No NameArrayAddFlags
		mov	dx, ss
		lea	ax, ss:[element]	; dx:ax = data
		call	NameArrayAdd		; ax <- new element's token
		pop	bx
		jnc	error
		clc
done:
		.leave
		ret

error:	

	; Our resource name was already in the resource name array, so
	; delete the group we created.

		mov	ax, ss:[element].RMD_group
		call	DBGroupFree
		mov	ax, EV_NAME_ADD
		stc
		jmp	done

AddNewResource		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitResArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add elements to ResourceArrays for each chunk in 
		the resource, as read from the geode.

CALLED BY:	(EXTERNAL) ReadGeodeFile

PASS:		ss:bp	- TranslationFileFrame
		*ds:si	- document

RETURN:		carry set if error
			ax - ErrorValue

DESTROYED:	di
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitResArrays 		proc	far
		uses bx,dx,es
		.enter

EC <		cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG>
EC <		ERROR_NE  BAD_TRANSLATION_FILE_FRAME			>

	; Remember document for dereferencing.

		push	ds:[LMBH_handle],si

	; Lock the TransMapHeader.

		call	LockTransFileMap_DS

	; Get handle to the resource table.

		segmov	es, ss:[bp].TFF_handles, cx
EC <		cmp	es:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG	>
EC <		ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT			>
		mov	cx, es:[DHS_resourceTable]

	; Enumerate each resource, adding an element for each chunk in the
	; geode.

		mov	bx, cs
		mov	di, offset InitResArraysCallback
		mov	dx, ss:[bp].TFF_numResources
		call	ChunkArrayEnum

	; Unlock the TransMapHeader.

		call	DBUnlock_DS

	; Dereference document.

		pop	bx, si
		call	MemDerefDS

		.leave
		ret
InitResArrays	 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitResArraysCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the resource, and for each chunk add an element
		to the ResourceArray.

CALLED BY:	(INTERNAL) InitResArrays, via ChunkArrayEnum

PASS:		*ds:si  - ResourceMap (TransMapHeader)
		ds:di	- ResourceMapElement
		ss:bp	- TranslationFileFrame
		^hcx	- ResourceTable
		dx	- total number of resources in geode

RETURN:		carry set if FileRead or MemAlloc error
			ax - LoadResourceError
		or if AddChunkItemError
			ax - ErrorValue

DESTROYED:	
	ax,bx,si,di
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers to it.

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitResArraysCallback  	proc	far
	uses cx,dx
	.enter

		push	ds:[LMBH_handle]

	; Get this resource's number.

		call	ChunkArrayPtrToElement	; ax <- resource number

	; Load the resource into a block.

		call	LoadResource		; bx <- resource handle
		jc	noResource		; if error, continue
		cmp	ax, LRE_NOT_LMEM	; if not LMem, continue
		je	noResource
		cmp	ax, LRE_NO_HANDLES	; if no handles, continue
		je	noResource
EC <		call 	ECCheckMemHandle				>

	; Save the number of chunks in the map array element (and
	; there better be some, because this was checked in LoadResource)

		call	MyMemLock
		mov	es, ax
		mov	dx, es:[LMBH_nHandles]
EC <		tst	dx						>
EC <		ERROR_Z	NO_CHUNKS					>
		call	MemUnlock
		mov	ds:[di].RME_data.RMD_numChunks, dx

	; Allocate and add the items for each chunk to the ResourceArray

		mov	ax, ds:[di].RME_data.RMD_group
		mov	di, ds:[di].RME_data.RMD_item
		mov	cx, ss:[bp].TFF_transFile
		call	AddChunkItems	;carry set if error, ax = ErrorValue
		pushf	
		tst	bx
		call	MyMemFree	;it's no longer needed, free it
		popf
done:

	; Dereference the array.

		pop	bx
		call	MemDerefDS
		.leave
		ret

noResource:
	; either there was an error reading the resource into memory,
	; or the resource is not editable (not an LMem block, no handles)
	; If the latter is true, don't return an error.
	;
	tst	bx
	jz	noFree
	call	MyMemFree

noFree:
EC<	cmp	ax, LRE_HANDLE_TABLE_FULL			>
EC<	ERROR_E RESEDIT_INTERNAL_LOGIC_ERROR			>
	ornf	ds:[di].RME_data.RMD_resourceType, mask RT_NOT_EDITABLE
	mov	cx, EV_MEMALLOC
	cmp	ax, LRE_MEMALLOC
	je	error
	mov	cx, EV_FILE_READ
	cmp	ax, LRE_FILE_READ
	je	error
	clc
	jmp	done
error:
	mov	ax, cx
	stc	
	jmp	done

InitResArraysCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddChunkItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For each chunk in this resource, add an element to the 
		chunk name array.

CALLED BY:	(INTERNAL) InitResArraysCallback

PASS:		^hbx	- resource block handle
		^hcx	- file handle
		dx	- number of chunks to add
		ax	- resource group number
		di	- chunk array item number

RETURN:		carry set if error
			ax - ErrorValue

DESTROYED:	ax,cx,dx,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddChunkItems		proc	near
	uses	bx,si
resHandle	local	hptr		push bx
element		local	ResourceArrayData
SBCS <chunkName	local	MAX_NAME_LEN+1	dup (char)			>
DBCS <chunkName	local	MAX_NAME_LEN+1	dup (wchar)			>
	.enter

	; Lock the ResourceArray in DB item ax:di

		mov	bx, cx
		mov	cx, dx
		call	DBLock_DS		; ds:si <- name array
		call	DBDirty_DS

	; Initialize the ResourceArrayElement data with zeroes

		push	cx, di
		segmov	es, ss
		lea	di, ss:[element]
		mov	cx, size element
		clr	al
		rep	stosb
		pop	cx, di
		clr	dx

	; Lock the resource block and get a pointer to its handle table
	
		mov	bx, ss:[resHandle]
		call	ObjLockObjBlock
		mov	es, ax
		mov	di, es:[LMBH_offset]	;^ldi <- first chunk handle 
	
addChunk:

	; Re-initialize this to "unknown" type

		mov	ss:[element].RAD_chunkType, 0

	; Store the chunk number and handle in the element,
	; and create a default name 'Chunkn' where n = RAD_number

		mov	ss:[element].RAD_number, dx
		mov	ss:[element].RAD_handle, di
		mov	ax, offset ChunkName

	; Check if the chunk is free (ptr = 0) or 0 size (ptr = -1)

		mov	bx, ss:[resHandle]
		call	MemDerefES
if	ERROR_CHECK
	; Since this is compiled with .rcheck, ECCheckBounds dies on the
	; instruction below when the chunk handle is free and ECF_LMEM is on.
	; Therefore we need to disable ECF_LMEM temporarily.
		push	ax			;save old value
		call	SysGetECLevel		;ax = ErrorCheckFlags, bx=hptr
		push	ax			;save orig. ErroCheckFlags
		BitClr	ax, ECF_LMEM
		call	SysSetECLevel
endif	; ERROR_CHECK
		mov	di, es:[di]		;deref the chunk handle
if	ERROR_CHECK
		pop	ax			;ax = orig. ErrorCheckFlags
		call	SysSetECLevel
		pop	ax			;restore old value
endif	; ERROR_CHECK
		tst	di
		jz	invalid
		cmp	di, -1
		jne	createName

invalid:
		mov	ss:[element].RAD_chunkType, mask CT_NOT_EDITABLE

createName:

	; Create the default name for this chunk 'ChunkN'

		segmov	es, ss	
		lea	di, ss:[chunkName]
		call	CreateName		;es:di <- chunk name

	; Check if this name already exists.

		push	cx, dx
		clr	cx			;null-terminated name
		clr	dx			;don't return data
		call	NameArrayFind
		mov	ax, EV_NAME_EXISTS
		jc	error			;this name already exists!

	; Add our chunk to the array.

		clr	bx			; no flags
		mov	dx, ss	
		lea	ax, ss:[element]	; dx:ax = data to add
		call	NameArrayAdd		; ax <- name token
		cmc
		mov	ax, EV_NAME_ADD
		jc	error

chunkAdded::						; (For verbose.tcl)

	; Handle next chunk.

		pop	cx, dx
		mov	di, ss:[element].RAD_handle	;last handle
		add	di, size word			;next handle
		inc	dx
		loop	addChunk	
		clc

done:
	; Clean up.

		mov	si, ds:[si]
		mov	ds:[si].RAH_arrayType, AT_RESOURCE_ARRAY
		call	DBUnlock_DS		; unlock ResourceArray 
		mov	bx, ss:[resHandle]
		call	MemDerefDS		; deref the resource block
		call	MemUnlock		; unlock it

		.leave
		ret
error:
		pop	cx, dx
		jmp	done

AddChunkItems		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyLocToTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy localization file information into the translation
		file, resource by resouce, using ChunkArrayEnum.

CALLED BY:	(EXTERNAL) ReadLocalizationFile

PASS:		ss:bp	- TranslationFileFrame

RETURN:		carry set if unsuccessful
			ax - ErrrorValue

DESTROYED:	bx,cx,si,di,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyLocToTrans		proc	far

EC <		cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG >
EC <		ERROR_NE  BAD_TRANSLATION_FILE_FRAME			>

		mov	bx, ss:[bp].TFF_locFile
		call	DBLockMap_DS				;*ds:si <- LocArray
		mov	bx, cs
		mov	di, offset CopyLocToTransCallback
		call	ChunkArrayEnum
		call	DBUnlock_DS
		ret

CopyLocToTrans		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyLocToTransCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy localization information for this resource to the
		translation file.

CALLED BY:	CopyLocToTrans via ChunkArrayEnum
PASS:		*ds:si	- LocMap array
		ds:di	- LocMapElement
		ax	- element size
		ss:bp	- TranslationFileFrame

RETURN:		nothing
DESTROYED:	everything except bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyLocToTransCallback		proc	far
	.enter

EC<	cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG	>
EC<	ERROR_NE  BAD_TRANSLATION_FILE_FRAME				>
	push	ss:[bp].TFF_destGroup		; save ResourceMap group
	push	ds:[LMBH_handle]		; save LocMapArray handle
	segmov	es, ds, cx
	mov	cx, ax					; cx <- element size
	mov	ax, es:[di].LME_data.LMD_number		; ax <- resource number

	; Lock down the translation file's ResourceMap.
	call	LockTransFileMap_DS			; ds:si <- trans file map block

	; Look for this resource in the ResourceMap, if its not found,
	; just leave the information gathered from the Geode as is.
	;
	mov	bx, di
	call	FindResourceNumber		; ds:di <- ResourceMapElement
	jc	notFound
	call	ChunkArrayPtrToElement		; ax <- element number

	; Now replace the resource name with that from the Localization file
	;
	lea	di, es:[bx].LME_data.LMD_name	; es:di <- name
gotName::						; (For verbose.tcl)
	sub 	cx, size LocMapElement		; cx <- name size
DBCS <	shr	cx, 1				; cx <- name length	>
	call	NameArrayChangeName
	call	ChunkArrayElementToPtr		; ds:di <- possibly resized
						;  and moved element

	; Lock down the ResourceArray for this resource
	;
	push	bx
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBUnlock_DS			; unlock ResourceMap
	mov	ss:[bp].TFF_destGroup, ax
	mov	bx, ss:[bp].TFF_transFile
	call	DBLock_DS
	mov	bx, ds:[LMBH_handle]
	movdw	ss:[bp].TFF_destArray, bxsi	;
	pop	di				; es:di <- LocMapElement

	; Lock down the LocArray for this resource, and enumerate it
	; to copy all of its information to the elements in the 
	; ResourceArray.
	;
	push	bx				; save ResourceArray handle
	mov	ax, es:[di].LME_data.LMD_group
	mov	di, es:[di].LME_data.LMD_item
	mov	ss:[bp].TFF_sourceGroup, ax
	mov	bx, ss:[bp].TFF_locFile
	call	DBLock_DS			; *ds:si <- LocArray
	mov	bx, cs
	mov	di, offset CopyLocElement
	call	ChunkArrayEnum	
	call	DBUnlock_DS			; unlock LocArray
	pop	bx
	call	MemDerefES
	call	DBUnlock			; unlock ResourceArray

done:
	pop	bx				
	call	MemDerefDS			; restore LocMap segment
	pop	ss:[bp].TFF_destGroup		; restore ResMap group
	clc

	.leave
	ret

notFound:
	call	DBUnlock_DS			; unlock ResourceMap
	jmp	done

CopyLocToTransCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyLocElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy info from LocArray to ResourceArray for this chunk.

CALLED BY:	CopyLocToTransCallback via ChunkArrayEnum
PASS:		*ds:si	- LocArray
		ds:di	- LocArrayElement
		ax	- element size
		ss:bp	- TranslationFileFrame
			TFF_destArray = ResArray optr
			TFF_destGroup = its resource group number
			TFF_sourceGroup = LocArray group number
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyLocElement		proc	far
	.enter

	mov	cx, ax
	segmov	es, ds
	movdw	bxsi, ss:[bp].TFF_destArray
	call	MemDerefDS
	mov	ax, es:[di].LAE_data.LAD_number
	mov	bx, di
findChunk::						; (For verbose.tcl)
	call	FindChunkNumber			; ds:di <- ResArrayElement
	LONG	jc	done

	;
	; should really change name only *after* we've confirmed
	; these are really the same items.
	;
	call	ChunkArrayPtrToElement		; ax <- element number

	;
	; if this chunk is not localizable, delete it from the ResourceArray
	; 
	cmp	es:[bx].LAE_data.LAD_flags, 1
	LONG	je	notLocalizable

localizable::						; (For verbose.tcl)
	lea	di, es:[bx].LAE_data.LAD_name	; es:di <- name
	sub	cx, size LocArrayElement	; cx <- name size
DBCS <	shr	cx, 1				; cx <- name length	>
	call	NameArrayChangeName
	call	ChunkArrayElementToPtr		; ds:di <- possibly resized
						;  and moved element
	mov	si, bx				; es:si <- LocArrayElement
	
	mov	bl, mask CT_MONIKER
	mov	ax, es:[si].LAE_data.LAD_chunkType
	cmp	ax, CDT_visMoniker
	je	haveType

	mov	bl, mask CT_GSTRING
	cmp	ax, CDT_GString
	je	haveType

	mov	bl, mask CT_TEXT
	cmp	ax, CDT_text
	je	haveType
	clr	bl

haveType:						; bl == type stored in .loc
	test	ds:[di].RAE_data.RAD_chunkType, bl
	jz	done

	;
	; if marked as a text chunk in the loc file, we need to do an additional
	; check to see if our heuristic scanning misinterpreted this as a moniker.
	; if it did, make it a text chunk.

	test	bl, mask CT_TEXT
	jz	setSize

	test	ds:[di].RAE_data.RAD_chunkType, mask CT_MONIKER
	jz	setSize

	mov	ds:[di].RAE_data.RAD_chunkType, bl

setSize:
	mov	ax, es:[si].LAE_data.LAD_minSize
	mov	ds:[di].RAE_data.RAD_minSize, ax
	mov	ax, es:[si].LAE_data.LAD_maxSize
	mov	ds:[di].RAE_data.RAD_maxSize, ax
	mov	ax, es:[si].LAE_data.LAD_flags
	mov	ds:[di].RAE_data.RAD_instFlags, ax

	push	si
	mov	si, ss:[bp].TFF_destArray.chunk
	call	ChunkArrayPtrToElement		; ax <- element number
	pop	si

	push	ax, bp
	mov	bx, ss:[bp].TFF_locFile
	mov	ax, ss:[bp].TFF_sourceGroup
	mov	di, es:[si].LAE_data.LAD_instItem
	tst	di
	jz	noInstruction
	mov	cx, ss:[bp].TFF_destGroup
	mov	bp, ss:[bp].TFF_transFile
	call	DBCopyDBItem
	pop	ax, bp

	mov	dx, di
	movdw	bxsi, ss:[bp].TFF_destArray
	call	MemDerefDS
	call	ChunkArrayElementToPtr
	mov	ds:[di].RAE_data.RAD_instItem, dx

done:
	segmov	ds, es, ax			; ds <- LocArray segment
	clc

	.leave
	ret

noInstruction:
	pop	ax, bp
	jmp	done

notLocalizable:
	call	ChunkArrayDelete
	jmp	done

CopyLocElement		endp


DatabaseCode ends


