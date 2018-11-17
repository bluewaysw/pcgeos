COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Video Preferences
FILE:		prefvidGadgets.asm

AUTHOR:		Allen Yuen, Aug 10, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/10/99   	Initial revision


DESCRIPTION:
		
	Code for UI objects for changing video driver settings.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	GPC_VERSION

idata	segment
	PrefVidTvPosInteractionClass
	PrefVidTvSizeInteractionClass
	PrefVidTvSizeBordersPrimaryClass
	PrefVidBooleanGroupClass
	PrefVidBooleanClass
idata	ends

udata	segment
	videoDrStrategy		fptr.far	NULL
udata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTPIMetaLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the horiz and vert pos values from the .INI file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= PrefVidTvPosInteractionClass object
		es 	= segment of PrefVidTvPosInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	In a Pref subclass, reading options from .INI file should usually
	be done by using ATTR_GEN_INIT_FILE_KEY and intercepting
	MSG_GEN_LOAD_OPTIONS.  Howerver, we can't store two init file keys
	in the same object, so we intercept MSG_META_LOAD_OPTIONS instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/29/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
screen0Cat		char	"screen 0", 0
horizPosKey		char	"horizPos", 0
vertPosKey		char	"vertPos", 0

PVTPIMetaLoadOptions	method dynamic PrefVidTvPosInteractionClass, 
					MSG_META_LOAD_OPTIONS

	;
	; Call superclass to let it broadcast to our children by default.
	;
	mov	di, offset PrefVidTvPosInteractionClass
	call	CallSuperNoLock

	;
	; Get max values for horiz and vert positions from video driver.
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].PrefVidTvPosInteraction_offset
	mov	di, VID_ESC_GET_HORIZ_POS_PARAMS
	call	CallVideoDr		; dx = max horiz pos
	mov	ds:[bx].PVTPII_horizPos.PS_max, dx
	mov	di, VID_ESC_GET_VERT_POS_PARAMS
	call	CallVideoDr		; dx = max vert pos
	mov	ds:[bx].PVTPII_vertPos.PS_max, dx

	;
	; Get current values for horiz and vert positions from .INI file.
	;
	segmov	es, ds			; es:bx = instance
	mov	cx, cs
	mov	dx, offset horizPosKey	; cx:dx = horizPosKey
	mov	ds, cx
	mov	si, offset screen0Cat	; ds:si = screen0Cat
	call	InitFileReadInteger	; ax = value, CF clear if found
	jc	afterHorizPos
	Assert	be, ax, es:[bx].PVTPII_horizPos.PS_max
	mov	es:[bx].PVTPII_horizPos.PS_orig, ax
	mov	es:[bx].PVTPII_horizPos.PS_cur, ax

afterHorizPos:
	mov	dx, offset vertPosKey	; cx:dx = vertPosKey
	call	InitFileReadInteger	; ax = value, CF clear if found
	jc	afterVertPos
	Assert	be, ax, es:[bx].PVTPII_vertPos.PS_max
	mov	es:[bx].PVTPII_vertPos.PS_orig, ax
	mov	es:[bx].PVTPII_vertPos.PS_cur, ax

afterVertPos:

	ret
PVTPIMetaLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTPIChangePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the horiz or vert TV position.

CALLED BY:	MSG_PVTPI_CHANGE_POS

PASS:		*ds:si	= PrefVidTvPosInteractionClass object
		ds:di	= PrefVidTvPosInteractionClass instance data
		cx	= VidEscCode to change position
		dx	= signed value to change by
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/29/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTPIChangePos	method dynamic PrefVidTvPosInteractionClass, 
					MSG_PVTPI_CHANGE_POS

	mov	bx, offset PVTPII_horizPos	; ds:[di][bx] = PVTPII_horizPos
	cmp	cx, VID_ESC_SET_HORIZ_POS
	je	changePos
	mov	bx, offset PVTPII_vertPos	; ds:[di][bx] = PVTPII_vertPos

