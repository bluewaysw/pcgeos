COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- Full-page Postscript Form
FILE:		fps.asm

AUTHOR:		Adam de Boor, Dec  4, 1989

ROUTINES:
	Name			Description
	----			-----------
	FPSPrologue		Initialize file
	FPSSlice		Write a bitmap slice to the file
	FPSEpilogue		Cleanup

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 4/89	Initial revision


DESCRIPTION:
	Output-dependent routines for creating a Full-page Postscript file.
	
	This is exactly like an EPS file, except the suffix is different and
	there's some additional translation to center the image on the page.
		

	$Id: fps.asm,v 1.1 97/04/04 15:36:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
include	file.def
;include event.def
include psc.def


idata	segment

FPSProcs	DumpProcs	<
	PSCPreFreeze,
	FPSPrologue,
	FPSSlice,
	FPSEpilogue,
	<'psc'>,
	mask DUI_POSTSCRIPTBOX or mask DUI_NUMPAGES or mask DUI_PAGESIZE or \
	mask DUI_DESTDIR or mask DUI_BASENAME or mask DUI_DUMPNUMBER or \
	mask DUI_ANNOTATION
>

pagesText	char	6 dup(0)	; Buffer for #copies.

idata	ends

PSC	segment	resource		; To avoid bunches of far calls


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FPSPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start off a Full-page PostScript file.

CALLED BY:	EXTERNAL
PASS:		cx	= image width (pixels)
		dx	= image height (pixels)
		si	= image format (BMFormat)
		bp	= file handle
RETURN:		carry if couldn't write the whole header
DESTROYED:	lots of neat things

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FPSPrologue	proc	far
		.enter
		mov	bx, PSC_FULL	; Signal FPS
		call	PSCPrologue
		.leave
		ret
FPSPrologue	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FPSSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single bitmap slice out to the file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
		si	= bitmap block handle
		cx	= size of bitmap (bytes)
RETURN:		Carry set on error
DESTROYED:	ax, bx, cx, si

PSEUDO CODE/STRATEGY:
	Call PSCSlice and free the block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FPSSlice	proc	far
		.enter
		call	PSCSlice
		pushf
		mov	bx, si
		call	MemFree
		popf
		.leave
		ret
FPSSlice	endp


epilogue	char	'/#copies %1 def showpage\n', 0
ctrld		char	4

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FPSEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off a Full-page postscript file.

CALLED BY:	DumpScreen
PASS:		bp	= file handle
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Produce a showpage after setting #copies to be the number of
		copies we (the user) want, then call PSCEpilogue to take care
		of things there.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FPSEpilogue	proc	far
		uses	ds, dx, cx
		.enter
		mov	dl, ds:procVars.DI_psNumPages
		clr	dh
		mov	di, offset pagesText
		push	di			; for passing to PSCPrintf2
		push	di
		call	PSCFormatInt
		mov	di, offset epilogue
		call	PSCPrintf2
		jc	outCtrlD
		call	PSCEpilogue
outCtrlD:
	;
	; Put out ctrl-d to end the file.
	;
		segmov	ds, cs, dx
		mov	dx, offset ctrld
		mov	cx, length ctrld
		clr	al
		mov	bx, bp
		call	FileWrite
		.leave
		ret
FPSEpilogue	endp

PSC		ends
