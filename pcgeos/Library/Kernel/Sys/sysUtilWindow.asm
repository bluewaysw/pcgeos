COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Kernel
FILE:		sysUtilWindow.asm

AUTHOR:		Brian Chin, Nov 25, 1996

ROUTINES:
	Name			Description
	----			-----------
EXT	InitUtilWindow		initial utility mapping window
GLB	SysGetUtilWindowInfo	get utility mapping window info
GLB	SysMapUtilWindow	map physical data into mapping window
GLB	SYSUNMAPUTILWINDOW	release mapping of physical data info
				mapping window (C and ASM)
GLB	SYSGETUTILWINDOWINFO	C stub for SysGetUtilWindowInfo
GLB	SYSMAPUTILWINDOW	C stub for SysMapUtilWindow

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/25/96   	Initial revision


DESCRIPTION:
		
	Code for utility mapping window.

	$Id: sysUtilWindow.asm,v 1.1 97/04/05 01:15:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if UTILITY_MAPPING_WINDOW

ifndef	_DOVEPC
_DOVEPC	equ	FALSE
endif

ifndef	_DOVEHW
_DOVEHW	equ	FALSE
endif

ifdef	GPC_ONLY
_GPCHW	equ	TRUE
else
_GPCHW	equ	FALSE
endif

;-----------------------------------------------------------------------------
;
; definitions for all versions
;
;-----------------------------------------------------------------------------

;
; element in chunk array used to track nested mappings, chunk handle of array
; stored in thread's private data
;
UtilWindowSavePageStruct	struct
	UWSPS_page	word		; logical page number
	UWSPS_window	word		; window number (0-3)
UtilWindowSavePageStruct	ends

UtilWindowPhyMemEntry	struct
	UWPME_info	UtilWinPhyMemInfo

	; Add your hardware-specific fields here.
ifdef	_GPCHW
	UWPME_xmmHandle	word		; handle of XMS block
endif	; _GPCHW

UtilWindowPhyMemEntry	ends

UtilWindowPhyMemArray	struct
	UWPMA_geode		char	GEODE_NAME_SIZE dup(?)
	UWPMA_numEntries	word
	UWPMA_entries		label	UtilWindowPhyMemEntry
UtilWindowPhyMemArray	ends

;-----------------------------------------------------------------------------
;
; definitions for DOVE EMM version
;
;-----------------------------------------------------------------------------

if _DOVEPC

;
; number of windows to provide
;
UTIL_WINDOW_NUM_WINDOWS	equ	1	; only one window for now

;
; address of direct accesss memory (lowest legal address to pass to
; SysMapUtilWindow)
;
DIRECT_MAPPING_MEMORY		equ	0x220000

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

include	Internal/emm.def

;
; mapping page size provided by utility mapping window mechanism to apps
;
DIRECT_MAPPING_PAGE_SIZE	equ	PHYSICAL_PAGE_SIZE

;
; address in main memory to map in physical memory
;
FIRST_MAPPING_WINDOW	equ	0

;
; number of DIRECT_MAPPING_PAGE_SIZE banks in EMS page frame
;
EMS_MAX_BANKS			equ	4

endif	; _DOVEPC

;-----------------------------------------------------------------------------
;
; definitions for DOVE HW version
;
;-----------------------------------------------------------------------------

if _DOVEHW

include Internal/E3G.def
include Internal/Penelope/penehw.def

;
; number of windows to provide
;
UTIL_WINDOW_NUM_WINDOWS	equ	1	; only one window for now

;
; address of direct accesss memory (lowest legal address to pass to
; SysMapUtilWindow)
;
DIRECT_MAPPING_MEMORY		equ	0x220000

;
; mapping page size provided by hardware
;
PHYSICAL_PAGE_SIZE	equ	0x4000	; 16K

;
; mapping page size provided by utility mapping window mechanism to apps
;
DIRECT_MAPPING_PAGE_SIZE	equ	PHYSICAL_PAGE_SIZE

;
; address in main memory to map in physical memory
;
FIRST_MAPPING_WINDOW	equ	0xbc00

;
; start of direct accesss memory in physical address space
;
DOVEHW_PHYSICAL_MEMORY		equ	0x220000

;
; register needed to map in memory on hardware
;
DOVEHW_MAPPING_SOURCE_REG	equ	E3G_EMST3
DOVEHW_MAPPING_DEST_REG		equ	E3G_EMSC3

endif	; _DOVEHW

;-----------------------------------------------------------------------------
;
; definitions for GPC HW version
;
;-----------------------------------------------------------------------------

if _GPCHW

.386

include	initfile.def
include	Internal/elanSC400.def

;
; number of windows to provide
;
UTIL_WINDOW_NUM_WINDOWS		equ	2

;
; address of direct accesss memory (lowest legal address to pass to
; SysMapUtilWindow)
;
DIRECT_MAPPING_MEMORY		equ	0x100000

;
; mapping page size provided by hardware (in paragraphs)
;
PHYSICAL_PAGE_SIZE	equ	0x100	; 4K

;
; mapping page size provided by utility mapping window mechanism to apps (in
; paragraphs)
;
DIRECT_MAPPING_PAGE_SIZE	equ	0x1000	; 64K

;
; address in main memory to map in physical memory
;
FIRST_MAPPING_WINDOW		equ	0xa000
FIRST_MAPPING_WINDOW_END	equ	(FIRST_MAPPING_WINDOW \
					 + DIRECT_MAPPING_PAGE_SIZE - 1)
SECOND_MAPPING_WINDOW		equ	0xb800
SECOND_MAPPING_WINDOW_END	equ	(SECOND_MAPPING_WINDOW \
					 + DIRECT_MAPPING_PAGE_SIZE - 1)

; Currently some code assumes that the window sizes are the same.
.assert FIRST_MAPPING_WINDOW_END - FIRST_MAPPING_WINDOW eq \
	SECOND_MAPPING_WINDOW_END - SECOND_MAPPING_WINDOW

endif	; _GPCHW

;-----------------------------------------------------------------------------
;
; variables for all versions
;
;-----------------------------------------------------------------------------

idata	segment

;
; number of windows provided
;
utilWindowNumWindows	word	UTIL_WINDOW_NUM_WINDOWS

;
; map of which logical pages are mapped into each of the possible windows
; (-1 indicates no page has been mapped in)
;
utilWindowMap	word	UTIL_WINDOW_MAX_NUM_WINDOWS dup (-1)

;
; segment of (first) utility window, 0 if no support for utility window
;
utilWindowSegment	word	FIRST_MAPPING_WINDOW

;
; size of each utility window (in paragraphs)
;
utilWindowSize		word	DIRECT_MAPPING_PAGE_SIZE

idata	ends


udata	segment

;
; offset in ThreadPrivateData of our private storage, holds handle of
; chunk array that tracks nested mappings
;
utilWindowDataOffset	word

;
; handle of global lmem block holding chunk arrays that track nested mappings
;
utilWindowMapBlock	word

;
; temporarily used to hold return address for utility routines that
; mess with the stack, only used while interrupts are off, so no worries
; about synchronization
;
retAddr			fptr

udata	ends

;-----------------------------------------------------------------------------
;
; variables for DOVE EMM version
;
;-----------------------------------------------------------------------------

if _DOVEPC

udata	segment

;
; EMM handle for logical pages reserved for mapping in
;
utilWindowEMMHandle	word

;
; first EMS window number to use for mapping (0-3)
;
utilWindowEMMWindow	word

