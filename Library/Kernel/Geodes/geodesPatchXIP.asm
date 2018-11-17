COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel	
FILE:		geodesPatchXIP.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

	(See geodesPatch.asm for an overview to the patching code.) 

If the geode is XIP, all of the following routines must be called,
since the XIP loading code will not take care of it.

	GeodePatchModifyCoreBlock	Modify a core block for an XIP
				geode, or any geode that is already in
				memory.
	-------------------------------------------------------------
	GeodePatchReAllocCoreBlock*	Reallocate the core block
				larger to provide room for additional
				entry points and resources, if
				necessary.
	GeodePatchCoreBlock*	Apply patch to the core block (if
				patch exists), and recalculate 
				pointers to geode tables if 
				resources were added.
	GeodePatchInitNewResources	Allocate any resources that
				don't already exist for this geode
				(that only exist in the patched 
				version).
	GeodePatchPreLoadNewResources	Preload resources that exist
				only in the patch file and are
				supposed to be preloaded (i.e. not
				discarded).
	GeodePatchRelocateNewExportEntries	Relocate those
				parts of the export table that have
				been patched.

* These routines are in geodesPatchCoreBlock.asm

	GeodePatchXIPGeode	Patch an XIP geode that's in the
				process of being loaded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/21/94   	Initial version.
	PJC	1/26/95		Major revision, added multi-language
				support.

DESCRIPTION:
	Routines for patching XIP geodes.

	$Id: geodesPatchXIP.asm,v 1.1 97/04/05 01:12:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GLoad	segment	resource

if USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchModifyCoreBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify a core block for an XIP geode, or any
		geode that is already in memory.

CALLED BY:	PatchRunningGeodeCB, GeodePatchXIPGeode

PASS:		ds - segment of core block
			ds:[GH_generalPatchData] contains handle of locked
			PatchDataHeader

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchModifyCoreBlock	proc far
		.enter

	; First, reallocate the core block if the patch will add
	; resources or entry points.

		LoadVarSeg	es, ax
		push	es
		call	GeodePatchReAllocCoreBlock
	
	; Make any necessary changes to the core block.
		
		call	GeodePatchCoreBlock

	; Initialize any new resources (added by the patch).
	;   Initialize = assign a handle, and if it should be
	;   preloaded, allocate space for it.

		call	GeodePatchInitNewResources
		
	; Pre-load any of these new resources.

		call	GeodePatchPreLoadNewResources		

	; Relocate any entries in the export table that were changed
	; by the patch. 

		pop	es
		call	GeodePatchRelocateNewExportEntries

		.leave
		ret
GeodePatchModifyCoreBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchInitNewResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate any resources that don't already exist for
		this geode (ie, that only exist in the patched version).

CALLED BY:	INTERNAL: GeodePatchModifyCoreBlock

PASS:		ds - core block
		es - kdata

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/21/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchInitNewResources	proc near

EC <		call	ECCheckCoreBlockDS				>
EC <		call	ECCheckDGroupES					>

		uses	ds, es
		.enter

		call	GeodeGetGeneralPatchBlock		
			; es = Patch data block.
		mov	cx, es:[PDH_count]
		mov	di, offset PDH_resources
		mov	bx, ds:[GH_resHandleOff]
initLoop:

	; Check if a handle already exists for this resource.  If so,
	; skip it.

		mov	si, es:[di].PRE_id
		shl	si			; resId*2
		tst	<{word} ds:[si][bx]>
		jnz	next

	; Allocate a handle for the resource, and if it should be
	; pre-loaded, allocate space for it.

		push	cx, es
		mov	ax, es:[di].PRE_resourceSizeDiff
		mov	cx, {word} es:[di].PRE_heapFlags
		LoadVarSeg	es
		call	AllocateResource
		pop	cx, es

next:
		add	di, size PatchedResourceEntry
		loop	initLoop

		.leave
		ret
