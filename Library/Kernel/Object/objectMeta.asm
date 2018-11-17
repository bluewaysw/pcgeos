COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objMeta.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	MetaClass		Superclass of all classes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	2/89		Updated DEATH & DESTROY

DESCRIPTION:
	This file contains routines to implement the meta class.

	$Id: objectMeta.asm,v 1.1 97/04/05 01:14:32 newdeal Exp $

-------------------------------------------------------------------------------@

	; Root class, ancestor of all others

	; Define class record. Sets the NEVER_SAVED flag to avoid
	; creating a relocation table. We can't use a table to
	; relocate/unrelocate the class as we can't find the table until
	; we do so, so...
	;
	; KLUDGE: We set the MASTER_CLASS bit for meta even though it's not
	; really a master class. This is to allow ObjCallMethodTable to use
	; this bit as the criterion based on which it checks the superclass
	; pointer to decide if it's got a variant or meta class on its hands.
	; 
	MetaClass	mask CLASSF_NEVER_SAVED or mask CLASSF_MASTER_CLASS


MetaProcessClassCode	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		ObjMetaGetClass

DESCRIPTION:	Returns class of object

PASS:
	*ds:si - instance data
	ds:di - instance data
	es - segment of MetaClass

	ax - MSG_META_GET_CLASS

	cx, dx, bp - ?

RETURN:
	cx:dx	- far ptr to class of object

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

ObjMetaGetClass	method	MetaClass, MSG_META_GET_CLASS
	mov	cx, ds:[di].MB_class.segment
	mov	dx, ds:[di].MB_class.offset
	ret
ObjMetaGetClass	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ObjMetaGetOptr

DESCRIPTION:	Returns optr of object

PASS:
	*ds:si - instance data
	ds:di - instance data
	es - segment of MetaClass

	ax - MSG_META_GET_OPTR

	cx, dx, bp - ?

RETURN:
	^lcx:dx	- optr of object

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

ObjMetaGetOptr	method	MetaClass, MSG_META_GET_OPTR
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	ret
ObjMetaGetOptr	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ObjMetaGetTargetAtTargetLevel

DESCRIPTION:	Default hander for MSG_META_GET_TARGET_AT_TARGET_LEVEL,
		returns info about current object

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_META_GET_TARGET_AT_TARGET_LEVEL

	cx	- 0 to return leaf target (this object), else TargetLevel
		  to seek out as defined by the UI.  This handler provides
		  leaf data, & presumes that other target levels are handled
		  in the UI, so if this object is reached, the target was not
		  found.
	
RETURN:
	cx:dx	- optr of this object
	ax:bp	- class of this object

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@

ObjMetaGetTargetAtTargetLevel	method dynamic	MetaClass, \
				MSG_META_GET_TARGET_AT_TARGET_LEVEL
	tst	cx
	jnz	notFound
	mov	cx, ds:[LMBH_handle]		; return object OD
	mov	dx, si
	mov	di, ds:[si]			; & object's Class
	mov	ax, ds:[di].MB_class.segment
	mov	bp, ds:[di].MB_class.offset
	ret

notFound:
	clr	cx			; Target Level not found (UI
	clr	dx			; is responsible for intercepting &
	clr	ax			; recognizing those levels)
	clr	bp
	ret

ObjMetaGetTargetAtTargetLevel	endm



COMMENT @-----------------------------------------------------------------------

METHOD:		ObjMetaObjFree -- MSG_META_OBJ_FREE for MetaClass

DESCRIPTION:	Free an object after clearing out the queues of the the
		owning process and the executing thread

PASS:
	*ds:si - object

RETURN:

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

-------------------------------------------------------------------------------@

ObjMetaObjFree	method static	MetaClass, MSG_META_OBJ_FREE

	; The inUse count is decremented in MSG_META_FINAL_OBJ_FREE

	call	ObjIncInUseCount

	; Now, flush input queues for this object, & when done call
	; MSG_META_FINAL_OBJ_FREE on the object to wrap up & nuke the puppy.
	;
	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	bx, ds:[LMBH_handle]	; ^lbx:si is this obj
					; cx, dx, bp - don't care
	mov	di, bx			; flushing is being performed for this
					;	block
	FALL_THRU	ObjStartQueueFlushCommon
