COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processText.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	DoTextPrinting		Handles printing in text modes
	GetTextStrings		Extracts text strings from gstrings
	SendTextStrings		Send the text strings down to the printer

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/92		Initial 2.0 revision


DESCRIPTION:
	This file contains routines to handle text printing
		
	Text printing is done in a rather interesting fashion under PC GEOS.
	Applications actually draw their spool file just as if they were
	printing a graphics page.  The code here scans through the resulting
	graphics string and pulls out the text strings, along with the
	position to draw them and the attributes in affect at the time.

	A first pass is made through the gstrings containing the page
	description.  In this pass, all the text strings are extracted ajnd
	stored in chunks, in the TextStrings block.  These chunks are 
	sorted in x and y. After all the strings for the page are extracted,
	they are sent to the printer.  This is done by building a line
	of characters, with spaces separating the runs of text, along with
	information about the style.  A print head positioning command is
	sent for the beginning of the line, then the entire line is sent
	down to the printer, a style run at a time.

	$Id: processText.asm,v 1.1 97/04/07 11:11:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintText	segment	resource

if	_TEXT_PRINTING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTextInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization for text printing

CALLED BY:	INTERNAL
		PrintDocument

PASS:		inherits lots of local variables from SpoolerLoop

RETURN:		ax	- 0  (signals no error)

DESTROYED:	di, cx, bx, dx, ds

PSEUDO CODE/STRATEGY:
		Get the strings out of the gstring;
		Build out a list of the strings, sorted in y order;
		Send them on down to the printer;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Dave	7/92		Initial 2.0 version	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DoTextInit	proc	far
curJob		local	SpoolJobInfo
		.enter	inherit

		; we need to create a gstate to draw through, even though
		; we're not going to really draw anything using the 
		; graphics system
	clr	di			; pass bogus window handle
	call	GrCreateState		; di = gstate handle
	mov	curJob.SJI_gstate, di	; save gstate
		; get the transformation matrix back to start in the gstate
	segmov	ds,ss,si
	lea	si,curJob.SJI_defMatrix ;set to our transformation matrix
	call	GrApplyTransform

		; allocate the TextStrings structure. 
		; (see processConstant.def)
	mov	ax, LMEM_TYPE_GENERAL	;type of block.
	mov	cx, size TextStrings	;size of header.
	call	MemAllocLMem
	mov	curJob.SJI_tsHan, bx	; save handle
		;we have our lmem block, now create the structures within.
	call	MemLock			; lock it down
	mov	ds, ax			; ds -> block
		; alloc an extra chunk in the TextStrings block to act as
		; a buffer for reading in gstring elements
	clr	al			; no object flags
	mov	cx, 0			; alloc to zero to start
	call	LMemAlloc		; 
	mov	ds:[TS_gsBuffer], ax	; save handle for later
	clr	bx			;variable size elements.
	mov	cx,bx			;default ChunkArrayHeader.
	mov	si,bx			;new chunk.
	mov	al, mask OCF_IGNORE_DIRTY
	call	ChunkArrayCreate	;do it.
	mov	ds:TS_styleRunInfo,si	;store the handle to the chunkarray
	clr	si
	mov	bx,size TextAttrInfo
	call	ElementArrayCreate
	mov	ds:TS_textAttributeInfo,si ;store the handle to elementarray

	mov	bx, curJob.SJI_tsHan
	call	MemUnlock		; unlock block for later use
	clr	ax			; signal no error

	.leave
	ret
DoTextInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTextStringsBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the TextStrings block

CALLED BY:	INTERNAL
		DoTextInit, 

PASS:		curJob	- passed stack frame

RETURN:		nothing

DESTROYED:	ds, dx, cx

PSEUDO CODE/STRATEGY:
		call LMemInitHeap, blah, blah

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version
		Dave	7/92		Initial 2.0 version	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitTextStringsBlock	proc	near
	uses	ax
curJob	local	SpoolJobInfo
	.enter	inherit

		; lock the block, and initialize the lmem heap

	push	si, di, bp
	mov	bx, curJob.SJI_tsHan	; save handle
	call	MemLock			; lock it down
	mov	ds, ax			; ds -> block
        pop     si, di, bp

		; alloc an extra chunk in the TextStrings block to act as
		; a buffer for reading in gstring elements
	clr	al			; no object flags
	mov	cx, 0			; alloc to zero to start
	call	LMemAlloc		; 
	mov	ds:[TS_gsBuffer], ax	; save handle for later

		;initialize the chunkarray for the string info.
	mov	si,ds:[TS_styleRunInfo]	;get the handle for array.
	call	ChunkArrayGetCount	;get teh number of chunks.
	jcxz	inittedChunks
	clr	ax
	call	ChunkArrayDeleteRange	;get rid of the string infos.

inittedChunks:

		;initialize the element array for the attribute info.
inittedElements::

		; all done, release the block
	mov	bx, curJob.SJI_tsHan	; save handle
	call	MemUnlock

	.leave
	ret
InitTextStringsBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintTextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a single text page, including any tiling required

CALLED BY:	EXTERNAL
		PrintDocument

PASS:		curJob stack frame

RETURN:		ax	- return code from GetTextStrings
		carry	- set if some error transmitting to printer

DESTROYED:	most everything

PSEUDO CODE/STRATEGY:
		do what it takes, man.

		This routine is responsible for printing a single document
		page.  That means that it deals with printing all the tiles
		of tiled output, if that is required.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintTextPage	proc	far
curJob		local	SpoolJobInfo
		.enter	inherit

		; the file is already open, associate it with a graphics
		; string handle

		mov	cx, GST_STREAM		; type of gstring it is
		mov	bx, curJob.SJI_fHan	; bx gets file handle
		call	GrLoadGString		; si = string handle
		mov	curJob.SJI_gstring, si	; store the handle
		mov	di, curJob.SJI_gstate	; restore gstate handle

		; find/load the strings into the TextStrings block
		; then send the strings down to the printer.  For big documents
		; the GetTextStrings routine will load up all the strings
		; for the entire document.  Then we can deal with printing
		; out the tiles separately.

		call	GetTextStrings		; get the strings
		cmp	ax, GSRT_FAULT		; quit if any problem
		LONG je	done
			;source point for ax, and bx later.......

		; done with this page, kill the string

		mov	dl, GSKT_LEAVE_DATA	; don't try to kill the data
		call	GrDestroyGString	; si = string handle

		;This little bit of mularky is to make sure that ProcessEndPage
		;has the correct entry GSRT value from playing the GString.
		;The way this works is: GString is played once; for tiling the
		;ProcessEndPage routine is called many times in the following
		;loops; dx is used to hold the original GSRT passed from the 
		;playstring stuff; ax is passed out of this routine like normal
		;ax is restuffed from dx at the beginning of each page loop,
		;so that ProcessEndPage will do the right thing.

		mov	dx,ax			;save the GSRT value.

		; now we have all the strings.  So print them.
		; We need to output all the pages we print tiled documents 
		; across, then down.  Outside loop is for y papers, 
		; inside loop is for x papers

		mov	cx, curJob.SJI_yPages		; init y loop variable
		mov	curJob.SJI_curyPage, cx	
		mov	cx, paperInfo.PSR_margins.PCMP_top ; init top side
		mov	curJob.SJI_textTileY.low, cx
		clr	curJob.SJI_textTileY.high
