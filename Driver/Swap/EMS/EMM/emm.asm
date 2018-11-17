COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swap Drivers -- Expanded Memory Version
FILE:		emm.asm

AUTHOR:		Adam de Boor, Jun 19, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/19/90		Initial revision


DESCRIPTION:
	Swap driver relying on standard EMM.SYS DOS-level driver to allocate
	and bank in memory.
		

	$Id: emm.asm,v 1.1 97/04/18 11:57:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			     Common Code
;------------------------------------------------------------------------------
include	emsCommon.asm

;------------------------------------------------------------------------------
;			   Special Includes
;------------------------------------------------------------------------------
include	Internal/interrup.def		; for EMMIntercept
include	Internal/fileInt.def		; for EMMIntercept & EmsDeviceInit

UseDriver Internal/fsDriver.def		; for EMMCheckForStealthMode
UseDriver Internal/dosFSDr.def		; for EMMCheckForStealthMode
include Internal/dos.def		; for EMMCheckForStealthMode
include Internal/fsd.def		; for EMMCheckForStealthMode

;------------------------------------------------------------------------------
;	List of lists (for finding device)
;------------------------------------------------------------------------------
DosListOfLists	struct		; > 3.0
    DLOL_DCB		fptr.DeviceControlBlock
    DLOL_SFT		fptr.SFTBlockHeader
    DLOL_clock		fptr.DeviceHeader; Device header for CLOCK$
    DLOL_console	fptr.DeviceHeader; Device header for CON
    DLOL_maxSect	word		; Size of largest sector on any drive
    DLOL_cache		fptr		; First cache block
    DLOL_CWDs		fptr		; Current Working Directory info per
					;  drive
    DLOL_FCBs		fptr		; SFT for FCB access
    DLOL_FCBsize	word		; Number of entries in FCB SFT
    DLOL_numDrives	byte		; Number of drives in system
    DLOL_lastDrive	byte		; Last real drive
    DLOL_null		DeviceHeader	; Header for NUL device -- the head
					;  of the driver chain.
DosListOfLists	ends

Dos3_0ListOfLists struct		; 3.0
    D3LOL_DCB		fptr.DeviceControlBlock
    D3LOL_SFT		fptr.SFTBlockHeader
    D3LOL_clock		fptr.DeviceHeader
    D3LOL_console	fptr.DeviceHeader
    D3LOL_numDrives	byte
    D3LOL_maxSector	word
    D3LOL_cache		fptr
    D3LOL_CWDs		fptr.CurrentDirectory
    D3LOL_lastDrive	byte
    			byte	12 dup(?); Who knows?
    D3LOL_null		DeviceHeader
Dos3_0ListOfLists ends

Dos2ListOfLists	struct		; 2.X
    D2LOL_DCB		fptr.DeviceControlBlock
    D2LOL_SFT		fptr.SFTBlockHeader
    D2LOL_clock		fptr.DeviceHeader; Device header for CLOCK$
    D2LOL_console	fptr.DeviceHeader; Device header for CON
    D2LOL_numDrives	byte		; Number of drives in system
    D2LOL_maxSect	word		; Size of largest sector on any drive
    D2LOL_cache		fptr		; First cache block
    D2LOL_null		DeviceHeader	; Header for NUL device -- the head
					;  of the driver chain.
Dos2ListOfLists	ends

DEBUG_PROTECT		= FALSE

if DEBUG_PROTECT
PrintMessage <*+*+*+*+*+*+ DEBUG_PROTECT IS ON +*+*+*+*+*+*>
endif

LOG_PROTECT		= FALSE

if LOG_PROTECT
PrintMessage <*+*+*+*+*+*+ LOG_PROTECT IS ON +*+*+*+*+*+*>
endif

LOG_ACTIONS		= FALSE

if LOG_ACTIONS
PrintMessage <*+*+*+*+*+*+ LOG_ACTIONS IS ON +*+*+*+*+*+*>
endif

;
; This needs to turned on if the kernel has the UTILITY_MAPPING_WINDOW
; feature turned on.
;
CHECK_UTILITY_MAPPING_WINDOW	=	FALSE

TF		equ	0x100	; Trace flag in a flags-word image
.ioenable			; allow CLI/STI...

;------------------------------------------------------------------------------
;			      Constants
;------------------------------------------------------------------------------

ERR_EMS								enum FatalErrors

include Internal/emm.def
;------------------------------------------------------------------------------
;			      Variables
;------------------------------------------------------------------------------

idata		segment

emsBaseBank	word	EMS_MAX_BANKS-1	;first bank of our allocated
					; banks that is used for
					; swapping when emsUseMoveRegion
					; is FALSE
;emmSem		Semaphore	<>	;Semaphore grabbed by EMMCallRealDriver
					; in case something calls EMM w/o
					; grabbing the DOS semaphore (it's
					; happened with Super PC-Kwik...)
					; 
idata		ends

udata	segment

emsSwapHandle		word	(?)	;handle of swap area

emsSwapSeg		sptr		;segment of bank to which data are
					; actually swapped
emsCurBank		word	0	;bank currently in the swapping bank

ifdef MOVE_REGION_NOT_HOSED
emsUseMoveRegion BooleanByte BB_FALSE	;TRUE if we can use EMF_MOVE_REGION
					; to swap in and out.
endif

emsMoveParams	EMMMoveParams		;parameters for EMF_MOVE_REGION
					; if needed.
emsBytesMoved	word	0		;bytes moved so far this transfer
udata	ends

;
; Garbage for protecting GEOS from TSRs
; 
idata	segment
emmLastVector	fptr.fptr.far EMM_INT*4	;address of last vector leapt through.
					; initialized to the int 67h vector
					; to make life simpler.
idata	ends

udata		segment
emmDriver	fptr.far		;address of real driver

oldEMM		fptr.far		;original contents of *emmLastVector


emmProtected	byte	0		;non-zero if system currently protected
					; from EMM-using TSRs via a
					; SysEnterCritical


emmMaps		sptr			;buffer containing our saved map (if
					; supported) and our saved partial
					; map (if supported) for comparison in
					; EMMIntercept
emmPartStart	word			;offset into emmMaps at which our
					; partial map starts
emmPartSize	word			;size of our partial map

EmmMapTypes	record
    EMT_FULL:1,		; Full map supported (version >= 3.2)
    EMT_PART:1		; Partial map supported (version >= 4.0)
EmmMapTypes	end

emmMapTypes	EmmMapTypes	<0,0>

EMMPartMapDesc	struct
    EMMPMD_numBanks	word	EMS_MAX_BANKS
    EMMPMD_banks	sptr	EMS_MAX_BANKS dup(?)
EMMPartMapDesc	ends

; Partial-map descriptor used in EMF_GET_PART_MAP and EMF_GET_PART_MAP_SIZE
; functions
emmPartMapDesc	EMMPartMapDesc	<0,<>>

;
; Variables for locating the real EMM
; 
oldInt1		fptr.far		;saved single-step vector while locating
					; the EMM's entry point
udata		ends

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

;------------------------------------------------------------------------------
;			Protection Debugging
;------------------------------------------------------------------------------
if	LOG_PROTECT

