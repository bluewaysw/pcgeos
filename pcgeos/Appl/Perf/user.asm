COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Perf	(Performance Meter)
FILE:		user.asm (code to handle UI events)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

DESCRIPTION:
	This file source code for the Perf application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: user.asm,v 1.1 97/04/04 16:27:04 newdeal Exp $

------------------------------------------------------------------------------@

PerfUIHandlingCode segment resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfStartSelect -- MSG_META_START_SELECT handler

DESCRIPTION:	This method is sent when the user clicks in the GenView
		area. If the controls are hidden, we show them. We also
		determine which graph the user is clicking on, and we
		select that graph in the scrolling list. If the user
		has double clicked, we open the GraphColors dialog box.

PASS:		ds	= dgroup
		cx, dx	= position of mouse in document coordinates
		bp	= [ UIFunctionsActive | ButtonInfo ]

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		initial version

------------------------------------------------------------------------------@

PerfStartSelect	method	PerfProcessClass, MSG_META_START_SELECT

	;is the mouse button pressed?

	test	bp, mask UIFA_SELECT shl 8
	jz	90$			;skip to end if not...

	;In case the Colors dialog box is up, let's set the active graph
	;in that dialog box.

	push	bp
	mov	di, ST_AFTER_LAST_STAT_TYPE
					;di = offset to last chart type

10$:	;for each chart which is displayed:

	sub	di, 2
	cmp	word ptr ds:[graphXPositions][di], cx
					;pointing to this graph?
	jle	30$			;skip if so...

	;if not at first graph, then loop

	tst	di
	jnz	10$			;loop for more...

30$:	;we have found the right graph: set the list

	mov	ds:[currentGraph], di
	mov	cx, di

	call	PerfSetGraphColorsChooseMeter	;in FixedCommonCode resource

	;if this is a double-click, open the help dialog box

	pop	bp
	test	bp, mask BI_DOUBLE_PRESS
	jz	90$			;skip if is not a double-click...

if 0	;2.0 BUSTED - HELP WINDOW
	;open the help window, and scroll to the text for this graph

	GetResourceHandleNS	HelpBox, bx
	mov	si, offset HelpBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage
endif

	;mov	di, ds:[currentGraph]
	;mov	cx, cs:[ChartHelpStartOffsets][di]
	;mov	dx, cs:[ChartHelpEndOffsets][di]
	;inc	dx

;2.0BUSTED - TEXT SELECTION
;	GetResourceHandleNS	HelpText, bx
;	mov	si, offset HelpText
;	mov	ax, MSG_SET_SELECTION
;	clr	di
;	call	ObjMessage			;ax = chunk

90$:	;done

	mov	ax, mask MRF_PROCESSED
	ret
PerfStartSelect	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetGraphMode -- MSG_PERF_SET_GRAPH_MODE

DESCRIPTION:	This method is sent by our "Performance Meters" GenList,
		when the user enables or disables one of the performance meters.

PASS:		ds	= dgroup
		cx	= StatTypeMask indicating the state of all of the items.
		bp	= StatTypeMask indicating which items changed.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update
	Eric	5/92		2.0 port

------------------------------------------------------------------------------@

PerfSetGraphMode	method	PerfProcessClass, MSG_PERF_SET_GRAPH_MODE

	;make sure that the data passed from the GenListEntry is cool.

EC <	test	cx, not (mask StatTypeMask)				>
EC <	ERROR_NZ PERF_ERROR_BAD_UI_ARGUMENTS				>

	;update our list of BooleanWords, according to the new state

	clr	di				;start with the 0th item

10$:	;check this BooleanWord

	clr	ax
	shl	cx, 1				;CY = bit flag
	adc	ax, 0				;ax = 0 or 1

	mov	word ptr ds:[graphModes][di], ax

	add	di, 2
	cmp	di, ST_AFTER_LAST_STAT_TYPE
	jl	10$

	;calculate the new number of graphs

	call	PerfCalcNumGraphs	;in FixedCommonCode resource

	;send method to self so that we will eventually update the view

	call	PerfForceEventualViewUpdate
	ret