tileInY:
		mov	cx, curJob.SJI_xPages		; init x loop variable
		mov	curJob.SJI_curxPage, cx	
		mov	cx, paperInfo.PSR_margins.PCMP_left ; init left side
		mov	curJob.SJI_textTileX, cx
		add	cx, curJob.SJI_printWidth	; set right margin
		mov	curJob.SJI_textTileXright, cx

		; First, tell the printer we're starting a new page.
tileInX:
		call	BumpPhysPageNumber

		call	ProcessStartPage		; send START_PAGE
		LONG jc	exitError			; all done

		; next send the strings for this page

		call	SendTextStrings		; print strings for page
		LONG jc	exitError		; all done

		; let the printer know we're done with a page.  If the 
		; SUPRESS_FF flag is set, then don't send the END_PAGE

			;ax,bx,and dx have to be preserved through this loop!
		mov	ax,dx			; recover the original GSRT.
		call	ProcessEndPage		; issue a DR_PRINT_END_PAGE
		LONG jc	exitError		; all done

		; even though we're done with the page, we need to advance 
		; down to the end of the document (if we haven't issued a
		; form feed). So check for the mode and do the right thing.

		test	curJob.SJI_printState, mask SPS_FORM_FEED
		jnz	checkNextSwoosh
		mov	di, DR_PRINT_SET_CURSOR
		push	bx,dx			;save GSRT and data from 
						;GetTextStrings routine.
		mov	bx, curJob.SJI_pstate
		mov	dx, curJob.SJI_printHeight ; finish document
		call	curJob.SJI_pDriver
		pop	bx,dx			;recover GSRT and data from 
						;GetTextStrings routine.

		; now we're done with a page.  We might have to print out
		; a few more to the right, so check that first
checkNextSwoosh:
		sub	curJob.SJI_curxPage, 1		; one less this way
		jle	nextSwoosh			; done this way, check

		; We have more to do in this swoosh .  Update the current pos
		; and go for it.  First make sure we have paper...

		push	ax
		call	AskForNextTextPage
		cmp	ax, IC_DISMISS			; verify this fact...
		pop	ax
		je	shutdownCondition		; or go shutdown
		mov	cx, curJob.SJI_printWidth	; add in prntable width
		add	curJob.SJI_textTileX, cx	; bump origin
		add	curJob.SJI_textTileXright, cx	; bump right margin
		jmp	tileInX

		; done with a horizontal swoosh of papers.  Do the next 
		; swoosh. Like before, check first to see if there is another
nextSwoosh:
		sub	curJob.SJI_curyPage, 1		; one less
		jle	donePage
		
		; more swooshes to do. Update origin.
		; First make sure we have paper...

		push	ax
		call	AskForNextTextPage
		cmp	ax, IC_DISMISS			; except when we're
		pop	ax
		je	shutdownCondition		; shutting down
		mov	cx, curJob.SJI_printHeight	; add printable height
		add	curJob.SJI_textTileY.low, cx	; bump origin
		adc	curJob.SJI_textTileY.high, 0
		jmp	tileInY

		; done with the current document page.  
donePage:
		clc

		; we're done with this page.  Re-init the LMemBlock
done:
		pushf
		call	InitTextStringsBlock		; clear out the strings
		popf
exit:
		.leave
		ret

		; shutting down GEOS, take evasive action..
shutdownCondition:
		mov	ax, GSRT_FAULT			; something wrong
		jmp	exit

		; some error transmitting to printer.  set carry and we're gone
exitError:
		stc
		jmp	done				; all done...
PrintTextPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTextCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		everything is in curJob stack frame

RETURN:		nothing

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
		free the memory we accumulated

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version
		Dave	7/92		Initial 2.0 version	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoTextCleanup	proc	far
curJob	local	SpoolJobInfo
	.enter	inherit

		; clean up the normal text-related things
	mov	bx, curJob.SJI_tsHan		; get handle
	call	MemFree				; kill the block
	mov	di, curJob.SJI_gstate	; kill gstate
	call	GrDestroyState		; di = gstate handle

		; if we were aborting this print job, then nuke the stream
		; buffer, to stop more characters from getting to the printer
	call	CheckForErrors		; see if ABORT is pending...
	jnc	done			;  no, just exit

		; OK, we're exiting because of an user-initiated abort.  We want
		; to nuke the stream buffer, then re-open it (since the rest of
		; the spooler expects it to be open)
	mov	di, DR_STREAM_FLUSH	; destroy the stream buffer
	mov	ax, STREAM_WRITE	; biff the data in it

		; this will get the unit number for either the parallel port
		; or the serial port.  When another port type is supported
		; in the (near) future, then this code will probably have
		; to change.
	mov	bx, curJob.SJI_info.JP_portInfo.PPI_params.PP_parallel.PPP_portNum
	call	curJob.SJI_stream	; nuke it.

		; after we flush the stream, we should send a form feed
	mov	cl,C_FF				;init for FF
	mov	di, DR_PRINT_END_PAGE
	mov	bx, curJob.SJI_pstate
	call	curJob.SJI_pDriver
done:
	.leave	
	ret
DoTextCleanup endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendTextStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out the collected strings to the printer

CALLED BY:	INTERNAL
		DoTextPrinting

PASS:		inherits local frame

RETURN:		carry		- set if some transmission error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Go through the TextStrings block, and send each string

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Dave	7/92		Initial 2.0 version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendTextStrings	proc	near
	uses	ax, bx, cx, si, dx
curJob	local	SpoolJobInfo
	.enter 	inherit

		; for each StyleRunInfo chunk, loop through all the strings
	mov	bx, curJob.SJI_pstate
        call    MemLock
        mov     ds, ax
        mov     dl,ds:[PS_paperInput]		;grab paperpath for test later
        call    MemUnlock                       ; (preserves flags)

	; lock down the TextStrings block

	mov	bx, curJob.SJI_tsHan		; get handle to text block
	call	MemLock
	mov	ds, ax				; ds -> text chunk

	mov	si, ds:[TS_styleRunInfo]	;get the chunks set up.
	clr	ax
