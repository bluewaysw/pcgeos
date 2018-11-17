COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript translation library
FILE:		exportPath.asm

AUTHOR:		Jim DeFrisco, Jan 25, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/25/93		Initial revision


DESCRIPTION:
	Code to deal with implementing paths in PostScript.
		

	$Id: exportPath.asm,v 1.1 97/04/07 11:25:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportPath	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitClipPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is a clip path, set it.

CALLED BY:	INTERNAL
		EmitStartObject
PASS:		tgs	- inherited locals
		bx	- modified element number 
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmitClipPath		proc	far
		uses	ds, bx, ax
tgs		local	TGSLocals
		.enter	inherit

		; if we're gonna be doing the fill-mask thing, then forget
		; these clip masks.

		cmp	bx, 2*(GR_FILL_RECT-GSE_FIRST_OUTPUT_OPCODE)
		jae	checkAreaMask

		; XXX: should use GSE_LAST_TEXT_OPCODE, but it's defined
		; incorrectly (misses GR_DRAW_TEXT_OPTR)
		cmp	bx, 2*(GR_DRAW_TEXT_OPTR-GSE_FIRST_OUTPUT_OPCODE)
		ja	checkLineMask
		cmp	bx, 2*(GSE_FIRST_TEXT_OPCODE-GSE_FIRST_OUTPUT_OPCODE)
		jae	checkTextMask

checkLineMask:
		call	CheckFullLineMask
		jnc	exitOK

		; we'll probably need this 
checkTextMask:			; XXX: we don't seem to support text
				;  masks yet, so there's no point in checking
				;  for them
getPath:
		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		mov	bx, tgs.TGS_stream

		; get the current clip path.

		mov	ax, GPT_WIN_CLIP
		call	EmitPath
		tst	ax			; if zero, skip clipPath
		jz	doClip
		EmitPS	emitClip
doClip:
		mov	ax, GPT_CLIP
		call	EmitPath
		tst	ax			; if zero, we're done
		jz	done
		EmitPS	emitClip

done:		
		mov	bx, handle PSCode
		call	MemUnlock
exitOK:
		clr	ax			; no error

		.leave
		ret

checkAreaMask:
		call	CheckFullAreaMask
		jnc	exitOK
		jmp	getPath
EmitClipPath		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to get a path and emit a procedure to build it.

CALLED BY:	INTENAL
PASS:		ax	- GetPathType	 - indicates which path to get
		tgs	- inherited locals
