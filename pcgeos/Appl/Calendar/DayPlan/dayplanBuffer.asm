COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Dayplan
FILE:		dayPlanBuffer.asm

AUTHOR:		Don Reeves, December 18, 1989

ROUTINES:
	Name			Description
	----			-----------
	BufferAllocFromBack	Allocate (guaranteed) buffer.  Steal from back
	BufferAlloc		Allocate a free buffer (may fail).
	BufferFree		Free a buffer, causing writeback
	BufferAllWriteAndFree	Write and possibly free all buffers in use
	BufferWriteBack		Writeback a single buffer to the database
	BufferUpdateAllInUse	Force writeback of all buffers in use
	BufferEnsureEnough	Ensure enough buffers for screen size
	BufferCreate		Create a new buffer
	BufferFreeMem		Free memory associated with unused buffers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/18/89	Initial revision

DESCRIPTION:
	Contains the code to implement the DayEvent buffer system
		
	$Id: dayplanBuffer.asm,v 1.1 97/04/04 14:47:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BUFFER_USED	equ 0x0001

DayPlanCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferVerifyFreeBuffer, BufferVerifyUsedBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the passed handle is either used or free, 
		according to the buffer table.

CALLED BY:	GLOBAL
	
PASS:		DS	= DPResource
		AX	= DayEvent buffer handle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
if	0
BufferVerifyFreeBuffer	proc	near
	uses	ax, dx
	.enter

	; Find the buffer, and verify its non-usage
	;
	call	BufferFindBuffer
	test	dx, BUFFER_USED
	ERROR_NZ	BUFFER_VERIFY_NOT_FREE

	.leave
	ret
BufferVerifyFreeBuffer	endp
endif

BufferVerifyUsedBuffer	proc	near
	uses	ax, dx
	.enter

	; Find the buffer, and verify its non-usage
	;
	call	BufferFindBuffer
	test	dx, BUFFER_USED
	ERROR_Z		BUFFER_VERIFY_NOT_USED

	.leave
	ret
BufferVerifyUsedBuffer	endp

BufferFindBuffer	proc	near
	class	DayPlanClass
	uses	cx, si
	.enter

	; Some set-up work
	;
	mov	si, offset DPResource:DayPlanObject
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; acces the instance data
	mov	si, ds:[si].DPI_bufferTable	; access the buffer table
	mov	si, ds:[si]			; dereference the handle
	clr	ch
	mov	cl, ds:[si].BTH_buffers		; number of buffers => CX
	add	si, size BufferTableHeader	; initial offset

	; Now loop until buffer found or end of the table
	;
findLoop:
	mov	dx, ds:[si].BTE_handle		; buffer handle DX
	andnf	dx, not BUFFER_USED		; clear in-use bit
	cmp	ax, dx				; compare the buffer handles
	je	found				; OK, continue
	add	si, size BufferTableEntry	; go to the next entry
	loop	findLoop			; loop on count in CX
	ERROR	BUFFER_VERIFY_BUFFER_NOT_FOUND
found:
	mov	dx, ds:[si].BTE_handle		; reload DX with BTE_handle
	
	.leave
	ret
BufferFindBuffer	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferAllocNoErr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a buffer.  If none available, steal a buffer either
		from the top or bottom of the screen.

CALLED BY:	GLOBAL

PASS:		DS	= DayPlan segment handle
		DL	= ScreenUpdateFlags
				SUF_STEAL_FROM_BOTTOM
				SUF_STEAL_FROM_TOP
		BX	= Destination offset for buffer in EventTable

RETURN:		AX	= DayEvent handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		There is a rather large kludge in this routine. Basically,
		if I determine that the "steal" flag cannot be used, I
		override it. The case can only arise when inserting a
		new event, and hence can only override the STEAL_FROM_BOTTOM
		case. This is why the destination offset must be passed,
		so I can compare it against the "screenLast" offset.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferAllocNoErr	proc	near
	class	DayPlanClass
	.enter

	call	BufferAlloc			; attempt to allocate
	jnc	done				; easy, buffer available

	; Else steal from the back
	;
	push	bx, si
	mov	si, offset DPResource:DayPlanObject
	mov	si, ds:[si]			; dereference the chunk handle
	add	si, ds:[si].DayPlan_offset	; access my instance data
	mov	si, ds:[si].DPI_eventTable	; acess the event table chunk
	mov	si, ds:[si]			; dereference the handle
	test	dl, SUF_STEAL_FROM_BOTTOM	; steal from the bottom ??
	jnz	fromBottom