GeodePatchInitNewResources	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchPreLoadNewResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Preload resources that exist only in the patch file
		and are supposed to be preloaded (ie, not discarded).

CALLED BY:	GeodePatchModifyCoreBlock

PASS:		ds - segment of core block

RETURN:		nothing 

DESTROYED:	ax,bx,dx,dx,si,di,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/21/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchPreLoadNewResources	proc near
		.enter

EC <		call	ECCheckCoreBlockDS				>

		call	GeodeGetGeneralPatchBlock
			; es = Patch data block.
		clr	di
		mov	cx, es:[PDH_count]

resourceLoop:
		; Is this a new resource?  If not, look at the next one.

		mov	ax, es:[di].PRE_id
		cmp	ax, es:[PDH_origResCount]
		jae	next			; Not a new resource.

		; Get the handle of the resource.

		shl	ax
		add	ax, ds:[GH_resHandleOff]
		mov_tr	bx, ax
		mov	bx, ds:[bx]		; Resource handle.

		push	ds			; Core block.
		LoadVarSeg	ds, ax

		test	es:[di].PRE_heapFlags, mask HF_FIXED
		jnz	loadIt			; Not fixed.

		call	FarFullLockNoReload
		jc	popDS			; Error on lock.
loadIt:
		push	cx
		mov	ax, ds:[bx].HM_addr
		mov	cx, bx
		call	LoadResourceLow
		pop	cx

		test	es:[di].PRE_heapFlags, mask HF_FIXED
		jnz	popDS

		call	MemUnlock
popDS:
		pop	ds			; Core block.
next:
		loop	resourceLoop

		.leave
		ret
GeodePatchPreLoadNewResources	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchRelocateNewExportEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate those parts of the export table that have
		been patched.

CALLED BY:	GeodePatchModifyCoreBlock

PASS:		ds - core block
		es - kdata

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Since the patches are stored from high to low order, but there
	may be insertions and deletions, we need to go in reverse,
	keeping track of the amount by which patch elements that are
	later in the block are shifted.

	For example, if the following patch elements are found:

	(Type: REPLACE, Pos: 200, Size: 4)
	(Type: INSERT, Pos: 100, Size: 20)

	then we know that the first patch is actually at position 220,
	not 200, and must act accordingly.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchRelocateNewExportEntries	proc near
		uses	ax,bx,cx,dx,di,si,ds,es

patchBlock	local	hptr
patchOffset	local	word
patchSize	local	word
		
		.enter
	
EC <		call	ECCheckCoreBlockDS				>
EC <		call	ECCheckDGroupES					>

	; If the first resource in the patch list isn't the core
	; block, then we're done!

		call	GeodeGetGeneralPatchBlock
			; es = Patch data block.
		tst	es:[PDH_resources][PRE_id]
		jz	continue
		.leave
		ret
continue:
	
	; Allocate a block to load the core block patch data.
	
		push	ds			; Core block.
		mov	ax, es:[PDH_resources].PRE_size
		mov	cx, ALLOC_FIXED or (mask HAF_NO_ERR shl 8)
		call	MemAllocFar
		mov	ds, ax
		mov	ss:[patchBlock], bx
	
	; Find the start of data in the patch file.
		
		mov	al, FILE_POS_START
		movdw	cxdx, es:[PDH_resources].PRE_pos
		mov	bx, es:[PDH_fileHandle]
		call	FilePosFar

	; Load it in.
		
		clr	dx
		mov	cx, es:[PDH_resources].PRE_size
		mov	ss:[patchSize], cx
		mov	al, FILE_NO_ERRORS
		call	FileReadFar
		segmov	es, ds
		pop	ds			; Core block.
	
	; Look through each patch to see if it falls inside the export
	; table, and if so, see which entries to relocate.

		mov	ax, ds:[GH_exportLibTabOff]
		add	ax, 2		; point to the first segment
					; in the table
		
		mov	bx, ds:[GH_resHandleOff]	; end of table
		clr	si, ss:[patchOffset]

		call	processPatch
		mov	bx, ss:[patchBlock]
		call	MemFree
		.leave
		ret