PerfSetGraphMode	endm


PerfForceEventualViewUpdate	proc	near

	;send self a method, delayed by the UI queue, to resize the view.

	call	GeodeGetProcessHandle
	mov	cx, bx			;pass ^lcx:dx = destination for message
	clr	dx
	mov	ax, MSG_PERF_SIZE_VIEW_ACCORDING_TO_GRAPHS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	ret
PerfForceEventualViewUpdate	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSizeViewAccordingToGraphs

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

PerfSizeViewAccordingToGraphs	method	PerfProcessClass,
				MSG_PERF_SIZE_VIEW_ACCORDING_TO_GRAPHS

	;we will set ax = total width of all graphs and margins

	mov	al, GRAPH_WIDTH+GRAPH_SPACING
	mul	ds:[curNumGraphs]	;ax = al*[curNumGraphs]


	inc	ax			;in case there are none, set min
					;width = 1
	cmp	ax, 1
	je	10$			;skip if that is the case...

	;otherwise, add margins, and remove the extra graph spacing that
	;we added into the sum (and correct for the +1 above)

	add	ax, LEFT_MARGIN+RIGHT_MARGIN-GRAPH_SPACING-1

10$:	;and set dx = total height

	mov	dx, TOP_MARGIN+BOTTOM_MARGIN+GRAPH_HEIGHT

	;add room for captions above

	test	ds:[displayOptions], mask PDO_SHOW_CAPTIONS
	jz	20$

	add	dx, CAPTION_HEIGHT

20$:	;and add room for values drawn below

	test	ds:[displayOptions], mask PDO_SHOW_VALUES
	jz	setViewSize

;future
;	tst	ds:[placeValuesBelow]
;	jz	setViewSize

	add	dx, EXTRA_MARGIN_FOR_VALUES_BELOW_GRAPH

setViewSize:
	;set new document size. View size will be set to match.

	mov	cx, ax
	dec	cx			;cx = right side Y coord
	dec	dx			;dx = bottom X coord
	clr	ax			;ax = 0, for left X and top y coords

	GetResourceHandleNS	PerfView, bx
	mov	si, offset PerfView

	.assert (size RectDWord) eq 16
	push	ax, dx, ax, cx, ax, ax, ax, ax
	mov	bp, sp			;ss:bp = RectDWord struct on stack

	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS
	mov	dx, size RectDWord
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
	call	ObjMessage		;ax = chunk

	add	sp, (size word)*4	;clean up stack
	pop	ax, dx, ax, cx

	GetResourceHandleNS	PerfPrimary, bx
	mov	si, offset PerfPrimary

	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_NOW
;	mov	di, mask MF_FORCE_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;ax = chunk

	;force a complete redraw

	call	PerfEraseViewWindow	;will set redrawCaptions = 1, so

	ret
PerfSizeViewAccordingToGraphs	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetUpdateRate -- MSG_PERF_SET_UPDATE_RATE handler

DESCRIPTION:	This method is sent from the "Update Rate" GenRange object.

PASS:		ds	= dgroup
		cx	= new update rate (updates per second)

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

;PerfSetUpdateRate	method	PerfProcessClass, MSG_PERF_SET_UPDATE_RATE
;
;	;make sure that  1 <= (updates per second) <= 10
;
;EC <	cmp	cx, 10							>
;EC <	ERROR_G PERF_ERROR_BAD_UI_ARGUMENTS				>
;
;	mov	ds:[updateRate], cl		;save new update rate
;
;	call	PerfSetTimerInterval		;(in FixedCommonCode resource)
;						;and reset our timer
;	ret
;PerfSetUpdateRate	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfHideControls -- MSG_PERF_HIDE_CONTROLS

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

