COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swap Driver -- XMS Manager version
FILE:		xms.asm

AUTHOR:		Adam de Boor, May 21, 1990

ROUTINES:
	XmsStrategy		Driver strategy routine

    INT XmsStrategy		Entry point for this here driver

    INT XmsCheckFinal64K	Verify that we can actually read and write
				the final 64K of our extended memory block.
				It is sufficient to ensure we can read and
				write the first 128 bytes of the final 64K.
				This is to detect a buggy version of
				Microsoft's HIMEM.SYS that erroneously
				includes the HMA in the total extended
				memory available.

    INT XmsAllocDos5UMBs	Attempt to allocate upper memory blocks The
				DOS 5 Way.

    INT XmsInit			Initialization routine for driver. In
				separate resource so it can go away if need
				be.

    INT XmsExit			Release external resources allocated by the
				driver

    INT XmsDoNothing		Do-nothing routine for suspend/unsuspend

    INT XmsSwapOut		Swap a block out to extended memory with
				the XMM's help

    INT XmsSwapIn		Swap a block in from xms

    INT XmsDiscard		Delete the swap space associated with a
				block

    INT XmsGetMap		Return the segment of the swap map used by
				the driver

    INT XmsCompact		Reduce the memory usage of the swap driver to
				the desired target.

    INT XmsFindPageAndLimit	Figure the XMS handle to use for a
				transfer, as well as the number of bytes we
				can actually transfer.

    INT XmsTransfer		Perform a move to or from extended memory
				or the HMA

    INT XmsReadPage		Read page(s) in from extended memory via
				the XMM

    INT XmsWritePage		Write page(s) to extended memory via the
				XMM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/90		Initial revision (from extmem.asm)


DESCRIPTION:
	A driver to make use of memory above the 1Mb limit by means of a
	manager/driver that obeys the XMS protocol.
		
Some implementation details:
	When a block is swapped out, it is broken into pages and written
	out that way. We use a smaller page size than is used in disk swapping
	to reduce internal fragmentation, since the paging itself is
	faster and much less is gained from paging out in large pieces.

	We currently use a page size of 1K, just because.
	
	Like all swap drivers, we use the Swap library to maintain our
	swap map, allocate pages and tell us what to do. In general, the
	DR_SWAP functions we export are implemented by loading the segment
	of the swap map allocated for us by the library and calling a routine
	in the library. It will then determine what pages are affected, or
	allocate a list of pages, and call us back to perform the actual
	transfer to or from XMS memory.
	
	In the past, we would find how much extended memory was available
	and allocate it all at once. This can screw up task-switching,
	however, so we do things differently now. We still find how much
	extended memory is available, and allocate the HMA if it's available,
	and use that amount to size our swap map. We allocate extended 
	memory blocks only on demand, however. When we've been told to write
	to a page for which we don't have an extended memory block, we
	attempt to allocate a block for the page. If we can't, we return failure
	and the Swap library deals with it.
	
TO DO:
	
	$Id: xms.asm,v 1.1 97/04/18 11:58:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_SwapDriver		=	1

;------------------------------------------------------------------------------
;	Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include driver.def
include sem.def
include system.def
include file.def
include initfile.def
include drive.def
include disk.def

include Internal/interrup.def
include Internal/fileInt.def		;includes dos.def as well
include Internal/xms.def

DefDriver Internal/swapDr.def

UseLib	Internal/swap.def

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;
; Constants we use
;
ERR_XMS_NESTED_INIT 		enum FatalErrors
ERR_XMS_BAD_PU_COUNT		enum FatalErrors
ERR_XMS_GU_ERROR 		enum FatalErrors
ERR_XMS_CUR_NOT_NULL		enum FatalErrors
ERR_XMS_SO_BAD_OFFSET		enum FatalErrors
ERR_XMS_BAD_PAGE_INDEX 		enum FatalErrors
ERR_XMS_BIOS_ERROR 		enum FatalErrors
ERR_XMS_ADDR_OUT_OF_RANGE 	enum FatalErrors
ERR_XMS_INVALID_PROCESSOR 	enum FatalErrors
CANNOT_READ_SWAPPED_BLOCK	enum FatalErrors
ERR_XMS_TOO_MUCH_MEMORY		enum FatalErrors
ERR_XMS_USED_SPACE_MISMATCH	enum FatalErrors

;
; Driver flags:
;
XmsFlags	record
	XF_INITIALIZED:1,	; Non-zero if DR_INIT called
	XF_HAVE_HMA:1,		; Non-zero if we could allocate the HMA
	XF_HAVE_PURPOSE:1,	; Non-zero if we have a reason to be here,
				;  either b/c of the HMA, an EMB or the UMBs
	XF_DOS5:1,		; Non-zero if UMBs were allocated with new
				;  NIH DOS5 protocol.
XmsFlags	end

XMS_PAGE_SIZE	equ	1024

XMS_TEST_SIZE	equ	128	; Number of bytes to copy in and out of the
				;  first K in the final 64K of any extended
				;  memory block we allocate.

NUM_HMA_PAGES	equ (64 * 1024 - 16) / XMS_PAGE_SIZE

HMA_SEGMENT	equ	0xffff
HMA_BASE	equ	0x10
HMA_SIZE	equ	(NUM_HMA_PAGES * XMS_PAGE_SIZE)

MAX_UMBS	equ	8	; Largest number of upper memory blocks we
				;  can allocate and give to the heap.
MAX_EMBS	equ	8	; The number of extended memory blocks we'll
				;  allocate, at most
SMALLEST_UMB	equ	16	; Number of paragraphs a UMB must be before
				;  we're willing to allocate it. There's a point
				;  of diminishing returns here, as the heap gets
				;  fragmented with small free UMBs separated
				;  by larger locked blocks. 256 bytes seems a
				;  reasonable threshold for now.
LOG_ACTIONS	equ	FALSE

;==============================================================================
;			VARIABLES AND SUCH
;==============================================================================

idata	segment

;
; Driver information table
;
DriverTable	DriverInfoStruct <XmsStrategy,<>,DRIVER_TYPE_SWAP>

