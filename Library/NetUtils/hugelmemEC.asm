COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		hugelmemEC.asm

AUTHOR:		Steve Jang, Apr 12, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/12/94   	Initial revision


DESCRIPTION:
	EC modules for hugelmem

	$Id: hugelmemEC.asm,v 1.1 97/04/05 01:25:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK
;
; EC stuff for HugeLMem
;
;
; EC stuff
;

;
; Maximum number of data blocks that a hugelmem can have
;
REASONABLE_BLOCK_NUMBER_UPPER_BOUND                     equ     500

;
; These numbers are arbitrary. The user should provide real optimal block
; size within this range. (for instance, 4K-8K)
;
REASONABLE_MINIMUM_BLOCK_SIZE                           equ     10
REASONABLE_MAXIMUM_BLOCK_SIZE                           equ     20000

WARNING_UNREASONABLE_NUMBER_OF_BLOCKS                   enum    Warnings
WARNING_UNREASONABLE_MIN_BLOCK_SIZE                     enum    Warnings
WARNING_UNREASONABLE_MAX_BLOCK_SIZE                     enum    Warnings
ERROR_MIN_BLOCK_SIZE_BIGGER_THAN_MAX_SIZE               enum    FatalErrors
ERROR_CORRUPTED_HUGELMEM_MAP_BLOCK                      enum    FatalErrors
ERROR_CHUNK_DOES_NOT_BELONG_TO_THIS_HUGELMEM            enum    FatalErrors

UNLOCKING_HUGE_LMEM_NOT_LOCKED_BY_THIS_THREAD		enum	FatalErrors
;
; Queue errors and warnings
;
WARNING_MAX_QUEUE_LENGTH_TOO_BIG			enum	Warnings
WARNING_MAX_LEN_BY_ELT_SIZE_TOO_BIG			enum	Warnings

ERROR_INITIAL_LENGTH_LARGER_THAN_MAX			enum	FatalErrors
ERROR_MAX_QUEUE_LENGTH_BEYOND_REASON			enum	FatalErrors
ERROR_MAX_LEN_BY_ELT_SIZE_BEYOND_REASON			enum	FatalErrors

WARNING_STRETCHING_QUEUE				enum	Warnings
WARNING_SHRINKING_QUEUE					enum	Warnings

endif

HugeLMemECCode              segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ECCheckHugeLMemParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Checks to make sure that the parameters to HugeLMemCreate
                are appropriate.

CALLED BY:      HugeLMemCreate
PASS:           ax      = number of blocks to be used
                bx      = minimum size for an optimal block
                cx      = maximum size for an optimal block
RETURN:         Error if bad parameters.
DESTROYED:      nothing
SIDE EFFECTS:   nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        SJ      3/18/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckHugeLMemParams   proc    far
if ERROR_CHECK
                .enter

                cmp     ax, REASONABLE_BLOCK_NUMBER_UPPER_BOUND
                WARNING_AE      WARNING_UNREASONABLE_NUMBER_OF_BLOCKS

                cmp     bx, REASONABLE_MINIMUM_BLOCK_SIZE
                WARNING_BE      WARNING_UNREASONABLE_MIN_BLOCK_SIZE

                cmp     cx, REASONABLE_MAXIMUM_BLOCK_SIZE
                WARNING_AE      WARNING_UNREASONABLE_MAX_BLOCK_SIZE

                cmp     cx, bx
                ERROR_B         ERROR_MIN_BLOCK_SIZE_BIGGER_THAN_MAX_SIZE

                .leave
endif
                ret
ECCheckHugeLMemParams   endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ECValidateHugeLMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       validates a HugeLMem

CALLED BY:      HugeLMemAlloc, HugeLMemFree, HugeLMemResize
PASS:           bx = HugeLMem( map handle )
RETURN:         signal error if corrupted HugeLMem
DESTROYED:      nothing
SIDE EFFECTS:   nothing
REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        SJ      3/17/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECValidateHugeLMem      proc    far
if ERROR_CHECK
                uses    ax,bx,cx,ds
                .enter
                push    bx
                call    MemPLock         ; ax = seg addr
                jc      error

		mov     ds, ax
		mov	ax, 50		; hack... just to let it keep going
                mov     bx, ds:HLMM_minOptimalSize
                mov     cx, ds:HLMM_maxOptimalSize
                call    ECCheckHugeLMemParams

                pop     bx
                call    MemUnlockV
	;
	; Checking semaphore: this is good way to veryfy that HugeLMem is
	;		      valid. But, postponed since I might change
	;		      the semaphore related code
	;

                .leave
                ret
error::
		ERROR   ERROR_CORRUPTED_HUGELMEM_MAP_BLOCK
else  ; ! ERROR_CHECK
		ret
endif
ECValidateHugeLMem      endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ECValidateHugeLMemChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Returns an error if given chunk does not belong to given
                hugelmem.

