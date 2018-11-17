COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert Library
FILE:		convertGString.asm

AUTHOR:		Jim DeFrisco, Oct 12, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/12/92		Initial revision

DESCRIPTION:
	Implement function to transform 1.X graphics strings into 2.X
	HugeArray based graphics strings.
		
	$Id: convertGString.asm,v 1.1 97/04/04 17:52:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GStringCode	segment	resource

GSFrame	struct
    GSF_options		GSConvertOptions
    GSF_sourceVMfile	word
    GSF_targetGString	hptr.GState
    GSF_thisVMblock	word
    GSF_memVMblock	word
    GSF_sliceStart	word		; start of last bitmap slice
    GSF_kernRoutine	fptr
    GSF_errorCode	GSConvertStatus
    GSF_dataSize	word
    GSF_styleRunPtr	word
    GSF_origStyleRunPtr	word
    GSF_GDFVars		GDF_vars
GSFrame	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a VM-based 1.X GString to a HugeArray-based 2.X GString

CALLED BY:	GLOBAL
PASS:		cx:di	- VM file/VM block handle of source GString
		dx	- VM file handle of destination file
		si	- GSConvertOptions
RETURN:		carry	- set on failure
		ax	- GSConvertStatus enum
		dx:di	- VM file/VM block handle of converted 2.X GString
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Interpret the input, call graphics functions to produce 
		output.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function assumes the VM file has already been converted.
		Obviously, this only supports VM-based 1.X GStrings.  
		Other UNSUPPORTED items:
			* embedded graphics in GrDrawTextField elements
			* tab leaders in GrDrawTextField elements
			* GString parameters
			* Arcs and rounded rectangles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertGString		proc	far
		uses	dx, cx, si, ds, bx
gsf		local	GSFrame
		.enter

		; save some of the arguments

		mov	gsf.GSF_sourceVMfile, cx	
		mov	gsf.GSF_thisVMblock, di
		mov	gsf.GSF_errorCode, GSCS_NO_ERROR
		mov	gsf.GSF_options, si

		; we want ds:si pointing at the source GString.  Lock down
		; the first block and get started...  Since we're gonna free
		; the block when we're done, we don't need to save the memHan

		push	bp
		mov	bx, cx
		mov	ax, di			; bx:ax = VM file/block handle
		call	VMLock			
		mov	ds, ax			; ds -> block
		mov	si, bp			; si = mem handle
		pop	bp
		mov	gsf.GSF_memVMblock, si	; save handle for unlock later

		; create GString we are to return

		mov	cl, GST_VMEM		; creating HugeArray type
		mov	bx, dx			; bx = VM file handle
		call	GrCreateGString		; si = target VM block handle
		push	bx, si			; save return values
		mov	gsf.GSF_targetGString, di	; save destination
		mov	si, 4			; restore off (past blk/size)

		; Loop through the elements, interpreting as we go, until
		; we hit the end of the string.  Handle going to the next block
		; as well.

elemLoop:
		call	PlayElement		; play the current element 
		jnc	elemLoop		; go till we're done.

		; all done or error, destroy the GString structure for the 
		; new GString and then restore the new VM file/block handles.

		mov	si, di			; GString to destroy
		mov	dl, GSKT_LEAVE_DATA
		cmp	gsf.GSF_errorCode, GSCS_NO_ERROR
		jne	returnError	
		call	GrDestroyGString
		clc				; no errors at this time

done:		
		mov	ax, gsf.GSF_errorCode	; return error code
		pop	dx, di			; restore VM file/block handle
		.leave
		ret

		; some error.  Destroy the whole string (including data)
returnError:
		mov	dl, GSKT_KILL_DATA
		call	GrDestroyGString
		stc
		jmp	done
ConvertGString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlayElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the next 1.X graphics string element

CALLED BY:	INTERNAL
		ConvertGString
PASS:		ds:si	- pointer to element to play
		inherits stack frame
RETURN:		carry	- set if done with GString, else:
				ds:si	- points to next element to play
DESTROYED:	nothign

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlayElement	proc	near
gsf		local	GSFrame
		.enter	inherit

		lodsb			; grab the opcode
		clr	ah
		mov	bx, ax		; make it a word
		shl	bx, 1		; call specific routine
		shl	bx, 1		; call specific routine
		mov	ax, cs:KernRoutTable[bx].offset 
		mov	gsf.GSF_kernRoutine.offset, ax
		mov	ax, cs:KernRoutTable[bx].segment 
		mov	gsf.GSF_kernRoutine.segment, ax
		shr	bx, 1			; call specific routine
		call	cs:PlayElemTable[bx]
		jc	done			; quit on error

		; ds:si -> after element we just played.  See if we're past
		; the end of the block...

		cmp	si, ds:[2]		; see if over block
		jae	nextBlock		;  else next block, free this 1
doneOK:
		clc
