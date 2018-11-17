COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Object
FILE:		objErrorCheck.asm

ROUTINES:
	Name			Description
	----			-----------

CALLED BY:	GLOBAL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

DESCRIPTION:
	This file contains error checking routines for the Object module

	$Id: objectErrorCheck.asm,v 1.1 97/04/05 01:14:41 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckClass

DESCRIPTION:	Check a Class pointer

CALLED BY:	GLOBAL

PASS:
	es:di - class pointer

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckClass	proc	far					>
NEC <	ret								>
NEC <ECCheckClass	endp						>

if	ERROR_CHECK

ECCheckClass	proc	far
	call	CheckClass
	ret
ECCheckClass	endp

CheckClass	proc	near
	pushf
	call	CheckNormalECEnabled
	jz	done
	push	ax

	push	ds
	segmov	ds, es
	xchg	si, di
	call	ECCheckBounds
	xchg	si, di
	pop	ds

	test	es:[di].Class_flags, not ClassFlags
	ERROR_NZ	BAD_CLASS
	cmp	es:[di].Class_methodCount, 4096
	ERROR_A	BAD_CLASS
	cmp	es:[di].Class_masterOffset, 256
	ERROR_A	BAD_CLASS
	test	es:[di].Class_masterOffset, 1
	ERROR_NZ	BAD_CLASS
	cmp	es:[di].Class_instanceSize, 16384
	ERROR_A	BAD_CLASS
; Removed 4/26/90 to prevent the input manager from blocking on the heap
; semaphore when dispatching events
;	mov	ax,es
;	call	ECCheckSegment

	pop	ax
done:
	popf
	ret

CheckClass	endp

endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckLMemObject, CheckLMemObject

DESCRIPTION:	Checks to see if *ds:si is a pointer into an object stored
		in an LMem block.  Will FatalError if "Object" is a process.

CALLED BY:	GLOBAL

PASS:
	*ds:si - object chunk to check

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


ECCheckLMemObject	proc	far
EC <	call	CheckLMemObject						>
	ret
ECCheckLMemObject	endp

if	ERROR_CHECK

CheckLMemObject		proc	near
	pushf
	call	CheckNormalECEnabled
	jz	exit
	push	ax
	push	bx
	push	di
	push	es
	LoadVarSeg	es

	test	si, 1
	ERROR_NZ	LMEM_CHUNK_HANDLE_AT_ODD_ADDRESS

	test	es:[sysECLevel], mask ECF_HIGH
	jz	done

					; Make sure ds:[0] holds memory
					; block handle w/address ds.
					; Sets bx = block handle
	call	CheckSelfReferencedMemSeg
					; Make sure a valid memory handle,
					; then that it is NOT a process handle
	call	CheckNotProcess

					; Make sure marked as an LMem Block
					; 	handle
	test	es:[bx].HM_flags, mask HF_LMEM
	ERROR_Z		OBJECT_NOT_IN_LMEM_BLOCK

					; Make sure LMem Block marked as being
					; 	an Object Block
	cmp	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	ERROR_NZ	OBJECT_NOT_IN_OBJECT_BLOCK
	call	ECLMemValidateHandle	; Make sure that is a valid chunk
					;	handle within this block

	mov	bx, ds:[si]		; get ptr to object instance
	inc	bx			; Make sure not an empty chunk
	ERROR_Z		OBJECT_CHUNK_EMPTY
	dec	bx			; Make sure not a free chunk handle
	ERROR_Z		OBJECT_CHUNK_HANDLE_FREE
	les	di, ds:[bx][MB_class]	; fetch the object class
	call	CheckClass		; Make sure a valid class table

	call	ECLMemValidateHeap	; Go crazy, do BRUTAL error checking
					; (BUT, only if HIGH EC level)

done:
	pop	es
	pop	di
	pop	bx
	pop	ax
exit:
	popf
	ret
CheckLMemObject		endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckObject, CheckObject

DESCRIPTION:	Checks to see if locked object passed is for real.  Allows
		both processes & LMem-stored objects.

CALLED BY:	GLOBAL

PASS:
	ds	- points to dgroup if "object" is actually a process
	*ds:si - object chunk to check

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


ECCheckObject	proc	far
EC <	call	CheckObject		; call near routine which does work>
	ret
ECCheckObject	endp

if	ERROR_CHECK
CheckObject	proc	near	uses bx, es
	.enter
	pushf

	LoadVarSeg	es
	test	es:[sysECLevel], mask ECF_HIGH
	jz	done


	; Make sure ds:[0] holds memory block handle w/address ds.

	call	CheckSelfReferencedMemSeg	; bx <- block handle

	test	es:[bx].HM_flags, mask HF_LMEM
	jz	done
	call	CheckLMemObject		; Otherwise, must be an LMem object