;;------------------------------
;; Recursive routine to process patches in reverse order
		
processPatch:
	; 	es:si - current patch
	;	ax - start of export table
	;	bx - end of export table
	;
		cmp	si, ss:[patchSize]
		jae	done

		push	si
		mov	dx, es:[si].PE_flags
		andnf	dx, mask PF_TYPE
		cmp	dx, PT_INSERT shl offset PF_TYPE
		je	addSize
		cmp	dx, PT_REPLACE shl offset PF_TYPE
		jne	addPESize
addSize:
		add	si, es:[si].PE_flags
addPESize:
		add	si, size PatchElement

	; First, process the NEXT patch
	;
		call	processPatch
		pop	si

	;
	; Now, do this one. Adjust the position by the offset that we
	; updated by processing the next patch before this one.
	;
		mov	dx, es:[si].PE_pos
		add	dx, ss:[patchOffset]
		cmp	dx, ax
		jb	fixupOffset
		
		cmp	dx, bx
		jae	done
	;
	; This patch lies inside the export table, so relocate what
	; needs relocating
	;
		mov	di, dx			; start of patch

		mov	dx, es:[si].PE_flags
		andnf	dx, mask PF_SIZE
		add	dx, di			; end of patch

	;
	; Point to the appropriate segment address.
	;
		
		sub	di, ax
		add	di, 2
		andnf	di, 0xFFFC		; strip off low 2 bits
		add	di, ax
convertLoop:
		call	ConvertIDToSegment
		add	di, 4
		cmp	di, dx
		jb	convertLoop
fixupOffset:
	; If this is an INSERT or DELETE patch, then fixup the offset
	; appropriately.
		mov	cx, es:[si].PE_flags
		mov	dx, cx
		andnf	cx, mask PF_TYPE
		andnf	dx, mask PF_SIZE
		cmp	cx, PT_REPLACE shl offset PF_TYPE
		je	done
	;
	; for an INSERT or INSERT_ZERO, do an add, otherwise subtract
	;
		cmp	cx, PT_DELETE shl offset PF_TYPE
		jne	doAdd
		neg	dx
doAdd:
		add	ss:[patchOffset], dx
done:
		retn
		
GeodePatchRelocateNewExportEntries	endp

endif	; USE_BUG_PATCHES

if FULL_EXECUTE_IN_PLACE and USE_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchXIPGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Patch an XIP geode that's in the process of being loaded.

CALLED BY:	LoadXIPGeodeWithHandle

PASS:		ss:bp - inherited local vars
		ds - core block
		es - kdata

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/25/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchXIPGeode	proc near

EC <		call	ECCheckCoreBlockDS				>
EC <		call	ECCheckDGroupES					>

		.enter	inherit LoadXIPGeodeWithHandle

	; Open a patch file for this geode, if such there be.
		
if USE_BUG_PATCHES
		lea	di, ss:[execHeader].EFH_udataSize
		call	GeodeOpenGeneralPatchFile
endif
if MULTI_LANGUAGE
		call	IsMultiLanguageModeOn
		jc	afterLanguageStuff
		call	GeodeOpenLanguagePatchFile

afterLanguageStuff:
endif

if USE_BUG_PATCHES

	; If there is no general patch data, we are done.

		tst	ds:[GH_generalPatchData]
		jz	done

	; Reallocate the core block, patch it, initialize and load in
	; any appropriate new resources, and relocate the export table.

		call	GeodePatchModifyCoreBlock
endif

done:
		.leave
		ret
GeodePatchXIPGeode	endp

endif ; FULL_EXECUTE_IN_PLACE and USE_BUG_PATCHES

GLoad	ends