ObjMetaObjFree	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjStartQueueFlushCommon

DESCRIPTION:	Start a flush of the input queue

CALLED BY:	INTERNAL

PASS:		^lbx:si	- final destination for message
		ax	- message to deliver after queue flushed
		cx, dx, bp	- any data to be passed in message
		di	- Block Handle that flushing is being performed for
			  (Generally the handle of the destination object
			  in the above Event).  This is the block from
			  which the "OWNING GEODE", as referenced in the
			  ObjFlushInputQueueNextStop enumerated type, is
			  determined.

RETURN:		nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Initial version
------------------------------------------------------------------------------@

ObjStartQueueFlushCommon	proc	far
EC <	xchg	bx, di							>
EC <	call	ECCheckMemHandleNSFar					>
EC <	xchg	bx, di							>

EC <	; Make sure we're not about to send a message to an object	>
EC <	; that's  not going to be around by the time the message is 	>
EC <	; actually sent to it.						>
EC <	;								>
EC <	call	ECObjEnsureBlockNotDying				>

	;
	; Start by recording event to dispatch once all the queues are freed
	;
	push	di
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; Pass Event in cx
	pop	dx			; handle of block in dx

	; Start flush at input manager.  Since we don't have an object to
	; just start at, send directly to input manager, with system input
	; object as the next stop.
	;
					; next ObjFlushInputQueueNextStop
	mov	bp, OFIQNS_SYSTEM_INPUT_OBJ
	call	ImInfoInputProcess	; Fetch bx = IM thread
	mov	di, mask MF_FORCE_QUEUE	; start queue flushing sequence
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	GOTO	ObjMessage
ObjStartQueueFlushCommon	endp


COMMENT @-----------------------------------------------------------------------

METHOD:		ObjMetaFinalObjFree -- MSG_META_FINAL_OBJ_FREE for MetaClass

DESCRIPTION:	Free chunk, unless this object came from a resource, in
		which case we mark dirty & resize to zero.

PASS:
	*ds:si - object

RETURN:

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

-------------------------------------------------------------------------------@

ObjMetaFinalObjFree	method static	MetaClass, MSG_META_FINAL_OBJ_FREE

	call	ObjDecInUseCount

	; Get our flags
	;
	mov	ax, si

	FALL_THRU	ObjFreeChunk

ObjMetaFinalObjFree	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjFreeChunk

DESCRIPTION:	Free chunk, unless this object came from a resource, in
		which case we mark dirty & resize to zero.

CALLED BY:	GLOBAL

PASS:
	*ds:ax - chunk to free

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@

ObjFreeChunk	proc	far

	push	ax
	call	ObjGetFlags			;al = flags
	test	al, mask OCF_IN_RESOURCE	;object in resource?
	pop	ax
	jz	free				;not in resource, free object

	push	bx, cx
						;mark as dirty, so will be
	mov	bx, mask OCF_DIRTY		;saved to state file
	call	ObjSetFlags

	clr	cx				;make zero length
	call	LMemReAlloc			;re-alloc the object
	pop	bx, cx
	ret

free:
	GOTO	LMemFree			;free the object

ObjFreeChunk	endp


COMMENT @-----------------------------------------------------------------------

METHOD:		ObjMetaGetFlags -- MSG_META_SET_FLAGS for MetaClass

DESCRIPTION:	Get the object chunk flags for a chunk

PASS:
	cx - chunk to get flags for

RETURN:
	al - flags
	ah - 0

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

-------------------------------------------------------------------------------@

ObjMetaGetFlags	method static	MetaClass, MSG_META_GET_FLAGS
	mov	ax,cx
	GOTO	ObjGetFlags

ObjMetaGetFlags	endm


COMMENT @-----------------------------------------------------------------------

METHOD:		ObjMetaSetFlags -- MSG_META_SET_FLAGS for MetaClass

DESCRIPTION:	Set the object chunk flags for a chunk

PASS:
	cx - chunk to set flags for
	dl - bits to SET
	dh - bits to RESET

RETURN:
	none

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

-------------------------------------------------------------------------------@

ObjMetaSetFlags	method static	MetaClass, MSG_META_SET_FLAGS
	mov	ax,cx
	mov	bx,dx
	GOTO	ObjSetFlags

ObjMetaSetFlags	endm