done:

	popf
	.leave
	ret

CheckObject	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckLMemOD

DESCRIPTION:	Checks to see if OD to a local-memory-based object
		is for real.

CALLED BY:	GLOBAL

PASS:
	bx:si - OD of object to check

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


ECCheckLMemOD	proc	far
if	ERROR_CHECK
	pushf
	call	CheckNormalECEnabled
	jz	Done
	tst	bx			; Allow NULL OD's
	jz	Done
					; Make sure a valid memory handle,
					; then that it is NOT a process handle
	call	CheckNotProcess
					; If run by diff thread, we can't do
					; very much:  Branch & check if LMem
	call	ObjTestIfObjBlockRunByCurThread
	jne	DifferentThread
	push	ax
	push	ds
	call	ObjLockObjBlockToDS	; If same thread, hey! we can go ahead
					; 	& check the object.
	call	CheckLMemObject		; Make sure everything is good about
					;	it.
	call	NearUnlock
	pop	ds
	pop	ax
DifferentThread:
	call	ECCheckLMemHandleNS	; All we can do is see if LMem handle
Done:
	popf
endif
	ret
ECCheckLMemOD	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckOD

DESCRIPTION:	Checks to see if OD passed is for real.  Allows
		both processes & LMem-stored objects.

CALLED BY:	GLOBAL

PASS:
	bx:si - OD of object to check

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


ECCheckOD	proc	far
if	ERROR_CHECK
	pushf
	push	ds
	tst	bx			; Allow NULL OD's
	jz	Done
	LoadVarSeg	ds
	test    ds:[sysECLevel], mask ECF_HIGH
	jz      Done			; skip out if segment EC not on
	cmp	ds:[bx].HG_type, SIG_THREAD
	jne	checkQueue
	tst	ds:[bx].HT_eventQueue
	jnz	Done			; thread has a queue, so it's ok

checkQueue:
	cmp	ds:[bx].HG_type, SIG_QUEUE
	je	Done			; event queues are legal

	call	ECCheckMemHandleNSFar
	cmp	bx, ds:[bx].HM_owner	; if handle = handle owner, is process
	je	Done			; & therefore an OK OD, done
	call	ECCheckLMemOD		; Othewise, make sure an object OD
Done:
	pop	ds
	popf
endif
	ret
ECCheckOD	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckSelfReferencedMemSeg

DESCRIPTION:	Blow up if ds:[0] isn't mem handle pointing at block

CALLED BY:	INTERNAL
		CheckObject, CheckLMemObject

PASS:
	ds	- segment of locked block
	es	- idata

RETURN:
	bx - handle of ds block

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

if	ERROR_CHECK
CheckSelfReferencedMemSeg	proc	near
	pushf
	call	CheckNormalECEnabled
	jz	done
	push	di
	mov	bx, ds:[LMBH_handle]	; Get presumed handle of block
	call	ECCheckMemHandleNSFar	; Make sure a Memory Block handle
	mov	di, ds			; copy segment to di
	cmp	di, es:[bx].HM_addr	; See if address matches stored handle
	ERROR_NZ	HANDLE_OF_BLOCK_NOT_STORED_IN_DS_0
	pop	di
done:
	popf
	ret
CheckSelfReferencedMemSeg	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckNotProcess

DESCRIPTION:	Make sure handle passed is a valid handle, but NOT
		a process handle

CALLED BY:	INTERNAL
		ECCheckLMemOD, CheckLMemObject

PASS:
	bx	- handle to test

RETURN:
	Nothing

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

if	ERROR_CHECK
CheckNotProcess	proc	near
	pushf
	call	CheckNormalECEnabled
	jz	done
	push	ds
	LoadVarSeg	ds
	call	ECCheckMemHandleNSFar
	cmp	bx, ds:[bx].HM_owner	; if handle = handle owner, is process
	ERROR_Z	PROCESS_HANDLE_NOT_ALLOWED
	pop	ds
done:
	popf
	ret
CheckNotProcess	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	NullDSIfObjBlock
FUNCTION:	NullESIfObjBlock
FUNCTION:	NullSegIfObjBlock	- Seg is passed in AX

