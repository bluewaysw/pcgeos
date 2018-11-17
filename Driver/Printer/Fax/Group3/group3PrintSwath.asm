COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3PrintSwath.asm

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

DESCRIPTION:

	$Id: group3PrintSwath.asm,v 1.1 97/04/18 11:52:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
;  Stick it in its own resource so the rest of the Group3 code
;  can move around while this stuff is locked down & executing.
;  Saves us about 6k of fixed blocks on the heap.
;
PrintSwathCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the huge bitmap

CALLED BY:	PrintSwath
PASS:		bx:di	= huge bitmap
RETURN:		ax	= height of bitmap
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumLines	proc	near
	uses	bx, ds, bp
	.enter
					; bx = file handle
	mov	ax, di			; ax = dir block handle
	call	VMLock			; lock the HugeArray dir block
	mov	ds, ax			; ds -> HugeArray dir block
	mov	bx, size HugeArrayDirectory ; skip past dir header
	mov	ax, ds:[bx].B_height
	call	VMUnlock		; release the VM block

	.leave
	ret
GetNumLines	endp


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

	get next scanline
	compress it
	copy it into the fax file
	go back to first step

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/ 7/93    	Initial version
	AC	9/13/93		Modified for group3
	stevey	2/17/94		rewrote to use less fixed mem & heapspace

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSwath	proc	far
		uses	ax,bx,cx,dx,di,si,ds,es,bp

compressData	local	COMPRESS_DATA_BUFFER_SIZE	dup	(char)
loopCount	local	word			; how many lines total
lineCount	local	word			; what line to write next
yetAnotherCount	local	word			; count to 10 & check space
faxFile		local	hptr			; The Fax File
hugeArray	local	word			; fax huge array handle
printSwath	local	dword			; the passed print swath

		.enter
	;
	;  See if we're running out of disk space, and if we are,
	;  handle it.
	;
		call	CheckAvailableDiskSpace	; es <- dgroup, nukes ax & bx
		LONG	jc	exit
	;
	;  Get the total scan line count.  If zero, bail.  Notice
	;  we have two counters:  loopCount, which tells us when we
	;  run out of huge-array elements (it counts down), and also
	;  lineCount, which tells us the next element to process (it
	;  counts up).  Oh well.
	;
		movdw	printSwath, dxcx	; save it
		movdw	bxdi, dxcx		; bx.di = huge bitmap
	;	call	HugeArrayGetCount	; #lines in print swath
		call	GetNumLines
		tst	ax			; how many elements?
EC <		ERROR_Z	EMPTY_HUGE_ARRAY_PASSED_TO_PRINT_SWATH		>
NEC <		jz	done			; nothing to do		>
	;
	;  Lock the first scan line of the passed print swath.
	;
		mov	ss:[loopCount], ax	; total scan lines
		clr	dx, ax			; lock first element
		call	HugeArrayLock		; ds:si <- scanline
	;
	; Store some dgroup variables on stack, since we need all our
	; segment registers for the loop.
	;
		segmov	es, dgroup, bx
		mov	bx, es:[outputHugeArrayHan]
		mov	ss:[hugeArray], bx	; save huge array handle
		mov	bx, es:[outputVMFileHan]
		mov	ss:[faxFile], bx	; save fax file handle

		clr	ss:[lineCount]		; start with first element
		segmov	es, ss, di		; loop invariants
elementLoop:
	;
	;  Compress and copy the scanline passed from the print driver
	;  to the fax file we are creating.
	;
		lea	di, ss:[compressData]
		mov	cx, FAXFILE_HORIZONTAL_BYTE_WIDTH
		mov	dx, COMPRESS_DATA_BUFFER_SIZE
		call	FaxFileCompressScanline	; cx <- size of compressed data

EC <		cmp	cx, COMPRESS_DATA_BUFFER_SIZE
EC <		ERROR_G GROUP3_COMPRESSED_DATA_LARGER_THAN_BUFFER	>

	;
	;  Unlock the print-swath huge array block before we go
	;  and append our compressed data to the fax file, to free
	;  up heapspace.
	;
		call	HugeArrayUnlock
	;
	;  Append the scanline to the file.  cx currently has the
	;  number of bytes of compressed data (including EOL), and we
	;  pass this to HugeArrayAppend as the size of the variable-
	;  sized element.
	;
		push	bp			; save stack frame
		mov	bx, ss:[faxFile]
		mov	di, ss:[hugeArray]	; ^vbx:di = huge array
		lea	si, ss:[compressData]
		mov	bp, ss			; bp.si = compressed data
		call	HugeArrayAppend		; dx:ax = new element number
		pop	bp			; locals
	;
	;  Set up to loop.  Decrement the line count and lock the
	;  next huge-array element.
	;
		inc	ss:[lineCount]		; next printswath scan line
		inc	ss:[yetAnotherCount]	; 1 step closer to 10 lines
		dec	ss:[loopCount]		; 1 step closer to victory
		jz	done			; no more elements!
	;
	;  OK, check yetAnotherCount to see if we've hit a multiple of
	;  10 lines.  If we have, check the available disk space and
	;  stop everything if we're running low.
	;
		cmp	ss:[yetAnotherCount], LINES_PER_DISK_SPACE_CHECK
		jb	nextElement
		clr	ss:[yetAnotherCount]	; we hit 10!
		call	CheckAvailableDiskSpace	; enough space for 10 more?
		jc	done			; nope!  bail.
nextElement:
	;
	;  We're OK for space.  Lock the next element.
	;
		movdw	bxdi, ss:[printSwath]
		clr	dx			; high word of element number
		mov	ax, ss:[lineCount]
		call	HugeArrayLock		; ds:si = next element

EC <		tst	ax			; call me paranoid...	>
EC <		ERROR_Z PRINT_SWATH_CORRUPT_HUGE_ARRAY			>

		jmp	elementLoop
done:
		clc
exit:
		.leave
		ret

PrintSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAvailableDiskSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check disk space & put up dialog if not enough left.

CALLED BY:	PrintSwath()

PASS:		nothing

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
		uses	dx, ax, bx, es
		.enter
	;
	;  Get the dgroup segment and check our disk-space flag.
	;
		mov	ax, segment dgroup
		mov	es, ax
		tst_clc	es:[errorFlag]			; clears carry
		stc					; assume the worst
		jnz	done				; already ran out!
	;
	;  We haven't run out yet.  Check the available disk space.
	;
		mov	bx, es:[outputVMFileHan]
		call	VMUpdate			; flush blocks to disk
		jc	noSpace				; disk full!
		
		mov	bx, FAX_DISK_HANDLE
		call	DiskGetVolumeFreeSpace		; dx:ax - bytes free
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