;nuked for new 2.0 UI arrangement
;PerfHideControls	method	PerfProcessClass, MSG_PERF_HIDE_CONTROLS
;
;	GetResourceHandleNS	PerfControls, bx
;	mov	si, offset PerfControls
;	mov	ax, MSG_GEN_SET_NOT_USABLE
;	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
;	clr	di
;	call	ObjMessage			;ax = chunk
;
;	GetResourceHandleNS	PerfPrimary, bx
;	mov	si, offset PerfPrimary
;	mov	ax, MSG_VIS_RESET_TO_INITIAL_SIZE
;	mov	dl, VUM_NOW
;	clr	bp				;no flags
;	clr	di
;	call	ObjMessage			;ax = chunk
;	ret
;PerfHideControls	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetDisplayOptions -- MSG_PERF_SET_DISPLAY_OPTIONS

DESCRIPTION:	This method is sent by our "Display Options" GenList,
		when the user makes a change.

PASS:		ds	= dgroup
		cx	= new PerfDisplayOptions record
		bp	= which bits changed

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update
	Eric	5/92		2.0 port

------------------------------------------------------------------------------@

PerfSetDisplayOptions	method	PerfProcessClass, \
						MSG_PERF_SET_DISPLAY_OPTIONS

	;make sure that the data passed from the GenListEntry is cool.

EC <	test	cl, not (mask PerfDisplayOptions)			>
EC <	ERROR_NZ PERF_ERROR_BAD_UI_ARGUMENTS				>

	;save the new state of all of the bit flags

	mov	ds:[displayOptions], cl

	;if the "Show Values" setting changed, update the "Place Values"
	;list below it.

;	test	bp, mask PDO_SHOW_VALUES
;	jz	95$
;
;	mov	ax, MSG_GEN_SET_ENABLED
;	test	cl, mask LES_ACTUAL_EXCL ;is this list entry on?
;	jnz	92$			 ;skip if so...
;
;	mov	ax, MSG_GEN_SET_NOT_ENABLED
;
;92$:
;	pushf	
;	GetResourceHandleNS	ValuesInsideOrBelowGraphGenList, bx
;	mov	si, offset ValuesInsideOrBelowGraphGenList
;	mov	dl, VUM_NOW
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	call	ObjMessage		;returns ah = DisplayType
;	popf
;	jnz	95$			;skip if is now on...
;95$:

	;force an update, if necessary

	test	bp, mask PDO_SHOW_CAPTIONS or mask PDO_SHOW_VALUES
	jz	99$

	;send method to self so that we will eventually update the view

	call	PerfForceEventualViewUpdate

99$:
	ret
PerfSetDisplayOptions	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetValueLocation -- MSG_PERF_SET_VALUE_LOCATION

DESCRIPTION:	This method is sent by our "Place Value" GenList,
		when the user makes a change.

PASS:		ds	= dgroup
		cx	= TRUE/FALSE
		bp (high) = ListUpdateFlags
		bp (low)  = 

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

;PerfSetValueLocation	method	PerfProcessClass, \
;						MSG_PERF_SET_VALUE_LOCATION
;
;	;cx = TRUE or FALSE, so just store lower byte of this value
;
;	mov	ds:[placeValuesBelow], cl	;save the new state
;
;	;send method to self so that we will eventually update the view
;
;	call	PerfForceEventualViewUpdate
;	ret
;PerfSetValueLocation	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetOnOffState -- MSG_PERF_SET_ON_OFF_STATE

DESCRIPTION:	This method is sent by our "On/Off" GenList,
		when the user makes a change.

PASS:		ds	= dgroup
		cx	= TRUE/FALSE

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfSetOnOffState	method	PerfProcessClass, \
						MSG_PERF_SET_ON_OFF_STATE

	;cx = TRUE or FALSE

	mov	ds:[onOffState], cx	;save the new state

	;set the new timer interval (none if we are now "off")

	call	PerfSetTimerInterval	;(in FixedCommonCode resource)
	ret
PerfSetOnOffState	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetGraphColor -- MSG_PERF_SET_GRAPH_COLOR

DESCRIPTION:	This method is sent by our "Graph Colors" GenList,
		when the user makes a change.

