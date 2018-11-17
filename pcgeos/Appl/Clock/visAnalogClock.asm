COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		visAnalogClock.asm

AUTHOR:		Adam de Boor, Feb  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 9/92		Initial revision


DESCRIPTION:
	Implementation of the VisAnalogClock class.
		

	$Id: visAnalogClock.asm,v 1.1 97/04/04 14:50:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	clock.def

include	Internal/videoDr.def

idata	segment
	VisAnalogClockClass
idata	ends

AnalogClockCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of when we're attached so we can figure the
		aspect ratio of the display.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= VisAnalogClock object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACAttach	method dynamic VisAnalogClockClass, MSG_META_ATTACH
		.enter
	;
	; Let superclass actually attach us to the field.
	; 
		mov	di, offset VisAnalogClockClass
		CallSuper	MSG_META_ATTACH
	;
	; Now find the field window.
	; 
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_FIELD
		call	GenCallApplication	; bp <- field window
		mov	di, bp
	;
	; Get the strategy routine of its driver.
	; 
		push	si			; save ourselves
		mov	si, WIT_STRATEGY
		call	WinGetInfo

		push	cx, dx
		mov	bp, sp
		mov	di, DR_VID_INFO
		call	{fptr.far}ss:[bp]
		lea	sp, ss:[bp+4]
		mov	di, si
		mov	es, dx
		
		clr	cx
		mov	dx, es:[di].VDI_vRes	; dx.cx = vertical res
		clr	ax
		mov	bx, es:[di].VDI_hRes	; bx.ax = horizontal res
		cmp	bx, dx			; see if equal
		je	noAdjust
		call	GrUDivWWFixed		; dx.cx <- aspect ratio
saveAspect:
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].VisAnalogClock_offset
		mov	ds:[di].VACI_aspectRatio.WWF_int, dx
		mov	ds:[di].VACI_aspectRatio.WWF_frac, cx
		.leave
		ret
noAdjust:
		mov	dx, 1
		clr	cx
		jmp	saveAspect
VACAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACDrawGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a gstring associated with an analog clock.

CALLED BY:	INTERNAL
PASS:		*ds:si	= VisAnalogClock object
		di	= gstate to use for the drawing
		ds:bx	= BoundedGString to draw
		cx	= 0 to ignore color escapes.
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACDrawGString	proc	far
		class	VisAnalogClockClass
		uses	bp, ax, cx, dx, si, bx
		.enter
	;
	; Now draw the gstring, dealing with color escapes properly.
	; 
		push	si		; save object chunk

		mov	si, ds:[si]
		add	si, ds:[si].VisAnalogClock_offset
		add	si, offset VACI_colors
		push	si		; save color table
		
		mov	bp, cx		; bp <- ignore-escapes flag

		lea	si, ds:[bx].BGS_gstring
		mov	bx, ds
		mov	cl, GST_PTR
		call	GrLoadGString	; si <- gstring handle
		call	GrSaveState
		clr	ax
		clr	bx
		mov	dx, mask GSC_ESCAPE
		call	GrDrawGString
drawLoop:
		cmp	dx, GSRT_ESCAPE		; stopped on escape?
		jne	done			; no -- some other error
		
		cmp	cx, GR_CLOCK_COLOR_ESCAPE	; our escape?
		jne	skipEscape		; no -- ignore it
		tst	bp			; pay attention to it?
		jz	skipEscape	; => ignore color escapes

	;
	; Fetch the escape data
	; 
