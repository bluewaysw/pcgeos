COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Open
FILE:		openGauge.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLGaugeClass		Open look Gauge

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/89		Initial version

	$Id: copenGauge.asm,v 2.9 95/11/06 16:26:32 clee Exp $

DESCRIPTION:

-------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

OLGaugeClass:

Synopsis
--------

OLGauge is the OPEN LOOK Gauge object



State Information
-----------------

Generic state:


Specific state derived from Generic state:
	(State which can be derived from generic state by OPEN LOOK
	generic object)

	VI_visBounds	- current position & size
	VI_visAttr	- attributes (managed, drawable, detectable)
	Which visMoniker to use
	OLGI_mgr	- manager of this specific object

Specific state not derivable from Generic state:
	none

State information for optimization purposes:
	VI_visOptFlags	- not composite, not window

	NOTE: The section between "Declaration" and "Methods declared" is
	      copied into uilib.def by "pmake def"

Declaration
-----------

OLGaugeClass	class VisClass

;DeclareMethod	OLGaugeClass, METHOD_SET_OL_GAUGE_GEN_STATE


;	These flags represent the current state of the Gauge:

OLGaugeOptFlags	record
	OLGOF_VERTICAL:1,		;If gauge is to be drawn vertically
	OLGOF_DISP_MNKR:1,		;If we're to display the main moniker
	OLGOF_DISP_TICKS:1,		;Whether to display tick marks
	OLGOF_DISP_END_MNKRS:1,		;Whether to display end monikers
	:4
OLGaugeOptFlags	end

    OLGI_optFlags	byte	OLGaugeOptFlags		;keep these two flags

OLGaugeClass	endc


PROP_WIN_TEXT_SPACING	=	12	;space between text and gadget in
 					;property windows -- should be  						;defined in the openPropWin.asm


Methods declared
----------------

------------------------------------------------------------------------------@

CommonUIClassStructures segment resource

	OLGaugeClass	mask CLASSF_NEVER_SAVED or mask CLASSF_DISCARD_ON_SAVE

	method	VupCreateGState, OLGaugeClass, MSG_VIS_VUP_CREATE_GSTATE

DefMethod	OLGaugeClass, METHOD_DRAW, OLGaugeDraw
DefMethod	OLGaugeClass, METHOD_GET_SIZE, OLGaugeGetSize
DefMethod	OLGaugeClass, METHOD_GET_CENTER, OLGaugeGetCenter

CommonUIClassStructures ends

;---------------------------------------------------

DrawBW segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBWGauge

DESCRIPTION:	Draw an OL Gauge on a black and white display

CALLED BY:	INTERNAL
		OLGaugeDraw

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ch - DrawFlags:  DF_EXPOSED set if updating
	di - GState to use

RETURN:
	carry - set

DESTROYED:
	all

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/89		Initial version

------------------------------------------------------------------------------@

DrawBWGauge	proc	far
	stc				; show complete
	ret
DrawBWGauge	endp

DrawBW ends


;---------------------------------------------------
if not _ASSUME_BW_ONLY
DrawColor segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawColorGauge

DESCRIPTION:	Draw an OL Gauge on a color display

CALLED BY:	INTERNAL
		OLGaugeDraw

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	cl - color scheme
	ch - DrawFlags:  DF_EXPOSED set if updating
	di - GState to use

RETURN:
	carry - set

DESTROYED:
	all

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	The general case is to redraw the entire Gauge.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GAUGE_LEFT_MARGIN	=	6	;offset from start of gauge to min
GAUGE_RIGHT_MARGIN	=	8	;offset from end of gauge to max
GAUGE_Y_OFFSET		=	2	;offset to top of gauge
GAUGE_WIDTH		=	12	;width of gauge (as opposed to length)
TICKS_Y_OFFSET		=	GAUGE_WIDTH + 2     ;offset to tick ypos
MINMAX_Y_OFFSET		=	TICKS_Y_OFFSET + 6  ;offet to min max text

