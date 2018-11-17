COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel -- System Performance
FILE:		sysStats.asm

AUTHOR:		Adam de Boor, Apr  6, 1989

ROUTINES:
	Name			Description
	----			-----------
   GLB	SysInfo			Get general system information
   GLB	SysStatistics		Get system performance statistics
   EXT  SysUpdateStats		Update statistics info

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 6/89		Initial revision


DESCRIPTION:
	Functions for analyzing system performance


	$Id: sysStats.asm,v 1.1 97/04/05 01:14:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysGetInfo

DESCRIPTION:	Get general system information

CALLED BY:	GLOBAL

PASS:
	ax - SysGetInfoType (note that there are two groups of values for
	     this enum, global and internal)

RETURN:
	ax (or dx:ax) - value dependent on SysGetInfoType passed

	SGIT_lastHandle

DESTROYED:	dx, if not holding value

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
------------------------------------------------------------------------------@

SysGetInfo	proc	far	uses bx, cx, si, di, ds
	.enter
	LoadVarSeg	ds

	mov	bx, size globalSysGetInfoTable
		CheckHack <SysGetInfoTypeInternal eq 0x8000>
	tst	ax				;internal?
	jns	checkParam			;skip if not...

	; convert ax to index into combined table (as opposed to having to
	; know later which table to use) and load bx with the limit against
	; which to check the index
	sub	ax, SysGetInfoTypeInternal - (size globalSysGetInfoTable)
	mov	bx, size globalSysGetInfoTable + size internalSysGetInfoTable

checkParam:
	clr	dx			; destroys dx in EC
	xchg	ax, bx			; ax <- table limit, bx <- index
	cmp	bx, ax
NEC <	mov	ax, dx			; dxax <- 0, on error		>
NEC <	jae	done							>
EC <	ERROR_AE SYS_GET_INFO_BAD_PARAMETER				>
	mov	ax, ds:[loaderVars].KLV_lastHandle  ;pass last handle
	call	cs:[globalSysGetInfoTable][bx]

NEC <done:								>
	.leave
	ret

SysGetInfo	endp

globalSysGetInfoTable	nptr	\
	SGI_TotalHandles,			;SGIT_TOTAL_HANDLES
	SGI_HeapSize,				;SGIT_HEAP_SIZE
	SGI_LargestFreeBlock,			;SGIT_LARGEST_FREE_BLOCK
	SGI_TotalCount,				;SGIT_TOTAL_COUNT
	SGI_NumberOfVolumes,			;SGIT_NUMBER_OF_VOLUMES
	SGI_TotalGeodes,			;SGIT_TOTAL_GEODES
	SGI_NumberOfProcesses,			;SGIT_NUMBER_OF_PROCESSES
	SGI_NumberOfLibraries,			;SGIT_NUMBER_OF_LIBRARIES
	SGI_NumberOfDrivers,			;SGIT_NUMBER_OF_DRIVERS
	SGI_CPUSpeed,				;SGIT_CPU_SPEED
	SGI_SystemDisk,				;SGIT_SYSTEM_DISK
	SGI_UIProcess,				;SGIT_UI_PROCESS
	SGI_CounterAtLastInput,			;SGIT_COUNTER_AT_LAST_INPUT
	SGI_ScreenSaverDelay			;SGIT_SCREEN_SAVER_DELAY

internalSysGetInfoTable	nptr	\
	SGI_HandleTableStart,			;SGIT_HANDLE_TABLE_START
	SGI_HandleTableSegment,			;SGIT_HANDLE_TABLE_SEGMENT
	SGI_LastHandle,				;SGIT_LAST_HANDLE
	SGI_BIOSLock,				;SGIT_BIOS_LOCK
	SGI_InitialTextMode,			;SGIT_INITIAL_TEXT_MODE
	SGI_DefaultSimpleGraphicsMode,		;SGIT_DEFAULT_SIMPLE_GRAPHICS_MODE
	SGI_CurrentSimpleGraphicsMode,		;SGIT_CURRENT_SIMPLE_GRAPHICS_MODE
	SGI_NumberOfFreeHandles,		;SGIT_NUMBER_OF_FREE_HANDLES
	SGI_Error,				;SGIT_ERROR
	SGI_LastDiskAccess,			;SGIT_LAST_DISK_ACCESS
	SGI_LoaderVarsAddr,			;SGIT_LOADER_VARS_ADDRESS
	SGI_KCodeSegment,			;SGIT_KCODE_SEGMENT
	SGI_XIPHeaderSegment,			;SGIT_XIP_HEADER_SEGMENT
	SGI_SwapFreeSize,			;SGIT_SWAP_FREE_SIZE
	SGI_HeapFreeSize			;SGIT_HEAP_FREE_SIZE

	ForceRef	internalSysGetInfoTable

;---

SGI_TotalHandles	proc	near
	sub	ax, ds:[loaderVars].KLV_handleTableStart
	shr	ax 
	shr	ax
	shr	ax
	shr	ax
	ret
SGI_TotalHandles	endp

;---

SGI_HeapSize	proc	near
	mov	ax, ds:[loaderVars].KLV_heapEnd
	sub	ax, ds:[loaderVars].KLV_heapStart
	ret
SGI_HeapSize	endp

;---

SGI_LargestFreeBlock	proc	near
	call	FarPHeap
	mov	ax, 0xffff
	clr	cx			;not fixed
	call	FindFree
	mov	ax, ds:[bx].HM_size
	call	FarVHeap
	ret
SGI_LargestFreeBlock	endp

;---

SGI_TotalCount	proc	near
	mov	ax, ds:[totalCount].low
	mov	dx, ds:[totalCount].high
	ret
SGI_TotalCount	endp

;---

