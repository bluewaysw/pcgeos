COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swap Drivers -- Extended Memory Version
FILE:		extmem.asm

AUTHOR:		Adam de Boor, Apr 15, 1989

ROUTINES:
	EmStrategy		Driver strategy routine

    EXT EmStrategy		ExtMem driver strategy routine

    INT EmInit			Actual initialization routine for driver.
				In separate resource so it can go away if
				need be.

    INT GetEmSize		Calls DOS interrupt 15h function 88h to get
				the size of extended memory, then checks
				for VDISK slimeballs in the system.

    INT EmExit			Handle cleanup of driver.

    INT EmDoNothing		Do-nothing routine for suspend/unsuspend

    INT EmSwapOut		Swaps a chunk out into extended memory.

    INT EmSwapIn		Transfers a block to the heap and frees the
				space occupied by the block in extended
				memory.

    INT EmDiscard		Release a block from the used list and
				update the free list.

    INT EmGetMap		Return the segment of the swap map used by
				the driver

    INT EmReadPage		Read page(s) in from extended memory.

    INT EmWritePage		Write page(s) out to extended memory.

    INT EmTransfer		Transfer data to/from extended memory

    INT EmFarToLinear		Convert a real address into an extended
				memory linear address

    INT StressMe

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial revision
	Adam	4/15/89		Code snarfed from em to allow access
				to the Atron board as well.
	Adam	6/7/89		Generalized to support Atron memory as an
				option and to use either BIOS or
				unofficial '286 LOADALL instruction for
				data movement.
	Adam	4/28/90		Nuked LOADALL support, as BIOS is faster.


DESCRIPTION:
	A driver to make use of memory above the 1Mb limit.
		
	PC/GEOS EXTENDED MEMORY MANAGER CORE

	A manager for extended memory that relies on BIOS int 15h
	
	A user should make use of an EMS driver if his hardware is capable
	of supporting it as the time taken to switch to protected mode to
	access extended memory is long (supposed to be only marginally faster
	than an access to fixed disk storage).
	
Glossary (some terms differ from regular pc-geos usage):

	Block:
		The block of memory in the heap with which we are dealing.

	Linear address (LinAddr):
		The 24 bit extended memory address of the unit.

	Pointer:
		A unit index.

	Page:
		The smallest amount of space allocatable.
		Currently set at 1024 bytes. See EM_PAGE_SIZE

Some implementation details:
	There can be 15 Megs of extended memory (15360 K).
	This memory is divided up into pages and memory is swapped out
	by breaking up the block into page-sized chunks.

	The swap map is a structure maintained by the swap library that
	tracks the allocation of pages in the swap space. Since a page
	index is a word, the smallest a page can be is 256 bytes.  The
	swap map can be large if page size is small (eg 256 byte units
	in a 15 Meg system => 15360 * 8 = 122880 bytes).

	A page size of 1 K is currently used. The swap map will then
	be at most 30720 bytes.

Conversion from a page index into a linear address:
	For a 1 Kbyte page,
		linear address := (page index * 1024) + 1Meg

TO DO:
   	Look for VDISK header at 1Mb boundary to avoid tromping a RAM
	disk that uses the VDISK protocol. We use all the rest of the memory,
	but want to preserve the disk contents.
	
	Make sure the Atron board is active and enabled by copying
	something out to it and back, making sure the data got there ok.

	Check error returns from BIOS call.

	$Id: extmem.asm,v 1.1 97/04/18 11:58:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		.286p		;For LOADALL code
		.ioenable	;We need to dick with interrupts

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
include initfile.def

DefDriver Internal/swapDr.def
include Internal/interrup.def		;For INT_ON/INT_OFF
include Internal/driveInt.def		;For VDISK search
include Internal/fileInt.def		;Ditto
UseLib Internal/swap.def