udata	ends

endif	; _DOVEPC

;-----------------------------------------------------------------------------
;
; variables for GPC HW version
;
;-----------------------------------------------------------------------------

if	_GPCHW

udata	segment

;
; Info block of XMM handles for logical pages reserved for mapping in
;
utilWindowNumGeodes	word		; # of arrays in utilWindowXMMInfoBlk
utilWindowXMMInfoBlk	hptr.UtilWindowPhyMemArray

xmsAddrUW		fptr.far		; Entry point for the XMM

udata	ends

endif	; _GPCHW


;
; allow access to hardware
;
.ioenable

endif	; UTILITY_MAPPING_WINDOW

if UTILITY_MAPPING_WINDOW

kinit	segment	resource

;-----------------------------------------------------------------------------
;
; code for DOVE EMM version
;
;-----------------------------------------------------------------------------

if _DOVEPC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfEMMPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if an EMM driver is present

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if none present
DESTROYED:	ax, bx, cx, dx, di, si, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 2/94   	Scarfed from Adam's code in the swap driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
emm_device_name2	char	"EMMXXXX0"	;guaranteed name of EMM driver
CheckIfEMMPresent	proc	near	uses	es, ds
	.enter
	;
	; First make sure the driver's around. Just because we've been loaded
	; doesn't mean there's a manager around...
	; We use the device chain to locate the last EMMXXXX0 device so we
	; don't get fooled by things like Super PC-Kwik that intercept int 67h
	; for their own purposes.
	;
		mov	ah, MSDOS_GET_VERSION
		int 21h
		xchg	ax, cx
		
		mov	ah, MSDOS_GET_DOS_TABLES
		int 21h
		
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
		lea	si, emm_device_name2
					;number of bytes to compare
		mov	cx, length emm_device_name2
		repe	cmpsb
		clc
		je	haveEMM

nextDev:
		les	bx, es:[bx].DH_next
		cmp	bx, -1		; end of the line?
		jne	devLoop		; no -- keep looking
		stc
haveEMM:
	.leave
	ret
CheckIfEMMPresent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateEMSMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates EMS memory for use via utility mapping window

CALLED BY:	GLOBAL
PASS:		dx.ax - # bytes to allocate
RETURN:		dx - EMM handle
		carry set if not enough memory
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateEMSMemory	proc	near	uses	ax, bx, cx, ds, si
	bytesToAlloc	local	dword
	.enter
	movdw	bytesToAlloc, dxax

;	First, see if there already is an EMM handle owned by GEOS. If so,
;	free it and allocate a new one.

	segmov	ds, cs
	mov	si, offset hanName
	mov	ax, EMF_SEARCH
	int	EMM_INT
	tst	ah
	jnz	notFound

	mov	ah, high EMF_FREE
	int	EMM_INT
	tst	ah
	ERROR_NZ	UTIL_WINDOW_EMM_ERROR
	
notFound:

;	Re-Allocate handle 0 to have no pages on it - for some random reason,
;	EMS drivers allocate memory for handle 0, which we want to use.
;
;	DON'T DO THIS! I GOT RANDOM CRASHES AND RANDOM TRASHING OF IMAGE
;	DATA WHEN I DID THIS, SO DON'T!
;
; 	OK, we won't. Geez, Drew, take a deep breath...
;
;	mov	ax, EMF_REALLOC
;	clr	dx			;Reallocate handle 0 to 0 pages...
;	clr	bx
;	int	EMM_INT

;	Allocate an EMM handle with the correct # pages associated with it...

if 1
	push	dx
	movdw	dxax, bytesToAlloc
	adddw	dxax, DIRECT_MAPPING_PAGE_SIZE-1
	mov	bx, DIRECT_MAPPING_PAGE_SIZE
	div	bx
if	DIRECT_MAPPING_PAGE_SIZE	eq	PHYSICAL_PAGE_SIZE * 2
	shl	ax
endif
	mov_tr	bx, ax			;BX <- # pages needed to hold XIP image
	pop	dx			;DX <- EMM handle
else
	;
	; use all pages, leaving none for EMS swap driver
	;
	push	dx
	mov	ax, EMF_GET_NUM_PAGES
	int	EMM_INT			; bx = num available pages
	pop	dx
	tst	ah
	stc
	jnz	exit
	tst	bx
	jz	exit			; no pages available
endif

	mov	ax, EMF_ALLOC
	int	EMM_INT
	tst	ah			;If there is an error allocating our
	stc				; memory, return it...
	jnz	exit

	mov	ax, EMF_SET_NAME	;Set the name to the string whose ptr
	int	EMM_INT			; is still in DS:SI
	tst	ah
	ERROR_NZ	UTIL_WINDOW_EMM_ERROR

exit:
	.leave
	ret
AllocateEMSMemory	endp
hanName		char	"util map" ;No null necessary - only 8 bytes copied

endif	; _DOVEPC

;-----------------------------------------------------------------------------
;
; code for GPC HW version
;
;-----------------------------------------------------------------------------

if _GPCHW

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfRightProcessor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if we are on a SC400/410 processor.

CALLED BY:	InitUtilWindow
PASS:		nothing
RETURN:		CF clear if right processor
DESTROYED:	eax, ebx, ecx, edx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	See section 3.6 in Elan(TM)SC400 and ElanSC410 Microcontrollers
	User's Manual for a description.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/05/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
amdStr	char	VENDOR_ID_STR_AMD
.assert	size amdStr eq 3 * size dword

CheckIfRightProcessor	proc	near

	call	SysGetConfig		; al = SysConfigFlags, dl =
					;  SysProcessorType
	cmp	dl, SPT_80486
	jne	wrong
	test	al, mask SCF_COPROC
	jnz	wrong			; => has FPU, wrong processor

	;
	; Get vendor.
	;
		CheckHack <CPUIDI_VENDOR eq 0>
	xor	eax, eax		; EAX = CPUIDI_VENDOR
	cpuid

	cmp	eax, CPUIDI_VER_AND_FEATURE
	jne	wrong
	cmp	ebx, {dword} cs:amdStr[0 * size dword]
	jne	wrong
	cmp	edx, {dword} cs:amdStr[1 * size dword]
	jne	wrong
	cmp	ecx, {dword} cs:amdStr[2 * size dword]
	jne	wrong

	;
	; Get version and features.
	; EAX already set to CPUIDI_VER_AND_FEATURE from above.
	;
	; According to the SC410 User's Manual, CPUID should always return
	; CPUIDVL_MODEL equal to 0xA for "enhanced Am486 SX1 write back mode".
	; Not surprisingly, this is not true, as the SC410 on the GPC
	; sometimes starts returning 0xC after rebooting a few times.  It
	; changes back to 0xA only after power-off-on.  So, we ignore
	; CPUIDVL_MODEL and only check the other fields.
	;
	cpuid
	andnf	ax, mask CPUIDVL_TYPE or mask CPUIDVL_FAMILY
	cmp	ax, CPUIDVerLow <PT_OEM, PF_486, , >
	je	done			; => CF clear

wrong:
	stc				; wrong processor

done:
	ret
CheckIfRightProcessor	endp

endif	; ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfXMMPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if an XMM driver is present

CALLED BY:	InitUtilWindow
PASS:		ds	= dgroup
RETURN:		CF clear if present
			xmsAddrUW filled in
		CF set if not present
