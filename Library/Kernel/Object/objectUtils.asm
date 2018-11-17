COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Object
FILE:		objUtils.asm

ROUTINES:
	Name			Description
	----			-----------
	ObjResizeMaster
	ObjInitializeMaster
	ObjInitializePart
	ObjGetFlags
	ObjSetFlags
	ObjMarkDirty
	ObjIncInUseCount
	ObjDecInUseCount
	ObjIncInteractibleCount
	ObjDecInteractibleCount
	ObjSwapLock
	ObjSwapUnlock
	ObjIsObjectInClass	Determine if object is of a certain class
	ObjBlockSetOutput	Set OLMBH_output field of object block
	ObjBlockGetOutput	Get OLMBH_output field

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	11/89		Added ObjInc/DecInUseCount, ObjSwap(Un)lock

DESCRIPTION:
	This file contains routines to load a GEODE and execute it.

	$Id: objectUtils.asm,v 1.1 97/04/05 01:14:33 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjResizeMaster

DESCRIPTION:	Resize a master class part of an object

CALLED BY:	GLOBAL

PASS:
	*ds:si - object
	bx - offset of offset to master part to expand
	ax - new size for master part

RETURN:
	ds - possibly changed due to global realloc

DESTROYED:
	ax
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	lastMaster = object->class).Class_masterOffset
	if (offsetPassed == lastMaster) {
		curSize = (size of object) - curOffset
	} else {
		curSize = (next offset) - curOffset
	}
	temp = current size of part

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjResizeMaster	proc	far	uses	cx, dx, di, bp, es
	.enter
EC <	call	CheckLMemObject					>

	mov	di,ds:[si]
	les	bp,ds:[di].MB_class		;es:bp = class
	mov	cx,es:[bp].Class_masterOffset	;get object's master offset

	; cx = address of object's last master offset

	; If the master offset isn't the same as that of the object's class,
	; it must be one of the superclass master levels and, by definition,
	; ALL LEVELS BELOW IT MUST ALREADY BE BUILT
	; 
	cmp	bx, cx
	jb	figureEndFromNext
	
	mov	dx, ds:[di][bx]
	tst	dx
	jz	nothingGrown

	; resizing final thing, so the size of the current part is the
	; es:[bp].Class_instanceSize, unless the master ptr is 0
	
	add	dx, es:[bp].Class_instanceSize
	jmp	haveEnd

nothingGrown:
	; beastie has no data at all, so end of master part is end of
	; the base structure

	mov	dx, cx
	inc	dx
	inc	dx
	jmp	haveEnd

figureEndFromNext:
	push	bx
findNextLoop:
	inc	bx
	inc	bx

	; make sure we've not gone past the final master offset for the
	; object. This should never, ever happen, since even if the object
	; is of a DISCARD_ON_SAVE class, that data won't go away unless there's
	; a variant master below it, which there isn't, by assumption.
	; this could happen if someone willfully resizes the final master
	; part to 0, I suppose, but...
EC <	cmp	bx, cx							>
EC <	ERROR_A	GASP_CHOKE_WHEEZE					>
	mov	dx, ds:[di][bx]
	tst	dx
	jz	findNextLoop
	pop	bx

haveEnd:
	; dx = end of the master part
	;
	; if the master part has no data, dx is the offset at which we'll
	; be inserting things, so set it as the offset for the master part
	; being resized.
	tst	{word}ds:[di][bx]
	jnz	figureSize

	mov	ds:[di][bx], dx

