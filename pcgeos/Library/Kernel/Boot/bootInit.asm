COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Boot
FILE:		bootInit.asm

ROUTINES:
	Name		Description
	----		-----------
   EXT	InitGeos	Initialize the system

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This module initializes the boot module.  See manager.asm for
documentation.

	$Id: bootInit.asm,v 1.1 97/04/05 01:10:53 newdeal Exp $

------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitGeos

DESCRIPTION:	Library entry point for the kernel.

CALLED BY:	PC/GEOS loader.

PASS:
	ds, es - dgroup
	cx:dx - KernelLoaderVars structure (on non-full-XIP systems)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	call InitXXXX routines to initialize modules
	call ProcessIniFile to do other crap

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK
FXIP <initGeosTag	char	"aw"					>
endif

InitGeos	proc	far

;
; On FXIP systems, we have to initialize the heap module *before* we call
; LoaderStuff(), because LoaderStuff loads things in from the ROM image
; (like the kinit module).
;
FXIP <	call	InitHeap		; init heap module		>
FXIP <	call	ReplaceMovableVector	; allow calls between modules>

	; handle loader interface
	call	LoaderStuff
	SSP_DEBUG	'0'
SSP <   call	SingleStepInitAccountant				>
SSP <   call	SingleStepHookVideo					>
SSP <	call	HookSingleStepInterrupt					>

;	We don't have single-stepping turned on by default while booting
;	because it's *so* slow. You can comment this next line back in
;	if you like
;SSP <	call	StartSingleStepping					>

NOFXIP <call	InitHeap						>
	SSP_DEBUG	'1'

	; Do this first.  This allows calls to movable resources that have
	; been pre-loaded (since the interrupt vectors are caught here).

NOFXIP <	call	ReplaceMovableVector	; allow calls between modules>


if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
	call	InitHeapSize
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS

	call	InitGeode		; init geode module

	; Figure out system type and configuration info now we're in our
	; top-level directory.

	call	InitSys

	; Initialize other modules -- do not change this ordering

	call	InitFile		; init file module

	SSP_DEBUG	'2'
	call	InitFSD			; init FSD module

	call	InitThread		; init thread module


if	INI_SETTABLE_HEAP_THRESHOLDS
	call	LMemInit		; init lmem module -- should only
endif					; set a few threshold constants!

	call	InitDrive		; init drive module
	call	InitDisk		; init disk module
	call	InitObject		; init object module


	; Re-alloc the size of the path block correctly

	call	ReAllocPathBlock

	; switch to the top-level system directory

	call	FileSetInitialPath

if CHECKSUM_DOS_BLOCKS
	; Must do this prior to any SysLockBIOS calls!
	call	SysSetDOSTables
endif

	; Load geodes essential to the function of the kernel...
	; (loading of the kernel lib here, since it contains the LMem Error
	; checking code, which is used by GrInitSys.  We could load it later
	; for non-error checking version, if desired...)

	call	LoadFSDriver		; Load the appropriate FS driver
if	HASH_INIFILE
	call	InitFileInitHashTable	; create the category lookup table
endif

if USE_BUG_PATCHES
	call	InitGeneralPatches
endif

if MULTI_LANGUAGE
	call	InitLanguagePatches
endif

if USE_PATCHES
	call	GeodePatchRunningGeodes
endif

if FULL_EXECUTE_IN_PLACE and MULTI_LANGUAGE
	call	GeodeProcessFixedStringsResource
endif

	; If logging, create log file, so that LogWriteInitEntry &
	; LogWriteEntry may be called to record further startup progress

	call	LogInit

	; Load the power management driver

	call	LoadPowerDriver
	SSP_DEBUG '3'

	; Initialize the timer *after* loading the power management driver

	call	InitTimer		; init timer module
if PROFILE_LOG	
	call	ProfileInit		; init Profiling
endif
	call	LoadPenDefaults		;Must be called *before* InitIM, 
					; because the stack size for the 
					; input manager is different on pen
					; machines.

	; .. continue loading geodes essential to the kernel

	call	HeapStartScrub		; start the scrub thread for the heap

	call	InitIM			; initialize the input manager
	SSP_DEBUG '4'

	call	LocalInit
	call	GrInitFonts		; find fonts on disk
	; Process first part of ini file needed by graphics system

	call	ProcessInitFileBeforeGr

	call	GrInitDefaultFont	; load default font
	call	GrInitSys		; init graphics module
	call	WinInitSys		; init window module
	SSP_DEBUG '5'

	; Load other drivers needed by the kernel, then call ProcessInitFile
	; for other inits

	; See if we've got an ATS system in place
	call	InitATS							

	;
	; If initfile contains "noVidMem = true" under [system], then
	; do not load the memory video driver.

	push 	ds
	mov	cx, cs
	mov	dx, offset cs:[noVidMemKeyString]
	mov	ds, cx
	mov	si, offset cs:[systemCategoryString]
	call	InitFileReadBoolean
	pop	ds

	jc	loadVidMem		; if no key, load vidmem by default
	tst	ax			; if noVidMem = false, load vidmem.
	jz	loadVidMem
	jmp 	noVidMem