nextYPos:
	push	ax				;save the chunk element #
	call	ChunkArrayElementToPtr		;deref the chunk.
	jc	doneNoErr			;if after the last element, ex
	mov	ax, ds:[di].SRI_yPosition	;get the y position.
	add	ax, paperInfo.PSR_margins.PCMP_top ;add the margin amount in.
						; printer always prints from 0
	sub	ax, curJob.SJI_textTileY.low 	; above current ytop ?
	jl	skipThisElement			;  yes, skip this line

	test	curJob.SJI_printState, mask SPS_TILED ; if not tiled in Y, 
	jz	checkBottom			;  don't care about tractor
        test    dl, mask PIO_TRACTOR
	jnz	checkXPosition			;if tractor, one big page.
checkBottom:
	sub 	ax, curJob.SJI_printHeight	; bottom margin.
	jge	doneNoErr			; all done with this page
	
checkXPosition:
                ; Make sure it's past the left margin, since that is where
                ; we want to start outputting characters.

	mov	ax, ds:[di].SRI_xPosition	;get the x position.
	add	ax, paperInfo.PSR_margins.PCMP_left ;add the margin amount in.
						; printer always prints from 0
	sub     ax, curJob.SJI_textTileX        ; past left margin ?
	jl      skipThisElement                 ; if so, for now, just bail.

	sub	ax,curJob.SJI_printWidth	;see if offpage to right.
	jge	skipThisElement			; if so, reject....
	add	ax,ds:[di].SRI_stringWidth.WBF_int ;see if the whole string is
	jl	stringOnPage			;on this page.
	
	call	SnipTextString			;take and cut this string up.
	jc	skipThisElement			;if the whole element moved
						;as a result of an incomplete
						;character left on left page,
						;skip it.

stringOnPage:
	push	dx,si				;save the paperpath, SRI handle
	mov	dx, ds				;set dx:si to be element.
	mov	si, di
	mov	ax, curJob.SJI_textTileX 	; pass the offset into tiles
	mov	cx, curJob.SJI_textTileY.low 	; pass the offset into tiles
	mov	bx, curJob.SJI_pstate
	mov	di, DR_PRINT_STYLE_RUN		;call to print this text.
	call	curJob.SJI_pDriver		; print out the collected buff
	pop	dx,si
	jc	done				; if any error, quit
	mov	bx, curJob.SJI_tsHan		; just in case PRINT_STYLE_RUN
	call	MemDerefDS			; messes with us.

		; all done with this style run, on to the next one
skipThisElement:
	pop	ax
	inc	ax				;point at next chunk.
	jmp	nextYPos

doneNoErr:
	clc
done:
	mov	bx, curJob.SJI_tsHan		; release text block
	call	MemUnlock

	pop	ax			;adjust stack.
	.leave
	ret


SendTextStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SnipTextString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	cut the string in two peices at the right margin, store both 
		back into chunkarray

CALLED BY:	INTERNAL

PASS:		*ds:si - textStrings array
		ds:di - textStrings array element being snipped
		ax - number of points the string extends to the right of margin.

RETURN:		ds:di - address of left element (may have moved)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		1 Get the string width and # chars for the left part.
		2 Insert a new chunk and copy everything up to the last left
		  part character in it from the original.
		3 fix up the number of characters and stringWidth in each part,
		  and the x position for the right part.
		4 move the characters from the end of the origional string
		  to the beginning of the right part string.
		5 resize the right part chunk.
		6 deref the left chunk to return.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	03/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SnipTextString	proc	near
	uses	ax, bx, cx, dx, es
curJob	local	SpoolJobInfo
	.enter 	inherit

	push	si			;save chunk array handle

		;Get the string width and # chars for the left part.
	mov     dx,ds:[di].SRI_stringWidth.WBF_int
	sub	dx,ax			;get the width of the string to left.
					;dx is now the width to left, ax the
					;width to right. We start on the right
					;first.
	push	dx			;save the left part.
	clr	ax
	clr	cx
	mov     bx,ds:[di].SRI_stringWidth.WBF_int
	call	GrUDivWWFixed		;get fraction of string width to right.
	mov	bx,ds:[di].SRI_numChars ;x total number of chars =
	clr	ax
	call	GrMulWWFixed		;dx.cx = # chars to left
					;always round down.

		;see if there are any whole character in the left part after
		;the rounding down.
					;at this point dx = #char to left,
					;width to left is on stack
	tst	dx			;any chars left on left?
	jnz	insertNewChunk		;if so, then we add a new chunk to 
					;hold them.
	pop	cx			;get back the position to right.
        add     ds:[di].SRI_xPosition,cx ;adjust the x position of right part.
        sub     ds:[di].SRI_stringWidth.WBF_int,cx ;set the right width
					;Now the whole string has been moved to
					;the right part to be printed on the
					;next page.
	pop	si			;adjust stack.
	stc				;set to not print this element now...
	jmp	exit			;leave.

		;Insert a new chunk and copy everything up to the last left
		;part character in it from the original.
insertNewChunk:
					;at this point dx = chars to left, and 
					;stringWidth to left is on stack.
	mov	ax,offset SRI_text      ;size req'd for header
DBCS <	shl	dx, 1							>
	add     ax,dx                   ;size required for string
	call	ChunkArrayInsertAt	;create the new chunk for right part.
	mov	bx,di			;save this offset.
	call	ChunkArrayPtrToElement	;get this element #.
	inc	ax			;get element # of source chunk.
	call	ChunkArrayElementToPtr	;get offset of source chunk.
	mov	si,di			;switch so source is in si.
	mov	di,bx			;get back new chunk offset.
	segmov	es,ds,cx		;set up same segment.
	mov	cx,offset SRI_text	;size of information header.
	add	cx,dx                   ;size required for string.
	push	si,di			;save indices for chunks.
	rep	movsb			;fill in info
	pop	si,di			;get back indices.

		;fix up the number of characters and stringWidth in each part,
		;and the x position for the right part.
					;at this point we have a duplicate
					;chunk added in front of the original
					;chunk with only the left side
					;characters.
DBCS <	shr	dx, 1							>
	mov	ds:[di].SRI_numChars,dx ;replace the number of characters.
	sub	ds:[si].SRI_numChars,dx	;set remaining number to right.
	pop	cx			;retreive the width to left.
	mov	ds:[di].SRI_stringWidth.WBF_int,cx ;set the left width.
	add	ds:[si].SRI_xPosition,cx ;adjust the x position of right part.
	sub	ds:[si].SRI_stringWidth.WBF_int,cx ;set the right width
	clr	ds:[di].SRI_stringWidth.WBF_frac   ;clear left fraction.

		;move the characters from the end of the origional string
		;to the beginning of the right part string.
					;at this point the new (first, left)
					;chunk is ready to go, and all that
					;needs to be done is move the text from
					;the end of the string in the right part					;chunk to the beginning of the text
					;field, and lopp of the end of the
					;chunk.
	push	si			;save the offset to right chunk.
	mov	cx,ds:[si].SRI_numChars	;number of chars to right
	add	si,offset SRI_text	;now offset to text start.
	mov	di,si			;into dest.
