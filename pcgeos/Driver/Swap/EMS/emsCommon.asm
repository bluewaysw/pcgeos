COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swap Drivers -- EMS (LIM) version
FILE:		ems.asm

AUTHOR:		Adam de Boor, Apr 28, 1990

ROUTINES:
	Name			Description
	----			-----------
    EXT EmsStrategy		Ems driver strategy routine

    INT EmsInit			Initialize the driver

    INT EmsSwapOut		Swaps a chunk out to expanded memory.

    INT EmsSwapIn		Transfers a block to the heap and frees the
				space occupied by the block.

    INT EmsDiscard		Release a block from the used list and
				update the free list.

    INT EmsGetMap		Return the segment of the swap map used by
				the driver

    INT EmsCompact		Compact swap space.
    INT EmsDealloc		Free up unused space.
    INT EmsRealloc		Reallocate and reinitialize space freed by
				EmsDealloc

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial revision
	CHL	2/94		GeosTS support (Added EmsCompact and 
				EmsDealloc)

DESCRIPTION:
	Swap driver to swap memory to and from Expanded Memory.
		
	This file contains code common to all the expanded memory managers.

Glossary (some terms differ from regular pc-geos usage):
	Chunk:
		The block of memory in the heap with which we are dealing.
	Frame:
		The expanded memory page frame.
	Bank:
		The bankable unit of EMS memory: 16 Kb (referred to as a
		"page" in the EMS spec, but not so here)

	Pointer:
		A page address.

	Swap area:
		The last bank in the page frame in which we do the
		swapping.
	Page:
		The smallest amount of space allocatable in the swap area.
		Currently set at 1024 bytes.
	Page address:
		The offset of the page from the start of expanded memory
		(starting at 0).
	Window:
		The 16 Kbyte swap area serves as a window into expanded memory.

Use of the Page Frame:
		48 Kbytes of the page frame is made use of by the regular heap.
		The remaining 16 Kbytes is the window into expanded memory.

Some implementation details:
	The page address is one word in size, thereby allowing a maximum
	of 65536 units. Since a v4.0 manager can handle 32 Meg of memory,
	a minimum unit size of 512 bytes is imposed.

Unit address:
	bits 15:4	- bank in which a page is located
	bits 3:0	- offset (number of pages) to page within a bank

To do:
	* if version 4.0 (and using a manager), use MoveRegion call (function
	  24...) and give fourth bank to the heap.

	$Id: emsCommon.asm,v 1.1 97/04/18 11:58:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_SwapDriver		=	1

;------------------------------------------------------------------------------
;	Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include resource.def
include ec.def
include driver.def
include geode.def
include sem.def
include system.def
include localize.def

DefDriver Internal/swapDr.def
UseLib	Internal/swap.def

include emsConstant.def



;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

;Driver information table
DriverTable	DriverInfoStruct <EmsStrategy,0,DRIVER_TYPE_SWAP>
ForceRef	DriverTable
idata	ends


