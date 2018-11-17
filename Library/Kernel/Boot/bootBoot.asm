COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Boot
FILE:		bootBoot.asm

ROUTINES:
	Name		Description
	----		-----------
	BootGeos	Called by MS-DOS when PC GEOS is started.
	EndGeos		Exit GEOS
	FatalError	The pit of iniquity to which all slime crawls

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/88...		Initial version

DESCRIPTION:
	This file starts PC GEOS.

	$Id: bootBoot.asm,v 1.2 98/04/30 15:49:19 joon Exp $

------------------------------------------------------------------------------@


	; Debugger hook from LoadResourceLow routine

idata	segment

if	SINGLE_STEP_PROFILING
FarDebugProcess	proc	far
	call	SaveAndDisableSingleStepping
	call	SwatFarDebugProcess
	call	RestoreSingleStepping
	ret
FarDebugProcess	endp
FarDebugMemory	proc	far
	call	SaveAndDisableSingleStepping
	call	SwatFarDebugMemory
	call	RestoreSingleStepping
	ret
FarDebugMemory	endp
FarDebugLoadResource	proc	far
	call	SaveAndDisableSingleStepping
	call	SwatFarDebugLoadResource
	call	RestoreSingleStepping
	ret
FarDebugLoadResource	endp
SwatFarDebugProcess	proc	far
	ret
	db	4 dup(0x90)	; nops
SwatFarDebugProcess	endp

SwatFarDebugMemory	proc	far
	ret
	db	4 dup(0x90)	; nops
SwatFarDebugMemory	endp

SwatFarDebugLoadResource	proc	far
	ret
	db	4 dup(0x90)	; nops
SwatFarDebugLoadResource	endp
else

FarDebugProcess	proc	far
	ret
	db	4 dup(0x90)	; nops
FarDebugProcess	endp

FarDebugMemory	proc	far
	ret
	db	4 dup(0x90)	; nops
FarDebugMemory	endp

FarDebugLoadResource	proc	far
	ret
	db	4 dup(0x90)	; nops
FarDebugLoadResource	endp
endif
if	FULL_EXECUTE_IN_PLACE
WritableWarningNotice	proc	far
	ret
WritableWarningNotice	endp
WritableFatalError	proc	far
	ret
WritableFatalError	endp
endif
idata	ends
kcode		segment




COMMENT @----------------------------------------------------------------------

FUNCTION:	KernelLibraryEntry

DESCRIPTION:	Library entry point for the kernel

CALLED BY:	ProcessLibraryTable

PASS:
	di - LCT_ATTACH if called from loader
	if di = LCT_ATTACH
		CX:DX - ptr to KernelLoaderVars structure passed by loader

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

KernelLibraryEntry	proc	far
	jmp	short entry

;	IMPORTANT IMPORTANT IMPORTANT
;	this swatTablePtr must directly after the jmp instruction at the
;	beginning of the kernel entry for swat to work!!!!
;	jimmy 7/93
;	IMPORTANT IMPORTANT IMPORTANT

	.assert ($ - offset KernelLibraryEntry) eq 2
	SwatVectorDesc <
		SWAT_VECTOR_SIG,
		KV_AFTER_EXCEPTION_CHANGE,
		size swatVectorTable, 
		offset swatVectorTable
	>

entry:
	cmp	di, LCT_ATTACH
	jnz	done

;	On full-XIP systems, we want to bank in the movable InitGeos resource,
;	but cannot until the KernelLoaderVars structure is copied in. SO,
;	we move this code from LoaderStuff() to here.


if	FULL_EXECUTE_IN_PLACE
	; Copy the structure passed by the loader.  This enables the heap
	; and other stuff to function properly

	push	ds
	movdw	dssi, cxdx
	mov	di, offset loaderVars
	mov	cx, size KernelLoaderVars
	rep	movsb

	; If we're running under the Swat stub, tell it where our kcode
	; is actually located.

	tst	es:[loaderVars].KLV_swatKcodePtr.segment
	jz	swatDealtWith
	lds	si, es:[loaderVars].KLV_swatKcodePtr
	mov	{sptr}ds:[si], kcode
swatDealtWith:

;	The XIP header is in ROM, so it can't lie in the heap (there are lots
;	of places in the code that assume that ROM resources lie above
;	KLV_heapEnd).

	pop	ds
EC <	mov	bx, ds:[loaderVars].KLV_xipHeader			>
EC <	cmp	bx, ds:[loaderVars].KLV_heapEnd				>
EC <	ERROR_B	HEAP_END_COMES_AFTER_START_OF_XIP_READ_ONLY_RESOURCES	>

endif

	; we want to go to InitGeos, which is in memory (since it is preloaded)
	; but we must do so manually

	mov	bx, handle InitGeos					
