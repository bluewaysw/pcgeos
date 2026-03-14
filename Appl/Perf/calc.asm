COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:        Perf    (Performance Meter)
FILE:           calc.asm (calculates new stats)

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Tony, Adam 1990         Initial version
	Eric    5/91            more stat types..., cleanup

DESCRIPTION:
	This file source code for the Perf application. This code will
	be assembled by Esp, and then linked by the Glue linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: calc.asm,v 1.1 97/04/04 16:26:58 newdeal Exp $

------------------------------------------------------------------------------@

PerfCalcStatCode segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:       PerfCalcNewStats

DESCRIPTION:    Determine new statistics

CALLED BY:      PerfTimerExpired

PASS:           ds      = dgroup
		es      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

Copy the following structure into our rotating table:

SysStats        struc
    SS_idleCount        dword           ; Number of "idle ticks" in the last
					;  second. When used in combination
					;  with the total idle count returned
					;  by SysInfo, this tells you how busy
					;  the CPU is.
    SS_swapOuts         SysSwapInfo     ; Outward-bound swap activity
    SS_swapIns          SysSwapInfo     ; Inward-bound swap activity
				SysSwapInfo     struc
					SSI_paragraphs          word
					SSI_blocks              word
				SysSwapInfo     ends
    SS_contextSwitches  word            ; Number of context switches during the
					;  last second.
    SS_interrupts       word            ; Number of interrupts during the last
					;  second.
    SS_waitPostCalls    word            ; Number of wai/post calls during the
					; last second
    SS_runQueue         word            ; Number of runnable threads at the
					;  end of the last second. MUST BE
					;  LAST FIELD
SysStats        ends


REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Adam/Tony 1990          Initial version
	Eric    4/27/91         improvements, doc update

------------------------------------------------------------------------------@
;get new statistics

PerfCalcNewStats        proc    far     ;in PerfCalcStatCode resource

	;call kernel routine to copy the above structure to es:di
	;(See /staff/pcgeos/Include/sysstats.def)

	mov     di, offset lastStats
	call    SysStatistics

	;for each statistic that we care about, we must copy the raw value
	;into [numericArray], so that we can display that number if necessary.
	;We also must copy the adjusted value into our historical array.

	call    PerfCalcContextSwitches
	call    PerfCalcLoadAverage
	call    PerfCalcInterrupts
	call    PerfCalcCPUUsage

	;memory usage

	call    CalcMemoryStatistics
	call    PerfCalcHeapAllocation
	call    PerfCalcHeapFixed
	call    PerfCalcHeapFragmentation

	call    PerfCalcSwapAllocation
	call    PerfMCalcSwapOut
	call    PerfCalcSwapIn

	;other stuff

	call    PerfCalcPPPStatistics
	call	PerfCalcFreeHandles
		
	ret
PerfCalcNewStats        endp


COMMENT @----------------------------------------------------------------------

FUNCTION:       PerfCalcXXXXXX

DESCRIPTION:    These routines calculate our new statistic values

CALLED BY:      PerfCalcNewStats

PASS:           ds      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Adam/Tony 1990          Initial version
	Eric    4/27/91         improvements, doc update

------------------------------------------------------------------------------@

PerfCalcContextSwitches proc    near
	mov     ax, ds:[lastStats].SS_contextSwitches
					;ax = # of context switches in last sec
	push    ax
	call    MultAXBy10              ;multiple by 10 so is decimal
					;(no fractional portion)
	mov     ds:[numericLast].PSS_switches, ax
	pop     ax

	add     ax,4                    ;divide by 8, rounding first (+4)
	shr     ax,1
	shr     ax,1
	shr     ax,1
	mov     ds:[statArray].PSS_switches, ax
	ret
PerfCalcContextSwitches endp


idata   segment
lastLoadAverage BBFixed
idata   ends

LOAD_AVERAGE_DECAY      = 4
LOAD_AVERAGE_DECAY_BASE = 2