;
; State flags
;
xmsFlags		XmsFlags	<0,0,0,0,0>

idata	ends

;------------------------------------------------------------------------------
;	Uninitialized Variables
;------------------------------------------------------------------------------

udata	segment

xmsSwapMap	sptr.SwapMap	(?)

xmsMoveParams	XMSMoveParams

xmsUMBs		sptr	MAX_UMBS dup(0)	; Segments of allocated UMBs

xmsEMBs		XMSExtendedMemoryBlock	MAX_EMBS dup(<>) ; data for EMBs we've
							 ;  allocated so far

xmsAllocSize	word			; Kb to try and allocate for each
					;  EMB (total size/MAX_EMBS)
xmsAllocPages	word			; # pages in xmsAllocSize, so we don't
					;  try and allocate beyond our swap
					;  map.
;
; Entry point for the Extended Memory Manager, if it's around.
;
xmsAddr		fptr.far		; Entry point for the XMM
XMS_PRESENT?	= 0x4300		; value in AX for int 2fh to determine
					;  if XMM is present
XMS_HERE	= 0x80			; value returned in al if manager is
					;  around
XMS_ADDRESS?	= 0x4310		; value in AX for int 2fh to fetch
					;  the entry point for the XMM

if	LOG_ACTIONS

%out	TURN OFF ACTION LOGGING BEFORE YOU INSTALL

MAX_LOG		equ	128
logPtr		word	0

OpType		etype	word
OP_READ		enum	OpType
OP_WRITE	enum	OpType

opLog		OpType	MAX_LOG dup(?)
segLog		sptr	MAX_LOG	dup(?)
offLog		word	MAX_LOG dup(?)
sizeLog		sword	MAX_LOG dup(?)
pageLog		word	MAX_LOG dup(?)

endif

udata	ends

idata segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for this here driver

CALLED BY:	Kernel
PASS:		di	= function code
		refer to swapDriver.def for interface
RETURN:		depends on function invoked
DESTROYED:	depends on function invoked

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
xmsFunctions	nptr	XmsExit, XmsDoNothing, XmsDoNothing,
			XmsSwapOut, XmsSwapIn, XmsDiscard,
			XmsGetMap, XmsCompact, XmsDealloc, XmsDoNothing

XmsStrategy	proc	far	uses ds, es
		.enter
		segmov	ds, dgroup, ax	; ds <- data segment
		mov	es, ax

	;
	; Special-case DR_INIT as it's in a movable module.
	;
		cmp	di, DR_INIT
		jne	notInit
		call	XmsInit
done:
		.leave
		ret
notInit:
		call	cs:xmsFunctions-2[di]
		jmp	done
XmsStrategy	endp

idata ends

Init segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsCheckFinal64K
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that we can actually read and write the final 64K
		of our extended memory block. It is sufficient to ensure we
		can read and write the first 128 bytes of the final 64K.
		This is to detect a buggy version of Microsoft's HIMEM.SYS
		that erroneously includes the HMA in the total extended
		memory available.

CALLED BY:	XmsInit
PASS:		ds	= dgroup
		ax	= number of Kb in our extended memory block
		dx	= the handle of our extended memory block
RETURN:		ax	= number of usable Kb in our extended memory block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsCheckFinal64K proc	near
kbUsable	local	word \
		push	ax		; assume all of it's usable
kbTrimmed	local	word
		uses	bx, cx, dx, ds, es, si, di
		.enter
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_handle, dx
	;
	; Figure the Kb offset to which to copy. It should be 64 less than
	; the total size. If the total size is less than 64K, however, just
	; use an offset of 0.
	; 
		sub	ax, 64
		jge	setDest
		clr	ax		; just check offset 0
setDest:
		mov	ss:[kbTrimmed], ax
	;
	; Shift to multiply the result by 2**10 (1024)
	; 
		clr	bx
		shl	ax
		rcl	bx
		shl	ax
		rcl	bx
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.low.low, 0
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.low.high, al
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.high.low, ah
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.high.high, bl
	;
	; Allocate a block twice the size of the test sample so we've got
	; a source from which to copy the test pattern out and a destination
	; to which to copy it back.
	;
		mov	cx, mask HF_FIXED
		mov	ax, XMS_TEST_SIZE*2
		call	MemAlloc
		mov	es, ax		; es <- test block
		
	;
	; Initialize the low half of the block to some nice pattern, in this
	; case b[0] = block handle, b[i+1] = b[i]+17.
	; 
		clr	di
		mov	ax, bx
		mov	cx, XMS_TEST_SIZE/2
initLoop:
		stosw
		add	ax, 17
		loop	initLoop
	;
	; Perform the move out to extended memory.
	;
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_handle, 0
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.offset, 0
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.segment, es
		mov	ds:[xmsMoveParams].XMSMP_count.low, XMS_TEST_SIZE
		
		mov	ah, XMS_MOVE_EMB
		mov	si, offset xmsMoveParams
		call	ds:[xmsAddr]
		tst	ax
		jz	trim
	;
	; Now swap the source and dest, setting the dest to the second half of
	; the test staging area we allocated.
	;
		clr	ax
		xchg	ax, ds:[xmsMoveParams].XMSMP_dest.XMSA_handle
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_handle, ax
		mov	ax, XMS_TEST_SIZE
		xchg	ax, ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.offset
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.offset, ax
		mov	ax, es
		xchg	ax, ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.segment
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.segment, ax
		
		mov	ah, XMS_MOVE_EMB
		call	ds:[xmsAddr]
		tst	ax
		jz	trim
	;
	; Compare the two halves.
	;
		push	ds
		segmov	ds, es
		clr	si
		mov	di, XMS_TEST_SIZE
		mov	cx, XMS_TEST_SIZE/2
		repe	cmpsw
		pop	ds
		je	done
trim:
		mov	ax, ss:[kbTrimmed]
		mov	ss:[kbUsable], ax
done:
	;
	; Recover the staging-area's handle from its first word (clever of us
	; to use that pattern, wot?) and free the bloody thing.
	; 
		mov	bx, es:[0]
		call	MemFree
	;
	; Fetch the number of usable K on which we decided..
	;
		mov	ax, ss:[kbUsable]
		.leave
		ret