COMMENT @-----------------------------------------------------------------------

METHOD:		ObjMetaBlockFree -- MSG_META_BLOCK_FREE for MetaClass

DESCRIPTION:	Free block via MemFree

PASS:
	none

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

-------------------------------------------------------------------------------@

ObjMetaBlockFree	method 	MetaClass, MSG_META_BLOCK_FREE
	mov	bx, ds:[LMBH_handle]
	FALL_THRU	ObjFreeObjBlock

ObjMetaBlockFree	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjFreeObjBlock

DESCRIPTION:	Free an object block.

CALLED BY:	GLOBAL

PASS:
	bx - object block

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
	Tony	3/89		Initial version
	Doug	10/89		Added changes to match those in ObjDecInUseCount

------------------------------------------------------------------------------@

ObjFreeObjBlock	proc	far	uses ax, ds
	.enter

	call	ObjLockObjBlock
	mov	ds, ax

	; Check in-use count for block.  If non-zero, something in the
	; obj block is begging for us not to destroy it, so just set the
	; AUTO_FREE bit & quit out of here.  OTHERWISE, we have to have
	; faith in whoever this routine that they know what they are doing,
	; & this block really can be freed up.

	cmp	ds:[OLMBH_inUseCount], 0	; If 0, branch to start freeing
	je	startFreeing

	; Otherwise, set LMF_AUTO_FREE & quit out of this routine.  Another
	; attempt to free the block will be made by ObjDecInUseCount when
	; the count reaches 0.

EC <	; See if we've already starting set this flag			>
EC <	test	ds:[LMBH_flags], mask LMF_AUTO_FREE			>
EC <	ERROR_NZ	NESTED_FREE_OBJ_BLOCK				>
	ornf	ds:[LMBH_flags], mask LMF_AUTO_FREE

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	.leave
	ret


startFreeing:
	; we must be in the thread that executes the block since we are
	; doing just that.  We need to flush our event

EC <	; See if we're already in the middle of a death flush		>
EC <	test	ds:[LMBH_flags], mask LMF_DEATH_COUNT			>
EC <	ERROR_NZ	NESTED_FREE_OBJ_BLOCK				>

	inc	ds:[LMBH_flags]			; inc death flush count
	call	MemUnlock

	push	bx, cx, dx, si, di, bp

	mov	cx, bx				; Need to pass cx = block to
						; MSG_PROCESS_FINAL_BLOCK_FREE
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			; ax = exec thread
	mov	bx, ax				; bx is now handle of running
	clr	si				;	thread, where we should
						; 	dispatch the following
						;	message to.
	mov	ax, MSG_PROCESS_FINAL_BLOCK_FREE
						; Message to dispatch once
						; queue's have been cleared
	mov	di, cx				; pass block to flush for in di
	call	ObjStartQueueFlushCommon	; Do it!

	pop	bx, cx, dx, si, di, bp

	.leave
	ret

ObjFreeObjBlock	endp


;
; handlers for Object Variable Storage messages
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaAddVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add variable data entry

CALLED BY:	MSG_META_ADD_VAR_DATA

PASS:		dx	- size AddVarDataParams
		ss:bp	- ptr to AddVarDataParams
		NOTE: 	AVDP_dataType should have VDF_SAVE_TO_STATE set as
				       desired.  VDF_EXTRA_DATA is ignored, 
				       it will be set correctly by this
				       routine.
RETURN:		object marked dirty even if data type already exists
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es
		ax, cx, dx, bp


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version
	doug	11/91		Modified for changes to ObjVar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMetaAddVarData	method	dynamic MetaClass, MSG_META_ADD_VAR_DATA
	mov	ax, ss:[bp].AVDP_dataType
	mov	cx, ss:[bp].AVDP_dataSize
	call	ObjVarAddData		; get ds:bx ptr to extra data
	jcxz	done

					; setup es:di = dest
	push	ds
	pop	es
	mov	di, bx

					; setup ds:si = source
	mov	ax, ss:[bp].AVDP_data.high
	tst	ax
	jz	done
	mov	ds, ax
	mov	si, ss:[bp].AVDP_data.low

if	FULL_EXECUTE_IN_PLACE
EC <	xchg	ax, bx							>
EC <	call	ECAssertValidFarPointerXIP				>
EC <	xchg	ax, bx							>
endif

	rep	movsb			; initialize var data entry
