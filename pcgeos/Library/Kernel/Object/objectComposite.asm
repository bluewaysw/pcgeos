COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objComposite.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ObjCompAddChild
   GLB  ObjCompRemoveChild
   GLB	ObjCompFindChild
   GLB	ObjCompMoveChild
   GLB	ObjCompProcessChildren

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	2/89		Updated DEATH & DESTROY

DESCRIPTION:
	This file contains routines to implement a composite class.

	$Id: objectComposite.asm,v 1.1 97/04/05 01:14:29 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @------------------------------------------------------------------


; A composite object is an object that contains a linked list of other objects
; that are called "children" of the composite.  The linkage is accomplisted by
; keeping a "firstChild" pointer in the composite object and "nextSibling"
; pointers in each child object, with the final child pointing back to the
; parent (the pointer is kept in the nextSibling link with the LP_IS_PARENT
; bit set in the .chunk portion of the pointer).  This restricts an object to
; being a child of only one composite (using a given linkage) at a time.
;
; For a given linkage, the composite has a CompPart structure (to be used
; exclusively by these routines), while each child has a LinkPart structure
; (also to be considered opaque).


; ObjCompAddChild is used to add a child to a composite.  
; The location to add the child is determined by the flags and the reference
; child passed (see "choosing where to add/move", below).
;
;	Pass:	*ds:si - instance data
;		cx:dx	- object to add
;		bp - flags for how to add child (CompChildFlags)
;		bx - offset of master group pointer in composite and child's
;			base structure
;		ax - offset within master group instance data to LinkPart in
;			the child
;		di - offset within master group instance data to CompPart in
;			the composite
;	Return:	none
;
;	Choosing where to add/move a child:
;
; Both ObjCompAddChild and ObjCompMoveChild take a CompChildFlags constant
; in bp that determines where the child is added or moved to.  The options are:
;	CCO_FIRST - Put the child at the beginning of the list.  This makes
;		    the child the first child in the composite
;	CCO_LAST - Put the child at the end of the list.  This makes the
;		   child the last child in the composite (does not work if more
;		   than 32766 children)	
;	ELSE, it uses the number passed in BP as the number of the child before
;             which it will add this new object.


; ObjCompRemoveChild is used to remove a child from the composite.  The child
; to be removed must be a child of the composite (else a fatal error in the
; error checking version).  Note that the child is not destroyed and is not
; sent any notification that it is being removed.
;
;	Pass:	*ds:si - instance data
;		cx:dx - object to remove
;		bp - flags for how to remove child (CompChildFlags)
;		bx - offset of master group pointer in composite and child's
;			base structure
;		ax - offset within master group instance data to LinkPart in
;			the child
;		di - offset within master group instance data to CompPart in
;			the composite
;	Return:	none