DBCS <	shl	dx, 1							>
	add	si,dx			;source index is start of chars to right
	LocalCopyNString		;transfer them to beginning.
	pop	di			;recover the offset to chunk.

		;resize the right part chunk.
	pop	si			;recover chunk array handle
	call	ChunkArrayPtrToElement	;get element # in ax.
        mov     cx,ds:[di].SRI_numChars ;size required for string
DBCS <	shl	cx, 1							>
	add	cx,offset SRI_text      ;size req'd for header
	call	ChunkArrayElementResize ;resize the right part

		;now deref the left chunk to return.
	dec	ax
	call	ChunkArrayElementToPtr
	clc				;OK to print this element now.....

exit:
	.leave
	ret
SnipTextString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
SYNOPSIS:	Extract text strings from a gstring for one document page

CALLED BY:	INTERNAL
		DoTextPrinting

PASS:		si		- gstring handle
		di		- gstate handle

RETURN:		ax		- GSRetType
		bx		- data accompanying GSRetType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Search for output elements in the gstrings...
		Accumulate/sort them in a separate block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTextStrings	proc	near
		uses	cx, dx
curJob		local	SpoolJobInfo
		.enter 	inherit

		; first off, lock down the TextStrings block

		mov	bx, curJob.SJI_tsHan		; lock down block
		call	MemLock
		mov	ds, ax				; ds -> TextString blk

		; search for the next output element
keepScanning:
		mov	dx, mask GSC_NEW_PAGE or mask GSC_OUTPUT
		clr	ax
		clr	bx
		call	GrDrawGString			; go until we hit one
		mov	ax, dx				; save return code

		; if we're done with the page, exit.  If the last element in
		; the entire string is an output element, we will FAULT here,
		; so just map it to COMPLETE

		cmp	ax, GSRT_FAULT			; if some problem...
		jne	checkFormFeed			;  ...exit
		mov	ax, GSRT_COMPLETE			; map FAULT to COMPLETE
checkFormFeed:
		cmp	ax, GSRT_NEW_PAGE		; if at end of page..
		je	donePage			;  ...exit
		cmp	ax, GSRT_COMPLETE		; same if at end of 
		je	donePage			;  document

		; not at end of page, so we must have hit some output.
		; check to see what it is...

		clr	bx				; use bx as table index
tryNextCode:
		cmp	cl, cs:textOpcodes[bx]		; check for valid code
		je	foundValidCode
		inc	bx
		cmp	bx, NUM_VALID_TEXT_CODES
		jb	tryNextCode

		; it's not a text-output code, skip it.  Need to execute it
		; so that the current position is updated correctly
		; We can return to our normal processing here, since the 
		; call will skip this element and go on.

		jmp	keepScanning

		; found a valid text opcode, extract the string
		; We need to get the current transformation matrix elements,
		; so we may apply the appropriate translation.  We do not 
		; do scales/rotates.
foundValidCode:
		shl	bx, 1				; make it a word index
		call	cs:extractRouts[bx]		; call routine
		jmp	keepScanning

		; all done, exit
donePage:
		mov	bx, curJob.SJI_tsHan		; unlock the block
		call	MemUnlock
		mov	bx, cx				; bx <- GSRetType data
		.leave
		ret
GetTextStrings	endp

;-------------------------------------------------------------------------
;		Text opcode table and extraction routine table
;-------------------------------------------------------------------------

		; table of valid text opcodes
textOpcodes	label	byte
		byte	GR_DRAW_TEXT_FIELD		; this is most common
		byte	GR_DRAW_TEXT
		byte	GR_DRAW_TEXT_CP
		byte	GR_DRAW_CHAR
		byte	GR_DRAW_CHAR_CP

NUM_VALID_TEXT_CODES	equ	$-textOpcodes


		; table of extraction routines
extractRouts	label	nptr
		nptr	offset cs:GetTextFieldString
		nptr	offset cs:GetTextString
		nptr	offset cs:GetTextCPString
		nptr	offset cs:GetCharString
		nptr	offset cs:GetCharCPString


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a text string from a gstring element and put it
		it our TextStrings block

CALLED BY:	INTERNAL
		GetTextStrings

PASS:		si		- handle to gstring
		di		- handle to gstate (contains current attr)
		ds		- segment of TextStrings block
		bp		- pointer to stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The current position in the gstring is at the element,
		so use GetElement to read in the data, then put the text
		string in the chunk.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Dave	08/92		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTextString	proc	near
		uses	ax, bx, cx, si, di, dx
		.enter 	

		; Get the element to see how big the string is

		call	ReadNextElement			; get the element

		; OK, we have the element and how big it is, so alloc 
		; a new text string chunk and init to current attributes

		mov	cx, ds:[bx].ODT_len		; get string length
		mov	ax, ds:[bx].ODT_x1		; get x,y coordinates
		mov	bx, ds:[bx].ODT_y1
		call	TransformStringPosition		; apply any transform
		mov	dx, size OpDrawText		; ds:si -> string
		mov	si, ds:[TS_gsBuffer]		; string is in buffer
		call	AllocStringChunk		; make some space

		.leave
		ret
GetTextString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextCPString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a text string from a gstring element and put it
		it our TextStrings block

CALLED BY:	INTERNAL
		GetTextStrings

PASS:		si		- handle to gstring
		di		- handle to gstate (contains current attr)
		ds		- segment of TextStrings block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The current position in the gstring is at the element,
		so use GetElement to read in the data, then put the text
		string in the chunk.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Dave	08/92		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTextCPString	proc	near
		uses	ax, bx, cx, si, di, dx
		.enter	

		; Get the element to see how big the string is

		call	ReadNextElement			; get the element

		; OK, we have the element and how big it is, so alloc 
		; a new text string chunk and init to current attributes

		mov	cx, ds:[bx].ODTCP_len		; get string length
		call	GrGetCurPos			; ax,bx = cur pen pos
		call	TransformStringPosition		; apply any transform
		mov	dx, size OpDrawTextAtCP		; ds:si -> string
		mov	si, ds:[TS_gsBuffer]		; string is in buffer
		call	AllocStringChunk		; make some space

		.leave
		ret
GetTextCPString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextFieldString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a text string from a gstring element and put it
		it our TextStrings block

CALLED BY:	INTERNAL
		GetTextStrings

PASS:		si		- handle to gstring
		di		- handle to gstate (contains current attr)
		ds		- segment of TextStrings block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Since the element could have multiple Style runs, we
		use GrCopyGString to copy it from the gstring to our local
		buffer, using the GST_CHUNK option on creating a gstring.

		Then we can take it apart.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Dave	08/92		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTextFieldString	proc	near
		uses	ax, bx, cx, si, di, dx