EC <	test	dl, SUF_STEAL_FROM_TOP		; just to make sure	>
EC <	ERROR_Z	BUFFER_ALLOC_NO_ERR_NO_STEAL_FLAG_SET			>
fromTop:
	mov	bx, ds:[si].ETH_screenFirst	; first offset => BX
	add	ds:[si].ETH_screenFirst, size EventTableEntry
	jmp	common
fromBottom:
	cmp	bx, ds:[si].ETH_screenLast	; compare with last on screen
	ja	fromTop				; if larger, steal from the top
	mov	bx, ds:[si].ETH_screenLast	; last offset => BX
	sub	ds:[si].ETH_screenLast, size EventTableEntry
common:
	clr	ax
	xchg	ax, ds:[si][bx].ETE_handle	; get handle, store 0
EC <	mov	si, ax				; DayEvent => DS:*SI	>
EC <	call	ECCheckLMemObject		; verify valid object	>
	mov	bl, BufferUpdateFlags <1, 0, 1>	; write back & delete
	call	BufferWriteBack
	pop	bx, si

done:
	.leave
	ret
BufferAllocNoErr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a DayEvent buffer. If none, return error

CALLED BY:	GLOBAL

PASS:		DS	= DPResource block

RETURN:		AX	= DayEvent handle
		Carry	= Clear if valif handle
			= Set if no buffers available

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferAlloc	proc	near
	class	DayPlanClass
	uses	bx, si
	.enter

	; Some set-up work
	;
	mov	si, offset DPResource:DayPlanObject
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; acces the instance data
	mov	si, ds:[si].DPI_bufferTable	; access the buffer table
	mov	si, ds:[si]			; dereference the handle
	mov	bx, size BufferTableHeader	; initial offset

	; Now loop until buffer found or end of the table
	;
allocLoop:
	test	ds:[si][bx].BTE_handle, BUFFER_USED
	jz	found				; buffer found if not set
	add	bx, size BufferTableEntry	; go to the next entry
	cmp	bx, ds:[si].BTH_size		; total size of the table
	jl	allocLoop
	stc					; fail - set carry
	jmp	done				; we're outta here
found:
	mov	ax, ds:[si][bx].BTE_handle	; move the handle to AX
	or	ds:[si][bx].BTE_handle, BUFFER_USED	; also clears the carry
done:
	.leave		
	ret
BufferAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up a DayEvent buffer (also writes-back to the database)

CALLED BY:	GLOBAL

PASS:		DS	= DPResource block
		AX	= DayEvent handle

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferFreeFar	proc	far
	call	BufferFree
	ret
BufferFreeFar	endp


BufferFree	proc	near
	class	DayPlanClass
	uses	bx, si
	.enter

	; Some set-up work
	;
	mov	si, offset DPResource:DayPlanObject
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; acces the instance data
	mov	si, ds:[si].DPI_bufferTable	; access the buffer table
	mov	si, ds:[si]			; dereference the handle
EC <	mov	bx, ds:[si].BTH_size		; total size of the table >
EC <	add	bx, si				; BX holds final address  >
	add	si, (size BufferTableHeader - size BufferTableEntry)
	or	ax, BUFFER_USED			; set the in-use bit

	; Now loop until the buffer is found
	;
freeLoop:
	add	si, size BufferTableEntry	; go to the next entry
EC <	cmp	si, bx							>
EC <	ERROR_GE DP_BUFFER_FREE_BAD_HANDLE				>
	cmp	ds:[si].BTE_handle, ax		; correct buffer to free ?
	jne	freeLoop			; loop if not equal

	; Set this buffer as unused, and write-back to the database
	;
	and	ax, (not BUFFER_USED)		; clear the bit mask
	mov	ds:[si].BTE_handle, ax		; re-store the buffer handle
	mov	bl, BufferUpdateFlags <1, 1, 1>	; write back & remove
	call	BufferWriteBack

	.leave
	ret
BufferFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferAllWriteAndFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up all the buffers (and perform write-back)

CALLED BY:	GLOBAL

PASS:		DS	= DPResource block
		CL	= BufferUpdateFlags

RETURN:		AX	= 0 if something updated
			= <> 0 if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/15/89	Initial version
	Don	3/21/90		Added just the writeback idea

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferAllWriteAndFree	proc	far
	class	DayPlanClass
	uses	bx, si, bp
	.enter

	; Some set-up work
	;
