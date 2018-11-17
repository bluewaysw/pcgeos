COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/VMem
FILE:		vmemObject.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle VMem blocks used to store objects

	$Id: vmemObject.asm,v 1.1 97/04/05 01:16:07 newdeal Exp $

------------------------------------------------------------------------------@

ObjectLoad	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VMObjMemHandleToIndex

DESCRIPTION:	Given a VM memory block, return the VM index, being careful
		not to deadlock/block if owning file has already been entered

CALLED BY:	INTERNAL

PASS:
	bx - memory handle of a VM block

RETURN:
	ax - VM index

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

VMObjMemHandleToIndex	proc	near	uses bx, dx
	.enter

	call	VMMemBlockToVMBlock

	sub	ax, offset VMH_blockTable
	clr	dx
	mov	bx, size VMBlockHandle
	div	bx			;ax = index

	.leave
	ret

VMObjMemHandleToIndex	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMObjIndexToMemHandle

DESCRIPTION:	Given a VM index and a VM file handle, return a virtual
		handle

CALLED BY:	INTERNAL

PASS:
	ax - VM index
	bx - memory handle owned by the VM file OR the VM file itsself

RETURN:
	ax - memory handle

DESTROYED:
	ax, bx, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

VMObjIndexToMemHandle	proc	near

	; calculate block

	push	dx
	mov	cx, size VMBlockHandle
	mul	cx
	add	ax, offset VMH_blockTable

	; find VM file

	LoadVarSeg	ds
	cmp	ds:[bx].HG_type, SIG_FILE
	jz	common

	; it's a block owned by the VM file

	mov	bx, ds:[bx].HM_owner
	mov	bx, ds:[bx].HVM_fileHandle

common:
	pop	dx

	; ax = VM block handle
	; bx = VM file handle

	call	VMVMBlockToMemBlock
	ret

VMObjIndexToMemHandle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMObjRelocOrUnReloc

DESCRIPTION:	Relocate or unrelocate a VM object block

CALLED BY:	INTERNAL

PASS:
	ax = memory handle
	bx = VM file handle
	di = VM block handle of loaded block
	dx = segment address of block
	si low = VMAttributes
	cx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	cx = 0 if block is going away
		not-0 if block has just been loaded

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp ,ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

VMObjRelocOrUnReloc	proc	far
	mov	ds, dx			;ds = segment
	jcxz	unrelocate

	cmp	cx, VMRT_RELOCATE_AFTER_READ
	jnz	noStuffInUseCount
	clr	ds:[OLMBH_inUseCount]
	clr	ds:[OLMBH_interactibleCount]
noStuffInUseCount:
	call	RelocateObjBlock
NEC <	jc	choke							>
	ret

unrelocate:

	cmp	cx, VMRT_UNRELOCATE_BEFORE_WRITE
	jnz	noGenericStuff
	test	si, mask VMA_COMPACT_OBJ_BLOCK
	jz	noGenericStuff
	call	CompactObjBlock
noGenericStuff:

	call	UnRelocateObjBlock
NEC <	jc	choke							>
	ret

if NOT ERROR_CHECK
choke:
ifdef	GPC
	mov	al, KS_OBJ_VM_LOAD_ERROR
else
	mov	si, offset objVMLoadError1
	mov	di, offset objVMLoadError2
endif
	GOTO	ChokeWithMovableString
	.UNREACHED
endif

VMObjRelocOrUnReloc	endp

ObjectLoad	ends