NOFXIP <push	ds:[bx].HM_addr				;segment	>

;	On full-xip systems, the InitGeos resource *isn't* preloaded - bank
;	it into memory

FXIP <	call	MapInXIPResource	;Returns BX <- segment of resource>
FXIP <	push	bx							>
if	ERROR_CHECK
FXIP <	push	ds							>
FXIP <	mov	ds, bx							>
FXIP <	cmp	{word} ds:[initGeosTag], 'aw'				>
FXIP <	ERROR_NZ	XIP_MAP_ERROR					>
FXIP <	pop	ds							>
endif
	mov	ax, offset InitGeos
	push	ax					;offset
done:
	clc
	ret

KernelLibraryEntry	endp

if ERROR_CHECK
sysECBlockOffset 	equ 	offset	sysECBlock
sysECChecksumOffset	equ	offset	sysECChecksum
sysECLevelOffset	equ	offset	sysECLevel
else
sysECBlockOffset 	equ 	0
sysECChecksumOffset	equ	0
sysECLevelOffset	equ	0
endif

if FULL_EXECUTE_IN_PLACE
curXIPPageOffset	equ	offset curXIPPage
MapXIPPageFarOffset	equ	offset MapXIPPageFar
else
curXIPPageOffset	equ	0
MapXIPPageFarOffset	equ	0
MAPPING_PAGE_SIZE	equ	0
endif

if	SINGLE_STEP_PROFILING
DEBUG_PROCESS_ROUTINE	equ	SwatFarDebugProcess
DEBUG_MEMORY_ROUTINE	equ	SwatFarDebugMemory
DEBUG_LOAD_RESOURCE_ROUTINE	equ	SwatFarDebugLoadResource
else
DEBUG_PROCESS_ROUTINE	equ	FarDebugProcess
DEBUG_MEMORY_ROUTINE	equ	FarDebugMemory
DEBUG_LOAD_RESOURCE_ROUTINE	equ	FarDebugLoadResource
endif

swatVectorTable	SwatVectorTable <
	offset	currentThread,
	offset	geodeListPtr,
	offset	threadListPtr,
	offset	biosLock,
	offset	heapSem,
	offset	DEBUG_LOAD_RESOURCE_ROUTINE,
	offset	DEBUG_MEMORY_ROUTINE,
	offset	DEBUG_PROCESS_ROUTINE,
	offset	MemLock,
	offset	EndGeos,
	offset	BlockOnLongQueue,
	offset	FileReadSwat,
	offset	FilePosSwat,
	sysECBlockOffset,
	sysECChecksumOffset,
	sysECLevelOffset,
	offset	systemCounter,
	offset  errorFlag,
	offset	ResourceCallInt,
	offset	ResourceCallInt_end,
	offset	FatalError,
	offset	FatalError_end,
	offset	SendMessage,
	offset	SendMessage_end,
	offset	CallFixed,
	offset	CallFixed_end,
	offset	ObjCallMethodTable,
	offset	ObjCallMethodTable_end,
	offset	CallMethodCommonLoadESDI,
	offset	CallMethodCommonLoadESDI_end,
	offset	ObjCallMethodTableSaveBXSI,
	offset	ObjCallMethodTableSaveBXSI_end,
	offset	CallMethodCommon,
	offset	CallMethodCommon_end,
	offset	MessageDispatchDefaultCallBack,
	offset	MessageDispatchDefaultCallBack_end,
	offset	MessageProcess,
	offset	MessageProcess_end,
	offset	OCCC_callInstanceCommon,
	offset	OCCC_callInstanceCommon_end,
	offset	OCCC_no_save_no_test,
	offset	OCCC_no_save_no_test_end,
	offset	OCCC_save_no_test, 
	offset	OCCC_save_no_test_end,
	offset	Idle,
	offset	Idle_end,
	curXIPPageOffset,
	MapXIPPageFarOffset,
	MAPPING_PAGE_SIZE
>



COMMENT @----------------------------------------------------------------------

FUNCTION:	FatalError

DESCRIPTION:	Handle a fatal error in an application.

CALLED BY:	GLOBAL

PASS:
	ax - error code

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Cheng	10/89		Made non-EC version put up error box

------------------------------------------------------------------------------@
if ERROR_CHECK

idata	segment

errorCursor	PointerDef <
	16,				; PD_width
	16,				; PD_height
	8,				; PD_hotX
	8				; PD_hotY