BS_firstFree	equ <BS_totalSectorsInVolume>	; location of word
						; containing Kb address
						; of first free byte
						; in extmem

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;
; Constants we use
;
ERR_EM_NESTED_INIT 		enum FatalErrors
ERR_EM_BAD_PU_COUNT		enum FatalErrors
ERR_EM_GU_ERROR 		enum FatalErrors
ERR_EM_CUR_NOT_NULL		enum FatalErrors
ERR_EM_SO_BAD_OFFSET		enum FatalErrors
ERR_EM_BAD_UNIT_INDEX 		enum FatalErrors
ERR_EM_BIOS_ERROR 		enum FatalErrors
ERR_EM_ADDR_OUT_OF_RANGE 	enum FatalErrors
ERR_EM_INVALID_PROCESSOR 	enum FatalErrors

;
; Driver flags:
;	EF_INITIALIZED	Non-zero if DR_INIT called
;	EF_USE_ATRON	Non-zero if should use Atron Probe memory at d00000
;
EmFlags	record	EF_INITIALIZED:1, EF_USE_ATRON:1

CAN_USE_ATRON	= FALSE		; Set TRUE if can use an existing ATRON
				;  debug board (need means to enable same).

EM_PAGE_SIZE	equ	1024

EM_BASE		= 10h		; base of extended memory (added to
					;  highest byte of address)

;
; Constants for the Atron board
;
; Many of the functions of the board are controlled by a register at
; fffff -- the highest byte in real mode. Several bits have dual
; functions. Their meanings are as follows (maybe):
; 	B7		Enable timer 0/1 counting
; 	B6		Write-protect RAM/Enable hardware breakpoints
; 	B5		Bank out top ?K of RAM for access to I/O locations
; 	B4		Write-enable RAM/disable hardware breakpoints
; 	B3		?
; 	B2		?
; 	B1		?
; 	B0		Enable board...?
;
; Write-enabling is a two-stage process. First ATRON_WR_ENABLE is stored,
; then ATRON_ENABLE...
;
ATRON_SIZE		= 1024		; # units of atron memory available
ATRON_WR_ENABLE		= 11h
ATRON_ENABLE		= 01h



;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

;
; Driver information table
;
DriverTable	DriverInfoStruct <EmStrategy,<>,DRIVER_TYPE_SWAP>

;
; State flags
;
emFlags		EmFlags	<0,0,0>

;
; Jump table for supported driver functions
;
emFunctions	nptr	EmExit, EmDoNothing, EmDoNothing,
			EmSwapOut, EmSwapIn, EmDiscard,
			EmGetMap, EmDoNothing, EmDoNothing, EmDoNothing

if CAN_USE_ATRON
emAtronBase	byte	0d0h	; Base of Atron memory (added to high byte
				;  of linear address as for EM_BASE)
		even
endif

emSwapBase	dword	0x100000;Start of swap space in extended memory
				; (after any VDISK-like things)

idata	ends

;------------------------------------------------------------------------------
;	Uninitialized Variables
;------------------------------------------------------------------------------

udata	segment

emSwapMap	sptr.SwapMap

;***** status vars *****

if CAN_USE_ATRON
emFirstAtron	word		; First unit number for Atron board
					; memory
endif

wordsMoved	word		; # bytes moved this transfer

udata	ends

;-----------------------------------------------------------------------------
;		     BIOS BlockMove Declarations
;-----------------------------------------------------------------------------
udata	segment
;
; Access rights for a segment:
;	AR_PRESENT	non-zero if segment actually in memory
;	AR_PRIV		privilege level (0-3) required for access
;	AR_ISMEM	1 if a memory segment, 0 if special
;	AR_TYPE		type of segment
;	AR_ACCESSED	non-zero if memory accessed
;
SegTypes 				etype byte, 0
SEG_DATA_RD_ONLY			enum SegTypes
SEG_DATA				enum SegTypes
SEG_DATA_EXPAND_DOWN_RD_ONLY		enum SegTypes
SEG_DATA_EXPAND_DOWN			enum SegTypes
SEG_CODE_NON_READABLE			enum SegTypes
SEG_CODE				enum SegTypes
SEG_CODE_CONFORMING_NON_READABLE	enum SegTypes
SEG_CODE_CONFORMING			enum SegTypes