GET_COLOR_ESCAPE_SIZE	equ ((size OpEscape + byte) + 1) and not 1
		sub	sp, GET_COLOR_ESCAPE_SIZE	; make room for elt
							;  on the stack
		mov	bx, sp
		push	ds
		segmov	ds, ss			; ds:bx <- buffer
		mov	cx, GET_COLOR_ESCAPE_SIZE	; cx <- buffer size
		call	GrGetGStringElement
		mov	al, ds:[bx+size OpEscape]
		pop	ds
		add	sp, GET_COLOR_ESCAPE_SIZE
		cmp	cx, GET_COLOR_ESCAPE_SIZE; element too large?
		ja	skipEscape		; yes => malformed, so skip

	;
	; Fetch the color for the index.
	; 
			CheckHack <size ColorQuad eq 4>
		clr	ah			; zero extend index
		shl	ax
		shl	ax
		pop	bx			; ds:bx <- color table
		push	bx
		add	bx, ax			; ds:bx <- color quad
		mov	ax, ({dword}ds:[bx]).low
		mov	bx, ({dword}ds:[bx]).high
	;
	; Set all colors with that value.
	; 
		call	GrSetAreaColor
		call	GrSetLineColor
		call	GrSetTextColor
skipEscape:
		mov	dx, mask GSC_ESCAPE
		clr	ax, bx
		call	GrDrawGString
		jmp	drawLoop
done:
		mov	dl, GSKT_LEAVE_DATA
		push	di
		clr	di		; no gstate to nuke
		call	GrDestroyGString
		pop	di

		call	GrRestoreState
		inc	sp		; discard color table
		inc	sp
		pop	si
		.leave
		ret
VACDrawGString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return how big we'd like to be. For now, this is just
		the size of the pattern gstring

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= object
RETURN:		cx	= desired width
		dx	= desired height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACRecalcSize 	method dynamic VisAnalogClockClass, MSG_VIS_RECALC_SIZE
		.enter
		
		mov	cx, ds:[di].VACI_diameter
		mov	dx, cx
		mov	bx, ds:[di].VACI_aspectRatio.WWF_int
		mov	ax, ds:[di].VACI_aspectRatio.WWF_frac

		cmp	bx, 1
		jne	adjustHeight
		tst	ax
		je	done
adjustHeight:
		push	cx		; save width
		clr	cx		; dx.cx <- multiplier
		call	GrMulWWFixed
		add	cx, 0x8000
		adc	dx, 0		; round up
		pop	cx		; recover width
done:
		.leave
		ret
VACRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACDivideIfNotEqual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Optimization for determining the scale for drawing.

CALLED BY:	VACCalcPatternRegion
PASS:		dx	= dividend
		ax	= divisor-1
RETURN:		dx.cx	= scale factor
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACDivideIfNotEqual proc	near
		.enter
		inc	ax
		mov	bx, ax
		clr	ax
		clr	cx		; dx.cx <- actual width (dividend)
					; bx.ax <- pattern width (divisor)
		cmp	dx, bx
		jne	divide
		mov	dx, 1		; scale is 1.0 if they're the same...
done:
		.leave
		ret
divide:
		call	GrSDivWWFixed
		jmp	done
VACDivideIfNotEqual endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACApplyScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply scale, dealing with our need to have things backwards

CALLED BY:	VACCalcPatternRegion, VACDraw
PASS:		ds:bp	= VisAnalogClockInstance
		di	= gstate to which to apply the scale
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACApplyScale	proc	near
		class	VisAnalogClockClass
		.enter
	;
	; bx.ax <- Y scale
	; 
		mov	bx, ds:[bp].VACI_yScale.WWF_int
		mov	ax, ds:[bp].VACI_yScale.WWF_frac
	;
	; dx.cx <- X scale
	; 
		mov	dx, ds:[bp].VACI_xScale.WWF_int
		mov	cx, ds:[bp].VACI_xScale.WWF_frac
	;
	; Apply scale only if one of them isn't 1.0
	; 
		cmp	dx, 1
		jne	doScale
		tst	cx
		jnz	doScale
		cmp	bx, 1
		jne	doScale
		tst	ax
		jz	done	; => both X and Y scales are 1.0
doScale:
		call	GrApplyScale
done:
		.leave
		ret
VACApplyScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACCalcPatternRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a new region for the object based on the current
		bounds and the pattern gstring.