>
byte	00000111b, 11000000b,
	00011111b, 11110000b,
	00111111b, 11111000b,
	01111111b, 11111100b,
	01111111b, 11111100b,
	11111111b, 11111110b,
	11111111b, 11111110b,
	11111111b, 11111110b,
	11111111b, 11111110b,
	11111111b, 11111110b,
	01111111b, 11111100b,
	01111111b, 11111100b,
	00111111b, 11111000b,
	00011111b, 11110000b,
	00000111b, 11000000b,
	00000000b, 00000000b

byte	00000000b, 00000000b,
	00000000b, 00000000b,
	00000110b, 00010000b,
	00000110b, 00011000b,
	00000000b, 00111000b,
	00000000b, 01111100b,
	00000000b, 11111100b,
	00000000b, 11111100b,
	00000001b, 11111100b,
	00000011b, 11111100b,
	00000111b, 10011000b,
	00000111b, 10011000b,
	00000111b, 11110000b,
	00000011b, 11000000b,
	00000000b, 00000000b,
	00000000b, 00000000b


idata	ends

endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	AddErrorInfo

DESCRIPTION:	The non error checking kernel places a SysError box up
		when a fatal error is encountered. Part of the message
		string is the name of the geode owning the function that
		called FatalError and the error number

CALLED BY:	INTERNAL (FatalError)

PASS:		ax - FatalErrors
		bp - segment of calling code

RETURN:		ds - idata
		ds:[messageBuffer] - error message string
			If death occurred in kernel, the code will have been
			mapped to a special string if it's one of the known
			errors. Else just the standard string.

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version
	Tony	12/90		Rewritten for localization

-------------------------------------------------------------------------------@
AddErrorInfo	proc	near
	LoadVarSeg	ds
	call	PushAll

	push	ax				;save error code
	mov	al, KS_FATAL_ERROR_IN					
	call	AddStringAtMessageBuffer				

	; Now add the geode name...

	; Use heap function to locate the handle involved.

	mov	cx, bp
	call	SegmentToHandle
	jc	useOwner

	; couldn't find a handle for the caller, so just assume it's in the
	; kernel.
useKernel:
	mov	al, KS_KERNEL						
	call	AddStringAtESDI						
	pop	ax
	jmp	checkKernelCode

useOwner:
	;copy geode name into string

	mov	bx, cx				;bx = handle
	mov	bx, ds:[bx][HM_owner]		;bx <- handle of geode header

	;
	; Since a fatal error has occurred, don't try to lock the coreblock
	; if it is swapped because it may fail for one reason or another.
	; (E.g. swap driver died.)
	;
	call	SysEnterCritical
	tst	ds:[bx].HM_addr
	jnz	lockCoreblock			; => coreblock on heap
	call	SysExitCritical
	jmp	useKernel

lockCoreblock:
	call	NearLockDS			; ds <- core block
	call	SysExitCritical
	mov	si, offset GH_geodeName		; ds:si = geode name
	mov	cx, GEODE_NAME_SIZE
copyNameLoop:
	lodsb
	cmp	al, ' '
	jz	unlockIt
SBCS <	stosb								>
DBCS <	stosw								>
	loop	copyNameLoop
unlockIt:
	call	UnlockDS
EC <	call	NullDS							>

	pop	ax
	cmp	bx, handle 0
	jne	noString

checkKernelCode:
	;
	; See if we have a string for this error...
	;

	cmp	ax, FIRST_ERROR_WITH_STRING
	jb	noString
	cmp	ax, FIRST_ERROR_WITHOUT_A_STRING
	jb	mapKernelErrorCode

	; start with "Fatal error in "

noString:
	push	ax

	; add ". Error Code: KRX-"

	mov	al, KS_CODE_EQUALS
	call	AddStringAtESDI

	; add error code #

	pop	ax
	clr	dx
SBCS <	mov	cx, mask UHTAF_NULL_TERMINATE				>
DBCS <	mov	cx, mask UHTAF_NULL_TERMINATE or mask UHTAF_SBCS_STRING	>
	call	UtilHex32ToAscii

done:
	call	PopAll
	ret

mapKernelErrorCode:

	cmp	ax, LAST_ANONYMOUS_ERROR
	ja	notAnon
	cmp	ax, FIRST_ANONYMOUS_ERROR
	jb	notAnon
	segmov	ds, es		; ds <- kdata again
	push	ax
	mov	al, KS_TE_SYSTEM_ERROR
	call	AddStringAtMessageBuffer
	pop	ax
	sub	ax, FIRST_ERROR_WITH_STRING
	call	AddStringAtESDI
	jmp	done