AccRights	record
	AR_PRESENT:1
	AR_PRIV:2
	AR_ISMEM:1
	AR_TYPE SegTypes:3
	AR_ACCESSED:1
AccRights	end

SegmentDescriptor	struct
    SD_limit		word			; Limit for segment
    SD_baseLow		word			; Low 16 bits of physical base
    SD_baseHigh		byte			; High 8 bits of same
    SD_access		AccRights		; Access rights for segment
    SD_mbz		word	0		; Must be zero (for 286)
SegmentDescriptor	ends
;
; GDT required by BlockMove function.
;	0	required null-selector
;	1	descriptor for GDT itself
;	2	descriptor for move source
;	3	descriptor for move dest
;	4	descriptor for BIOS code
;	5	descriptor for stack
;
GDTStruct	struct
    GDT_null	SegmentDescriptor <>; null selector
    GDT_gdt	SegmentDescriptor <>; gdt itself
    GDT_source	SegmentDescriptor <>; move's source
    GDT_dest	SegmentDescriptor <>; move's dest
    GDT_bios	SegmentDescriptor <>; bios code
    GDT_stack	SegmentDescriptor <>; stack segment
GDTStruct	ends

emGDT		GDTStruct	<>

udata	ends

idata segment

COMMENT @----------------------------------------------------------------------

FUNCTION:	EmStrategy

SYNOPSIS:	ExtMem driver strategy routine

CALLED BY:	EXTERNAL
       		Note that heap semaphore guarantees exclusive access to
		this driver.

PASS:		cs = ds = dgroup
		di		- DR command code.
		other regs	- parameters
		no parameter should be passed in ax

	-----------------------------------------------------------
	PASS:	di	- DR_INIT

	RETURN: carry clear if we can be of use present

	-----------------------------------------------------------
	PASS:	di	- DR_EXIT

	RETURN: carry clear if no error

	-----------------------------------------------------------
	PASS:	di	- DR_SWAP_SWAP_OUT
		dx	- segment of data block
		cx	- size of data block (bytes)
		
	RETURN:	carry clear if no error
		ax	- id of swapped data (for swap-in)

	-----------------------------------------------------------
	PASS:	di	- DR_SWAP_SWAP_IN
		bx	- id of swapped data (as returned by
			  	DR_SWAP_SWAP_OUT)
		dx	- segment of data block
		cx	- size of data block (bytes)

	RETURN:	carry clear if no error

	-----------------------------------------------------------
	PASS:	di	- DR_SWAP_DISCARD
		bx	- id of swapped data (as returned by
			  	DR_SWAP_SWAP_OUT)

	RETURN:	carry clear if no error