done:
	Destroy	ax, cx, dx, bp
	ret
ObjMetaAddVarData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaDeleteVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete variable data type and extra data (if any).

CALLED BY:	MSG_META_DELETE_VAR_DATA

PASS:		*ds:si - object to delete variable data from
		ax - MSG_META_DELETE_VAR_DATA

		cx - data type to delete
			VarDataFlags ignored

RETURN:		carry clear if data deleted
		carry set if not found
		object marked dirty if data type found and deleted

ALLOWED TO DESTROY:
		bx, si, di, ds, es
		ax, cx, dx, bp


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMetaDeleteVarData	method	MetaClass, MSG_META_DELETE_VAR_DATA
	mov	ax, cx
	call	ObjVarDeleteData
	Destroy	ax, cx, dx, bp
	ret
ObjMetaDeleteVarData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaGetVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch data from variable data entry

CALLED BY:	MSG_META_GET_VAR_DATA

PASS:		dx	- size GetVarDataParams
		ss:bp	- ptr to GetVarDataParams
RETURN:		Buffer referred to in GetVarDataParams filled with data
		ax	- # of bytes copied out, or -1 if entry not found
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es
		ax, cx, dx, bp


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMetaGetVarData	method	dynamic MetaClass, MSG_META_GET_VAR_DATA
	mov	ax, ss:[bp].AVDP_dataType
	call	ObjVarFindData
	jnc	notFound
					; ds:bx is data
	mov	si, bx			; setup ds:si = source
	VarDataSizePtr	ds, si, cx	; get size in cx

					; setup es:di = dest
	mov	ax, ss:[bp].GVDP_buffer.high
	mov	es, ax
	mov	di, ss:[bp].GVDP_buffer.low

	; Use smaller of (VarData size, buffer size)
	;
	mov	ax, ss:[bp].GVDP_bufferSize
	cmp	cx, ax
	jbe	moveEmOut
	mov	cx, ax
moveEmOut:
	push	cx			; save # of bytes moved for return
	rep	movsb			; initialize var data entry
	pop	ax			; return # of bytes moved
exit:
	Destroy	cx, dx, bp
	ret

notFound:
	mov	ax, -1
	jmp	short exit
ObjMetaGetVarData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialized variable data component passed

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_INITIALIZE_VAR_DATA
		cx	- data type

RETURN:		ax	- offset to data entry
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMetaInitializeVarData	method MetaClass, MSG_META_INITIALIZE_VAR_DATA
EC <	cmp	cx, TEMP_EC_IN_USE_COUNT			>
EC <	je	TempCount					>
EC <	cmp	cx, TEMP_EC_INTERACTIBLE_COUNT			>
EC <	je	TempCount					>
	cmp	cx, TEMP_META_GCN
	je	TempGCN

;	mov	di, offset MetaClass
;	GOTO	ObjCallSuperNoLock
	ret			; no where to run to, baby, no where to hide..

TempGCN:
	push	si
	call	GCNListCreateBlock		; create list of lists
	mov	di, si				; di = chunk
	pop	si
	mov	ax, TEMP_META_GCN		; save to state may be needed
						; (if so, it is set in caller
						; of ObjVarDerefData)

	;
	; Add the vardata element, and initialize the data structure.
	; Set the TMGCNF_RELOCATED flag, since we must be in memory to
	; be adding vardata to an object.
	;

	mov	cx, size TempMetaGCNData
	call	ObjVarAddData
	mov	ds:[bx].TMGCND_flags, mask TMGCNF_RELOCATED
	mov	ds:[bx].TMGCND_listOfLists, di	; store list of lists
	mov	ax, bx		; Return offset to data element in ax
	ret

EC <TempCount:							>
EC <	mov	ax, cx						>
EC <	mov	cx, size word					>
EC <	call	ObjVarAddData					>
EC <	mov	{word} ds:[bx], 0				>
EC <	mov	ax, bx						>
EC <	ret							>

ObjMetaInitializeVarData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaGCNListDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Destroys GCN Lists & all chunks created for its implementation

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_GCN_LIST_DESTROY

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMetaGCNListDestroy	method	MetaClass, MSG_META_GCN_LIST_DESTROY
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData			; get ptr to TempGenAppGCNList
	jnc	done
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists
						; get other params
	call	GCNListDestroyBlock		; free all the chunks we've
						;	been using
	mov	ax, TEMP_META_GCN
	call	ObjVarDeleteData		; Remove var data element