notAnon:

	mov	es:[di], ':' or (' ' shl 8)
	inc	di
	inc	di

	; if init-only error code then map to correct string

	cmp	ax, FIRST_FATAL_ERROR_ONLY_IN_INIT
	jb	noMap
	add	ax, FIRST_STRING_IN_INIT_STRINGS - \
			(FIRST_FATAL_ERROR_ONLY_IN_INIT-FIRST_ERROR_WITH_STRING)
	mov	di, offset messageBuffer	; nuke the "Unknown error in"
						;  thing, since we've got a
						;  decent string for these
						;  things.

noMap:
	sub	ax, FIRST_ERROR_WITH_STRING	; convert to KernelStrings
						;  enumerated type

	call	AddStringAtESDI
	jmp	done

AddErrorInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	AddStringAtESDI

DESCRIPTION:	Get a string from the strings file.

CALLED BY:	INTERNAL

PASS:
	es:di - buffer for string
	al - KernelStrings
	DBCS:
		al - KS_DBCS_DEST set to create DBCS string

RETURN:
	es:di - pointing at null

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/90		Initial version

------------------------------------------------------------------------------@


AddStringAtMessageBufferFar	proc	far
	call	AddStringAtMessageBuffer
	ret
AddStringAtMessageBufferFar	endp

AddStringAtESDIFar	proc	far
	call	AddStringAtESDI
	ret
AddStringAtESDIFar	endp

AddStringAtMessageBuffer	proc	near
	segmov	es, ds				;es:di = messageBuffer
	mov	di, offset messageBuffer
	mov	ds:[errorMessageDisplayed], BB_FALSE
	FALL_THRU	AddStringAtESDI
AddStringAtMessageBuffer	endp

;---

AddStringAtESDI	proc	near
SBCS <	uses ax, bx, cx, si, ds						>
DBCS <	uses ax, bx, cx, dx, si, ds					>
	.enter

DBCS <	mov	dl, al				;dl <- KS_DBCS_DEST flag >
DBCS <	andnf	al, not (KS_DBCS_DEST)		;clear flag for enum	>
	LoadVarSeg	ds
	clr	ah
	shl	ax
	mov	si, ax
	clr	bx				;assume no block to unlock

	; is the string in FixedStrings ?

	cmp	ax, FIRST_STRING_IN_MOVABLE_STRINGS*2
	jae	notInFixedStrings

	mov	ax, ds:[fixedStringsSegment]
	mov	ds, ax
	jmp	gotPtr

	; is the string in MovableStrings ?

notInFixedStrings:
	cmp	ax, FIRST_STRING_IN_INIT_STRINGS*2
	jae	notInMovableStrings

	mov	bx, handle MovableStrings
	sub	si, (FIRST_STRING_IN_MOVABLE_STRINGS*2)
	jmp	lockStrings

	; must be in InitStrings

notInMovableStrings:
	mov	bx, handle InitStrings
	sub	si, (FIRST_STRING_IN_INIT_STRINGS*2)
lockStrings:
	call	NearLockDS

gotPtr:
	add	si, ds:[LMBH_offset]
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
if DBCS_PCGEOS
	shr	cx, 1				;cx <- # of chars
;assume always DBCS DEST
;	test	dl, KS_DBCS_DEST		;DBCS dest?
;	jz	charLoop			;branch if SBCS dest
	rep	movsw				;copy me jesus
	LocalPrevChar esdi			;es:di <- point at NULL
;	jmp	afterCopy
;
;charLoop:
;	lodsw					;ax <- character
;EC <	tst	ah				;DBCS char?		>
;EC <	ERROR_NZ CHARACTER_VALUE_TOO_LARGE				>
;	stosb					;store SBCS character
;	loop	charLoop
;	dec	di				;es:di <- point at NULL
;afterCopy:

else
 	rep	movsb
	dec	di				;es:di <- point at NULL
endif

	tst	bx
	jz	noUnlock
	call	MemUnlock
noUnlock:

	.leave
	ret

AddStringAtESDI	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SwitchToKernel

DESCRIPTION:	Switch to the kernel thread

CALLED BY:	UTILITY

PASS:
	none

RETURN:
	ds - idata

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

SwitchToKernel	proc	near
	cld
	LoadVarSeg	ds
	pop	ds:[switchTemporary]
	mov	ss, cs:[kernelData]
	mov	sp, ds:[loaderVars].KLV_handleTableStart
	mov	ds:[currentThread], 0
	jmp	ds:[switchTemporary]
SwitchToKernel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WarningNotice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A place for Swat to place a breakpoint to catch taken
		invocations of the WARNING family of macros

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	control returns 3 bytes beyond the instruction that called
     		us, to skip over the three bytes of "mov ax, number" 

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WarningNotice	proc	far
if	FULL_EXECUTE_IN_PLACE
		call	WritableWarningNotice
endif
		push	bp
		mov	bp, sp
		pushf
		add	{word}ss:[bp+2], 3
		popf
		pop	bp
		ret