CALLED BY:      HugeLMemFree, HugeLMemResize
PASS:           bx      = hugelmem handle
                ^lax:cx = hugelmem chunk
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:   error if chunk is not valid

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        SJ      4/12/94         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateHugeLMemChunk proc    far
if ERROR_CHECK
                uses    ax,bx,ds,si
                .enter
                call    ECValidateHugeLMem
        ;
        ; See if the block belongs to HugeLMem given
        ;
                push    ax                      ; preserve data block handle
                call    MemPLock                ;-> ax = seg addr/CF set on err
                mov     ds, ax                          ; ds = map's seg addr
                pop     ax
                push    ax
                call    FindBufferBlock         ; -> ds:si = entry found
                ERROR_C ERROR_CHUNK_DOES_NOT_BELONG_TO_THIS_HUGELMEM
                call    MemUnlockV
        ;
        ; See if the chunk belongs to block
        ;
                pop     bx			; bx <- data block
                call    MemPLock
                mov     ds, ax
                mov     si, cx
                call    ECLMemValidateHandle	; (don't deref, as chunk might
						;  be zero-sized)
                call    MemUnlockV
                .leave
endif
                ret
ECValidateHugeLMemChunk endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECHugeLMemRemoveLockRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a lock on the passed block from the lock record for
		this thread.

CALLED BY:	(INTERNAL) HugeLMemUnlock
PASS:		es	= segment of data block
RETURN:		carry set if no more locks for this thread
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECHugeLMemRemoveLockRecord proc	far
if ERROR_CHECK
		uses	ax, ds, bx, si, di, dx, cx
		.enter
	;
	; Lock down the lock record for exclusive access.
	;
		mov	bx, es:[HLMDBH_locks]
		call	MemPLock
		mov	ds, ax
	;
	; Find our thread handle for comparison.
	;
		clr	bx
		mov	ax, TGIT_THREAD_HANDLE
		call	ThreadGetInfo
	;
	; Loop through the records looking for ones for this thread and this
	; block. We effectively make two passes. The first search is to find
	; a record to nuke. Once the record is nuked, we keep searching until
	; the end of the list or until we find another record for the pair.
	; This is how we know if there are any more locks on the block by this
	; thread.
	;
		mov	bx, es:[LMBH_handle]
		mov	si, offset HLMLRH_locks
		mov	cx, si			; cx <- non-zero
lockLoop:
		cmp	si, ds:[HLMLRH_free]
		jae	done			; => end of record
	;
	; See if this is a record for this pair.
	;

		cmp	ds:[si].HLMLR_block, bx
		jne	nextLock
		cmp	ds:[si].HLMLR_thread, ax
		jne	nextLock
		jcxz	moreLocks		; => found another lock after
						;  nuking one, so return carry
						;  clear
	;
	; Remove this record from the list.
	;
		push	es, si
		segmov	es, ds
		mov	di, si			; es:di <- dest for movsw
		add	si, size HugeLMemLockRecord	; ds:si <- move next one
							;  down onto this one
		mov	cx, ds:[HLMLRH_free]
		sub	cx, si			; cx <- # bytes to move
		shr	cx
			CheckHack <(size HugeLMemLockRecord and 1) eq 0>
		rep	movsw
		pop	es, si
		sub	ds:[HLMLRH_free], size HugeLMemLockRecord

		clr	cx			; cx <- we've deleted something
		jmp	lockLoop

nextLock:
	;
	; Not for this block+thread, so advance to the next, please.
	;
		add	si, size HugeLMemLockRecord
		jmp	lockLoop

done:
	;
	; Hit the end of the array. If cx is still non-zero, it means there was
	; no record of this block+thread pair, which is a Bozo no-no
	;
		tst	cx
		ERROR_NZ	UNLOCKING_HUGE_LMEM_NOT_LOCKED_BY_THIS_THREAD
	;
	; Signal no more locks for this block by this thread.
	;
		stc
		jmp	exit

moreLocks:
		clc
exit:
	;
	; Release the lock record.
	;
		mov	bx, es:[HLMDBH_locks]
		call	MemUnlockV
		.leave
endif
		ret
ECHugeLMemRemoveLockRecord endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECHugeLMemAddLockRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a record of this huge lmem block being locked by
		the current thread.

CALLED BY:	(INTERNAL)
PASS:		ds	= block being locked
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECHugeLMemAddLockRecord proc	far
if ERROR_CHECK
		uses	bx, si, ax, cx, ds, dx
		.enter
	;
	; Find thread handle & block handle.
	;
		clr	bx
		mov	ax, TGIT_THREAD_HANDLE
		call	ThreadGetInfo
		mov_tr	si, ax
		mov	dx, ds:[LMBH_handle]
	;
	; Lock down the lock record for exclusive access.
	;
		mov	bx, ds:[HLMDBH_locks]
		call	MemPLock
		mov	ds, ax
	;
	; See if there's enough room in the block for another record.
	;
		mov	ax, ds:[HLMLRH_free]
		cmp	ax, ds:[HLMLRH_max]
		jb	addRecord
	;
	; There's not. Add some random number of free records to the end and
	; enlarge.
	;
		add	ax, size HugeLMemLockRecord * 8
		mov	ds:[HLMLRH_max], ax
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc
		mov	ds, ax
addRecord:
	;
	; Add a new record to the end (no order maintained)
	;
		mov_tr	ax, si
		mov	si, ds:[HLMLRH_free]
		mov	ds:[si].HLMLR_thread, ax
		mov	ds:[si].HLMLR_block, dx
	;
	; Take up that space, please, and release the lock record again.
	;
		add	si, size HugeLMemLockRecord
		mov	ds:[HLMLRH_free], si
		call	MemUnlockV
		.leave
endif
		ret
ECHugeLMemAddLockRecord endp


HugeLMemECCode              ends
