COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		mtask.asm

AUTHOR:		Paul L. DuBois, Sep 15, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB FIDODESTROYTASK		C stub for FidoDestroyTask

    GLB FIDOUSELIBRARY_AGG	C stub for FidoUseLibrary_Agg

    GLB FIDOUSELIBRARY_GEODE	C stub for FidoUseLibrary_Geode

    INT FindGeode_Callback	Find already-loaded library matching
				ss:[lib_name]

    GLB FIDOCLEANTASK		C stub for FidoCleanTask

    GLB FidoAllocTask		Allocate and initialize FidoTask block

    GLB FidoDestroyTask		Gracefully destroy a FidoTask block

    INT Fido_FreeGeodes		Gracefully destroy a FidoTask block

    INT freeLibrary_Callback	Gracefully destroy a FidoTask block

    EXT TaskLockDS		Lock ftask handle in bx into ds.

    EXT TaskUnlockDS		Unlock ftask pointed to by ds.

    EXT Fido_AddLibrary		Add an element to array of libraries

    EXT Fido_DestroyLibrary	Called on a LibraryData when it is being
				destroyed

    EXT Fido_AddLocalLibraryRef	Add to module's local array of loaded libs

    EXT Fido_AddGlobalLibraryRef
				Add to a FidoTask's global library array

    EXT Fido_AddDriver		Add to a FidoTask's driver array

    INT Fido_AllocHashTable	Allocate hash table for aggregate table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/15/94   	Initial revision

DESCRIPTION:
	Allocates/destroys fido tasks.

	$Id: mtask.asm,v 1.1 98/08/13 09:13:54 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include Internal/geodeStr.def

MainCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDODESTROYTASK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoDestroyTask

CALLED BY:	GLOBAL

C DECLARATION:	extern void _far _pascal
		    FidoDestroyTask(MemHandle ftask);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDODESTROYTASK	proc	far		ftask:hptr.FidoTask
	uses	es, di
	.enter
		mov	bx, ss:[ftask]
		call	FidoDestroyTask	; destroy bx
	.leave
	ret
FIDODESTROYTASK	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOUSELIBRARY_AGG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoUseLibrary_Agg

CALLED BY:	GLOBAL

C DECLARATION:	extern Boolean _far _pascal
		    FidoUseLibrary_Agg(FTaskHan ftaskHan,
				       ModuleToken using_module,
				       ModuleToken lib_module);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOUSELIBRARY_AGG	proc	far \
	task:hptr.FidoTask, using_module:word, lib_module:word
	uses	ds,si,di			;,es
	.enter
		mov	bx, ss:[task]
		call	TaskLockDS
	; *ds:si - array, ax - elt #.  stc if oob, cx - elt size, ds:di - elt
		mov	ax, ss:[lib_module]
		mov	si, ds:[FT_modules]
		call	ChunkArrayElementToPtr
EC <		ERROR_C	FIDO_INVALID_MODULE_TOKEN			>
		mov	bx, ds:[di].MD_myLibrary

	; If module doesn't have an associated library element
	; that means it hasn't exported any components
		
		cmp	bx, CA_NULL_ELEMENT
		je	errorDone

	; ds-ftask,bx-library to use
		mov	ax, bx
		mov	si, ds:[FT_libraries]
		call	ElementArrayAddReference

		mov	ax, ss:[using_module]
		call	Fido_AddLocalLibraryRef
		mov	ax, 1		; signal success
done:
		call	TaskUnlockDS
	.leave
	ret

errorDone:
		clr	ax, dx		; signal failure
		jmp	done
		
FIDOUSELIBRARY_AGG	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOUSELIBRARY_GEODE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoUseLibrary_Geode

CALLED BY:	GLOBAL

C DECLARATION:	extern Boolean _far _pascal
		    FidoUseLibrary_Agg(FTaskHan ftaskHan,
				       ModuleToken using_module,
				       TCHAR* lib_name);

PSEUDO CODE/STRATEGY:
	Look in already-loaded modules first, to avoid having
	to look on disk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