EmmCall		struct
    EC_ax		EMMFunctions
    EC_bx		word
    EC_cx		word
    EC_dx		word
    EC_si		word
    EC_di		word
    EC_ds		sptr
    EC_es		sptr
    EC_ss		sptr
    EC_sp		word
    EC_inProgress	word
EmmCall		ends

MAX_CALL_LOG	equ	128

udata	segment
callLog		EmmCall	MAX_CALL_LOG dup(<>)
callLogPtr	word	0
callPrevPtr	word	0
udata	ends

endif


Init	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMMCheckForStealthMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if QEMM is loaded and, if so, it's in stealth mode. We
		can't operate when it's in stealth mode, as it likes to
		manipulate the page frame behind our back, so we can context
		switch while the frame isn't set up properly and start
		executing garbage.

CALLED BY:	(INTERNAL) EmsDeviceInit
PASS:		nothing
RETURN:		carry set if QEMM is present and in stealth mode.
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString qemmDeviceName <"QEMM386$", 0>
EMMCheckForStealthMode proc	near
entryPoint	local	fptr.far
		uses	ds, es, bx, cx, dx, si, di
		.enter
		
		mov	dx, offset qemmDeviceName
		segmov	ds, cs
		mov	al, FileAccessFlags<FE_NONE,FA_READ_ONLY>
		call	FileOpen
		jc	noQ

		mov_tr	bx, ax
		call	EMMFetchQemmEntryPoint
		
		pushf
		clr	al
		call	FileClose
		popf
		jc	noQ
		
		mov	ax, 1e00h	; Pass:	  ax = 1e00h
					; Return: cl = stealth type (char)
					;	       0 if disabled
					;	  ch = suspend/resume int #
					; Destroyed:	bx, dx, di, si
		push	bp
		call	ss:[entryPoint]
		pop	bp
		tst	cl
		jz	done
		stc
done:
		.leave
		ret
noQ:
		clc
		jmp	done
EMMCheckForStealthMode endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMMFetchQemmEntryPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an IOCTL_READ_CONTROL_STRING to fetch the entry
		point within QEMM we can query.

CALLED BY:	(INTERNAL) EMMCheckForStealthMode
PASS:		bx	= file handle
RETURN:		carry set on error
DESTROYED:	ax, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	XXX: This is a gross hack to set the device into raw mode, so it
	won't try to translate returns or do any of the other nonsense the
	DOS driver so likes to do.
	
	We have no generic IOCTL mechanism in the kernel, unfortunately, as
	we have no time to design a good one. So we're going to call the
	primary IFS driver directly for this one, gaining us a DOS file
	handle we can then use to make the call to DOS.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMMFetchQemmEntryPoint proc	near
		.enter	inherit	EMMCheckForStealthMode
		push	bx
	;
	; Fetch the geode handle of the primary IFS driver.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, es:[FIH_primaryFSD]
		mov	bx, es:[si].FSD_handle
	;
	; Get to its FSDriverInfoStruct and make sure its alternate
	; strategy is something we can talk to.
	; 
		call	GeodeInfoDriver		; ds:si <- FSDriverInfoStruct
		cmp	ds:[si].FSDIS_altProto.PN_major,
			DOS_PRIMARY_FS_PROTO_MAJOR
		stc
		jne	done
		cmp	ds:[si].FSDIS_altProto.PN_minor,
			DOS_PRIMARY_FS_PROTO_MINOR
		jb	done
	;
	; Fetch the SFN for the file handle and ask the driver to allocate
	; us a DOS file handle.
	; 
		mov	es, es:[FIH_dgroup]
		pop	bx
		push	bx
		mov	bl, es:[bx].HF_sfn
		mov	di, DR_DPFS_ALLOC_DOS_HANDLE
		call	ds:[si].FSDIS_altStrat
	;
	; Now fetch the entrypoint from the driver
	; 
		push	ds, si
		lea	dx, ss:[entryPoint]
		segmov	ds, ss
		mov	cx, size entryPoint
		mov	ax, MSDOS_IOCTL_READ_CONTROL_STRING
		call	FileInt21
		pop	ds, si
	;
	; Release the DOS handle again.
	; 
		pushf
   		mov	di, DR_DPFS_FREE_DOS_HANDLE
		call	ds:[si].FSDIS_altStrat
		popf
done:
		call	FSDUnlockInfoShared
		pop	bx
		.leave
		ret
EMMFetchQemmEntryPoint endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsDeviceInit

SYNOPSIS:	Initialize the swap device

CALLED BY:	EmsInit

PASS:		ds	= dgroup

RETURN:		carry - set on error
		ax	= # pages available for swapping
		bx	= segment of the page frame to add to the heap
		cx	= # paragraphs in the frame to add

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision

-------------------------------------------------------------------------------@

emm_device_name	char	"EMMXXXX0"	;guaranteed name of EMM driver

EmsDeviceInit	proc	near	uses si, di
		.enter
	;
	; First make sure the driver's around. Just because we've been loaded
	; doesn't mean there's a manager around...
	; We use the device chain to locate the last EMMXXXX0 device so we
	; don't get fooled by things like Super PC-Kwik that intercept int 67h
	; for their own purposes.
	;
		push	es, ds
		mov	ah, MSDOS_GET_VERSION
		call	FileInt21
		xchg	ax, cx
		
		mov	ah, MSDOS_GET_DOS_TABLES
		call	FileInt21
		
		add	bx, offset D2LOL_null	; assume DOS 2.X
		cmp	cl, 2
		je	haveNull		; yup
		
		; Deal with DOS 3.0, which has a smaller ListOfLists
		add	bx, offset D3LOL_null - offset D2LOL_null
		cmp	cl, 3
		jne	10$			; > 3
		cmp	ch, 10			; 3.10 or above?
		jb	haveNull		; no
10$:		
		add	bx, offset DLOL_null - offset D3LOL_null
haveNull:
		segmov	ds, cs
devLoop:
	;
	; EMS driver must be a character device...
	;
		test	es:[bx].DH_attr, mask DA_CHAR_DEV
		jz	nextDev
	;
	; Does the thing match the defined name for the EMM?
	;		
		lea	di, es:[bx].DH_name
		lea	si, emm_device_name
		mov	cx, length emm_device_name;number of bytes to compare
		repe	cmpsb
		jne	nextDev
	;
	; Have a match. Record this one and continue, in case some interceptor
	; has stuck itself in the device chain as well. We need to find the
	; very first EMM, on the assumption that it's the real one with all
	; the power.
	; 
		pop	ds
		mov	ds:[emmDriver].segment, es
		push	ds
		segmov	ds, cs
nextDev:
		les	bx, es:[bx].DH_next
		cmp	bx, -1		; end of the line?
		jne	devLoop		; no -- keep looking
	;
	; See if we found any EMM in the list. If not, we can't operate.
	;
		pop	ds
		tst	ds:[emmDriver].segment
		jnz	haveEMM
popESError:
		pop	es
		jmp	error

