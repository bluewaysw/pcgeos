COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Group3 Printer Driver
FILE:		group3CoverSheet.asm

AUTHOR:		Andy Chiu, Oct  6, 1993

ROUTINES:
	Name			Description
	----			-----------
	
	INT FaxInfoPrintCoverSheet
				Handles the esc from the print spooler so we
				can add a cover page.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 6/93   	Initial revision


DESCRIPTION:
	
	Routines for creating a cover sheet for the fax file.

	$Id: group3CoverSheet.asm,v 1.1 97/04/18 11:52:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3CreateCoverPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin rasterizing the cover page for the fax file.

CALLED BY:	Group3EndJob

PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	possibly adds a cover page to the fax file

PSEUDO CODE/STRATEGY:

	- see if a cover page is selected in the fax file header
	- if not, generate the cover page.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3CreateCoverPage	proc	near
		uses	ax, bx, si, bp, ds, es
		.enter
	;
	;  Examine the FaxFileHeader of the current fax file to see
	;  if it's supposed to have a cover page.
	;
		segmov	es, ds, bx			; es = dgroup
		mov	bx, es:[outputVMFileHan]
		call	FaxFileGetHeader		; ds:si = FaxFileHeader
		jc	done

		mov	bx, ds:[si].FFH_flags
		call	VMUnlock

		test	bx, mask FFF_COVER_PAGE
		jz	done
	;
	;  Call routine to create cover page.
	;
		call	CreateAndAppendSwaths
done:
		.leave
		ret
Group3CreateCoverPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAndAppendSwaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to create the cover page proper.

CALLED BY:	Group3CreateCoverPage

PASS:		es = dgroup

RETURN:		cover page added to fax file
		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This is the outermost loop in the process of creating the
	coverpage.  We do the following:

		* create a small swath bitmap
		* initialize & load coverpage gstring
	loop:
		* set the origin in the swath
		* draw the coverpage gstring to the swath
		* compress & append each scanline to the file (1st page)

	(end loop)

		* destroy swath
		* unload coverpage gstring

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine does not handle errors!  It uses "defensive
	programming," exiting if it finds a fatal problem but not
	notifying the user or doing anything more intelligent.

	It should be fixed to handle errors better.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAndAppendSwaths	proc	near
		uses	ax,bx,cx,dx,si,di,bp

		swathCount	local	word
		scanBuffer	local	COMPRESS_DATA_BUFFER_SIZE dup (char)
		swath		local	dword		; the swath bitmap
		coverPage	local	dword		; coverpage VM handle
		blockHandle	local	hptr		; gstring data block

		ForceRef	scanBuffer
		
		.enter
	;
	;  Create the swath for drawing (and a gstate in di).
	;
		call	CreateSwath			; ^vbx:ax = swath
		jc	exit				; no can do...
		movdw	swath, bxax
	;
	;  Initialize the swath count -- 1/2" high swaths, 11" high
	;  page => 22 swaths.
	;
		mov	ss:swathCount, FAX_COVERPAGE_NUM_SWATHS
	;
	;  Add a coverpage to to the fax file, and save the handle
	;  of the huge array.
	;
		mov	cx, FAX_PAGE_FIRST		; put in front
		mov	ax, FAP_ADD_CREATE		; make a huge array
		call	FaxFileInsertPage		; dx = HA handle
		movdw	coverPage, bxdx
	;
	;  Get the spooler gstring handle into si (it contains the
	;  coverpage data, which we drew in the PREPEND_PAGE handler).
	;
		call	GetCoverPageGString		; bx = file handle
		jc	destroySwath			; si = gstring handle
		mov	blockHandle, bx			; save for free
	;
	;  Initialize the origin y-translation (and x too) to zero.
	;
		clr	ax, bx, cx, dx			; bx = y-trans (0)
	;
	;  During the loop:
	;
	;	si = spooler gstring handle (w/ coverpage data)
	;	di = swath gstate
	;	bx = origin y-translation (decrements each time)
	;	ax, cx, dx = cleared (for GrApplyTranslation)
	;	es = dgroup
swathLoop:
	;
	;  Update the origin, translating it upwards.
	;
		call	GrApplyTranslation
	;
	;  Draw our gstring to the swath.
	;
		call	DrawGStringToSwath
	;
	;  Append the swath (handles compression).
	;
		call	AppendSwathToFaxFile
	;
	;  Loop (next swath) after moving origin up half an inch.
	;
		mov	bx, (-1 * 36)			; up 1/2"
		dec	swathCount			; next swath
		jnz	swathLoop
