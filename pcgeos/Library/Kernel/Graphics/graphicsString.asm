COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

930!	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Graphics
FILE:		Graphics/graphicsString.asm

AUTHOR:		Jim DeFrisco, 26 September 1989

ROUTINES:
	Name			Description
	----			-----------
    GLB GrCreateGString		Open a graphics string, start redirecting
				graphics orders to the string.
    GLB GrLoadGString		Load a graphics string from a file
    GLB GrDrawGString		Draw a graphics string
    GLB GrDrawGStringAtCP	Draw a graphics string at the current
				position.
    INT GStringSetup		Utility routine used by GrDrawGString
    INT GStringCleanup		Finished drawing GString, do some cleanup.
    GLB GrCopyGString		Copy a graphics string
    GLB GrGetGStringElement	Extract an element from a graphics string
    GLB GrGetGStringBounds	Get the coordinate bounds of a graphics
				string drawn at the current position
    EXT GrDerefPtrGString	Dereference a pointer-type gstring
    INT CheckEndCondition	Check end condition, see if done drawing
    GLB ReadElement		Read the next graphics string into the file
				buffer
    INT DerefMemElement		Read the next element from a chunk-based
				GString
    INT DerefStreamElement	Already an element in the buffer, point at
				it.
    INT ReadStreamElement	Read in the next element from a stream
    INT ReadStreamBytes		Utility routine to read a few bytes from a
				stream.
    INT DerefVMemElement	Read in the next vmem element
    INT ReadVMemElement		Read in the next vmem element
    INT DerefPtrElement		Get pointer to element
    INT GetElementInfo		Grab some info about the element, store in
				the stack frame
    GLB PlayElement		Play a single graphics string element
    INT CallKernelRoutine	Call the appropriate kernel graphics
				routine
    INT PENoArgs		Interpret elements with no arguments
    INT PEOneCoord		Interpret elements with one coordinate
				value
    INT PERelCoord		Interpret elements with one coordinate
				value
    INT PETwoCoords		Interpret elements with two coordinate
				values
    INT PEByteAttr		Interpret attribute elements with one byte
				arguments
    INT PE3ByteAttr		Interpret elements with RGB color arguments
    INT PEWordAttr		Interpret attribute elements with one word
				arguments
    INT PELineStyle		Interpret attribute elements with one word
				arguments
    INT PESpacePad		Interpret elements with RGB color arguments
    INT PESetFont		Interpret SetFont call
    INT PEDrawChar		Interpret drawchar elements
    INT PETMatrix		Interpret elements with transformation
				matrices passed
    INT PEClipRect		Interpret elements from a clip rect opcode
    INT PEDrawText		Interpret draw_text elements
    INT PEDrawRoundRects	Interpret rounded rectangle & some
				arc-related elements
    INT PEDrawArcs		Interpret arc-related elements
    INT PEDrawHalfLine		Interpret horis and vertical lines
    INT PEPolyCoord		Interpret poly-coord elements
    INT PERotate		Interpret scale and rotate opcodes
    INT PETransScale		Interpret translation/scale opcode
    INT PEComment		Encountered a GR_COMMENT opcode while
				interpreting
    INT PECustomMask		Encountered a END_STRING opcode while
				interpreting
    INT PECustomStyle		Encountered a GR_SET_CUSTOM_LINE_STYLE
				opcode
    INT PEAttr			Encountered a SET_{LINE,AREA,TEXT}_ATTR
				opcode
    INT PESetPattern		Encountered a GR_SET_???_PATTERN in the
				GString
    INT PESetCustPattern	Encountered a GR_SET_???_PATTERN in the
				GString
    GLB PEBitmapPtr		Draw a bitmap pointer static element
    GLB PEBitmapOptr		Draw a bitmap localmem pointer static
				element
    INT PEBitmap		Encountered a GR_DRAW_BITMAP opcode
    GLB PEBitmapCB		Callback to write next slice of bitmap
    GLB PETextPtr		Draw a text pointer static element
    GLB PETextOptr		Draw a text localmem pointer static element
    INT PETextField		Draw GR_DRAW_TEXT_FIELD element
    EXT TextFieldCB		Callback routine for PETextField
    INT BoundRelCoord		Accumulate the bounds of a relatively drawn
				object
    INT BoundText		Figure the bounds for some piece of text
    INT BoundPoly		Do bounds calc, for poly something
    INT BoundRect		Calculate and accumulate bounds for an
				object
    INT BoundCoord		Process a single coordinate for bounds
				calculation
    INT BoundX			Do min/max calc on X coordinate
    INT BoundY			Do min/max calc on y coordinate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	9/26/89		Initial revision


DESCRIPTION:
	This file contains the global interface for all the graphics string
	support in the kernel.

	Resources:

	GraphicsCommon

	GraphicsString

	$Id: graphicsString.asm,v 1.1 97/04/05 01:13:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrLoadGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a graphics string from a file

CALLED BY:	GLOBAL

PASS:		cl	- type of handle passed in bx (enum GStringType):
			      GST_CHUNK	- block handle
			      GST_STREAM	- stream handle
			      GST_VMEM		- VMem file handle
			      GST_PTR		- segment address

     		bx	- handle to file where gstring is stored, or 
			  segment address (For GST_PTR strings)

		si	- if cx = GST_VMEM then
			     si = vmem block handle of gstring beginning
			  if cx = GST_PTR then
			     si = offset in block to start of string
			  if cx = GST_CHUNK then
			     si = chunk handle

RETURN:		si	- handle of graphics string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine doesn't actually load the entire string into
		memory, it just allocates a GString structure for the file, so
		that the handle can be used with the other string routines.

		The file is assumed open, and positioned at the beginning of
		the string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrLoadGString	proc	far
		uses	ax, cx, di		; save some regs
		.enter
		
if	FULL_EXECUTE_IN_PLACE
EC <		cmp	cl, GST_PTR				>
EC <		jne	continue				>
EC <		call	ECAssertValidFarPointerXIP		>
continue::
endif
		clr	ch
		call	AllocGString		; allocate the handle/structs
		mov	si, di			; return handle in si
		.leave
		ret
GrLoadGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefPtrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pointer to element

CALLED BY:	INTERNAL
		ReadElement
PASS:		es	- GString block
RETURN:		ds:si	- ptr to element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefPtrElement		proc	far
		.enter
		
		mov	ds, es:[GSS_hString]	; get segment
		mov	si, es:[GSS_firstBlock]	; get pointer to start
		add	si, es:[GSS_curPos].low	; get offset
		clc

		.leave
		ret
DerefPtrElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetElementInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab some info about the element, store in the stack frame

CALLED BY:	INTERNAL
		ReadString
PASS:		es	- GString block
		ds:si	- pointer to element
		inherits DrawStringFrame
RETURN:		carry	- set if invalid opcode
			  else 
				fills fields in the stack frame
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetElementInfo	proc	near
		.enter

		movdw	es:[GSS_lastPtr], dssi
		mov	bl, ds:[si]		; get opcode

		cmp	bl, GStringElement
		cmc
		jc	done

				CheckHack <(size GSElemInfo) eq 10>
		clr	bh
		shl	bx			;*2
		mov	ax, bx
		shl	bx			;*4
		shl	bx			;*8
		add	bx, ax
		cmp	bx, GR_DRAW_TEXT_FIELD * (size GSElemInfo)
		je	yowza
		mov	ax, cs:GSElemInfoTab[bx].GSEI_size ; al = elem size
		cmp	ax, 1			; if zero, bail >
		jc	done

		; if any of the top two bits are set, it indicates that the
		; that the element is variable sized.  The rest of the 
		; byte is an offset into the element to a word that holds
		; a count.  That count can be one of bytes, words or dwords
		; as indicated by the top two bits:
		;	TOP TWO BITS		SIZE OF VARIABLE ELEMENTS
		;	00			Not variable sized
		;	01			byte count
		;	10			word count
		;	11			dword count

		test	ah, 0xc0		; variable sized ?
		jnz	calcVariableSize
haveSize:
		mov	es:[GSS_lastSize], ax
		movdw	es:[GSS_lastRout], cs:GSElemInfoTab[bx].GSEI_play, ax
		movdw	es:[GSS_lastKern], cs:GSElemInfoTab[bx].GSEI_kern, ax
		clc

done:
		.leave
		ret

		; we can calculate this now...
calcVariableSize:
		push	bx
		mov	bl, ah
		and	bx, 0x3f		; isolate low bits
		mov	bx, ds:[si][bx]		; grab count
		test	ah, 0x80		; *2 ?
		jz	haveVarSize
		shl	bx, 1
		test	ah, 0x40
		jz	haveVarSize
		shl	bx, 1
haveVarSize:
		clr	ah
		add	ax, bx
		pop	bx
		jmp	haveSize


		; GR_DRAW_TEXT_FIELD is a brutish beast and we must
		; calculate its size. 
		; First get the total number of chars and advance
		; si to the begining of the first style run

yowza:
		push	cx				; don't trash
		push	si				; offset to element
		add	si,offset ODTF_saved
		mov	cx,ds:[si].GDFS_nChars		;
		add	si,size GDF_saved

		; Loop through the style runs until we've read 
		; the total number of chars
nextStyle:
		lodsw					; num chars in style
		add	si,size TextAttr		; move past TextAttr
DBCS <		shl	ax, 1						>
		add	si,ax				; move past chars
DBCS <		shr	ax, 1						>
		sub	cx,ax
		jnz	nextStyle

		; The size of the GR_DRAW_TEXT_FIELD is the offset past	
		; the last char - the original offset to the element
		mov	ax,si				; offset past last char
		pop	si				; original offset
		sub	ax,si				; size
		pop	cx				; don't trash
		jmp	haveSize

GetElementInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlayElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a single graphics string element

CALLED BY:	GLOBAL

PASS:		ds:si	- far pointer to element
		inherits DrawStringFrame
		di 	- GState
		es	- GString block
RETURN:		nothing 
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version
		jim	4/92		rewritten for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlayElement	proc	far

		; signal we're going to use the element that is setup

		and	es:[GSS_flags], not mask GSF_ELEMENT_READY

		; bump curPos to the next element

		mov	bx, es:[GSS_flags]	; get flags
		and	bl, mask GSF_HANDLE_TYPE ; isolate gstring type
		cmp	bl, GST_VMEM		; different bump routine for vm
		je	bumpVMemCurPos
		mov	bx, es:[GSS_lastSize]
		add	es:[GSS_curPos].low, bx
		adc	es:[GSS_curPos].high, 0
	
		; call the local play routine
playIt:
		tst	di			; if zero, don't call rout
		jz	done
		test	es:[GSS_flags], mask GSF_FIGURE_BOUNDS ; see which...
						; clears carry
		jz	notBounds
		stc
notBounds:
		mov	bx, es:[GSS_lastRout].segment
		mov	ax, es:[GSS_lastRout].offset

		push	bx
		call	ProcCallModuleRoutine
		pop	bx
done:
		ret

		; for all other gstring types, add in the current elem size
bumpVMemCurPos:
		incdw	es:[GSS_curPos]		; next element in HugeArray
		jmp	playIt

PlayElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallKernelRoutine
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

Common_CallKernelRoutine proc	near
DSframe		local	DrawStringFrame
		.enter	inherit
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		movdw	bxax, es:[GSS_lastKern]
		call	ProcCallFixedOrMovable
		.leave
		ret
Common_CallKernelRoutine endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEndCondition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check end condition, see if done drawing

CALLED BY:	INTERNAL
		GrDrawStringAtCP

PASS:		inherits DrawStringFrame
		ds:si	- points at next element

RETURN:		carry	- set if done, else clear

		if carry is set:
		    dx	- exit code, if carry set
		    cx	- additional info, as per exit code:

				enum in dx		value in cx
				----------		-----------
				GSRT_COMPLETE 		nothing
				GSRT_NEW_PAGE 		PageEndCommand (in cl)
				GSRT_FAULT 		nothing
				GSRT_LABEL		label value 
				GSRT_ESCAPE  		escape number
				GSRT_ONE 		next opcode (in cl)
				GSRT_MISC		next opcode (in cl)
				GSRT_XFORM 		next opcode (in cl)
				GSRT_OUTPUT 		next opcode (in cl)
				GSRT_ATTR 		next opcode (in cl)
				GSRT_PATH 		next opcode (in cl)
				
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		Check opcode against various ending conditions

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEndCondition proc	far
DSframe		local	DrawStringFrame
		.enter	inherit

		; test for all the possible abort conditions
		; check first for end of string

		clr	ch				; return a word
		mov	cl, ds:[si]			; get next opcode
		mov	dx, GSRT_COMPLETE		; assume we're done
		cmp	cl, GR_END_GSTRING		; done ?
		je	doneStop			;  yes, set carry & go

		; check to see if any other flags set

		mov	bx, DSframe.DSF_flags		; load up passed flags
		tst	bx				; no flags ?
		jnz	keepLooking			;  no, continue
doneContinue:
		clc					; setup carry
		.leave
		ret

		; stop drawing
doneStop:
		stc					; signal done
		.leave
		ret


		; check next for drawing one element
keepLooking:
		mov	dx, GSRT_ONE			; assume return value
		test	bx, mask GSC_ONE		; done after one ?
		jnz	doneStop

		; check for an output element

		test	bx, mask GSC_OUTPUT
		jz	checkNewPage
		mov	dx, GSRT_OUTPUT			; setup return type
		cmp	cl, GSE_FIRST_OUTPUT_OPCODE	; check the range
		jb	notOutput
		cmp	cl, GSE_LAST_OUTPUT_OPCODE
		jbe	doneStop

		; we were looking for an output code, but didn't find one,
		; it that's all we were interested in, we're done.
notOutput:
		and	bx, not mask GSC_OUTPUT		; clear the bit
		jz	doneContinue			;  if nothing else, go

		; check next for a form feed
checkNewPage:
		test	bx, mask GSC_NEW_PAGE		; looking for new page?
		jz	checkEscape			;  no, continue
		cmp	cl, GR_NEW_PAGE			; found new page ?
		jne	notNewPage
		mov	dx, GSRT_NEW_PAGE		; signal we found it
		mov	cl, ds:[si].ONP_pageEnd		; return PageEndCommand
		jmp	doneStop
notNewPage:
		and	bx, not mask GSC_NEW_PAGE
		jz	doneContinue

		; check next for an escape code
checkEscape:
		test	bx, mask GSC_ESCAPE		; looking for escape ?
		jz	checkLabel			;  no, continue
		cmp	cl, GR_ESCAPE			; escape code ?
		jne	notEscape			;  no, continue
		mov	dx, GSRT_ESCAPE			;  yes, load ret values
		mov	cx, ds:[si].OE_escCode		;   including esc code
		jmp	doneStop			;  yes, finished
notEscape:
		and	bx, not mask GSC_ESCAPE
		jz	doneContinue

		; check next for a GString label element
checkLabel:
		test	bx, mask GSC_LABEL		; stopping for labels ?
		jz	checkMisc
		cmp	cl, GR_LABEL			; found one ?
		jne	notLabel
		mov	dx, GSRT_LABEL
		mov	cx, ds:[si].OL_value		; return label value
		jmp	doneStop
notLabel:
		and	bx, not mask GSC_LABEL
		jz	doneContinue

		; check for an output code
checkMisc:
		test	bx, mask GSC_MISC		; bit set ?
		jz	checkXform			;  no, keep looking
		mov	dx, GSRT_MISC
		cmp	cl, GSE_LAST_MISC_OPCODE	; see if an output code
		ja	notMisc
doneStopCloser:
		stc
		.leave
		ret

notMisc:
		and	bx, not mask GSC_MISC
		jz	doneContCloser

		; check for xformation related opcode
checkXform:
		test	bx, mask GSC_XFORM		; bit set ?
		jz	checkAttr
		mov	dx, GSRT_XFORM
		cmp	cl, GSE_FIRST_XFORM_OPCODE
		jb	checkAttr
		cmp	cl, GSE_LAST_XFORM_OPCODE
		jbe	doneStopCloser
		and	bx, not mask GSC_XFORM
		jnz	checkAttr
doneContCloser:
		clc
		.leave
		ret

		; check for attribute related opcode
checkAttr:
		test	bx, mask GSC_ATTR		; bit set ?
		jz	checkPath
		mov	dx, GSRT_ATTR
		cmp	cl, GSE_FIRST_ATTR_OPCODE
		jb	checkPath
		cmp	cl, GSE_LAST_ATTR_OPCODE
		jbe	doneStopCloser
		and	bx, not mask GSC_ATTR
		jz	doneContCloser

		; must be path, then
checkPath:
		mov	dx, GSRT_PATH
		cmp	cl, GSE_FIRST_PATH_OPCODE	; in not here, fault
		jb	doneContCloser
		cmp	cl, GSE_LAST_PATH_OPCODE	; in not here, fault
		jbe	doneStopCloser
		mov	dx, GSRT_FAULT
		cmp	cl, GSE_LAST_OPCODE		; catch bogus codes
		ja	doneStopCloser
		jmp	doneContCloser
CheckEndCondition endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the next graphics string into the file buffer

CALLED BY:	GLOBAL

PASS:		inherits DrawStringFrame
		es	- GString

RETURN:		carry	- set if some problem reading, else
			  ds:si	- far pointer to element

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		if we don't already have one:
		    call individual read routines 
		    set the flag saying we have one
		else
		    just get a pointer to it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note: this routine does NOT bump the curPos, that is now
		      done in PlayElement

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version
		jim	4/92		rewritten for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadElement	proc	far	uses ax