haveEMM:
EC<		pop	es		>	; put somthing
EC<		push	es		>	; reasonable in it!
	;
	; Make sure QEMM, if it's around, isn't in stealth mode.
	; 
		call	EMMCheckForStealthMode
		jc	popESError
	;
	; Now fetch the offset and segment of the EMM manager from int 67h
	; so we can get to the sucker more quickly than via a software int.
	; If the vector points to the EMM we found in the device chain, we're
	; happy, else we have to go to the gross function that locates the
	; entry for the real manager...
	; 
		clr	ax
		mov	es, ax
		mov	ax, es:[67h * fptr].offset
		mov	ds:[emmDriver].offset, ax
		mov	ax, es:[67h * dword].segment
		cmp	ax, ds:[emmDriver].segment	; any interceptors?
		je	normalInit			; nope -- we're happy

		mov	ds:[emmDriver].segment, ax	;assume no interceptors,
							; just a relocated
							; manager...
		call	EmsGetStatusFindEMM
		jnz	popESError
		jmp	getVersion
normalInit:
		mov	ax, EMF_GET_STATUS
		call	EmsInitCallEMM
		jnz	popESError

getVersion:
		pop	es		; can now recover ES
	;
	; Fetch the version number so we can decide whether to use
	; EMF_MOVE_REGION and give the kernel more memory.
	;
		mov	ax, EMF_GET_VERSION
		call	EmsInitCallEMM
		jnz	error
		cmp	al, 0x32
		jb	doAlloc
		ornf	ds:[emmMapTypes], mask EMT_FULL
		cmp	al, 0x40	; 4.0 or higher?
		jb	doAlloc		; no
		ornf	ds:[emmMapTypes], mask EMT_PART

		; XXX: use a larger frame if hardware can provide it.
		; A call exists to find this out, but we'd have to detect
		; contiguous banks to add them to the heap
ifdef MOVE_REGION_NOT_HOSED
		mov	ds:[emsUseMoveRegion], BB_TRUE
		inc	ds:[emsBaseBank]
endif
doAlloc:
	;
	; Allocate all the remaining banks.
	;
		mov	ax, EMF_GET_NUM_PAGES
		call	EmsInitCallEMM
		jnz	error
		
		cmp	bx, EMS_MAX_BANKS
		jb	error
		
		;
		; Figure the number of swap pages that gives us.
		;
		mov	ax, bx
		mov	cx, EMS_BANK_SIZE/EMS_PAGE_SIZE
		mul	cx
		jc	maxOutPages
		cmp	ax, EMS_MAX_PAGES
		jb	allocPages
maxOutPages:
		;
		; Too many pages available -- max out at our limit and set
		; bx to the appropriate number of banks.
		;
		mov	ax, EMS_MAX_PAGES
		mov	bx, (EMS_MAX_PAGES*EMS_PAGE_SIZE+EMS_BANK_SIZE-1)/EMS_BANK_SIZE
allocPages:		
		push	ax
		mov	ax, EMF_ALLOC
		call	EmsInitCallEMM
		jnz	errorPopAX
		
		mov	ds:[emsSwapHandle], dx
	;
	; If the utility mapping window exists in the page frame, don't
	; step on it
	;
if CHECK_UTILITY_MAPPING_WINDOW
		call	AdjustForUtilWindow
endif
	;
	; Bank in the initial things for the heap.
	;
		mov	bx, ds:[emsBaseBank]
if CHECK_UTILITY_MAPPING_WINDOW
		tst	bx
		js	errorFreePopAX		; no room for bank window
endif
bankLoop:
		dec	bx
		js	finish
		mov	al, bl
		mov	ah, high EMF_MAP_BANK
		call	EmsInitCallEMM
		jz	bankLoop
	
errorFreePopAX:
		mov	dx, ds:[emsSwapHandle]
		mov	ax, EMF_FREE
		call	EmsInitCallEMM

errorPopAX:
		pop	ax

error:
		stc
		jmp	done

finish:
	;
	; Now figure where that went and how much of it we can give to the
	; kernel.
	;
		mov	ax, EMF_GET_PAGE_FRAME
		call	EmsInitCallEMM
		jnz	errorFreePopAX
		
		pop	ax			; recover # pages
if CHECK_UTILITY_MAPPING_WINDOW	;--------------------------------------------
		clr	dx
		mov	cx, ds:[emsBaseBank]
		jcxz	doneHeapAdj
heapAdjLoop:
		add	dx, EMS_BANK_SIZE shr 4
		sub	ax, EMS_BANK_SIZE/EMS_PAGE_SIZE
		loop	heapAdjLoop
doneHeapAdj:
		mov	cx, dx			; cx = heap space
else	;--------------------------------------------------------------------
ifdef MOVE_REGION_NOT_HOSED
		mov	cx, (EMS_MAX_BANKS * EMS_BANK_SIZE) shr 4
		sub	ax, EMS_MAX_BANKS * (EMS_BANK_SIZE/EMS_PAGE_SIZE)
		tst	ds:[emsUseMoveRegion]
		jnz	done			; add entire frame to heap
		
		sub	cx, EMS_BANK_SIZE shr 4	; use one bank for swapping
		add	ax, EMS_BANK_SIZE/EMS_PAGE_SIZE
else
		mov	cx, ((EMS_MAX_BANKS-1) * EMS_BANK_SIZE) shr 4
		sub	ax, (EMS_MAX_BANKS-1) * (EMS_BANK_SIZE/EMS_PAGE_SIZE)
endif
endif	;--------------------------------------------------------------------
		mov	dx, bx
		add	dx, cx			; (cannot set carry)
		mov	ds:[emsSwapSeg], dx

	;
	; Allocate space on the heap for the maps we have to maintain to
	; prevent corruption by TSRs
	; 
		push	ax, bx, cx
		test	ds:[emmMapTypes], mask EMT_FULL
		jz	mapsComplete
		;
		; Fetch the size of a full map, since the EMM supports it.
		; Record it as the start of any partial map we fetch.
		;
		mov	ax, EMF_GET_MAP_SIZE
		call	EmsInitCallEMM
		mov	ds:[emmPartStart], ax
		;
		; If EMM supports partial maps, initialize emmPartMapDesc so
		; we can find out how many bytes we need to hold the thing.
		; For now, we are only interested in the 4 banks of the
		; standard 64K page frame. Eventually we should be interested
		; in all pages in an expanded page frame.
		;
		test	ds:[emmMapTypes], mask EMT_PART
		jz	allocMapBlock

		mov	cx, EMS_MAX_BANKS
		mov	di, offset emmPartMapDesc.EMMPMD_banks
		mov	ds:[emmPartMapDesc].EMMPMD_numBanks, cx
		segmov	es, ds
		xchg	ax, bx
pmapBankLoop:
		stosw
		add	ax, EMS_BANK_SIZE shr 4
		loop	pmapBankLoop

		mov	bx, EMS_MAX_BANKS
		mov	ax, EMF_GET_PART_MAP_SIZE
		call	EmsInitCallEMM
		mov	ds:[emmPartSize], ax