DrawColorGauge	proc	far
	push	si, ds
	push	cx				;save color scheme and update
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	;
	;Make ds:si point at the correct GaugeDraw structure,
	;	cx = Gauge width, dx = Gauge height
	;
	call	GenGetMonikerSize		;return width of moniker in cx
	add	cx,PROP_WIN_TEXT_SPACING+STD_OL_LEFT_MARGIN ;add in left margin
	push	cx				;save as offset to gauge
	;
	; Draw the various and sundry monikers.
	;
	mov	cl,(J_LEFT shl offset MJ_X_JUST) or \
		(J_LEFT shl offset MJ_Y_JUST)
	mov	dx, STD_OL_LEFT_MARGIN	       ;inset to left margin
	mov	bp, di			; pass GState in bp
	call	GenDrawMoniker		;draw the text for this
	;
	; Draw the min moniker, x inset = offset to gauge
	; + LEFT_MARGIN - (1/2 length minMoniker)
	;
	mov	di, ds:[si]		;point at instance data
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	di, ds:[di][GRI_minMoniker]	;pass handle of min moniker
	mov	bx, di				; (also keep in bx)
	call	VisGetMonikerSize		;get size of min moniker
	shr	cx, 1				;divide width by 2
	pop	dx				;restore offset to gauge
	push	dx				;we'll need it later...
	add	dx, GAUGE_LEFT_MARGIN		;now offset to min
	sub	dx, cx				;subtract 1/2 min mnkr size
	mov	cl,(J_LEFT shl offset MJ_X_JUST) or \
		(J_LEFT shl offset MJ_Y_JUST)
	mov	dh, MINMAX_Y_OFFSET		;offset to text
	call	VisDrawMoniker			;draw it
	;
	; Draw the max moniker, x inset from right edge.
	;   If max moniker size > 2 * RIGHT_MARGIN
	;       x inset = 0
	;	gauge right = VI_right + RIGHT_MARGIN - 1/2 moniker size
	;   else
	;       x inset = RIGHT_MARGIN - 1/2 moniker size
	;	gauge right = VI_right
	;
	mov	di, ds:[si]			;again point to instance data
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	bx, ds:[di][GRI_maxMoniker]	;pass handle of min moniker
	mov	di, bx				;  (also keep in bx)
	call	VisGetMonikerSize		;get size of moniker
	mov	ax, GAUGE_RIGHT_MARGIN		;start with right margin
	shr	cx, 1				;else divide by 2
	sub	ax, cx				;and subtract 1/2 width

	cmp	cx, GAUGE_RIGHT_MARGIN		;see if larger than margin
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	cx, ds:[di].VI_bounds.R_right	;assume not, goes to right edge
	sub	cx, STD_OL_RIGHT_MARGIN		;subtract this always
	mov	dx, ax				;and inset = margin-1/2 width
	jb	DCG10				;if not, branch
	clr	dx				;else no inset
	add	cx, ax				;add margin-1/2 width to right
