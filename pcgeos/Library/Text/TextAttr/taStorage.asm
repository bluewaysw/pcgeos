COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		taStorage.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/92		Initial version

DESCRIPTION:

	$Id: taStorage.asm,v 1.1 97/04/07 11:18:54 newdeal Exp $

------------------------------------------------------------------------------@

TextInstance segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextCreateStorage -- MSG_VIS_TEXT_CREATE_STORAGE
					for VisTextClass

DESCRIPTION:	Create storage structures for a text object.  Note that
		additional levels of attribute storage can only be *set*.

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cl - VisTextStorageFlags to set
	ch - non-zero to create regions

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/22/92		Initial version

------------------------------------------------------------------------------@
VisTextCreateStorage	proc	far	; MSG_VIS_TEXT_CREATE_STORAGE
	class	VisLargeTextClass

EC <	test	cl, not (mask VTSF_MULTIPLE_CHAR_ATTRS or \
			 mask VTSF_MULTIPLE_PARA_ATTRS or \
			 mask VTSF_TYPES or mask VTSF_GRAPHICS or \
			 mask VTSF_STYLES)				>
EC <	ERROR_NZ VIS_TEXT_ILLEGAL_BITS_TO_SET				>
EC <	test	cl, ds:[di].VTI_storageFlags				>
EC <	ERROR_NZ VIS_TEXT_ILLEGAL_BITS_TO_SET				>

	;VisTextMaxParaAttr is 250+ bytes, so we should borrow some stack
	;space here.

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di
	sub	sp, size VisTextMaxParaAttr
	mov	bp, sp

	test	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	jz	noCharAttrs

	; *** char attrs ***

	call	GetSingleCharAttr

	; allocate an empty run and element structure

	mov	bl, TAT_CHAR_ATTRS
	call	createArraysForObject		;ax = run
	mov	ds:[di].VTI_charAttrRuns, ax
	ornf	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	andnf	ds:[di].VTI_storageFlags, not mask VTSF_DEFAULT_CHAR_ATTR

	mov	bx, offset VTI_charAttrRuns
	call	addElementAndInsertRun
noCharAttrs:

	test	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	noParaAttrs

	; *** para attrs ***

	call	GetSingleParaAttr

	; allocate an empty run and element structure

	mov	bl, TAT_PARA_ATTRS
	call	createArraysForObject		;ax = run
	mov	ds:[di].VTI_paraAttrRuns, ax
	ornf	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	andnf	ds:[di].VTI_storageFlags, not mask VTSF_DEFAULT_PARA_ATTR

	mov	bx, offset VTI_paraAttrRuns
	call	addElementAndInsertRun
noParaAttrs:

	; *** types ***

	test	cl, mask VTSF_TYPES
	jz	noTypes

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bh, ds:[di].VTI_storageFlags
	and	bh, mask VTSF_LARGE
	pushf
	call	TA_CreateNameArray
	popf
	jz	5$				;z flag set for small object
	mov_tr	ax, bx				;large names, store block
5$:
	mov	bx, ATTR_VIS_TEXT_NAME_ARRAY or mask VDF_SAVE_TO_STATE
	call	addVarData

	mov	ax, CA_NULL_ELEMENT
	mov	ss:[bp].VTT_hyperlinkName, ax
	mov	ss:[bp].VTT_hyperlinkFile, ax
	mov	ss:[bp].VTT_context, ax
	clr	ss:[bp].VTT_unused

	; allocate an empty run and element structure

	mov	bl, TAT_TYPES
	call	createArraysForObject		;ax = run
	mov	bx, ATTR_VIS_TEXT_TYPE_RUNS or mask VDF_SAVE_TO_STATE
	call	addVarData
	ornf	ds:[di].VTI_storageFlags, mask VTSF_TYPES

	mov	bx, OFFSET_FOR_TYPE_RUNS
	call	addElementAndInsertRun