RETURN:		ax	- zero if no path was written (path is NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Use GrGetPath to get the current path of the type indicated;
		Parse the GString returned to build out the path contruction
		  operators needed to build the path;
		Write it out to the output stream;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmitPath	proc	far
		uses	ds, bx, cx, dx, si, di
tgs		local	TGSLocals
		.enter	inherit

		; now get the current path.

		mov	tgs.TGS_pathType, al	; save path type
		clr	tgs.TGS_pathCnt		; no elements yet
		mov	bx, ax
		mov	di, tgs.TGS_gstate	; get current path
		call	GrSaveState		; save everything
		call	GrGetPath		; bx = block handle

		; if there isn't a path, we're done.

		tst	bx			; if nothing returned,
		jnz	openPath		;  skidaddle
		clr	ax			; return no path flag
		jmp	exit

		; lock down the block and make it a GString...
openPath:
		push	bx			;  else, save block handle
		call	MemLock			; 
		mov	bx, ax
		clr	si			; bx:si -> Path GString
		mov	cl, GST_PTR		; pass GString type
		call	GrLoadGString		; si = new GString handle

		; write out the opening bracket and newpath operator.

		mov	bx, handle PSCode	; need access to PSCode block
		call	MemLock
		mov	ds, ax			; ds -> PSCode segment
		mov	bx, tgs.TGS_stream	; get stream block handle
		EmitPS	emitOpenPath

		; now scan through the path, emitting the appropriate path
		; construction components.

		call	CreatePathGString	; di = new GState handle 
keepScanning:
		mov	dx, mask GSC_OUTPUT or mask GSC_PATH 
		call	GrDrawGStringAtCP		; go until we hit one
		mov	ax, dx				; save return code

		cmp	ax, GSRT_FAULT			; if some problem...
		je	donePath
		cmp	ax, GSRT_COMPLETE		; same if at end of 
		je	donePath			;  document
		cmp	ax, GSRT_PATH			; path opcode ?
		jne	checkOutput			;  no, must be output
skipPathElements:
		mov	al, GSSPT_SKIP_1		;  yes, skip over it.
		call	GrSetGStringPos
		jmp	checkNextElement

		; found an output code.  Do some range checking and call the
		; proper emit routine.
checkOutput:
EC <		cmp	cl, GSE_FIRST_OUTPUT_OPCODE		>
EC <		ERROR_B	PS_EXPORT_UNKNOWN_GSTRING_ELEMENT	>
EC <		cmp	cl, GSE_LAST_OUTPUT_OPCODE		>
EC <		ERROR_A	PS_EXPORT_UNKNOWN_GSTRING_ELEMENT	>

		; found a valid output opcode, write some PostScript code
handleOutput:
		mov	bl, cl				; set up for jump tab
		clr	bh
		sub	bx, GSE_FIRST_OUTPUT_OPCODE
		shl	bx, 1				; need a word index
		call	EmitTransform			; update if needed
		inc	tgs.TGS_pathCnt			; one more element
		jnz	callRoutine
		mov	tgs.TGS_pathCnt, 2		; don't leave at zero
callRoutine:
		call	cs:pathRouts[bx]		; call routine

		; before we go on, check out the next opcode.  Most likely
		; it's not something we're interested in, but you never know.
checkNextElement:
		clr	cx				; just teasing
		call	GrGetGStringElement		; just want opcode
		mov	cl, al
		cmp	al, GSE_FIRST_OUTPUT_OPCODE	; see if in range
		jb	keepScanning
		cmp	al, GSE_LAST_OUTPUT_IN_PATH	; output code ?
		jbe	handleOutput			;  yes, deal with it
		cmp	al, GSE_FIRST_PATH_OPCODE
		jb	keepScanning
		cmp	al, GSE_LAST_PATH_OPCODE
		jbe	skipPathElements
		jmp	keepScanning

		; all finished.  Clean up and leave.
donePath:
;		mov	dx, offset emitRPM
;		mov	cx, length emitRPM
;		call	EmitPSCode
		call	DestroyPathGString	; kill temp extaction buffer 

		; done with path source GString, kill it.

		clr	di			; no GState to pass
		mov	ax, GSKT_LEAVE_DATA	; we'll do this ourselves
		call	GrDestroyGString	; get rid of data structures

		; done creating path, release the block that was alloc'd for us

		mov	bx, handle PSCode
		call	MemUnlock

		pop	bx			; restore path handle
		call	MemFree			; don't need it anymore

		mov	ax, 0xffff		; make it non-zero
		tst	tgs.TGS_pathCnt		; if nothing in there...
		jnz	exit
		clr	ax
exit:
		mov	di, tgs.TGS_gstate
		call	GrRestoreState		; restore it

		.leave
		ret
EmitPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for GrDrawLine, GrDrawLineTo
		GrDrawHLine, GrDrawHLineTo, GrDrawVLine, GrDrawVLineTo

CALLED BY:	INTERNAL
		EmitPath

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			set transformation matrix code;
			<x> <y> <x> <y> L

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathLine	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; get the element

		call	ExtractElement

		; output the coordinates

		mov	cx, bx			; save opcode
		mov	di, tgs.TGS_pathGState
		call	GrGetCurPos		; get the current position
		cmp	cx, (GR_DRAW_HLINE-GSE_FIRST_OUTPUT_OPCODE)*2
		je	hline
		cmp	cx, (GR_DRAW_VLINE-GSE_FIRST_OUTPUT_OPCODE)*2
		LONG je	vline
		mov	ax, ds:[si].ODL_x2	; do second endpoint first
		mov	bx, ds:[si].ODL_y2
		call	GrMoveTo		; update the current position
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		mov	ax, ds:[si].ODL_x1	; now do first coordinate
		mov	bx, ds:[si].ODL_y1
		call	CoordToAscii

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitPL
		mov	cx, length emitPL
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock

		.leave
		ret

		; handle GR_DRAW_HLINE
hline:
		mov	ax, ds:[si].ODHL_x1	; get first coord
		mov	bx, ds:[si].ODHL_y1
		push	ds:[si].ODHL_x2		; save future coord
		push	bx
outputPoints:
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		pop	bx			; restore second coord
		pop	ax
		call	CoordToAscii
		push	di			; save buffer offset
		mov	di, tgs.TGS_pathGState
		call	GrMoveTo		; update the current position
		pop	di
		jmp	emitCode		; all done 
		
		; handle GR_DRAW_VLINE
vline:
		mov	ax, ds:[si].ODVL_x1	; get first coord
		mov	bx, ds:[si].ODVL_y1
		push	ax
		push	ds:[si].ODVL_y2		; save future coord
		jmp	outputPoints
		
PathLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for GrDrawRelLineTo, GrDrawLineTo
		GrDrawHLineTo, GrDrawVLineTo

CALLED BY:	EmitPath

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			<x> <y> DLT

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathLineTo	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit
		
		; get the bugger

		call	ExtractElement

		; output the coordinates

		mov	cx, bx			; save opcode
		mov	di, tgs.TGS_pathGState
		cmp	cx, (GR_DRAW_REL_LINE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	rlineTo
		call	GrGetCurPos
		cmp	cx, (GR_DRAW_HLINE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	hlineTo
		cmp	cx, (GR_DRAW_VLINE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	vlineTo
		mov	ax, ds:[si].ODLT_x2	; do second endpoint first
		mov	bx, ds:[si].ODLT_y2
updatePen:
		call	GrMoveTo		; update the current position
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii

		; finished with coords.  emit PS code and we're outta here

		mov	si, offset emitPLT
		mov	cx, length emitPLT
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock

		.leave
		ret

		; handle GR_DRAW_HLINE_TO
hlineTo:
		add	ax, ds:[si].ODHLT_x2
		jmp	updatePen

		; handle GR_DRAW_VLINE_TO
vlineTo:
		add	bx, ds:[si].ODVLT_y2
		jmp	updatePen

		; handle GR_DRAW_REL_LINE_TO
rlineTo:
		add	si, offset ODLT_x2	; ds:si -> PointWWFixed
		call	WWFCoordToAscii		

		push	di			; save buffer offset
		mov	di, tgs.TGS_pathGState
		movwwf	dxcx, ds:[si].PF_x
		movwwf	bxax, ds:[si].PF_y
		call	GrDrawRelLineTo		; update the current position
		pop	di

		; finished with coords.  emit PS code and we're outta here

		mov	si, offset emitPRLT
		mov	cx, length emitPRLT
		jmp	emitCode
		
PathLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a curve

CALLED BY:	EmitPath
PASS:		si	- gstring handle
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathCurve		proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		call	ExtractElement

		; output the coordinates

		mov	di, tgs.TGS_pathGState
		mov	cx, bx			; save opcode
		cmp	cx, (GR_DRAW_CURVE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		LONG je	doCurveTo
		cmp	cx, (GR_DRAW_REL_CURVE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		LONG je	handleRelCurve

		add	si, offset ODCV_x1
		call	GrDrawCurve		; update curpos
		sub	si, offset ODCV_x1
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	ax, ds:[si].ODCV_x4	; do second endpoint first
		mov	bx, ds:[si].ODCV_y4
		call	CoordToAscii
		mov	ax, ds:[si].ODCV_x2
		mov	bx, ds:[si].ODCV_y2
		call	CoordToAscii
		mov	ax, ds:[si].ODCV_x3
		mov	bx, ds:[si].ODCV_y3
		call	CoordToAscii
		mov	ax, ds:[si].ODCV_x1
		mov	bx, ds:[si].ODCV_y1
		call	CoordToAscii

		; finished with coords.  emit PS code and we're outta here

		mov	si, offset emitPC
		mov	cx, length emitPC
copyOp:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock

		.leave
		ret

		; Hit a curveto.  Important to do this right for paths.
doCurveTo:
		add	si, offset ODCVT_x2	; ds:si-> points
		call	GrDrawCurveTo		; update curpos
		sub	si, offset ODCVT_x2	; ds:si-> points
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	ax, ds:[si].ODCVT_x4	; output first rel coord
		mov	bx, ds:[si].ODCVT_y4
		call	CoordToAscii
		mov	ax, ds:[si].ODCVT_x2
		mov	bx, ds:[si].ODCVT_y2
		call	CoordToAscii
		mov	ax, ds:[si].ODCVT_x3
		mov	bx, ds:[si].ODCVT_y3
		call	CoordToAscii
		mov	si, offset emitPCT
		mov	cx, length emitPCT
		jmp	copyOp
				
		; Hit a rel curveto.  Update current position and output coords
handleRelCurve:
		add	si, offset ODRCVT_x2	; ds:si -> points
		call	GrDrawRelCurveTo	; update curpos
		sub	si, offset ODRCVT_x2
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	ax, ds:[si].ODRCVT_x4	; output first rel coord
		mov	bx, ds:[si].ODRCVT_y4
		call	CoordToAscii
		mov	ax, ds:[si].ODRCVT_x2
		mov	bx, ds:[si].ODRCVT_y2
		call	CoordToAscii
		mov	ax, ds:[si].ODRCVT_x3
		mov	bx, ds:[si].ODRCVT_y3
		call	CoordToAscii
		mov	si, offset emitPRC
		mov	cx, length emitPRC
		jmp	copyOp

PathCurve		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Output PostScript code to draw an arc

CALLED BY:	INTERNAL
		EmitPath
PASS:		si	- gstring handle with opcode
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathArc		proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; get it.

		call	ExtractElement

		; output the coordinates

		cmp	{byte} ds:[si], GR_DRAW_ARC	; see if 3Point
		je 	normalArc

		; handle 3Point kind of stuff

		call	Convert3PointToNormalArc ; also outputs coords & such
		jmp	dArcCommon

		; normal arc.  We have all the info we need.
normalArc:
		mov	di, tgs.TGS_pathGState
		add	si, offset ODA_close	; ds:si -> ArcParams
		call	GrDrawArc		; get curpos up to date
		sub	si, offset ODA_close
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	bx, ds:[si].ODA_ang1	; put out the two angles
		call	SWordToAscii
		mov	al, ' '
		stosb
		mov	bx, ds:[si].ODA_ang2	
		call	SWordToAscii
		mov	al, ' '
		stosb
		mov	bx, ds:[si].ODA_x2
		call	XCoordToAsciiFar
		mov	al, ' '
		stosb
		mov	bx, ds:[si].ODA_x1
		call	XCoordToAsciiFar
		mov	al, ' '
		stosb
		mov	bx, ds:[si].ODA_y2
		call	YCoordToAsciiFar
		mov	al, ' '
		stosb
		mov	bx, ds:[si].ODA_y1
		call	YCoordToAsciiFar
		mov	al, ' '
		stosb
dArcCommon:
		mov	bx, ds:[si].ODA_close

		; finished with coords.  emit PS code and we're outta here

		shl	bx, 1
		mov	si, cs:pathArcString[bx]
		mov	cx, cs:pathArcStringLen[bx]
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		rep	movsb
		call	EmitBuffer
		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock

		.leave
		ret

PathArc		endp

pathArcString	label	nptr	
		word	offset emitCAPO
		word	offset emitCAPC
		word	offset emitCAPP

pathArcStringLen label	word
		word	length emitCAPO
		word	length emitCAPC
		word	length emitCAPP



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for GrDrawPolyline, GrDrawPolygon
		GrBrushPolyline, GrDrawSpline, GrDrawSplineTo

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			set transformation matrix code;
			<xn> <yn> <count> DPL

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathPolyline	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; get the whole element

		call	ExtractElement

		; output the coordinates

		push	bx
		mov	cx, ds:[si].ODPL_count	; get # coord pairs
		add	si, size OpDrawPolyline	; set ds:si -> points

		mov	di, tgs.TGS_pathGState
		call	EmitPolyCoords		; write out all the coords

		mov	bx, cx			; setup #points
		dec	bx
		call	UWordToAscii		; write out #coords

		; finished with coords.  emit PS code and we're outta here

		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		pop	ax			; restore opcode
		mov	si, offset emitPPG
		mov	cx, length emitPPG
		cmp	ax, (GR_DRAW_POLYGON-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitPS
		mov	cx, length emitPS
		cmp	ax, (GR_DRAW_SPLINE-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitPST
		mov	cx, length emitPST
		cmp	ax, (GR_DRAW_SPLINE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitPPL
		mov	cx, length emitPPL
copyString:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock

		.leave
		ret
		
PathPolyline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for ellipse fill

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set area attributes code;
			<x> <y> <x> <y> DL
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathEllipse	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; get it.

		call	ExtractElement

		; just output the coords.  We don't have to convert them..

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	ax, ds:[si].OFFR_x2	; for ellipse write out: x2 x1
		mov	bx, ds:[si].OFFR_x1
		call	CoordToAscii
		mov	ax, ds:[si].OFFR_y2	; ...then: y2 y1
		mov	bx, ds:[si].OFFR_y1	
		call	CoordToAscii

		; finished with coords.  emit PS code and we're outta here

		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitPE
		mov	cx, length emitPE
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock

		.leave
		ret
PathEllipse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for rectangle outline

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			<x> <y> <x> <y> DL

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathRect	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		call	ExtractElement

		mov	di, tgs.TGS_pathGState
		cmp	bx, (GR_DRAW_RECT_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	doRectTo
		call	CheckFullPageHack
		jc	doneRect
		mov	ax, ds:[si].ODR_x2	; do second endpoint first
		mov	bx, ds:[si].ODR_y2
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		mov	ax, ds:[si].ODR_x1	; do the other two too
		mov	bx, ds:[si].ODR_y1	; do the other two too
		call	CoordToAscii

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitPR
		mov	cx, length emitPR
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock
doneRect:
		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock

		.leave
		ret

		; opcode was GrDrawRectTo
doRectTo:
		call	GrGetCurPos		; get current position
		push	ax, bx			; save upper left corder
		mov	ax, ds:[si].ODRT_x2	; do second endpoint first
		mov	bx, ds:[si].ODRT_y2
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		pop	ax, bx			; do upper right corner
		call	CoordToAscii
		jmp	emitCode

PathRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFullPageHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a hack (but a well documented one :-)  to check
		for a full-page clip rectangle, in which case we want to 
		ignore it. 

CALLED BY:	INTERNAL
		PathRect
PASS:		ds:si	- points at OpDrawRect
		tgs	- inherited locals
RETURN:		carry	- set if we should ignore this element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFullPageHack		proc	far
		uses	es, ax
tgs		local	TGSLocals
		.enter	inherit

		; get size from options block and do checks

		cmp	tgs.TGS_pathType, GPT_CURRENT
		je	useIt				; OK if CURR (carryclr)
		mov	es, tgs.TGS_options
		tst	es:[PSEO_common].GEO_docW.high
		jnz	useIt
		tst	es:[PSEO_common].GEO_docW.high
		jnz	useIt
		mov	ax, es:[PSEO_common].GEO_docW.low ; width the same ?
		cmp	ax, ds:[si].ODR_x2		; check against right
		jne	useIt
		mov	ax, es:[PSEO_common].GEO_docH.low ; height the same ?
		cmp	ax, ds:[si].ODR_y2		; check against bottom
		jne	useIt
		tst	ds:[si].ODR_x1
		jnz	useIt
		tst	ds:[si].ODR_y1
		jz	dontUseIt
useIt:
		clc
exit:
		.leave
		ret

dontUseIt:
		stc
		dec	tgs.TGS_pathCnt			; discount this one
		jmp	exit
CheckFullPageHack		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for rounded rectangle outline

CALLED BY:	INTERNAL
		EmitPath

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			<x1+r> <y1+r> <x2-r> <y2-r> <r> DRR

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathRoundRect	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		call	ExtractElement

		; do the coords

		mov	di, tgs.TGS_pathGState
		cmp	bx, (GR_DRAW_ROUND_RECT_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	doRRectTo		; yes, already have first coord
		mov	ax, ds:[si].ODRR_x1	; fetch coords to check
		mov	bx, ds:[si].ODRR_y1
		mov	cx, ds:[si].ODRR_x2
		mov	dx, ds:[si].ODRR_y2
orderCoords:
		call	OrderRoundRectCoords
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		xchgdw	axbx, cxdx		; put out deltas first
		call	CoordToAscii
		mov	bx, si			; bx = radius
		call	UWordToAscii		; do radius
		mov	al, ' '
		stosb
		movdw	axbx, cxdx
		call	CoordToAscii

		; finished with coords.  emit PS code and we're outta here

		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitPRR
		mov	cx, length emitPRR
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock

		.leave
		ret

		; opcode was GrDrawRoundRectTo
doRRectTo:
		call	GrGetCurPos		; get current position
		mov	cx, ds:[si].ODRRT_x2
		mov	dx, ds:[si].ODRRT_y2
		jmp	orderCoords

PathRoundRect	endp

PathNothing	proc	near
		uses	cx, bx, ds, es, si
tgs		local	TGSLocals
		.enter inherit
		
		call	ExtractElement
		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock

		.leave
		ret
PathNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePathGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a temporary gstring for use in element processing

CALLED BY:	INTERNAL
		EmitBitmap, mostly
PASS:		tgs	- inherited local vars
RETURN:		di	- GState handle to temp GState
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreatePathGString	proc	near
		uses	ax, bx, cx, dx, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; clear out the path last matrix Tmatrix

		clr	ax
		segmov	es, ss, di
		lea	di, tgs.TGS_pathmatrix
		mov	cx, (size TransMatrix)/2
		rep	stosw

		; destroy any chunk that is there.
		; lock down our scratch block, clear out the scratch chunk

		mov	bx, tgs.TGS_chunk.handle
		call	MemLock			; 
		mov	ds, ax			; ds -> block

		clr	cx			; resize to zero
		mov	ax, tgs.TGS_pathchunk	; ax = chunk handle
		tst	ax			; if already zero, bail
		jz	unlockBlock
		call	LMemFree
unlockBlock:
		call	MemUnlock

		; first set up to draw into our buffer

		push	si			; save source GString handle
		mov	cl, GST_CHUNK		; it's a memory type gstring
		call	GrCreateGString		; di = gstring handle
		mov	tgs.TGS_pathchunk, si	; store new chunk
		pop	si			; restore source gstring

		mov	tgs.TGS_pathgs, di	;

		clr	di			; need a GState too, to keep
		call	GrCreateState		;  track of attrib, CurPos
		mov	tgs.TGS_pathGState, di

		.leave
		ret
CreatePathGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyPathGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Companion routine to CreatePathGString

CALLED BY:	INTERNAL
		EmitBitmap
PASS:		tgs	- locals
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyPathGString	proc	near
		uses	di, si
tgs		local	TGSLocals
		.enter	inherit

		; that's all we need, so biff the string

		mov	dl, GSKT_LEAVE_DATA	; don't kill the data
		mov	si, tgs.TGS_pathgs	; si = GString handle
		clr	di			; di = GState handle (0)
		call	GrDestroyGString
		
		clr	tgs.TGS_pathgs		; set to zero
		
		mov	di, tgs.TGS_pathGState
		call	GrDestroyState
		clr	tgs.TGS_pathGState

		.leave
		ret
DestroyPathGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathTextStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front routine for adding text to the current path

CALLED BY:	INTERNAL
		EmitPath
PASS:		si	- gstring
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathTextStub	proc	near
		call	EmitText
		ret
PathTextStub	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathTextFieldStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front routine for adding text to the current path

CALLED BY:	INTERNAL
		EmitPath
PASS:		si	- gstring
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathTextFieldStub	proc	near
		call	EmitTextField
		ret
PathTextFieldStub	endp

ExportPath	ends
