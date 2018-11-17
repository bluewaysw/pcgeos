COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		geodesPatchCoreBlock.asm

AUTHOR:		Paul Canavese, Jan 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	(See geodesPatch.asm for an overview to the patching code.) 

INITIALIZE A GEODE PATCH

A geode's core block needs to be modified to allow patching to work
correctly.

If the geode in non-XIP and is just being loaded in, we reallocate the
core block (GeodePatchReAllocCoreBlock) and apply the patch
(GeodePatchCoreBlock). The rest of the work will be done 
automatically by the regular geode loading mechanism, which will call
our routines to read in the allocation flags for new resources and get 
the proper resource size for changed resources.

	GeodePatchReadAllocationFlags	Copy the allocation flags for
				any new resources onto the stack.
	GeodeGetPatchedResourceSize	Return the proper resource
				size of a resource, if it's patched.

If the geode was loaded into memory before the patch code had a chance
to run, all of the following routines must be run.

If the geode is XIP, all of the following routines must be called,
since the XIP loading code will not take care of it.

	GeodePatchModifyCoreBlock*	Modify a core block for an XIP
				geode, or any geode that is already in
				memory.
	-------------------------------------------------------------
	GeodePatchReAllocCoreBlock	Reallocate the core block
				larger to provide room for additional
				entry points and resources, if
				necessary.
	GeodePatchCoreBlock	Apply patch to the core block (if
				patch exists), and recalculate 
				pointers to geode tables if 
				resources were added.
	GeodePatchInitNewResources*	Allocate any resources that
				don't already exist for this geode
				(that only exist in the patched 
				version).
	GeodePatchPreLoadNewResources*	Preload resources that exist
				only in the patch file and are
				supposed to be preloaded (i.e. not
				discarded).
	GeodePatchRelocateNewExportEntries*	Relocate those
				parts of the export table that have
				been patched.

* These routines are in geodesPatchXIP.asm
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/27/95   	Initial revision


DESCRIPTION:
	Code to modify a geode's core block to allow patching. 
		
	$Id: geodesPatchCoreBlock.asm,v 1.1 97/04/05 01:12:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GLoad	segment	resource

if USE_PATCHES

if USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchReadAllocationFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the allocation flags for any new resources onto
		the stack

CALLED BY:	InitResources

PASS:		ss:dx - pointer to flags list
		ds - core block
		es - kdata

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/20/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchReadAllocationFlags	proc far

EC <		call	ECCheckCoreBlockDS				>
EC <		call	ECCheckDGroupES					>

		uses	es, di
		.enter

	; If there are no new resources, we're done.

		call	GeodeGetGeneralPatchBlock
			; es = Patch data segment.
		tst	es:[PDH_newResCount]
		jz	done

		mov	cx, es:[PDH_count]
		mov	si, offset PDH_resources
startLoop:
		mov	ax, es:[si].PRE_id
		cmp	ax, es:[PDH_origResCount]
		jb	next
		shl	ax
		mov	di, dx
		add	di, ax
		mov	ax, {word} es:[si].PRE_heapFlags
		mov	ss:[di], ax
next:
		add	si, size PatchedResourceEntry
		loop	startLoop

done:
		.leave
		ret
GeodePatchReadAllocationFlags	endp

endif ; USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeGetPatchedResourceSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the proper resource size of a resource, if it's
		patched. 

CALLED BY:	AllocateResource

PASS:		ds - core block
		si - resource number * 2
		ax - size of resource

RETURN:		ax - updated, if resource is patched

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/31/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeGetPatchedResourceSize	proc far
		uses	cx,si,es,di
		.enter

EC <		call	ECCheckCoreBlockDS				>

		shr	si			; Resource number.

if USE_BUG_PATCHES

tryGeneralPatches::
		tst	ds:[GH_generalPatchData]
		jz	tryLanguagePatches	; No general patches.
		call	GeodeGetGeneralPatchBlock
			; es = Patch data segment.
		mov	cx, es:[PDH_count]
		mov	di, offset PDH_resources

startLoopGeneral:
		cmp	si, es:[di].PRE_id
		je	found
		jb	tryLanguagePatches	; Since resources are stored
						; in order.

		add	di, size PatchedResourceEntry
		loop	startLoopGeneral
endif

tryLanguagePatches::

if MULTI_LANGUAGE

		tst	ds:[GH_languagePatchData]
		jz	done			; No language patches.
		mov	bx, ds:[GH_languagePatchData]
		call	MemDerefES
		mov	cx, es:[PDH_count]
		mov	di, offset PDH_resources

startLoopLanguage:
		cmp	si, es:[di].PRE_id
		je	found
		jb	done			; Since resources are stored
						; in order.

		add	di, size PatchedResourceEntry
		loop	startLoopLanguage
endif

done:
		.leave
		ret
found:
		add	ax, es:[di].PRE_resourceSizeDiff
		jmp	done
GeodeGetPatchedResourceSize	endp


if USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchReAllocCoreBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate the core block larger to provide room for
		additional entry points and resources, if necessary.

CALLED BY:	GeodeModifyCoreBlock, LoadGeodeAfterFileOpen,

PASS:		ds - segment of core block
		es - kdata

RETURN:		ds - segment of core block (may have moved)

DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 3/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchReAllocCoreBlock	proc far
		uses	es
		.enter
		
EC <		call	ECCheckCoreBlockDS				>
EC <		call	ECCheckDGroupES					>
	
	; Fetch original size of core block.
			
		LoadVarSeg	es, ax
		mov	ax, es:[bx].HM_size
		mov	cl, 4
		shl	ax, cl
		
	; Get the patch data.

		call	GeodeGetGeneralPatchBlock
			; es = Patch data segment.
	
	; Will the core block be patched?  (It would be the first entry,
	; since resources are stored in order.)

		tst	es:[PDH_resources].PRE_id
		jnz	done			; No core block changes.

	; See if core block size will change with the patch.
	
		mov	cx, es:[PDH_resources].PRE_resourceSizeDiff
		jcxz	done		; No change in # of resources.

	; Reallocate the core block to the new size.

		add	ax, cx
		mov	bx, ds:[GH_geodeHandle]
		mov	ch, mask HAF_ZERO_INIT or mask HAF_NO_ERR
		call	MemReAlloc
		mov	ds, ax

done:
		.leave
		ret
GeodePatchReAllocCoreBlock	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchCoreBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply patch to the core block (if patch exists), and
		recalculate pointers to geode tables if resources were
		added.

CALLED BY:	InitResources (for new, non-XIP geodes), 
		GeodeModifyCoreBlock (for all other geodes)

PASS:		ds - segment of core block

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/30/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchCoreBlock	proc far
		uses	ax,dx,di,es
		.enter

EC <		call	ECCheckCoreBlockDS				>
		
		mov	ax, ds
		mov	dx, ds:[GH_geodeHandle]

	; Does core block have a patch?  (It would be the first entry.)

		call	GeodeGetGeneralPatchBlock
			; es = Patch data segment.
		tst	es:[PDH_resources].PRE_id
		jnz	done			; No core block patch.

	; Apply the patch.

		mov	di, offset PDH_resources
		call	GeodePatchResourceFar

	; Recalculate the pointers to the resource position table,
	; relocation table size table, and extra library table.

		mov	ax, es:[PDH_newResCount]
		shl	ax
		add	ds:[GH_resPosOff], ax
		add	ds:[GH_resRelocOff], ax
		add	ds:[GH_extraLibOffset], ax
		
done:
		.leave
		ret
GeodePatchCoreBlock	endp

endif ; USE_BUG_PATCHES

endif ; USE_PATCHES

GLoad	ends

