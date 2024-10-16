COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		visSkeletonClock.asm

AUTHOR:		Adam de Boor, Mar  7, 1992

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/ 7/92		Initial revision


DESCRIPTION:
	Implementation of a skeleton digital clock.


	$Id: visSkeletonClock.asm,v 1.1 97/04/04 14:50:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	clock.def

include	Internal/window.def
include Internal/grWinInt.def
include Objects/winC.def

idata	segment
	VisSkeletonClockClass

idata	ends

DigitalCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VSCCalcWindowRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the clock's region to match the current time.

CALLED BY:	MSG_VIS_OPEN_WIN, MSG_VIS_MOVE_RESIZE_WIN
PASS:		*ds:si	= VisSkeletonClock object
		cx, dx, bp = ? (preserved)
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VSCCalcWindowRegion method dynamic VisSkeletonClockClass,
		    		MSG_VIS_MOVE_RESIZE_WIN,
				MSG_VIS_OPEN_WIN
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
	; Make sure the text always shows up, even if C_BLACK is chosen,
	; by forcing the text color to be C_WHITE for the duration.
	;
		push	{word}ds:[di].VDCI_colors[VDCC_TEXT*ColorQuad]
		CheckHack <CF_INDEX eq 0 and CQ_info eq 1 and \
				CQ_redOrIndex eq 0>
		mov	({dword}ds:[di].VDCI_colors[VDCC_TEXT*ColorQuad]).low,
				C_WHITE
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
	;
	; Call our superclass to draw itself with the gstate we've got.
	;
		mov	bp, di			; bp <- gstate
		mov	ax, MSG_VIS_DRAW
		mov	di, offset VisSkeletonClockClass
		push	bp
		mov	cl, mask DF_PRINT
		call	ObjCallSuperNoLock
		pop	di
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
		add	di, ds:[di].VisClock_offset
		mov	ds:[di].VCI_region, ax
	;
	; Restore text color.
	;
		pop	{word}ds:[di].VDCI_colors[VDCC_TEXT*ColorQuad]
		.leave
	;
	; Call the superclass, now the region has been established.
	;
		mov	di, offset VisSkeletonClockClass
		GOTO	ObjCallSuperNoLock
VSCCalcWindowRegion endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VSCGetWindowColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the color for the window that's about to be opened.

CALLED BY:	MSG_VC_GET_WINDOW_COLOR
PASS:		*ds:si	= VisClock object
		ds:di	= VisSkeletonClockInstance
RETURN:		ah	= WinColorFlags
		al	= color index or red value, if using RGB
		dl	= green value, if using RGB
		dh	= blue value, if using RGB
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VSCGetWindowColor method dynamic VisSkeletonClockClass,
				MSG_VC_GET_WINDOW_COLOR
		.enter
		mov	ah, WinColorFlags <
			0,		; WCF_RGB: using color index
			0,		; WCF_TRANSPARENT: window has background color
			1,		; WCF_PLAIN: window doesn't require exposes
			0,		; WCF_MASKED: internal
			0,		; WCF_DRAW_MASK: internal
			ColorMapMode <	; WCF_MAP_MODE
				0,		; CMM_ON_BLACK: black is seldom our background color.
				CMT_CLOSEST	; CM_MAP_TYPE
			>
		>

		mov	al,
			ds:[di].VDCI_colors[VDCC_TEXT*ColorQuad].CQ_redOrIndex
		cmp	ds:[di].VDCI_colors[VDCC_TEXT*ColorQuad].CQ_info,
				CF_INDEX
		jne	checkRGB
		cmp	al, C_BLACK
		jne	done
setOnBlack:
		ornf	ah, mask CMM_ON_BLACK shl offset WCF_MAP_MODE
done:
		.leave
		ret
checkRGB:
		mov	dh, ds:[di].VDCI_colors[VDCC_TEXT*ColorQuad].CQ_blue
		mov	dl, ds:[di].VDCI_colors[VDCC_TEXT*ColorQuad].CQ_green
		ornf	ah, mask WCF_RGB
		push	ax
		or	al, dh
		or	al, dl
		pop	ax
		jnz	done
		jmp	setOnBlack
VSCGetWindowColor endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VSCClockTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a clock tick by updating the region we use for our
		clock face to match the current time.

CALLED BY:	MSG_VC_CLOCK_TICK
PASS:		nothing
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VSCClockTick	method dynamic VisSkeletonClockClass, MSG_VC_CLOCK_TICK
		.enter
	;
	; Do not adjust the window region if our window is obscured. This will
	; only happen if Lights Out is saving the screen, or the user has gone
	; to a field that doesn't hold us. In the former case, resizing our
	; window will cause the screen to unsave (as a MSG_META_WIN_CHANGE will
	; be sent out), and in the latter case, there's no need to waste
	; the energy.
	;
		call	VisQueryWindow
		tst	di
		jz	done

		mov	bx, di
		call	MemPLock
		mov	es, ax
		mov	di, es:[W_visReg]
		mov	di, es:[di]
		mov	ax, es:[di]
		mov	cl, es:[W_color]
		call	MemUnlockV

		cmp	ax, EOREGREC		; region empty?
		je	ensureExposures		; yes, so do nothing, but make
						;  sure we're notified when the
						;  thing is exposed.
	;
	; Just send a MOVE_RESIZE_WIN message to ourselves. This will use the
	; current time to set the window's region properly.
	;
		mov	ax, MSG_VIS_MOVE_RESIZE_WIN
		call	ObjCallInstanceNoLock