figureSize:
	;
	; Now figure how many bytes are currently in the master part.
	; 
	sub	dx, ds:[di][bx]

	; dx = current part size
	; ax = new size

	sub	ax,dx				;determine type of resize
	jz	done

	; while we are resizing the object we *don't* want to mark it as
	; dirty, thus we save the flags and restore them

	push	ax
	push	bx
	push	cx
	mov_tr	cx,ax				;cx = +/- # bytes
	mov	ax,si				;ax = chunk
	call	ObjGetFlags			;al = flags
	push	ax
	mov	ax, si
	mov	bx,ds:[di][bx]			;bx = offset to delete at
	tst	cx
	jns	larger

	; resizing smaller -- Use LMemDeleteAt

	neg	cx				;cx = # bytes to delete
	add	bx, dx				;want to truncate the group
	sub	bx, cx				; rather than removing from the
						; front, so set bx to be cx
						; bytes from the end of the
						; master data; this is required
						; by MailboxAddressControl for
						; it to change its class before
						; unloading the transport
						; driver -- ardeb 11/4/94
	call	LMemDeleteAt
	jmp	common


	; resizing larger -- Use LMemInsertAt

larger:
	add	bx,dx				;insert at end of master part
	call	LMemInsertAt

common:
	pop	bx				;bx = flags
	mov	bh, mask ObjChunkFlags
	call	ObjSetFlags

	pop	cx
	pop	bx
	pop	ax

	; fix all offsets after one changed

	mov	di,ds:[si]
	push	bx
updateLoop:
	inc	bx
	inc	bx
	cmp	bx,cx
	ja	updateDone

	cmp	word ptr ds:[di][bx],0
	jz	updateLoop

	add	ds:[di][bx],ax
	jmp	updateLoop

updateDone:
	pop	bx
done:
	.leave
	ret

ObjResizeMaster	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ResolveVariant

DESCRIPTION:	Determine what class a variant is to be

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	es:di - variant class to build

RETURN:
	es:di - new class (di = 0 if not resolved)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ResolveVariant	proc	near	uses ax, bx, cx, dx, bp
	.enter
EC <	call	CheckLMemObject						>
EC <	call	CheckClass						>

	mov	ax, MSG_META_RESOLVE_VARIANT_SUPERCLASS ;Initialize the object
	mov	cx,es:[di].Class_masterOffset
	mov	bx,cx
	call	ObjCallInstanceNoLock	;Returns cx:dx = class

	mov	di,ds:[si]		;point at instance
	add	di,ds:[di][bx]		;make di point at part
	mov	ds:[di].segment,cx
	mov	ds:[di].offset,dx
	mov	di,dx
	mov	es,cx

EC <	call	CheckClass						>

	.leave
	ret

ResolveVariant	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjInitializeMaster

DESCRIPTION:	Initialize a master part of an object

CALLED BY:	GLOBAL

PASS:
	*ds:si - object
	es:di - class of part to initialize

RETURN:
	carry - set
	ds - possibly changed

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
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjInitializeMaster	proc	far
	push	ax, bx, cx, dx, di, bp
EC <	call	CheckLMemObject					>
EC <	call	CheckClass						>
	mov	ax,es:[di].Class_instanceSize
	mov	bx,es:[di].Class_masterOffset
	call	ObjResizeMaster
	mov	ax,MSG_META_INITIALIZE	;Initialize the object
	call	ObjCallClassNoLock
	pop	ax, bx, cx, dx, di, bp
	stc
	ret

ObjInitializeMaster	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjInitializePart

DESCRIPTION:	Ensures that the object is expanded, and initialized
	if necessary, for all master parts down through the one passed.  Sends
	MSG_META_RESOLVE_VARIANT_SUPERCLASS to any master parts above the one passed, if the
	variable class had not yet been determined (this necessary to get down
	to the part passed)

CALLED BY:	GLOBAL

PASS:
	*ds:si - object
	bx - offset to part to build

