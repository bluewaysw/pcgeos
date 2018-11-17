COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fileEC.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 9/93   	Initial version.

DESCRIPTION:
	

	$Id: fileEC.asm,v 1.1 97/04/07 10:45:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFilenameDSDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that DS:DX points to a valid filename

CALLED BY:	ShellGetFileHeaderFlags

PASS:		ds:dx - filename?

RETURN:		nothing 

DESTROYED:	nothing  (flags preserved)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 9/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFilenameDSDX	proc near
	uses	si

	.enter
	
	mov	si, dx
	call	ECCheckAsciiString

	.leave
	ret
ECCheckFilenameDSDX	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckAsciiString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that ds:si is a valid ascii string (filename
		or path name)

CALLED BY:	utility

PASS:		ds:si - string to check

RETURN:		nothing 

DESTROYED:	nothing - flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckAsciiString	proc near
	uses	ax,cx,si
	.enter

	call	ECCheckBounds		; first - check ds:si

if not DBCS_PCGEOS
	pushf
	mov	cx, size PathName
	clr	ah
startLoop:
	lodsb
	tst	al
	jz	done
	call	LocalIsDosChar
	ERROR_Z	ILLEGAL_ASCII_STRING
	loop	startLoop

	ERROR	ILLEGAL_ASCII_STRING
done:
	popf
endif
	.leave
	ret
ECCheckAsciiString	endp