done:
	ret

ObjMetaGCNListDestroy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaSetObjBlockOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the object block output to the passed OD.

CALLED BY:	MSG_META_SET_OBJ_BLOCK_OUTPUT

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_SET_OBJ_BLOCK_OUTPUT
		^lcx:dx - OD of output object

RETURN:		nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMetaSetObjBlockOutput		method dynamic MetaClass,
						MSG_META_SET_OBJ_BLOCK_OUTPUT

	; make sure that *ds:si is an object, not a process
EC < 	call 	ECCheckLMemObject					>

	mov	bx, cx				; bx:si <- OD of output object
	mov	si, dx
	call	ObjBlockSetOutput

	ret
ObjMetaSetObjBlockOutput		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaGetObjBlockOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the object block output.

CALLED BY:	MSG_META_GET_OBJ_BLOCK_OUTPUT

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_GET_OBJ_BLOCK_OUTPUT

RETURN:		^lcx:dx - block output

ALLOWED TO DESTROY:
	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMetaGetObjBlockOutput		method dynamic MetaClass,
						MSG_META_GET_OBJ_BLOCK_OUTPUT

	; make sure that *ds:si is an object, not a process
EC < 	call 	ECCheckLMemObject					>

	call	ObjBlockGetOutput	; ^lbx:si = block output
	movdw	cxdx, bxsi		; ^lcx:dx = block output

	ret
ObjMetaGetObjBlockOutput		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaDecBlockRefCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the reference count on one or two memory blocks.

CALLED BY:	MSG_META_DEC_BLOCK_REF_COUNT
PASS:		cx, dx	= handles whose counts should be decremented, or 0
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	if reference count goes to zero, block will be freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMetaDecBlockRefCount method dynamic MetaClass, MSG_META_DEC_BLOCK_REF_COUNT
		.enter
		mov	bx, cx
		call	MemDecRefCount
		mov	bx, dx
		call	MemDecRefCount
		.leave
		ret
ObjMetaDecBlockRefCount endm


MetaProcessClassCode	ends

;---------------------------------------------------------------

ChunkCommon segment resource


COMMENT @-----------------------------------------------------------------------

METHOD:		ObjMetaObjFlushInputQueue

DESCRIPTION:	Queue-flushing mechanism for object/window system, to
		ensure that references to, & messages destined for,
		the object/window have been flushed before the objects
		are freed.

PASS:		cx	- Event to dispatch upon conclusion of queue flushing
		dx	- Block Handle that flushing is being performed for
			  (Generally the handle of the destination object
			  in the above Event).  This is the block from
			  which the "OWNING GEODE", as referenced in the
			  ObjFlushInputQueueNextStop enumerated type, is
			  determined.
		bp	- ObjFlushInputQueueNextStop (Zero should be passed
			  in call to first object, from there is sequenced
			  by default MetaClass handler)
RETURN:		Nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Added for new thread model

-------------------------------------------------------------------------------@

ObjMetaObjFlushInputQueue	method	dynamic MetaClass,
					MSG_META_OBJ_FLUSH_INPUT_QUEUE
EC <	xchg	bx, dx							>
EC <	call	ECCheckMemHandleNSFar					>
EC <	xchg	bx, dx							>

EC <	cmp	bp, ObjFlushInputQueueNextStop				>
EC <	ERROR_AE	OBJ_FLUSH_INPUT_QUEUE_BAD_NEXT_STOP		>
EC <	test	bp, 1							>
EC <	ERROR_NZ	OBJ_FLUSH_INPUT_QUEUE_BAD_NEXT_STOP		>
	call	cs:objFlushInputQueueActionTable[bp]
	ret
	
ObjMetaObjFlushInputQueue	endm

objFlushInputQueueActionTable	label	word
	word	ObjFlushInputManager	; OFIQNS_INPUT_MANAGER
	word	ObjFlushSystemInputObj	; OFIQNS_SYSTEM_INPUT_OBJ
	word	ObjFlushGeodeInputObj	; OFIQNS_INPUT_OBJ_OF_OWNING_GEODE
	word	ObjFlushProcess		; OFIQNS_PROCESS_OF_OWNING_GEODE
	word	ObjFlushDispatch	; OFIQNS_DISPATCH