changePos:
	;
	; Change current value by the amount specified.
	;
	mov	ax, ds:[di][bx].PS_cur
	add	ax, dx
	jns	notBelow
	clr	ax			; set value to min
notBelow:
	cmp	ax, ds:[di][bx].PS_max
	jbe	notAbove
	mov	ax, ds:[di][bx].PS_max
notAbove:
	mov	ds:[di][bx].PS_cur, ax

	;
	; Pass the new value to the video driver.
	;
	mov	di, cx			; cx = VidEscCode
	call	CallVideoDr

	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	CallInstance

	ret
PVTPIChangePos	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTPIGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the current position values as the original values.

CALLED BY:	MSG_GEN_APPLY

PASS:		*ds:si	= PrefVidTvPosInteractionClass object
		ds:di	= PrefVidTvPosInteractionClass instance data
		es 	= segment of PrefVidTvPosInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/01/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTPIGenApply	method dynamic PrefVidTvPosInteractionClass, 
					MSG_GEN_APPLY

	;
	; Store the current values as the original values, because they
	; have now been "applied".
	;
	mov	bx, ds:[di].PVTPII_horizPos.PS_cur
	mov	ds:[di].PVTPII_horizPos.PS_orig, bx
	mov	bx, ds:[di].PVTPII_vertPos.PS_cur
	mov	ds:[di].PVTPII_vertPos.PS_orig, bx

	mov	di, offset PrefVidTvPosInteractionClass
	call	CallSuperNoLock

	ret
PVTPIGenApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTPIMetaSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the horiz and vert pos values to the .INI file.

CALLED BY:	MSG_META_SAVE_OPTIONS

PASS:		*ds:si	= PrefVidTvPosInteractionClass object
		es 	= segment of PrefVidTvPosInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/29/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTPIMetaSaveOptions	method dynamic PrefVidTvPosInteractionClass, 
					MSG_META_SAVE_OPTIONS

	push	ds:[di].PVTPII_vertPos.PS_cur
	push	ds:[di].PVTPII_horizPos.PS_cur

	;
	; Call superclass to perform the default action of broadcasting
	; to our children.
	;
	mov	di, offset PrefVidTvPosInteractionClass
	call	CallSuperNoLock

	;
	; Save horiz and vert position values to .INI file.
	;
	mov	cx, cs
	mov	dx, offset horizPosKey	; cx:dx = horizPos
	mov	ds, cx
	mov	si, offset screen0Cat	; ds:si = screen0Cat
	pop	bp			; bp = horiz pos value
	call	InitFileWriteInteger
	mov	dx, offset vertPosKey
	pop	bp			; bp = vert pos value
	call	InitFileWriteInteger

	ret
PVTPIMetaSaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTPIGenReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the current position values to the original values.

CALLED BY:	MSG_GEN_RESET

PASS:		*ds:si	= PrefVidTvPosInteractionClass object
		ds:di	= PrefVidTvPosInteractionClass instance data
		es 	= segment of PrefVidTvPosInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/29/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTPIGenReset	method dynamic PrefVidTvPosInteractionClass, 
					MSG_GEN_RESET

	push	ds:[di].PVTPII_vertPos.PS_orig
	push	ds:[di].PVTPII_horizPos.PS_orig

	;
	; Call superclass to let it broadcast to our children by default.
	;
	mov	di, offset PrefVidTvPosInteractionClass
	call	CallSuperNoLock

	;
	; Pass the original values to the video driver.
	;
	mov	di, VID_ESC_SET_HORIZ_POS
	pop	ax			; ax = orig horiz value
	call	CallVideoDr

	mov	di, VID_ESC_SET_VERT_POS
	pop	ax			; ax = orig vert value
	call	CallVideoDr

	ret
PVTPIGenReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallVideoDr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the video driver strategy routine.

CALLED BY:	INTERNAL
PASS:		di	= VidFunction or VidEscCode to call
		other registers (except es) depending on function called
RETURN:		es preserved
		others depending on function called
