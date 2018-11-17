COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		geodesPatchResource.asm

AUTHOR:		Paul Canavese, Jan 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	(See geodesPatch.asm for an overview to the patching code.) 

APPLY A PATCH TO A RESOURCE

When a resource is loaded in, check if there is patch data for
that resource.  If so, apply it.

	GeodePatchLoadResource	Load the resource, and see if patches
				need to be applied.
	-------------------------------------------------------------
	GeodeLoadPatchedResource	Make sure the resource block
				is big enough for patching, read in
				the resource from the geode file, 
				patch it, and resize the block to its
				final size.
	SearchPatchResourceList	Check each entry in the list for the
				resource being loaded.
	-------------------------------------------------------------
	GeodePatchInitLMemBlock	This is a hack to make "resedit"-
				produced files work on an EC system.
	GeodePatchResource	Patch a resource.
	-------------------------------------------------------------
	GeodePatchData		Apply some patches to a segment of
				code, relocations, etc.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/27/95   	Initial revision


DESCRIPTION:
	Code to facilitate the actual patching of a resource.
		

	$Id: geodesPatchResource.asm,v 1.1 97/04/05 01:12:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment

if USE_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchLoadResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the resource, and see if patches need to be
		applied. 

CALLED BY:	DoLoadResource

PASS:		ax - segment address of temporary block
		bx - handle of temporary block
		cx - size of resource
			if resource is dgroup, then this size doesn't
			include the udata size

		dx - handle of resource
		bp - handle of block that relocation is relative to (?)
		ds - core block of owner of resource
		si - resource number * 2

RETURN:		carry SET if relocations have been performed
		carry CLEAR otherwise (relocations should be loaded
			from the original geode)

DESTROYED:	bx, es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Locks the PatchedResourceList every time a resource is loaded
	-- is this too much overhead?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/17/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchLoadResource	proc near

passedBP	local	hptr	push	bp
tempBlock	local	hptr	push	bx	; Handle of resource
						; block.
		.enter

	; Streamlined for no patches...

if USE_BUG_PATCHES

tryGeneralPatchList::

	; Are there any general patches?

		tst	ds:[GH_generalPatchData]
		jnz	searchGeneralPatchList
endif

tryLanguagePatchList::

if MULTI_LANGUAGE

	; Are there any language patches?

		tst	ds:[GH_languagePatchData]
		jnz	searchLanguagePatchList

noPatchDataFound:

endif
	; No patch data found for this resource... just load
	; in the resource normally.

		call	LoadResourceDataFar
		clc			; Use normal relocations

exit:
		.leave
		ret			; <---  EXIT HERE!

if USE_BUG_PATCHES
searchGeneralPatchList:

		mov	bx, ds:[GH_generalPatchData]
			; si = twice the resource number being loaded.
		call	SearchPatchResourceList
		jnc	found
		jmp	tryLanguagePatchList
endif

if MULTI_LANGUAGE
searchLanguagePatchList:

		mov	bx, ds:[GH_languagePatchData]
			; si = twice the resource number being loaded.
		call	SearchPatchResourceList
		jc	noPatchDataFound
endif

found::
		push	bx, bp
		mov	bx, ss:[tempBlock]
		mov	bp, ss:[passedBP]
		call	GeodeLoadPatchedResource
		pop	bx, bp

	; Unlock the patch data
		
		call	NearUnlock
		jmp	exit
		
GeodePatchLoadResource	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeLoadPatchedResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the resource block is big enough for
		patching, read in the resource from the geode file,
		patch it, and resize the block to its final size.

CALLED BY:	GeodePatchLoadResource

PASS:		ax - segment address of temporary block
		bx - handle of temporary block
			temporary block is the size that it will be
			after patching occurs.
		cx - size of resource
			if resource is dgroup, then this size doesn't
			include the udata size

		dx - handle of resource
		bp - handle of block that relocation is relative to (?)
		ds - core block of owner of resource
		si - resource number * 2
		es:di - PatchedResourceEntry
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeLoadPatchedResource	proc	near
	uses	bx,cx,dx,si,di,bp