ObjFlushInputManager	proc	near
	call	ImInfoInputProcess
	clr	si
	GOTO	FlushNext
ObjFlushInputManager	endp

ObjFlushSystemInputObj	proc	near
	LoadVarSeg	ds, bx
	mov	bx, ds:[wPtrOutputOD].handle
	mov	si, ds:[wPtrOutputOD].chunk
	FALL_THRU	FlushNext
ObjFlushSystemInputObj	endp

FlushNext	proc	near
	inc	bp
	inc	bp
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
FlushNext	endp

ObjFlushGeodeInputObj	proc	near
	push	cx, dx
	mov	bx, dx
	call	MemOwnerFar
	call	WinGeodeGetInputObj
	mov	bx, cx
	mov	si, dx
	pop	cx, dx
	tst	bx			;If no input object, just dispatch the
	jz	ObjFlushDispatch	; message
	GOTO	FlushNext
ObjFlushGeodeInputObj	endp

ObjFlushProcess	proc	near
	mov	bx, dx
	call	MemOwnerFar	; get owning process
	clr	si
	GOTO	FlushNext
ObjFlushProcess	endp

ObjFlushDispatch	proc	near
	mov	bx, cx
	mov	di, mask MF_FORCE_QUEUE
	call	MessageDispatch
	ret
ObjFlushDispatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaGCNListAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Adds new optr to a particular notification list on this
		object's GCN system

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_GCN_LIST_ADD
		dx      - size GCNListParams
		ss:bp   - ptr to GCNListParams

RETURN:		carry   - set if optr added
               		- clear if optr is already there and not added
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Only MSG_META_GCN_LIST_ADD is allowed to create a
		TEMP_META_GCN stored GCN list that will be saved to state
		(GCNLT_SAVE_TO_STATE), so we handled that here by setting
		the VDF_SAVE_TO_STATE flag on TEMP_META_GCN, if needed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMetaGCNListAdd	method	MetaClass, MSG_META_GCN_LIST_ADD
	mov	ax, TEMP_META_GCN
	call	ObjVarDerefData			; get ptr to TempGenAppGCNList
	test	ss:[bp].GCNLP_ID.GCNLT_type, mask GCNLTF_SAVE_TO_STATE
	jz	noSaveToState
	ornf	{word} ds:[bx].VEDP_dataType, mask VDF_SAVE_TO_STATE
noSaveToState:
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists chunk
	call	ObjMetaGCNListFetchParams
	call	GCNListAddToBlock
	ret

ObjMetaGCNListAdd	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaGCNListRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Remove optr from a particular notification list on this 
		object's GCN system

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_GCN_LIST_REMOVE
		dx      - size GCNListParams
		ss:bp   - ptr to GCNListParams

RETURN:		carry   - set if optr added
               		- clear if optr is already there and not added
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMetaGCNListRemove	method	MetaClass, MSG_META_GCN_LIST_REMOVE
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData			; get ptr to TempGenAppGCNList
	jnc	done				; or quit if not found
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists chunk
	call	ObjMetaGCNListFetchParams
	call	GCNListRemoveFromBlock
done:
	ret

ObjMetaGCNListRemove	endm

ObjMetaGCNListFetchParams	proc	near
        mov     bx, ss:[bp].GCNLP_ID.GCNLT_manuf
        mov     ax, ss:[bp].GCNLP_ID.GCNLT_type
        mov     cx, ss:[bp].GCNLP_optr.handle
        mov     dx, ss:[bp].GCNLP_optr.chunk
	ret

ObjMetaGCNListFetchParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaGCNListSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send message to a particular GCN list in this object's
		GCN system

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_GCN_LIST_SEND
		dx      - size GCNListMessageParams
		ss:bp   - ptr to GCNListMessageParams

		NOTE:  If data block w/refernce count is passed in, its in-use
		       count should be incremented by one before the call/send
		       to this message, as this message decrements the count
		       by one upon completion.  (and destroys the block if
		       count reaches zero)


RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMetaGCNListSend	method	MetaClass, MSG_META_GCN_LIST_SEND
	mov	ax, TEMP_META_GCN

	test	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	jz	justSend