RETURN:
	ds - possibly changed

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	/* Start at class of object */
	curClass := *ds:si.MB_class;

	/* & loop through each master level, building until dest. found */
	loop {

	    /* If current master part not yet built out, do so */
	    if (*(ds:si).(curClass.Class_masterOffset) == 0)
	    		ObjInitializeMaster(*ds:si, curClass);

	    /* If we've reached destination, done */
	    if (curClass.Class_masterOffset == destinationPart) break;

	    /* Loop to find first class in master part */
	    while !(curClass && mask CLASSF_MASTER_CLASS)
	    		curClass:=curClass.Class_superClass;

	    /* If it has a master class, set curClass to it */
	    if (curClass.Class_superClass != -1) {
	    	curClass:=curClass.Class_superClass;

	    /* Else if variant, then build out variant part if it needs it */
	    } else  {
	        if (*(ds:si).(curClass.Class_masterOffset) == 0) {
	    	    curClass:= ResolveVariant(*ds:si, curClass);
	    	} else {
		    /* If it doesn't need building, just get class */
	    	    curClass:= *(ds:si).*(curClass.Class_masterOffset).OD
	    	}
	    }
	} /* loop */

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Doug	5/89		Changed to build classes between object class
				& target part class, if in need.

------------------------------------------------------------------------------@

ObjInitializePart	proc	far
	push	di, es
EC <	call	CheckLMemObject					>
	mov	di,ds:[si]
	les	di,ds:[di].MB_class		;es:di = class

	; loop to build master parts through the one desired

masterLoop:
						; es:di points to last
						; subclassing within current
						; master part
	push	bx
	mov	bx, es:[di].Class_masterOffset	; Get offset to new master
						;	section part
	add	bx, ds:[si]
	cmp	word ptr ds:[bx], 0		; See if part had been grown
	pop	bx
	jnz	grown
	call	ObjInitializeMaster		; Grow & Initialize master part
grown:
	cmp	bx,es:[di].Class_masterOffset	; Branch out if desired part
	jz	found			; 	found (now grown)

						; Else loop to find first
						;	 class for master part
OIP_loop:
	test	es:[di].Class_flags,mask CLASSF_MASTER_CLASS
	jnz	master			; branch to OIP_master when
	les	di,es:[di].Class_superClass	;	we've found first class
	jmp	OIP_loop			; else loop to get to first
						;	class of master part

	; found a master class

master:
						; Error if null superclass
EC <	cmp	es:[di].Class_superClass.segment,0			>
EC <	jnz	OIP_10							>
EC <	ERROR	BAD_MASTER_OFFSET					>
EC <OIP_10:								>

						; If not variant, just get
						; 	next class
	cmp	es:[di].Class_superClass.segment,VARIANT_CLASS  ;variant ?
	jz	variant
	les	di,es:[di].Class_superClass
	jmp	masterLoop

variant:
	push	bx
	push	di
	mov	bx, es:[di].Class_masterOffset	; Get offset to current master
						;	section part
	mov	di, ds:[si]			; get ptr to instance
	add	di, ds:[di][bx]			; else get ptr to variant
						;	master part
	cmp	ds:[di].MB_class.segment,0
	jz	buildVariant
	les	di, ds:[di].MB_class
	add	sp, 2				; consume di value that was
						;	on stack
	jmp	haveVariant

buildVariant:
	pop	di
	call	ResolveVariant
haveVariant:
	pop	bx
	jmp	masterLoop
found:
	pop	di, es
	ret

ObjInitializePart	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjGetFlags

DESCRIPTION:	Return the object flags associated with a chunk

CALLED BY:	GLOBAL

PASS:
	ax - chunk
	ds - object block

RETURN:
	al - flags
	ah - 0

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	flags are at:   ((ax - offset) / 2) + *offset

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjGetFlags	proc	far
EC <	call	ECGetFlags						>

	push	si
	mov	si,ds:[LMBH_offset]		;*ds:si = flags
	sub	ax,si
	shr	ax,1				;bx = handle #
	mov	si,ds:[si]			;ds:si = flags
	add	si,ax
	mov	al,ds:[si]
EC <	test	al,not mask ObjChunkFlags				>
EC <	ERROR_NZ BAD_LMEM_FLAGS						>

	clr	ah
	pop	si
	ret

ObjGetFlags	endp

;---