doneLoop::
	;
	;  Undo all the setup stuff in the reverse order that
	;  we set it all up, so if any setup operation fails, it
	;  can undo all that came before it by jumping to the
	;  appropriate label below.  Start by unloading the
	;  spooler's gstring.
	;
		push	di				; save swath gstate
		clr	di				; no gstate
		mov	dl, GSKT_LEAVE_DATA		; we free this ourselves
		call	GrDestroyGString
		pop	di				; restore swath gstate
	;
	;  Free the data block containing coverpage gstring data.
	;
		mov	bx, blockHandle
		call	MemFree
destroySwath:
	;
	;  Destroy the swath bitmap.
	;
		mov	al, BMD_KILL_DATA		; no longer need it
		call	GrDestroyBitmap
exit:
		.leave
		ret
CreateAndAppendSwaths	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a swath bitmap.

CALLED BY:	CreateAndAppendSwaths

PASS:		es = dgroup

RETURN:		^vbx:ax = bitmap
		di	= gstate

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSwath	proc	near
		uses	cx,dx,si
		.enter
	;
	;  Get the resolution to determine the swath height to use.
	;
		call	GetFaxResolution	; ax = x res, bx = y res
		mov	dx, COVERPAGE_STD_SWATH_HEIGHT
		cmp	bx, FAXFILE_STD_VERTICAL_RESOLUTION
		je	gotHeight
		mov	dx, COVERPAGE_FINE_SWATH_HEIGHT
gotHeight:
	;
	;  Create the (temporary) swath bitmap in the output fax
	;  file, and set the appropriate bitmap resolution.
	;
		push	ax, bx			; bitmap resolution
		clr	di, si			; exposure object
		mov	bx, es:[outputVMFileHan]	; use fax file
		mov	al, BMType <0, 1, 0, 1, BMF_MONO>
		mov	cx, FAXFILE_HORIZONTAL_WIDTH
		call	GrCreateBitmap		; ^vbx:ax = bitmap
						; di = gstate to bitmap
		movdw	cxdx, bxax		; ^vcx:dx = bitmap
		pop	ax, bx			; ax = x, bx = y (resolution)
		call	GrSetBitmapRes

		movdw	bxax, cxdx		; ^vbx:ax = bitmap

		.leave
		ret
CreateSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFaxResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out whether we're in FINE or STANDARD mode.

CALLED BY:	CreateAndAppendSwaths

PASS:		es	= dgroup

RETURN:		ax = x res
		bx = y res
		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/15/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFaxResolution	proc	near
		uses	cx,dx,si,bp,ds
		.enter
	;
	;  Get the fax file header and look at the resolution.
	;
		mov	bx, es:[outputVMFileHan]
		call	FaxFileGetHeader		; ds:si = header
		jc	done
	;
	;  While we've got the x & y resolution of the fax available,
	;  use them to set the resolution of the swath bitmap.
	;
		mov	ax, ds:[si].FFH_xRes
		mov	bx, ds:[si].FFH_yRes
	;
	;  Unlock the fax file header.
	;
		call	VMUnlock
done:
		.leave
		ret
GetFaxResolution	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendSwathToFaxFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use fax file library to compress the scan lines.

CALLED BY:	CreateAndAppendSwaths

PASS:		ss:bp	= inherited stack frame from CreateAndAppendSwaths

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- compress each element of the swath (doesn't actually
	  compress the element -- puts data in local buffer)
	- append scanline to fax file (coverpage)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendSwathToFaxFile	proc	near
		uses	ax,bx,cx,dx,si,di,ds,es		; not bp though
		.enter	inherit CreateAndAppendSwaths
	;
	;  Loop through the lines of the swath, compressing them
	;  and appending them to the fax-file cover-page hugearray.
	;
		movdw	bxdi, ss:swath			; swath bitmap
		clr	dx, ax				; lock first element
		call	HugeArrayLock			; ds:si = element
		segmov	es, ss, di			; es = stack
scanLineLoop:
	;
	;  Call the faxfile library to compress 1 scanline.
	;
		lea	di, ss:scanBuffer		; es:di = output buffer
		mov	cx, FAXFILE_HORIZONTAL_BYTE_WIDTH
		mov	dx, COMPRESS_DATA_BUFFER_SIZE
		call	FaxFileCompressScanline		; cx = element size