WarningNotice	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CWARNINGNOTICE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as above, but for warnings generated by C code

CALLED BY:	(GLOBAL)
PASS:		number	= warning number
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CWARNINGNOTICE	proc	far
if	FULL_EXECUTE_IN_PLACE
		call	WritableWarningNotice
endif
		ret	2		; just return, popping the error number
					;  from the stack
CWARNINGNOTICE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	CFatalError

C DECLARATION:	extern void
			_far _pascal CFatalError(word errorcode);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CFATALERROR	proc	far
	call	FatalError
CFATALERROR_ret	label	near
	.unreached
CFATALERROR	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FatalError

DESCRIPTION:	Handle a fatal error in an application.

CALLED BY:	GLOBAL

PASS:
	ax - error code

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Cheng	10/89		Made non-EC version put up error box

------------------------------------------------------------------------------@

if 0		; no longer used, and errorPrefix isn't filled in anyway...
		; 	-- ardeb 1/25/93
		;
SysNotifyWithMessageBufferAndSystemError	proc	near
	segmov	es, ds
	mov	di, offset messageBuffer
	mov	si, offset errorPrefix
	REAL_FALL_THRU	SysNotifySetDisplayed
SysNotifyWithMessageBufferAndSystemError	endp
endif

SysNotifySetDisplayed	proc	near
	mov	ds:[errorMessageDisplayed], BB_TRUE  ;prevent message on exit
	call	SysNotify		;ignore return value
	ret
SysNotifySetDisplayed	endp

;---

SysNotifyWithMessageBuffer	proc	near
	mov	si, offset messageBuffer
	clr	di
	GOTO	SysNotifySetDisplayed
SysNotifyWithMessageBuffer	endp

;---

AppFatalError	proc	far
		call	FatalError
		.UNREACHED
AppFatalError	endp

FEFrame	struct
    FEF_ax	word
    FEF_ds	word
    FEF_si	word
    FEF_bp	word
    FEF_nret	nptr
    FEF_fret	fptr
    FEF_cCode	word	; pushed CFATALERROR arg
FEFrame	ends

FatalError	proc	near
SSP <	call	StopSingleStepping					>
;SSP <	call	UnhookSingleStepInterrupt				>

if	FULL_EXECUTE_IN_PLACE
	call	WritableFatalError
endif
	push	bp, si, ds, ax
	INT_OFF
	mov	bp, sp
	segmov	ds, cs
	mov	si, ss:[bp].FEF_nret

	cmp	si, offset CFATALERROR_ret	; CFATALERROR?
	jne	checkAppFatalError

	lea	si, ss:[bp].FEF_cCode-1	; ds:si <- pushed error code
	segmov	ds, ss			;  address-1 (see fetchErrorCode...)
	jmp	fetchErrorCode

checkAppFatalError:
	cmp	si, offset FatalError 	; can only return to ourselves if we're
					;  called from AppFatalError, meaning
					;  we were called far.
	jne	fetchErrorCode
	lds	si, ss:[bp].FEF_fret

fetchErrorCode:
	inc	si			; fetch error code from MOV AX that
	lodsw				;  follows call to us
			
	mov	bp, ds
	call	AddErrorInfo		; Figure geode that declared the error
					;  and convert the error code. Returns
					;  ds = idata

	andnf	ds:[exitFlags], not mask EF_RUN_DOS	; Just to make sure...
ifdef	GPC
	ornf	ds:[exitFlags], mask EF_RESET	;also make sure we don't hit DOS
endif

	inc	ds:[errorFlag]		; Record single fault
	jne 	EndGeosDoubleFault	; Double-fault -- get the h*** out

	cmp	ax, HANDLE_TABLE_FULL	; Always print panic message and leave
	je	EndGeos			;  if handle table is full.

	tst	ds:defaultVideoStrategy.segment
	jz	EndGeos			; no video driver loaded, so no way
					;  to display reason for death except
					;  as final words		

if ERROR_CHECK	;**************************************************************
	;
	; Set error cursor first. Save lots o' registers because video
	; driver pointer functions like to biff them.
	;
	; XXX: What if pointer not on default screen. Well. This is just
	; EC code...
	;
	call	PushAll
	clr	cl
	mov	di, DR_VID_SETPTR
	mov	si, offset errorCursor
	call	ds:defaultVideoStrategy
	call	PopAll

	;
	; Now signal the debugger
	;
	int	3
else
	;----------------------------------------------------------------------
	;put up system error box

ifdef	GPC
	mov	ax, mask SNF_REBOOT	; unrecoverable - reboot
else
	mov	ax, mask SNF_EXIT or mask SNF_REBOOT or mask SNF_BIZARRE