curJob		local	SpoolJobInfo
		.enter	inherit

		push	di			; save our gstate handle

		; first resize the buffer chunk to zero

		mov	ax, ds:[TS_gsBuffer]	; pass chunk handle too
		mov	cx, 0			; 
		call	LMemFree

		; first set up to draw into our buffer

		push	si			;save GString handle
		mov	cl, GST_CHUNK		; it's a memory type gstring
		mov	bx, ds:[TS_header].LMBH_handle ; get block handle
		call	GrCreateGString		; di = gstring handle
		mov	ds:[TS_gsBuffer], si	
		pop	si			;recover GString handle

		; now draw the one element into our buffer

		mov	dx, mask GSC_ONE	; return after one element
		clr	ax
		clr	bx
		call	GrCopyGString

		; that's all we need, so biff the string

		mov	si, di			; si -> destination GString
		clr	di			; no associated GState
		mov	dl, GSKT_LEAVE_DATA	; don't kill the data
		call	GrDestroyGString
		pop	di			; restore gstate handle

		; Now in the process of GrCopyGString-ing to the buffer, the
		; block may have moved (it being an LMem block and all).  We
		; wouldn't know it, of course, since ds is pushed/poped
		; by GrDrawGString.  So let's dereference it here.

		mov	bx, curJob.SJI_tsHan	; get the handle
		call	MemDerefDS		; dereference it

		mov	bx, ds:[TS_gsBuffer]	; get pointer to buffer
		mov	bx, ds:[bx]		; ds:bx -> buffer

		; get the size of the fixed part of the element

		mov	dx, (size OpDrawTextField + size TFStyleRun) 

		mov	si, size OpDrawTextField ; bx.dx -> string
		
		mov	cx,ds:[bx].ODTF_saved.GDFS_nChars ;get # chars.



		; do the first style run, it might be the only one too...

		mov	ax, ds:[bx].ODTF_saved.GDFS_drawPos.PWBF_x.WBF_int

		; loop through the style runs, getting out the attributes
styleRuns:

		; check for auto hyphen
		test	ds:[bx].ODTF_saved.GDFS_flags, \
						mask HF_AUTO_HYPHEN
		jz	stringFixed	
		call	FixUpAutoHyphen

stringFixed:
		call	HandleStyleRun		; handle next run
		cmp	cx, 0			; fewer characters to go
		jle	done			;  all done, exit

		; done with this style run, bump pointers on to the next one
		; also dereference the chunk again

		mov	bx, ds:[TS_gsBuffer]	; get chunk handle
		mov	bx, ds:[bx]		; dereference it
if DBCS_PCGEOS
		push	ax
		mov	ax, ds:[bx].[si].TFSR_count ;add past the text +...
		shl	ax, 1
		add	si, ax
		pop	ax
else
		add	si,ds:[bx].[si].TFSR_count ;add past the text +...
endif
		add	si, size TFStyleRun	; the size of this structure
		jmp	styleRuns		; do another run....

		; all done, just leave
done:
		.leave
		ret
GetTextFieldString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a Character from a gstring element and put it
		it our CharStrings block

CALLED BY:	INTERNAL
		GetTextStrings

PASS:		si		- handle to gstring
		di		- handle to gstate (contains current attr)
		ds		- segment of TextStrings block
		bp		- pointer to stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The current position in the gstring is at the element,
		so use GetElement to read in the data, then put the text
		string in the chunk.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	08/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCharString	proc	near
		uses	ax, bx, cx, si, di, dx
		.enter 	

		; Get the element to see how big the string is

		call	ReadNextElement			; get the element

		; OK, we have the element and how big it is, so alloc 
		; a new text string chunk and init to current attributes

		mov	cx, 1			; get string length
		mov	ax, ds:[bx].ODC_x1		; get x,y coordinates
		mov	bx, ds:[bx].ODC_y1
		call	TransformStringPosition		; apply any transform
		mov	dx, offset ODC_char	; ds:si -> string
		mov	si, ds:[TS_gsBuffer]		; string is in buffer
		call	AllocStringChunk		; make some space

		.leave
		ret
GetCharString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCharCPString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a Character from a gstring element and put it
		it our TextStrings block

CALLED BY:	INTERNAL
		GetTextStrings

PASS:		si		- handle to gstring
		di		- handle to gstate (contains current attr)
		ds		- segment of TextStrings block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The current position in the gstring is at the element,
		so use GetElement to read in the data, then put the text
		string in the chunk.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	08/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCharCPString	proc	near
		uses	ax, bx, cx, si, di, dx
		.enter	

		; Get the element to see how big the string is

		call	ReadNextElement			; get the element

		; OK, we have the element and how big it is, so alloc 
		; a new text string chunk and init to current attributes

		mov	cx, 1			; get string length
		call	GrGetCurPos			; ax,bx = cur pen pos
		call	TransformStringPosition		; apply any transform
		mov	dx, offset ODCCP_char	; ds:si -> string
		mov	si, ds:[TS_gsBuffer]		; string is in buffer
		call	AllocStringChunk		; make some space

		.leave
		ret
GetCharCPString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformStringPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the string position, adding the base line offset
		to the y position before using the GrTransform routine.

CALLED BY:	INTERNAL
		GString extraction routines -
		GetTextString,GetTextCPString,GetCharString,GetCharCPString

PASS:		si		- handle to gstring
		di		- handle to gstate (contains current attr)
		ax		- Xposition
		bx		- Yposition

RETURN:		ax,bx transformed

DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		add the baseline offset to the y position,
		call GrTransform to do the rest.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransformStringPosition	proc	near
		push	ax,si			;save the X position.
		call	GrGetTextMode		;see how we are positioned.
		and	al,mask TM_DRAW_BASE or mask TM_DRAW_BOTTOM \
				or mask TM_DRAW_ACCENT
		jz	drawFromTop
		and	al,not mask TM_DRAW_BASE ;see if baseline ref.
		jz	yPosCorrected		;jmp if baseline...
		and	al,not mask TM_DRAW_BOTTOM ;see if bottom ref.
		jz	drawFromBottom
		mov	si,GFMI_ROUNDED or GFMI_ASCENT ;must be accent ref.
		jmp	correctTheYPos
drawFromBottom:
		mov     si,GFMI_ROUNDED or GFMI_DESCENT ;I'm assuming this is 
		jmp	correctTheYPos			;a signed value.
drawFromTop:
                mov     si,GFMI_ROUNDED or GFMI_BASELINE
correctTheYPos:
                call    GrFontMetrics
                add     bx,dx                   ;add the baseline to y pos.
yPosCorrected:
		pop	ax,si			;recover the X position.
                call    GrTransform             ; apply any transform
		ret
TransformStringPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixUpAutoHyphen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we need to put a hyphen at the end