noTypes:

	; *** graphics ***

	test	cl, mask VTSF_GRAPHICS
	jz	noGraphics

	; allocate an empty run and element structure

	mov	bl, TAT_GRAPHICS
	call	createArraysForObject		;ax = run
	mov	bx, ATTR_VIS_TEXT_GRAPHIC_RUNS or mask VDF_SAVE_TO_STATE
	call	addVarData
	ornf	ds:[di].VTI_storageFlags, mask VTSF_GRAPHICS
noGraphics:

	; *** styles ***

	test	cl, mask VTSF_STYLES
	jz	noStyles
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bh, ds:[di].VTI_storageFlags
	and	bh, mask VTSF_LARGE
	pushf
	call	TA_CreateStyleArray		;ax = chunk, bx = handle
	popf
	jz	10$
	mov_tr	ax, bx				;large styles, store block
10$:
	mov	bx, ATTR_VIS_TEXT_STYLE_ARRAY or mask VDF_SAVE_TO_STATE
	call	addVarData
	ornf	ds:[di].VTI_storageFlags, mask VTSF_STYLES
noStyles:

	; *** regions ***

	tst	ch
	jz	noRegions
	push	si
 	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	regionsHuge

	mov	bx, size VisLargeTextRegionArrayElement
	clr	cx
	clr	si
	mov	al, mask OCF_DIRTY
	call	ChunkArrayCreate
	mov_tr	ax, si
	jmp	regionsCommon

regionsHuge:
	call	T_GetVMFile			;bx = file
	clr	di
	mov	cx, size VisLargeTextRegionArrayElement
	call	HugeArrayCreate			;di = vm block handle
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_REGION
	mov	cx, size VisLargeTextCachedRegion
	call	ObjVarAddData			;ds:bx = data
	mov	ds:[bx].VLTCR_num, -1
	mov_tr	ax, di

regionsCommon:
	pop	si
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VLTI_regionArray, ax

	; Only cache if we have that turned on
	test	ds:[di].VLTI_attrs, mask VLTA_CACHE_REGION_CALCS
	jz	noCaching

	; Setup the cached region line and char count (with nothing cached)
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	mov	cx, size VisLargeTextCachedLineAndCharCount
	call	ObjVarAddData			;ds:bx = data
	mov	ds:[bx].VLTCLACC_lineRegionIndex, -1
	mov	ds:[bx].VLTCLACC_prevLineRegionIndex, -1
	mov	ds:[bx].VLTCLACC_lineToRegionRegionIndex, -1
	mov	ds:[bx].VLTCLACC_regionFromLineRegionIndex, -1

noCaching:
	pop	si
		
noRegions:

	add	sp, size VisTextMaxParaAttr
	pop	di
	call	ThreadReturnStackSpace

	call	SendGenericUpdate
	ret

;---

addVarData:
	push	cx
	push	ax
	mov_tr	ax, bx
	mov	cx, size word
	call	ObjVarAddData
	pop	ds:[bx]
	pop	cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	retn

;---

createArraysForObject:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bh, ds:[di].VTI_storageFlags
	and	bh, mask VTSF_LARGE
	call	TA_CreateRunAndElementArrays	;ax = runs, bx = elements
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	retn

;---

addElementAndInsertRun:
	push	cx, si, ds:[LMBH_handle]
	call	FarRunArrayLock
	call	AddElement			;bx = token
	clrdw	dxax
	call	FarRunArrayInsert
	call	FarRunArrayUnlock
	pop	cx, si, bx
	call	MemDerefDS
	retn

VisTextCreateStorage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_CreateRunAndElementArrays

DESCRIPTION:	Create a run array and an element array

CALLED BY:	INTERNAL

PASS:
	bl - TextArrayType
	bh - non-zero to create VM

