COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Text
FILE:		textElement.asm

ROUTINES:

	Name			Description
	----			-----------

	Routines used by textMethodCharAttr, textMethodParaAttr and textMethodType.

   EXT	GetElement		Get an element from an array
   EXT	ElementAddRef		Change the reference count of an element
   EXT	AddElement		Add an element to an array
   EXT	RemoveElement		Remove an element from an array

   EXT	GetInsertionElement	Get the insertion element
   EXT	SetInsertionElement	Set the given token as the insertion element
				and increment its reference count
   EXT	ClearInsertionElement	Clear the current insertion element

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version
	Tony	7/91		Reviewed for 2.0

DESCRIPTION:

This file contains the internal routines to handle charAttr and paraAttr element
arrays.  None of these routines are directly accessable outisde the text
object.

Most of these routines take *ds:si being the text object and bx being the
offset to the run structure.  These routines can actually work on either:

    - runs in the instance data
	bx = offset VTI_???

    - runs in a transfer item
	bx >= TRANSFER_RUN_MARKER
	ss:[bx-TRANSFER_RUN_MARKER] = TransferRun

Handling associated data:

* a new element is added (via AddElement)
	- charAttr/paraAttr: reference added for associated name




	$Id: taElement.asm,v 1.1 97/04/07 11:18:38 newdeal Exp $

------------------------------------------------------------------------------@

TextGraphic segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_EnumElements

DESCRIPTION:	Enumerate the elements in an element array

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - run offset
	dxax - callback
	cx, bp - callback data

RETURN:
	cx, bp, carry - from callback

DESTROYED:
	dx, ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/13/92		Initial version

------------------------------------------------------------------------------@

if 0

TA_EnumElements	proc	near	uses bx, si, di, ds
	.enter

	call	FarRunArrayLock			;ds:si = run array, di = token
	push	ds
	call	FarElementArrayLock		;*ds:si = element array
	push	bx

	movdw	bxdi, dxax			;bxdi = callback
	call	ChunkArrayEnum

	pop	bx
	call	FarElementArrayUnlock
	pop	ds
	call	FarRunArrayUnlock

	.leave
	ret

TA_EnumElements	endp

endif

TextGraphic ends

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetElement

DESCRIPTION:	Get an element from an array

CALLED BY:	INTERNAL

PASS:
	ds:si - pointing run array element
	di - run token
	bx - token
	ss:bp - buffer

RETURN:
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

GetElement	proc	far		uses	ax, bx, cx, dx, si, ds
	.enter

EC <	call	ECCheckRunsElementArray					>

	mov_tr	ax, bx				;ax = token

	call	ElementArrayLock		;*ds:si = element array
						;bx = value for unlock

EC <	push	cx, di							>
EC <	call	ChunkArrayElementToPtr					>
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	TEXT_ATTRIBUTE_ELEMENT_IS_FREE				>
EC <	pop	cx, di							>

	mov	cx, ss				;cx:dx = buffer
	mov	dx, bp
	call	ChunkArrayGetElement

EC <	call	ECCheckElement						>

	call	ElementArrayUnlock

	.leave
	ret

GetElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetElementStyle

DESCRIPTION:	Get the style for an element

CALLED BY:	INTERNAL

PASS:
	ds:si - pointing run array element
	di - run token
	bx - token

RETURN:
	ax - style

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@
GetElementStyle	proc	far		uses	bx, si, ds
	.enter

EC <	call	ECCheckRunsElementArray					>

	mov_tr	ax, bx				;ax = token

	call	ElementArrayLock		;*ds:si = element array
						;bx = value for unlock
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].SSEH_style

	call	ElementArrayUnlock

	.leave
	ret

GetElementStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementAddRef

DESCRIPTION:	Change the reference count of an element

CALLED BY:	INTERNAL

PASS:
	ds:si - pointing run array element
	di - run token
	bx - token

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

ElementAddRef	proc	far		uses	ax, bx, si, ds
	.enter

EC <	call	ECCheckRunsElementArray					>

	mov_tr	ax, bx				;ax = token

	call	ElementArrayLock		;*ds:si = element array
						;bx = value for unlock

	call	ElementArrayAddReference

	call	ElementArrayUnlock

	.leave
	ret

ElementAddRef	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddGraphicElement

DESCRIPTION:	Add a graphic element to an array, testing for duplicates

CALLED BY:	INTERNAL

PASS:
	ds:si - pointing run array element
	di - run token
	ss:bp - VisTextGraphic to add
	dx - source VM file
	bx - destination VM file

RETURN:
	ds:si - possibly changed
	bx - token of structure added
	carry - set if new element added

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/25/92		Initial version