XmsCheckFinal64K endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsAllocDos5UMBs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to allocate upper memory blocks The DOS 5 Way.

CALLED BY:	XmsInit
PASS:		es:di	= xmsUMBs
		ds	= dgroup
RETURN:		xmsFlags.XF_DOS5 if UMBs couldn't be allocated
		xmsUMBs filled in (up to XMS_MAX_UMBS) with segments of
			allocated upper (or conventional, actually) memory
			blocks if they could be allocated.
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsAllocDos5UMBs proc	near
		.enter
	;
	; Get current allocator state so we can restore it.
	;
		mov	ax, MSDOS_GET_UMB_LINK
		call	FileInt21
		push	ax		; save UMB link status for end
		
		mov	ax, MSDOS_GET_STRAT
		call	FileInt21
		push	ax		; save previous allocation strategy
		
	;
	; Now give us access to the upper memory, dammit.
	;
		mov	ax, MSDOS_SET_UMB_LINK
		; DOS may only care about the byte in bl, but NTVDM looks
		; at the whole word.  Go figure.  Thanks to Marcus Groeber
		; for finding this one. -dhunter 1/17/2000
		mov	bx, 1		; include upper memory in your fascist
					;  search
		call	FileInt21
		jc	done
		
	;
	; First fit in UMB, please oh mighty Microsoft, God of
	; All Operating Systems...
	;
		mov	ax, MSDOS_SET_STRAT
		mov	bl, DosAllocStrat <1, DAS_FIRST_FIT>
		call	FileInt21
		jc	done

	;
	; Keep trying to allocate useful blocks until everything is ours.
	; ha ha ha ha ha ha!
	;
allocLoop:
		mov	bx, 0xffff	; return largest value, please
		mov	ah, MSDOS_ALLOC_MEM_BLK
		call	FileInt21
		jnc	haveBlock	; wheeeeeee. unlikely, but what the
					;  f***. It could happen. It could!
		cmp	ax, ERROR_INSUFFICIENT_MEMORY
		jne	done

		cmp	bx, SMALLEST_UMB; too small to be useful?
		jb	done		; yes -- ignore it

		mov	ah, MSDOS_ALLOC_MEM_BLK
		call	FileInt21
		jc	done

haveBlock:
	; ax = segment of allocated block.
		stosw
		mov	cx, bx		; cx <- block length (paras)
					; ax already segment
		call	MemExtendHeap

		cmp	di, offset xmsUMBs + size xmsUMBs
		jb	allocLoop

done:
	;
	; Restore the allocation strategy, etc.
	;
		pop	bx
		mov	ax, MSDOS_SET_STRAT
		call	FileInt21
		
		pop	bx
		clr	bh		; GET_UMB_LINK returns only a
					;  byte, but SET_UMB_LINK insists
					;  on a word... -- ardeb 6/7/91
		mov	ax, MSDOS_SET_UMB_LINK
		call	FileInt21
	;
	; See if we netted any UMBs out of this. If not, clear the XF_DOS5
	; flag. If so, set the XF_HAVE_PURPOSE
	;
		mov	al, ds:[xmsFlags]
		andnf	al, not mask XF_DOS5	; assume the worst
		cmp	di, offset xmsUMBs
		je	exit
		ornf	al, mask XF_DOS5 or mask XF_HAVE_PURPOSE
exit:
		mov	ds:[xmsFlags], al
		.leave
		ret
XmsAllocDos5UMBs endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialization routine for driver. In separate
		resource so it can go away if need be.

CALLED BY:	XmsInit
PASS:		DS	= dgroup
RETURN:		Carry set on error
DESTROYED:	AX, BX, ...

PSEUDO CODE/STRATEGY:
	Set the XF_INITIALIZED flag
	Attempt to allocate the HMA, setting XF_HAVE_HMA if we can
	Find the largest free block in extended memory and allocate it.
	Allocate a swap map big enough to cover the space allocated.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsInit		proc	far 	uses es, di, si
numPages	local	word
		.enter
		mov	numPages, 0
	;
	; Make sure DOS is >= 3.0
	;
		mov	ax, MSDOS_GET_VERSION shl 8
		call	FileInt21
		cmp	al, 3
		LONG jb	outtaHere	; => major version < 3, so no XMS
					;  possible.
	;
	; If version is 5.0+, flag a possible need for DOS5 UMB support.
	;
		cmp	al, 5
		jb	checkXms
		ornf	ds:[xmsFlags], mask XF_DOS5
checkXms:
	;
	; See if an Extended Memory Manager is present.
	;
		mov	ax, XMS_PRESENT?
		int	2fh
		cmp	al, XMS_HERE
		je	fetchXMSAddr
		stc
		jmp	outtaHere

fetchXMSAddr:
	;
	; Fetch the entry address for the thing.
	;
EC <		push	es		; avoid segment-checking death 	>
		mov	ax, XMS_ADDRESS?
		int	2fh
		mov	ds:xmsAddr.offset, bx
		mov	ds:xmsAddr.segment, es
EC <		pop	es						>
	;
	; Allocate the HMA if possible.
	;
		mov	ah, XMS_ALLOC_HMA
		mov	dx, 0xffff	; Give us all of it, precioussss
		call	ds:xmsAddr
		tst	ax
		jz	tryForEMB
		
	;
	; Turn on A20 until we exit -- no one around here relies on the wrapping
	; at 1Mb... XXX: Of course, lord knows about Other People's Software
	;
		mov	ah, XMS_GLOBAL_ENABLE_A20
		call	ds:xmsAddr

	;
	; Note that we have the HMA and a purpose, adding the number of
	; pages in the HMA to our total.
	; 
		ornf	ds:xmsFlags, mask XF_HAVE_HMA or mask XF_HAVE_PURPOSE
		add	numPages, NUM_HMA_PAGES