EC <		cmp	cx, COMPRESS_DATA_BUFFER_SIZE			>
EC <		ERROR_A	FAX_SCANLINE_COMPRESSION_BUFFER_TOO_SMALL	>
	;
	;  Append the scanline to the output huge array.
	;
		movdw	bxdi, ss:coverPage		; output hugearray

		push	bp, si				; locals + element
		lea	si, ss:scanBuffer
		mov	bp, ss				; bp.si = data
		call	HugeArrayAppend			; append line to cover
		pop	bp, si				; locals + element
	;
	;  Loop to the next scanline.
	;
		call	HugeArrayNext			; ds:si = next element
		tst	ax				; done yet?
		jnz	scanLineLoop
doneLoop::
	;
	;  Unlock the last element in the swath.
	;
		call	HugeArrayUnlock

		.leave
		ret
AppendSwathToFaxFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCoverPageGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the spooler gstring file and load the gstring from it.

CALLED BY:	CreateAndAppendSwaths

PASS:		es = dgroup

RETURN:		si = coverpage gstring handle
		bx = handle of locked block containing the data
		     for GST_PTR gstring.  Caller must free block
		     when finished using gstring.

		carry set on error (bx & si garbage in this case)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCoverPageGString	proc	near
		uses	ax,cx,dx,di,bp,ds

		readBuf		local	word
		blockHan	local	hptr
		spoolFile	local	hptr
		tempState	local	hptr.GState

		.enter
	;
	;  Open the file.
	;
		mov	al, FILE_DENY_NONE		; be generous
		segmov	ds, es, dx
		mov	dx, offset gstringFileName	; ds:dx = filename
		call	FileOpen			; ax = file handle
		LONG	jc	done
	;
	;  Create a temporary GState for playing the gstring (we're
	;  trying to get to a specific offset in the gstring, so
	;  it doesn't matter where it gets drawn just yet).
	;
		mov	spoolFile, ax
		clr	di
		call	GrCreateState		; di = gstate
		mov	tempState, di
	;
	;  Load the gstring from the file.  Well, OK, it's not that
	;  simple.  We have to get the file position of the first
	;  GrComment from our GrLabel's word of data, skip to that
	;  file position + size GStringElement, read the size of
	;  the comment, and use THAT to read the next <size> bytes
	;  into a block.  We sick GrLoadGString on the block and
	;  use the returned handle for all swath operations.
	;
		mov_tr	bx, ax				; bx = file handle
		mov	cl, GST_STREAM
		call	GrLoadGString			; si = spooler gstring
	;
	;  Find our label in the spooler gstring.
	;
findLabel::
		mov	dx, mask GSC_LABEL	; look for a label
		call	GrDrawGStringAtCP	; dx = GSRetType, cx = value
	;
	;  If we didn't get a label back, then there's some sort
	;  of problem and we should just bail.
	;
		cmp	dx, GSRT_LABEL
		jne	destroyState
	;
	;  We got a label, and furthermore, we must assume that
	;  it is ours.  If somehow a label gets stuck in the
	;  spooler gstring *before* our label, it will have
	;  unpredictable and probably horrible results.  So given
	;  that it's our label, we use the value in cx to set the
	;  file position to the OC_size field of the subsequent
	;  OpComment.  (bx is still the file handle, amazingly).
	;
		mov	dx, cx
		clr	cx			; cx:dx = offset
		mov	al, FILE_POS_START
		call	FilePos
	;
	;  Now read the word of data containing the size of our
	;  gstring information.
	;
		clr	al
		mov	cx, size word
		segmov	ds, ss, dx
		lea	dx, ss:readBuf		; ds:dx = buffer for size
		call	FileRead
		jc	destroyState
	;
	;  Allocate a block in which to hold our GString data.
	;
		mov	ax, readBuf
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx = han, ax = seg
		jc	destroyState

		mov	blockHan, bx
		mov	ds, ax
getElement::
	;
	;  Get the body of the comment into our block.
	;
		clr	dx			; ds:dx = read buffer
		clr	al			; no read flags
		mov	cx, readBuf
		mov	bx, spoolFile		; bx = file handle
		call	FileRead		; fills ds:dx
	;
	;  We've read our data into the block we allocated.  Now
	;  load the gstring from the block.
	;
		mov	bx, ds			; segment address of data
		mov	cl, GST_PTR
		clr	si			; starts at start of block
		call	GrLoadGString		; si = gstring handle
		clc
destroyState:
	;
	;  Nuke the temp gstate and close the spool file.
	;
		pushf
		mov	di, tempState
		call	GrDestroyState
		mov	al, FILE_NO_ERRORS
		mov	bx, spoolFile
		call	FileClose
		popf

		mov	bx, blockHan		; could be garbage...
done:
		.leave
		ret
GetCoverPageGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawGStringToSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the cover-page gstring to passed swath.

CALLED BY:	CreateAndAppendSwaths

PASS:		di = swath gstate
		si = coverpage gstring handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/14/94		started life as FaxInfoPrintCoverSheet

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawGStringToSwath	proc	near
		uses	ax,bx,cx,dx
		.enter
	;
	;  IMPORTANT:  clear out the swath bitmap before drawing
	;  the gstring into it.
	;
		call	GrClearBitmap
	;
	;  Draw the string to the passed gstate.  We only draw
	;  our data, which ends in a GrEndString (conveniently).
	;  Also, there is a GR_MOVE_TO packaged into the gstring
	;  to make it draw at the appropriate location, so we
	;  only need clear ax & bx for it to work correctly.
	;
		clr	ax, bx, dx		; GSControl & origin
		call	GrDrawGString		; nukes cx

		.leave
		ret
DrawGStringToSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoPrintCoverSheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the coverpage gstring to the spooler gstring.

CALLED BY:	DR_PRINT_ESC_PREPEND_PAGE

PASS:		ax	= handle of GState to draw to
		bx	= handle of PState
		cx	= handle of duplicated "Main" tree
		dx	= handle of duplicated "Options" tree

RETURN:		nothing

DESTROYED:	ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoPrintCoverSheet	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		
		gState		local	hptr.GState	push	ax
		uiTree		local	hptr		push	cx
		fHandle		local	word
		startPos	local	word
		endPos		local	word
		dataSize	local	word

		.enter
	;
	;  Get the handle of the gstring file (for FilePos).
	;
		mov_tr	bx, ax				; bx = gstate block
		call	MemLock
		mov	ds, ax				; ds = GState
		mov	cx, ds:[GS_gstring]		; cx = gstring handle
		call	MemUnlock			; unlock gstate block
		mov	bx, cx
		call	MemLock				; lock gstring block
		mov	ds, ax				; ds = GString
		mov	cx, ds:[GSS_hString]		; get file handle
		call	MemUnlock
		mov	fHandle, cx			; save it
	;
	;  Lock the passed UI block.
	;
		mov	bx, uiTree
		call	ObjLockObjBlock
		mov	ds, ax				; ds = UI segment
	;		
	;  Query "CoverSheetList" to see if user wanted a cover sheet.
	;  If not, we don't have to do any of this. Selection returned in ax.
	;
		push	bp				; locals
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset CoverPageUseCoverPageItemGroup
		call	ObjCallInstanceNoLock
		pop	bp				; locals
		cmp	ax, TRUE
		LONG	jnz	done			; no selection!
writeLabel::
	;
	;  Figure out the file position before writing anything
	;  to the file.  We'll assume it's word-sized.  Then take
	;  that file position and add size OpLabel + size GStringElement.
	;  This gives us the offset to the OP_size field of the OpComment
	;  we'll be writing shortly.
	;
		mov	bx, fHandle
		mov	al, FILE_POS_RELATIVE
		clr	cx, dx			; move 0 bytes from current pos.
		call	FilePos			; dx:ax = current position

CheckHack <(size OpLabel + size GStringElement) eq 4>
		add	ax, 4
		mov	startPos, ax
	;
	;  Write a label whose word of data is the computed
	;  file position.
	;
		mov	di, gState
		call	GrLabel			; add our label
	;
	;  Draw a GR_COMMENT to the passed gstate, so that our 
	;  coverpage data doesn't get scaled.
	;
		clr	cx			; size 0 for now
		call	GrComment
	;
	;  Draw our gstring to the passed gstate.
	;
		call	DrawToSpoolerGString
	;
	;  Note:  the data we've written out so far may not have
	;  been entirely flushed to disk (which would make the
	;  next FilePos fail).  We call a routine that pads the
	;  current gstring chunk out to the flush threshold, so
	;  that on the next operation (GrEndGString), any leftover
	;  data gets written to disk.
	;
		call	MaybePadGStringChunk
	;
	;  Write oooooone laaaaaaast opcode to the gstring, which
	;  will cause it to flush like a cheap toilet.  It doesn't
	;  really matter which opcode we write, since the string
	;  ended *before* our padding.
	;
		call	GrEndGString
getPos::
	;
	;  Get the new file position and subtract the old file
	;  position to get the size of the data.  Then go back
	;  to the start position and set the comment-size field.
	;
		mov	al, FILE_POS_RELATIVE
		clr	cx, dx
		call	FilePos			; ax = end position

EC <		tst	dx						>
EC <		ERROR_NZ	COVERPAGE_GSTRING_DATA_LARGER_THAN_64K	>

		mov	endPos, ax		; save for later
		mov	cx, startPos		; cx = start position
		sub	ax, cx			; ax = data size
	;
	;  We have (in ax) the size of the data plus one word, since
	;  startPos was actually pointing to the OP_size field of the
	;  OpComment opcode, rather than to the actual beginning of
	;  the data.  Adjust accordingly.
	;
		dec	ax
		dec	ax
	;
	;  Set the file position to point to the OP_size field of
	;  the GrComment (we have this offset stored in startPos).
	;
		mov	dataSize, ax		; ax = data size
		mov	al, FILE_POS_START
		mov	bx, fHandle
		clr	cx
		mov	dx, startPos		; cx:dx = start position
		call	FilePos
	;
	;  Write the size of the data to the OP_size field.
	;  We should probably handle an error here ... how?
	;
		clr	al
		mov	cx, size word		; write 2 bytes
		segmov	ds, ss, dx
		lea	dx, ss:dataSize		; ds:dx -> bytes to write
		call	FileWrite
EC <		ERROR_C	COULD_NOT_WRITE_SPOOLER_GSTRING_FILE		>
	;
	;  Reset the file position to the end of our data.
	;
		mov	al, FILE_POS_START
		clr	cx
		mov	dx, endPos		; cx:dx = end position
		call	FilePos
done:
		.leave
		ret
FaxInfoPrintCoverSheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawToSpoolerGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the code that "works" (Andy's code to draw
		the gstring and the ink object to the passed gstate.

CALLED BY:	FaxInfoPrintCoverSheet

PASS:		di = gstate to which to draw
		ds = locked UI resource

RETURN:		nothing (UI block unlocked)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	AC	10/3/93			Initial version
	stevey	3/17/94			isolated to this routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawToSpoolerGString	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Modify the cover sheet gstring to hold the offsets of the text
	;  chunks for the text objects in the above tables.
	;
		.warn	-private

		push	di			; dest gstate

		mov	di, ds:[CoverGString]
		clr	bp
		mov	cx, length ptrOffsets
coverTextLoop:
		mov	bx, cs:ptrOffsets[bp]
		mov	si, cs:objChunks[bp]
	;
	;  Dereference the chunk containing the text object
	;  and point to the actual text within that object.
	;
		mov	si, ds:[si]
		add	si, ds:[si].Gen_offset
		mov	si, ds:[si].GTXI_text
	;
	; Store the current base of the chunk in the gstring opcode
	;
		mov	si, ds:[si]
		tst	{char}ds:[si]
		jnz	storeTextPtr
	;
	;  GR_DRAW_TEXT_PTR opcode screws up if null-terminator-only string
	;  is given to it (copies no data & gives length of 0, making
	;  GR_DRAW_TEXT handler draw the following gstring elements as
	;  the string), so give it a blank string instead.
	;
		mov	si, ds:[BlankString]
storeTextPtr:
		mov	ds:[di][bx].ODTP_ptr, si
	;
	;  Advance to next text object.
	;
		inc	bp
		inc	bp
		loop	coverTextLoop
afterLoop::
		.warn	@private

		pop	di			; gstate
	;
	;  Load the gstring so we can pass the handle to GrDrawGString.
	;
		mov	cl, GST_PTR
		mov	bx, ds
		mov	si, ds:[CoverGString]
		call	GrLoadGString		; si - gstring handle
	;
	;  Now draw the string to the passed gstate
	;
		mov	ax, COVER_LEFT_MARGIN
		mov	bx, COVER_TOP_MARGIN	; position on page to
						; play GString
		clr	dx			; play entire string
		call	GrDrawGString
	;
	;  Destroy the original gstring handle.
	;
		push	di			; save the gstate
		clr	di			; no associated gstate
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString

		pop	di			; restore the gstate
	;
	;  Finally, set up and draw the message text. This code is taken from
	;  the notepad. wheeee.
	;
		call	GrSetDefaultTransform
		mov	dx, FAX_MESSAGE_LEFT+COVER_LEFT_MARGIN
		clr	cx
		mov	bx, FAX_MESSAGE_TOP+COVER_TOP_MARGIN
		clr	ax
		call	GrApplyTranslation

if _PEN_BASED
		
	;		
	;  Now tell the ink object to draw itself
	;
		mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
		mov	si, offset CoverPageCommentsContent
		call	ObjCallInstanceNoLock
		

		mov	bp, di
		mov	cl, mask DF_EXPOSED or mask DF_PRINT
		mov	ax, MSG_VIS_DRAW
		call	ObjCallInstanceNoLock
else

	;
	; Draw the text object
	;
if 0
		mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
		mov	si, offset CoverPageCommentsView
		call	ObjCallInstanceNoLock
		

		mov	bp, di
		mov	cl, mask DF_EXPOSED or mask DF_PRINT
		mov	ax, MSG_VIS_DRAW
		call	ObjCallInstanceNoLock
endif
	;		
	; Added this code for NIKE, was blank be4
	; Now stuff the text into the empty text object
	; (Allocate text in memory block to prevent objects from shifting)
	;
		clr	dx
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		mov	si, offset CoverPageCommentsView
		call	ObjCallInstanceNoLock

		mov	bx, cx
		call	MemLock
		mov_tr	dx, ax
		
		clr	cx, bp
		mov	si, offset PrintTextEdit
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		call	MemFree
	;		
	; Now tell the text object to draw itself
	;
		mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
		call	ObjCallInstanceNoLock

		mov	bp, di
		mov	cl, mask DF_EXPOSED or mask DF_PRINT
		mov	ax, MSG_VIS_DRAW
		call	ObjCallInstanceNoLock
endif		
	;
	;  Draw an end-string to finish things off.
	;
		call	GrEndGString
	;
	;  Unlock the passed UI block.
	;
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock

		.leave
		ret
DrawToSpoolerGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaybePadGStringChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the thing gets written to disk.

CALLED BY:	FaxInfoPrintCoverSheet

PASS:		di = gstate handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	The reason we have to do this is that unless the data being
	written reaches a certain threshold, it won't be flushed to
	disk.

	We go into the gstring and get the size of the chunk it's
	using, and subtract that value from the threshold constant.
	This is how much space we need to write to the gstring to
	get it to flush.

	The structure of the gstring will be:
		 
		------------------------------------------
		Header   				  
		------------------------------------------
		<maybe some other of Don's stuff>
		------------------------------------------
		GrLabel (ours)
		GrComment <no size as yet>
		<coverpage gstring stuff here>
		GrEndPage
		------------------------------------------
		< space added by this routine >
		GrEndPage (again) (arbitrary)
		------------------------------------------

	Then we'll go back and stuff the size of the FIRST
	comment as being the size of our data + the padding.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GS_WRITE_THRESHOLD	equ	2048		; from graphicsConstant.def

MaybePadGStringChunk	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter
	;
	;  Lock the GState block to get the gstring block.
	;
		mov	bx, di
		call	MemLock			; lock GState
		mov	ds, ax
		mov	cx, ds:[GS_gstring]
		call	MemUnlock
	;
	;  Lock the gstring block to get the gstring chunk.  The
	;  gstring chunk is (conveniently) stored in the gstring
	;  block, so when we lock the block we can do all sorts
	;  of nifty things to the chunk.
	;
		mov	bx, cx
		call	MemLock			; lock gstring
		mov	ds, ax
	;
	;  If the chunk is already big enough, don't resize it.
	;
		mov	ax, ds:[GSS_fileBuffer]	; ax = gstring chunk handle
		ChunkSizeHandle	ds, ax, si	; si = size

		cmp	si, GS_WRITE_THRESHOLD	; is it already big enough?
		jae	unlock
	;
	;  The chunk is NOT big enough -- resize it to the threshold.
	;  (It will get slightly bigger than the threshold when we do
	;  the GrEndGString.  The point is that on that operation we
	;  want the thing to flush, so the chunk must be at least as
	;  big as the threshold NOW).
	;
		mov	cx, GS_WRITE_THRESHOLD	; make it at least this big
		call	LMemReAlloc
unlock:
		call	MemUnlock		; unlock gstring block

		.leave
		ret
MaybePadGStringChunk	endp