allocMapBlock:
		mov	ax, ds:[emmPartSize]	; make room for two partial
		shl	ax			;  maps so EMMIntercept can
						;  avoid potential stack
						;  trashing
		add	ax, ds:[emmPartStart]
		mov	cx, mask HF_FIXED
		mov	bx, handle 0
		call	MemAllocSetOwner
		; XXX: look for errors
		mov	ds:[emmMaps], ax
		
		call	EmsUpdateMaps
mapsComplete:
		pop	ax, bx, cx
			
	;
	; Adjust the contents of the final vector through which we jumped
	; or called before we got to the real EMM. This may just be the
	; int 67h vector, of course, but that's fine.
	; 
		push	ax, es, di
		
		les	di, ds:[emmLastVector]
		INT_OFF
		mov	ax, offset EMMIntercept
		xchg	ax, es:[di].offset
		mov	ds:[oldEMM].offset, ax
		mov	ax, segment EMMIntercept
		xchg	ax, es:[di].segment
		mov	ds:[oldEMM].segment, ax
		INT_ON
		
		pop	ax, es, di
		clc
done:
		.leave
		ret

EmsDeviceInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForUtilWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust swapping window for utility mapping window

CALLED BY:	INTERNAL
			EmsDeviceInit
PASS:		ds = dgroup
RETURN:		ds:[emsBaseBank] = updated to avoid utility mapping window
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CHECK_UTILITY_MAPPING_WINDOW

AdjustForUtilWindow	proc	near
		push	dx, bp
		call	SysGetUtilWindowInfo	; ax = TRUE if util window
						; cx = window size
						; bx = number of windows
						; dx:bp = window address
		tst	ax
		jz	noUtilWindowCheck
		xchg	bx, cx			; bx = size, cx = #
		test	bx, 0x000f
		jz	paraAligned
		add	bx, 0x0010		; else, another paragraph
paraAligned:
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1			; bx = size in paragraphs
		clr	ax			; ax = running total
utilWindowSizeLoop:
		add	ax, bx
		loop	utilWindowSizeLoop	; ax = total map window size
						;	in paragraphs
		add	ax, dx			; ax = ending segment
		mov	cx, ax			; cx = ending segment
		mov	ax, EMF_GET_PAGE_FRAME
		call	EmsInitCallEMM		; bx = page frame segment
		jnz	noUtilWindowCheck
		cmp	cx, bx
		jb	noUtilWindowCheck	; util window before page frame
		add	bx, (EMS_BANK_SIZE * EMS_MAX_BANKS) shr 4
		cmp	dx, bx
		jae	noUtilWindowCheck	; util window after page frame
checkUtilLocLoop:
		dec	ds:[emsBaseBank]
		js	noUtilWindowCheck
		sub	bx, EMS_BANK_SIZE shr 4
		cmp	dx, bx
		jb	checkUtilLocLoop
noUtilWindowCheck:
		pop	dx, bp
		ret
AdjustForUtilWindow	endp

endif	; CHECK_UTILITY_MAPPING_WINDOW


COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsInitCallEMM

DESCRIPTION:	Calls the EMS driver function through Int 67h to perform
		the ems function.

CALLED BY:	INTERNAL (utility)

PASS:		parameters for ems driver

RETURN:		results of function
		carry always clear
		JZ will take if function was successful.

DESTROYED:	depends on function

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

EmsInitCallEMM	proc	near
	int	67h			;call EMS
	tst	ah			;test for error
	ret
EmsInitCallEMM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsGetStatusFindEMM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function is necessitated by certain programs' (e.g.
		Super PC-Kwik's and our own) tendency to intercept int 67h,
		then call the real EMM directly, rather than via int 67h.
		The problem is, we *need* to intercept all calls so we can
		avoid context switches while the mapping context is confused.
		This function locates the real manager, while at the same
		time fetching the status of the thing.

CALLED BY:	EmsDeviceInit
PASS:		ds	= dgroup
		es	= interrupt table
		ds:[emmDriver].segment = segment of the real manager
RETURN:		ds:[emmDriver].offset set to the offset of the real EMM
		jz if status fetch was successful
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		Rather than try and decode all the possible layers of
		interceptors and find the vector that actually points to
		the real one, it seems "cleaner" (and certainly more reliable)
		to just single-step the processor until the CS matches the
		segment we've recorded for the EMM. At that point, we'll know
		the real address of the EMM so we can intercept it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Perhaps we should disable most hardware interrupts? On 8088
		and 8086 machines, if an interrupt comes in, we'll single-step
		the handler as well. Perhaps we should try and detect this...
		
		9/23: Actually, this isn't true. The processor will indeed
		stop at the first instruction of the handler, having recognized
		the hardware interrupt before the single-step interrupt, but
		the flags word pushed on the way here will have TF clear, so
		when we return, the machine will execute normally until the
		handler returns, at which point TF will become set again,
		having been popped from the stack, and we'll continue stepping
		as we wanted to.

		DO NOT STEP INTO THIS FUNCTION!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsGetStatusFindEMM proc near
		.enter
	;
	; Rather than waste time looking for POPF instructions w/TF clear (in
	; EmsStepHandler), we just push an extra copy of the flags register with
	; TF clear here, and pop it before resetting the single-step interrupt
	; at callRet. This makes sure that any weird POPF's of the flags passed
	; into the "int EMM_INT" we're doing, such as are in Super PC-Kwik, will
	; not cause us to lose control of the machine.
	; 
		pushf			; MUST HAVE TF CLEAR
	;
	; Set up interrupt frame for the interceptor's return
	;
		pushf
		pop	ax
		ornf	ax, TF		; set the trace flag
		push	ax
		push	cs
		mov	di, offset callRet
		push	di
	;
	; Set up an interrupt frame for us to transfer control to the
	; interceptor with the trace flag set.
	;
		push	ax
		push	es:[EMM_INT * fptr].segment
		push	es:[EMM_INT * fptr].offset

	;
	; Intercept the single-step interrupt
	;
		segmov	es, ds
		mov	ax, 1		; single-step interrupt
		mov	di, offset oldInt1
		mov	bx, cs
		mov	cx, offset EmsStepHandler
		call	SysCatchInterrupt
	
	;
	; Now "call" the interceptor.
	;
		mov	ax, EMF_GET_STATUS
		iret
callRet:
		popf			;recover flags register w/TF clear
	;
	; Reset the single-step interrupt vector.
	;
		push	ax
		mov	di, offset oldInt1
		mov	ax, 1
		call	SysResetInterrupt
		pop	ax
	;
	; See if the call was successful.
	;
		tst	ah
		.leave
		ret
EmsGetStatusFindEMM endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsStepHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler function for single-step interrupt when looking for
		the real manager.

CALLED BY:	Trace Flag Exception
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		One might think it important to look out for software
		interrupts here, since on the 286 and above, the interrupt
		handler will execute before the single-step trap will be
		taken. However, the only interrupt that could possibly be
		of interest here would be int 67h, and that can't come
		in, or the INT 67h would loop infinitely. For any other
		interrupt, we'd really rather not step the handler, as it can't
		pertain to what were after: the address of the real manager's
		interrupt routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
emmTempVector	fptr.fptr.far 0		;stored address of the vector through
					; which the call or jump occurred.
haveSegment	byte 	0
emmCheckSegment	byte	0		;set non-zero if single-step handler is
					; to check the return segment of the
					; next instruction for EMM.