udata	segment
ifndef	NO_REALLOC_DEALLOC_COMPACT
emsRestoreBanks		word	0	;number of 16K EMS banks we have to
					; reclaim before resuming normal
					; execution of GEOS. (Bank allocation
					; may have been reduced by 
					; DR_SWAP_DEALLOC
endif

emsSwapMap		sptr.SwapMap	;pointer to swap map for the device


udata	ends



idata	segment

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsStrategy

SYNOPSIS:	Ems driver strategy routine

CALLED BY:	EXTERNAL

PASS:		cs = ds
		di		- DR command code.
		other regs	- parameters
		no parameter should be passed in ax

	-----------------------------------------------------------
	PASS:	di	- DR_INIT

	RETURN: carry clear if ems present

	-----------------------------------------------------------
	PASS:	di	- DR_EXIT

	RETURN: carry clear if no error

	-----------------------------------------------------------
	PASS:	di	- DR_SWAP_SWAP_OUT
		dx	- segment of block to swap
		cx	- size of block to swap (bytes)

	RETURN:	carry clear if no error
		ax	- id of swapped data

	-----------------------------------------------------------
	PASS:	di	- DR_SWAP_SWAP_IN
		bx	- id of swapped data
		dx	- segment of destination block
		cx	- size of data block (bytes)

	RETURN:	carry clear if no error

	-----------------------------------------------------------
	PASS:	di	- DR_SWAP_DISCARD
		bx	- id of swapped data

	RETURN:	carry clear if no error

	-----------------------------------------------------------

DESTROYED:	Depends on function, though best to assume all registers
		that are not returning a value.
		(Segment registers are preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
emsFunctions	nptr	EmsExit, EmsDeviceSuspend, EmsDeviceUnsuspend,
			EmsSwapOut, EmsSwapIn, EmsDiscard, EmsGetMap,
			EmsCompact, EmsDealloc, EmsRealloc

EmsStrategy	proc	far	uses ds
		.enter
		segmov	ds, cs			;set ds equal to cs

	;
	; Special-case DR_INIT as it's in a movable module.
	;
		cmp	di, DR_INIT
		jne	notInit
		call	EmsInit
done:
		.leave
		ret
notInit:
ifdef	DO_CHECKSUM
EC <		call	VerifyEMSAreaChecksum				>
endif
		call	cs:emsFunctions-2[di]
ifdef	DO_CHECKSUM
EC <		call	CreateEMSAreaChecksum				>
endif
		jmp	done
EmsStrategy	endp

idata		ends

Init		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routines for unsupported DR_SWAP calls.

CALLED BY:	DR_SWAP_COMPACT
PASS:		who cares
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsDoNothing	proc	near
		.enter
		clc
		.leave
		ret
EmsDoNothing	endp
ForceRef EmsDoNothing

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsInit

SYNOPSIS:	Initialize the driver

CALLED BY:	DriverStrategy

PASS:		ds	= dgroup

RETURN:		carry - set on error

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision

-------------------------------------------------------------------------------@

EmsInit		proc	far	uses di, si, cx, dx, bp
	.enter

	;
	; Initialize the board(s) and fetch the number of pages available.
	; Returns ax = # pages available for swapping
	;	  bx = segment of the page frame to add to the heap
	;	  cx = # paragraphs of the page frame to add to the heap
	;
	call	EmsDeviceInit		;call device-specific routine
	jc	done
	
	push	bx, cx
	;
	; Create a swap map for our use.
	;
	mov	cx, EMS_PAGE_SIZE
	mov	bx, handle 0
	mov	si, segment EmsWritePage
	mov	di, offset EmsWritePage
	mov	dx, segment EmsReadPage
	mov	bp, offset EmsReadPage
	call	SwapInit
	jc	done

	mov	ds:[emsSwapMap], ax

	;
	; Tell the kernel we're here and really fast. For NIKE, we tell
	; the Kernel that we're "kinda slow" to work around some problems
	; in the heap code. This code should be removed before NIKE ships!
	;
	mov	cx, segment EmsStrategy
	mov	dx, offset EmsStrategy
	mov	ax, SS_REALLY_FAST
	call	MemAddSwapDriver
	pop	ax, cx			; recover page frame and its length
	jc	done

	;
	; Add the frame returned by EmsInitDevice to the kernel's heap.
	;
	tst	cx			; BULLET: all EMS is used for swap
	jz	noExtraHeap		;   space, so don't extend heap. 
	call	MemExtendHeap

noExtraHeap:
	;
	; Make the init code be discard-only now, since we need it no
	; longer.
	;
	mov	bx, handle Init
	mov	ax, mask HF_DISCARDABLE or (mask HF_SWAPABLE shl 8)
	call	MemModifyFlags
	clc
done:
	.leave
	ret
EmsInit	endp

Init	ends

idata	segment


COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsSwapOut

DESCRIPTION:	Swaps a chunk out to expanded memory.

CALLED BY:	INTERNAL

PASS:		dx - data address of chunk
		cx - number of bytes in chunk

RETURN:		ax - id of storage
		carry - set if error, clear otherwise

DESTROYED:	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@
EmsSwapOut	proc	near
	mov	ax, ds:[emsSwapMap]
	call	SwapWrite
	ret
EmsSwapOut	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsSwapIn

DESCRIPTION:	Transfers a block to the heap and frees the space occupied
		by the block.

CALLED BY:	INTERNAL

PASS:		bx - id to retrieve data
		cx - size of chunk in bytes
		dx - data address of chunk
		ds - dgroup

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

EmsSwapIn	proc	near
	mov	ax, ds:[emsSwapMap]
	call	SwapRead
	ret
EmsSwapIn	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsDiscard

DESCRIPTION:	Release a block from the used list and update the free list.

CALLED BY:	INTERNAL

PASS:		bx - swap id
		ds - dgroup

RETURN:		nothing

DESTROYED:	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

EmsDiscard	proc	near
	mov	ax, ds:[emsSwapMap]
	call	SwapFree
	ret
EmsDiscard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsGetMap
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
EmsGetMap	proc	near
		.enter
		mov	ax, ds:[emsSwapMap]
		.leave
		ret
EmsGetMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsCompact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate EMS swap pages so that the requested amount of
		contiguous free space is available.

CALLED BY:	DR_SWAP_COMPACT
PASS:		bx	= requested Kbytes of contiguous free space.
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
	Changes HSM_swapID in the handle of the blocks that are compacted.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef VG230
	; Don't support this call
EmsCompact	proc	near
		stc
		ret
EmsCompact	endp

else

EmsCompact	proc	near
		uses	bx,cx,dx,es,di
		.enter

		mov	cx, dx			;swap driver ID
	;
	; How much total swap space do we have?
	;
		mov	es, ds:[emsSwapMap]
		mov	ax, es:[SM_total]

IF EMS_PAGE_SIZE LT 1024
		; smaller than a K, must multiply by ratio
		mov	di, 1024/XMS_PAGE_SIZE
		mul	di
ELSEIF EMS_PAGE_SIZE GT 1024
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
		mov	ax, ds:[emsSwapMap]
		call	SwapCompact

		mov	ax, dx			;ax = maximum Kbytes
		.leave
		ret
EmsCompact	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsDealloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free unused EMS swap memory.

CALLED BY:	DR_SWAP_DEALLOC
PASS:		bx	= Kbytes used by this swap driver.
		ds	= dgroup
RETURN:		if success:
			carry clear
		else:
			carry set
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef NO_REALLOC_DEALLOC_COMPACT
EmsDealloc	proc	near
		stc
		ret
EmsDealloc	endp

else

EmsDealloc	proc	near
		uses	ax,bx,cx,dx
		.enter

		push	bx
                mov     dx, ds:[emsSwapHandle]
		mov	ax, EMF_QUERY_PAGES
                call    EmsCallEMM
		jnz	errorPopBX
		mov	ds:[emsRestoreBanks], bx
		pop	bx

        ;
        ; All the pages used by the EMS swap driver have been compacted
        ; into the lower ax kbytes of the allocated space.
        ; Now realloc this space to be the desired size.
        ;
                mov     ax, bx                          ; # of Kb
                clr     dx

                mov     cx, EMS_BANK_SIZE / 1024        ; should be 16
                div     cx                              ; ax = quotient
                                                        ; dx = remainder
                tst     dx
                jz      gotBanks
        ;
        ; Amount of free space needed isn't on page boundary -- round # of pages
        ; up...
        ;
                inc     ax
gotBanks:
                mov     bx, ax                          ; # of (16K) banks
	;
	; There are 3 or 4 banks used to extend the heap. These are located
	; below the swap memory banks, so we must account for them in our 
	; count of banks to keep.
	;
		add	bx, ds:[emsBaseBank]	

doRealloc::
                mov     dx, ds:[emsSwapHandle]
        ;
        ; Note!  The following call is only supported for > 4.0 EMS managers.
        ; We should probably check the version here (or above) and do something
        ; reasonable....
        ;
                mov     ax, EMF_REALLOC
                call    EmsCallEMM
		jz	done
error:
                stc
EC <            ERROR_C	ERR_EMS 	                               >
done:
		.leave
		ret
errorPopBX:
		pop	bx
		jmp	error
EmsDealloc	endp

endif	; NO_REALLOC_DEALLOC_COMPACT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsRealloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate space freed by EmsDealloc, and re-initialize
		bank mapping.

CALLED BY:	DR_SWAP_REALLOC
PASS:		ds	= dgroup
RETURN:		carry set if error, ax = error code.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef NO_REALLOC_DEALLOC_COMPACT
EmsRealloc	proc	near
		stc
		ret
EmsRealloc	endp

else

EmsRealloc	proc	near
		uses	bx,dx
		.enter
		clr	bx
		xchg	bx, ds:[emsRestoreBanks]
		tst	bx
		jz	remapBanks

                mov     dx, ds:[emsSwapHandle]
		mov	ax, EMF_REALLOC
		call	EmsCallEMM
		jnz	error

remapBanks:
	;
	; remap banks used to extend the heap.
	;
		mov	bx, ds:[emsBaseBank]
bankLoop:
		dec	bx
		js	done
		mov	al, bl
		mov	ah, high EMF_MAP_BANK
		call	EmsCallEMM
		jz	bankLoop
		jmp	error

done:
		clc
exit:
		.leave
		ret
error:
		stc
		jmp	exit
EmsRealloc	endp

endif ; NO_REALLOC_DEALLOC_COMPACT

idata	ends