DESTROYED:	depending on function called
SIDE EFFECTS:	videoDrStrategy contains strategy routine

PSEUDO CODE/STRATEGY:
	Currently, ES cannot be passed to video function.  We can muck with
	the stack to allow passing all registers, but we don't need it right
	now.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/06/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallVideoDr	proc	near
	uses	es
	.enter

	;
	; Get video driver strategy only once and store it, to avoid locking
	; down the driver core block again and again.
	;
	segmov	es, dgroup
	tst	es:[videoDrStrategy].segment
	jnz	hasStrategy

	pusha
	push	ds
	mov	ax, GDDT_VIDEO
	call	GeodeGetDefaultDriver	; ax = driver hptr
	mov_tr	bx, ax			; bx = driver hptr
	call	GeodeInfoDriver		; ds:si = DriverInfoStruct
	movdw	es:[videoDrStrategy], ds:[si].DIS_strategy, ax
	pop	ds
	popa

hasStrategy:
	call	es:[videoDrStrategy]

	.leave
	ret
CallVideoDr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTSIMetaLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the horiz and vert size values from the .INI file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= PrefVidTvSizeInteractionClass object
		es 	= segment of PrefVidTvSizeInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	In a Pref subclass, reading options from .INI file should usually
	be done by using ATTR_GEN_INIT_FILE_KEY and intercepting
	MSG_GEN_LOAD_OPTIONS.  Howerver, we can't store two init file keys
	in the same object, so we intercept MSG_META_LOAD_OPTIONS instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/06/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
uiCat			char	"ui", 0
tvBorderWidthKey	char	"tvBorderWidth", 0
tvBorderHeightKey	char	"tvBorderHeight", 0

PVTSIMetaLoadOptions	method dynamic PrefVidTvSizeInteractionClass, 
					MSG_META_LOAD_OPTIONS

	mov	di, offset PrefVidTvSizeInteractionClass
	call	CallSuperNoLock

	;
	; Get border width and height from .INI file
	;
	mov	cx, cs
	mov	dx, offset tvBorderWidthKey	; cx:dx = tvBorderWidthKey
	mov	ds, cx
	mov	si, offset uiCat	; ds:si = uiCat
	clr	ax			; default = 0
	call	InitFileReadInteger	; ax = value
	segmov	es, dgroup
	mov	es:[tvBorderOrigWidth], ax
	mov	es:[tvBorderCurWidth], ax
	mov	dx, offset tvBorderHeightKey	; cx:dx = tvBorderHeightKey
	clr	ax			; default = 0
	call	InitFileReadInteger	; ax = value
	mov	es:[tvBorderOrigHeight], ax
	mov	es:[tvBorderCurHeight], ax

	ret
PVTSIMetaLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTSIChangeSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the horiz or vert TV size.

CALLED BY:	MSG_PVTSI_CHANGE_HORIZ_SIZE, MSG_PVTSI_CHANGE_VERT_SIZE

PASS:		*ds:si	= PrefVidTvSizeInteractionClass object
		ax	= message #
		cx	= signed value to change by
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/04/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTSIChangeSize	method dynamic PrefVidTvSizeInteractionClass, 
					MSG_PVTSI_CHANGE_HORIZ_SIZE,
					MSG_PVTSI_CHANGE_VERT_SIZE

	push	si			; save self lptr

	;
	; Change border values.
	;
	segmov	es, dgroup
	mov	si, offset tvBorderCurWidth
	cmp	ax, MSG_PVTSI_CHANGE_HORIZ_SIZE
	je	change
	mov	si, offset tvBorderCurHeight
change:
	add	es:[si], cx
	jns	checkMax		; => not below zero
	clr	{word}es:[si]
checkMax:
	cmp	{word}es:[si], TV_BORDER_MAX_THICKNESS
	jbe	refresh
	mov	{word}es:[si], TV_BORDER_MAX_THICKNESS