DESTROYED:	Depends on function, though best to assume all registers
		that are not returning a value.
		(Segment registers are preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

------------------------------------------------------------------------------@


EmStrategy	proc	far	uses ds, es
		.enter
		mov	ax, cs			;set ds equal to cs
		mov	ds, ax
		mov	es, ax

	;
	; Special-case DR_INIT as it's in a movable module.
	;
		cmp	di, DR_INIT
		jne	notInit
		call	EmInit
done:
		.leave
		ret
notInit:
		call	cs:emFunctions-2[di]
		jmp	done
EmStrategy	endp

idata ends


Init segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actual initialization routine for driver. In separate
		resource so it can go away if need be.

CALLED BY:	EmStrategy
PASS:		DS	= dgroup
RETURN:		Carry set on error
DESTROYED:	AX, BX, ...

PSEUDO CODE/STRATEGY:
	Set the EF_INITIALIZED flag
       	See if /a given in parameter buffer so can set EF_USE_ATRON
	Figure size of extended memory. If result is 0, return with
		carry set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
systemCat	char	"system", 0
extmemDisabled	char	"extmemDisabled", 0

EmInit		proc	far	uses es, di, si, cx, dx, bp
		.enter
	;
	; See if [system]::extmemDisabled is true. If so, we refuse to
	; load.
	; 
		push	ds
		segmov	ds, cs, cx	; ds, cx <- cs
		mov	si, offset systemCat
		mov	dx, offset extmemDisabled
		call	InitFileReadBoolean
		pop	ds
		jc	checkProcessor	; => not present, so not disabled
		tst	ax
		jnz	error

checkProcessor:
	;
	; Figure out if we can actually run.
	;
		call	SysGetConfig
		cmp	dl, SPT_80286	; 80286 or above?
		jge	ERI_20		; Ok -- use BIOS
		;
		; Not 286 or above -- can't have extended memory anyway,
		; silly user.
		;
		mov	ax, ERR_EM_INVALID_PROCESSOR
error:
		stc
		jmp	done
ERI_20:
	;
	; One-time initialization of things for BIOS that don't
	; change between extended-memory accesses.
	;
		;
		; Set the limits for the source and dest segments to
		; always be the unit size (pass the number of words to
		; copy in CX for BIOS, so no need to limit the thing each
		; time). Also initialize the access rights for the source
		; and destination segments since they, too, remain constant.
		;
		mov	ds:emGDT.GDT_source.SD_limit, EM_PAGE_SIZE
		mov	ds:emGDT.GDT_dest.SD_limit, EM_PAGE_SIZE

		mov	ds:emGDT.GDT_source.SD_access, AccRights <1,0,1,SEG_DATA,1>
		mov	ds:emGDT.GDT_dest.SD_access, AccRights <1,0,1,SEG_DATA,1>
		;------------------------------------------------------------
		; 		End BIOS Initialization
		;------------------------------------------------------------
		;
		; Figure size of extended memory.
		; XXX: CHECK FOR VDISK(s)
		;
		call	GetEmSize
		jc	done

	;
	; If not working in Kb units, adjust AX to reflect the number
	; of units, given it's the number of Kb available.
	;
IF EM_PAGE_SIZE LT 1024
		; smaller than a K, must multiply by ratio
		mov	di, 1024/EM_PAGE_SIZE
		mul	di
ELSE
 IF EM_PAGE_SIZE GT 1024
		; more than a K, must divide by ratio
		mov	di, EM_PAGE_SIZE/1024
		clr	dx
		div	di
 ENDIF
ENDIF
if CAN_USE_ATRON
	;
	; Preserve that as the first unit of Atron memory
	;
		mov	ds:emFirstAtron, ax
		test	ds:emFlags, mask EF_USE_ATRON
		jz	ERI_50
	;
	; Write-enable the Atron memory by tweaking its register up in
	; high memory.
	;
	; XXX: write a unit to the memory to make sure Atron board
	; is functioning.
	;
		push	es
		push	ax
		mov	ax, 0f000h
		mov	es, ax
		mov	byte ptr es:[0ffffh], ATRON_WR_ENABLE
		mov	cx, 10	; Spin for a bit
ERI_45:		loop	ERI_45
		mov	byte ptr es:[0ffffh], ATRON_ENABLE
		pop	ax
		pop	es
		add	ax, ATRON_SIZE
ERI_50:
endif
	;
	; Create a swap map for ourselves.
	;
		mov	bx, handle 0
		mov	cx, EM_PAGE_SIZE
		mov	si, segment EmWritePage
		mov	di, offset EmWritePage
		mov	dx, segment EmReadPage
		mov	bp, offset EmReadPage
		call	SwapInit
		jc	done

		mov	ds:[emSwapMap], ax

		ornf	ds:[emFlags], mask EF_INITIALIZED

	;
	; Tell kernel where we are so it can use us :)
	;
		mov	cx, segment EmStrategy
		mov	dx, offset EmStrategy
		mov	ax, SS_PRETTY_FAST or (mask SDF_VOLATILE shl 8)
		call	MemAddSwapDriver
		jc	done
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
EmInit		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetEmSize

DESCRIPTION:	Calls DOS interrupt 15h function 88h to get the size of
		extended memory, then checks for VDISK slimeballs in the
		system.

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		ax - size of extended memory in Kbytes
		carry set if no memory present/available
		emSwapBase adjusted to account for any VDISK(s)

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision

------------------------------------------------------------------------------@
emBootSector	BootSector	<>

GetEmSize	proc	near
	mov	ah, 88h
	int	15h
	test	ah, 0x80	;some BIOSes return carry set even if there
				; is extended memory. On machines that don't
				; support extended memory, the carry will come
				; back set w/either 0x80 or 0x86 in AH. Since
				; a machine cannot possibly have 0x8000 K of
				; extended memory, it strikes me as safe to
				; test the high bit of AH for an error return.
	jnz	done
	tst	ax
if 0
	jnz	checkVDISK
else
	jnz	done
endif
fail:
	stc
done:
	ret

if 0
checkVDISK:
	push	bx, cx, di, es
	push	ax		; save # kb in extmem total
	
	clr	ax		; fetch segment of potential initial VDISK
	mov	es, ax		;  device
	mov	ax, es:[19h*dword].segment
	
				; fetch the base & length of the drive map
	call	DriveReturnStatusTable
	clr	bx		; start drive # at 0
findFirst:
				CheckHack <mask DS_PRESENT eq 0x80>
	test	es:[di].DSE_status, mask DS_PRESENT or mask DS_MEDIA_REMOVABLE
	jns	nextDrive	; => DS_PRESENT clear
	jpe	nextDrive	; => DS_MEDIA_REMOVABLE set
	
	cmp	es:[di].DSE_dosDriver.segment, ax
	je	haveFirst
nextDrive:
	add	di, size DriveStatusEntry
	inc	bx
	loop	findFirst
	clr	cx
	jmp	adjust

haveFirst:
	;
	; Make sure the driver we found is actually a VDISK driver. That is,
	; it's not a character device and it only services a single unit (as
	; stored in the first byte of the DH_name field...). If these don't
	; apply, there's not much we can do except assume there's no VDISK...
	;
	clr	cx
	les	di, es:[di].DSE_dosDriver
	test	es:[di].DH_attr, mask DA_CHAR_DEV
	jnz	adjust
	cmp	es:[di].DH_name, 1
	jne	adjust

	xchg	ax, bx		; al <- drive number, bx <- driver segment
	push	ds
	segmov	ds, cs
	mov	si, offset emBootSector
	call	DiskGetBootSector
	pop	ds
	mov	cx, 0		; Assume no adjustment needed b/c of error
	jc	adjust
	
	;
	; If the oemNameAndVersion doesn't begin with the string VDISK, assume
	; it doesn't follow the "standard" VDISK allocation scheme.
	;
	cmp	{word}cs:[emBootSector.BS_oemNameAndVersion],
			'V' or ('D' shl 8)
	jne	notProper
	cmp	{word}cs:[emBootSector.BS_oemNameAndVersion+2],
			'I' or ('S' shl 8)
	jne	notProper
	cmp	cs:[emBootSector.BS_oemNameAndVersion+4], 'K'
	jne	notProper

	;
	; See if the word in which the Kb address of the first free byte of
	; extmem is supposedly stored makes sense.
	;
	pop	ax		; Fetch total size of extmem
	push	ax		;  and save it again
	mov	cx, {word}cs:[emBootSector.BS_firstFree]
	sub	cx, 1024	; must be above the meg limit
	jbe	notProper
	cmp	cx, ax		; and below the total size of extmem
	jae	notProper
	
	;
	; Well, we'll trust the thing, I guess. Adjust emSwapBase up to match
	; the boundary.
	;
	mov	ax, cx		; multiply by 1K by shifting this left 2 bits
	shl	ax		;  and adding it to the high two bytes of the
	shl	ax		; base address (highest byte
	add	{word}ds:emSwapBase+1, ax 	; is unused...)

