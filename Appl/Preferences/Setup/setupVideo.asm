COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphical Setup
FILE:		setupVideo.asm

AUTHOR:		Adam de Boor, Oct  6, 1990

ROUTINES:
	Name			Description
	----			-----------
	SetupDrawCornerArrows	Draw the corner arrows for the first video
				test screen.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 6/90	Initial revision


DESCRIPTION:
	Functions for video-setting stage of Setup
		

	$Id: setupVideo.asm,v 1.3 98/06/17 21:27:04 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupDrawCornerArrows

DESCRIPTION:	Initializes the polygon specifying buffers and calls
		GrFillPolygon to draw the corner markers.

CALLED BY:	SetupScreenClass(MSG_VIS_DRAW)

PASS:		di	= gstate to use for drawing

RETURN:		ds - dgroup

DESTROYED:	ax,bx,cx,dx,bp,di,si

REGISTER/STACK USAGE:
	bx <- 0
	dx <- CORNER_POLY_W
	di <- CORNER_POLY_H
	bp <- CORNER_POLY_THICKNESS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

SetupDrawCornerArrows	proc	far
	mov	ax, dgroup
	mov	ds, ax

	push	di		; save GState

	clr	bx
	mov	dx, CORNER_POLY_W
	mov	di, CORNER_POLY_H
	mov	bp, CORNER_POLY_THICKNESS

	;-----------------------------------------------------------------------
	;init coords for top left corner

	mov	si, offset dgroup:cornerTopL
	mov	ds:[si].CPS_1.P_x, bx
	mov	ds:[si].CPS_1.P_y, bx

	mov	ds:[si].CPS_2.P_x, dx
	mov	ds:[si].CPS_2.P_y, bx

	mov	ds:[si].CPS_3.P_x, dx
	mov	ds:[si].CPS_3.P_y, bp

	mov	ds:[si].CPS_4.P_x, CORNER_POLY_THICKNESS * 2
	mov	ds:[si].CPS_4.P_y, bp

	mov	ds:[si].CPS_5.P_x, dx
	mov	ds:[si].CPS_5.P_y, CORNER_POLY_H - CORNER_POLY_THICKNESS

	mov	ds:[si].CPS_6.P_x, CORNER_POLY_W - CORNER_POLY_THICKNESS
	mov	ds:[si].CPS_6.P_y, di

	mov	ds:[si].CPS_7.P_x, bp
	mov	ds:[si].CPS_7.P_y, CORNER_POLY_THICKNESS * 2

	mov	ds:[si].CPS_8.P_x, bp
	mov	ds:[si].CPS_8.P_y, di

	mov	ds:[si].CPS_9.P_x, bx
	mov	ds:[si].CPS_9.P_y, di

	;-----------------------------------------------------------------------
	;init coords for bottom left corner
	;ax <- screenH
	;cx <- screenH - CORNER_POLY_H

	mov	si, offset dgroup:cornerBotL
	mov	ax, ds:[screenH]
	mov	cx, ax
	sub	cx, di
	mov	ds:[si].CPS_1.P_x, bx
	mov	ds:[si].CPS_1.P_y, cx

	mov	ds:[si].CPS_2.P_x, bp
	mov	ds:[si].CPS_2.P_y, cx

	mov	ds:[si].CPS_3.P_x, bp
	push	ax
	sub	ax, CORNER_POLY_THICKNESS * 2
	mov	ds:[si].CPS_3.P_y, ax
	pop	ax

	push	dx
	sub	dx, bp
	mov	ds:[si].CPS_4.P_x, dx
	pop	dx
	mov	ds:[si].CPS_4.P_y, cx

	mov	ds:[si].CPS_5.P_x, dx
	push	cx
	add	cx, bp
	mov	ds:[si].CPS_5.P_y, cx
	pop	cx

	push	bp
	shl	bp, 1
	mov	ds:[si].CPS_6.P_x, bp
	pop	bp

	push	ax
	sub	ax, bp
	mov	ds:[si].CPS_6.P_y, ax

	mov	ds:[si].CPS_7.P_x, dx
	mov	ds:[si].CPS_7.P_y, ax
	pop	ax

	mov	ds:[si].CPS_8.P_x, dx
	mov	ds:[si].CPS_8.P_y, ax

	mov	ds:[si].CPS_9.P_x, bx
	mov	ds:[si].CPS_9.P_y, ax

	;-----------------------------------------------------------------------
	;init coords for top right corner

	;ax <- screenW
	;cx <- screenW - CORNER_POLY_H

	mov	si, offset dgroup:cornerTopR
	mov	ax, ds:[screenW]
	mov	cx, ax
	sub	cx, dx

	mov	ds:[si].CPS_1.P_x, cx
	mov	ds:[si].CPS_1.P_y, bx

	mov	ds:[si].CPS_2.P_x, ax
	mov	ds:[si].CPS_2.P_y, bx

	mov	ds:[si].CPS_3.P_x, ax
	mov	ds:[si].CPS_3.P_y, di

	push	ax
	sub	ax, bp
	dec	ax
	mov	ds:[si].CPS_4.P_x, ax
	mov	ds:[si].CPS_4.P_y, di

	mov	ds:[si].CPS_5.P_x, ax
	push	bp
	shl	bp, 1
	mov	ds:[si].CPS_5.P_y, bp
	pop	bp
	pop	ax

	push	cx
	add	cx, bp
	mov	ds:[si].CPS_6.P_x, cx
	pop	cx
	mov	ds:[si].CPS_6.P_y, di

	mov	ds:[si].CPS_7.P_x, cx
	push	di
	sub	di, bp
	mov	ds:[si].CPS_7.P_y, di
	pop	di

	push	ax
	sub	ax, CORNER_POLY_THICKNESS * 2
	mov	ds:[si].CPS_8.P_x, ax
	pop	ax
	mov	ds:[si].CPS_8.P_y, bp

	mov	ds:[si].CPS_9.P_x, cx
	mov	ds:[si].CPS_9.P_y, bp

	;-----------------------------------------------------------------------
	;init coords for bottom right corner
	;ax = screenW
	;cx = screenW - CORNER_POLY_W

	mov	si, offset dgroup:cornerBotR

	push	cx
	add	cx, bp
	mov	ds:[si].CPS_1.P_x, cx
	pop	cx

	push	ax
	mov	ax, ds:[screenH]
	mov	ds:[si].CPS_5.P_y, ax
	mov	ds:[si].CPS_6.P_y, ax
	push	ax
	sub	ax, di
	mov	ds:[si].CPS_1.P_y, ax
	mov	ds:[si].CPS_3.P_y, ax
	mov	ds:[si].CPS_4.P_y, ax
	add	ax, bp
	mov	ds:[si].CPS_9.P_y, ax
	pop	ax
	sub	ax, bp
	mov	ds:[si].CPS_7.P_y, ax
	mov	ds:[si].CPS_8.P_y, ax
	sub	ax, bp
	mov	ds:[si].CPS_2.P_y, ax
	pop	ax

	push	ax
	sub	ax, bp
	dec	ax
	mov	ds:[si].CPS_2.P_x, ax
	mov	ds:[si].CPS_3.P_x, ax
	pop	ax

	mov	ds:[si].CPS_4.P_x, ax
	mov	ds:[si].CPS_5.P_x, ax

	mov	ds:[si].CPS_6.P_x, cx
	mov	ds:[si].CPS_7.P_x, cx
	mov	ds:[si].CPS_9.P_x, cx

	sub	ax, CORNER_POLY_THICKNESS * 2
	mov	ds:[si].CPS_8.P_x, ax

	;-----------------------------------------------------------------------
	;draw polygons

	pop	di		; di <- gstate

	mov	si, offset dgroup:cornerTopL
	call	SetupDrawArrow

	mov	si, offset dgroup:cornerBotL
	call	SetupDrawArrow

	mov	si, offset dgroup:cornerTopR
	call	SetupDrawArrow

	mov	si, offset dgroup:cornerBotR
	call	SetupDrawArrow
	ret