DESTROYED:	ax, bx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfXMMPresent	proc	near

	;
	; See if an Extended Memory Manager is present.
	;
	mov	ax, XMS_PRESENT?
	int	2fh
	cmp	al, XMS_HERE
	stc				; assume XMM not present
	jne	done			; => XMM not present

	;
	; Fetch the entry address for the thing.
	;
	mov	ax, XMS_ADDRESS?	; es:bx = addr
	int	2fh
	movdw	ds:[xmsAddrUW], esbx
EC <	call	NullES			; to avoid ec segment crash	>
	clc				; XMM present

done:
	ret
CheckIfXMMPresent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateXMSMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate XMS memory for use via utility mapping window

CALLED BY:	InitUtilWindow
PASS:		nothing
RETURN:		CF clear if okay
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateXMSMemory	proc	near
	uses	ds, es
	.enter
	pusha

	LoadVarSeg	ds, ax

	;
	; Allocate an empty info block to start with.
	;
	mov	ax, 1				; can't alloc zero
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAllocFar
	mov	ds:[utilWindowXMMInfoBlk], bx

	;
	; Go thru each init file string section and allocate.
	;
	mov	cx, cs
	mov	dx, offset utilWindowUsersKey	; cx:dx = key
	mov	ds, cx
	mov	si, offset utilWindowCategory	; ds:si = cat
	mov	bp, mask IFRF_READ_ALL
	mov	di, cs
	mov	ax, offset AXMCallback	; di:ax = CB
	clr	bx			; bx = initial info blk size
	call	InitFileEnumStringSection	; bx = final info blk size

	;
	; If there is nothing in init file, free the block.
	;
	LoadVarSeg	ds, ax
	tst_clc	bx			; size > 0?
	mov	bx, ds:[utilWindowXMMInfoBlk]
	call	MemUnlock		; flags preserved
	jnz	done			; => has users
	call	MemFree			; no users
	stc

done:
	popa
	.leave
	ret
AllocateXMSMemory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AXMCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate XMS memory for use by one geode

CALLED BY:	AllocateXMSMemory via InitFileEnumStringSection
PASS:		ds:si	= string section
		cx	= length of section
		bx	= initial info block size
RETURN:		bx	= new info block size
		dgroup:[utilWindowNumGeodes] incremented
		CF clear
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	String section must be in this format:
		PERMNAME,xxxx,xxxx,......
	where "PERMNAME" is the permanent name of the geode (GEODE_NAME_SIZE)
	and xxxx is the hex size (in paragraphs) of the block to allocate.

	No need to lock BIOS since we are the only thread at this moment.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/20/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AXMCallback	proc	far

	push	ds			; save string sptr

	LoadVarSeg	ds, ax
	inc	ds:[utilWindowNumGeodes]

	;
	; Calculate how much extra room we need for the info array.
	;
	mov_tr	ax, cx			; ax = string len
EC <	Assert	a, ax, GEODE_NAME_SIZE	; must be followed by size strings>
	sub	ax, GEODE_NAME_SIZE
	clr	dx			; dxax = length of size specifiers
	mov	bp, 1 + 4		; divide by 1 + 4 chars (always SBCS),
	div	bp			; ax = # blks for this user
EC <	Assert	e, dx, 0		; must be evenly divisible	>
	mov	bp, ax			; bp = # blks for this user
		CheckHack <size UtilWindowPhyMemEntry eq 8>
	shl	ax, 3			; ax *= size UtilWindowPhyAddrEntry
	add	ax, size UtilWindowPhyMemArray

	;
	; Expand the info block.
	;
		CheckHack <offset UWPMA_geode eq 0>
	mov	di, bx			; di = old size = UWPMA_geode offset in
					;  new entry
	add	ax, bx			; ax = new info blk size
	mov	bx, ds:[utilWindowXMMInfoBlk]
	mov	ch, mask HAF_ZERO_INIT or mask HAF_NO_ERR
	call	MemReAlloc

	;
	; Fill in new user name.
	;
	pop	ds			; ds:si = string section
	mov	es, ax			; es:di = UWPMA_geode
		CheckHack <(GEODE_NAME_SIZE and 1) eq 0>
	mov	cx, GEODE_NAME_SIZE /  2
	rep	movsw			; es:di = UWPMA_numEntries
	inc	si			; ds:si = first size
	mov	ax, bp			; ax = num entries
	stosw				; write UWPMA_numEntries, di =
					;  UWPMA_entries

nextBlk:
	;
	; Get size of XMS block.
	;
	call	ReadHexDigits		; ax = size in paras, ds:si = ','
	mov	es:[di].UWPME_info.UWPMI_paraSize, ax

	;
	; Allocate and lock an XMS block
	;
	push	ds			; save init string seg
	LoadVarSeg	ds, cx
	mov	dx, ax
	shr	dx, 6			; dx = size in K
	mov	ah, XMS_ALLOC_EMB
	call	ds:[xmsAddrUW]		; dx = handle, ax = 1 if OK
	Assert	e, ax, 1
	mov	es:[di].UWPME_xmmHandle, dx
	mov	ah, XMS_LOCK_EMB
	call	ds:[xmsAddrUW]		; dxbx = linear addr, ax = 1 if OK
	Assert	e, ax, 1
	movdw	es:[di].UWPME_info.UWPMI_addr, dxbx

	;
	; More to allocate?
	;
	add	di, size UtilWindowPhyMemEntry
	pop	ds			; ds = init string seg
	inc	si			; skip comma (if any), ds:si = next
					;  size str
	dec	bp
	jnz	nextBlk

	;
	; Return new info block size
	;
	mov	bx, di			; bx = new size
	clc				; continue

	ret	
AXMCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadHexDigits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert four hex digits to an integer value

CALLED BY:	AXMCallback
PASS:		ds:si	= four hex digits, always SBCS
RETURN:		ax	= value of hex digits
		ds:si	= point to char after size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/20/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadHexDigits	proc	near
	uses	dx, cx
	.enter

	clr	dx			; init value
	mov	cx, 4			; 4 digits

next:
	lodsb
	sub	al, '0'
	cmp	al, 0x9
	jbe	hasDigitValue
	sub	al, 'A' - '0' - 0xA
hasDigitValue:
	shl	dx, 4
	ornf	dl, al
	loop	next

	mov_tr	ax, dx

	.leave
	ret
ReadHexDigits	endp

endif	; _GPCHW

;-----------------------------------------------------------------------------
;
; code for all versions
;
;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitUtilWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup utility mapping window, if any.

CALLED BY:	INTERNAL
			InitSys
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitUtilWindow	proc	far
	uses	ax, bx, cx, dx, si, ds
	.enter

if _DOVEPC
	;
	; check if running EMM
	;
	call	CheckIfEMMPresent
	LONG jc	noWindow
	;
	; allocated requested amount of space
	;
	segmov	ds, cs, cx
	mov	si, offset utilWindowCategory
	mov	dx, offset utilWindowSizeKey
	call	InitFileReadInteger		; ax = size in K
	jc	noWindow			; not found, no util window
	clr	dh
	mov	dl, ah
	mov	ah, al
	clr	al
	shldw	dxax
	shldw	dxax				; dxax = bytes
	call	AllocateEMSMemory		; dx = EMM handle
	jc	noWindow
	LoadVarSeg	ds, ax
	mov	ds:[utilWindowEMMHandle], dx
	;
	; get number of windows
	;
	mov	ds, cx				; ds:si = category
	mov	dx, offset utilWindowNumKey	; cx:dx = key
	call	InitFileReadInteger
	LoadVarSeg	ds, bx
	jc	noNum				; just use default (= 1)
	cmp	ax, UTIL_WINDOW_MAX_NUM_WINDOWS
	jbe	goodNum
	mov	ax, UTIL_WINDOW_MAX_NUM_WINDOWS	; else, use max