adjust:
	pop	ax
	sub	ax, cx
	pop	bx, cx, di, es
	jz	fail
	jmp	done

notProper:
	;
	; The VDISK driver isn't playing by the rules. We'll assume other things
	; think the same thing and just look for VDISKs themselves.
	; XXX: For now just assume all of extended memory is used. If they
	; won't play by the rules, I'm going to take my marbles and go home...
	;
	pop	cx		; use up everything...
	push	cx
	jmp	adjust
endif
GetEmSize	endp

Init ends


idata segment


COMMENT @----------------------------------------------------------------------

FUNCTION:	EmExit

DESCRIPTION:	Handle cleanup of driver.

CALLED BY:	EmStrategy

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	clear the EF_INITIALIZED flag

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision

------------------------------------------------------------------------------@

EmExit	proc	near
	andnf	ds:emFlags, not mask EF_INITIALIZED
	ret
EmExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmDoNothing
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
EmDoNothing	proc	near
		.enter
		clc
		.leave
		ret
EmDoNothing	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	EmSwapOut

DESCRIPTION:	Swaps a chunk out into extended memory.

CALLED BY:	EmStrategy

PASS:		dx - data address of chunk
		cx - number of bytes in chunk
		ds - dgroup (from EmStrategy)

RETURN:		ax - id of storage list
		carry - set if error, clear otherwise

DESTROYED:	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

------------------------------------------------------------------------------@


EmSwapOut	proc	near
	mov	ax, ds:[emSwapMap]
	call	SwapWrite
	ret
EmSwapOut	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmSwapIn

DESCRIPTION:	Transfers a block to the heap and frees the space occupied
		by the block in extended memory.

CALLED BY:	EmStrategy

PASS:		bx - id to retrieve data
		cx - size of chunk in bytes
		dx - data address of chunk
		ds - dgroup (from EmStrategy)

RETURN:		nothing

DESTROYED:	ax, cx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

------------------------------------------------------------------------------@

EmSwapIn	proc	near
	mov	ax, ds:[emSwapMap]
	call	SwapRead
	ret
EmSwapIn	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	EmDiscard

DESCRIPTION:	Release a block from the used list and update the free list.

CALLED BY:	EmStrategy

PASS:		bx - swap id (unit index of stored data)

RETURN:		nothing

DESTROYED:	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	map in page
	return page to free list
	inc free space

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

------------------------------------------------------------------------------@

EmDiscard	proc	near
	mov	ax, ds:[emSwapMap]
	call	SwapFree
	ret
EmDiscard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmGetMap
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
EmGetMap	proc	near
		.enter
		mov	ax, ds:[emSwapMap]
		.leave
		ret
EmGetMap	endp
idata ends

;==============================================================================
;
;		    UTILITY AND CALLBACK ROUTINES
;
;==============================================================================
idata segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmReadPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read page(s) in from extended memory.

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
	ardeb	6/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmReadPage	proc	far	uses bp
		.enter
		mov	bp, offset emGDT.GDT_source
		mov	bx, offset emGDT.GDT_dest
		call	EmTransfer
		.leave
		ret
EmReadPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmWritePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write page(s) out to extended memory.

CALLED BY:	SwapWrite
PASS:		ds:dx	= address from which to read the page(s)
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
	ardeb	6/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmWritePage	proc	far	uses bp
		.enter
		mov	bx, offset emGDT.GDT_source
		mov	bp, offset emGDT.GDT_dest
		call	EmTransfer
		.leave
		ret
EmWritePage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer data to/from extended memory

CALLED BY:	EmsReadPage, EmsWritePage
PASS:		ax	= starting page number
		cx	= number of bytes to transfer
		ds:dx	= source/dest for transfer (depends on bx & bp)
		es	= segment of SwapMap
		bx	= SegmentDescriptor for conventional memory
		bp	= SegmentDescriptor for extended memory
