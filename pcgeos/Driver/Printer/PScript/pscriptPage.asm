
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptPage.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	5/90	initial version

DESCRIPTION:

	$Id: pscriptPage.asm,v 1.1 97/04/18 11:56:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.

RETURN:		ax	- return value from EPSExportBeginPage

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		basically, just call the EPSExportBeginPage function, which
		will do most of what we need

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintStartPage	proc	far
		uses	bx, ds, dx, di
		.enter

		; just call the translation library

		mov	ds, bp				; ds -> PState
		clr	ds:[PS_cursorPos].P_x
		clr	ds:[PS_cursorPos].P_y
		mov	dx, ds:[PS_expansionInfo]	; option block handle
		push	ds
		mov	bx, dx
		call	MemLock
		mov	ds, ax
		mov	di, ds:[GEO_hFile]		; grab file handle
		call	MemUnlock
		pop	ds
		mov	bx, ds:[PS_epsLibrary]		; get lib handle
		mov	ax, TR_EXPORT_BEGIN_PAGE
		call	CallEPSLibrary		; start page stuff

		.leave
		ret
PrintStartPage	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.

RETURN:		

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintEndPage	proc	far
		uses	ax, bx, cx, dx, si, di, es,ds
		.enter

		; just call the translation library

		mov	ds, bp
		push	ds
		mov	dx, ds:[PS_expansionInfo]	; option block handle
		mov	bx, dx
		call	MemLock
		mov	ds, ax
		mov	di, ds:[GEO_hFile]		; grab file handle
		call	MemUnlock
		pop	ds				; restore PState
		mov	bx, ds:[PS_epsLibrary]
		mov	ax, TR_EXPORT_END_PAGE
		call	CallEPSLibrary			; start page stuff
		clc

		.leave
		ret
PrintEndPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCurrentFileToPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy what we've done so far to the printer

CALLED BY:	INTERNAL
		PrintEndPage, PrintEndJob
PASS:		bx	- file handle
		ds	- PState
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
CopyCurrentFileToPrinter	proc	near
		uses	ax,bx,cx,dx,si,di,es,ds
scratchBuffer	local	128 dup (char)
		.enter

		; if not going to a file, then send down the current page

		mov	al, FILE_POS_RELATIVE		; figure out where we
		clr	cx				;   are...
		clr	dx
		call	FilePos				; get current pos
		mov	cx, dx				; truncate file there
		mov	dx, ax		
		mov	al, FILE_NO_ERRORS
		call	FileTruncate
		mov	al, FILE_POS_START		; reposition at start
		clr	cx
		clr	dx
		call	FilePos

		; copy pieces to the scratch buffer til we're done with the file

		segmov	es, ds, si		; es -> PState
		segmov	ds, ss, si
		lea	si, scratchBuffer	; ds:si -> buffer (writes)
		mov	dx, si			; ds:dx -> buffer (reads)
		mov	cx, length scratchBuffer

		; keep read/writing until we're finished with the file
copyLoop:
		clr	al			; errors please
		call	FileRead
		jc	handleReadError		; probably end of file
		call	PrintStreamWrite	; copy data to port
		jc	resetFile		; if some error, quit
		jmp	copyLoop		; else continue

		; some error happened on the read.  If its a short read (end
		; of file), then we're happy.
handleReadError:
		cmp	ax, ERROR_SHORT_READ_WRITE
		jne	resetFile		;  oops, a REAL error...
		call	PrintStreamWrite	; last few bytes

		; now we need to set the file pos back to the beginning
resetFile:
		mov	al, FILE_POS_START		; reposition at start
		clr	cx
		clr	dx
		call	FilePos

		.leave
		ret
CopyCurrentFileToPrinter	endp
endif