RETURN:
	ax - run array
	bx - element array

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TA_CreateRunAndElementArrays	proc	far	uses cx, dx, si, di, bp
	.enter

	call	TA_CreateElementArray

	tst	bh
	jz	notVM

	; allocate a huge array for the run array

	push	ax
	mov	cx, size TextRunArrayElement
	mov	di, size TextLargeRunArrayHeader ; allocate xtra space in hdr
	call	T_GetVMFile			;bx = file
	clr	si
	call	HugeArrayCreate			;di = vm block handle
	mov	ax, di				;ax = block
	pop	cx				;cx = element's vm block handle
	push	cx				;save elements
	call	SetElementBlock			;set ID to element block

	; create initial runs

	push	bp
	mov	cx, 1
	clr	bp				;no data
	call	HugeArrayAppend
	pop	bp

	push	ds
	clrdw	dxax
	call	HugeArrayLock			;point at first element

	mov	ds:[si].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH
	mov	ds:[si].TRAE_position.WAAH_low, TEXT_ADDRESS_PAST_END_LOW
	mov	ds:[si].TRAE_token, CA_NULL_ELEMENT
	call	HugeArrayDirty
	call	HugeArrayUnlock
	pop	ds
	pop	bx				;bx = elements
	mov_tr	ax, di				;ax = runs
	jmp	done

	; allocate a chunk

notVM:
	push	ax

	mov	al, mask OCF_DIRTY
	mov	bx, size TextRunArrayElement
	mov	cx, size TextRunArrayHeader
	clr	si
	call	ChunkArrayCreate		;*ds:si = run array

	mov	di, ds:[si]
	pop	bx
	mov	ds:[di].TRAH_elementArray, bx

	; create last entry

	call	ChunkArrayAppend	;ds:di = element
	mov	ds:[di].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH
	mov	ds:[di].TRAE_position.WAAH_low, TEXT_ADDRESS_PAST_END_LOW
	mov	ds:[di].TRAE_token, CA_NULL_ELEMENT
	mov_tr	ax, si				;ax = runs
done:
	.leave
	ret

TA_CreateRunAndElementArrays	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_CreateElementArray

DESCRIPTION:	Create an element arrya

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bl - TextArrayType
	bh - non-zero to create VM

RETURN:
	ax - element vm block to chunk handle

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/30/92		Initial version

------------------------------------------------------------------------------@
TA_CreateElementArray	proc	far	uses cx, dx, si, di, bp
	.enter

EC <	call	T_AssertIsVisText					>

	tst	bh
	jz	notVM1

	; allocate a vm block for the element array

	mov	dx, bx				;dx = TextArrayType & boolean
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	T_GetVMFile			;bx = file
	call	VMAllocLMem			;ax = block handle
	push	ax, ds
	call	VMLock
	mov	ds, ax
	mov	bx, dx				;restore TextArrayType & boolean
notVM1:

	; allocating a chunk

	push	bx				;save array type
	mov	cx, size TextElementArrayHeader
	mov_tr	ax, bx				;al = array type
	clr	bx
	cmp	al, TAT_PARA_ATTRS
	jz	gotSize
	mov	bl, size VisTextCharAttr
	cmp	al, TAT_CHAR_ATTRS
	jz	gotSize
	mov	bl, size VisTextType
	cmp	al, TAT_TYPES
	jz	gotSize
	mov	bl, size VisTextGraphic
	cmp	al, TAT_GRAPHICS
	jz	gotSize
gotSize:
	mov	al, mask OCF_DIRTY
	clr	si
	call	ElementArrayCreate
	pop	bx

EC <	tst	bh							>
EC <	jz	10$							>
EC <	cmp	si, VM_ELEMENT_ARRAY_CHUNK				>
EC <	ERROR_NZ	WRONG_CHUNK_HANDLE_ALLOCATED			>
EC <10$:								>

	mov	ax, si				;ax = chunk
	mov	si, ds:[si]
	mov	ds:[si].TEAH_arrayType, bl
	mov	ds:[si].TEAH_unused, 0

	tst	bh
	jz	notVM2
	call	VMUnlock
	pop	ax, ds
notVM2:
	.leave
	ret

TA_CreateElementArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetElementBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to set the element block associated with
		a Large text object's character array.

CALLED BY:	INTERNAL
		TA_CreateRunAndElementArrays, ChangeElementArray
