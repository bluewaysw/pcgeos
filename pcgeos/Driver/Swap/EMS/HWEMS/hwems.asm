COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swap Drivers -- EMS
FILE:		vg230ems.asm

AUTHOR:		Adam de Boor, Jun 19, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/19/90		Initial revision
	andres	10/04/96	Added code for PENELOPE

DESCRIPTION:
	VG230 swap driver 
		

	$Id: hwems.asm,v 1.1 97/04/18 11:58:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			     Common Code
;------------------------------------------------------------------------------

NO_REALLOC_DEALLOC_COMPACT	equ	TRUE
;DO_CHECKSUM			equ	0	;Should not be defined

include	emsCommon.asm


; These constants are only here so the non product-specific version
; will compile.

HWSPEC_SWAP_NUM_BANKS		equ	0
HWSPEC_EMS_BASE_BANK		equ	0
HWSPEC_EMS_SWAP_SEG		equ	0


;------------------------------------------------------------------------------
;			   Special Includes
;------------------------------------------------------------------------------
include Internal/emm.def
include	Internal/interrup.def


LOG_ACTIONS		= FALSE

if LOG_ACTIONS
PrintMessage <*+*+*+*+*+*+ LOG_ACTIONS IS ON +*+*+*+*+*+*>
endif

TF		equ	0x100	; Trace flag in a flags-word image
.ioenable			; allow CLI/STI...

;------------------------------------------------------------------------------
;			      Constants
;------------------------------------------------------------------------------

ERR_EMS							enum FatalErrors
ifdef	DO_CHECKSUM
EMS_SWAP_AREA_HAS_BEEN_CORRUPTED			enum FatalErrors
endif

;------------------------------------------------------------------------------
;			      Variables
;------------------------------------------------------------------------------

idata		segment

emsBaseBank		word	HWSPEC_EMS_BASE_BANK
					; the base swap bank

emsSwapSeg		sptr	HWSPEC_EMS_SWAP_SEG
					;segment of bank to which data is
					; actually swapped
idata		ends

udata	segment

emsMoveParams	EMMMoveParams		;parameters for EMF_MOVE_REGION
					; if needed.
emsBytesMoved	word	0		;bytes moved so far this transfer

udata	ends

;------------------------------------------------------------------------------
;			Action Logging Stuff
;------------------------------------------------------------------------------
udata		segment

if	LOG_ACTIONS

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

Init	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	EmsDeviceInit

SYNOPSIS:	Initialize the swap device

CALLED BY:	EmsInit

PASS:		ds	= dgroup