SetupDrawCornerArrows	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDrawArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single polygonal arrow on the screen

CALLED BY:	SetupDrawCornerArrows
PASS:		di	= gstate handle
		ds:si	= array of Point structures describing the polygon
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupDrawArrow	proc	near
	; draw innards in white
	mov	ax, C_WHITE
	call	GrSetAreaColor
	mov	al, RFR_WINDING	; specify winding rule for fill
	mov	cx, size CornerPolyStruct / size Point
	call	GrFillPolygon

	; and border in black
	mov	ax, C_BLACK
	call	GrSetLineColor
	mov	cx, size CornerPolyStruct / size Point
	call	GrDrawPolygon
	ret
SetupDrawArrow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a MSG_SPEC_BUILD for SetupColorBoxClass

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= SetupColorBoxClass object
		es	= dgroup
		bp	= SpecBuildFlags
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Figure how big we should be as a portion of the screen size,
		making sure we can fit 8 boxes in two rows w/o gaps.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBSpecBuild	method	SetupColorBoxClass, MSG_SPEC_BUILD
		.enter
	;
	; Pass the call on to our superclass first.
	;
		mov	di, offset SetupColorBoxClass
		CallSuper	MSG_SPEC_BUILD
	;
	; Set the size of the thing permanently to 1/2 the screen width by
	; 1/8 the screen height.
	; 
		mov	ax, es:[screenW]
		shr	ax
		xchg	cx, ax		; box is 1/2 the screen width
		
		mov	ax, es:[screenH]
		shr	ax
		shr	ax
		shr	ax
		andnf	ax, 0xfffe	; ax <- make it even
		xchg	dx, ax		; box is 1/8 the screen height.
		call	VisSetSize
	;
	; Tell geometry manager we're doing nothing fancy, but to leave us
	; our current size.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		ornf	ds:[di].VI_geoAttrs, 
			mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID or \
			mask VGA_USE_VIS_SET_POSITION

	;
	; Figure and record the dimensions of a single box.
	;
		shr	cx		; 8 boxes per row
		shr	cx
		shr	cx
		
		shr	dx		; 2 boxes per column
		
		mov	di, ds:[si]
		add	di, ds:[di].SetupColorBox_offset
		mov	ds:[di].SCBI_boxWidth, cx
		mov	ds:[di].SCBI_boxHeight, dx
		.leave
		ret