loadVidMem:
	call	LoadMemVid		; load memory video driver
noVidMem:
	call	ProcessInitFileAfterGr
	SSP_DEBUG '6'

	; call ProcessCommandLine to load .geo files specified

	call	ProcessCommandLine

	; unlock the InitStrings resource
	mov	bx, handle InitStrings		;will be discarded soon...
	call	MemUnlock

	call	FSDInitComplete
	SSP_DEBUG '7'

	; all done, let's do it

	mov	ds:[initFlag], 0


if FULL_EXECUTE_IN_PLACE
	; didn't have to lock kinit for XIP system, so don't unlock it
	jmp	Dispatch
else
	; unlock kinit, but do it in such a way that MemUnlock returns to
	; Dispatch, rather than here, as ec +unlockMove will cause kinit to
	; move (leaving the thing with no place to return to). It's also
	; unaesthetic to unlock your own code resource and then keep executing
	; in it. This code snippet is ever so much cleaner :) -- ardeb 3/22/94

	mov	bx, segment Dispatch
	push	bx
	mov	bx, offset Dispatch
	push	bx
	mov	bx, handle kinit
	jmp	MemUnlock
endif
InitGeos	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderStuff

DESCRIPTION:	Handle loader interface stuff

CALLED BY:	InitGeos

PASS:
	ds, es - dgroup
	cx:dx - KernelLoaderVars structure

RETURN:
	loaderVars - set
	InitStuff, kinit - locked
	kTPD - initialized

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

LoaderStuff	proc	near

if	FULL_EXECUTE_IN_PLACE and MULTI_LANGUAGE

	; To make FixedStrings patchable, it was not preloaded as fixed.
	; Lock it until the patching code has a chance to move it to a fixed
	; block.

	mov	bx, handle FixedStrings
	call	MemLock
	mov	ds:[fixedStringsSegment], ax 
else
	mov	ds:[fixedStringsSegment], FixedStrings
endif

if	not FULL_EXECUTE_IN_PLACE

;	This code lies in a movable resource, but on full XIP systems, we
;	can't load this code in until the loaderVars are copied in. So,
;	this code is moved into KernelLibraryEntry on those systems...

	; Copy the structure passed by the loader.  This enables the heap
	; and other stuff to function properly

	push	ds
	movdw	dssi, cxdx
	mov	di, offset loaderVars
	mov	cx, size KernelLoaderVars
	rep	movsb
if DBCS_PCGEOS
	;
	; Convert various loader strings from DOS to GEOS
	; Ideally, we would wait until the FS driver is loaded
	; and let it deal with it, but we can't.
	;
PrintMessage <can conversion of loader strings be down later?>
	mov	si, dx
	mov	di, offset KLV_bootupPath
	call	ConvertLoaderString
	mov	di, offset KLV_topLevelPath
	call	ConvertLoaderString
endif

	; If we're running under the Swat stub, tell it where our kcode
	; is actually located.

	tst	es:[loaderVars].KLV_swatKcodePtr.segment
	jz	swatDealtWith
	lds	si, es:[loaderVars].KLV_swatKcodePtr
	mov	{sptr}ds:[si], kcode
swatDealtWith:

	pop	ds
endif

if	FULL_EXECUTE_IN_PLACE and DBCS_PCGEOS
;
; .... I'll explain later ...  --- AY
;

	;
	; Convert various loader strings from DOS to GEOS
	; Ideally, we would wait until the FS driver is loaded
	; and let it deal with it, but we can't.
	;
PrintMessage <can conversion of loader strings be down later?>
	mov	di, offset loaderVars.KLV_bootupPath
	call	ConvertLoaderStringInPlace
	mov	di, offset loaderVars.KLV_topLevelPath
	call	ConvertLoaderStringInPlace