passedBP	local	hptr	push	bp
resourceSize	local	word	push	cx	; Size of the resource
						; before patching.
reAllocSize	local	word	push	cx	; Size to reallocate
						; the resource block
						; to after patching.
		.enter

	; Is this resource dgroup? 

		cmp	si, 2
		jne	notDgroup

	; Resource is dgroup.  Remember the current size of the
	; resource block, so we can reallocate the resource block to
	; it later (cx does not account for udata).

		push	ax, ds
		LoadVarSeg	ds, ax
		call	GetByteSize		; ax, cx = size
		mov	ss:[reAllocSize], ax
		pop	ax, ds

notDgroup:

	; Check if more room is needed to apply the patches than we
	; currently have.

		cmp	cx, es:[di].PRE_maxResourceSize
		jae	afterReAlloc		; Enough space already.

reAlloc::

	; Reallocate the resource to the maximum space needed while
	; patching this resource.

		mov	ax, es:[di].PRE_maxResourceSize
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc

afterReAlloc:

	; Determine size of resource to load from original file.

		mov	cx, ss:[resourceSize]
			; cx = original size of resource.

	; If size is zero, this is a new resource (nothing to load).

		jcxz	afterLoad		; Resource is new.

	; Load the original version of the resource from the geode file.

		call	LoadResourceDataFar

afterLoad:

	; Perform the patches on the resource.

		push	bp
		mov	bp, ss:[passedBP]
		call	GeodePatchResource
		pop	bp
		pushf			; Remember if we did relocations.

	; Now restore the resource to its normal size. Since the block
	; is still locked, we'll get its address back in AX

		mov	ax, ss:[reAllocSize]
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc

		call	GeodePatchInitLMemBlock				

		popf			; Remember if we did relocations.
		
		.leave
		ret
GeodeLoadPatchedResource	endp


if FULL_EXECUTE_IN_PLACE and MULTI_LANGUAGE

GeodeLoadPatchedResourceFar proc far
		call	GeodeLoadPatchedResource
		ret
GeodeLoadPatchedResourceFar endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchPatchResourceList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check each entry in the list for the resource
		being loaded.

CALLED BY:	GeodePatchLoadResource
PASS:		bx	= handle of patch data list
		si	= twice the resource number being loaded

RETURN:		if resource is found,
			carry clear
			es = patch data (LOCKED)
			di = matching entry
		else
			carry set

DESTROYED:	es, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchPatchResourceList	proc	far
		uses	ax, bx, cx, ds, si
		.enter

	; Search the lock the patch list.

		call	NearLock
		mov	es, ax

	; Prepare search loop.

		mov_tr	ax, si		; Twice the resource number.
		shr	ax		; Resource number.
		mov	cx, es:[PDH_count]
		mov	si, offset PDH_resources

startLoop:

	; Check each entry for our resource.

		cmp	ax, es:[si].PRE_id
		je	found		; This is the resource.
		add	si, size PatchedResourceEntry
		loop	startLoop

	; Not found... unlock patch list.

		call	NearUnlock
		stc
		jmp	exit

found:
		mov	di, si		; Offset of matching entry.
exit:
		.leave
		ret
SearchPatchResourceList	endp

endif ; USE_PATCHES

kcode	ends

GLoad	segment	resource

if USE_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchInitLMemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a hack to make "resedit"-produced files work
		on an EC system.

CALLED BY:	GeodeLoadPatchedResource

PASS:		ss:bp - inherited local vars
		ax - address of temporary block
		bx - handle of temp block
		dx - resource handle

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/22/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchInitLMemBlock	proc far
		uses	ax,bx,dx,ds
		.enter

		push	bx
		mov	bx, dx
		LoadVarSeg	ds, dx
		test	ds:[bx].HM_flags, mask HF_LMEM
		pop	bx
		jz	done

		mov	dx, ax		; resource segment
		mov_tr	ax, bx		; handle

done:
		.leave
		ret
GeodePatchInitLMemBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Patch a resource