;setStatus:
	call	ObjVarDerefData			; get ptr to TempGenAppGCNList
	jmp	short continue

justSend:
	call	ObjVarFindData			; get ptr to TempGenAppGCNList
	jnc	done				; or quit if not found
continue:
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists
						; get other params

; Now, load params into registers.  Since ObjMetaGCNListFetchParams, though
; it operates on a slightly different data structure, would get the correct
; parameters into the correct registers, let's use it, but make sure the
; structers haven't changed:

.assert	(offset GCNLP_ID.GCNLT_manuf eq offset GCNLMP_ID.GCNLT_manuf)
.assert	(offset GCNLP_ID.GCNLT_type eq offset GCNLMP_ID.GCNLT_type)
.assert	(offset GCNLP_optr.handle eq offset GCNLMP_event)
.assert	(offset GCNLP_optr.chunk eq offset GCNLMP_block)

;        mov     bx, ss:[bp].GCNLMP_ID.GCNLT_manuf
;        mov     ax, ss:[bp].GCNLMP_ID.GCNLT_type
;        mov     cx, ss:[bp].GCNLMP_event
;        mov     dx, ss:[bp].GCNLMP_block
	call	ObjMetaGCNListFetchParams	; call routine instead

	mov	bp, ss:[bp].GCNLMP_flags	; pass GCNListSendFlags

	call	GCNListSendToBlock
	ret

done:
	; free up event
	;
	mov     bx, ss:[bp].GCNLMP_event
	call	ObjFreeMessage

	; free up reference to block, if any
	;
	mov     bx, ss:[bp].GCNLMP_block
	call	MemDecRefCount
	ret

ObjMetaGCNListSend	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMetaGCNListFindItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Look for a particular object on a particular notification list

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_GCN_LIST_FIND_ITEM
		dx      - size GCNListParams
		ss:bp   - ptr to GCNListParams
			  (GCNLP_optr.chunk = 0 for to match any chunk handle)

RETURN:		carry   - set if item found
               		- clear if not found
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMetaGCNListFindItem	method	MetaClass, MSG_META_GCN_LIST_FIND_ITEM
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData
	jnc	exit
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists chunk

	call	ObjMetaGCNListFetchParams	; get bx:ax - GCNListType
	clc					; don't create list
	call	GCNListFindListInBlock
	jnc	exit
	call	GCNListFindItemInList
exit:
	ret

ObjMetaGCNListFindItem	endm



COMMENT @-----------------------------------------------------------------------

METHOD:		MetaWinDecRefCount

DESCRIPTION:	Decrement window reference count on passed Window

PASS:		^hcx	- Window
RETURN:		Nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Added for new thread model

-------------------------------------------------------------------------------@

MetaWinDecRefCount	method	dynamic MetaClass,
					MSG_META_WIN_DEC_REF_COUNT
	mov	di, cx
	call	WinDecRefCount
	ret
MetaWinDecRefCount	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ObjMetaSendClassedEvent

DESCRIPTION:	Default handling for a classed event passed to an object
		via MSG_META_SEND_CLASSED_EVENT.  If this object belongs to 
		the class pointed to by the fptr stored in the OD field of
		the recorded event, then send the event to the this object,
		otherwise destroy it.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TravelOption:
			If TO_NULL, destroy
			else if TO_OBJ_BLOCK_OUTPUT send to output stored
				with ObjBlock
			else if TO_PROCESS send to owner of ObjBlock
			else call on self if possible.

RETURN:
	if Event delivered:
		carry, ax, cx, dx, bp 	- return values, if any, from method

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

ObjMetaSendClassedEvent	method dynamic	MetaClass, \
					MSG_META_SEND_CLASSED_EVENT
	mov	bx, cx

	tst	dx		; If TO_NULL, just destroy event.
	jz	destroyEvent

				; If TO_OBJ_BLOCK_OUTPUT, send message on to
				; the optr which is stored in the object
				; block header.
	cmp	dx, TO_OBJ_BLOCK_OUTPUT
	je	objBlock

	cmp	dx, TO_PROCESS
	je	process

				; Otherwise, call event on this object, 
				; if possible
	push	si
	call	ObjGetMessageInfo
	mov	di, si
	pop	si
	jcxz	dispatchEvent	; if class is null, same as MetaClass,
				; dispatch.
	mov	es, cx		; Get class ptr in es:di

	call	ObjIsObjectInClass
	jnc	destroyEvent

