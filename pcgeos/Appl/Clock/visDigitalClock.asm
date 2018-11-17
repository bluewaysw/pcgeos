COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		visDigitalClock.asm

AUTHOR:		Adam de Boor, Feb  2, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 2/92		Initial revision


DESCRIPTION:
	Implementation of a digital clock, based on Gene's earlier non-object-
	oriented code.
		

	$Id: visDigitalClock.asm,v 1.1 97/04/04 14:51:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	clock.def

idata	segment
	VisDigitalClockClass
idata	ends

DigitalCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle attaching and the subsequent change in display
		format that could be engendered by the setting of our
		interval by our superclass.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= VisDigitalClock object
		ds:di	= VisDigitalClockInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VDCAttach	method dynamic VisDigitalClockClass, MSG_META_ATTACH
		.enter
	;
	; Let our superclass do all the hard work.
	; 
		mov	di, offset VisDigitalClockClass
		CallSuper	MSG_META_ATTACH
	;
	; While we just adjust our display format once that's complete.
	; 
		mov	dl, VUM_MANUAL
		call	VDCAdjustFormat
		.leave
		ret
VDCAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current time into the clock window

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= VisDigitalClock object
		bp	= gstate
		cl	= DrawFlags
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VDCDraw		method dynamic VisDigitalClockClass, MSG_VIS_DRAW
		.enter
	;
	; Wipe out the clock background.
	; 
		mov	ax, ({dword}ds:[di].VDCI_colors[VDCC_BACKGROUND*ColorQuad]).low
		mov	bx, ({dword}ds:[di].VDCI_colors[VDCC_BACKGROUND*ColorQuad]).high
						;al <- color, ah <- index flag
		mov	di, bp
		call	GrSetAreaColor
	;
	; Set the color-map mode for everything to dither, keeping CMM_ON_BLACK
	; clear so we don't effectively invert everything...
	; 
		mov	al, ColorMapMode <0, CMT_DITHER>
		call	GrSetAreaColorMap
		call	GrSetLineColorMap
		call	GrSetTextColorMap

		test	cl, mask DF_PRINT
		jnz	skipRect
		call	VisGetSize
		clr	ax
		mov	bx, ax
		call	GrFillRect
skipRect:
	;
	; Format the current time.
	; 
		call	TimerGetDateAndTime
		call	VDCFormat

	;
	; Center the result in the window. (cx will hold the left offset)
	; 
		push	dx		; save the width of the time text
		call	VisGetSize	; cx <- window width
		pop	ax

		sub	cx, ax		; figure gutter*2
		sar	cx		; cut difference in 2 to center...
	;
	; Draw the thing from the accent line, since we don't have anything
	; with accents and the text is too high otherwise.
	; 
		mov	ax, mask TM_DRAW_ACCENT
		call	GrSetTextMode

		lea	si, ds:[bx].VDCI_buffer
		mov	bx, DIGITAL_MARGIN_Y		; y <- margin
		mov_tr	ax, cx		; ax <- left offset
		clr	cx		; null-terminated text
		call	GrDrawText
		
		mov	ax, mask TM_DRAW_ACCENT shl 8
		call	GrSetTextMode
		.leave
		ret
VDCDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the passed time & date into the buffer in the object,
		returning its width and the gstate set up properly for
		drawing.

CALLED BY:	VDCDraw, VDCGetRegionParams
PASS:		*ds:si	= object
		ax	= year
		bl	= month (1-12)
		bh	= day (1-31)
		cl	= weekday (0-6)
		ch	= hours (0-23)
		dl	= minutes (0-59)
		dh	= seconds (0-59)
		bp	= gstate
RETURN:		VDCI_buffer containing formatted date/time
		dx	= width of string
		cx	= length of string
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VDCFormat	proc	near
		class	VisDigitalClockClass
		uses	bp
		.enter
	;
	; Deref the object so we can get the format & the buffer.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].VisDigitalClock_offset

		push	si, bp, di
		mov	si, ds:[di].VDCI_display	; si <- format
		lea	di, ds:[di].VDCI_buffer
		segmov	es, ds				; es:di <- buffer
		call	LocalFormatDateTime
		pop	si, di, bx	; *ds:si <- object, di <- gstate
					;  ds:bx <- VisDigitalClockInstance
	;
	; Set the gstate appropriately.
	; 
		push	cx			; save string length
		push	bx
		mov	ax, ({dword}ds:[bx].VDCI_colors[VDCC_TEXT*ColorQuad]).low
		mov	bx, ({dword}ds:[bx].VDCI_colors[VDCC_TEXT*ColorQuad]).high
		call	GrSetTextColor
		pop	bx

		mov	ax, mask TS_BOLD	; set bold, reset nothing
		call	GrSetTextStyle

		mov	cx, DIGITAL_FONT_ID	; cx <- font
		mov	dx, ds:[bx].VDCI_size
		clr	ah			; dx.ah <- pointsize
		call	GrSetFont
		pop	cx
	;
	; Center the text inside the window.
	; 
		push	si
		lea	si, ds:[bx].VDCI_buffer
		call	GrTextWidth		; dx <- width (points)
		pop	si
		.leave
		ret
VDCFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure how big we ought to be, given our current display
		format.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= object
RETURN:		cx	= desired width
		dx	= desired height.
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VDCRecalcSize	method dynamic VisDigitalClockClass, MSG_VIS_RECALC_SIZE
		.enter
		clr	di
		call	GrCreateState
		mov	bp, di				;bp <- gstate
		mov	ax, 9999			;ax <- year
		mov	bx, 12 or (31 shl 8)		;bx <- month / day
		mov	cx, 6 or (23 shl 8)		;cx <- DOW / hours
		mov	dx, 59 or (59 shl 8)		;dx <- minutes / seconds
		
		call	VDCFormat
		
		mov	di, ds:[si]
		add	di, ds:[di].VisDigitalClock_offset
		mov	ds:[di].VDCI_width, dx

		push	dx, di
		mov	di, bp
		mov	si, GFMI_ACCENT or GFMI_ROUNDED
		call	GrFontMetrics
		mov	cx, dx
		mov	si, GFMI_HEIGHT or GFMI_ROUNDED
		call	GrFontMetrics
		sub	dx, cx			; reduce height by accent
						;  height, since we draw
						;  nothing with accents
		pop	cx, di
		
		mov	ds:[di].VDCI_height, dx
		
		add	cx, DIGITAL_MARGIN_X*2
		add	dx, DIGITAL_MARGIN_Y*2

		mov	di, bp
		call	GrDestroyState
		
		.leave
		ret
VDCRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCSetInterval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the interval between clock updates.

CALLED BY:	MSG_VC_SET_INTERVAL
PASS:		*ds:si	= VisDigitalClock object
		ds:di	= VisDigitalClockInstance
		cx	= seconds between VC_CLOCK_TICK messages
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VDCSetInterval	method dynamic VisDigitalClockClass, MSG_VC_SET_INTERVAL
		.enter
		mov	di, offset VisDigitalClockClass
		CallSuper	MSG_VC_SET_INTERVAL
		
		mov	dl, VUM_NOW
		call	VDCAdjustFormat

		.leave
		ret
VDCSetInterval	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the base format used to display the time.

CALLED BY:	MSG_VDC_SET_FORMAT
PASS:		*ds:si	= VisDigitalClock object
		ds:di	= VisDigitalClockInstance
		cx	= DateTimeFormat (HM version, not HMS)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VDCSetFormat	method dynamic VisDigitalClockClass, MSG_VDC_SET_FORMAT
		.enter
		mov	ds:[di].VDCI_format, cx
		call	ObjMarkDirty
		mov	dl, VUM_NOW
		call	VDCAdjustFormat
		.leave
		ret
VDCSetFormat	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCAdjustFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the display format and our geometry based on the
		new interval/base format

CALLED BY:	VDCSetInterval, VDCSetFormat
PASS:		*ds:si	= VisDigitalClock object
		dl	= VisualUpdateMode to use when marking geometry invalid
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.assert (DTF_HM eq DTF_HMS+1)
.assert (DTF_HM_24HOUR eq DTF_HMS_24HOUR+1)

VDCAdjustFormat	proc	near
		class	VisDigitalClockClass
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].VisDigitalClock_offset
		mov	ax, ds:[di].VDCI_format
		cmp	ds:[di].VCI_interval, 60	; showing seconds?
		jne	setFormat
		dec	ax				; yes -- shift display
							;  format back to one
							;  that shows seconds
setFormat:
		xchg	ds:[di].VDCI_display, ax
		cmp	ax, ds:[di].VDCI_display
		je	done
	;
	; Since our display format changed, mark our geometry invalid so we
	; recalculate everything.
	; 
		mov	cx, mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_NOW
		call	VisClockMarkInvalid

done:
		.leave
		ret
VDCAdjustFormat	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VDCSetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the pointsize used to display the time.

CALLED BY:	MSG_VDC_SET_SIZE
PASS:		*ds:si	= VisDigitalClock object
		ds:di	= VisDigitalClockInstance
		dx.cx	= pointsize
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VDCSetSize	method dynamic VisDigitalClockClass, MSG_VDC_SET_SIZE
		.enter
	;
	; Throw away the fraction and set the pointsize we should use.
	; 
		mov	ds:[di].VDCI_size, dx
	;
	; Mark our geometry invalid so we resize the window accordingly.
	; 
		mov	cx, mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_NOW
		call	VisClockMarkInvalid
		.leave
		ret
VDCSetSize	endm


DigitalCode	ends