SCBSpecBuild	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the 16-color box on the screen.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= SetupColorBoxClass object
		es	= dgroup
		bp	= gstate to use
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBDraw		method	SetupColorBoxClass, MSG_VIS_DRAW
		.enter
		mov	di, bp
		call	GrSaveState

;		commented out 3/4/91.  Border width stuff is gone
;		clr	ax			; all boxes unbordered
;		call	GrSetBorderWidth
	;
	; Check for the gradient version
	;
		mov	di, ds:[si]
		add	di, ds:[di].SetupColorBox_offset
		tst	ds:[di].SCBI_isGradient
		jnz	isGradient	; branch if is gradient
	;
	; Draw the first row
	; 
		clr	ax		; initial X offset = 0
		clr	bx		; initial Y offset = 0
		mov	cx, C_BLACK	; initial color = C_BLACK
		call	SCBDrawRow

	;
	; Draw the second row below the first.
	;
		mov	di, ds:[si]
		add	di, ds:[di].SetupColorBox_offset
		clr	ax		; initial X offset = 0
		mov	bx, ds:[di].SCBI_boxHeight	; initial Y offset =
							;  row height
		mov	cx, C_DARK_GREY	; initial color = C_DARK_GREY
		call	SCBDrawRow

	;
	; Draw the frame of the object in black.
	;
		mov	di, bp
		mov	ax, C_BLACK
		call	GrSetLineColor

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	ax, ds:[di].VI_bounds.R_left
		mov	bx, ds:[di].VI_bounds.R_top
		mov	cx, ds:[di].VI_bounds.R_right
		mov	dx, ds:[di].VI_bounds.R_bottom
		mov	di, bp
		call	GrDrawRect

	;
	; Restore the gstate to its original condition...
	; 
done:
		call	GrRestoreState
		.leave
		ret

	;
	; Draw our gradient version instead
	;
isGradient:
		mov	di, ds:[si]
		add	di, ds:[di].SetupColorBox_offset
		mov	ax, ds:[di].SCBI_boxHeight
		shr	ax, 1				;ax <- box height/2
	;
	; red bar
	;
		clr	bx				;bx <- y offset
		mov	dx, offset SCBUpdateRed		;dx <- color routine
		call	SCBDrawColorBar
	;
	; green bar
	;
		add	bx, ax				;bx <- y offset
		mov	dx, offset SCBUpdateGreen	;dx <- color routine
		call	SCBDrawColorBar
	;
	; blue bar
	;
		add	bx, ax				;bx <- y offset
		mov	dx, offset SCBUpdateBlue	;dx <- color routine
		call	SCBDrawColorBar
	;
	; gray bar
	;
		add	bx, ax				;bx <- y offset
		mov	dx, offset SCBUpdateGrey	;dx <- color routine
		call	SCBDrawColorBar

		mov	di, bp				;di <- GState
		jmp	done
SCBDraw		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBDrawRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single row of color boxes

