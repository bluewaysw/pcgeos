COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallInvert.asm

AUTHOR:		John Wedgwood, Jan  3, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 3/92	Initial revision

DESCRIPTION:
	Code for inverting ranges on lines.

	$Id: tlSmallInvert.asm,v 1.1 97/04/07 11:20:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineInvertRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a range on a line.

CALLED BY:	TL_LineInvertRange via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars with:
			    LICL_region set
			    LICL_line = line to invert on
			    LICL_range holds the range to invert
			       VTR_start = 0 for line start
			       VTR_end   = TEXT_ADDRESS_PAST_END for line end
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineInvertRange	proc	near
	uses	ax, bx, cx, di, es
	.enter
	movdw	bxdi, ss:[bp].LICL_line

EC <	call	ECCheckSmallLineReference			>

	call	SmallGetLinePointer	; *ds:ax <- chunk array
					; es:di <- line pointer
					; cx <- size of line/field data
	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; ss:bp	= LICL_vars
	;
	call	CommonLineInvertRange	; Invert the range
	.leave
	ret
SmallLineInvertRange	endp

TextFixed	ends
