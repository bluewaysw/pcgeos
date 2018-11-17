COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargeFlags.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Flags related stuff for large text objects.

	$Id: tlLargeFlags.asm,v 1.1 97/04/07 11:20:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineAlterFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the LineFlags associated with a given line.

CALLED BY:	TL_LineAlterFlags via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
		ax	= Bits to set
		dx	= Bits to clear
		if ax == dx then the bits in ax are toggled
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineAlterFlags	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line
	mov	cx, dx			; cx <- flags

	push	cx			; Save flags to clear
	call	LargeGetLinePointer	; es:di <- line pointer
					; cx <- size of line/field data
	pop	cx			; Restore flags to clear
	call	CommonLineAlterFlags	; Modify the flags
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineAlterFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineTestFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for flags being set in the LineFlags for a given line.

CALLED BY:	TL_LineTestFlags via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
		ax	= LineFlags to test
RETURN:		Zero flag clear (non-zero) if any bits in ax are set in the
			LineFlags for the line.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineTestFlags	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

	call	LargeGetLinePointer	; es:di <- line pointer
					; cx <- size of line/field data
	call	CommonLineTestFlags	; Check the flags
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineTestFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the LineFlags for a given line.

CALLED BY:	TL_LineGetFlags via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		ax	= LineFlags for the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineGetFlags	proc	far
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

	call	LargeGetLinePointer	; es:di <- line pointer
					; cx <- size of line/field data
	call	CommonLineGetFlags	; Get the flags
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineGetFlags	endp


TextFixed	ends