RETURN:		carry - set on error
		ax	= # pages available for swapping
		cx	= 0 (# paragraphs in the frame to add to heap)

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision
	Chrisb	11/94		Modified for VG230 EMS

------------------------------------------------------------------------------@


EmsDeviceInit	proc	near
		.enter
		clr	cx

		mov	ax, HWSPEC_SWAP_NUM_BANKS * 16


ifdef	DO_CHECKSUM
if	ERROR_CHECK
		call	CreateEMSAreaChecksum
endif
endif
		.leave
		ret
EmsDeviceInit	endp


Init		ends

idata		segment

COMMENT @----------------------------------------------------------------------

FUNCTION:	EmsExit

DESCRIPTION:	Do nothing.

CALLED BY:	DR_EXIT

PASS:		ds	= dgroup

RETURN:		nothing 

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision

------------------------------------------------------------------------------@

EmsExit		proc	near
		.enter
		clc				;No errors
		.leave
		ret
EmsExit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsWritePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a page or pages out to expanded memory

CALLED BY:	SwapWrite
PASS:		ds:dx	= address from which to write the page(s)
		ax	= starting page number
		cx	= number of bytes to write
		es	= segment of SwapMap
RETURN:		carry set if all bytes could not be written
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsWritePage	proc	far	uses bp
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
		mov	bx, offset emsMoveParams.EMMMP_source
		mov	bp, offset emsMoveParams.EMMMP_dest
		call	EmsTransfer
		.leave
		ret
EmsWritePage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsReadPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a page or pages out of expanded memory

CALLED BY:	SwapRead
PASS:		ds:dx	= address to which to write the page(s)
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
	ardeb	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsReadPage	proc	far
		uses	bp, cx
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
		mov	bp, offset emsMoveParams.EMMMP_source
		mov	bx, offset emsMoveParams.EMMMP_dest
		call	EmsTransfer
		.leave
		ret
EmsReadPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer data to/from EMS memory

CALLED BY:	EmsReadPage, EmsWritePage
PASS:		ax	= starting page number
		cx	= number of bytes to transfer
		ds:dx	= source/dest for transfer (depends on bx & bp)
		es	= segment of SwapMap
		bx	= EMSAddr for conventional memory
		bp	= EMSAddr for expanded memory
RETURN:		carry set if transfer couldn't be completed:
			cx	= bytes actually transferred
DESTROYED:	ax, bx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsTransfer	proc	near	uses si, di, es, ds, dx
		.enter

		call	SwapLockDOS
	;
	; Set up the move parameters regardless of whether the EMM can
	; handle an EMF_MOVE_REGION. It's easier to keep track of things
	; this way...
	;
		mov	cs:emsMoveParams.EMMMP_length.low, cx
		mov	cs:emsBytesMoved, 0
	;
	; Set up the conventional part of the move parameters from the passed
	; ds:dx.
	;
		mov	cs:[bx].EMMA_addr.segment, ds
		segmov	ds, cs
		mov	ds:[bx].EMMA_type, 0	; => conventional
		mov	ds:[bx].EMMA_addr.offset, dx

	;
	; Now for the expanded portion.
	;
		xchg	bx, bp
		mov	ds:[bx].EMMA_type, 1	; => expanded

		call	EmsCvtPageToEms
		mov	ds:[bx].EMMA_addr.segment, ax
		mov	ds:[bx].EMMA_addr.offset, cx

	;
	; The EMM doesn't support EMF_MOVE_REGION, so we have to bank things
	; in ourselves, dealing with bank boundaries and all that grossness.
	;
		mov	ds:[bx].EMMA_handle, ax	; Save handle
		mov	ax, ds:[emsSwapSeg]
		mov	ds:[bx].EMMA_addr.segment, ax
		mov	cx, ds:[emsMoveParams].EMMMP_length.low
xferLoop:
	;
	; First make sure the proper bank is mapped into the swap bank.
	;
	
		call	EmsMapBank
	;
	; Make sure the transfer isn't going to overflow the bank. CX is the
	; number of bytes to be transferred.
	;
		mov	ax, EMS_BANK_SIZE
		sub	ax, ds:[bx].EMMA_addr.offset	; ax <- amount left
							;  in bank.
		cmp	ax, cx		; more than enough?
		jae	doXfer		; yup -- just use CX
		;
		; We'll overrun it, meaning we have to loop again. Use the
		; size remaining in the bank as the size of the transfer.
		;
		mov	cx, ax
doXfer:
	;
	; Adjust the length remaining by the amount being moved this time,
	; point es:di and ds:si at their respective places (both parts
	; of the EMMMoveParams having been filled with physical addresses)
	; and do the move.
	;
		sub	ds:[emsMoveParams].EMMMP_length.low, cx
		add	ds:[emsBytesMoved], cx
		mov	ax, cx
		push	ds
		les	di, ds:[emsMoveParams].EMMMP_dest.EMMA_addr
		lds	si, ds:[emsMoveParams].EMMMP_source.EMMA_addr
		shr	cx
		rep	movsw
		pop	ds
	;
	; Recover the length remaining and get out of here with carry clear
	; if we're done.
	;
		mov	cx, ds:[emsMoveParams].EMMMP_length.low
		clc
		jcxz	done
	;
	; Adjust loop variables to account for amount moved and loop again.
	;
		add	ds:[bp].EMMA_addr.offset, ax
		inc	ds:[bx].EMMA_handle		; Go to next bank
		mov	ds:[bx].EMMA_addr.offset, 0	; from offset 0...
		jmp	xferLoop

ifndef MOVE_REGION_NOT_HOSED
done:
		mov	cx, ds:[emsBytesMoved]	; return total bytes moved
		call	SwapUnlockDOS
		.leave
		ret
endif
EmsTransfer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsMapBank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a bank into the swap area

CALLED BY:	EmsTransfer
PASS:		ds:bx	= EMMAddr to map in
RETURN:		flags set so jnz will jump on an error
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/29/91		Initial version
	chrisb	11/94		modified for VG230
	andres 	10/04/96	Added code for PENELOPE (E3G)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsMapBank	proc	near	uses	dx
		.enter
	; Preserve the address register around this mapping

		mov	ax, ds:[bx].EMMA_handle

	PrintMessage <Add code to EmsMapBank>
		ERROR	-1
		.unreached
		.leave
		ret
EmsMapBank	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsCvtPageToEms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a swap page to a bank:offset pair

CALLED BY:	EmsTransfer
PASS:		ax	= swap page #
		ds	= dgroup
RETURN:		ax	= EMS bank within emsSwapHandle's range
		cx	= offset into EMS bank
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This needs a little explaining. Since there are 16 pages in a bank,
	we convert from the passed page to a swap bank by shifting the page
	right four bits. We need to add the base bank to this value, of
	course, as the low n banks are dedicated to the heap.

	To get the offset into the bank at which to begin the transfer,
	we need to multiply the low four bits of the page by 1024.
	This can be accomplished easily by moving the low four bits into
	the high byte of CX and shifting the thing left two bits (1024
	being 2**10, we need a left shift of 10 bits...) after masking out
	the unneeded bits.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/19/90		Initial version
	andres 10/04/96		Header had return values for ax and cx
				switched.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsCvtPageToEms	proc	near
		.enter
				CheckHack <EMS_PAGE_SIZE eq 1024>
		mov	ch, al
		mov	cl, 4			; figure logical page
		shr	ax, cl			;  based on swap page

		add	ax, ds:[emsBaseBank]
		andnf	cx, 0x0f00		; figure starting offset
		shl	cx			;  w/in logical page
		shl	cx

		.leave
		ret
EmsCvtPageToEms	endp


;==============================================================================
;
;			TASK SWITCHER SUPPORT
;
;==============================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsDeviceSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend this driver.  This procedure should copy all
		memory out of (potentially) volatile EMS memory into a
		non-volatile memory space.

CALLED BY:	DR_SUSPEND

PASS:		cx:dx	= buffer for reason for failure to suspend

RETURN:		carry set if refuse to suspend

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsDeviceSuspend proc	near
		.enter
		clc
		.leave
		ret
EmsDeviceSuspend endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsDeviceUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing.  On a task-switching system, this
		procedure should copy the memory that was protected in
		EmsDeviceSuspend back into EMS memory.

CALLED BY:	DR_UNSUSPEND
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsDeviceUnsuspend proc	near
		.enter
		clc
		.leave
		ret
EmsDeviceUnsuspend endp


;==============================================================================
;
;			Checksum of EMS Area
;
;==============================================================================

ifdef	DO_CHECKSUM
if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateEMSAreaChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a checksum for each bank in the EMS swap area

CALLED BY:	EmsStrategy, EmsDeviceInit

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateEMSAreaChecksum	proc	far
		pushf
		uses	ax, bx, cx, bp, ds
		.enter
	;
	; Loop through each page, verifying the checksum
	;
		segmov	ds, dgroup, ax
		mov	bx, HWSPEC_EMS_BASE_BANK
		mov	cx, HWSPEC_SWAP_NUM_BANKS
		clr	bp
pageLoop:
		call	CalcBankChecksum
		mov	ds:[checksumTable][bp], ax
		inc	bx			; next bank
		add	bp, 2			; next table offset
		loop	pageLoop
	
		.leave
		popf
		ret
CreateEMSAreaChecksum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyEMSAreaChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the checksum for each bank in the EMS swap area

CALLED BY:	EmsStrategy

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VerifyEMSAreaChecksum	proc	far
		pushf
		uses	ax, bx, cx, bp, ds
		.enter
	;
	; Loop through each page, verifying the checksum
	;
		segmov	ds, dgroup, ax
		mov	bx, HWSPEC_EMS_BASE_BANK
		mov	cx, HWSPEC_SWAP_NUM_BANKS
		clr	bp
pageLoop:
		call	CalcBankChecksum
		cmp	ds:[checksumTable][bp], ax
		ERROR_NE EMS_SWAP_AREA_HAS_BEEN_CORRUPTED
		inc	bx			; next bank
		add	bp, 2			; next table offset
		loop	pageLoop
	
		.leave
		popf
		ret
VerifyEMSAreaChecksum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcBankChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a checksum for a bank (16K) of EMS swap memory

CALLED BY:	CreateEMSAreaChecksum, VerifyEMSAreaChecksum

PASS:		DS	= DGroup
		BX	= Page #

RETURN:		AX	= Checksum value

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcBankChecksum	proc	near
		uses	bx, cx, si, ds
		.enter
		call	SwapLockDOS

	;
	; Map the bank in, and sum the words in the 16K page
	;
		mov	cs:[checksumAddr].EMMA_handle, bx
		mov	bx, offset checksumAddr
		call	EmsMapBank
		segmov	ds, HWSPEC_EMS_SWAP_SEG, ax
		mov	cx, PHYSICAL_PAGE_SIZE / 2	; # of words
		clr	bx, si
checksumLoop:
		lodsw
		add	bx, ax
		loop	checksumLoop
		mov_tr	ax, bx			; checksum => AX

		call	SwapUnlockDOS
		.leave
		ret
CalcBankChecksum	endp

checksumAddr	EMMAddr <0, 0, 0>
checksumTable	word 	HWSPEC_SWAP_NUM_BANKS dup (0)

endif
endif

idata		ends