PASS:		bx.ax	= VM file/block handle
		cx	= handle of element block to associate w/HugeArray
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The code used to use the VMUserID to store this, and it's been
		changed to store it after the HugeArrayDirectory structure
		in the directory block.  I've written this routine to take 
		the same arguments as VMModifyUserID, to make the transition
		a little smoother.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetElementBlock	proc	near
		uses	ax, di, ds
		.enter
		
		; lock the VM directory block

		mov	di, ax			; bx.di -> HugeArrayDirectory
		call	HugeArrayLockDir	; lock the directory
		mov	ds, ax			; ds -> TextLargeRunArrayHeader
		mov	ds:[TLRAH_elementVMBlock], cx ; store new block handle
		call	HugeArrayDirty
		call	HugeArrayUnlockDir

		.leave
		ret
SetElementBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_CreateStyleArray

DESCRIPTION:	Create a style array

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bh - non-zero to create VM

RETURN:
	ax - chunk handle
	bx - mem/vm handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TA_CreateStyleArray	proc	far	uses cx, dx, si, di, bp
	.enter

EC <	call	T_AssertIsVisText					>

	tst	bh
	jz	notVM1

	; allocate a vm block for the element array

	push	ds
	push	bx
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	T_GetVMFile			;bx = file
	call	VMAllocLMem			;ax = block handle
	mov	di, ax				;di saves vm block handle
	call	VMLock
	mov	ds, ax
	pop	bx
notVM1:

	; allocating a chunk

	push	bx
	mov	al, mask OCF_DIRTY
	mov	bx, (size TextStyleElementHeader)-(size NameArrayElement)
	mov	cx, size NameArrayHeader
	clr	si
	call	NameArrayCreate
	mov_tr	ax, si
	pop	bx

	tst	bh
	mov	bx, 0				;assume not vm
	jz	notVM2

EC <	cmp	ax, VM_ELEMENT_ARRAY_CHUNK				>
EC <	ERROR_NZ	WRONG_CHUNK_HANDLE_ALLOCATED			>
	mov	bx, di				;bx = block handle
	call	VMUnlock
	pop	ds
notVM2:

	.leave
	ret

TA_CreateStyleArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TA_CreateNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a name array (for use with types)

CALLED BY:	VisTextCreateStorage()
PASS:		*ds:si - text object
		bh - non-zero to create VM
RETURN:		ax - chunk handle
		bx - mem/vm handle

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TA_CreateNameArray		proc	far
	uses cx, dx, si, di, bp
	.enter
EC <	call	T_AssertIsVisText			>

	tst	bh
	jz	notVM1
	;
	; allocate a vm block for the element array
	;
	push	ds
	push	bx
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	T_GetVMFile			;bx <- file
	call	VMAllocLMem			;ax <- block handle
	mov	di, ax				;di saves vm block handle
	call	VMLock
	mov	ds, ax
	pop	bx
notVM1:
	;
	; allocating a chunk
	;
	push	bx
	mov	al, mask OCF_DIRTY
	mov	bx, (size VisTextNameData)
	mov	cx, size NameArrayHeader
	clr	si
	call	NameArrayCreate
	mov_tr	ax, si
	pop	bx

	tst	bh
	mov	bx, 0				;assume not vm
	jz	notVM2

EC <	cmp	ax, VM_ELEMENT_ARRAY_CHUNK				>
EC <	ERROR_NZ	WRONG_CHUNK_HANDLE_ALLOCATED			>
	mov	bx, di				;bx = block handle
	call	VMUnlock
	pop	ds
notVM2:

	.leave
	ret
TA_CreateNameArray		endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextChangeElementArray -- MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY
					for VisTextClass