suffix_string	TCHAR	'.geo',C_NULL
suffix_len equ 5
	SetGeosConvention
FIDOUSELIBRARY_GEODE	proc	far \
	task:hptr.FidoTask, using_module:word, lib_name_ptr:fptr.TCHAR
	perm_name	local	GEODE_NAME_SIZE dup(char)
	file_name	local	DosDotFileName

	uses	ds,si,es,di
	.enter

	; Copy to SBCS string, pad to GEODE_NAME_SIZE chars with C_SPACE
	; 'cause that's the way name is stored in GeodeHeader.
		lds	si, ss:[lib_name_ptr]
		segmov	es, ss, ax
		lea	di, ss:[perm_name]
		lea	bx, ss:[file_name]
		mov	cx, GEODE_NAME_SIZE
copyLoop:		
		LocalGetChar	ax, dssi
		cmp	al, C_NULL
		je	afterLoop
		stosb
		LocalPutChar	esbx, ax
		loop	copyLoop
afterLoop:

	; Yuck -- also construct a filename by tacking on ec.geo or e.geo
	;
		xchg	bx, di
if ERROR_CHECK
		cmp	cx, 2
		jae	add_ec
		cmp	cx, 1
		je	add_e
		LocalPrevChar	esdi	; nuke last letter for the 'e'
add_e:
		LocalLoadChar	ax, C_SMALL_E
		LocalPutChar	esdi, ax
		jmp	add_geo
add_ec:
		LocalLoadChar	ax, C_SMALL_E
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_SMALL_C
		LocalPutChar	esdi, ax
endif
add_geo:
		segmov	ds, cs, ax
		mov	si, offset suffix_string
		mov_tr	ax, cx		; save old count
		mov	cx, suffix_len
		LocalCopyNString
		mov_tr	cx, ax		; restore

		xchg	bx, di

		mov	al, C_SPACE
		rep	stosb

		mov	bx, ss:[task]
		call	TaskLockDS

	;
	; 1. Look through already-used libraries to see if we can
	; avoid the overhead of a GeodeUseLibrary
	;
		mov	si, ds:[FT_libraries]
		mov	bx, cs
		mov	di, offset FindGeode_Callback
		call	ChunkArrayEnum	; stc if found, ax = lib elt
		jnc	try_useLibrary

		call	ElementArrayAddReference
		jmp	addRef

try_useLibrary:
	;
	; 2. Try a GeodeUseLibrary and see if that works
	; Token chars must be CoOL or BoOL
	;
		push	ds
		segmov	ds, ss, ax
		lea	si, ss:[file_name]
		clr	ax,bx		; don't care about protocol
		call	FidoPushDir
		call	GeodeUseLibrary	; bx <- geode
		lahf
		call	FilePopDir
		sahf
		pop	ds
		jc	errorDone

		call	MemLock
		mov	es, ax
		cmp	{word}es:GH_geodeToken.GT_chars, ('o' shl 8) or 'C'
		je	cmpRest
		cmp	{word}es:GH_geodeToken.GT_chars, ('o' shl 8) or 'B'
		jne	afterCmp
cmpRest:
		cmp	{word}es:GH_geodeToken.GT_chars[2], ('L' shl 8) or 'O'
afterCmp:
		lahf
		call	MemUnlock
		sahf
		jne	errorFree
	; success.  No need to EltArrayAddRef, as it's created with refct 1
		clr	ax		; no flags
		call	Fido_AddLibrary	; ax <- new lib elt

addRef:
	; All that, and now we can add the library to the module's list
	; ax <- found library elt
		mov_tr	bx, ax
		mov	ax, ss:[using_module]
		call	Fido_AddLocalLibraryRef
		mov	ax, 1		; signal success

done:
		call	TaskUnlockDS
	.leave
	ret
errorFree:
		call	GeodeFreeLibrary
errorDone:
		clr	dx, ax		; signal failure
		jmp	done
FIDOUSELIBRARY_GEODE	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindGeode_Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find already-loaded library matching ss:[perm_name]