DESCRIPTION:	Checks to see if passed segment is without question a segment
		of an LMem-based Object Block, & if so, the segment is NULL'ed
		out.  What, may you ask, is this used for?  Well, to catch
		programmers who aren't careful, & do things like the following
		in a method handler:

		; Fetch "data" from object in ^lcx:dx
		;
		push	si
		mov	bx, cx
		mov	si, dx
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	si

		; & store locally
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	ds:[di].OLWI_myData, ax
		ret

		The problem in the above code?  MF_FIXUP_DS wasn't passed to
		ObjMessage, meaning the store of data following could end up
		writing data to most anyplace on the heap.  The various
		object messaging routines call these EC utilities to cause
		the segment registers to become the "NULL_SEGMENT" value for
		the above types of scenerios, where the programmer hasn't asked
		for the register to be fixed up.  With this EC on, it will
		write to video memory, where it is easy to "see" that there
		is a problem.

CALLED BY:	INTERNAL

PASS:		ds/es/ax (depending on routine called)	- segment

RETURN:		ds/es/ax (depending on routine called)	- nulled out if
							  object block

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Initial version
------------------------------------------------------------------------------@

if	ERROR_CHECK
NullDSIfObjBlock	proc	far
	push	ax
	mov	ax, ds
	call	NullSegIfObjBlock
	mov	ds, ax
	pop	ax
	ret
NullDSIfObjBlock	endp

NullESIfObjBlock	proc	far
	push	ax
	mov	ax, es
	call	NullSegIfObjBlock
	mov	es, ax
	pop	ax
	ret
NullESIfObjBlock	endp

NullSegIfObjBlock	proc	far	uses	bx, ds, es
	pushf
	.enter
	LoadVarSeg	ds, bx
	test    ds:[sysECLevel], mask ECF_SEGMENT
	jz      exit			; skip out if segment EC not on

	mov	es, ax
	mov	bx, es:[LMBH_handle]	; get what we hope is a handle

        ; Make sure the thing's in bounds
	;
	test	bx, 0xf			; valid handle ID?
	jnz	exit
	cmp	bx, ds:[loaderVars].KLV_lastHandle	; after table?
	jae	exit
	cmp	bx, ds:[loaderVars].KLV_handleTableStart; before table?
	jb	exit

	; Check if ds:[LMBH_handle] is indeed handle of passed segment
	;
	cmp	ax, ds:[bx].HM_addr	; if not, exit, not an object block
	jne	exit

	; Check if LMem handle
	;
	test	ds:[bx].HM_flags, mask HF_LMEM
	jz	exit			; if not, exit, not an object block

	; Check if type ObjectBlock
	;
	cmp	es:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jne	exit			; if not, exit, not an object block.

	; Well, I'm convinced.  We've got an honest-to-god segment of an
	; Object Block here.  Let's nuke it & see what havoc results :)
	;
missed_fixup_label	label	near | ForceRef missed_fixup_label
;;;	nop
;;;	WARNING	YOU_FORGOT_A_FIXUP_FLAG_BOZO
	mov	ax, NULL_SEGMENT
exit:
	.leave
	popf
	ret
NullSegIfObjBlock	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	ECObjEnsureBlockNotDying

DESCRIPTION:	Blow up if block passed is an object block which is in the
		final stages of dying, i.e. a MSG_PROCESS_FINAL_BLOCK_FREE is 
		somewhere in the queues.

CALLED BY:	INTERNAL -- misc initiators of MSG_META_OBJ_FLUSH_INPUT_QUEUE
		WinFlushQueue
		ObjStartQueueFlushCommon

PASS:		bx	- block handle

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Initial version
------------------------------------------------------------------------------@

if	ERROR_CHECK
ECObjEnsureBlockNotDying	proc	far

	push	ax, ds
	LoadVarSeg	ds
	test    ds:[sysECLevel], mask ECF_HIGH
	jz      exit			; skip out if segment EC not on

RED <	cmp	ds:[bx].HG_type, SIG_UNUSED_FF				>
RED <	je	isMem							>

	cmp	ds:[bx].HG_type, SIG_NON_MEM
	jae	exit		; skip out if not obj block handle (likely
				; a thread or process handle)
RED <isMem:								>

	call	CheckToLock

	FastLock1	ds, bx, ax, ECOLOB_1, ECOLOB_2
	jc	fullyDiscarded

finish:
	INT_OFF
	push	es
	mov	es, ds:[bx].HM_addr
	cmp	es:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jne	afterObjBlockCheck

	; Check to see if death sequeunce has been started on this block
	;
	test	es:[LMBH_flags], mask LMF_DEATH_COUNT
	ERROR_NZ	OBJ_ILLEGAL_REFERENCE_TO_DYING_OBJECT_BLOCK

afterObjBlockCheck:
	pop	es
	INT_ON

	call	MemUnlock
exit:
	pop	ax, ds
	ret

	FastLock2	ds, bx, ax, ECOLOB_1, ECOLOB_2

	; Block is fully discarded

fullyDiscarded:
	call	FullObjLock

	jmp	finish
ECObjEnsureBlockNotDying	endp
endif
