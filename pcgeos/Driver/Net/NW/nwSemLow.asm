COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		NetWare Driver
FILE:		semLow.asm (low-level NetSem code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version
	Eric	8/92		Ported to 2.0.

DESCRIPTION:
	see semHigh.asm.

RCS STAMP:
	$Id: nwSemLow.asm,v 1.1 97/04/18 11:48:42 newdeal Exp $

------------------------------------------------------------------------------@
;substituted by nwSimpleSem.asm

if 0


NetWareCommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareOpenSem_FindItemByNameCallback

DESCRIPTION:	Find the NetSemDataItem which matches the passed name

CALLED BY:	

PASS:		ds	= SemData block
		ss:bp	= NetOpenSem_Frame

RETURN:		nothing

DESTROYED:	es, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareOpenSem_FindItemByNameCallback	proc	far
	vars	local	NOS_Frame
	.enter inherit

	mov	si, ds:[di]+0		;*ds:si = NetSemDataItem

	push	si
	mov	si, ds:[si]
EC <	cmp	ds:[si].NSDI_protect, NSDI_PROTECT			>
EC <	ERROR_NE NW_ERROR						>

	;compare names

	add	si, offset NSDI_name	;ds:si = name, after initial 'GEOS'

	mov	di, vars.NOS_name.segment
	mov	es, di
	mov	di, vars.NOS_name.offset

	mov	cx, NET_SEMAPHORE_NAME_LENGTH	;compare 128 chars max

10$:	;compare strings, ending at null term.

	cmp	byte ptr ds:[si], 0
	jne	20$

	cmp	byte ptr es:[di], 0
	je	50$			;exact match...

20$:
	cmpsb
	jne	50$

	loop	10$

50$:
	pop	si
	clc
	jne	done

	;stop processing here

	stc
	mov	dx, si

done:
	.leave
	ret
NetWareOpenSem_FindItemByNameCallback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareOpenSem_CreateNewItem

DESCRIPTION:	

CALLED BY:	

PASS:		ds	= SemDataBlock
		ss:bp	= stack frame

RETURN:		ds	= same
		*ds:ax	= new item in LMem heap

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareOpenSem_CreateNewItem	proc	near
	vars	local	NOS_Frame
	.enter inherit

;------------------------------------------------------------------------------
	;find length of source string

	mov	di, vars.NOS_name.segment ;es:di = source name
	mov	es, di
	mov	di, vars.NOS_name.offset

	mov	cx, NET_SEMAPHORE_NAME_LENGTH
	clr	al
	repne	scasb			;es:di = byte after null term
EC <	ERROR_NE NW_ERROR		;no null term!			>

	sub	di, vars.NOS_name.offset ;di = length of source string
	inc	di			;include null term

;------------------------------------------------------------------------------
	;create a new chunk, large enough to hold this item

	mov	cx, di			;cx = length of name (with null term)
	add	cx, size NetSemDataItem	;add room for rest of structure
	clr	al
	call	LMemAlloc		;*ds:ax = new chunk

	mov	cx, di			;cx = length of name (with null term)
	mov	di, ax			;*ds:di = chunk

;------------------------------------------------------------------------------
	;allocate a PC/GEOS semaphore

	call	NetWareOpenSem_AllocateAccessSem
					;trashes es
					;returns ^hbx = semaphore

	segmov	es, ds, ax		;*es:di = chunk

	push	di
	mov	di, es:[di]		;es:di = chunk

	mov	si, vars.NOS_name.segment ;ds:si = source name
	mov	ds, si
	mov	si, vars.NOS_name.offset

;------------------------------------------------------------------------------
	;fill in the NetSemDataItem structure

EC <	mov	es:[di].NSDI_protect, NSDI_PROTECT			>

	mov	es:[di].NSDI_inUseCount, 1

	mov	es:[di].NSDI_accessSem, bx

;	mov	ax, vars.NOS_scope
	clr	ax
	mov	es:[di].NSDI_scope, ax

	mov	ax, vars.NOS_pollInterval
	mov	es:[di].NSDI_pollInterval, ax

;------------------------------------------------------------------------------
	;and append the name to the end

	push	di
	add	di, offset NSDI_nameRoot
	push	di
	mov	al, 'G'			;highly un-localizable!
	stosb

	mov	al, 'E'
	stosb

	mov	al, 'O'
	stosb

	mov	al, 'S'
	stosb

	;copy name into chunk

	rep	movsb
	pop	di			;es:di = name string

;------------------------------------------------------------------------------
	;last but not least, call Network driver to actually Open this
	;semaphore, and then save its handle
	;pass:	es:di	= null term string

	mov	cx, vars.NOS_initialValue ;pass cx = initial value

	push	bp
	call	NetWareCallOpenSemaphore ;trashes EVERYTHING except es:di
	pop	bp
	pop	di			;es:di = NetSemDataItem

EC <	cmp	es:[di].NSDI_protect, NSDI_PROTECT			>
EC <	ERROR_NE NW_ERROR						>

	mov	es:[di].NSDI_netBasedSem.high, cx
	mov	es:[di].NSDI_netBasedSem.low, dx

;------------------------------------------------------------------------------
	;restore ds = SemData block, and return

	segmov	ds, es, ax
	pop	ax			;*ds:ax = new item in LMem heap

	.leave
	ret
NetWareOpenSem_CreateNewItem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareOpenSem_AllocateAccessSem

DESCRIPTION:	Allocate a PC/GEOS semaphore, which we will use to restrict
		access to the network-based semaphore (we only want one
		thread at a time polling the network-based semaphore).

CALLED BY:	NetOpenSem_CreateNewItem

PASS:		dgroup:semDataSem GRABBED

RETURN:		dgroup:semDataSem = same
		bx	= offset to semaphore to use, in dgroup
		
		For 2.0:
			^hbx	= semaphore

DESTROYED:	es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareOpenSem_AllocateAccessSem	proc	near
	uses	di, cx
	.enter

	segmov	es, <segment dgroup>, ax
	mov	di, 0 - (size Semaphore)
	mov	cx, HACK_MAX_NUM_ACCESS_SEMAPHORES

10$:
	add	di, (size Semaphore)
	cmp	word ptr es:[hackAccessSemFlags][di], 0
	jz	20$

	loop	10$			;loop if already taken...

PrintMessage <FIX FOR NON-EC>
	ERROR NW_ERROR

20$:
	mov	word ptr es:[hackAccessSemFlags][di], 1

	add	di, offset dgroup:hackAccessSemList
					;es:di = semaphore to use

	mov	bx, di			;es:bx = semaphore to use

	.leave
	ret
NetWareOpenSem_AllocateAccessSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareOpenSemGetSemDataBlock

DESCRIPTION:	

CALLED BY:	NetWareOpenSem

PASS:		es	= dgroup

RETURN:		ds	= SemDataBlock
		*ds:si	= chunkarray containing NetSemDataItems
		es	= same (dgroup)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareOpenSemGetSemDataBlock	proc	near

	mov	bx, es:[semData]
	tst	bx
	jnz	lockBlock

	;first, allocate a global memory block to hold our local memory heap

	mov	ax, INITIAL_SEM_DATA_BLOCK_SIZE
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
					;allocate as HF_SWAPABLE and HAF_LOCK
					;(DO NOT set HF_LMEM here!)
	mov	bx, handle 0		;set this block to owned by this
					;library, NOT the geode whose thread
					;we are running in.
	call	MemAllocSetOwner	;returns bx = handle of block

	;save handle

	mov	es:[semData], bx

	mov	ds, ax			;set DS = segment of block (is locked)

	;now set up a local heap within this block

	mov	dx, size NetSemDataBlockStruct
					;leave room for our header structure
					;at the beginning of the block.
	mov	si, INITIAL_SEM_DATA_BLOCK_SIZE-100
					;amount of space to allocate initially
	mov	cx, 20			;we will only need about 20 handles
					;in this LMem heap.
	mov	ax, LMEM_TYPE_GENERAL	;type of heap to create
	clr	di			;no LocalMemoryFlags to set.
	call	LMemInitHeap

EC <	mov	ds:[NSDB_protect], NSDB_PROTECT				>

	;now allocate the semList chunk array, without any items in it.
	;It will be resized as we add items.

	mov	bx, size AccessSemaphoreHandle
	clr	cx			;no extra space at start of array
	clr	al
	clr	si
	call	ChunkArrayCreate	;returns si = chunk array handle
	mov	ds:[NSDB_semList], si
					;save handle of AccessSemaphoreHandle
					;chunk array
	jmp	short done

lockBlock:
	call	MemLock
	mov	ds, ax
	mov	si, ds:[NSDB_semList]

done:
EC <	cmp	ds:[NSDB_protect], NSDB_PROTECT				>
EC <	ERROR_NE NW_ERROR						>

	ret
NetWareOpenSemGetSemDataBlock	endp


endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECNetWareCheckSemHandle

DESCRIPTION:	

CALLED BY:	

PASS:		ds	= SemDataBlock
		*ds:si	= chunk array containing handles of NetSemDataItems

RETURN:		ds	= same
		*ds:si	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@
;if ERROR_CHECK
if 0

ECNetWareCheckSemHandle	proc	near
	uses	ax, di, dx
	.enter

	;find the item in the list for this semaphore

	call	NetWareSemFindSemInList
	ERROR_NC NW_ERROR		;fail if not found

	;now see if the chunk contains valid stuff

	mov	di, cx			;*ds:di = NetSemDataItem
	mov	di, ds:[di]		;ds:di = NetSemDataItem
	cmp	ds:[di].NSDI_protect, NSDI_PROTECT
	ERROR_NE NW_ERROR

	.leave
	ret
ECNetWareCheckSemHandle	endp

endif

if 0

COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareSemFindSemInList

DESCRIPTION:	

CALLED BY:	

PASS:		ds	= SemDataBlock
		*ds:si	= chunk array containing handles of NetSemDataItems

RETURN:		ds	= same
		*ds:si	= same

		carry set if found it
		ds:di	= pointer to chunk handle in the chunkarray list.

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareSemFindSemInList	proc	near
	uses	bx, dx
	.enter

	;verify that ds = SemDataBlock

EC <	cmp	ds:[NSDB_protect], NSDB_PROTECT				>
EC <	ERROR_NE NW_ERROR						>

EC <	cmp	si, ds:[NSDB_semList]					>
EC <	ERROR_NE NW_ERROR						>

	;scan the block for a semaphore having this handle

	clr	dx
	mov	bx, cs
	mov	di, offset NetWareSemFindSemInList_callback
	call	ChunkArrayEnum		;returns ds:dx = pointer to item
					;chunk handle in list

	tst	dx
	clc
	jz	done

	;return with carry set and ds:di = pointer to item in list if
	;found it.

	stc
	mov	di, dx

done:
	.leave
	ret
NetWareSemFindSemInList	endp


NetWareSemFindSemInList_callback	proc	far
	cmp	ds:[di], cx
	clc
	jne	done

	;found it

	mov	dx, di
	stc

done:
	ret
NetWareSemFindSemInList_callback	endp

NetWareCommonCode	ends


endif