EC <	test	cl, not mask BufferUpdateFlags				>
EC <	ERROR_NZ	BUFFER_BAD_UPDATE_FLAGS				>
	mov	si, offset DPResource:DayPlanObject
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access the instance data
	mov	di, ds:[si].DPI_bufferTable	; get buffer table handle
	mov	si, ds:[di]			; dereference the handle
	mov	bp, size BufferTableHeader
	mov	bl, cl				; flags => BL
	mov	bh, 1				; assume no changes

	; Just loop, dude
	;
freeLoop:
	test	ds:[si][bp].BTE_handle, BUFFER_USED	; is the low bit set
	jz	next					; no, forget about it
	test	bl, BUF_DELETE			; are we going to delete ??
	jz	doCall				; no, so don't free buffer
	and	ds:[si][bp].BTE_handle, not BUFFER_USED
doCall:
	mov	ax, ds:[si][bp].BTE_handle	; DayEvent handle to AX
	and	ax, not BUFFER_USED		; clear the buffer used bit
	call	BufferWriteBack			; write back & delete
	mov	si, ds:[di]			; dereference the handle
	jnc	next				; if no carry, no update
	clr	bh				; else signify an update
next:
	add	bp, size BufferTableEntry
	cmp	bp, ds:[si].BTH_size
	jl	freeLoop

	; Clean up by leaving value in AX
	;
	clr	ah				
	mov	al, bh				; 0 if update, non-zero if not

	; Now let's do some nasty ink work
	;
	push	ax, cx, dx			; BP & SI are already preserved
	mov	ax, MSG_DP_STORE_INK
	mov	si, offset DPResource:DayPlanObject
	call	ObjCallInstanceNoLock	
	pop	ax, cx, dx			; restore registers
	
	.leave
	ret
BufferAllWriteAndFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferWriteBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write back and visually remove the DayEvent

CALLED BY:	GLOBAL

PASS:		DS	= DPResource block
		AX	= DayEvent handle
		BL	= BufferUpdateFlags

RETURN:		Carry	= Set if updated
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferWriteBack	proc	near
	uses	ax, cx, dx, bp, si
	.enter

	; Update the database
	;
	mov	si, ax				; DayEvent handle => SI
	test	bl, BUF_WRITE_BACK		; remove ??
	jz	notifyDP			; if no, try to notify the DP
	mov	cl, DBUF_IF_NECESSARY		; update if necessary
	mov	ax, MSG_DE_UPDATE		; update the database 
	call	ObjCallInstanceNoLock		; text now saved
	tst	ax				; check the return value
	jnz	notifyDP			; if non-zero, continue
	stc					; else set the carry
	
	; Remove "pointer" to the buffer in the EventTable
	;
notifyDP:
	pushf					; save the flags
	mov	bp, si				; DayEvent handle => BP
	test	bl, BUF_NOTIFY_DAYPLAN		; notify the DayPlan
	jz	delete				; no, so leave
	mov	ax, MSG_DP_ETE_LOST_BUFFER
	mov	si, offset DPResource:DayPlanObject
	call	ObjCallInstanceNoLock

	; Visually close & remove the event
	;
delete:
	test	bl, BUF_DELETE			; delete the event ??
	jz	done				; no, so done
	mov	si, bp				; DayEvent handle => SI
	mov	ax, MSG_VIS_CLOSE		; close up the event
	call	ObjCallInstanceNoLock
	mov	dx, si
	mov	cx, ds:[LMBH_handle]		; DayEvent => CX:DX
	clr	bp				; no need to dirty things
	mov	ax, MSG_VIS_REMOVE_CHILD	; remove from the DayPlan
	mov	si, offset DPResource:DayPlanObject
	call	ObjCallInstanceNoLock
done:
	popf					; restore the flags

	.leave
	ret
BufferWriteBack	endp

DayPlanCode	ends



ObscureCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferFreeMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell all free buffers (DayEvents) to free as much memory as
		possible.

CALLED BY:	GLOBAL
	
PASS:		DS:*SI	= DayPlanObject instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferFreeMem	proc	near
	class	DayPlanClass
	uses	si
	.enter

	; Some set-up work
	;
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access the instance data
	mov	di, ds:[si].DPI_bufferTable	; get buffer table handle
	mov	si, ds:[di]			; dereference the handle
	mov	bp, size BufferTableHeader
	mov	cl, ds:[si].BTH_buffers
	clr	ch				; # of buffers => CX

	; Just loop, dude
freeLoop:
	test	ds:[si][bp].BTE_handle, BUFFER_USED	; is the buffer in use?
	jnz	next					; yes,so don't touch it
	mov	ax, MSG_DE_FREE_MEM
	mov	si, ds:[si][bp].BTE_handle	; DayEvent => DS:*SI
	call	ObjCallInstanceNoLock		; send the method
	mov	si, ds:[di]			; dereference the table handle