SGI_NumberOfVolumes	proc	near
	.enter

	call	FSDDriveGetCount

	.leave
	ret
SGI_NumberOfVolumes	endp

;---

SGI_TotalGeodes	proc	near
	mov	ax, ds:[geodeCount]
	ret
SGI_TotalGeodes	endp

;---

SGI_NumberOfProcesses	proc	near
	mov	ax, ds:[geodeProcessCount]
	ret
SGI_NumberOfProcesses	endp

;---

SGI_NumberOfLibraries	proc	near
	mov	ax, ds:[geodeLibraryCount]
	ret
SGI_NumberOfLibraries	endp

;---

SGI_NumberOfDrivers	proc	near
	mov	ax, ds:[geodeDriverCount]
	ret
SGI_NumberOfDrivers	endp

;---

SGI_CPUSpeed	proc	near
	mov	ax, ds:[cpuSpeed]
	ret
SGI_CPUSpeed	endp

;------

SGI_SystemDisk	proc	near
	mov	ax, ds:[topLevelDiskHandle]
	ret
SGI_SystemDisk	endp

;------

SGI_UIProcess	proc	near
	mov	ax, ds:[uiHandle]
	ret
SGI_UIProcess	endp

;------

SGI_CounterAtLastInput	proc	near
	movdw	dxax, ds:[sysCounterAtLastInput]
	ret
SGI_CounterAtLastInput	endp

;------

SGI_ScreenSaverDelay	proc	near
	mov	ax, ds:[screenSaverDelay]
	ret
SGI_ScreenSaverDelay	endp

;------

;------
;------

SGI_HandleTableStart	proc	near
	mov	ax, ds:[loaderVars].KLV_handleTableStart
	ret
SGI_HandleTableStart	endp

;---

SGI_HandleTableSegment	proc	near
	mov	ax, ds
	ret
SGI_HandleTableSegment	endp

;---

SGI_LastHandle	proc	near
	ret
SGI_LastHandle	endp

;---

SGI_BIOSLock	proc 	near
	mov	ax, offset biosLock
	mov	dx, ds
	ret
SGI_BIOSLock	endp

SGI_InitialTextMode	proc	near
	mov	al, ds:[loaderVars].KLV_initialTextMode
	ret
SGI_InitialTextMode	endp

SGI_DefaultSimpleGraphicsMode	proc	near
	mov	al, ds:[loaderVars].KLV_defSimpleGraphicsMode
	ret
SGI_DefaultSimpleGraphicsMode	endp

SGI_CurrentSimpleGraphicsMode	proc	near
	mov	al, ds:[loaderVars].KLV_curSimpleGraphicsMode
	ret
SGI_CurrentSimpleGraphicsMode	endp

SGI_NumberOfFreeHandles	proc	near
	mov	ax, ds:[loaderVars].KLV_handleFreeCount
	ret
SGI_NumberOfFreeHandles	endp


SGI_Error	proc	near
	mov	ax, ds:errorFlag
	ret
SGI_Error	endp

SGI_LastDiskAccess proc near
	movdw	dxax, ds:[diskLastAccess]
	ret
SGI_LastDiskAccess endp

SGI_LoaderVarsAddr proc	near
	mov	dx, segment loaderVars
	mov	ax, offset loaderVars
	ret
SGI_LoaderVarsAddr endp

SGI_KCodeSegment proc near
	mov	ax, segment kcode
	ret
SGI_KCodeSegment endp

SGI_XIPHeaderSegment proc near
	mov	ax, ds:[loaderVars].KLV_xipHeader
	ret
SGI_XIPHeaderSegment endp


SGI_HeapFreeSize	proc	near
	; Convert paragraphs to bytes
	;
		clr	dx
		mov	ax, ds:[loaderVars].KLV_heapFreeSize
		shldw	dxax
		shldw	dxax
		shldw	dxax
		shldw	dxax
		ret
SGI_HeapFreeSize	endp

kcode	ends


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysStatistics

DESCRIPTION:	Get system performance statistics

CALLED BY:	GLOBAL

PASS:
	es:di	= Address of buffer to which SysStatus structure should
		  be copied.

RETURN:
	buffer filled with statistics from the last second.

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
------------------------------------------------------------------------------@

SysStatistics	proc	far	uses ds, si, di, cx
	.enter
	
if	FULL_EXECUTE_IN_PLACE
EC <		push	bx, si				>
EC <		movdw	bxsi, esdi			>
EC <		call	ECAssertValidFarPointerXIP	>
EC <		pop	bx, si				>
endif
	
	LoadVarSeg	ds
	INT_OFF
	mov	si, offset lastStats
	mov	cx, size lastStats/2	| CheckHack <not (size lastStats AND 1)>
	rep	movsw
	INT_ON
	.leave
	ret
SysStatistics	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysUpdateStats

DESCRIPTION:	Update system statistics

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	ds - kernel data

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
------------------------------------------------------------------------------@

SysUpdateStats	proc	near	uses si, di, es, cx
	.enter
	segmov	es, ds, si
	mov	si, offset curStats
	mov	di, offset lastStats
	mov	cx, offset SS_runQueue/2
	rep	movsw

	mov	di, offset curStats
	clr	ax
	mov	cx, offset SS_runQueue/2
	rep	stosw

	; count runable threads

	mov	bx,offset runQueue - HT_nextQThread
	cmp	ds:[currentThread], ax		; running kernel thread?
						;  (faster than tst)
	jne	countCurrent			; no -- count current thread
						;  as real
runQueueLoop:
	mov	bx,ds:[bx][HT_nextQThread]
	tst	bx
	jz	done

countCurrent:
	inc	ax
	jmp	runQueueLoop

done:
	mov	ds:[lastStats].SS_runQueue,ax
	.leave
	ret
SysUpdateStats	endp