tryForEMB:
	;
	; Allocate the largest free EMB.
	; XXX: Allocate them all, if more than one?
	;
		mov	ah, XMS_QUERY_FREE_EMB
		call	ds:xmsAddr
		tst	ax
		jz	checkUMB

		push	ax		; Save block size...
		mov	dx, ax		; Give me THIS much
		mov	ah, XMS_ALLOC_EMB
		call	ds:xmsAddr
		tst	ax		; success?
		pop	ax
		jz	checkUMB	; Nope. Yuck

		call	XmsCheckFinal64K
		tst	ax		; anything useful?
		jnz	haveEMB		; yup -- keep it

		mov	ah, XMS_FREE_EMB; bleah
		call	ds:[xmsAddr]
		jmp	checkUMB

haveEMB:
		ornf	ds:xmsFlags, mask XF_HAVE_PURPOSE
	;
	; Free the thing again. We allocated it only so we could call
	; XmsCheckFinal64K
	; 
		push	ax
		mov	ah, XMS_FREE_EMB
		call	ds:[xmsAddr]
		pop	ax
	;
	; If not working in Kb pages, adjust AX to reflect the number of
	; pages, given it's the number of Kb available.
	;
IF XMS_PAGE_SIZE LT 1024
		; smaller than a K, must multiply by ratio
		mov	di, 1024/XMS_PAGE_SIZE
		mul	di
ELSEIF XMS_PAGE_SIZE GT 1024
		; more than a K, must divide by ratio
		mov	di, XMS_PAGE_SIZE/1024
		clr	dx
		div	di
ENDIF

		;
		; All pages are free at this point.
		;
		add	numPages, ax
	;
	; Figure the number to allocate for each EMB
	; 
		add	ax, MAX_EMBS-1
IF MAX_EMBS ne 8
   		cbw
		mov	cx, MAX_EMBS
		div	cx
ELSE
		shr	ax
		shr	ax
		shr	ax
ENDIF
		mov	ds:[xmsAllocPages], ax
IF XMS_PAGE_SIZE ne 1024
   		mov	dx, XMS_PAGE_SIZE
		mul	dx
		add	ax, 1023	; round allocation up to be sure
		adc	dx, 0 		;  all pages will fit
		mov	cx, 1024
		div	cx
ENDIF
		mov	ds:[xmsAllocSize], ax

checkUMB:
	;
	; Now allocate up to MAX_UMBS upper memory blocks for the heap, if
	; they're available.
	;
		segmov	es, ds		 ; es <- dgroup to make life easier
		mov	di, offset xmsUMBs
umbLoop:
		;
		; Find the size of the next largest UMB. The initial ALLOC call
		; must fail, since we're asking for 1Mb (DX is in paragraphs).
		;
		mov	dx, 0xffff
		mov	ah, XMS_ALLOC_UMB
		call	ds:xmsAddr
		cmp	bl, XMS_SMALLER_UMB_AROUND
		jne	checkDos5UMB		;some other error, so we're done
		
		;
		; If any UMB is around, DOS5 can't have snagged them all...
		;
		andnf	ds:[xmsFlags], not mask XF_DOS5

		;
		; See if the block is too small to be useful. If so, break
		; out, as we assume nothing larger is around...
		; 
		cmp	dx, SMALLEST_UMB
		jb	checkDos5UMB
		;
		; Allocate the returned amount.
		;
		mov	ah, XMS_ALLOC_UMB
		call	ds:xmsAddr
		tst	ax
		jz	checkDos5UMB		; shouldn't happen

		ornf	ds:xmsFlags, mask XF_HAVE_PURPOSE
		xchg	ax, bx			; ax <- segment
		stosw				; save the segment
		mov	cx, dx			; cx <- block length (paras)
		call	MemExtendHeap
		cmp	di, offset xmsUMBs + size xmsUMBs
		jb	umbLoop

checkDos5UMB:
		cmp	di, offset xmsUMBs
		jne	seeIfUseful
		test	ds:[xmsFlags], mask XF_DOS5
		jz	seeIfUseful
	;
	; Well, it looks like DOS 5 has snagged them all, so let's get down to
	; the business of allocating the blocks Their Way.
	;
		call	XmsAllocDos5UMBs
seeIfUseful:
	;
	; We've done all we can do. See if we've accomplished anything.
	;
		test	ds:xmsFlags, mask XF_HAVE_PURPOSE
		stc
		jz	outtaHere

		ornf	ds:[xmsFlags], mask XF_INITIALIZED

	;
	; Allocate a swap map if we actually have some swap space.
	;
		mov	ax, numPages
		tst	ax
		jz	noSwapMap

		push	bp
		mov	bx, handle 0
		mov	cx, XMS_PAGE_SIZE
		mov	si, segment XmsWritePage
		mov	di, offset XmsWritePage
		mov	dx, segment XmsReadPage
		mov	bp, offset XmsReadPage
		call	SwapInit
		pop	bp
		jc	outtaHere
		
		mov	ds:[xmsSwapMap], ax

	;
	; Tell the kernel we're here...
	;
		mov	cx, segment XmsStrategy
		mov	dx, offset XmsStrategy
		mov	ax, SS_PRETTY_FAST
		call	MemAddSwapDriver
		jc	outtaHere	; Couldn't register, so return error.

noSwapMap:
	;
	; Make the init code be discard-only now, since we need it no
	; longer.
	;
		mov	bx, handle Init
		mov	ax, mask HF_DISCARDABLE or (mask HF_SWAPABLE shl 8)
		call	MemModifyFlags
		clc
outtaHere:
		.leave
		ret
XmsInit		endp

Init ends

idata	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release external resources allocated by the driver

CALLED BY:	DR_EXIT
PASS:		ds=es=dgroup
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsExit		proc	near
		uses	es, si
		.enter
	;
	; Release the HMA and turn off A20 if we were able to allocate the
	; sucker.
	;
		test	ds:xmsFlags, mask XF_HAVE_HMA
		jz	releaseEMBs

		mov	ah, XMS_FREE_HMA
		call	ds:xmsAddr

		mov	ah, XMS_GLOBAL_DISABLE_A20
		call	ds:xmsAddr