CALLED BY:	MSG_VIS_OPEN_WIN, MSG_VIS_MOVE_RESIZE_WIN
PASS:		*ds:si	= VisAnalogClock object
		cx, dx, bp = ? (preserved)
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACCalcPatternRegion method dynamic VisAnalogClockClass, MSG_VIS_OPEN_WIN,
		     		MSG_VIS_MOVE_RESIZE_WIN
		uses	ax, cx, dx, bp
		.enter
	;
	; Free the current region.
	; 
		mov	ax, ds:[di].VCI_region
		tst	ax
		jz	oldRegionFreed
		call	LMemFree
oldRegionFreed:
	;
	; Start the definition of a new one.
	; 
		call	VisGetSize
		call	CRCreate
		push	bx		; save token for destruction
	;
	; Set default attributes for the gstate, most notably to map
	; colors to solid.
	; 
		mov	ax, ColorMapMode <
			1,			; CMM_ON_BLACK: yup
			CMT_CLOSEST		; CMM_MAP_TYPE
		>
		call	GrSetAreaColorMap
		call	GrSetLineColorMap
		call	GrSetTextColorMap
		
		mov	bx, ds:[si]
		add	bx, ds:[bx].VisAnalogClock_offset
		mov	bp, bx

		mov	bx, ds:[bx].VACI_pattern
EC <		tst	bx						>
EC <		ERROR_Z	ANALOG_CLOCK_PATTERN_MUST_BE_SUPPLIED		>
		mov	bx, ds:[bx]
	;
	; Set the scale to map from the bounds of the pattern to the bounds
	; of the object.
	; 
		push	dx		; save height
		mov	dx, cx
		push	bx
		mov	ax, ds:[bx].BGS_bounds.R_right
		sub	ax, ds:[bx].BGS_bounds.R_left
		call	VACDivideIfNotEqual
		mov	ds:[bp].VACI_xScale.WWF_int, dx
		mov	ds:[bp].VACI_xScale.WWF_frac, cx

		pop	bx
		pop	dx		; dx <- height
		push	bx
		
		mov	ax, ds:[bx].BGS_bounds.R_bottom
		sub	ax, ds:[bx].BGS_bounds.R_top
		call	VACDivideIfNotEqual
		mov	ds:[bp].VACI_yScale.WWF_int, dx
		mov	ds:[bp].VACI_yScale.WWF_frac, cx

		call	VACApplyScale
		
	;
	; If (left, top) aren't 0,0, translate the origin so (left,top) maps
	; to (0,0) in the region.
	; 
		pop	bx		; ds:bx <- BoundedGString

		mov	cx, ds:[bx].BGS_bounds.R_left
		mov	dx, ds:[bx].BGS_bounds.R_top
		mov	ax, cx
		or	ax, dx
		jz	translationPerformed
		
		push	bx
		mov	bx, dx
		mov	dx, cx
		clr	ax
		clr	cx
		neg	dx
		neg	bx
		call	GrApplyTranslation
		pop	bx
translationPerformed:
	;
	; Make this the default transformation.
	; 
		call	GrInitDefaultTransform
	;
	; Make sure the pattern color isn't black, as that won't give us
	; a particularly enlightening region.
	; 
			CheckHack <CF_INDEX eq 0>
		mov	ax, C_WHITE
		call	GrSetAreaColor
		call	GrSetLineColor
		call	GrSetTextColor
	;
	; Now draw the thing into the region
	; 
		clr	cx		; => ignore color escapes
		call	VACDrawGString
	;
	; Convert the result into a region.
	; 
		mov	ax, mask CRCM_PARAMETERIZE
		call	CRConvert
	;
	; Destroy the ClockRegion stuff.
	; 
		pop	bx		; bx <- token for CRDestroy
		push	ax		; save region chunk
		call	CRDestroy
		pop	ax
		mov	di, ds:[si]
		add	di, ds:[di].VisAnalogClock_offset
		mov	ds:[di].VCI_region, ax
		.leave
	;
	; Call the superclass, now the region has been established.
	; 
		mov	di, offset VisAnalogClockClass
		GOTO	ObjCallSuperNoLock