done:
		.leave
		ret

		; past the end of the current block, get next one if there is
		; kill the current block first
nextBlock:
		push	ds:[0]			; save link to next block
		mov	bx, gsf.GSF_sourceVMfile
		test	gsf.GSF_options, mask GSCO_FREE_ORIG_GSTRING
		jz	unlockInstead
		mov	ax, gsf.GSF_thisVMblock
		call	VMFree			; free the current block
checkNextBlock:
		pop	ax
		tst	ax
		jnz	lockNextBlock
		stc				; signal all finished
		jmp	done
lockNextBlock:
		mov	gsf.GSF_thisVMblock, ax	; store new block handle
		push	bp
		call	VMLock			; lock the next block
		mov	si, bp			; need to save mem handle
		pop	bp
		mov	gsf.GSF_memVMblock, si	; save mem handle
		mov	ds, ax			; reload pointer
		mov	si, 4			; skip over link/size
		jmp	doneOK

unlockInstead:
		push	bp
		mov	bp, gsf.GSF_memVMblock
		call	VMUnlock
		pop	bp
		jmp	checkNextBlock
PlayElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallKernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate kernel graphics routine

CALLED BY:	all PEXXXXX routines

PASS:		es	- GString structure

RETURN:		depends on kernel routine

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call ProCallFixedOrMovable

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine became necessary when some of the kernel graphics
		routines moved out of fixed memory.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallKernel proc	near
gsf		local	GSFrame
		.enter	inherit
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		movdw	bxax, gsf.GSF_kernRoutine
		call	ProcCallFixedOrMovable
		clc
		.leave
		ret
CallKernel endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PENoArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with no arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:
			GrEndString


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		ardeb	12/9/92		Created to cope with bad gstrings in
					background bitmap files, which have
					corrupt linkage in the final block
					(s/b 0, but seems to be 0x00ff, for
					no readily apparent reason).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEEndString	proc	near
		.enter	inherit	PlayElement
		call	CallKernel
	;
	; Unlock or free the last block, as appropriate.
	; 
		mov	bx, gsf.GSF_sourceVMfile
		test	gsf.GSF_options, mask GSCO_FREE_ORIG_GSTRING
		jz	unlockCurBlock
		mov	ax, gsf.GSF_thisVMblock
		call	VMFree
done:
		stc			; signal done
		.leave
		ret

unlockCurBlock:
		push	bp
		mov	bp, gsf.GSF_memVMblock
		call	VMUnlock
		pop	bp
		jmp	done
PEEndString	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PENoArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with no arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSaveState
			GrRestoreState
			GrSetNullTransform
			GrDrawPointAtCP
			GrNewPage
			GrNullOp
			GrInitDefaultTransform
			GrSetDefaultTransform


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PENoArgs	proc	near
		call	CallKernel
		ret
PENoArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ooops, bad gstring

CALLED BY:	INTERNAL
		PlayElement
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEError		proc	far
if ERROR_CHECK
		ERROR	CONVERT_GSTRING_ELEMENT_NOT_SUPPORTED
else
gsf		local	GSFrame	
		.enter	inherit	
		mov	gsf.GSF_errorCode, GSCS_UNSUPPORTED_OPCODE
		stc
		.leave
		ret							
endif
PEError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEOneCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with one coordinate value

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load args from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawPoint
			GrMoveTo


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEOneCoord	proc	near
		uses	ax,bx		; save argument locations
		.enter

		; load the arguments and call the routine

		lodsw			; load x
		mov	bx, ax		; store here temp
		lodsw			; load y
		xchg	bx, ax		; get them in right regs
		call	CallKernel

		; restore regs and leave

		.leave
		ret
PEOneCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEOneCoordTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with one coordinate value, that are
		current position things normally taking two coords

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load args from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawLineTo
			GrDrawRectTo
			GrFillRectTo


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEOneCoordTo	proc	near
		uses 	ax,cx,dx	; save argument locations
		.enter

		; load the arguments and call the routine

		lodsw			; load x
		mov	cx, ax
		lodsw
		mov	dx, ax
		call	CallKernel

		; restore regs and leave

		.leave
		ret
PEOneCoordTo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETwoCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with two coordinate values

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load args from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawLine
			GrDrawRect
			GrFillRect
			GrDrawEllipse
			GrFillEllipse


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETwoCoords	proc	near
		uses 	ax,bx,cx,dx	; save argument locations
		.enter

		; load the arguments and call the routine

		lodsw			; load x1
		mov	dx, ax		; save for later
		lodsw			; load y1
		mov	bx, ax		; save for later
		lodsw			; load x2
		mov	cx, ax		; save for later
		lodsw			; load y2
		xchg	dx, ax		; save for later
		call	CallKernel

		; restore regs and leave

		.leave
		ret