CALLED BY:	INTERNAL
		GetTextFieldString

PASS:		ds:bx	 - pointer to TextField element (base of current
			   chunk)
		ds:bx.dx - pointer to text string (within ds:bx)
		ds:bx.si - pointer to TFStyleRun
		cx	 - character count

RETURN:		cx	 - real char count
		ds:bx	 - fixed up
		ds:dx	 - pointer to text string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		 have an auto-hyphen.
		 Re alloc the chunk and add a hyphen at end..
		 has to be the last string in the text field

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixUpAutoHyphen	proc	near
	uses	ax, di

	cmp	cx,ds:[si].[bx].TFSR_count	; see if this is the last run
	jne	exit				; if not, dont bother.

	.enter	
	push	si
	push	cx				; save string length

	mov	ax, ds:[TS_gsBuffer]		; load the handle of chunk
	add	cx,dx				; add stuff from before...
	add	cx, 2				; add some space
	call	LMemReAlloc
	pop	cx				; recover string length

	mov	di, ax				; di -> chunk handle
	mov	bx, ds:[di]			; get pointer to chunk

	mov	si,dx				; pointer to string
	add	si,cx				; point at end of string
	mov	{byte} ds:[si].[bx], '-'	; stuff a hyphen there.
	inc	cx				; really is one more
	pop	si
	mov	ds:[si].[bx].TFSR_count,cx	; save in the TFStyleRun.

	.leave
exit:
	ret

FixUpAutoHyphen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleStyleRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a single style run of a GrDrawTextField element,
		including any embedded graphics strings

CALLED BY:	INTERNAL
		GetTextFieldString

PASS:		ds:bx	 - pointer to element
		ds:bx+si - pointer to TFStyleRun structure
		ax	 - x position to draw string
		cx	 - #chars still left to draw (before this run)
		dx	 - offset into string chunk to find string
		di	 - gstate handle

RETURN:		cx	 - #chars still left to draw (after this run)
		dx	 - updated to past style run characters
		ax	 - modified x position for next style run.
		ds	 - probably has moved due to AllocStringChunk.

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		Set the current attributes, allocate a StyleRunInfo element,
		blah, blah, blah

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version
		Dave	7/92		Initial 2.0 version	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HandleStyleRun	proc	near
	uses	bx,si,di
curJob	local	SpoolJobInfo
	.enter	inherit
	push	cx			; save #chars left (total)
	add	si, bx			; ds:si -> TFStyleRun
	add	si, TFSR_attr		; point to attributes
	mov	ds:[si].TA_spacePad.WBF_int, 0 ; set no space padding
	mov	ds:[si].TA_spacePad.WBF_frac, 0 ; set no space padding
	call	GrSetTextAttr		; set the text attributes
	sub	si, TFSR_attr
	sub	si, bx			; things back to normal
	mov	cx, ds:[bx][si].TFSR_count ; get character count
	push	dx,si
	mov	curJob.SJI_textXPosition,ax ;save this runs x position.
	mov	si, bx			;get offset to text.
	add	si, dx
	call	GrTextWidth		; get the width of this text string
	add	ax,dx			; add to the xPosition for next time.
	pop	dx,si
	push	ax,dx,si
	mov	ax, ds:[bx].ODTF_saved.GDFS_drawPos.PWBF_y.WBF_int ; get y pos
	add	ax, ds:[bx].ODTF_saved.GDFS_baseline.WBF_int ; get baseline pos
	mov	bx,ax			; get into bx now that we are done.
	mov	ax,curJob.SJI_textXPosition ;recover this runs x position.
	call	GrTransform		; transform the coordinates
	call	GrSaveState		; save font, point size...
	call	AllocStringChunk 	; save the string
	call	GrRestoreState		; restore font, point size...

	pop	ax,dx,si

haveString::
	add	dx, cx			; bump string offset
DBCS <	add	dx, cx			; char offset -> byte offset	>
	add	dx, size TFStyleRun	; add the size of this structure
	mov	di, cx			; save char count
	pop	cx			; restore #chars left (total)
	sub	cx, di			; are we done ?
	.leave
	ret

HandleStyleRun	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadNextElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the next gstring element into our buffer

CALLED BY:	INTERNAL
		GetTextString

PASS:		ds	- segment of TextString block
		si	- gstring handle
		di	- gstate handle

RETURN:		bx	- pointer to start of buffer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Read the element into our buffer, resizing if necc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadNextElement	proc	near
		uses	si, ax
		.enter
tryAgain:
		mov	bx, ds:[TS_gsBuffer]		; handle of buff chunk
		ChunkSizeHandle	ds, bx, cx		; get size of chunk
		tst	cx				; if null, enlarge it
		jz	reallocChunk
getElement:
		mov	bx, ds:[bx]			; get ptr to chunk
		call	GrGetGStringElement		; extract GR_DRAW_TEXT
		cmp	bx, si				; was it copied ?
		jne	done				;  yes, all done
		mov	ax, ds:[TS_gsBuffer]		;  no, resize chunk
		call	LMemReAlloc			; re-alloc the buffer
		jmp	tryAgain
done:
		.leave
		ret

reallocChunk:
		mov	ax, bx				; get chunk handle
		mov	cx, 512				; make it big enough
		call	LMemReAlloc
		jmp	getElement
ReadNextElement	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocStringChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alloc a text string chunk, and fill in the info

CALLED BY:	INTERNAL
		GetTextString, GetTextStringCP

PASS:		*ds:si		- chunk to find string in
		dx		- offset into chunk to find string
		cx		- length of string
		ax,bx		- x,y position to draw string

		di		- gstate handle

RETURN:		ds		- may have moved through allocs.

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		use the Y position, and X position of the passed text to build
		out an ordered array of increaseing Y position. If the Y
		position is equal, the X position is use to order the elements.
		At the same time, another array is built of the
		font/style/color/etc info associated with the text.
		At print time the array is enumerated in order, and the text
		sent out in an order that the printer (dot-matrix especially)
		needs.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	07/92		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocStringChunk proc	near
	uses	cx, dx, di, si, es
curJob	local	SpoolJobInfo
	.enter	inherit

		;if cx=0, then we either have an embedded graphic or an
		;empty string.  In either case, lets bail.
	test	cx,cx
LONG	jz	exit

		;if the suppress form-feed flag is set, them bump the y
		;positions by the margin amount.
	test	curJob.SJI_printState, mask SPS_FORM_FEED
	jnz	findControlCodes
	add	bx, paperInfo.PSR_margins.PCMP_top	; add in top end

		;ferret out those nasty one-character control codes and
		;skip the allocation 
findControlCodes:
	mov	si,ds:TS_gsBuffer	;source for string.

	mov	si, ds:[si]		; deref chunk
	add	si, dx			; get ptr to string

	cmp	cx, 1			; one character ?
	jne	allocNewChunk		;  no, continue