refresh:
	;
	; Make ourselves applyable.
	;
	pop	si			; *ds:si = self
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	CallInstance

	;
	; Force border primary window to redraw.
	;
	mov	si, offset PrefVidTvSizeBorders	; *ds:si = primary
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	CallInstance		; ^hbp = GState
	mov	di, bp			; ^hdi = GState
	clr	ax, bx			; (ax,bx) = top left
	mov	cx, es:[scrWidth]
	mov	dx, es:[scrHeight]	; (cx,dx) = bottom right
	call	GrInvalRect
	GOTO	GrDestroyState

PVTSIChangeSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTSIMetaSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the horiz and vert size values to the .INI file.

CALLED BY:	MSG_META_SAVE_OPTIONS

PASS:		*ds:si	= PrefVidTvSizeInteractionClass object
		es 	= segment of PrefVidTvSizeInteractionClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/07/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTSIMetaSaveOptions	method dynamic PrefVidTvSizeInteractionClass, 
					MSG_META_SAVE_OPTIONS

	;
	; Call superclass to let it broadcast to our children by default.
	;
	mov	di, offset PrefVidTvSizeInteractionClass
	call	CallSuperNoLock

	;
	; Save border width and height to .INI file.
	;
	mov	cx, cs
	mov	dx, offset tvBorderWidthKey	; cx:dx = tvBorderWidthKey
	mov	ds, cx
	mov	si, offset uiCat	; ds:si = uiCat
	segmov	es, dgroup
	mov	bp, es:[tvBorderCurWidth]
	call	InitFileWriteInteger
	mov	dx, offset tvBorderHeightKey
	mov	bp, es:[tvBorderCurHeight]
	call	InitFileWriteInteger

	ret
PVTSIMetaSaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTSIPrefGetRebootInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether we or any of our children want to reboot.

CALLED BY:	MSG_PREF_GET_REBOOT_INFO

PASS:		*ds:si	= PrefVidTvSizeInteractionClass object
		ds:di	= PrefVidTvSizeInteractionClass instance data
		ax	= message #
RETURN:		If reboot needed:
			^lcx:dx	= OD of string to put up in ConfirmDialog
		else
			cx	= 0
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/06/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTSIPrefGetRebootInfo	method dynamic PrefVidTvSizeInteractionClass, 
					MSG_PREF_GET_REBOOT_INFO

	;
	; First check ourselves if we ourselves ever want to reboot.
	;
	test	ds:[di].PI_attrs, mask PA_REBOOT_IF_CHANGED
	jz	callSuper		; => no reboot for us

	;
	; We may want to reboot.  Do so if our state has changed.
	;
	segmov	es, dgroup
	mov	bx, es:[tvBorderCurWidth]
	cmp	bx, es:[tvBorderOrigWidth]
	jne	reboot			; => reboot
	mov	bx, es:[tvBorderCurHeight]
	cmp	bx, es:[tvBorderOrigHeight]
	je	callSuper		; => no reboot for us

reboot:
	;
	; Return reboot string to our caller.
	;
	mov	ax, MSG_PREF_GET_REBOOT_STRING
	call	CallInstance		; ^lcx:dx = reboot string (if any)

	ret

callSuper:
	;
	; Call superclass to pass the message to our children, to see if
	; any of them want to reboot.
	;
	segmov	es, <segment PrefVidTvSizeInteractionClass>
	mov	di, offset PrefVidTvSizeInteractionClass
	call	CallSuperNoLock

	ret
PVTSIPrefGetRebootInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTSBPVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the window to be transparent, to avoid flashing when
		it is invalidated.

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si	= PrefVidTvSizeBordersPrimaryClass object
		es 	= segment of PrefVidTvSizeBordersPrimaryClass
		ax	= message #
		bp	= 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/06/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTSBPVisOpen	method dynamic PrefVidTvSizeBordersPrimaryClass, 
					MSG_VIS_OPEN

	mov	di, offset PrefVidTvSizeBordersPrimaryClass
	call	CallSuperNoLock

	;
	; Store window size for redrawing.  It should be the same as screen
	; size anyway.
	;
	mov	ax, MSG_VIS_GET_SIZE
	call	CallInstance		; cx = width, dx = height
	segmov	es, dgroup
	mov	es:[scrWidth], cx
	mov	es:[scrHeight], dx

	;
	; Set the window to be transparent.
	;
	mov	ax, MSG_VIS_QUERY_WINDOW
	call	CallInstance		; ^hcx = Window
	mov	si, WIT_COLOR
	mov	ah, mask WCF_TRANSPARENT
	mov	di, cx			; ^hdi = Window
	call	WinSetInfo

	ret
PVTSBPVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVTSBPVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the TV sizing borders.

CALLED BY:	MSG_VIS_DRAW

PASS:		^hbp	- GState to draw through.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/30/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVTSBPVisDraw	method dynamic PrefVidTvSizeBordersPrimaryClass, 
					MSG_VIS_DRAW

	;
	; Don't call superclass, because we don't want the grey modal mask.
	;

	mov	di, bp			; ^hdi = GState

	segmov	ds, dgroup

	;
	; Draw red outer border.
	;
	mov	ax, CF_INDEX shl 8 or C_RED
	call	GrSetAreaColor
	clr	si, bp			; no margins
	mov	ax, ds:[tvBorderCurWidth]
	mov	bx, ds:[tvBorderCurHeight]
	call	DrawSizingBorder

	;
	; Draw inner green border.
	;
	mov_tr	si, ax			; si = margin width
	mov	bp, bx			; bp = margin height
	mov	ax, CF_INDEX shl 8 or C_GREEN
	call	GrSetAreaColor
	mov	ax, TV_SIZING_INNER_BORDER_THICKNESS
	mov	bx, ax
	call	DrawSizingBorder

	;
	; Draw black center rectangle.
	;
	add	si, ax			; si = left of rect
		CheckHack <CF_INDEX shl 8 or C_BLACK eq 0>
	clr	ax			; ah = CF_INDEX, al = C_BLACK
	call	GrSetAreaColor
	mov_tr	ax, si			; ax = left of rect
	add	bx, bp			; bx = top of rect
	mov	cx, ds:[scrWidth]
	sub	cx, ax			; cx = right of rect
	mov	dx, ds:[scrHeight]
	sub	dx, bx			; dx = bottom of rect
	GOTO	GrFillRect

PVTSBPVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSizingBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one sizing border in the shape of a hollow rectangle.

CALLED BY:	PVTSBVisDraw
PASS:		^hdi	= GState with area color already set
		ax	= border width
		bx	= border height
		si	= width of left/right margin outside border
		bp	= height of top/bottom margin outside border
		ds:[scrWidth]	= screen width
		ds:[scrHeight]	= screen height
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The sides of the border are drawn in this order:
		44444444444444444444444433
		44444444444444444444444433
		11			33
		11			33
		11			33
		11			33
		11222222222222222222222222
		11222222222222222222222222

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/04/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSizingBorder	proc	near
marginHeight	local	word	push	bp
borderWidth	local	word	push	ax
borderHeight	local	word	push	bx
	.enter
	pusha

	;
	; Draw left side.
	;
	mov	ax, si			; ax = left
	mov	bx, ss:[marginHeight]
	add	bx, ss:[borderHeight]	; (ax,bx) = top left
	mov	cx, si			; cx = margin width
	add	cx, ss:[borderWidth]	; cx = right
	mov	dx, ds:[scrHeight]
	sub	dx, ss:[marginHeight]	; (cx,dx) = bottom right
	call	GrFillRect

	;
	; Draw bottom side.
	; (cx,dx) = bottom left
	;
	mov	ax, ds:[scrWidth]
	sub	ax, si			; ax = right
	mov	bx, dx			; bx = scr height - margin height
	sub	bx, ss:[borderHeight]	; (ax,bx) = top right
	call	GrFillRect

	;
	; Draw right side.
	; (ax,bx) = bottom right
	;
	mov	cx, ax			; cx = scr width - margin width
	sub	cx, ss:[borderWidth]	; cx = left
	mov	dx, ss:[marginHeight]	; (cx,dx) = top left
	call	GrFillRect

	;
	; Draw top side.
	; (cx,dx) = top right
	;
	mov	ax, si			; ax = left
	mov	bx, dx			; bx = margin height
	add	bx, ss:[borderHeight]	; (ax,bx) = bottom left
	call	GrFillRect

	popa
	.leave
	ret