------------------------------------------------------------------------------@
AddGraphicElement	proc	far
	stc
	GOTO	AddElementLow

AddGraphicElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddElement

DESCRIPTION:	Add an element to an array

CALLED BY:	INTERNAL

PASS:
	dx - source VM file (if a graphic)
	bx - destination VM file
	ds:si - pointing run array element
	di - run token
	ss:bp - structure to add

RETURN:
	ds:si - possibly changed
	bx - token of structure added
	carry - set if new element added

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@
AddElement	proc	far
	clc
	FALL_THRU	AddElementLow

AddElement	endp

;---

AddElementLow	proc	far		uses	ax, cx, dx
	.enter

	; So this is a hack, shoot me.

	push	bx				;save source, dest files
	push	dx
	mov	dx, sp				;ss:dx points at source,dest

	; make cx be the segment of the callback

	mov	cx, vseg TG_CompareGraphics
	mov	ax, offset TG_CompareGraphics
	jc	10$
	clrdw	cxax
10$:

	call	RunArrayUnref			;bx, si, di = data
	push	bx, si, di

EC <	call	ECCheckRunsElementArray					>

	call	ElementArrayLock		;*ds:si = element array
	push	bx				;bx = value for unlock

	pushdw	cxax				;save callback

EC <	call	ECCheckElement						>

	mov	di, ds:[si]			;get element type

	; if this is a paraAttr then calculate its size

	cmp	ds:[di].TEAH_arrayType, TAT_PARA_ATTRS
	jnz	notParaAttr
	CalcParaAttrSize	<ss:[bp]>, ax
notParaAttr:

	popdw	bxdi				;bxdi = callback
	mov	cx, ss
	xchg	dx, bp				;cx:dx = element, bp = frame
	call	ElementArrayAddElement		;ax = new token
	xchg	dx, bp
	pushf
	jnc	noNewGraphic
	tst	bx
	jz	noNewGraphic

	; new graphic added -- copy it in

	mov	di, dx
	mov	dx, ss:[di]			;dx = source file
	mov	bx, ss:[di+2]			;bx = dest file
	call	TG_CopyGraphic
	call	ChunkArrayElementToPtr		;ds:di = ptr
	movdw	ds:[di].VTG_vmChain, ss:[bp].VTG_vmChain, dx
noNewGraphic:

	popf
	pop	bx
	call	ElementArrayUnlock

	pop	bx, si, di
	call	RunArrayReref
	mov_tr	bx, ax				;bx = token to return

	pop	ax, ax				;nuke passed files

	.leave
	ret

AddElementLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RemoveElement

DESCRIPTION:	Remove an element from an array

CALLED BY:	INTERNAL

PASS:
	ds:si - pointing run array element
	di - run token
	bx - token of element to remove
	cx - VM file

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

RemoveElement	proc	far		uses	ax, bx, si, di, ds
	.enter

EC <	call	ECCheckRunsElementArray					>

	mov_tr	ax, bx				;ax = token

	call	ElementArrayLock		;*ds:si = element array
	push	bx

	; if this is a graphic element then pass a callback to remove the
	; graphic properly

	clr	bx				;assume no callback
	mov	di, ds:[si]			;get element type

	cmp	ds:[di].TEAH_arrayType, TAT_GRAPHICS
	jnz	notGraphic
	mov	di, offset TG_GraphicRunDelete
	mov	bx, vsegment TG_GraphicRunDelete
notGraphic:
	call	ElementArrayRemoveReference

	pop	bx
	call	ElementArrayUnlock

	.leave
	ret

RemoveElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetInsertionElement

DESCRIPTION:	Get the insertion element

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - run offset

RETURN:
	bx - insertion token (CA_NULL_ELEMENT if none)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@
GetInsertionElement	proc	far	uses	ax
	class	VisTextClass
	.enter

EC <	cmp	bx, offset VTI_paraAttrRuns				>
EC <	ERROR_Z	VIS_TEXT_PARA_ATTRS_HAVE_NO_INSERTION_ELEMENT		>

	mov	ax, ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN
	cmp	bx, offset VTI_charAttrRuns
	jz	10$
	mov	ax, CA_NULL_ELEMENT
	cmp	bx, OFFSET_FOR_TYPE_RUNS
	jnz	done
	mov	ax, ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN
10$:
	call	ObjVarFindData
	mov	ax, CA_NULL_ELEMENT
	jnc	done
	mov	ax, ds:[bx]
done:
	mov_tr	bx, ax

	.leave
	ret

GetInsertionElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetInsertionElement

DESCRIPTION:	Set the given token as the insertion element and increment its
		reference count

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ax - run offset
	bx - token of element to set as insertion element

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

SetInsertionElement	proc	near	uses	ax, bx, cx, dx, di
	class	VisTextClass
	.enter

EC <	cmp	ax, offset VTI_paraAttrRuns				>
EC <	ERROR_Z	VIS_TEXT_PARA_ATTRS_HAVE_NO_INSERTION_ELEMENT		>

	push	ax
	push	bx
	mov	bx, ax
	mov	dx, 1
	call	ClearInsertionElement
	pop	dx

	cmp	ax, offset VTI_charAttrRuns
	mov	ax, ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN
	jz	10$
	mov	ax, ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN
10$:
	mov	cx, size word
	call	ObjVarAddData
	mov	ds:[bx], dx

	pop	bx
	push	si, ds
	call	RunArrayLock
	mov	bx, dx
	call	ElementAddRef
	call	RunArrayUnlock
	pop	si, ds

	.leave
	ret

SetInsertionElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ClearInsertionElement

DESCRIPTION:	Clear the current insertion element

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset of run
	dx - non-zero to remove references to the token

RETURN:
	bx - insertion token (CA_NULL_ELEMENT if none)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

ClearInsertionElement	proc	near	uses	ax, cx
	class	VisTextClass
	.enter

EC <	cmp	bx, offset VTI_paraAttrRuns				>
EC <	ERROR_Z	VIS_TEXT_PARA_ATTRS_HAVE_NO_INSERTION_ELEMENT		>

	mov	cx, bx
	mov	ax, ATTR_VIS_TEXT_CHAR_ATTR_INSERTION_TOKEN
	cmp	bx, offset VTI_charAttrRuns
	jz	10$
	cmp	bx, OFFSET_FOR_TYPE_RUNS
	jnz	notFound
	mov	ax, ATTR_VIS_TEXT_TYPE_INSERTION_TOKEN
10$:
	call	ObjVarFindData
	jnc	notFound

	push	si, di, ds

	push	ds:[bx]
	call	ObjVarDeleteData

	mov	bx, cx
	call	RunArrayLock
	pop	bx
	tst	dx
	jz	noRemoveRef
	call	RemoveElement	
noRemoveRef:
	call	RunArrayUnlock
	pop	si, di, ds
done:
	.leave
	ret

notFound:
	mov	bx, CA_NULL_ELEMENT
	jmp	done

ClearInsertionElement	endp

;----------------------------------------------------------------------------
;	Routines below are internal to this file
;----------------------------------------------------------------------------

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayLock

DESCRIPTION:	Given a run, return the corresponding array.

CALLED BY:	INTERNAL

PASS:
	ds:si - pointing run array element
	di - run token

RETURN:
	*ds:si - element array
	bx - value to pass to ElementArrayUnlock
	     0 - runs are in the same block
	     !0 - VM mem handle

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@
FarElementArrayLock	proc	far
	call	ElementArrayLock
	ret
FarElementArrayLock	endp

ElementArrayLock	proc	near	uses ax, cx, di, bp
	.enter

	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jnz	runsInVM

	; if the runs are in an object block then they must be part of a small
	; text object, thus di is the chunk handle of the run array

	mov	si, ds:[di]			;ds:si = run
	mov	bx, ds:[si].TRAH_elementArray
	mov	ax, ds:[si].TRAH_elementVMBlock

	; if the vm block is non-zero then the elements are in a VM block
	; and the vm file handle is stored in the TRAH_elementArray field
	; (by RunArrayLock)

	tst	ax
	jnz	vmCommon

	; else the elements are in a chunk

	mov	si, bx				;*ds:si = elements
	clr	bx				;return 0 since in same block
	jmp	done

runsInVM:

	; the runs are in a VM block, thus the elements must be in a VM
	; block in the same file

	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = VM file handle
	mov_tr	bx, ax				;bx = VM file handle

	; di is the VM block handle of the runs, the user id of this block
	; is the VM block handle of the elements

	mov_tr	ax, di
	call	VMLock		
	mov	ds, ax			; ds -> TextLargeRunArrayHeader
	mov	di, ds:[TLRAH_elementVMBlock]	; get handle
	call	VMUnlock		; release block
	mov_tr	ax, di

	; bx = vm file, ax = vm block

vmCommon:
	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK

	; if this block is not an LMEM block (which it is not if it is a
	; transfer block) then temporarily make it an lmem block

	clr	bx
	tst	ds:[LMBH_handle]
	jnz	done
	mov	ds:[LMBH_handle], bp
	mov	bx, bp				;return non-zero
	mov	ax, mask HF_LMEM
	call	MemModifyFlags
