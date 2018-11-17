COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- Gif Format
FILE:		gif.asm

AUTHOR:		Adam de Boor, Dec  4, 1989

ROUTINES:
	Name			Description
	----			-----------
	GIFPrologue		Initialize file
	GIFSlice		Write a bitmap slice to the file
	GIFEpilogue		Cleanup

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 4/89	Initial revision


DESCRIPTION:
	Output-dependent routines for creating a Gif file.
		

	$Id: gif.asm,v 1.1 97/04/04 15:36:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
include	file.def

global  GIFPROLOGUE: far
global  GIFSLICE: far
global  GIFEPILOGUE: far

idata	segment

GIFProcs	DumpProcs	<
	0, GIFPrologue, GIFSlice, GIFEpilogue, <'gif'>,
	mask DUI_DESTDIR or mask DUI_BASENAME or mask DUI_DUMPNUMBER or \
	mask DUI_ANNOTATION
>

idata	ends

Gif	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a Gif file

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
GIFPrologue	proc	far	uses es, di, cx, dx
		.enter

		push	si
		push	bp
		push	cx
		push	dx
		
		call 	GIFPROLOGUE

		clc
		.leave
		ret
GIFPrologue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFSlice
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
GIFSlice	proc	far	uses es, di, ax, bx, dx
		.enter
		push	bp
		push	si
		push	cx
		
		call 	GIFSLICE

		clc
		.leave
		ret
GIFSlice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off a Gif file

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
GIFEpilogue	proc	far
		.enter
		push	bp
		
		call 	GIFEPILOGUE

		clc		; Nothing to do here
		.leave
		ret
GIFEpilogue	endp

Gif		ends