endif	; GPC
	call	SysNotifyWithMessageBuffer


endif	;**********************************************************************

	REAL_FALL_THRU	EndGeos
SwatLabel FatalError_end
FatalError	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	EndGeos

DESCRIPTION:	Exit GEOS

CALLED BY:	INTERNAL
		FatalError, SysShutdown

PASS:

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	Cheng	6/89		Code to end PC/GEOS's file interactions with DOS
------------------------------------------------------------------------------@
idata	segment
	irp	lock, <bios>
	    global lock&Lock:ThreadLock
	endm
moduleLocks	nptr.ThreadLock	geodeSem, biosLock, heapSem
idata	ends


EndGeos	proc	near

	INT_OFF
	call	SwitchToKernel			;ds <- idata
	INT_ON				; we're on the kernel thread, so
					;  ain't no context switch gonna happen
					;  now anyways...
SSP <	call	StopSingleStepping					>
SSP <	call	UnhookSingleStepInterrupt				>
SSP <	call	SingleStepUnhookVideo					>
EC <	segmov	es, ds				;avoid ec +segment death>

	clr	bx				;for ResetThreadLock

EC <	mov	ds:[initFlag], 1					>

	;
	; Reset all the module locks -- we don't care about protecting things
	; and cannot afford to block here...
	;
	mov	si, offset moduleLocks
	mov	cx, length moduleLocks
resetLoop:
	lodsw
	xchg	ax, si
	call	ResetThreadLock
	xchg	ax, si
	loop	resetLoop

	; reset stuff

	call	ResetWatchdog

;	There may still be things on the file change notification list.
;	These things will be going away soon, and in any case they won't
;	be able to respond to any notifications, so nuke the GCN list.
;
;	This fixes a crash that occurs if an object in a geode is on
;	the GCN list, and a dirty shutdown occurs - the geode exits, but
;	the object is left on the GCN list.

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	call	GCNListClearList

	mov	si, offset loaderVars.KLV_initFileHan
	call	CloseIfNotAlreadyClosed

;	mov	si, offset loaderFileHandle
;	call	CloseIfNotAlreadyClosed

	call	ResetWatchdog
	call	RemoveGeodes

if UTILITY_MAPPING_WINDOW
	call	ExitSys
endif

	call	ResetWatchdog
	call	ExitFile

	call	ResetWatchdog
	call	ExitFSD

	call	RestoreMovableInt	;reset INT
	
EndGeosDoubleFault label near
	cmp	ds:errorFlag, 1
	jg	tripleFault	; => died exiting system geodes
					;  (should never happen!)

	call	ResetWatchdog
	call	RestoreTextVideoModeIfSplashScreenStillPresent
	call	ExitSystemDrivers

tripleFault:
	; restore these before the MS-DOS time b/c resetting the time
	; on jim's home machine generates an NMI-from-left-field when
	; adjusting the RTC. Since we're pretty much dead, it's rather
	; unfortunate to have us catch the NMI and attempt to put up a
	; SysNotify box about it...
	call	ThreadRestoreExceptions
	call	SysResetIntercepts

	call	RestoreTimerInterrupt
	call	RestoreMSDOSTime

	cmp	ds:errorFlag, -1	; any fatal errors?
	jne	finishSystem		; yes => leave semaphore file for
					;  next time.

	; get back to top-level directory so we may nuke the semaphore file
	mov	bx, offset loaderVars.KLV_topLevelPath
	call	FileChangeDirectory

	mov	dx, offset sysSemaphoreFile
	mov	ah, MSDOS_DELETE_FILE
	int	21h

finishSystem:
	;
	; Let the stub know we're about to make XIP mapping impossible,
	; for example -- ardeb 10/23/95
	;
	mov	ax, DEBUG_SYSTEM_EXITING
	call	FarDebugProcess

	;
	; The Bullet platform has to clean up some EMM and CMOS odds
	; and ends before exiting or restarting.
	; We may end up mapping out part (or all) of kcode, so copy it to
	; RAM...
	;
if	FULL_EXECUTE_IN_PLACE
	call	CopyKCodeToRAM		
	mov	bx, handle kcode		;Change the address in the
	mov	ds:[bx].HM_addr, ax		; handle table, so the task
						; switch driver can get to it
		;Returns AX = kcode segment
	mov	ss:[TPD_callVector].segment, ax				
	mov	ss:[TPD_callVector].offset, offset afterCopy		
	jmp	ss:[TPD_callVector]	;Jump to "afterCopy" in RAM...	
afterCopy:
endif
BULLET <call	BulletCleanUp						>

	test	ds:exitFlags, mask EF_RUN_DOS
	jz	quit
	mov	cx, TRUE			; shutdown confirmed
	mov	di, DR_TASK_SHUTDOWN_COMPLETE
	mov	si, offset loaderVars
	jmp	ds:[taskDriverStrategy]