ESHStack	struct
    ESHS_ax	word
    ESHS_bx	word
    ESHS_cx	word
    ESHS_dx	word
    ESHS_bp	word
    ESHS_si	word
    ESHS_di	word
    ESHS_ds	sptr
    ESHS_es	sptr
    ESHS_retf	fptr.far
    ESHS_flags	word
ESHStack	ends

EmsStepHandler	proc	far
		push	es, ds, di, si, bp, dx, cx, bx, ax
		segmov	ds, dgroup, ax
		mov	bp, sp
		mov	ax, ss:[bp].ESHS_retf.segment	; ax <- return segment
		tst	cs:[emmCheckSegment]
		jz	checkInst
		
	;
	; We were told to check the destination of a far call or jump when that
	; call or jump completed, which it has now done.
	;
	; If the destination is in the same segment as the previous call or
	; jump we checked, just ignore this one, on the assumption that the
	; first entry to a segment will be the main EMM entry point.
	;
	; If the destination contains a DeviceHeader at its front with the
	; guaranteed name of the EMM device, record the segment and offset
	; to which we jumped as the entry for the EMM. Keep stepping, however
	; to deal with multiple interceptors...
	; 
		cmp	ds:[emmDriver].segment, ax
		je	resetCheckSegment

		push	es, di, cx
		mov	es, ax
		mov	di, offset DH_name
		mov	si, offset emm_device_name
		mov	cx, length emm_device_name
		repe	cmpsb cs:		; interrupts are off, so we
						;  can safely do this...
		pop	es, di, cx
		; (ax still contains return segment)
		jne	resetCheckSegment	; Nope -- ignore jmp/call
		
		mov	si, ss:[bp].ESHS_retf.offset	; Fetch offset of inst 
		mov	ds:[emmDriver].offset, si	;  w/o trashing AX
		mov	ds:[emmDriver].segment, ax	;  (see below)

		; save the address of the vector through which we jumped
		mov	si, cs:[emmTempVector].segment
		mov	ds:[emmLastVector].segment, si
		mov	si, cs:[emmTempVector].offset
		mov	ds:[emmLastVector].offset, si

resetCheckSegment:
		dec	cs:[emmCheckSegment]	; Don't check segment next time
		; FALL THROUGH TO HANDLE INITIAL CALL/JMP

checkInst:
	;
	; See if the instruction to which we're going to return is a far
	; indirect call or jump. If so, set emmCheckSegment so when the thing
	; is complete, we see if the destination of the call or jump is an
	; EMM segment. Both calls and jumps of this nature use the 0xff opcode,
	; with a reg field in the ModRM byte of 011 (call) or 101 (jmp).
	; 
		push	ds
		mov	ds, ax
		mov	si, ss:[bp].ESHS_retf.offset
		mov	cs:[haveSegment], FALSE
		; check for segment override. The possible overrides are
		; 0x26 (ES:), 0x2e (CS:), 0x36 (SS:) and 0x3e (DS:), so
		; masking the instruction with 0xe7 will clear the bits that
		; don't matter (the only bits in which the overrides differ),
		; allowing us to compare the instruction with the base override
		; (0x26) to see if it's an override.
skipPrefixes:
		lodsb
		mov	ah, al
		andnf	ah, 0xe7
		cmp	ah, 0x26
		jne	afterPrefixes
		xor	al, ah		; clear out all but register #
		
		jnz	notES
		mov	ax, es
		jmp	storeSegment
notES:
		; three remaining choices are CS (1 shl 3), SS (2 shl 3) or
		; DS (3 shl 3), so a single compare can figure which it is.
		cmp	al, 2 shl 3	; SS?
		mov	ax, ss
		je	storeSegment	; yes
		mov	ax, ds		; CS?
		jb	storeSegment	; yes
		mov	ax, ss:[bp].ESHS_ds
storeSegment:
		mov	cs:[emmTempVector].segment, ax
		mov	cs:[haveSegment], TRUE
		jmp	skipPrefixes

afterPrefixes:
		; no other prefixes (REP or LOCK) can precede an indirect call
		; or jump, so no need to check for them.
		
		cmp	al, 0xff		; group 2 instruction?
		jne	donePopDS

		mov	al, ds:[si]
		andnf	al, 00111000b		; clear out all but REG field
		cmp	al, 00011000b		; FAR CALL?
		je	checkNext
		cmp	al, 00101000b		; FAR JMP?
		jne	donePopDS
checkNext:
		inc	cs:[emmCheckSegment]

		; we must now decode the effective address so we know what
		; vector was last used to transfer control to a different
		; segment so we know what vector to patch.

		mov	cx, ss:[bp].ESHS_ds	; assume DS is default segment

		lodsb
		andnf	al, 11000111b		; clear out REG field
		cmp	al, 6
		jne	notDirect
		lodsw
		xchg	dx, ax		; dx <- offset (1-byte inst)
		jmp	storeOffset

notDirect:
		clr	dx
		mov	bx, ax
		andnf	bx, 7
		shl	bx
		jmp	cs:[eaCalc][bx]

ea_bx_si:
		mov	dx, ss:[bp].ESHS_bx
		jmp	ea_si
ea_bx_di:
		mov	dx, ss:[bp].ESHS_bx
		jmp	ea_di
ea_bp_si:
		mov	cx, ss
		mov	dx, ss:[bp].ESHS_bp
		jmp	ea_si
ea_bp_di:
		mov	cx, ss
		mov	dx, ss:[bp].ESHS_bp
		jmp	ea_di
ea_si:
		add	dx, ss:[bp].ESHS_si
		jmp	addDisp
ea_di:
		add	dx, ss:[bp].ESHS_di
		jmp	addDisp
ea_bp:
		mov	cx, ss
		mov	dx, ss:[bp].ESHS_bp
		jmp	addDisp
ea_bx:
		mov	dx, ss:[bp].ESHS_bx
addDisp:
		and	al, 11000000b
		jz	storeOffset
		lodsw			; assume word displacement
		js	addDispAX	; we were right -- just use AX (can't
					;  be a register [11000000b], so no
					;  need to check for that)
		cbw			; wrong -- convert byte to word
addDispAX:
		add	dx, ax		; add the displacement to the offset
storeOffset:
	;
	; CX is the value of the default segment for the addressing mode.
	; DX is the offset of the vector within whatever segment.
	; cs:[haveSegment] was set non-zero if a segment-override was seen.
	; 
		mov	cs:[emmTempVector].offset, dx
		tst	cs:[haveSegment]
		jnz	donePopDS
		mov	cs:[emmTempVector].segment, cx
donePopDS:
		pop	ds
done:
		pop	es, ds, di, si, bp, dx, cx, bx, ax
		iret

eaCalc		nptr	ea_bx_si, ea_bx_di, ea_bp_si, ea_bp_di,
			ea_si, ea_di, ea_bp, ea_bx
EmsStepHandler	endp
		
Init		ends



idata		segment

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsExit

DESCRIPTION:	Cleans up by freeing the occupied space in expanded memory.

CALLED BY:	DR_EXIT