DESCRIPTION:	Change the element array being used for the text object.
		This allows an application to easily set up multiple objects
		referencing common element arrays.

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cl - VisTextStorageFlags for field to replace (one of these bits should
	     be set:
		VTSF_MULTIPLE_CHAR_ATTRS
		VTSF_MULTIPLE_PARA_ATTRS
	        VTSF_TYPES
		VTSF_GRAPHICS
		VTSF_STYLES
		VTSF_NAMES
	ch - non-zero if word passed in dx is a VM block, zero if it is a
	     chunk handle
	dx - VM block handle or chunk handle containing element array (depends
	     on ch)
	bp - token for first (and only) run (char, para, type)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/23/92		Initial version

------------------------------------------------------------------------------@
VisTextChangeElementArray	proc	far ; MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY
	class	VisTextClass

	mov	bx, offset VTI_charAttrRuns
	cmp	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	jnz	notCharAttr
changeCommon:
	call	ChangeElementArray

done:
	ret

notCharAttr:
	mov	bx, offset VTI_paraAttrRuns
	cmp	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	jz	changeCommon
	mov	bx, OFFSET_FOR_TYPE_RUNS
	cmp	cl, mask VTSF_TYPES
	jz	changeCommon
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	cmp	cl, mask VTSF_GRAPHICS
	jz	changeCommon

	mov	ax, ATTR_VIS_TEXT_NAME_ARRAY or mask VDF_SAVE_TO_STATE
	cmp	cl, VTSF_NAMES
	je	varDataCommon

	; must be styles

EC <	cmp	cl, mask VTSF_STYLES					>
EC <	ERROR_NZ VIS_TEXT_ILLEGAL_PARAMETER				>

	mov	ax, ATTR_VIS_TEXT_STYLE_ARRAY or mask VDF_SAVE_TO_STATE
varDataCommon:
	call	ObjVarFindData
	jnc	noExistingStyleArray
	mov	ax, ds:[bx]
	push	bx

	; figure out how the array is stored

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].VTI_storageFlags, mask VTSF_LARGE
	jnz	large

	; this is a small object -- it *might* still have VM blocks for the
	; attribute arrays, we have to look and see

	mov	bx, ds:[bx].VTI_charAttrRuns
	mov	bx, ds:[bx]			;ds:bx = TextRunArrayHeader
	tst	ds:[bx].TRAH_elementVMBlock
	jnz	large
	call	LMemFree
	jmp	popCommon
large:
	call	T_GetVMFile
	call	VMFree
popCommon:
	pop	bx
	jmp	common
noExistingStyleArray:
	mov	cx, size word
	call	ObjVarAddData
common:
	mov	ds:[bx], dx
	jmp	done

VisTextChangeElementArray	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeElementArray

DESCRIPTION:	Change a run array to use a different element array

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	bx - run offset
	ch - non-zero if word passed in dx is a VM block, zero if it is a
	     chunk handle
	dx - VM block handle or chunk handle containing element array (depends
	     on ch)
	bp - token for first (and only) run (char, para, type)

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/23/92		Initial version

------------------------------------------------------------------------------@
ChangeElementArray	proc	near	uses si, ds
	class	VisTextClass
	.enter

	; get the file in case we need it later

	push	bx
	call	T_GetVMFile
	mov	ax, bx				;ax <- VM file handle
	pop	bx

	; first we must delete the old array

	push	cx
	call	FarRunArrayLock
	call	ElementArrayFree
	pop	cx

	push	bx
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	lmem

	; run array is a VM block -- elements must be VM

EC <	tst	ch							>
EC <	ERROR_Z	ELEMENTS_MUST_BE_VM_IF_RUNS_ARE				>

	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = file
	mov_tr	bx, ax

	mov	ax, di				;ax = block handle
	mov	cx, dx				;cx = element block
	call	SetElementBlock			;set ID to element block
	jmp	done

lmem:

	; run array is a chunk -- elements might be chunks or VM
	; If it is VM, we need to store the VM file handle in
	; TRAH_elementArray so that ElementArrayLock can use it
	; 	ax - VM file handle
	;	dx - chunk or block handle
	;	ch - non-zero if dx is block handle

	mov	bx, ds:[di]			;ds:bx = TextRunArrayHeader
	tst	ch				;VM?
	jnz	isVM				;branch if VM
	clr	ax
	xchg	ax, dx				;ax <- chunk handle, dx <- 0
