COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hierarchy
FILE:		graphicBodyObjArray.asm

AUTHOR:		Steve Scholl, Nov 15, 1991

ROUTINES:
	Name			Description
	----			-----------
ObjArrayProcessChildren
ObjArrayProcessChildrenRV
ObjArrayProcessChildrenEnd
ObjArrayProcessChildrenCB
ChunkArrayEnumRV

METHOD HANDLERS
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/91	Initial revision


DESCRIPTION:

	$Id: bodyObjArray.asm,v 1.1 97/04/04 18:07:50 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjInitCode	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjArrayProcessChildren

DESCRIPTION:	Process the children of a composite object via a callback
		routine or via several predefined callback routines.

		The callback routine is called for each child in order, with
		all passed registers preserved except BX.  The callback routine
		returns the carry set to end processing at this point.

CALLED BY:	GLOBAL

PASS:
	*ds:si - chunk array of ODs
	ax, cx, dx, bp - parameters to pass to call back routine
	on stack (pushed in this order):
		optr -  object descriptor of initial child to process or 0
			to start at composite's Nth child, where N is stored
			in the chunk half of the optr.
		fptr - address of call back routine (segment pushed first) or
		       if segment = 0 then offset is in ObjCompCallType:
		       (vfptr if XIP'ed)

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
		OCCT_COUNT_CHILDREN:  DO NOT USE (ChunkArrayGetCount
			is faster, no?)

		optr - handle:offset of composite

RETURN:
	call back routine and method popped off stack
	carry - set if call aborted in the middle
	ax, cx, dx, bp - returned with call back routine's changes
	ds - pointing at same block (could have moved)
	es - untouched (i.e. it ain't fixed up if it points at a block
	     that might have moved)

DESTROYED:
	nothing
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  to them.

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
	CDB	10/91		modified for ChunkArray... stuff

------------------------------------------------------------------------------@


; These params are used by the callback routine to directly access the
; stack frame created by this routine. 
ArrayProcessParams	struct
	APP_paramBP	word
	APP_retAddr	fptr	; caller of ObjArrayProcessChildren
	APP_composite	fptr
	APP_callBack	fptr
	APP_initialChild optr
ArrayProcessParams	ends

;******************************************************************************
; This is kind of weird:  Acoording to adam, if I push-initialize a
; variable with BP, it'll be popped upon returning.  However, any
; other push-initialized variables WON'T be popped.  That's just the
; way it is, I guess...
;******************************************************************************
 
ObjArrayProcessChildren	proc	far call	\
				composite:optr,
 				callBack:fptr,
				initialChild:optr
	paramBP		local word	; message data passed in bp\
	push	bp
	lastLockedBlock	local hptr	; block handle of current DS\
	push	ds:[LMBH_handle]

	uses	bx, di, es
	.enter

ForceRef	composite
ForceRef	callBack
ForceRef	initialChild
ForceRef	paramBP
ForceRef	lastLockedBlock

; Set up the callback routine address
	tst	callBack.segment
	jnz	afterCallBackAddress
	mov	bx, SEGMENT_CS
	mov	callBack.segment, bx

; convert offset from ETYPE to ADDRESS:
	mov	bx, callBack.offset
	mov	bx, cs:[bx].OCCC_callBackTable
	mov	callBack.offset, bx

afterCallBackAddress:
	mov	di, offset ObjArrayProcessChildrenCB
	mov	bx, cs

	call	ChunkArrayEnum
	call	ObjArrayProcessChildrenEnd
	.leave
	ret	@ArgSize
ObjArrayProcessChildren	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjArrayProcessChildrenRV

DESCRIPTION:	Process an array of objects, starting at the LAST
		object and moving backwards thru the list

		The callback routine is called for each child in order, with
		all passed registers preserved except BX.  The callback routine
		returns the carry set to end processing at this point.

CALLED BY:	GLOBAL

PASS:
	*ds:si - chunk array of ODs
	ax, cx, dx, bp - parameters to pass to call back routine
	on stack (pushed in this order):
		optr - object descriptor of initial child to process.
		    If handle part is 0, then the chunk part contains
		    the number of objects to skip before processing.
		    Note that this counts back from the last object
		    (ie, if a value of 2 is passed, then the last 2
		    objects won't be processed, but everything before
		    them will).

		fptr - address of call back routine (segment pushed first) or
		   if segment = 0 then offset is in ObjCompCallType:

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
		OCCT_COUNT_CHILDREN:  DO NOT USE (ChunkArrayGetCount
			is faster, no?)

		optr - composite

RETURN:
	call back routine and method popped off stack
	carry - set if call aborted in the middle
	ax, cx, dx, bp - returned with call back routine's changes
	ds - pointing at same block (could have moved)
	es - untouched (i.e. it ain't fixed up if it points at a block
	     that might have moved)

DESTROYED:
	di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  to them.

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
	CDB	10/91		modified for ChunkArray... stuff

------------------------------------------------------------------------------@
 
ObjArrayProcessChildrenRV	proc	far call	\
				composite:optr,
 				callBack:fptr,
				initialChild:optr
	paramBP		local word	; message data passed in bp\
	push	bp
	lastLockedBlock	local hptr	; block handle of current DS\
	push	ds:[LMBH_handle]
	.enter

ForceRef	composite
ForceRef	callBack
ForceRef	initialChild
ForceRef	paramBP
ForceRef	lastLockedBlock


; Set up the callback routine address
	tst	callBack.segment
	jnz	afterCallBackAddress
	mov	bx, SEGMENT_CS
	mov	callBack.segment, bx

; convert offset from ETYPE to ADDRESS:
	mov	bx, callBack.offset
	mov	bx, cs:[bx].OCCC_callBackTable
	mov	callBack.offset, bx

afterCallBackAddress:
	mov	di, offset ObjArrayProcessChildrenCB
	mov	bx, cs
	call	ChunkArrayEnumRV
	call	ObjArrayProcessChildrenEnd
	.leave
	ret	@ArgSize
ObjArrayProcessChildrenRV	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjArrayProcessChildrenEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	finish up the ObjArrayProcessChildren routine by
		unlocking the last locked block (if it's different
		than the ChunkArray's block)

CALLED BY:	ObjArrayProcessChildren, ObjArrayProcessChildrenRV

PASS:		*ds:si - chunk array
		ss:bp - ArrayProcessParams

RETURN:		nothing 

DESTROYED:	Nothing (flags preserved)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/15/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjArrayProcessChildrenEnd	proc near	
	lastLockedBlock	local hptr
	.enter	inherit
	pushf
	mov	bx, lastLockedBlock
	cmp	bx, ds:[LMBH_handle]
	je	done
	call	MemUnlock
done:
	popf
	.leave
	ret
ObjArrayProcessChildrenEnd	endp


;******************************************************************************
;
;******************************************************************************
 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjArrayProcessChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to process children 

CALLED BY:

PASS:		ds:di - address of current OD
		ss:bp - ArrayProcessParams

		ax, cx, dx - values to pass to lower levels

RETURN:		ax, cx, dx - possibly modified by called routines

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Optimize for simplest case:  no initial child & block already
	locked. 

SCREWY STACK STUFF:  This procedure is called with ss:bp pointing at
the data structure ArrayProcessParams, and ss:[bp-2] pointing at 
lastLockedBlock.
 
The reason I specify everything explicitly in this procedure, and
not in ObjArrayProcessChildren, above, is that in the above
procedure, I want Swat to know what's going on, but down here, I
need to access these values without using bp (since at one point, bx
is used to point to this data).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjArrayProcessChildrenCB	proc far
	lastLockedBlock	local	hptr
	.enter inherit

; get child's OD
	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk

; Check if there's an initial child
	tst	[bp].APP_initialChild.chunk
	jnz	checkInitial

; The purpose of all this is to get the current child's segment locked
; and into DS.  I also want to unlock the last child's block unless
; it's the same block as the chunk array (which must always remain
; locked). 
checkBlock:
	push	ds:[LMBH_handle]	; chunk array's block handle
	mov	di, bx			; child's handle
	xchg	di, lastLockedBlock 	; store, get last one
	cmp	bx, di			; compare current, last
	jne	unlockAndLock
	call	MemDerefDS
	
; now, the child's block is in DS, and we're ready to go!
callRoutine:
	push	bp
	mov	bx, bp
	mov	bp, [bp].APP_paramBP

	push	bx	
	mov	di, ss:[bx].APP_composite.offset
	mov	bx, ss:[bx].APP_composite.handle
	call	MemDerefES
	pop	bx

NOFXIP<	call	ss:[bx].APP_callBack				>
FXIP<	pushdw	ss:[bx].APP_callBack				>
FXIP<	call	PROCCALLFIXEDORMOVABLE_PASCAL			>
	mov	bx, bp
	pop	bp
	mov	[bp].APP_paramBP, bx

; restore the chunkArray block to DS so ChunkArrayEnum knows where
; it's at. 
	pop	bx
	call	MemDerefDS
done:
	.leave
	ret

; If the initial child is an OD, compare it with the current object
; (^lbx:si), otherwise skip (since we're using the initialChild.chunk
; field as a countdown).
checkInitial:
	mov	di, [bp].APP_initialChild.handle
	tst	di
	jz	skipAndDecrement

; Compare the OD of the "initialChild" with ^lbx:si
	cmp	bx, di			; compare handles
	jne	skipThisOne
	cmp	si, [bp].APP_initialChild.chunk
	jne	skipThisOne

; ODs are identical.  Zero out the initialChild chunk so this whole
; business won't be performed again
	clr	[bp].APP_initialChild.chunk
	jmp	checkBlock

; Decrement the counter stored in initialChild.chunk 
skipAndDecrement:
	dec	[bp].APP_initialChild.chunk

skipThisOne:
	clc
	jmp	done

unlockAndLock:
; unlock last block (unless same as chunk array)
	xchg	bx, di		; bx <= last, di <= current
	cmp	bx, ds:[LMBH_handle]
	je	lockNew
	call	MemUnlock
lockNew:
	xchg	bx, di		; bx <= current, di <= last
	push	ax
	call	ObjLockObjBlock
	mov	ds, ax
	pop	ax
	jmp	callRoutine
ObjArrayProcessChildrenCB	endp




;-----------------------------------------

OCCC_callBackTable	label	word
	word	OCCC_save_test
	word	OCCC_save_no_test
	word	OCCC_no_save_test
	word	OCCC_no_save_no_test
	word	OCCC_no_save_abort_after_first

;-----------------------------------------

OCCC_callInstanceCommon proc near
	uses ax
	.enter
	call	ObjCallInstanceNoLockES
	.leave
	ret
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

OCCC_save_no_test	endp


OCCC_no_save_test	proc	far
	call	OCCC_callInstanceCommon
	ret
OCCC_no_save_test	endp


OCCC_no_save_no_test	proc	far
	call	OCCC_callInstanceCommon
	clc
	ret

OCCC_no_save_no_test	endp

OCCC_no_save_abort_after_first	proc	far
	call	OCCC_callInstanceCommon
	stc				;ABORT after calling first child
	ret

OCCC_no_save_abort_after_first	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayEnumRV

DESCRIPTION:	Enumerate all elements in a general array

CALLED BY:	GLOBAL

PASS:
	*ds:si - array
	bx:di - offset of callback routine
	ax, cx, dx, bp, es - data to pass to callback

RETURN:
	ax, cx, dx, bp, es - modified by callbacks
	carry - set if the callback returned the carry set

DESTROYED:
	bx

	Callback:
	Pass:
		*ds:si - array
		ds:di - array element being enumerated
		fixed size elements:
		    ax, cx, dx, bp, es - data passed to GArrayEnum
		variable sized elements:
		    ax - element size
		    cx, dx, bp, es - data passed to GArrayEnum
	Return:
		carry	- set to end enumeration
		ax, cx, dx, bp, es - data to pass to next
	Destroyed:
		bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Performing other chunk array functions during ChunkArrayEnumRV
	is a dangerous thing.
	
	You CANNOT delete the current element or any elements before
	it.	

	You CANNOT insert at the current element or before it.

	Before means elements with lower element numbers, it is
	not meant to be relative to the direction we are enuming in.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	3/90		Converted for KLib use
	Steve	11/92		Nuked linkage in stack frame

------------------------------------------------------------------------------@


GAE_params	struct
	GAE_curOffset	word
	GAE_vector	dword
GAE_params	ends

ChunkArrayEnumRV	proc	far

	; make stack frame

	push	bx			; segment of callback
	push	di			; offset
	mov	bx, bp			; keep bp data in bx
					; (GAE_vector is pushed manually)
	sub	sp, (size GAE_params - size GAE_vector)
	mov	bp, sp

EC <	call	ECCheckChunkArray					>

	mov	di, ds:[si]
	cmp	ds:[di].CAH_count, 0		;any elements?
	LONG je	done				;no (carry is clear)

; Get last element
	
	push	ax, cx, dx			;data for callback
	mov	cx, ds:[di].CAH_count
	dec	cx
	mov	ax, ds:[di].CAH_elementSize
EC <	tst	ax	
EC <	ERROR_Z GROBJ_CHUNK_ARRAY_ENUM_RV_CANT_HANDLE_VARIABLE_SIZED_ELEMENTS
	mul	cx
	add	ax, ds:[di].CAH_offset
	mov	ss:[bp].GAE_curOffset, ax	
	pop	ax, cx, dx			;data for callback

	; loop: *ds:si = array,
	;	ss:[bp].GAE_curOffset = offset into array

enumLoop:
	mov	di, ds:[si]			; ds:di = array
	add	di, ss:[bp].GAE_curOffset	; di = element
	push	si,bp				; array, frame ptr
	xchg	bp, bx				; bp's call back data, frame ptr
	call	ss:[bx].GAE_vector		; call routine
	mov	bx,bp				; bp's call back data
	pop	si,bp				; array, frame ptr
	jc	done				; if carry returned set, then
						; done
; Move to the PREVIOUS element -- stop if we've gotten before the
; beginning of the array.

	push	ax
	mov	di, ds:[si]			; ds:di = array
	mov	ax, ds:[di].CAH_elementSize
	sub	ss:[bp].GAE_curOffset, ax
	mov	ax, ss:[bp].GAE_curOffset
	cmp	ax, ds:[di].CAH_offset
	pop	ax
	jae	enumLoop

EC <	call	ECCheckChunkArray					>

	clc
done:
EC <	call	ECCheckChunkArray					>

	mov	di, sp				; don't trash carry flag
	lea	sp, ss:[di][(size GAE_params - size GAE_vector)]
	pop	di				; di = callback offset
	pop	bp				; bp = callback segment
	xchg	bx, bp				; bp = data BP
						; bx = callback segment
	ret

ChunkArrayEnumRV	endp

GrObjInitCode	ends