DSframe		local	DrawStringFrame
		.enter	inherit
EC <		call	ECCheckStack					>

		; see if we have one already.

		mov	bx, es:[GSS_flags]		; we'll need the type
		test	bx, mask GSF_ELEMENT_READY	; see if we have one
		jnz	derefElement			;  yes, just deref it

		; there isn't one set up yet.  Call the routine to get the
		; next one.

		and	bx, mask GSF_HANDLE_TYPE	; get GString type
		shl	bx				; dword table
		shl	bx
		mov	ax, cs:[readElemTable][bx].offset
		mov	bx, cs:[readElemTable][bx].segment
		call	ProcCallFixedOrMovable		; call approp routine
		jc	exit
done:
		call	GetElementInfo			; get routine,size,etc
		jc	exit				; check invalid opcodes
		or	es:[GSS_flags], mask GSF_ELEMENT_READY
		clc
exit:
		.leave
		ret

		; there is already an element set up somewhere that we 
		; haven't played yet.  Get a pointer to it.
derefElement:
		and	bx, mask GSF_HANDLE_TYPE	; type of gstring
		shl	bx
		shl	bx
		mov	ax, cs:[derefElemTable][bx].offset
		mov	bx, cs:[derefElemTable][bx].segment
		call	ProcCallFixedOrMovable		; ds:si -> element
		jmp	done
ReadElement	endp

		; table of routines to read in and dereference an element
readElemTable	fptr	\
		DerefMemElement,	; GST_CHUNK
		ReadStreamElement,	; GST_STREAM
		ReadVMemElement,	; GST_VMEM
		DerefPtrElement		; GST_PTR

		; table of routines to dereference an element
derefElemTable	fptr	\
		DerefMemElement,	; GST_CHUNK
		DerefStreamElement,	; GST_STREAM
		DerefVMemElement,	; GST_VMEM
		DerefPtrElement		; GST_PTR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by GrDrawGString

CALLED BY:	INTERNAL
		GrDrawGStringAtCP
PASS:		si	- handle of GString to draw 
		di	- handle of GState to draw to
		dx	- GSControl flags (if required)
		    NOTE: if CheckEndCondition() is not going to be called,
		    (as is the case for GrSetGStringPos()), then the flags
		    are not used (or required).
		es	- GString block
		inherits DrawStringFrame

		carry	- set if are called from CopyString, so that we don't
			  need to do the transformation matrix stuff.
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringSetup	proc	far
DSframe		local	DrawStringFrame
		.enter inherit

		; save the parameters

		pushf					; save carry
		mov	DSframe.DSF_hSrc, si		; save handle
		mov	DSframe.DSF_hDest, di		; save handle
		mov	DSframe.DSF_flags, dx		; save them 

		; check for valid gstring operation

EC <		cmp	di, si				; bad idea...	>
EC <		ERROR_Z	GRAPHICS_NO_RECURSIVE_GSTRINGS	;  ..that's why	>

		; lock graphics string block

		mov	bx, si				; lock gstate	
		call	MemLock	
		mov	es, ax				; es -> GState
		mov	ax, es:[GS_gstring]		; get handle
EC <		tst	ax				; make sure valid >
EC <		ERROR_Z GRAPHICS_BAD_GSTRING_HANDLE	;  bogus, die	  >
		call	MemUnlock			; release gstate 
		mov	DSframe.DSF_hGString, ax	; save handle
		mov	bx, ax				; lock GString block
		call	MemLock				
		mov	es, ax				; es -> GString block

		; if it's a chunk-based GString, lock the chunk with the 
		; elements.  We'll unlock it again at the end of the routine.
		; Also, we don't store the segment anywhere, since it's an
		; LMem type thing and can move around on us.  We'll just 
		; deref the handle when we need to access the block.

		mov	bx, es:[GSS_flags]		; test the flags
		and	bx, mask GSF_HANDLE_TYPE	; isolate type
		cmp	bl, GST_CHUNK			; chunk based ?
		jne	checkStart			;  no, continue
		mov	bx, es:[GSS_hString]		; get chunk block han
		call	MemLock				; lock the block

		; if this is the intial call to DrawString, save the current
		; transform and translate the coord system to the current pos
		; If we're continuing, then don't re-save the transform.
checkStart:
		popf					; restore carry
		jc	done				;  if CopyString, skip
		test	es:[GSS_flags], mask GSF_CONTINUING
		jnz	done

		call	GrSaveTransform			; save the current xfrm
		call	GrGetCurPosWWFixed
		call	GrApplyTranslation		; translate to spot
		call	GrInitDefaultTransform		; make this the default
		or	es:[GSS_flags], mask GSF_CONTINUING
done:
		.leave
		ret
GStringSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finished drawing GString, do some cleanup.

CALLED BY:	INTERNAL
		GrDrawStringAtCP
PASS:		inherits DrawStringFrame
		dx	- GSRetType enum
		cx	- value appropriate to GSRetType in dx (see description
			  in GrDrawGString, above)
		es	- GString structure

		carry	- set if are called from CopyString, so that we don't
			  need to do the transformation matrix stuff.

RETURN:		GString structure unlocked
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		Things to cleanup:
			unlock any locked blocks;
			if we stopped on a NEW_PAGE or COMPLETE
			    restore the matrices.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringCleanup	proc	far
		uses	ax, di, bx
DSframe		local	DrawStringFrame
		.enter inherit

		jc	checkEnd			; no xform stuff for
		cmp	dx, GSRT_COMPLETE		;  CopyString
		je	restoreMatrix
		cmp	dx, GSRT_FAULT
		je	restoreMatrix
		cmp	dx, GSRT_NEW_PAGE
		jne	checkEnd	

		; time to restore the transformation matrix to what it was 
		; before the GString was played.  This includes the default
		; transformation.
restoreMatrix:
		and	es:[GSS_flags], not mask GSF_CONTINUING ; reset flag
		mov	di, DSframe.DSF_hDest		; get GState handle
		call	GrRestoreTransform		; restore GS_TMatrix

		; if we've hit the end of the GString, then reset the 
		; position back to the beginning.
checkEnd:
		cmp	dx, GSRT_COMPLETE		; if at END_STRING
		jne	checkStream

		; if we're at the END_STRING, reset it back to the beginning

		mov	ax, es:[GSS_flags]		; see if stream type
		and	ax, not mask GSF_ELEMENT_READY	; nothing ready
		mov	es:[GSS_flags], ax		; reset flags variable
		and	ax, mask GSF_HANDLE_TYPE 	; isolate handle info
		cmp	al, GST_STREAM			; if stream, bail
		je	doFileStuff

		; for all but the stream type, we just reset the curPos to zero

		clr	ax			; clear current position
		mov	es:[GSS_curPos].low, ax	;  this works for all but file
		mov	es:[GSS_curPos].high, ax ;  type

		; see if we are a vmem-based string and clean that up too
checkStream:
		mov	ax, es:[GSS_flags]		; see if stream type
		and	ax, mask GSF_HANDLE_TYPE 	; isolate handle info
		cmp	al, GST_STREAM			; if stream, bail
		je	unlockStream

		; see if we are a vmem-based string and clean that up too
checkVMemBlock:
		mov	bx, es:[GSS_flags]		; test the flags
		test	bx, mask GSF_VMEM_LOCKED	; if locked, undoit
		jnz	unlockVMem

		; see if we had a chunk-based gstring, and unlock the block
		; if we did

		and	bx, mask GSF_HANDLE_TYPE	; isolate type
		cmp	bl, GST_CHUNK			; chunk based ?
		je	unlockChunk			;  yes, unlock it

		; next thing is to unlock the GString block.
unlockGString:
		mov	bx, DSframe.DSF_hGString
		call	MemUnlock			; all clear.
		
		.leave
		ret

		; for stream types, reset the "file position"
doFileStuff:
		push	bx, cx, dx 
		mov	al, FILE_POS_START	;  assume beginning
		movdw	cxdx, es:[GSS_filePos]
		mov	bx, es:[GSS_hString]
		call	FilePosFar
		movdw	es:[GSS_curPos], dxax
		clr	es:[GSS_readBytesAvail]
		pop	bx, cx, dx
		jmp	checkVMemBlock

		; for stream types we need to restore the file position
		; to what it would be if we were not buffering the reads
		; we only use the term "unlock" for consistency with the
		; handle of the other GString types
unlockStream:   
		tst	es:[GSS_readBytesAvail] ;  are there excess bytes in buffer?
		je	checkVMemBlock          ;  if not, then continue normally
		push	bx, cx, dx 
		mov	al, FILE_POS_RELATIVE	;  back up relative to cur pos
		clr	dx
		xchg	dx, es:[GSS_readBytesAvail]
		neg	dx
		mov	cx, -1
		mov	bx, es:[GSS_hString]
		call	FilePosFar
		movdw	es:[GSS_curPos], dxax
		pop	bx, cx, dx
		jmp	checkVMemBlock

		; we have some HugeArray block locked.  Deal with it.
unlockVMem:
		push	ds
		mov	ds, es:[GSS_lastPtr].segment	; all we need is seg
		call	HugeArrayUnlock
		and	es:[GSS_flags], not mask GSF_VMEM_LOCKED
		pop	ds
		jmp	unlockGString 

		; unlock the block the chunk is in
unlockChunk:
		mov	bx, es:[GSS_hString]		; get chunk block han
		call	MemUnlock			; release the block
		jmp	unlockGString

GStringCleanup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a graphics string

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		si	- handle of GString to draw
			  (as returned by GrLoadString)
		ax,bx	- x,y coordinate at which to draw 
		dx	- control flags  (record of type GSControl):

RETURN:		dx	- enum of type GSRetType
		cx	- extra information, based on enum retuned in GSRetType
			  as follows:

				enum in dx		value in cx
				----------		-----------
				GSRT_COMPLETE 		nothing
				GSRT_NEW_PAGE 		PageEndCommand (in cl)
				GSRT_FAULT 		nothing
				GSRT_LABEL		label value 
				GSRT_ESCAPE  		escape number
				GSRT_ONE 		next opcode (in cl)
				GSRT_MISC		next opcode (in cl)
				GSRT_XFORM 		next opcode (in cl)
				GSRT_OUTPUT 		next opcode (in cl)
				GSRT_ATTR 		next opcode (in cl)
				GSRT_PATH 		next opcode (in cl)
				
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Interpret the drawing opcodes in the string, until a string
		terminator, end-of-file, user-defined escape or form-feed
		opcode (see flags above) is encountered.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Copied over from the kernel
	jim	4/92		lots of changes for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawGString	proc	far

		; before we do anything, we have to figure out if this
		; routine has been called already with this gstring, in
		; which case we don't want to reset the current position.

		push	ax,bx,ds
		mov	bx, si				; get source string
		call	MemLock				; ax -> GState
		mov	ds, ax
		mov	ax, ds:[GS_gstring]		; get handle to string
		call	MemUnlock			; release GState
EC <		tst	ax				; if zero, bail	>
EC <		ERROR_Z GRAPHICS_BAD_GSTRING_HANDLE	;  bogus, die	  >
		mov	bx, ax
		call	MemLock				; lock GString block
		mov	ds, ax				; ds -> GString
		test	ds:[GSS_flags], mask GSF_CONTINUING ; here before 
		call	MemUnlock			; leaves flags alone
		pop	ax,bx,ds			; restore everything
		jnz	alreadyMoved
		call	GrMoveTo			; set pen position
alreadyMoved:
		call	GrDrawGStringAtCP
		.leave
		ret
GrDrawGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawGStringAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a graphics string at the current position.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		si	- handle of GString to draw 
			  (as returned by GrLoadString)
		dx	- control flags  (record of type GSControl):

RETURN:		dx	- enum of type GSRetType
		cx	- extra information, based on enum retuned in GSRetType
			  as follows:

				enum in dx		value in cx
				----------		-----------
				GSRT_COMPLETE 		nothing
				GSRT_NEW_PAGE 		PageEndCommand (in cl)
				GSRT_FAULT 		nothing
				GSRT_LABEL		label value 
				GSRT_ESCAPE  		escape number
				GSRT_ONE 		next opcode (in cl)
				GSRT_MISC		next opcode (in cl)
				GSRT_XFORM 		next opcode (in cl)
				GSRT_OUTPUT 		next opcode (in cl)
				GSRT_ATTR 		next opcode (in cl)
				GSRT_PATH 		next opcode (in cl)
				
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawGStringAtCP	proc	far
		uses	si, ax, bx, ds, es
