COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		faxprintPrintSwath.asm

AUTHOR:		Jacob Gabrielson, Apr  7, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT PrintSwath		print a slice of the HugeArray bitmap to
				the output file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/ 7/93   	Initial revision
	AC	9/ 8/93		Changed for Group3
	jdashe	10/31/94	Updated for tiramisu
	jimw	4/12/95		Updated for multi-page cover pages

DESCRIPTION:

	$Id: faxprintPrintSwath.asm,v 1.1 97/04/18 11:53:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
;  Stick it in its own resource so the rest of the FaxPrint code
;  can move around while this stuff is locked down & executing.
;  Saves us about 6k of fixed blocks on the heap.
;
PrintSwathCode	segment	resource

.norcheck
.nowcheck


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a slice of the HugeArray bitmap to the output file.

CALLED BY:	DriverStrategy

PASS:		bp	= PState segment
		dx.cx	= VM file and block handle for Huge bitmap

RETURN: 	carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Check on disk space every ten lines.
	Get next scanline.
	Copy it into the unused swath buffer.
	Pass the scanline and the used swath buffer to the 2d compressor,
	  indicating that the first and every 64th line is to be compressed 1d.
	Copy the results into the fax file.
	Go back to first step.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/ 7/93    	Initial version
	AC	9/13/93		Modified for group3
	stevey	2/17/94		rewrote to use less fixed mem & heapspace
	jdashe	10/31/94	rewrote for 2D compression
	jimw	4/12/95		added multiple cover page support
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSwath	proc	far
		uses	ax, bx, cx, dx, di, si, ds, es, bp

compressedLine	local	word			; compressed line buffer segment
linesLeft	local	word			; how many lines to compress
currentLine	local	word			; what line to write next
spaceCheckCount	local	word			; count to 10 & check space
faxFile		local	hptr			; The Fax File
faxHugeArray	local	word			; fax huge array handle
swath1Buffer	local	word			; previous line buffer #1
swath2Buffer	local	word			; previous line buffer #2
totalLines	local	word			; total number page lines
printSwath	local	dword			; the passed print swath
twoDparams	local	FaxFile2DCommonParameters
lowestNonBlank	local	word			; lowest non-blank line

ForceRef	compressedLine
ForceRef	faxFile
ForceRef	faxHugeArray
ForceRef	swath1Buffer
ForceRef	swath2Buffer
ForceRef	twoDparams
		
		.enter
	;
	;  See if we're running out of disk space, and if we are,
	;  handle it.
	;
		mov	bx, handle dgroup
		call	MemDerefES		; es <- dgroup
	;
	; We may not need to do anything at all.
	;
		test	{word} es:[faxFileFlags], mask FFF_DONE_REPLACING
		jnz	exit
		
		call	CheckAvailableDiskSpace
	LONG	jc 	exit
	;
	; Store some dgroup variables locally, since we need all our
	; segment registers for the loop, and allocate the compressed line
	; buffer.
	;
		call	PrintSwathSetupLocals
	LONG	jc	exit			; jump if an error occurred.
	;
	;  Lock the first scan line of the passed print swath.
	;
		clr	dx, ax			; lock first element
		movdw	bxdi, ss:[printSwath]	; bx.di = swath's huge bitmap
		call	HugeArrayLock		; ds:si <- scanline
EC <		cmp	dx, FAXPRINT_SWATH_SIZE				>
EC <		ERROR_NE FAXPRINT_ILLEGAL_SWATH_LINE_SIZE		>
		
elementLoop:
	;
	; Copy the scanline at ds:si to the available swath buffer.  This
	; will be used as the "last line" the next time through.
	;
	; New and improved: sets lowestNonBlank to totalLines'
	; value if the scanline is non-zero.
	;
		call	FaxprintCopyLine
	;
	; Compress the line at ds:si into the compressedLine buffer.  Uses the
	; scan line above the current one, as indicated by totalLines.
	;
		call	FaxprintCompressALine	; cx <- number of bytes in the
						;  compressed line.
	;
	;  Unlock the print-swath huge array block before we go
	;  and append our compressed data to the fax file, to free
	;  up heapspace.
	;
		call	HugeArrayUnlock
	;
	; Append or replace.  Check a flag to see.
	;
		test	{word} es:[faxFileFlags], mask FFF_REPLACE_WITH_COVER_PAGE
		jz	append
	;
	; Maybe we don't need to be doing this.  If we've done all of the
	; copying, then we just return.  If we replace, we don't need to update
	; the spaceCheckCount.
	;
		mov	ax, es:[absoluteCurrentLine]
		cmp	ax, es:[lastCPHeight] 
		jb	replace
		BitSet	es:[faxFileFlags], FFF_DONE_REPLACING
		jmp	cleanUp