endif	; FULL_EXECUTE_IN_PLACE and DBCS_PCGEOS

	; no need to lock kinit on XIP systems since its gets banked in
	; from ROM when executing by ResourceCallInt
NOFXIP<	mov	bx, handle kinit					>
NOFXIP<	call	MemLock							>

	; lock the InitStrings resource
	mov	bx, handle InitStrings
	call	MemLock

	; setup initial thread private data

	mov	ds:[TPD_processHandle], handle 0

	push	ds, es
	mov	ax, size ThreadExceptionHandlers
	mov	cx, mask HAF_NO_ERR shl 8 or mask HF_FIXED or mask HF_SHARABLE
	call	MemAllocFar
	mov	es, ax
	mov	es:[TEH_handle], bx
	mov	es:[TEH_referenceCount], 1
	mov	di, offset TEH_divideByZero
	segmov	ds, cs
	mov	si, offset initialThreadExeptions
	mov	cx, (size initialThreadExeptions)/2
	rep	movsw
	pop	ds, es

	mov	ds:[TPD_exceptionHandlers], ax	; save exception block segment

	; store the dgroup handle

	mov	ax, ds:[loaderVars].KLV_dgroupHandle
	mov	ds:[TPD_blockHandle], ax

NOAXIP<	; store the dgroup segment					>
NOAXIP<	mov	ax, ds:[loaderVars].KLV_dgroupSegment			>
NOAXIP<	mov	ds:[TPD_dgroup], ax					>

	; free the loader itself.

ifndef PRODUCT_GEOS32       ; GEOS32 requires the loader for the GPMI routines
NOAXIP <	mov	bx, ds:[loaderVars].KLV_handleBottomBlock	>
NOAXIP <	mov	bx, ds:[bx].HM_prev				>
NOAXIP <	call	MemFree						>
endif

	ret

LoaderStuff	endp

initialThreadExeptions	fptr	\
	ThreadTE_DIVIDE_BY_ZERODefault,	; TPD_divideByZero
	ThreadTE_OVERFLOWDefault,	; TPD_overflow
	ThreadTE_BOUNDDefault,		; TPD_bound
	ThreadTE_FPU_EXCEPTIONDefault,	; TPD_fpuException
if	SINGLE_STEP_PROFILING
	0,
else
	ThreadTE_SINGLE_STEPDefault,	; TPD_singleStep
endif
	ThreadTE_BREAKPOINTDefault	; TPD_breakpoint

if	not FULL_EXECUTE_IN_PLACE and DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertLoaderString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string from the loader

CALLED BY:	LoaderStuff()
PASS:		ds:si - ptr to loader's KernelLoaderVars
		es - dgroup
		di - offset of string in KernelLoaderVars to convert
RETURN:		none
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertLoaderString		proc	near
	uses	si
	.enter

	add	si, di				;ds:si <- ptr to string
	add	di, offset loaderVars		;es:di <- ptr to dest
	clr	ah
charLoop:
	lodsb					;al <- DOS character
EC <	cmp	al, 0x80						>
EC <	ERROR_AE UNCONVERTABLE_DOS_CHARACTER_FOR_BOOT			>
	stosw					;store GEOS character
	tst	ax				;reached NULL?
	jnz	charLoop

	.leave
	ret
ConvertLoaderString		endp
endif

if	FULL_EXECUTE_IN_PLACE and DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertLoaderStringInPlace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	... later ...

CALLED BY:	(INTERNAL) LoaderStuff
PASS:		ds, es	= dgroup
		ds:di	= string in KernelLoaderVars to convert
RETURN:		nothing
DESTROYED:	ax, cx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	allen	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertLoaderStringInPlace	proc	near
	.enter

	;
	; Find the ends of the source string (SBCS) and dest string (DBCS).
	;
	clr	ax
	mov	cx, -1
	repne	scasb
	dec	di
	mov	si, di			; ds:si = null char in src

	not	cx			; cx = length w/ null

	add	di, cx
	dec	di			; es:di = last wchar (dest)

	std

charLoop:
	lodsb
EC <	cmp	al, 0x80						>
EC <	ERROR_AE UNCONVERTABLE_DOS_CHARACTER_FOR_BOOT			>
	stosw
	loop	charLoop

	cld

	.leave
	ret
ConvertLoaderStringInPlace	endp
endif	; FULL_EXECUTE_IN_PLACE and DBCS_PCGEOS

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReAllocPathBlock

DESCRIPTION:	Re-alloc the path block to its correct size

CALLED BY:	INTERNAL (InitGeos)

PASS:		ds = idata

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