if	ERROR_CHECK

ECGetFlags	proc	near
	call	ECLMemExists
	test	ds:[LMBH_flags], mask LMF_HAS_FLAGS
	ERROR_Z	OBJ_LMEM_BLOCK_HAS_NO_FLAGS
	ret

ECGetFlags	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjSetFlags

DESCRIPTION:	Set the object flags associated with a chunk

CALLED BY:	GLOBAL

PASS:
	ax - chunk
	bl - ObjChunkFlags to SET
	bh - ObjChunkFlags to RESET
	ds - object block

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	flags are at:   ((ax - offset) / 2) + *offset

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjSetFlags	proc	far	uses ax, si
	.enter

	test	ds:[LMBH_flags], mask LMF_HAS_FLAGS
	jz	common

EC <	call	ECGetFlags						>
EC <	test	bl, not mask ObjChunkFlags				>
EC <	ERROR_NZ BAD_LMEM_FLAGS						>
EC <	test	bh, not mask ObjChunkFlags				>
EC <	ERROR_NZ BAD_LMEM_FLAGS						>

	mov	si,ds:[LMBH_offset]		;*ds:si = flags
	sub	ax,si				;ax = handle number
	shr	ax,1				;bx = handle #
	mov	si,ds:[si]			;ds:si = flags
	add	si,ax
	mov	al,ds:[si]
EC <	test	al, not mask ObjChunkFlags				>
EC <	ERROR_NZ BAD_LMEM_FLAGS						>
	mov	ah,bh				;invert bits to RESET
	not	ah
	and	al,ah				;mask out bits
	or	al,bl				;mask in bits
	mov	ds:[si],al

	test	al, mask OCF_IGNORE_DIRTY
	jnz	done
common:
	mov	ax, bx 
	call	ObjHandleDirtyFlags
done:

	.leave
	ret

ObjSetFlags	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjMarkDirty

DESCRIPTION:	Reg-saving routine to mark object as being dirty.

CALLED BY:	GLOBAL

PASS:
	*ds:si	- chunk in Object Block to mark dirty

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
------------------------------------------------------------------------------@


ObjMarkDirty	proc	far
	pushf
	push	ax
	push	bx
	mov	ax, si
	mov	bx, mask OCF_DIRTY
	call	ObjSetFlags
	pop	bx
	pop	ax
	popf
	ret

ObjMarkDirty	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjHandleDirtyFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	 Take care of marking a VM block dirty if this is the first chunk to
	 be marked dirty in the block.
	

CALLED BY:	EXTERNAL

PASS:		
		al - object flags	
		ds - object block
RETURN:		
		vm dirtied if necessary
		
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjHandleDirtyFlags		proc	near
	uses	si
	.enter

	test	al, mask OCF_IGNORE_DIRTY
	jnz	done				;=> dirty makes no difference
	test	al, mask OCF_DIRTY
	jz	done				;not marking dirty, so...
	test	ds:[LMBH_flags], mask LMF_IS_VM	;block in VM file?
	jz	done
	push	ds				;see if block already dirty
	mov	si, ds:[LMBH_handle]
	LoadVarSeg	ds
	test	ds:[si].HM_flags, mask HF_DISCARDABLE
	jz	donePopDS
	xchg	si, bp
	call	VMDirty
	xchg	si, bp

donePopDS:
	pop	ds
done:
	.leave
	ret
ObjHandleDirtyFlags		endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjIncInUseCount

DESCRIPTION:	Increment in-use count for an object block

CALLED BY:	GLOBAL

PASS:
	ds	- object block
	si	- chunk handle of object in block that is incrementing count.
		  Used in EC code only to keep track of count on a per-object
		  basis, to make debugging this mechanism easier.   Same object
		  should be passed to both inc/dec pair.  NULL may be passed
		  if object not appropriate/not available.

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
	Doug	10/89		Initial version

------------------------------------------------------------------------------@

ObjIncInUseCount	proc	far
	pushf

EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckLMemHandle					>
EC <	pop	bx							>
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_NZ	NON_OBJECT_BLOCK				>

EC <	; See if we've already starting destroying the block		>
EC <	test	ds:[LMBH_flags], mask LMF_DEATH_COUNT			>
EC <	ERROR_NZ	OBJ_BLOCK_IN_PROCESS_OF_BEING_DESTROYED_IS_BECOMING_IN_USE	>

if	TEST_IN_USE_CODE
EC <	tst	si							>
EC <	jz	10$							>
EC <	; Check count on individual object				>
EC <	push	ax, bx							>
EC <	mov	ax, TEMP_EC_IN_USE_COUNT				>
EC <	call	ObjVarDerefData						>
EC <	; In use count shouldn't be negative				>
EC <	or	{word} ds:[bx], 0					>
EC <	ERROR_S	OBJ_BAD_IN_USE_COUNT					>
EC <	inc	{word} ds:[bx]						>
EC <	pop	ax, bx							>
EC <10$:								>
endif

EC <	; Check block count						>
EC <	; In use count shouldn't be negative				>
EC <	tst	ds:[OLMBH_inUseCount]					>
EC <	ERROR_S	OBJ_BLOCK_BAD_IN_USE_COUNT				>

	tst	ds:[OLMBH_inUseCount]
	jz	becomingInUse
				; INCREMENT THE IN-USE COUNT
	inc	ds:[OLMBH_inUseCount]
	popf
	ret

becomingInUse:
				; INCREMENT THE IN-USE COUNT
	inc	ds:[OLMBH_inUseCount]
	popf
	ret

ObjIncInUseCount	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjDecInUseCount

DESCRIPTION:	Decrement in-use count for an object block

CALLED BY:	GLOBAL

PASS:
	ds - object block
	si	- chunk handle of object in block that is incrementing count.
		  Used in EC code only to keep track of count on a per-object
		  basis, to make debugging this mechanism easier.   Same object
		  should be passed to both inc/dec pair.  NULL may be passed
		  if object not appropriate/not available.

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
	Doug	10/89		Initial version

------------------------------------------------------------------------------@

ObjDecInUseCount	proc	far
	pushf

EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckLMemHandle					>
EC <	pop	bx							>
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_NZ	NON_OBJECT_BLOCK				>

if	TEST_IN_USE_CODE
EC <	tst	si							>
EC <	jz	10$							>
EC <	; Check per-object count					>
EC <	push	ax, bx							>
EC <	mov	ax, TEMP_EC_IN_USE_COUNT				>
EC <	call	ObjVarFindData	; should exist				>
EC <	ERROR_NC	OBJ_BAD_IN_USE_COUNT				>
EC <	dec	{word} ds:[bx]						>
EC <	pop	ax, bx							>
EC <	ERROR_S	OBJ_BAD_IN_USE_COUNT					>
EC <10$:								>
endif

				; DECREMENT THE IN-USE COUNT
	dec	ds:[OLMBH_inUseCount]

EC <	; Check block count						>
EC <	; In use count shouldn't go negative				>
EC <	pushf								>
EC <	tst	ds:[OLMBH_inUseCount]					>
EC <	ERROR_S	OBJ_BLOCK_BAD_IN_USE_COUNT				>
EC <	popf								>

	jnz	notZeroYet
				; Is block set up to auto-free as soon as
				; the in-use count reaches zero?
	test	ds:[LMBH_flags], mask LMF_AUTO_FREE
	jz	afterFree	; if not, skip freeing attempt

				; Clear flag, we're going to start freeing.
	and	ds:[LMBH_flags], not mask LMF_AUTO_FREE

	push	bx
	mov	bx, ds:[LMBH_handle]
	call	ObjFreeObjBlock
	pop	bx
afterFree:

notZeroYet:
	popf
	ret

ObjDecInUseCount	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjIncInteractibleCount

DESCRIPTION:	Increment in-use count for an object block

CALLED BY:	GLOBAL

PASS:
	ds - object block
	si	- chunk handle of object in block that is incrementing count.
		  Used in EC code only to keep track of count on a per-object
		  basis, to make debugging this mechanism easier.   Same object
		  should be passed to both inc/dec pair.  NULL may be passed
		  if object not appropriate/not available.

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
	Doug	5/92		Initial version

------------------------------------------------------------------------------@

ObjIncInteractibleCount	proc	far
	pushf

EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckLMemHandle					>
EC <	pop	bx							>
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_NZ	NON_OBJECT_BLOCK				>

if	TEST_IN_USE_CODE
EC <	tst	si							>
EC <	jz	10$							>
EC <	; Check count on individual object				>
EC <	push	ax, bx							>
EC <	mov	ax, TEMP_EC_INTERACTIBLE_COUNT				>
EC <	call	ObjVarDerefData						>
EC <	; Count shouldn't be negative					>
EC <	or	{word} ds:[bx], 0					>
EC <	ERROR_S	OBJ_BAD_INTERACTIBLE_COUNT				>
EC <	inc	{word} ds:[bx]						>
EC <	pop	ax, bx							>
EC <10$:								>
endif

EC <	; Check block count						>
EC <	; Count shouldn't be negative					>
EC <	tst	ds:[OLMBH_interactibleCount]				>
EC <	ERROR_S	OBJ_BLOCK_BAD_INTERACTIBLE_COUNT			>

	tst	ds:[OLMBH_interactibleCount]
	jz	becomingInteractible

	inc	ds:[OLMBH_interactibleCount]	; Inc interactible count
	popf
	ret

becomingInteractible:
if	TEST_IN_USE_CODE
EC <	push	si							>
EC <	clr	si							>
endif
	call	ObjIncInUseCount		; Inc in-use count
if	TEST_IN_USE_CODE
EC <	pop	si							>
endif
	inc	ds:[OLMBH_interactibleCount]	; Inc interactible count

	; Notify resource controller that the object block has become
	; interactible
	;
	push	ax
	mov	ax, MSG_META_NOTIFY_OBJ_BLOCK_INTERACTIBLE
	call	ObjSendToObjBlockOutput
	pop	ax

	popf
	ret

ObjIncInteractibleCount	endp

ObjSendToObjBlockOutput	proc	near	uses bx, cx, si, di
	.enter

	movdw	bxsi, ds:[OLMBH_output]
	tst	bx
	jz	done

	mov	di, 700
	call	ThreadBorrowStackSpace
	push	di

	mov	cx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	di
	call	ThreadReturnStackSpace
done:
	.leave
	ret
ObjSendToObjBlockOutput	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjDecInteractibleCount

DESCRIPTION:	Decrement in-use count for an object block

CALLED BY:	GLOBAL

PASS:
	ds - object block
	si	- chunk handle of object in block that is incrementing count.
		  Used in EC code only to keep track of count on a per-object
		  basis, to make debugging this mechanism easier.   Same object
		  should be passed to both inc/dec pair.  NULL may be passed
		  if object not appropriate/not available.

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
	Doug	5/92		Initial version

------------------------------------------------------------------------------@

ObjDecInteractibleCount	proc	far
	pushf

EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckLMemHandle					>
EC <	pop	bx							>
EC <	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK			>
EC <	ERROR_NZ	NON_OBJECT_BLOCK				>


if	TEST_IN_USE_CODE
EC <	tst	si							>
EC <	jz	10$							>
EC <	; Check per-object count					>
EC <	push	ax, bx							>
EC <	mov	ax, TEMP_EC_INTERACTIBLE_COUNT				>
EC <	call	ObjVarFindData	; should exist				>
EC <	ERROR_NC	OBJ_BAD_INTERACTIBLE_COUNT			>
EC <	dec	{word} ds:[bx]						>
EC <	pop	ax, bx							>
EC <	ERROR_S	OBJ_BAD_INTERACTIBLE_COUNT				>
EC <10$:								>
endif

	dec	ds:[OLMBH_interactibleCount]	; Dec interactible count