CALLED BY:	GeodePatchLoadResource, GeodePatchCoreBlock

PASS:		ax - segment address at which to load resource
		dx - handle of resource
		ds - core block
		es - PatchDataHeader
		es:di - PatchedResourceEntry for patch data

RETURN:		carry SET if relocations loaded from patch file,
		carry CLEAR otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/17/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchResource	proc far
		uses	ax,bx,cx,dx,di,si

passedBP		local	word	push	bp
resourceSegment		local	sptr	push	ax
resourceHandle		local	hptr	push	dx
coreBlock		local	sptr.GeodeHeader	  push	ds
patchedResourceEntry	local	fptr.PatchedResourceEntry push	es, di
patchBlock		local	hptr
patchBlockSeg		local	sptr
relocBlock		local	hptr
		
		.enter

	; Allocate a block in which to read the patch data.
		
		mov	ax, es:[di].PRE_size
		push	ax			; Resource patch size.

		add	ax, es:[di].PRE_relocSize
		push	ax				; Total size.

		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAllocFar
		mov	ds, ax
		mov	ss:[patchBlock], bx
		mov	ss:[patchBlockSeg], ax

	; Load the patch data from the patch file.
		
		mov	al, FILE_POS_START
		movdw	cxdx, es:[di].PRE_pos
		mov	bx, es:[PDH_fileHandle]
		call	FilePosFar

		clr	dx
		pop	cx				; Total size.
		mov	al, FILE_NO_ERRORS
		call	FileReadFar
	
	; Apply the patches.
	
		mov	dx, es:[di].PRE_maxResourceSize
		mov	es, ss:[resourceSegment]
		mov	bx, ss:[resourceHandle]

		pop	cx			; resource patch size
		clr	si
		call	GeodePatchData		; ds:si now points to
						; reloc patches.

	; Now that all patches have been applied, apply the
	; relocations.  If there are no relocations in the patch file,
	; then relocations will be done normally.

		les	di, ss:[patchedResourceEntry]
		mov	ax, es:[di].PRE_relocSize
		tst	ax			; clears carry
		LONG jz	doneFree
		
patchReloc::
	
	; Allocate a block to hold the relocations, using the size
	; stored in the PatchedResourceEntry.
	  
		mov	ds, ss:[coreBlock]
		mov	ax, es:[di].PRE_maxRelocSize
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAllocFar
		mov	ss:[relocBlock], bx
		push	ax			; Relocation block segment.

if FULL_EXECUTE_IN_PLACE

	; Is this an XIP resource?  If so, there are no old relocations.

		test	ds:[GH_geodeAttr], mask GA_XIP
		jnz	afterRead
endif
	; Is this is a new resource?  If so, there are no old relocations.

		mov	bx, es:[di].PRE_id
		cmp	bx, es:[PDH_origResCount]
		jae	afterRead
		
	; Read in the old relocation table from the geode file.

		shl	bx
		add	bx, ds:[GH_resRelocOff]
		mov	cx, ds:[bx]		; Old relocation size.
		mov	bx, ds:[GH_geoHandle]	; Handle to .GEO file.
		mov	ds, ax
		clr	dx			; Destination block.
		mov	al, FILE_NO_ERRORS
		call	FileReadFar

afterRead:

	; Patch the old relocation table.

		mov	cx, es:[di].PRE_size
		add	cx, es:[di].PRE_relocSize	; End of reloc patches.
		mov	dx, es:[di].PRE_maxRelocSize	; Size of reloc block.

		pop	es				; Relocation block.
		mov	ds, ss:[patchBlockSeg]		; Patch information.
		call	GeodePatchData

	; Prepare for performing the relocations.

		segmov	ds, es				; Relocation block.
		mov	es, ss:[resourceSegment]
		clr	si

	; Perform the relocations.