next:
	add	bp, size BufferTableEntry	; go to the next entry
	loop	freeLoop			; loop on count in CX	

	.leave
	ret
BufferFreeMem	endp

ObscureCode	ends



GeometryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferEnsureEnough
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make certain there are sufficient buffers for the screen
		height.

CALLED BY:	GLOBAL

PASS: 		DS:*SI	= DayPlan instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferEnsureEnough	proc	far
	class	DayPlanClass
	uses	si
	.enter

	; Some set-up work
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access insance data
	mov	bp, ds:[di].DPI_bufferTable
	mov	bp, ds:[bp]			; dereference the handle
	
	; Determine if there are enough	buffers
	;
	mov	ax, ds:[di].DPI_viewHeight
	mov	cx, ds:[di].DPI_textHeight
	div	cl
	tst	ah
	je	BufferCheck
	inc	al				; add fractional buffer
BufferCheck:
	inc	al				; add one for safety
	sub	al, ds:[bp].BTH_buffers		; compare the buffers
	jle	done				; jump if enough

	; First resize the buffer table
	;
	push	ax				; save the count
	add	ds:[bp].BTH_buffers, al		; change the count
	mov	cl, al
	shl	cl, 1				; calc size to add
	clr	ch
	add	cx, ds:[bp].BTH_size		; total size to CX
	mov	ax, ds:[di].DPI_bufferTable
	call	LMemReAlloc			; resize the table
	mov	si, ax
	mov	di, ds:[si]			; dereference the handle
	mov	bx, ds:[di].BTH_size		; old size to BX
	mov	ds:[di].BTH_size, cx		; store the new size
	pop	ax				; restore the count
	
	; Now loop, creating the buffers
	;	
createLoop:
	mov	di, offset DayEventClass	; parent class to create
	call	BufferCreate
	mov	di, ds:[si]			; dereference the table handle
	mov	ds:[di][bx].BTE_handle, dx	; store the handle
	add	bx, size BufferTableEntry
	dec	al
	jg	createLoop			; loop until done
done:
	.leave
	ret
BufferEnsureEnough	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufferCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new DayEvent (DayEvent, TimeText, EventText)

CALLED BY:	BufferEnsureEnough, DayPlanCreatePrintEvent

PASS:		ES:DI	= Parent class (DayEvent or PrintEvent)
		DS	= Block in which to create new Event

RETURN:		CX:DX	= Block:Chunk of new event

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/27/89		Initial version
	Don	12/4/89		Changed to VisText objects
	Don	1/11/90		Changed to MyText object
	Don	8/13/90		Commented out unecessary code
	Chris	7/ 3/91		Fixed assumption that cx was preserved
	sean	7/27/95		Responder change
	sean	2/5/96		Responder font changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufferCreate	proc	far
	class	DayPlanClass			; friend to this class
	uses	ax, bx, di, si, bp
	.enter
	
	; Create the event text & time MyTextClass objects
	;
EC <	call	ECCheckClass						>
	mov_tr	ax, di				; save class
	mov	bx, ds:[LMBH_handle]		; block to hold new objects
	mov	di, offset MyTextClass		; class of object to create
	call	ObjInstantiateAndIgnoreDirty	; create first TextObject
	push	si				; save the handle
	call	ObjInstantiateAndIgnoreDirty	; create second TextObject

	; Don't want underlines for time text object in Responder
	;
	mov	dx, si
	mov_tr	di, ax				; parent class to create
	call	ObjInstantiateAndIgnoreDirty	; create the DayEvent

	; Now set up the children
	;
	mov	cx, bx				; CX:DX is the first child
	mov	bp, CCO_FIRST			; the 1st child
	mov	ax, MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock
	pop	dx				; CX:DX is the last child
	mov	bp, CCO_LAST			
	mov	ax, MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock

	; Set up the text handles for the DayEvent
	;
	mov	ax, MSG_DE_SET_HANDLES
	call	ObjCallInstanceNoLock
	mov	dx, si				; CX:DX is the DayEvent

	.leave
	ret
BufferCreate	endp

ObjInstantiateAndIgnoreDirty	proc	near
	uses	ax, bx
	.enter

	call	ObjInstantiate
	mov	ax, si
	mov	bx, mask OCF_IGNORE_DIRTY	; bits to set => BL, reset => BH
	call	ObjSetFlags

	.leave
	ret
ObjInstantiateAndIgnoreDirty	endp		



GeometryCode	ends