PETwoCoords	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEByteAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret attribute elements with one byte arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetDrawMode
			GrSetLineEnd
			GrSetLineJoin
			GrSetLineColorMap
			GrSetAreaColorMap
			GrSetTextColorMap
			GrSetLineMask	(system pattern)
			GrSetAreaMask	(system pattern)
			GrSetTextMask	(system pattern)
			GrSetLineColor	(color index)
			GrSetAreaColor	(color index)
			GrSetTextColor	(color index)


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEByteAttr	proc	near
		uses 	ax		; save argument locations
		.enter

		; load the arguments and call the routine

		lodsb			; load byte
		clr	ah		; some routines need this 
		call	CallKernel

		; restore regs and leave

		.leave
		ret
PEByteAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEWordAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret attribute elements with one word arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetTextMode
			GrSetTextStyle
			GrSetLineWidth
			GrSetLineStyle


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEWordAttr	proc	near
		uses	ax		; save argument locations
		.enter

		; load the arguments and call the routine

		lodsw			; load argument
		call	CallKernel

		; restore regs and leave

		.leave
		ret
PEWordAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PELineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PELineWidth	proc	near
		uses	ax, dx		; save argument locations
		.enter

		; load the arguments and call the routine

		lodsw			; load argument
		mov	dx, ax
		clr	ax
		call	CallKernel

		; restore regs and leave

		.leave
		ret
PELineWidth		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PELineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret attribute elements with one word arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetLineStyle


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PELineStyle	proc	near
		uses	ax,bx
		.enter

		; load the arguments and call the routine

		lodsw			; load argument
		mov	bl, ah
		call	GrSetLineStyle
		clc

		; restore regs and leave

		.leave
		ret
PELineStyle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PE3ByteAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with RGB color arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetLineColor
			GrSetAreaColor
			GrSetTextColor

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PE3ByteAttr	proc	near
		uses	ax,bx			; regs we trash
		.enter

		; get the components, call the routine

		mov	al, ds:[si]		; get R
		mov	bx, ds:[si+1]		; get G, B
		add	si, 3
		mov	ah, CF_RGB
		call	CallKernel
		.leave
		ret
PE3ByteAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PESpacePad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with RGB color arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetTextSpacePad

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PESpacePad	proc	near
		uses	bx,dx			; regs we trash
		.enter

		; get the components, call the routine

		mov	bl, ds:[si]		; get fraction
		mov	dx, ds:[si+1]		; get integer
		add	si, 3
		call	GrSetTextSpacePad	; call routine to set color 
		clc
		.leave
		ret
PESpacePad	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDWordAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret attribute elements with double word arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetMiterLimit

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEDWordAttr	proc	near
		uses 	ax,bx,cx,dx	; save argument locations
		.enter

		; load the arguments and call the routine

		mov	ax, ds:[si]	; only SetMiterLimit for now
		mov	bx, ds:[si+2]	; 
		add	si, 4		; bump pointer past dat
		call	CallKernel

		; restore regs and leave

		.leave
		ret
PEDWordAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PESetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret SetFont call

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetFont

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PESetFont	proc	near
		uses 	ax,bx,cx,dx	; save argument locations
		.enter

		; load the arguments and call the routine

		mov	ah, ds:[si]	; assume SetFont
		mov	dx, ds:[si+1]	; 
		mov	cx, ds:[si+3]	; get fontID
		add	si, 5		; bump pointer past data
		call	GrSetFont
		clc
	
		; restore regs and leave

		.leave
		ret
PESetFont	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret drawchar elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawChar
			GrDrawCharAtCP

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PEDrawChar	proc	near
		uses	ax, bx, dx		; save argument locations
		.enter

		; load up the character to draw

		lodsb				; al = char
		mov	dl, al			; but it belongs here

		; see if DrawChar or DrawCharAt

		cmp	bx, GR12X_DRAW_CHAR_CP*2 	; right opcode ?
		je	PEDC_draw		;  yes, all ready to draw

		; load the arguments and call the routine

		lodsw				; get x coord
		mov	bx, ax			; save for later
		lodsw				; get x coord
		xchg	bx, ax			; get in right regs
PEDC_draw:
		call	CallKernel
		clc

		; restore regs and leave

		.leave
		ret
PEDrawChar	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with transformation matrices passed

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetTransform
			GrApplyTransform

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETMatrix	proc	near
		uses	ax
tm		local	TransMatrix
		.enter		

		movdw	tm.TM_e11, ds:[si].OTM_e11, ax
		movdw	tm.TM_e12, ds:[si].OTM_e12, ax
		movdw	tm.TM_e21, ds:[si].OTM_e21, ax
		movdw	tm.TM_e22, ds:[si].OTM_e22, ax
		add	si, (size WWFixed)*4		; bump past initial 1s

		lodsw					; 31 fraction
		mov	tm.TM_e31.DWF_frac, ax
		lodsw
		cwd
		movdw	tm.TM_e31.DWF_int, dxax

		lodsw					; 32 fraction
		mov	tm.TM_e32.DWF_frac, ax
		lodsw
		cwd
		movdw	tm.TM_e32.DWF_int, dxax

		push	ds, si
		segmov	ds, ss
		lea	si, tm				; ds:si -> tm
		call	CallKernel
		pop	ds, si
		.leave
		ret