goodNum:
	mov	ds:[utilWindowNumWindows], ax
noNum:
	;
	; get page frame, using highest possible bank(s)
	;
	mov	ah, high EMF_GET_PAGE_FRAME
	int	EMM_INT				; bx = segment
	tst	ah
	jnz	noWindow
	mov	cx, UTIL_WINDOW_MAX_NUM_WINDOWS
	sub	cx, ds:[utilWindowNumWindows]
	mov	ds:[utilWindowEMMWindow], cx		; save first window
	mov	ax, DIRECT_MAPPING_PAGE_SIZE shr 4
	mul	cx				; ax = offset of window
	add	bx, ax
	mov	ds:[utilWindowSegment], bx
endif	; _DOVEPC

if _GPCHW
	;
	; See if it is enabled in .INI file.
	;
	clr	ax			; default = FALSE
	mov	cx, cs
	mov	dx, offset utilWindowEnabledKey
	mov	ds, cx
	mov	si, offset utilWindowCategory
	call	InitFileReadBoolean
	LoadVarSeg	ds, cx
	mov_tr	cx, ax			; cx = TRUE if enabled
	jcxz	toNoWindow

if	ERROR_CHECK
	;
	; Check if right processor.
	;
	call	CheckIfRightProcessor	; CF clear if right
	Assert	carryClear
endif	; ERROR_CHECK

	;
	; check if running XMM.
	;
	call	CheckIfXMMPresent
	jc	toNoWindow

	;
	; Allocated requested amount of space.
	;
	call	AllocateXMSMemory
	jnc	hasWindow
toNoWindow:
	jmp	noWindow
hasWindow:

	;
	; Set up those hardware registes that don't change as mapping
	; switches around.  Also, disable the windows as default.
	;
		CheckHack <SC400_PC_CARD_CTRL_INDEX + 1 eq \
			SC400_PC_CARD_CTRL_DATA>

	;
	; Enable PC card controller.
	;
	mov	al, SC400_INTERNAL_IO_ENABLE
	out	SC400_CHIP_INDEX, al
	in	al, SC400_CHIP_DATA	; al = SC400InternalIOEnable
	BitSet	al, SIIE_PCC_ENB
	out	SC400_CHIP_DATA, al

	;
	; Set PC card to standard mode.
	;
	mov	al, SC400_PC_CARD_MODE_AND_DMA_CTRL
	out	SC400_CHIP_INDEX, al
	in	al, SC400_CHIP_DATA	; al = SC400PCCardModeAndDMACtrl
	BitClr	al, SPCMADC_MODE
	out	SC400_CHIP_DATA, al

	;
	; Disable the windows as default.  (Need to do this just in case
	; GEOS crashed after mapping was enabled, and then GEOS is restarted
	; without cold-booting the machine.)
	;
	mov	dx, SC400_PC_CARD_CTRL_INDEX
	mov	al, SC400_SOCKET_B_ADDR_WIN_ENABLE
	out	dx, al
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	in	al, dx			; al = SC400SocketAddrWinEnable
	andnf	al, not (mask SSAWE_MEM_WIN_EN1 or mask SSAWE_MEM_WIN_EN2)
	out	dx, al

	;
	; Make the windows point to DRAM.
	;
	mov	al, SC400_MMS30_DEVICE_SELECT
	out	SC400_CHIP_INDEX, al
	in	al, SC400_CHIP_DATA	; al = SC400MMS30DeviceSelect
	andnf	al, not (mask SM30DS_MMSD_DEVICE or mask SM30DS_MMSC_DEVICE)
	ornf	al, SC400MMS30DeviceSelect <, , MMSD_DRAM, MMSD_DRAM>
	out	SC400_CHIP_DATA, al

	;
	; BIOS turns on write-protect for SC410 linear address 0xC0000-0xCFFFF
	; to protect VIDEO BIOS at 0xC0000-0xC7FFF, but we need to use this
	; range for window #1.  So we need to turn off the write-protect.
	;
	; Also, we need to clear the SR0A_CSEG_CACHE_EN bit set by BIOS,
	; even though the MMSD_CACHE_EN bit is already clear.  Otherwise,
	; stale data remains in the cache when MMS Win D is switched on or off.
	; We're supposed to execute INVD after clearing the bit, but we can't
	; because INVD causes General Protection Fault in V86 mode.  We're
	; pretty safe, however, as the window won't be used until a long time
	; later when all the stale data are probably flushed already.
	;
	; The side effect of turning off this cache bit is that video BIOS
	; will slow down, but that should be okay since our video driver does
	; most of the things without using video BIOS anyway.
	;
		.assert (SECOND_MAPPING_WINDOW le 0xCFFF) and \
			(SECOND_MAPPING_WINDOW_END ge 0xC000)
	mov	al, SC400_ROM0_ATTRIBUTE
	out	SC400_CHIP_INDEX, al
	in	al, SC400_CHIP_DATA	; al = SC400ROM0Attribute
	andnf	al, not (mask SR0A_CSEG_CACHE_EN or mask SR0A_CSEG_WP)
	out	SC400_CHIP_DATA, al

	;
	; Set up start and stop addresses of windows.
	;
	mov	bx, (SC400_SOCKET_B_MEM_WIN_1_START_ADDR_LO shl 8) \
			or ((FIRST_MAPPING_WINDOW shl 4) shr 12)
					; bh = first start addr low reg index,
					;  bl = first start addr low
winLoop:
	; MMS start addr low
	mov	dx, SC400_PC_CARD_CTRL_INDEX
	mov	al, bh			; al = start addr low reg index
	out	dx, al
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	mov	al, bl			; al = start addr low
	out	dx, al

	; MMS start addr high
	inc	bh			; bh = start addr high reg index
	dec	dx			; dx = SC400_PC_CARD_CTRL_INDEX
	mov	al, bh			; al = start addr high reg index
	out	dx, al
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	mov	al, SC400SocketMemWinStartAddrHi <1, 0, 0> ; 16-bit data path
	out	dx, al

	; MMS stop addr low
	add	bl, ((FIRST_MAPPING_WINDOW_END shl 4) shr 12) \
			- ((FIRST_MAPPING_WINDOW shl 4) shr 12)
	inc	bh			; bh = stop addr low reg index
	dec	dx			; dx = SC400_PC_CARD_CTRL_INDEX
	mov	al, bh			; al = stop addr low reg index
	out	dx, al
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	mov	al, bl			; al = stop addr low
	out	dx, al

	; MMS stop addr high
	inc	bh			; bh = stop addr high reg index
	dec	dx			; dx = SC400_PC_CARD_CTRL_INDEX
	mov	al, bh			; al = stop addr high reg index
	out	dx, al
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	mov	al, SC400SocketMemWinStopAddrHi <0, 0>
	out	dx, al

	add	bx, (SC400_SOCKET_B_MEM_WIN_2_START_ADDR_LO \
			- SC400_SOCKET_B_MEM_WIN_1_STOP_ADDR_HI) shl 8 \
			or \
			(((SECOND_MAPPING_WINDOW shl 4) shr 12) \
			- ((FIRST_MAPPING_WINDOW_END shl 4) shr 12))
					; bh = next start addr low reg index,
					;  bl = next start addr low
	cmp	bh, SC400_SOCKET_B_MEM_WIN_2_START_ADDR_LO
	jbe	winLoop

