COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		Graphics/grOutput.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
   GBL	GrDrawPoint	Draw a single pixel to the screen
   GBL	GrDrawPointAtCP	Draw a single pixel to the screen
   GBL	GrDrawHLine	Draw a horizontal line
   GBL	GrDrawHLineTo	Draw a horizontal line
   GBL	GrDrawVLine	Draw a vertical line
   GBL	GrDrawVLineTo	Draw a vertical line
   GBL	GrFillRect	Draw a rectangle
   GBL	GrFillRectTo	Draw a rectangle
   INT	FillRect	Internal utility routine for rectangle drawing
   GBL	GrDrawRect	Draw a rectangle frame
   GBL	GrDrawRectTo	Draw a rectangle frame
   EXT	GrDrawRectLow	Far routine to draw rectangles, for calling from KLib
   INT	DrawRect	Internal routine to draw rectangle
   INT	CheckCoord	internal error-checking routine.
   INT	Check4Coords	internal error-checking routine.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	4/88	initial version


DESCRIPTION:
	This file contains the application interface for all graphics output
	except text.  Most of the routines here call the currently selected
	screen driver to do most of the work, and deal with coordinate
	translation.

	$Id: graphicsOutput.asm,v 1.1 97/04/05 01:12:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsObscure	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawPointAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single pixel.at the current pen position.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		store in a graphics string and exit if in store mode
		call rect routine

		IMAGING CONVENTIONS NOTE:
			This routine is taken care of via the changes to
			FillRect.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version
	Jim	4/89		update documentation
	Jim	10/89		Added GrDrawPointAtCP, changed to use area
				attributes instead of line attributes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawPointAtCP	proc	far
		call	EnterGraphics
		jc	dpcpGString

		call	TrivialRejectFar		; ok to draw if returns
		call	GetDevPenPos			; ax,bx = pen position
		jc	done				; bail on overflow
		movdw	cxdx, axbx			; drawing one pixel
		mov	si,GS_areaAttr			; use area attributes
		call	FillRectLowFar			; fill the rectangle
done:
		jmp	ExitGraphics

		; writing to a gstring
dpcpGString:
		mov	al, GR_DRAW_POINT_CP		; set correct opcode
		clr	cl				; no data bytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes			; store the bytes
		jmp	ExitGraphicsGseg
GrDrawPointAtCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a pixel.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- coordinate to draw at (document coord space)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawPoint	proc	far
		call	EnterGraphics
		call	SetDocPenPos			; set current position
		jc	dpGString

		; transform the coordinates
		
		call	TrivialRejectFar		; draw if this returns
		call	GrTransCoordFar
		jc	done				; bail on overflow
		movdw	cxdx, axbx			; drawing one pixel
		mov	si,GS_areaAttr			; use area attributes
		call	FillRectLowFar			; fill the rectangle
done:
		jmp	ExitGraphics

		; writing to a gstring
dpGString:
		mov	al, GR_DRAW_POINT		; set correct opcode
		mov	cx, OpDrawPoint - 1		; # bytes to store
		call	WriteGSElementFar
		jmp	ExitGraphicsGseg
GrDrawPoint	endp

GraphicsObscure	ends

kcode	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawHLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a horizontal line from the current pen position.

CALLED BY:	GLOBAL