PETMatrix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements from a clip rect opcode
CALLED BY:	PlayElement()

PASS:		ds:si - ptr to element data
		di - handle of GState
RETURN:		ds:si - ptr past element data
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: OpSetClipRect & OpSetDocClipRect are equivalent
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEClipRect	proc	near
		.enter

		; I've decided to nuke support for the conversion of clip
		; rectangles from 1.2 to 2.0.  They weren't used anywhere
		; except for the text object, which didn't really need them.
		; There are a few bugs associated with their conversion,
		; so out they go.  (jim 3/5/93)
if (0)
		lodsw					; get flags
		mov	dx, ax
		lodsw
		mov	cx, ax
		lodsw
		mov	bx, ax
		lodsw
		xchg	ax, cx
		push	si			; save pointer
		mov	si, ds:[si]
		xchg	si, dx			; si = flags, dx = bottom
		rol	si, 1			; rotate around so we can do
		rol	si, 1			;  lookup
		rol	si, 1
		and	si, 0x7			; only 8 possibilities
		shl	si, 1
		mov	si, cs:[combineTable][si] ; get new combine type
		call	CallKernel
		pop	si
		add	si, 2			; for last one
else
		add	si, 10			; bump past data
endif
		clc
		.leave
		ret
PEClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret draw_text elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawText
			GrDrawTextAtCP

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PEDrawText	proc	near
		uses 	ax, bx, cx		; regs we trash
		.enter

		; getting at least one word, then check for function

		lodsw				; get first parameter
		mov	cx, ax			; assume At version
		cmp	bx, GR12X_DRAW_TEXT_CP*2	; test opcode type
		je	PEDT_at			;  yep, finish off

		; regular old GrDrawText, finish params

		mov	cx, ax			; save for later
		lodsw				; get y coord
		mov	bx, ax			; save for later
		lodsw				; get count
		xchg	cx, ax			; get in right regs

		; have params, call routine
PEDT_at:
		call	CallKernel

		; correct element pointer

		add	si, cx			; bump to next element
		clc
		.leave
		ret
PEDrawText	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawHalfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret horis and vertical lines

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawHLine
			GrDrawHLineTo
			GrDrawVLine
			GrDrawVLineTo

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PEDrawHalfLine	proc	near
		uses	ax,bx,cx,dx		; regs we trash
		.enter

		; test type of opcode and load up the parameters

		mov	dx, bx			; save opcode
		cmp	bx, GR12X_DRAW_VLINE_TO*2	; test for to vers
		je	PEDHL_to
		cmp	bx, GR12X_DRAW_HLINE_TO*2	; test for to vers
		je	PEDHL_to
		lodsw				; get x coordinate
		mov	cx, ax			; save
		lodsw				; get x coordinate
		xchg	bx, ax			; get in right regs
PEDHL_to:
		lodsw				; get other coord
		xchg	cx, ax			; get in right regs
		cmp	dx, GR12X_DRAW_HLINE*2	; test for horiz lines
		je	PEDHL_horiz
		cmp	dx, GR12X_DRAW_HLINE_TO*2	; test for horiz lines
		je	PEDHL_horiz
		mov	dx, cx	
PEDHL_horiz:
		call	CallKernel
		.leave
		ret
PEDrawHalfLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEPolyCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret poly-coord elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawPolyline
			GrDrawSpline
			GrFillPolygon
			GrDrawPolygon

		We need to allocate a buffer and do the transformation on
		all the points that are passed.  bummer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PEPolyCoord	proc	near
		uses	ax,bx,cx,dx
		.enter

		; if polygon or spline, need to prefetch a word

		cmp	bx, GR12X_DRAW_POLYLINE*2 ; if plain old polyline, skip
		je	PEDHL_pline
		cmp	bx, GR12X_DRAW_POLYGON*2 ; if frame polygon, skip
		je	PEDHL_pline
		lodsb				; get first word, bump ptr
		mov	dl, al			; save flag
PEDHL_pline:
		lodsw				; ax = #coords
		tst	ax			; if no points, skip all this
		jz	done
		mov	cx, ax			; setup #pairs to do

		mov	al, dl			; restore flag
		call	CallKernel		; call the routine

		shl	cx, 1			; compute size of coords
		shl	cx, 1
		add	si, cx			; bump past coords
done:
		clc
		.leave
		ret