endif	; _GPCHW

	;
	; allocate space in ThreadPrivateData to track nested mappings
	;
	LoadVarSeg	ds, ax
	mov	cx, 1				; need one word
	mov	bx, 1				; indicate owned by kernel
						; (must be non-zero)
	call	ThreadPrivAlloc			; bx = offset
	mov	ds:[utilWindowDataOffset], bx	; save offset
	jnc	done				; success
noWindow::
	mov	ds:[utilWindowSegment], 0	; else, no mapping window
done:
	;
	; allocate global lmem block to track nested mappings
	;
	tst	ds:[utilWindowSegment]
	jz	exit
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem
	mov	ax, mask HF_SHARABLE		; set sharable, clear none
	call	MemModifyFlags
	mov	ds:[utilWindowMapBlock], bx
exit:

	.leave
	ret
InitUtilWindow	endp

if _DOVEPC
utilWindowCategory	char	"utilWindow", 0
utilWindowSizeKey	char	"size", 0
utilWindowNumKey	char	"numWindows", 0
endif	; _DOVEPC

if _GPCHW
utilWindowCategory	char	"utilWindow", 0
utilWindowEnabledKey	char	"enabled", 0
utilWindowUsersKey	char	"users", 0
endif	; _GPCHW

kinit	ends

endif	; UTILITY_MAPPING_WINDOW


UtilWindowCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysGetUtilWindowInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get info about utility mapping window

CALLED BY:	GLOBAL
PASS:		dx:bp	= UtilWinInfo array of UTIL_WINDOW_MAX_NUM_WINDOWS
			  entries
		ds:si	= permanent name of geode (GEODE_NAME_SIZE chars)
RETURN:		ax	= TRUE if mapping window supported
		dx:bp	= buffer filled
		^hbx	= block of UtilWinPhyMemInfoBlk entries for this
			  geode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysGetUtilWindowInfo	proc	far

if UTILITY_MAPPING_WINDOW

	uses	cx, dx, si, di, bp, ds, es
	.enter

	movdw	esdi, dssi		; es:di = permanent name

	;
	; get mapping window
	;
	LoadVarSeg	ds, ax
	mov	ax, ds:[utilWindowSegment]
	tst	ax
	jz	done				; no mapping window

EC <	add	bp, size UtilWinInfo * UTIL_WINDOW_MAX_NUM_WINDOWS - 1	>
EC <	Assert	fptr, dxbp						>
EC <	sub	bp, size UtilWinInfo * UTIL_WINDOW_MAX_NUM_WINDOWS - 1	>

if	_GPCHW

	push	ds			; save dgroup
	movdw	dssi, dxbp		; dx:bp = UtilWinInfo array, use si to
					;  avoid segment override
	mov	ax, DIRECT_MAPPING_PAGE_SIZE
	mov	ds:[si + 0 * size UtilWinInfo].UWI_addr, FIRST_MAPPING_WINDOW
	mov	ds:[si + 0 * size UtilWinInfo].UWI_paraSize, ax
	mov	ds:[si + 1 * size UtilWinInfo].UWI_addr, SECOND_MAPPING_WINDOW
	mov	ds:[si + 1 * size UtilWinInfo].UWI_paraSize, ax
	clr	ax
	mov	ds:[si + 2 * size UtilWinInfo].UWI_addr, ax
	mov	ds:[si + 3 * size UtilWinInfo].UWI_addr, ax
	pop	ds			; ds = dgroup

	;
	; Look for the UtilWindowPhyMemArray for this geode
	;
	mov	dx, ds:[utilWindowNumGeodes]
	mov	bx, ds:[utilWindowXMMInfoBlk]
	call	MemLock
	mov	ds, ax
	clr	si			; ds:si = 1st UtilWindowPhyMemArray

nextGeode:
	;
	; See if permanent name matches this entry
	;
		CheckHack <offset UWPMA_geode eq 0>
	push	si, di
		CheckHack <(GEODE_NAME_SIZE and 1) eq 0>
	mov	cx, GEODE_NAME_SIZE /  2
	repe	cmpsw
	pop	si, di
	je	found

	;
	; Not match.  Go to next entry.
	;
	mov	bx, ds:[si].UWPMA_numEntries
		CheckHack <size UtilWindowPhyMemEntry eq 8>
	shl	bx, 3			; bx *= size UtilWindowPhyAddrEntry
	lea	si, ds:[si].UWPMA_entries[bx]
					; ds:si = next UtilWindowPhyMemArray
	dec	dx
	jnz	nextGeode

	;
	; Geode not found.
	;
	clr	bx			; no info for this geode
	jmp	unlockInfoBlk

found:
	;
	; Geode found.  Alloc a block to return the info.
	;
	mov	bp, ds:[si].UWPMA_numEntries
	mov	ax, size UtilWinPhyMemInfo
	mul	bp			; ax = size of entries
	add	ax, size UtilWinPhyMemInfoBlk	; add header size
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	mov	es, ax
	mov	es:[UWPMIB_count], bp
	mov	di, offset UWPMIB_info	; es:di = 1st UtilWinPhyMemInfo
	add	si, offset UWPMA_entries	; ds:si = 1st UWPME

copyNextEntry:
	;
	; Copy all the UWPAE entries
	;
		CheckHack <(size UtilWinPhyMemInfo and 1) eq 0>
	mov	cx, size UtilWinPhyMemInfo / 2
	rep	movsw			; es:di = next UtilWinPhyMemInfo
	add	si, size UtilWindowPhyMemEntry - (offset UWPME_info \
			+ size UWPME_info)	; ds:si = next UWPME
	dec	bp
	jnz	copyNextEntry

	call	MemUnlock		; unlock return info blk

unlockInfoBlk:
	push	bx			; save return blk handle
	LoadVarSeg	ds, ax
	mov	bx, ds:[utilWindowXMMInfoBlk]
	call	MemUnlock
	pop	bx			; bx = return blk handle

	mov	ax, TRUE		; supported

endif	; _GPCHW

done:
	.leave

else

	mov	ax, FALSE

endif

	ret
SysGetUtilWindowInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysMapUtilWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map physical address into mapping window

CALLED BY:	GLOBAL
PASS:		dxbp = physical address to map in
		ax = window number to use
RETURN:		ax = number of paragraphs mapped in (i.e. size of window -
						offset into window where
						passed physical address
						begins)
		dx:bp = beginning of physical data in map window
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysMapUtilWindow	proc	far

if UTILITY_MAPPING_WINDOW

	uses	bx, cx, si, di, ds
	.enter
	;
	; some checking
	;
	LoadVarSeg	ds, bx
	cmp	ax, ds:[utilWindowNumWindows]
EC <	ERROR_AE	UTIL_WINDOW_BAD_WINDOW_NUMBER			>
NEC <	LONG jae	error						>
	tst	ds:[utilWindowSegment]
	LONG jz	error
	;
	; save current mapping info
	;
	mov	si, ax				; si = desired window
	shl	si, 1				; si = table offset
	push	ds:[utilWindowMap][si]		; save logical page in window
	;
	; convert physical address to logical page number
	;
	push	ax				; save window number
	movdw	bxcx, DIRECT_MAPPING_MEMORY	; bxcx = start of
						;	direct mapping memory
	subdw	dxbp, bxcx			; dxbp = ext. mem offset