PASS: 		di	- GState handle
		cx	- x2
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if in store mode, store in graphics string and exit
		call line draw routine

		IMAGING CONVENTIONS NOTE:
			This routine is taken care of via the changes to
			DrawLine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Need to add support for wide lines;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version
	Jim	4/89		updated to deal with rotation
	Jim	10/89		added GrDrawHLineTo, changed name from `
				GrHorizLine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawHLineTo	proc	far
		call	EnterGraphics
		jc	hltoGString

		; drawing to device

		call	TrivialReject		; if this returns, draw it
		mov	dx, 8000h		; signal to use CP for Y
		call	PenPosCoordSetup	; do the setup, set new penPos
		jc	done			; no draw on coord overflow
		mov	di, offset GS_lineAttr
		call	DrawLineLow		; finish it off
done:
		jmp	ExitGraphics

		; writing to a graphics string
hltoGString:
		push	cx			; save coordinate
		mov	dx, 8000h		; need to update curpos
		call	PenPosCoordSetup
		pop	cx			; restore doc coordinate
		mov	al, GR_DRAW_HLINE_TO	; graphics opcode
		mov	bx, cx			; store data byte
		mov	cl, size OpDrawHLineTo - 1 ; # data bytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; store to string
		jmp	ExitGraphicsGseg
GrDrawHLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PenPosCoordSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute coords "To" drawing routines, and set new pen pos.

CALLED BY:	INTERNAL
		GrDrawHLineTo
PASS:		ds	- GState
		es	- Window
		cx	- x2 (doc coords)  OR  8000h to use current x position
		dx	- y2 (doc coords)  OR  8000h to use current y position
RETURN:		carry	- set if some coordinate overflow
		ax,bx	- first endpoint (current position; dev coords)
		cx,dx	- second endpoint (current Y, passed X; dev coords)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This is kind of tricky since the penPos in the GState is 
		stored in PAGE coordinates, while the passed x position is
		in DOCUMENT coordinates, and we want DEVICE coordiantes.

		Additionally, we want to maintain the accuracy of the current
		pen position, which is stored in DWFixed PAGE coordinates.
		So we Untransform that coordinate into DWFixed device coords,
		and use the result to forward translate to DEVICE coords for 
		both the current position and the 2nd endpoint.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should only be used by HLineTo and VLineTo, since
		extra work is done because of the fact that only one (x or y)
		of the endpoint coordinates is provided.  A more optimal 
		routine could be written if both endpoint coords are given.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PenPosCoordSetup proc	near
		uses	ds, es, si
penPos		local	PointDWFixed
endPos		local	PointDWFixed
		.enter

		; move the pen position over to the endPos scratch space, 
		; and to the penPos variable.  

		movdwf	sibxax, ds:[GS_penPos].PDF_x	; get x position
		movdwf	ss:penPos.PDF_x, sibxax		;  save it locally
		movdwf	ss:endPos.PDF_x, sibxax	
		movdwf	sibxax, ds:[GS_penPos].PDF_y	; get y position
		movdwf	ss:penPos.PDF_y, sibxax		;  save it locally
		movdwf	ss:endPos.PDF_y, sibxax	

		; Untransform the endPos, so we have document coordinates

		push	es				; save window seg
		mov	ax, dx				; save dx
		mov	si, offset GS_TMatrix		; penPos is PAGE coords
		segmov	es, ss
		lea	dx, ss:endPos			; es:dx -> coord
		call	UnTransCoordDWFixed

		; do Y position

		cmp	ax, 8000h			; skip calc if using CP
		je	doX2
		cwd
		movdw	ss:endPos.PDF_y.DWF_int, dxax	; store new y position
		clr	ss:endPos.PDF_y.DWF_frac
		jmp	haveEndDoc
		
		; do the same for the X position
doX2:
		cmp	cx, 8000h			; do we need to do X ?
		je	haveEndDoc			;  no, done
		mov	ax, cx				; make it a dword
		cwd
		movdw	ss:endPos.PDF_x.DWF_int, dxax	; store new x position
		clr	ss:endPos.PDF_x.DWF_frac

		; since we need to store the new current position, transform
		; endPos into PAGE coordinates.
haveEndDoc:	
		lea	dx, ss:endPos			; reload pointer
		call	TransCoordDWFixed		; es:dx -> new pen pos
		movdwf	ds:[GS_penPos].PDF_x, ss:endPos.PDF_x, ax
		movdwf	ds:[GS_penPos].PDF_y, ss:endPos.PDF_y, ax

		; if we are going to a GString, skip getting the device coords

		tst	ds:[GS_gstring]			; if going to gstring
		mov	ax, ds				; save GState
		pop	ds				; ds -> Window
		LONG jnz	done

		; finally, transform both coords into device coordinates

		mov	si, offset W_TMatrix		; ds:si -> W_TMatrix
		call	TransCoordDWFixed		; xform endPos
		lea	dx, ss:penPos
		call	TransCoordDWFixed		; xform penPos

		; round the coordinates and add the window position

		movdw	sidx, ss:endPos.PDF_y.DWF_int	; get y2
		cmp	ss:endPos.PDF_y.DWF_frac, 8000h
		cmc
		adc	dx, ds:[W_winRect].R_top	; add in window coord
		adc	si, 0
		CheckDWordResult si, dx			; check for overflow
		jc	done				; bail on overflow
		movdw	sicx, ss:endPos.PDF_x.DWF_int	; get x2
		cmp	ss:endPos.PDF_x.DWF_frac, 8000h
		cmc
		adc	cx, ds:[W_winRect].R_left	; add in window coord
		adc	si, 0
		CheckDWordResult si, cx			; check for overflow
		jc	done				; bail on overflow
		movdw	sibx, ss:penPos.PDF_y.DWF_int	; get y2
		cmp	ss:penPos.PDF_y.DWF_frac, 8000h
		cmc
		adc	bx, ds:[W_winRect].R_top	; add in window coord
		adc	si, 0
		CheckDWordResult si, bx			; check for overflow
		jc	done				; bail on overflow
		movdw	siax, ss:penPos.PDF_x.DWF_int	; get x2
		cmp	ss:penPos.PDF_x.DWF_frac, 8000h
		cmc
		adc	ax, ds:[W_winRect].R_left	; add in window coord
		adc	si, 0
		CheckDWordResult si, ax			; check for overflow
done:
		.leave
		ret

PenPosCoordSetup endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLineFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to translate coords and draw a thin line

CALLED BY:	INTERNAL
		DrawRect, various others
PASS:		ax...dx		- line endpoints
		ds		- GState
		es		- Window
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawLineFixed	proc	near

		;  translate coordinates

		call	GrTransCoord2		; translate both coords
		jnc	checkStyle		; skip draw if overflow
		ret					

		; coords are OK.  Draw the line.
checkStyle:
		mov	di, GS_lineAttr			; pass line attributes
		call	DrawLineLow
		ret
DrawLineFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawVLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a vertical line from the current pen position.

CALLED BY:	GLOBAL

PASS: 		di	- GState handle
		dx	- y2
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		store in a graphics string and exit if in store mode
		call line drawing routine

		IMAGING CONVENTIONS NOTE:
			This routine is taken care of via the changes to
			DrawLine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version
	Jim	4/89...		updated to deal with rotation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawVLineTo	proc	far
		call	EnterGraphics
		jc	vltoGString

		; we need to grab the current position and calculate the
		; other position.

		call	TrivialReject		; won't return if no draw
		mov	cx, 8000h		; use CP for x
		call	PenPosCoordSetup
		jc	done			; no draw on coord overflow
		mov	di, offset GS_lineAttr
		call	DrawLineLow		; finish it off
done:
		jmp	ExitGraphics

		; handle writing out a gstring
vltoGString:
		push	dx
		mov	cx, 8000h		; use CP for x
		call	PenPosCoordSetup
		pop	dx
		mov	al, GR_DRAW_VLINE_TO	; graphics opcode
		mov	bx, dx			; store data byte
		mov	cl, size OpDrawVLineTo - 1 ; # data bytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; store to string
		jmp	ExitGraphicsGseg
GrDrawVLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillRectTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a filled rectangle from the current pen position.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		cx,dx	- coordinates of opposite corner
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call GSStore to try to store command to memory
		if we're writing to the screen:
			translate coords to screen coords;
			call rectangle function in driver;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		IMAGING CONVENTIONS NOTE:
			This routine is taken care of via the changes to
			FillRect

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version
	Chris	11/ 9/88	Changed to store to a graphics string

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFillRectTo	proc	far
		call	EnterGraphicsFill
		jc	frtoGString

		; writing to a device

		call	TrivialReject		; do basic rejection test

		; we need to do something different if there is rotation.

		test	es:[W_curTMatrix].TM_flags, TM_ROTATED
		jnz	handleRotation

		; if there is no rotation, we can just transform the coords

		movdw	axbx, cxdx
		call	GrTransCoord		; transform 2nd endpoint
		jc	done
		movdw	cxdx, axbx		; move back to cxdx
		call	GetDevPenPos		; ax,bx = current pen pos.
		jc	done
		mov	si, offset GS_areaAttr
		call	FillRectLow		; fill the rectangle
done:
		jmp	ExitGraphics		; all done		

		; there is rotation in the transformation matrix.
handleRotation:
		clc				; fill it
		mov	di, offset cs:CalcRectToCorners
		mov	si, offset GS_areaAttr
		call	GetDevPenPos		; ax,bx = pen position
		call	DrawFillRotRect
		jmp	ExitGraphics

		; write out to graphics string
frtoGString:
		mov	al, GR_FILL_RECT_TO
		jz	haveOpcode		; if not Path, we're fine
		mov	al, GR_DRAW_RECT_TO	; else use unfilled version
haveOpcode:
		mov	bx, cx			; set up right register
		mov	cl, size OpFillRectTo - 1 ; #data bytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write out to string
		jmp	ExitGraphicsGseg
GrFillRectTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a rectangle.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- coordinates of first corner.
		cx,dx	- coordinates of opposite corner
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFillRect	proc	far
		call	EnterGraphicsFill
		call	SetDocPenPos		; set new pen position
		jc	frGString

		; drawing to a device
	
		call	TrivialReject		; check for the usual
		mov	si,GS_areaAttr		; use area attributes
		call	FillRect		; fill the rectangle
		jmp	ExitGraphics

		; write out to graphics string
frGString:
		mov	al, GR_FILL_RECT	; graphics opcode
		jz	haveOpcode		; use DRAW for paths
		mov	al, GR_DRAW_RECT
haveOpcode:
		mov	cx, size OpFillRect - 1	; # data bytes
		call	WriteGSElement		; write info to GString
		jmp	ExitGraphicsGseg
GrFillRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNFillRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A simple version of GrFillRect that can execute without
		loading any other kernel modules.

CALLED BY:	INTERNAL
		DrawErrorBox, SysNotify
PASS:		di	- GState
		ax...dx	- the usual rectangle corners
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SNFillRect	proc	far
		call	EnterGraphics
		add	ax, es:[W_winRect].R_left
		add	cx, es:[W_winRect].R_left
		add	bx, es:[W_winRect].R_top
		add	dx, es:[W_winRect].R_top
		mov	si, GS_areaAttr
		mov	di, DR_VID_RECT
		call	es:[W_driverStrategy]
		jmp	ExitGraphics
SNFillRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteGSElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to write info to a graphics string 

CALLED BY:	INTERNAL
		Graphics drawing routines 
PASS:		al	- GString opcode
		cx	- number of bytes to write
		di	- GString handle	(setup by EnterGraphics)
		ss:bp	- pointer to EGframe	(setup by EnterGraphics)
		ds	- GState		(setup by EnterGraphics)
RETURN:		nothing
DESTROYED:	si, ds

PSEUDO CODE/STRATEGY:
		since EnterGraphics pushes ax,bx,cx,dx in order, we can use
		these values in the stack frame to write out info to the 
		GString.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteGSElement	proc	near
		segmov	ds, ss			; set ds:si -> stack parms
		mov	si, bp			;
		add	si, offset EG_ax	; set ds:si => part of EGframe
		mov	ah, GSSC_FLUSH
		call	GSStore			;and call the store routine
		ret
WriteGSElement	endp

WriteGSElementFar proc	far
		call	WriteGSElement
		ret
WriteGSElementFar endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRectTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle frame from the current pen position

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		cx,dx	- coordinate of opposite corner
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see PSEUDO CODE/STRATEGY of DrawRect

		IMAGING CONVENTIONS NOTE:
			This routine is taken care of via the changes to
			DrawLine and DrawRect

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version
	Jim	4/89		updated to account for rotation
	Steve	7/19/89		broke out code for DrawFrameRectLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawRectTo	proc	far
		call	EnterGraphics
		jc	rtoGString

		; drawing to a device

		call	TrivialReject		; do basic rejection test
		call	CheckThinLine		; see if we have single pixel.
		jc	handleRotation		;  if not, draw fat rectangle

		; we need to do something different if there is rotation.

		test	es:[W_curTMatrix].TM_flags, TM_ROTATED
		jnz	handleRotation

		; if there is no rotation, we can just transform the coords

		movdw	axbx, cxdx
		call	GrTransCoord		; transform 2nd endpoint
		jc	done
		movdw	cxdx, axbx		; move back to cxdx
		call	GetDevPenPos		; ax,bx = current pen pos.
		jc	done
		call	DrawRectLow		; fill the rectangle
done:
		jmp	ExitGraphics		; all done		

		; there is rotation in the transformation matrix.
handleRotation:
		clc				; fill it
		mov	di, offset cs:CalcRectToCorners
		mov	si, offset GS_areaAttr
		call	GetDevPenPos		; ax,bx = pen position
		jc	done
		call	DrawFillRotRect
		jmp	done

		; drawing to a graphics string
rtoGString:
		mov	al, GR_DRAW_RECT_TO
		mov	bx, cx			; set up right register
		mov	cl, size OpDrawRectTo - 1 ; #databytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write out to string
		jmp	ExitGraphicsGseg
GrDrawRectTo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle frame.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- coordinates for one corner of the rectangle
		cx,dx	- coordinates for the opposite corner
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawRect	proc	far
		call	EnterGraphics
		call	SetDocPenPos		; set new pen position
		jc	rGString

		; writing to a device
	
		call	TrivialReject		; do basic check
		call	CheckThinLine		; see if we have single pixel.
		jc	fatLine

		call	DrawRect
		jmp	ExitGraphics

		; line is not 1-pixel wide
fatLine:	
		stc				; carry set to DRAW
		mov	si, GS_lineAttr		; use line attributes
		mov	di, offset CalcRectCorners
		call	DrawFillRotRect		; draw the thing
		jmp	ExitGraphics

		; writing to a graphics string
rGString:
		mov	al, GR_DRAW_RECT
		mov	cx, size OpDrawRect - 1	; # data bytes
		call	WriteGSElement		; write info to GString
		jmp	ExitGraphicsGseg
GrDrawRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Fill a rectangle.

CALLED BY:	INTERNAL
		GrFillRect

PASS: 		ax - left (in document coordinates)
		bx - top (in document coordinates)	
		cx - right (in document coordinates)
		dx - bottom (in document coordinates)
		si - offset to proper CommonAttr struc in GState
		ds - graphics state structure
		es - Window structure

RETURN: 	es - Window structure (may have moved)

DESTROYED: 	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	
	IMAGING CONVENTIONS NOTE:
		This routine has been adjusted by Jim for the 2.0 imaging
		conventions.  4 March 1991.  This will take care of:

		    GrDrawPoint, GrDrawPointAtCP, GrFillRect, GrFillRectTo

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Jim	4/89		partial fix for rotation (doesn't crash now)
	jim	1/91		take out border stuff
	jim	3/91		correct 2.0 version to conform to new imaging
				conventions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillRect	proc	near

		cmp	ax,cx
		jle	orderY
		xchg	ax,cx
orderY:
		cmp	bx,dx
		jle	checkRot
		xchg	bx,dx

		; if rotated, need to do more than just a transformation
checkRot:
		test	es:[W_curTMatrix].TM_flags, TM_ROTATED
		jnz	handleRotation
		call	GrTransCoord2		; translate coord to screen
		jc	done			; skip if 32-bit overflow
		call	FillRectLow
done:
		ret

		; rotated coords, call polygon routine
handleRotation:
		clc				; carry clear to FILL
		mov	di, offset cs:CalcRectCorners
		mov	si, offset GS_areaAttr	; pass area attributes
		call	DrawFillRotRect		; common rout polygon and line
		jmp	done			; all finished
FillRect	endp

if (0)
FillRectFar	proc	far
		call	FillRect
		ret
FillRectFar	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillRectLow  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Call the video driver to draw a rectangle after clipping the
		rectangle to wMask bounds

CALLED BY:	INTERNAL		(FillRectLow)
		FillRect, GrDrawRect
		GLOBAL			(GrIntFillRectLow)

PASS: 		ax - left (in device coordinates)
		bx - top (in device coordinates)
		cx - right (in device coordinates)
		dx - bottom (in device coordinates)
		si - offset GS_areaAttr.CA_mask to use area drawing state
		     offset GS_lineAttr.CA_mask to use line drawing state
		ds - graphics state structure
		es - Window structure

		IMAGING CONVENTIONS NOTE:
			this routine assumes that the passed coordinates have 
			been adjusted for imaging conventions.  The coordinates
			that are filled by the video driver include the left,
			right, top and bottom pixels specified.

RETURN: 	es - Window structure (may have moved)

DESTROYED: 	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillRectLow	proc	near

		; If the coords are equal, then don't mess with them (that is,
		; don't adjust right/bottom).  This means that nothing should
		; disappear by getting scaled too small.  This kind of violates
		; the imaging conventions, but was deemed appropriate by a
		; panel of impartial jurors.

		cmp	ax, cx			; check min/max in x
		jge	swapX1X2
xOrdered:
		dec	cx			; adjust for imaging convention
reorderY:
		cmp	bx, dx			; check min/max in y
		jge	swapY1Y2
yOrdered:
		dec	dx			; adjust for imaging convention

		; check for trivial reject for clipping and clip to wMask
		; bounds at the same time
		; LEFT
checkCoords:
EC <		call	Check4Coords					>
		mov	di,es:[W_maskRect.R_left]
		cmp	cx,di
		jl	DRL_ret				;  reject: before left
		cmp	ax,di				; clip to left
		jg	DRL_1
		mov	ax,di

		; RIGHT
DRL_1:
		mov	di,es:[W_maskRect.R_right]
		cmp	ax,di
		jg	DRL_ret				;  reject: past right
		cmp	cx,di				; past to right
		jl	DRL_2
		mov	cx,di

		; TOP
DRL_2:
		mov	di,es:[W_maskRect.R_top]
		cmp	dx,di
		jl	DRL_ret				;  reject: above top
		cmp	bx,di				; clip to top
		jg	DRL_3
		mov	bx,di

		; BOTTOM
DRL_3:
		mov	di,es:[W_maskRect.R_bottom]
		cmp	bx,di
		jg	DRL_ret				;  reject: below bottom
		cmp	dx,di				; clip to bottom
		jl	DRL_4
		mov	dx,di

		; all clear file away
DRL_4:
		mov	di,DR_VID_RECT
		push	bp, si				; save frame pointer
		call	es:[W_driverStrategy]		; make call to driver
		pop	bp, si				; restore frame pointer
DRL_ret:
		ret

		; order coordinates in X
swapX1X2:
		je	reorderY		; catch single pixels
		xchg	ax, cx
		jmp	xOrdered

swapY1Y2:
		je	checkCoords		; catch single pixels
		xchg	bx, dx
		jmp	yOrdered

FillRectLow	endp

FillRectLowFar	proc	far
		call	FillRectLow
		ret
FillRectLowFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFillRotRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by drawrect and fillrect. Draws either
		a Polyline or a Polygon

CALLED BY:	INTERNAL

PASS:		carry	- 0 to fill polygon (fill rule = ODD_EVEN)
			  1 to draw polyline (draw connected line)
		ax,bx,cx,dx - bounds of rectangle
		si	- offset to attributes to use
		di	- near offset to routine to get coords
			  (set to either CalcRectCorners or CalcRectToCorners)
RETURN:		nothing
DESTROYED:	si,di

PSEUDO CODE/STRATEGY:
		For drawing rectangular polygons, it doesn't matter what fill
		rule is used, so we pick the ODD_EVEN rule (enum = 0) so that
		the value passed in dl is different than is passed to 
		PolylineSpecial (where dl=1 to indicate connected lines).  
		This allows us to use this routine to call either, saving
		some bytes.  The carry is used to indicate which one, since
		dl is otherwise occupied on entry.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawFillRotRect proc	near
penPos		local	PointDWFixed
scratchPos	local	PointDWFixed
eoregrec1	local	word
eoregrec2	local	word
docX		local	word
docY		local	word
ll_y		local	word			; lower left
ll_x		local	word	
lr_y		local	word			; lower right
lr_x		local	word
ur_y		local	word			; upper right
ur_x		local	word
ul_y		local	word			; upper left
ul_x		local	word			;
		push	ax,bx,cx,dx
		jc	lines			; do lines if needed
		.enter

		ForceRef	penPos
		ForceRef	scratchPos
		ForceRef	docX
		ForceRef	docY

		; coords given in document coords, translate to device space

		call	di
		mov	cx, 4
		mov	bx, ss
		lea	dx, ss:ul_x		; bx:dx -> points
		mov	di, DR_VID_POLYGON
		clr	al			; pass the flag to ALWAYS draw
		push	bp, ds
		call	es:[W_driverStrategy]
		pop	bp, ds
done:
		.leave
		pop	ax,bx,cx,dx
		ret			

		; drawing polylines...
lines:
		.enter
		call	CheckThinLine		; check for solid, 1-pixel wide
		jc	complexLine
		cmp	ds:[GS_lineStyle], LS_SOLID
		jne	complexLine

		; draw the simple case - 1-pixel solid line

		call	di			; do transformations
		mov	ax, ss:ul_x		; copy fourth point
		mov	ss:docY, ax
		mov	ax, ss:ul_y		; copy fourth point
		mov	ss:docX, ax
		mov	ss:eoregrec1, EOREGREC	; signal end of point list
		mov	ss:eoregrec2, EOREGREC	; signal end of point list
		mov	cx, 4
		mov	bx, ss
		lea	si, ss:ul_x		; bx:si -> point buffer
		mov	di, DR_VID_POLYLINE	; load up function number
		push	bp
		mov	ax, 101h		; 1x1 brush size
		call	es:[W_driverStrategy]	; call video driver
		pop	bp
		jmp	done

		; Either fat or styled.
complexLine:
		mov	ul_x, ax		; store document coords
		mov	ul_y, bx
		mov	ur_x, cx
		mov	ur_y, bx
		mov	ll_x, ax
		mov	ll_y, dx
		mov	lr_x, cx
		mov	lr_y, dx
		mov	ss:docY, ax
		mov	ss:docX, bx
		push	bp, di
		mov	di, si			; di = offset to attr
		lea	si, ss:ul_x		; bp:si -> points
		mov	bp, ss
		mov	dl, 1			; draw connected lines
		mov	cx, 4			; four points passed
		call	DrawPolylineFar		; draw polyline
		pop	bp, di
		jmp	done
DrawFillRotRect endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcRectCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the corners for a possibly rotated rectangle

CALLED BY:	INTERNAL
		DrawFillRotRect

PASS:		ds	- GState
		es	- Window
		ax,bx,cx,dx	- rect bounds
		inherits stack frame
RETURN:		fills out dev coords in stack frame
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcRectCorners	proc	near
		.enter	inherit DrawFillRotRect

		; coords given in document coords, translate to device space

		mov	ss:ll_y, dx		; save coords for later
		mov	ss:ll_x, ax
		mov	ss:ur_y, bx
		mov	ss:ur_x, cx
		call	GrTransCoord2		; translate the ul and lr
		mov	ss:ul_x, ax		; store translated coords
		mov	ss:ul_y, bx
		mov	ss:lr_x, cx
		mov	ss:lr_y, dx
		mov	ax, ss:ll_x
		mov	bx, ss:ll_y
		mov	cx, ss:ur_x
		mov	dx, ss:ur_y
		call	GrTransCoord2
		mov	ss:ll_x, ax
		mov	ss:ll_y, bx 
		mov	ss:ur_x, cx
		mov	ss:ur_y, dx
		.leave
		ret
CalcRectCorners	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcRectToCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the four corners of a rectangle.

CALLED BY:	INTERNAL
		DrawFillRectTo
PASS:		ds	- GState
		es	- Window
		cx,dx	- opposite corner (document coords)
		inherited stack frame
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		We have the current position, and a document coordinate to
		transform.  We need to untransform the pen position by the
		GState matrix in order to get document coordinates for both,
		then transform forward to device coordinates for all four
		corners.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcRectToCorners proc	near
		uses	ds, si, es, di
		.enter inherit DrawFillRotRect

		; Move the pen position into a local variable, so we can
		; untransform it.
		
		mov	ss:docX, cx			; save passed coords 
		mov	ss:docY, dx
		mov	bx, es				; save Window
		movdwf	ss:penPos.PDF_x, ds:GS_penPos.PDF_x, ax
		movdwf	ss:penPos.PDF_y, ds:GS_penPos.PDF_y, ax
		segmov	es, ss, dx
		lea	dx, ss:penPos			; es:dx -> coord
		mov	si, offset GS_TMatrix		; ds:si -> TMatrix
		call	UnTransCoordDWFixed

		; we need to do all four coords.  Just take it one at a time.

		mov	ds, bx				; ds -> Window
		mov	si, offset W_curTMatrix		; get full TMatrix
		mov	ax, ss:docX			; do upper right
		cwd
		movdw	ss:scratchPos.PDF_x.DWF_int, dxax
		clr	ss:scratchPos.PDF_x.DWF_frac
		movdwf	ss:scratchPos.PDF_y, ss:penPos.PDF_y, ax
		lea	dx, ss:scratchPos
		lea	di, ss:ur_x
		call	CalcOneCorner
		jc	done

		mov	ax, ss:docX			; do lower right
		cwd
		movdw	ss:scratchPos.PDF_x.DWF_int, dxax
		mov	ax, ss:docY
		cwd
		movdw	ss:scratchPos.PDF_y.DWF_int, dxax
		clr	ax
		mov	ss:scratchPos.PDF_x.DWF_frac, ax
		mov	ss:scratchPos.PDF_y.DWF_frac, ax
		lea	dx, ss:scratchPos
		lea	di, ss:lr_x
		call	CalcOneCorner
		jc	done

		mov	ax, ss:docY			; do lower left
		cwd
		movdw	ss:scratchPos.PDF_y.DWF_int, dxax
		clr	ss:scratchPos.PDF_y.DWF_frac
		movdwf	ss:scratchPos.PDF_x, ss:penPos.PDF_x, ax
		lea	dx, ss:scratchPos
		lea	di, ss:ll_x
		call	CalcOneCorner
		jc	done

		lea	dx, ss:penPos
		lea	di, ss:ul_x
		call	CalcOneCorner
done:
		.leave
		ret
CalcRectToCorners endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcOneCorner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for CalcRectToCorners

CALLED BY:	INTERNAL
		CalcRectToCorners
PASS:		ds:si		- points at TMatrix to use
		es:dx		- points at PointDWFixed
		ss:di		- points at Point to store result
RETURN:		carry		- set if overflow
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcOneCorner	proc	near
		.enter

		call	TransCoordDWFixed
		mov	bx, dx
		clr	dx			; use as a NULL register
		movdw	cxax, es:[bx].PDF_x.DWF_int
		cmp	es:[bx].PDF_x.DWF_frac.high, 80h
		cmc
		adc	ax, dx
		adc	cx, dx
		mov	ss:[di].P_x, ax
		CheckDWordResult cx, ax
		jc	done
		movdw	cxax, es:[bx].PDF_y.DWF_int
		cmp	es:[bx].PDF_y.DWF_frac.high, 80h
		cmc
		adc	ax, dx
		adc	cx, dx
		mov	ss:[di].P_y, ax
		CheckDWordResult cx, ax
done:
		.leave
		ret
CalcOneCorner	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRect 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level interface to frame drawing code

CALLED BY:	GrDrawRect

PASS:		expects EnterGraphics has already been called
		ds - graphics state
		ax - left
		bx - top
		cx - right
		dx - bottom
RETURN:
		nothing
DESTROYED:
		ax,bx,cx,dx,di,bp,si

PSEUDO CODE/STRATEGY:
		Call DrawLine for each side of the rectangle

		IMAGING CONVENTIONS NOTE:
			This routine has been changed to adhere to the 
			imaging conventions for version 2.0.  All that had
			to be done here is ensure the proper line end type
			was set up in the GState.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		doesn't work in INVERT mode because corners overlap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/19/89		Stole code from middle of GrDrawRect and
				added StackFrame and passed attributes
	jim	8/10/89		added global version
	jim	3/91		saved,set,restored line end type to conform
				to imaging conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawRect	proc	near
rLeft		local	word \
		push	ax
rTop		local	word \
		push	bx
rRight		local	word \
		push	cx
rBottom		local	word \
		push	dx

		.enter

		; force line end type to square, so we get the right size
		; lines

		mov	cl, ds:[GS_lineEnd]	; get current line end
		push	cx			; save line end type
		mov	ds:[GS_lineEnd], LE_SQUARECAP

		; Draw left side

		mov	cx,ax			; right = left
		call	DrawLineFixed		; LEFT SIDE

		; Draw right side

		mov	ax, rRight		; set x1 = x2 = right
		mov	cx, ax
		mov	bx, rTop		; restore top
		mov	dx, rBottom		; restore bottom
		call	DrawLineFixed		; RIGHT SIDE

		; Draw top side

		mov	ax, rLeft		; set x1 left
		mov	cx, rRight		; set x2 right
		mov	bx, rTop		; restore top
		mov	dx,bx
		call	DrawLineFixed		; TOP

		; Draw bottom side

		mov	ax, rLeft		; set x1 left
		mov	cx, rRight		; set x2 right
		mov	bx, rBottom 		; restore bottom
		mov	dx,bx
		call	DrawLineFixed		; BOTTOM

		pop	cx			; restore old line end
		mov	ds:[GS_lineEnd], cl	; save the old one

		.leave
		ret
DrawRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level interface to frame drawing code

CALLED BY:	INTERNAL
		GrDrawRectTo

PASS:		expects EnterGraphics has already been called
		ds - graphics state
		ax - left	(device coords)
		bx - top	
		cx - right
		dx - bottom
RETURN:
		nothing
DESTROYED:
		ax,bx,cx,dx,di,bp,si

PSEUDO CODE/STRATEGY:
		Call DrawLineLowTransed for each side of the rectangle

		IMAGING CONVENTIONS NOTE:
			This routine has been changed to adhere to the 
			imaging conventions for version 2.0.  All that had
			to be done here is ensure the proper line end type
			was set up in the GState.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		doesn't work in INVERT mode because corners overlap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawRectLow	proc	near
rLeft		local	word \
		push	ax
rTop		local	word \
		push	bx
rRight		local	word \
		push	cx
rBottom		local	word \
		push	dx

		.enter

		; force line end type to square, so we get the right size
		; lines

		mov	cl, ds:[GS_lineEnd]	; get current line end
		push	cx			; save line end type
		mov	ds:[GS_lineEnd], LE_SQUARECAP
		mov	di, offset GS_lineAttr

		; Draw left side

		mov	cx,ax			; right = left
		call	DrawLineLow		; LEFT SIDE

		; Draw right side

		mov	ax, rRight		; set x1 = x2 = right
		mov	cx, ax
		mov	bx, rTop		; restore top
		mov	dx, rBottom		; restore bottom
		call	DrawLineLow		; RIGHT SIDE

		; Draw top side

		mov	ax, rLeft		; set x1 left
		mov	cx, rRight		; set x2 right
		mov	bx, rTop		; restore top
		mov	dx,bx
		call	DrawLineLow		; TOP

		; Draw bottom side

		mov	ax, rLeft		; set x1 left
		mov	cx, rRight		; set x2 right
		mov	bx, rBottom 		; restore bottom
		mov	dx,bx
		call	DrawLineLow		; BOTTOM

		pop	cx			; restore old line end
		mov	ds:[GS_lineEnd], cl	; save the old one

		.leave
		ret
DrawRectLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do basic trivial reject (NULL clip, no window)

CALLED BY:	INTERNAL
		drawing routines
PASS:		ds	- GState
		es	- Window
RETURN:		nothing (will not return if object is trivially rejected)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (window null)
		    jump to ExitGraphicsGseg
		else 
		    if (clip region null)
		        jump to ExitGraphics
		    elseif (x scale factor is zero)
			jump to ExitGraphics
		    elseif (y scale factor is zero)
			jump to ExitGraphics
	
		else
		    return

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TrivialReject	proc	near

		; check for a window

		tst	ds:[GS_window]		; if no window, bail
		jz	noWindow
		test	es:[W_grFlags], mask WGF_MASK_NULL ; see if null mask
		jnz	nullClip
		push	ax
		mov	ax, es:[W_curTMatrix].TM_11.WWF_int ; check X coord
		or	ax, es:[W_curTMatrix].TM_11.WWF_frac
		or	ax, es:[W_curTMatrix].TM_21.WWF_int
		or	ax, es:[W_curTMatrix].TM_21.WWF_frac
		jz	nullXform
		mov	ax, es:[W_curTMatrix].TM_12.WWF_int ; check Y coord
		or	ax, es:[W_curTMatrix].TM_12.WWF_frac
		or	ax, es:[W_curTMatrix].TM_22.WWF_int
		or	ax, es:[W_curTMatrix].TM_22.WWF_frac
		jz	nullXform
		pop	ax
		ret

		; there is no window.  pop the return address and bail.
noWindow:
		add	sp, 2			; lose return address
		jmp	ExitGraphicsGseg	; bail out

		; NULL transformation in X or Y
nullXform:
		pop	ax

		; NULL clip region.  do the same
nullClip:
		add	sp, 2			; lose return address
		jmp	ExitGraphics

TrivialReject	endp

TrivialRejectFar proc far

		; check for a window

		tst	ds:[GS_window]		; if no window, bail
		jz	noWindow
		test	es:[W_grFlags], mask WGF_MASK_NULL ; see if null mask
		jnz	nullClip
		ret

		; there is no window.  pop the return address and bail.
noWindow:
		add	sp, 4			; lose far return address
		jmp	ExitGraphicsGseg	; bail out

		; NULL clip region.  do the same
nullClip:
		add	sp, 4			; lose far return address
		jmp	ExitGraphics
TrivialRejectFar endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Verify that a device coordinate is legal

CALLED BY:	INTERNAL
		Utility

PASS: 		ax - coordinate

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK

CheckCoordFar	proc	far
		call	CheckCoord
		ret
CheckCoordFar	endp

CheckCoord	proc	near
;		cmp	ax, MAX_COORD
;		jb	CC_good
;		cmp	ax, MIN_COORD
;		ja	CC_good
;		ERROR	GRAPHICS_BAD_COORDINATE
;CC_good:
		ret
CheckCoord	endp

Check4CoordsFar	proc	far
		call	Check4Coords
		ret
Check4CoordsFar	endp

Check4Coords	proc	near
		push	ax
		call	CheckCoord
		mov	ax, bx
		call	CheckCoord
		mov	ax, cx
		call	CheckCoord
		mov	ax, dx
		call	CheckCoord
		pop	ax
		ret
Check4Coords	endp

endif

kcode	ends
