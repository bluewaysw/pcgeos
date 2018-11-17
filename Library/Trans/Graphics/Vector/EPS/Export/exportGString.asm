COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportGString.asm

AUTHOR:		Jim DeFrisco, 19 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
	TranslateGString	Do the main translation work

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision
    JMG 2/01        added code for pattern printing (PT_SYSTEM_HATCH only)

DESCRIPTION:
	This file contains the real part of the translation work
		

	$Id: exportGString.asm,v 1.1 97/04/07 11:25:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a Graphics String

CALLED BY:	INTERNAL
		TransExport

PASS:		si	- gstring handle for source
		cx	- flag to pass to GrDrawGString to control ending
			  (type GSControl)
		di	- handle of EPSExportLowStreamStruct
		es	- points to locked options block

RETURN:		ax	- error code as returned from GrDrawGString

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each output element in gstring:
		    get/write current attributes;
		    get/write current transform;
		    invoke proper procedure;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TranslateGString proc	near
		uses	bx, di, dx
		.enter

		mov	bx, di			; save stream block handle
		clr	di			; just need a bogus one
		call	GrCreateState
		xchg	bx, di			; get em lined up

		call	TranslateGStringCommon	; so we can use it internally

		mov	di, bx
		call	GrDestroyState		; release gstate

		.leave
		ret
TranslateGString endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateGStringCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a Graphics String

CALLED BY:	INTERNAL
		TransExport

PASS:		si	- gstring handle for source
		cx	- flag to pass to GrDrawGString to control ending
			  (type GSControl)
		di	- handle of EPSExportLowStreamStruct
		es	- points to locked options block
		bx	- gstate handle

RETURN:		ax	- error code as returned from GrDrawGString

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		for each output element in gstring:
		    get/write current attributes;
		    get/write current transform;
		    invoke proper procedure;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TranslateGStringCommon proc	far
		uses	bx, cx, di, dx, si, ds, es
tgs		local	TGSLocals
		
;; The following are used in the optimized EmitMonoBitmap which sends
;; mixed binary and hex ascii to the printer.  See EmitMonoBitmap for details.

count		local	word	
ForceRef count
				
start		local	word	
ForceRef start
writeProc	local	nptr	
ForceRef writeProc
				
bytesPerBuff	local	word	
ForceRef bytesPerBuff
buffsPerLine	local	word	
ForceRef buffsPerLine
originalBMWidth	local	word	
ForceRef originalBMWidth
bmWidthDiff	local	word	
ForceRef bmWidthDiff
buffCount	local	word
ForceRef buffCount
		.enter

		; save the arguments

		clr	ax
		mov	tgs.TGS_tempgs, ax	; no temp gstring to start
		mov	tgs.TGS_pathgs, ax	; no path gstring to start
		mov	tgs.TGS_writeErr, ax	; no error from StreamWrite
		mov	tgs.TGS_pathGState, ax	; no path gstring to start
		mov	tgs.TGS_gstate, bx	; save gstate handle
		mov	tgs.TGS_options, es	; save options block pointer
		mov	tgs.TGS_stream, di	; save the stream block handle
		mov	tgs.TGS_gstring, si	; save the gstring handle
		or	cx, mask GSC_OUTPUT or mask GSC_PATH	; need these 2
		mov	tgs.TGS_flags, cx	; save the flags
		mov	tgs.TGS_xfactor, 1	; assume TMatrix is OK
		mov	tgs.TGS_yfactor, 1	; assume TMatrix is OK
		mov	di, bx			; gstate handle in di

		; next, all the Emit{SomeObject} routines need some scratch
		; LMem space.  Allocate it here so they all don't have to 
		; allocate it themselves

		mov	ax, LMEM_TYPE_GENERAL		
		clr	cx
		call	MemAllocLMem			; get a block
		mov	tgs.TGS_chunk.handle, bx	; save block handle
		mov	tgs.TGS_pageFonts.handle, bx	; save block handle
		call	MemLock
		mov	ds, ax				; ds-> block
		clr	cx				; no space to start
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_chunk.chunk, ax		; save chunk handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_pathchunk, ax		; save chunk handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_xtrachunk, ax		; save xtra chunk han
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmRed.CC_chunk, ax	; save color handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmGreen.CC_chunk, ax	; save color handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmBlue.CC_chunk, ax	; save color handle
		mov	cx, 256*(size RGBValue)+(size Palette) ; alloc palette
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmPalette, ax		; save palette handle
		mov	cx, size PageFonts		; 
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_pageFonts.chunk, ax	; save chunk handle
		mov	bx, ax
		mov	bx, ds:[bx]
		clr	ds:[bx].PF_count		; no fonts to start
		mov	bx, tgs.TGS_chunk.handle	; save block handle
		call	MemUnlock			; unlock the block

		; scan string for fonts that the printer doesn't have

		call	GetPageFonts			; setup page font info
		call	DownloadPageFonts
;;;		jnc	fontsDownloaded
;;;
;;;		; couldn't download something, so return error
;;;
;;;		mov	ax, GSRT_FAULT
;;;		jmp	done
;;;
;;;fontsDownloaded:

		; scan the gstring for ouptut elements.  When we find one,
		; call a routine to emit the proper postscript code

		call	CreateTempGString		; create area to work
		clr	ax, bx				; start at beginning :)
		call	GrMoveTo
keepScanning:
		mov	dx, tgs.TGS_flags		; pass GSControl flags
		call	GrDrawGStringAtCP		; go until we hit one
		mov	ax, dx				; save return code

		; if it were a PATH type opcode, then enter another state.

		cmp	ax, GSRT_PATH
		LONG je	handlePath

		; if we're done with the page, exit.  If the last element in
		; the entire string is an output element, we will FAULT here,
		; so just map it to COMPLETE

		cmp	ax, GSRT_FAULT			; if some problem...
		jne	checkFormFeed			;  ...exit
		mov	ax, GSRT_COMPLETE		; map FAULT to COMPLETE