replace:
		call	FaxprintReplaceScanLine
		jmp	noAppend
append:
	;
	; Append the compressed data to the fax file
	;
		call	FaxprintAppendToFile	; append the compressed line to
						;  the fax file.
	;
	;  Set up to loop.  Decrement the line count and lock the
	;  next huge-array element.  Note that we use up no new space
	;  when replacing.
	;
		inc	ss:[spaceCheckCount]	; 1 step closer to 10 lines
noAppend:
		inc	ss:[currentLine]	; next printswath scan line
		inc	ss:[totalLines]		; 1 more line on this page
		inc	es:[absoluteCurrentLine]
		dec	ss:[linesLeft]		; 1 step closer to victory
		jz	cleanUp			; no more elements!
	;
	;  OK, check spaceCheckCount to see if we've hit a multiple of
	;  10 lines.  If we have, check the available disk space and
	;  stop everything if we're running low.
	;
		cmp	ss:[spaceCheckCount], LINES_PER_DISK_SPACE_CHECK
		jb	nextElement
		clr	ss:[spaceCheckCount]	; we hit 10!
		call	CheckAvailableDiskSpace	; enough space for 10 more?
		jc	cleanUp			; nope!  bail.
nextElement:
	;
	;  We're OK for space.  Lock the next element.
	;
		movdw	bxdi, ss:[printSwath]
		clr	dx			; high word of element number
		mov	ax, ss:[currentLine]	; dx.ax <- element to lock
		call	HugeArrayLock		; ds:si <- next scan line

EC <		tst	ax			; call me paranoid...	>
EC <		ERROR_Z PRINT_SWATH_CORRUPT_HUGE_ARRAY			>

		jmp	elementLoop
cleanUp:
	;
	; All done!  Unlock the swappable compressed line buffer.
	;
EC <		call	ECCheckDGroupES					>

		mov	bx, es:[compressedLineHandle]
		call	MemUnlock
	;	
	; Update the total number of lines for this page.
	;
		mov	ax, ss:[totalLines]
		mov	es:[twoDCompressedLines], ax
		mov	ax, ss:[lowestNonBlank]
		mov	es:[lowestNonBlankLine], ax
		clc
exit:
		.leave
		ret

PrintSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwathSetupLocals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads PrintSwath's local variables with some info from dgroup,
		and allocates the compressed line buffer.  Loads the following
		locals:

		compressedLine	word		; compressed line buffer segment
		linesLeft	word		; how many lines to compress
		currentLine	word		; what line to write next
		spaceCheckCount	word		; count to 10 & check space
		faxFile		hptr		; The Fax File
		faxHugeArray	word		; fax huge array handle
		swath1Buffer	word		; previous line buffer #1
		swath2Buffer	word		; previous line buffer #2
		totalLines	word		; total number page lines
		printSwath	dword		; the passed print swath
		ffFlags		word		; faxfile flags
CALLED BY:	PrintSwath

PASS:		dx.cx	- VM file and block handle for Huge bitmap
		ss:bp	- inherited frame
		es	- dgroup

RETURN:		carry flag	- clear if there were no problems
				- set if there was an error

DESTROYED:	ax, bx, cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSwathSetupLocals	proc	near
		uses	ds
		.enter inherit PrintSwath
		Assert	stackFrame, bp
		
	;
	;  Get the total scan line count.  If zero, bail.  Notice
	;  we have two counters:  linesLeft, which tells us when we
	;  run out of huge-array elements (it counts down), and also
	;  currentLine, which tells us the next element to process (it
	;  counts up).  Oh well.
	;
		movdw	ss:[printSwath], dxcx	; save it
		movdw	bxdi, dxcx
		call	HugeArrayGetCount	; dx.ax <- #lines in print swath
		tst	ax			; how many elements?
EC <		ERROR_Z	EMPTY_HUGE_ARRAY_PASSED_TO_PRINT_SWATH		>
NEC <		jz	error			; nothing to do		>
		mov	ss:[linesLeft], ax	; total scan lines
	;
	;  Grab the buffer for the compressed line.
	;
