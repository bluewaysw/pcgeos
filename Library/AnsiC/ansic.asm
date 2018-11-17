COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/AnsiC
FILE:		ansic.asm

AUTHOR:		Don Reeves, Apr 23, 1992

ROUTINES:
	Name			Description
	----			-----------
	AnsiCEntry		Library entry point
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	4/23/92		Initial revision

DESCRIPTION:
	Contains the library netry point for the ANSI C library

	$Id: ansic.asm,v 1.1 97/04/04 17:42:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include ansicGeode.def

udata	segment
	mallocOffset	word	(?)
		public	mallocOffset
	streamOffset	word	(?)
		public	streamOffset
udata	ends

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AnsiCEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library entry point

CALLED BY:	GLOBAL

PASS:		di	= Library Call Type
		cx	= handle of geode

RETURN:		carry	= clear if successful
			= set otherwise

DESTROYED:	BX, CX

PSEUDO CODE/STRATEGY:
		* The malloc code needs two words of private data, one
		  for small blocks & the other for large blocks.

		* The stream code needs one word of private data, for
		  a linked-list of stream handles

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/23/92		Initial version
		Schoon	7/28/92		Revised for streams

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHack	<LCT_ATTACH eq 0>
AnsiCEntry	proc	far	
		.enter
	
		; See if we are detaching
		;
NOFXIP	<	segmov	ds, dgroup, ax				>
FXIP	<	mov	bx, handle dgroup			>
FXIP	<	call	MemDerefDS		; ds = dgroup	>
		mov	cx, 3			; # of words to alloc/free => CX
		cmp	di, LCT_DETACH
		jg	done
		jl	next

		mov	bx, ds:[mallocOffset]
		call	GeodePrivFree
done:
		clc				; no errors 
		jmp	exit

		; See if we are attaching
next:						; ax -> 0
		mov	bx, handle 0
		call	GeodePrivAlloc		; allocate words in private data
		mov	ds:[mallocOffset], bx
		add 	bx, 4
		mov	ds:[streamOffset], bx
		clc	
		cmp	bx, 4			; did allocation succeed ??
		jnz	exit
		stc				; error
exit:
		.leave
		ret
AnsiCEntry	endp

	ForceRef	AnsiCEntry
InitCode	ends