-------------------------------------------------------------------------------@
ReAllocPathBlock	proc	near	uses ds
	.enter

	mov	bx, ds:[loaderVars].KLV_stdDirPaths
	tst	bx
	jz	done
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[SDP_blockSize]
	call	MemUnlock

	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
done:
	.leave
	ret

ReAllocPathBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadMemVid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the memory video driver

CALLED BY:	EXTERNAL
		BootGeos

PASS:		ds - kernel variable segment

RETURN:		none

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		load the driver file;
		store the strategy routine address;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadMemVid	proc	near
		push	ds
		segmov	ds, cs
		mov	si, offset cs:memvidName
		mov	ax, SP_VIDEO_DRIVERS
		mov	cx, VIDEO_PROTO_MAJOR
		mov	dx, VIDEO_PROTO_MINOR
		call	LoadDriver		; load memory driver
		ERROR_C	CANNOT_LOAD_MEMORY_VIDEO_DRIVER
		call	GeodeInfoDriver		; get structure w/valuable info
		mov	ax,ds:[si][DIS_strategy].offset   ; get strat rout
		mov	cx,ds:[si][DIS_strategy].segment
		pop	ds			; restore idata segment
		mov	ds:[memVidStrategy].offset, ax
		mov	ds:[memVidStrategy].segment, cx
		mov	ds:[defaultDrivers].DDT_memoryVideo, bx
		ret
LoadMemVid	endp

NEC <LocalDefNLString	memvidName <'vidmem.geo', 0>>
EC <LocalDefNLString	memvidName <'vidmemec.geo', 0>>

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadPowerDriver

DESCRIPTION:	Load the power management driver

CALLED BY:	INTERNAL

PASS:
	ds - kdata

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/30/92		Initial version

------------------------------------------------------------------------------@
LoadPowerDriver	proc	near
	push	ds

	mov	dx, offset cs:[powerDriverString]
	call	GetSystemString
POQET <	jnc	haveDriver						>

	; no default driver, try to recognize...

POQET <	call	LookForPoqet						>
POQET <	cmc								>
	jc	done			; if not found, we're done
POQET <	segmov	ds, cs							>
POQET <	mov	si, offset cs:poqetName					>

POQET <haveDriver:							>

	; *ds:si = string

	mov	ax, SP_POWER_DRIVERS
	mov	cx, POWER_PROTO_MAJOR
	mov	dx, POWER_PROTO_MINOR
	call	LoadDriver		; bx = handle
	jc	done

	call	GeodeInfoDriver		; get structure w/valuable info
	movdw	dxax, ds:[si][DIS_strategy]

		
		
	pop	ds
	push	ds

	movdw	ds:[powerStrategy], dxax
	mov	ds:[defaultDrivers].DDT_power, bx	

done:
	;
	; Always tell ourselves to ignore device-power notifications. If driver
	; was loaded and wants them, it will have hooked the notification and
	; we'll get an error back.
	;
	mov	si, SST_DEVICE_POWER
	call	SysIgnoreNotification

	pop	ds
	call	DoneWithString
	ret

LoadPowerDriver	endp

; -----------------------------------------------------------------------------
; 			      RESPONDER SPECIFIC
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
;			   RESPONDER SPECIFIC ENDS
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; 			      PENELOPE SPECIFIC
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
;			   PENELOPE SPECIFIC ENDS
; -----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitATS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the ATS geode (if needed)

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Loads 

PSEUDO CODE/STRATEGY:
		Look in INI file for ATS flags
		If active, load the ATS geode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	10/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

atsCategory	char	"ats",0
loadKey		char	"loadOnStartup",0
nameKey		char	"geodeName",0
udata		segment
	atsGeodeHandle		hptr
udata		ends

InitATS	proc	near
		uses	ax, bx, cx, dx, si, di, bp, ds
		.enter
	;
	;  Take a look at the .INI file and see if
	;  we should load the ATS geode on startup.

		clr	bx				; assume no...

		mov	cx, cs				; cx:dx -> key
		mov	dx, offset loadKey
		mov	ds, cx				; ds:si -> category
		mov	si, offset atsCategory

		call	InitFileReadBoolean	; carry set on error
						; ax <- value
		jc	storeHandle	; => Nope.

		tst	ax			
		jz	storeHandle	; => Nope.

	;
	;  We should load it.  Find out what the name
	;  of the geode is...
							; ds:si -> category
		mov	dx, offset nameKey		; cx:dx -> key
		clr	bp				; bp -> allocate block

		call	InitFileReadString	; carry set on error
						; bx <- block handle of name
						; cx <- # chars (-null)
		jc	storeHandle	; => Missing.
		jcxz	error		; => Missing.

	;
	;  Now that we know what it's called, switch
	;  back to the system driectory and load it.
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		jc	storeHandle	; => We're hosed.

		push	bx				; save name block

		call	MemLock			; ax <- segment of name block

		mov	ds, ax				; ds:si -> name
		clr	si, ax				; ax -> any version

		call	GeodeUseLibrary		; carry set on error
						; bx <- handle of geode

		pop	ax				; restore name block
		jnc	freeNameBlock	; => All Is Well!