EC <	; Count shouldn't go negative					>
EC <	pushf								>
EC <	tst	ds:[OLMBH_interactibleCount]				>
EC <	ERROR_S	OBJ_BLOCK_BAD_INTERACTIBLE_COUNT			>
EC <	popf								>

	jnz	notZeroYet

	; Notify resource controller that the object block is no longer
	; Interactible
	;
	push	ax
	mov	ax, MSG_META_NOTIFY_OBJ_BLOCK_NOT_INTERACTIBLE
	call	ObjSendToObjBlockOutput
	pop	ax

if 	TEST_IN_USE_CODE
EC <	push	si							>
EC <	clr	si							>
endif
	call	ObjDecInUseCount		; Dec in-use count
if	TEST_IN_USE_CODE
EC <	pop	si							>
endif

notZeroYet:
	popf
	ret

ObjDecInteractibleCount	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjSwapLock

DESCRIPTION:	General object utility routine to lock a new object block,
		& save old object's block handle

CALLED BY:	EXTERNAL

PASS:		ds	- segment of object 1
		bx	- block handle of object 2

RETURN:		ds	- segment of object 2 (Now locked, if different from
			  object 1)
		bx	- block handle of object 1
		flags	- intact

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

ObjSwapLock	proc	far
	pushf
					; If objects in same block, done
	cmp	bx, ds:[LMBH_handle]
	jne	MustLock
	popf
	ret

MustLock:
	push	ax
	call	ObjLockObjBlock		; lock object 2's block
	mov	bx, ds:[LMBH_handle]	; return object 1's handle in bx
	mov	ds, ax			; return object 2's seg in ds
	pop	ax
	popf
	ret

ObjSwapLock	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjSwapUnlock

DESCRIPTION:	General object utility routine complement to ObjSwapLock.

CALLED BY:	EXTERNAL

PASS:		ds	- segment of object 2
		bx	- block handle of object 1  (which must be locked)

RETURN:		ds	- segment of object 1
		bx	- block handle of object 2
		flags	- intact

			  This block is MemUnlock'd if it is different than
			  object 1's block.

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

ObjSwapUnlock	proc	far
	pushf
					; If objects in same block, done
	cmp	bx, ds:[LMBH_handle]
	jz	popFlagsExit

	push	ax
	mov	ax, ds:[LMBH_handle]	; Get parent block handle
	call	MemDerefDS		; restore ds to object 1's segment
	mov_tr	bx, ax
	call	NearUnlock		; Unlock object 2's block
	pop	ax
popFlagsExit:
	popf
	ret

ObjSwapUnlock	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjTestIfObjBlockRunByCurThread

DESCRIPTION:	General object utility routine to determine if the current
		running thread is the thread which owns a given object block.
		(i.e. does this thread have direct acess to the block)

CALLED BY:	EXTERNAL

PASS:		bx	- handle of object block
			  If bx is a vm-block then the thread which runs
			  the vm-file is checked.

RETURN:		zero flag	- Set if current thread is the same one
				  as the one specified to run the object block:
				  The block may be locked, unlocked, & sent
				  methods using any routines available, by
				  the current thread.

				  Clear if the block is inaccesible by the
				  current thread (ObjMessage must be used
				  in order to remotely call any block in the
				  object)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
	John	22-Jun-90	Should now handle VM blocks correctly.

------------------------------------------------------------------------------@

ObjTestIfObjBlockRunByCurThread		proc	far	uses ax, ds
	.enter

	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			;ax = exec thread

	LoadVarSeg	ds
	cmp	ax, ds:currentThread	; see if that is the current thread

	.leave
	ret

ObjTestIfObjBlockRunByCurThread	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjIsClassADescendant

DESCRIPTION:	Test whether a class is a descentant of another class

CALLED BY:	INTERNAL

PASS:
	ds:si - class
	es:di - class

RETURN:
	carry - set if es:di is a subclass of ds:si

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/26/92		Initial version

------------------------------------------------------------------------------@
ObjIsClassADescendant	proc	far
	call	PushAll

	mov	bp, ds:[si].Class_masterOffset	;for optimization
	movdw	cxdx, dssi			;cx:dx = class to search for
	clr	si
	call	ClassInClassCommon

	call	PopAll
	ret

ObjIsClassADescendant	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjIsObjectInClass

DESCRIPTION:	Test whether or not an object is in a given class.  If
		a variant class is encountered, the object will NOT
		be grown out past that class in the search (If you want
		to do a complete search past variant classes, send a 
		MSG_META_DUMMY first.

PASS:
	*ds:si - object
	es:di - class

RETURN:
	carry - set if object is in the given class

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

ObjIsObjectInClass	proc	far
	call	PushAll

EC <	call	ECCheckClass						>
EC <	call	CheckLMemObject						>

	mov	bp, es:[di].Class_masterOffset	;for optimization
	movdw	cxdx, esdi			;cx:dx = class to search for

	mov	di, ds:[si]
	les	di, ds:[di].MB_class		;ds:si = object's class

	call	ClassInClassCommon

	call	PopAll
	ret

ObjIsObjectInClass	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ClassInClassCommon

DESCRIPTION:	Determine if one class is a subclass of another class

CALLED BY:	INTERNAL

PASS:
	*ds:si - object (for variant resolution) or si=0 for none
	cx:dx - class
	es:di - class
	bp  - master offset for cx:dx class

RETURN:
	carry - set if es:di is a subclass of cx:dx

DESTROYED:
	bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/26/92		Initial version

------------------------------------------------------------------------------@
ClassInClassCommon	proc	near

	; loop up the class tree

compareLoop:
EC <	call	CheckClass						>

	; if master offset of class that we are searching for is more than the
	; master offset of the class we are at then a match cannot be found

	cmp	bp, es:[di].Class_masterOffset
	ja	notFound

	; found a match ?

	cmp	dx, di
	jnz	10$
	mov	bx, es
	cmp	bx, cx
	stc
	jz	done
10$:

	; move to superclass -- if 0 (MetaClass), then done

	mov	bx, es:[di].Class_superClass.segment
	tst	bx
	jz	notFound
	cmp	bx, VARIANT_CLASS
	jz	variant
	mov	di, es:[di].Class_superClass.offset
	mov	es, bx
	jmp	compareLoop

	; variant class -- get superclass from instance data
variant:
	tst	si
	jz	notFound
	mov	bx, es:[di].Class_masterOffset
	mov	di, ds:[si]
	add	di, ds:[di][bx]
	cmp	ds:[di].MB_class.segment, 0
	jz	notFound
	les	di, ds:[di].MB_class
	jmp	compareLoop

notFound:
	clc
done:

	ret

ClassInClassCommon	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjBlockSetOutput

DESCRIPTION:	Set resource output for an object block

CALLED BY:	GLOBAL

PASS:		ds - object block
		bx:si	- output

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version

------------------------------------------------------------------------------@

ObjBlockSetOutput	proc	far
EC <	call	ECCheckOD					>
	mov	ds:[OLMBH_output].handle, bx
	mov	ds:[OLMBH_output].chunk, si
	ret
ObjBlockSetOutput	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjBlockGetOutput

DESCRIPTION:	Get resource output for an object block

CALLED BY:	GLOBAL

PASS:		ds - object block

RETURN:		bx:si	- output

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version

------------------------------------------------------------------------------@

ObjBlockGetOutput	proc	far
	mov	bx, ds:[OLMBH_output].handle
	mov	si, ds:[OLMBH_output].chunk
	ret
ObjBlockGetOutput	endp