EC <		call	ECCheckDGroupES					>
		mov	bx, es:[compressedLineHandle]
		call	MemLock
EC <		ERROR_C FAXPRINT_NO_COMPRESSED_LINE_BUFFER		>
		mov	ss:[compressedLine], ax
	;
	; Move dgroup variables to locals.
	;
		mov	bx, es:[outputHugeArrayHan]
		mov	ss:[faxHugeArray], bx	; save huge array handle
		mov	bx, es:[outputVMFileHan]
		mov	ss:[faxFile], bx	; save fax file handle

		mov	bx, es:[swathBuffer1Handle]
		call	MemDerefDS		; get  buffer 1 segment
		mov	bx, ds
		mov	ss:[swath1Buffer], bx	; save buffer 1 segment

		mov	bx, es:[swathBuffer2Handle]
		call	MemDerefDS		; get  buffer 2 segment
		mov	bx, ds
		mov	ss:[swath2Buffer], bx	; save buffer 2 segment

		mov	bx, es:[twoDCompressedLines]
		mov	ss:[totalLines], bx	; save total number of lines
						;  for this page.
		mov	bx, es:[lowestNonBlankLine]
		mov	ss:[lowestNonBlank], bx	; save lowest non-blank so far
						;  for this page.
		clr	ss:[currentLine]	; start with first element
		clr	ss:[spaceCheckCount]	; no lines yet.

		
		clc				; success!
NEC < done:								>
		.leave
		ret
NEC < error:								>
NEC <		stc				; set error flag	>
NEC <		jmp	done						>
		
PrintSwathSetupLocals	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintCopyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the passed scan line to one of two "previous line"
		buffers.  The totalLines local (inherited from PrintSwath)
		indicates how many lines have been printed so far for the
		current page, and indirectly indicates which buffer contains
		the previous line info, and which is ready to be filled:

			if totalLines is even,
			   swath1Buffer is ready to be filled
			   swath2Buffer contains the last scan line
			else (totalLines is odd),
			   swath1Buffer contains the last scan line
			   swath2Buffer is ready to be filled

		Also pads out the margins to 1/4".

		New and improved: now updates lowestNonBlank to totalLines'
		value if the passed line has a non-zero value in it.

CALLED BY:	PrintSwath

PASS:		ss:bp	- inherited frame from PrintSwath 
		ds:si	- scan line bitmap with FAXPRINT_SWATH_SIZE
			  bytes to copy
		
RETURN:		ds:si	- copied scan line bitmap, padded to
			  FAXFILE_HORIZONTAL_BYTE_WIDTH.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxprintCopyLine	proc	near
		uses	ax, bx, cx, si, di, es
		.enter	inherit PrintSwath
		Assert	stackFrame, bp
	;
	;  If the total number of lines is even, then swath1Buffer is the
	;  unused buffer, and swath2Buffer contains the last line.  If the
	;  total number of lines is odd, then it's the other way around.
	;
		mov	bx, ss:[swath1Buffer]	; assume even
		test	ss:[totalLines], 1	; odd or even?
		jz	getDestination		; jump if even
		mov	bx, ss:[swath2Buffer]
getDestination:
		mov	es, bx			; es:di <- destination buffer
		mov	di, (LEFT_MARGIN_OFFSET / 8)
	;
	; Copy the buffer.  Since it's an even number of bytes, copy words.
	;
		CheckHack <(FAXPRINT_SWATH_SIZE and 1) eq 0>
		mov	cx, (FAXPRINT_SWATH_SIZE / 2)
		rep	movsw			; copy buffer
		
	;
	; If there's non-zero in here, update lowestNonBlank.
	;
		mov	di, (LEFT_MARGIN_OFFSET / 8)
		clr	al
		CheckHack <(FAXPRINT_SWATH_SIZE and 1) eq 0>
		mov	cx, (FAXPRINT_SWATH_SIZE / 2)
		repz	scasw
		jz	done			; jump if it's a blank line.
	;
	; It's non-blank!  Update the lowestNonBlank counter.
	;
		mov	ax, ss:[totalLines]
		mov	ss:[lowestNonBlank], ax
done:
		.leave
		ret
FaxprintCopyLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintCompressALine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compresses the passed scan line into the compressedLine buffer.
		Uses the previous line, if this is a 2d compressed line (which
		it will be unless totalLines is 0 or a multiple of 64).  This
		is how you tell which buffer to use:

			if totalLines is even,
			   swath2Buffer contains the previous scan line
			else (totalLines is odd),
			   swath1Buffer contains the previous scan line

CALLED BY:	PrintSwath

PASS:		ss:bp	- inherited frame

RETURN:		cx	- number of bytes in the compressed line

DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxprintCompressALine	proc	near
		uses	dx, es
		.enter	inherit PrintSwath
		Assert	stackFrame, bp

	;
	; If the totalLines is zero, or the number of lines compressed thus far
	; for this page is a multiple of 64, compress the scan line in 1d.
	;
		mov	bx, ss:[totalLines]
		tst	bx
		jz	compress1d		; jumps if it's the first line
		and	bx, 0x3f		; examine the low six bits
		jz	compress1d		; jumps if a multiple of 64.
	;
	; If we're replacing (or appending in the range of the lastCPHeight)
	; then we ALLWAYS want to do 1-d.  Otherwise, the last replacement
	; scanline can't be gauranteed to be what the following original
	; scan line is expecting (a la 2-d).  
	;
		test	{word} es:[faxFileFlags], mask	FFF_REPLACE_WITH_COVER_PAGE
		jnz	compress1d
		test	{word} es:[faxFileFlags], mask	FFF_PRE_REPLACE_PAGE
		jz	compress2d
		mov	dx, es:[lastCPHeight]
		inc	dx
		inc	dx
		cmp	es:[absoluteCurrentLine], dx
		jbe	compress1d

compress2d:
	;
	; This line will be 2d compressed.
	;
		mov	ss:[twoDparams].FF2DCP_compressFlags,
				mask FF2DCF_2D_COMPRESS_OUTPUT_LINE or \
				mask FF2DCF_OPTIMIZE_FOR_SPACE
loadSourceLine:
	;
	; Figure out which buffer contains the previous scan line.
	;
		test	bx, 1			; odd or even?
		mov	bx, ss:[swath1Buffer]	; assume odd
		mov	ax, ss:[swath2Buffer]	; assume odd
		jnz	getLine			; jump if odd
		xchg	ax, bx			; evens.  Switch 'em.
getLine:
	;
	; At this point:
	;	ax:0	- source line buffer
	;	bx:0	- reference line buffer
	;
	; Load the reference line pointer.
	;
		mov	ss:[twoDparams].FF2DCP_referenceLine.segment, bx
		clr	ss:[twoDparams].FF2DCP_referenceLine.offset
		mov	bx, FAXFILE_HORIZONTAL_BYTE_WIDTH
		mov	ss:[twoDparams].FF2DCP_bytesInRefLine, bx
	;
	; Now the source line.
	;
		mov	ss:[twoDparams].FF2DCP_sourceLine.segment, ax
		clr	ss:[twoDparams].FF2DCP_sourceLine.offset
		mov	ss:[twoDparams].FF2DCP_bytesInSourceLine, bx
	;
	; And the destination...
	;
		mov	bx, ss:[compressedLine]
		mov	ss:[twoDparams].FF2DCP_outputLine.segment, bx
		clr	ss:[twoDparams].FF2DCP_outputLine.offset
		mov	ss:[twoDparams].FF2DCP_bytesToOutput,
					       FAXFILE_MAX_HORIZONTAL_BYTE_WIDTH
	;
	; Now go to it.
	;
		lea	bx, ss:[twoDparams]
		mov	dx, ss
		call	FaxFile2DCompressScanline; cx <- size of compressed data

EC <		cmp	cx, FAXFILE_MAX_HORIZONTAL_BYTE_WIDTH 		>
EC <		ERROR_G FAXPRINT_COMPRESSED_DATA_LARGER_THAN_BUFFER	>

		.leave
		ret

compress1d:
	;
	; This is a great time to update our progress meter.
	;
		mov	bx, ss:[totalLines]
		call	CheckSpaceAndProgress
	;
	; The line will be compressed 1d.
	;
		mov	ss:[twoDparams].FF2DCP_compressFlags,
				mask FF2DCF_OPTIMIZE_FOR_SPACE
		jmp	loadSourceLine
		
FaxprintCompressALine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintReplaceScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces a line in the fax file's current page
		huge array. 