PEPolyCoord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PERotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret scale and rotate opcodes

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrApplyRotation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PERotate	proc	near
		uses	ax,bx,cx,dx		; regs we trash
		.enter
		
		mov	cx, ds:[si]		; get rotation angle/scale
		mov	dx, ds:[si+2]

		; apply the rotation

		call	CallKernel
		add	si, 4			; bump to next opcode
		clc
		.leave
		ret
PERotate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETransScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret translation/scale opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrApplyTranslation
			GrApplyScale

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETransScale	proc	near
		uses	ax,bx,cx,dx		; regs we trash
		.enter
		
		; need bx, so do test now and save result

		mov	cx, ds:[si]		; get rotation angle/scale
		mov	dx, ds:[si+2]
		mov	ax, ds:[si+4]		; get y scale factor
		mov	bx, ds:[si+6]

		; apply the scale/rotation

		call	CallKernel
		add	si, 8			; bump to next opcode
		clc
		.leave
		ret
PETransScale	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEComment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a GR_COMMENT opcode while interpreting

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...
		di	- gstring handle

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		resume normal string interpretation;
		if the target gstate is a gstring, call the kernel functions;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrComment
			GrEscape

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PEComment	proc	near
		uses	ax, bx, di
		.enter

		; in case we are writing to a valid gstring, call the kernel 
		; routines.  If we're not, they'll just return

		lodsw				; get first word
		mov	cx, ax			; cx takes count for both
		cmp	bx, GR12X_COMMENT*2	; see if ready to go
		je	callKernel		;  yes, call it in
		lodsw				; escape code, get another
		xchg	ax, cx			; get things in right order
callKernel:
		call	CallKernel

		add	si, cx			; bump past data
		clc
		.leave
		ret

PEComment	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PECustomMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a END_STRING opcode while interpreting

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetLineMask
			GrSetAreaMask
			GrSetTextMask

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PECustomMask	proc	near
		uses 	ax			; save reg
		.enter
		mov	al, SDM_CUSTOM
		call	CallKernel
		add	si, 8			; bump by size of mask
		clc
		.leave
		ret
PECustomMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PECustomStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a GR_SET_CUSTOM_LINE_STYLE opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetLineStyle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PECustomStyle	proc	near
		uses	ax, bx
		.enter

		lodsb				; get index
		mov	bl, al			; set up index
		lodsw				; get count
		push	ax			; save count
		mov	ah, al			; this is where setstyle wants
		mov	al, LS_CUSTOM		; give it right option code
		call	GrSetLineStyle		; call the darn thing
		pop	ax			; restore count
		shl	ax, 1			; count is #pairs
		add	si, ax			; bump string pointer

		clc
		.leave
		ret
PECustomStyle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PELineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a SET_LINE_ATTR opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetLineAttr

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PELineAttr	proc	near
		uses	ax
la		local	LineAttr
		.enter

		lodsw
		mov	{word} la.LA_colorFlag, ax
		lodsw
		mov	{word} la.LA_color.RGB_green, ax
		lodsw
		xchg	al, ah
		shr	ah, 1				; shift down ON_BLACK
		jnc	setClosest
		or	ah, 1
haveMapMode:
		mov	{word} la.LA_mask, ax	
		lodsw
		mov	la.LA_width.WWF_int, ax
		clr	la.LA_width.WWF_frac
		lodsw
		mov	{word} la.LA_end, ax
		mov	la.LA_style, LS_SOLID	; just set solid line style
		push	ds, si
		segmov	ds, ss, si
		lea	si, la
		call	GrSetLineAttr		; only one routine to call
		pop	ds, si
		clc
		.leave
		ret

		; set map mode to CMT_CLOSEST
setClosest:
		and	ah, 0x2			; clear low bit
		jmp	haveMapMode
PELineAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEAreaAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a SET_AREA_ATTR opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetAreaAttr

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEAreaAttr	proc	near
		uses	ax
areaA		local	AreaAttr
		.enter

		lodsw
		mov	{word} areaA.AA_colorFlag, ax
		lodsw
		mov	{word} areaA.AA_color.RGB_green, ax
		lodsw
		xchg	al, ah
		shr	ah, 1				; shift down ON_BLACK
		jnc	setClosest
		or	ah, 1
haveMapMode:
		mov	{word} areaA.AA_mask, ax

		push	ds, si
		segmov	ds, ss, si
		lea	si, areaA
		call	GrSetAreaAttr		; only one routine to call
		pop	ds, si
		clc

		.leave
		ret

		; set map mode to CMT_CLOSEST
setClosest:
		and	ah, 0x2			; clear low bit
		jmp	haveMapMode
PEAreaAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETextAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a SET_TEXT_ATTR opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetTextAttr

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETextAttr	proc	near
textA		local	TextAttr
		.enter

		lodsw				; move textAttr structure over
		xchg	al, ah
		mov	{word} textA.TA_color.low, ax
		lodsw
		mov	{word} textA.TA_color.high, ax
		lodsb
		mov	textA.TA_mask, al
		lodsw
		mov	{word} textA.TA_styleSet, ax
		lodsw
		mov	{word} textA.TA_modeSet, ax
		movwbf	textA.TA_spacePad, ds:[si], ax
		add	si, 3
		lodsw	
		mov	textA.TA_font, ax
		movwbf	textA.TA_size, ds:[si], ax
		add	si, 3
		lodsw
		mov	textA.TA_trackKern, ax
		clr	ax
		mov	textA.TA_fontWeight, FW_NORMAL
		mov	textA.TA_fontWidth, FWI_MEDIUM
		mov	textA.TA_pattern.GP_type, PT_SOLID
		mov	textA.TA_pattern.GP_data, al

		push	ds, si
		segmov	ds, ss, si
		lea	si, textA
		call	GrSetTextAttr		; only one routine to call
		pop	ds, si
		clc
		.leave
		ret
PETextAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a GR_DRAW_BITMAP opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data
		ss:bp	- pointer to structure alloocated in GrPlayString...

		if it is a dynamic string, es will be pointing at the 
		gstring block

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawBitmap
			GrDrawBitmapAtCP

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PEBitmap	proc	near
		uses	ax,bx,cx,dx, bp		; save some regs
gsf		local	GSFrame	
		.enter	inherit

		; if "AtCP" version, don't need to load position to draw

		cmp	bx, GR12X_DRAW_BITMAP_CP*2 ; draw at CP ?
		je	drawAt
		lodsw				; get x position
		mov	bx, ax			; save
		lodsw				; get y position
		xchg	bx, ax			; get in right regs

		; ready to go, bump pointer to start of header
drawAt:
		mov	cx, ds:[si]		; get slice size
		mov	gsf.GSF_dataSize, cx
		mov	ds:[si], bp		; save frame pointer for callbk
		add	si, 2			; bump past byte count

		; set up callback, if needed

		mov	gsf.GSF_sliceStart, si
		clr	dx			; assume no callback
		test	ds:[si].B_type, mask BM_COMPLEX ; check if complex
		jz	commonCall		;  no, just draw the thing
		mov	dx, cs			; set up our routine
		mov	cx, offset PEBitmapCB	;  offset

	; We don't want to look at the palette bit, really, since 1.X 
	; didn't deal with palettes in bitmaps (so they didn't see the 
	; effect of one if it was there) and it would be a pain to deal
	; with it now.  If we don't set the palette bit, the 2.0 Kernel
	; will just ignore the info that is there.
;		tst	ds:[si].CB_palette	; if there was a palette, set
;		jz	commonCall		;   the new palette bit.
;		or	ds:[si].B_type, mask BM_PALETTE

		; all ready to go, call the routine
		; but if the source is a monochrome bitmap, use GrFillBitmap
commonCall:
		test	ds:[si].B_type, mask BMT_FORMAT ; if zero, it's mono
		jz	haveMono
		call	CallKernel 		;  returns, it's all drawn
doneDrawing:
		mov	si, gsf.GSF_sliceStart	; fetch start of slice, as
						;  might be in new block, for
						;  complex bitmap, and
						;  GrDrawBitmap returns SI
						;  unchanged...
		mov	bx, gsf.GSF_memVMblock	; set ds to be current VM block
		call	MemDerefDS		; (GrDrawBitmap doesn't update
						;	it for new slices)
		mov	ax, gsf.GSF_dataSize	; get size of last element
		mov	ds:[si-2], ax		; restore slice size
		add	si, ax			; bump to next element
		clc

		.leave
		ret

haveMono:
		cmp	gsf.GSF_kernRoutine.low, offset GrDrawBitmap
		jne	fillAtCP
		call	GrFillBitmap
		jmp	doneDrawing
fillAtCP:
		call	GrFillBitmapAtCP
		jmp	doneDrawing
PEBitmap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEBitmapCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to write next slice of bitmap

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to last slice

RETURN:		ds:si	- update pointer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (stream-based string)
		    read in next slice;
		else
		    just bump pointer to next slice;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEBitmapCB	proc	far
		uses 	ax, bx, bp, es		; save regs we trash
gsf		local	GSFrame
		.enter	inherit

		mov	bp, ds:[si-2]		; get frame pointer
		mov	ax, gsf.GSF_dataSize
		mov	ds:[si-2], ax		; restore size word
		add	si, ax			; add in count
		cmp	si, ds:[2]		; off end ?
		jae	loadNextOne		;  yes, load next block
doneOK:
		mov	ax, ds:[si]		; get slice size
		mov	gsf.GSF_dataSize, ax	; and save for later
		mov	ds:[si], bp		; save frame pointer for next
						;	iteration of callback
		add	si, 2			; bump past size
		mov	gsf.GSF_sliceStart, si
		clc
done:
		.leave
		ret

		; load in next block