releaseEMBs:
	;
	; Free any extended memory blocks we were able to allocate.
	;
		mov	si, offset xmsEMBs
freeEMBLoop:
		clr	dx
		xchg	dx, ds:[si].XMSEMB_handle
		tst	dx
		jz	releaseUMBs
		mov	ah, XMS_FREE_EMB
		call	ds:[xmsAddr]
		add	si, size XMSExtendedMemoryBlock
		cmp	si, offset xmsEMBs + size xmsEMBs
		jb	freeEMBLoop

releaseUMBs:
	;
	; Release any upper-memory blocks we allocated. We are guaranteed
	; that nothing of interest resides in them now...
	;
		mov	si, offset xmsUMBs
freeUMBLoop:
		lodsw
		tst	ax
		jz	done
		test	ds:[xmsFlags], mask XF_DOS5
		jnz	freeDOS5UMB
		xchg	ax, dx
		mov	ah, XMS_FREE_UMB
		call	ds:xmsAddr
nextUMB:
		cmp	si, offset xmsUMBs + size xmsUMBs
		jb	freeUMBLoop
done:
		andnf	ds:xmsFlags, not mask XF_INITIALIZED
		.leave
		ret
freeDOS5UMB:
		mov	es, ax
		mov	ah, MSDOS_FREE_MEM_BLK
		call	FileInt21
		jmp	nextUMB
XmsExit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine for suspend/unsuspend

CALLED BY:	DR_SUSPEND, DR_UNSUSPEND
PASS:		who cares?
RETURN:		carry clear
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsDoNothing	proc	near
		.enter
		clc
		.leave
		ret
XmsDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Coming back from an unsuspend, reallocate UMBs and HMA.
		Re-enable A20.

CALLED BY:	Special circumstances...
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsUnsuspend	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Get HMA back if necessary.
	;
		test	ds:[xmsFlags], mask XF_HAVE_HMA
		jz	reallocUMBs

		mov	ah, XMS_ALLOC_HMA
		mov	dx, 0xffff
		call	ds:xmsAddr
		tst	ax
		jz	error
		mov	ah, XMS_GLOBAL_ENABLE_A20
		call	ds:xmsAddr

reallocUMBs:
	;	
	; Oh boy...
	;

exit:
		.leave
		ret
error:
	;
	; Unexpectedly, something we should be able to reallocate could
	; not be reallocated.  What now?
	;
		stc
		jmp	exit
XmsUnsuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsSwapOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap a block out to extended memory with the XMM's help

CALLED BY:	DR_SWAP_SWAP_OUT
PASS:		dx	= segment of data block
		cx	= size of data block (bytes)
RETURN:		carry clear if no error
		ax	= swap ID of block
DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
	Allocate room for the block in the HMA or our EMB. If can't, return
		error.
	Write each page out to the memory via the XMM (XXX: do things
		contiguously?)
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsSwapOut	proc	near
		.enter
		mov	ax, ds:[xmsSwapMap]
		call	SwapWrite
		.leave
		ret
XmsSwapOut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsSwapIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap a block in from xms

CALLED BY:	DR_SWAP_SWAP_IN
PASS:		ds	= dgroup
		bx	= ID of swapped data (initial page)
		dx	= segment of destination block
		cx	= size of data block (bytes)
