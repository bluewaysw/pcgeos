
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptPDL.asm

AUTHOR:		Jim DeFrisco, 14 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintSetPageTransform	PDL-specific function to set the transformation
				matrix for the current page
	PrintGString		PDL_specific function to print a gstring

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision


DESCRIPTION:
	This file containt the escape functions that are specific to PDL
	printers
		

	$Id: pscriptPDL.asm,v 1.1 97/04/18 11:56:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetPageTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the transformatrion matrix for the current page

CALLED BY:	GLOBAL (DR_PRINT_ESC_SET_PAGE_TRANSFORM)

PASS:		bx	- PState handle
		dx:si	- pointer to TransMatrix

RETURN:		ax	- error code as returned from TransExportRaw

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		emit some PostScript code to set the current transformation 
		matrix variable.  This code assumes a function that currently
		exists in the PC/GEOS PostScript prolog called SDT (for
		SetDefaultTransform).  This function (currently) does not
		alter the PostScript graphics state, it merely sets a 
		PC/GEOS-defined PostScript variable, and is used later to 
		set the default transformation for the page.

		Also, the passed TransMatrix should NOT include the 
		transformation required to conform to the PostScript coordinate
		system.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetPageTransform	proc	far
		uses	es, di, bx, bp
		.enter

		; we're passed a PState handle, not the segment here.

		push	bx				; save handle
		call	MemLock
		mov	bp, ax				; usually held here
		mov	es, ax				; es -> PState

		; we need to translate all the values into ascii, then write
		; out a buffer with the matrix and the function call.  First
		; lock down the PState and get the file handle to write to.

		mov	ds, dx
		mov	dx, es:[PS_expansionInfo]	; get options blk han
		push	es				; save PState seg
		mov	bx, dx
		call	MemLock
		mov	es, ax
		mov	di, es:[GEO_hFile]		; get file handle
		call	MemUnlock
		pop	es				; restore PState seg
		call	EmitTransform			; send transform

		; now set the paper size (so the reversal of the coordinate
		; system will work OK)

		call	EmitPaperSize			; 

		; release the PState before we go

		pop	bx
		call	MemUnlock

		clc					; just leave carry
		.leave
		ret
PrintSetPageTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a graphics string

CALLED BY:	GLOBAL (DR_PRINT_ESC_PRINT_GSTRING)

PASS:		bx	- PState handle
		si	- GString handle
		cx	- GString flags (record, type GSControl)

RETURN:		ax	- stop code returned from GrDrawGString

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		pass off all the work to the PostScript Translation Lib

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGString	proc	far
		uses	ds, dx, di, cx, bx, bp
		.enter

		; first we need to lock down the PState

		push	bx
		call	MemLock
		mov	bp, ax

		; this is easy.  Just call the TransExport function in the
		; PostScript translation library

		mov	ds, bp				; ds -> PState
		mov	dx, ds:[PS_expansionInfo] 	; get opts block handle
		mov	bx, dx
		call	MemLock
		mov	ds, ax
		mov	di, ds:[GEO_hFile]		; get file handle
		call	MemUnlock
		or	cx, mask GSC_NEW_PAGE 		; make sure this is set
		mov	ds, bp				; ds -> PState
		mov	bx, ds:[PS_epsLibrary]
		mov	ax, TR_EXPORT_LOW
		call	CallEPSLibrary
		mov	ax, cx			 ; return flag fr GrDrawGString

		; release the PState

		pop	bx
		call	MemUnlock

		clc
		.leave
		ret
PrintGString	endp

CommonCode	ends