PerfCalcLoadAverage     proc    near

	; calculate the load average via:
	;       load average = (# runable threads)   + (old load average)*15
	;                      ---------------------------------------------
	;                                               16

	mov     ax, {word} ds:[lastLoadAverage]
	mov     cx, LOAD_AVERAGE_DECAY-1
	mul     cx                              ;dx:ax = result
	add     ax, LOAD_AVERAGE_DECAY/2
	add     ah, ds:[lastStats].SS_runQueue.low
	mov     cl, LOAD_AVERAGE_DECAY_BASE
	shr     ax, cl
	mov     {word} ds:[lastLoadAverage], ax

	push    ax
	call    MultAXBy10              ;multiple by 10 so is decimal
					;(no fractional portion)

	; round BBFixed to int

	add     ax, 128
	mov     al, ah
	clr     ah
	mov     ds:[numericLast].PSS_load, ax
	pop     ax

	shl     ax, 1                   ;multiply by 4, to make the
	shl     ax, 1                   ;change visible
	mov     al, ah
	clr     ah
	mov     ds:[statArray].PSS_load, ax
	ret
PerfCalcLoadAverage     endp


PerfCalcInterrupts      proc    near
	mov     ax, ds:[lastStats].SS_interrupts

	push    ax
	call    MultAXBy10              ;multiple by 10 so is decimal
					;(no fractional portion)
	mov     ds:[numericLast].PSS_interrupts, ax
	pop     ax

	add     ax, 16                  ;to round the result
	mov     cl, 5                   ;divide by 32
	shr     ax, cl

	mov     ds:[statArray].PSS_interrupts, ax
	ret
PerfCalcInterrupts      endp


PerfCalcCPUUsage        proc    near
					;dx:ax = kdata:idleCount for last second
	mov     ax, ds:[lastStats].SS_idleCount.low
	mov     dx, ds:[lastStats].SS_idleCount.high

	tst	ds:[totalCountPure]
	jz	noPure
	mov	dx, 1000
	mul	dx
noPure:
	;calculate idle amount as ratio of totalCount, then multiply by
	;1000, so that we get a result between 0 and 999.

	;idle average (0-999) = idleCount / totalCountDivBy1000

	mov     si, ds:[totalCountDivBy1000]    ;compute idle average
	tst     si
	jnz     notZero                 ;don't divide by zero!
	inc     si                      ;make it at least one
notZero:
	div     si                      ;ax.dx = dx:ax / totalCountDivBy1000

	;round up, so 99.9999% idle means 100.0% idle.

	tst     dx
	jns     5$

	inc     ax

5$:     ;ax = idle ratio: from (1000 to 0)

	;if for any reason this value is too high, let's normalize it.

	cmp     ax, 1001                ;too big?
	jb      10$                     ;skip if not...

	mov     ax, 1000                ;set to MAX value

10$:    
	tst	ds:[totalCountPure]
	jz	pure

	mov	dx, 12
	mul	dx
	shr	ax, 3
pure:
	cmp     ax, 1001                ;too big?
	jb      11$                     ;skip if not...

	mov     ax, 1000                ;set to MAX value

11$:    

	;convert from idle time to used time (0 to 1000)
	sub     ax, 1000                ;convert from idle time to usage time
	neg     ax

EC <    cmp     ax, 1001                ;too big?                       >
EC <    ERROR_GE PERF_ERROR_IDLE_COUNT_TOO_BIG                          >

					;store numeric value
	mov     ds:[numericLast].PSS_cpuUsage, ax

	;now, normalize the paragraph value so that graph top = 100%

	clr     dx                      ;
	mov     si, 1001 / GRAPH_HEIGHT
	div     si                      ; now ax has idle (0-24)

	;even so, we will get an overflow sometimes, Because 1001/GRAPH_HEIGHT
	;is an integer value in the division.

	cmp     ax, GRAPH_HEIGHT        ;too big?
	jl      50$

	mov     ax, GRAPH_HEIGHT - 1

50$:
	mov     ds:[statArray].PSS_cpuUsage, ax
	ret
PerfCalcCPUUsage        endp


PerfCalcHeapAllocation  proc    near
	tst     ds:[heapTotalMemSize]   ;did we collect any info?
	jz      noInfo                  ;skip if not...

	;set dx:ax = allocated size, including kernel, in paragraphs.
	;And then convert (*10/64) so that we can display the number as Kbytes.

	mov     ax, ds:[heapAllocatedMemSize]

;no longer necessary
;       add     ax, ds:[kernelSize]

	call    MultAXBy10AndDivideBy64
	mov     ds:[numericLast].PSS_heapAllocated, ax

	;now calculate allocated size as ration of total heap size

					;dx:ax = heapAllocatedMemSize*1000h
	mov     dx, ds:[heapAllocatedMemSize]
	clr     ax

	;calculate used amount as ratio of totalSize.
	;ratio (0-65535) = allocated*65536 / total

	mov     si, ds:[heapTotalMemSize]
	div     si                      ;ax = dx:ax / si

;Old code which showed memory usage as a percentage
;       ;calculate % times 10 (999-0)
;
;       push    ax
;       mov     si, 65536 / 1000
;       clr     dx
;       div     si                      ;now ax has %
;                                       ;store numeric value
;       mov     ds:[numericLast].PSS_heapAllocated, ax
;       pop     ax

	;calculate height of bar (essentially multiplying by GRAPH_HEIGHT,
	;and then dividing by 65536)

	mov     si, 65536 / GRAPH_HEIGHT
	clr     dx
	div     si                      ; now ax has %
	mov     ds:[statArray].PSS_heapAllocated, ax
	ret

noInfo: ;we have no info on this statistic. Just zero-out the graph.
	clr     ax
	mov     ds:[numericLast].PSS_heapAllocated, ax
	mov     ds:[statArray].PSS_heapAllocated, ax
	ret     
PerfCalcHeapAllocation  endp


PerfCalcHeapFixed       proc    near
	tst     ds:[heapTotalMemSize]   ;did we collect any info?
	jz      noInfo                  ;skip if not...

	;set dx:ax = fixed block size, including kernel, in paragraphs.
	;And then convert (*10/64) so that we can display the number as Kbytes.

	mov     ax, ds:[heapFixedMemSize]

;no longer necessary
;       add     ax, ds:[kernelSize]

	call    MultAXBy10AndDivideBy64
	mov     ds:[numericLast].PSS_heapFixed, ax

	;now calculate allocated size as ration of total heap size

					;dx:ax = heapFixedMemSize*1000h
	mov     dx, ds:[heapFixedMemSize]
	clr     ax

	;calculate fixed amount as ratio of totalSize.
	;ratio (0-65535) = fixed*65536 / total

	mov     si, ds:[heapTotalMemSize]
	div     si                      ;ax = dx:ax / si

;Old code which showed memory usage as a percentage
;       ;calculate % times 10 (999-0)
;
;       push    ax
;       mov     si, 65536 / 1000
;       clr     dx
;       div     si                      ;now ax has %
;                                       ;store numeric value
;       mov     ds:[numericLast].PSS_heapFixed, ax
;       pop     ax

	;calculate height of bar (essentially multiplying by GRAPH_HEIGHT,
	;and then dividing by 65536)

	mov     si, 65536 / GRAPH_HEIGHT
	clr     dx
	div     si                      ; now ax has %
	mov     ds:[statArray].PSS_heapFixed, ax
	ret

noInfo: ;we have no info on this statistic. Just zero-out the graph.
	clr     ax
	mov     ds:[numericLast].PSS_heapFixed, ax
	mov     ds:[statArray].PSS_heapFixed, ax
	ret     
PerfCalcHeapFixed       endp


PerfCalcHeapFragmentation       proc    near
	tst     ds:[heapTotalMemSize]   ;did we collect any info?
	jz      noInfo                  ;skip if not...

	;set dx:ax = frag size in paragraphs.
	;And then convert (*10/64) so that we can display the number as Kbytes.

	mov     ax, ds:[heapUpperFreeMemSize]
	call    MultAXBy10AndDivideBy64
	mov     ds:[numericLast].PSS_heapFragmentation, ax

	;now calculate fragmented size as ratio of total heap size

					;dx:ax = heapUpperFreeMemSize*1000h
	mov     dx, ds:[heapUpperFreeMemSize]
	clr     ax

	;calculate used amount as ratio of totalSize.
	;ratio (0-65535) = allocated*65536 / total

	mov     si, ds:[heapTotalMemSize]
	div     si                      ;ax = dx:ax / si

;Old code which showed memory usage as a percentage
;       ;calculate % times 10 (999-0)
;
;       push    ax
;       mov     si, 65536 / 1000
;       clr     dx
;       div     si                      ;now ax has %
;                                       ;store numeric value
;       mov     ds:[numericLast].PSS_heapFragmentation, ax
;       pop     ax

	;calculate height of bar (essentially multiplying by GRAPH_HEIGHT,
	;and then dividing by 65536)

	mov     si, 65536 / GRAPH_HEIGHT
	clr     dx
	div     si                      ; now ax has %
	mov     ds:[statArray].PSS_heapFragmentation, ax
	ret

noInfo: ;we have no info on this statistic. Just zero-out the graph.
	clr     ax
	mov     ds:[numericLast].PSS_heapFragmentation, ax
	mov     ds:[statArray].PSS_heapFragmentation, ax
	ret     
PerfCalcHeapFragmentation       endp




PerfCalcSwapAllocation  proc    near

	push    es
	mov     si, offset dgroup:swapMaps
	mov     ds:[numericLast].PSS_swapFileAllocated, 0
	mov     ds:[numericLast].PSS_swapMemAllocated, 0

mapLoop:
	mov     cx, ds:[si].PSD_map
	jcxz    done

	mov     di, offset PSS_swapMemAllocated

	tst     ds:[si].PSD_disk
	jz      figureAlloc

	mov     di, offset PSS_swapFileAllocated

figureAlloc:
	mov     es, cx
	mov     ax, es:[SM_total]
	sub     ax, es:[SM_numFree]
	mul     es:[SM_page]
	mov     al, ah
	mov     ah, dl
	shr     dh
	rcr     ax
	shr     dh
	rcr     ax
	add     {word}ds:[numericLast][di], ax
	add     si, size PerfSwapDriver
	cmp     si, offset dgroup:swapMaps + size swapMaps
	jb      mapLoop

done:
	mov     di, offset PSS_swapMemAllocated
	mov     si, ds:[maxMemSwap]
	call    CalcSwapStuff

	mov     di, offset PSS_swapFileAllocated
	mov     si, ds:[maxDiskSwap]
	call    CalcSwapStuff
	pop     es

	ret
PerfCalcSwapAllocation  endp


CalcSwapStuff   proc    near
	; di = offset in numericLast and statArray of appropriate field
	; si = total allocatable space of this type.

	mov     ax, {word}ds:[numericLast][di]
	push    ax
	call    MultAXBy10
	mov     {word}ds:[numericLast][di], ax
	pop     dx

	clr     ax
	tst     si
	jz      storeRes

	cmp     dx, si
	je      maxOut          ; avoid quotient-overflow...

	div     si
	clr     dx              ; NOT cwd -- number be unsigned, mahn
	mov     si, 65536/100
	div     si
	clr     dx              ; NOT cwd -- number be unsigned, mahn
	mov     si, 100/GRAPH_HEIGHT
	div     si
	cmp     ax, GRAPH_HEIGHT
	jl      storeRes

maxOut:
	mov     ax, GRAPH_HEIGHT-1

storeRes:
	mov     {word}ds:[statArray][di], ax
	ret
CalcSwapStuff   endp


PerfMCalcSwapOut        proc    near
	mov     ax, ds:[lastStats].SS_swapOuts.SSI_paragraphs
					;ax = number of paragraphs swapped out

	;divide by 64 to get the amount in K (there are 64 paragraphs in a K)

	push    ax

	mov     cl, 6                   ;divide by 64
	shr     ax, cl
	call    MultAXBy10              ;multiple by 10 so is decimal
					;store numeric value
	mov     ds:[numericLast].PSS_swapOut, ax
	pop     ax

	;now, normalize the paragraph value so that graph top = 256K

	mov     si, (262144/16) / GRAPH_HEIGHT
	clr     dx
	div     si                      ; now ax has value

	cmp     ax, GRAPH_HEIGHT
	jl      60$

	mov     ax, GRAPH_HEIGHT-1
60$:
	mov     ds:[statArray].PSS_swapOut, ax
	ret
PerfMCalcSwapOut        endp


PerfCalcSwapIn  proc    near
	mov     ax, ds:[lastStats].SS_swapIns.SSI_paragraphs
					;ax = number of paragraphs swapped out

	;divide by 64 to get the amount in K (there are 64 paragraphs in a K)

	push    ax

	mov     cl, 6                   ;divide by 64
	shr     ax, cl
	call    MultAXBy10              ;multiple by 10 so is decimal
					;store numeric value
	mov     ds:[numericLast].PSS_swapIn, ax
	pop     ax

	;now, normalize the paragraph value so that graph top = 128K

	mov     si, (262144/16) / GRAPH_HEIGHT
	clr     dx
	div     si                      ; now ax has value

	cmp     ax, GRAPH_HEIGHT
	jl      60$

	mov     ax, GRAPH_HEIGHT-1
60$:
	mov     ds:[statArray].PSS_swapIn, ax
	ret
PerfCalcSwapIn  endp


PerfCalcPPPStatistics   proc    near
    tst ds:[pppDr]
    jz  done

    ;Compute received Kb/s

    mov di, PPP_ID_GET_BYTES_RECEIVED
    call    ds:[pppStrategy]
    movdw   cxbx, dxax
    subdw   dxax, ds:[pppBytesReceived]
    movdw   ds:[pppBytesReceived], cxbx
    ; shouldn't be this many bytes in a second, but just in case...
    clr dx

    ;divide by 100 to get the numeric value in decimal Kb/s
    push    ax
    mov si, 100
    div si
    mov ds:[numericLast].PSS_pppIn, ax
    pop ax
    
    ;normalize the byte count so that graph top = 10Kb/s

    mov si, (10000) / GRAPH_HEIGHT
    clr dx
    div si          ; now ax has value

	cmp     ax, GRAPH_HEIGHT
	jl      60$

	mov     ax, GRAPH_HEIGHT-1
60$:
	mov     ds:[statArray].PSS_pppIn, ax

    ;Compute sent Kb/s

    mov di, PPP_ID_GET_BYTES_SENT
    call    ds:[pppStrategy]
    movdw   cxbx, dxax
    subdw   dxax, ds:[pppBytesSent]
    movdw   ds:[pppBytesSent], cxbx
    ; shouldn't be this many bytes in a second, but just in case...
    clr dx

    ;divide by 100 to get the numeric value in decimal Kb/s
    push    ax
    mov si, 100
    div si
    mov ds:[numericLast].PSS_pppOut, ax
    pop ax
    
    ;normalize the byte count so that graph top = 10Kb/s

    mov si, (10000) / GRAPH_HEIGHT
    clr dx
    div si          ; now ax has value

	cmp     ax, GRAPH_HEIGHT
	jl      61$

	mov     ax, GRAPH_HEIGHT-1
61$:
	mov     ds:[statArray].PSS_pppOut, ax
done:
    ret
PerfCalcPPPStatistics   endp

PerfCalcFreeHandles      proc    near

	; Record number of free handles (absolute value * 10)

	mov	ax, SGIT_NUMBER_OF_FREE_HANDLES
	call	SysGetInfo
	push	ax
	call	MultAXBy10
	mov     ds:[numericLast].PSS_handlesFree, ax
	pop	ax

	; Now we need to generate the value to graph, so ideally
	; we'd want (freeHandles / totalHandles) * GRAPH_HEIGHT.
	; But, we've already calculated # of handles/pixel, so
	; we'll just do the division portion.
		
	mov	si, ds:[handlesPerPixel]
	div	si
	mov     ds:[statArray].PSS_handlesFree, ax
	ret
PerfCalcFreeHandles      endp

MultAXBy10AndDivideBy64 proc    near
	clr     dx                      ;set dx:ax = A LARGE NUMBER

	;multiply by 10 to adjust for the print decimal routine

	shl     ax, 1                   ; * 2
	rcl     dx

	mov     bx, ax                  ;set cx:bx = dx:ax
	mov     cx, dx

	shl     ax, 1                   ; * 2
	rcl     dx

	shl     ax, 1                   ; * 2 (is now * 8 total)
	rcl     dx

	add     ax, bx                  ; ax is now * 10
	adc     dx, cx

	;divide by 64 to convert to K

	mov     cx, 6

10$:
	shr     dx
	rcr     ax
	loop    10$
	ret
MultAXBy10AndDivideBy64 endp

MultAXBy10      proc    near
	shl     ax, 1                   ; * 2
	mov     bx, ax
	shl     ax, 1                   ; * 2
	shl     ax, 1                   ; * 2 (* 8 total)
	add     ax, bx                  ; ax is now * 10
	ret
MultAXBy10      endp


COMMENT @----------------------------------------------------------------------

FUNCTION:       CalcMemoryStats

DESCRIPTION:    Calculate memory statistics

CALLED BY:      PerfCalcNewStats

PASS:           ds      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Eric    5/91            Initial version, with help from Adam of course

------------------------------------------------------------------------------@

CalcMemoryStatistics    proc    near

	;zero out counters (could be coded better!)

	clr     ax
	mov     ds:[heapTotalMemBlocks], ax
	mov     ds:[heapTotalMemSize], ax
	mov     ds:[heapAllocatedMemBlocks], ax
	mov     ds:[heapAllocatedMemSize], ax
	mov     ds:[heapFixedMemBlocks], ax
	mov     ds:[heapFixedMemSize], ax

	mov     ds:[heapUpperMemBlocks], ax
	mov     ds:[heapUpperMemSize], ax

	mov     ds:[heapUpperFreeMemBlocks], ax
	mov     ds:[heapUpperFreeMemSize], ax

	mov     ds:[heapUpperScanActive], al    ;set FALSE
	mov     ds:[heapUpperScanStartSeg], ax

	tst     ds:[graphModes].PSS_heapAllocated
	jnz     scanMemory
	tst     ds:[graphModes].PSS_heapFixed
	jnz     scanMemory
	tst     ds:[graphModes].PSS_heapFragmentation
	jz      exit                    ;skip to end if no info needed...

scanMemory:
	;some memory meter is enabled: perform the stats.
	;Now enter a no-context-switch state and tally the usage of handles
	;in the system. NOTHING WE DO HERE SHOULD CAUSE US TO BLOCK IN
	;ANY WAY.

;;;     call    SysEnterCritical

	push    es

	;first find the first handle which is memory-related.

	mov     cx, es:[handleEnd]      ;cx = offset to last handle + 1
	les     bx, es:[handleStart]    ;es:bx = first handle
					;(now es:cx = last handle + 1)

	;grab the heap semaphore in a round-about friendly sort of way

	call    MemGrabHeap

;       push    bx
;       mov     ax, es
;       mov     bx, ds:[heapSemOffset]  ;ax:bx = heapSem (really)
;       call    ThreadLockModule
;       pop     bx

handleLoop:
EC <    call    CheckForNukedHandle     ;>

	cmp     es:[bx].HG_type, SIG_NON_MEM
	jae     next                    ;skip if not memory related...

	mov     ax, es:[bx].HM_owner
	tst     ax                      ;is this block free?
	jz      next                    ;skip if so...

	;see if the block is discarded or swapped out

	tst     es:[bx].HM_addr         ;resident?
	jnz     foundMemoryBlockHandle  ;skip if so...

next:
	add     bx, size HandleMem
	cmp     bx, cx                  ;at end of handle table yet?
	jb      handleLoop              ;loop if not...

EC <    ERROR   PERF_ERROR_REACHED_END_OF_HEAP_WITHOUT_FINDING_MEMORY_BLOCK >

NEC <   jmp     short done              ;non-ec: bail without stats     >
NEC <                                   ;rather than dying!             >

foundMemoryBlockHandle:
	;We have found the handle of a memory block which is in the heap.
	;Now follow the linked list of memory handles, so that we don't
	;have to examine as many handles to scan the heap.

	;our first job is to scan downwards in the heap until we find an
	;allocated MOVABLE block, or an allocated FIXED block. This will tell
	;us whether we are inside the Upper area or not.

	mov     dx, bx                  ;save address of this handle,
					;so that we know if we are looping
					;helplessly

scanDownExamineHandle:
EC <    call    CheckForNukedHandle     ;>

	;examine this memory block handle, to learn the size and info
	;on its memory block.

	call    ExamineMemoryBlockHandleForAllocated
	jc      scanUp                  ;skip if found one...

	mov     bx, es:[bx].HM_prev     ;point to handle for previous block
	cmp     dx, bx                  ;have we completed a loop?
	jne     scanDownExamineHandle   ;loop if not...

EC <    ERROR   PERF_ERROR                                              >

NEC <   jmp     short done              ;bail in non-ec...              >

scanUp:
	;now we scan forwards, making a complete loop through the heap,
	;gathering stats as we go. (heapUpperStart = handle OR 8000h if we
	;are starting in the middle of the Upper area).

	mov     dx, bx                  ;save address of this handle, so that
					;we know when to stop!

scanUpExamineHandle:
EC <    call    CheckForNukedHandle     ;>

	;examine this memory block handle, to learn the size and info
	;on its memory block. Update stats accordingly.

	call    ExamineMemoryBlockHandle

	mov     bx, es:[bx].HM_next     ;point to handle for next block
	cmp     dx, bx                  ;have we completed a loop?
	jne     scanUpExamineHandle     ;loop if not...

done:
	ForceRef done

;       pop     es
;       call    SysExitCritical

	call    MemReleaseHeap

;       mov     ax, es
;       mov     bx, ds:[heapSemOffset]  ;ax:bx = heapSem (really)
;       call    ThreadUnlockModule

	pop     es

exit:
	ret
CalcMemoryStatistics    endp

if ERROR_CHECK

CheckForNukedHandle     proc    near
	push    ax, cx, di
	mov     cx, 6                   ;cx <- 6 words always trashed
	mov     di, bx                  ;es:di <- ptr to HandleMem
	clr     ax                      ;ax <-look for non-zeroes
	repe    scasw                   ;scan me jesus
	ERROR_Z HANDLE_TRASHED_BUMMER_DUDE_GAME_OVER
	pop     ax, cx, di
	ret
CheckForNukedHandle     endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:       ExamineMemoryBlockHandleForAllocated

DESCRIPTION:    

CALLED BY:      

PASS:           ds      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Eric    5/91            Initial version

------------------------------------------------------------------------------@

ExamineMemoryBlockHandleForAllocated    proc    near

	;is this block FREE or USED?

	tst     es:[bx].HM_owner                ;is there an owner?
	jz      isFree                          ;skip if not (is FREE)...

	;The area from A0000h to BFFFFh is not really RAM, and so is allocated
	;by the kernel as a fake "LOCKED block". If that is what we have,
	;then leave it out of the stats completely.

	call    CheckForKernelFakeLockedBlock
	jc      isFree                          ;skip if is...

isUsed: ;This block is in use. Depending upon whether we have found
	;a fixed or movable block, begin our stats here.

	ForceRef isUsed

	test    es:[bx].HM_flags, mask HF_FIXED ;is this in the FIXED area?
	jnz     isAlloc                         ;skip if so...

	;we are somewhere in the Upper heap area. Save the segment address
	;of this block so that we know when we wrap around.

	mov     ds:[heapUpperScanActive], TRUE
	mov     ax, es:[bx].HM_addr
	mov     ds:[heapUpperScanStartSeg], ax

isAlloc:
	stc
	ret

isFree: ;this is a free block: must continue to scan backwards
	clc
	ret
ExamineMemoryBlockHandleForAllocated    endp


COMMENT @----------------------------------------------------------------------

FUNCTION:       ExamineMemoryBlockHandle

DESCRIPTION:    

CALLED BY:      

PASS:           ds      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Eric    5/91            Initial version

------------------------------------------------------------------------------@

ExamineMemoryBlockHandle        proc    near

	;The area from A0000h to BFFFFh is not really RAM, and so is allocated
	;by the kernel as a fake "LOCKED block". If that is what we have,
	;then leave it out of the stats completely.

	call    CheckForKernelFakeLockedBlock
	jc      done                            ;skip if is...

	;Seems like a normal memory block.
	;Account for each block (free or otherwise)

	call    KeepNormalStats

	;now update stats for Upper heap area, if necessary

	call    KeepUpperAreaStats

done:
	ret
ExamineMemoryBlockHandle        endp


COMMENT @----------------------------------------------------------------------

FUNCTION:       KeepNormalStats

DESCRIPTION:    

CALLED BY:      

PASS:           ds      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Eric    5/91            Initial version

------------------------------------------------------------------------------@

KeepNormalStats proc    near
	inc     ds:[heapTotalMemBlocks]
	mov     ax, es:[bx].HM_size
	add     ds:[heapTotalMemSize], ax

	;is this block FREE or USED?

	tst     es:[bx].HM_owner                ;is there an owner?
	jz      done                            ;skip if not (is FREE)...

isUsed: ;This block is in use. Change a random bit in it. No, just kidding!

	ForceRef isUsed

	inc     ds:[heapAllocatedMemBlocks]
	mov     ax, es:[bx].HM_size
	add     ds:[heapAllocatedMemSize], ax

	;see if it is fixed

	cmp     es:[bx].HM_lockCount, 255               ;check for pseudo-fixed
	jz      isFixed

	test    es:[bx].HM_flags, mask HF_FIXED
	jz      done
isFixed:
	inc     ds:[heapFixedMemBlocks]
	mov     ax, es:[bx].HM_size
	add     ds:[heapFixedMemSize], ax

done:
	ret
KeepNormalStats endp


COMMENT @----------------------------------------------------------------------

FUNCTION:       KeepUpperAreaStats

DESCRIPTION:    

CALLED BY:      

PASS:           ds      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

heapUpperScanActive     byte    ;TRUE when we are scanning the upper area.
				;set FALSE when we find a block with a segment
				;address below heapUpperScanStartSeg.

heapUpperScanStartSeg   word    ;if we have begun scanning the upper area,
				;this is the segment of the MOVABLE block
				;which begins the upper area.

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Eric    5/91            Initial version

------------------------------------------------------------------------------@

KeepUpperAreaStats      proc    near
	;are we scanning in the upper area?

	tst     ds:[heapUpperScanActive]
	jz      scanningLower                   ;skip if not...

scanningUpper:
	ForceRef scanningUpper

	;we are scanning the upper heap. If the address of this block
	;is less than [heapUpperScanStartSeg], it means we have wrapped
	;around, and are now scanning the lower heap.

	mov     ax, es:[bx].HM_addr
	cmp     ds:[heapUpperScanStartSeg], ax
;WRONG! jle     addToUpperStats                 ;have not wrapped around

	jbe     addToUpperStats                 ;have not wrapped around
						;yet, so just update stats...

	;we have wrapped around

	mov     ds:[heapUpperScanActive], FALSE
	jmp     short done                      ;skip to end...

scanningLower:
	;We are scanning the lower heap. If we encounter a MOVABLE block,
	;then we have reached the beginning of the Upper area.

	tst     es:[bx].HM_owner                ;is this block FREE or ALLOC?
	jz      done                            ;skip if is FREE (scan)...

	test    es:[bx].HM_flags, mask HF_FIXED ;is this ALLOC block FIXED?
	jnz     done                            ;skip if FIXED (scan)...

scanningLowerFoundLowerBoundOfUpper:
	;we have found the LOWEST bound of the Upper area. Set our flag
	;TRUE, and save the segment of this block, so we don't falsely
	;think that we have wrapped around.

	ForceRef scanningLowerFoundLowerBoundOfUpper

	mov     ds:[heapUpperScanActive], TRUE
	mov     ax, es:[bx].HM_addr
	mov     ds:[heapUpperScanStartSeg], ax

addToUpperStats:
	inc     ds:[heapUpperMemBlocks]
	mov     ax, es:[bx].HM_size
	add     ds:[heapUpperMemSize], ax

	tst     es:[bx].HM_owner                ;is this block FREE or ALLOC?
	jnz     done                            ;skip if is ALLOC...

	inc     ds:[heapUpperFreeMemBlocks]
	mov     ax, es:[bx].HM_size
	add     ds:[heapUpperFreeMemSize], ax

done:
	ret
KeepUpperAreaStats      endp


COMMENT @----------------------------------------------------------------------

FUNCTION:       CheckForKernelFakeLockedBlock

DESCRIPTION:    

CALLED BY:      

PASS:           ds      = dgroup

RETURN:         nothing

DESTROYED:      ?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Eric    5/91            Initial version

------------------------------------------------------------------------------@
;The area from A0000h to BFFFFh is not really RAM, and so is allocated
;by the kernel as a fake "LOCKED block".

ABOVE_640K              = 0xa000                ;segment which starts at 640K
NORMAL_USAGE_VALUE      = 1000                  ;normal blocks have at least
						;this usage value

CheckForKernelFakeLockedBlock   proc    near

	cmp     es:[bx].HM_owner, handle geos   ;owned by kernel?
;       cmp     es:[bx].HM_owner, KERNEL_ID     ;owned by kernel?
	jne     10$                             ;skip if not...

	tst     es:[bx].HM_flags
	jnz     10$                             ;skip if has any flag...

	cmp     es:[bx].HM_lockCount, 1         ;lock count of 1?
	jne     10$

	cmp     es:[bx].HM_addr, ABOVE_640K
	jl      10$                             ;skip if below 640K...

	cmp     es:[bx].HM_usageValue, NORMAL_USAGE_VALUE
	jl      90$                             ;skip if not used very often...

10$:    ;is not
	clc
	ret

90$:    ;is fake

	stc
	ret
CheckForKernelFakeLockedBlock   endp

PerfCalcStatCode ends
