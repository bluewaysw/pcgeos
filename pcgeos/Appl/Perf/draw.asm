COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Perf	(Performance Meter)
FILE:		draw.asm (drawing code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

DESCRIPTION:
	This file source code for the Perf application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: draw.asm,v 1.1 97/04/04 16:27:01 newdeal Exp $

------------------------------------------------------------------------------@

PerfDrawCode segment resource

;This tables contains the chunk handles for the monikers which are stored in
;the "PerfUIStrings" resource. The COPY_VIS_MONIKER method will lock that
;resource when grabbing the appropriate moniker. We cannot merge this resource
;with PerfProcStrings, because the UI will be locking this resource,
;the the Perf thread will be locking the other.
;
;WARNING: this table must be in the same order as PerfStatStruc.

ShortChartNames	label	word		;in PerfDrawCode resource
	word	offset PerfUIStrings:CPUUsageShortText
	word	offset PerfUIStrings:LoadAverageShortText
	word	offset PerfUIStrings:InterruptsShortText
	word	offset PerfUIStrings:ContextSwitchesShortText
	word	offset PerfUIStrings:HeapAllocatedShortText
	word	offset PerfUIStrings:HeapFixedShortText
	word	offset PerfUIStrings:HeapFragmentationShortText
	word	offset PerfUIStrings:SwapMemAllocatedShortText
	word	offset PerfUIStrings:SwapFileAllocatedShortText
	word	offset PerfUIStrings:SwapOutShortText
	word	offset PerfUIStrings:SwapInShortText
	word    offset PerfUIStrings:PPPInShortText
	word    offset PerfUIStrings:PPPOutShortText
	word    offset PerfUIStrings:HandlesFreeShortText

;This table contains chunk handles for the chunks which contain the graph name
;text. This text is displayed in the "caption" area above each graph.
;WARNING: this table must be in the same order as PerfStatStruc.

ChartNames	label	word		;in PerfDrawCode resource
	word	offset PerfProcStrings:CPUUsageText
	word	offset PerfProcStrings:LoadAverageText
	word	offset PerfProcStrings:InterruptsText
	word	offset PerfProcStrings:ContextSwitchesText
	word	offset PerfProcStrings:HeapAllocatedText
	word	offset PerfProcStrings:HeapFixedText
	word	offset PerfProcStrings:HeapFragmentationText
	word	offset PerfProcStrings:SwapMemAllocatedText
	word	offset PerfProcStrings:SwapFileAllocatedText
	word	offset PerfProcStrings:SwapOutText
	word	offset PerfProcStrings:SwapInText
	word	offset PerfProcStrings:PPPInText
	word	offset PerfProcStrings:PPPOutText
	word    offset PerfProcStrings:HandlesFreeText

;This table contains the chunk handles for the chunks which contain the
;graph units text. This text is displayed next to the value below the graph.
;WARNING: this table must be in the same order as PerfStatStruc.

ChartUnitNames	label	word		;in PerfDrawCode resource
	word	offset PerfProcStrings:CPUUsageUnitNameText
	word	offset PerfProcStrings:LoadAverageUnitNameText
	word	offset PerfProcStrings:InterruptsUnitNameText
	word	offset PerfProcStrings:ContextSwitchesUnitNameText
	word	offset PerfProcStrings:HeapAllocatedUnitNameText
	word	offset PerfProcStrings:HeapFixedUnitNameText
	word	offset PerfProcStrings:HeapFragmentationUnitNameText
	word	offset PerfProcStrings:SwapMemAllocatedUnitNameText
	word	offset PerfProcStrings:SwapFileAllocatedUnitNameText
	word	offset PerfProcStrings:SwapOutUnitNameText
	word	offset PerfProcStrings:SwapInUnitNameText
	word	offset PerfProcStrings:PPPInUnitNameText
	word	offset PerfProcStrings:PPPOutUnitNameText
	word	offset PerfProcStrings:HandlesFreeUnitNameText


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfExposed -- MSG_META_EXPOSED for PerfProcessClass

DESCRIPTION:	

CALLED BY:	

PASS:		ds	= dgroup
		di	= MSG_META_EXPOSED (????)
		^hcx	= handle of window

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PerfExposed	method	PerfProcessClass, MSG_META_EXPOSED
	mov	ds:[viewWindow], cx	;save handle of window

	;Create us a GState

	mov	di,ds:[viewWinGState]	;do we already have a GState?
	tst	di
	jnz	haveGState		;skip if so...

	mov	di, ds:[viewWindow]	;^hdi = window inside GenView
	call	GrCreateState 		;create a GState for that window
					;returns ^hdi = GState
	mov	ds:[viewWinGState], di	;save handle of GState

haveGState:
	;Updating the window... (since we are handling an EXPOSED event,
	;we must tell the window system we start and end drawing)

	call	GrBeginUpdate

	mov	ds:[redrawCaptions], 1	;force a redraw of captions

	;and force a redraw of the values:

	mov	di, offset oldNumericLast
	mov	cx, PerfStatStruc
	mov	ax, -1
	rep	stosb			;store bytes * size of structure

	call	DrawAllPerfMeters	;pass ^hdi = GState to use

	call	GrEndUpdate		;done updating...

	ret
PerfExposed	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfTimerExpired -- MSG_PERF_TIMER_EXPIRED handler

DESCRIPTION:	This method is sent to this object when the timer expires.

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

PerfTimerExpired	method	PerfProcessClass, MSG_PERF_TIMER_EXPIRED

	;if we have recently been turned off, then ignore this

	tst	ds:[onOffState]		;save the new state
	jz	done			;skip if "off"...

	;Make us a high priority task, because we want to gather all of
	;our statistics as a "snapshot".

	clr	bx			;use current thread
	mov	ah, mask TMF_BASE_PRIO	;modify priority only
	mov	al, PRIORITY_HIGH	;set it high
	call	ThreadModify

	;shift values in history array, and make a copy of the last time's
	;numeric values

	call	ShiftValueHistory

	;get new statistics

	CallMod	PerfCalcNewStats	;in PerfCalcStatCode resource

	;see if the application is iconified or open

	mov	di, ds:[viewWinGState]
	tst	di
	jz	isIconified		;skip if so...

isOpened:
	ForceRef isOpened

	;if the application is not iconified, then go ahead and
	;draw all of the active graphs into the view.

	call	DrawAllPerfMeters	;pass ^hdi = GState to use
	jmp	short done

isIconified:
	;the application is iconified: draw the first graph, saving the
	;GString opcodes into a chunk. When done, transform the chunk
	;into a Moniker, and send it to the icon object.

if UPDATE_ICON
	tst	ds:[curNumGraphs]	;are there any graphs?
	jz	isIconifiedAndOff	;skip if not...

	tst	ds:[onOffState]		;save the new state
	jz	isIconifiedAndOff	;skip if "off"...

isIconifiedAndOn:
	ForceRef isIconifiedAndOn

if 0	;2.0 BUSTED due to LMEM bug in Graphics string code

	call	PrepareToDrawToMemory	;returns ^hdi = GState
	jc	done			;skip if error...

	call	PerfLockStrings		;lock the PerfProcStrings resource
					;(in FixedCommonCode resource)

	call	ChooseFirstPerfMeter	;set bx = StatType of first graph
					;(i.e. word-oriented offset)

	;set up the drawing coordinates

PrintMessage <CONSTANTS>
	mov	cx, 0			;LEFT_MARGIN
	mov	dx, 6			;TOP_MARGIN

	;first draw the background, in the correct color (this includes
	;the area below the graph, where the value is displayed).

	call	DrawBackgroundForOneMeter

	;now draw the meter itself, and the value below it

	call	DrawOnePerfMeter

	call	PerfUnlockStrings	;unlock the PerfProcStrings resource
					;(in FixedCommonCode resource)

	call	FinishDrawingToDrawToMemory

	;now send both the icon moniker and the caption moniker to
	;the icon object. (bx = StatType)

	call	ConvertGStringToMonikerAndSendToIcon
endif

	jmp	short done

isIconifiedAndOff:
	ForceRef isIconifiedAndOff

	;just show the Perf icon, stupid!
endif

done:
	ret
PerfTimerExpired	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PrepareToDrawToMemory

DESCRIPTION:	This routine prepares an LMem heap, and a chunk within that
		heap, for the graphics system to store the GString into,
		as we draw our single graph.

CALLED BY:	PerfTimerExpired

PASS:		ds	= dgroup

RETURN:		ds	= same
		^lbx:si	= chunk which will contain GString
				(block is locked)
		^hdi	= GState to draw with (magic!)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PrepareToDrawToMemory	proc	near

	mov	bx, ds:[lmemChunkForGString].handle
	tst	bx
	stc
	jz	done			;return if error...

	mov	si, ds:[lmemChunkForGString].chunk

	segmov	es, ds
	call	MemLock			;pass ^hbx = block
	mov	ds, ax			;set *ds:ax = chunk
	mov	ax, si

	;re-alloc the chunk to 0-size

	clr	cx			;resize to 0
	call	LMemReAlloc

	call	MemUnlock
	segmov	ds, es

	;^lbx:si = chunk to place GString into

	mov	cl, GST_CHUNK
	call	GrCreateGString		;returns ^hdi = GState
	clc				;indicate no error

done:
	ret
PrepareToDrawToMemory	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChooseFirstPerfMeter

DESCRIPTION:	

CALLED BY:	PerfTimerExpired

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

ChooseFirstPerfMeter	proc	near
	clr	bx

10$:	cmp	word ptr ds:[graphModes][bx], TRUE
	je	90$

	add	bx, 2
	cmp	bx, ST_AFTER_LAST_STAT_TYPE
	jl	10$

EC <	ERROR PERF_ERROR						>

90$:
	ret
ChooseFirstPerfMeter	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FinishDrawingToDrawToMemory

DESCRIPTION:	This routine prepares an LMem heap, and a chunk within that
		heap, for the graphics system to store the GString into,
		as we draw our single graph.

CALLED BY:	PerfTimerExpired

PASS:		ds	= dgroup
		bx	= StatType of graph
		^hdi	= GState to draw with (magic!)

RETURN:		^lbx:si	= chunk which will contain GString
				(block is locked)

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

FinishDrawingToDrawToMemory	proc	near

	;finish up the GString in the chunk (^hdi = GState)

	call	GrEndGString		;returns ax = GStringErrorType enum
EC <	cmp	ax, GSET_NO_ERROR					>
EC <	ERROR_NE PERF_ERROR						>

	;make sure to nuke the GString!

	mov	dl, GSKT_LEAVE_DATA	;don't nuke the GString chunk
	mov	si, di			;si = GString handle
	clr	di			;no GState handle
	call	GrDestroyGString

EC <	tst	ds:[lmemChunkForGString].handle				>
EC <	ERROR_Z	PERF_ERROR						>
	mov	si, ds:[lmemChunkForGString].chunk
EC <	tst	si							>
EC <	ERROR_Z	PERF_ERROR						>

	ret
FinishDrawingToDrawToMemory	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertGStringToMonikerAndSendToIcon

DESCRIPTION:	Convert the passed GString into a full-blown moniker,
		and then pass it on to the icon for this application. Neat!

CALLED BY:	PerfPerfTimer

PASS:		ds	= dgroup
		bx	= StatType

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/27/91		Initial version

------------------------------------------------------------------------------@

if 0
ConvertGStringToMonikerAndSendToIcon	proc	near

	push	bx

	mov	bx, ds:[lmemChunkForGString].handle
	mov	si, ds:[lmemChunkForGString].chunk

EC <	tst	bx							>
EC <	ERROR_Z	PERF_ERROR						>
EC <	tst	si							>
EC <	ERROR_Z	PERF_ERROR						>

if 0
	;lock the block, and resize the chunk, to make room for the
	;VisMoniker structure

	segmov	es, ds
	call	MemLock		
	mov	ds, ax			;*ds:ax = chunk
	mov	ax, si

	push	bx
	clr	bx
	mov	cx, size VisMoniker  ;cx = number of bytes to insert
	call	LMemInsertAt
	pop	bx

	;now set up the VisMoniker structure at the beginning of this chunk

	mov	di, ds:[si]
	mov	ds:[di].VM_type, \
			mask VMT_GSTRING \
			or (VMAR_NORMAL shl offset VMT_GS_ASPECT_RATIO) \
			or (DC_COLOR_4 shl offset VMT_GS_COLOR)

	mov	ds:[di].VM_width, ICON_WIDTH

;	mov	ds:[di].VM_size.XYS_width, ICON_WIDTH
;	mov	ds:[di].VM_size.XYS_height, ICON_HEIGHT

	call	MemUnlock
	segmov	ds, es
endif

;THIS IS NOT CORRECT YET: it is changing the GenApplication's moniker
;to the new moniker. We really want to change one moniker in a template
;moniker list, and then give that list to the GenApp. That way, the
;text moniker used by the GenPrimary is still cool.

	;Now, create a VisMoniker for this GString, and replace the icon
	;VisMoniker chunk in our GenApplication's alternate moniker list.
	;Start by setting up this structure on the stack:
	;
	;    ReplaceVisMonikerFrame	struct
	;	RVMF_source	dword
	;	RVMF_sourceType	VisMonikerSourceType
	;	RVMF_dataType	VisMonikerDataType
	;	RVMF_length	word
	;	RVMF_width	word
	;	RVMF_height	word
	;	RVMF_updateMode	VisUpdateMode
	;    ReplaceVisMonikerFrame	ends

	mov	dx, size ReplaceVisMonikerFrame
	sub	sp, dx
	mov	bp, sp

;HACK
	mov	ss:[bp].RVMF_source.segment, cs
	mov	ss:[bp].RVMF_source.offset, offset PerfDrawCode:fooText
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR

;	mov	ss:[bp].RVMF_source.handle, bx
;	mov	ss:[bp].RVMF_source.chunk, si
;	mov	ss:[bp].RVMF_sourceType, VMST_OPTR

	mov	ss:[bp].RVMF_dataType, VMDT_TEXT
	mov	ss:[bp].RVMF_length, 0

;will need to set these when use VMDT_GSTRING
;	mov	ss:[bp].RVMF_width,
;	mov	ss:[bp].RVMF_height,

	mov	ss:[bp].RVMF_updateMode, VUM_NOW

	GetResourceHandleNS	PerfApp, bx
	mov	si, offset PerfApp

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage

	add	sp, size ReplaceVisMonikerFrame


considerCaption:
	;now depending upon the graph we are drawing, update the caption

	ForceRef considerCaption

	pop	di			;get StatType
	tst	ds:[redrawCaptions]	;have we already done this once
					;since we were iconified?
	jz	done			;skip if so...

drawCaption:
	ForceRef drawCaption

	dec	ds:[redrawCaptions]

	GetResourceHandleNS	PerfUIStrings, cx
					;^lcx:dx = name from strings.ui
	mov	dx, cs:[ShortChartNames][di]

;2.0BUSTED - ICON
if 0
	GetResourceHandleNS	PerfPrimary, bx
	mov	si, offset PerfPrimary
	mov	ax, MSG_HACK_PRIMARY_COPY_MONIKER_TO_CAPTION_PLEASE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
endif

done:
	ret
ConvertGStringToMonikerAndSendToIcon	endp

fooText	char	"Icon", 0
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ShiftValueHistory

DESCRIPTION:	shift values in history array

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version

------------------------------------------------------------------------------@

ShiftValueHistory	proc	near
	;shift the array of PerfStatStruc items up in the array, making room
	;for a new item.

	mov	si, offset statArray+((NUM_POINTS-1)*(size PerfStatStruc))-2
	mov	di, offset statArray+((NUM_POINTS-0)*(size PerfStatStruc))-2
	segmov	es, ds
	mov	cx, (NUM_POINTS-1) * ((size PerfStatStruc)/2)
	std
	rep	movsw
	cld

	;and make a copy of the last set of numeric values

	mov	si, offset numericLast		;source
	mov	di, offset oldNumericLast	;dest

	mov	cx, size PerfStatStruc
	rep	movsb				;move bytes * size of struc

	ret
ShiftValueHistory	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawAllPerfMeters

DESCRIPTION:	This routine draws all of the enabled graphs into
		the GenView window.

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		ds	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

DrawAllPerfMeters	proc	near

	;most times, we are passed ^hdi = GState, but let's be sure...

	mov	di, ds:[viewWinGState]	;set ^hdi = GState to use
	tst	di
	jz	90$			;skip if none...

	call	PerfLockStrings		;lock the PerfProcStrings resource
					;(in FixedCommonCode resource)

	mov	bx, ST_CPU_USAGE	;start with the first stat type
	mov	cx, LEFT_MARGIN
	mov	dx, TOP_MARGIN

	test	ds:[displayOptions], mask PDO_SHOW_CAPTIONS
	jz	10$

	add	dx, CAPTION_HEIGHT

10$:	;is this stat type enabled?

	mov	word ptr ds:[graphXPositions][bx], MAX_DOC_WIDTH
					;set X position = INVALID
					;(used to detect mouse position)

	cmp	word ptr ds:[graphModes][bx], FALSE
					;check entry in TRUE/FALSE word-oriented
					;lookup-table
	je	50$			;skip if not...

	mov	word ptr ds:[graphXPositions][bx], cx
					;save real X position

	;first draw the background, in the correct color (this includes
	;the area below the graph, where the value is displayed).

	call	DrawBackgroundForOneMeter

	;if in B&W mode, and this is not the left-most meter, then draw
	;a vertical line to separate the graphs

	call	DrawBWSepLine

	;now draw the graph and caption

	call	DrawOnePerfMeter	;draw a graph for this stat
	add	cx, GRAPH_WIDTH+GRAPH_SPACING
					;draw next chart shifted over

50$:
	add	bx, 2			;on to next stat type
	cmp	bx, ST_AFTER_LAST_STAT_TYPE
	jl	10$			;loop if more to go...

	call	PerfUnlockStrings	;unlock the PerfProcStrings resource
					;(in FixedCommonCode resource)

90$:	;decrement counter if necessary

	tst	ds:[redrawCaptions]
	jz	99$

	dec	ds:[redrawCaptions]

99$:
	ret
DrawAllPerfMeters	endp

;clear entire area behind chart

DrawBackgroundForOneMeter	proc	near
	push	bx, cx, dx

	;set color for this chart

	mov	bp, bx
	mov	ax, word ptr ds:[graphColors][bp]
	call	GrSetAreaColor

	;draw the background for the graph, erasing the old plot line

	mov	ax, cx
	mov	bx, dx
	add	cx, GRAPH_WIDTH
	add	dx, GRAPH_HEIGHT
	call	GrFillRect

if 0	;MOVED INTO PrintLastValue routine. EDS 5/92.
	;erase the area below the graph, where the caption is displayed

	test	ds:[displayOptions], mask PDO_SHOW_VALUES
	jz	50$			;skip if values not displayed...

	tst	ds:[viewWindow],	;special case: see if iconified.
	jz	50$			;if so, values are drawn inside
					;graph, so no need to draw background.

;future
;	tst	ds:[placeValuesBelow]
;	jz	50$

	push	ax
	mov	ax, OVERALL_BACKGROUND_COLOR
	call	GrSetAreaColor
	pop	ax

	add	bx, GRAPH_HEIGHT
	mov	dx, bx
	add	dx, EXTRA_MARGIN_FOR_VALUES_BELOW_GRAPH-1
	call	GrFillRect

50$:
endif

	pop	bx, cx, dx
	ret
DrawBackgroundForOneMeter	endp


DrawBWSepLine	proc	near
	tst	ds:[bwMode]		;B&W mode?
	jz	20$			;skip if not...

	cmp	cx, LEFT_MARGIN		;are we drawing the left-most graph?
	je	20$			;skip if so...

	mov	ax, C_BLACK		;fudge. We know it should be black
	call	GrSetAreaColor

	push	bx, cx, dx
	mov	ax, cx
	sub	ax, GRAPH_SPACING
	dec	cx
	mov	bx, dx
	add	dx, GRAPH_HEIGHT
	call	GrFillRect
	pop	bx, cx, dx

20$:
	ret
DrawBWSepLine	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawOnePerfMeter

DESCRIPTION:	Draw the graph or number for the value we are monitoring.

CALLED BY:	PerfPerfTimer

PASS:		ds	= dgroup
		bx	= StatType indicating which graph to draw
					(ST_CPU_USAGE, etc)
		cx	= X margin on left side of graph (makes room for
						graphs drawn to the left)
		dx	= Y margin above graph (make room for captions)
		^hdi	= GState

RETURN:		ds, bx, dx, dx, di = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

DrawOnePerfMeter	proc	near

	;draw the caption below the graph

	tst	ds:[viewWindow]		;special case: see if iconified.
	jz	20$			;is so, then do not draw caption...

	test	ds:[displayOptions], mask PDO_SHOW_CAPTIONS
	jz	20$

	tst	ds:[redrawCaptions]	;have we already drawn the caption?
	jz	20$			;skip if so...

	call	PrintChartCaption

20$:	;draw the vertical lines or points which represent the graph

	test	ds:[displayOptions], mask PDO_SHOW_GRAPHS
	jz	30$

	call	PlotPoints

30$:	;if value display is enabled, draw the most recent value on top
	;of the graph

	test	ds:[displayOptions], mask PDO_SHOW_VALUES
	jz	90$

	call	PrintLastValue

90$:
	ret
DrawOnePerfMeter	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PlotPoints

DESCRIPTION:	Draw a graph representing the most recent history for the
		value we are monitoring.

CALLED BY:	DrawOnePerfMeter

PASS:		ds	= dgroup
		bx	= StatType indicating which graph to draw
					(ST_CPU_USAGE, etc)
		cx	= X margin on left side of graph (makes room for
						graphs drawn to the left)
		dx	= Y margin above graph (make room for captions)
		^hdi	= GState

RETURN:		ds, bx, cx, dx, di	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PlotPoints	proc	near
	uses	bx, cx, dx
	.enter

	;set line color to use

	mov	ax, ds:[lineColor]
	call	GrSetLineColor

	mov	si, offset statArray + (NUM_POINTS-2) * (size PerfStatStruc)
	add	si, bx			;offset into structure, according
					;to which graph we are drawing.

	mov	bp, cx			;set bp = cx (X coord to draw at)
	add	dx, GRAPH_HEIGHT-1	;dx = Y coord of X (horiz) axis

	;setup (lastX, lastY), so that we don't have to draw anything
	;until we deviate from a flat line.

	mov	ax, word ptr ds:[si]	;get first data value

	cmp	ax, GRAPH_HEIGHT	;test against maximum value
	jl	5$

	mov	ax, GRAPH_HEIGHT-1	;correct value

5$:
	mov	bx, dx			;bx = Y coord of X (horiz) axis
	sub	bx, ax			;bx = first Y value

	mov	ax, cx			;ax = first X value

	mov	cx, GRAPH_WIDTH		;cx = loop counter

10$:	;for each X value across the graph:
	;	si	= offset to grab data points
	;	di	= GState
	;	dx	= Y coord of X (horiz) axis
	;
	;	ax	= lastX
	;	bx	= lastY
	;
	;	bp	= curX
	;
	;	cx	= loop counter

	;adjust top of line segment according to statistic value

	push	dx			;save Y coord of X (horiz) axis
	push	di			;save GState handle
	mov	di, word ptr ds:[si]	;get value

	cmp	di, GRAPH_HEIGHT	;test against maximum value
	jl	20$

	mov	di, GRAPH_HEIGHT-1	;correct value

20$:
	sub	dx, di			;dx = curY value
	pop	di			;restore ^hdi = GState

	;now see if we need to draw a horizontal line to the last
	;data point

	cmp	cx, 1			;are we at the far-right side of
					;the graph?
	je	drawHorizLine		;must draw line to previous point
					;if so...

	cmp	bx, dx			;lastY = curY?
	je	nextPoint		;skip if so (no need to draw anything)..

drawHorizLine:
	;We have a change in the Y coordinate (or are at the far right side
	;of the graph): we must draw a horizontal line to the last point
	;at this Y coord.

	push	cx			;save loop count

	;quick trivial reject: if horizontal line is two pixels long,
	;then no need to draw, because each of these pixels is the endpoint
	;of a vertical line.

	mov	cx, bp			;cx = curX
	sub	cx, ax
	dec	cx			;does curX = lastX+1 ?
	je	checkForVertLine	;skip if so...

	mov	cx, bp			;cx = curX
	call	GrDrawHLine		;draw: (ax, bx) -> (cx, bx)

checkForVertLine:
	;now, if there is really a change in the Y coordinate value,
	;then we must draw a vertical line

	mov	ax, bp			;lastX = curX

	cmp	bx, dx			;lastY = curY?
	je	nextPointPopCX		;skip if so (are at right edge)...

	call	GrDrawVLine		;draw: (ax, bx) -> (ax, dx)
	mov	bx, dx			;lastY = curY

nextPointPopCX:
	pop	cx

nextPoint:
	sub	si, size PerfStatStruc	;point to next entry in table
	inc	bp			;move over in X coordinate

	pop	dx			;restore Y margin
	loop 	10$

	.leave
	ret
PlotPoints	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PrintLastValue

DESCRIPTION:	Prints a number representing the last value which was
		monitored.

CALLED BY:	DrawOnePerfMeter

PASS:		ds	= dgroup
		bx	= StatType indicating which graph to draw
					(ST_CPU_USAGE, etc)
		cx	= X margin on left side of graph (makes room for
						graphs drawn to the left)
		dx	= Y margin above graph (make room for captions)
		^hdi	= GState

RETURN:		ds, bx, cx, dx, di	= same

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PrintLastValue	proc	near

	;get numeric value to print

	mov	si, word ptr ds:[numericLast][bx]

	;see if this value has changed since last time we drew it.

	cmp	si, word ptr ds:[oldNumericLast][bx]
	LONG je	done

	;we have to draw this value

	push	bx, cx, dx		;save stat type, X and Y margins

	push	bx			;save stat type

	;erase the background behind the value if not drawing into an icon

	tst	ds:[viewWindow]		;special case: see if iconified.
	jz	5$			;if so, values are drawn inside
					;graph, so no need to draw background.

;future
;	tst	ds:[placeValuesBelow]
;	jz	5$

	push	ax, bx, cx, dx
	mov	ax, OVERALL_BACKGROUND_COLOR
	call	GrSetAreaColor

	add	dx, GRAPH_HEIGHT	;(cx, dx) = top left of text area
	mov	ax, cx
	mov	bx, dx

	add	cx, GRAPH_WIDTH
	add	dx, EXTRA_MARGIN_FOR_VALUES_BELOW_GRAPH
	call	GrFillRect
	pop	ax, bx, cx, dx

5$:	;now get ready to draw the value

	push	cx, dx
	mov	cx, FID_DTC_URW_ROMAN	;font (URW Roman)
	mov	dx, VALUE_TEXT_POINT_SIZE	;point size (integer)
	clr	ah				;point size (fraction) = 0
	call	GrSetFont		;change the GState

	;set the text color according to our textColor variable

	mov	ax, ds:[valueColor]
	call	GrSetTextColor		;set text color in GState

	pop	cx, dx

	;set the position

	mov	ax, cx			;get X margin
	add	ax, VALUE_TEXT_X_INSET	;move a little inside

	mov	bx, dx			;get Y margin
	add	bx, VALUE_TEXT_Y_INSET	;move a little downwards

	test	ds:[displayOptions], mask PDO_SHOW_VALUES
	jz	10$

	tst	ds:[viewWindow],	;special case: see if iconified.
	jz	10$			;is so, then draw value inside graph...

;	tst	ds:[placeValuesBelow]
;	jz	10$

	add	bx, VALUE_TEXT_Y_INSET_WHEN_BELOW_GRAPH

10$:
	mov	cx, si			;get numeric value to print
	call	DrawDecimal

	;see if we want to write the units

	pop	bp			;get stat type
	mov	bp, cs:[ChartUnitNames][bp]
					;get chunk handle for unit name
					;in PerfProcStrings resource

	push	ds			;point to the LOCKED strings resource
	mov	ax, ds:[procStringsSeg]
EC <	tst	ax							>
EC <	ERROR_Z	PERF_ERROR						>

	mov	ds, ax
	assume	ds:PerfProcStrings
	clr	dx

	mov	bp, ds:[bp]		;point to chunk
	mov	dl, byte ptr ds:[bp]
	tst	dl
	jz	90$

	call	GrDrawCharAtCP

	inc	bp
	mov	dl, byte ptr ds:[bp]
	tst	dl
	jz	90$

	call	GrDrawCharAtCP

90$:
	pop	ds			;restore ds = dgroup
	assume	ds:dgroup

	pop	bx, cx, dx		;restore X and Y margins

done:
	ret
PrintLastValue	endp

;pass ax, bx = position, cx = number

DrawDecimal	proc	near
	call	GrMoveTo
	push	cx, dx, si

	clr	dh			;flag: still writing leading 0's.
	mov	si, 10000
	call	CountIt

	mov	si, 1000
	call	CountIt

	mov	si, 100
	call	CountIt

	mov	dh, 1				;force display of 10's digit
	mov	si, 10
	call	CountIt

	clr	dh
	mov	dl, '.'
	call	GrDrawCharAtCP

	mov	dl, cl
	add	dl, '0'
	call	GrDrawCharAtCP

	pop	cx, dx, si
	ret
DrawDecimal	endp

;si = base
;cx = number

CountIt	proc	near
	mov	dl,'0'

CI_loop:
	cmp	cx, si
	jb	CI_end

	sub	cx, si
	inc	dl
	jmp	CI_loop

CI_end:
	tst	dh
	jnz	CI_do

	cmp	dl, '0'
	jz	CI_ret				;skip leading 0's...

CI_do:
	clr	dh
	call	GrDrawCharAtCP
	mov	dh,1

CI_ret:
	ret
CountIt	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PrintChartCaption

DESCRIPTION:	Prints the caption text for a chart.
		monitored.

CALLED BY:	DrawOnePerfMeter

PASS:		ds	= dgroup
		bx	= StatType indicating which graph to draw
					(ST_CPU_USAGE, etc)
		cx	= X margin on left side of graph (makes room for
						graphs drawn to the left)
		dx	= Y margin above graph (make room for captions)
		^hdi	= GState

RETURN:		ds, bx, cx, dx, di	= same

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PrintChartCaption	proc	near
	push	bx, cx, dx

	;first change some of the default GState values, such as font

	push	bx, cx, dx
	mov	cx, FID_DTC_URW_ROMAN	;font (URW Roman)
	mov	dx, CAPTION_TEXT_POINT_SIZE
					;point size (integer)
	clr	ah			;point size (fraction) = 0
	call	GrSetFont		;change the GState

	;set the text color according to our textColor variable

	mov	ax, ds:[captionColor]
	call	GrSetTextColor		;set text color in GState

	;draw some text onto the document

	pop	bp, ax, bx		;get position for text

	sub	bx, CAPTION_HEIGHT+2	;place caption above chart area

	;lock the strings resource, and grab one string

	mov	si, cs:[ChartNames][bp]	;set si = chunk of chart name text
					;within string resource

	push	ds			;point to the LOCKED strings resource
	push	ax
	mov	ax, ds:[procStringsSeg]
EC <	tst	ax							>
EC <	ERROR_Z	PERF_ERROR						>

	mov	ds, ax
	assume	ds:PerfProcStrings
	pop	ax

	mov	si, ds:[si]		;point to the chunk
	ChunkSizePtr ds, si, cx		;cx = length of string
	call	GrDrawText		;draw text into window

	pop	ds			;restore ds = dgroup
	assume	ds:dgroup

	pop	bx, cx, dx
	ret
PrintChartCaption	endp

PerfDrawCode ends