CALLED BY:	SCBDraw
PASS:		ax	= initial X offset from top-left corner of box
		bx	= initial Y offset from top-left corner of box
		cx	= initial color index
		*ds:si	= SetupColorBoxClass object
		bp	= gstate to use for drawing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBDrawRow	proc	near
		class	SetupColorBoxClass
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		add	ax, ds:[di].VI_bounds.R_left
		add	bx, ds:[di].VI_bounds.R_top
		mov	dx, cx		; dx <- current color index
		mov	cx, 8		; 8 boxes per row...
boxLoop:
	;
	; Set area color to current box color.
	;
		xchg	ax, dx
		mov	di, bp
		call	GrSetAreaColor
		inc	ax		; dx <- color for next box
		xchg	ax, dx

		push	cx, dx

	;
	; Figure lower-right corner of box to draw.
	;
		mov	cx, ax
		mov	dx, bx
		
		mov	di, ds:[si]
		add	di, ds:[di].SetupColorBox_offset
		add	cx, ds:[di].SCBI_boxWidth
		add	dx, ds:[di].SCBI_boxHeight
	;
	; Draw the rectangle itself.
	;
		mov	di, bp
		call	GrFillRect
		xchg	ax, cx		; ax <- next X coordinate
	;
	; Restore counter and next color and loop to do the next box
	; 
		pop	cx, dx
		loop	boxLoop
		.leave
		ret
SCBDrawRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBDrawColorBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a gradient-filled bar, 1/2 box height

CALLED BY:	SCBDraw
PASS:		ax	= bar height
		bx	= initial Y offset from top-left corner of box
		dx	= routine to update color
		*ds:si	= SetupColorBoxClass object
		bp	= GState to use for drawing
RETURN:		nothing
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/6/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BAR_SIZE	equ	2

SCBDrawColorBar	proc	near
		class	SetupColorBoxClass
		uses	ax, bx
gstate		local	hptr.GState	push bp
colorRout	local	word		push dx
barHeight	local	sword		push ax
barColor	local	RGBValue

		.enter

	;
	; set up some things
	;
		clr	ss:barColor.RGB_red
		clr	ss:barColor.RGB_green
		clr	ss:barColor.RGB_blue

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		add	bx, ds:[di].VI_bounds.R_top
		mov	ax, ds:[di].VI_bounds.R_right
		mov	dx, ds:[di].VI_bounds.R_left
		sub	ax, dx				;ax <- width
		sub	ax, 256				;ax <- width - 256
		shr	ax, 1				;ax <- margin
		add	ax, dx				;ax <- left X
barLoop:
	;
	; Draw a color bar
	;
		mov	di, ss:gstate
		push	ax, bx
		mov	ah, CF_RGB			;ah <- ColorFlag
		mov	al, ss:barColor.RGB_red
		mov	bl, ss:barColor.RGB_green
		mov	bh, ss:barColor.RGB_blue
		call	GrSetAreaColor
		pop	ax, bx

		mov	dx, bx
		add	dx, ss:barHeight		;dx <- bottom
		mov	cx, ax
		add	cx, BAR_SIZE			;cx <- right
		call	GrFillRect
	;
	; Advance the x position
	;
		mov	ax, cx				;ax <- new left
	;
	; Update the color
	;
		call	ss:colorRout
		jnc	barLoop				;loop if more

		.leave
		ret
SCBDrawColorBar	endp

;
; PASS:		ss:bp - inherited locals
; RETURN:	carry - set to stop
;

SCBUpdateRed	proc	near
		.enter	inherit	SCBDrawColorBar
		add	ss:barColor.RGB_red, BAR_SIZE
		.leave
		ret
SCBUpdateRed	endp

SCBUpdateGreen	proc	near
		.enter	inherit	SCBDrawColorBar
		add	ss:barColor.RGB_green, BAR_SIZE
		.leave
		ret
SCBUpdateGreen	endp

SCBUpdateBlue	proc	near
		.enter	inherit	SCBDrawColorBar
		add	ss:barColor.RGB_blue, BAR_SIZE
		.leave
		ret
SCBUpdateBlue	endp

SCBUpdateGrey	proc	near
		.enter	inherit	SCBDrawColorBar
		add	ss:barColor.RGB_red, BAR_SIZE
		add	ss:barColor.RGB_green, BAR_SIZE
		add	ss:barColor.RGB_blue, BAR_SIZE
		.leave
		ret
SCBUpdateGrey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupShowColorScreenIfAppropriate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the current driver can show colors or grayscales, put
		up the color test screen, else consider video test complete