done:
	.leave
	ret

ElementArrayLock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayUnlock

DESCRIPTION:	Finish with element array by unlocking if necessary

CALLED BY:	INTERNAL

PASS:
	ds - element block
	bx - value returned by ElementArrayLock

RETURN:
	flags preserved

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@
FarElementArrayUnlock	proc	far
	call	ElementArrayUnlock
	ret
FarElementArrayUnlock	endp

ElementArrayUnlock	proc	near	uses bp
	.enter
	pushf

EC <	tst	bx							>
EC <	jz	ok							>
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_Z ELEMENT_ARRAY_UNLOCK_PASSED_BAD_DATA			>
EC <	cmp	bx, ds:[LMBH_handle]					>
EC <	ERROR_NZ ELEMENT_ARRAY_UNLOCK_PASSED_BAD_DATA			>
EC <ok:									>

	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	done

	; if we temporarily changed this block to be LMEM then change it back

	mov	bp, ds:[LMBH_handle]
	tst	bx
	jz	noLMemFix

	push	ax
	mov	ax, (mask HF_LMEM) shl 8
	call	MemModifyFlags				;bx is handle
	clr	ds:[LMBH_handle]
	pop	ax

noLMemFix:
	call	VMUnlock
done:

	popf
	.leave
	ret

ElementArrayUnlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayFree

DESCRIPTION:	Given a run, free the corresponding array

CALLED BY:	INTERNAL

PASS:
	ds:si - pointing run array element
	di - run token

RETURN:
	carry - set if elements freed

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@

TextInstance segment resource

ElementArrayFree	proc	near	uses ax, cx, si, di
	.enter

	; We only free the elements if they are stored in an lmem chunk

	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	clc
	jnz	done

	; small text object, element chunk is stored in di or in a
	; vm block

	mov	si, ds:[di]			;ds:si = run
	mov	ax, ds:[si].TRAH_elementVMBlock
	tst_clc	ax
	jnz	done
	mov	ax, ds:[si].TRAH_elementArray
	call	ObjFreeChunk
	stc

done:
	.leave
	ret

ElementArrayFree	endp

TextInstance ends

;------------------------------------------------------------------------------
;		ERROR CHECKING
;------------------------------------------------------------------------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckElement

DESCRIPTION:	Check an element for validity

CALLED BY:	INTERNAL

PASS:
	*ds:si - element array
	ss:bp - element

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK

ECCheckElement	proc	far	uses di
	.enter
	pushf

	mov	di, ds:[si]
	cmp	ds:[di].TEAH_arrayType, TAT_CHAR_ATTRS
	jnz	notCharAttr

	call	ECCheckCharAttr
	jmp	done

notCharAttr:
	cmp	ds:[di].TEAH_arrayType, TAT_PARA_ATTRS
	jnz	notParaAttr
	call	ECCheckParaAttr

notParaAttr:

done:
	popf
	.leave
	ret

ECCheckElement	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckRunsElementArray

DESCRIPTION:	Check a run's associated element array

CALLED BY:	ECCheckRun

PASS:
	ds:si - pointing run array element
	di - run token
	bx - offset of run

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/18/91		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK

ECCheckRunsElementArray	proc	far	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter
	pushf

	call	ECCheckTextEC
	jnc	done

	mov	ax, di
	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di
	mov	di, ax

	call	ElementArrayLock	;*ds:si = element array
	push	bx

	mov	di, ds:[si]
	mov	dl, ds:[di].TEAH_arrayType
	mov	bx, cs
	mov	di, offset ECEACallback
	call	ChunkArrayEnum

	pop	bx
	call	ElementArrayUnlock

	pop	di
	call	ThreadReturnStackSpace

done:
	popf
	.leave
	ret

ECCheckRunsElementArray	endp

	; ds:di = element
	; ax = size (if paraAttr)
	; dl = TextArrayType

ECEACallback	proc	far	uses	dx
buf	local	VisTextMaxParaAttr
	.enter

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	done

	mov	si, di			;ds:si = element
	segmov	es, ss
	lea	di, buf
	mov	cx, size VisTextMaxParaAttr
	rep movsb

	push	bp
	lea	bp, buf
	cmp	dl, TAT_CHAR_ATTRS
	jnz	notCharAttr
	call	ECCheckCharAttr
	jmp	common
notCharAttr:
	cmp	dl, TAT_PARA_ATTRS
	jnz	notParaAttr
	call	ECCheckParaAttr
	jmp	common
notParaAttr:

common:
	pop	bp

done:
	.leave
	ret
ECEACallback	endp

endif

TextAttributes ends