CALLED BY:	INTERNAL FIDOUSELIBRARY_GEODE via ChunkArrayEnum
PASS:		*ds:si	- array
		ds:di	- elt
		stack	- inherited from caller
RETURN:		ax, stc	- set if found
DESTROYED:	can destroy bx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindGeode_Callback	proc	far
	uses	cx,dx,ds,es
	.enter inherit FIDOUSELIBRARY_GEODE

	; Since this is an element array, we can run across
	; free elements during the enum.  Ignore them.
		cmp	ds:[di].LD_meta.REH_refCount.WAAH_high, 0xff
		je	next

		test	ds:[di].LD_flags, mask LDF_AGGREGATE
		jnz	next

		call	ChunkArrayPtrToElement
		mov_tr	dx, ax		; save elt #

		mov	bx, ds:[di].LD_library
		call	MemLock

		mov	ds, ax
		mov	si, offset GH_geodeName
		segmov	es, ss, ax
		lea	di, ss:[perm_name]
		mov	cx, GEODE_NAME_SIZE
	; Don't DBCS-ize this.  It's always a byte compare
		repe	cmpsb

		lahf
		call	MemUnlock
		sahf

		jne	next

		mov_tr	ax, dx		; ax <- lib elt #
		stc
done:
	.leave
	ret
next:
		clc
		jmp	done
FindGeode_Callback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOCLEANTASK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoCleanTask

CALLED BY:	GLOBAL

C DECLARATION:	extern void _far _pascal
		    FidoCleanTask(FTaskHan fidoTask);

PSEUDO CODE/STRATEGY:
	Clean out the agg name -> rtask mapping, so we can use the
	FidoTask across "run"s in the builder.  Perhaps this should
	nuke FT_modules as well?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOCLEANTASK	proc	far \
	task:hptr
	uses	ds, si
	.enter
		mov	bx, ss:[task]
		call	TaskLockDS
		call	TaskUnlockDS
	.leave
	ret
FIDOCLEANTASK	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoAllocTask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize FidoTask block

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry	- set on error
		ax	- Newly allocated MemHandle, or garbage
DESTROYED:	nothing
SIDE EFFECTS:
	Allocates block of memory

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoAllocTask	proc	far
FIDOALLOCTASK	label	far
	uses	bx,cx,si,ds
	.enter
		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size FidoTask
		call	MemAllocLMem
		jc	done

		mov	al, mask HF_SHARABLE
		clr	ah
		call	MemModifyFlags
	
		call	MemLock
		mov	ds, ax
EC <		mov	ds:[FT_tag], FT_MAGIC_NUMBER			>
	; Allocate FT_modules
		mov	bx, size ModuleData
		mov	cx, size ModuleArrayHeader
		clr	si, ax
		call	ElementArrayCreate
		mov	ds:[FT_modules], si

	; Allocate FT_libraries
		mov	bx, size LibraryData
		mov	cx, size LibraryArrayHeader
		clr	si, ax
		call	ElementArrayCreate
		mov	ds:[FT_libraries], si

	; Allocate FT_drivers
		mov	cx, size ClientDrivers
		clr	ax
		call	LMemAlloc
		mov	ds:[FT_drivers], ax
		mov_tr	si, ax
		mov	si, ds:[si]
		clr	ds:[si].CDR_count
EC <		mov	ds:[si].CDR_unused, CDR_MAGIC_NUMBER		>

	; Allocate FT_globalLibs (ChunkArray of lptr)
		clr	ax, cx, si
		mov	bx, size lptr
		call	ChunkArrayCreate
		mov	ds:[FT_globalLibs], si
		
	; Allocate FT_aggHashTable
if 0
FIXME		call	Fido_AllocHashTable		

	; Allocate FT_aggregates
		clr	ax, bx, cx, si
		call	ChunkArrayCreate
		mov	ds:[FT_aggregates], si
endif
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		mov_tr	ax, bx
		clc
done:
	.leave
	ret
FidoAllocTask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoDestroyTask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gracefully destroy a FidoTask block

CALLED BY:	GLOBAL
PASS:		bx	- Block to destroy
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:
	Frees fido task.  This unloads any geodes that were dynamically
	loaded.