VACCalcPatternRegion endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the clock using the pattern and the appropriate hands

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= VisAnalogClock object
		cl	= DrawFlags
		bp	= gstate to use
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACDraw		method dynamic VisAnalogClockClass, MSG_VIS_DRAW
		.enter
	;
	; Apply the calculated scale factor and make that the default matrix
	; for the gstate for VACDrawHand to come back to.
	; XXX: what about translation?
	; 
		xchg	di, bp
		push	cx
		call	VACApplyScale
		call	GrInitDefaultTransform
		pop	cx
		mov	al, CMT_DITHER
		call	GrSetLineColorMap
		call	GrSetAreaColorMap
		call	GrSetTextColorMap
	;
	; Draw the pattern as the background of the clock.
	; 
		test	cl, mask DF_EXPOSED
		jz	eraseHands

		mov	bx, ds:[bp].VACI_pattern
		mov	bx, ds:[bx]
		mov	cx, TRUE	; use regular colors
		call	VACDrawGString
		mov	ax, -1
		mov	ds:[bp].VACI_lastSecondAngle, ax
		mov	ds:[bp].VACI_lastMinuteAngle, ax
		mov	ds:[bp].VACI_lastHourAngle, ax
		jmp	allClear

eraseHands:
		mov	cx, ds:[bp].VACI_lastSecondAngle
		tst	cx
		js	eraseMinuteHand
		clr	dx
		mov	bx, offset VACI_secondHand
		call	VACDrawHand
eraseMinuteHand:
		mov	cx, ds:[bp].VACI_lastMinuteAngle
		tst	cx
		js	eraseHourHand
		clr	dx
		mov	bx, offset VACI_minuteHand
		call	VACDrawHand
eraseHourHand:
		mov	cx, ds:[bp].VACI_lastHourAngle
		tst	cx
		js	allClear
		clr	dx
		mov	bx, offset VACI_hourHand
		call	VACDrawHand
allClear:
		

	;
	; Now get the time of day.
	; 
		call	TimerGetDateAndTime
	;
	; Convert minutes to degrees by multiplying by 6
	; 
		push	dx		; save seconds in case 1-second interval

		clr	dh
		mov	ax, dx		; save minutes for additional
					;  hour-hand rotation
		shl	dx		; *2
		mov	bx, dx
		shl	dx		; *4
		add	dx, bx		; dx <- dl*6

		cmp	ch, 12		; afternoon?
		jb	convertHours
		sub	ch, 12		; convert to 0-11
convertHours:
	;
	; Convert hours to degrees by multiplying by 30 = 16 + 8 + 4 + 2
	; 
		shr	ax		; divide minutes by 2 to get additional
					;  degrees of rotation (30 degrees in
					;  an hour...)
		mov	cl, ch
		clr	ch
		shl	cx		; *2
		add	ax, cx
		shl	cx		; *4
		add	ax, cx
		shl	cx		; *8
		add	ax, cx
		shl	cx		; *16
		add	cx, ax		; cx <- cl*30

		mov	ds:[bp].VACI_lastHourAngle, cx
		mov	ds:[bp].VACI_lastMinuteAngle, dx
	;
	; Draw the minute first, since it's usually lower on analog clocks.
	; 
		xchg	cx, dx		; cx <- minute rotation, dx <- hour
		push	dx
		mov	dx, TRUE	; draw hand, please
		mov	bx, offset VACI_minuteHand
		call	VACDrawHand
	;
	; Draw the hour hand next so it shows up when the two overlap...
	; 
		pop	cx		; cx <- rotation
		mov	dx, TRUE	; draw hand, please
		mov	bx, offset VACI_hourHand
		call	VACDrawHand
	;
	; See if a second hand is required.
	; 
		pop	cx		; recover seconds in CH

		mov	bx, ds:[si]
		add	bx, ds:[bx].VisClock_offset
		cmp	ds:[bx].VCI_interval, 60	; second hand required?
		jne	done
	;
	; Second hand needed, so convert seconds to degrees and draw the hand.
	; 
		mov	cl, ch
		clr	ch
		shl	cx
		mov	ax, cx
		shl	cx
		add	cx, ax
		mov	ds:[bx].VACI_lastSecondAngle, cx
		mov	bx, offset VACI_secondHand
		mov	dx, TRUE
		call	VACDrawHand