DCG10:
	add	dx, STD_OL_RIGHT_MARGIN		;add this to the inset
	push	cx				;save as right edge of gauge
	mov	cl,(J_RIGHT shl offset MJ_X_JUST) or \
		(J_LEFT shl offset MJ_Y_JUST)
	mov	dh, MINMAX_Y_OFFSET		;offset to text
	call	VisDrawMoniker			;draw it

	pop	cx				;restore right edge of gauge
	pop	ax				;restore offset to gauge
	mov	di, ds:[si]			;ds:si = instance data
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	add	ax, ds:[di].VI_bounds.R_left	;add left to width

	mov	bx, ds:[di].VI_bounds.R_top
	add	bx, GAUGE_Y_OFFSET		;add offset to gauge
	call	GrMoveTo
	sub	cx,ax				;gauge width = right - left
	inc	cx
	mov	dx, GAUGE_WIDTH   	       	;standard height of gauge
	;
	; Let's calculate the offset needed for the filled area.
	;
	push	dx
	mov	bx, cx				;put right edge in bx
	sub	bx, GAUGE_LEFT_MARGIN+GAUGE_RIGHT_MARGIN
						;subtract left and right margins
	push	bx				;useful later...
	mov	di, ds:[si]			;ds:si = instance data
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	ax, ds:[di][GRI_curValue]	;get the current value
	sub	ax, ds:[di][GRI_minValue]	;subtract min value
	mul	bx				;multiply, result in dx:ax
	mov	bx, ds:[di][GRI_maxValue]	;divisor is max-min
	sub	bx, ds:[di][GRI_minValue]	;
	div	bx				;result in ax
	mov	bx, ax				;now in bx
	add	bx, GAUGE_LEFT_MARGIN	      	;add offset to left
	pop	ax				;get length back
	pop	dx

	push	ax				;save length for later...
	mov	ax, C_BLACK			;do right/bottom in black
	call	GrSetAreaColor
	call	GrSetTextColor

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawColorRegions				>
FXIP < 	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

NOFXIP<	segmov	ds, cs				;region data in code	>
	
	mov	si, offset CBRborderRB
	call	GrDrawRegionAtCP

        mov	si, offset gaugeMercData
	call	GrDrawRegionAtCP

	mov	ax, C_WHITE			;do top/left in white
	call	GrSetAreaColor
	mov	si, offset CBRborderLT
	call	GrDrawRegionAtCP

	mov	ax, C_DARK_GREY
	call	GrSetAreaColor

	mov	si, offset gaugeLineData
	call	GrDrawRegionAtCP
	pop	bx				;restore length
	;
	; First, let's do the gradient marks.  For starters, let's try to do
	; 10 of them...
	;
	mov	cx, 11				;first do ten divisions
DCG30:
	push	cx
	push	dx
	mov	ax, bx				;length of gauge in ax
	dec	cx				;use cx-1
	mul	cx				;dx:ax = ax * cx
	mov	cx, 10				;now divide by 10
	div	cx				;result in ax
	add	ax, GAUGE_LEFT_MARGIN	       	;offset to gauge
	mov	cx, ax				;put in cx
	pop	dx				;restore offset to tick
	;
	; Offset to tick in cx (x pos), top of gauge in dx, draw the tick mark.
	;
	mov	ax, C_WHITE
	call	GrSetAreaColor
	mov	si, offset gaugeTickWData	;draw white tick
	call	GrDrawRegionAtCP
	mov	ax, C_BLACK
	call	GrSetAreaColor
	mov	si, offset gaugeTickBData	;draw black tick
	call	GrDrawRegionAtCP
	pop	cx				;restore count
	loop	DCG30				;branch
	;
	; Draw moniker offset in X and centered in Y
	;

	pop	cx
	DoPop	ds, si

FXIP <	push	bx							>
FXIP <	mov	bx, handle DrawColorRegions				>	
FXIP <	call	MemUnlock						>
FXIP <	pop	bx							>
	
	stc				; show complete
	ret

DrawColorGauge	endp

DrawColor ends
endif		; if not _ASSUME_BW_ONLY

;---------------------------------------------------

Geometry segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLGaugeSpecVisOpenNotify -- MSG_SPEC_VIS_OPEN_NOTIFY
							for OLGaugeClass

DESCRIPTION:	Handle notification that an object with GA_NOTIFY_VISIBILITY
		has been opened

PASS:
	*ds:si - instance data
	es - segment of OLGaugeClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/24/92		Initial version

------------------------------------------------------------------------------@
OLGaugeSpecVisOpenNotify	method dynamic	OLGaugeClass,
						MSG_SPEC_VIS_OPEN_NOTIFY
	call	VisOpenNotifyCommon
	ret

OLGaugeSpecVisOpenNotify	endm

;---