checkFormFeed:
		cmp	ax, GSRT_NEW_PAGE		; if at end of page..
		je	donePage			;  ...exit
		cmp	ax, GSRT_COMPLETE		; same if at end of 
		je	donePage			;  document

		; found an output code.  Do some range checking and call the
		; proper emit routine.

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
		call	cs:emitRouts[bx]		; call routine

		; before we go on, check out the next opcode.  Most likely
		; it's not something we're interested in, but you never know.

		mov	ax, tgs.TGS_emitRetType		; if done, leave
		cmp	ax, GSRT_COMPLETE
		je	donePage
		clr	cx				; just teasing
		call	GrGetGStringElement		; just want opcode
		mov	cl, al
		cmp	cl, GR_NEW_PAGE			; if new page, done
		je	preNewPage
		cmp	al, GSE_FIRST_OUTPUT_OPCODE	; see if in range
		jb	keepScanning
		cmp	al, GSE_LAST_OUTPUT_OPCODE	; output code ?
		jbe	handleOutput			;  yes, deal with it
		cmp	al, GSE_FIRST_PATH_OPCODE	; check path stuff too
		jb	keepScanning
		cmp	al, GSE_LAST_PATH_OPCODE
		jbe	handlePath
		jmp	keepScanning

		; all done, cleanup and leave
donePage:
		call	DestroyTempGString		; don't need it anymore

		mov	bx, tgs.TGS_chunk.handle	; free the scratch blk
		call	MemFree
	;
	; If no other error, but TGS_writeErr is non-zero, we ran into
	; trouble writing stuff out, so return GSRT_FAULT.
	; 
		cmp	ax, GSRT_FAULT
		je	exit
		tst	tgs.TGS_writeErr
		jz	exit
		mov	ax, GSRT_FAULT
exit:
		.leave
		ret

		; need to bump past the new page
preNewPage:
		mov	al, GSSPT_SKIP_1
		call	GrSetGStringPos
		mov	ax, GSRT_NEW_PAGE
		jmp	donePage

		; found a path opcode.  If it is BEGIN_PATH, then skip all
		; output elements until we hit END_PATH, else continue
handlePath:
		cmp	cl, GR_BEGIN_PATH		; if begin path...
		LONG jne keepScanning			;  then skip until we
							;  hit another path el
		mov	dx, mask GSC_PATH or mask GSC_NEW_PAGE
pathSkipLoop:
		clr	ax
		clr	bx
		call	GrDrawGString			; go until we hit one
		mov	ax, dx

		; see why we stopped.  If not a fault or complete, continue

		cmp	ax, GSRT_FAULT			; if some problem...
		jne	checkPathFormFeed			;  ...exit
		mov	ax, GSRT_COMPLETE		; map FAULT to COMPLETE
checkPathFormFeed:
		cmp	ax, GSRT_NEW_PAGE		; if at end of page..
		je	donePage			;  ...exit
		cmp	ax, GSRT_COMPLETE		; same if at end of 
		je	donePage			;  document

		; can only be a path thing at this point

		cmp	cl, GR_END_PATH			; searching for this
		jne	pathSkipLoop			;  keep looking til we
		jmp	keepScanning			;  find it.
				
TranslateGStringCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for GrDrawLine, GrDrawLineTo
		GrDrawHLine, GrDrawHLineTo, GrDrawVLine, GrDrawVLineTo

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set line attributes code;
			<x> <y> <x> <y> DL
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitDrawLine	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; first check for blank draw mask, so we don't draw nuthin

		call	CheckZeroLineMask
		LONG jc	done

		; first check for blank draw mask, so we don/t draw nothing
		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		clr	ax
		call	EmitStartStrokeStuff
		call	ExtractElement

		; output the coordinates

		mov	cx, bx			; save opcode
		mov	di, tgs.TGS_gstate
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
checkMask:
		call	CheckFullLineMask
		jc	emitCode
		call	EmitLineDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDL
		mov	cx, length emitDL
		call	CheckFullLineMask
		jc	copyOp
		mov	si, offset emitDML
		mov	cx, length emitDML
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock
done:
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
		mov	di, tgs.TGS_gstate
		call	GrMoveTo		; update the current position
		pop	di
		jmp	checkMask		; all done 
		
		; handle GR_DRAW_VLINE
vline:
		mov	ax, ds:[si].ODVL_x1	; get first coord
		mov	bx, ds:[si].ODVL_y1
		push	ax
		push	ds:[si].ODVL_y2		; save future coord
		jmp	outputPoints
		
EmitDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for GrDrawRelLineTo, GrDrawLineTo
		GrDrawHLineTo, GrDrawVLineTo

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set line attributes code;
			<x> <y> DLT
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitDrawLineTo	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		clr	ax
		call	EmitStartStrokeStuff
		call	ExtractElement

		; output the coordinates

		mov	cx, bx			; save opcode
		mov	di, tgs.TGS_gstate
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

		mov	si, offset emitDLT
		mov	cx, length emitDLT
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

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
		mov	di, tgs.TGS_gstate
		movwwf	dxcx, ds:[si].PF_x
		movwwf	bxax, ds:[si].PF_y
		call	GrDrawRelLineTo		; update the current position
		pop	di

		; finished with coords.  emit PS code and we're outta here

		mov	si, offset emitDRLT
		mov	cx, length emitDRLT
		jmp	emitCode
		
EmitDrawLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a curve