RETURN:		carry set if transfer couldn't be completed:
			cx	= bytes actually transferred.
DESTROYED:	ax, bx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmTransfer	proc	near	uses si, di, es, ds, dx
		.enter
		call	SwapLockDOS
	;
	; Calculate the linear address for the conventional memory and store it
	; in the GDT.
	;
		call	EmFarToLinear		; si:di = linear address
		segmov	ds, cs

		mov	ds:[bx].SD_baseLow, di
		xchg	ax, si
		mov	ds:[bx].SD_baseHigh, al
		xchg	ax, si
		
	;
	; Convert the passed page number into a linear address and store it
	; away as well.
	;
		mov	dx, EM_PAGE_SIZE
		mul	dx
		add	ax, ds:emSwapBase.low
		adc	dx, ds:emSwapBase.high
		
		mov	ds:[bp].SD_baseLow, ax
		mov	ds:[bp].SD_baseHigh, dl

		shr	cx		; Wants it in words...
		segmov	es, cs
		mov	si, offset emGDT
		mov	cs:[wordsMoved], 0
xferLoop:
	;
	; Perform the transfer in page-sized pieces.
	;
		push	cx
		cmp	cx, EM_PAGE_SIZE/2	; more than a page?
		jle	doMove
		mov	cx, EM_PAGE_SIZE/2
doMove:
		add	cs:[wordsMoved], cx
		mov	ah, 87h
		int	15h
		tst	ah		;XXX: BIOS is supposed to return carry
					; set on error, but Phoenix BIOS doesn't
		jnz	fail		; so test AH instead.
		xchg	ax, cx		; ax <- words moved
		pop	cx		; recover words left

	;
	; Reduce word count and boogie if done
	;
		sub	cx, ax
		jz	done
	;
	; Adjust segment descriptors to account for the move.
	;
		shl	ax	; deal with bytes, here...
		add	ds:emGDT.GDT_source.SD_baseLow, ax
		adc	ds:emGDT.GDT_source.SD_baseHigh, 0
		add	ds:emGDT.GDT_dest.SD_baseLow, ax
		adc	ds:emGDT.GDT_dest.SD_baseHigh, 0
		jmp	xferLoop
fail:
		pop	cx
		stc
done:
		mov	cx, cs:[wordsMoved]
		lahf
		shl	cx	; convert to bytes
		sahf
		call	SwapUnlockDOS
		.leave
		ret
EmTransfer	endp		



COMMENT @----------------------------------------------------------------------

FUNCTION:	EmFarToLinear

DESCRIPTION:	Convert a real address into an extended memory linear address

CALLED BY:	EmTransfer

PASS:		ds:dx - segment and offset

RETURN:		si:di - linear address

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision

------------------------------------------------------------------------------@

EmFarToLinear	proc	near
	mov	di, ds
	rol	di, 4			; Shift high nibble into lowest and
					; position other parts properly
	mov	si, di			; Transfer high nibble
	and	si, 0fh			; Clear out all but high nibble of addr
	and	di, not 0fh		; Remove high nibble from low byte
	add	di, dx			;add offset to get linear address
	adc	si, 0			; ripple carry
	ret
EmFarToLinear	endp

ifdef STRESS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StressMe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
stressCounter	word	0

StressMe	proc	far
		.enter
		; Give RPC_CONTINUE reply a chance to return...
		mov	ax, 5
waitLoop:
		mov	cx, -1
		loop	$
		dec	ax
		jnz	waitLoop
		segmov	ds, dgroup, dx
stressLoop:
		mov	dx, dgroup
		mov	cx, EM_PAGE_SIZE
		call	EmSwapOut
		jc	done
		mov	bx, ax
		call	EmDiscard
		dec	ds:stressCounter
		jnz	stressLoop
done:
		.leave
		ret
StressMe	endp

endif
idata ends