SBCS <	cmp	{char} ds:[si], C_SPACE	; control code			>
DBCS <	cmp	{wchar} ds:[si],C_SPACE	; control code			>
	jae	allocNewChunk		; OK if real character
	clr	si			; no string allocated
	jmp	exit

		; find/alloc a Chunk Array Element for this text string.  
		;ds:si has to be the locked array here......
		;ax = x position
		;bx = y position
allocNewChunk:
	call	TranslateSpecialChars	;fix the hyphens etc....
	mov	ds:TS_textOffset,dx	;save the text offset in gstring chunk.
	mov	curJob.SJI_textXPosition,ax	;save x pos.
	mov	curJob.SJI_textYPosition,bx	;save y pos.
	push	di			;save GState handle.
	push	cx			;save the length of the string text
	mov	si,ds:TS_styleRunInfo	;handle of the chunkarray.
	call	ChunkArrayGetCount	;see if there are any elements yet.
	clc				;set up to append
	jcxz	popNGo			;if not, pop the length of string....
	mov	cx,curJob.SJI_textXPosition
	mov	dx,curJob.SJI_textYPosition
	mov	bx,cs			;address of callback routine.
	mov	di,offset FindXYPosition
	call	ChunkArrayEnum		;get the element with the next lower
					;position to insert in front of.
					;on return from the enum routine,
					;the carry will be set for a peice of
					;text that should remain after the 
					;new text. In this case
					;ChunkArrayInsertAt is called
					;If the carry is cleared, then there is
					;no text below or to the right, and
					;this text should go at the end of the
					;array.
	mov	di,ax			;get ds:di = element address.
popNGo:
	pop	cx			;recover the length of the string text
	pushf
	mov	ax,cx			;size required for string
DBCS <	shl 	ax, 1							>
	add	ax,offset SRI_text	;size req'd for header
	popf
	jc	insertTheElement
	call	ChunkArrayAppend	;add it on the end.
	jmp	initElement

insertTheElement:
	call	ChunkArrayInsertAt	;insert the string here

initElement:
	mov	ax,curJob.SJI_textXPosition
	mov	bx,curJob.SJI_textYPosition
	mov	ds:[di].SRI_yPosition,bx ;load the new y position.
	mov	ds:[di].SRI_xPosition,ax ;load the new x position.
	mov	ds:[di].SRI_numChars,cx	;load the length of string.
		;now load the text string into the chunk.
	push	di			;save offset to this chunk.
	add	di,offset SRI_text	;point at the text position.
	segmov	es,ds,ax		;get destination (same lmem block)
	mov	si,ds:TS_gsBuffer	;source for string.
	mov	si,ds:[si]		;deref chunk.
	add	si,ds:TS_textOffset	;add to get past the gstring structure.
if not DBCS_PCGEOS
	shr	cx,1			;divide /2 for word move.
	jnc	textMove
	movsb
	jcxz	afterTextMove		;if there was only one character in the
					;style run, skip the move following...
textMove:
	rep movsw
afterTextMove:

else
	rep movsw
endif


		;now we need to see if there is an existing attribute block
		;that matches what we have passed here. If there is one, then 
		;just load the SRI_attributes pointer with the element number
		;of the matching attribute block. If there is no matching
		;block, we add one at the end of the array, and store that
		;element number.
		;ds = lmem block
		;di = GState handle
		;fill out the element to add.....

	pop	si				;offset to SRI chunk
	pop	di				;GState handle.
	mov	cx, ds:[si].SRI_numChars	;get #chars
	push	si				;save chunk offset
	add	si,offset SRI_text		;offset to beginning of chars
	call	GrTextWidthWBFixed	; figure out how wide
	pop	si				;recover chunk offset
	add	ds:[si].SRI_stringWidth.WBF_frac, ah
	adc	ds:[si].SRI_stringWidth.WBF_int, dx ; 
	call	GetTextAttr			;load the TestAttribute table
						;from GState.

		;Now that we have all the good info to set a font/style/size,
		;either add or get the element # of an identical set of 
		;attributes.
	mov	di,si
	mov	si,ds:[TS_styleRunInfo]		;handle of the chunk array.
	call	ChunkArrayPtrToElement		;get # of this style run.
	push	ax				;save away for later.
	mov	si,ds:TS_textAttributeInfo		;element array 
	mov	cx,ds				;in this lmem segment
	mov	dx,offset TS_testAttribute	;element to compare and add
EC <	mov	bx,ss				;stuff es w/valid	>
EC <	mov	es,bx				;segment info		>
	clr	bx
	mov	di,bx				;set to zero to do compare.
	call	ElementArrayAddElement		;return the element number
	mov	dx,ax				;save attr element #
	mov	bx, curJob.SJI_tsHan	; get the handle
	call	MemDerefDS		; dereference it
	
	; the code above may screw up if the block moves, so here we copy the
	; data again to make sure it's correct.  We could copy it to the 
	; stack before calling ElementArrayAddElement, but here we don't use 
	; up valuable stack space (20+ bytes).

	mov	si,ds:TS_textAttributeInfo		;element array 
	call	ChunkArrayElementToPtr		;  ds:di -> element just added
	mov	cx, size TextAttrInfo		;  cx = element size
	segmov	es, ds				; es:di -> element just added
	mov	si, offset TS_testAttribute	; ds:si -> source of attr info
	rep	movsb

	pop	ax				;recover chunk #
	mov	si,ds:[TS_styleRunInfo]		;handle of the chunk array.
	call	ChunkArrayElementToPtr	;get the address of this style run.
	
	mov	ds:[di].SRI_attributes,dx	;in ax for StyleRunInfo.


exit:
	.leave
	ret

AllocStringChunk endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateSpecialChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix up the special characters that may be in the string.

CALLED BY:	INTERNAL

PASS:		ds:si		- string address
		cx		- length of string
		di - Gstate handle

RETURN:		cx		- length of string (may have changed)
		string adjusted to contain the right hyphenation, etc.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	04/93		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TranslateSpecialChars	proc	near
	uses	ax,bx,dx,si,es
	.enter
	push	cx
	mov	bx,di			;GState handle
	segmov	es,ds,di
	mov	di,si			;everything points at the string.
	clr	dx			;dx now counts skipped chars.
checkLoop:
	LocalGetChar ax, dssi		;get a char
SBCS <	cmp	al,C_NONBRKHYPHEN	;is it a non breaking hyphen?	>
DBCS <	cmp	ax,C_NON_BREAKING_HYPHEN ;is it a non breaking hyphen?	>
	jne	checkOptHyphen
SBCS <	mov	al,C_HYPHEN		;if it is, replace with printable "-".>
DBCS <	mov	ax,C_HYPHEN		;if it is, replace with printable "-".>
	jmp	thisCharTested