CALLED BY:	PrintSwath
PASS:		ss:[bp]	- inherited from PrintSwath
		es	- dgroup
		cx	- number of bytes in compressed line
		ax	- the number of the scan line to replace
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	4/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxprintReplaceScanLine	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		
		.enter 	inherit	PrintSwath		
	;
	;  Replace the scan line.  cx currently has the
	;  number of bytes of compressed data (including EOL), and we
	;  pass this to HugeArrayAppend as the size of the variable-
	;  sized element.
	;
		clr	dx
		mov	bx, ss:[faxFile]
		mov	di, ss:[faxHugeArray]	; ^vbx:di = huge array
		mov	bp, ss:[compressedLine]
		clr	si			; bp.si = compressed data
		call	HugeArrayReplace	
		.leave
		
		ret
		
FaxprintReplaceScanLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintAppendToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends the compressed line to the fax file's current page
		hugeArray.

		This routine also deducts the passed number of bytes from the
		running disk space counter set in FaxprintResetDiskSpace.
		If there is not enough (approximate) disk space to add the
		scanline, it will not be added.

CALLED BY:	PrintSwath

PASS:		ss:bp	- inherited frame from PrintSwath
		cx	- number of bytes in compressedLine
		es	- dgroup

RETURN:		dx:ax	- new element number

DESTROYED:	bx, di, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxprintAppendToFile	proc	near
		.enter	inherit	PrintSwath
EC <		call	ECCheckDGroupES					>
	;
	; Deduct the number of bytes from the available disk space count.
	;
		clr	bx			
	;
	; Make sure we have enough to deduct.
	;
		cmpdw	es:[diskSpace], bxcx
		jbe	noSpace			; jump if no space left...
	;
	; We have that much, at least.  Subtract away.
	;
		subdw	es:[diskSpace], bxcx
	;
	;  Append the scanline to the file.  cx currently has the
	;  number of bytes of compressed data (including EOL), and we
	;  pass this to HugeArrayAppend as the size of the variable-
	;  sized element.
	;
		push	bp			; save stack frame
		mov	bx, ss:[faxFile]
		mov	di, ss:[faxHugeArray]	; ^vbx:di = huge array
		mov	si, ss:[compressedLine]
		mov	bp, si			; bp.si = compressed data
		clr	si
		call	HugeArrayAppend		; dx:ax = new element number
		pop	bp			; recover stack frame
done:
		.leave
		ret

noSpace:
	;
	; There's not enough space to add this scanline.  Set an error flag.
	;
		mov	es:[errorFlag], PDEC_RAN_OUT_OF_DISK_SPACE
		jmp	done
		
FaxprintAppendToFile	endp

.rcheck
.wcheck



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSpaceAndProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for disk space and sends out the current scanline to the
		progress optr.

CALLED BY:	PrintSwath

PASS:		bx	- the current scanline so far
		es	- dgroup

RETURN:		carry set if not enough disk space, clear otherwise

DESTROYED:	possibly es/ds, since there's an ObjMessage in here.


	absolute current scanline     *  one oage worth of scanlines
      -----------------------------
	     total scanlines

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	12/29/94   	Initial version
	jimw	4/12/95		updated for multiple page CPs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSpaceAndProgress	proc	near
		uses	ax, bx, cx, dx, di, si
		.enter
EC <		call	ECCheckDGroupES					>
		
		call	CheckAvailableDiskSpace
	LONG	jc	done
	;
	; We've enough disk space.  Now update the progress system, if one's
	; available.
	;
		mov	cx, bx			; cx <- scanline number
		tst	es:[progressOptr].high
	LONG	jz	success			; jump if no update to be done.
	;
	; Send off an update.  But wait; what if we're replacing?
	;
		mov	dx, es:[faxFileFlags]		;dx <- faxfile flags
		test	dx, mask FFF_COVER_PAGE_IS_HEADER
	LONG	jz	normalProgress
	;
	; Get the number of scanlines in a whole page into bx and di.
	;
		mov	bx, FAXFILE_NUM_SCANLINES_STD 
		test	dx, mask FFF_FINE_RESOLUTION
		jz	standard
		shl	bx		
standard:
		mov	di, bx			;di <- page worth of scanlines
		mov 	ax, es:[faxPageCount]
		test	dx, mask FFF_PRINTING_COVER_PAGE
		jnz	coverPageCheck
	;
 	; Not printing the cover page.  There's one situation where we need
	; to do something; when the faxPageCount  == bodyPageCount and
	; cpPageCount == 1.  Then, the current scan line (cx) is correct,
	; but we need a new total. 
	;
		cmp	es:[cpPageCount], 1
		jne	normalProgress
		cmp	ax, es:[bodyPageCount]
		jne	normalProgress
		jmp	figureNewScanline
