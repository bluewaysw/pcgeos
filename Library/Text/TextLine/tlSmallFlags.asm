COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallFlags.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	SmallLineAlterFlags	Alter flags for a small object
	SmallLineTestFlags	Test flags for a small object
	SmallLineGetFlags	Get flags for a small object
				   
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Flags related stuff for small text objects.

	$Id: tlSmallFlags.asm,v 1.1 97/04/07 11:21:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineAlterFlags
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
SmallLineAlterFlags	proc	near
	uses	di, es
	.enter
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference			>

	push	ax, dx			; Save flags to set, clear
	call	SmallGetLinePointer	; *ds:ax <- chunk array
					; es:di <- line pointer
					; cx <- size of line/field data
	pop	ax, cx			; Restore flags to set, clear
	;
	; es:di	= Pointer to the line
	; ax	= Bits to set
	; cx	= Bits to clear
	;
	call	CommonLineAlterFlags	; Modify the flags
	.leave
	ret
SmallLineAlterFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineTestFlags
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
SmallLineTestFlags	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference			>

	push	ax			; Save flags to set
	call	SmallGetLinePointer	; *ds:ax <- chunk array
					; es:di <- line pointer
					; cx <- size of line/field data
	pop	ax			; Restore flags to set
	;
	; es:di	= Pointer to the line
	; ax	= Bits to test
	;
	call	CommonLineTestFlags	; Check the flags
	.leave
	ret
SmallLineTestFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetFlags
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
SmallLineGetFlags	proc	far
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference			>

	call	SmallGetLinePointer	; *ds:ax <- chunk array
					; es:di <- line pointer
					; cx <- size of line/field data
	;
	; es:di	= Pointer to the line
	;
	call	CommonLineGetFlags	; Get the flags
	.leave
	ret
SmallLineGetFlags	endp


TextFixed	ends