error:
	;
	;  Houston, we have a problem...  There has been
	;  a complication, so we need to free the block
	;  allocated to hold the geode name, and mark the
	;  geode as not loaded...
		clr	bx

freeNameBlock:
	;
	;  Return the block containing the geode name
	;  while preserving the geode block handle
							; ax <- geode handle
		xchg	ax, bx				; bx <- name block
		call	MemFree
		mov_tr	bx, ax				; bx <- geode handle

storeHandle:
	;
	;  Record the handle of the ATS geode in dgroup
	;  so that we can unload it if needed.
		LoadVarSeg	ds, ax

		mov	ds:[atsGeodeHandle], bx

done::
		.leave
		ret
InitATS	endp

powerDriverString	char	"power", 0

if	POQET_SUPPORT

NEC <poqetName	char	"poqet.geo", 0					>
EC <poqetName	char	"poqetec.geo", 0				>

COMMENT @----------------------------------------------------------------------

FUNCTION:	LookForPoqet

DESCRIPTION:	See if this is a Poqet machine (and thus needs the Poqet
		power management driver)

CALLED BY:	INTERNAL

PASS:
	ds - kdata

RETURN:
	carry - set if found
DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/ 4/92		Initial version

------------------------------------------------------------------------------@
LookForPoqet	proc	near	uses di, ds, es
	.enter

	; look for "POQET" in the first 256 bytes of 0xf000

	mov	ax, 0xf000
	mov	es, ax
	clr	di
	mov	cx, 256
	segmov	ds, cs
	mov	si, offset poqetString
	mov	dx, length poqetString
	call	SearchForString

	.leave
	ret

LookForPoqet	endp

poqetString	char	"POQET"

COMMENT @----------------------------------------------------------------------

FUNCTION:	SearchForString

DESCRIPTION:	Search for a string

CALLED BY:	LookForPoqet

PASS:
	es:di - buffer to search
	cx - length of buffer
	ds:si - string to search for
	dx - length of search string

RETURN:
	carry - set if found

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/ 4/92		Initial version

------------------------------------------------------------------------------@
SearchForString	proc	near	uses cx, dx, di
	.enter
searchLoop:
	push	cx, si, di
	mov	cx, dx
	repe cmpsb
	pop	cx, si, di
	stc
	jz	done
	inc	di
	loop	searchLoop
	clc
done:
	.leave
	ret

SearchForString	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcessCommandLine

DESCRIPTION:	Process the command line

CALLED BY:	INTERNAL (InitGeos)

PASS:
	ds - idata

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

ProcessCommandLine	proc	near	uses	ds, es
	.enter

	segmov	es, ds
	mov	ds, ds:[loaderVars].KLV_pspSegment

	mov	si, offset PSP_cmdTail
	lodsb
	clr	ah
	xchg	ax, bx
	mov	{byte}ds:[bx][si], 0;null terminate string
PCL_skipCommand:
	lodsb	
	tst	al
	jz	PCL_ret			;hit end -- return
	cmp	al,' '
	jz	PCL_skipCommand
	cmp	al,'/'
	jne	PCL_load

	; skip chars until the first whitespace, as switches can be
	; multiple characters.

skipSwitch:
	lodsb
	cmp	al, ' '
	je	PCL_skipCommand
	cmp	al, '\t'
	je	PCL_skipCommand
	tst	al
	jnz	skipSwitch
	jmp	PCL_ret

PCL_load:
	;
	; Use the rest of the tail as the name of a file to load
	; XXX: handle multiple files?
	;
	clr	di			;pass nothing to new process
	dec	si			;point to start of name

	mov	al,PRIORITY_STANDARD	;priority
	clr	ah
	mov	cx,mask GA_PROCESS
	clr	dx
	call	GeodeLoad
PCL_ret:
	.leave
	ret

ProcessCommandLine	endp