done:
		.leave
		ret

ensureExposures:
		test	cl, mask WCF_PLAIN
		jz	done
	;
	; Window still marked as plain, so get the current color flags for
	; ourselves and change the window to not be plain, so we get a
	; MSG_META_EXPOSED when the screen is unsaved, the user re-enters our
	; field, whatever, and can update the display immediately.
	;
		mov	ax, MSG_VC_GET_WINDOW_COLOR
		push	bx
		call	ObjCallInstanceNoLock
		pop	di
		mov	bx, dx			; bx = green/blue
		mov	si, WIT_COLOR
		andnf	ah, not mask WCF_PLAIN
		call	WinSetInfo
		jmp	done
VSCClockTick	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VSCExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with being exposed, which means the user has unsaved
		the screen or come back to the field in which we reside
		and we should update our time, as well as turning off
		expose events.

CALLED BY:	MSG_META_EXPOSED
PASS:		*ds:si	= VisSkeletonClock object
		cx	= handle of exposed window
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VSCExposed	method dynamic VisSkeletonClockClass, MSG_META_EXPOSED
		.enter
	;
	; Get the actual color flags for the window.
	;
		push	cx
		mov	ax, MSG_VC_GET_WINDOW_COLOR
		call	ObjCallInstanceNoLock
		pop	di
		mov	bx, dx			; bx = green/blue
	;
	; And set them.
	;
		push	si
		mov	si, WIT_COLOR
		call	WinSetInfo
		pop	si
	;
	; Clear the inval region.
	;
		call	GrCreateState
		call	GrBeginUpdate
		call	GrEndUpdate
		call	GrDestroyState
	;
	; And change our region to correspond to the current time.
	;
		mov	ax, MSG_VIS_MOVE_RESIZE_WIN
		call	ObjCallInstanceNoLock
		.leave
		ret
VSCExposed	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VSCSetPartColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We have only one part whose color can be set: the text, so
		change the window color before we call our superclass.

CALLED BY:	MSG_VC_SET_PART_COLOR
PASS:		*ds:si	= VisSkeletonClock object
		ds:di	= VisSkeletonClockInstance
		dxcx	= ColorQuad
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VSCSetPartColor method dynamic VisSkeletonClockClass, MSG_META_COLORED_OBJECT_SET_COLOR
		call	VisQueryWindow
		tst	di
		jz	passItUp

		push	cx

		cmp	ch, CF_INDEX
	;
	; Form arguments for WinSetInfo using the new text color as the
	; background color of the window.
	;
if PZ_PCGEOS
		mov	ah, WinColorFlags <
			0,		; WCF_RGB: using color index
			0,		; WCF_TRANSPARENT: window has background color
			1,		; WCF_PLAIN: window doesn't require exposes
			0,		; WCF_MASKED: internal
			0,		; WCF_DRAW_MASK: internal
			ColorMapMode <	; WCF_MAP_MODE
				0,		; CMM_ON_BLACK: so solids
						;  will be visible in mono
				CMT_DITHER	;  map to dither so that
						;  it will be easier to
						;  see in monochrome.
			>
		>
else
		mov	ah, WinColorFlags <
			0,		; WCF_RGB: using color index
			0,		; WCF_TRANSPARENT: window has background color
			1,		; WCF_PLAIN: window doesn't require exposes
			0,		; WCF_MASKED: internal
			0,		; WCF_DRAW_MASK: internal
			ColorMapMode <	; WCF_MAP_MODE
				0,		; CMM_ON_BLACK: black is seldom
						; our background color.
				CMT_CLOSEST	; CM_MAP_TYPE
			>
		>
endif
		mov	ch, cl		; ch <- color index or red, for
					;  checking if color is black
		je	setRedOrIndex
		ornf	ah, mask WCF_RGB
		mov	bx, dx		; bx, green & blue
		or	ch, bl		; merge green & blue into red
		or	ch, bh		;  so we can see if all are 0
setRedOrIndex:
		mov	al, cl
			CheckHack <C_BLACK eq 0>
		tst	ch		; color is black?
		jnz	setWinColor	; no
		ornf	ah, mask CMM_ON_BLACK shl offset WCF_MAP_MODE
setWinColor:
		push	si
		mov	si, WIT_COLOR
		call	WinSetInfo
		pop	si
	;
	; Pass the message up to our superclass to actually store the
	; color and invalidate the window.
	;
		mov	ax, MSG_META_COLORED_OBJECT_SET_COLOR
		pop	cx
passItUp:
		mov	di, offset VisSkeletonClockClass
		GOTO	ObjCallSuperNoLock
VSCSetPartColor endm

DigitalCode	ends