EC <	ERROR_S	UTIL_WINDOW_BAD_ADDRESS					>
NEC <	LONG js	errorPopPop						>
	mov	ax, bp				; dxax = ext. mem offset
		; only physical page sizes smaller than 64K are supported.
		.assert PHYSICAL_PAGE_SIZE lt 65536 shr 4
	mov	bx, PHYSICAL_PAGE_SIZE shl 4
	div	bx				; ax = logical page number
						; dx = offset in logical page
	;
	; map logical page in
	;	ax = logical page number
	;	dx = offset in page
	;	(updates utilWindowMap)
	;
	mov	bp, dx				; bp = offset in page
	mov	bx, ax				; bx = logical page number
	pop	ax				; ax = window number

	call	MapUtilityWindow
	jc	errorPop			; couldn't map
	;
	; mapped successfully, save previous mapping
	;	ax = window number
	;	(on stack) previous logical page in this window
	;
	push	bp				; save offset in page
	push	ax				; save window number
	mov	bp, ds:[utilWindowDataOffset]	; ss:bp = list array handle
	mov	bx, ds:[utilWindowMapBlock]	; bx = map block
	call	MemPLock
	mov	ds, ax
	mov	si, ss:[bp]			; *ds:si = chunk array for
						;	this thread
	tst	si
	jnz	haveArray
	push	bx				; save map block
	mov	bx, size UtilWindowSavePageStruct
	clr	cx, si, ax
	call	ChunkArrayCreate		; *ds:si = chunk array
	pop	bx				; bx = map block
	mov	ss:[bp], si			; save handle
haveArray:
	call	ChunkArrayAppend		; ds:di = new element
	pop	ax				; ax = window number
	mov	ds:[di].UWSPS_window, ax	; save window number
	pop	bp				; bp = offset in page
	pop	ds:[di].UWSPS_page		; save page number
	call	MemUnlockV
	;
	; return info
	;	dx:bp = addr in page
	;

	LoadVarSeg	ds, dx
if	_GPCHW
	; GPC hardware has non-contiguous windows
	mov	dx, FIRST_MAPPING_WINDOW
	tst	ax
	jz	hasSeg				; => win 0
		CheckHack <(FIRST_MAPPING_WINDOW and 0xFF) \
			eq (SECOND_MAPPING_WINDOW and 0xFF)>
	mov	dh, SECOND_MAPPING_WINDOW shr 8	; dx = 2nd win seg
hasSeg:
else
	mov	dx, ds:[utilWindowSize]		; dx = size in paras
	mul	dx				; ax = # paras between this win
						;  and win 0
	mov_tr	dx, ax				; dx = # paras
	add	dx, ds:[utilWindowSegment]	; dx = segment of mapped memory
endif	; _GPCHW
	mov	ax, ds:[utilWindowSize]		; ax = total paras mapped
	mov	bx, bp				; bx = offset in page
	shr	bx, 4
	sub	ax, bx				; ax = paras requested
	;
	; adjust offset to 0-15
	;
	add	dx, bx
	andnf	bp, 0x000f			; dx:bp = address
done:
	.leave
	ret

NEC <errorPopPop:							>
NEC <	pop	ax				; throw away window number>
errorPop:
	pop	ax				; throw away previous page
error:
	mov	ax, 0				; indicate nothing mapped
	jmp	short done

else

	mov	ax, 0
	ret

endif	; UTILITY_MAPPING_WINDOW

SysMapUtilWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SYSUNMAPUTILWINDOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	release current mapping of physical data into map window

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax = non-zero if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We free the chunk array if we've unmapped the last one so
		that we don't need to do anything when a thread exits -- as
		long as map/unmaps are balanced when a thread exits, it won't
		have an array in the map block.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SYSUNMAPUTILWINDOW	proc	far

if UTILITY_MAPPING_WINDOW

	uses	bx, cx, dx, di, si, bp, ds
	.enter
	;
	; release currently mapped page and restore previously mapped page
	; for this window
	;
	LoadVarSeg	ds, ax
	mov	bp, ds:[utilWindowDataOffset]
	mov	si, ss:[bp]			; si = chunk array for
						;	this thread
EC <	tst	si							>
EC <	ERROR_Z	UTIL_WINDOW_UNMATCHED_UNMAP				>
NEC <	tst	si							>
NEC <	stc					; error if unmatched	>
NEC <	jz	done							>
	mov	bx, ds:[utilWindowMapBlock]
	call	MemPLock
	mov	ds, ax				; *ds:si = chunk array

	mov	ax, CA_LAST_ELEMENT
	call	ChunkArrayElementToPtr		; ds:di = last one, CF always
						;  set (because we're passing
						;  CA_LAST_ELEMENT)
	mov	ax, ds:[di].UWSPS_window	; ax = window number
	mov	dx, ds:[di].UWSPS_page		; dx = logical page in window
	call	ChunkArrayDelete		; free it
	call	ChunkArrayGetCount		; anything left?
	tst	cx
	jnz	finishMap
	;
	; no more nested mappings, free list
	;
	push	ax				; save window number
	mov	ax, si				; *ds:ax = empty chunk array
	call	LMemFree			; free it
	pop	ax				; ax = window number
	mov	{word}ss:[bp], 0		; clear list handle
finishMap:
	call	MemUnlockV
	mov	bx, dx				; bx = page number
if not _GPCHW
	cmp	bx, -1				; anything mapped previously?
	je	done				; nope (carry clear)
endif	; not _GPCHW
	call	MapUtilityWindow		; carry clear if success

done::
	mov	ax, 0				; assume good (saves flags)
	jnc	exit
	dec	ax				; indicate error
exit:
	.leave

endif	; UTILITY_MAPPING_WINDOW

	ret

if UTILITY_MAPPING_WINDOW

if 0	; Where was this used?
NEC <mismatchNest:							>
NEC <	call	MemUnlockV						>
NEC <	stc								>
NEC <	jmp	exit							>
endif

endif

SYSUNMAPUTILWINDOW	endp

;-----------------------------------------------------------------------------
;
; C stubs
;
;-----------------------------------------------------------------------------

SetGeosConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysGetUtilWindowInfo

C DECLARATION:	extern Boolean
			_far _pascal SysGetUtilWindowInfo(
				UtilWinInfo info[UTIL_WINDOW_MAX_NUM_WINDOWS],
				char permName[GEODE_NAME_SIZE],
				MemHandle *phyMemInfoBlk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/20/96	Initial version

------------------------------------------------------------------------------@
SYSGETUTILWINDOWINFO	proc	far	info:fptr.UtilWinInfo,
					permName:fptr.char,
					phyMemInfoBlk:fptr.hptr.UtilWinPhyMemInfoBlk
	uses	si, ds
	.enter

	push	bp
	lds	si, ss:[permName]
	mov	dx, ss:[info].segment
	mov	bp, ss:[info].offset	; dx:bp = UtilWinInfo array
	call	SysGetUtilWindowInfo	; ax = TRUE
	pop	bp
	lds	si, ss:[phyMemInfoBlk]
	mov	ds:[si], bx

	.leave
	ret
SYSGETUTILWINDOWINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	SysMapUtilWindow

C DECLARATION:	extern word
			_far _pascal SysMapUtilWindow(fptr physicalAddress,
							fptr *windowAddress,
							word windowNumber);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/20/96	Initial version

------------------------------------------------------------------------------@
SYSMAPUTILWINDOW	proc	far	physicalAddress:fptr,
					windowAddress:fptr.fptr,
					windowNumber:word
	uses	ds, si, di
	.enter
	mov	ax, windowNumber
	push	bp				; save params
	mov	dx, physicalAddress.high
	mov	bp, physicalAddress.low
	call	SysMapUtilWindow		; ax = # paras
						; dx:bp = mapped data
	mov	di, bp				; dx:si = mapped data
	pop	bp				; restore params
	lds	si, windowAddress
	movdw	ds:[si], dxdi
	.leave
	ret
SYSMAPUTILWINDOW	endp

SetDefaultConvention

;-----------------------------------------------------------------------------
;
; Utility routines
;
;-----------------------------------------------------------------------------

if UTILITY_MAPPING_WINDOW


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilWindowThreadCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize our private data

CALLED BY:	EXTERNAL
			ThreadCreate
PASS:		es - segment of thread's ThreadPrivateData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment

UtilWindowThreadCreate	proc	far
	uses	ax, ds, di
	.enter
	LoadVarSeg	ds, ax
	mov	di, ds:[utilWindowDataOffset]
	mov	{word}es:[di], 0		; initialize mapping list array
	.leave
	ret
UtilWindowThreadCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilWindowInitSavedMapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize state of utility mapping windows for thread

CALLED BY:	EXTERNAL
			CreateThreadCommon
PASS:		ds:di = ThreadBlockState
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilWindowInitSavedMapping	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
.assert (UTIL_WINDOW_MAX_NUM_WINDOWS eq 4)
	mov	ds:[di].TBS_utilWindow[0*(size word)], -1
	mov	ds:[di].TBS_utilWindow[1*(size word)], -1
	mov	ds:[di].TBS_utilWindow[2*(size word)], -1
	mov	ds:[di].TBS_utilWindow[3*(size word)], -1
	.leave
	ret
UtilWindowInitSavedMapping	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilWindowSaveMapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save current utility mapping windows on stack

CALLED BY:	EXTERNAL
			BlockOnLongQueue
			BlockAndDispatchSI
			WaitForRemoteCall
PASS:		ds = kdata
		interrupts off
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	utility mapping window left on stack

PSEUDO CODE/STRATEGY:
		We mess with the return address a bit to allow
		pushing stuff on the stack
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilWindowSaveMapping	proc	far
	popdw	ds:[retAddr]		; get return address
.assert (UTIL_WINDOW_MAX_NUM_WINDOWS eq 4)
	push	ds:[utilWindowMap][0*(size word)]
	push	ds:[utilWindowMap][1*(size word)]
	push	ds:[utilWindowMap][2*(size word)]
	push	ds:[utilWindowMap][3*(size word)]
	jmp	ds:[retAddr]		; return

UtilWindowSaveMapping	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilWindowRestoreMapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore utility mapping windows for this thread

CALLED BY:	EXTERNAL
			DispatchSI
PASS:		ds = kdata
		interrupts off
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilWindowRestoreMapping	proc	far
	popdw	ds:[retAddr]		; get return address
.assert (UTIL_WINDOW_MAX_NUM_WINDOWS eq 4)
	pop	ds:[utilWindowMap][3*(size word)]
	pop	ds:[utilWindowMap][2*(size word)]
	pop	ds:[utilWindowMap][1*(size word)]
	pop	ds:[utilWindowMap][0*(size word)]
	call	RestoreMappingWindows
	jmp	ds:[retAddr]

UtilWindowRestoreMapping	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreMappingWindows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore state of utility mapping windows

CALLED BY:	INTERNAL
			UtilWindowRestoreMapping
PASS:		ds = kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreMappingWindows	proc	far
	uses	ax, bx, cx, dx, si
	.enter
	mov	cx, ds:[utilWindowNumWindows]
	clr	si				; map offset
	clr	ax				; window number
restoreLoop:
	mov	bx, ds:[utilWindowMap][si]	; bx = page
if not _GPCHW
	cmp	bx, -1				; not mapped?
	je	nextWindow			; yes
endif	; not _GPCHW
	call	MapUtilityWindow		; must ignore errors
nextWindow::
	add	si, size word			; next map item
	inc	ax				; next window
	loop	restoreLoop
	.leave
	ret
RestoreMappingWindows	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapUtilityWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map in window and update table

CALLED BY:	INTERNAL
			SysMapUtilWindow
			SysUnmapUtilWindow
			RestoreMappingWindows
PASS:		bx = page number
		ax = window number
RETURN:		carry clear if success
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We map the page and update the map without interruption
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapUtilityWindow	proc	far

;----------------------------------------------------------------------------
;
; MapUtilityWindow for DOVE HW
;
;----------------------------------------------------------------------------

if _DOVEHW
	uses	ax, bx, dx, ds
	.enter
	;
	; update map, we do this first so if we context switch away before
	; mapping in the page, the thread switching code will restore the page
	; for us (its okay that we map it again), no need for turning off
	; interrupts or context switches
	;	bx = page number
	;
	LoadVarSeg	ds, dx
	xchg	bx, ax				; ax = page number
						; bx = window number
	shl	bx, 1				; map contains words
	mov	ds:[utilWindowMap][bx], ax	; store cur page for window
	;
	; convert desired 0-based page to physical memory page
	;
if (DIRECT_MAPPING_PAGE_SIZE eq PHYSICAL_PAGE_SIZE)
	add	ax, DOVEHW_PHYSICAL_MEMORY/PHYSICAL_PAGE_SIZE
else
	PrintMessage<Write code to convert page number>
endif
	;
	; map in page
	;
	mov	dx, DOVEHW_MAPPING_SOURCE_REG
	out	dx, ax
	.leave
	ret

;----------------------------------------------------------------------------
;
; MapUtilityWindow for DOVE EMM
;
;----------------------------------------------------------------------------

elseif _DOVEPC

	uses	ax, bx, dx, ds
	.enter

	LoadVarSeg	ds, dx
;	pushf					; save interrupt state
;	INT_OFF					; turn them off for this op
;this seems to cause problems
	call	SysEnterCritical
	;
	; convert non-contiguous DOVE memory into continguous EMM memory
	;	page 0 = 220000h
	;	top of direct RAM = 250000h
	;	start of direct ROM = 3ed0000h
	;	end of direct ROM = 4000000h
	;
	cmp	bx, 250000h/16384		; top of direct access RAM
	jbe	havePage
	sub	bx, (3ed0000h-250000h)/16384	; beginning of direct access
						;	ROM
	js	error				; signed value enough to hold
						;	all pages
havePage:
	;
	; map in page
	;
	add	ax, ds:[utilWindowEMMWindow]	; get absolute window number
EC <	tst	ah							>
EC <	ERROR_NZ	UTIL_WINDOW_EMM_ERROR				>
	ornf	ax, EMF_MAP_BANK		; ah = cmd, al = window #
	mov	dx, ds:[utilWindowEMMHandle]	; dx = EMM handle
	int	EMM_INT
	tst	ah
	jnz	error				; error, no map update
	;
	; update map
	;
	mov	dx, bx				; dx = page number
	clr	bx
	mov	bl, al				; bx = window map offset
	sub	bx, ds:[utilWindowEMMWindow]	; make 0-based
	shl	bx, 1				; map contains words
	mov	ds:[utilWindowMap][bx], dx	; store cur page for window
;	call	SafePopf			; restore interrupts
	call	SysExitCritical
	clc					; indicate success
done:
	.leave
	ret

error:
;	call	SafePopf
	call	SysExitCritical
	stc
	jmp	done

;----------------------------------------------------------------------------
;
; MapUtilityWindow for GPC HW
;
;----------------------------------------------------------------------------

elseif _GPCHW
	uses	ds
	.enter

		CheckHack <SC400_PC_CARD_CTRL_INDEX + 1 eq \
			SC400_PC_CARD_CTRL_DATA>

	LoadVarSeg	ds

	tst	ds:[utilWindowSegment]
	stc
	jz	done			; => error

	pusha				; preserve regs

	call	SysEnterCritical	; prevents us from being preempted by
					;  other threads that use the index
					;  regs

	;
	; Update map.
	;
	mov	cx, ax			; cx = cl = win #
	mov_tr	si, ax			; si = win #
	shl	si			; si = word offset into array
	mov	ds:[utilWindowMap][si], bx	; store cur page for window

	mov	di, mask SSAWE_MEM_WIN_EN1
	shl	di, cl			; di.low = SC400SocketAddrWinEnable bit
					;  to turn on/off.

	cmp	bx, -1			; no mapping?
	jz	turnOff			; => yes

	;
	; Calculate the offset from CPU linear addr of mapping window to
	; physical DRAM addr of the XMS block.
	;
	; On the GPC hardware, phisical DRAM addr of the XMS block happens to
	; be the same as CPU linear addr of the XMS block (which is
	; returned by XMS_LOCK_EMB).  So we just calculate the offset from CPU
	; linear addr of mapping window to CPU linear addr of the XMS block.
	;
	mov	ax, SECOND_MAPPING_WINDOW - FIRST_MAPPING_WINDOW
					; ax = dist. btw windows (paras)
	mul	cx			; ax = dist. btw this win and win 0
	Assert	carryClear
	add	ax, FIRST_MAPPING_WINDOW	; ax = start seg of this win
		; Make sure "8" is the correct number of right-shifts to
		;  convert segments (paragraphs) to logical page #s.
		CheckHack <((PHYSICAL_PAGE_SIZE shl 4) / 16) eq (1 shl 8)>
	shr	ax, 8			; ax = # physical pages btw start of
					;  win and 0:0
	add	bx, DIRECT_MAPPING_MEMORY / (PHYSICAL_PAGE_SIZE shl 4)
					; bx = # physical pages btw start of
					;  requested physical mem and 0:0
	sub	bx, ax			; bx = desired offset (in # pages).
					; bx is still correct even if carry or
					;  borrow occured during ADD or SUB
	mov	si, bx			; si = offset to write to MMS reg

	;
	; Write to the MMS offset regs
	;
	mov	al, SC400_SOCKET_B_MEM_WIN_2_ADDR_OFFSET_LO \
			- SC400_SOCKET_B_MEM_WIN_1_ADDR_OFFSET_LO
	mul	cl			; al *= window #
	add	al, SC400_SOCKET_B_MEM_WIN_1_ADDR_OFFSET_LO
					; al = addr offset low reg of this win

	mov	dx, SC400_PC_CARD_CTRL_INDEX
	out	dx, al			; write offset-low reg index
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	mov_tr	bx, ax			; bl = offset-low reg index
	mov	ax, si			; ax = offset to write to MMS reg
	out	dx, al			; write offset-low reg

	dec	dx			; dx = SC400_PC_CARD_CTRL_INDEX
	xchg	ax, bx			; al = offset-low reg index, bh =
					;  off[25-20]
	inc	ax			; al = offset-high reg index
	out	dx, ax
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	mov	al, bh			; al = off[25-20]
	out	dx, al			; write offset-high reg

	;
	; Turn on this mapping window.
	;
	mov	dx, SC400_PC_CARD_CTRL_INDEX
	mov	al, SC400_SOCKET_B_ADDR_WIN_ENABLE
	out	dx, al
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	in	al, dx			; al = SC400SocketAddrWinEnable
	or	ax, di			; turn on bit in al
	jmp	writeReg

turnOff:
	;
	; Turn off this mapping window.
	;
	mov	dx, SC400_PC_CARD_CTRL_INDEX
	mov	al, SC400_SOCKET_B_ADDR_WIN_ENABLE
	out	dx, al
	inc	dx			; dx = SC400_PC_CARD_CTRL_DATA
	in	al, dx			; al = SC400SocketAddrWinEnable
	not	di
	and	ax, di			; turn off bit in al

writeReg:
	out	dx, al

	call	SysExitCritical
	clc				; success

	popa				; restore regs

done:
	.leave
	ret

;----------------------------------------------------------------------------
;
; MapUtilityWindow for everything else
;
;----------------------------------------------------------------------------

else

PrintMessage <Add code for MapUtilityWindow>

endif

MapUtilityWindow	endp

kcode	ends

kinit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitSys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the System module.

CALLED BY:	EndGeos
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitSys	proc	far

	FALL_THRU ExitUtilWindow

ExitSys	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitUtilWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the utility mapping windows and other cleanup.

CALLED BY:	ExitSys
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitUtilWindow	proc	far

	tst	ds:[utilWindowSegment]
	jz	done

if _GPCHW

	;
	; Turn the cache bit for 0xC0000 back on to speed up DOS apps.  Also,
	; turn the write-protect bit back on in case some DOS apps have bugs.
	;
		.assert (SECOND_MAPPING_WINDOW le 0xCFFF) and \
			(SECOND_MAPPING_WINDOW_END ge 0xC000)
	mov	al, SC400_ROM0_ATTRIBUTE
	out	SC400_CHIP_INDEX, al
	in	al, SC400_CHIP_DATA	; al = SC400ROM0Attribute
	ornf	al, mask SR0A_CSEG_CACHE_EN or mask SR0A_CSEG_WP
	out	SC400_CHIP_DATA, al

	;
	; Free allocated space.
	;
	call	FreeXMSMemory

endif	; _GPCHW

done:
	ret
ExitUtilWindow	endp

if _GPCHW


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeXMSMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the XMS memory that we allocated

CALLED BY:	ExitUtilWindow
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeXMSMemory	proc	near
	uses	es
	.enter

	mov	bp, ds:[utilWindowNumGeodes]
	mov	bx, ds:[utilWindowXMMInfoBlk]
	push	bx			; save info blk handle
	call	MemLock
	mov	es, ax
	clr	si			; es:si = 1st UtilWindowPhyMemArray

geodeLoop:
	mov	cx, es:[si].UWPMA_numEntries
	add	si, offset UWPMA_entries	; es:si = 1st UWPME

blkLoop:
	mov	dx, es:[si].UWPME_xmmHandle
	tst	dx
	jz	nextBlk
	push	dx			; save XMM handle
	mov	ah, XMS_UNLOCK_EMB
	call	ds:[xmsAddrUW]
	Assert	e, ax, 1
	pop	dx			; bx = XMM handle
	mov	ah, XMS_FREE_EMB
	call	ds:[xmsAddrUW]
	Assert	e, ax, 1

nextBlk:
	add	si, size UtilWindowPhyMemEntry
	loop	blkLoop

	dec	bp
	jnz	geodeLoop

	pop	bx			; bx = info blk handle
	call	MemFree

	.leave
	ret
FreeXMSMemory	endp

endif	; _GPCHW

kinit	ends

endif	; UTILITY_MAPPING_WINDOW

UtilWindowCode	ends
