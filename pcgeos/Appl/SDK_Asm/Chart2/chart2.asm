COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Chart2
MODULE:		
FILE:		chart2.asm

AUTHOR:		David Litwin, Jun 13, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/13/94   	Initial revision


DESCRIPTION:
	A lab where charting routines are written.
		

	$Id: chart2.asm,v 1.1 97/04/04 16:35:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;------------------------------------------------------------------------------
;		Generic Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include graphics.def
include gstring.def
include object.def

include Objects/winC.def
include Objects/inputC.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def


;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

NewChartType	etype	word
NCT_ASCENDING	enum	NewChartType
NCT_DESCENDING	enum	NewChartType


MAX_HEIGHT		equ	100
DEFAULT_BAR_WIDTH	equ	20



;------------------------------------------------------------------------------
;			Class definitions
;------------------------------------------------------------------------------


ChartProcessClass	class	GenProcessClass
	; No new methods
	; No new instance data
ChartProcessClass	endc

ChartClass	class	VisClass
;-------------------------------  Messages  -----------------------------------
MSG_CHART_SET_NEW_CHART	message
;	Set the chart to a new chart type given a high range, low range,
; number of bars and an ascending or descending flag.
;
; Context:	Sent when the user clicks "Ascending" or "Descending"
; Source:	UI
; Destination:  a ChartClass object
; Interception: This sets up one of the routines that is to be subclassed for 
;		this lab, so you probably don't want to subclass it.
;
; Pass:		cx	= NewChartType
;			
; Return:	nothing
; Destroyed:	ax, cx, dx, bp
;

;-----------------------------  Instance data  --------------------------------
	CI_chartDataBlock	hptr
	CI_chartDataSize	word
ChartClass	endc


idata	segment
	ChartProcessClass
	ChartClass
idata	ends


;------------------------------------------------------------------------------
;			local includes
;------------------------------------------------------------------------------

include	chart2.rdef



;------------------------------------------------------------------------------
;			Methods
;------------------------------------------------------------------------------


ChartCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartDrawData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bar chart from a block of height data.

CALLED BY:	ChartVisDraw

PASS:		^hdi	= GState
		^hbx	= block of bar heights (one word each)
		cx	= # of bar heights in block
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartDrawData	proc	near
	uses	ax, bx, cx, ds, si
	.enter

	;
	; Replace this with code to draw a bar charts based on the passed
	; in block and size.
	;

	mov	ax, 100
	mov	bx, 100
	clr	cx
	segmov	ds, cs, si
	mov	si, offset sampleText
	call	GrDrawText

	.leave
	ret
ChartDrawData	endp

LocalDefNLString sampleText <"Hello World", 0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCreateNewChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new chart given a range of data, the number
		of bars requested, the progressing direction.  Also passed
		in are the old chart block and old # bars.

CALLED BY:	ChartSetNewChart

PASS:		ax	= NewChartType
		^hbx	= block handle of old chart
		cx	= # of bars (in old chart block)
		dh	= high value of new chart
		dl	= low value of new chart
		bp	= # of bars for new chart
RETURN:		^hbx	= block handle of new chart
		cx	= new # of bars in chart
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCreateNewChart	proc	near
	uses	ax,dx,si,di,bp
	.enter

	;
	; Add code here to generate a new block of height data to
	; be drawn.  This block should contain one word for each bar's
	; height, in an even progression from low to high (or high to low,
	; according the the NewChartType in ax).
	;

	.leave
	ret
ChartCreateNewChart	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw ourselves according to the values in our instance data

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= ChartClass object
		ds:di	= ChartClass instance data
		ds:bx	= ChartClass object (same as *ds:si)
		es 	= segment of ChartClass
		ax	= message #
		cl	= DrawFlags
		^hbp	= GState
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartVisDraw	method dynamic ChartClass, 
					MSG_VIS_DRAW
	.enter

	mov	bx, ds:[di].CI_chartDataBlock
	mov	cx, ds:[di].CI_chartDataSize
	mov	di, bp			; put GState handle in di
	call	ChartDrawData

	.leave
	ret
ChartVisDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate an initial data block for our chart object.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= ChartClass object
		ds:di	= ChartClass instance data
		ds:bx	= ChartClass object (same as *ds:si)
		es 	= segment of ChartClass
		ax	= message #
		bp	= 0 if top window, else window for object
				 to open on
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartVisOpen	method dynamic ChartClass, 
					MSG_VIS_OPEN
	uses	ax, cx, dx, bp
	.enter

	push	ax, bx, cx, dx, bp

	mov	ax, size initialDataSet
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc

	push	ds, si, es
	mov	es, ax
	clr	di				; es:di is our data block

	segmov	ds, cs, si
	mov	si, offset initialDataSet	; ds:si is our code segment data
CheckHack< size word eq 2 >
	mov	cx, (size initialDataSet)/2
	rep	movsw				; copy data into our block

	call	MemUnlock

	pop	ds, si, es

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	ds:[di].CI_chartDataBlock, bx
	mov	ds:[di].CI_chartDataSize, length initialDataSet

	pop	ax, bx, cx, dx, bp
	mov	di, offset ChartClass
	call	ObjCallSuperNoLock

	.leave
	ret
ChartVisOpen	endm

initialDataSet	word	\
	40,
	28,
	15,
	34,
	10,
	38



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the block our instance data points to

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= ChartClass object
		ds:di	= ChartClass instance data
		ds:bx	= ChartClass object (same as *ds:si)
		es 	= segment of ChartClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartVisClose	method dynamic ChartClass, 
					MSG_VIS_CLOSE
	uses	ax, cx, dx, bp
	.enter

	mov	bx, ds:[di].CI_chartDataBlock
	call	MemFree

	clr	ds:[di].CI_chartDataBlock
	clr	ds:[di].CI_chartDataSize

	mov	di, offset ChartClass
	call	ObjCallSuperNoLock

	.leave
	ret
ChartVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartSetNewChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the chart to a new chart type given a high range, low
		range, number of bars and an ascending or descending flag.

CALLED BY:	MSG_CHART_SET_NEW_CHART
PASS:		*ds:si	= ChartClass object
		ds:di	= ChartClass instance data
		ds:bx	= ChartClass object (same as *ds:si)
		es 	= segment of ChartClass
		ax	= message #
		cx	= NewChartType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	changes our chartDataBlock and chartDataSize
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartSetNewChart	method dynamic ChartClass, 
					MSG_CHART_SET_NEW_CHART
	.enter

	push	si			; save our object handle

	push	cx			; save NewChartType
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	GetResourceHandleNS	Interface, bx
	mov	si, offset ChartHigh
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	push	dx			; save high range

	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	si, offset ChartLow	; bx remains the handle to Interface
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	push	dx			; save low range

	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	si, offset ChartBars	; bx remains the handle to Interface
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; dx is # bars


	mov	bp, dx			; # bars in bp
	pop	dx			; low range in dl
	pop	cx
	mov	dh, cl			; high range in dh
	pop	ax			; NewChartType in ax

	pop	si			; restore our object handle
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	bx, ds:[di].CI_chartDataBlock	; block in bx
	mov	cx, ds:[di].CI_chartDataSize	; size in cx

	call	ChartCreateNewChart

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].CI_chartDataBlock, bx
	mov	ds:[di].CI_chartDataSize, cx

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave
	ret
ChartSetNewChart	endm


ChartCode ends