RETURN:		carry clear if no error
DESTROYED:	ax, bx, cx (ds, es preserved by XmsStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	ardeb	12/ 9/89	Changed to single-swapfile model

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsSwapIn	proc	near
		.enter
		mov	ax, ds:[xmsSwapMap]
		call	SwapRead
		.leave
		ret
XmsSwapIn	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsDiscard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the swap space associated with a block

CALLED BY:	DR_SWAP_DISCARD
PASS:		bx	= ID returned from DR_SWAP_SWAP_OUT (first page #)
		ds	= dgroup
RETURN:		carry clear if no error
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	Free up the page list whose head is bx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added
	ardeb	12/9/89		Changed to single-swapfile model

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsDiscard	proc	near
		.enter
		mov	ax, ds:[xmsSwapMap]
		call	SwapFree
		.leave
		ret
XmsDiscard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsGetMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the segment of the swap map used by the driver

CALLED BY:	DR_SWAP_GET_MAP
PASS:		ds	= dgroup
RETURN:		ax	= segment of SwapMap
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsGetMap	proc	near
		.enter
		mov	ax, ds:[xmsSwapMap]
		.leave
		ret
XmsGetMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsCompact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate the data in XMS extended memory so that there
		is at least a certain amount of free space left.

CALLED BY:	DR_SWAP_COMPACT

PASS:		bx	= in Kbytes, the desired amount of free space.
		dx	= swap driver ID (i.e., what's stored in
			  HSM_swapDriver for blocks swapped to this
			  device.)
		ds	= dgroup

RETURN:		if success:
			carry clear
			ax	= Kbytes used by this swap driver
		else:
			carry set.

DESTROYED:	nothing
SIDE EFFECTS:	
	- Mucks with the handle table...

PSEUDO CODE/STRATEGY:
	- figure out the maximum page number below which we have to stay
	  in order to satisfy the target.
	- walk the handle table looking for blocks marked swapped to this
	driver.  For each block, check if any pages are above the desired
	target.  If so, look in the free list for a slot below the limit
	page number.
	- stop if we either run out of free pages below the limit (fail)
	or we have run through the whole handle table (success).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsCompact	proc	near
		uses	bx,cx,dx,es,di
		.enter
		mov	cx, dx			;swap driver ID

	;
	; How much total swap space do we have?
	;
		mov	ax, ds:[xmsSwapMap]
		mov	es, ax
		mov	ax, es:[SM_total]

	;
	; don't count the HMA pages
	;
		test	ds:xmsFlags, mask XF_HAVE_HMA
		jz	havePages
		sub	ax, NUM_HMA_PAGES
havePages:

IF XMS_PAGE_SIZE LT 1024
		; smaller than a K, must multiply by ratio
		mov	di, 1024/XMS_PAGE_SIZE
		mul	di
ELSEIF XMS_PAGE_SIZE GT 1024
		; more than a K, must divide by ratio
		mov	di, XMS_PAGE_SIZE/1024
		clr	dx
		div	di
ENDIF
	;
	; What is the maximum space this swap device can occupy?
	;
		sub	ax, bx		
		mov	dx, ax			;dx = maximum Kbytes
		mov	ax, ds:[xmsSwapMap]
		call	SwapCompact

		mov	ax, dx			;ax = maximum Kbytes
		.leave
		ret
		
XmsCompact	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsDealloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free all Upper Memory Blocks and all possible Extended
		Memory Blocks.

CALLED BY:	DR_SWAP_DEALLOC
PASS:		bx	= Kbytes used by this swap driver.
		ds	= dgroup
RETURN:		if success:
			carry clear
		else:
			carry set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsDealloc	proc	near
		uses	ax,bx,cx,dx,si,di
		.enter
if 0
;;
;; This error check code is only useful in limited cases.
;;

		push	ax,bx,cx,es,di
	; 
	; The number of used bytes passed in ax should equal the total swap
	; space minus the number of free pages.
	;	
		mov	ax, ds:[xmsSwapMap]
		mov	es, ax
		mov	ax, es:[SM_total]
		sub	ax, es:[SM_numFree]	;ax = total pages used
	;
	; don't count the HMA pages
	;
		test	ds:xmsFlags, mask XF_HAVE_HMA
		jz	havePages
		sub	ax, NUM_HMA_PAGES
havePages:

IF XMS_PAGE_SIZE LT 1024
		; smaller than a K, must multiply by ratio
		mov	di, 1024/XMS_PAGE_SIZE
		mul	di
ELSEIF XMS_PAGE_SIZE GT 1024
		; more than a K, must divide by ratio
		mov	di, XMS_PAGE_SIZE/1024
		clr	dx
		div	di
ENDIF

		cmp	ax, bx
		ERROR_NE ERR_XMS_USED_SPACE_MISMATCH
		pop	ax,bx,es,di
endif

	; 
	; All the pages used by the XMS swap driver have been compacted 
	; into the lower ax kbytes of the allocated EMBs.
	; Now walk through xmsEMBs, and free or don't touch each EMB.
	;
		mov	ax, bx				;used space
		mov	bx, ds:[xmsAllocSize]		;size of each EMB.
		mov	cx, MAX_EMBS
		mov	si, offset xmsEMBs
embLoop:
	; when ax becomes negative, start freeing those blocks.
		sub	ax, bx	
		jge 	dontFree
		
		mov	dx, ds:[si].XMSEMB_handle
		tst	dx
		jz	dontFree

		push	ax
		mov	ah, XMS_FREE_EMB
		call	ds:[xmsAddr]
EC <		cmp	ax, 0					>
EC <		ERROR_Z	-1					>
		jz	error
		clr	ds:[si].XMSEMB_handle
		pop	ax

dontFree:
		add 	si, size XMSExtendedMemoryBlock
		loop	embLoop

	;
	; Don't release UMBs and HMA for now... HACK.
	;
		jmp	done
	;
	; Release HMA and turn off A20 if we were able to allocate it.
	; 
		test	ds:xmsFlags, mask XF_HAVE_HMA
		jz	releaseUMBs

		mov	ah, XMS_FREE_HMA
		call	ds:xmsAddr

		mov	ah, XMS_GLOBAL_DISABLE_A20
		call	ds:xmsAddr

releaseUMBs:
	;
	; Release any upper-memory blocks we allocated. We are guaranteed
	; that nothing of interest resides in them now...
	;
		mov	si, offset xmsUMBs
freeUMBLoop:
		lodsw
		tst	ax
		jz	noMore
		test	ds:[xmsFlags], mask XF_DOS5
		jnz	freeDOS5UMB
		xchg	ax, dx
		mov	ah, XMS_FREE_UMB
		call	ds:xmsAddr
nextUMB:
		cmp	si, offset xmsUMBs + size xmsUMBs
		jb	freeUMBLoop
noMore:
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done

freeDOS5UMB:
		mov	es, ax
		mov	ah, MSDOS_FREE_MEM_BLK
		call	FileInt21
		jmp	nextUMB
XmsDealloc	endp

;==============================================================================
;
;		    UTILITY AND CALLBACK ROUTINES
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsFindPageAndLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the XMS handle to use for a transfer, as well as the
		number of bytes we can actually transfer.

CALLED BY:	XmsTransfer
PASS:		ax	= page number (always from the start of the extended
			  area, i.e. if we've got the HMA, NUM_HMA_PAGES
			  will have been subtracted from what the Swap
			  library passed us)
		xmsMoveParams.XMSMP_count.low total bytes left in the transfer
		ds:bx	= XMSAddr in which the EMB address should be placed when
			  we've found it.
		es	= segment of swap map
RETURN:		carry set if transfer cannot take place (couldn't allocate
			an EMB for the page)
		carry clear if all set:	
			cx	= bytes left to transfer after this one
			ax	= starting page of transfer after this one
			xmsMoveParams.XMSMP_count.low adjusted to hold the
				number of bytes that can be transferred
				this time
			ds:[bx]	set up appropriately
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsFindPageAndLimit proc	near
		uses	di, dx
		.enter
	;
	; Look for the block that contains the starting page.
	; 
		mov	si, offset xmsEMBs
		mov	di, ax
findLoop:
		tst	ds:[si].XMSEMB_handle	; any memory?
		jz	allocNew		; no -- allocate some

		sub	ax, ds:[si].XMSEMB_pages; reduce page by number in
						;  this block
		jb	foundBlock		; => starting page is in
						;  this block

		add	si, size XMSExtendedMemoryBlock
		cmp	si, offset xmsEMBs + size xmsEMBs
		jb	findLoop
fail:
		stc		; page beyond all allocated blocks and no
				;  room to store the handle for a new one,
				;  so return carry set to signal our
				;  displeasure.
done:
		.leave
		ret
foundBlock:
		add	ax, ds:[si].XMSEMB_pages	; ax <- pages into
							;  emb at which to start
							;  transfer
		
	;
	; Calculate pages left to transfer, rounding count up, of course
	;
		push	ax		; save page offset into EMB for later
		mov	ax, ds:[xmsMoveParams].XMSMP_count.low
		clr	dx
		mov	cx, es:[SM_page]
		dec	cx
		add	ax, cx		; + page_size-1...
		adc	dx, 0
		inc	cx
		div	cx		; ax <- # pages left to transfer
		pop	dx		; dx <- page w/in this EMB

		add	ax, dx		; ax <- ending page + 1
		sub	ax, ds:[si].XMSEMB_pages	; all in this block?
		jbe	transferFits			; yes
	;
	; Transfer spans a block boundary, so adjust the byte count for our
	; caller and figure the parameters for the transfer after this one.
	; dx = page w/in EMB, di = global starting page
	; end up w/di = global starting page for next transfer, cx =
	; bytes left after this transfer.
	; 
		mov	ax, ds:[si].XMSEMB_pages
		sub	ax, dx		; ax <- # pages to transfer this time
		add	di, ax		; di <- starting global page for next
					;  time
		push	dx
		mul	cx		; ax <- # bytes to transfer
		pop	dx

		mov	cx, ax		; save that in CX
		xchg	ds:[xmsMoveParams].XMSMP_count.low, ax
		sub	ax, cx		; ax <- # bytes to transfer next time
		mov_trash	cx, ax
figureStart:		
	;
	; Finally, figure the handle and transfer offset w/in the EMB we've
	; selected.
	; 
	; di = starting global page for next time
	; cx = bytes for next transfer
	; dx = starting page w/in this EMB
	; ds:si = XMSExtendedMemoryBlock
	; ds:bx = XMSAddr to fill in
	; es = SwapMap
	; xmsMoveParams.XMSMP_count set
	; 
		mov	ax, es:[SM_page]
		mul	dx
		mov	ds:[bx].XMSA_offset.low, ax
		mov	ds:[bx].XMSA_offset.high, dx
		mov	ax, ds:[si].XMSEMB_handle
		mov	ds:[bx].XMSA_handle, ax

		mov_trash	ax, di	; ax <- page for next time
		clc
		jmp	done		
transferFits:
	;
	; Transfer fits wholy within the block we found, so set CX to 0 so
	; our caller knows there's nothing more it needs to do. No other
	; registers need adjusting, since we won't be back again.
	; 
		clr	cx
		jmp	figureStart

	;--------------------
allocNew:
	;
	; Allocate a new extended memory block, if possible. First figure the
	; number of pages we think we should allocate (1/MAX_EMBSth of the
	; total that were available when we started), making sure that adding
	; that many pages won't overshoot our swap map
	; 
		push	ax, bx
		sub	ax, di
		neg	ax		; ax <- pages in previous blocks
		mov	dx, ds:[xmsAllocPages]
		add	ax, dx
		sub	ax, es:[SM_total]
		jbe	allocIt
		sub	dx, ax
allocIt:
IF XMS_PAGE_SIZE ne 1024
	;
	; Convert pages to Kb
	; 
		mov	ax, XMS_PAGE_SIZE
		mul	dx
		add	ax, 1023
		adc	dx, 0
		mov	cx, 1024
		div	cx
		mov	dx, ax
ENDIF
	;
	; See if there's that much around. We'll settle for less if that's
	; all we'll get.
	; 
		mov	cx, dx		; preserve #K we'd like
		mov	ah, XMS_QUERY_FREE_EMB
		call	ds:[xmsAddr]	; ax <- largest free block
		cmp	ax, cx		; more than we need?
		jae	doAlloc		; yup.
		mov_trash	cx, ax	; reduce our expectations
doAlloc:
	;
	; Allocate however much we've decided on.
	; 
		mov	dx, cx
		mov	ah, XMS_ALLOC_EMB
		call	ds:[xmsAddr]
		tst	ax		; alloc successful?
		pop	ax, bx
		jz	fail		; nope -- transfer fails
	;
	; Store away the handle and the number of pages we actually allocated.
	; 
		mov	ds:[si].XMSEMB_handle, dx
if XMS_PAGE_SIZE ne 1024
	;
	; Compute pages from Kb...
	; 
		push	ax
		mov_trash	ax, cx
		mov	cx, 1024
		mul	cx
		mov	cx, XMS_PAGE_SIZE
		div	cx
		mov	ds:[si].XMSEMB_pages, ax
		pop	ax
else
	;
	; Pages & Kb are one and the same, so just store the size we alloced
	; 
		mov	ds:[si].XMSEMB_pages, cx
endif
	;
	; Go see if that was enough.
	; 
		jmp	findLoop
XmsFindPageAndLimit endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a move to or from extended memory or the HMA

CALLED BY:	XmsReadPage, XmsWritePage
PASS:		ax	= page number
		cx	= number of bytes to read
		bx	= XMSAddr in which to store EMB address from page
			  number
		di	= XMSAddr for conventional address
		es	= segment of SwapMap
RETURN:		carry set on error:
			cx	= bytes actually transferred
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsTransfer	proc	near	uses dx, ds, si
		.enter
		call	SwapLockDOS	; XMS is supposed to be re-entrant,
					;  but we try to be careful w.r.t.
					;  Other People's Software
		segmov	ds, cs
	;
	; Store the count first so we can handle fall-through gracefully
	;
		mov	ds:[xmsMoveParams].XMSMP_count.low, cx
	;
	; See if we're accessing the HMA or the EMB.
	;
		test	ds:[xmsFlags], mask XF_HAVE_HMA
		jz	doEMB
		sub	ax, NUM_HMA_PAGES
		jae	doEMB

		push	ds, es, di, bx		; Save additional registers
	;
	; Accessing the HMA, but might overlap into the EMB. Do as much
	; as we can in real mode, then fall through, if necessary.
	;
		add	ax, NUM_HMA_PAGES	; Bring it back up...
		mul	es:[SM_page]		; Figure offset in HMA
		mov	si, ax			;  adjusting for starting
		add	si, HMA_BASE		;  offset of the HMA itself
		mov	ds:[bx].XMSA_offset.offset, si	; Store in proper place
		mov	ds:[bx].XMSA_offset.segment, HMA_SEGMENT

	;
	; Save conventional offset in BX for "overflow" handler.
	; 
		mov	bx, di
	;
	; Set up ds:si and es:di to point to the source/dest for the move.
	;
		lds	si, cs:xmsMoveParams.XMSMP_source.XMSA_offset
		les	di, cs:xmsMoveParams.XMSMP_dest.XMSA_offset
	;
	; See if the move crosses the boundary from the HMA to the EMB.
	;
		add	ax, cx			; dx:ax = ending offset
		adc	dx, 0
		jnz	overflow		; => carried into high word
		cmp	ax, HMA_SIZE		; bigger than HMA?
		jae	overflow		; ja...
doHMA:
		shr	cx			; move words please
		rep	movsw

		pop	ds, es, di, bx		; Restore additional registers

		tst	dx			; fall through?
		jz	done			; nope...we're done

		clr	ax			; start transfer at EMB page 0
doEMB:
		segmov	ds, cs			; ds:bx = XMSAddr in EMB
embLoop:
	;
	; Read/write the extended memory block.
	; ax = page number in the EMB.
	; ds:bx = XMSAddr in EMB
	; ds:di = XMSAddr in conventional
	; ds:[xmsMoveParams].XMSMP_count = bytes to transfer
	; dx = bytes transferred so far
	;
		call	XmsFindPageAndLimit
		jc	fail

		push	ax, bx
		mov	si, offset xmsMoveParams
		mov	ah, XMS_MOVE_EMB
		call	ds:[xmsAddr]

		shr	ax			; Set carry if AX == 0
		cmc
		pop	ax, bx		; recover extended XMSAddr & next page
		jc	fail
	;
	; Record those bytes as transferred.
	; 
		add	dx, ds:[xmsMoveParams].XMSMP_count.low
		jcxz	done		; => nothing more to move
	;
	; Adjust conventional address by amount transferred, setting
	; count for next transfer.
	; 
		xchg	ds:[xmsMoveParams].XMSMP_count.low, cx
		add	ds:[di].XMSA_offset.offset, cx
		jmp	embLoop
done:
		call	SwapUnlockDOS
		.leave
		ret

fail:
		mov	cx, dx		; return # bytes actually written
		jmp	done

overflow:
	;
	; Handle boundary crossing:
	;	- subtract HMA_SIZE from the ending offset to get the number of
	;	  bytes in the EMB affected by the move, storing this as the
	;	  count for the move (for when we fall into doEMB).
	;	- Reduce the number of bytes affected in the HMA by the same
	;	  amount, adding the final number to the offset in conventional
	;	  for the fall-through.
	;	- set DX to the number of bytes that'll be transferred. This
	;	  will be non-zero, so we use that above to note that we need
	;	  to fall through to copy things to extended memory.
	; Note: conventional XMSAddr offset was shifted into BX for our
	; use up above.
	;
		sub	ax, HMA_SIZE
		mov	cs:xmsMoveParams.XMSMP_count.low, ax
		sub	cx, ax		; adjust amt to move by amt not moved
		mov	dx, cx		; signal overflow/record amt moved
		add	cs:[bx].XMSA_offset.offset, cx
		jmp	doHMA
XmsTransfer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsReadPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read page(s) in from extended memory via the XMM

CALLED BY:	SwapRead
PASS:		ds:dx	= address to which to read the page(s)
		ax	= starting page number
		cx	= number of bytes to read
		es	= segment of SwapMap
RETURN:		carry set if all bytes could not be read
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsReadPage	proc	far
		uses	di, cx
		.enter
if LOG_ACTIONS
		mov	bx, cs:[logPtr]
		mov	cs:opLog[bx], OP_READ
		mov	cs:segLog[bx], ds
		mov	cs:offLog[bx], dx
		mov	cs:sizeLog[bx], cx
		mov	cs:pageLog[bx], ax
		inc	bx
		inc	bx
		cmp	bx, MAX_LOG * word
		jne	10$
		clr	bx
10$:
		mov	cs:[logPtr], bx
endif

		mov	cs:xmsMoveParams.XMSMP_dest.XMSA_handle, 0
		mov	cs:xmsMoveParams.XMSMP_dest.XMSA_offset.offset, dx 
		mov	cs:xmsMoveParams.XMSMP_dest.XMSA_offset.segment, ds
		mov	bx, offset xmsMoveParams.XMSMP_source
		mov	di, offset xmsMoveParams.XMSMP_dest
		call	XmsTransfer
EC <		ERROR_C	CANNOT_READ_SWAPPED_BLOCK			>
		.leave
		ret
XmsReadPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsWritePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write page(s) to extended memory via the XMM

CALLED BY:	SwapWrite
PASS:		ds:dx	= address from which to write the page(s)
		ax	= starting page number
		cx	= number of bytes to write
		es	= segment of SwapMap
RETURN:		carry set if all bytes could not be written
			cx	= # bytes actually written
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsWritePage	proc	far
		uses	di
		.enter
if LOG_ACTIONS
		mov	bx, cs:[logPtr]
		mov	cs:opLog[bx], OP_WRITE
		mov	cs:segLog[bx], ds
		mov	cs:offLog[bx], dx
		mov	cs:sizeLog[bx], cx
		mov	cs:pageLog[bx], ax
		inc	bx
		inc	bx
		cmp	bx, MAX_LOG * word
		jne	10$
		clr	bx
10$:
		mov	cs:[logPtr], bx
endif
		mov	cs:xmsMoveParams.XMSMP_source.XMSA_handle, 0
		mov	cs:xmsMoveParams.XMSMP_source.XMSA_offset.offset, dx 
		mov	cs:xmsMoveParams.XMSMP_source.XMSA_offset.segment, ds
		mov	bx, offset xmsMoveParams.XMSMP_dest
		mov	di, offset xmsMoveParams.XMSMP_source
		call	XmsTransfer
		.leave
		ret
XmsWritePage	endp

idata ends
