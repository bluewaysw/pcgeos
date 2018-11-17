COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objLinkable.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ObjSwapLockParent	Utility for having fun w/registers
   GLB	ObjLinkCallParent	Call a linkable object's parent object
   GLB	ObjLinkFindParent	Returns linkable object's parent object
   GLB	ObjLinkCallNextSibling	Call a linkable object's sibling(s)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	2/89		Updated DEATH & DESTROY

DESCRIPTION:
	This file contains routines to implement the linkable routines

	$Id: objectLinkable.asm,v 1.1 97/04/05 01:14:27 newdeal Exp $

-------------------------------------------------------------------------------@



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjSwapLockParent

DESCRIPTION:	General object utility routine to lock the parent of an
		object, & save away the child's handle.

CALLED BY:	GLOBAL

PASS:		*ds:si	- object
		bx	- master offset (like VB_offset)
		di	- offset to linkage part (like VI_link)

RETURN:		carry	- set if succesful (clear if no parent)
		*ds:si	- instance data of parent object  (si = 0 if no parent)
		bx	- block handle of original object, which is
			  still locked.


DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	This routine is called an incredible # of times by the UI, & so
	has been optimized for speed, NOT byte savings.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@


ObjSwapLockParent	proc	far
	call	ObjLinkFindParent
	cmp	bx, ds:[LMBH_handle]	; same block?
	jne	differentBlock
EC <	call	CheckLMemObject					>
	stc
	ret

differentBlock:
	tst	bx			; (clears carry)
	jz	returnChildBlock

	push	ax
	call	ObjLockObjBlock		; now *ds:si is parent, ax is child
	mov	bx, ds:[LMBH_handle]	; return original block in bx
	mov	ds, ax
EC <	call	CheckLMemObject					>
	pop	ax
	stc
	ret

returnChildBlock:
	mov	bx, ds:[LMBH_handle]	; return original block handle, 
	ret				; carry clear to indicate parent not
					; found.
ObjSwapLockParent	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjLinkCallParent

DESCRIPTION:	Pass a method to the parent of a linkable object

CALLED BY:	GLOBAL

PASS:
	ax - method number to call
	cx, dx, bp - other data to pass
	*ds:si - instance data of object whose parent is to be called

	bx - offset to MasterClass ptr
	di - offset into MasterPart where LinkPart is

RETURN:
	carry - if no method routine called: 0
		if method routine called: set by method
	ax, cx, dx, bp - return value (if any)
	bx, si, di, es - unchanged
	ds - pointing to the same block as the "ds" passed.  The address could
	     be different since local memory blocks can move while locked.

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	This routine is called an incredible # of times by the UI, & so
	has been optimized for speed, NOT byte savings.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

ObjLinkCallParent	proc	far
	push	bx, si
	call	ObjLinkFindParent	; Find parent object

					; Call OD, but check for in same
					; block (do faster call)
	cmp	bx, ds:[LMBH_handle]		;in same block ?
	jne	differentBlock			;skip if not...
EC <	call	CheckLMemObject					>
	call	ObjCallInstanceNoLock
	pop	bx, si
	ret

differentBlock:
	tst	bx			; clears carry
	jz	done

	push	di
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
done:
	pop	bx, si
	ret

ObjLinkCallParent	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjLinkFindParent

DESCRIPTION:	Find parent OD link for this object's link field

CALLED BY:	GLOBAL

PASS:
	*ds:si  - object instance
	bx - offset to MasterClass ptr to use
	di - offset into MasterPart where LinkPart is

RETURN:
	bx:si	- parent object (or 0, if none)
	ds - unchanged

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	This routine is called an incredible # of times by the UI, & so
	has been optimized for speed, NOT byte savings.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

ObjLinkFindParent	proc	far	uses	bp
	.enter
EC <	call	CheckLMemObject			; make sure real object	>

	mov	bp, bx				; Keep MasterClass offset in
						;	bp for duration
linkLoop:
EC <	call	CheckLMemObject						>
	mov	si, ds:[si]			; ds:si = Instance ptr
	tst	bp
	jz	10$
	add	si, ds:[si][bp]			; ds:si = MasterInstance ptr