PSEUDO CODE/STRATEGY:
	FIXME: need to enum the module array & call driver close?
	most drivers won't be "open"?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoDestroyTask	proc	far
	uses	ax,cx,dx,ds,si
	.enter

		call	MemLock
		mov	ds, ax

		call	Fido_FreeGeodes

		mov	bx, ds:[LMBH_handle]
		call	MemFree
	.leave
	ret
FidoDestroyTask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fido_FreeGeodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gracefully destroy a FidoTask block

CALLED BY:	INTERNAL, FidoDestroyTask
PASS:		ds	- locked FidoTask
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx
SIDE EFFECTS:
	Makes a bunch of GeodeFree{Library,Driver} calls

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Fido_FreeGeodes	proc	near
	uses	si
	.enter

	; Call GeodeFreeLibrary on all the library handles
		mov	si, ds:[FT_libraries]
		mov	bx, cs
		mov	di, offset Fido_DestroyLibrary
		call	ChunkArrayEnum

	; Call GeodeFreeDriver on all the driver handles
		mov	si, ds:[FT_drivers]
		mov	si, ds:[si]
EC <		cmp	ds:[si].CDR_unused, CDR_MAGIC_NUMBER		>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>
		mov	cx, ds:[si].CDR_count
		add	si, offset CDR_data
		jcxz	fd_fallThru

freeDriver:
		lodsw
		mov_tr	bx, ax
		call	GeodeFreeDriver
		loop	freeDriver
fd_fallThru:

	.leave
	ret
Fido_FreeGeodes	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskLockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock ftask handle in bx into ds.

CALLED BY:	EXTERNAL
PASS:		bx	- fido task handle
RETURN:		ds	- locked block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskLockDS	proc	near
		push	ax
		call	MemLock
		mov	ds, ax

EC <		cmp	ds:[FT_tag], FT_MAGIC_NUMBER			>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>

		pop	ax
		ret
TaskLockDS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskUnlockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock ftask pointed to by ds.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskUnlockDS	proc	near
		push	bx
		mov	bx, ds:[LMBH_handle]

EC <		cmp	ds:[FT_tag], FT_MAGIC_NUMBER			>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>

		call	MemUnlock
		pop	bx
		ret
TaskUnlockDS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fido_AddLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element to array of libraries

CALLED BY:	EXTERNAL
PASS:		ds	- Locked FidoTask
		ax	- LibraryDataFlags
		bx	- GeodeHandle/RTaskHan if agg lib
RETURN:		ax	- index of new element
DESTROYED:	nothing
SIDE EFFECTS:	
	May move ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Fido_AddLibrary	proc	far
	data	local	LibraryData
	uses	bx,cx,dx,si,di
	.enter
EC <		test	ax, not (mask LDF_AGGREGATE or mask LDF_STATIC)	>
EC <		ERROR_NZ BARK_YELP_YELP					>

		mov	ss:[data].LD_flags, ax
		mov	ss:[data].LD_library, bx

		mov	ss:[data].LD_myModule, 0xcccc
		mov	ss:[data].LD_components, 0xcccc

		clr	ax,bx,di	; not variable, plain binary compare
		mov	cx, ss
		lea	dx, ss:[data]	; cx:dx <- data to add
		mov	si, ds:[FT_libraries]
		call	ElementArrayAddElement
	.leave
	ret
Fido_AddLibrary	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fido_DestroyLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called on a LibraryData when it is being destroyed

CALLED BY:	EXTERNAL
PASS:		ds:di	- LibraryData
		ax	- callback data
