COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- Jpeg Format
FILE:		jpeg.asm

AUTHOR:		Adam de Boor, Dec  4, 1989

ROUTINES:
	Name			Description
	----			-----------
	JPEGPrologue		Initialize file
	JPEGSlice		Write a bitmap slice to the file
	JPEGEpilogue		Cleanup

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 4/89	Initial revision


DESCRIPTION:
	Output-dependent routines for creating a Jpeg file.
		

	$Id: jpeg.asm,v 1.1 97/04/04 15:36:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
include	file.def

global  JPEGPROLOGUE: far
global  JPEGSLICE: far
global  JPEGEPILOGUE: far

idata	segment

JPEGProcs	DumpProcs	<
	0, JPEGPrologue, JPEGSlice, JPEGEpilogue, <'jpg'>,
	mask DUI_DESTDIR or mask DUI_BASENAME or mask DUI_DUMPNUMBER or \
	mask DUI_ANNOTATION
>

idata	ends

Jpeg 	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JEGPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a Jpeg file

CALLED BY:	DumpScreen
PASS:		si	= BMFormat
		bp	= file handle
		cx	= dump width
		dx	= dump height
		ds	= dgroup
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	fr	10/17/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JPEGPrologue	proc	far	uses es, di, cx, dx
		.enter

		push	si
		push	bp
		push	cx
		push	dx
		
		call 	JPEGPROLOGUE

		clc
		.leave
		ret
JPEGPrologue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JPEGSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single bitmap slice out to the file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
		si	= bitmap block handle
		cx	= size of bitmap (bytes)
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	fr	10/17/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JPEGSlice	proc	far	uses es, di, ax, bx, dx
		.enter
		push	bp
		push	si
		push	cx
		
		call 	JPEGSLICE

		clc
		.leave
		ret
JPEGSlice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JPEGEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off a Jpeg file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	fr	10/17/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JPEGEpilogue	proc	far
		.enter
		push	bp
		
		call 	JPEGEPILOGUE

		clc		; Nothing to do here
		.leave
		ret
JPEGEpilogue	endp

Jpeg		ends