DSframe		local	DrawStringFrame
		.enter

		ForceRef	DSframe

		; store away the function arguments and do some setup work

		and	dx, not mask GSC_PARTIAL	; don't allow it here
		clc					; signal not CopyString
		call	GStringSetup			; es -> GString struc

		; if there is something already setup (that is, ReadElement 
		; was called, but PlayElement wasn't), then play the element
		; before we do anything.  

		test	es:[GSS_flags], mask GSF_ELEMENT_READY ; is one there ?
		jz	readNextElement
	
		call	ReadElement			; ds:si -> element
		cmp	{byte} ds:[si], GR_END_GSTRING	;  don't play past this
		je	deadAlready
		call	PlayElement			; bump past it

		; loop through all elements in string, until we hit something
		; we're not supposed to draw...
readNextElement:
		call	ReadElement			; set up next element
		jc	hosed
		call	CheckEndCondition		; see if done
		jc	donePlaying
		call	PlayElement			; draw the next one
		jmp	readNextElement

		; done with the gstring. cleanup and leave.
donePlaying:
		clc					; signal not CopyString
		call	GStringCleanup			; clean up things

		.leave
		ret

		; premature end.  what a cruel world.
deadAlready:
		mov	dx, GSRT_COMPLETE
		clr	cx
		jmp	donePlaying
		
		; premature termination.
hosed:
		mov	dx, GSRT_FAULT
		clr	cx
		jmp	donePlaying
GrDrawGStringAtCP	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEBitmapOptr
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
			GR_FILL_BITMAP_OPTR

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEBitmapOptr	proc	far
		uses	ds, si
		.enter
		mov	cx, ds:[si].ODBOP_x	; get position info
		mov	dx, ds:[si].ODBOP_y	; get position info
		movdw	bxsi, ds:[si].ODBOP_optr ; get resource handle
		push	bx			; save handle
		pushf
		call	MemLock			; lock it down
		mov	ds, ax			; ds -> resource
		mov	si, ds:[si]		; dereference chunk
		movdw	axbx, cxdx		; move coords over
		popf				; restore carry
		jc	figBounds		; do bounds calculation
callKernel:
		clr	cx, dx			; no callback routine
		call	Common_CallKernelRoutine
		pop	bx			; restore resource handle
		call	MemUnlock		; release block
		.leave
		ret

		; do bounds calc for bitmap
figBounds:
		call	GrGetBitmapSize
		xchgdw	axbx, cxdx
		add	cx, ax
		add	dx, bx
		call	BoundFillRect
		jmp	callKernel
PEBitmapOptr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a GR_DRAW_BITMAP opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
		inherits DrawStringFrame so we can see PARTIAL flag
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrDrawBitmap
			GrDrawBitmapAtCP
			GrFillBitmap
			GrFillBitmapAtCP

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PEBitmap	proc	far
		uses	si
DSframe		local	DrawStringFrame
		.enter	inherit

		; load up the coordinates to pass to the bitmap routines.  If
		; we are doing CP versions, they just won't be used.

		pushf				; save bounds flag
		mov	ax, ds:[si].ODB_x	; get coordinate to draw
		mov	bx, ds:[si].ODB_y
		mov	cl, ds:[si].ODB_opcode	; get this opcode
		add	si, size OpDrawBitmap	; ds:si -> BM header
		cmp	cl, GR_DRAW_BITMAP	; check for CP versions
		je	haveHdrPtr
		cmp	cl, GR_FILL_BITMAP
		jne	handleAtCP
haveHdrPtr:
		test	ds:[si].B_type, mask BMT_COMPLEX ; see if it's complex
		jnz	handleComplex
goforit:
		popf				; restore bounds flag
		jc	figBounds		; do bounds calc
callKernel:
		push	es:[LMBH_handle]	; find GString block again
		call	Common_CallKernelRoutine	; call the routine
		pop	bx
		call	MemDerefES		; es -> GString block

		.leave
		ret

		; we're doing one of the CP versions.  size is at a different
		; offset
handleAtCP:
		add	si, size OpDrawBitmapAtCP - size OpDrawBitmap
		call	GrGetCurPos		; for AtCP versions, need CP
		jmp	haveHdrPtr

		; we're drawing a complex bitmap.  Setup the callback routine
		; and other good stuff.
handleComplex:
		test	DSframe.DSF_flags, mask GSC_PARTIAL	; if partial
		jnz	partialCallback				;  diff callb
setupCallback:
		mov	ds:[si].CB_devInfo, bp	; save frame pointer
		mov	dx, SEGMENT_CS
		mov	cx, offset PEBitmapCB	; dx:cx = callback address
		jmp	goforit

		; do bounds calc for bitmap
figBounds:
		push	ax, bx, cx, dx
		movdw	cxdx, axbx
		call	GrGetBitmapSize
		xchgdw	axbx, cxdx
		add	cx, ax
		add	dx, bx
		call	BoundFillRect
		pop	ax, bx, cx, dx
		jmp	callKernel

		; if partial, callback should be NULL
		; but only if we would stop here anyway...
partialCallback:
		test	DSframe.DSF_flags, mask GSC_OUTPUT or mask GSC_ONE
		jz	setupCallback
		clr	cx, dx			; no callback...
		jmp	goforit
PEBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PESlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A specialty routine for bitmap slices when GrCopyGString is
		used in PARTIAL mode.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PESlice		proc	far
		uses	si, di, bx, cx, ax
DSframe		local	DrawStringFrame
		.enter	inherit

		; bail if we're not going to another GString

		push	ds
		mov	bx, di
		call	MemLock
		mov	ds, ax
		mov	ax, ds:[GS_gstring]
		mov	cx, ds:[GS_window]
		call	MemUnlock
		pop	ds

		or	cx, ax					; if no win or
		jz	done					;  gstring,bail
		tst	ax
		jz	done	

		; bail if we're not in partial mode

		test	DSframe.DSF_flags, mask GSC_PARTIAL	; must be...
EC <		ERROR_Z	GRAPHICS_BAD_GSTRING_ELEMENT_DATA		>
NEC <		jz	done					; else skip >

		; only writing to a GString here...

		mov	di, ax				; di = GString handle
		mov	al, GSE_BITMAP_SLICE
		mov	cl, 2
		mov	bx, ds:[si].OBS_size
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes

		mov	al, GSE_INVALID
		mov	ah, GSSC_FLUSH
		mov	cx, ds:[si].OBS_size
		add	si, size OpBitmapSlice
		call	GSStore
done:
		.leave
		ret
PESlice		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEBitmapPtr
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
			GR_FILL_BITMAP_PTR

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEBitmapPtr	proc	far
		uses	si
		.enter
		mov	ax, ds:[si].ODTP_x1	; get position info
		mov	bx, ds:[si].ODTP_y1	; get position info
		mov	si, ds:[si].ODTP_ptr	; load offset to bitmap data
		jc	figBounds
callKernel:
		clr	cx, dx			; no complex ones allowed
		call	Common_CallKernelRoutine
		.leave
		ret

figBounds:
		movdw	cxdx, axbx
		call	GrGetBitmapSize
		xchgdw	cxdx, axbx
		add	cx, ax
		add	dx, bx
		call	BoundFillRect
		jmp	callKernel
PEBitmapPtr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEBitmapCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to write next slice of bitmap

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to last slice

RETURN:		ds:si	- update pointer

DESTROYED:	es (else ec +segment death for VM gstrings)

PSEUDO CODE/STRATEGY:
		We need to inherit the DrawStringFrame variables, so we can
		read in the next slice.  BP is actually not correct as passed
		to this routine, but we've stored the correct value of BP in
		the CB_devInfo field of the bitmap header.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version
		jim	4/92		rewritten for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEBitmapCB	proc	far
		uses	bp, bx
DSframe		local	DrawStringFrame
		.enter	inherit

		mov	bp, ds:[si].CB_devInfo		; make the frame valid
		sub	si, size OpBitmapSlice		; assume it was a slice
		cmp	{byte} ds:[si], GSE_BITMAP_SLICE ; check assumption
		jne	notASlice
		
		; ds:si -> beginning of element.  Use ReadElement to read in
		; the next slice.
haveElemPtr:
		mov	bx, DSframe.DSF_hGString	; get handle to locked
		call	MemDerefES			;  block es -> GString
		call	ReadElement			; read the next element
		and 	es:[GSS_flags], not mask GSF_ELEMENT_READY
		cmp	{byte} ds:[si], GSE_BITMAP_SLICE ; see if we're done
		jne	doneWithBitmap

		; In order that the PESlice routine doesn't get called when 
		; we are done drawing, we need to update the internal 
		; pointers in the GString structure.  The operation depends 
		; on the type of GString (the current position in a VMem 
		; GString is the element number, for others it is an offset 
		; into the block/chunk/file.

		mov	bx, es:[GSS_flags]	; get flags
		and	bl, mask GSF_HANDLE_TYPE ; isolate gstring type
		cmp	bl, GST_VMEM		; different bump routine for vm
		je	bumpVMemCurPos
		mov	bx, es:[GSS_lastSize]
		add	es:[GSS_curPos].low, bx
		adc	es:[GSS_curPos].high, 0
playIt:
		add	si, size OpBitmapSlice		; else bump past GS
		mov	ds:[si].CB_devInfo, bp		; save frame ptr again
		clc					; signal valid slice
done:
		.leave
		ret

		; we're done with the bitmap.  Signal completion and exit.
doneWithBitmap:
		stc
		jmp	done

		; we just finished with the first slice.  It's either a 
		; GR_DRAW_BITMAP or a GR_DRAW_BITMAP_CP
notASlice:
		sub	si, (size OpDrawBitmap)-(size OpBitmapSlice)
		cmp	{byte} ds:[si], GR_DRAW_BITMAP
		je	haveElemPtr
		sub	si, (size OpDrawBitmapAtCP) - (size OpDrawBitmap)
		jmp	haveElemPtr

		; for all other gstring types, add in the current elem size
bumpVMemCurPos:
		incdw	es:[GSS_curPos]		; next element in HugeArray
		jmp	playIt

PEBitmapCB	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEByteAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret attribute elements with one byte arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; OUTPUT
			GrFillPath	(RegionFillRule)
			; ATTRIBUTE
			GrSetMixMode
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
PEByteAttr	proc	far

		; load the arguments and call the routine

		mov	al, ds:[si].OSMM_mode	; get byte

		; Move into CL as well, so GrFillPath can be called.

		mov	cl, al
		mov	ah, 0			; some routines need this 
		jc	figBounds
callKernel:
		call	Common_CallKernelRoutine
		ret

		; for this routine, the only significant opcode is GR_FILL_PATH
figBounds:
		cmp	ds:[si].OFLP_opcode, GR_FILL_PATH
		jne	callKernel
		push	ax,bx,cx,dx
		mov	ax, GPT_CURRENT
		call	GrGetPathBounds
		call	BoundFillRect
		pop	ax,bx,cx,dx
		jmp	callKernel
PEByteAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PESetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret SetFont call

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PESetFont	proc	far

		; load the arguments and call the routine

		mov	ah, ds:[si].OSF_size.WBF_frac	; assume SetFont
		mov	dx, ds:[si].OSF_size.WBF_int	; 
		mov	cx, ds:[si].OSF_id		; get FontID
		call	GrSetFont
		ret
PESetFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret draw_text elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PEDrawText	proc	far
		uses	si
		.enter
.assert (offset ODT_x1) eq (offset ODTCP_len)

		; getting at least one word, then check for funct
		; assume GrDrawText
	
		mov	ax, ds:[si].ODT_x1	; first word was x coord
		mov	bx, ds:[si].ODT_y1
		mov	cx, ds:[si].ODT_len
		jc	figBounds
		cmp	{byte} ds:[si], GR_DRAW_TEXT	; different for each
		jne	doCP
		add	si, size OpDrawText

		; have params, call routine
callKernel:
		jcxz	done			; if no text, we're done
						; (the length field is always
						;  valid in a GString, so we
						;  don't have to worry about
						;  NULL-terminated strings)
		call	Common_CallKernelRoutine
done:
		.leave
		ret

		; no bounds, but we're doing the Current Pos thing
doCP:
		mov	cx, ax			; move size over
		add	si, size OpDrawTextAtCP
		jmp	callKernel

		; need to compute the bounds of the text
figBounds:
		cmp	{byte} ds:[si], GR_DRAW_TEXT	; different for each
		jne	getDrawPos
		add	si, size OpDrawText
getBounds:
		jcxz	done			; if no text, we're done
						; (the length field is always
						;  valid in a GString, so we
						;  don't have to worry about
						;  NULL-terminated strings)
		call	BoundText
		jmp	callKernel
getDrawPos:
		mov	cx, ax			; size is first word here
		call	GrGetCurPos		; ax,bx = current position
		add	si, size OpDrawTextAtCP	; ds:si -> text
		jmp	getBounds

PEDrawText	endp

GraphicsCommon ends

;---------------------------------------------------------
;---------------------------------------------------------
;---------------------------------------------------------

GraphicsString	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallKernelRoutine
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

GS_CallKernelRoutine proc	near
DSframe		local	DrawStringFrame
		.enter	inherit
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		movdw	bxax, es:[GSS_lastKern]
		call	ProcCallFixedOrMovable
		.leave
		ret
GS_CallKernelRoutine endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCreateGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a graphics string, start redirecting graphics orders to
		the string.

CALLED BY:	GLOBAL

PASS:		cl	- type of handle passed in bx (enum GStringType):
			      GST_CHUNK	- memory handle:chunk
			      GST_STREAM	- stream handle
			      GST_VMEM		- VM file handle
			  
		bx	- handle of entity in which to store graphics string.
			  (one of: {memory,stream,vmem file} handle)

RETURN:		di 	- handle of graphics string
		si	- allocated chunk/VMBlock handle (as appropriate)
			    (for GST_CHUNK and GST_VMEM types only)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/89		Initial version
		Jim	11/89		Broke out substring definition to
					another routine
		Jim	2/90		Added GState support
		Jim	3/90		Added VMem support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrCreateGString	proc	far
		uses	ax, cx			; save some regs
		.enter
		mov	ch, mask CGSC_WRITING	; initiating writing
		clr	si			; allocate me a block
		call	AllocGString		; allocate the handle/structs
		.leave
		ret
GrCreateGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEditGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a graphics string into an editing mode

CALLED BY:	GLOBAL

PASS:		bx:si	- VM file:block handle to HugeArray where gstring 
			  is stored (Editing only works for GST_VMEM types)

RETURN:		di	- handle of graphics string to edit (actually a GState
			  handle)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrEditGString	proc	far
		uses	ax, cx			; save some regs
		.enter
		mov	cl, GST_VMEM
		mov	ch, mask CGSC_WRITING	; initiating writing
		call	AllocGString		; allocate the handle/structs
		.leave
		ret
GrEditGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrParseGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a graphics string by calling back on desired elements.

CALLED BY:	GLOBAL

PASS:		di	- GState handle or 0
		si	- handle of GString to draw 
			  (as returned by GrLoadString)
		dx	- control flags  (record of type GSControl):
		bx:cx	- vfptr to callback routine

RETURN:		nothing
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		When the callback routine is called, the following is set
		up:

			PASS:	ds:si	- pointer to element.
				bx	- BP passed to GrParseGString
				di 	- GState handle passed to GrParseGString

			RETURN:	ax	- TRUE if finished, else
					  FALSE to continue parsing.
				ds	- as passed or segment of another
					  huge array block in vm based
					  gstrings. See Special Processing
					  below.
		
			MAY DESTROY: ax,bx,cx,dx,di,si,bp,es
					
			Must *NOT* write into, realloc, move or otherwise 
			munge the block pointed to by ds.

			Special Processing:
				In huge array based gstrings the call back 
				routine	may change ds to point to other huge 
				array blocks in the gstring. In this case, 
				upon returning from the call back, 
				GrParseGString will unlock the huge array 
				block now referenced by ds and relock the
				the huge array block originally passed
				to the call back. All gstring elements will
				be processed.


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrParseGString	proc	far
		uses	si, ax, bx, ds, es, cx, dx
DSframe		local	DrawStringFrame
		.enter
if FULL_EXECUTE_IN_PLACE
	;
	;  In XIP kernels, we need to make sure the far pointer does not
	;  reference something in an XIP'ed resource (since this code is
	;  in a movable resource and might have just been banked over the
	;  callback routine...
EC<		xchg	cx, si						>
EC<		call	ECAssertValidFarPointerXIP			>
EC<		xchg	si, cx						>
endif
		mov	ax, ss:[bp]			; get old BP
		mov	DSframe.DSF_savedBP, ax		; save for callback
		movdw	DSframe.DSF_callBack,bxcx


		; store away the function arguments and do some setup work

		and	dx, not mask GSC_PARTIAL	; don't allow it here
		stc					; signal no xforms
		call	GStringSetup			; es -> GString struc

		; if there is something already setup (that is, ReadElement 
		; was called, but PlayElement wasn't), then play the element
		; before we do anything.  

		test	es:[GSS_flags], mask GSF_ELEMENT_READY ; is one there ?
		jz	readNextElement
	
		call	ReadElement			; ds:si -> element
		cmp	{byte} ds:[si], GR_END_GSTRING	; don't go past this
		je	deadAlready
		call	PlayElement			; bump past it

		; loop through all elements in string, until we hit something
		; we're not supposed to draw...
readNextElement:
		call	ReadElement			; set up next element
		jc	hosed
		call	CheckEndCondition		; see if done
		jc	foundElement
playElement:
		call	PlayElement			; draw the next one
		jmp	readNextElement

		; do the callback
foundElement:
		cmp	dx, GSRT_COMPLETE		; if done, exit
		je	donePlaying
		push	si, bp, dx, cx, di

		push	ds,es				; element, GString seg
		mov	cl, ds:[si]			; get opcode
		cmp	cl, GR_ESCAPE
		jne	doCallBack
		mov	dx, ds:[si].OE_escCode		; load escape type
doCallBack:
if	FULL_EXECUTE_IN_PLACE
		mov	ss:[TPD_dataAX], ax		; faster than push/pop
		mov	ax, DSframe.DSF_savedBP
		mov	ss:[TPD_dataBX], ax
		movdw	bxax, DSframe.DSF_callBack
		call	ProcCallFixedOrMovable
else
		mov	bx,  DSframe.DSF_savedBP	; give them access 
		call	ss:DSframe.DSF_callBack		; call caller
endif
		pop	bx,es				; passed element seg
							; GString seg

		; If this is a gstring in a vmem the call back routine
		; may have advanced to another block in the gstring.

CheckHack <offset GSF_HANDLE_TYPE eq 0 >
		mov	dx,es:[GSS_flags]
		andnf	dx,mask GSF_HANDLE_TYPE
		cmp	dx,GST_VMEM
		je	checkForNewBlock
popRest:
		pop	si, bp, dx, cx, di

		cmp	ax, TRUE			; see if done
		jne	playElement

		; done with the gstring. cleanup and leave.
donePlaying:
		stc					; signal not CopyString
		call	GStringCleanup			; clean up things

		.leave
		ret

		; END_GSTRING was the first element.  bummer.
deadAlready:
		mov	dx, GSRT_COMPLETE
		clr	cx
		jmp	donePlaying

		; premature termination.
hosed:
		mov	dx, GSRT_FAULT
		clr	cx
		jmp	donePlaying

checkForNewBlock:
		; If the returned segment is different we need to unlock
		; the block currently being pointed to and lock the
		; original block so that we can continue processing
		; where we left off.

		mov	dx,ds			; returned segemnt
		cmp	dx,bx			; returned seg, passed seg
		je	popRest
		push	ax			; call back return flags
		call	HugeArrayUnlock
		mov	bx,es:[GSS_hString]
		mov	di,es:[GSS_firstBlock]
		movdw	dxax,es:[GSS_curPos]
		call	HugeArrayLock
		mov	es:[GSS_lastPtr].segment,ds; orig block may have moved
		pop	ax			; call back return flags
		jmp	popRest

GrParseGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCopyGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a graphics string

CALLED BY:	GLOBAL

PASS:		si	- source gstring
		di	- destination gstring

		dx	- control flags  (record of type GSControl):

RETURN:		dx	- enum of type GSRetType
		cx	- extra info as appropriate to the value in dx:

				enum in dx		value in cx
				----------		-----------
				GSRT_COMPLETE 		nothing
				GSRT_NEW_PAGE 		nothing
				GSRT_FAULT 		nothing
				GSRT_LABEL		label value 
				GSRT_ESCAPE  		escape number
				GSRT_ONE 		next opcode (in cl)
				GSRT_MISC		next opcode (in cl)
				GSRT_XFORM 		next opcode (in cl)
				GSRT_OUTPUT 		next opcode (in cl)
				GSRT_ATTR 		next opcode (in cl)
				GSRT_PATH 		next opcode (in cl)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Write elements found in input GString to output GString, until
		we're done.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Moved over from the kernel
	Jim	04/92		rewritten for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCopyGString	proc	far
		uses	si, ax, bx, ds, es
DSframe		local	DrawStringFrame
		.enter

		ForceRef	DSframe

		; store away the function arguments and do some setup work

		stc					; signal CopyString
		call	GStringSetup			; es -> GString struc

		; if there is something already setup (that is, ReadElement 
		; was called, but PlayElement wasn't), then play the element
		; before we do anything.  

		test	es:[GSS_flags], mask GSF_ELEMENT_READY ; is one there ?
		jz	readNextElement
	
		call	ReadElement			; ds:si -> element
		cmp	{byte} ds:[si], GR_END_GSTRING	; play it anyway
		pushf
		call	PlayElement			; bump past it
		popf
		je	deadAlready			; play, but don't keep

		; loop through all elements in string, until we hit something
		; we're not supposed to draw...
readNextElement:
		call	ReadElement			; set up next element
		jc	hosed
		call	CheckEndCondition		; see if done
		jc	donePlaying			;  yes, cleanup
		call	PlayElement			; draw the next one
		jmp	readNextElement

		; done with the gstring. cleanup and leave.
donePlaying:
		stc					; signal CopyString
		call	GStringCleanup			; clean up things

		.leave
		ret

		; first element was an END_GSTRING.  Didn't know what hit me.
deadAlready:
		mov	dx, GSRT_COMPLETE
		clr	cx
		jmp	donePlaying

hosed:
		mov	dx, GSRT_FAULT
		clr	cx
		jmp	donePlaying
GrCopyGString	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetGStringElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract an element from a graphics string

CALLED BY:	GLOBAL

PASS:		di	- handle to GState
		si	- handle to GString
		cx	- size of buffer to put element into
		ds:bx	- far pointer to buffer

RETURN:		al	- opcode of element
		cx	- actual size of element

		NOTE:	  if there are no elements left to get, al is
			  returned as GSE_INVALID, and cx = zero.

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		if (buffer is large enough to hold element)
		    copy element;
		return size of element;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetGStringElement	proc	far
		uses	es, ds, di, bx, si, dx
DSframe		local	DrawStringFrame
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		jcxz	xipOK						>
EC <		push	bx, si						>
EC <		mov	si, bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx, si						>
xipOK::
endif		
		ForceRef	DSframe

		push	ax				; save passed ah

		; store away the function arguments and do some setup work

		stc					; signal not drawing
		push	bx, cx
		call	GStringSetup			; es -> GString struc
		pop	bx, cx

		push	es:[LMBH_handle]		; save GString block
		push	di				; save GString handle
		push	ds, bx				; save destination addr

		push	cx
		call	ReadElement			; get it all in memory
		pop	cx
		jc	readError

		; see if the buffer is big enough.  If not, copy what we have 
		; and return the right info

		cmp	cx, es:[GSS_lastSize]		; buffer big enough ?
		jbe	haveCopySize
		mov	cx, es:[GSS_lastSize]
haveCopySize:
		pop	es, di				; es:di -> destination
		mov	al, ds:[si]			; grab opcode
		jcxz	doneCopy
		rep	movsb				; copy the data
		clc					; return no error

		; all done, so return some useful info and cleanup
doneCopy:
		pop	di				; restore gstring handle
		call	MemDerefStackES			; restore gstring seg
		mov	cx, es:[GSS_lastSize]		; return element size
doneCommon:
		pop	dx				; restore old ah
		mov	ah, dh				; return it intact
		mov	dx, GSRT_ONE
		stc					; signal not drawing
		call	GStringCleanup			; all done...

		.leave
		ret

		; ReadElement failed.  Clear destination address from stack.
readError:
		add	sp, 4				; don't need dest addr
		mov	al, GSE_INVALID			; setup error return
		pop	di				; restore gstring handle
		call	MemDerefStackES			; restore gstring seg
		clr	cx
		jmp	doneCommon

GrGetGStringElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetGStringBoundsDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get coordinate bounds of a graphics string

CALLED BY:	GLOBAL
PASS:		di	- graphics state handle, or 0 for no graphics state
		si	- graphics string handle
		dx	- enum of type GSControl
		ds:bx - fptr to buffer the size of RectDWord

RETURN:		ds:bx - RectDWord structure filled with bounds		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If the GString is empty, this routine returns bounds of
		(0,0) to (0,0).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetGStringBoundsDWord		proc	far
		uses	ax, bx, cx, dx, di, si, ds, es
DSframe		local	DrawStringFrame
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx, si					>
EC <		movdw	bxsi, dsbx				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>
endif		
		push	ds, bx		; save pointer to result structure

		and	dx, not mask GSC_PARTIAL	; no partial elements

		; If we are passed a bogus GState (by Steve, probably), then
		; allocate one.

		tst	di				; check bogosity
		jnz	haveGState
		call	GrCreateState
		push	si
		segmov	ds, ss
		lea	si, DSframe.DSF_tempMatrix
		call	GrGetTransform
		pop	si
		jmp	initBounds

		; we want to save the GState, and use one without a Window,
		; since we don't really want to draw anything.  
haveGState:		
		push	si, dx
		segmov	ds, ss
		lea	si, DSframe.DSF_tempMatrix
		call	GrGetFont			; cx, dx.ah = font
		pushwwf	dxax
		call	GrGetTransform
		call	GrGetLineWidth			; affects outcome
		pushwwf	dxax
		call	GrGetCurPos			; ax, bx = pos
		clr	di
		call	GrCreateState
		call	GrSetTransform
		call	GrMoveTo
		popwwf	dxax
		call	GrSetLineWidth
		popwwf	dxax				; cx, dx.ah = font
		call	GrSetFont
		pop	si, dx

		; initialize bounds
initBounds:
		mov	ax, 0xffff			; init right/bot to neg
		mov	ss:DSframe.DSF_brBound.PDF_x.DWF_int.high, ax
		mov	ss:DSframe.DSF_brBound.PDF_y.DWF_int.high, ax
		clr	ax				; init top/left to pos
		mov	ss:DSframe.DSF_brBound.PDF_x.DWF_int.low, ax
		mov	ss:DSframe.DSF_brBound.PDF_y.DWF_int.low, ax
		mov	ss:DSframe.DSF_tlBound.PDF_x.DWF_int.high, ax
		mov	ss:DSframe.DSF_tlBound.PDF_y.DWF_int.high, ax
		mov	ax, 0x3fff
		mov	ss:DSframe.DSF_tlBound.PDF_x.DWF_int.low, ax
		mov	ss:DSframe.DSF_tlBound.PDF_y.DWF_int.low, ax

		; store away the function arguments and do some setup work

		stc					; signal not playing
		call	GStringSetup			; es -> GString struc


		; set the flag in the GString structure that tells PlayElement
		; that we want to get the bounds, not play the darn thing.

		or	es:[GSS_flags], mask GSF_FIGURE_BOUNDS

		; if there is something already setup (that is, ReadElement 
		; was called, but PlayElement wasn't), then play the element
		; before we do anything.  

		test	es:[GSS_flags], mask GSF_ELEMENT_READY ; is one there ?
		jz	readNextElement
	
		call	ReadElement			; ds:si -> element
		cmp	{byte} ds:[si], GR_END_GSTRING
		jne	playFirst
		mov	dx, GSRT_COMPLETE
		clr	cx
		jmp	donePlaying
playFirst:
		call	PlayElement			; bump past it

		; loop through all elements in string, until we hit something
		; we're not supposed to draw...
readNextElement:
		call	ReadElement			; set up next element
		jc	donePlaying
		call	CheckEndCondition		; see if done
		jc	donePlaying			;  yes, cleanup
		call	PlayElement			; draw the next one
		jmp	readNextElement

		; done with the gstring. cleanup and leave.
donePlaying:
		and	es:[GSS_flags], not mask GSF_FIGURE_BOUNDS
		stc					; signal CopyString
		call	GStringCleanup			; clean up things

		; before we untransform the coordinates, make sure that
		; the bounds are reasonable -- that is, make sure that 
		; left is smaller than the right.  If not, it means the 
		; GString was empty and we should fixup the values to return.

		mov	ax, ss:DSframe.DSF_brBound.PDF_x.DWF_int.high
		cmp	ax, ss:DSframe.DSF_tlBound.PDF_x.DWF_int.high
		jl	emptyGString			; bail if empty

		; get the values stored in the stack frame, and untransform
		; them through the transformation matrix.

		segmov	ds, ss
		lea	si, ss:DSframe.DSF_tempMatrix	; ds:si -> orig matrix
		call	GrSetTransform			; setup new transform
		
		clr	ax, si
		cmpwwf	ss:DSframe.DSF_tempMatrix.TM_e12, siax	; these should
		jnz	doRotate				;  be zero
		cmpwwf	ss:DSframe.DSF_tempMatrix.TM_e21, siax
		jnz	doRotate

		segmov	es, ss
		lea	dx, ss:DSframe.DSF_tlBound	; do top left
		call	GrUntransformDWFixed
		lea	dx, ss:DSframe.DSF_brBound	; do bottom right
		call	GrUntransformDWFixed
		jmp	storeResults

		; GString is empty.  Zero out the coords and exit
emptyGString:
		call	GrDestroyState			; nuke extra GState
		pop	es, di				; ds:si -> results rect
		mov	cx, (size RectDWord) / 2	; # of words => CX
		clr	ax
		rep	stosw				; stuff it with zeroes
		jmp	done

		; untransform PAGE coordinate bounds through a rotated matrix.
doRotate:
		call	UnTransRotBounds

		; Store our results, after checking to see that the
		; bounds are ordered & properly rounded
storeResults:
		call	GrDestroyState			; nuke extra GState
		pop	ds, si				; ds:si -> results rect
		movdwf	axbxdi, ss:DSframe.DSF_tlBound.PDF_x
		rnddwf	axbxdi
		movdwf	cxdxdi, ss:DSframe.DSF_brBound.PDF_x
		rnddwf	cxdxdi
		jledw	axbx, cxdx, xSorted
		xchgdw	axbx, cxdx
xSorted:
		movdw	ds:[si].RD_left, axbx
		movdw	ds:[si].RD_right, cxdx
		
		; Finished left & right. Now deal with top & bottom.
		;
		movdwf	axbxdi, ss:DSframe.DSF_tlBound.PDF_y
		rnddwf	axbxdi
		movdwf	cxdxdi, ss:DSframe.DSF_brBound.PDF_y
		rnddwf	cxdxdi
		jledw	axbx, cxdx, ySorted
		xchgdw	axbx, cxdx
ySorted:
		movdw	ds:[si].RD_top, axbx
		movdw	ds:[si].RD_bottom, cxdx
done:
		.leave
		ret
GrGetGStringBoundsDWord		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetGStringBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the coordinate bounds of a graphics string drawn at the 
		current position

CALLED BY:	GLOBAL

PASS:		di	- graphics state handle, or 0 for no graphics state
		si	- graphics string handle
		dx	- enum of type GSControl

RETURN:		carry	- set on any overflow, else
		ax	- left side coord of smallest rect enclosing string
		bx	- top coord
		cx	- right coord
		dx	- bottom coord

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (encounter a GR_SET_GSTRING_BOUNDS element)
		    use the values in there;
		else
		    Get bounds of each item in string;
		    Accumulate the net bounds;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* The coordinates are returned relative to the transformation
		  matrix in place AT THE BEGINNING of the operation. 

		* This procedure starts working at the "current GString
		  position" (ie, the current element number), which
		  may or may not be the beginning of the GString.  To
		  get the size of the entire string, make sure to call
		  GrSetGStringPos, passing GSSPT_BEGINNING, BEFORE calling 
		  this routine.

		ALSO, 


		* The "current GString position" after this operation 
		  depends on what is passed in the GSControl flags. So, you 
		  probably want to call GrSetGStringPos directly after
		  this call, in order to set the position back to where it
		  was before the call.

		* If the GString is empty, this routine returns bounds of
		  (0,0) to (0,0).

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetGStringBounds proc	far
		uses	si, ds, es
		push	di	
		mov_tr	ax, di			;Save gstate handle
		mov	di, 1000
		call	ThreadBorrowStackSpace
		xchg	di, ax			;DI <- gstate handle
						;AX <- val returned from TBSS
		push	ax			;Save value from ThreadBorrowSS

dwBounds	local	RectDWord
		.enter

		segmov	ds, ss, bx
		lea	bx, dwBounds

		call	GrGetGStringBoundsDWord

		; grab the untransformed values and round the results

		movdw	siax, ss:dwBounds.RD_left
		CheckDWordResult si, ax
		jc	done
		movdw	sibx, ss:dwBounds.RD_top
		CheckDWordResult si, bx
		jc	done
		movdw	sicx, ss:dwBounds.RD_right
		CheckDWordResult si, cx
		jc	done
		movdw	sidx, ss:dwBounds.RD_bottom
		CheckDWordResult si, dx
done:
		.leave
		pop	di
		call	ThreadReturnStackSpace
		pop	di			;Restore gstate handle
		ret
GrGetGStringBounds endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetGStringPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current position of a string

CALLED BY:	GLOBAL

PASS:		si		- gstring handle
		al		- GStringSetPosType enum
					GSSPT_SKIP_1	- skip 1 element
					GSSPT_RELATIVE	- skip N elements
					GSSPT_BEGINNING	- start of string
					GSSPT_END	- end of string

		cx		- #elements to skip if GSSPT_RELATIVE chosen
				  (this number can be negative for HugeArray
				   based gstrings, but must be positive 
				   otherwise).

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetGStringPos	proc	far
		uses	ax, bx, cx, dx, di, ds, si, es
DSframe		local	DrawStringFrame
		.enter

		ForceRef	DSframe

		; clear DI so GStringSetup doesn't get confused

		clr	di

		; store away the function arguments and do some setup work

		stc					; signal not drawing
		push	ax, cx
		call	GStringSetup			; es -> GString struc
		pop	ax, cx

		cmp	al, GSSPT_BEGINNING		; special stuff 
		je	resetGString			;  to backup

		cmp	al, GSSPT_END			; special stuff 
		je	resetGString			;  to go to end

		cmp	al, GSSPT_SKIP_1		; just skip one element
		jne	haveElemCount
		mov	cx, 1

		; have element count.  Take a shortcut for VMem based ones.
haveElemCount:
		mov	dx, es:[GSS_flags]	; see if HugeArray type
		and	dx, mask GSF_HANDLE_TYPE ; isolate handle info
		cmp	dl, GST_VMEM		; if not vmem, bail
		je	moveVMemRelative

		; for non-VMem based GStrings, only allow positive counts

		tst	cx				; make sure we're > 0
		jns	readNextElement
EC <		ERROR	GRAPHICS_BAD_GSTRING_TYPE			>
NEC <		jmp	done						>

		; loop through all elements in string, until we hit something
		; we're not supposed to draw...
readNextElement:
		push	cx				; save count
		call	ReadElement			; set up next element
		jc	noMoreElements

		mov	es:[GSS_lastRout].offset, offset PENull
		mov	es:[GSS_lastRout].segment, handle PENull
		call	PlayElement			; advance to next
		pop	cx
		loop	readNextElement

		; done. cleanup and leave.
done:
		mov	dx, GSRT_MISC
		stc					; signal CopyString
		call	GStringCleanup			; clean up things

		.leave
		ret

		; we get here if ReadElement fails (because there are no
		; more elements to read)
noMoreElements:
		pop	cx
		jmp	done

		; we allow backing up, but only for the HugeArray code
moveVMemRelative:
		mov	ax, cx				; make it a dword 
		cwd					;   signed number
		adddw	es:[GSS_curPos], dxax
		jmp	done

		; go to the beginning of the gstring
resetGString:
		mov	dx, es:[GSS_flags]		; see if stream type
		and	dx, not mask GSF_ELEMENT_READY	; nothing ready
		mov	es:[GSS_flags], dx		; reset flags variable
		and	dx, mask GSF_HANDLE_TYPE 	; isolate handle info
		cmp	dl, GST_STREAM			; if stream, bail
		je	doFileStuff

		; see if going to beginning or end...

		cmp	al, GSSPT_BEGINNING	; if not beginning...
		jne	resetToEnd

		; for all but the stream type, we just reset the curPos to zero

		clr	ax			; clear current position
		mov	es:[GSS_curPos].low, ax	;  this works for all but file
		mov	es:[GSS_curPos].high, ax ;  type
		jmp	done

		; for stream types, reset the "file position"
doFileStuff:
		cmp	al, GSSPT_BEGINNING	; go to beginning or end ?
		mov	al, FILE_POS_START	;  assume beginning
		movdw	cxdx, es:[GSS_filePos]
		je	setFilePos
		mov	al, FILE_POS_END
		clr	cx, dx
setFilePos:
		mov	bx, es:[GSS_hString]
		call	FilePosFar
		movdw	es:[GSS_curPos], dxax
		clr	es:[GSS_readBytesAvail]
		jmp	done

		; go to the end of the GString.  Depends on type...
resetToEnd:
		cmp	dl, GST_PTR		; no can do for ptr
EC <		ERROR_Z	GRAPHICS_CANT_POS_PTR_GSTRING_TO_END		>
NEC <		je	done			; just bail in non-ec	>
		cmp	dl, GST_CHUNK		; if chunk based, find size
		je	posChunkAtEnd
EC <		cmp	dl, GST_VMEM		; must be HugeArray based >
EC <		ERROR_NE GRAPHICS_BAD_GSTRING_TYPE			>

		; for VMem ones, just get the count

		mov	bx, es:[GSS_hString]	; get VM file handle
		mov	di, es:[GSS_firstBlock]	;  and block handle
		call	HugeArrayGetCount	; dxax = #elements
		movdw	es:[GSS_curPos], dxax	; set curPos at end
		jmp	done

		; for Chunk ones, get the size of the chunk
posChunkAtEnd:
		mov	bx, es:[GSS_hString]	; get block handle
		call	MemLock			; ax -> block with chunk
		mov	ds, ax
		mov	si, es:[GSS_firstBlock]	; get chunk handle
		ChunkSizeHandle	ds, si, si	; si = size of chunk
		call	MemUnlock		; release block
		mov	es:[GSS_curPos].low, si	; store position
		jmp	done

GrSetGStringPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDeleteGStringElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a range of GString elements

CALLED BY:	GLOBAL
PASS:		di	- GState handle (points to graphics string)
		cx	- number of elements to delete (starting with element
			  at current position)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrDeleteGStringElement		proc	far
		uses	es, bx, ax, dx, di
		.enter

		mov	bx, di			; lock GState
		call	MemLock
		mov	es, ax			; es -> GState		
		mov	ax, es:[GS_gstring]	; get gstring handle
		call	MemUnlock
EC <		tst	ax			; check for null gstring >
EC <		ERROR_Z	GRAPHICS_BAD_GSTRING_HANDLE			>
		mov	bx, ax			; bx = gstring handle
		push	bx			; save block handle
		call	MemLock			; lock gstring structure
		mov	es, ax			; es -> GString structure
EC <		mov	ax, es:[GSS_flags]		; see if vmem type >
EC <		and	ax, mask GSF_HANDLE_TYPE 	; isolate handle info>
EC <		cmp	al, GST_VMEM			; if not vmem, bail >
EC <		ERROR_NE GRAPHICS_BAD_GSTRING_TYPE			>
		mov	bx, es:[GSS_hString]	; get vm file handle
		mov	di, es:[GSS_firstBlock]	; get vm block handle
		movdw	dxax, es:[GSS_curPos]	; get current position
		call	HugeArrayDelete
		pop	bx			; restore GString block handle
		call	MemUnlock		; releae block
		.leave
		ret
GrDeleteGStringElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnTransRotBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Untransform the bounds determined by GrGetGStringBounds

CALLED BY:	INTERNAL
		GrGetGStringBoundsDWord
PASS:		inherits stack frame
RETURN:		ax...dx		- rectangle bounds, in doc coords
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnTransRotBounds proc	near
		uses	ax, dx, di
		.enter	inherit	GrGetGStringBoundsDWord

		; make a copy of the coords for the other corners

		movdwf	ss:DSframe.DSF_trCorner.PDF_y,\
			ss:DSframe.DSF_tlBound.PDF_y, ax
		movdwf	ss:DSframe.DSF_trCorner.PDF_x,\
			ss:DSframe.DSF_brBound.PDF_x, ax
		movdwf	ss:DSframe.DSF_blCorner.PDF_y,\
			ss:DSframe.DSF_brBound.PDF_y, ax
		movdwf	ss:DSframe.DSF_blCorner.PDF_x,\
			ss:DSframe.DSF_tlBound.PDF_x, ax

		; untransform all four corners

		segmov	es, ss
		lea	dx, ss:DSframe.DSF_tlBound	; do top left
		call	GrUntransformDWFixed
		lea	dx, ss:DSframe.DSF_brBound	; do bottom right
		call	GrUntransformDWFixed
		lea	dx, ss:DSframe.DSF_blCorner	; do bottom left
		call	GrUntransformDWFixed
		lea	dx, ss:DSframe.DSF_trCorner	; do top right
		call	GrUntransformDWFixed

		; sort the results.

		movdw	axdx, ss:DSframe.DSF_tlBound.PDF_x.DWF_int
		jledw	axdx, ss:DSframe.DSF_brBound.PDF_x.DWF_int, xSorted
		xchgdw	axdx, ss:DSframe.DSF_brBound.PDF_x.DWF_int
		movdw	ss:DSframe.DSF_tlBound.PDF_x.DWF_int, axdx 
xSorted:
		movdw	axdx, ss:DSframe.DSF_tlBound.PDF_y.DWF_int
		jledw	axdx, ss:DSframe.DSF_brBound.PDF_y.DWF_int, ySorted
		xchgdw	axdx, ss:DSframe.DSF_brBound.PDF_y.DWF_int
		movdw	ss:DSframe.DSF_tlBound.PDF_y.DWF_int, axdx

		; now we have to do another check to find the mins and maxs
		; after the transformations.  Use the tlBound and brBound
		; variables to keep the min and max.
ySorted:
		movdwf	siaxdi, DSframe.DSF_blCorner.PDF_x
		call	CheckGSBX
		movdwf	siaxdi, DSframe.DSF_trCorner.PDF_x
		call	CheckGSBX
		movdwf	siaxdi, DSframe.DSF_blCorner.PDF_y
		call	CheckGSBY
		movdwf	siaxdi, DSframe.DSF_trCorner.PDF_y
		call	CheckGSBY
		
		.leave
		ret
UnTransRotBounds endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckGSBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check an X coordinate against current min/max

CALLED BY:	INTERNAL
		UnTransRotBounds
PASS:		siaxdi	- DWFixed coord to check
RETURN:		nothing
DESTROYED:	si,ax,di

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckGSBX	proc	near
		.enter	inherit GrGetGStringBoundsDWord

		cmp	si, DSframe.DSF_tlBound.PDF_x.DWF_int.high
		jl	newLow
		jg	checkHigh
		cmp	ax, DSframe.DSF_tlBound.PDF_x.DWF_int.low
		jl	newLow
checkHigh:
		cmp	si, DSframe.DSF_brBound.PDF_x.DWF_int.high
		jg	newHigh
		jl	done
		cmp	ax, DSframe.DSF_brBound.PDF_x.DWF_int.low
		jg	newHigh
done:
		.leave
		ret

newLow:
		xchgdwf	siaxdi, DSframe.DSF_tlBound.PDF_x
		jmp	checkHigh

newHigh:
		xchgdwf	DSframe.DSF_brBound.PDF_x, siaxdi
		cmp	si, DSframe.DSF_tlBound.PDF_x.DWF_int.high
		jl	makeHighLow
		jg	done
		cmp	ax, DSframe.DSF_tlBound.PDF_x.DWF_int.low
		jge	done
makeHighLow:
		movdwf	DSframe.DSF_tlBound.PDF_x, siaxdi		
		jmp	done
CheckGSBX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckGSBY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check an Y coordinate against current min/max

CALLED BY:	INTERNAL
		UnTransRotBounds
PASS:		siaxdi	- DWFixed coord to check
RETURN:		nothing
DESTROYED:	si,ax,di

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckGSBY	proc	near
		.enter	inherit GrGetGStringBoundsDWord

		cmp	si, DSframe.DSF_tlBound.PDF_y.DWF_int.high
		jl	newLow
		jg	checkHigh
		cmp	ax, DSframe.DSF_tlBound.PDF_y.DWF_int.low
		jl	newLow
checkHigh:
		cmp	si, DSframe.DSF_brBound.PDF_y.DWF_int.high
		jg	newHigh
		jl	done
		cmp	ax, DSframe.DSF_brBound.PDF_y.DWF_int.low
		jg	newHigh
done:
		.leave
		ret

newLow:
		xchgdwf	siaxdi, DSframe.DSF_tlBound.PDF_y
		jmp	checkHigh

newHigh:
		xchgdwf	DSframe.DSF_brBound.PDF_x, siaxdi
		cmp	si, DSframe.DSF_tlBound.PDF_x.DWF_int.high
		jl	makeHighLow
		jg	done
		cmp	ax, DSframe.DSF_tlBound.PDF_x.DWF_int.low
		jge	done
makeHighLow:
		movdwf	DSframe.DSF_tlBound.PDF_x, siaxdi		
		jmp	done
CheckGSBY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDerefPtrGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a pointer-type gstring

CALLED BY:	EXTERNAL
		Path code.
PASS:		si	- GString handle
RETURN:		ds:si	- pointer to current element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrDerefPtrGString	proc	far
		uses	ax, bx
		.enter

		; get things started...

		mov	bx, si				; lock gstate	
		call	MemLock	
		mov	ds, ax				; es -> GState
		mov	ax, ds:[GS_gstring]		; get handle
EC <		tst	ax				; make sure valid >
EC <		ERROR_Z GRAPHICS_BAD_GSTRING_HANDLE	;  bogus, die	  >
		call	MemUnlock			; release gstate 
		mov	bx, ax				; lock GString block
		call	MemLock				
		mov	ds, ax				; es -> GString block

		; if we're not a memory type, bail

EC <		mov	ax, ds:[GSS_flags]				>
EC <		and	al, mask GSF_HANDLE_TYPE	; isolate type	>
EC <		cmp	al, GST_PTR			; must be ptr	>
EC <		ERROR_NE GRAPHICS_INVALID_GSTRING_TYPE			>

		; just grab the current pointer

		mov	si, ds:[GSS_firstBlock]	; get base position
		add	si, ds:[GSS_curPos].low	; add offset
		mov	ds, ds:[GSS_hString]	; get segment

		call	MemUnlock			; release GString blk

		.leave
		ret
GrDerefPtrGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefMemElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the next element from a chunk-based GString

CALLED BY:	INTERNAL
		ReadElement
PASS:		inherits DrawStringFrame
		es	- GString block
RETURN:		carry	- set if some problem reading element
			  else: ds:si	- points at element
				   cx	- element size
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefMemElement	proc	far
DSframe		local	DrawStringFrame
		.enter	inherit

		; this is easy, since the element is already there.  Just
		; dereference the block that it is in and set si to curPos

		mov	bx, es:[GSS_hString]		; get block handle
		call	MemDerefDS			; ds -> block
		mov	si, es:[GSS_firstBlock]		; get chunk handle
		mov	si, ds:[si]			; ds:si -> chunk start
		add	si, es:[GSS_curPos].low		; ds:si -> cur element
		clc
		
		.leave
		ret
DerefMemElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefStreamElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Already an element in the buffer, point at it.

CALLED BY:	INTERNAL
		ReadElement
PASS:		es	- GString block
RETURN:		ds:si	- points at element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefStreamElement	proc	far
		.enter

		segmov	ds, es, si		; ds -> GString block
		mov	si, ds:[GSS_fileBuffer]
		mov	si, ds:[si]		; ds:si -> filebuff chunk
		clc

		.leave
		ret
DerefStreamElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadStreamElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the next element from a stream

CALLED BY:	INTERNAL
		ReadElement

PASS:		inherits DrawStringFrame
		es	- GString 

RETURN:		carry	- set if some error reading stream
			  or if the opcode read is invalid
		if carry is clear:
		    ds:si	- far pointer to the element read it

DESTROYED:	bx, cx, dx, ax

PSEUDO CODE/STRATEGY:
		If (variable sized element)
		    read enough to figure out how big it will be
		If (chunk for file buffer not big enough)
		    resize it
		Read in element

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadStreamElement proc	far
DSframe		local	DrawStringFrame
		.enter	inherit
		
		; read in a single byte, to see what the element type is.

		segmov	ds, es				; ds -> GString block
		mov	cx, 1				; read one byte
		clr	dx				; at 0 offset in chunk
		call	ReadStreamBytes			; read 'em in
		jc	done				; bail on error
		
		; the opcode is in the buffer.  Calculate how big the element
		; is.  We may need to read more to determine this

		mov	bl, ds:[si]			; get opcode
		cmp	bl, GStringElement		; make sure in range
		cmc
		jc	done				; bad opcode

		push	ds
		push	bx
		mov	bx, handle GSElemInfoTab
		call	MemLock
		mov	ds, ax
		pop	bx
				CheckHack <(size GSElemInfo) eq 10>
		clr	bh				; bx = opcode
		shl	bx				; *2
		mov	ax, bx
		shl	bx				; *4
		shl	bx				; *8
		add	bx, ax
		mov	ax, ds:GSElemInfoTab[bx].GSEI_size ; al = elem size
		mov	bx, handle GSElemInfoTab
		call	MemUnlock
		pop	ds

		test	ah, 0xc0			; if high bits set, var
		jnz	variableSize			; we need more info
		cmp	al, 1				; if single byte, done
		jb	done				; unclaimed opcode
		ja	readMore
doneOK:
		clc
done:
		.leave
		ret
		
		; it's a fixed sized element, but we have more to read
readMore:
		mov	dx, 1				; read in past opcode
		mov	cx, ax				; 
		clr	ch				; cx = element size
		dec	cx				; already read first
		call	ReadStreamBytes			; read in extra bytes

		; if the element is a GR_DRAW_TEXT_FIELD element, then there
		; is more to read (style runs, etc).  

		cmp	{byte} ds:[si], GR_DRAW_TEXT_FIELD ; if so...
		jne	doneOK

		; OK, we have more to read.  Get the total character count,
		; and loop til we've read all the style runs

		call	ReadStreamStyleRuns
		jmp	done

		; have a variable sized element. Read in a little more, so 
		; we can figure out how much more to read.
variableSize:
		mov	cl, al				; read the rest of the
		clr	ch
		dec	cx				; already read one, 
		mov	dx, 1				; 
		call	ReadStreamBytes			; have enough to tell
		jc	done				; bail on error
		mov	cl, ah
		and	cx, 3fh				; ds:[si][cx] = offset
		add	si, cx				; ds:si -> count word
		mov	dx, ds:[si]			; grab count word
		sub	si, cx
		mov	cx, dx
		mov	dl, al
		clr	dh
		test	ah, 0x80			; *2 or *4 ?
		jz	haveCount
		shl	cx, 1				; at least words
		test	ah, 0x40			; might be dwords
		jz	haveCount
		shl	cx, 1
haveCount:
		cmp	{byte} ds:[si], GR_SET_PALETTE	; if this, 3* count
		je	hackForSetPalette
readVarBytes:
		call	ReadStreamBytes			; read in rest of data
		jmp	done
		
		; we lied about there being byte values in the SetPalette
		; element, cause we have no flag for "three-byte values".  So
		; calculate the real number here.
hackForSetPalette:
		push	ax
		mov	ax, cx
		shl	cx, 1
		add	cx, ax
		pop	ax
		jmp	readVarBytes
		
ReadStreamElement endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadStreamStyleRuns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the style runs associated with GR_DRAW_TEXT_FIELD

CALLED BY:	INTERNAL
		ReadStreamElement
PASS:		ds:si	- pointer to start of element in GS_fileBuffer
RETURN:		carry	- set if some error in disk reading, else
		ds:si	- still points to structure, though the pointer may
			  have changed.
DESTROYED:	cx, dx, ax

PSEUDO CODE/STRATEGY:
		Keep reading style runs until we have all the characters in.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadStreamStyleRuns	proc	near
DSframe		local	DrawStringFrame
		.enter	inherit

		; First get the total number of characters we have to read.

		mov	cx, ds:[si].ODTF_saved.GDFS_nChars
		mov	dx, size OpDrawTextField	; offset to first
							;  style run spot

		; Now loop through all the nice style runs.  They are stored
		; with the TFStyleRun structure first, then the text string.
styleRunLoop:
		push	cx			; save number of chars left
		mov	ax, dx			; save offset to start of run
		mov	cx, size TFStyleRun	; first read in the structure
		call	ReadStreamBytes
		jc	doneError
		add	si, ax			; ds:si -> TFStyleRun
		mov	cx, ds:[si].TFSR_count	; get char count for this run
DBCS <		shl	cx, 1			; Char to byte count	>
		add	ax, size TFStyleRun
		mov	dx, ax
		call	ReadStreamBytes		; read in character string
		jc	doneError
		add	ax, cx			; ax = offset to next run
		mov	dx, ax			; needs to be in dx
DBCS <		shr	cx, 1			; Byte to char count	>
		mov	ax, cx			; ax = #chars just read
		pop	cx			; restore #chars left
		sub	cx, ax			; fewer to go
EC <		ERROR_S	GRAPHICS_BAD_GSTRING_ELEMENT_DATA	>
		jnz	styleRunLoop		;
		clc
done:
		.leave
		ret

		; some error reading from disk
doneError:
		pop	cx			; restore stack
		jmp	done
ReadStreamStyleRuns	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadStreamBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to read a few bytes from a stream.

CALLED BY:	INTERNAL
		ReadStreamElement
PASS:		ds,es	- GString block
		dx	- offset into GSS_fileBuffer to read into
		cx	- #bytes to read
RETURN:		carry	- set if some error reading file
		ds:si	- start of GSS_fileBuffer chunk
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		The higher-level code assumes that the chunk
		GSS_fileBuffer holds the GStringElement data
		in a specific location, so we do buffered file
		reads in a separate chunk.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/16/92		Initial version
	Don	3/21/00		Added buffered FileReads

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MIN_CHUNK_RESIZE	equ	32

ReadStreamBytes	proc	near
		uses	ax, cx, di
		.enter

		mov	si, ds:[GSS_fileBuffer]		; use file buffer
		ChunkSizeHandle ds, si, ax		; ax = size of chunk
		mov	di, ds:[si]			; get pointer to buffer
		add	cx, dx				; cx = total chunk size
							;  after read
		cmp	ax, cx				; if zero, resize chunk
		jb	resizeChunk

		; alright, we have enough room to read, so copy the data
copyData:
		sub	cx, dx				; cx = bytes to copy
		add	di, dx				; es:di = destination
copyDataLow:		
		mov	si, ds:[GSS_readBuffer]
		mov	si, ds:[si]
		add	si, ds:[GSS_readOffset]
		cmp	cx, ds:[GSS_readBytesAvail]
		ja	copyDataPartial
		add	ds:[GSS_readOffset], cx
		sub	ds:[GSS_readBytesAvail], cx
		rep	movsb

		; clean up

		mov	si, ds:[GSS_fileBuffer]
		mov	si, ds:[si]
		clc
done:
		.leave
		ret

		; not enough room.  Resize it.
resizeChunk:
		mov	ax, ds:[GSS_fileBuffer]		; get chunk handle
		add	cx, MIN_CHUNK_RESIZE		; resize a little extra
		call	LMemReAlloc			; resize chunk
		sub	cx, MIN_CHUNK_RESIZE		; get back chunk size
		mov	di, ax				; deref chunk again
		mov	di, ds:[di]			; ds:di -> chunk
		jmp	copyData			; now we have enough

		; partially fill the request
copyDataPartial:
		mov	ax, cx				; ax = bytes desired
		clr	cx
		xchg	cx, ds:[GSS_readBytesAvail]	; cx = byte available
		jcxz	fileRead
		sub	ax, cx
		rep	movsb		

		; read data from the file
fileRead:		
		push	ax				; bytes we still need
		mov	si, ds:[GSS_readBuffer]
		ChunkSizeHandle	ds, si, ax
		mov	cx, GS_READ_BUFFER_SIZE		
		cmp	ax, cx
EC <		ERROR_A	GRAPHICS_INTERNAL_ERROR_IN_GSTRING_READ_BUFFERING >
		je	fileReadLow
		mov	ax, ds:[GSS_readBuffer]
		call	LMemReAlloc
		mov	si, ax
		mov	di, es:[GSS_fileBuffer]
		mov	di, es:[di]
		add	di, dx
fileReadLow:
		mov	bx, ds:[GSS_hString]		; get file handle
		clr	al				; we want errors
		mov	dx, ds:[si]			; ds:dx = read buffer
		call	FileReadFar			; cx = bytes read
		pop	dx				; dx=bytes still needed
		jc	fileReadError
fileReadDone:		
		mov	ds:[GSS_readBytesAvail], cx
		clr	ds:[GSS_readOffset]
		mov	cx, dx				; cx=bytes still needed
		jmp	copyDataLow

		; some error on reading.  Set a flag
fileReadError:
		cmp	ax, ERROR_SHORT_READ_WRITE
		jne	fileReadErrorReal
		cmp	cx, dx				; is file too short?
		jae	fileReadDone			; ...nope, we're OK
fileReadErrorReal:
		or	ds:[GSS_flags], mask GSF_ERROR
		stc
		jmp	done
ReadStreamBytes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefVMemElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the next vmem element

CALLED BY:	INTERNAL
		ReadElement
PASS:		inherits DrawStringFrame
RETURN:		ds:si	-> next element
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefVMemElement proc	far
DSframe		local	DrawStringFrame
		.enter	inherit

		; see if the vmem block is already locked.  If so, just grab
		; the pointer.

		test	es:[GSS_flags], mask GSF_VMEM_LOCKED
		jz	lockIt

		movdw	dssi, es:[GSS_lastPtr]
done:
		clc
		.leave
		ret

		; for now, just use HugeArrayLock
lockIt:
		push	di, dx, cx, ax
		movdw	dxax, es:[GSS_curPos]	; get this element
		mov	bx, es:[GSS_hString]	; file handle
		mov	di, es:[GSS_firstBlock]	; vmem block handle
		call	HugeArrayLock		; ds:si -> block
		or	es:[GSS_flags], mask GSF_VMEM_LOCKED
		mov	es:[GSS_vmemNext], ax
		mov	es:[GSS_vmemPrev], cx
		pop	di, dx, cx, ax
		jmp	done
DerefVMemElement endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadVMemElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the next vmem element

CALLED BY:	INTERNAL
		ReadElement
PASS:		inherits DrawStringFrame
RETURN:		carry	- set if some problem, else
			ds:si	-> next element
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadVMemElement proc	far
DSframe		local	DrawStringFrame
		.enter	inherit
EC <		call	ECCheckStack					>

		; see if the vmem block is already locked.  If so, just grab
		; the pointer.

		test	es:[GSS_flags], mask GSF_VMEM_LOCKED
		jz	lockIt

		movdw	dssi, es:[GSS_lastPtr]
		inc	es:[GSS_vmemPrev]		; update opt vars
		dec	es:[GSS_vmemNext]		; if negative, go to
		jz	nextVMemBlock			;  the next block
		add	si, es:[GSS_lastSize]		; ds:si -> next elem
done:
		.leave
		ret

		; for now, just use HugeArrayLock
lockIt:
		push	di, dx, ax, cx
		movdw	dxax, es:[GSS_curPos]	; get this element
		mov	bx, es:[GSS_hString]	; file handle
		mov	di, es:[GSS_firstBlock]	; vmem block handle
		call	HugeArrayLock		; ds:si -> block
		mov	es:[GSS_vmemNext], ax
		mov	es:[GSS_vmemPrev], cx
		tst	ax			; check for NULL element
		pop	di, dx, ax, cx
		je	nullElement		; ..and jump if found
		or	es:[GSS_flags], mask GSF_VMEM_LOCKED
;;;		clc				; carry flag cleared by OR
		jmp	done

		; done with all the elements in this block, go to next one
nextVMemBlock:
		call	HugeArrayNext		; read in next block
		clr	es:[GSS_vmemPrev]	; no previous ones
		mov	es:[GSS_vmemNext], ax 	; save number in new block
		tst	ax			; make sure no error
		clc
		jnz	done
nullElement:
		or	es:[GSS_flags], mask GSF_ERROR ; signal error
		stc
		jmp	done
ReadVMemElement endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PENoArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with no arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
		es	- GString block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; MISC
			GrNullOp
			; TRANSFORM
			GrSetNullTransform
			GrSetDefaultTransform
			GrInitDefaultTransform
			GrSaveTransform
			GrRestoreTransform
			; OUTPUT
			GrDrawPointAtCP
			GrDrawPath
			; ATTRIBUTES
			GrSaveState
			GrRestoreState
			GrCreatePalette
			GrDestroyPalette
			; PATH
			GrEndPath
			GrCloseSubPath
			GrSetStrokePath			

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PENoArgs	proc	far
		jc	figBounds
callKernel:
		call	GS_CallKernelRoutine
PENull		label	far
		ret

		; might be DrawPointAtCP
figBounds:
		cmp	{byte} ds:[si], GR_DRAW_PATH
		je	pathBounds
		cmp	{byte} ds:[si], GR_DRAW_POINT_CP
		jne	callKernel
		call	GrGetCurPos
		call	BoundFillCoord
		jmp	callKernel

		; it's a GrDrawPath.  Need the path bounds
pathBounds:
		mov	ax, GPT_CURRENT
		call	GrGetPathBounds
		call	BoundLineRect
		jmp	callKernel
PENoArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEOneCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with one coordinate value

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load args from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; OUTPUT
			GrDrawLineTo
			GrDrawRectTo
			GrDrawPoint
			GrFillRectTo
			; ATTRIBUTE
			GrMoveTo
			GrSetPaletteEntry
			GrSetLineWidth
			GrSetMiterLimit
			; PATH
			GrBeginPath

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEOneCoord	proc	far
		.enter

		; load the arguments and call the routine

		mov	bx, ds:[si].ODP_y1
		mov	dx, bx			; put here to cover more rout
		mov	ax, ds:[si].ODP_x1
		mov	cx, ax	
		jc	figBounds		; do bounds calc
callKernel:
		cmp	ds:[si].ODP_opcode, GR_SET_PALETTE_ENTRY
		jne	doIt
		xchg	al, ah			; these stored sitched
doIt:
		call	GS_CallKernelRoutine

		.leave
		ret

figBounds:
		cmp	ds:[si].ODP_opcode, GSE_FIRST_OUTPUT_OPCODE
		jb	callKernel
		cmp	ds:[si].ODP_opcode, GSE_LAST_OUTPUT_OPCODE
		ja	callKernel
		call	GrGetCurPos	; ax,bx = current position
		cmp	ds:[si].ODP_opcode, GR_DRAW_LINE_TO
		je	figLine
		cmp	ds:[si].ODP_opcode, GR_FILL_RECT_TO
		je	figFillBound
		call	BoundLineRect
		jmp	callKernel

figFillBound:
		call	BoundFillRect
		jmp	callKernel

		; just a line.
figLine:
		call	BoundLine
		jmp	callKernel
PEOneCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PERelCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with one coordinate value

CALLED BY:	INTERNAL
		PlayElement
PASS:		ds:si	- pointer to element
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; OUTPUT
			GrDrawRelLineTo
			; ATTRIBUTE
			GrRelMoveTo

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PERelCoord	proc	far
		.enter

		; load args and call routine

		movdw	dxcx, ds:[si].ODRLT_x2
		movdw	bxax, ds:[si].ODRLT_y2
		jc	figBounds
callKernel:
		call	GS_CallKernelRoutine
		.leave
		ret

		; do relative bounds calculation
figBounds:
		cmp	{byte} ds:[si], GR_REL_MOVE_TO
		je	callKernel
		cmp	{byte} ds:[si], GR_MOVE_TO_WWFIXED
		je	callKernel
		push	ax, bx
		call	GrGetCurPos
		call	BoundLineCoord
		pop	ax, bx
		call	BoundRelCoord
		jmp	callKernel
PERelCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETwoCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with two coordinate values

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load args from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; MISC
			GrSetGStringBounds
			; OUTPUT
			GrDrawLine
			GrDrawRect
			GrDrawEllipse
			GrFillRect
			GrFillEllipse


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETwoCoords	proc	far
		.enter

		; load the arguments and call the routine

		mov	ax, ds:[si].ODL_x1
		mov	bx, ds:[si].ODL_y1
		mov	cx, ds:[si].ODL_x2
		mov	dx, ds:[si].ODL_y2
		jc	figBounds
callKernel:
		call	GS_CallKernelRoutine

		; restore regs and leave

		.leave
		ret

		; need to figure the bounds of the object
figBounds:
		cmp	{byte} ds:[si], GR_FILL_RECT
		je	figFillBound
		cmp	{byte} ds:[si], GR_FILL_ELLIPSE
		je	figFillEllipse
		cmp	{byte} ds:[si], GR_SET_GSTRING_BOUNDS
		je	figFillBound
		cmp	{byte} ds:[si], GR_DRAW_ELLIPSE
		je	figDrawEllipse
		call	BoundLineRect
		jmp	callKernel

figFillBound:
		call	BoundFillRect
		jmp	callKernel

		; Ellipses. 
		; We want to ultimately call the CalcEllipse routine elsewhere
		; in the kernel to generate the points along the ellipse, 
		; then call the appropriate BoundPolyLine or BoundPolyFill
figFillEllipse:
		push	bx, ds, si, cx
		push	bp
		mov	bp, offset BoundSetupEllipse
		call	GetArcCoords		; bx = block handle
		pop	bp
		jc	doneCoords
		call	BoundDevFillPoly
ellipseBoundCommon:
		call	MemFree			; free coord block
doneCoords:
		pop	bx, ds, si, cx
		jmp	callKernel

		; drawing an ellipse.  This gets complicated
figDrawEllipse:
		push	bx, ds, si, cx
		push	bp
		mov	bp, offset BoundSetupEllipse
		call	GetArcCoords		; bx = block handle
		pop	bp
		jc	doneCoords
		call	BoundDevLinePoly
		jmp	ellipseBoundCommon
PETwoCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PE3ByteAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with RGB color arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; ATTRIBUTE
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
PE3ByteAttr	proc	far

		; get the components, call the routine

		mov	al, ds:[si].OSAC_color.RGB_red		  ; get R
		mov	bx, {word} ds:[si].OSAC_color.RGB_green ; get G, B
		mov	ah, CF_RGB
		call	GS_CallKernelRoutine
		ret
PE3ByteAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEWordAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret attribute elements with one word arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; MISC
			GrLabel
			; ATTRIBUTE
			GrSetTextStyle
			GrSetTextMode
			GrSetTrackKern
			GrSetSuperscriptAttr
			GrSetSubscriptAttr


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEWordAttr	proc	far

		; load the arguments and call the routine

		mov	ax, {word} ds:[si].OSTM_mask	; get word
		mov	cx, ax			; path stuff wants this
		call	GS_CallKernelRoutine
		ret
PEWordAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle SetPalette

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetPalette

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEPalette	proc	far
		uses	si
		.enter

		mov	cx, ds:[si].OSP_num	; get count
		lodsb				; get starting number
		add	si, 2			; ds:si -> data
		mov	dx, ds			; dx:si -> data
		call	GrSetPalette		; call routine

		.leave
		ret
PEPalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEPathArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret SetPath elements 

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetClipPath
			GrSetWinClipPath


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEPathArgs	proc	far

		; load the arguments and call the routine

		mov	dl, ds:[si].OSCP_rule	; get fill rule
		mov	cx, ds:[si].OSCP_flags	; get combine type
		call	GS_CallKernelRoutine
		ret
PEPathArgs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PELineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret attribute elements with one word arguments

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PELineStyle	proc	far

		; load the arguments and call the routine

		mov	al, ds:[si].OSLS_style
		mov	bl, ds:[si].OSLS_index
		call	GrSetLineStyle
		ret
PELineStyle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PESpacePad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret SetTextSpacePad element

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PESpacePad	proc	far

		; get the components, call the routine

		movwbf	dxbl, ds:[si].OSTSP_pad		; get space padding
		call	GrSetTextSpacePad	; call routine to set color 
		ret
PESpacePad	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret drawchar elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
		carry set if we are just getting the bounds
RETURN:		nothing
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
PEDrawChar	proc	far

		; load up the character to draw

if DBCS_PCGEOS
		mov	dx, ds:[si].ODC_char	; get the character
else
		mov	dl, ds:[si].ODC_char	; get the character
		;DON'T CHANGE THIS TO "CLR", AS WE USE THE CARRY BELOW
EC <		mov	dh,0			; single-byte char	>
endif

		; if we're doing bounds stuff, branch here

		mov	bx, ds:[si].ODC_y1	; load coords.  It's OK for CP
		mov	ax, ds:[si].ODC_x1
		jc	figBounds

		; call the routine
callKernel:
		call	GS_CallKernelRoutine
		ret

		; we need to calculate the bounds.  Load up the correct args
		; and do the right thing.
figBounds:
		cmp	ds:[si].ODC_opcode, GR_DRAW_CHAR
		jne	getCurPos
getTextBounds:
		inc	si			; point at character
		mov	cx, 1
		call	BoundText
		dec	si
		jmp	callKernel

		; doing the AtCP thing, get the current text position
getCurPos:
		call	GrGetCurPos
		jmp	getTextBounds
PEDrawChar	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements with transformation matrices passed

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data

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
PETMatrix	proc	far
		
		; args already set up, just call

		inc	si			; bump to TransMatrix data
		call	GS_CallKernelRoutine
		dec	si			; restore pointer
		ret
PETMatrix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret elements from a clip rect opcode
CALLED BY:	PlayElement()

PASS:		ds:si - ptr to element data
		di - handle of GState
		bx - GStringElement x 2
RETURN:		ds:si - ptr past element data
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: OpSetClipRect & OpSetWinClipRect are equivalent
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/90		Initial version
	don	7/25/91		Changed parameters to GrSetClip[Doc]Rect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Flags that were previously passed to GrSetAppClipRect() & GrSetWinClipRect().
; They are no longer passed, but a conversion from the old flags to the new is
; left for compatability with 1.0 GStrings.
;
SetApplClipRegionFlags	record
	SACRF_REPLACE:1
	:1
	SACRF_NULL:1
	SACRF_RECT:1
	:12
SetApplClipRegionFlags	end

PEClipRect	proc	far
	uses	si
	.enter

	cmp	{byte} ds:[si], GR_SET_CLIP_RECT 	; see which one it is...
	pushf					; save results of comparison
	mov	ax, ds:[si].OSCR_rect.R_left 	; load coords
	mov	bx, ds:[si].OSCR_rect.R_top
	mov	cx, ds:[si].OSCR_rect.R_right
	mov	dx, ds:[si].OSCR_rect.R_bottom
	mov	si, ds:[si].OSCR_flags		; si <- PathCombineType
	test	si, mask SACRF_REPLACE or mask SACRF_NULL
	jz	continue			; if neither set, PCP_ passed
	test	si, mask SACRF_REPLACE		; was replace set ??
	mov	si, PCT_NULL			; assume not, and use NULL
	jz	continue
	mov	si, PCT_REPLACE			; else replace was set
continue:
	popf					; restore results of comparison
	jne	callDocRect
	call	GrSetClipRect
done:
	.leave
	ret

callDocRect:
	call	GrSetWinClipRect
	jmp	done
PEClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawRoundRects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret rounded rectangle & some arc-related elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; OUTPUT
			GrDrawRoundRect
			GrFillRoundRect
			GrDrawRoundRectTo
			GrFillRoundRectTo

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEDrawRoundRects	proc	far
		uses	si
		.enter
	
		; load up the radius and some coords

		push	ds:[si].ODRR_radius	; get the radius (goes in si)
		pushf				; save carry (for bounds)
		mov	ax, ds:[si].ODRR_x1	; get coord
		mov	cx, ax			; could be a "RectTo" routine
		mov	bx, ds:[si].ODRR_y1	; get coord
		mov	dx, bx			; could be a "RectTo" routine
		cmp	{byte} ds:[si], GR_DRAW_ROUND_RECT_TO
		je	rrectTo
		cmp	{byte} ds:[si], GR_FILL_ROUND_RECT_TO
		je	rrectTo

		; It's not a "RectTo" routine, load up the other coordinate

		mov	cx, ds:[si].ODRR_x2	; load up opposite corner
		mov	dx, ds:[si].ODRR_y2

		; Call the routine.
haveParams:
		popf				; restore carry
		jc	figBounds
getRadius:
		pop	si			; restore radius
		call	GS_CallKernelRoutine

		.leave
		ret

		; a To routine.  Load up the current position
rrectTo:
		call	GrGetCurPos
		jmp	haveParams

		; calculate the bounds of the object
figBounds:
		cmp	{byte} ds:[si], GR_FILL_ROUND_RECT
		je	figFillBound
		cmp	{byte} ds:[si], GR_FILL_ROUND_RECT_TO
		je	figFillBound
		call	BoundLineRect
		jmp	getRadius

figFillBound:
		call	BoundFillRect
		jmp	getRadius

PEDrawRoundRects	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawArcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret arc-related elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

		        ; OUTPUT
			GrDrawArc
			GrFillArc
			GrDrawArc3Point
			GrFillArc3Point
			GrDrawArc3PointTo
			GrFillArc3PointTo
			GrDrawRelArc3PointTo

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEDrawArcs	proc	far
		uses	si
		.enter

		; pass a struct in DS:SI to the appropriate routine
		;

		jc	figBounds		; do bounds for ARC routines
		inc	si			; just point to the params
callKernel:
		call	GS_CallKernelRoutine	; call the routine

		.leave
		ret

		; do bounds calc for arc routines
figBounds:
		lodsb				; grab opcode
		push	ds, si, bx, cx
		push	bp
		mov	bp, offset BoundSetupArc
		cmp	al, GR_FILL_ARC		;  check assumption
		je	boundFillArc
		cmp	al, GR_DRAW_ARC
		je	boundArc
		mov	bp, offset BoundSetupRelArc
		cmp	al, GR_DRAW_REL_ARC_3POINT_TO
		je	boundArc
		mov	bp, offset BoundSetup3PointTo
		cmp	al, GR_FILL_ARC_3POINT_TO
		je	boundFillArc
		cmp	al, GR_DRAW_ARC_3POINT_TO
		je	boundArc
		mov	bp, offset BoundSetup3Point
		cmp	al, GR_FILL_ARC_3POINT
		je	boundFillArc
boundArc:
		call	GetArcCoords
		pop	bp
		jc	doneCoords
		call	BoundDevLinePoly	; bound like polycoord rout
boundArcCommon:
		call	MemFree			; release the puny block
doneCoords:
		pop	ds, si, bx, cx
		jmp	callKernel

boundFillArc:
		call	GetArcCoords
		pop	bp
		jc	doneCoords
		call	BoundDevFillPoly
		jmp	boundArcCommon
PEDrawArcs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundSetupArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various callback routines for arc bounds setup

CALLED BY:	INTERNAL
		GetArcCoords
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoundSetupArc	proc	near
		call	SetupArcLowFar
		ret
BoundSetupArc	endp

BoundSetupRelArc	proc	near
		call	SetupRelArc3PointToLowFar
		ret
BoundSetupRelArc	endp

BoundSetup3PointTo	proc	near
		call	SetupArc3PointToLowFar
		ret
BoundSetup3PointTo	endp

BoundSetup3Point	proc	near
		call	SetupArc3PointLowFar
		ret
BoundSetup3Point	endp

BoundSetupEllipse proc	near
		mov	di, CET_ELLIPSE 
		ret
BoundSetupEllipse endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetArcCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get coord list for points along an arc

CALLED BY:	INTERNAL
PASS:		ds:si	- pointer to arc coords
		di	- GState handle
		bp	- setup routine to call

RETURN:		carry	- SET if there is nothing else to do, else
		
		if carry is CLEAR:
		bx	- handle of blocks holding point
		ds:si	- pointer to points
		cx	- number of points

DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetArcCoords	proc	near
		uses ax, dx
		.enter

		; lock down the GState since we'll need that eventually.
		; Make like we don't have a window, so that we'll get back
		; all the points.

		push	di			; save GState handle
		push	ds:[si].AP_close	; save for CloseArcFar
		push	ds			; save pointer to params
		push	ax			; save for param for ellipse
		xchg	bx, di			; bx = GState handle
		call	MemLock			; 
		xchg	bx, di			; bx = GState handle
		mov	ds, ax			; ds -> GState
		pop	ax			; restore ellipse parameter

		; call the local setup routine

		cmp	bp, offset BoundSetupEllipse
		je	doEllipse
		pop	ax			; ax:si -> parameters
		sub	sp, SETUP_AE_BUFFER_SIZE ; allocate stack frame
		mov	bx, bp			; setup routine in bx
		mov	bp, sp			; ss:bp -> scratch space
		call	bx
		
		; Generate the points in an ellipse or arc
		;
genPoints:
		test	di, mask CEF_COLINEAR	; check for colinear points
		jnz	handleLine
		mov	si, sp			; parameters => SS:SI
		call	CalcEllipse		; calculate point buffer
		tst	bx
		jz	haveBlock		; if no block, bail

		; if we were drawing an arc, handle the close type

		cmp	di, CET_ELLIPSE
		je	haveBlock
		call	CloseArcFar		; handle close type
haveBlock:
		add	sp, SETUP_AE_BUFFER_SIZE+2 ; free structure and arc 
						   ;  close type

		; fix things up, release the GState

		pop	di			; restore GState handle
		xchg	di, bx			; need to release GState
		call	MemUnlock		; release it
		xchg	di, bx			

		; lock down Ellipse points block if there

		tst	bx
		stc				; anticipate nothing to do
		jz	done
		tst	cx			; if this is an empty arc, bail
		stc	
		jz	done
		call	MemLock	
		mov	ds, ax
		clr	si			; ds:si -> ellipse points

		clc
done:
		.leave
		ret

doEllipse:
		add	sp, 2			; don't need segment on stack
		sub	sp, SETUP_AE_BUFFER_SIZE ; allocate stack frame
		call	bp
		jmp	genPoints

handleLine:
		push	ax,bx,cx
		mov	ax, 8			; only need 8 bytes
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK 
		call	MemAllocFar
		mov	ds, ax			; ds -> block
		clr	si
		mov	ds:[(size Point)].P_y, dx ; store second point
		pop	ax,dx,cx
		mov	ds:[0].P_x, ax		; store other points
		mov	ds:[0].P_y, dx
		mov	ds:[(size Point)].P_x, cx
		call	MemUnlock		; release for a second
		mov	cx, 2			; two coords
		jmp	haveBlock
GetArcCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEDrawHalfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret horis and vertical lines

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			; OUTPUT
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
PEDrawHalfLine	proc	far

		; test type of opcode and load up the parameters
		
		mov	cx, ds:[si].ODHLT_x2	; assume simplest
		mov	al, ds:[si]
		jc	figBounds
		cmp	al, GR_DRAW_HLINE_TO 	; test for to vers
		je	haveParams
		mov	dx, cx			; might be VLineTo
		cmp	al, GR_DRAW_VLINE_TO
		je	haveParams
		xchg	ax, dx
		mov	bx, ds:[si].ODHL_y1	; get y coordinate
		mov	cx, ds:[si].ODHL_x2	; assume horiz
		cmp	dl, GR_DRAW_HLINE	; check assumption
		je	haveParams
		mov	dx, cx			; must be VLINE
haveParams:
		call	GS_CallKernelRoutine
		ret

		; we need to calc the bounds of the line
figBounds:
		mov	dx, cx			; in case of VLINE_TO
		cmp	al, GR_DRAW_HLINE_TO
		je	doCP
		cmp	al, GR_DRAW_VLINE_TO
		je	doCP
		mov	ax, dx
		mov	bx, ds:[si].ODHL_y1
		call	BoundLineCoord
		mov	cx, ds:[si].ODHL_x2	; assume hline
		mov	dx, bx
		cmp	{byte} ds:[si], GR_DRAW_HLINE
		je	have2nd
		mov	dx, cx
		mov	cx, ax
have2nd:
		xchgdw	axbx, cxdx
		call	BoundLineCoord
		xchgdw	axbx, cxdx
		jmp	haveParams
doCP:
		call	GrGetCurPos		; set ax/bx
		call	BoundLineCoord
		cmp	{byte} ds:[si], GR_DRAW_HLINE_TO
		je	hlineTo
		mov	bx, dx
boundTo:
		call	BoundLineCoord
		jmp	haveParams
hlineTo:
		mov	ax, cx
		jmp	boundTo
		

PEDrawHalfLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEPolyCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret poly-coord elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data

RETURN:		ds:si	- points past data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

		; OUTPUT
		GrDrawPolyline	
		GrDrawSpline	
		GrDrawSplineTo
		GrDrawPolygon	
		GrBrushPolyline	
		GrFillPolygon	


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEPolyCoord	proc	far
		uses	si
		.enter

		; If polyline, polygon, or spline, only read a word

		pushf				; save carry
		mov	cx, ds:[si].ODPL_count	; get poly-coord count

		; If filled polygon, read another byte.  If brushed
		; polyline, read another word.

		mov	al, ds:[si]		; grab opcode
		cmp	al, GR_FILL_POLYGON	; a few opcodes need more work
		je	getFillRule
		cmp	al, GR_BRUSH_POLYLINE	
		je	getBrushSize

		; OK, we have all we need, just setup si -> coord block

		add	si, size OpDrawPolyline	; same for spline, drawPolygon
		popf				; restore carry
		jc	doBoundsThing
callKernel:
		call	GS_CallKernelRoutine
		.leave
		ret

		; for filled polygons, get the fill rule
getFillRule:
		mov	al, ds:[si].OFP_rule
		add	si, size OpFillPolygon
		popf				; restore bounds flag
		jnc	callKernel
		call	BoundFillPoly
		jmp	callKernel

		; for brushed polylines, get brush size
getBrushSize:
		mov	ax, {word} ds:[si].OBPL_width	; get width, height
		add	si, size OpBrushPolyline
		popf				; restore bounds flag
		jnc	callKernel
normalBounds:
		call	BoundLinePoly
		jmp	callKernel

doBoundsThing:
		cmp	al, GR_DRAW_POLYGON
		je	normalBounds
		cmp	al, GR_DRAW_POLYLINE
		je	normalBounds
		cmp	al, GR_DRAW_SPLINE_TO
		je	splineToBound

		; do first point alone then fall into common code

		push	bx, ds, si, cx
		mov	ax, ds:[si].P_x
		mov	bx, ds:[si].P_x
		call	GrMoveTo
		dec	cx			; one less point
		add	si, (size Point)
		jmp	getpoints
splineToBound:
		push	bx, ds, si, cx
getpoints:
		call	GetCurveCoords
		pop	bx, ds, si, cx
		jmp	callKernel
		
PEPolyCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurveCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get coords for bezier curve

CALLED BY:	INTERNAL
		PEPolyCoord
PASS:		ds:si	- pointer to array of control points
		di	- GState handle
		cx	- count of points
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurveCoords	proc	near
		uses	ax, bx, cx,dx, si, di, es, ds
		.enter

		cmp	cx, 2			; if fewer than three points...
		jbe	handleLine
		mov	bx, cx			; di = point count
		call	AllocCurveDataStructsFar
		push	cx, dx
		push	di			; save GState
		push	bx			; save point count
		call	GrGetCurPos		; current pos is first
		pop	di			; restore point count

		; Convert all the passed curves to one big huge polyline
curveLoop:
		call	CurveToPolylineFar
		sub	di, 3
		cmp	di, 3
		jge	curveLoop

		mov	bx, cx			; CurvePoints block
		call	MemDerefDS
		mov	cx, ds:[CP_numPoints]	; cx = #points
		mov	si, size CurvePolyline	; ds:si -> points

		pop	di			; restore GState
		call	BoundFillPoly

		pop	cx, dx
		call	FreeCurveDataStructsFar
done:
		.leave
		ret

handleLine:
		call	GrGetCurPos
		call	BoundFillCoord
		movdw	axbx, ds:[si]
		call	BoundFillCoord
		add	si, (size Point)
		movdw	axbx, ds:[si]
		call	BoundFillCoord
		jmp	done
GetCurveCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PECurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret curve elements

CALLED BY:	INTERNAL
		PlayElement

PASS:		bx	- graphics opcode *2
		ds:si	- pointer to element data

RETURN:		ds:si	- points past data

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

		; OUTPUT
		GrDrawCurve
		GrDrawCurveTo
		GrDrawRelCurveTo

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PECurve	proc	far
		uses	si
		.enter

		; Pass structure in DS:SI to appropriate routine
		;
		lodsb				; opcode => AL, params => DS:SI
		jc	doBoundsCalc
callKernel:
		call	GS_CallKernelRoutine

		.leave
		ret

		; Determine the bounds of the element
doBoundsCalc:
		push	cx, si
		mov	cx, 3			; we have 3 points
		cmp	al, GR_DRAW_REL_CURVE_TO
		je	relativeCurve
		cmp	al, GR_DRAW_CURVE_TO
		je	doBounds
		mov	ax, ds:[si].P_x
		mov	bx, ds:[si].P_y
		call	GrMoveTo
		add	si, size Point
doBounds:
		call	GetCurveCoords
		pop	cx, si
		jmp	callKernel		; now go draw the sucker

		; Deal with GrDrawRelCurveTo. Since we have integer
		; coordinates now, but will later have WWFixed points,
		; do a little unnecessary work for now.
relativeCurve:
		push	cx			; save # of remaining points
		lodsw				
		mov_tr	dx, ax			; P_x => AX		
		lodsw
		mov_tr	bx, ax			; P_y => BX
		clr	ax, cx			; clear fractions
		call	BoundRelCoord
		pop	cx			; restore # of remaining points
		loop	relativeCurve		; loop through the points
		pop	cx, si
		jmp	callKernel		; now go draw the sucker
PECurve	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PERotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret scale and rotate opcodes

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PERotate	proc	far
		movdw	dxcx, ds:[si].OAR_angle	; get rotation angle
		call	GS_CallKernelRoutine
		ret
PERotate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETransScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret translation/scale opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrApplyTranslation
			GrApplyTranslationDWord
			GrApplyScale

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETransScale	proc	far
		movdw	dxcx, ds:[si].OAS_xScale	; move factors over
		movdw	bxax, ds:[si].OAS_yScale
		call	GS_CallKernelRoutine
		ret
PETransScale	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PEComment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a GR_COMMENT opcode while interpreting

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PEComment	proc	far
		uses	si
		.enter

		mov	cx, ds:[si].OC_size	; get size of beast
		cmp	{byte} ds:[si], GR_COMMENT	; see if comment or escape
		jne	setupEscape
		add	si, size OpComment	; bump source pointer
haveParams:
		call	GS_CallKernelRoutine
		.leave
		ret

		; it's an escape code
setupEscape:
		mov	ax, cx
		mov	cx, ds:[si].OE_escSize	; get size of escape
		add	si, size OpEscape
		jmp	haveParams
PEComment	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PECustomMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a END_STRING opcode while interpreting

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PECustomMask	proc	far
		mov	al, SET_CUSTOM_PATTERN	; give it right option code
		inc	si			; point at mask
		call	GS_CallKernelRoutine
		dec	si			; restore si
		ret
PECustomMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PECustomStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a GR_SET_CUSTOM_LINE_STYLE opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
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
PECustomStyle	proc	far
		mov	bl, ds:[si].OSCLS_index.low ; get index
		mov	ah, ds:[si].OSCLS_count.low ; get pair count
		mov	al, LS_CUSTOM	; give it right option code
		add	si, size OpSetCustomLineStyle
		call	GrSetLineStyle		; call the darn thing
		sub	si, size OpSetCustomLineStyle
		ret
PECustomStyle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PELineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a SET_{LINE,AREA,TEXT}_ATTR opcode

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		load arg from string;
		call graphics routine;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine supports the following graphics functions:

			GrSetLineAttr
			GrSetAreaAttr
			GrSetTextAttr

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PEAttr		proc	far
		inc	si			; point ds:si -> LineAttr
		call	GS_CallKernelRoutine	; call appropriate routine
		dec	si
		ret
PEAttr		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PESetPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encountered a GR_SET_???_PATTERN in the GString

CALLED BY:	INTERNAL
		PlayElement

PASS:		ds:si	- pointer to element data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PESetPattern	proc	far
		mov	ax, {word} ds:[si].OSAP_pattern
		call	GS_CallKernelRoutine
		ret
PESetPattern	endp

PESetCustPattern	proc	far
		mov	ax, {word} ds:[si].OSCAP_pattern
		mov	cx, ds:[si].OSCAP_size	; size of custom pattern
		add	si, (size OpSetCustomAreaPattern)
		call	GS_CallKernelRoutine
		sub	si, (size OpSetCustomAreaPattern)
		ret
PESetCustPattern	endp		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a text pointer static element

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to last slice
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Supports the following codes:
			GR_DRAW_TEXT_PTR

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETextPtr	proc	far
		uses	si
		.enter
		mov	ax, ds:[si].ODTP_x1	; get position info
		mov	bx, ds:[si].ODTP_y1	; get position info
		mov	si, ds:[si].ODTP_ptr	; load offset to bitmap data
		jc	figBounds
callKernel:
		call	GS_CallKernelRoutine
		.leave
		ret

		; we need to calculate the text extent
figBounds:
		clr	cx			; null-terminated
		call	BoundText
		jmp	callKernel

PETextPtr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETextOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a text localmem pointer static element

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to element
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Supports the following codes:
			GR_DRAW_BITMAP_OPTR
			GR_FILL_BITMAP_OPTR

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PETextOptr	proc	far
		uses	ds, si
		.enter
		mov	cx, ds:[si].ODTO_x1	; get position info
		mov	dx, ds:[si].ODTO_y1	; get position info
		movdw	bxsi, ds:[si].ODTO_optr	; get resource handle
		push	bx			; save handle
		pushf				; save carry
		call	MemLock			; lock it down
		popf				; restore carry
		mov	ds, ax			; ds -> resource
		mov	si, ds:[si]		; dereference chunk
		movdw	axbx, cxdx		; move coords over
		jc	figBounds		; do bounds calc
callKernel:
		clr	cx			; string is null-terminated
		call	GS_CallKernelRoutine
		pop	bx			; restore resource handle
		call	MemUnlock		; release block
		.leave
		ret

		; need to do text extent calculation
figBounds:
		clr	cx
		call	BoundText
		jmp	callKernel
PETextOptr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PETextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw GR_DRAW_TEXT_FIELD element

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer to element data:
RETURN:		nothing
DESTROYED:	ax-dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PETextField	proc	far
		uses	si, bp, es, di
		.enter

		; need to do bounds the hard way  :(

		jc	figBounds

		; allocate some breathing room, and copy over the saved params

		sub	sp, size GDF_vars		
		mov	bp, sp				; ss:bp -> GDF_vars
		mov	ax, di				; ax = GState han
		segmov	es, ss, di
		mov	di, bp				; es:di -> GDF_vars
		add	di, offset GDFV_saved		; 
		add	si, offset ODTF_saved		; ds:si -> GDF_saved
		mov	cx, size GDF_saved
		rep	movsb				; move parameters
		mov	di, ax				; restore GState han

		; setup the callback address, and save an address of our own

NOFXIP<		mov	ss:[bp].GDFV_styleCallback.segment, cs		     >
FXIP<		mov	ss:[bp].GDFV_styleCallback.segment, vseg TextFieldCB >
		mov	ss:[bp].GDFV_styleCallback.offset, offset TextFieldCB
		movdw	ss:[bp].GDFV_other, dssi	; set ptr to 1st run

		; everything is set.  do it.

		call	GrDrawTextField

		add	sp, size GDF_vars		; backup stack
done:
		.leave
		ret

		; we need to calculate the bounds of this beast.  
		; the way we do this is to set the attributes for each run.
		; Since for the bounds calc we are only interested in position
		; info, this will be a satisfactory replacement for calling 
		; the TextField function.
figBounds:
		add	si, ODTF_saved
		movwbf	dxch, ds:[si].GDFS_drawPos.PWBF_x
		clr	cl
		movwbf	bxah, ds:[si].GDFS_drawPos.PWBF_y
		addwbf	bxah, ds:[si].GDFS_baseline
		clr	al
		call	GrMoveToWWFixed		 ; set the current position
		mov	cx, ds:[si].GDFS_nChars	 ; get total string length
		add	si, size GDF_saved	; ds:si -> first style run
fieldLoop:
		lodsw				; ax = count for this run
		call	GrSetTextAttr		; set text attributes for run
		add	si, size TextAttr	; ds:si -> string
		xchg	cx, ax			; cx = string length, ax=total
		push	ax
		call	GrGetCurPos
		call	BoundText		; deal with this set
		pop	ax
		xchg	ax, cx
		call	GrDrawTextAtCP		; update current position
DBCS <		shl	ax, 1						>
		add	si, ax			; ds:si -> next style run
DBCS <		shr	ax, 1						>
		sub	cx, ax			; see if we're done
		jnz	fieldLoop
		jmp	done
		
PETextField	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextFieldCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for PETextField

CALLED BY:	EXTERNAL
		GrDrawTextField

PASS:		ss:bp	- pointer to GDF_vars struct (see above)
		bx:di	- pointer to buffer to fill with TextAttr
		si	- current offset to the text
RETURN:		cx	- # characters in this run
		ds:si	- Pointer to text

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
		uses	es, di, ax
		.enter

		; first fill the TextAttr structre.  The GDFV_other field is
		; already pointing there..

		mov	es, bx			; es:di -> buffer to fill
		movdw	dssi, ss:[bp].GDFV_other ; ds:si -> TFStyleRun
		mov	ax, ds:[si].TFSR_count	; need this later
		add	si, offset TFSR_attr	; ds:si -> TextAttr
		mov	cx, size TextAttr
		rep	movsb
		
		; at this point ds:si -> text string.  Record the position
		; of the next run.

		movdw	ss:[bp].GDFV_textPointer, dssi ; save pointer
		mov	cx, ax			; return string len in cx
DBCS <		shl	cx, 1						>
		add	si, cx			; calc next pointer
		movdw	ss:[bp].GDFV_other, dssi ; save next run pointer
		sub	si, cx
DBCS <		shr	cx, 1						>
		.leave
		ret
TextFieldCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundRelCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accumulate the bounds of a relatively drawn object

CALLED BY:	INTERNAL
PASS:		dxcx	- x offset (WWFixed)
		bxax	- y offset (WWFixed)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BoundRelCoord	proc	near
		uses	ax, bx, cx, dx, ds, si
DSframe		local	DrawStringFrame
		.enter inherit

		; copy coords into some temp space so we can transform them
		
		mov	si, ax			; save ax
		xchg	bx, di
		call	MemLock
		mov	ds, ax
		xchg	bx, di
		mov	ax, si
		call	TransformRelVector
		pushdw	bxax			; save X offset
		mov	si, dx			; save dx and ax
		call	GrGetLineWidth
		xchg	si, dx			; set dxax = Y offset
		xchg	cx, ax			; sicx = line width
		mov	bx, ax
		mov	ax, dx
		cwd				; dxaxbx = y offset (DWFixed)
		adddwf	dxaxbx, ds:[GS_penPos].PDF_x
		call	BoundXLine
		popdw	axbx			; restore in new order
		cwd
		adddwf	dxaxbx, ds:[GS_penPos].PDF_y
		call	BoundYLine

		mov	bx, di
		call	MemUnlock

		.leave
		ret
BoundRelCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the bounds for some piece of text

CALLED BY:	INTERNAL
PASS:		di	- GState handle
		ax,bx	- position to draw at
		cx	- number of characters
		ds:si	- pointer to string
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoundText		proc	far
		uses	ax,bx,cx,dx
		.enter

		; use the new kernel function to get the text bounds

		call	GrGetTextBounds
		jc	done			; if bogus, don't use
		call	BoundFillRect
done:
		.leave
		ret
BoundText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundPoly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do bounds calc, for poly something

CALLED BY:	PEPolyCoord
PASS:		ds:si	- pointer to coords
		cx	- number of coords
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoundLinePoly	proc	near
		uses	ax,bx,cx,si
		.enter

coordLoop:
		lodsw			; get x coord
		mov	bx, ax
		lodsw			; get y coord
		xchg	ax, bx
		call	BoundLineCoord
		loop	coordLoop
	
		.leave
		ret
BoundLinePoly	endp

BoundFillPoly	proc	near
		uses	ax,bx,cx,si
		.enter

coordLoop:
		lodsw			; get x coord
		mov	bx, ax
		lodsw			; get y coord
		xchg	ax, bx
		call	BoundFillCoord
		loop	coordLoop
	
		.leave
		ret
BoundFillPoly	endp

	; save as above routines, except we already have device coords.
BoundDevLinePoly	proc	near
		uses	ax,bx,cx,si
		.enter

coordLoop:
		lodsw			; get x coord
		mov	bx, ax
		lodsw			; get y coord
		xchg	ax, bx
		call	BoundDevLineCoord
		loop	coordLoop
	
		.leave
		ret
BoundDevLinePoly	endp

BoundDevFillPoly	proc	near
		uses	ax,bx,cx,si
		.enter

coordLoop:
		lodsw			; get x coord
		mov	bx, ax
		lodsw			; get y coord
		xchg	ax, bx
		call	BoundDevFillCoord
		loop	coordLoop
	
		.leave
		ret
BoundDevFillPoly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundLineRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate and accumulate bounds for an object

CALLED BY:	INTERNAL
		various playelement routines
PASS:		ax..dx	- rectangle bounds
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		figure the bounds and accumulate in DSframe

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoundLineRect	proc	near
		uses	ax,bx,cx,dx
		.enter

		push	ax, dx			; save other corners
		push	cx, bx
		push	cx, dx
		call	BoundLineCoord		; do upper left
		pop	ax, bx
		call	BoundLineCoord		; do lower right
		pop	ax, bx
		call	BoundLineCoord		; do upper right
		pop	ax, bx
		call	BoundLineCoord		; do lower left

		.leave
		ret
BoundLineRect	endp

BoundFillRect	proc	far
		uses	ax,bx,cx,dx
		.enter

		push	ax, dx			; save other corners
		push	cx, bx
		push	cx, dx
		call	BoundFillCoord		; do upper left
		pop	ax, bx
		call	BoundFillCoord		; do lower right
		pop	ax, bx
		call	BoundFillCoord		; do upper right
		pop	ax, bx
		call	BoundFillCoord		; do lower left

		.leave
		ret
BoundFillRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bounding box for line

CALLED BY:	INTERNAL
PASS:		ax,bx,cx,dx	- x1,y1,x2,y2 for line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoundLine	proc	near
		call	BoundLineCoord
		xchgdw	axbx, cxdx
		call	BoundLineCoord
		xchgdw	axbx, cxdx
		ret
BoundLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundLineCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single coordinate for bounds calculation

CALLED BY:	INTERNAL
		BoundRect
PASS:		ax,bx	- doc coord 
		di	- GState
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BoundLineCoord	proc	near
		uses	ax,bx,dx,es,cx,si
DSframe		local	DrawStringFrame
		.enter inherit

		; copy the coordinate into a temporary space

		cwd
		movdw	DSframe.DSF_tempCoord.PDF_x.DWF_int, dxax
		clr	DSframe.DSF_tempCoord.PDF_x.DWF_frac
		mov	ax, bx
		cwd
		movdw	DSframe.DSF_tempCoord.PDF_y.DWF_int, dxax
		clr	DSframe.DSF_tempCoord.PDF_y.DWF_frac

		segmov	es, ss, dx
		lea	dx, ss:DSframe.DSF_tempCoord
		call	GrTransformDWFixed

		call	GrGetLineWidth			; dxax = width
		movdw	sicx, dxax
		movdwf	dxaxbx, DSframe.DSF_tempCoord.PDF_x
		call	BoundXLine
		movdwf	dxaxbx, DSframe.DSF_tempCoord.PDF_y		
		call	BoundYLine

		.leave
		ret
BoundLineCoord	endp

BoundFillCoord	proc	near
		uses	ax,bx,dx,es
DSframe		local	DrawStringFrame
		.enter inherit

		; copy the coordinate into a temporary space

		cwd
		movdw	DSframe.DSF_tempCoord.PDF_x.DWF_int, dxax
		clr	DSframe.DSF_tempCoord.PDF_x.DWF_frac
		mov	ax, bx
		cwd
		movdw	DSframe.DSF_tempCoord.PDF_y.DWF_int, dxax
		clr	DSframe.DSF_tempCoord.PDF_y.DWF_frac

		segmov	es, ss, dx
		lea	dx, ss:DSframe.DSF_tempCoord
		call	GrTransformDWFixed

		movdwf	dxaxbx, DSframe.DSF_tempCoord.PDF_x
		call	BoundXFill
		movdwf	dxaxbx, DSframe.DSF_tempCoord.PDF_y		
		call	BoundYFill

		.leave
		ret
BoundFillCoord	endp

	; save as above, except device coords passed.

BoundDevLineCoord	proc	near
		uses	ax,bx,dx,cx,si
		.enter

		push	bx
		push	ax
		call	GrGetLineWidth			; dxax = width
		movdw	sicx, dxax
		pop	ax
		cwd
		clr	bx
		call	BoundXLine
		pop	ax
		cwd
		clr	bx
		call	BoundYLine

		.leave
		ret
BoundDevLineCoord	endp

BoundDevFillCoord	proc	near
		uses	ax,bx,dx
		.enter

		push	bx
		cwd
		clr	bx
		call	BoundXFill
		pop	ax
		cwd
		clr	bx
		call	BoundYFill

		.leave
		ret
BoundDevFillCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do min/max calc on X coordinate

CALLED BY:	INTERNAL
PASS:		dxaxbx	- x coordiante to check (Page coords, DWFixed)
		sicx	- line width
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine takes the current line width into account, 
		whether or not the passed coordinate is part of a line object.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BoundXLine		proc	near
		uses	cx,si
DSframe		local	DrawStringFrame
		.enter	inherit
		sar	si, 1			; only apply half
		rcr	cx, 1
		sub	bx, cx			; add fractions
		sbb	ax, si
		sbb	dx, 0			; dxaxbx = pos - linewidth
		cmp	dx, DSframe.DSF_tlBound.PDF_x.DWF_int.high
		jl	storeNewLowX
		je	checkMoreLow
checkHighX:
		add	bx, cx			; adding twice is faster than
		adc	ax, si			;  saving/restoring orig coord
		adc	dx, 0			; dxaxbx = orig pos
		add	bx, cx			; add fractions
		adc	ax, si
		adc	dx, 0			; dxaxbx = pos + linewidth
		cmp	dx, DSframe.DSF_brBound.PDF_x.DWF_int.high
		jg	storeNewHighX
		je	checkMoreHigh
done:
		sub	bx, cx			; restore original values
		sbb	ax, si			;  (faster than push/pop)
		sbb	dx, 0			
		.leave
		ret

checkMoreLow:
		cmp	ax, DSframe.DSF_tlBound.PDF_x.DWF_int.low
		jb	storeNewLowX
		jne	checkHighX
		cmp	bx, DSframe.DSF_tlBound.PDF_x.DWF_frac
		jae	checkHighX
storeNewLowX:
		movdwf	DSframe.DSF_tlBound.PDF_x, dxaxbx
		jmp	checkHighX

checkMoreHigh:
		cmp	ax, DSframe.DSF_brBound.PDF_x.DWF_int.low
		ja	storeNewHighX
		jne	done
		cmp	bx, DSframe.DSF_brBound.PDF_x.DWF_frac
		jbe	done
storeNewHighX:
		movdwf	DSframe.DSF_brBound.PDF_x, dxaxbx
		jmp	done
BoundXLine		endp



BoundXFill	proc	near
DSframe		local	DrawStringFrame
		.enter	inherit
		cmp	dx, DSframe.DSF_tlBound.PDF_x.DWF_int.high
		jl	newLowX
		je	moreCheckLow
checkHighX:
		cmp	dx, DSframe.DSF_brBound.PDF_x.DWF_int.high
		jg	newHighX
		je	moreCheckHigh
done:
		.leave
		ret

		; make sure it's lower
moreCheckLow:
		cmp	ax, DSframe.DSF_tlBound.PDF_x.DWF_int.low
		jb	newLowX
		jne	checkHighX
		cmp	bx, DSframe.DSF_tlBound.PDF_x.DWF_frac
		jae	checkHighX
newLowX:
		movdwf	DSframe.DSF_tlBound.PDF_x, dxaxbx
		jmp	checkHighX

		; make sure it's higher
moreCheckHigh:
		cmp	ax, DSframe.DSF_brBound.PDF_x.DWF_int.low
		ja	newHighX
		jne	done
		cmp	bx, DSframe.DSF_brBound.PDF_x.DWF_frac
		jbe	done
newHighX:
		movdwf	DSframe.DSF_brBound.PDF_x, dxaxbx
		jmp	done
BoundXFill	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoundY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do min/max calc on y coordinate

CALLED BY:	INTERNAL
PASS:		dxaxbx	- DWFixed Page coordiante to check
		sicx	- current line width (WWFixed)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BoundYLine		proc	near
		uses	cx,si
DSframe		local	DrawStringFrame
		.enter	inherit
		sar	si, 1			; only apply half
		rcr	cx, 1
		sub	bx, cx			; add fractions
		sbb	ax, si
		sbb	dx, 0			; dxaxbx = pos - linewidth
		cmp	dx, DSframe.DSF_tlBound.PDF_y.DWF_int.high
		jl	storeNewLowY
		je	checkMoreLow
checkHighY:
		add	bx, cx			; adding twice is faster than
		adc	ax, si			;  saving/restoring orig coord
		adc	dx, 0			; dxaxbx = orig pos
		add	bx, cx			; add fractions
		adc	ax, si
		adc	dx, 0			; dxaxbx = pos + linewidth
		cmp	dx, DSframe.DSF_brBound.PDF_y.DWF_int.high
		jg	storeNewHighY
		je	checkMoreHigh
done:
		sub	bx, cx			; restore original values
		sbb	ax, si			;  (faster than push/pop)
		sbb	dx, 0			
		.leave
		ret

checkMoreLow:
		cmp	ax, DSframe.DSF_tlBound.PDF_y.DWF_int.low
		jb	storeNewLowY
		jne	checkHighY
		cmp	bx, DSframe.DSF_tlBound.PDF_y.DWF_frac
		jae	checkHighY
storeNewLowY:
		movdwf	DSframe.DSF_tlBound.PDF_y, dxaxbx
		jmp	checkHighY

checkMoreHigh:
		cmp	ax, DSframe.DSF_brBound.PDF_y.DWF_int.low
		ja	storeNewHighY
		jne	done
		cmp	bx, DSframe.DSF_brBound.PDF_y.DWF_frac
		jbe	done
storeNewHighY:
		movdwf	DSframe.DSF_brBound.PDF_y, dxaxbx
		jmp	done
BoundYLine		endp



BoundYFill	proc	near
DSframe		local	DrawStringFrame
		.enter	inherit
		cmp	dx, DSframe.DSF_tlBound.PDF_y.DWF_int.high
		jl	newLowY
		je	moreCheckLow
checkHighY:
		cmp	dx, DSframe.DSF_brBound.PDF_y.DWF_int.high
		jg	newHighY
		je	moreCheckHigh
done:
		.leave
		ret

		; make sure it's lower
moreCheckLow:
		cmp	ax, DSframe.DSF_tlBound.PDF_y.DWF_int.low
		jb	newLowY
		jne	checkHighY
		cmp	bx, DSframe.DSF_tlBound.PDF_y.DWF_frac
		jae	checkHighY
newLowY:
		movdwf	DSframe.DSF_tlBound.PDF_y, dxaxbx
		jmp	checkHighY

		; make sure it's higher
moreCheckHigh:
		cmp	ax, DSframe.DSF_brBound.PDF_y.DWF_int.low
		ja	newHighY
		jne	done
		cmp	bx, DSframe.DSF_brBound.PDF_y.DWF_frac
		jbe	done
newHighY:
		movdwf	DSframe.DSF_brBound.PDF_y, dxaxbx
		jmp	done
BoundYFill	endp

GraphicsString ends