PASS:		ds	= dgroup

RETURN:		all EMS pages taken up by GEOS are freed

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial Revision

-------------------------------------------------------------------------------@

EmsExit		proc	near
		uses	es, di
		.enter
	;
	; Free the pages we allocated.
	;
		mov	dx, ds:[emsSwapHandle]
		mov	ax, EMF_FREE
		call	EmsCallEMM
	;
	; Reset our intercept.
	;
		les	di, ds:[emmLastVector]
		INT_OFF
		mov	ax, ds:[oldEMM].offset
		stosw
		mov	ax, ds:[oldEMM].segment
		stosw
		INT_ON

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

ifdef MOVE_REGION_NOT_HOSED
		tst	ds:[emsUseMoveRegion]	; Let EMM do it?
		jz	doItTheHardWay		; No. yuck.

		mov	ds:[bx].EMMA_handle, dx
		
	;
	; Point ds:si to the move parameters and tell the EMM to move the
	; sucker.
	;
		mov	ax, EMF_MOVE_REGION
		mov	si, offset emsMoveParams
		call	EmsCallEMM
		jz	done

error:
		stc
done:
		call	SwapUnlockDOS
		.leave
		ret
	;------------------------------------------------------------
doItTheHardWay:
endif

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
		jnz	error
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
		push	cx
		push	ds
		les	di, ds:[emsMoveParams].EMMMP_dest.EMMA_addr
		lds	si, ds:[emsMoveParams].EMMMP_source.EMMA_addr
		shr	cx
		rep	movsw
		pop	ds
		pop	ax
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
		inc	ds:[bx].EMMA_handle	; Go to next bank
		mov	ds:[bx].EMMA_addr.offset, 0	; from offset 0...
		jmp	xferLoop
ifndef MOVE_REGION_NOT_HOSED
error:
		stc
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

SYNOPSIS:	Map a bank into the swap area, updating the maps used for
		protecting us from TSRs

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsMapBank	proc	near
		uses	bx
		.enter
		mov	bx, ds:[bx].EMMA_handle
		cmp	bx, ds:[emsCurBank]
		je	done
		
		mov	ds:[emsCurBank], bx	; record as currently mapped
						;  bank
if CHECK_UTILITY_MAPPING_WINDOW
		mov	ax, EMF_MAP_BANK
		or	ax, ds:[emsBaseBank]
else
		mov	ax, EMF_MAP_BANK or (EMS_MAX_BANKS - 1)
endif
	
	;
	; When returning from a GeosTS DosExec, don't bother with 
	; SysEnterCritical and SysExitCritical
	;
		call	SwapIsKernelInMemory?
		jnc	callEMM
		call	SysEnterCritical	; prevent context switch
						;  until our maps are updated
callEMM:
		call	EmsCallEMM
		jnz	doneExitCritical

		call	EmsUpdateMaps
		clr	ax			; signal no error
doneExitCritical:
		pushf
		call	SwapIsKernelInMemory?	
		jnc	donePopf
		call	SysExitCritical
donePopf:
		popf
done:
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
RETURN:		ax	= offset into EMS bank
		cx	= EMS bank within emsSwapHandle's range
		dx	= emsSwapHandle
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

		mov	dx, ds:[emsSwapHandle]
		.leave
		ret
EmsCvtPageToEms	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	EmsCallEMM

DESCRIPTION:	Calls the EMS driver function through Int 67h to perform
		the ems function.

CALLED BY:	INTERNAL (utility)

PASS:		parameters for ems driver
		ds	= dgroup

RETURN:		results of function
		carry always clear
		JZ will take if function was successful.

DESTROYED:	depends on function

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

EmsCallEMM	proc	near
	int	EMM_INT
	tst	ah			;test for error
EC <	ERROR_NZ	ERR_EMS						>
	ret
EmsCallEMM	endp


;==============================================================================
;
;			TASK SWITCHER SUPPORT
;
;==============================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsDeviceSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove our protective hook from the EMM.

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
		uses	es, si
		.enter
		les	di, cs:[emmLastVector]
		mov	si, offset oldEMM
		INT_OFF
		movsw	cs:
		movsw	cs:
		INT_ON
		clc
		.leave
		ret
EmsDeviceSuspend endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsDeviceUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install our protective hook into the EMM.

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
		uses	es
		.enter
		les	di, cs:[emmLastVector]
		INT_OFF
		mov	ax, offset EMMIntercept
		stosw
		mov	ax, cs
		stosw
		INT_ON
		clc
		.leave
		ret
EmsDeviceUnsuspend endp



;==============================================================================
;
;			     PROTECTORATE
;
;==============================================================================

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmsUpdateMaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update our record of what GEOS's maps look like so we can
		better protect GEOS from TSRs that use EMM.

CALLED BY:	EmsDeviceInit, EmsMapBank
PASS:		ds	= dgroup
		ds:emmMaps	= segment of block containing full and partial
				  maps
		ds:emmPartStart	= offset to start of partial map, if supported
		ds:emmMapTypes	= flags set indicating what maps are supported
				  by the EMM
		ds:emmPartMapDesc= partial-map descriptor initialized if
				   partial maps are supported
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmsUpdateMaps	proc	far	uses ax, si, es, di
		.enter
	;
	; Prevent context switches here, as an interruption that causes a
	; context switch can lead to very bad things should we have been
	; running on a low-priority thread while executing this...
	; 

		call	SwapIsKernelInMemory?
		jnc	fetchMap
		call	SysEnterCritical
fetchMap:
	;
	; Fetch the full map first, if the EMM supports it...
	;
		test	ds:[emmMapTypes], mask EMT_FULL
		jz	done
		mov	es, ds:[emmMaps]
		clr	di
		mov	ax, EMF_GET_MAP_PTR
		int	EMM_INT
		; XXX: what to do on error?
 	;
	; Now go for the partial map.
	;
		test	ds:[emmMapTypes], mask EMT_PART
		jz	done
		mov	di, ds:[emmPartStart]
		mov	si, offset emmPartMapDesc
		mov	ax, EMF_GET_PART_MAP
		int	EMM_INT
done:
	;
	; Deal with a race condition that arises between when we map the swap
	; bank in and when we get here. If something comes in that does a
	; SET_MAP, to restore the mapping context it just mangled, before we've
	; had a chance to get the new GEOS mapping context, we will think they
	; didn't restore to our context and we'll leave the system protected,
	; with unfortunate consequences (the system will freeze).
	;
	; If we're executing here, then by definition the mapping context is
	; correct for GEOS (if it's not, we've just gotten bad information and
	; will die soon for our sins), so if we're still protecting the system,
	; we're doing so in error and must unprotect before we return.
	; 
		INT_OFF
		clr	al
		xchg	al, ds:[emmProtected]
		tst	al
		jz	exit
if DEBUG_PROTECT
		call	EmmShowUnprotect
endif
		call	SwapIsKernelInMemory?
		jnc	exit
		call	SysExitCritical	; balance the extra enter done
					;  when protecting
exit:
		INT_ON
		call	SwapIsKernelInMemory?
		jnc	exit2
		call	SysExitCritical
exit2:
		.leave
		ret