CALLED BY:	MSG_SETUP_SHOW_COLOR_SCREEN_IF_APPROPRIATE
PASS:		ds = es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupShowColorScreenIfAppropriate method SetupClass,
				 MSG_SETUP_SHOW_COLOR_SCREEN_IF_APPROPRIATE
		.enter
	;
	; If the default video driver can show more than 2 colors, put up the
	; color test screen.
	;
		mov	bx, handle ColorTestScreen		; assume can do
		mov	si, offset ColorTestScreen		;  color...
		mov	ax, MSG_GEN_INTERACTION_INITIATE

		lds	di, ds:[defaultVideo]
	;
	; Check for many color display
	;
CheckHack <BMF_8BIT gt BMF_4BIT>
		cmp	ds:[di].VDI_bmFormat, BMF_8BIT
		jb	notManyColor
	;
	; Is many color -- enable the gradient bars
	;
		mov	si, offset GradientText
		call	sendUsableToGradient
		mov	si, offset GradientBox
		call	sendUsableToGradient
	;
	; Continue on our way
	;
		mov	bx, handle ColorTestScreen		; assume can do
		mov	si, offset ColorTestScreen		;  color...
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		jmp	sendIt

notManyColor:
		cmp	ds:[di].VDI_bmFormat, BMF_MONO
		jne	sendIt
		
	;
	; Nope. Send ourselves the video-test-complete method so we can
	; figure what to do next.
	;
		mov	ax, MSG_SETUP_VIDEO_TEST_COMPLETE
		mov	bx, handle 0
sendIt:
	;
	; Ship off whatever method we've decided to send. Don't FORCE_QUEUE or
	; CALL the thing -- just send it.
	; 
		clr	di
		call	ObjMessage
		.leave
		ret

sendUsableToGradient:
		mov	ax, MSG_GEN_SET_USABLE
		mov	bx, handle GradientText
		clr	di
		mov	dl, VUM_NOW
		call	ObjMessage
		retn
SetupShowColorScreenIfAppropriate endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupVideoTestComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge the completion of the video-test portion of our
		programme.

CALLED BY:	MSG_SETUP_VIDEO_TEST_COMPLETE
PASS:		ds = es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
spuiKey char "spui",0 

SetupVideoTestComplete	method	SetupClass, MSG_SETUP_VIDEO_TEST_COMPLETE
		.enter
	;
	; If we're in MODE_AFTER_VIDEO_CHANGE, change the restart mode to
	; full setup so we don't screw up if the user exits here and restarts
	; us later on, then tries to change the video.
	;
		cmp	ds:[mode], MODE_AFTER_VIDEO_CHANGE
		jne	10$
		mov	bp, MODE_FULL_SETUP
		call	SetupSetRestartMode
10$:
	;
	; Figure what to do...
	;
		cmp	ds:[mode], MODE_AFTER_PM_VIDEO_CHANGE
		je	setupComplete
		cmp	ds:[mode], MODE_AFTER_SETUP_VIDEO_CHANGE
		je	setupComplete
	;
	; Still performing a full install/setup, so bring up the mouse
	; selection screen or the SPUI selection screen
	; 
		mov	cx, cs
		mov	ds, cx
		mov	si, offset setupCategory	;ds:si <- category
		mov	dx, offset spuiKey		;cx:dx <- key
		mov	ax, TRUE			;ax <- default value
		call	InitFileReadBoolean
		tst	ax
		jz	skipSPUI

;		mov	si, offset UISelectScreen
;		mov	bx, handle UISelectScreen
; -- We don't have but the Motif UI right now for breadbox ensemble
;  - LES DEC 18, 2001
		mov	si, offset MouseSelectScreen
		mov	bx, handle MouseSelectScreen
gotScreen:
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
done:
		.leave
		ret

skipSPUI:
		mov	si, offset MouseSelectScreen
		mov	bx, handle MouseSelectScreen
		jmp	gotScreen

setupComplete:
	;
	; Only here to make sure the video is ok, so bring up the DoneScreen
	; with the video-test-complete text in it.
	; 
		mov	si, offset VideoDoneText
		call	SetupComplete
		jmp	done
SetupVideoTestComplete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupRevertVideo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a request to revert to the previous video driver.

CALLED BY:	MSG_SETUP_REVERT_VIDEO
PASS:		ds = es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		This is the escape hatch for the user to recover the previous
		video settings. We want to restore the device and driver keys
		and restart the system.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupRevertVideo method	SetupClass, MSG_SETUP_REVERT_VIDEO
	;
	; Return screen 0 keys to their previous values.
	;
		call	PrefRestoreVideo
	;
	; When we restart, come back in full-setup mode if we didn't get here
	; b/c Preferences changed the video driver.
	;
		cmp	ds:[mode], MODE_AFTER_PM_VIDEO_CHANGE
		je	pmChange
		mov	bp, MODE_FULL_SETUP
		call	SetupSetRestartMode