OLGaugeSpecVisCloseNotify	method dynamic	OLGaugeClass,
						MSG_SPEC_VIS_CLOSE_NOTIFY
	call	VisCloseNotifyCommon
	ret

OLGaugeSpecVisCloseNotify	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLGaugeGetSize -- METHOD_GET_SIZE for OLGaugeClass

DESCRIPTION:	Returns the size of the Gauge.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- METHOD_GET_SIZE
		cx	- width info for choosing size
		dx 	- height info

RETURN:		cx 	- width to use
		dx 	- height to use

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/89		Initial version

------------------------------------------------------------------------------@


OLGaugeGetSize	method	OLGaugeClass, METHOD_GET_SIZE
EC <	call	ShowcallsGeoEntry					>
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	push	cx			;save width passed in
	clr	bp			;no GState...
	call	GenGetMonikerSize	;get size of main moniker
	mov	ax, cx			;store as minimum width of gauge
	add	ax, GAUGE_LEFT_MARGIN+GAUGE_RIGHT_MARGIN+1
	pop	cx
	; don't bother setting  min height, usually in bx
	clr	bp			;do not optionally expand Gauges
	call	VisHandleMinResize	;keeps in min, max range, desired
					;  is the minimum
	push	cx			;save width to return
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	di, ds:[di][GRI_minMoniker]  ;get handle of min moniker
	clr	bp
	call	VisGetMonikerSize	     ;returns height of min mnkr
	push	dx

	mov	bp, dx			     ;save in bp
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	di, ds:[di][GRI_maxMoniker]  ;get height of max moniker
	clr	bp
	call	VisGetMonikerSize	     ;returns height of max moniker
	pop	cx			     ;restore height of other moniker
	cmp	dx, cx			     ;see if bigger
	ja	OLGGS10			     ;no, branch
	mov	dx, cx			     ;else use as height to return
OLGGS10:
	add	dx, MINMAX_Y_OFFSET	     ;add y offset to min & max text
	pop	cx		             ;restore width to return
OLGCS90:
EC <	call	ShowcallsGeoExit					>
	ret
OLGaugeGetSize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLGaugeGetCenter -- METHOD_GET_CENTER for OLGaugeClass

DESCRIPTION:	Returns the center of the gauge.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- METHOD_GET_CENTER

RETURN:		cx -- center of object in x direction
		dx -- center of object in y direction.

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/24/89		Initial version

------------------------------------------------------------------------------@


OLGaugeGetCenter	method OLGaugeClass, METHOD_GET_CENTER
	call	VisGetCenter			;get real center of object
	push	dx				;and save height
	clr	bp				;no GState around
	call	GenGetMonikerSize		;return moniker size as width
	pop	dx
	ret
OLGaugeGetCenter	endm

Geometry ends

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLGaugeDraw -- METHOD_DRAW for OLGaugeClass

DESCRIPTION:	Draw the Gauge

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - METHOD_DRAW

	cl - DrawFlags:  /staff/pcgeos/chris/Library/OpenLook/Open
	ch - ?
	dx - ?
	bp - GState to use

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Call the correct draw routine based on the display type:

	if (black & white) {
		DrawBWGauge();
	} else {
		DrawColorGauge();
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

OLGaugeDraw	method	OLGaugeClass, METHOD_DRAW
	mov	di,bp				;di = GState

	; get display scheme data

	push	cx
	mov	ax,GIT_PRIVATE_DATA
	call	GrGetInfo			;returns ax, bx, cx, dx
	pop	cx

	;al = color scheme, ch = update flag, cl = display type

	and	cl,mask DF_DISPLAY_TYPE
	cmp	cl,DC_GRAY_1
	jnz	OLGD_color

	; draw black & white

	GotoMod	DrawBWGauge

	; draw color

OLGD_color:
	mov	cl, al				; Pass color scheme in cl
						; (ax & bx get trashed)
	GotoMod	DrawColorGauge

OLGaugeDraw	endm

CommonFunctional ends