dispatchEvent:
	mov	cx, ds:[LMBH_handle]	; send here, to this object
	mov	di, mask MF_CALL
dispatchCommon:
	call	MessageSetDestination	; set destination
	call	MessageDispatch
	ret

destroyEvent:
	; HACK FOR IACP: If the event is MSG_META_DISPATCH_EVENT with bp
	; set to 0xadeb, it's a message that *must* be dispatched, as it's
	; the completion message for an IACP transaction. Just send the thing
	; to this object, rather than destroy it.
	LoadVarSeg	es, ax
	cmp	es:[bx].HE_method, MSG_META_DISPATCH_EVENT
	jne	reallyNukeIt
	cmp	es:[bx].HE_bp, 0xadeb
	je	dispatchEvent

reallyNukeIt:	
	call	ObjFreeMessage	; can't deliver -- nuke the event.
	;
	; Emulate ObjCallMethodTable, clearing AX and carry, so caller
	; can reliably determine if message was delivered, barring
	; thread crossings and assuming real handler always returns carry
	; set... -- ardeb 10/25/92
	; 
	clr	ax
	ret

process:
	call	GeodeGetProcessHandle
	xchg	bx, cx		; bx <- handle of event, cx <- process
	clr	di		; cannot call
	jmp	dispatchCommon

objBlock:
	mov	cx, ds:[OLMBH_output].handle
	jcxz	destroyEvent	; if no output, nuke event -- nowhere to
				; deliver
	xchg	bx, cx		; output handle in bx, ClassedEvent in cx
	mov	si, ds:[OLMBH_output].chunk
	mov	dx, TO_SELF	; change to deliver to self, if possible
	clr	di		; send, or call if possible, but no return data
	call	ObjMessage
	ret

ObjMetaSendClassedEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement usage count of Notification extra
		data block.  If usage count goes to zero, free the block.

CALLED BY:	GLOBAL

PASS:		bp - extra data block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMetaNotifyWithDataBlock	method	MetaClass, 
					MSG_META_NOTIFY_WITH_DATA_BLOCK,
					MSG_NOTIFY_FILE_CHANGE

	mov	bx, bp
	call	MemDecRefCount
	ret

ObjMetaNotifyWithDataBlock	endm


COMMENT @----------------------------------------------------------------------

METHOD:		ObjMetaIsObjectInClass

DESCRIPTION:	Determines if object is a member of the class passed.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_META_IS_OBJECT_IN_CLASS

	cx:dx	- class to see if object is a member of

RETURN:
	carry	- set if object is a member of the class

DESTROYED:
	di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

ObjMetaIsObjectInClass	method static	MetaClass, MSG_META_IS_OBJECT_IN_CLASS
	mov	es, cx
	mov	di, dx
	GOTO	ObjIsObjectInClass
ObjMetaIsObjectInClass	endm



COMMENT @----------------------------------------------------------------------

METHOD:		ObjMetaDispatchEvent

DESCRIPTION:

	A general method for causing an object to send/call a method of another
	object.  Useful for getting an object run by a different thread to call
	yet another object, or send a reply to the first object.
	to warrantee is expressed nor implied with this mechanism --
	it is strictly up to the caller to make sure that the detination object
	exists, that the MessageFlags passed are reasonable and do not result
	in deadlock situations, etc.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_META_DISPATCH_EVENT

	cx	- handle of Event to dispatch
	dx	- MessageFlags to use in ObjDispatchEvent:
                  MF_CALL - call destionation and return values in ax, cx,
                          dx, bp
                  MF_RECORD - causes the event not to be freed

RETURN:
	If MF_CALL option specified:
		carry, ax, cx, dx, bp 	- return values, if any, from method
	otherwise:
		ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

ObjMetaDispatchEvent	method MetaClass, \
				MSG_META_DISPATCH_EVENT

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	mov	bx, cx		; Event handle
	mov	di, dx		; ObjMessageFlags
	call	MessageDispatch

	pop	di
	call	ThreadReturnStackSpace
	ret

ObjMetaDispatchEvent	endm

ChunkCommon ends