doRestart:
	;
	; Now restart GEOS.
	; 
		mov	ax, SST_RESTART
		call	SysShutdown
		ret			; XXX: => can't restart should
					;  notify user nicely, no?
pmChange:
	;
	; Set "continue setup" to FALSE so we restart into Preferences and
	; don't have to worry about reverting a revert....
	; 
		call	SetupClearContinueSetup
		jmp	doRestart
SetupRevertVideo endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupVideoSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge the selection of a video driver by loading it
		and seeing if it thinks the device is around.

CALLED BY:	MSG_SETUP_VIDEO_SELECTED
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		Find the selected video driver. If none selected, return.
		Lock down the PrefDeviceDescriptor for it.
		Switch to SP_SYSTEM and attempt to load the thing.
		If get GLE_NOT_MULTI_LAUNCHABLE, call GeodeForEach to find
			all loaded video drivers and call their 
			DRE_TEST_DEVICE functions, passing the device
			of choice. If get back DP_NOT_PRESENT, DP_PRESENT or
			DP_CANT_TELL, we've found the right one.
		Else, call the DRE_TEST_DEVICE function of the loaded driver,
			save the result and unload the driver again.
		If DP_NOT_PRESENT returned, bitch.
		Else put up VideoRestartScreen

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupVideoSelected	method	SetupClass, MSG_SETUP_VIDEO_SELECTED
		.enter
	;
	; Fetch the selected entry number and save it away.
	;
		mov	bx, handle VideoSelectList
		mov	si, offset VideoSelectList
		call	GetEntryPos
		cmp	cx, -1
		je	done

		xchg	ax, cx
		mov	ds:[videoDeviceNum], ax

		call	PrefTestVideoDevice
		jnc	ok
		mov	bp, offset noSuchDisplay
		tst	ax
		jz	error
		mov	bp, offset cantLoadVidDriver
error:
		call	MyError
		jmp	done
ok:
	;
	; Figure which set of continuation instructions applies to the current
	; mode and set it usable so it shows up on screen.
	; 
		mov	si, offset VideoRestartContinueText_FullSetup
		cmp	ds:[mode], MODE_FULL_SETUP
		je	initiateScreen
		cmp	ds:[mode], MODE_AFTER_VIDEO_CHANGE
		je	initiateScreen
		mov	si, offset VideoRestartContinueText_PMVideo
		

initiateScreen:
		mov	bx, handle VideoRestartContinueText_FullSetup
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
	;
	; Now bring the restart screen up.
	;
		mov	si, offset VideoRestartScreen
		mov	bx, handle VideoRestartScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
done:
		.leave
		ret

SetupVideoSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupRestartForVideo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restart the system to change the video driver, arranging for
		the change to be revertable.

CALLED BY:	MSG_SETUP_RESTART_FOR_VIDEO
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Save the current video state
		Set the current device as the driver of choice
		Restart GEOS.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupRestartForVideo	method	SetupClass, MSG_SETUP_RESTART_FOR_VIDEO
	;
	; Preserve the current video settings.
	;
		call	PrefSaveVideo
	;
	; Store the current video device to the ini file as screen 0.
	;
;		mov	ax, ds:[videoDeviceNum]
;		call	SetupFetchVideoDeviceBlock

;		mov	si, offset screen0CatString
;		call	PrefDeviceSetINIFile

		mov	bx, handle VideoSelectList
		mov	si, offset VideoSelectList
		mov	di, mask MF_CALL
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjMessage

	;
	; Change the setup mode to MODE_AFTER_VIDEO_CHANGE so user can recover
	; easily if s/he chose the wrong driver.
	;
		cmp	ds:[mode], MODE_AFTER_PM_VIDEO_CHANGE
		je	doRestart	; leave in AFTER_PM, if that's where
					;  we were, to avoid going through
					;  the rest of the setup again...
		mov	bp, MODE_AFTER_VIDEO_CHANGE
		call	SetupSetRestartMode
	;
	; Restart the system.
	;
doRestart:
		mov	ax, SST_RESTART
		call	SysShutdown
		ret			; XXX: => couldn't restart, so should
					;  notify user nicely...
SetupRestartForVideo	endp