RETURN:		clc (to continue processing the enum)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Probably called by ElementArrayRemoveReference.  Also called
	from ChunkArrayEnum when we're destroying all our state.

	Free up any resources used by this element.  We keep a chunk
	around for aggregate libraries, and of course geodes must be
	Freed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Fido_DestroyLibrary	proc	far
	uses	ax, bx, si, di
	.enter
	; Since this is an element array, we can run across
	; free elements during the enum.  Ignore them.
		cmp	ds:[di].LD_meta.REH_refCount.WAAH_high, 0xff
		je	done

	; oh my god don't free libraries that we got from the core block
		test	ds:[di].LD_flags, mask LDF_STATIC
		jnz	done

		test	ds:[di].LD_flags, mask LDF_AGGREGATE
		jz	notAgg

		mov	ax, ds:[di].LD_components
		call	LMemFree
		mov	ds:[di].LD_components, 0xdead

		mov	ax, ds:[di].LD_myModule
		cmp	ax, CA_NULL_ELEMENT
		je	done

		mov	si, ds:[FT_modules]
		call	ChunkArrayElementToPtr
		mov	ds:[di].MD_myLibrary, CA_NULL_ELEMENT

		jmp	done

notAgg:
		mov	bx, ds:[di].LD_library
		call	GeodeFreeLibrary
		mov	ds:[di].LD_library, 0xdead
done:
		clc			; keep processing
	.leave
	ret
Fido_DestroyLibrary	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fido_AddLocalLibraryRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add to module's local array of loaded libs

CALLED BY:	EXTERNAL
PASS:		ds	- Locked FidoTask
		ax	- module token
		bx	- index of library to add

RETURN:		ds	- same block
DESTROYED:	nothing
SIDE EFFECTS:	
	May resize client block, invalidating segment pointers to it.
	May shuffle chunks around inside the client block.

PSEUDO CODE/STRATEGY:
	Used to implement new Fido behavior, where each module has
	a list of libraries to search.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Fido_AddLocalLibraryRef	proc	far
	uses	ax, si,di
	.enter
		mov	si, ds:[FT_modules]
		call	ChunkArrayElementToPtr
EC <		ERROR_C	FIDO_INVALID_MODULE_TOKEN			>
		mov	si, ds:[di].MD_localLibs

		call	ChunkArrayAppend
		mov	{word}ds:[di], bx

if 0
	; Most of the time the element is newly created
	; and already has a reference on it
		mov	si, ds:[FT_libraries]
		mov	ax, bx
		call	ElementArrayAddReference
endif
	.leave
	ret
Fido_AddLocalLibraryRef	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fido_AddGlobalLibraryRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add to a FidoTask's global library array

CALLED BY:	EXTERNAL
PASS:		ds	- locked FidoTask
		ax	- library index
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
	May resize block, invalidating segment pointers to it.
	May shuffle chunks around inside the client block.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Fido_AddGlobalLibraryRef	proc	far
	uses	si,di
	.enter
		mov	si, ds:[FT_globalLibs]
		call	ChunkArrayAppend	; ds always valid
						; after this call
		mov	{word}ds:[di], ax

if 0
	; Most of the time the element is newly created
	; and already has a reference on it
		mov	si, ds:[FT_libraries]
		call	ElementArrayAddReference
endif
	.leave
	ret
Fido_AddGlobalLibraryRef	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fido_AddDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add to a FidoTask's driver array

CALLED BY:	EXTERNAL
		FidoOpenModule
PASS:		ax	- driver handle
		bx	- hptr.FidoTask
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
	May resize client block, invalidating segment pointers to it.
	May shuffle chunks around inside the client block.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Fido_AddDriver	proc	far
	uses	ax,bx,cx,ds,si
	.enter
		call	TaskLockDS
		mov_tr	bx, ax		; bx <- driver

	; append a word to the chunk
		mov	ax, ds:[FT_drivers]
		ChunkSizeHandle	ds, ax, si
		mov	cx, si
		add	cx, 2
		call	LMemReAlloc
		
	; increment count and fill in the word
		mov_tr	si, ax
		mov	si, ds:[si]	; ds:si <- ClientModules
EC <		cmp	ds:[si].CDR_unused, CDR_MAGIC_NUMBER		>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>
		inc	ds:[si].CDR_count
		add	si, cx		; ds:si points to end of chunk
		mov	ds:[si-2], bx
		
		call	TaskUnlockDS
	.leave
	ret
Fido_AddDriver	endp

MainCode	ends
