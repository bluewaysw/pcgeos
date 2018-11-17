COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		stringSize.asm

AUTHOR:		John Wedgwood, Dec 12, 1991

ROUTINES:
	Name			Description
	----			-----------
	LocalStringSize		Compute number of bytes in a null terminated
					string.
	LocalStringLength	Compute number of characters in a null
					terminated string
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/12/91	Initial revision

DESCRIPTION:
	Code for computing string sizes.

	$Id: stringSize.asm,v 1.1 97/04/05 01:16:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalStringSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the number of bytes in a null terminated string.

CALLED BY:	Global
PASS:		es:di	= String pointer
RETURN:		cx	= Number of bytes in the string (not counting the NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DBCS_PCGEOS
LocalStringSize	proc	far
	uses	ax, di
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	ds, si					>
EC <	segmov	ds, es, si				>
EC <	mov	si, di					>
EC <	call	ECCheckBounds				>
EC <	pop	ds, si					>
endif
	
	LocalStrSize				;cx <- # of bytes

	.leave
	ret
LocalStringSize	endp

else

LocalStringSize		proc	far
	FALL_THRU	LocalStringLength
LocalStringSize		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the number of characters in a null terminated string.

CALLED BY:	Global
PASS:		es:di	= String pointer
RETURN:		cx	= Number of characters in the string (not counting the
				NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalStringLength	proc	far
	uses	ax, di
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	ds, si					>
EC <	segmov	ds, es, si				>
EC <	mov	si, di					>
EC <	call	ECCheckBounds				>
EC <	pop	ds, si					>
endif

	LocalStrLength				;cx <- # of chars

	.leave
	ret
LocalStringLength	endp


kcode	ends