CALLED BY:	TranslateGString
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
EmitCurve		proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; first check for blank draw mask, so we don't draw nuthin

		call	CheckZeroLineMask
		LONG jc	done

		; first check for blank draw mask, so we don/t draw nothing
		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		clr	ax
		call	EmitStartStrokeStuff
		call	ExtractElement

		; output the coordinates

		mov	cx, bx			; save opcode
		mov	di, tgs.TGS_gstate
		call	GrGetCurPos		; get the current position
		cmp	cx, (GR_DRAW_CURVE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	haveFirst
		cmp	cx, (GR_DRAW_REL_CURVE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		LONG je	handleRelCurve
		mov	ax, ds:[si].ODCV_x1
		mov	bx, ds:[si].ODCV_y1
		add	si, 4			; bump over first coords
haveFirst:
		push	ax, bx			; save first coordinate
		mov	ax, ds:[si].ODCVT_x4	; do second endpoint first
		mov	bx, ds:[si].ODCVT_y4
		call	GrMoveTo		; update the current position
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		mov	ax, ds:[si].ODCVT_x2
		mov	bx, ds:[si].ODCVT_y2
		call	CoordToAscii
		mov	ax, ds:[si].ODCVT_x3
		mov	bx, ds:[si].ODCVT_y3
		call	CoordToAscii
		pop	ax, bx
		call	CoordToAscii

		call	CheckFullLineMask
		jc	emitCode
		call	EmitLineDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDC
		mov	cx, length emitDC
		call	CheckFullLineMask
		jc	copyOp
		mov	si, offset emitDMC
		mov	cx, length emitDMC
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock
done:
		.leave
		ret

		; Hit a rel curveto.  Update current position and output coords
handleRelCurve:
		add	si, offset ODRCVT_x2	; ds:si -> points
		push	di
		mov	di, tgs.TGS_gstate
		call	GrDrawRelCurveTo	; update curpos
		pop	di
		sub	si, offset ODRCVT_x2
		mov	ax, ds:[si].ODRCVT_x2	; output first rel coord
		mov	bx, ds:[si].ODRCVT_y2
		call	CoordToAscii
		mov	ax, ds:[si].ODRCVT_x3
		mov	bx, ds:[si].ODRCVT_y3
		call	CoordToAscii
		mov	ax, ds:[si].ODRCVT_x4
		mov	bx, ds:[si].ODRCVT_y4
		call	CoordToAscii
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDRC
		mov	cx, length emitDRC
		jmp	copyOp

EmitCurve		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Output PostScript code to draw an arc

CALLED BY:	INTERNAL
		TranslateGString
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
EmitDrawArc	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; first check for blank draw mask, so we don/t draw nothing
		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		call	CheckZeroLineMask
		LONG jc	done

		; emit preamble

		clr	ax
		call	EmitStartStrokeStuff

		; output the coordinates

		call	ExtractElement		; GString data -> ds:si
		call	CheckZeroScaleFactor
		jz	endObject
		cmp	{byte} ds:[si], GR_DRAW_ARC	; see if 3Point
		je 	normalArc

		; handle 3Point kind of stuff

		call	Convert3PointToNormalArc ; also outputs coords & such
		jmp	dArcCommon

		; normal arc.  We have all the info we need.
normalArc:
		mov	di, tgs.TGS_gstate
		add	si, offset ODA_close	; ds:si -> ArcParams
		call	GrDrawArc		; get curpos up to date
		sub	si, offset ODA_close
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	bx, ds:[si].ODA_ang1	; put out the two angles
		call	SWordPlusSpaceToAscii
		mov	bx, ds:[si].ODA_ang2	
		call	SWordPlusSpaceToAscii
		mov	bx, ds:[si].ODA_x2
		call	XCoordPlusSpaceToAscii
		mov	bx, ds:[si].ODA_x1
		call	XCoordPlusSpaceToAscii
		mov	bx, ds:[si].ODA_y2
		call	YCoordPlusSpaceToAscii
		mov	bx, ds:[si].ODA_y1
		call	YCoordPlusSpaceToAscii
dArcCommon:
		mov	bx, ds:[si].ODA_close
		call	CheckFullLineMask
		jc	emitCode
		call	EmitLineDrawMask
		add	bx, 3			; onto second set of strings

		; finished with coords.  emit PS code and we're outta here
emitCode:
		shl	bx, 1
		mov	si, cs:arcString[bx]
		mov	cx, cs:arcStringLen[bx]
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		rep	movsb
		call	EmitBuffer
		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup
endObject:
		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock
done:
		.leave
		ret

EmitDrawArc	endp

arcString	label	nptr	
		word	offset emitDAO
		word	offset emitDAC
		word	offset emitDAP
		word	offset emitDMAO
		word	offset emitDMAC
		word	offset emitDMAP
arcStringLen	label	word
		word	length emitDAO
		word	length emitDAC
		word	length emitDAP
		word	length emitDMAO
		word	length emitDMAC
		word	length emitDMAP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitFillArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Output PostScript code to fill an arc

CALLED BY:	INTERNAL
		TranslateGString
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
EmitFillArc	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; first check for blank draw mask, so we don/t draw nothing
		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		call	CheckZeroAreaMask
		LONG jc	done

		; output the preamble

		call	EmitStartObject		; write out info about object
		call	EmitTransform
		call	EmitAreaAttributes	; do the line attributes

		; output the coordinates

		call	ExtractElement		; GString data => DS:SI
		call	CheckZeroScaleFactor
		jz	endObject
		cmp	{byte} ds:[si], GR_DRAW_ARC	; see if 3Point
		je 	normalArc

		; do 3Point stuff

		call	Convert3PointToNormalArc
		jmp	fArcCommon

		; normal one, have all the info
normalArc:
		mov	di, tgs.TGS_gstate
		add	si, offset OFA_close
		call	GrFillArc		; get curpos up to date
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	bx, ds:[si].OFA_ang1	; put out the two angles
		call	SWordPlusSpaceToAscii
		mov	bx, ds:[si].OFA_ang2	
		call	SWordPlusSpaceToAscii
		mov	bx, ds:[si].OFA_x2
		call	XCoordPlusSpaceToAscii
		mov	bx, ds:[si].OFA_x1
		call	XCoordPlusSpaceToAscii
		mov	bx, ds:[si].OFA_y2
		call	YCoordPlusSpaceToAscii
		mov	bx, ds:[si].OFA_y1
		call	YCoordPlusSpaceToAscii
fArcCommon:
		mov	bx, ds:[si].OFA_close
		call	CheckFullAreaMask
		jc	emitCode
		call	EmitAreaDrawMask
		add	bx, 3			; onto second set of strings

		; finished with coords.  emit PS code and we're outta here
emitCode:
		shl	bx, 1
		mov	si, cs:farcString[bx]
		mov	cx, cs:farcStringLen[bx]
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		rep	movsb
		call	EmitBuffer
		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup
endObject:
		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock the coords block
		call	MemUnlock
done:
		.leave
		ret

EmitFillArc	endp

farcString	label	nptr	
		word	offset emitFAC
		word	offset emitFAC
		word	offset emitFAP
		word	offset emitFMAC
		word	offset emitFMAC
		word	offset emitFMAP
farcStringLen	label	word
		word	length emitFAC
		word	length emitFAC
		word	length emitFAP
		word	length emitFMAC
		word	length emitFMAC
		word	length emitFMAP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for GrDrawPolyline, GrDrawPolygon
		GrBrushPolyline, GrDrawSpline, GrDrawSplineTo

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set line attributes code;
			<xn> <yn> <count> DPL
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPolyline	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; first check for blank draw mask, so we don't draw nuthin

		call	CheckZeroLineMask
		LONG jc	done

		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		mov	ax, 1
		call	EmitStartStrokeStuff
		call	ExtractElement

		; output the coordinates

		push	bx
		mov	cx, ds:[si].ODPL_count	; get # coord pairs
		cmp	{byte} ds:[si], GR_BRUSH_POLYLINE
		jne	notBrush
		add	si, size OpBrushPolyline
		jmp	emitCoords
notBrush:
		add	si, size OpDrawPolyline	; set ds:si -> points
emitCoords:
		mov	di, tgs.TGS_gstate
		call	EmitPolyCoords		; write out all the coords

		mov	bx, cx			; setup #points
		dec	bx
		call	UWordToAscii		; write out #coords

		call	CheckFullLineMask
		jc	emitCode
		call	EmitLineDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		call	CheckFullLineMask
		pop	ax			; restore opcode
		jc	copyFillOp
		mov	si, offset emitDMPG
		mov	cx, length emitDMPG
		cmp	ax, (GR_DRAW_POLYGON-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitDMS
		mov	cx, length emitDMS
		cmp	ax, (GR_DRAW_SPLINE-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitDMST
		mov	cx, length emitDMST
		cmp	ax, (GR_DRAW_SPLINE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitDMPL
		mov	cx, length emitDMPL
		jmp	copyString
copyFillOp:
		mov	si, offset emitDPG
		mov	cx, length emitDPG
		cmp	ax, (GR_DRAW_POLYGON-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitDS
		mov	cx, length emitDS
		cmp	ax, (GR_DRAW_SPLINE-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitDST
		mov	cx, length emitDST
		cmp	ax, (GR_DRAW_SPLINE_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	copyString
		mov	si, offset emitDPL
		mov	cx, length emitDPL
copyString:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock
done:
		.leave
		ret
		
EmitPolyline	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for GrDrawPolyline

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set line attributes code;
			<xn> <yn> <count> FPW or FPO
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPolygon	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; check draw mask.  If anything but solid, skip the draw.  
		; Eventually, we'll write code to build out a bitmap to 
		; send down...

		call	CheckZeroAreaMask
		LONG jc	done

		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		call	EmitStartObject		; write out info about object
		call	EmitTransform
		call	EmitAreaAttributes	; do the line attributes

		; emit the code for the line

		call	ExtractElement		; extract it from the gstring

		; output the coordinates

		mov	cx, ds:[si].OFP_count	; get # coord pairs
		mov	al, ds:[si].OFP_rule	; save rul
		push	ax
		add	si, size OpFillPolygon	; set ds:si -> points

		mov	di, tgs.TGS_gstate
		call	EmitPolyCoords		; write out all the coords

		mov	bx, cx			; setup #points
		dec	bx
		call	UWordToAscii		; write out #coords

		call	CheckFullAreaMask
		jc	emitCode
		call	EmitAreaDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		pop	bx			; restore full rule
		call	CheckFullAreaMask
		jc	copyFullOp
		mov	si, offset emitFPMW	; assume winding
		mov	cx, length emitFPMW
		cmp	bl, RFR_WINDING		; check assumption
		je	copyString
		mov	si, offset emitFPMO	; must be odd-even
		mov	cx, length emitFPMO
		jmp	copyString

		; not doing mask - use full filled opcode
copyFullOp:
		mov	si, offset emitFPW
		mov	cx, length emitFPW
		cmp	bl, RFR_WINDING		; get the rule straight
		je	copyString
		mov	si, offset emitFPO
		mov	cx, length emitFPO
copyString:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup
		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock
done:
		.leave
		ret
		
EmitPolygon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPolyCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string of polygon coordinates

CALLED BY:	INTERNAL
		EmitPolyline, EmitPolygon

PASS:		cx	- # coords pairs to output
		ds:si	- pointer to coordinate values
		di	- GState to update curpos for

RETURN:		es:di	- points into tgs.TGS_buffer after last coord written

DESTROYED:	ax, bx, si

PSEUDO CODE/STRATEGY:
		loop through all coords, putting no more than five pairs on
		a given line.

		For 2.0 - put them out in the reverse order, so we can do 
		the right thing current position wise.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPolyCoords	proc	far
		uses	cx
tgs		local	TGSLocals
		.enter	inherit

		; last coord pair is at ds:si+((cx-1)*4)

		shl	cx, 1
		shl	cx, 1			; *4
		add	si, cx
		sub	si, 4
		shr	cx, 1			; restore cx
		shr	cx, 1

		; before we begin, set the current position

		mov	ax, ds:[si].P_x		; get next coord
		mov	bx, ds:[si].P_y
		call	GrMoveTo

		; we're ready to output the points, but put a newline in for
		; every four coordinates
		; set us up looking at the buffer

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer

coordLoop:
		mov	ax, ds:[si].P_x		; get next coord
		mov	bx, ds:[si].P_y
		call	CoordToAscii
		dec	cx			; one less to go
		jz	done

		sub	si, 4
		mov	ax, ds:[si].P_x		; get next coord
		mov	bx, ds:[si].P_y
		call	CoordToAscii
		dec	cx			; one less to go
		jz	done

		sub	si, 4
		mov	ax, ds:[si].P_x		; get next coord
		mov	bx, ds:[si].P_y
		call	CoordToAscii
		dec	cx			; one less to go
		jz	done

		sub	si, 4
		mov	ax, ds:[si].P_x		; get next coord
		mov	bx, ds:[si].P_y
		call	CoordToAscii
		dec	cx			; one less to go
		jz	done

		sub	si, 4
		mov	ax, ds:[si].P_x		; get next coord
		mov	bx, ds:[si].P_y
		call	CoordToAscii
		dec	cx			; one less to go

		; did four coordinate pairs, output a line feed

		push	cx, ds, si		; save coord pair
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitCRLF
		mov	cx, length emitCRLF
		rep	movsb
		call	EmitBuffer
		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock
		lea	di, tgs.TGS_buffer
		pop	cx, ds, si		; restore coord pair
		jcxz	done
		sub	si, 4
		jmp	coordLoop

		; finished all the coordinates, but before we leave, the last 
		; coordinate pair is in ax,bx, so set the current position
done:
		.leave
		ret
EmitPolyCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current path.

CALLED BY:	TranslateGString
PASS:		si	- GString handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmitDrawPath	proc	near
		uses	ax, si, di, ds, es, cx
tgs		local	TGSLocals
		.enter	inherit

		; first check for blank draw mask, so we don't draw nuthin

		call	CheckZeroLineMask
		jc	done

		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		call	EmitStartObject		; write out info about object
		mov	ax, 1
		call	EmitLineAttributes	; do the line attributes
		call	ExtractElement

		; output the path

		mov	ax, GPT_CURRENT
		call	EmitPath

		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDP
		mov	cx, length emitDP
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock		; release temp chunk block
done:
		.leave
		ret
		
EmitDrawPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitFillPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the current path.

CALLED BY:	TranslateGString
PASS:		si	- GString handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmitFillPath	proc	near
		uses	ax, si, di, ds, es, cx
tgs		local	TGSLocals
		.enter	inherit

		; first check for blank draw mask, so we don't draw nuthin

		call	CheckZeroAreaMask
		LONG jc	done

		; put in some comments to start off
		; save the current transformation matrix
		; set up the appropriate transform
		; set up the proper line attributes

		call	EmitStartObject		; write out info about object
		call	EmitAreaAttributes	; do the line attributes
		call	ExtractElement		; ds:si -> OpFillPath
		mov	al, ds:[si].OFP_rule	; get fill rule
		clr	ah
		push	ax			; save fill rule

		; output the path

		mov	ax, GPT_CURRENT
		call	EmitPath

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer
		call	CheckFullAreaMask
		jc	emitCode
		call	EmitAreaDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		pop	bx			; restore fill rule
		call	CheckFullAreaMask
		jc	copyFullOp
		mov	si, offset emitFPMWind	; assume winding
		mov	cx, length emitFPMWind
		cmp	bl, RFR_WINDING		; check assumption
		je	copyOp
		mov	si, offset emitFPMOdd	; must be odd-even
		mov	cx, length emitFPMOdd
		jmp	copyOp

		; not doing mask - use full filled opcode
copyFullOp:
		mov	si, offset emitFPOdd
		mov	cx, length emitFPOdd
		cmp	bl, RFR_ODD_EVEN
		je	copyOp
		mov	si, offset emitFPWind
		mov	cx, length emitFPWind
copyOp:		
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock		; release temp chunk block
done:
		.leave
		ret
		
EmitFillPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitStartStrokeStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for each stroke-type object

CALLED BY:	EmitDrawLine...

PASS:		si	- gstring handle
		bx	- element, as passed from TranslateGString
		ax	- zero if only drawing a single line, else non-zero
			  for polyline-type objects

RETURN:		nothing

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		write out the StartObject comment
		save the current transformation matrix
		output the current transform
		output the line attributes
		extract the element from the gstring

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitStartStrokeStuff	proc	far
		uses	ds, si, bx
tgs		local	TGSLocals
		.enter	inherit

		push	ax
		call	EmitStartObject		; write out info about object
		call	EmitTransform
		pop	ax			; restore single line flag
		call	EmitLineAttributes	; do the line attributes

		.leave
		ret
EmitStartStrokeStuff	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CoordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a coordinate value to ascii

CALLED BY:	all EmitXXXXX routines

PASS:		ax, bx	- coordinate value to writE
		es:di	- pointer to buffer to write ascii into
			  NOTE: buffer is assumed to have at least 12 chars

RETURN:		es:di	- points to byte after last char written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		translate x then translate y

		this routine adds a space character between the numbers and
		after the 2nd one

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CoordToAscii	proc	far
		uses	ax
tgs		local	TGSLocals
		.enter	inherit
		xchg	ax, bx			; save x2 first
		call	XCoordToAscii
		mov	bx, ax			; now do y2
		mov	al, ' '
		stosb
		call	YCoordToAscii
		stosb
		.leave
		ret
CoordToAscii	endp

XCoordToAsciiFar proc	far
		call	XCoordToAscii
		ret
XCoordToAsciiFar endp

XCoordPlusSpaceToAscii	proc	near
		call	XCoordToAscii
		mov	al, ' '
		stosb
		ret
XCoordPlusSpaceToAscii	endp		

XCoordToAscii	proc	near
tgs		local	TGSLocals
		.enter	inherit
		tst	tgs.TGS_xfactor		; check to see what it is
		jnz	xOK
		clr	bx
xOK:
		call	SWordToAscii		; save coordinate value
		.leave
		ret
XCoordToAscii	endp

YCoordToAsciiFar proc	far
		call	YCoordToAscii
		ret
YCoordToAsciiFar endp

YCoordPlusSpaceToAscii	proc	near
		call	YCoordToAscii
		mov	al, ' '
		stosb
		ret
YCoordPlusSpaceToAscii	endp		

YCoordToAscii	proc	near
tgs		local	TGSLocals
		.enter	inherit
		tst	tgs.TGS_yfactor		; check to see what it is
		jnz	yOK
		clr	bx
yOK:
		call	SWordToAscii		; save coordinate value
		.leave
		ret
YCoordToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WWFCoordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a WWFixed coordinate value to ascii

CALLED BY:	some EmitXXXXX routines

PASS:		ds:si	- pointer to PointWWFixed structure
		es:di	- pointer to buffer to write ascii into
			  NOTE: buffer is assumed to have at least 12 chars

RETURN:		es:di	- points to byte after last char written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		translate x then translate y

		this routine adds a space character between the numbers and
		after the 2nd one

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WWFCoordToAscii	proc	far
		uses	ax, bx
tgs		local	TGSLocals
		.enter	inherit

		movwwf	bxax, ds:[si].PF_x
		tst	tgs.TGS_xfactor		; check to see what it is
		jnz	xOK
		clr	bx, ax
xOK:
		call	WWFixedToAscii		; save coordinate value
		mov	al, ' '
		stosb
		movwwf	bxax, ds:[si].PF_y
		tst	tgs.TGS_yfactor		; check to see what it is
		jnz	yOK
		clr	bx, ax
yOK:
		call	WWFixedToAscii		; save coordinate value
		stosb
		.leave
		ret
WWFCoordToAscii	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for rectangle outline

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set line attributes code;
			<x> <y> <x> <y> DL
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitDrawRect	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		call	CheckZeroLineMask
		jc	done

		; put in some comments to start off
		; set up the appropriate transform
		; set up the proper line attributes

		mov	ax, 1
		call	EmitStartStrokeStuff
		call	ExtractElement
		; we need to convert the coordinates ourselves, since under
		; PC/GEOS, the line width does not scale with the GState.  
		; Yeah, it's a bummer (but our way is better...)

		mov	di, tgs.TGS_gstate
		cmp	bx, (GR_DRAW_RECT_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	doRectTo
		mov	ax, ds:[si].ODR_x2	; do second endpoint first
		mov	bx, ds:[si].ODR_y2
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		mov	ax, ds:[si].ODR_x1	; do the other two too
		mov	bx, ds:[si].ODR_y1	; do the other two too
		call	CoordToAscii

checkMask:
		call	CheckFullLineMask
		jc	emitCode
		call	EmitLineDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDR
		mov	cx, length emitDR
		call	CheckFullLineMask
		jc	copyOp
		mov	si, offset emitDMR
		mov	cx, length emitDMR
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock
done:
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
		jmp	checkMask

EmitDrawRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitFillRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for rectangle fill

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

EmitFillRect	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; check draw mask.  If anything but solid, skip the draw.  
		; Eventually, we'll write code to build out a bitmap to 
		; send down...

		call	CheckZeroAreaMask
		LONG jc	done

		; put in some comments to start off
		; set up the appropriate transform
		; set up the proper line attributes

		push	bx			; save opcode
		call	EmitStartObject		; write out info about object
		call	EmitTransform
		call	EmitAreaAttributes	; do the line attributes

		; emit the code for the line

		call	ExtractElement		; extract it from the gstring

		pop	bx

		; just output the coords.  We don't have to convert them..

		mov	di, tgs.TGS_gstate
		cmp	bx, (GR_FILL_RECT-GSE_FIRST_OUTPUT_OPCODE)*2
		jne	wierdOpcode
		mov	ax, ds:[si].OFFR_x2	; do second endpoint first
		mov	bx, ds:[si].OFFR_y2
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		mov	ax, ds:[si].OFFR_x1	; do the other two too
		mov	bx, ds:[si].OFFR_y1	; do the other two too
		call	CoordToAscii
checkMask:
		call	CheckFullAreaMask
		jc	emitCode
		call	EmitAreaDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitFR
		mov	cx, length emitFR
		call	CheckFullAreaMask
		jc	copyOp
		mov	si, offset emitFMR
		mov	cx, length emitFMR
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock
done:
		.leave
		ret

		; something besides FILL_RECT.  handle it.
wierdOpcode:
		cmp	bx, (GR_DRAW_POINT_CP-GSE_FIRST_OUTPUT_OPCODE)*2
		je	doPointCP
		cmp	bx, (GR_DRAW_POINT-GSE_FIRST_OUTPUT_OPCODE)*2
		je	doPoint

		; opcode was GrFillRectTo

		call	GrGetCurPos		; get current position
		push	ax,bx
		mov	ax, ds:[si].OFFRT_x2	; do second endpoint first
		mov	bx, ds:[si].OFFRT_y2
rectToCommon:
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		call	CoordToAscii
		pop	ax, bx 			; do the other two too
		call	CoordToAscii
		jmp	checkMask

		; opcode was GrDrawPointAtCP
doPointCP:
		call	GrGetCurPos
		jmp	doPointCommon

		; opcode was GrDrawPoint
doPoint:
		mov	ax, ds:[si].ODP_x1
		mov	bx, ds:[si].ODP_y1
doPointCommon:
		push	ax,bx
		inc	ax
		inc	bx
		jmp	rectToCommon
EmitFillRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for rounded rectangle outline

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set line attributes code;
			<x1+r> <y1+r> <x2-r> <y2-r> <r> DRR
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitDrawRoundRect	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		call	CheckZeroLineMask
		LONG jc	done

		; put in some comments to start off
		; set up the appropriate transform
		; set up the proper line attributes

		mov	ax, 1
		call	EmitStartStrokeStuff
		call	ExtractElement

		; do the coords

		mov	di, tgs.TGS_gstate
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

		call	CheckFullLineMask
		jc	emitCode
		call	EmitLineDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDRR
		mov	cx, length emitDRR
		call	CheckFullLineMask
		jc	copyOp
		mov	si, offset emitDMRR
		mov	cx, length emitDMRR
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock
done:
		.leave
		ret

		; opcode was GrDrawRoundRectTo
doRRectTo:
		call	GrGetCurPos		; get current position
		mov	cx, ds:[si].ODRRT_x2
		mov	dx, ds:[si].ODRRT_y2
		jmp	orderCoords

EmitDrawRoundRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitFillRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create PostScript code for rectangle fill

CALLED BY:	TranslateGString

PASS:		si	- gstring handle

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		emit in the following order:
			StartObject code;
			set transformation matrix code;
			set area attributes code;
			<r> <dx/2-r> <dy/2-r> <xc> <yc> FRR
			EndObject code;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitFillRoundRect	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; check draw mask.  If anything but solid, skip the draw.  
		; Eventually, we'll write code to build out a bitmap to 
		; send down...

		call	CheckZeroAreaMask
		LONG jc	done

		; put in some comments to start off
		; set up the appropriate transform
		; set up the proper line attributes

		push	bx			; save opcode
		call	EmitStartObject		; write out info about object
		call	EmitTransform
		call	EmitAreaAttributes	; do the line attributes

		; emit the code for the line

		call	ExtractElement		; extract it from the gstring

		pop	bx

		; just output the coords.  We don't have to convert them..

		mov	di, tgs.TGS_gstate
		cmp	bx, (GR_FILL_ROUND_RECT_TO-GSE_FIRST_OUTPUT_OPCODE)*2
		je	doRRectTo
		mov	ax, ds:[si].OFRR_x1	; fetch coords to check
		mov	bx, ds:[si].OFRR_y1
		mov	cx, ds:[si].OFRR_x2
		mov	dx, ds:[si].OFRR_y2
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

		call	CheckFullAreaMask
		jc	emitCode
		call	EmitAreaDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitFRR
		mov	cx, length emitFRR
		call	CheckFullAreaMask
		jc	copyOp
		mov	si, offset emitFMRR	
		mov	cx, length emitFMRR
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock
done:
		.leave
		ret

		; opcode was GrFillRoundRectTo
doRRectTo:
		call	GrGetCurPos		; get current position
		mov	cx, ds:[si].OFRRT_x2
		mov	dx, ds:[si].OFRRT_y2
		jmp	orderCoords
EmitFillRoundRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OrderRoundRectCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function orders the rounded rect coordinates, so
		that the path is created correctly.

CALLED BY:	INTERNAL
		Emit{Fill,Draw}RoundRect
PASS:		ds:si	- pointer to GString element
		ax...dx	- x1,y1,x2,y2
		di	- GState handle
RETURN:		ax,bx	- center of RoundRect
		cx	- x offset from RR center to center of corner arc
		dx	- y offset from RR center to center of corner arc
		si	- radius of corner arcs
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Transform the coords by the current GState
		Order them (based on device values) to (xmin,ymin) to 
						       (xmax,ymax)


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OrderRoundRectCoords		proc	far
		uses	di
		.enter

		; calc center of rect and half-widths

		mov	si, ds:[si].ODRR_radius	; in same place for all opcodes
		sub	cx, ax			; cx = deltaX
		sar	cx, 1			; cx = deltaX/2
		add	ax, cx			; ax = center of rect (X)
		sub	dx, bx			; dx = deltaY
		sar	dx, 1			; dx = deltaY/2
		add	bx, dx			; bx = center of rect (Y)

		; need abs value of half-widths
	
		tst	cx			; do X first
		jns	doYHalfW		;  OK, onto Y
		neg	cx
doYHalfW:
		tst	dx			; do Y next
		jns	checkRadius
		neg	dx

		; Make sure the radius is within bounds.
checkRadius:
		cmp	cx, si			; must be greater
		jge	radiusX
		mov	si, cx			; set to half deltaX
radiusX:
		cmp	dx, si			; radius > delta Y ?
		jge	done			;  no, done
		mov	si, dx			; set to half deltaY

		; subtract radius from half-widths 
done:
		sub	cx, si
		sub	dx, si

		.leave
		ret
OrderRoundRectCoords		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckZeroAreaMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- set if draw mask is zero.  Element passed already.

DESTROYED:	al

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckZeroAreaMask	proc	far
		uses	di
tgs		local	TGSLocals
		.enter	inherit

		; check draw mask.  If anything but solid, skip the draw.  
		; Eventually, we'll write code to build out a bitmap to 
		; send down...

		mov	di, tgs.TGS_gstate	; get gstate handle
		mov	al, GMT_ENUM	; get the mask number
		call	GrGetAreaMask		; al = mask enum
		cmp	al, SDM_0		; 0% mask ?
		clc				; assume it isn't
		jne	done
		call	EmitNothing		; skip this element
		stc				; signal it is
done:
		.leave
		ret
CheckZeroAreaMask	endp

CheckFullAreaMask	proc	far
		uses	ax,bx,cx,di
tgs		local	TGSLocals
		.enter	inherit

		; check draw mask and draw pattern.  
		; return carry set if solid mask and pattern.

		mov	di, tgs.TGS_gstate	; get gstate handle
		mov	al, GMT_ENUM	; get the mask number
		call	GrGetAreaMask		; al = mask enum
		cmp	al, SDM_100		; 0% mask ?
		clc				; assume it isn't
		jne	done
		mov	di, tgs.TGS_gstate	; get gstate handle
		call	GrGetAreaPattern
		cmp al, PT_SOLID
		clc
		jne	done
		stc				; signal it is
done:
		.leave
		ret
CheckFullAreaMask	endp


CheckZeroLineMask	proc	far
		uses	di
tgs		local	TGSLocals
		.enter	inherit

		; check draw mask.  If anything but solid, skip the draw.  
		; Eventually, we'll write code to build out a bitmap to 
		; send down...

		mov	di, tgs.TGS_gstate	; get gstate handle
		mov	al, GMT_ENUM	; get the mask number
		call	GrGetLineMask		; al = mask enum
		cmp	al, SDM_0		; 0% mask ?
		clc				; assume it isn't
		jne	done
		call	EmitNothing		; skip this element
		stc				; signal it is
done:
		.leave
		ret
CheckZeroLineMask	endp

CheckFullLineMask	proc	far
		uses	di
tgs		local	TGSLocals
		.enter	inherit

		; if we've set the flag saying we're doing full mask no
		; matter what, handle it.  See the routine EmitLineAttributes
		; for a description of why this flag is used.

		tst	tgs.TGS_bmType
		stc				; assume flag set
		jnz	done			; if flag non-zero, use solid

		; check draw mask.  return carry set if solid mask.

		mov	di, tgs.TGS_gstate	; get gstate handle
		mov	al, GMT_ENUM	; get the mask number
		call	GrGetLineMask		; al = mask enum
		cmp	al, SDM_100		; 0% mask ?
		stc				; assume it isn't
		je	done
		clc				; signal it is
done:
		.leave
		ret
CheckFullLineMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckZeroScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if both scale factors are zero

CALLED BY:	INTERNAL
		EmitDrawArc, EmitFillArc

PASS:		local	= TGSLocals

RETURN:		Z	= Set if scale factors in X & Y are both zero

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/28/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckZeroScaleFactor	proc	near
tgs		local	TGSLocals
		.enter	inherit
	
		tst	tgs.TGS_xfactor
		jnz	done
		tst	tgs.TGS_yfactor
done:		
		.leave
		ret
CheckZeroScaleFactor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a draw mask

CALLED BY:	INTERNAL
		EmitFillRect

PASS:		es:di	- point to buffer where to put mask array

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		writes an array of strings that looks like:

		" [(ff)(ff)(ff)(ff)(ff)(ff)(ff)(ff)]"

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitLineDrawMask proc	near
		uses	ax, bx, cx, dx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		; get the mask into a buffer.  just alllcate a quick one

		push	ds, si
		segmov	ds, ss, si
		sub	sp, size DrawMask
		mov	si, sp
		mov	al, GMT_BUFFER
		push	di
		mov	di, tgs.TGS_gstate
		call	GrGetLineMask		; get mask 
		pop	di
		call	EmitDrawMask
		add	sp, size DrawMask
		pop	ds, si

		.leave
		ret
EmitLineDrawMask endp


COMMENT @%
SystemHatch		etype byte
 SH_VERTICAL				enum SystemHatch					; vertical lines
 SH_HORIZONTAL				enum SystemHatch					; horizontal lines
 SH_45_DEGREE				enum SystemHatch					; lines at 45 degrees
 SH_135_DEGREE				enum SystemHatch					; lines at 135 degrees
 SH_BRICK				enum SystemHatch					; basic brick
 SH_SLANTED_BRICK				enum SystemHatch					; basic brick, slanted

%@

EmitAreaDrawMask proc	near
		uses	ax, bx, cx, dx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		; get the mask into a buffer.  just alllcate a quick one

		push	ds, si

		segmov	ds, ss, si
		sub	sp, size DrawMask
		mov	si, sp
		mov	al, GMT_BUFFER
		push	di
		mov	di, tgs.TGS_gstate
		call	GrGetAreaMask		; get mask 
		mov	di, tgs.TGS_gstate	; get gstate handle
		call	GrGetAreaPattern
		cmp al, PT_SYSTEM_HATCH
        jne cont
        
        ; add system pattern to draw mask.
        ; this is a hack, the real system pattern isn't 8x8 bit, but better than a solid object.
        
        push    bx,bp
        clr bx
        clr bp
        mov bl,ah
        shl bl,3
        mov cx,8
hashlp: mov al,ds:[si+bp]
        and al,cs:hatches[bx]
        mov ds:[si+bp],al
        inc bx
        inc bp
        loop hashlp
        
        pop bx,bp
cont:	pop	di
		call	EmitDrawMask
		add	sp, size DrawMask
		pop	ds, si

		.leave
		ret
EmitAreaDrawMask endp
        
hatches db  0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88 ;   SH_VERTICAL
        db  0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00 ;   SH_HOTIZONTAL
        db  0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01 ;   SH_45_DEGREE
        db  0x08,0x10,0x20,0x40,0x80,0x01,0x02,0x04 ;   SH_135_DEGREE
        db  0x80,0x80,0x80,0xff,0x08,0x08,0x08,0xff ;   SH_BRICK
        db  0x80,0x40,0x20,0x50,0x88,0x05,0x02,0x01 ;   SH_SLANTED_BRICK
        
        
EmitDrawMask	proc	near
		uses	ax, bx, cx, dx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		mov	al, ' '			; write a space and a left
		mov	ah, '['			;  bracket
		stosw
		mov	al, '('
		stosb
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, '('
		stosw
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, '('
		stosw
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, '('
		stosw
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, '('
		stosw
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, '('
		stosw
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, '('
		stosw
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, '('
		stosw
		lodsb	
		call	EmitMaskByte		; convert all eight bytes
		mov	al, ')'
		mov	ah, ']'			; closing bracket
		stosw

		.leave
		ret
EmitDrawMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitMaskByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a byte as a series of octal escapes

CALLED BY:	EmitDrawMask

PASS:		al	- byte to write
		es:di	- where to write it

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if the byte is between ESC and ~, just copy it.  else write
		it out as an octal digit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitMaskByte	proc	near
tgs		local	TGSLocals
		.enter	inherit

		cmp	al, C_ESCAPE		; is it ok just to write it ?
		jb	writeOctal		;  no, do octal
		cmp	al, C_ASCII_TILDE	; check high end
		ja	writeOctal
		stosb				; ok to just write it
		stosb				; write it twice for 16 bits
done:
		.leave
		ret

		; write out octal representation
writeOctal:
		push	bx			; save reg
		mov	ah, al			; save digit
		mov	al, C_BACKSLASH		; write out backslash
		stosb
		mov	bl, ah			; compute first digit
		and	bx, 0xc0		; high two digits
		shr	bx, 1			; get two bits down
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		mov	al, cs:maskOctal[bx]	; get digit
		stosb
		mov	bl, ah			; get next three
		and	bl, 0x38
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		mov	al, cs:maskOctal[bx]
		stosb
		mov	bl, ah			; last one
		and	bl, 7			; low three bits
		mov	al, cs:maskOctal[bx]
		stosb
		mov	al, C_BACKSLASH		; write it again
		stosb
		mov	al, es:[di-4]		; copy three digits
		stosb
		mov	al, es:[di-4]		; copy three digits
		stosb
		mov	al, es:[di-4]		; copy three digits
		stosb
		pop	bx
		jmp	done

EmitMaskByte	endp

maskOctal	char	"01234567"

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitFillEllipse
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

EmitFillEllipse	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		call	CheckZeroAreaMask
		jc	done

		; put in some comments to start off
		; set up the appropriate transform
		; set up the proper line attributes

		call	EmitStartObject		; write out info about object
		call	EmitTransform
		call	EmitAreaAttributes	; do the line attributes

		; emit the code for the line

		call	ExtractElement		; extract it from the gstring

		; just output the coords.  We don't have to convert them..

		mov	di, tgs.TGS_gstate
		mov	ax, ds:[si].OFFR_x2	; do second endpoint first
		mov	bx, ds:[si].OFFR_y2
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	bx, ds:[si].OFFR_x1	; for ellipse write out: x2 x1
		call	CoordToAscii
		mov	ax, ds:[si].OFFR_y2	; ...then: y2 y1
		mov	bx, ds:[si].OFFR_y1	
		call	CoordToAscii

		call	CheckFullAreaMask
		jc	emitCode
		call	EmitAreaDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitFE
		mov	cx, length emitFE
		call	CheckFullAreaMask
		jc	copyOp
		mov	si, offset emitFME
		mov	cx, length emitFME
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock

done:
		.leave
		ret
EmitFillEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawEllipse
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

EmitDrawEllipse	proc	near
		uses	ax, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		call	CheckZeroLineMask
		jc	done

		; put in some comments to start off
		; set up the appropriate transform
		; set up the proper line attributes

		mov	ax, 1
		call	EmitStartStrokeStuff
		call	ExtractElement

		; just output the coords.  We don't have to convert them..

		mov	di, tgs.TGS_gstate
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		mov	ax, ds:[si].OFFR_x2
		mov	bx, ds:[si].OFFR_x1	; for ellipse write out: x2 x1
		call	CoordToAscii
		mov	ax, ds:[si].OFFR_y2	; ...then: y2 y1
		mov	bx, ds:[si].OFFR_y1	
		call	CoordToAscii

		call	CheckFullLineMask
		jc	emitCode
		call	EmitLineDrawMask

		; finished with coords.  emit PS code and we're outta here
emitCode:
		mov	bx, handle PSCode	; emit opcode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDE
		mov	cx, length emitDE
		call	CheckFullLineMask
		jc	copyOp
		mov	si, offset emitDME
		mov	cx, length emitDME
copyOp:
		rep	movsb
		call	EmitBuffer

		mov	bx, handle PSCode	; unlock the resource
		call	MemUnlock

		; all done, cleanup

		call	EmitEndObject		; all done, cleanup

		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock
done:
		.leave
		ret
EmitDrawEllipse	endp


EmitNothing	proc	near
		uses	cx, bx, ds, es, si
tgs		local	TGSLocals
		.enter inherit
		
		call	ExtractElement
		mov	bx, tgs.TGS_chunk.handle ; unlock coords block
		call	MemUnlock

		.leave
		ret
EmitNothing	endp

EmitTextFieldStub proc	near
		call	EmitTextField
		ret
EmitTextFieldStub endp

EmitTextStub proc	near
		call	EmitText
		ret
EmitTextStub endp

EmitBitmapStub proc	near
		call	EmitBitmap
		ret
EmitBitmapStub endp


ExportCode	ends