coverPageCheck:
	;
	; It's a cover page.  If it's the second to last or last coverpage,
	; then we need to figure the new scanline.  We add ten to adjust for
	; the last printswath which copied ten scanlines.
	;
		cmp	ax, es:[cpPageCount]
		jne	notCP
		add	cx, bx		;cx <- absolute current scanLine
		add	cx, 10		;adjustment for previous printswath
		jmp	figureNewScanline
notCP:
		inc	ax	
		cmp	ax, es:[cpPageCount]
		jne	normalProgress
figureNewScanline:
		add	bx, es:[lastCPHeight]	;bx <- total scan lines
		clr	dx
		mov	ax, cx	       ;dxax <- absolute current scanlin
		mul	di	       ;dxax <- absolute SL  * pageworth of SLs
		div	bx		;divide by total scanline
		inc	ax		;round up ONE scanline
		mov	cx, ax		;cx <- effective current scanline
normalProgress:
		mov	bx, es:[progressOptr].high
		mov	si, es:[progressOptr].low
		mov	ax, es:[progressMessage]
		clr	di
		call	ObjMessage
success:
		clc
done:
		.leave
		ret

CheckSpaceAndProgress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintResetDiskSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine checks the current amount of available disk space
		and stores it in instance data.  If there is not another
		DISK_SPACE_FOR_WARNING amount of disk space left, an error is
		returned.

		This should be called when all VMBlocks in memory have been
		flushed already to get a more realistic size back from
		DiskGetVolumeFreeSpace().

CALLED BY:	internal

PASS:		nothing

RETURN:		carry set if not enough space, clear if OK

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	* check dgroup flag to see if we've already done this
	  test on this run:

		- flag set:  return carry set & do nothing
		- flag clear:  set flag, return carry set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxprintResetDiskSpace	proc	far
		uses	ax, bx, dx, es
		.enter
	;
	;  Get the dgroup segment and check our disk-space flag.
	;
		mov	bx, handle dgroup
		call	MemDerefES			; es <- dgroup

		tst	es:[errorFlag]			; clears carry
		stc					; assume the worst
		jnz	done				; already ran out!
	;
	;  We haven't run out yet.  Check the available disk space.
	;
		mov	bx, FAX_FILE_STANDARD_PATH
		call	DiskGetVolumeFreeSpace		; dx:ax - bytes free
		movdw	es:[diskSpace], dxax
	;
	; Do the rest of the checking in CheckAvailableDiskSpace.
	;
		call	CheckAvailableDiskSpace
done:
		.leave
		ret
FaxprintResetDiskSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAvailableDiskSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check disk space & put up dialog if not enough left.

CALLED BY:	PrintSwath()

PASS:		es	- dgroup

RETURN:		carry set if not enough space, clear if OK

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	* check dgroup flag to see if we've already done this
	  test on this run:

		- flag set:  return carry set & do nothing
		- flag clear:  set flag, return carry set

	* user will get warned later (& the file will be deleted)
	  if we're out of disk space

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/21/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAvailableDiskSpace	proc	near
		uses	bx, dx, ax
		.enter
	;
	;  Check our disk-space flag.
	;
EC <		call	ECCheckDGroupES					>
		tst_clc	es:[errorFlag]			; clears carry
		stc					; assume the worst
		jnz	done				; already ran out!
	;
	;  We haven't run out yet.  Check the available disk space.
	;
		movdw	dxax, es:[diskSpace]		; dx:ax <- remaining
							; 	    disk space
		tst_clc	dx				; clears carry
		jnz	done				; no problemo
	;
	;  We've got less than 65K left.  Compare ax (the actual amount)
	;  against our low-water level warning.
	;
		cmp	ax, DISK_SPACE_FOR_WARNING	; above low-level?
		ja	done				; carry clear (really)
	;
	;  We're below our warning level.  Set the errorFlag appropriately.
	;
noSpace::
		mov	es:[errorFlag], PDEC_RAN_OUT_OF_DISK_SPACE
		stc
done:
		.leave
		ret
CheckAvailableDiskSpace	endp


PrintSwathCode	ends