DrawSizingBorder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVBGetVidFunc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the video function for which this boolean sets.

CALLED BY:	MSG_PVB_GET_VID_FUNC

PASS:		ds:di	= PrefVidBooleanClass instance data
RETURN:		ax	= VidEscCode or VidFunction of video function
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/09/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVBGetVidFunc	method dynamic PrefVidBooleanClass, 
					MSG_PVB_GET_VID_FUNC

	mov	ax, ds:[di].PVBI_setVidFunc

	ret
PVBGetVidFunc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVBGBooleanChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify video driver function of the new boolean value set
		by user.

CALLED BY:	MSG_PVBG_BOOLEAN_CHANGED

PASS:		*ds:si	= PrefVidBooleanGroupClass object
		cx	= Booleans currently selected, or "True"
		bp	= Booleans whose state has just changed
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/09/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVBGBooleanChanged	method dynamic PrefVidBooleanGroupClass, 
					MSG_PVBG_BOOLEAN_CHANGED

	mov	ax, 1			; first identifier

bitLoop:
	test	ax, bp
	jz	next			; => boolean not changed

	pusha

	; See if changed boolean is TRUE or FLASE
	andnf	cx, ax			; cx = non-zero if boolean is TRUE
	push	cx			; save boolean value

	; Get video function associated with the changed boolean
	mov_tr	cx, ax			; cx = identifier
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR
	call	CallInstance		; ^lcx:dx = optr, CF if found
	Assert	carrySet
	movdw	bxsi, cxdx
	mov	ax, MSG_PVB_GET_VID_FUNC
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = VidFunction

	; Pass boolean value to Video Driver
	mov_tr	di, ax			; di = VidFunction
	pop	ax			; ax = boolean value
	call	CallVideoDr

	popa

next:
	shl	ax			; next identifier
	jnc	bitLoop

	ret
PVBGBooleanChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVBGGenReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to the original setting.  Also forces the status
		message to be sent out if the booleans have been modified (we
		need to do so to tell video driver to revert its settings to
		the original values), because superclass doesn't send the
		status message on MSG_GEN_RESET.

CALLED BY:	MSG_GEN_RESET

PASS:		*ds:si	= PrefVidBooleanGroupClass object
		es 	= segment of PrefVidBooleanGroupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/09/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVBGGenReset	method dynamic PrefVidBooleanGroupClass, 
					MSG_GEN_RESET

	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS
	call	CallInstance		; ax = bits of modified booleans
	push	ax			; save modified booleans

	mov	ax, MSG_GEN_RESET
	mov	di, offset PrefVidBooleanGroupClass
	call	CallSuperNoLock

	pop	cx			; cx = modified booleans
	jcxz	done			; => nothing modified

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
	call	CallInstance

done:
	ret
PVBGGenReset	endm

endif	; GPC_VERSION

SetUsable	proc	near
	mov	ax, MSG_GEN_SET_USABLE
	GOTO	CallInstanceDelayedViaAppQueue
SetUsable	endp

SetNotUsable	proc	near
	mov	ax, MSG_GEN_SET_NOT_USABLE
	FALL_THRU CallInstanceDelayedViaAppQueue
SetNotUsable	endp

CallInstanceDelayedViaAppQueue	proc	near
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	FALL_THRU CallInstance
CallInstanceDelayedViaAppQueue	endp

CallInstance	proc	near
	call	ObjCallInstanceNoLock
	ret
CallInstance	endp

CallSuperNoLock	proc	near
	call	ObjCallSuperNoLock
	ret
CallSuperNoLock	endp
