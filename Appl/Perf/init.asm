COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Perf	(Performance Meter)
FILE:		init.asm (init code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

DESCRIPTION:
	This file source code for the Perf application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: init.asm,v 1.1 97/04/04 16:27:03 newdeal Exp $

------------------------------------------------------------------------------@

PerfInitCode segment resource		;OBSCURE INIT/EXIT CODE


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfGenProcessOpenApplication --
					MSG_GEN_PROCESS_OPEN_APPLICATION

SYNOPSIS:	This is the method handler for the method that is sent out
		when the application is started up or restarted from
		state. After calling our superclass, we do any initialization
		that is necessary.

CALLED BY:	

PASS:		AX	= Method
		CX	= AppAttachFlags
		DX	= Handle to AppLaunchBlock
		BP	= Block handle
		DS, ES	= DGroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PerfGenProcessOpenApplication	method	PerfProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION

	tst	bp
	jz	10$

	;Restore the data (if any)

	push	cx, es				; save the method #, segment
	mov	bx, bp				; block handle to BX
	call	MemLock
	mov	ds, ax				; set up the segment
	mov	cx, (EndStateData - StartStateData)
	clr	si
	mov	di, offset StartStateData
	rep	movsb				; copy the bytes
	call	MemUnlock
	pop	cx, es				; restore the method #, segment

10$:	;Now call the superclass

	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	segmov	ds, es				; DGroup => DS
	mov	di, offset PerfProcessClass	; class of SuperClass we call
	call	ObjCallSuperNoLock		; method already in AX

initUIComponents:
	ForceRef initUIComponents

	;initialize our UI components according to current state

	push	ax, cx, dx, bp

	;init LMemBlock for use by code which draws our icon on the fly.

	call	PerfInitLMemBlockForMoniker

	;Calculate TonyIndex

	call	CalcTonyIndex

	;Initialize Memory Stats

	call	InitMemoryStats

	;Load the PPP driver

	call	LoadPPPDriver

	;Initialize Handle Stats

	call	InitHandleStats

	;determine which colors would be cool

	call	PerfDetermineColors

	;set up the user interface state

	call	PerfInitUIComponents

	;Start a timer

	call	PerfSetTimerInterval		;in FixedCommonCode resource

	pop	ax, cx, dx, bp
	ret
PerfGenProcessOpenApplication	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfInitLMemBlockForMoniker

DESCRIPTION:	Init LMemBlock for use by code which draws our icon on the fly.
		(This may be wasted memory if we are never iconified,
		but it yields predictable results whether we are iconified
		or not.)

CALLED BY:	PerfGenProcessOpenApplication

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfInitLMemBlockForMoniker	proc	near
EC <	tst	ds:[lmemChunkForGString].handle				>
EC <	ERROR_NZ PERF_ERROR						>
EC <	tst	ds:[lmemChunkForGString].chunk				>
EC <	ERROR_NZ PERF_ERROR						>

	mov	ax, MONIKER_GSTRING_BLOCK_SIZE
	mov	cx, (mask HAF_LOCK shl 8) ;allocate as LOCKED (not swapable,
					  ;not discardable)

	call	MemAlloc		;returns ^hbx = new block
					;and ax = segment of block
	jc	done			;skip if error (no memory!)...

	;create an LMem heap within this block, making sure that we don't
	;grow the block size

	segmov	es, ds			;es = DGroup
	mov	ds, ax			;ds = block
					;pass ^hbx = handle of block
	mov	dx, size LMemBlockHeader ;no other data to save
	mov	cl, (MONIKER_GSTRING_BLOCK_SIZE-(size LMemBlockHeader)-8)/8
	mov	ch, 1			;we will only need one chunk handle
	mov	ax, LMEM_TYPE_GENERAL
	call	LMemInitHeap		;will update DS if block moves

	;allocate one block on this LMem heap (ds = block)

	clr	al			;no ObjectChunkFlags to set
	clr	cx			;allocate to 0-size
	call	LMemAlloc
	mov	si, ax

	segmov	ds, es			;restore ds = DGroup

	;save segment and chunk handle of this chunk.

	mov	ds:[lmemChunkForGString].handle, bx
	mov	ds:[lmemChunkForGString].chunk, si

done:
	ret
PerfInitLMemBlockForMoniker	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CalcTonyIndex

DESCRIPTION:	This routine calculates the "Tony Index" for this machine.
		A 1.0 on the Tony Index means that the machine has the
		same performance as a base XT-class machine (4.77MHZ 8088),
		in terms of CPU speed.

CALLED BY:	PerfAttach

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

CalcTonyIndex	proc	near
	;determine what the CPU idle count would be if the system
	;were completely idle.

	mov	ax, SGIT_TOTAL_COUNT
	call	SysGetInfo

	mov	bx, 1000
	div	bx			;ax = dx:ax / 1000
	mov	ds:[totalCountDivBy1000], ax

	;calculate the TonyIndex

	mov	ax, SGIT_CPU_SPEED
	call	SysGetInfo		;returns Tony Index * 10

	mov	ds:[tonyIndexTimes10], ax
	ret
CalcTonyIndex	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitMemoryStats

DESCRIPTION:	Perform some initialization work so that memory statistics
		are easier to come by later on.

CALLED BY:	PerfAttach

PASS:		ds	= dgroup
		es	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric 	5/91		Initial version

------------------------------------------------------------------------------@

InitMemoryStats	proc	near

	mov	ax, SGIT_HANDLE_TABLE_SEGMENT
	call	SysGetInfo
	mov	es:[handleStart].segment, ax
	mov	bx, ax

	mov	ax, SGIT_HANDLE_TABLE_START
	call	SysGetInfo
	mov	es:[handleStart].offset, ax

	mov	ax, SGIT_LAST_HANDLE
	call	SysGetInfo
	mov	es:[handleEnd], ax

;	;find the start and end of the handle table
;
;	push	ds
;	call	MemInfoHandles		;returns ds:bx = first handle
;					;and ds:ax = last handle + 1
;	mov	es:[handleStart].offset, bx
;	mov	es:[handleStart].segment, ds
;	mov	es:[handleEnd], ax
;
;	;now use a hack to get the offset of the Heap semaphore
;
;	push	ax
;	call	SysPrepareForSwitch
;	mov	es:[heapSemOffset], si
;	pop	ax
;
;no longer necessary: the fixed portions of the kernel,
;and the handle table, are technically in the heap.
;
;	;find the size of the kernel
;	;	(offset from kdata to end of kdata)
;
;	shr	ax, 1			;convert to # paragraphs
;	shr	ax, 1
;	shr	ax, 1
;	shr	ax, 1
;
;	;find the size of kcode in paragraphs
;
;	mov	bx, ds
;	pop	ds
;
;	sub	bx, segment MemInfoHandles
;
;	add	ax, bx			;ax = total size of kernel
;	mov	ds:[kernelSize], ax

	;locate all swap drivers and their swap maps

	clr	bx			;process all geodes
	mov	di, cs
	mov	si, offset LocateSwapDriver
	mov	dx, ds
	mov	bp, offset dgroup:swapMaps
	mov	ds:[maxMemSwap], bx	;initialize maximum counters
	mov	ds:[maxDiskSwap], bx
	call	GeodeForEach

	ret
InitMemoryStats	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocateSwapDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed geode is a swap driver. If so, fetch
		its swap map and initialize a entry in the swapMaps array
		for it.

CALLED BY:	InitMemoryStats via GeodeForEach
PASS:		bx	= handle of geode
		es	= segment of core block
		dx:bp	= first free entry in swapMaps
				(PerfSwapDriver structure)

RETURN:		carry set to stop processing (only if swapMaps fills up)
DESTROYED:	di, si, es, ds, if I want

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

diskName	char	'disk    '	; name of disk-based swap driver

LocateSwapDriver proc	far
		.enter
	;
	; See if the geode's a swap driver by examining its token characters
	; and attributes. A swap driver's token is always 'MEMD', and it must
	; at least have GA_DRIVER set in its attributes.
	;
		cmp	{word}es:[GH_geodeToken].GT_chars,
				'M' or ('E' shl 8)
		jne	continue
		cmp	{word}es:[GH_geodeToken].GT_chars+2,
				'M' or ('D' shl 8)
		jne	continue
		test	es:[GH_geodeAttr], mask GA_DRIVER
		jz	continue
	;
	; Yup. See if its name is "disk" and mark it as disk-based if so.
	; XXX: do this based on the speed or something.
	;
		segmov	ds, cs
		mov	si, offset diskName
		mov	di, offset GH_geodeName
		mov	cx, length diskName
		repe	cmpsb
		mov	ax, TRUE
		je	fetchMap
		not	ax
fetchMap:
	;
	; Save the SD_disk flag and go fetch the swap map.
	;
		push	ax
		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct
		mov	di, DR_SWAP_GET_MAP
		call	ds:[si].DIS_strategy
		pop	cx

		tst	ax
		jz	continue		; no swap map => we can't
						;  find out anything about it

		mov	ds, dx			; ds:bp <- entry in table.
		mov	ds:[bp].PSD_map, ax
		mov	ds:[bp].PSD_disk, cx
		mov	di, offset maxMemSwap
		jcxz	figureKb

		mov	di, offset maxDiskSwap

figureKb:
		mov	es, ax			; es <- swap map
		mov	ax, es:[SM_total]
		mul	es:[SM_page]		; dx:ax <- # bytes of swap
		mov	cx, 1024
		div	cx			; ax <- # Kb of swap

		add	ds:[di], ax		; add to total
		mov	dx, ds			; restore dx for next round

	;
	; Another map entry consumed. If we've used them all, stop processing.
	;

		add	bp, size PerfSwapDriver
		cmp	bp, offset dgroup:swapMaps + size swapMaps
		jb	continue
		stc
		jmp	done
continue:
		clc
done:
		.leave
		ret
LocateSwapDriver endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfDetermineColors

DESCRIPTION:	

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfDetermineColors	proc	near

	;first ask our GenApplication object if we are running in black&white

	GetResourceHandleNS	PerfApp, bx
	mov	si, offset PerfApp
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;returns ah = DisplayType

	;by default, things are set up for color. If is color, skip to end.

	ANDNF	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	setForColor

setForBW:
	ForceRef setForBW

	;set up for B&W operation

	mov	ds:[bwMode], TRUE

	;disable color usage

	GetResourceHandleNS	GraphColorsGenInteraction, bx
	mov	si, offset GraphColorsGenInteraction
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	;change colors for all charts

	segmov	es, ds
	mov	di, offset graphColors
	mov	cx, NUM_STAT_TYPES
	mov	ax, BW_GRAPH_BACKGROUND_COLOR
	rep stosw			;es:[di] = ax, di++

	;set color for line, value text, and caption text

	mov	ax, BW_GRAPH_FOREGROUND_COLOR
	mov	ds:[lineColor], ax
	mov	ds:[valueColor], ax
	mov	ds:[captionColor], ax
	jmp	short done

setForColor:
	;set up for color operation

	mov	ds:[bwMode], FALSE

	;enable color usage

	GetResourceHandleNS	GraphColorsGenInteraction, bx
	mov	si, offset GraphColorsGenInteraction
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	;change colors for all charts

	segmov	es, ds
	mov	si, offset InitialGraphColors
	mov	di, offset graphColors
	mov	cx, NUM_STAT_TYPES
	rep	movsw		

	;set color for line, value text, and caption text

	mov	ds:[lineColor], C_BLACK
	mov	ds:[valueColor], C_BLUE
	mov	ds:[captionColor], C_BLACK

done:

	ret
PerfDetermineColors	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfGenProcessCloseApplication -- MSG_GEN_PROCESS_CLOSE_APPLICATION

DESCRIPTION:	

CALLED BY:	

PASS:		DS, ES	= DGroup
		AX	= MSG_UI_CLOSE_APPLICATION

RETURN:		CX	= Block handle holding state data

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/27/91		Initial version

------------------------------------------------------------------------------@

PerfGenProcessCloseApplication	method	PerfProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	;nuke LMemBlock which was used by code which draws our icon on the fly.

	call	PerfNukeLMemBlockForMoniker

	; Allocate the block

	mov	ax, (EndStateData - StartStateData)
	mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE or (mask HAF_LOCK shl 8)
	call	MemAlloc
	mov	es, ax

	; Store the state

	mov	cx, (EndStateData - StartStateData)
	clr	di
	mov	si, offset StartStateData
	rep	movsb				; copy the bytes

	;Clean up

	call	MemUnlock
	mov	cx, bx
	ret
PerfGenProcessCloseApplication	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfNukeLMemBlockForMoniker

DESCRIPTION:	Nuke LMemBlock.

CALLED BY:	PerfGenProcessCloseApplication

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfNukeLMemBlockForMoniker	proc	near
	mov	bx, ds:[lmemChunkForGString].handle
	tst	bx
	jz	done

	call	MemFree

	clr	ds:[lmemChunkForGString].handle

done:
	ret
PerfNukeLMemBlockForMoniker	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfInitUIComponents

DESCRIPTION:	This routine will initialize all of our UI components
		according to the current state of our variables.

CALLED BY:	PerfAttach

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/28/91		Initial version

------------------------------------------------------------------------------@

PerfInitUIComponents	proc	near

	;set the on/off state

	mov	cx, ds:[onOffState]	;cx = TRUE or FALSE

	GetResourceHandleNS	PerfOnOffGenItemGroup, bx
	mov	si, offset PerfOnOffGenItemGroup
	clr	dx			;not indeterminant
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

	;calculate the new number of graphs

	call	PerfCalcNumGraphs		;in FixedCommonCode resource

	;resize the view accordingly

	CallMod	PerfSizeViewAccordingToGraphs	;in PerfUIHandlingCode resource

	;update the state of the PerfMeter checkboxes 

	call	PerfUpdatePerfMeterBooleans

	;update the state of the Display options checkboxes

	mov	cl, ds:[displayOptions]		;cx = state for flags
	clr	ch
	clr	dx				;nothing is indeterminant

	GetResourceHandleNS	DisplayOptionsCheckboxes, bx
	mov	si, offset DisplayOptionsCheckboxes
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

;might want to add this list back in for V2.0
;	;set the current color of the CPU meter in the Color dialog box
;	;(do this by telling the scrolling list to update us again)
;
;	GetResourceHandleNS	MeterList, bx
;	mov	si, offset MeterList
;	mov	ax, MSG_GEN_LIST_SEND_AD
;	mov	bp, mask LF_REFERENCE_USER_EXCL
;	clr	di
;	call	ObjMessage

	;see which graph was the "current" graph, and update the color bar
	;accordingly.

;2.0BUSTED - COLORS
;	mov	cx, ds:[currentGraph]
;	call	PerfSetGraphColorsChooseMeter	;in FixedCommonCode resource

	;Now, set the PerfPrimary usable

	GetResourceHandleNS	PerfPrimary, bx
	mov	si, offset PerfPrimary
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	;done

	ret
PerfInitUIComponents	endp


;update the state of the PerfMeter checkboxes 

PerfUpdatePerfMeterBooleans	proc	near

	;convert our table of BooleanWords into a word-length bitfield.

	mov	di, ST_AFTER_LAST_STAT_TYPE-2
	clr	cx

10$:	;check this BooleanWord

	cmp	word ptr ds:[graphModes][di], 0
	jz	20$				;skip if is off (cy=0)...

	stc					;set carry

20$:
	rcr	cx, 1

	sub	di, 2
	jns	10$

	;now send this bitfield record off to the list

	GetResourceHandleNS	PerfMeterCheckboxes, bx
	mov	si, offset PerfMeterCheckboxes
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx				;nothing is indeterminant
	clr	di
	call	ObjMessage

	ret
PerfUpdatePerfMeterBooleans	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfDetach

DESCRIPTION:	

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PerfDetach	method	PerfProcessClass, MSG_META_DETACH

	;Remove the timer

	mov	bx,ds:[timerHandle]
	mov	ax,ds:[timerID]
	call	TimerStop

    ;Unload the PPP driver

    call    UnloadPPPDriver

	;Call our superclass (the UI) to finish

	mov	ax, MSG_META_DETACH
	mov	di,offset PerfProcessClass
	call	ObjCallSuperNoLock
	ret
PerfDetach	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfViewWinClosed -- MSG_META_CONTENT_VIEW_WIN_CLOSED

DESCRIPTION:	This method is sent by the window inside the GenView,
		as it is closing. This indicates that the application
		is exiting, or is being iconified.

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PerfViewWinClosed	method	PerfProcessClass, 
				MSG_META_CONTENT_VIEW_WIN_CLOSED

	cmp	bp, ds:[viewWindow]	;is it our window?
	jnz	TWDN_other		;skip if not...

	;nuke our window and GState handles

	mov	ds:[viewWindow], 0	;indicate that we don't have a window

	mov	di, ds:[viewWinGState]	;do we still have a GState?
	tst	di
	jz	TWDN_other		;skip if not...

	call	GrDestroyState		;nuke the GState
	mov	ds:[viewWinGState],0	;indicate that we did

	;in case the window is iconifying, ensure that we force the caption
	;to "draw" (i.e. be copied to the icon) at least once.

	mov	ds:[redrawCaptions], 1

TWDN_other:
	mov	di, offset PerfProcessClass	; class of SuperClass we call
	call	ObjCallSuperNoLock
	ret
PerfViewWinClosed	endp

LocalDefNLString	socketString, <"socket", 0>
EC <LocalDefNLString	pppName, <"pppec.geo", 0>		>
NEC<LocalDefNLString	pppName, <"ppp.geo", 0>		>

COMMENT @----------------------------------------------------------------

FUNCTION:	LoadPPPDriver

DESCRIPTION:	Load the PPP driver to obtain PPP xmit statistics.

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:  nothing

STRATEGY:

SIDE EFFECTS:   Clears the PPP statistics.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	11/30/98	initial version
    dhunter 1/30/2000   adapted for Perf
-------------------------------------------------------------------------@
LoadPPPDriver		proc	far	
		uses	bx, si, dx, ax, ds, es, bp, di
		.enter

    ;
    ; Clear the PPP statistics here as a convenient place.
    ;
        clrdw   ds:[pppBytesSent]
        clrdw   ds:[pppBytesReceived]

    ;
    ; Locate and load the PPP driver.
    ;
		segmov	es, ds, si
        segmov  ds, cs, si
		call	FilePushDir
		mov	bx, SP_SYSTEM
		mov	dx, offset socketString
		call	FileSetCurrentPath
		jc	done

		mov	ax, 0
		mov	bx, 0
		mov	si, offset pppName		; ds:si = driver name
		call	GeodeUseDriver
		jc	done

		mov	es:[pppDr], bx
	;
	; Get the strategy routine.
	;
		call	GeodeInfoDriver
		movdw	es:[pppStrategy], ds:[si].DIS_strategy, ax
done:
		call	FilePopDir
		.leave
		ret

LoadPPPDriver		endp

COMMENT @----------------------------------------------------------------

FUNCTION:	UnloadPPPDriver

DESCRIPTION:	Unload the PPP driver

PASS:		ds	= dgroup

RETURN:		nothing

STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
    dhunter 1/30/2000   Initial Revision
-------------------------------------------------------------------------@
UnloadPPPDriver		proc	far	
		uses	bx
		.enter

		mov	bx, ds:[pppDr]
        tst bx
        jz  done
		call	GeodeFreeDriver
        clr ds:[pppDr]
done:
		.leave
		ret

UnloadPPPDriver		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitHandleStats

DESCRIPTION:	Do any initialization work to maintain handle statistics

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/21/00	Initial version

------------------------------------------------------------------------------@

InitHandleStats	proc	near
	uses	ax, cx, dx
	.enter

	; calculate # of handles/pixel for graphing purposes. Rounding
	; won't matter here since the system will always be using a decent
	; number of handles, so just use the integer result.
		
	mov	ax, SGIT_TOTAL_HANDLES
	call	SysGetInfo
	mov	cx, GRAPH_HEIGHT
	div	cx
	mov	ds:[handlesPerPixel], ax

	.leave
	ret
InitHandleStats	endp

PerfInitCode ends