quit:
	;
	; Change to the boot directory if we ever located it.
	;
	cmp	ds:loaderVars.KLV_bootDrive, -1
	je	showReason
EC <	mov	ds:loaderVars.KLV_bootDrive, -1	; In case bootupPath is hosed >
	mov	bx, offset loaderVars.KLV_bootupPath
	call	FileChangeDirectory

showReason:
	;
	; If we're supposed to give the user a reason for the exit, do so now
	;
	tst	ds:[errorMessageDisplayed]
	jnz	exitAppropriately
	tst	ds:[messageBuffer]
	jz	exitAppropriately

	mov	dx, offset messageBuffer
if DBCS_PCGEOS
	;
	; do brute force DBCS->SBCS conversion
	;
	push	si
	mov	di, dx
	mov	si, dx
	segmov	es, ds
convertLoop:
	lodsw
	stosb
	tst	ax
	jnz	convertLoop
	pop	si
endif
	call	CallInt21PrintStringReplaceDollarSign

	mov	dx, offset crlfString
	call	CallInt21PrintStringReplaceDollarSign

exitAppropriately:

if	EMM_XIP
	mov	dx, ds:[loaderVars].KLV_emmHandle			
	CallEMMDriver	EMF_FREE
endif

	mov	al, ds:[exitFlags]

	test	al, mask EF_OLD_EXIT
	jnz	useOldExit
	test	al, mask EF_RESET
	jnz	resetMachine
	test	al, mask EF_RESTART
	jnz	reloadSystem
	test	al, mask EF_POWER_OFF
	jnz	powerOff

if	NO_DOS
	;
	; the kernel should probably never exit, it should just
	; reboot the machine.
	;
	test	ds:[sysConfig], mask SCF_UNDER_SWAT
	jz	resetMachine
endif

	mov	ax,4c00h		;exit program
	int	21h

useOldExit:
	; Use DOS 1.x exit style, since running under DOS 1.x (else wouldn't be
	; exiting this way). Must have CS = PSP, so just arrange to return to
	; the int 20h so nicely placed there for our use.
	push	ds:loaderVars.KLV_pspSegment
	mov	ax, offset PSP_int20h
	push	ax
	retf



resetMachine:
	; Reset the machine now we've shut down.

if 0	; Doesn't work on many machines. The floppy just spins...
	int	19h
else
	; set WARM_START flag in BIOS data area and vault to the processor
	; reset vector up in high memory.
	;
	; XXX: There may be '286 or '386 machines that have POST in a
	; 64k ROM up at the high end of the 16Mb address space, since
	; the 286 actually starts out with the CS base address being
	; ff0000. If so, we're hosed...
	mov	ax, BIOS_DATA_SEG
	mov	es, ax
	mov	es:[BIOS_RESET_FLAG], BRF_WARM_START
	jmp	BIOSSeg:Reset
endif


reloadSystem:
	; Set up to reload the system.
	jmp	ds:[reloadSystemVector]

powerOff:
	hlt
	jmp	powerOff

EndGeos	endp
CloseIfNotAlreadyClosed	proc	near
	clr	bx
	xchg	bx, ds:[si]
	tst	bx
	jz	done
;	cmp	bx, ds:[loaderVars].KLV_handleTableStart
;	jb	done
	clr	ax
	call	FileCloseFar
done:
	ret

CloseIfNotAlreadyClosed	endp

;---------

CallInt21PrintStringReplaceDollarSign	proc	near
	mov	di, dx
	segmov	es, ds
	clr	ax
	mov	cx, -1
	repne	scasb
	mov	{char}es:[di-1], '$'

	mov	ah, MSDOS_DISPLAY_STRING
	int	21h
	ret
CallInt21PrintStringReplaceDollarSign	endp

;---------

idata	segment
crlfString	char	C_CR, C_LF, 0
idata	ends

;---------

; Completely reset the module lock pointed to by ds:si. Doesn't bother to
; wake anything up as we'll never go to Dispatch again.

	; bx = 0
ResetThreadLock proc near
	mov	ds:[si].TL_sem.Sem_queue, bx
	mov	ds:[si].TL_nesting, bx
	inc	bx				;bx = 1
	mov	ds:[si].TL_sem.Sem_value, bx
	dec	bx
	dec	bx				;bx = -1
	mov	ds:[si].TL_owner, bx
	inc	bx				;bx = 0
	ret
ResetThreadLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetWatchdog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the watchdog timer to its starting value.

