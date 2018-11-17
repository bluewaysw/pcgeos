COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VM Tree Data Driver
FILE:		vmtreeStack.asm

AUTHOR:		Chung Liu, Jun 15, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94   	Initial revision


DESCRIPTION:
	Abstraction for stack of VM block handles.  Each stack is a
	memory block with a header.

	$Id: vmtreeStack.asm,v 1.1 97/04/18 11:41:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTSAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a dword stack.

CALLED BY:	
PASS:		nothing
RETURN:		bx	= stack handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTSAlloc	proc	near
	uses	ax,cx,ds
	.enter
	mov	ax, DEFAULT_STACK_BLOCK_SIZE
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			;bx = handle, ax = addr.
	mov	ds, ax
	mov	ds:[VMTSH_count], 0
	call	MemUnlock
	.leave
	ret
VMTSAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTSPush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push element onto word stack.

CALLED BY:	VMTreeReadInitialize, VMTreeReadNextBlock
PASS:		bx 	= stack handle
		dx:ax	= element to push
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTSPush	proc	near
	uses	bx,cx,ds,si
	.enter
	;
	; If we're about to overflow the stack, then expand the segment.
	;
	push	dx, ax			;element to push
	call	MemLock			;ax = segment
	mov	ds, ax
	mov	cx, ds:[VMTSH_count]	;number of dword elements.
	inc	cx			;check if there's room for one more.
	shl	cx
	shl	cx			;multiply by dword size	
	add	cx, size VMTStackHeader	;cx = bytes used.

	mov	ax, MGIT_SIZE	
	call	MemGetInfo		;ax = size of block
	cmp	cx, ax
	jbe	pushElement

	;
	; expand block to fit more elements.
	;
	push	cx
	add	ax, DEFAULT_STACK_BLOCK_SIZE
	mov	ch, HAF_STANDARD_NO_ERR
	call	MemReAlloc	
	mov	ds, ax
	pop	cx

pushElement:
	; cx = offset of new element + size dword.
	pop	dx, ax			;element to push
	inc	ds:[VMTSH_count]

	sub	cx, 4			;cx = offset of new element
	mov	si, cx
	movdw	ds:[si], dxax
	call	MemUnlock
	.leave
	ret
VMTSPush	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTSPop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop from the top of the stack

CALLED BY:	VMTreeReadNextBlock, etc.
PASS:		bx 	= stack handle
RETURN:		carry set if stack is empty, otherwise
		carry clear, and dx:ax = element.
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTSPop	proc	near
	uses	bx,cx,ds,si
	.enter
	call	MemLock
	mov	ds, ax
	tst	ds:[VMTSH_count]
	jz	emptyStack

	dec	ds:[VMTSH_count]
	mov	cx, ds:[VMTSH_count]
	
	;offset for a word size element is 4*cx + size VMTStackHeader.
	shl	cx
	shl	cx
	add	cx, size VMTStackHeader
	mov	si, cx
	movdw	dxax, ds:[si]
	clc
unlockAndExit:
	call	MemUnlock
	.leave
	ret
emptyStack:
	stc
	jmp	unlockAndExit
VMTSPop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTSFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the stack.  Stack cannot be used after this is called.

CALLED BY:	
PASS:		bx 	= stack handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTSFree	proc	near
	call	MemFree
	ret
VMTSFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTSGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of items pushed on the stack.

CALLED BY:	
PASS:		bx	= stack handle
RETURN:		cx	= count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTSGetCount	proc	near
	uses	ax, ds
	.enter
	call	MemLock
	mov	ds, ax
	mov	cx, ds:[VMTSH_count]
	call	MemUnlock
	.leave
	ret
VMTSGetCount	endp

Movable 	ends


