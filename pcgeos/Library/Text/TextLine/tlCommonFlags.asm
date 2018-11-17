COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonFlags.asm

AUTHOR:		John Wedgwood, Jan  2, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 2/92	Initial revision

DESCRIPTION:
	Common code for manipulating flags.

	$Id: tlCommonFlags.asm,v 1.1 97/04/07 11:20:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineAlterFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the flags for a line.

CALLED BY:	SmallLineAlterFlags, LargeLineAlterFlags
PASS:		es:di	= Line
		ax	= Bits to set
		cx	= Bits to clear
		if ax == cx then the bits are toggled
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineAlterFlags	proc	far
	cmp	ax, cx			; Check for toggling
	je	toggle

	not	cx			; Make a mask
	and	es:[di].LI_flags, cx	; Clear bits
	or	es:[di].LI_flags, ax	; Set bits
	not	cx			; Restore cx
quit:
	ret

toggle:
	xor	es:[di].LI_flags, ax	; Toggle bits
	jmp	quit
CommonLineAlterFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineTestFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test LineFlags for bits set

CALLED BY:	SmallLineTestFlags, LargeLineTestFlags
PASS:		es:di	= Line
		ax	= Bits to test
RETURN:		Zero flag clear (nz) if the any of the bits are set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineTestFlags	proc	near
	test	es:[di].LI_flags, ax	; test bits
	ret
CommonLineTestFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the LineFlags for a line

CALLED BY:	SmallLineGetFlags, LargeLineGetFlags
PASS:		es:di	= Line
RETURN:		ax	= LineFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineGetFlags	proc	far
	mov	ax, es:[di].LI_flags	; Get flags
	ret
CommonLineGetFlags	endp


TextFixed	ends