; ObjCompMoveChild is used to move a child to a different location in the list
; of children.  Note that the child is not physically moved, rather the
; "nextSibling" pointers (and possibly the composite's "firstChild" pointer)
; are changed.  The child to be moved must be a child of the composite (else a
; fatal error in the error checking version).  The location to add the child
; is determined by the flags and the reference child passed (see "choosing
; where to add/move", above).
;
;	Pass:	*ds:si - instance data (of composite)
;		cx:dx - chunk handle to move
;		bp - flags for how to move child (CompChildOptions)
;		bx - offset of master group pointer in composite and child's
;			base structure
;		ax - offset within master group instance data to LinkPart in
;			the child
;		di - offset within master group instance data to CompPart in
;			the composite
;	Return:	none


-------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjCompAddChild

DESCRIPTION:	Perform "MSG_ADD_CHILD" for a composite object

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data of composite
	cx:dx - object to add
	bp - flags for child location desired (CompChildFlags)
		CCF_MARK_DIRTY to mark chunks as dirty

	ax - offset to field of type "LinkPart" in instance data
	bx - offset to master instance offset to
		part containing LinkPart and CompPart
	di - offset to field of type "CompPart" in instance data

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	ax, bx, di, bp
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	5/89		Re-wrote for single OD "next" field

------------------------------------------------------------------------------@

ObjCompAddChild	proc	far
	push	si			;save composite chunk
EC <	call	CheckLMemObject						>

EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	jnz	notAddingSelf						>
EC <	cmp	dx, si							>
EC <	ERROR_Z CANNOT_MAKE_OBJECT_A_CHILD_OF_ITSELF			>
EC <notAddingSelf:							>

;;;byte-savings: since *ds:si gets loaded with the kid down below,
;;;I've decided to postpone the CheckLMemObject until then -- ardeb 8/3/90
;;;if	ERROR_CHECK
;;;	call	CheckLMemObject		; *ds:si is obj to add to
;;;	call	PushAll			;Check object in CX:DX
;;;	mov	bx, cx
;;;	call	ObjLockObjBlock
;;;	mov	ds, ax
;;;	mov	si, dx			; now *ds:si is obj to be added
;;;	call	CheckLMemObject		; check it out.
;;;	call	NearUnlock		; release block
;;;	call	PopAll
;;;endif

	call	FindObjLocation		; Figure out where to insert obj

;	ds:si	- pointing directly at link field at location requested
;	di	- handle of composite obj.  If ds:[0] != di, then we've locked
;		  another block to be able to provide ds above.

	; if previous "next" was 0, then this should be a parent pointer

	pop	bp			; get parent chunk from stack
	push	bp
	or	bp,LP_IS_PARENT		; assume parent link
	push	di			; save handle of composite obj
	cmp	ds:[si].handle,0	; assume this is a parent link
	jz	parent
	mov	di, ds:[si].handle	; get previous "next" ptr
	mov	bp, ds:[si].chunk
parent:
	mov	ds:[si].handle, cx	; store ptr to new object
	mov	ds:[si].chunk, dx

	; setup new child

	push	ds:[LMBH_handle]	; preserve current ds handle

	;
	; Lock down the child object and make sure the master part that
	; contains the linkage is actually around, building it out if not...
	; 
	xchg	bx, cx
	call	ObjLockObjBlockToDS
	xchg	bx, cx			; restore master offset
	mov	si, dx
EC <	call	CheckLMemObject						>
					; See if obj master part needs building
	tst	bx			; If no master offset then must be 
	jz	alreadyBuilt		; built, so jmp
	mov	si, ds:[si]
	cmp	{word}ds:[si][bx], 0
	mov	si, dx
	jne	alreadyBuilt	; Skip if already build
					; *ds:si = object
					; bx = master offset
	call	ObjInitializePart	; build the master part
alreadyBuilt:

; Registers:
;	*ds:si	- child object
;	ax 	- offset to field of type "LinkPart" in instance data
;	bx 	- offset to master instance offset to
;	   	  	part containing LinkPart and CompPart
;	cx	- ds:[0]
;	di:bp	- OD to stuff into LP_next field

	mov	si, ds:[si]		; ptr to instance
	tst	bx
	jz	10$
	add	si, ds:[si][bx]		; add master offset
10$:
	add	si, ax			; add in offset to link part

					; See if LP_next field is 0 (not
					;	currently attached)
EC<	cmp	ds:[si].LP_next.handle, 0			>
EC<	ERROR_NZ	ADD_CHILD_OF_OBJ_ALREADY_IN_COMPOSITE	>
					; Store "Next" link
	mov	ds:[si].LP_next.handle, di
	mov	ds:[si].LP_next.chunk, bp

	; unlock child (locked above)

	xchg	bx, cx
	call	NearUnlock
	xchg	bx, cx

	LoadVarSeg	ds		; Need idata to do this
	pop	di			; get handle of (locked) block
					;  containing link
	mov	ds,ds:[di].HM_addr	; extract segment

	pop	di			; retrieve composite block handle
	call	UnlockDSIfNotDIAndReloadDS

	pop	si
	ret

ObjCompAddChild	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindObjLocation

DESCRIPTION:	Find object location in composite child list, based on
		info passed.  Returns object referenced, ptr to the correct
		link field.

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data of composite
	bp - flags for child location desired (CompChildFlags)
		CCF_MARK_DIRTY set to mark chunks as dirty

	cx:dx - object to dirty (if CCF_MARK_DIRTY is set)
	ax - offset to field of type "LinkPart" in instance data
	bx - offset to master instance offset to
		part containing LinkPart and CompPart
	di - offset to field of type "CompPart" in instance data

RETURN:
	ds:si	- pointing directly at link field at location requested
	di	- handle of composite obj.  If ds:[0] != di, then we've locked
		  another block to be able to provide ds above.

DESTROYED:
	bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

FindObjLocation	proc	near
	push	cx
	push	dx
	mov	cx, bp			; put flags in cx 
	mov	bp, bx			; keep master offset in bp
					; Map After test to a before test
	test	cx,mask CCF_MARK_DIRTY	;
	pushf				; save "make dirty" status
	and	cx,not mask CCF_MARK_DIRTY ;Nuke the mark dirty flag
					;CX <- child # to add object before
	mov	dx, si			; save parent object as one to mark
					;  dirty, if that's called for
	mov	si, ds:[si]
	tst	bx
	jz	10$
	add	si, ds:[si][bx]		; add in master offset (still in bx
					;  as well as bp -- no point in using
					;  an override if we can avoid it)
10$:
	add	si, di			; ds:si is now pointer to CP_firstChild
	mov	di, ds:[LMBH_handle]	; store handle of composite obj here
	cmp	ds:[si].chunk, 0	; empty composite ?
	jne	loopEntry
done:
	mov	bx, bp			; restore master offset
	mov	bp, dx			; recover link object to make dirty
	popf				; recover "make dirty" flag
	pop	dx
	pop	cx
	jz	noDirty

	push	ax, bx
	xchg	ax,bp			; ax = object to dirty
	call	MarkAXAndCXDXDirty
	pop	ax, bx

noDirty:
	ret

	; *ds:si = child, dx = object to mark dirty, bp = master offset,
	; ax = offset to LinkPart, cx = count of children left to traverse,
	; di = handle of composite's block

FOL_loop:
	mov	dx, si			; record this one as object to dirty
	mov	si, ds:[si]
	tst	bp
	jz	20$
	add	si, ds:[si][bp]		; add in master offset
20$:
	add	si, ax			; ds:si is now pointer to LP_next

	; ds:si = address of link

loopEntry:
	jcxz	done			; 0 => used up child counter
	test	ds:[si].chunk, LP_IS_PARENT	;at end ?
	jnz	done		; if so,done (add to the end)

EC <	cmp	ds:[si].handle, 0					>
EC <	ERROR_Z	CORRUPT_LINKAGE						>
					; MOVE on to next object
	mov	bx, ds:[si].handle
	mov	si, ds:[si].chunk
	call	UnlockDSIfNotDIAndReloadDS
	dec	cx			; bump object count
	cmp	bx, di			; see if in block of composite
	je	FOL_loop		; if so, just loop

	call	ObjLockObjBlockToDS	; else lock the block
	jmp	FOL_loop		; & loop back in

FindObjLocation	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MarkAXAndCXDXDirty

DESCRIPTION:	Mark *ds:ax and ^lcx:dx dirty

CALLED BY:	INTERNAL

PASS:
	*ds:ax - object to mark dirty
	^lcx:dx - object to mark dirty

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

MarkAXAndCXDXDirty	proc	near			uses ds
	.enter

	mov	bx,mask OCF_DIRTY
	call	ObjSetFlags

	mov	bx,cx			; lock additional object to dirty
	call	ObjLockObjBlockToDS
	mov	ax,dx			; (not xchg, as DX still needed)
	mov	bx,mask OCF_DIRTY
	call	ObjSetFlags
	mov	bx,cx
	call	NearUnlock

	.leave
	ret

MarkAXAndCXDXDirty	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjCompRemoveChild

DESCRIPTION:	Perform "MSG_REMOVE_CHILD" for a composite object

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	cx:dx - object to remove

	ax - offset to field of type "LinkPart" in instance data
	bx - offset to instance part containing LinkPart and CompPart
	di - offset to field of type "CompPart" in instance data
	bp - flags: CCF_MARK_DIRTY to mark chunks as dirty

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	5/89		Re-wrote for single "Next" OD ptr

------------------------------------------------------------------------------@

ObjCompRemoveChild	proc	far
	push	cx, dx, si, bp
EC <	call	CheckLMemObject					>

EC <	test	bp, not mask CCF_MARK_DIRTY				>
EC <	ERROR_NZ	REMOVE_CHILD_BAD_FLAGS				>

	; find object

	call	FindChildLow		; locate the child
;EC <	ERROR_C	BAD_REMOVE_CHILD					>
;
; Don't error anymore -- instead, assume this is a "one-way" linkage, and
; zero out the child's parent link.
;
	pushf				; Save flags so that we can figure out
					; later we're just removing parent link

	; lock object, save and zero its next link

	push	si
	push	ds
	xchg	bx, cx			;bx = child handle, cx = master offset
	call	ObjLockObjBlockToDS
	mov	si, dx			;*ds:si = child being removed
EC <	call	CheckLMemObject					>
	mov	si, ds:[si]
	xchg	cx, bp			;bp = master offset, cx = child #
	tst	bp
	jz	10$
	add	si, ds:[si][bp]		; add in master offset
10$:
	mov	bp, cx			;bp = child #
	add	si, ax			; add in offset to LinkPart
					; Get "next" link stored there
	clr	cx			; & replace with zeros
	mov	dx, cx
	xchg	cx, ds:[si].handle
	xchg	dx, ds:[si].chunk
	pop	ds
	pop	si

	popf				; Get flags - removing one-way link?
	jnc	fixupPreviousLink	; skip if not

EC <					; if removing one-way link, make>
EC <					; sure that's what it was	>
EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	BAD_REMOVE_CHILD				>
EC <	sub	dx, LP_IS_PARENT	; un-convert from parent link	>
EC <	cmp	dx, si							>
EC <	ERROR_NZ	BAD_REMOVE_CHILD				>

					; if one-way link, just unlock child,
					; & we're all done.
	; unlock block of object removed

	call	NearUnlock

	; restore composite segment to DS

	LoadVarSeg	ds
	mov	ds,ds:[di].HM_addr
	jmp	short done

fixupPreviousLink:
	; if removing first child AND link is a parent link then we are
	; removing the only child

	tst	bp
	jnz	notOnly
	test	dx,LP_IS_PARENT
	jz	notOnly
	clr	cx
	mov	dx, cx
notOnly:
; fix previous link

	mov	ds:[si].handle,cx
	mov	ds:[si].chunk,dx

	; unlock block of object removed

	call	NearUnlock

	; unlock child block if different and make sure ds contains
	; composite again

	call	UnlockDSIfNotDIAndReloadDS

done:
	pop	cx, dx, si, bp
	ret

ObjCompRemoveChild	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjCompFindChild

DESCRIPTION:	Find a child in a composite

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data of composite
	cx:dx - optr of child
		-- or --
		cx = 0
		dx = # of child to find

	ax - offset to field of type "LinkPart" in instance data
	bx - offset to master instance offset to
		part containing LinkPart and CompPart
	di - offset to field of type "CompPart" in instance data

RETURN:
	carry	- set if NOT FOUND

	if FOUND:
		bp 	- child position (0 = first child)
		cx:dx 	- OD of child

	if NOT FOUND:
		bp 	- number of children
		if optr passed:
			cx, dx  - unchanged
		if # of child passed:
			cx	- unchanged
			dx	- # of child passed minus number of children
DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

ObjCompFindChild	proc	far		uses si, di, ds
	.enter
EC <	call	CheckLMemObject					>

	jcxz	numberToOD			;number -> OD ???

	; OD -> number

	clr	bp				;don't mark dirty
	call	FindChildLow			;preserves cx, dx
	jc	done

	call	UnlockDSIfNotDI
	clc
done:

	.leave
	ret

	; numer to OD, use ObjCompProcessChildren, cx = 0

numberToOD:
	push	cx			;start at first child (pass null)
	push	cx

	push	ax			;LinkPart

	push	cs			;callback
	mov	cx,offset OCFC_callBack
	push	cx

	clr	bp			;init children count
	call	ObjCompProcessChildren

	cmc				;we want to return the opposite of
					;ObjCompProcessChildren

	jmp	done

ObjCompFindChild	endp

	; *ds:si = child, dx = number
	; return ^lcx:dx (and carry set) if this is the one.

OCFC_callBack	proc	far

	inc	bp			;one more child found

	tst	dx
	jz	found
	dec	dx
	clc
	ret

found:
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	stc
	ret

OCFC_callBack	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindChildLow

DESCRIPTION:	Find a child in a composite

CALLED BY:	INTERNAL
		ObjRemoveChild, ObjCompFindChild

PASS:
	*ds:si - instance data of composite
	cx:dx - optr of child

	ax - offset to field of type "LinkPart" in instance data
	bx - offset to master instance offset to
		part containing LinkPart and CompPart
	di - offset to field of type "CompPart" in instance data
	bp - flags: CCF_MARK_DIRTY to mark chunks as dirty

RETURN:
	carry - set if not found
	if FOUND:
		carry clear
		ds:si - pointing directly at link to given child
		di - handle of composite obj.  If ds:[LMBH_handle] != di, then
		     we've locked another block to be able to provide ds above.
		bp - child position (0 = first child)
	if NOT FOUND:
		carry set
		bp - number of children
		*ds:si - composite
		di - handle of composite

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/89		Initial version

------------------------------------------------------------------------------@


FindChildLow	proc	near
flags		equ	{word}ss:[bp]
masterOffset	local	word		; master offset of linkage\
		push	bx
chunkToDirty	local	word		; save chunk to dirty (parent at first)\
		push	si
counter		local	word		; child counter
		.enter
EC <	call	CheckLMemObject					>
	mov	counter, 0

	push	si			; save original chunk of composite, in
					; case needed
	mov	si, ds:[si]
	tst	bx
	jz	10$
	add	si, ds:[si][bx]		; add in master offset
10$:
	add	si, di			; ds:si is now pointer to CP_firstChild
	mov	di, ds:[LMBH_handle]	; store handle of composite obj here
	tst	ds:[si].handle
	pop	bx			; restore chunk handle of composite, in
					; case needed
	jnz	loopEntry		; jmp if list not empty
	mov	si, bx			; THIS is the case where the composite
					; chunk is needed:
					; if list empty, return *ds:si = comp
	jmp	notFound

	; *ds:si = child

childLoop:
	inc	ss:counter
	mov	ss:chunkToDirty,si
	mov	si, ds:[si]
	mov	bx,ss:masterOffset
	tst	bx
	jz	20$
	add	si, ds:[si][bx]		; add in master offset
20$:
	add	si, ax			; ds:si is now pointer to LP_next

	; ds:si = address of link, cx:dx = target, di = handle of composite
	; ax = LinkPart offset

loopEntry:
	mov	bx,ds:[si].chunk	; bx = chunk of child
	test	bx, LP_IS_PARENT	;at end ?
	jnz	atEnd
	cmp	bx,dx			; matching handles ?
	jnz	noMatch
	cmp	cx,ds:[si].handle
	jz	match
noMatch:

EC <	tst	ds:[si].handle						>
EC <	ERROR_Z	CORRUPT_LINKAGE						>

	; Move to next object

	mov	si, ds:[si].handle
	xchg	bx, si
	call	UnlockDSIfNotDIAndReloadDS
	cmp	bx, di			; see if in block of composite
	je	childLoop		; if so, just loop

	call	ObjLockObjBlockToDS	; else lock the block
	jmp	childLoop		; & loop back in

match:
	test	ss:flags, mask CCF_MARK_DIRTY
	jz	noDirty
	push	ax
	mov	ax,ss:chunkToDirty
	call	MarkAXAndCXDXDirty
	pop	ax
noDirty:
	clc				;found
done:
	mov	bx, ss:counter		;return child counter in BP
	mov	ss:[bp], bx
	mov	bx, ss:masterOffset	; and restore master offset
	.leave
	ret

atEnd:
	; restore pointer to composite
	andnf	bx,not LP_IS_PARENT
	mov	si,bx			; si = composite
	call	UnlockDSIfNotDIAndReloadDS
notFound:
	stc				;didn't find
	jmp	short done

FindChildLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjCompMoveChild

DESCRIPTION:	Perform "MSG_MOVE_CHILD" for a composite object

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data (of composite)
	cx:dx - object to move
	bp - flags for how to move child (CompChildOptions)

	ax - offset to field of type "LinkPart" in instance data
	bx - offset to instance part containing LinkPart and CompPart
	di - offset to field of type "CompPart" in instance data

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	ax, bx, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

ObjCompMoveChild	proc	far
EC <	call	CheckLMemObject					>
	; first remove the chunk

	push	ax, bx, di		;save stuff trashed
EC <	push	bp			;avoid death in EC stuff	>
EC <	and	bp, mask CCF_MARK_DIRTY					>
	call	ObjCompRemoveChild
EC <	pop	bp							>
	pop	ax, bx, di

	; then insert it in the correct place

	GOTO	ObjCompAddChild

ObjCompMoveChild	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjCompProcessChildren

DESCRIPTION:	Process the children of a composite object via a callback
		routine or via several predefined callback routines.

		The callback routine is called for each child in order, with
		all passed registers preserved except BX.  The callback routine
		returns the carry set to end processing at this point.

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data of composite object
	bx - offset to MasterPart containing LinkPart and CompPart
	di - offset to field of type "CompPart" in instance data
	ax, cx, dx, bp - parameters to pass to call back routine
	on stack (pushed in this order):
		optr -  object descriptor of initial child to process or 0
			to start at composite's Nth child, where N is stored
			in the chunk half of the optr.
		word - offset to field of type "LinkPart" in instance data
		fptr - virtual address of call back routine (segment pushed
			first) or...
		   if segment = 0 then offset is an ObjCompCallType (below),
			ax - message to send to children
			cx, dx, bp - parameters to message

		   ObjCompCallTypes:
		   OCCT_SAVE_PARAMS_TEST_ABORT - Save cx, dx and bp around the
			calling of the child, if carry is set on return from
			the call then abort with carry set
		   OCCT_SAVE_PARAMS_DONT_TEST_ABORT - Save cx, dx and bp around
			the calling of the child, don't check carry on return
		   OCCT_DONT_SAVE_PARAMS_TEST_ABORT - Don't save cx, dx and bp
			around the calling of the child, if carry is set on
			return from the call then abort with carry set
		   OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT - Don't save cx, dx and
			bp around the calling of the child, don't check carry
			on return
		   OCCT_DONT_SAVE_PARAMS_ABORT_AFTER_FIRST - Don't save cx, dx,
			and bp around the calling of the child, and abort after
			have called one child (usually used with "call nth
			child" capability.
		   OCCT_COUNT_CHILDREN - Counts the number of children along the
			specified link. Returns # of children added to DX.

RETURN:
	call back routine and method popped off stack
	carry - set if call aborted in the middle
	ax, cx, dx, di, bp - returned with call back routine's changes
	ds - pointing at same block (could have moved)
	es - untouched (i.e. it ain't fixed up if it points at a block
	     that might have moved)

DESTROYED:
	di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

	CALL BACK ROUTINE:
		Desc:	Process child
		Pass:	*ds:si - child
			*es:di - composite
			ax, cx, dx, bp - data
		Return:	carry - set to end processing
			ax, cx, dx, bp - data to send to next child
		Destroy: bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Eric	10/89		Added "start at Nth child" capability
	doug	7/90		Changed to patch up ds, es values around
				calls to callback routine for each child

------------------------------------------------------------------------------@


ObjCompProcessChildren	proc	far call	\
		callBack:fptr,		; Callback routine
		linkOffset:word,	; Offset of LinkPart in master group
		initialChild:optr	; Child from which to start

		uses	es

masterPart	local	word		; Master part of link fields\
		push	bx		; initialized from BX on entry
EC <lockCount	local	word		; Initial lock count of composite block>
countdown	local	word		; countdown to first child to do
composite	local	word		; chunk of composite
	.enter
EC <	call	CheckLMemObject					>

	mov	composite, si		;save composite chunk handle for loop

	;
	; setup ^lbx:si to be the first child
	;
	mov	si,ds:[si]			;ds:si = composite object
	tst	bx
	jz	10$
	add	si,ds:[si][bx]			;ds:si = instance
10$:
	add	si,di				;ds:si = CompPart


	; if EC then save lock count for composite
EC <	LoadVarSeg	es						>
EC <	mov	bx,ds:[LMBH_handle]					>
EC <	mov	bl, es:[bx].HM_lockCount				>
EC <	mov	lockCount, bx						>

	segmov	es, ds				;es = composite

	push	ax
	mov	countdown, 0			;assume initial child given
	mov	ax, initialChild.chunk		; so no countdown needed
	mov	bx, initialChild.handle
	tst	bx
	jnz	haveInitial
	
	mov	countdown, ax			;wrong. set countdown from
						; chunk half of initialChild
						; pointer
	mov	bx, ds:[si].CP_firstChild.handle; and fetch the composite's
	mov	ax, ds:[si].CP_firstChild.chunk	; first child for the loop

haveInitial:
	xchg	si, ax				; si <- child chunk (1-b i)
	pop	ax

	tst	bx				; (clears carry)
	jnz	setupCallback			;skip everything if no initial
						; child/no child passed
	jmp	done

setupCallback:
EC <	call	ECCheckLMemOD						>
	; fix callback routine if using standard callback type

	tst	callBack.segment		;call back supplied?
	jnz	processLoop

	mov	di, callBack.offset		;get call type
EC <	cmp	di, ObjCompCallType					>
EC <	ERROR_AE BAD_OBJ_COMP_CALL_TYPE					>   
						;stuff our call back
	mov	callBack.segment, vseg ObjCompProcessChildren

	mov	di,cs:[OCCC_callBackTable][di]	;routine on
	mov	callBack.offset,di		;the stack

	;------------------------------------------------------------
processLoop:
	; es = composite block; ^lbx:si = child; ax, cx, dx, bp = data
EC <	call	ECCheckLMemOD						>

	;
	; Unlock the previous child's block if it's not the same as the
	; next child's block or the composite's block.
	;
	cmp	bx,ds:[LMBH_handle]		;same as last child ?
	jz	childLocked
	push	bx
	mov	bx,ds:[LMBH_handle]		;unlock old child if doesn't
	cmp	bx,es:[LMBH_handle]		;hold composite
	jz	oldChildUnlocked
	call	NearUnlock

oldChildUnlocked:
	pop	bx

	segmov	ds, es				;assume child is in parent blk
	cmp	bx,es:[LMBH_handle]		;same as parent ?
	jz	childLocked
	call	ObjLockObjBlockToDS
childLocked:	;block is now locked. See if we have reached Nth child yet

EC <	call	CheckLMemObject					>

						; But first!  get OD of
						; NEXT child to do 
						; & save on stack.

	mov	di, ds:[si]			;ds:di <- object base
	mov	bx, masterPart
	tst	bx
	jz	20$
	add	di, ds:[di][bx]			;point to master group data
20$:	
	add	di, linkOffset			;point to LinkPart

EC <	push	bx, si							>
EC <	mov	bx, ds:[di].LP_next.handle				>
EC <	mov	si, ds:[di].LP_next.chunk				>
EC <	tst	bx							>
EC <	ERROR_Z	CORRUPT_LINKAGE						>
EC <	tst	si							>
EC <	ERROR_Z	CORRUPT_LINKAGE						>
EC <	and	si, 0fffeh						>
EC <	call	ECCheckLMemOD						>
EC <	pop	bx, si							>

	push	ds:[di].LP_next.handle		;save handle and chunk of next
	push	ds:[di].LP_next.chunk

	dec	countdown		;has countdown finished?
	jns	next			;skip if not... (carry must be clear
					; b/c add of linkOffset may not wrap)

	; DO IT!  Call the callback routine passing parent & child
	; objects.  Preserve ds & es values around the call, so that the
	; routine can be written using same parameter handling rules as
	; method handlers.
	;
	mov	di, composite		; *es:di = composite
	push	ds:[LMBH_handle]
	push	es:[LMBH_handle]	; Preserve handle of parent block

	push	bp

	;
	;  We need to see if we were passed a regular fptr, or a
	;  vfptr.  If a vfptr, we need to do "special things" when
	;  running under the XIP system.
	;  We need not verify the fptr because we reside in the
	;  fixed "kcode" segment.
	;			-- todd 02/17/94
FXIP<	cmp	{byte}ss:callBack.high+1, 0f0h			>
FXIP<	ja	doProcCall					>

	lea	bx, ss:callBack		; ss:[bx] = callback routine
	mov	bp, ss:[bp]		; restore passed/returned BP
	call	{dword}ss:[bx]		;send the thing
FXIP<	jmp	short restoreBP					>

doProcCall::
FXIP<	mov	ss:[TPD_dataAX], ax				>
FXIP<	mov	ss:[TPD_dataBX], bx				>
FXIP<	movdw	bxax, ss:callBack				>
FXIP<	mov	bp, ss:[bp]					>
FXIP<	call	ProcCallFixedOrMovable				>

restoreBP::
	mov	bx, bp			;preserve returned value
	pop	bp
	mov	ss:[bp], bx

	LoadVarSeg	ds
	pop	bx			; Get handle of parent block
	mov	es, ds:[bx].HM_addr	; Fixup address into es
	pop	bx			; Get handle of child block
	mov	ds, ds:[bx].HM_addr	; Fixup address into ds

next:

	pop	si			;Fetch OD of next sibling off stack
	pop	bx

	jc	endLoop			;if carry returned set -> done

	test	si, LP_IS_PARENT		;at end ? (clears carry)
	LONG jz	processLoop			;if not then loop

	; unlock child block if necessary (not in same block as composite)

endLoop:
	pushf					;save carry status
	mov	bx,ds:[LMBH_handle]
	cmp	bx,es:[LMBH_handle]
	jz	noUnlock2
	call	NearUnlock
noUnlock2:
	popf

	segmov	ds, es				;recover composite segment

done:

	mov	si, composite		;return si untouched

	; if EC then make sure that the lock count is still the same

	LoadVarSeg	es

if	ERROR_CHECK
	pushf
	mov	bx,ds:[LMBH_handle]
	mov	bl, es:[bx].HM_lockCount
	cmp	bl, {byte}lockCount
	ERROR_NZ	OBJ_COMP_PROCESS_CHILDREN_LOCK_COUNT_CHANGED
	popf
endif
	mov	bx, masterPart
	.leave
	ret	@ArgSize			;pop off parameters

ObjCompProcessChildren	endp

;-----------------------------------------

OCCC_callBackTable	label	word
	word	OCCC_save_test
	word	OCCC_save_no_test
	word	OCCC_no_save_test
	word	OCCC_no_save_no_test
	word	OCCC_no_save_abort_after_first
	word	OCCC_count_children

;-----------------------------------------

OCCC_callInstanceCommon proc near
	uses ax
	.enter
	call	ObjCallInstanceNoLockES
	.leave
	ret
SwatLabel OCCC_callInstanceCommon_end
OCCC_callInstanceCommon endp

OCCC_save_test	proc	far
	push	cx, dx, bp
	call	OCCC_callInstanceCommon
	pop	cx, dx, bp
	ret
OCCC_save_test	endp


OCCC_save_no_test	proc	far
	push	cx, dx, bp
	call	OCCC_callInstanceCommon
	pop	cx, dx, bp
	clc
	ret
SwatLabel OCCC_save_no_test_end
OCCC_save_no_test	endp


OCCC_no_save_test	proc	far
	call	OCCC_callInstanceCommon
	ret

OCCC_no_save_test	endp


OCCC_no_save_no_test	proc	far
	call	OCCC_callInstanceCommon
	clc
	ret
SwatLabel OCCC_no_save_no_test_end
OCCC_no_save_no_test	endp

OCCC_no_save_abort_after_first	proc	far
	call	OCCC_callInstanceCommon
	stc				;ABORT after calling first child
	ret

OCCC_no_save_abort_after_first	endp

OCCC_count_children	proc	far
	inc	dx			;INC count in dx
	clc
	ret

OCCC_count_children	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjLockObjBlockToDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the object block passed in BX and store its segment
		in DS

CALLED BY:	INTERNAL
PASS:		bx	= block to lock
RETURN:		ds	= block segment
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjLockObjBlockToDS proc near	uses ax
		.enter
		call	ObjLockObjBlock
		mov	ds, ax
		.leave
		ret
ObjLockObjBlockToDS endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDSIfNotDIAndReloadDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A lot like UnlockDSIfNotDI, but reloads DS with [di].HM_addr

CALLED BY:	INTERNAL
PASS:		ds	= segment of object block to check
		di	= (locked) handle of composite
RETURN:		ds	= segment of composite
		carry clear
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockDSIfNotDIAndReloadDS proc	near
		.enter
		call	UnlockDSIfNotDI
		jnc	done

		; restore composite segment to DS

		LoadVarSeg	ds
		mov	ds,ds:[di].HM_addr
done:
		.leave
		ret
UnlockDSIfNotDIAndReloadDS endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDSIfNotDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the block pointed to by DS if it's not the block
		whose handle is in DI

CALLED BY:	INTERNAL
PASS:		ds	= object block to possibly unlock
		di	= handle of composite against which to check
			  ds:[LMBH_handle]
RETURN:		carry set if block unlocked
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockDSIfNotDI	proc	near
		.enter
		cmp	di, ds:[LMBH_handle]
		je	done
		call	UnlockDS
		stc
done:
		.leave
		ret
UnlockDSIfNotDI	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnlockDS

DESCRIPTION:	Unlock block pointed to by DS

CALLED BY:	INTERNAL

PASS:
	ds - block with handle in LMBH_handle

RETURN:
	ds - not valid

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

UnlockDS	proc	near
	push	bx
	mov	bx, ds:[LMBH_handle]
	call	NearUnlock
	pop	bx
	ret
UnlockDS	endp