CALLED BY:	(EXTERNAL) EndGeos, RemoveGeodes, ExitFile, ExitSystemDrivers
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	watchdogTimer is set to WATCHDOG_TIMER

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetWatchdog	proc	far
	uses	ds
	.enter
	call	LoadVarSegDS
	mov	ds:[watchdogTimer], WATCHDOG_TIMER
	.leave
	ret
ResetWatchdog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreTextVideoModeIfSplashScreenStillPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is no default video driver loaded, and the splash
		screen is still up, then restore the original text mode
		before exiting to DOS.

CALLED BY:	EndGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;from Video/VidCom/vidcomConstant.def

VIDEO_BIOS		=	10h		; video bios interrupt number
SET_VMODE		=	00h		; set video mode function #

RestoreTextVideoModeIfSplashScreenStillPresent	proc	near

	;first, see if we even displayed a splash screen at all

	call	LoadVarSegDS
	cmp	ds:[loaderVars].KLV_curSimpleGraphicsMode, SSGM_NONE
	je	done			;skip if not...

	;We did. Now see if a default video driver is loaded. If so,
	;it will restore the video mode as it exits.

	cmp	ds:[defaultDrivers].DDT_video, 0
	jne	done			;skip if there is a video driver...

	; set the previous video mode.  The VESA standard says that
	; this should work with VESA boards as well...
	; (VESA Super VGA Standard VS891001, page 6, 10/1/89)

	mov	ah, SET_VMODE
	mov	al, ds:[loaderVars].KLV_initialTextMode
	cmp	al, SITM_UNKNOWN
	je	done			;skip if the loader was baffled by it...

	int	VIDEO_BIOS

done:
	ret
RestoreTextVideoModeIfSplashScreenStillPresent	endp

;------------

if	HACK_STUFF_VIDEO

;*****
; Call like this:
;	HackVideo	eg3, <"After iniFileClosed">
;*****

idata	segment
hackLine	word	0
idata	ends

	;pass: idata:si = string (null terminated)

kcode	segment

HackVideoOut	proc	near	uses ax, cx, dx, di, ds, es
	.enter
	pushf

	LoadVarSeg	ds
	mov	di, 0xb800
	mov	es, di			;es = video ram

	; compute address

	mov	ax, 80*2
	mul	ds:[hackLine]		;ax = offset
	mov	di, ax			;es:di = dest

	mov	cx, 80
drawLoop:
	lodsb
	tst	al
	jz	stringEnd
	call	HackChar
	jmp	drawLoop

stringEnd:
	mov	al, {byte} ds:[biosWaitSem].Sem_value
	add	al, '0'
	call	HackChar
	mov	al, {byte} ds:[dosLock].TL_sem.Sem_value
	add	al, '0'
	call	HackChar
	mov	al, {byte} ds:[heapSem].TL_sem.Sem_value
	add	al, '0'
	call	HackChar

	mov	al, 'g'
	cmp	ds:[oldInt15Vector].segment, 0xf000
	jnz	vectorBad
	cmp	ds:[oldInt15Vector].offset, 0xf859
	jz	vectorGood
vectorBad:
	mov	al, 'B'
vectorGood:
	call	HackChar
	
	pushf
	pop	ax
	test	ax, mask CPU_INTERRUPT
	mov	al, '0'
	jz	noInts
	inc	al
noInts:
	call	HackChar

	mov	al, ' '
spaceLoop:
	stosb
	inc	di
	loop	spaceLoop

	inc	ds:[hackLine]

	popf
	.leave
	ret
HackVideoOut	endp

HackChar	proc	near
	stosb
	inc	di			;skip attributes byte
	dec	cx
	ret
HackChar	endp

kcode ends

endif

if	FULL_EXECUTE_IN_PLACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyKCodeToRAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the kcode resource to RAM, before it is mapped out
		as part of the exit procedure. We don't bother freeing the
		memory we allocate, as we're exiting, so we don't need to...

CALLED BY:	GLOBAL
PASS:		ds - dgroup
RETURN:		ax - segment address where we copied kcode...
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyKCodeToRAM	proc	near	uses	bx, cx, si, di, es, ds
	.enter

;	Allocate a block large enough to hold the kcode resource

	mov	bx, handle kcode
	mov	ax, ds:[bx].HM_size
	mov	cl, 4
	shl	ax, cl		;AX = byte size of kcode resource
	push	ax
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	pop	cx		;CX <- size of kcode resource

;	Copy kcode into the block

	mov	es, ax		;ES:DI <- dest to copy kcode
	clr	di
	segmov	ds, cs
	clr	si
	shr	cx, 1
	rep	movsw
	mov	ax, es	
	.leave
	ret
CopyKCodeToRAM	endp
endif

kcode	ends