relocLoop:
		mov	ax, {word} ds:[si].GRE_info
		mov	bx, ds:[si].GRE_offset

		push	ds, bp, dx, si
		mov	ds, ss:[coreBlock]
		mov	cx, ss:[resourceHandle]
		mov	bp, ss:[passedBP]
		call	DoRelocation
		pop	ds, bp, dx, si
		add	si, size GeodeRelocationEntry
		cmp	si, dx
		jb	relocLoop

		mov	bx, ss:[relocBlock]
		call	MemFree
		
		stc			; signal - relocations handled

doneFree:
		mov	bx, ss:[patchBlock]
		pushf
		call	MemFree
		popf
		mov	ds, ss:[coreBlock]
		.leave
		ret

		
GeodePatchResource	endp

GeodePatchResourceFar	proc	far
		call	GeodePatchResource
		ret
GeodePatchResourceFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply some patches to a segment of code, relocations,
		etc. 

CALLED BY:	GeodePatchResource

PASS:		es - segment to which to apply patches
		dx - size of segment
		ds:si - array of PatchElement structures
		ds:cx - pointer to end of array

RETURN:		ds:si - points at first PatchElement after this group

DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:	

SIDE EFFECTS:	Do not operate heavy machinery after reading this
		routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/24/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchData	proc near

patchLoop:
		mov	ax, ds:[si].PE_flags
		Assert record	ax PatchFlags
		
		mov	bx, ax
		andnf	bx, mask PF_TYPE
	
	; Rotating left 3 times is probably faster than shifting right
	; 13 times...
		
		CheckHack <offset PF_TYPE eq 14>
		rol	bx
		rol	bx
		rol	bx
		
		push	si, cx
		call	cs:patchTable[bx]	; bx <- patch size
		pop	si, cx
patchNext::		
		lea	si, ds:[si][bx][size PatchElement]
		
		cmp	si, cx
		jb	patchLoop
		ret
		
;;----------------------------------------
patchReplace:
		mov	di, ds:[si].PE_pos
		mov	ax, ds:[si].PE_flags
		mov	cx, ax
		andnf	cx, mask PF_SIZE
		andnf	ax, mask PF_TYPE

		cmp	ax, PT_INSERT_ZERO shl offset PF_TYPE
		je	insertZero
		
		mov	bx, cx			; return size
		lea	si, ds:[si].PE_data

EC <		call	checkRepMovsb					>
		rep	movsb

replaceDone:
		retn
;;----------------------------------------
insertZero:
		clr	ax, bx
		Assert	okForRepScasb
		; (really Assert okForRepStosb!)
		
		rep	stosb
		jmp	replaceDone
		
		
;;----------------------------------------
patchDelete:
		mov	di, ds:[si].PE_pos
		andnf	ax, mask PF_SIZE
		
		mov	si, di
		add	si, ax

		mov	cx, dx			; segment size
		sub	cx, si
		push	ds
		segmov	ds, es

EC <		call	checkRepMovsb					>
		rep	movsb
		clr	bx			; return size
		pop	ds
		retn

;;----------------------------------------
patchInsert:
	; ax - size
		
		andnf	ax, mask PF_SIZE
		mov	bx, ds:[si].PE_pos	; source
	;
	; # bytes to move = ResourceSize - Position - insert count
	;

		mov	cx, dx			; segment size
		sub	cx, bx
EC <		ERROR_Z PATCH_FILE_ERROR				>
		sub	cx, ax
EC <		ERROR_S PATCH_FILE_ERROR				>
	
	; If it's an insertion at the end, then there's nothing to move
	
		LONG jz	patchReplace

		push	ds, si			; PatchElement
		mov	si, bx
		add	si, cx
		dec	si

		mov	di, bx
		add	di, ax			; dest
		add	di, cx
		dec	di

		segmov	ds, es

		Assert	fptr	dssi
		Assert	fptr	esdi

		std
		rep	movsb
		cld

		pop	ds, si			; PatchElement
		jmp	patchReplace

patchTable	nptr.near	\
		patchReplace,
		patchDelete,
		patchInsert,
		patchInsert

if ERROR_CHECK
checkRepMovsb:
;		Assert	okForRepMovsb
		retn
endif
		
GeodePatchData	endp


endif ; USE_PATCHES

GLoad 	ends