done:
		.leave
		ret
VACDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACDrawHand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a clock hand, using a bounded gstring 

CALLED BY:	VACDraw	
PASS:		*ds:si	= VisAnalogClock object
		bx	= offset in VisAnalogClockInstance pointing to the
			  gstring to draw.
		cx	= degrees of rotation clockwise from 12 o'clock
		dx	= non-zero to draw the hand, 0 to erase it
		di	= gstate to use for drawing
RETURN:		nothing
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACDrawHand	proc	near
		class	VisAnalogClockClass
		.enter
	;
	; Translate to the center of the clock first.
	; 
		push	dx, bx, cx
		mov	bx, ds:[si]
		add	bx, ds:[bx].VisAnalogClock_offset
		mov	bx, ds:[bx].VACI_pattern
		mov	bx, ds:[bx]
		mov	dx, ds:[bx].R_right
		sub	dx, ds:[bx].R_left
		inc	dx
		shr	dx
		mov	ax, ds:[bx].R_bottom
		sub	ax, ds:[bx].R_top
		inc	ax
		shr	ax
		mov	bx, ax
		clr	ax
		clr	cx
		call	GrApplyTranslation
		
	;
	; Convert the degrees to be counterclockwise from 12 o'clock and apply
	; the rotation
	; 
		pop	cx
		mov	dx, 360
		sub	dx, cx
		clr	cx
		call	GrApplyRotation
	;
	; Now get the gstring itself and draw it the standard way.
	; 
		mov	bx, ds:[si]
		add	bx, ds:[bx].VisAnalogClock_offset
		mov	dx, bx		; save for possible erasure
		pop	ax		; ax <- offset in instance data...
		add	bx, ax
		mov	bx, ds:[bx]	; *ds:bx <- BoundedGString
		mov	bx, ds:[bx]	; ds:bx <- BoundedGString
		pop	cx
		jcxz	setToBackgroundColor
drawHand:
		call	VACDrawGString
	;
	; Reset the gstate to the transformation it had before.
	; 
		call	GrSetDefaultTransform
		.leave
		ret

setToBackgroundColor:
		xchg	bx, dx
		mov	ax,
			({dword}ds:[bx].VACI_colors[VACC_BACKGROUND*ColorQuad]).low
		mov	bx,
			({dword}ds:[bx].VACI_colors[VACC_BACKGROUND*ColorQuad]).high
		call	GrSetAreaColor
		call	GrSetLineColor
		call	GrSetTextColor
		mov	bx, dx
		jmp	drawHand
VACDrawHand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACSetInterval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note a change in the rate at which we're called

CALLED BY:	MSG_VC_SET_INTERVAL
PASS:		*ds:si	= VisAnalogClock object
		ds:di	= VisAnalogClockInstance
		cx	= new interval (in ticks)
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		let the superclass do its thing, but invalidate our image,
		as we need to get the nose-as-second-hand going or stopped
		right away.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACSetInterval	method dynamic VisAnalogClockClass, MSG_VC_SET_INTERVAL
		.enter
		mov	di, offset VisAnalogClockClass
		CallSuper	MSG_VC_SET_INTERVAL
		
		mov	cx, mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		call	VisClockMarkInvalid
		.leave
		ret
VACSetInterval	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VACSetDiameter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the diameter of the clock displayed.

CALLED BY:	MSG_VAC_SET_CLOCK_DIAMETER
PASS:		*ds:si	= VisAnalogClock object
		ds:di	= VisAnalogClockInstance
		dx.cx	= diameter of the clock in points
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VACSetDiameter	method dynamic VisAnalogClockClass, MSG_VAC_SET_CLOCK_DIAMETER
		.enter
	;
	; Save it away for later.
	; 
		mov	ds:[di].VACI_diameter, dx
		call	ObjMarkDirty
	;
	; Mark our geometry invalid so it'll get recalculated.
	; 
		mov	cx, mask VOF_GEOMETRY_INVALID
		call	VisClockMarkInvalid
		.leave
		ret
VACSetDiameter	endm

AnalogClockCode	ends