loadNextOne:
		push	ds:[0]			; save link to next block
		mov	bx, gsf.GSF_sourceVMfile
		test	gsf.GSF_options, mask GSCO_FREE_ORIG_GSTRING
		jz	unlockInstead
		mov	ax, gsf.GSF_thisVMblock
		call	VMFree			; release current one
checkNextBlock:
		pop	ax
		mov	gsf.GSF_thisVMblock, ax	; save for later
		tst	ax			; if zero, bail
EC <		ERROR_Z CONVERT_GSTRING_BAD_LINKAGE			>
		jnz	lockBlock
		mov	gsf.GSF_errorCode, GSCS_DAMAGED_GSTRING
		stc	
		jmp	done
lockBlock:
		push	bp
		call	VMLock			; lock down next block
		mov	si, bp			; si = mem handle
		pop	bp
		mov	gsf.GSF_memVMblock, si	; save mem handle
		mov	ds, ax			; ds:si -> block
		mov	si, 4			; skip over link/size
		jmp	doneOK

unlockInstead:
		push	bp
		mov	bp, gsf.GSF_memVMblock
		call	VMUnlock
		pop	bp
		jmp	checkNextBlock
		
PEBitmapCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDataPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap pointer static element

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to last slice

RETURN:		ds:si	- update pointer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (stream-based string)
		    read in next slice;
		else
		    just bump pointer to next slice;

		Supports the following codes:
			GR_DRAW_BITMAP_PTR
			GR_DRAW_TEXT_PTR

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEDataPtr	proc	near
		uses	ax,bx,dx,cx
		.enter
		push	si			; save pointer
		lodsw				; get position info
		mov	bx, ax			; save x position
		lodsw				; get y position
		xchg	ax, bx
		push	si
		mov	si, ds:[si]		; load offset to bitmap data
		clr	dx			; no complex ones allowed
		clr	cx			; no count for DrawText
		call	CallKernel
		pop	si			; restore data pointer
		add	si, 2
		clc
		.leave
		ret
PEDataPtr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDataOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap localmem pointer static element

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to last slice

RETURN:		ds:si	- update pointer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (stream-based string)
		    read in next slice;
		else
		    just bump pointer to next slice;

		Supports the following codes:
			GR_DRAW_BITMAP_OPTR

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEDataOptr	proc	near
		uses	ax,bx,dx,cx
		.enter
		push	ds			; save pointer
		lodsw				; get position info
		mov	bx, ax			; save x position
		lodsw				; get y position
		xchg	ax, bx
		push	ax, bx			; save y position
		lodsw				; get chunk handle
		push	si
		mov	bx, ds:[si]		; get resource handle
		mov	si, ax			; chunk handle in si
		mov	dx, bx			; save resource handle
		call	MemLock			; lock it down
		mov	ds, ax			; ds -> resource
		mov	si, ds:[si]		; dereference chunk
		clr	cx			; no callback routine
		pop	ax, bx			; restore draw position
		push	dx			; save resource handle
		clr	dx			; no callback routine
		call	CallKernel
		pop	bx			; restore resource handle
		call	MemUnlock		; release block
		pop	si
		add	si, 2
		pop	ds			; restore data pointer

		clc
		.leave
		ret
PEDataOptr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw GR_DRAW_TEXT_FIELD element

CALLED BY:	INTERNAL

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data:

RETURN:		ds:si 	- pointer to next element

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PETextField	proc	near
		uses	ax,bx,cx,dx
gsf		local	GSFrame
		.enter

		; calculate pointer to first style run record and save it
		; also setup string length for GrDrawTextField

		lodsw				; get byte count, with string
		add	ax, si			; ax -> past 1st styleRun 
		sub	ax, (size OldTFStyleRun) ; back up to begin of run
		mov	gsf.GSF_styleRunPtr, ax ; save it for callback 
		mov	gsf.GSF_origStyleRunPtr, ax ; save it for callback 
		sub	ax, si			; calc string length
		sub	ax, size OldGDF_saved	; ax = string length
		mov	cx, ax			; cx = string length
		mov	gsf.GSF_dataSize, cx	; save it for callback 
		mov	gsf.GSF_GDFVars.GDFV_saved.GDFS_nChars, cx

		; set up ss:bp -> GDF_vars, and fill it with values passed in
		; gstring data.  Calc the ones we need to do on-the-fly

		push	bp			; save local frame pointer
		lea	bp, gsf.GSF_GDFVars 	; ss:bp -> GDF_vars (new struc)

		; move/translate GDF_saved structure from gstring buffer 
		; to local buffer on the stack

		movdw	ss:[bp].GDFV_other, dssi
		add	ss:[bp].GDFV_other.low, size OldGDF_saved
		mov	ax, ds:[si].OGDFS_field.OFI_position
		add	ax, ds:[si].OGDFS_textLeft
		add	ax, ds:[si].OGDFS_adjustment
		mov	ss:[bp].GDFS_drawPos.PWBF_x.WBF_int, ax
		clr	ss:[bp].GDFS_drawPos.PWBF_x.WBF_frac
		mov	ax, ds:[si].OGDFS_yPos
		mov	ss:[bp].GDFS_drawPos.PWBF_y.WBF_int, ax
		clr	ss:[bp].GDFS_drawPos.PWBF_y.WBF_frac
		clrwbf	ss:[bp].GDFS_baseline
		clr	ss:[bp].GDFS_limit
		clr	ss:[bp].GDFS_flags

		; force the callback routine to here in klib

		mov	ss:[bp].GDFV_styleCallback.offset, offset TextFieldCB
		mov	ss:[bp].GDFV_styleCallback.segment, cs

		call	GrDrawTextField	

		; restore frame pointer

		mov	ds, ss:[bp].GDFV_other.high	; bump string ptr
		pop	bp

		; all done, bump data pointer to next element

		mov	si, gsf.GSF_styleRunPtr		; 

		.leave
		ret