10$:
	add	si, di				; ds:si = LinkPart ptr
	mov	bx, ds:[si].LP_next.handle	; bx:si = next obj link
	mov	si, ds:[si].LP_next.chunk	; get next ptr chunk

	test	si, LP_IS_PARENT		; see if parent link
	jnz	foundParentLink			; if LP_IS_PARENT bit
						;	is set, we've found it
	cmp	bx, ds:[LMBH_handle]		; Is next sibling in same block?
	je	linkLoop			; if so, loop to do next
	tst	bx
	jz	foundParentLink

	push	ax, ds
	call	ObjLockObjBlock
linkLoop2:
	mov	ds, ax
EC <	call	CheckLMemObject						>
	mov	si, ds:[si]			; ds:si = Instance ptr
	tst	bp
	jz	20$
	add	si, ds:[si][bp]			; ds:si = MasterInstance ptr
20$:
	add	si, di				; ds:si = LinkPart ptr
	mov	bx, ds:[si].LP_next.handle	; bx:si = next obj link
	mov	si, ds:[si].LP_next.chunk	; get next ptr chunk

	test	si, LP_IS_PARENT		; see if parent link
	jnz	foundParentLink2		; if LP_IS_PARENT bit
						;	is set, we've found it
	cmp	bx, ds:[LMBH_handle]		; Is next sibling in same block?
	je	linkLoop2			; if so, loop to do next

	tst	bx
	je	foundParentLink2		; If handle is 0, then isn't
						;	connected
	call	ObjLockObjBlock			; lock next block
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock			; unlock old block
	jmp	linkLoop2			; and go lock new

foundParentLink2:
	call	UnlockDS			; Release current block. If ds
						;  didn't change during the
						;  loop, we still need to
						;  release the extra lock we
						;  put on the thing at lockLoop
	pop	ax, ds

foundParentLink:
	andnf	si, not LP_IS_PARENT		; clear flag, to get OD
	.leave
	ret

ObjLinkFindParent	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjLinkCallNextSibling (ObjLinkCallLittleBro')

DESCRIPTION:	Pass a method to the next sibling of a linkable object

CALLED BY:	GLOBAL

PASS:
	ax - method number to call
	cx, dx, bp - other data to pass
	*ds:si - instance data of object whose sibling is to be called

	bx - offset to MasterClass ptr
	di - offset into MasterPart where LinkPart is

RETURN:
	carry - if no method routine called: 0
		if method routine called: set by method
	ax, cx, dx, bp - return value (if any)
	bx, si, di, es - unchanged
	ds - pointing to the same block as the "ds" passed.  The address could
	     be different since local memory blocks can move while locked.

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@


ObjLinkCallNextSibling	proc	far
	push	bx, si
EC <	call	CheckLMemObject						>

	;get next sibling/parent link

	push	bp
	mov	bp, bx				;Keep MasterClass offset in
						;	bp for duration
	mov	si, ds:[si]			; ds:si = Instance ptr
	tst	bp
	jz	10$
	add	si, ds:[si][bp]			; ds:si = MasterInstance ptr
10$:
	add	si, di				; ds:si = LinkPart ptr
	mov	bx, ds:[si].LP_next.handle	; bx:si = next obj link
	mov	si, ds:[si].LP_next.chunk	; get next ptr chunk
	pop	bp

	;bx:*si is link to sibling/parent

	test	si, LP_IS_PARENT		;see if parent link
						;  (AND clear the carry flag)
	jnz	done				;skip to end if so (no sib)...
						;  returning carry clear

	or	bx, bx				;is anything connected?
						;  (AND clear the carry flag)
	jz	done				;skip if not..., returning
						;  carry clear

	;bx:si is handle of sibling, may be in different block
					; Call OD, but check for in same
					; block (do faster call)
	cmp	bx, ds:[LMBH_handle]		;in same block ?
	jne	differentBlock			;skip if not...
	call	ObjCallInstanceNoLock
	pop	bx, si
	ret

differentBlock:
	push	di
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
done:
	pop	bx, si
	ret

ObjLinkCallNextSibling	endp