EmsUpdateMaps	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMMIntercept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept routine to protect the kernel from TSRs that alter
		the page maps

CALLED BY:	int EMM_INT
PASS:		params for call
		ax	=  EMMFunctions
RETURN:		values from call
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This function exists to protect the system from TSR's that
		change the EMS mapping. Since the system expects all but
		16K of the driver's page frame to remain locked in memory
		throughout the life of the system, any change in the mapping
		of those pages could have (has had) disastrous effects should
		the kernel context-switch while the mapping has been thus
		disturbed.
		
		Any TSR that changes the mapping must, to keep the system
		operating correctly, save the current page mapping in some
		way before altering the mapping for its own purposes. If this
		intercept function detects the saving of the mapping state,
		in any of the ways the EMS spec allows, it calls
		SysEnterCritical before dispatching the call to the real
		EMM driver. This will prevent the system from context switching
		and attempting to use the memory that has temporarily been
		banked out. Similarly, when the matching state-restore is
		detected, the call is dispatched to the real driver, and
		SysExitCritical is called once that call completes.

		Note that a simple SysEnterCritical/SysExitCritical pair
		around int EMM_INT is insufficient because of the multi-
		stage nature of EMS manipulation.

		REVISED 9/23/90 IN THE FACE OF REALITY:
			EMF_GET_MAP		- always protect
			EMF_SET_MAP		- always unprotect
			EMF_SET_MAP_PTR		- unprotect if map set
						matches our current full map
						- protect if map set doesn't
						match our current full map
			EMF_XCHG_MAP_PTR	ditto
			EMF_SET_PART_MAP	- protect during the call, and
						unprotect only if partial map
						for our banks is unmolested.
			EMF_MAP_BANK		- protect if not mapping
						from our handle (XXX: look for
						mapping outside the low 4 banks
						and don't protect then?)
			EMF_MAP_MANY		- ditto
			EMF_MOVE_REGION		- protect during the call
			EMF_XCHG_REGION		- ditto
			EMF_MAP_AND_JUMP,
			EMF_MAP_AND_JUMP_SEG	- protect
			EMF_MAP_AND_CALL,
			EMF_MAP_AND_CALL_SEG	- protect during the call

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This could get into trouble (especially the SET_MAP_PTR and XCHG_MAP_PTR
	handlers) on a 4.0 board with an expanded page frame. Perhaps we
	should always compare partial map.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMMIntercept	proc	far
						CheckHack <@CurSeg eq idata>
if DEBUG_PROTECT or LOG_PROTECT
		call	EmmShowFunction
endif
		cmp	ah, high EMF_GET_MAP
		je	startProtect
		cmp	ah, high EMF_SET_MAP
		je	endProtect
		
		cmp	ax, EMF_SET_MAP_PTR
		je	checkFullSet
		cmp	ax, EMF_XCHG_MAP_PTR
		je	checkFullSet

		cmp	ax, EMF_SET_PART_MAP
		je	handlePartSet
		
		cmp	ah, high EMF_MAP_BANK
		je	handleMap
		cmp	ax, EMF_MAP_MANY
if CHECK_UTILITY_MAPPING_WINDOW
		LONG je	handleMapMany
else
		je	handleMap
endif
		
		cmp	ah, high EMF_MAP_AND_JUMP
		je	startProtect

if 0
		cmp	ax, EMF_MOVE_REGION
		je	protectDuringCall
		cmp	ax, EMF_XCHG_REGION
		je	protectDuringCall
		cmp	ax, EMF_MAP_AND_CALL
		je	protectDuringCall
		cmp	ax, EMF_MAP_AND_CALL_SEG
		jne	passItOn
protectDuringCall:
	;
	; Protect the system during the call to the real manager. This is
	; used for function calls that last a while and may alter the mapping
	; state in ways unwholesome for GEOS, but that restore the mapping
	; state when they return.
	;
		call	EMMProtect
		call	EMMCallRealDriver
		jmp	realEndProtect
endif
		
passItOn:
		call	EMMCallRealDriver
if LOG_PROTECT
   		jmp	boogie
else
		iret
endif
startProtect:
	;
	; Protect the system from a mapping change by calling SysEnterCritical
	; if the system isn't already protected.
	; 
		call	EMMProtect
		jmp	passItOn

checkFullSet:
	;
	; Handle setting the full mapping context. If the source (ds:si) doesn't
	; match GEOS's regular full map. To avoid running into problems with
	; expanded page frames under LIM 4.0, if the EMM supports partial
	; maps, we treat this as a SET_PART_MAP call instead, to make sure
	; we don't stay protected when a TSR alters the mapping for pages
	; in which we have no interest.
	;
		test	cs:[emmMapTypes], mask EMT_PART
		jnz	handlePartSet
		push	es, di, cx, si
		mov	es, cs:[emmMaps]
		clr	di
		mov	cx, cs:[emmPartStart]	; cx <- size of a full map
		repe	cmpsb
		pop	es, di, cx, si
		jne	startProtect

endProtect:
	;
	; Finish protecting the system after the EMM has been called, if
	; we're actually protecting the thing now, that is.
	; XXX: shouldn't we always be?
	;
		INT_OFF
		tst	cs:[emmProtected]
		jz	passItOn
		call	EMMCallRealDriver
realEndProtect:
	;
	; Note: we have to check emmProtected to make sure the system is
	; still protected to handle weird cases with delayed-writes, where
	; an EMF_SET_PART_MAP to restore geos' page map is interrupted
	; and some other operations are performed, which eventually leave
	; the system without need for protection. If we don't check for
	; this case, we call SysExitCritical one too many times, causing
	; all hell to break loose. -- ardeb 7/12/91
	; 
		INT_OFF
		tst	cs:[emmProtected]
		jz	rEPDone
if DEBUG_PROTECT
		call	EmmShowUnprotect
endif
		mov	cs:[emmProtected], BB_FALSE
		call	SysExitCritical
rEPDone:
if LOG_PROTECT
   		jmp	boogie
else
		iret
endif

handleMap:
	;
	; Deal with a single- or multi-bank mapping call. If mapping in
	; a bank from some handle other than GEOS's, protect the system;
	; we will presumably unprotect when the mapping is restored.
	;
	; Only do protect if the physical page being mapped into was
	; given to the heap.  We'll rely on the fact that the everything
	; in the page frame below the mapping window is given to the heap.
	;
		cmp	dx, cs:[emsSwapHandle]
if CHECK_UTILITY_MAPPING_WINDOW
		je	passJmp
		cmp	al, cs:[emsBaseBank].low
startProtectJB:
		jb	startProtect
passJmp:
else
		jne	startProtect
endif
		jmp	passItOn

handlePartSet:
	;
	; Handle a partial set map, or a full set map under a 4.0 manager.
	; We protect the system during the call, since we're not sure what
	; pages are being altered. Once the call completes, we fetch the
	; current partial map for the banks we maintain and see if they're
	; unmolested. If they're all where we left them, we can safely let
	; the system continue. If the map differs in some way, we leave
	; the system protected until our pages are restored.
	;
		call	EMMProtect
		call	EMMCallRealDriver
		push	es, di, cx, ax, ds, si
		segmov	ds, cs		; ds:si <- partial map descriptor
		mov	si, offset emmPartMapDesc

		mov	cx, ds:[emmPartSize]
		mov	ax, EMF_GET_PART_MAP
		mov	es, ds:[emmMaps]; es:di <- storage for current
		mov	di, ds:[emmPartStart]	; partial map after storage for
		add	di, cx			; GEOS's partial map
		call	EMMCallRealDriver

		mov	si, ds:[emmPartStart]	; compare with GEOS's partial...
		INT_OFF			; (avoid multi-prefix death on 8088)
		repe	es:cmpsb
		pop	es, di, cx, ax, ds, si
		je	realEndProtect
		; mapping is different -- leave system protected
if LOG_PROTECT
boogie:
		INT_OFF
   		push	bp
		mov	bp, cs:[callPrevPtr]
		mov	cs:[callLog][bp].EC_inProgress, 0
		pop	bp
endif
		iret

if CHECK_UTILITY_MAPPING_WINDOW

handleMapMany:
		cmp	dx, cs:[emsSwapHandle]
		je	passJmp
		tst	al
		jnz	mapManyPage
	;
	; mapping segments
	;
		push	ax, cx, si
checkMapSegLoop:
		mov	ax, cs:[emsSwapSeg]
		cmp	ds:[si], ax
		jb	checkMapManyDone
		add	si, (size word)
		loop	checkMapSegLoop
checkMapManyNoProtect:
		clc				; indicate no protect needed
checkMapManyDone:
		pop	ax, cx, si
		jb	startProtectJB
		jmp	passItOn

	;
	; mapping pages
	;
mapManyPage:
		push	ax, cx, si
checkMapPageLoop:
		mov	ax, cs:[emsBaseBank]
		cmp	ds:[si], ax
		jb	checkMapManyDone
		add	si, (size word)
		loop	checkMapPageLoop
		jmp	checkMapManyNoProtect

endif	; CHECK_UTILITY_MAPPING_WINDOW

EMMIntercept	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMMProtect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Protect the system from context switches if not already
		protected.

CALLED BY:	EMMIntercept
PASS:		cs	= dgroup
RETURN:		cs:[emmProtected] set true
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMMProtect	proc	near
		.enter
		INT_OFF
		tst	cs:[emmProtected]
		jnz	done
if DEBUG_PROTECT
   		call	EmmShowProtect
endif
		call	SysEnterCritical
		mov	cs:[emmProtected], BB_TRUE
done:
		INT_ON
		.leave
		ret
EMMProtect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMMCallRealDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the real EMM after storing back the bytes we overwrite.

CALLED BY:	EMMIntercept
PASS:		cs	= dgroup
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMMCallRealDriver proc	near
						CheckHack <@CurSeg eq idata>
		.enter
	;
	; Now call the driver as if via an interrupt.
	;
		pushf
		cli
		call	cs:[oldEMM]		
		.leave
		ret
EMMCallRealDriver endp

if DEBUG_PROTECT
SCREEN_SEG	equ	0xb000
SCREEN_SIZE	equ	(80*2)*25	; total # bytes in screen
SCREEN_ATTR_NORMAL	equ	07h
SCREEN_ATTR_INV		equ	70h

MonoScreen segment at SCREEN_SEG
screenBase	label	word
MonoScreen ends

curPos		fptr.word	screenBase; current location in mono screen
;;;lastUP		word	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmmShowProtect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show me that we're protecting the system

CALLED BY:	EMMProtect
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmmShowProtect	proc	near
		uses	ax
		.enter
;;;		mov	cs:[lastUP], 0

		mov	ax, (SCREEN_ATTR_INV shl 8) or 'P'
		call	EmmShowChar
		.leave
		ret
EmmShowProtect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmmShowUnprotect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show me that we're unprotecting the system

CALLED BY:	?
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmmShowUnprotect proc	near
		uses	ax
		.enter
;;;		push	bp
;;;		mov	bp, sp
;;;		mov	ax, ss:[bp+4]
;;;		pop	bp
;;;		xchg	cs:[lastUP], ax
;;;		tst	ax
;;;		jz	ok
;;;		int	3
;;;ok:
		mov	ax, (SCREEN_ATTR_INV shl 8) or 'U'
		call	EmmShowChar
		.leave
		ret
EmmShowUnprotect endp
endif

if DEBUG_PROTECT or LOG_PROTECT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmmShowFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the function being executed

CALLED BY:	EMMIntercept
PASS:		ax	= function number
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmmShowFunction	proc	near
		uses	ax, bp
		.enter
		
if LOG_PROTECT
		INT_OFF
		mov	bp, cs:[callLogPtr]
		mov	cs:[callLog][bp].EC_ax, ax
		mov	cs:[callLog][bp].EC_bx, bx
		mov	cs:[callLog][bp].EC_cx, cx
		mov	cs:[callLog][bp].EC_dx, dx
		mov	cs:[callLog][bp].EC_si, si
		mov	cs:[callLog][bp].EC_di, di
		mov	cs:[callLog][bp].EC_ds, ds
		mov	cs:[callLog][bp].EC_es, es
		mov	cs:[callLog][bp].EC_ss, ss
		mov	cs:[callLog][bp].EC_sp, sp
		mov	cs:[callLog][bp].EC_inProgress, 1

		mov	cs:[callPrevPtr], bp
		add	bp, size EmmCall
		cmp	bp, size callLog
		jb	setNext
		clr	bp
setNext:
		mov	cs:[callLogPtr], bp
		INT_ON
endif
if DEBUG_PROTECT
;;;		mov	cs:[lastUP], 0

		push	ax
		mov	ax, (SCREEN_ATTR_NORMAL shl 8) or ' '
		call	EmmShowChar
		pop	ax

		xchg	al, ah
		call	EmmShowByte
		xchg	al, ah
		call	EmmShowByte
endif		
		.leave
		ret
EmmShowFunction	endp

endif

if DEBUG_PROTECT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmmShowByte
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
	ardeb	7/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nibbles		char	"0123456789ABCDEF"
EmmShowByte	proc	near
		push	bx
		push	ax
		mov	bx, offset nibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		mov	ah, SCREEN_ATTR_NORMAL
		call	EmmShowChar
		pop	ax
		push	ax
		and	al, 0fh
		xlatb	cs:
		mov	ah, SCREEN_ATTR_NORMAL
		call	EmmShowChar

		pop	ax
		pop	bx
		.leave
		ret
EmmShowByte	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmmShowChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the passed character w/attribute up on the mono screen
		and advance the cursor

CALLED BY:	
PASS:		ah	= attribute
		al	= character
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmmShowChar	proc	near
		uses	es, di
		.enter
		les	di, cs:[curPos]
		stosw
		cmp	di, SCREEN_SIZE
		jb	setCursor
		clr	di
setCursor:
		mov	{word}es:[di], ((SCREEN_ATTR_NORMAL or 0x80) shl 8) or \
					0x7f
		mov	cs:[curPos].offset, di
		.leave
		ret
EmmShowChar	endp
endif	; DEBUG_PROTECT

idata		ends