PETextField	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextFieldCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for PETextField

CALLED BY:	EXTERNAL
		GrDrawTextField

PASS:           ss:bp   = ptr to GDF_vars structure on stack.
                si      = offset to current position in text.
		bx:di   = fptr to buffer, sizeof TextAttr struc
RETURN:         buffer at bx:di filled
		cx      = # of characters in this run.
		ds:si   = Pointer to text at offset

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		stuff style run info for this run into buffer;
		return run length in cx;
		bump nextRunPtr to next run;
		reduce #chars left;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFieldCB	proc	far
		uses	es, ax
gsf		local	GSFrame
		.enter inherit

		; setup ss:bp to coincide with the full stack frame, not
		; just the GDF_vars part.

		add	bp, size GDF_vars	; restore old frame pointer

		; first, fill the passed buffer with the attributes that
		; we have.  

		mov	es, bx			; es:di -> TextAttr buffer
		mov	ds, gsf.GSF_GDFVars.GDFV_other.high 
		mov	si, gsf.GSF_styleRunPtr	; ds:si -> OldTFStyleRun
		add	gsf.GSF_styleRunPtr, size OldTFStyleRun
		mov	cx, ds:[si].OTFSR_count
		sub	gsf.GSF_dataSize, cx
		cmp	gsf.GSF_dataSize, 0
		jg	adjustedPtr

		; Since the new GrDrawTextField goes through all the style
		; runs TWICE when writing to a GString (once for the GString
		; and a second time to correctly update the pen position)
		; we need to prepare for the second coming.  So exchange the
		; origStyleRunPtr and the current one.  That way, at the 
		; end of the second run, we have the styleRunPtr set to the
		; correct point (after the end of the element)

		mov	ax, gsf.GSF_origStyleRunPtr
		xchg	gsf.GSF_styleRunPtr, ax	; restore original due to 
		mov	gsf.GSF_origStyleRunPtr, ax
		mov	ax, gsf.GSF_GDFVars.GDFV_saved.GDFS_nChars
		mov	gsf.GSF_dataSize, ax
adjustedPtr:
		mov	ax, {word} ds:[si].OTFSR_attr.OTA_colorFlag
		xchg	al, ah
		mov	es:[di].TA_color.low, ax
		mov	ax, {word} ds:[si].OTFSR_attr.OTA_color.RGB_green
		mov	es:[di].TA_color.high, ax
		mov	al, ds:[si].OTFSR_attr.OTA_mask
		mov	es:[di].TA_mask, al
		mov	ax, {word} ds:[si].OTFSR_attr.OTA_styleSet
		mov	{word} es:[di].TA_styleSet, ax
		mov	ax, {word} ds:[si].OTFSR_attr.OTA_modeSet
		mov	{word} es:[di].TA_modeSet, ax
		clrwbf	es:[di].TA_spacePad
		movwbf	es:[di].TA_size, ds:[si].OTFSR_attr.OTA_size, ax
		mov	ax, ds:[si].OTFSR_attr.OTA_font
		mov	es:[di].TA_font, ax
		mov	ax, ds:[si].OTFSR_attr.OTA_trackKern
		mov	es:[di].TA_trackKern, ax
		mov	es:[di].TA_fontWeight, FW_NORMAL
		mov	es:[di].TA_fontWidth, FWI_MEDIUM
		mov	es:[di].TA_pattern.GP_type, PT_SOLID
		clr	es:[di].TA_pattern.GP_data

		; setup pointer to text, update stored pointer

		mov	si, gsf.GSF_GDFVars.GDFV_other.low	; text pointer
		add	gsf.GSF_GDFVars.GDFV_other.low, cx	; update

		; restore ss:bp to point at GDF_vars

		sub	bp, size GDF_vars

		.leave
		ret
TextFieldCB	endp

GStringCode	ends