PASS:		ds	= dgroup
		cxdx	= ColorQuad
		bp (high) = ListUpdateFlags
		bp (low)  = 

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfSetGraphColor	method	PerfProcessClass, \
					MSG_META_COLORED_OBJECT_SET_COLOR

	;figure out which graph we are talking about

	mov	si, ds:[currentGraph]
EC <	cmp	si, ST_AFTER_LAST_STAT_TYPE				>
EC <	ERROR_GE PERF_ERROR						>

	;si = StatType, cxdx = ColorQuad

.assert (offset CQ_redOrIndex eq 0)	;in ColorQuad structure
.assert (offset CQ_info eq 1)		;in ColorQuad structure
.assert (CF_INDEX eq 0)			;in ColorFlag enum in ColorQuad struc

	cmp	ch, CF_INDEX
	je	storeColor
	movdw	axbx, cxdx
	clr	di
	call	GrMapColorRGB		; index -> AH
	clr	cx
	mov	cl, ah
storeColor:
	mov	word ptr ds:[graphColors][si], cx
	mov	word ptr ds:[InitialGraphColors][si], cx
	ret
PerfSetGraphColor	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfEraseViewWindow

DESCRIPTION:	

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/27/91		Initial Version

------------------------------------------------------------------------------@

PerfEraseViewWindow	proc	near
	;see if the application is iconified or open

	mov	di, ds:[viewWinGState]
	tst	di
	jz	90$			;skip if is iconified...

	;clear entire area

	mov	ax, OVERALL_BACKGROUND_COLOR	;whether in color or B&W mode
	call	GrSetAreaColor

	clr	ax			;draw backdrop
	clr	bx
	mov	cx, MAX_DOC_WIDTH-1	;change this for V2.0
	mov	dx, MAX_DOC_HEIGHT-1
	call	GrFillRect

	mov	ds:[redrawCaptions], 1	;force a redraw of captions

90$:
	ret
PerfEraseViewWindow	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfDisplayCPUSpeed -- MSG_PERF_DISPLAY_CPU_SPEED

DESCRIPTION:	This method is sent by our "Display CPU Speed" button.

PASS:		ds	= dgroup
		cx	= color value
		bp (high) = ListUpdateFlags
		bp (low)  = 

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/91		Initial version

------------------------------------------------------------------------------@

PerfDisplayCPUSpeed	method	PerfProcessClass,
						MSG_PERF_DISPLAY_CPU_SPEED
buffer		local	20 dup (char)
	.enter

	clr	dx				;dx:ax = value
	mov	ax, ds:[tonyIndexTimes10]
	mov	cx, mask UHTAF_NULL_TERMINATE
	segmov	es, ss
	lea	di, buffer
	call	UtilHex32ToAscii

	;insert decimal point

	push	di
	add	di, cx				;es:di = null term

	mov	al, es:[di-1]
	mov	{char} es:[di-1], '.'

	mov	es:[di], al
	mov	{char} es:[di+1], 0
	pop	di

	; push SDP_helpContext

	clr	si
	push	si, si

	;push StandardDialogParams, in reverse order:
	; SDP_customTriggers      fptr.StandardDialogResponseTriggerTable
	; SDP_stringArg2          fptr

	sub	sp, (size fptr)*2		;push bogus args.

	; SDP_stringArg1          fptr

	push	es, di				;save fptr to param string

	mov	bx, handle CPUSpeedText
	call	MemLock

	mov	ds, ax
	mov	si, offset CPUSpeedText
	mov	si, ds:[si]			;ds:si = string

	; SDP_customString        fptr

	push	ds, si

	; SDP_customFlags         CustomDialogBoxFlags
	; SDP_type                StandardDialogBoxType

	mov	ax, CustomDialogBoxFlags <0,CDT_NOTIFICATION,GIT_NOTIFICATION,0>
	push	ax

	;put up dialog box

	call	UserStandardDialog		;will clean up stack

	call	MemUnlock

	.leave
	ret
PerfDisplayCPUSpeed	endm

PerfUIHandlingCode ends