isVM:
	mov	ds:[bx].TRAH_elementArray, ax
	mov	ds:[bx].TRAH_elementVMBlock, dx

done:
	pop	bx
	cmp	bx, offset VTI_charAttrRuns
	jz	stuffToken
	cmp	bx, offset VTI_paraAttrRuns
	jz	stuffToken
	cmp	bx, OFFSET_FOR_TYPE_RUNS
	jnz	afterStuffToken
stuffToken:
	mov	ds:[si].TRAE_token, bp
	mov	bx, bp
	call	ElementAddRef			;add a reference for the new element
afterStuffToken:

	call	FarRunArrayUnlock

	.leave
	ret

ChangeElementArray	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextFreeStorage -- MSG_VIS_TEXT_FREE_STORAGE
						for VisTextClass

DESCRIPTION:	Remove all runs associated with this object.  Basically all
		elements which are referred to have their reference counts
		decremented and if the reference counts go to zero, the
		elements are removed.  Use caution with this method.


PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - non-zero to free elements also

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/23/92		Initial version

------------------------------------------------------------------------------@
VisTextFreeStorage	proc	far ; MSG_VIS_TEXT_FREE_STORAGE
	class	VisLargeTextClass

	andnf	ds:[di].VTI_features, not mask VTF_ALLOW_UNDO

	clr	ds:[di].VTI_output.handle

	push	cx
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock
	pop	cx

	mov	bx, offset VTI_charAttrRuns
	mov	dx, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			(mask VTSF_DEFAULT_CHAR_ATTR shl 8)
	call	FreeRun			;carry set if elements freed
	jnc	afterStyles

	; we only free the styles if we freed the elements

	mov	ax, ATTR_VIS_TEXT_STYLE_ARRAY
	call	FreeVarStruct

	mov	ax, ATTR_VIS_TEXT_NAME_ARRAY
	call	FreeVarStruct
afterStyles:

	mov	bx, offset VTI_paraAttrRuns
	mov	dx, mask VTSF_MULTIPLE_PARA_ATTRS or \
			(mask VTSF_DEFAULT_PARA_ATTR shl 8)
	call	FreeRun

	mov	bx, OFFSET_FOR_TYPE_RUNS
	mov	dx, mask VTSF_TYPES
	call	FreeRun

	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	mov	dx, mask VTSF_GRAPHICS
	call	FreeRun

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	notLarge

	mov	ax, ds:[di].VLTI_regionArray
	tst	ax
	jz	noRegions
	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	10$
	call	ObjFreeChunk
	jmp	noRegions
10$:
	mov_tr	di, ax
	call	T_GetVMFile
	call	HugeArrayDestroy
noRegions:
notLarge:

	ret
VisTextFreeStorage	endp

;---

	; return carry set if elements freed

FreeRun	proc	near
	class	VisTextClass

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	dl, ds:[di].VTI_storageFlags	;clears carry
	jz	done
	;
	; Set the appropriate default, if any (dh == 0 for none)
	;
	ornf	ds:[di].VTI_storageFlags, dh
	;
	; Clear the appropriate storage flag
	;
	mov	dh, dl
	not	dh				;dh <- all other bits
	and	ds:[di].VTI_storageFlags, dh	;clear our bit (clears carry)
	;
	; Free the elements if requested
	;
	jcxz	skipElementFree
	push	cx, ds, si
	call	FarRunArrayLock
	call	ElementArrayFree		;carry - set if elements freed
	call	FarRunArrayUnlock		;preserves flags
	pop	cx, ds, si
skipElementFree:
	;
	; Free the run arrays
	;
	pushf
	call	RunArrayFree
	popf
done:
	ret

FreeRun	endp

;---

FreeVarStruct	proc	near
	call	ObjVarFindData
	jnc	done
	mov	ax, ds:[bx]
	call	FreeLMemOrVMem
done:
	ret
FreeVarStruct	endp

TextInstance ends