checkOptHyphen:
                ;Now we see if this char was an Optional hyphen.
SBCS <	cmp     al,C_OPTHYPHEN          ;is it?				>
DBCS <	cmp     ax,C_SOFT_HYPHEN        ;is it?				>
        jne     thisCharTested
		;if here then it is an opt hyphen...
	cmp	cx,1			;if we are not at end,
	jne	thisCharSkipped		;just skip this char
	xchg	bx,di
	call	GrGetTextMode		;see if we need to print it.
	xchg	bx,di
	cmp	al,mask TM_DRAW_OPTIONAL_HYPHENS
	jz	thisCharSkipped		;if not, just exit....
SBCS <	mov	al,C_HYPHEN		;if so, replace with printable "-".>
DBCS <	mov	ax,C_HYPHEN		;if so, replace with printable "-".>
thisCharTested:
	LocalPutChar esdi, ax		;stuff the char back in the string
loopBack:
	loop	checkLoop		;check the next character.
	pop	cx
	sub	cx,dx			;subtract the number of skipped chars
	mov	di,bx			;recover GState handle
	.leave
	ret

thisCharSkipped:
	inc	dx
	jmp	loopBack

TranslateSpecialChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the important attributes out of the GState

CALLED BY:	INTERNAL

PASS:		ds - segment of the TextAttributes lmem block
		di - Gstate handle

RETURN:		
		ds:[TS_testAttribute] structure loaded.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	06/92		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTextAttr proc near
	uses	ax,bx,si,di,ds,es
	.enter
	segmov	es,ds,ax			;move the lmem to es.
	mov	bx,di				;lock GState
	call	MemLock
	mov	ds,ax				;get segment of GState.
	mov	di,offset TS_testAttribute.TAI_color	;start of my table.
		;set RGB value.
	mov	si,offset [GS_textAttr].[CA_colorRGB]
	movsw
	movsb
		;set system draw mask.
	mov	al,ds:[GS_textAttr].[CA_maskType]
	stosb
		;set styles.
	mov	al,[GS_fontAttr].[FCA_textStyle]
	call	MapToPrinterStyle			;translate the mess
	stosw
		;set text mode. 
	mov	al,ds:[GS_textMode]
	stosb
		;set space padding.
	mov	si,offset [GS_textSpacePad]
	movsb
	movsw
		;set FontID enum.
	mov	si,offset [GS_fontAttr].[FCA_fontID]
	movsw
		;set size.
	movsb
	movsw
		;set track kerning.
	mov	ax, {word}ds:[GS_trackKernValue]
	stosw
		;set the font weight.
	mov	al,ds:[GS_fontAttr].[FCA_weight]	
		;set the font width.
	mov	ah,ds:[GS_fontAttr].[FCA_width]
	stosw

	call	MemUnlock			;bx should still be GState han
	.leave
	ret
GetTextAttr endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindXYPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find the element with the next lower position in Y and
		X, (higher numbers)

CALLED BY:	INTERNAL
		Callback for ChunkArrayEnum in AllocStringChunk

PASS:		*ds:si - array
		ds:di - array element being enumerated
		ax - element size
		cx - x position of new text.
		dx - y position of new text.

RETURN:		ds:ax - address of this element 
		carry set if this is the one to insert in front of.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	06/92		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindXYPosition proc far
	.enter
	mov	bx,di			;save the offset of this element.
	cmp	dx,ds:[di].SRI_yPosition	;check the Y position.
	ja	exitClr			;jump if new text is below this text
	jb	exitSet			;insert if above this text
		;if here must be equal y positions.
	cmp	cx,ds:[di].SRI_xPosition	;check the X position.
	jbe	exitSet			;if to left or same, then insert
	clc
	jmp	exit			;haven't found what we want yet.
exitSet:
	stc
exit:
	mov	ax,bx			;recover the offset to the element
	.leave
	ret
exitClr:
	clc
	jmp	exit
	
FindXYPosition endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapToPrinterStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the current TextStyle setting to a valid 
		PrintTextStyle record

CALLED BY:	INTERNAL
		AllocStringChunk

PASS:		al		- TextStyle record to translate

RETURN:		ax		- PrintTextStyle equivalent

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The bit mapping is screwed.  Just do it brute force.

		Style		TextStyle		PrintTextStyle
		-----		----------		---------------
		OUTLINE		bit 6			bit 6
		BOLD		bit 5			bit 11
		ITALIC		bit 4			bit 10
		SUPERSCRIPT	bit 3			bit 13
		SUBSCRIPT	bit 2			bit 14
		STRIKE_THRU	bit 1			bit 8
		UNDERLINE	bit 0			bit 9

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MapToPrinterStyle	proc	near
		uses	dx, bx, cx
		.enter

		clr	dx
		clr	ah
		tst	al			; if zero, we're done
		jz	done		

		; have some bits set, so handle them

		mov	cx, NUM_TEST_BITS
		clr	bx
testLoop:
		test	ax, cs:sourceBitTable[bx] ; next bit set ?
		jz	nextBit			;  no, on to next one
		or	dx, cs:destBitTable[bx]	;  yes, set the bit
nextBit:
		add	bx, 2			; on to next entry
		loop	testLoop
done:
		mov	ax, dx
		.leave
		ret
MapToPrinterStyle	endp

sourceBitTable	label	word
		word	mask TS_OUTLINE
		word	mask TS_BOLD
		word	mask TS_ITALIC
		word	mask TS_SUPERSCRIPT
		word	mask TS_SUBSCRIPT
		word	mask TS_STRIKE_THRU
		word	mask TS_UNDERLINE
NUM_TEST_BITS	equ	($-sourceBitTable)/2

destBitTable	label	word
		word	mask PTS_OUTLINE
		word	mask PTS_BOLD
		word	mask PTS_ITALIC
		word	mask PTS_SUPERSCRIPT
		word	mask PTS_SUBSCRIPT
		word	mask PTS_STRIKETHRU
		word	mask PTS_UNDERLINE




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AskForNextTextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask for the next piece of paper for manual feed, if needed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax	- dialog box results

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		check manual feed flag and do the right thing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AskForNextTextPage	proc	near
curJob		local	SpoolJobInfo
		uses	bx,dx
		.enter	inherit

		push	ds
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		test	ds:[PS_paperInput], mask PIO_MANUAL
		call	MemUnlock			; (preserves flags)
		pop	ds
		jz	done				;  no, auto-fed paper

		; we have a manual feed situation.  Ask the user to stick
		; another piece (but nicely)

		mov	cx, SERROR_MANUAL_PAPER_FEED	; ask for next piece
		clr	dx
		call	SpoolErrorBox			; he can only answer OK
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
done:
		.leave
		ret
AskForNextTextPage	endp

endif	;_TEXT_PRINTING

PrintText	ends

